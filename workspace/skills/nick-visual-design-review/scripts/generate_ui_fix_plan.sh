#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/ui-fix-plan.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# UI Fix Plan: $PROJECT

## Highest-impact visual fixes
- 

## UX fixes
- 

## Mobile fixes
- 

## Conversion/trust fixes
- 

## Polish upgrades
- 
MD

echo "$OUT"
