#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/pipeline-notes.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# CI/CD Notes: $PROJECT

## Stack
- Next.js
- Supabase
- Vercel
- Playwright

## Required commands
- lint:
- test:
- test:e2e:
- build:

## Deploy rule
- deploy only after green lint/test/playwright/build

## Missing pieces to fill
- exact deploy command
- secret names/values in CI settings
- app URL for browser tests
MD

echo "$OUT"
