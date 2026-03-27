#!/usr/bin/env python3
"""
Unicode Steganography Scanner
Detects hidden payloads in source code using invisible Unicode characters.
Catches GlassWorm, PhantomRaven, CanisterWorm family of attacks.

Usage:
    python3 scan_unicode.py <path> [--strict] [--json] [--decode]
    
    path:     File or directory to scan
    --strict: Include Tier 2 (suspicious) characters in addition to Tier 1
    --json:   Output as JSON
    --decode: Attempt to decode Tags block payloads and print hidden content
"""

import os
import sys
import json as json_mod
import argparse
import unicodedata
from pathlib import Path
from typing import NamedTuple

# ─── Dangerous Unicode Ranges ───────────────────────────────────────────────

TIER1_RANGES = [
    (0xE0000, 0xE007F, "Tags block (ASCII steganography)"),
    (0xF0000, 0xFFFFF, "Supplementary Private Use Area-A"),
    (0x100000, 0x10FFFF, "Supplementary Private Use Area-B"),
]

TIER2_RANGES = [
    (0x200B, 0x200B, "Zero-Width Space"),
    (0x200C, 0x200D, "Zero-Width Non-Joiner/Joiner"),
    (0x200E, 0x200F, "LTR/RTL Mark"),
    (0x202A, 0x202E, "Bidi Overrides (Trojan Source)"),
    (0x2060, 0x2064, "Word Joiner / Invisible Operators"),
    (0x2066, 0x2069, "Bidi Isolates (Trojan Source)"),
    (0x2028, 0x2029, "Line/Paragraph Separator"),
    (0x00AD, 0x00AD, "Soft Hyphen"),
    (0x034F, 0x034F, "Combining Grapheme Joiner"),
    (0x061C, 0x061C, "Arabic Letter Mark"),
    (0xFE00, 0xFE0F, "Variation Selectors"),
    (0xFEFF, 0xFEFF, "BOM/ZWNBSP (suspicious if not at byte 0)"),
    (0xE0100, 0xE01EF, "Variation Selectors Supplement"),
]

EXECUTION_KEYWORDS = [
    "exec(", "eval(", "compile(", "FunctionType(", "new Function(",
    "subprocess", "os.system(", "os.popen(", "child_process",
    "import(", "require(", "__import__(", "getattr(",
    "setattr(", "globals()", "locals()",
]

SUPPRESSION_PATTERNS = [
    "except: pass", "except:", "catch(e) {}", "catch(e){}", "catch {",
    "catch(err){}", "catch(error){}", ".catch(() =>", ".catch(()=>",
]

# ─── Types ───────────────────────────────────────────────────────────────────

class Finding(NamedTuple):
    file: str
    line: int
    tier: int
    range_name: str
    char_count: int
    codepoints: list
    has_exec_nearby: bool
    has_suppression_nearby: bool
    decoded_payload: str  # Tags block decode attempt

# ─── Scanning Logic ─────────────────────────────────────────────────────────

BINARY_EXTENSIONS = {
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.svg',
    '.woff', '.woff2', '.ttf', '.eot', '.otf',
    '.zip', '.gz', '.tar', '.bz2', '.7z', '.rar',
    '.pdf', '.doc', '.docx', '.xls', '.xlsx',
    '.exe', '.dll', '.so', '.dylib', '.bin',
    '.mp3', '.mp4', '.avi', '.mov', '.wav',
    '.pyc', '.pyo', '.class', '.o', '.obj',
    '.lock',  # package-lock.json etc.
}

SKIP_DIRS = {
    'node_modules', '.git', '.next', '__pycache__', 'dist', 'build',
    '.venv', 'venv', '.cache', '.turbo',
}

# ─── Homoglyph Detection ────────────────────────────────────────────────────

# Common Cyrillic confusables for Latin characters
CONFUSABLES = {
    0x0430: 'a',  # Cyrillic а
    0x0441: 'c',  # Cyrillic с
    0x0435: 'e',  # Cyrillic е
    0x043E: 'o',  # Cyrillic о
    0x0440: 'p',  # Cyrillic р
    0x0445: 'x',  # Cyrillic х
    0x0443: 'y',  # Cyrillic у
    0x0410: 'A',  # Cyrillic А
    0x0412: 'B',  # Cyrillic В
    0x0421: 'C',  # Cyrillic С
    0x0415: 'E',  # Cyrillic Е
    0x041D: 'H',  # Cyrillic Н
    0x041A: 'K',  # Cyrillic К
    0x041C: 'M',  # Cyrillic М
    0x041E: 'O',  # Cyrillic О
    0x0420: 'P',  # Cyrillic Р
    0x0422: 'T',  # Cyrillic Т
    0x0425: 'X',  # Cyrillic Х
    0x212F: 'e',  # Math script ℯ
    0x1D4CD: 'x', # Math script 𝓍
}

CODE_EXTENSIONS = {'.py', '.js', '.ts', '.jsx', '.tsx', '.mjs', '.cjs'}

import re
IDENTIFIER_RE = re.compile(r'\b[A-Za-z_\u0080-\uffff][A-Za-z0-9_\u0080-\uffff]*\b')


def scan_homoglyphs(filepath: str) -> list:
    """Scan a file for homoglyph characters in identifiers."""
    findings = []
    ext = Path(filepath).suffix.lower()
    if ext not in CODE_EXTENSIONS:
        return findings
    
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except (OSError, PermissionError):
        return findings
    
    for line_idx, line in enumerate(lines):
        # Skip comments and strings (rough heuristic)
        stripped = line.strip()
        if stripped.startswith('#') or stripped.startswith('//'):
            continue
        
        for match in IDENTIFIER_RE.finditer(line):
            ident = match.group()
            confusable_chars = []
            for ch in ident:
                cp = ord(ch)
                if cp in CONFUSABLES:
                    confusable_chars.append((ch, cp, CONFUSABLES[cp]))
            
            if confusable_chars:
                findings.append(Finding(
                    file=filepath,
                    line=line_idx + 1,
                    tier=1,
                    range_name=f"Homoglyph in identifier '{ident}'",
                    char_count=len(confusable_chars),
                    codepoints=[f"U+{cp:04X} (looks like '{latin}')" for _, cp, latin in confusable_chars],
                    has_exec_nearby=False,
                    has_suppression_nearby=False,
                    decoded_payload=f"Identifier '{ident}' contains non-Latin chars that mimic Latin",
                ))
    
    return findings


def classify_char(cp: int, strict: bool):
    """Classify a codepoint into tier 1, tier 2, or None."""
    for start, end, name in TIER1_RANGES:
        if start <= cp <= end:
            return 1, name
    if strict:
        for start, end, name in TIER2_RANGES:
            if start <= cp <= end:
                return 2, name
    return None, None


def check_context(lines: list, line_idx: int, window: int = 20):
    """Check surrounding lines for execution functions and error suppression."""
    start = max(0, line_idx - window)
    end = min(len(lines), line_idx + window + 1)
    context = '\n'.join(lines[start:end]).lower()
    
    has_exec = any(kw.lower() in context for kw in EXECUTION_KEYWORDS)
    has_suppress = any(pat.lower() in context for pat in SUPPRESSION_PATTERNS)
    return has_exec, has_suppress


def decode_tags(text: str) -> str:
    """Decode Tags block characters to ASCII."""
    tags = [ch for ch in text if 0xE0000 <= ord(ch) <= 0xE007F]
    if not tags:
        return ""
    return ''.join(chr(ord(ch) - 0xE0000) for ch in tags)


def scan_file(filepath: str, strict: bool) -> list:
    """Scan a single file for Unicode steganography."""
    findings = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except (OSError, PermissionError):
        return findings
    
    for line_idx, line in enumerate(lines):
        chars_by_range = {}
        
        for ch in line:
            cp = ord(ch)
            tier, range_name = classify_char(cp, strict)
            if tier is not None:
                # Special case: BOM at start of file is legitimate
                if cp == 0xFEFF and line_idx == 0 and line.index(ch) == 0:
                    continue
                key = (tier, range_name)
                if key not in chars_by_range:
                    chars_by_range[key] = []
                chars_by_range[key].append(cp)
        
        for (tier, range_name), codepoints in chars_by_range.items():
            has_exec, has_suppress = check_context(lines, line_idx)
            decoded = decode_tags(line) if tier == 1 and "Tags" in range_name else ""
            
            findings.append(Finding(
                file=filepath,
                line=line_idx + 1,
                tier=tier,
                range_name=range_name,
                char_count=len(codepoints),
                codepoints=[hex(cp) for cp in codepoints[:10]],  # Cap at 10 for display
                has_exec_nearby=has_exec,
                has_suppression_nearby=has_suppress,
                decoded_payload=decoded,
            ))
    
    return findings


def scan_path(path: str, strict: bool) -> list:
    """Scan a file or directory recursively."""
    findings = []
    p = Path(path)
    
    if p.is_file():
        findings.extend(scan_file(str(p), strict))
        if strict:
            findings.extend(scan_homoglyphs(str(p)))
        return findings
    
    for root, dirs, files in os.walk(p):
        # Skip binary/cache directories
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        
        for fname in files:
            fpath = os.path.join(root, fname)
            ext = Path(fname).suffix.lower()
            if ext in BINARY_EXTENSIONS:
                continue
            findings.extend(scan_file(fpath, strict))
            if strict:
                findings.extend(scan_homoglyphs(fpath))
    
    return findings

# ─── Output Formatting ──────────────────────────────────────────────────────

SEVERITY_COLORS = {
    "CRITICAL": "\033[91m",  # Red
    "HIGH": "\033[93m",      # Yellow
    "MEDIUM": "\033[33m",    # Orange
    "LOW": "\033[36m",       # Cyan
}
RESET = "\033[0m"


def severity(finding: Finding) -> str:
    if finding.tier == 1 and finding.has_exec_nearby:
        return "CRITICAL"
    if finding.tier == 1:
        return "HIGH"
    if finding.tier == 2 and finding.has_exec_nearby:
        return "HIGH"
    if finding.tier == 2 and finding.has_suppression_nearby:
        return "MEDIUM"
    return "LOW"


def print_findings(findings: list, as_json: bool, decode: bool):
    if not findings:
        print("✅ No Unicode steganography detected.")
        return
    
    if as_json:
        output = []
        for f in findings:
            output.append({
                "file": f.file,
                "line": f.line,
                "tier": f.tier,
                "range": f.range_name,
                "count": f.char_count,
                "codepoints": f.codepoints,
                "severity": severity(f),
                "exec_nearby": f.has_exec_nearby,
                "suppression_nearby": f.has_suppression_nearby,
                "decoded": f.decoded_payload if decode else None,
            })
        print(json_mod.dumps(output, indent=2))
        return
    
    # Group by severity
    by_severity = {"CRITICAL": [], "HIGH": [], "MEDIUM": [], "LOW": []}
    for f in findings:
        by_severity[severity(f)].append(f)
    
    total = len(findings)
    critical = len(by_severity["CRITICAL"])
    high = len(by_severity["HIGH"])
    
    print(f"\n🔍 Unicode Steganography Scan Results")
    print(f"{'='*60}")
    print(f"Total findings: {total}")
    print(f"  CRITICAL: {critical}  |  HIGH: {high}  |  MEDIUM: {len(by_severity['MEDIUM'])}  |  LOW: {len(by_severity['LOW'])}")
    print(f"{'='*60}\n")
    
    for sev in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
        if not by_severity[sev]:
            continue
        color = SEVERITY_COLORS[sev]
        print(f"{color}── {sev} ──{RESET}")
        for f in by_severity[sev]:
            print(f"  {f.file}:{f.line}")
            print(f"    Range: {f.range_name} ({f.char_count} chars)")
            print(f"    Codepoints: {', '.join(f.codepoints[:5])}{'...' if len(f.codepoints) > 5 else ''}")
            if f.has_exec_nearby:
                print(f"    ⚠️  Execution function within 20 lines!")
            if f.has_suppression_nearby:
                print(f"    ⚠️  Silent error suppression nearby!")
            if decode and f.decoded_payload:
                print(f"    🔓 Decoded payload: {repr(f.decoded_payload[:200])}")
            print()
    
    if critical > 0 or high > 0:
        print(f"\n{SEVERITY_COLORS['CRITICAL']}⛔ VERDICT: BLOCKED — Hidden payloads detected in source code{RESET}")
    else:
        print(f"\n⚠️  VERDICT: WARNINGS — Suspicious Unicode found, manual review recommended")


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Unicode Steganography Scanner")
    parser.add_argument("path", help="File or directory to scan")
    parser.add_argument("--strict", action="store_true", help="Include Tier 2 suspicious characters")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--decode", action="store_true", help="Decode Tags block payloads")
    args = parser.parse_args()
    
    if not os.path.exists(args.path):
        print(f"Error: Path not found: {args.path}", file=sys.stderr)
        sys.exit(1)
    
    findings = scan_path(args.path, args.strict)
    print_findings(findings, args.json, args.decode)
    
    # Exit code: 2 for critical/high, 1 for medium/low, 0 for clean
    if any(severity(f) in ("CRITICAL", "HIGH") for f in findings):
        sys.exit(2)
    elif findings:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
