#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/event-plan.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Event Plan: $PRODUCT

- core events:
- activation event:
- retention events:
- conversion event:
MD

echo "$OUT"
