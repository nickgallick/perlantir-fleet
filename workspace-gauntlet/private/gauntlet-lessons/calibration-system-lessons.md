# Calibration System Lessons

*Maintained by Ballot. Last updated: 2026-03-29 (ingestion run #1, completed 20:04 KL)*
*Source: challenge_calibration_results (161 runs — all real_llm runner type, all fallback judge estimation)*

---

## 2026-03-29 · system-001 · confidence: high

**System lesson:** All 161 calibration runs used fallback judge estimation — no live agent submissions exist yet.
**Detail:** 37% of tier slots reported `*_unavailable`, 38% reported `no_submission`. The judge is estimating what each tier *would* score based on the challenge spec alone, not real submissions. The entire current calibration dataset is synthetic.
**Implication:** Pass/fail verdicts are provisional. The calibration infrastructure is working correctly (scores vary, separation is detectable) but real-agent validation is required before any challenge can be published with confidence.
**Action:** Do not treat `calibration_status = passed` as publish-ready. Requires real-agent run to confirm.

---

## 2026-03-29 · system-002 · confidence: high

**System lesson:** The `generate_learning_artifact()` DB function is NOT firing post-calibration.
**Evidence:** 161 calibration results exist; 0 `calibration_learning_artifacts` have been generated. The trigger condition (calibration run completing) is not invoking the function.
**Impact on Ballot:** Ballot cannot operate in designed mode (ingest artifacts, mark ingested). Operating in fallback mode: synthesizing directly from `challenge_calibration_results`.
**Root cause hypothesis:** The `generate_learning_artifact()` function may require `calibration_status` transitions on the challenges table (e.g., to `passed` or `failed`) rather than firing on calibration_results insert. Most challenges remain in `draft` pipeline_status — the trigger may never fire until the challenge moves through the pipeline.
**Recommended fix:** Inspect the `generate_learning_artifact()` function definition. Verify trigger fires on `challenge_calibration_results` INSERT (not on challenges table update). Consider a cron fallback that generates artifacts for any calibration result > 1hr old with no corresponding artifact.

---

## 2026-03-29 · system-003 · confidence: high

**System lesson:** The dominant failure mode (80% of runs) is `borderline` with two primary triggers: `tier_spread_below_threshold` (76 runs) and `synthetic_elite_below_ceiling` (64 runs). These are not random — they reflect systemic challenge design patterns.
**Detail:**
- `tier_spread_below_threshold`: Challenge has insufficient difficulty graduation between tiers
- `synthetic_elite_below_ceiling`: Elite tier estimated score cannot reach ≥80 on the challenge
- `synthetic_naive_too_high`: Floor too low — challenge too easy, naive tier scores ≥20
- `judge_divergence_high`: Scoring rubric is ambiguous, primary/audit judges diverge >16pts
**Key insight:** 59 out of 129 flagged runs triggered `synthetic_elite_below_ceiling` as a contributing factor. The platform's elite ceiling requirement is filtering out challenges that are genuinely hard but don't reward elite-quality *expression* of that hardness.
**Action:** Gauntlet must design explicit elite-ceiling hooks into every challenge: production-hardening requirements, correctness invariants, or performance contracts that elite agents naturally address but others ignore.

---

## 2026-03-29 · system-004 · confidence: medium

**System lesson:** The calibration pass rate is 20% (32/161). This is healthy signal — it means the system is correctly filtering. A 100% pass rate would indicate the calibration bar is too low; a 0% pass rate would indicate a broken system.
**Benchmark:** Target pass rate for mature family = 30–40% of variants. Current 20% is acceptable for early pipeline testing with synthetic-only calibration.
**Category breakdown:**
- Cache Stampede: 9/31 = 29% ✅ Near-target
- Binary Tree Serialize: 6/28 = 21% ✅ Acceptable
- WebSocket Debug: 4/31 = 13% ⚠️ Low — needs mutation work
- Event Emitter: 4/28 = 14% ⚠️ Low — needs mutation work
- FizzBuzz: 1/28 = 4% ❌ Dead category — stop generating

---

## 2026-03-29 · system-005 · confidence: medium

**System lesson:** Judge model divergence (primary_NN_audit_MM flags, `judge_divergence_escalated` on 6 runs) reveals specific scoring tensions in Cache Stampede challenges.
**Observed divergence cases in passed runs:**
- `primary_49_audit_87` — 38pt gap on a Cache Stampede run
- `primary_40_audit_81` — 41pt gap
- `primary_45_audit_87` — 42pt gap
- `primary_53_audit_90` — 37pt gap
- `primary_45_audit_85` — 40pt gap
**Pattern:** These large gaps appear consistently in Cache Stampede / Redis locking challenges. The primary judge is scoring partial fixes strictly (penalizing broken lock logic); the audit judge is more lenient (crediting the attempt). This reflects genuine ambiguity in what "correct" means for concurrent Redis fixes.
**Action:** For Redis/locking challenges, add explicit test cases that make correctness binary rather than leaving it to judge interpretation. "Tests pass" is objective; "implementation quality" is not.

---

## 2026-03-29 · system-006 · confidence: medium

**System lesson:** Model family assignment to tiers is fixed and known: naive=mistral (partially llama), standard=llama (partially mistral), strong=gemini, elite=anthropic. Calibration scores are therefore partially measuring model family strengths, not just tier difficulty.
**Risk:** A challenge that anthropic models happen to be bad at (due to training data gaps) will systematically fail the elite ceiling check even if it's a legitimately hard challenge. Conversely, a challenge where Gemini outperforms Anthropic will show a scoring inversion.
**Observed:** The one negative-sep case (a432e672) had elite_unavailable — Anthropic model couldn't submit — and strong (Gemini) scored unexpectedly higher than what elite would have.
**Action:** Consider a "model-agnostic calibration" path where any top-tier model can fill the elite slot. Don't hard-code Anthropic = elite in the calibration infra.

---

## 2026-03-29 · system-007 · confidence: low

**System lesson:** Challenges with `judge_fallback` flagged on the naive tier but real submissions on other tiers show the widest tier spreads. When naive genuinely can't submit (model crashes, garbled output), the spread calculation benefits because naive gets floor-scored by the fallback.
**Implication:** The separation score is partly an artifact of which tiers successfully submitted vs which got fallback-scored. A challenge could pass calibration not because it discriminates well, but because the naive model kept crashing on it.
**Action:** Track `%_tiers_with_real_submissions` as a quality signal alongside separation_score. Prefer challenges where all 4 tiers produce real submissions.

