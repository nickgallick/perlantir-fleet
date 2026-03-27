#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/supabase-task-brief.md}"
TASK="${2:-supabase-task}"
cat > "$OUT" <<MD
# Supabase Task Brief: $TASK

## Goal
- 

## Surface area
- Query / Auth / RLS / Storage / Realtime / Edge Function / Migration

## Roles involved
- 

## Recommended pattern
- 

## Auth/RLS implications
- 

## Common failure points
- 

## Deprecated patterns to avoid
- 
MD

echo "$OUT"
