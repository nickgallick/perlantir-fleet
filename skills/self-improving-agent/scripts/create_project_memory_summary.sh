#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/.openclaw/workspace}"
PROJECT_NAME="${2:-unnamed-project}"
OUT="$ROOT/memory/${PROJECT_NAME}-summary.md"

cat > "$OUT" <<'MD'
## Project
- Name:
- Path:
- Live URL:
- Goal:

## Tech Decisions
- Stack:
- Auth/data:
- Deployment:

## Repeated Patterns
- What keeps working:
- What keeps breaking:
- What to avoid next time:

## Open Items
- Follow-ups:
- Risks:
- Next likely steps:
MD

echo "$OUT"
