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
- **Personal Access Token (Supabase CLI/Management API)**: sbp_851afa9dfe477af8cb5c9a6e2c22ecdab2d5960b

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

### Current Tasks (as of 2026-03-28 — updated 8:58 AM KL)
- [ ] Brief Gauntlet on calibration runner + mutation contract (backend is ready for him)
- [ ] Companion spec docs: BOUTS_TRANSPARENCY_POLICY_v1, BOUTS_INTEGRITY_AND_ENFORCEMENT_v1, BOUTS_POST_MATCH_BREAKDOWN_SPEC_v1, BOUTS_CHALLENGE_CALIBRATION_SPEC_v1 (Nick asked about these)
- [ ] Nick's side: Stripe live keys + webhook, Iowa address, bouts.gg domain, ORACLE_WALLET_ADDRESS + BASE_RPC_URL

## Latest Fixes (2026-03-28 ~8:58 AM KL)
- ✅ Mobile nav fixed — InfoNav replaced with shared Header on /judging, /how-it-works, /philosophy, /fair-play, /status
- ✅ Activation freeze snapshot — challenge_activation_snapshots table + function + DB trigger. Freezes prompt hash, test config, judge weights, CDI, enforcement thresholds at activation time.
- ✅ Activation gate hardened — checks has_objective_tests, prompt, description, format, time_limit
- ✅ Sample guard — no flagging <20 runs, no quarantine <40 runs
- ✅ Quarantine alert includes challenge name, reason, metrics, admin link

## Completed This Session (2026-03-28)
- ✅ Full E2E live site test via Playwright
- ✅ Fair Play page — rebuilt with 4-lane judging content (old 3-judge system removed)
- ✅ How It Works — all stale "3-judge" / "3-Judge Panel" / "Claude+GPT-4o+Gemini" copy replaced with 4-lane language
- ✅ Homepage — identity changed to "The Competitive Arena for Autonomous Agents", proof block added, weight class framing → performance-profile
- ✅ Contest Rules Section 6 — reconciled with Judging page (4-lane bounded bands, exact formulas explicitly not published, links to /judging)
- ✅ /philosophy — new Challenge Philosophy page (failure modes, Bouts answers, flagship families, thesis)
- ✅ /docs/compete — new Competitor Guide (submission contract, telemetry schema, scoring principles, rules)
- ✅ Docs hub — restructured with 4 cards, stale "kinetic combat" copy removed
- ✅ Leaderboard empty state — "Be the first to compete" with CTA
- ✅ Nav/footer — Philosophy added
- ✅ SITE_CANON.md — created in workspace-forge as source of truth for all public copy

## Foundry — Phase 0 Status (as of 2026-03-28)
All frontend/backend architecture complete. Docs in workspace-forge:
- foundry-frontend-architecture.md — Next.js spec (canonical)
- foundry-frontend-architecture-lovable.md — Lovable SPA version
- foundry-v0-homepage.md — v0.dev prompt for homepage

Legal rulings applied (Counsel 2026-03-28):
- Binary AI review only — no numerical scores to backers
- Exact disclaimer text locked in
- "Claim Reward" primary CTA, marketplace secondary (hard requirement)
- Velocity limits: 24hr hold + 10/day cap → Chain's Marketplace.sol
- All 6 gaps vs Chain v1.8 closed and committed

Phase 1 gate — remaining items on Chain:
- [ ] Velocity limits in Marketplace.sol
- [ ] One-address-one-vote in voting logic
- [ ] Stake scaling formula
- [ ] P0: Fiat on-ramp architecture (Nick + Chain decision)
- [ ] Section 15 Q3, Q5, Q6, Q7, Q8 (Nick decisions)

Nick's design plan: v0.dev for components → Figma for full designs → Maks builds

## Session Context (2026-03-28 confirmed from full chat log PDF)
The PDF Nick sent covers the full Mar 26–27 session (316 pages). Key confirmed facts:
- All site content is intentional — 4-lane judging, how-it-works, judging transparency page, legal pages
- "3-Judge Panel" label in how-it-works quick overview card IS genuinely stale (pre-Phase 1 copy that wasn't cleaned up)
- FAQ answer "Three independent judges..." is also stale — predates Phase 1 rebuild
- No fake data directive is firm — Nick was explicit
- Wallet: profiles.coins (old) vs arena_wallets.balance (new/correct). credit_wallet RPC should handle future payouts but unconfirmed on real user flow
- Stripe live keys + webhook still needed before real money flows
- Iowa business address still placeholder in /legal/contest-rules
- bouts.gg domain not yet connected
- ORACLE_WALLET_ADDRESS, BASE_RPC_URL still needed from Chain for chain calls to activate

## Update This File
After every significant session, update the "Current Tasks" and "Fixes Applied" sections so the next session starts with full context.
