#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/admin-audit.md}"
PRODUCT="${2:-admin}"
cat > "$OUT" <<MD
# Admin Audit: $PRODUCT

- Workflow friction:
- Table/filter issues:
- Bulk action gaps:
- Operator UX fixes:
MD

echo "$OUT"
