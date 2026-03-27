#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/pricing-brief.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Pricing Brief: $PRODUCT

- Buyer:
- Value metric:
- Model:
- Tiers:
- Risks:
MD

echo "$OUT"
