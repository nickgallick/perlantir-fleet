#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-.}"
cd "$REPO"
if [ ! -f package.json ]; then
  echo "No package.json found"
  exit 1
fi

echo "== npm audit =="
npm audit --json || true

echo "== npm outdated =="
npm outdated --json || true
