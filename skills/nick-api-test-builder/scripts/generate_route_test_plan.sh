#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/route-test-plan.md}"
ROUTE="${2:-/api/example}"
cat > "$OUT" <<MD
# Route Test Plan: $ROUTE

## Methods
- 

## Auth assumptions
- 

## Happy path tests
- 

## Unauthenticated tests
- 

## Malformed/missing input tests
- 

## Unsupported method tests
- 
MD

echo "$OUT"
