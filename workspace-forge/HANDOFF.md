# Forge Handoff

## Last Updated
2026-03-31 ~18:45 KL

## Latest Deploy
Git: 3f769e5 | https://agent-arena-roan.vercel.app | pushed to GitHub

## Status: COMPLETE — Performance Breakdown System fully live + LLM verified working

## Performance Breakdown — FULLY COMPLETE (2026-03-31 ~19:15 KL) — commit cd91231
- Migration 00045: applied ✅
- Pipeline: Haiku 4.5, max_tokens:3500, maxDuration:120, 46.7s, confidence:HIGH, real LLM ✅
- Root cause fixed: max_tokens too low (2000) was truncating JSON mid-response → parse fail → fallback
- All A1–D3 + LLM quality verified ✅ TypeScript clean ✅
- Live: https://agent-arena-roan.vercel.app ✅

## Admin Mobile Fix — COMPLETE (2026-03-31 ~15:34 KL) — commit fec9909
- Sidebar: mobile horizontal scroll pill strip (replaces vertical sidebar)
- Forge Review: table replaced with mobile-first cards + expandable prompt preview
- Bug fix: fetchForgeReviews was reading data.reviews, API returns data.review_queue — queue always showed empty
- API fix: added prompt + format to forge-review GET select
- All 5 Gauntlet challenges reviewed: calibration_status=passed, status=reserve — all clean

## Performance Breakdown Remediation — DONE (commit 7d978e0)
A1: UNIQUE constraint 00045 SQL ready (apply in Supabase — see above). DB already cleaned.
A2: Sync pipeline. A3: Graceful failure states. A4: Classic tab default.
B1: Real DB stats, MIN_ENTRIES=5. B2/B3: Infra fields scoped. B4: Explicit whitelist.
C1: /10 vs /100 labeled. C2: Honest inline loading. C3: 'session' label. C4: Percentile tooltip.
D1: Evidence-required prompts. D2: Internal metrics hidden. D3: Sample gate.

## Migration 00043 — FULLY APPLIED ✅ (2026-03-31 ~14:58 KL)
Premium Post-Bout Feedback System — 7 tables created:
- submission_feedback_reports, submission_lane_feedback, submission_failure_modes
- submission_improvement_priorities, submission_evidence_refs
- agent_performance_profiles, agent_performance_events
- Full RLS, indexes, updated_at triggers

## Migration 00042 — FULLY APPLIED ✅ (2026-03-31 ~10:40 KL)
- Applied manually by Nick in Supabase SQL editor
- Columns confirmed: positive_signal, primary_weakness (judge_outputs), overall_verdict (challenge_entries)
- RLS recursion fixed at DB level via public.is_admin() SECURITY DEFINER function
- All RLS policies rewritten — no more inline profiles subqueries

---

## Session Summary — 2026-03-31 (Final QA + Polish Fixes)

### All commits this session (final batch):
- `677b1ad` — Final QA remediation: S1-S8 complete (replay hardening, provisional, session contract, feedback, admin, launch copy)
- `6cf445c` — Post-launch cleanup: backfill signals/verdict, restore full column selects, wallet dead code
- `f608ddb` — P1+P2 Sentinel fixes: isProvisional requires status=active, ends_at enforced on all 3 submit routes
- `ac2f5b9` — Polish: P2 format fallback, P3a admin tooltip, P3b wallet heading, sandbox test challenges retired

### Key decisions from final passes:
- **isProvisional rule** (permanent): must be `challenge.status === 'active' AND ends_at > now`. Status alone is not enough — manually-closed challenges (status=complete, ends_at future) must show final-only language.
- **ends_at enforcement**: all 3 submit routes (invoke, connector/submit, web-submit) now check `ends_at` as a hard deadline in addition to `status !== 'active'`. Code now matches docs.
- **Sandbox test challenges retired**: [Sandbox] Echo Agent, Full Stack Test, Hello Bouts → status=complete in DB. Public list is clean: 2 real challenges only.
- **challenge_format fallback**: replay route falls back to `challenge.format` when `challenge_format` entry column is null — prevents "FORMAT" display artifact.
- **Wallet heading**: "Bouts Wallet" (was "Arena Wallet").
- **Admin inventory tooltip**: `title={label}` not `title={action}` — no snake_case on hover.

### Backfill applied (DB-level, 2026-03-31):
- 17 judge_outputs rows: positive_signal + primary_weakness derived from dimension_scores/flags/rationale
- 8 challenge_entries rows: overall_verdict synthesized from composite score + lane spread + placement

## Session Summary — 2026-03-31 (Full Launch Remediation Pass)

### All commits this session (oldest → newest):
- `c0970ad` — Full launch remediation: P0 RLS fix, P1 provisional labels, P2 timing/dates, P3 radar, P4 admin, P5 copy
- `56ca946` — RLS recursion workaround: all profile/entry reads use adminClient until migration 00042 applied
- `9817615` — Fix replay route: remove missing columns from select until migration 00042 applied

### What changed:
- Migration 00042: is_admin() SECURITY DEFINER function, 3 new columns, all RLS policies rewritten
- All API routes using profiles/entries now use adminClient (workaround + permanent pattern)
- Replay route resilient to missing columns (gracefully null until migration applied)
- Provisional placement labels on all surfaces (results, replay, challenge detail)
- Year added to challenge open/close dates
- Session-extends-past-close warning in workspace
- 60m session label + tooltip on challenge cards
- Admin form: Per-Entry Session label, Challenge Window Opens/Closes, sandbox + RAI checkboxes
- Admin inventory: human action labels, StatusBadge human label map
- How-it-works: prize language removed, leaderboard/rankings copy
- Radar: no proxy defaults, suppressed when <3 real measured axes
- requireAdmin() uses adminClient (fixes all admin routes)

## Session Summary — 2026-03-31 (Launch Timing + Feedback Model)

### All commits this session (oldest → newest):
- `0818dc1` — Free-at-launch: all Stripe/payment surfaces disabled
- `c7c86ad` — Betting/gaming language removed, onboarding cleaned
- `9896c79` — Connector sweep: GitHub Action result_url, idempotency key bugs, deprecated API docs
- `ce114a5` — API docs auth section clarified (x-arena-api-key vs bouts_sk_)
- `76190de` — Pre-launch remediation pass (RLS migration, admin 500 fixes, v1 challenges filter)
- `eaf4261` — Deferred items completed (junk challenges deleted, USDC labels, RI toggle, MCP restored)
- `335b23e` — Launch timing + feedback model (see below)
- `1031d1a` — Fix missed timing copy: LIVE SESSION badge, Time Limit label, landing card

---

## Launch Timing + Feedback Model — COMPLETE (2026-03-31 ~08:00 KL)

### Schema (migration 00041 — applied manually in Supabase SQL editor)
- `judge_outputs.positive_signal` TEXT — strongest positive per lane
- `judge_outputs.primary_weakness` TEXT — key weakness per lane
- `challenge_entries.overall_verdict` TEXT — synthesized top-level verdict

### Timing model
- Challenge window (starts_at → ends_at) and per-entry session (time_limit_minutes) are now fully separated throughout UI, data model, docs, and copy
- Default challenge window: 48 hours (admin creator auto-fills end date)
- Default per-entry session: 60 minutes (starts when user opens workspace)
- Edge case policy: sessions started before challenge close may finish; new entries blocked at close

### Key files changed
- `supabase/migrations/00041_timing_feedback_model.sql`
- `src/lib/validators/challenge.ts` — time_limit_minutes allows 0 (sandbox no-limit)
- `src/components/admin/challenge-creator.tsx` — Challenge Window + Per-Entry Session sections
- `src/app/(public)/challenges/[id]/page.tsx` — timing card, live countdown, ChallengeCountdown component
- `src/app/(public)/challenges/[id]/workspace/page.tsx` — dual-clock (Your Session / Challenge Closes)
- `src/app/api/challenges/[id]/workspace/route.ts` — passes ends_at to client
- `src/app/(public)/submissions/[id]/status/page.tsx` — provisional placement, standings-at-close note
- `src/app/api/challenge-submissions/[submissionId]/route.ts` — challenge_ends_at, provisional_placement, total_entries
- `src/components/replay/post-match-breakdown.tsx` — full rewrite (verdict synthesis, per-lane signals, improvement guidance, relative context)
- `src/app/(public)/replays/[entryId]/page.tsx` — passes overall_verdict, placement, isProvisional to breakdown
- `src/app/api/replays/[entryId]/route.ts` — overall_verdict, total_entries, challenge_ends_at, positive_signal, primary_weakness
- `src/app/(public)/how-it-works/page.tsx` — timing FAQs rewritten
- `src/app/docs/compete/page.tsx` — Results & Standings section added, timing rules updated
- `src/app/docs/quickstart/page.tsx` — session timer clarified, results timing updated
- `src/components/challenges/challenge-detail-header.tsx` — "LIVE SESSION" → "Open — enter any time", "Time Limit" → "Per-Entry Session"
- `src/components/landing/current-challenge.tsx` — rewritten to fetch real active challenge, correct timing copy

---

## RLS Status — FULLY APPLIED (2026-03-31 06:22 KL)
Migration 00040_rls_launch_hardening.sql applied manually in Supabase SQL editor.
Second pass (agents column-level REVOKE) also applied.

### Verified live via anon PostgREST:
- submissions → blocked ✅
- challenge_entries → blocked ✅
- profiles → blocked ✅
- api_tokens → blocked ✅
- api_tokens.token_hash → blocked ✅
- agents.api_key_hash → blocked (column-level REVOKE+GRANT) ✅
- agents.remote_endpoint_url → blocked ✅
- agents.remote_endpoint_secret_hash → blocked ✅
- agents.sandbox_endpoint_secret_hash → blocked ✅
- challenges (anon) → active-only (2 rows) ✅

---

## Pre-Launch Remediation Pass — eaf4261

### P1 Items — All Done:
1. `/api/v1/challenges` — unauthenticated callers get active-only; reserve/draft blocked; 403 on internal status requests
2. `/api/prizes/claim` → 503; `/api/prizes/w9` → 503
3. Wallet: Claim button → "Pending payout" badge; Claim + W9 modals gated with `false`
4. how-it-works: USDC/Stripe/on-chain/Base copy removed; "payouts launching soon"
5. Supabase RLS: all 5 sensitive tables locked, secrets column-blocked — verified
6. Admin health-dashboard: non-fatal errors, returns empty instead of 500
7. Admin intake-queue: non-fatal errors, returns empty instead of 500
8. Admin "Web Submit" → "Web Workspace" with tooltip
9. Admin health dashboard: Remote Invoke toggle column added with handleRIToggle handler
10. Challenges page: removed "upcoming" status filter tab
11. Fair-play: removed "Verifiable on Basescan" on-chain copy
12. Wallet subtitle updated

### P2 Items — All Done:
- MCP confirmed live (Supabase Edge Function, v1.0, JWT-auth required) — docs/cards restored
- 158 Pipeline-Test/hex-suffix junk challenges deleted from DB (2 preserved — had entries)
- `entry-fee-modal.tsx` deleted (dead code, never imported)
- USDC labels → "prize" on challenges list, detail, spectate
- MCP docs index card restored to v1.0 live

---

## Challenge Pipeline (how it works)
- Gauntlet submits via POST /api/challenges/intake (API key auth, automatic)
- Lands as pipeline_status = "draft_review"
- Admin approves in Forge Review tab (MANUAL GATE 1)
- Calibration runs automatically
- Admin activates in Inventory tab (MANUAL GATE 2) once calibration_status = "passed"
- Goes live (status = "active")
- Reserve challenges ready to activate: Async Memoize, Sliding Window Rate Limiter, etc.

---

## Current Live State
- 2 public active challenges: "Full-Stack Todo App", "Debug the Payment Flow"
- 3 sandbox challenges (active, is_sandbox=true)
- Reserve challenges: ~25 non-junk challenges awaiting activation
- All pricing: free (entry_fee_cents=0 enforced at UI + API layer)
- Payouts: deferred (503 on claim/w9, "launching soon" UI)

---

## Post-Launch Deferred (not blockers)
- Re-enable Stripe Connect + webhook when paid tiers ship
- Un-hardcode Entry Fee = "Free" tag when per-challenge pricing finalised
- Re-add US state geo-blocking if paid contests return
- Activate reserve challenges via admin panel as needed

---

## Free-at-Launch Pass — COMPLETE (2026-03-31 ~03:20 KL)

### Commit 0818dc1 — Payment surfaces disabled
- POST /api/challenges/[id]/checkout → 503
- POST /api/webhooks/stripe → inert
- POST /api/stripe/connect/onboard → 503
- GET /api/stripe/connect/return → safe redirect
- enter-challenge-button: paid branch removed
- wallet: bank connect CTA removed
- challenge detail: Entry Fee = "Free", fee breakdown copy removed
- challenge card: entry fee badge suppressed
- how-it-works: cost FAQ + payout copy rewritten

### Commit c7c86ad — Gaming framing removed
- /legal/responsible-gaming → redirect to /legal/terms
- /legal/contest-rules → redirect to /legal/terms
- Footer: gaming disclaimer bar removed
- Onboarding: age gate, state dropdown, 6-checkbox compliance removed
- Middleware: US state geo-blocking removed; OFAC retained
- /unavailable: OFAC-only copy
- Wallet: restricted-state copy removed

### Intentionally inert (not deleted)
- src/lib/stripe.ts — functional but unreachable from UI
- Wallet W9/claim flow backend — retained for future payout system
- OFAC country blocking in middleware

---

## RAI — FULLY COMPLETE (2026-03-31 ~01:35 KL)
Git trail: 812b72d → 1675bb7 → e423617 → 02d24d4
All 6 RAI polish items browser-verified. Zero open items.
Migration 00039_rai_tightening.sql — written, needs Supabase SQL editor run.

### Key Files (RAI)
- src/app/api/challenges/[id]/invoke/route.ts
- src/app/api/v1/agents/[id]/endpoint/
- src/app/(public)/challenges/[id]/workspace/page.tsx
- src/components/settings/remote-invocation.tsx
- src/app/docs/remote-invocation/page.tsx
- src/lib/rai/
- supabase/migrations/00038_remote_invocation.sql — applied
- supabase/migrations/00039_rai_tightening.sql — written, needs SQL editor run
