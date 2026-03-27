#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/style-brief.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Style Brief: $PRODUCT

- vibe:
- trust level:
- color approach:
- typography approach:
MD

echo "$OUT"
