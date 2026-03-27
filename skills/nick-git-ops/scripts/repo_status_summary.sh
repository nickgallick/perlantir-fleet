#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/Projects}"
find "$ROOT" -maxdepth 2 -type d -name .git | while read -r gitdir; do
  repo="$(dirname "$gitdir")"
  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  status="$(git -C "$repo" status --short 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$status" = "0" ]; then
    echo "CLEAN  | $branch | $repo"
  else
    echo "DIRTY($status) | $branch | $repo"
  fi
done
