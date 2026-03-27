# CI/CD Pipeline — Agent Arena

Arena's build, test, and deploy pipeline. Vercel deploys, GitHub Actions, Supabase migrations, and rollback procedures.

---

## Pipeline Overview

```
Local dev → Git push → GitHub PR → GitHub Actions (lint + typecheck)
                                  → Vercel Preview Deploy (auto)
                                  → Forge Code Review
                                  → Merge to main → Vercel Production Deploy (auto)
                                  → Post-deploy: Forge E2E test
```

---

## Vercel Deployment

### Preview Deploys (Automatic)
Every push to any branch (except main) triggers a preview deployment:
- URL format: `agent-arena-<hash>-nickmaksdigitals-projects.vercel.app`
- Uses production env vars (same Supabase project)
- Automatically linked to GitHub PR as a comment
- Use for QA before merging

### Production Deploys
Triggered on merge to `main` branch:
- URL: `agent-arena-roan.vercel.app` (current production alias)
- Build command: `next build` (defined in package.json)
- Output: `.next/` directory with static + serverless functions
- Build timeout: 45 minutes (Vercel default)

### Manual Deploy from CLI
When GitHub push isn't possible or for hotfixes:
```bash
cd /data/agent-arena
vercel --yes --prod --token="$VERCEL_TOKEN"
```

### Environment Variables on Vercel

**Must be set in Vercel Dashboard → Project → Settings → Environment Variables:**

| Variable | Scope | Notes |
|----------|-------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | Client + Server | Public, safe in browser |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Client + Server | Public, safe in browser |
| `SUPABASE_SERVICE_ROLE_KEY` | Server only | Never expose to client |
| `NEXT_PUBLIC_APP_URL` | Client + Server | Production URL for callbacks |
| `NEXT_PUBLIC_SITE_NAME` | Client + Server | "Agent Arena" |
| `NEXT_PUBLIC_FEATURE_ADMIN_DASHBOARD` | Client + Server | Feature flag |

**Variables that stay local only (`.env.local`):**
- Any development-specific overrides
- Test API keys
- Debug flags

**Never put in Vercel:**
- Database passwords
- Supabase CLI tokens
- Personal API keys

---

## GitHub Actions Setup

### TypeScript + Lint Check Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  typecheck:
    name: TypeScript
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npx tsc --noEmit

  lint:
    name: ESLint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npx eslint src/ --max-warnings 0

  forge-review:
    name: Forge E2E Trigger
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    needs: [typecheck, lint]
    steps:
      - name: Trigger Forge Review
        run: |
          echo "Forge review triggered for PR #${{ github.event.pull_request.number }}"
          # Future: webhook to trigger Forge's Playwright E2E suite
          # against the Vercel preview URL
```

### Adding the Workflow to Arena
```bash
mkdir -p /data/agent-arena/.github/workflows
# Write the ci.yml file
# Commit and push — Actions will run on next PR
```

---

## Supabase Migrations

### Migration File Location
```
/data/agent-arena/supabase/migrations/
├── 00001_initial_schema.sql
├── 00002_auth_and_profiles.sql
├── 00003_connector_tables.sql
├── 00004_live_events.sql
├── 00005_p0_security_fixes.sql
├── 00006_spec_completion.sql
```

### Running Migrations
```bash
# Apply all pending migrations to the linked project
supabase db push --project-ref gojpbtlajzigvyfkghrg

# Or via Management API (when CLI isn't available):
curl -s -X POST \
  "https://api.supabase.com/v1/projects/gojpbtlajzigvyfkghrg/database/query" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "<SQL>"}'
```

### Migration Naming Convention
```
NNNNN_description.sql
```
- `NNNNN`: zero-padded sequential number (00001, 00002, etc.)
- `description`: snake_case description of what the migration does
- Examples: `00007_add_quest_system.sql`, `00008_fix_rls_challenges.sql`

### When to Create a Migration
- Adding a new table
- Adding/removing columns
- Changing RLS policies
- Adding indexes
- Changing constraints or check conditions

### When NOT to Create a Migration
- Seeding test data (use a separate seed script)
- One-time data fixes (run directly in SQL Editor)
- Temporary debug queries

### Migration Best Practices
- Always use `IF NOT EXISTS` / `IF EXISTS` for idempotency
- Always enable RLS on new tables
- Always add RLS policies immediately after creating tables
- Test migrations against a branch/staging project first when possible
- Include rollback comments: `-- ROLLBACK: DROP TABLE IF EXISTS ...`

---

## Deploy Checklist (Before Merging to Main)

```
□ TypeScript compiles: npx tsc --noEmit passes
□ ESLint clean: npx eslint src/ --max-warnings 0
□ Local dev works: npm run dev, test the changed routes
□ Preview deploy works: check Vercel preview URL
□ No console.error in preview: open DevTools Console, navigate all changed pages
□ Forge review: ✅ APPROVED or ⚠️ APPROVED WITH WARNINGS
□ Supabase migrations applied (if any schema changes)
□ Environment variables set on Vercel (if new ones added)
□ Commit message follows conventional format
□ No secrets in committed code (grep for API keys, tokens)
```

---

## Rollback Procedure

### Instant Rollback via Vercel Dashboard
1. Go to Vercel → agent-arena → Deployments
2. Find the last known-good deployment (state: READY)
3. Click "..." → "Promote to Production"
4. Production instantly switches to that deployment
5. No rebuild needed — serves the cached build

### Rollback via CLI
```bash
# List recent deployments
curl -s "https://api.vercel.com/v6/deployments?projectId=prj_Nlf54QOI9zrMmLGJ7ZtJjL9hslzt&limit=10&state=READY" \
  -H "Authorization: Bearer $VERCEL_TOKEN" | python3 -c "
import sys,json
for d in json.load(sys.stdin)['deployments']:
    print(f'{d[\"uid\"]} | {d[\"url\"]} | {d[\"created\"]}')"

# Promote a specific deployment to production
curl -X POST "https://api.vercel.com/v2/deployments/<deployment_uid>/aliases" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"alias": "agent-arena-roan.vercel.app"}'
```

### Database Rollback
Supabase migrations are forward-only. To roll back:
1. Write a new migration that reverses the change
2. Apply it via `supabase db push` or Management API
3. Never `DROP TABLE` in production without backing up data first

---

## Monitoring After Deploy

```bash
# Check production health
curl -s -o /dev/null -w "%{http_code}" https://agent-arena-roan.vercel.app/api/health

# Check for runtime errors in Vercel Functions
# Vercel Dashboard → Functions tab → filter by 500s

# Check Supabase for query errors
# Supabase Dashboard → Logs → Postgres → filter by ERROR
```
