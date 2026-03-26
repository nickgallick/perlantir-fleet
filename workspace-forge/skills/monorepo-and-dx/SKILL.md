---
name: monorepo-and-dx
description: Monorepo structure, developer experience tooling, CI/CD pipeline, database workflow, and environment management for production Next.js + Supabase projects.
---

# Monorepo & Developer Experience

## Project Structure (Arena)
```
arena/
├── apps/
│   ├── web/                    # Next.js frontend (Vercel)
│   │   ├── src/
│   │   │   ├── app/            # App Router pages and layouts
│   │   │   ├── components/     # App-specific components
│   │   │   ├── features/       # Feature modules (challenges, agents, leaderboard)
│   │   │   ├── hooks/          # App-specific hooks
│   │   │   └── lib/            # App-specific utilities
│   │   ├── next.config.ts
│   │   └── package.json
│   └── arena-connector/        # OpenClaw skill package
│       ├── SKILL.md
│       └── package.json
├── packages/
│   ├── db/                     # Database types, migrations, seed
│   │   ├── types.ts            # Generated from `supabase gen types`
│   │   ├── client.ts           # Typed Supabase client factory
│   │   └── package.json
│   ├── api/                    # Shared API types and Zod schemas
│   │   ├── schemas/            # Zod schemas (single source of truth)
│   │   ├── types.ts            # Inferred TypeScript types
│   │   └── package.json
│   ├── ui/                     # Shared UI components (Shadcn-based)
│   │   └── package.json
│   └── utils/                  # Shared utilities
│       └── package.json
├── supabase/
│   ├── migrations/             # SQL migrations (versioned)
│   ├── functions/              # Edge Functions
│   ├── seed.sql                # Development seed data
│   └── config.toml             # Supabase project config
├── turbo.json                  # Turborepo task config
├── pnpm-workspace.yaml         # Workspace definition
├── .github/workflows/ci.yml    # GitHub Actions CI/CD
└── package.json                # Root package.json
```

## Tooling Setup

### Turborepo Configuration
```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "lint": {},
    "typecheck": { "dependsOn": ["^build"] },
    "test": { "dependsOn": ["^build"] },
    "dev": { "cache": false, "persistent": true }
  }
}
```

### pnpm Workspace
```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
  - 'supabase/functions/*'
```

### GitHub Actions CI
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint           # ESLint across all packages
      - run: pnpm typecheck      # TypeScript strict mode
      - run: pnpm test           # Vitest unit + integration
      - run: pnpm build          # Verify production build
  
  e2e:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase start      # Local Supabase for E2E
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright install --with-deps
      - run: pnpm e2e            # Playwright tests
```

### Pre-commit Hooks
```json
// package.json
{
  "scripts": {
    "prepare": "husky"
  },
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.sql": ["prettier --write --plugin=prettier-plugin-sql"]
  }
}
```

---

## Database Workflow

### Migration Lifecycle
```bash
# 1. Start local Supabase
supabase start

# 2. Create migration
supabase migration new add_weight_class_field

# 3. Write SQL in supabase/migrations/TIMESTAMP_add_weight_class_field.sql

# 4. Apply locally
supabase db reset  # resets + applies all migrations + seed

# 5. Generate types
supabase gen types typescript --local > packages/db/types.ts

# 6. Commit migration + generated types together

# 7. CI applies to preview project (branch-based)
# 8. On merge to main, apply to production
supabase db push --linked
```

### Seed Data
```sql
-- supabase/seed.sql — development data
INSERT INTO agents (id, user_id, agent_name, primary_model, model_power_score, weight_class)
VALUES 
  ('agent-1', 'user-1', 'Test Agent Alpha', 'claude-opus-4-6', 98, 'Frontier'),
  ('agent-2', 'user-2', 'Test Agent Beta', 'llama-3.3-70b', 75, 'Contender'),
  ('agent-3', 'user-3', 'Test Agent Gamma', 'llama-3.3-8b', 55, 'Scrapper');

INSERT INTO agent_ratings (agent_id, weight_class, elo_rating, tier)
VALUES
  ('agent-1', 'Frontier', 1500, 'Gold'),
  ('agent-2', 'Contender', 1300, 'Silver'),
  ('agent-3', 'Scrapper', 1200, 'Bronze');
```

---

## Environment Management

### Environment Variable Validation
```ts
// packages/utils/env.ts
import { z } from 'zod'

const EnvSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  ANTHROPIC_API_KEY: z.string().startsWith('sk-ant-'),
  ENCRYPTION_KEY: z.string().length(64), // 32 bytes hex-encoded
})

// Validate at app startup — fail fast if misconfigured
export const env = EnvSchema.parse(process.env)
```

### .env.example (committed to git)
```bash
# .env.example — copy to .env.local and fill in values
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
ANTHROPIC_API_KEY=
ENCRYPTION_KEY=
```

**Rules:**
- `.env.local` — NEVER committed (in `.gitignore`)
- `.env.example` — ALWAYS committed (template)
- Vercel env vars for production secrets
- Supabase Dashboard for Edge Function secrets

## Sources
- turborepo documentation — monorepo task orchestration
- cal.com — production monorepo structure (apps + packages)
- bulletproof-react — feature-based organization
- Supabase CLI documentation (migrations, type generation, local dev)

## Changelog
- 2026-03-21: Initial skill — monorepo and developer experience
