#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/hotspot-checklist.md}"
AREA="${2:-auth flow}"
cat > "$OUT" <<MD
# Hotspot Checklist: $AREA

- Large/complex file?
- Duplicated logic?
- Weak validation?
- Weak test coverage?
- Hard to understand quickly?
- Touching this area feels risky?
- Clear refactor boundary exists?
MD

echo "$OUT"
