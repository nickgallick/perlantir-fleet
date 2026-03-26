---
name: ci-cd-pipeline-design
description: GitHub Actions CI/CD for Next.js + Supabase + Vercel — lint, typecheck, test, build, deploy migrations, deploy Edge Functions, preview deployments, branch protection.
---

# CI/CD Pipeline Design

## Standard Pipeline (GitHub Actions)

```yaml
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint-typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck  # tsc --noEmit

  test:
    runs-on: ubuntu-latest
    needs: lint-typecheck
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: 'pnpm' }
      - uses: supabase/setup-cli@v1
      - run: supabase start
      - run: pnpm install --frozen-lockfile
      - run: pnpm test           # Vitest
      - run: pnpm test:e2e       # Playwright
        env:
          NEXT_PUBLIC_SUPABASE_URL: http://127.0.0.1:54321
          NEXT_PUBLIC_SUPABASE_ANON_KEY: ${{ secrets.LOCAL_ANON_KEY }}

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm build           # next build

  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
      - run: supabase db push               # Apply migrations
      - run: supabase functions deploy       # Deploy Edge Functions
      # Vercel deploys automatically on push to main
```

## Pipeline Stages

| Stage | Tool | Catches | Speed |
|-------|------|---------|-------|
| 1. Lint | ESLint | Style, patterns | ~10s |
| 2. Typecheck | tsc --noEmit | Type errors | ~15s |
| 3. Unit test | Vitest | Logic errors | ~30s |
| 4. Integration test | Vitest + local Supabase | DB/auth issues | ~60s |
| 5. E2E test | Playwright | UI/flow issues | ~120s |
| 6. Build | next build | Build errors | ~60s |
| 7. Deploy DB | supabase db push | Migration issues | ~10s |
| 8. Deploy Functions | supabase functions deploy | Edge Function issues | ~20s |
| 9. Deploy App | Vercel (automatic) | — | ~60s |

## Deployment Safety

**Migration ordering:**
```
1. Deploy code that handles BOTH old and new schema
2. Run database migration
3. Deploy code using only new schema
4. Cleanup migration (drop old columns)
```

**Exception — removing a column:**
```
1. Deploy code that stops reading the column
2. Run migration that drops the column
```

**Rollback:** Revert the merge commit on main → Vercel auto-deploys reverted version.

## Branch Protection

```
main branch:
  ✅ Require PR review (1 approval minimum)
  ✅ Require CI passing (lint + typecheck + test + build)
  ✅ No direct pushes
  ✅ No force pushes
  ✅ Auto-merge for Dependabot PRs after CI passes
```

## Preview Deployments

- Every PR gets a preview URL (Vercel automatic)
- Preview can connect to Supabase branch database (if configured)
- QA on preview URL before merging
- E2E tests can run against preview URL in CI

## Sources
- GitHub Actions documentation
- Vercel deployment documentation
- Supabase CLI (migrations, functions deployment)
- cal.com CI pipeline (production reference)

## Changelog
- 2026-03-21: Initial skill — CI/CD pipeline design
