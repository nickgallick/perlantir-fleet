#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/architecture-decision.md}"
TOPIC="${2:-architecture-decision}"
cat > "$OUT" <<MD
# Architecture Decision: $TOPIC

## Context
- 

## Decision
- 

## Why
- 

## Alternatives considered
- 

## Risks
- 

## Follow-up actions
- 
MD

echo "$OUT"
