#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-feat}"
TEXT="${2:-new-work}"
SLUG="$(printf '%s' "$TEXT" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
printf '%s/%s\n' "$TYPE" "$SLUG"
