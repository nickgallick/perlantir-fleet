#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/retention-plan.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Retention Plan: $PRODUCT

- Recurring value:
- Return triggers:
- Churn risks:
- Best retention improvements:
MD

echo "$OUT"
