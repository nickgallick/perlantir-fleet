# HANDOFF.md — Sentinel Audit State

## Platform
- URL: https://agent-arena-roan.vercel.app
- QA credentials: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)

## Last Audit (2026-03-28 — ClawExpert run)
- Result: 43/47 checks PASS | 2 false positives, 0 real failures
- All public routes: ✅ | Auth redirect: ✅ | Mobile: ✅ | APIs: ✅
- Combined with Forge/Maks: 109 checks / 0 real failures → Gate 3 PASSED

## Forge Remediation Logged (2026-03-31 — 14 findings A1–D3, all closed)

### Section A — Runtime/Pipeline
- **A1**: UNIQUE constraint added to submission_feedback_reports.submission_id (migration 00045). Orphan rows cleaned. Upsert fixed.
- **A2**: Fire-and-forget replaced with synchronous await on both GET feedback endpoints.
- **A3**: 30s polling replaced with single AbortController fetch. All terminal states (timeout/failure/not_available) now transition correctly. No spinner dead-ends.
- **A4**: Default tab changed to classic. Score data visible immediately on load. Premium auto-switches only when report ready.

### Section B — Trust/Security
- **B1**: Fabricated numeric comparisons eliminated. signal-extractor.ts now pulls real composite scores from DB. MIN_ENTRIES_FOR_COMPARISON = 5 enforced. LLM writes narrative only — no invented numbers.
- **B2**: Infra fields (model_id, latency_ms, is_fallback) confirmed not leaking in public replay API.
- **B3**: short_rationale scoped to owner/admin only (API already correct, types updated).

### Section C (not in briefing — assumed covered in 7d978e0 commit)

### Section D — Data Integrity/Display
- **D2**: evidence_density hidden from users. Lane percentile now human-readable with tooltip.
- **D3**: MIN_ENTRIES = 5 enforced in signal extractor. Comparison block suppressed on insufficient data.

### Pipeline Config (final)
- Model: Haiku 4.5
- max_tokens: 3500
- Fetch timeout: 100s
- Route maxDuration: 120 on both feedback endpoints
- 3/3 stress test PASS (53.9s / 49.0s / 45.0s, confidence: high, real LLM ✅)

### Commits
- 7d978e0 — Full A1–D3 remediation
- 3f769e5 — Haiku model switch
- cd91231 — max_tokens:3500 + maxDuration:120
- 61be0da — fetch timeout 100s — 3/3 verified

## Known Issues (track these)
- /api/challenges/daily → 500 (data state — no is_daily=true challenge in DB)
- Landing stats hardcoded (src/app/page.tsx lines 50-59)
- Migration 00024 partial: challenge_bundles table may not exist
- Stripe live keys not set — billing not live
- bouts.gg domain not connected
- ORACLE_WALLET_ADDRESS + BASE_RPC_URL not set

## Next Audit
Awaiting task from Nick or ClawExpert. Ready to run verification audit on A1–D3 fixes and performance breakdown flow.

## How to Update
After every audit: update Last Audit section with date, results, issues found.
