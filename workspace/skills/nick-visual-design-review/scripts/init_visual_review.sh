#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/visual-review.md}"
URL="${2:-https://example.com}"
cat > "$OUT" <<MD
# Visual Review

## URL
- $URL

## Overall verdict
- 

## Strong
- 

## Weak / generic
- 

## Desktop issues
- 

## Mobile issues
- 

## Specific fixes
- 

## Screenshots
- 
MD

echo "$OUT"
