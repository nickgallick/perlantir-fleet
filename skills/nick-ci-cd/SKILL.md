---
name: nick-ci-cd
description: GitHub Actions CI/CD generation for Nick's standard stack: Next.js App Router, Supabase, Vercel, and Playwright-based testing. Use when setting up CI/CD, adding deploy automation, generating workflow files, or aligning pipeline behavior with Nick's test-before-deploy rule.
---

# Nick CI/CD

Use this as the default CI/CD pipeline skill for Nick.

## Purpose
Generate production-oriented GitHub Actions workflows that fit Nick's stack and release habits.

## Default stack assumptions
- Next.js App Router
- Node.js
- Supabase
- Vercel
- Playwright for browser/E2E testing

## Hard rules
- Always include a testing step before deploy
- Never deploy if tests fail
- Prefer GitHub Actions
- Use Playwright for E2E/browser validation in pipeline design
- Keep secrets in GitHub/Vercel secret stores, never in workflow YAML
- Make deploy steps explicit and auditable

## Standard workflow
1. Detect project commands and stack shape
2. Generate CI workflow with install, lint, test, build
3. Add Playwright/browser test stage
4. Gate deploy on successful checks
5. Generate env/secrets checklist
6. Output ready-to-commit workflow files

## Default output
- `.github/workflows/ci.yml`
- optional deploy workflow guidance
- secrets/env checklist
- notes on required commands or missing scripts

## Preferred pipeline shape
- checkout
- setup node
- install deps
- lint
- unit/integration tests if available
- Playwright install + browser test step
- build
- deploy only after green checks

## References
- Read `references/github-actions-patterns.md` for workflow design
- Read `references/vercel-deploy-gates.md` for deploy rules
- Read `references/playwright-ci.md` for Playwright expectations
- Read `references/secrets-checklist.md` for CI secret handling

## Bundled scripts
- `scripts/init_ci_workflow.sh` — generate a starter GitHub Actions workflow
- `scripts/generate_secrets_checklist.sh` — generate CI secrets/env checklist
- `scripts/generate_pipeline_notes.sh` — create project-specific CI/CD notes
