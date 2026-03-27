#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/.openclaw/workspace}"
MEMORY_FILE="$ROOT/MEMORY.md"
DAILY_DIR="$ROOT/memory"
mkdir -p "$DAILY_DIR"

if [ ! -f "$MEMORY_FILE" ] || [ ! -s "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" <<'MD'
## Preferences

## Startup Ideas / Opportunity Criteria

## Product Decisions

## Deployment Patterns

## Recurring Bugs And Fixes

## Skill Inventory / Overlap Notes

## Workflow Habits
MD
fi

echo "$MEMORY_FILE"
