#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/ux-upgrade-plan.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# UX Upgrade Plan: $PROJECT

## Highest-impact fixes
- 

## Design polish upgrades
- 

## UX clarity improvements
- 

## Trust/conversion improvements
- 

## Mobile improvements
- 
MD

echo "$OUT"
