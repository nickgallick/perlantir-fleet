#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/ci-secrets-checklist.md}"
cat > "$OUT" <<'MD'
# CI/CD Secrets Checklist

- VERCEL_TOKEN
- VERCEL_ORG_ID
- VERCEL_PROJECT_ID
- NEXT_PUBLIC_SUPABASE_URL
- NEXT_PUBLIC_SUPABASE_ANON_KEY
- APP_BASE_URL (if tests need it)

## Rules
- keep all secrets in GitHub/Vercel settings
- never commit secrets into workflow files
- verify environment parity before production deploy
MD

echo "$OUT"
