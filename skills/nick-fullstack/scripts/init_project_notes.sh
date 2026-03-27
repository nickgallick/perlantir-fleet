#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-/tmp}"
NAME="${2:-new-project}"
OUT="$OUT_DIR/${NAME}-project-notes.md"
cat > "$OUT" <<'MD'
# Project Notes

## Product
- Name:
- Goal:
- Users:
- Core flow:

## Stack
- Next.js App Router
- Tailwind CSS
- shadcn/ui
- Supabase
- Vercel

## Data/Auth
- Main entities:
- Auth roles:
- Key flows:

## Build Plan
- MVP:
- Risks:
- Follow-ups:
MD

echo "$OUT"
