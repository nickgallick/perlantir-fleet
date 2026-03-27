#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/cta-options.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# CTA Options: $PRODUCT

- Start free
- See it in action
- Join the waitlist
- Get early access
- Try the demo
MD

echo "$OUT"
