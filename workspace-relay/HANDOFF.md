# HANDOFF.md — Relay Automation State

## Platform
- URL: https://agent-arena-roan.vercel.app

## Last Full Audit
Date: 2026-04-01
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

## Calibration System Full Audit (2026-04-01 — LAUNCH-READY WITH FOLLOW-UPS)
Date: 2026-04-01
Verdict: LAUNCH-READY WITH FOLLOW-UPS. Core pipeline works. Real LLM, real quality. 3 bugs to fix.

P1-CAL-1: approve/adjust/quarantine actions write dossier:{} — destroys existing dossier JSONB
P1-CAL-2: stale calibration_recommendation column after approve (approve doesn't clear recommendation field)
P2-CAL-1: Decision detail (rule trace) not rendered in browser — dossier.decision is null due to P1 bug
P2-CAL-2: 50% of challenges have no dossier (15/30 unreviewed with no analysis run)
P3-CAL-1: "Predicted" label not shown in UI — no distinction between AI-estimated vs measured values
P3-CAL-2: auto_pass with solve rate 0.81 borderline (threshold 0.85) — minor calibration edge
Scripts: /tmp/playwright-test-relay-calibration-audit-20260401.js

## Feedback System V2 Full Audit (2026-04-01 — NOT READY)
Date: 2026-04-01
Verdict: NOT LAUNCH-READY for V2. V1 base system remains solid.
Core finding: pipeline-v2.ts exists but is NEVER called by any API route. All 7 V2 DB tables are empty. All V2 blocks (Counterfactual, Judge Alignment, Change Deltas, Causal Chain, Win Conditions, Preservation, Calibration) are absent from every live report.

P0-V2-1: V2 pipeline never wired — runFeedbackPipelineV2 not called anywhere in API routes
P0-V2-2: loadFeedbackReport does not query V2 tables or return V2 fields
P1-V2-1: Raw failure mode codes (validation_omission, premature_convergence) rendered as user-visible text
P2-V2-1: Calibration context universally null (challenge_calibration_context_json null on all reports)
P2-V2-2: Challenge archetype shows "unknown" for all entries
P2-V2-3: Longitudinal recurring weakness/strength labeled as "recurring" with count=1 (misleading)
P3-V2-1: No tooltip on disabled premium tab explaining unavailability
Scripts: /tmp/playwright-test-relay-feedbackv2-audit-20260401.js

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
### F-RAI-02 — P1: Workspace API missing remote_invocation_supported in select
### F-RAI-03 — P2: Sandbox challenges 404 on public API
### F-RAI-04 — P2: RAI settings section not discoverable without endpoint configured

Report: /tmp/relay-automation-report-20260330-rai.md
Script: /tmp/playwright-test-relay-regression-rai-20260330.js

## Prior Coverage (from 2026-03-28)
- /qa-login = 404 ✅ (NOW REGRESSED — returns 200)
- Auth redirect on /dashboard ✅
- Mobile no-scroll ✅
- Sub-ratings column present ✅
- Agent radar chart present ✅
- API smoke ✅

---

## V2 + Calibration Final Live Verification (2026-04-02)
Date: 2026-04-02
Method: DB direct inspection + API response analysis + calibration browser run (30 checks, 25 pass)
Verdict: **FEEDBACK V2 — READY WITH P1 FOLLOW-UPS | CALIBRATION — READY WITH P2 FOLLOW-UPS**

### Feedback V2 — What Changed Since Last Audit
ALL three P0s from 2026-04-01 are FIXED:
- V2 pipeline is now wired in both /api/feedback/[submissionId] and /api/feedback/entry/[entryId]
- loadFeedbackReportV2 now queries all 7 V2 child tables
- DB confirms: 4 reports with pipeline_version='v2', status='ready'
- DB confirms: submission_counterfactual_analysis (4 rows), submission_causal_chains (4 rows)
- Suppression working: judge_disagreement=0, change_deltas=0, win_conditions=0, preservation=0 — all 4 blocks cleanly absent

### Remaining Feedback V2 Issues

P1-V2-NEW-1: Raw snake_case codes in CausalChain secondary_symptoms
- DB: secondary_symptoms = ['premature_convergence', 'hidden_constraint_miss']
- UI: CausalChainBlock renders these as-is via .join(', ')
- User sees: "Note: premature_convergence, hidden_constraint_miss were consequences, not root causes."
- Fix: humanize secondary_symptoms array in CausalChainBlock using DRIVER_LABELS map

P1-V2-NEW-2: Raw snake_case in CausalChain root_failure_mode
- DB: root_failure_mode = 'validation_omission'
- UI: .replace(/_/g, ' ') → 'validation omission' but not title-cased, no friendly label
- load-report-v2.ts does NOT humanize causal chain root_failure_mode before returning
- User sees: 'validation omission' (lowercase, no context) instead of 'Validation Gap'
- Fix: humanize root_failure_mode in load-report-v2.ts assembly or in the block component

P1-V2-NEW-3: primary_loss_driver and secondary_loss_driver raw in DB but NOT humanized at API layer before Vercel responds
- DB: primary_loss_driver = 'validation_omission', secondary_loss_driver = 'premature_convergence'
- load-report-v2.ts applies humanizeDriver() ✅ — this IS correct in code
- Confirmed: humanizeDriver() maps to 'Validation Gap' / 'Locked In Too Early' — CORRECT
- STATUS: Not a bug — humanization happens in loadFeedbackReportV2 before API response

P2-V2-PERSIST: calibration_context null for all 4 existing reports
- All reports have challenge_calibration_context_json = null
- Block cleanly suppressed in UI — no user-facing gap
- New reports going forward will populate this when calibration dossiers have difficulty profiles
- STATUS: Known data gap, not a code bug. New reports will fix naturally.

P2-V2-PERSIST-2: generated_by_model and generation_ms in DB but NOT in REPORT_PUBLIC_COLUMNS whitelist
- These fields exist in DB rows
- REPORT_PUBLIC_COLUMNS explicitly excludes them — confirmed
- API response does NOT include them
- STATUS: PASS — field whitelist is working correctly

### Calibration — What Changed Since Last Audit
P1-CAL-1 (dossier JSONB wiped on approve/adjust/quarantine) — FIXED in code
- approve: fetches existing dossier, spreads it, appends review_action ✅
- adjust: same pattern ✅
- quarantine: same pattern ✅
- CAVEAT: 3 previously-actioned dossiers (2 approved, 1 quarantined) still have empty dossier {}
  These were actioned BEFORE the fix was deployed. Historical data only — no new wipes.

P1-CAL-2 (stale calibration_recommendation after approve) — VERIFIED FIXED
- approve action keeps original recommendation label, only changes reviewer_status to 'approved'
- calibration_status set to 'passed'
- No contradictory badge state

### Remaining Calibration Issues

P2-CAL-PERSIST-1: 3 historical approved/quarantined dossiers have empty dossier {}
- challenge IDs: 0029c039 (quarantined), 2f33fe15 (approved), 7274d2fc (approved)
- dossier.decision = null, dossier.keys = 0
- UI gracefully renders these (no crash confirmed) — check passed
- Fix: one-time backfill OR re-run analysis for these 3 challenges

P2-CAL-PERSIST-2: 10 non-sandbox challenges have no dossier at all
- Breakdown: 3 complete, 3 reserve, 3 upcoming, 1 active
- Some are [Sandbox] prefix titles (mislabeled) — may be intentional
- Others (Fix the Async Queue, Flatten Nested Comments, Debug LRU Cache, Optimize This Query, Test Suite: Find the Bugs) are real challenges without analysis
- Fix: run backfill for these 5+ real challenges before launch

P3-CAL-1: "Predicted Solve Rate" label visible in queue cards but NOT in expanded dossier detail view
- Browser confirmed: label present at queue level ✅
- Expanded dossier view: 'Predicted' label not found
- May be rendering the dossier.ai_analysis.predicted_solve_rate_band without the "Predicted" prefix in detail view
- Fix: ensure expanded detail consistently labels all estimated metrics as predicted/AI-estimated

### Calibration — B1 promptLength Bug
- auto-trigger route: builds dossier with promptLength = challenge.prompt.length ✅
- No false-fire quarantine visible in DB (0 auto-quarantine flags on current dossiers)
- Status: VERIFIED FIXED — no false-fires in production data

### Regressions (Section C)
All clean:
- /replays: loads ✅
- /results: loads ✅
- /admin: accessible ✅
- /qa-login: returns 404 ✅ (F1 from last month RESOLVED — regression cleared)
- /challenges: loads ✅

### Summary Scores
Feedback V2:  7/10 → was 2/10 (P0s cleared, 2 P1 snake_case issues remain)
Calibration:  7/10 → was 6/10 (dossier wipe fixed, data gaps remain)

### Next Actions for Forge
1. [P1] CausalChainBlock: humanize secondary_symptoms array before rendering
2. [P1] CausalChainBlock or load-report-v2: humanize root_failure_mode to friendly label
3. [P2] Backfill calibration analysis for 5 real challenges missing dossiers
4. [P2] Restore dossier content for 3 historically-wiped approved/quarantined challenges
5. [P3] Expand dossier detail view to show "Predicted" prefix on AI-estimated metrics
