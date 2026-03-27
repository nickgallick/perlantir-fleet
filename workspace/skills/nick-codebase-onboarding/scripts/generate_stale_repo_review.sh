#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/stale-repo-review.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# Stale Repo Review: $PROJECT

## Revalidate first
- install/build works
- env vars still valid
- auth still works
- main flow still works
- deploy target still correct

## Likely drift areas
- dependencies
- config files
- API integrations
- docs/scripts

## Notes
- 
MD

echo "$OUT"
