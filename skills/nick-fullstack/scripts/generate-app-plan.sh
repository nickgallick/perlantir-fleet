#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/app-plan.md}"
APP_NAME="${2:-app}"
cat > "$OUT" <<MD
# App Plan: $APP_NAME

## Product
- Problem:
- User:
- Main promise:
- Core CTA:

## Flows
- Landing/onboarding:
- Auth:
- Primary in-app flow:
- Settings/admin:

## Data
- Main entities:
- Key relationships:
- Permissions model:

## Build Order
1. Data/auth foundation
2. Core happy path
3. Validation + edge states
4. UI polish
5. QA + deploy

## Risks
- 

## Post-launch next steps
- Analytics
- Feedback capture
- Admin tooling
- Growth loop
MD

echo "$OUT"
