#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/endpoint-checklist.md}"
cat > "$OUT" <<'MD'
# Endpoint Coverage Checklist

- Route discovered
- Methods identified
- Happy path covered
- Auth path covered
- Missing input covered
- Malformed input covered
- Unsupported method covered
- Error response shape checked
MD

echo "$OUT"
