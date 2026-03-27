#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/feature-checklist.md}"
FEATURE="${2:-feature}"
cat > "$OUT" <<MD
# Feature Checklist: $FEATURE

- User goal is clear
- UI entry point exists
- Happy path works
- Validation exists
- Error state exists
- Empty state exists
- Loading state exists
- Mobile responsive
- Accessibility basics checked
- Data persistence verified
- Live QA after deploy
MD

echo "$OUT"
