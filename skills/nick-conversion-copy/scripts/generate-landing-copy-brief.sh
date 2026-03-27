#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/landing-copy-brief.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Landing Copy Brief: $PRODUCT

- ICP:
- Pain:
- Promise:
- CTA:
- Trust cues:
MD

echo "$OUT"
