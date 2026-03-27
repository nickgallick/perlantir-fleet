#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/auth-flow-checklist.md}"
cat > "$OUT" <<'MD'
# Auth Flow Checklist

- Signup works
- Login works
- Logout works
- Password reset works
- Session persists correctly
- Protected routes behave correctly
- Profile/bootstrap row is created if needed
- Role/default membership is created if needed
- Auth errors are understandable
MD

echo "$OUT"
