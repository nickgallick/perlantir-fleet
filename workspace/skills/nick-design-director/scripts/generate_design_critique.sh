#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/design-critique.md}"
SCREEN="${2:-screen}"
cat > "$OUT" <<MD
# Design Critique: $SCREEN

## What feels strong
- 

## What feels generic or weak
- 

## Hierarchy issues
- 

## Spacing/composition issues
- 

## UX issues
- 

## Specific upgrades
- 
MD

echo "$OUT"
