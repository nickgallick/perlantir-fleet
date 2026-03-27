#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/funnel-checklist.md}"
cat > "$OUT" <<'MD'
# Funnel Checklist

- acquisition event defined
- signup tracked
- activation tracked
- drop-off points visible
- conversion tracked
MD

echo "$OUT"
