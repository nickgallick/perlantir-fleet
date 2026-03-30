# Relay Playwright Automation Audit Progress — Bouts
**Date:** 2026-03-30
**Status:** INTERRUPTED — all 4 test packs ran, aborted during final report compilation
**Scope:** Full regression suite — public pages, auth/workspace flow, docs/routes, results/replay

---

## What Relay Completed Before Rate Limit

All 4 test packs were written AND executed. Relay was compiling the final written report when aborted.

### Test Packs Written (saved to /tmp/):
- `playwright-test-relay-smoke-public-20260330.js` — Layer 1: public navigation
- `playwright-test-relay-critical-auth-workspace-20260330.js` — Layer 2: auth + workspace + submission
- `playwright-test-relay-regression-docs-routes-20260330.js` — Layer 3: docs flows, route integrity
- `playwright-test-relay-regression-results-replay-20260330.js` — Layer 4: results + replay

---

## Raw Results Summary (from execution)

### Pack 1 — Smoke Public: 19 PASS / 4 FAIL
**Failures:**
1. **Homepage hero CTA — strict mode violation**: Two elements with same text "Enter Your First Bout →" — one links to `/challenges`, one to `/onboarding`. Playwright strict mode blocks this. Product issue: duplicate CTA with different destinations is confusing.
2. **Challenge detail page timeout**: `networkidle` timeout on sandbox challenge detail page — likely slow SSR/Supabase query on initial load.
3. **Dashboard redirect goes to `/agents` not `/login`**: Post-login, unauthenticated redirect goes to `/agents`. Relay's test expected `/login` but `/agents` may be intentional default. Needs clarification — if intentional, test needs updating.
4. **`/qa-login` returns HTTP 200**: Expected 404 in production. Returns 200 with custom "Not Found" UI. Security/hygiene finding (also confirmed by Aegis as AEG-P2-001).

### Pack 2 — Auth + Workspace: Results pending final tally
**Key finding:**
- **Submission status page infinite poll loop on unknown ID**: When navigating to `/submissions/00000000-0000-0000-0000-000000000000/status`, the page hangs — it appears to be in an infinite polling loop checking for a status that will never arrive. Page never shows a graceful "not found" or timeout state. This is a real UX/functional bug — a user whose submission ID is wrong or corrupted will be stuck on a spinner forever.

### Pack 3 — Docs/Routes: CLEAN SWEEP (all PASS)
- All docs sub-pages load correctly
- Auth-gated routes properly redirect
- Admin route protected
- No broken navigation links
- Critical CTAs all resolve

### Pack 4 — Results/Replay: Results pending final tally
- Relay was processing results when aborted

---

## Key Bugs Found (Relay-specific)

### P1 — Functional Bug
**REL-P1-001: Submission status page infinite poll on unknown/corrupted ID**
- `/submissions/{unknown-id}/status` spins forever
- No graceful timeout, no "not found" state, no error surface
- A real user with a wrong submission ID is permanently stuck
- Fix: Add max-poll timeout (e.g., 60s) and surface "submission not found" state

**REL-P1-002: Homepage has duplicate "Enter Your First Bout" CTA with different destinations**
- One links to `/challenges`, one to `/onboarding`
- Duplicate CTAs with different destinations confuses users and breaks strict-mode browser automation
- Fix: One primary CTA. If both paths are intentional, differentiate the labels.

### P2 — Quality Issue
**REL-P2-001: Challenge detail page slow initial load (networkidle timeout)**
- Sandbox challenge detail consistently slow to reach networkidle
- Suggests waterfall data fetching or blocking SSR queries
- Fix: Investigate server component data fetching pattern for challenge detail

### P3 — Test/Hygiene
**REL-P3-001: `/qa-login` returns HTTP 200 with "Not Found" UI**
- Consistent with Aegis finding AEG-P2-001
- Fix: Should return HTTP 404

---

## Resume Instructions for Relay

Start a new session and say:

"Relay — your automation audit progress was recovered at /data/.openclaw/workspace-relay/AUDIT-PROGRESS-2026-03-30.md.

All 4 test packs ran. You were compiling the final report when the session was cut off.

Key findings already extracted:
- P1: Submission status page infinite poll loop on unknown ID
- P1: Homepage duplicate CTA (Enter Your First Bout → /challenges AND /onboarding)
- P2: Challenge detail page slow networkidle timeout
- P3: /qa-login returns 200 instead of 404
- Pack 3 (docs/routes) was a clean sweep
- Pack 4 (results/replay) results need final tally

Please:
1. Write the full Relay audit report to /data/.openclaw/workspace-relay/RELAY-AUDIT-2026-03-30.md
2. Include: verdict (launch-safe / launch-safe with issues / not launch-safe), all findings by severity, evidence from the 4 packs
3. Send the P1 bug list to Forge for fixing
4. Note: DO NOT re-run the test packs — the results are already in this file"
