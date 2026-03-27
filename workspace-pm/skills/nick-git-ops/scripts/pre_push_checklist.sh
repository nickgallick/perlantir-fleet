#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/pre-push-checklist.md}"
cat > "$OUT" <<'MD'
# Pre-Push Checklist

- Correct repo confirmed
- Correct branch confirmed
- Working tree reviewed
- Staged changes reviewed
- Conventional commit message used
- No secrets or .env files included
- Push target understood
- Merge/rebase implications understood
MD

echo "$OUT"
