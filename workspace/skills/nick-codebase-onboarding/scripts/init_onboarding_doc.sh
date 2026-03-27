#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/codebase-onboarding.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# Codebase Onboarding: $PROJECT

## Project Summary
- Purpose:
- Users:
- Current state:

## Start Here
- Install:
- Run:
- Test:
- First route/page to open:

## Key Files And Folders
- 

## Main Flows
- 

## Risks / Stale Areas
- 

## First Things To Test
- 

## First Safe Edits
- 
MD

echo "$OUT"
