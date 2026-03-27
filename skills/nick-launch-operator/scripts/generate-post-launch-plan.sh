#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/post-launch-plan.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Post-Launch Plan: $PRODUCT

## First 7 days
- 

## Metrics to watch
- 

## Fast iteration priorities
- 
MD

echo "$OUT"
