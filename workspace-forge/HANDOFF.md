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

### Current Tasks (as of 2026-03-28 — updated 10:55 PM KL)
- [ ] **BLOCKED: Migration 00024 partially applied** — `add_pipeline_status` step failed with Supabase edge-fn 401 (Unauthorized). The one-time runner at `/api/internal/run-migration-024/route.ts` is deployed but migration needs re-triggering. The edge function `run-migration` auth check (`auth.includes(MIGRATION_SECRET)`) may not match what was passed. Re-call with correct `Bearer <SUPABASE_SERVICE_ROLE_KEY>` header.
- [ ] `challenge_bundles` table does not exist in DB yet — all new intake/forge-review/inventory routes will 500 until migration is applied
- [ ] After migration is confirmed live: delete `/src/app/api/internal/run-migration-024/route.ts` and redeploy
- [ ] Gauntlet: refine calibration profiles + mutation quality (intake pipeline infrastructure now built)
- [ ] Nick's side: Stripe live keys + webhook, Iowa address, bouts.gg domain, ORACLE_WALLET_ADDRESS + BASE_RPC_URL

## Full System Status (as of 12:13 PM KL)
✅ 4-lane judging system (Objective/Process/Strategy/Integrity)
✅ Challenge quality automation (CDI, auto-flag, quarantine, enforcement cron every 15min)
✅ Activation gate (calibration_status=passed + required assets check + trigger)
✅ Activation freeze snapshot (prompt hash, test config, judge weights, thresholds frozen at activation)
✅ Hybrid calibration system v3 (synthetic + real LLM, escalation logic, divergence risk, flagship hard gates, per-lane breakdowns, full cache key)
✅ Mutation engine (semantic/structural/adversarial, anti-drift checks, flagship gates)
✅ Admin APIs: /api/admin/challenge-quality, /api/admin/calibration
✅ Mobile nav fixed (Header on all public pages)
✅ Dashboard shell: Bouts logo in mobile header, notifications bell wired to real API
✅ Login page: Bouts logo, GitHub primary CTA, email secondary
✅ Live prize pool: DB trigger + 8% fee formula + challenge card display
✅ Stale copy cleaned: challenges hero, footer, agent form
✅ No fake data anywhere confirmed
✅ Full E2E test: 85/85 passing
✅ Full content alignment (philosophy, fair-play, how-it-works, contest rules, docs)
✅ SITE_CANON.md locked
✅ GitHub repo in sync (all commits pushed)
⏳ Gauntlet: refine calibration profiles + mutation quality
⏳ Nick: Stripe live keys + webhook, Iowa address, bouts.gg domain, ORACLE_WALLET_ADDRESS + BASE_RPC_URL

## Latest Work (2026-03-28 ~10:55 PM KL) — Gauntlet Intake Pipeline
Built complete challenge intake pipeline (Gauntlet → validation → Forge review → calibration → inventory → publish):
- **Migration 00024** (`supabase/migrations/00024_challenge_intake_pipeline.sql`) — `challenge_bundles` table, `pipeline_status` column on challenges, `forge_review_notes`, calibration states, trigger functions. **⚠️ NOT fully applied — see Current Tasks**
- `src/lib/intake/bundle-schema.ts` — Zod schema for GauntletBundle submission format
- `src/lib/intake/bundle-validator.ts` — semantic validator (prompt quality, test cases, difficulty, time limits)
- `src/lib/intake/inventory-advisor.ts` — inventory gap analysis (checks family/difficulty/type balance)
- `src/app/api/challenges/intake/route.ts` — POST /api/challenges/intake — receives bundle, validates, creates challenge_bundle record
- `src/app/api/admin/forge-review/route.ts` — GET list pending bundles, POST approve/reject with notes
- `src/app/api/admin/inventory/route.ts` — GET inventory health, POST trigger calibration → promote to reserve
- TypeScript: 0 errors (verified with `npx tsc --noEmit`)
- Deploy: production build succeeded at `agent-arena-efnsrucol-nickmaksdigitals-projects.vercel.app`

## Latest Shipped (2026-03-28 ~11:12 AM KL)
- ✅ Hybrid calibration system live — synthetic-runner, real-llm-runner, orchestrator, mutation-engine
- ✅ challenge_calibration_results table live
- ✅ /api/admin/calibration — run_synthetic, run_full, run_forced_real, mutate actions
- ✅ Mutation engine — semantic/structural/adversarial variants, auto-creates new draft challenge
- ✅ Policy map: daily=synthetic only, standard=synthetic+optional real, featured/prize=both required
- ✅ Build error fixed (max_coins missing from select)
- ✅ Calibration v3: escalate on judge delta >15pts, judge_divergence_risk signal, flagship hard gates, per-lane breakdowns, full cache key
- ✅ Login: Bouts logo, GitHub primary CTA, email secondary
- ✅ Dashboard: Bouts logo in mobile header, notifications bell wired to real API
- ✅ Live prize pool: platform_fee_percent column, recompute_prize_pool() DB function, DB trigger, challenge card badges
- ✅ Stale copy: challenges hero, footer (BOUTS ELITE → BOUTS), agent placeholders
- ✅ Full E2E test: 85/85 passing, zero real bugs
- ✅ GitHub repo pushed and in sync

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
