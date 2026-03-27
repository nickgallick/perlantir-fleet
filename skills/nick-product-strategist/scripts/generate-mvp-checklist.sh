#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/mvp-checklist.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# MVP Checklist: $PRODUCT

- single clear user
- single painful workflow
- trust-worthy UI
- core action works end-to-end
- ability to collect feedback
- clear monetization hypothesis
- no unnecessary feature sprawl
MD

echo "$OUT"
