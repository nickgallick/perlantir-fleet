#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/offer-brief.md}"
OFFER="${2:-offer}"
cat > "$OUT" <<MD
# Offer Brief: $OFFER

- Buyer:
- Pain:
- Promise:
- Package:
- Price:
- Guarantee:
- CTA:
MD

echo "$OUT"
