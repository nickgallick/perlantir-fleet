#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/refactor-plan.md}"
AREA="${2:-area}"
cat > "$OUT" <<MD
# Refactor Plan: $AREA

- Problem:
- Blast radius:
- Phases:
- Risks:
- Validation:
MD

echo "$OUT"
