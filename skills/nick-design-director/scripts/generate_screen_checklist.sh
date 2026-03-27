#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/screen-checklist.md}"
SCREEN="${2:-screen}"
cat > "$OUT" <<MD
# Screen Checklist: $SCREEN

- strong visual hierarchy
- clear CTA
- spacing feels intentional
- typography feels premium
- loading/empty/error states considered
- mobile experience considered
- trust cues present if needed
- does not feel like a default template
MD

echo "$OUT"
