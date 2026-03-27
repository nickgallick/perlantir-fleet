#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/post-deploy-checklist.md}"
URL="${2:-https://example.com}"
cat > "$OUT" <<MD
# Post-Deploy Checklist

- Live URL: $URL
- Homepage loads
- Main CTA works
- Auth flow smoke tested
- Core feature smoke tested
- Console errors checked
- Mobile spot-check done
- Memory updated with URL and decisions
- Next logical improvements suggested
MD

echo "$OUT"
