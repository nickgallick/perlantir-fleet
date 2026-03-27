#!/usr/bin/env python3
import os
import re
import sys
import math
import subprocess
from pathlib import Path

PATTERNS = [
    ("OpenAI key", re.compile(r"\bsk-[A-Za-z0-9]{20,}\b")),
    ("GitHub token", re.compile(r"\bghp_[A-Za-z0-9]{20,}\b")),
    ("Slack token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b")),
    ("Stripe secret", re.compile(r"\bsk_(live|test)_[A-Za-z0-9]{16,}\b")),
    ("Private key", re.compile(r"-----BEGIN (RSA |EC |OPENSSH |DSA |)?PRIVATE KEY-----")),
    ("Database URL", re.compile(r"\b(postgres|postgresql|mysql|mongodb(?:\+srv)?):\/\/[^\s]+:[^\s]+@[^\s]+\b")),
    ("Supabase service role", re.compile(r"\bSUPABASE_SERVICE_ROLE_KEY\s*=\s*.+")),
    ("OpenAI env", re.compile(r"\bOPENAI_API_KEY\s*=\s*.+")),
    ("Anthropic env", re.compile(r"\bANTHROPIC_API_KEY\s*=\s*.+")),
    ("Stripe env", re.compile(r"\bSTRIPE_SECRET_KEY\s*=\s*.+")),
]

TEXT_EXTS = {'.py','.js','.ts','.tsx','.jsx','.json','.env','.md','.txt','.yaml','.yml','.toml','.ini','.sh'}
SKIP_DIRS = {'.git','node_modules','.next','dist','build','coverage','__pycache__'}
MAX_FILE_SIZE = 1024 * 1024


def redacted(value: str) -> str:
    value = value.strip()
    if len(value) <= 10:
        return value[:2] + '***'
    return value[:4] + '***' + value[-4:]


def entropy(s: str) -> float:
    if not s:
        return 0.0
    probs = [s.count(c) / len(s) for c in set(s)]
    return -sum(p * math.log2(p) for p in probs)


def iter_files(root: Path):
    for p in root.rglob('*'):
        if any(part in SKIP_DIRS for part in p.parts):
            continue
        if p.is_file():
            yield p


def scan_file(path: Path, findings):
    if path.stat().st_size > MAX_FILE_SIZE:
        return
    if path.suffix.lower() not in TEXT_EXTS and path.name not in {'.env', '.env.local', '.env.production', '.env.development'}:
        return
    try:
        text = path.read_text(encoding='utf-8', errors='replace')
    except Exception:
        return
    for i, line in enumerate(text.splitlines(), 1):
        for name, pattern in PATTERNS:
            m = pattern.search(line)
            if m:
                findings.append(("HIGH", name, str(path), i, redacted(m.group(0))))
        # generic long quoted/base64-ish tokens near key names
        if any(k in line.lower() for k in ['key', 'token', 'secret', 'password']):
            chunks = re.findall(r"['\"]([A-Za-z0-9_\-]{24,})['\"]", line)
            for c in chunks:
                if entropy(c) >= 3.5:
                    findings.append(("WARN", "High-entropy credential-like string", str(path), i, redacted(c)))


def scan_git_history(root: Path, findings):
    try:
        revs = subprocess.check_output(['git', '-C', str(root), 'rev-list', '--all'], text=True, stderr=subprocess.DEVNULL).splitlines()
    except Exception:
        return
    for rev in revs[:200]:  # practical cap
        try:
            out = subprocess.check_output(['git', '-C', str(root), 'grep', '-nI', '-E', 'sk-|ghp_|xox|PRIVATE KEY|DATABASE_URL=|SUPABASE_SERVICE_ROLE_KEY=|OPENAI_API_KEY=|ANTHROPIC_API_KEY=|STRIPE_SECRET_KEY=', rev], text=True, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            continue
        except Exception:
            continue
        for line in out.splitlines():
            findings.append(("HIGH", "History match", f"commit:{rev[:12]}", 0, redacted(line[:120])))


def main():
    target = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
    findings = []
    scan_git_history(target, findings)
    for p in iter_files(target):
        scan_file(p, findings)

    if not findings:
        print('PASS: no likely secrets found')
        sys.exit(0)

    print('FAIL: likely secrets found')
    for sev, kind, file, line, preview in findings:
        loc = f'{file}:{line}' if line else file
        print(f'[{sev}] {kind} | {loc} | {preview}')
    sys.exit(1)


if __name__ == '__main__':
    main()
