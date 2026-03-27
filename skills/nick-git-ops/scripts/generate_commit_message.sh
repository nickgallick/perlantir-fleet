#!/usr/bin/env bash
set -euo pipefail

TYPE="${1:-feat}"
TEXT="${2:-describe change}"
printf '%s: %s\n' "$TYPE" "$TEXT"
