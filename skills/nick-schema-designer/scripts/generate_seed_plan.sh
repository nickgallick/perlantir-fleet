#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/seed-plan.md}"
APP_NAME="${2:-app}"
cat > "$OUT" <<MD
# Seed Plan: $APP_NAME

## Required users
- admin / owner:
- standard user:
- edge-case user:

## Required entities
- 

## Required relationships
- 

## Scenarios to support
- happy path
- empty state
- filtered/sorted state
- permission boundary state
- error-prone state

## Notes
- include realistic names/content
- include enough rows to test dashboards and lists
MD

echo "$OUT"
