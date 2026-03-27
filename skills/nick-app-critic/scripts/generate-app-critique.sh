#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/app-critique.md}"
TARGET="${2:-app}"
cat > "$OUT" <<MD
# App Critique: $TARGET

## Biggest risks
- 

## Why users may bounce
- 

## Trust issues
- 

## Activation issues
- 

## Highest-value fixes
- 
MD

echo "$OUT"
