#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/release-go-no-go.md}"
cat > "$OUT" <<'MD'
# Release Go / No-Go

- Core flow stable?
- Any critical bugs?
- Any major trust issues?
- Data/security concerns?
- Recommendation:
MD

echo "$OUT"
