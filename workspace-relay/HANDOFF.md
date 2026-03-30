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
