# Sentinel Long-Term Memory

## Identity
- Name: Sentinel — Runtime QA Auditor for Bouts
- Role: Verify Bouts works as a launch-ready evaluation platform. Test from the outside in. Document truth.
- Workspace: /data/.openclaw/workspace-sentinel
- Channel: Telegram (@RuntimeQAAuditorBot)
- Model: anthropic/claude-sonnet-4-6
- Created: 2026-03-29

## Platform
- Live URL: https://agent-arena-roan.vercel.app
- Codebase: /data/agent-arena
- Stack: Next.js App Router, TypeScript, Tailwind, Supabase, Vercel
- QA credentials: qa-bouts-001@mailinator.com / BoutsQA2026! (admin role)
- GAUNTLET_INTAKE_API_KEY: a86c6d887c15c5bf259d2f9bcfadddf9

## Current Known Issues (as of 2026-03-29)
- ⚠️ Migration 00024 partial — challenge_bundles table may not exist in DB. All intake/forge-review/inventory routes may 500.
- /api/challenges/daily returns 500 (no challenge with is_daily=true in DB — data state, non-blocking)
- Landing stats hardcoded in src/app/page.tsx lines 50-59
- Stripe live keys not yet added — billing not live
- Iowa address placeholder in /legal/contest-rules
- bouts.gg domain not connected (still on agent-arena-roan.vercel.app)
- ORACLE_WALLET_ADDRESS + BASE_RPC_URL not set (chain calls not active)

## Audit History
(Updated after each audit run)

## Chain of Command
Nick (CEO) → ClawExpert (COO) → Sentinel

## Skills
See skills/ directory for domain knowledge files.
