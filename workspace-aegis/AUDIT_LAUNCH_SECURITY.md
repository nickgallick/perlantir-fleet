# Aegis — Full Launch Security & Trust Audit
**Date:** 2026-03-31
**Scope:** Full launch security, control plane, billing exposure, submission trust
**Method:** Live verification + code review. Every finding is live-verified unless marked [CODE ONLY].
**Verdict:** TRUST-SAFE WITH MINOR FOLLOW-UPS

---

## Executive Verdict

The platform is trust-safe for launch. No P0s found. Two P1s — one informational data hygiene issue (non-active challenges exposed in v1 API), one billing surface concern (wallet/claim route is live code with Stripe in test mode). All admin control plane routes are correctly protected. All submission trust controls hold.

---

## P0 Findings — None

---

## P1 Findings

### P1-001: /api/v1/challenges exposes upcoming/reserve challenges to unauthenticated users

**Surface:** Public API exposure  
**Live verified:** Yes  
**Route:** GET `/api/v1/challenges`

The v1 challenges endpoint does not enforce `status=active` for unauthenticated/public requests. The regular `/api/challenges` route correctly filters to `status=active AND is_sandbox=false AND org_id IS NULL` for non-admins. The v1 route applies org and sandbox filters but **not** a status filter.

**Live evidence:**
```bash
curl https://agent-arena-roan.vercel.app/api/v1/challenges
# Returns: {"data":[...20 challenges...],"pagination":...}
# Status distribution: upcoming: 7, reserve: 13 — 0 active
```

**What's exposed:**  
Title, description, category, format, starts_at, ends_at, difficulty_profile — but NOT prompt, hidden tests, or any admin-only field. The prompt is not in the column select for this endpoint.

**Risk:** Competitors could enumerate upcoming/reserve challenges and see their titles/descriptions before they're activated. No scoring data, no prompt, no hidden tests leaked. Pure information disclosure — someone could see that "Sliding Window Rate Limiter" is in reserve and mentally prepare.

**Fix:** Add `.eq('status', 'active')` for non-admin/non-authenticated requests in the v1 challenges route, matching the behavior of the regular `/api/challenges` route.

---

### P1-002: Wallet/claim route is live code, claim button visible in UI, Stripe in test mode

**Surface:** Billing/payment  
**Live verified:** Partially (route is live, Stripe in test mode confirmed by key prefix)  
**Route:** POST `/api/prizes/claim`, GET/display `/dashboard/wallet`

The wallet page (`/dashboard/wallet`) is accessible (auth-gated, requires login) and shows a real claim interface including "Claim Prize" buttons. The `/api/prizes/claim` route is fully implemented — it deducts coins, checks W-9 threshold ($600), checks restricted states, and calls `stripe.transfers.create()` if a Stripe Connect bank account is connected.

**Stripe key:** `sk_test_...` — test mode, no real money movement possible today. However:
1. The UI says "Prize payouts are coming soon" but also shows live balance and functional claim buttons
2. Users who have earned coins (300/350 for active challenges) could click "Claim"
3. If Stripe key is switched to `sk_live_` without disabling the route, real transfers fire immediately
4. W-9 collection stores tax_id_last4 and personal data even in test mode

**Current risk:** No real money exposure (test key). But this is a latent risk if key rotation happens before route is properly gated.

**Fix:** Feature-flag the claim button behind `prizes_enabled: false` or disable route with 503 stub (like checkout already has). Remove or clearly hide claim button until live. Do not rotate to live Stripe key without first gating the route.

---

## P2 Findings

### P2-001: /admin and /admin/challenges return HTTP 200 to unauthenticated requests

**Surface:** Admin/control plane  
**Live verified:** Yes

`/admin` and `/admin/challenges` both return HTTP 200 rather than 302/307 redirect to unauthenticated users. The middleware does not include `/admin` in `PROTECTED_DASHBOARD_PATHS`. Server-side auth works (admin/page.tsx does `redirect('/login?redirect=/admin')` server-side, admin/challenges is `use client` and handles 401 from API calls) but the HTTP status code is 200 rather than a redirect.

**What unauthed users actually see:**  
- `/admin` — RSC redirect payload embedded in 200 HTML; browser is redirected to `/login?redirect=/admin`. No admin data in page. Confirmed: 0 admin fields in RSC chunks.
- `/admin/challenges` — Page skeleton renders (200), then fetch to `/api/admin/challenges` returns 401, then client-side redirect to `/login`. No challenge data rendered.

**Risk:** No admin data exposed. But a 200 status on admin routes is technically incorrect and could confuse monitoring/security scanners. The actual data protection (API 401) is correct. This is a defense-in-depth gap — the page renders before finding out the user is unauthorized.

**Fix:** Add `/admin` to `PROTECTED_DASHBOARD_PATHS` in middleware.ts. One-line fix, complete defense-in-depth.

---

### P2-002: Stripe CSP directives active even though payments are disabled

**Surface:** Billing/payment, public API  
**Live verified:** Yes

The Content-Security-Policy header includes `connect-src https://api.stripe.com` and `frame-src https://checkout.stripe.com` on all pages, including public ones. Stripe JS is not loaded on public pages (confirmed: no stripe JS on landing page). However, the CSP signals to any security scanner or auditor that Stripe is expected to be active.

**Risk:** Informational. Could confuse launch reviewers or legal/compliance review. No active risk.

**Fix:** Post-launch cleanup: when billing is ready, these are already correct. If delaying billing significantly, consider removing from CSP until active.

---

### P2-003: Remote invocation toggle admin-API exists but no admin UI

**Surface:** Admin/control plane  
**Code verified only**

`/api/admin/challenges/[id]` (PATCH) accepts `remote_invocation_supported: boolean` and can toggle RAI per challenge. However, there is no admin UI surface (toggle in admin/challenges page) to use it. The only way to toggle is via direct API call.

**Risk:** Low operational risk — admin must use curl to enable/disable RAI per challenge. Current state is safe (default-off, 2 manually enabled). If an admin needs to disable RAI quickly on a challenge, there's no one-click UI path.

**Fix:** Add a toggle in the admin/challenges page UI for `remote_invocation_supported`. Not a security issue, but an operator efficiency gap.

---

## P3 Findings

### P3-001: GAUNTLET_INTAKE_API_KEY in workspace documentation files

**Surface:** Secret management  
**Code verified only**

Already logged in prior audit. Key is in TOOLS.md. Not in NEXT_PUBLIC_ config, not in any public response. Low risk. Rotate periodically.

---

### P3-002: Stripe webhook stub returns 200 to all POST requests without signature verification

**Surface:** Billing/payment  
**Live verified:** Yes

`/api/webhooks/stripe` is a stub (`return NextResponse.json({ received: true })`). It returns 200 to any POST regardless of signature. This is harmless today (does nothing), but if the stub is replaced with real webhook handling without adding signature verification, it becomes a P0.

**Note in code:** "Stripe webhook disabled — payments not active at launch. Re-enable when paid challenge tiers ship."

**Fix:** When re-enabling, add `stripe.webhooks.constructEvent()` signature verification before any payload processing. The stub is safe as-is.

---

### P3-003: /api/stripe/connect/return returns 307 to unauthenticated users

**Surface:** Billing/payment  
**Live verified:** Yes

The Stripe Connect return URL (`/api/stripe/connect/return`) returns a 307 redirect for unauthenticated requests rather than 401. The redirect target was not captured in testing but is non-critical since Connect onboarding is disabled (503 stub on `/api/stripe/connect/onboard`).

---

## Section-Level Results

### 1. Admin / Control Plane Security

| Check | Result |
|-------|--------|
| All /api/admin/* routes unauthed → 401 | ✅ Confirmed live |
| /admin/challenges/[id]/quarantine unauthed | 401 ✅ |
| /admin/challenges/[id]/activate unauthed | 401 ✅ |
| /admin/challenges/[id]/retire unauthed | 401 ✅ |
| All /api/admin/* use requireAdmin() | ✅ 0 routes missing it |
| /admin page renders to 200 for unauthed (skeleton only, no data) | ⚠️ P2-001 |
| Admin-only fields not in public APIs | ✅ Confirmed live |
| remote_invocation_supported toggle API gated | ✅ (401 unauthed) |
| RAI toggle has admin UI | ⚠️ P2-003 (no UI) |
| Challenge status visibility filtering | ✅ Main API; ⚠️ v1 API (P1-001) |
| Sandbox isolation | ✅ Both APIs enforce is_sandbox filter |
| Admin agents/cleanup, compute-reputation | 401 ✅ |

### 2. Public/API Boundary Checks

| Check | Result |
|-------|--------|
| 37 auth-required endpoints tested | All 401 ✅ |
| Org/private challenge separation | ✅ Both APIs enforce org_id filter |
| Sandbox/public separation | ✅ Both APIs enforce is_sandbox filter |
| Admin fields in public APIs | NONE ✅ |
| Draft/quarantine challenges in public API | NONE in main; ⚠️ upcoming/reserve in v1 (P1-001) |
| Legacy submission loopholes | None ✅ |
| Stack traces in errors | None ✅ |
| Internal paths in errors | None ✅ |

### 3. RAI / Submission Trust Model

| Check | Result |
|-------|--------|
| Default-off, live DB 185/187 false | ✅ |
| SSRF protection at registration + invocation | ✅ |
| Redirect fail-closed | ✅ |
| Zero retries enforced | ✅ |
| Provenance by audience | ✅ |
| Non-RAI challenges blocked | ✅ |
| Old web-submit path inert | ✅ (5 deliberate, not loopholes) |
| Billing changes did not reopen paths | ✅ |
| Connector terminal status enforcement | ✅ |
| DB UNIQUE INDEX on submissions(entry_id) | ✅ |
| One-shot semantics | ✅ |

### 4. Payment/Billing Exposure

| Check | Result |
|-------|--------|
| Stripe key is test mode | ✅ sk_test_ confirmed |
| No real money movement possible | ✅ |
| Checkout/entry fee routes return 503 | ✅ |
| Wallet page: "coming soon" message present | ✅ |
| Wallet claim button: visible and functional in UI | ⚠️ P1-002 |
| Stripe webhook: stub, returns 200 to all | ⚠️ P3-002 (safe as stub) |
| Prize payout route: live code, Stripe test mode | ⚠️ P1-002 |
| /api/stripe/connect/onboard: 503 | ✅ |
| W9 collection route: live, collects last4 | ⚠️ P1-002 (use caution) |
| Stripe JS not loaded on public pages | ✅ |
| Coins on active challenges (300-350) | Present but judging does not award coins yet |

---

## Explicit Answers

**Can launch be operated safely from the admin side?**  
Yes. All admin API routes are correctly gated. `requireAdmin()` is used on all /api/admin/* routes. Admin can manage challenges, quarantine, activate, calibrate, and review via API. The only gap is no UI toggle for remote_invocation_supported (P2-003) — manageable via direct API call.

**Are any admin routes or controls exposed incorrectly?**  
No API routes are exposed. `/admin` and `/admin/challenges` return HTTP 200 (page skeleton) rather than 302/redirect before confirming auth — a defense-in-depth gap (P2-001). No admin data is served to unauthed users via these pages.

**Are any payment/billing remnants still exposed?**  
The wallet page is accessible to authenticated users with a functional claim button. Stripe is in test mode — no real money movement. The `/api/prizes/claim` route is live code and calls Stripe if a bank is connected. This is the main billing concern before launch (P1-002). All checkout/onboarding routes return 503.

**Is there any hidden legacy submission loophole?**  
No. The `/api/challenges/[id]/web-submit` route exists but requires `web_submission_supported=true` (only 5 deliberately enabled challenges). All submission paths tag `submission_source`. DB UNIQUE INDEX on `submissions(entry_id)` prevents race conditions. Connector submit checks terminal entry status. `/api/v1/submissions` POST returns 410 DEPRECATED.

**Is there anything that must be disabled or hidden before launch?**  
One clear action: feature-flag or stub the wallet claim button and `/api/prizes/claim` route until Stripe goes live (P1-002). The route processes real coin deductions now and calls Stripe — even in test mode, users shouldn't be able to initiate "claims" that don't actually pay out and may confuse them. Add a "coming soon" guard on the route matching the other billing stubs.

The v1 API status filter (P1-001) should be fixed but is lower urgency — the challenge data exposed has no prompt, no hidden tests, just title/description/status.

---

## Launch Readiness

**TRUST-SAFE WITH MINOR FOLLOW-UPS.**

Pre-launch required:
1. **P1-002:** Stub `/api/prizes/claim` with 503 or feature-flag the claim button until Stripe goes live
2. **P1-001:** Add status=active filter to `/api/v1/challenges` for non-admin requests

Nice to have before launch:
3. **P2-001:** Add `/admin` to middleware PROTECTED_DASHBOARD_PATHS
4. **P2-003:** Add remote_invocation_supported toggle to admin UI

Safe to defer:
5. P2-002, P3-001, P3-002, P3-003
