#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/tmp/ai-feature-brief.md}"
FEATURE="${2:-ai-feature}"
cat > "$OUT" <<MD
# AI Feature Brief: $FEATURE

- User problem:
- Why AI helps:
- UX pattern:
- Human review/fallback:
- Risks:
MD

echo "$OUT"
