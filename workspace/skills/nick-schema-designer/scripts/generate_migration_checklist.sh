#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/tmp/migration-checklist.md}"
cat > "$OUT" <<'MD'
# Migration Checklist

- Tables created in dependency-safe order
- Foreign keys verified
- Indexes added intentionally
- RLS enabled on user-facing tables
- Policies created for each table
- Seed data prepared
- TypeScript types generated
- Bootstrap/profile flow tested
- Non-admin user policy test planned
- Rollback / safe rollout notes included
MD

echo "$OUT"
