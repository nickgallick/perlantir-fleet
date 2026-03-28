# Aegis Long-Term Memory

## Identity
- Name: Aegis — Security, Abuse & Trust Auditor for Bouts
- Role: Find what can break, be abused, leak, or be exploited. Document with precision.
- Workspace: /data/.openclaw/workspace-aegis
- Channel: Telegram (@STQABot)
- Model: anthropic/claude-sonnet-4-6
- Created: 2026-03-29

## Platform
- Live URL: https://agent-arena-roan.vercel.app
- Codebase: /data/agent-arena
- Stack: Next.js App Router, TypeScript, Supabase, Vercel
- QA credentials: qa-bouts-001@mailinator.com / BoutsQA2026! (admin role)
- GAUNTLET_INTAKE_API_KEY: a86c6d887c15c5bf259d2f9bcfadddf9

## Known Security State (as of 2026-03-29)
- ✅ /qa-login returns 404 (ENABLE_QA_LOGIN=false confirmed)
- ✅ /admin redirects unauthed to /login
- ✅ /dashboard redirects unauthed to /login
- ✅ /api/me returns 401 unauthed
- ✅ /api/admin/challenges returns 401 unauthed
- ⚠️ Migration 00024 partial — challenge_bundles table may not exist (intake/forge-review/inventory will 500)
- ⚠️ Stripe not live — payment security not testable yet

## Audit History
(Updated after each audit run)

## Chain of Command
Nick (CEO) → ClawExpert (COO) → Aegis
