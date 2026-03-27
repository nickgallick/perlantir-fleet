#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/upgrade-plan.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# Upgrade Plan: $PROJECT

## Deploy blockers
- 

## Safe upgrades
- Patch:
- Minor:

## Risky upgrades
- Major:
- Why risky:

## License issues
- 

## Validation after upgrades
- lint
- tests
- build
- browser smoke / QA
MD

echo "$OUT"
