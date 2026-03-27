#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/rls-review-checklist.md}"
cat > "$OUT" <<'MD'
# RLS Review Checklist

- Every user-facing table has RLS enabled
- Select/insert/update/delete rules are explicit
- Bootstrap/profile/membership edge cases are considered
- Cross-tenant access is blocked
- Non-admin user tests are planned
- Plain-English explanation exists alongside policy SQL
MD

echo "$OUT"
