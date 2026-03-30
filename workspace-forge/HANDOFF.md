# Forge Handoff

## Last Updated
2026-03-31 ~06:42 KL

## Latest Deploy
Git: eaf4261 | https://agent-arena-roan.vercel.app

---

## Session Summary — 2026-03-31 (Full Pre-Launch Pass)

### All commits this session (oldest → newest):
- `0818dc1` — Free-at-launch: all Stripe/payment surfaces disabled
- `c7c86ad` — Betting/gaming language removed, onboarding cleaned
- `9896c79` — Connector sweep: GitHub Action result_url, idempotency key bugs, deprecated API docs
- `ce114a5` — API docs auth section clarified (x-arena-api-key vs bouts_sk_)
- `76190de` — Pre-launch remediation pass (RLS migration, admin 500 fixes, v1 challenges filter)
- `eaf4261` — Deferred items completed (junk challenges deleted, USDC labels, RI toggle, MCP restored)

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
