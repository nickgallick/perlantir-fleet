#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/validation-plan.md}"
PRODUCT="${2:-product}"
cat > "$OUT" <<MD
# Validation Plan: $PRODUCT

## Evidence to gather
- complaint evidence
- buyer conversations
- alternative dissatisfaction
- willingness-to-pay signals

## Fast validation tactics
- landing page
- waitlist
- concierge workflow
- outreach to likely users

## Build decision
- what would convince us to build?
- what would make us drop or refine it?
MD

echo "$OUT"
