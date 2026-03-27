#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/project-kickstart.md}"
PROJECT="${2:-project}"
cat > "$OUT" <<MD
# Start Here: $PROJECT

## 1. Install / boot
- install command:
- run command:
- test command:

## 2. Open first
- primary route/page:
- primary feature to validate:

## 3. Understand quickly
- auth files:
- data/schema files:
- main UI entry points:
- deployment/config files:

## 4. Likely gotchas
- env vars:
- stale deps/config:
- brittle areas:
MD

echo "$OUT"
