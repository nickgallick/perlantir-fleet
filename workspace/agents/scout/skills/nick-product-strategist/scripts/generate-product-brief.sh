#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/product-brief.md}"
IDEA="${2:-product idea}"
cat > "$OUT" <<MD
# Product Brief: $IDEA

## Problem
- 

## Buyer / ICP
- 

## Why this matters
- 

## Alternatives today
- 

## Gap / angle
- 

## Monetization
- 

## MVP scope
- 

## Validation plan
- 

## Risks
- 

## Recommendation
- 
MD

echo "$OUT"
