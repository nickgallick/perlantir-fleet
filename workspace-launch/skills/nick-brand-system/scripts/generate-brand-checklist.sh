#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/brand-checklist.md}"
cat > "$OUT" <<'MD'
# Brand Checklist

- color usage is disciplined
- typography is consistent
- UI feels recognizable
- trust cues are consistent
MD

echo "$OUT"
