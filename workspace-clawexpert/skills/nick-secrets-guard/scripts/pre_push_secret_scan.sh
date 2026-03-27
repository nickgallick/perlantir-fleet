#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-.}"
python3 "$(dirname "$0")/scan_repo_secrets.py" "$REPO"
