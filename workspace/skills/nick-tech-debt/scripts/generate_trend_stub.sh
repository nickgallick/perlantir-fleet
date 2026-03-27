#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/tech-debt-trend.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# Tech Debt Trend: $PROJECT

## Improved since last scan
- 

## Worse since last scan
- 

## New debt introduced
- 

## Same recurring hotspots
- 
MD

echo "$OUT"
