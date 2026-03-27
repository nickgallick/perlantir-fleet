#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/auth-matrix.md}"
ROUTE="${2:-/api/example}"
cat > "$OUT" <<MD
# Auth Matrix: $ROUTE

- No auth header
- Invalid auth token
- Valid auth, wrong role
- Valid auth, correct role
- Public access expected? If yes, document it
MD

echo "$OUT"
