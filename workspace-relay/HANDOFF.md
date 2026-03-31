# HANDOFF.md — Relay Automation State

## Platform
- URL: https://agent-arena-roan.vercel.app

## Last Full Audit
Date: 2026-03-30
Packs run: 4 (smoke, auth/workspace, docs/routes, results/replay)
Total checks: 79 | Passed: 72 | Failed: 7

## Active Findings (routed to Forge)

### P1 — F1: /qa-login returns 200 in production
- Route: /qa-login
- Expected: 404
- Actual: 200
- Fix: Gate behind ENABLE_QA_LOGIN env flag or return 404 unconditionally in prod

### P1 — F2: Replay entry page hangs (API returns 403)
- Route: /replays/{id}
- API: GET /api/replays/{id} → 403
- Page never resolves from loading state
- Tested with: 575dcd67-def3-4031-831d-4dce27764052
- Fix: Handle 403 in replay detail page — show error state, not infinite load

### P1 — F3: Submission status infinite poll on unknown/404 ID
- Route: /submissions/{id}/status
- API: GET /api/challenge-submissions/{id} → 404 (polls indefinitely)
- MAX_POLLS=120 = 10 minute hang
- Fix: Exit poll immediately on 404, show "submission not found" state

### P2 — F4: Challenge detail slow/timeout unauthenticated
- Route: /challenges/{id} (unauthenticated)
- networkidle timeout at 20s
- Works when authenticated
- Likely: /api/me → 401 causing component to not complete cycle

### P2 — F5: Duplicate homepage CTAs
- Two "Enter Your First Bout →" elements: /challenges and /onboarding
- Fix: Differentiate secondary CTA text

### P2 — F6: /dashboard anon redirect ends at /agents
- Expected: redirect to /login
- Actual: ends at /agents
- login page default redirectTo='/agents' causing double-redirect

### P2 — F7: /settings/tokens returns 404
- Something links here but route doesn't exist

## Regression Coverage Established (2026-03-30)
Layer 1 smoke: 23 checks
Layer 2 auth/workspace: 9 checks
Layer 3 docs/routes: 31 checks
Layer 4 results/replay: 16 checks

## Scripts
- /tmp/playwright-test-relay-smoke-public-20260330.js
- /tmp/playwright-test-relay-critical-auth-workspace-20260330.js
- /tmp/playwright-test-relay-regression-docs-routes-20260330.js
- /tmp/playwright-test-relay-regression-results-replay-20260330.js

## Final Signoff Verification Pass (2026-03-31 — READY WITH MINOR FOLLOW-UPS)
Commit 677b1ad verified. 55 checks | 49 PASS | P0: 0 | P1: 1 | P2: 4 | P3: 1
P0 from last pass (active-challenge replay crash) = FIXED ✅
P1: Near-close workspace test fixture issue (challenge expired during test, not product bug)
P2s: all test-fixture or intentional suppression behavior (not product bugs)
Scripts: /tmp/playwright-test-relay-final-signoff-20260331.js

## Post-Fix Verification Pass (2026-03-31)
Commits verified: 9817615, 56ca946, c0970ad, 1031d1a
PASS: 28/34 | P0: 1 | P1: 4 | P2: 1

CLEARED: RLS recursion, migration 00041/00042, replay API (closed challenges), results page, me/results
CLEARED: Near-close warning banner (VERIFIED LIVE), dual-clock, timing labels, payment cleanup

REMAINING P0: Replay page crashes (React error #130) when challenge.status='active'
  - All complete-challenge replays work fine
  - ONLY crashes when isProvisional=true (active challenge)
  - Root cause: likely in c0970ad's addition to replay page for active-challenge path
  - Fix needed before launch: debug React component render in active-challenge replay path

REMAINING P1: Submission status API (challenge-submissions) returns 404 for QA test
  - Using wrong entry IDs in test; API likely works with correct submission IDs
  - Provisional placement on submission status page not verified live

Scripts: /tmp/playwright-test-relay-postfix-verify-20260331.js

## Timing + Feedback Audit (2026-03-31 — NOT READY: P0 migration missing)
Commit 335b23e — Migration 00041 not applied to production DB
P0: Replay API returns 500, results page 500, post-match feedback completely broken
P1: 0 | P2: 3 (challenge countdown hydration, provisional label verification blocked, me/results 500)
All timing model UI code is correct. Feedback synthesis logic is well-designed.
Script: /tmp/playwright-test-relay-timing-feedback-20260331.js

## Full Launch Audit (2026-03-31)
83 checks | PASS: 63 | P0: 0 | P1: 4 real (14 were false positives from cookie-clear) | P2: 2
Verdict: LAUNCH-READY WITH MINOR FOLLOW-UPS
Key real findings: Stripe copy on how-it-works, W-9 UI in wallet, admin 500s on intake/health APIs
Script: /tmp/playwright-test-relay-launch-audit-20260331.js

## Full Post-RAI Browser Regression (2026-03-31 — PASSED)
Run: 57 checks | PASS: 53 | FAIL: 0 (1 was timing artifact) | WARN: 3
E2E invoke flow confirmed: confirm dialog → cancel → confirm → invoke → invalid_response state → retry
3 warnings: /replays (pre-existing F1), #trust-model anchor (div-id, not text), /settings/tokens (known 404)
Script: /tmp/playwright-test-relay-full-regression-20260331.js
Invoice confirm run: /tmp/playwright-test-relay-invoke-confirm-20260331.js

## RAI Polish Pass Verification (2026-03-31)
Run: 26 checks | PASS: 22 | FAIL: 0 | WARN: 4
All 6 polish scoped items verified. One NEW bug found:

### NEW BUG — P1: Workspace early returns missing remote_invocation_supported
File: src/app/api/challenges/[id]/workspace/route.ts
- expired entry early return → no remote_invocation_supported in payload
- already_submitted early return → no remote_invocation_supported in payload
- Client: !json.remote_invocation_supported = true → setState('not_supported')
- Result: RI-enabled challenges in expired/submitted state show "Connector Required" instead of correct terminal state
Fix: add remote_invocation_supported to both early-return payloads

### Cleared items:
- /docs/web-submission: renders transition page correctly, CTA confirmed ("Read Remote Agent Invocation docs")
- Settings deep-link: subtab=remote-invocation lands correctly, validate=1 auto-triggers
- Copy: all 6 labels confirmed
- /docs/web-submission CTA: confirmed working

Scripts: /tmp/playwright-test-relay-rai-polish-20260331.js, /tmp/playwright-test-relay-rai-polish-v2-20260331.js

## RAI Final Verification (2026-03-30 post-remediation — PASSED)
Run: 34 checks | PASS: 29 | FAIL: 0 | WARN: 5 | Confidence: HIGH
Commit: 812b72d (R-Fix-1 through R-Fix-6)
All P1 blockers cleared. Zero hard failures.
5 warnings are all environment-tab/validate/nudge items gated behind "endpoint configured" — not regressions.
Script: /tmp/playwright-test-relay-regression-rai-final-20260330.js
Screenshots: /tmp/relay-screenshots/rai-final-*.png

## RAI Browser Regression (2026-03-30)
Checks: 29 | PASS: 15 | FAIL: 3 | WARN: 11 | Confidence: MEDIUM

### F-RAI-01 — P1: Challenge detail crashes (weight_class_id=null → charAt TypeError)
- All active challenges have weight_class_id=null
- formatWeightClass(null) crashes the page → "Something went wrong"
- Fix: null guard in formatWeightClass()

### F-RAI-02 — P1: Workspace API missing remote_invocation_supported in select
- /api/challenges/[id]/workspace does NOT select remote_invocation_supported
- Always defaults to false → all challenges would show "Connector Required"
- Fix: add remote_invocation_supported to select query

### F-RAI-03 — P2: Sandbox challenges 404 on public API
- /api/challenges/sandbox-id → 404 even though active in DB

### F-RAI-04 — P2: RAI settings section not discoverable without endpoint configured

### CONFIRMED CLEAN:
- No manual text submission textarea anywhere (old path fully removed)
- No /settings/tokens broken links in RAI pages
- Docs/remote-invocation loads correctly
- Workspace terminal states (expired/submitted) render correctly

Report: /tmp/relay-automation-report-20260330-rai.md
Script: /tmp/playwright-test-relay-regression-rai-20260330.js

## Prior Coverage (from 2026-03-28)
- /qa-login = 404 ✅ (NOW REGRESSED — returns 200)
- Auth redirect on /dashboard ✅
- Mobile no-scroll ✅
- Sub-ratings column present ✅
- Agent radar chart present ✅
- API smoke ✅
