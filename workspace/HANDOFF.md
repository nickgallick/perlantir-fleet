# HANDOFF.md — Forge Context (read on every startup)
# Last updated: 2026-03-26

## Active Project: Bouts / Agent Arena

### Key Facts
- **Live URL**: https://agent-arena-roan.vercel.app
- **Codebase**: `/data/agent-arena` (already cloned on this VPS)
- **GitHub repo**: https://github.com/nickgallick/Agent-arena
- **GitHub token**: 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
- **Stack**: Next.js App Router, TypeScript strict, Tailwind, Supabase, Vercel
- **Deploy command**: `cd /data/agent-arena && vercel deploy --prod --yes --token $(cat ~/.vercel/auth.json | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")`
- **Vercel org/project**: team_h7szk9Nd73ydfud2R8vnQwSx / prj_Nlf54QOI9zrMmLGJ7ZtJjL9hslzt

### Supabase
- **URL**: https://gojpbtlajzigvyfkghrg.supabase.co
- **Credentials**: in `/data/agent-arena/.env.local`

### QA
- **QA user**: qa-bouts-001@mailinator.com (admin role, coins: 1450)
- **QA login**: `/qa-login` — MUST NOT be enabled in prod (`ENABLE_QA_LOGIN` env var)

### Fixes Applied (commit 8003cf4 — deployed and live)
1. Judging filter tab on /challenges page
2. Replay placement field with medal emoji
3. Agent slug 400 fix (UUID vs name/slug lookup)
4. Admin role for QA user

### Known Open Issues
- `/api/challenges/daily` returns 500 — DB schema issue (non-blocking, handled gracefully)
- Landing stats hardcoded in `src/app/page.tsx` lines 50-59
- Test agents in DB: `final-auth-test`, `Testagentarwna`
- Connector docs don't show v0.1.1 badge

### Current Tasks (as of 2026-03-28 — updated 10:55 PM KL)
- ⏳ **WAITING ON NICK** — tagline decision before Launch fires (3 options, #3 recommended: *"Bouts — Enter Your Agent. Win Real Money."*)
- ⏳ Nick's side: Stripe live keys + webhook, Iowa address, bouts.gg domain, ORACLE_WALLET_ADDRESS + BASE_RPC_URL
- ⏳ Migration 00024 (Gauntlet pipeline) needs re-triggering — see Forge HANDOFF for details

### Fixes Applied (latest — deployed and live)

**2026-03-28 (P0 Legal Compliance)**
- 4 legal pages live: `/legal/terms`, `/legal/privacy`, `/legal/contest-rules`, `/legal/responsible-gaming`
- 3-step onboarding with DOB validation, restricted state blocking (WA/AZ/LA/MT/ID), 6 compliance checkboxes
- Migration 00009: 19 compliance columns in `profiles` (age_verified, tos_accepted, full_name, dob, state_of_residence, etc.)
- `/api/onboarding/compliance` — stores all 6 consent timestamps
- Footer: 18+ RG notice bar + links to all 4 legal pages
- Entry fee modal with contest rules consent before payment
- Redirects: `/terms` → 308 → `/legal/terms`, `/privacy` → 308 → `/legal/privacy`
- E2E: 58/58 checks passing, 0 code bugs

**2026-03-27 (UI Fixes)**
- Logo: `h-9` → `h-12`, width 110 → 145 in public-header.tsx
- CTA section: `mx-auto flex flex-col items-center` added — "Ready to Compete?" centered on desktop

### E2E Status (2026-03-27)
- 58/58 passing
- 1 data issue (non-blocking): `/api/challenges/daily` returns 500 — no `is_daily=true` challenges in DB
- Dashboard sub-routes (307 redirect to login) — correct behavior
- Auto-calibration running: 2 challenges promoted to reserve (2026-03-28)

## Update This File
After every significant session, update the "Current Tasks" and "Fixes Applied" sections so the next session starts with full context.
