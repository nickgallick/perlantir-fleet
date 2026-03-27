#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/onboarding-audit.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Onboarding Audit: $PRODUCT

- Friction points:
- Activation blockers:
- Empty-state issues:
- Best fixes:
MD

echo "$OUT"
