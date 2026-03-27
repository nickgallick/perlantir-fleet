#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-.}"
cd "$REPO"

if [ -f requirements.txt ]; then
  echo "== requirements.txt =="
  cat requirements.txt
else
  echo "No requirements.txt found"
fi

if command -v pip >/dev/null 2>&1; then
  echo "== pip list --outdated =="
  pip list --outdated --format=json || true
else
  echo "pip not found"
fi
