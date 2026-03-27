#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/policy-test-checklist.md}"
TABLE="${2:-table_name}"
cat > "$OUT" <<MD
# Policy Test Checklist: $TABLE

## Anonymous
- SELECT:
- INSERT:
- UPDATE:
- DELETE:

## Authenticated non-member
- SELECT:
- INSERT:
- UPDATE:
- DELETE:

## Valid member/owner/admin
- SELECT:
- INSERT:
- UPDATE:
- DELETE:

## Cross-tenant isolation
- Attempt to read another tenant's row:
- Attempt to modify another tenant's row:

## Bootstrap edge cases
- Missing profile/membership row behavior:
MD

echo "$OUT"
