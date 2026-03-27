#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/bug-triage.md}"
cat > "$OUT" <<'MD'
# Bug Triage

- Severity:
- Title:
- Repro:
- Expected:
- Actual:
- Risk:
- Fix priority:
MD

echo "$OUT"
