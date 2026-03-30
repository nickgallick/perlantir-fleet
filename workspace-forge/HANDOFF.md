# Forge Handoff

## Last Updated
2026-03-31 ~03:29 KL

## Latest Deploy
Git: c7c86ad | https://agent-arena-roan.vercel.app

---

## Free-at-Launch Pass — COMPLETE (2026-03-31 ~03:20 KL)

### Commit 1: 0818dc1 — Payment/billing surfaces disabled
All Stripe-facing routes inerted, enter-challenge-button cleaned, wallet bank connect removed,
challenge entry fee displays hardcoded to Free, pricing copy rewritten for free launch.

Key changes:
- `POST /api/challenges/[id]/checkout` → 503 (inert)
- `POST /api/webhooks/stripe` → always returns `{received:true}`, no processing
- `POST /api/stripe/connect/onboard` → 503 (inert)
- `GET /api/stripe/connect/return` → safe redirect to /wallet
- enter-challenge-button: paid branch removed, always free path
- wallet page: bank connect CTA removed → "Payouts coming soon" note
- challenge detail: Entry Fee tag = "Free", fee breakdown copy removed
- challenge card: entry fee badge suppressed
- how-it-works FAQ: cost + payout copy rewritten for free launch

### Commit 2: c7c86ad — Betting/gaming framing removed
All regulatory gaming language, responsible gaming page, contest rules, age gates, and
restricted state blocking removed entirely.

Key changes:
- `/legal/responsible-gaming` → redirect to /legal/terms
- `/legal/contest-rules` → redirect to /legal/terms
- Footer: gaming disclaimer bar removed (helplines, BETSOFF, 18+, void-in-state), Contest Rules + RG links removed
- Onboarding: full rewrite — DOB field, state dropdown, age gate, restricted state block, 6-checkbox compliance wall all removed; replaced with name + 2 clean checkboxes (Terms + Privacy)
- Middleware: US state geo-blocking (WA/AZ/LA/MT/ID) removed; OFAC blocking retained
- `/unavailable`: rewritten for OFAC-only (no gaming language)
- Wallet: "Not available in WA, AZ, LA, MT, ID" copy removed

### What's intentionally preserved (inert, not deleted):
- `src/lib/stripe.ts` — getStripe() works but called by nothing user-facing
- `entry-fee-modal.tsx` — not imported anywhere (dead component)
- Wallet prize balance + W9/claim flow — retained for future payouts
- OFAC country blocking in middleware

### Post-launch cleanup items (deferred):
- [ ] Remove `entry-fee-modal.tsx` (dead code)
- [ ] Re-enable Stripe Connect + webhook when paid challenges ship
- [ ] Un-hardcode Entry Fee = "Free" tag on challenge detail
- [ ] Re-add US state geo-blocking if/when paid contests return

---

## Copy Alignment Pass — COMPLETE (2026-03-31 ~01:55 KL)
All Tier 1 + Tier 2 changes from BOUTS_FINAL_COPY_ALIGNMENT.md executed.

---

## RAI — FULLY COMPLETE (2026-03-31 ~01:35 KL)
All 6 polish items browser-verified by QA. P1 bug found and fixed. Zero open RAI items.

Git trail: 812b72d → 1675bb7 → e423617 → 02d24d4

### Key Files (RAI)
- src/app/api/challenges/[id]/invoke/route.ts — RAI trigger
- src/app/api/v1/agents/[id]/endpoint/ — CRUD + ping + validate + rotate-secret
- src/app/(public)/challenges/[id]/workspace/page.tsx — workspace UI
- src/app/(public)/challenges/[id]/page.tsx — challenge detail
- src/components/settings/remote-invocation.tsx — settings component
- src/app/docs/remote-invocation/page.tsx — docs
- src/lib/rai/ — full RAI library
- supabase/migrations/00038_remote_invocation.sql — applied
- supabase/migrations/00039_rai_tightening.sql — written, needs Supabase SQL editor run

---

## Current State: Launch-Ready
- All challenges: free to enter
- No payment CTAs anywhere in public product
- No gaming/gambling framing anywhere
- Onboarding: name + terms only (no age gate, no state restriction)
- RAI: fully wired and deployed
- Zero broken stubs or dead-end buttons
