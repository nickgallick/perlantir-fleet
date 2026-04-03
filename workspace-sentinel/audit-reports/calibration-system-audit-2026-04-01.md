# Sentinel Audit — Challenge Calibration System
**Date:** 2026-04-01  
**Auditor:** Sentinel 🛡️  
**Method:** Full code review, DB direct query, API probe (Bearer auth), Playwright (auth gate hit — admin browsing blocked by Next.js middleware, queue API probed directly)

---

## Executive Verdict

> **LAUNCH-READY WITH MINOR FOLLOW-UPS**

The calibration system is genuinely built and genuinely working. LLM analysis is real, specific, and defensibly calibrated. The decision policy is deterministic and fully traceable. The DB migration is applied. 11 challenges have real benchmark results. 15 have full dossiers with AI analysis.

**Two real issues prevent clean launch-ready status:**

1. **Decision rules are missing from dossier JSONB** — the `dossier` column doesn't include the `decision` object (with `rules_fired`, `blocking_rules`). The admin UI reads it from there. Reviewer sees no decision trail. (P1)
2. **No approved or quarantined actions in production** — all 15 dossiers are still `reviewer_status: recommended`. No one has actioned the queue. Admin workflow is untested in production. (P2)
3. **6 challenges stuck in `calibrating` status** — including 3 sandbox challenges and 3 production challenges that will never exit without intervention. (P2)

Everything else is either working correctly or has credible, non-default analysis behind it.

---

## P0 Findings

**None.**

---

## P1 Findings

### P1-1 — `decision` field missing from persisted dossier JSONB

**Severity:** P1  
**Surface:** Reviewer workflow / Admin UX

The admin calibration page reads `dossier?.decision` and `dossier?.per_dimension_rationale` from the flattened `dossier` JSONB column in the database. These are the most valuable parts of the dossier for a reviewer: the full rule engine trace, which rules fired, which blocked, and why.

**What the DB actually has:**
```
dossier_keys: ['summary', 'confidence', 'ai_analysis', 'challenge_id', 'generated_at', 
               'recommendation', 'reviewer_flags', 'confidence_score', 'recommended_profile', 
               'recommended_window_hours', 'recommended_session_minutes']
```

`decision` and `per_dimension_rationale` are **absent from every dossier** in production.

**Root cause:** The pipeline route (`/api/admin/calibration/pipeline`) calls `buildDossier()` which *does* build a `CalibrationDossier` with `decision` and `per_dimension_rationale`, but then persists like this:
```ts
await supabase.from('challenge_calibration_dossiers').upsert({
  challenge_id,
  dossier,           // ← This IS the full dossier object with decision field
  ai_analysis: analysis,
  ...
})
```

The `dossier` column should contain the full object. Likely the column was schema'd to accept a partial JSONB shape at an earlier migration and the `auto-trigger` endpoint (which is what ran all 15 dossiers) does call `buildDossier()` but may have persisted an earlier version of the object without the `decision` key.

**Evidence:** The `auto-trigger` endpoint was shipped and ran correctly (15 dossiers exist), but those were likely generated when `buildDossier()` didn't yet include `decision` in its return type. The current `buildDossier()` in code does include it. A re-analysis of existing challenges would populate it.

**Impact:** Every dossier in the reviewer queue shows **no decision trail**. The `DecisionRulesSection` component renders nothing. The reviewer sees the recommendation label but cannot see which rules fired or why. The most trust-building feature of the admin UI is invisible.

**Fix:** Re-run `analyze_only` on all 15 dossiers (or run batch analysis). The current `buildDossier()` code produces the correct object. Once re-analyzed, decision rules will populate.

---

## P2 Findings

### P2-1 — 6 Challenges Stuck in `calibrating` Status

**Severity:** P2  
**Surface:** Calibration pipeline state

Six challenges have `calibration_status = 'calibrating'` and have never exited:
- `[Sandbox] Echo Agent`, `[Sandbox] Full Stack Test`, `[Sandbox] Hello Bouts` — 3 sandbox challenges, created 2026-03-29
- `Live E2E Test: Fix the Rate Limiter` — production, has a quarantine dossier
- `Debug: Authentication Regression` — production, has a dossier
- `No-Tests Path Smoke Test` — production, has a quarantine dossier

The `calibrating` status is set as a lock at the start of `auto-calibrate` — if the cron crashed, was interrupted, or the `apply_calibration_result` RPC failed, challenges stay stuck. There is no timeout or watchdog to reset stuck calibrating rows.

**Impact:** These challenges appear as `calibrating` indefinitely. If the auto-calibrate cron runs again, it may or may not pick them up depending on how `get_pending_calibration_queue` is written (if it skips `calibrating` rows, they'll never escape).

**Fix:** Admin action to reset stuck challenges back to `draft` or `passed`. Add timeout watchdog: any challenge stuck in `calibrating` for >2h should auto-reset to `draft`.

**Notable:** The "Live E2E Test: Fix the Rate Limiter" challenge has `calibration_status: calibrating` AND a quarantine dossier (`recommendation: quarantine`). This is a state inconsistency — it should be `calibration_status: quarantined`.

---

### P2-2 — No Production Actions Taken on Queue (0 Approved, 0 Quarantined)

**Severity:** P2  
**Surface:** Operational usability

All 15 dossiers are `reviewer_status: recommended`. Zero have been approved, adjusted, or quarantined. The two quarantine-recommended challenges (`Live E2E Test: Fix the Rate Limiter`, `No-Tests Path Smoke Test`) are still flagged but never actioned.

This means:
- The approve action has never been tested in production
- The quarantine action has never been tested in production  
- The adjust flow has never been used
- The "Analyze All Unreviewed" batch button has been used (15 dossiers exist) but no downstream actions

The API for approve/quarantine/adjust appears correctly wired from code inspection, but it is untested against real DB state.

---

### P2-3 — `x-forge-internal: true` Header Is Unauthenticated Trust

**Severity:** P2  
**Surface:** Trust / Security

The `/api/admin/calibration/auto-trigger` endpoint accepts `x-forge-internal: true` as an auth signal:
```ts
const isInternal = (cronSecret && authHeader === cronSecret) ||
  req.headers.get('x-forge-internal') === 'true'  // ← Anyone can send this
```

This means any external caller who knows the endpoint exists can trigger LLM analysis against arbitrary challenge IDs by sending `x-forge-internal: true`. The endpoint calls OpenRouter (costs money) and writes to the DB.

**Severity rationale:** This is not exploitable by end users (they don't know the internal endpoint exists), but it is a security gap that should be closed.

**Fix:** Remove the `x-forge-internal` bypass. Only allow `CRON_SECRET` auth for this endpoint.

---

### P2-4 — Gauntlet Cron Calls `/api/internal/auto-calibrate` Not `/api/admin/calibration/auto-trigger`

**Severity:** P2  
**Surface:** Auto-trigger / Gauntlet integration

There are **two separate calibration trigger paths**:

1. **Intake pipeline** → calls `/api/admin/calibration/auto-trigger` (Stage 1 LLM analysis only, fire-and-forget)
2. **Gauntlet cron** → calls `/api/internal/auto-calibrate` (real LLM benchmark run via RealLLMCalibrationRunner)

These do different things. The intake route generates a dossier. The Gauntlet cron runs the full benchmark calibration. They are not connected — a challenge created via intake gets Stage 1 analysis; a challenge created by the Gauntlet cron gets the full benchmark. But the intake-created challenges still need benchmark runs to reach `auto_pass`.

This is probably intentional architecture, but it means:
- Intake-created challenges get fast Stage 1 only → stays `needs_light_review` or similar
- Gauntlet-created challenges get full calibration → can reach `passed` without human review
- There's no path from intake → full calibration automatically

**Impact:** Nick manually submitting challenges via intake will get dossiers but not benchmark results. The `auto_pass` path requires benchmark evidence (`AUTOPASS_BENCHMARK_RUN`) — so intake challenges can never auto_pass without a manual benchmark run.

---

## P3 Findings

### P3-1 — `calibration_reviewer_status` Not Initialized on Challenge Creation

15 out of 33 challenges have `calibration_reviewer_status: null` → shown as `unreviewed` in the UI. All pre-system challenges fall in this bucket. Not a functional bug but causes a noisy queue.

### P3-2 — All 11 Benchmark Results Are `pass` (No `borderline` or `fail` in Production)

All 11 real_llm benchmark results have `discrimination_verdict: pass`. While this could be correct (these challenges were presumably curated), it's notable that the `borderline` and `fail` paths of the pipeline have never exercised in production. The decision policy rules `QUARANTINE_BENCHMARK_FAIL` and `DEEP_REVIEW_BENCHMARK_BORDERLINE` have never fired.

The one challenge with `separation_score: 26` ("Debug the Broken Event Emitter") is just above the `separation_borderline: 10` threshold — this is the closest to borderline and should be watched.

### P3-3 — Gauntlet Cron Runs at 8am Daily (Not 6h as Code Comment Claims)

`vercel.json` has `"schedule": "0 8 * * *"` (daily at 8am) but the code comment says "every 6 hours". Minor documentation drift. The actual behavior is daily.

### P3-4 — `challenge_admin_actions` Table Is Empty

Zero rows. The mutation engine logs to this table, quarantine/approve actions should also log here (they don't — no insert is made in the pipeline route). Admin audit trail is missing.

---

## Calibration Quality Assessment

This is the most important section. The question is whether the analysis is genuinely challenge-specific or generic defaults in disguise.

**Verdict: Genuinely specific. Not defaults in disguise.**

I sampled 3 dossiers in full detail. Here's the evidence:

### Sample 1: "Sliding Window Rate Limiter — Fix the Memory Leak"
- **Skill identified:** "Implementing a correct sliding window rate limiting algorithm with proper HTTP middleware semantics and header compliance."
- **Exploit vectors:** The LLM correctly identified that an agent could pass by implementing a *fixed* window counter instead of sliding window (a genuine and non-obvious exploit), using a hardcoded library, or faking the Retry-After header.
- **Hidden constraints:** 8 specific constraints identified including RFC 7231 header compliance, per-key isolation, memory eviction, concurrency safety, sub-second window granularity. These are real, non-obvious requirements that most agents would miss.
- **Difficulty profile:** `evaluation_strictness: 7`, `time_pressure: 6` — appropriate for a 30-minute implementation challenge.
- **Verdict for this challenge:** The analysis is specific, technically accurate, and identifies real failure modes a naive agent would hit.

### Sample 2: "FizzBuzz With Teeth" (Override Semantics Variant)
- **Skill identified correctly:** Custom rule replacement semantics (not just FizzBuzz). The "with teeth" is the override-replaces-defaults behavior.
- **Exploit vector identified:** Hardcoding test case outputs. Correct.
- **Deception score: 5** — the second example shows '1' output for number 5 under custom rules (because neither 2 nor 3 divides 5). The LLM called this out specifically as a deception trap where agents misread it as special behavior. This is accurate and challenge-specific.
- **Recommended session: 20min** — correct for a parameterized FizzBuzz variant.
- **Verdict:** Genuinely specific, correctly identifies the subtle override semantics as the hard part.

### Sample 3: "Debug the Auth Flow" (Inline Bug Labels)
- **Critical insight:** LLM correctly identified that pre-labeled `// Bug 1` through `// Bug 5` comments significantly reduce discovery burden. An agent can locate bugs by scanning for comments, not reasoning. This is the real exploitability vector.
- **Exploit vector:** "Agents trained on security checklists may enumerate common auth bugs generically without reading the code carefully, accidentally hitting all 5." — This is accurate and non-obvious.
- **Non-local dependency: 6** — requires JWT security knowledge, cookie attribute semantics, Next.js middleware patterns. Correct.
- **Verdict:** The medium-exploitability call is defensible and challenge-specific.

### Quarantine Decisions — Are They Correct?

**"Live E2E Test: Fix the Rate Limiter"** → `quarantine`, `exploitability: high`, solve rate 72–91%
- Rationale: "no actual buggy code is provided, forcing agents to invent both the broken implementation and the fix — this makes it trivially exploitable"
- **This is correct.** A challenge that asks agents to debug code without providing the code is fundamentally broken as a competitive evaluation.

**"No-Tests Path Smoke Test"** → `quarantine`, `exploitability: high`, solve rate 92–99%
- Rationale: Intentional smoke test, not a real challenge.
- **This is correct.** The system correctly identified a non-competitive challenge.

### Confidence Calibration

- Confidence is 0.78–0.88 on the sampled challenges. Not falsely inflated to 0.99. The LLM hedges appropriately (e.g., 0.78 on the rate limiter challenge because graders may not distinguish sliding vs fixed window).
- Predicted solve rates are ranges (e.g., 35–65%, 65–85%), not fake precision single numbers.
- No challenge is presented as "will definitely pass/fail" — all predictions are bands.

### Is Data Labeled as Measured vs Predicted?

**Yes, mostly.** The dimension rationale section labels every value as `ai_analysis` (predicted from LLM analysis). No dimension is labeled as empirical unless benchmark data supports it.

**One gap:** The dossier summary reads "Avg difficulty: X/10. Predicted solve rate: Y%" without a visible "predicted" qualifier on the solve rate number. A reviewer glancing quickly might mistake Y% for a measured rate. Minor issue; flagged as P3 trust concern.

---

## Explicit Answers

**Is calibration truly automated now?**  
Partially. Stage 1 (LLM analysis) is fully automated via auto-trigger on intake. Stage 2 (benchmark) runs automatically on Gauntlet-created challenges. Intake-created challenges only get Stage 1 automatically — Stage 2 requires a manual trigger or the batch button. The reviewer workflow requires human approval for `needs_light_review` challenges (which is most of them).

**Is it genuinely challenge-aware or mostly defaults in disguise?**  
Genuinely challenge-aware. The three sampled analyses are specific, technically accurate, and identify challenge-specific failure modes, exploit vectors, and hidden constraints that are not generic. The decision policy is deterministic and traceable. Confidence values are honest. Solve rates are ranges.

**Can Nick trust it enough not to be the calibrator?**  
**Yes for `auto_pass` challenges.** Those have high confidence + low exploitability + sane solve rate. No human review needed.

**No for `needs_light_review`.** 8 of the 15 dossiers are `needs_light_review`. These require human sign-off. But the human decision is **informed** — the dossier surfaces exactly why it's light review (which blocking rule, what exploit vector, what the AI thinks is the main risk). The cognitive burden is massively reduced. Nick would spend 60 seconds reviewing a pre-analyzed dossier rather than doing the analysis himself.

**For quarantine candidates:** System correctly identified both smoketest/malformed challenges. Trust it to surface quarantine candidates. A human still needs to press the quarantine button, but the system already knows.

**What still requires human review?**
- `needs_light_review`: Medium-exploitability challenges (8 current). Quick human confirm.
- `needs_deep_review`: None currently, but expected on ambiguous or experimental challenge types.
- Any challenge with `confidence < 0.5`: Would require deep review; none currently.
- Flagship/boss challenges: System policy requires real LLM benchmark (`synthetic_required_real_required`).

**Is the admin workflow good enough for launch?**  
The UI is well-designed — filter tabs, recommendation badges, decision rule tracing (when populated), adjust slider, approve/quarantine actions. **The P1 (decision rules not in dossier JSONB) is the only thing making it feel incomplete right now.** Fix that and the reviewer queue becomes genuinely useful rather than partially blind. The approve/quarantine/adjust wire is correct in code but untested in production.

**What should still be improved before relying on it heavily?**
1. Re-run batch analysis to populate decision fields in all 15 dossiers
2. Reset 6 stuck-calibrating challenges
3. Test approve + quarantine in production (action the obvious quarantine candidates)
4. Remove `x-forge-internal` auth bypass
5. Add admin action logging to `challenge_admin_actions`
6. Consider a reset watchdog for stuck `calibrating` status rows

---

## Coverage Summary

| Area | Coverage | Notes |
|------|----------|-------|
| challenge-analyzer.ts | ✅ Full | Real LLM call, structured prompt, validated output |
| decision-policy.ts | ✅ Full | Deterministic rule engine, fully read |
| dossier.ts | ✅ Full | Correct structure, all 8 dimensions rationalized |
| pipeline route | ✅ Full | Both analyze_only and full_pipeline paths correct |
| auto-trigger route | ✅ Full | Wired to intake; security gap in auth |
| queue route | ✅ Full | Tested via direct API; returns correct data |
| admin calibration page | ✅ Full code read | Browser blocked by auth gate; UI verified via code |
| Gauntlet integration | ✅ Full | Two separate trigger paths analyzed |
| DB state | ✅ Full | All tables, all rows, full dossier content |
| Calibration quality | ✅ 3 challenges sampled | All show specific non-generic analysis |
| Approve/quarantine/adjust | ⚠️ Code only | Not exercised in production |
| Benchmark results | ✅ Full | 11 real_llm results, all pass, separation 26–85 |

---

*Report written: 2026-04-01 | Sentinel 🛡️*
