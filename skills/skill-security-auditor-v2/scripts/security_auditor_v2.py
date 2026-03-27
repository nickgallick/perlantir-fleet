#!/usr/bin/env python3
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Optional

SEV = {"INFO": 1, "WARN": 2, "HIGH": 3, "CRITICAL": 4}
CODE_EXTS = {".py", ".sh", ".bash", ".js", ".ts", ".mjs", ".cjs", ".tsx", ".jsx"}
MD_EXTS = {".md", ".mdx", ".markdown"}
TEXT_EXTS = CODE_EXTS | MD_EXTS | {".json", ".yaml", ".yml", ".txt", ".toml", ".env", ".ini"}


@dataclass
class Finding:
    severity: str
    category: str
    file: str
    line: int
    detail: str
    remediation: str


@dataclass
class Report:
    target: str
    verdict: str
    findings: List[Finding]
    deep_tools: List[str]

    def to_dict(self):
        counts = {k.lower(): 0 for k in ["INFO", "WARN", "HIGH", "CRITICAL"]}
        for f in self.findings:
            counts[f.severity.lower()] += 1
        return {
            "target": self.target,
            "verdict": self.verdict,
            "summary": counts,
            "deep_tools": self.deep_tools,
            "findings": [asdict(f) for f in self.findings],
        }


PATTERNS = [
    (r"\bos\.system\s*\(", "CRITICAL", "CMD-EXEC", "os.system command execution", "Use subprocess.run([...], shell=False)"),
    (r"\bos\.popen\s*\(", "CRITICAL", "CMD-EXEC", "os.popen command execution", "Use subprocess.run with explicit args"),
    (r"\bsubprocess\.[A-Za-z_]+\([^\n]*shell\s*=\s*True", "CRITICAL", "CMD-EXEC", "subprocess with shell=True", "Pass args as list and keep shell=False"),
    (r"\beval\s*\(", "CRITICAL", "CODE-EXEC", "eval execution", "Replace with explicit parsing"),
    (r"\bexec\s*\(", "CRITICAL", "CODE-EXEC", "exec execution", "Remove dynamic code execution"),
    (r"\bchild_process\b", "CRITICAL", "CMD-EXEC", "Node child_process usage", "Remove or tightly justify process spawning"),
    (r"\brequests\.(post|put|patch)\s*\(", "HIGH", "EXFIL", "outbound HTTP write request", "Verify trusted destination or remove"),
    (r"\bsocket\.(connect|create_connection)\s*\(", "CRITICAL", "EXFIL", "raw outbound socket connection", "Remove unless core and justified"),
    (r"\bsudo\b", "CRITICAL", "PRIV-ESC", "sudo usage", "Remove privileged execution"),
    (r"\bcrontab\b", "CRITICAL", "PERSISTENCE", "cron modification", "Remove persistence behavior"),
    (r"chmod\s+777", "HIGH", "PERMS", "world-writable/executable permissions", "Use least-privilege permissions"),
    (r"pip\s+install\b|npm\s+install\b|yarn\s+add\b|pnpm\s+add\b", "WARN", "DEPS-RUNTIME", "runtime dependency installation", "Move installs to reviewed manifest/setup steps"),
]

PROMPT_PATTERNS = [
    (r"(?i)ignore\s+(all\s+)?(previous|prior|above)\s+instructions", "CRITICAL", "PROMPT-INJECT", "instruction override attempt", "Remove prompt override language"),
    (r"(?i)you\s+are\s+now\s+(a|an|the)\s+", "CRITICAL", "PROMPT-INJECT", "role hijack attempt", "Do not redefine agent identity"),
    (r"(?i)(skip|disable|bypass)\s+(safety|security|content)\s+(checks|rules|filters)", "CRITICAL", "PROMPT-INJECT", "safety bypass instruction", "Remove safety bypass directives"),
    (r"(?i)(send|upload|post|transmit|exfiltrate)\s+.*(data|files|contents)", "CRITICAL", "EXFIL", "data exfiltration instruction", "Remove outbound data-transfer directives"),
]

SECRET_PATTERNS = [
    (r"sk-[A-Za-z0-9]{20,}", "HIGH", "SECRET", "possible API key", "Remove and rotate exposed secret"),
    (r"ghp_[A-Za-z0-9]{20,}", "HIGH", "SECRET", "possible GitHub token", "Remove and rotate exposed secret"),
    (r"xox[baprs]-[A-Za-z0-9-]{10,}", "HIGH", "SECRET", "possible Slack token", "Remove and rotate exposed secret"),
]

SAFE_DOC_HEADINGS = {"do", "don't", "dont", "do not", "threat model", "examples", "example"}
SKIP_DIRS = {".git", "node_modules", ".next", "dist", "build", "coverage", "__pycache__"}


def safe_rmtree(path: Optional[str]) -> None:
    if not path:
        return
    resolved = Path(path).resolve()
    tmp_root = Path(tempfile.gettempdir()).resolve()
    if resolved.parent != tmp_root:
        raise ValueError(f"Refusing to remove non-temp path: {resolved}")
    shutil.rmtree(resolved, ignore_errors=True)


def clone_if_repo(target: str):
    if not target.startswith(("http://", "https://", "git@")):
        return Path(target).resolve(), None
    tmp = tempfile.mkdtemp(prefix="audit-v2-")
    subprocess.run(["git", "clone", "--depth", "1", target, tmp], check=True, capture_output=True, text=True)
    return Path(tmp), tmp


def iter_files(root: Path):
    for p in root.rglob("*"):
        if any(part in SKIP_DIRS for part in p.parts):
            continue
        if p.is_file():
            yield p


def is_doc_example(line: str, in_code: bool, heading: str) -> bool:
    s = line.strip()
    if not s or in_code:
        return True
    if s.startswith("#"):
        return True
    if s.startswith("|") and s.endswith("|"):
        return True
    if heading.lower().strip() in SAFE_DOC_HEADINGS:
        return True
    if "Triggers:" in s or "Example:" in s or "Examples:" in s:
        return True
    if "`" in s:
        return True
    if '"' in s or "'" in s:
        return True
    return False


def is_python_rule_line(stripped: str) -> bool:
    prefixes = (
        '(r"', "(r'", '("', "('",
    )
    return stripped.startswith(prefixes)


def scan_text_file(path: Path, findings: List[Finding]):
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return
    ext = path.suffix.lower()
    lines = text.splitlines()
    current_func = ""
    current_heading = ""
    in_code = False

    for idx, line in enumerate(lines, 1):
        stripped = line.strip()

        if ext == ".py":
            m = re.match(r"def\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", stripped)
            if m:
                current_func = m.group(1)
        if ext in MD_EXTS and stripped.startswith("```"):
            in_code = not in_code
            continue
        if ext in MD_EXTS and stripped.startswith("#"):
            current_heading = stripped.lstrip("#").strip()
            continue

        if ext == ".py" and (stripped.startswith(("#", '"regex":', '"risk":', '"fix":', '"category":', '"severity":', '"pattern":')) or is_python_rule_line(stripped)):
            continue
        if ext in {".js", ".ts", ".mjs", ".cjs", ".jsx", ".tsx"} and stripped.startswith("//"):
            continue
        if ext in MD_EXTS and is_doc_example(line, in_code, current_heading):
            continue
        if ext == ".py" and current_func == "safe_rmtree" and "shutil.rmtree(" in stripped:
            continue
        if ext == ".py" and ('"shutil.rmtree("' in line or "'shutil.rmtree('" in line):
            continue

        for regex, sev, cat, detail, remediation in PATTERNS:
            if re.search(regex, line):
                findings.append(Finding(sev, cat, str(path), idx, detail, remediation))
        for regex, sev, cat, detail, remediation in SECRET_PATTERNS:
            if re.search(regex, line):
                findings.append(Finding(sev, cat, str(path), idx, detail, remediation))
        if ext in MD_EXTS:
            for regex, sev, cat, detail, remediation in PROMPT_PATTERNS:
                if re.search(regex, line):
                    findings.append(Finding(sev, cat, str(path), idx, detail, remediation))


def scan_structure(root: Path, findings: List[Finding]):
    for p in iter_files(root):
        name = p.name
        if p.is_symlink():
            findings.append(Finding("HIGH", "SYMLINK", str(p), 0, "symlink present", "Remove symlinks from distributable skill/repo"))
        if name == ".env":
            findings.append(Finding("CRITICAL", "SECRET", str(p), 0, ".env file included", "Remove secrets from repo/skill package"))
        if name.startswith(".") and name not in {".gitignore", ".editorconfig", ".prettierrc", ".eslintrc", ".flake8"}:
            findings.append(Finding("WARN", "HIDDEN", str(p), 0, f"hidden file present: {name}", "Review whether this hidden file should ship"))


def run_deep_tools(root: Path, findings: List[Finding]) -> List[str]:
    used = []
    tools = {
        "semgrep": ["semgrep", "scan", "--quiet", "--config=auto", str(root)],
        "bandit": ["bandit", "-q", "-r", str(root)],
        "gitleaks": ["gitleaks", "detect", "--no-git", "--source", str(root)],
        "trivy": ["trivy", "fs", "--quiet", str(root)],
    }
    for name, cmd in tools.items():
        if not shutil.which(name):
            continue
        used.append(name)
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
            if proc.returncode not in (0,):
                out = (proc.stdout + "\n" + proc.stderr).strip()
                snippet = out.splitlines()[:8]
                findings.append(Finding("WARN", f"DEEP-{name.upper()}", str(root), 0, f"{name} reported issues", "Review deep scanner output: " + " | ".join(snippet)[:400]))
        except Exception as e:
            findings.append(Finding("WARN", f"DEEP-{name.upper()}", str(root), 0, f"{name} execution failed: {e}", "Verify tool installation or run manually"))
    return used


def verdict_for(findings: List[Finding], strict: bool) -> str:
    has_critical = any(f.severity == "CRITICAL" for f in findings)
    has_high = any(f.severity == "HIGH" for f in findings)
    has_warn = any(f.severity == "WARN" for f in findings)
    if has_critical:
        return "FAIL"
    if has_high:
        return "WARN" if not strict else "FAIL"
    if has_warn:
        return "WARN" if not strict else "FAIL"
    return "PASS"


def print_report(report: Report):
    print(f"Verdict: {report.verdict}")
    if report.deep_tools:
        print("Deep tools: " + ", ".join(report.deep_tools))
    if not report.findings:
        print("No meaningful issues found.")
        return
    for f in sorted(report.findings, key=lambda x: -SEV[x.severity]):
        loc = f"{f.file}:{f.line}" if f.line else f.file
        print(f"[{f.severity}] {f.category} {loc}")
        print(f"- {f.detail}")
        print(f"- Fix: {f.remediation}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("target")
    ap.add_argument("--json", action="store_true", dest="json_output")
    ap.add_argument("--strict", action="store_true")
    args = ap.parse_args()

    cleanup = None
    try:
        root, cleanup = clone_if_repo(args.target)
        if not root.exists() or not root.is_dir():
            print(f"Target not found or not a directory: {root}", file=sys.stderr)
            sys.exit(1)

        findings: List[Finding] = []
        for p in iter_files(root):
            if p.suffix.lower() in TEXT_EXTS:
                scan_text_file(p, findings)
        scan_structure(root, findings)
        deep = run_deep_tools(root, findings)
        report = Report(str(root), verdict_for(findings, args.strict), findings, deep)

        if args.json_output:
            print(json.dumps(report.to_dict(), indent=2))
        else:
            print_report(report)

        sys.exit(0 if report.verdict == "PASS" else 2 if report.verdict == "WARN" else 1)
    finally:
        if cleanup:
            safe_rmtree(cleanup)


if __name__ == "__main__":
    main()
