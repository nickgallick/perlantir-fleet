#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/tech-debt-report.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# Tech Debt Report: $PROJECT

## Summary
- 

## Blockers
- 

## Slows shipping
- 

## Cleanup later
- 

## Hotspots
- 

## Missing test coverage
- 

## Quick wins
- 

## Trend vs last scan
- 

## Recommended next fixes
- 
MD

echo "$OUT"
