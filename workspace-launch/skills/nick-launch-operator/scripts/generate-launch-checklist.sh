#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/launch-checklist.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Launch Checklist: $PRODUCT

- live URL confirmed
- analytics installed
- onboarding tested
- waitlist/email capture decided
- feedback path exists
- trust/copy pass done
- first-week metrics defined
MD

echo "$OUT"
