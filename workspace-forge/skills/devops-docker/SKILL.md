# DevOps & Docker — Forge Skill

## Overview

Our infrastructure uses Docker for local development and CI, GitHub Actions for CI/CD, Vercel for web deployment, and EAS for mobile builds. Correct configuration prevents "works on my machine" issues and deployment failures.

## Docker

### Dockerfile Best Practices

```dockerfile
# GOOD — multi-stage build
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Build the application
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

# Production image
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000

CMD ["node", "server.js"]
```

### Dockerfile Checklist

- [ ] Multi-stage builds to minimize image size
- [ ] `.dockerignore` excludes `node_modules`, `.git`, `.env`, `.next`
- [ ] Non-root user for running the application
- [ ] `--frozen-lockfile` / `--ci` for deterministic installs
- [ ] `COPY` ordered from least to most frequently changed (layer caching)
- [ ] No secrets in build args or environment (use runtime injection)
- [ ] Health check defined
- [ ] Specific base image tag (not `latest`)
- [ ] Alpine-based images preferred for smaller size

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: deps  # For development
    volumes:
      - .:/app
      - /app/node_modules  # Preserve container node_modules
    ports:
      - '3000:3000'
    environment:
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      db:
        condition: service_healthy

  db:
    image: supabase/postgres:15.1.0.117
    ports:
      - '5432:5432'
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  db_data:
```

### Docker Compose Checklist

- [ ] Health checks on database services
- [ ] `depends_on` with conditions (not just service name)
- [ ] Named volumes for persistent data
- [ ] Environment variables from `.env` file (not hardcoded)
- [ ] Port mappings documented
- [ ] Volume mounts correct for development (watch for node_modules)

## Environment Configuration

### Environment Variable Management

```
.env                  # Local development defaults (in .gitignore)
.env.example          # Template with all required vars (committed)
.env.local            # Local overrides (in .gitignore)
.env.test             # Test environment (committed, no secrets)
```

### Environment Checklist

- [ ] `.env` and `.env.local` in `.gitignore`
- [ ] `.env.example` committed with all required variables (no real values)
- [ ] Variables prefixed correctly (`NEXT_PUBLIC_` for client-side in Next.js)
- [ ] No secrets in `NEXT_PUBLIC_` variables (exposed to browser)
- [ ] Environment validation at startup (fail fast if missing)
- [ ] Different values for dev/staging/production

### Environment Validation

```typescript
// lib/env.ts — validate at startup
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),
});

export const env = envSchema.parse(process.env);
```

## Deployment

### Vercel (Web)

- [ ] Build command correct in `vercel.json` or project settings
- [ ] Environment variables set in Vercel dashboard
- [ ] Preview deployments configured for PRs
- [ ] Redirects and rewrites configured
- [ ] Custom domains verified
- [ ] Edge/Serverless function regions appropriate

### EAS (Mobile)

- [ ] `eas.json` configured for development, preview, and production profiles
- [ ] App version and build number incremented
- [ ] Signing credentials managed through EAS
- [ ] Environment variables set in EAS secrets
- [ ] OTA updates configured (if using `expo-updates`)

## CI/CD — GitHub Actions

### Workflow Structure

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm test

  build:
    runs-on: ubuntu-latest
    needs: [lint, typecheck, test]
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
```

### CI/CD Checklist

- [ ] Dependencies cached (pnpm store, node_modules)
- [ ] `--frozen-lockfile` for deterministic installs
- [ ] Jobs run in parallel where possible (lint, typecheck, test)
- [ ] Build depends on passing lint, typecheck, and test
- [ ] Secrets stored in GitHub Secrets, not in workflow files
- [ ] Branch protection requires CI pass before merge
- [ ] Node version matches local development
- [ ] Timeout set on long-running jobs

### Security in CI/CD

- [ ] No secrets logged or echoed
- [ ] Third-party actions pinned to specific SHA (not `@latest` or `@v1`)
- [ ] `GITHUB_TOKEN` permissions scoped to minimum needed
- [ ] Pull request workflows from forks don't have access to secrets
- [ ] Artifact uploads don't include sensitive files

## Review Severity

| Issue | Severity |
|-------|----------|
| Secrets in Dockerfile or workflow | P0 — BLOCKED |
| Running container as root in production | P1 — High |
| Missing `.dockerignore` (includes node_modules/.git) | P1 — High |
| No health checks on services | P1 — High |
| `NEXT_PUBLIC_` variable with secret data | P0 — BLOCKED |
| Missing environment validation | P2 — Medium |
| CI caching not configured | P3 — Low |
| Using `latest` image tag | P2 — Medium |
| Missing `.env.example` | P3 — Low |
