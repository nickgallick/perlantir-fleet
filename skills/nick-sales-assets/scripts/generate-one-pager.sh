#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/one-pager.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# One Pager: $PRODUCT

- Problem:
- Buyer:
- Solution:
- Value:
- Proof:
- CTA:
MD

echo "$OUT"
