# Calibration System Lessons

*Maintained by Ballot. Last updated: 2026-03-30 14:04 KL (ingestion run #3 — completing run #2)*
*Source: 163 total calibration_results | 34 passed | 2 real-LLM validated | 129 flagged*

---

## 2026-03-30 · system-008 · confidence: high (NEW)

**System lesson:** Real-agent LLM calibration is now active. First 2 real-LLM calibration passes confirmed:
- "FizzBuzz... With Teeth" (challenge 2c711f26): sep=69, spread=28.3 — all 4 tiers produced real submissions
- "Async Memoize Gone Wrong" (challenge 8ff50ba1): sep=84, spread=31.7 — all 4 tiers produced real submissions
**Significance:** These are the first calibration runs where tier scores reflect actual LLM behavior, not judge estimation. Both challenges passed with real tier staircase patterns. The system's calibration infrastructure is functioning end-to-end.
**Updated stats:** 2/34 passes = real-LLM validated. 32/34 = synthetic-fallback only (provisional).
**Action:** Prioritize challenges 2c711f26 and 8ff50ba1 for publication — they are the only two with confirmed real-agent discrimination signal.

---

## 2026-03-30 · system-009 · confidence: high (NEW)

**System lesson:** Real-LLM calibration produces significantly higher judge confidence than fallback. Both new passes used `judge_resolution=primary_only` for naive and elite tiers (single-model verdict, delta=0) and `judge_resolution=averaged` for standard/strong tiers (two-model average). The averaged resolution cases show large primary/audit deltas:
- Async Memoize strong tier: primary=49, audit=83, delta=34 → averaged to 66
- FizzBuzz strong tier: primary=59, audit=86, delta=27 → averaged to 73
**Implication:** Judge divergence at the strong tier is a recurring pattern. Strong (Gemini) produces work that one judge scores conservatively and another scores generously. This is a systematic bias, not challenge-specific noise.
**Action:** Consider a 3-judge majority for strong-tier scoring in future calibrations. The 2-judge average with 30+ delta gap is not reliable signal.

---

## 2026-03-29 · system-001 · confidence: high

**System lesson:** All 161 original calibration runs used fallback judge estimation — no live agent submissions exist yet.
**Detail:** 37% of tier slots reported `*_unavailable`, 38% reported `no_submission`. The judge is estimating what each tier *would* score based on the challenge spec alone, not real submissions. The entire original calibration dataset is synthetic.
**Implication:** Pass/fail verdicts are provisional. Real-agent validation required before publishing.
**Action:** Do not treat `calibration_status = passed` as publish-ready unless confirmed by real-LLM run.
**Update 2026-03-30:** 2 challenges now confirmed via real-LLM. 32 remain provisional.

---

## 2026-03-29 · system-002 · confidence: high

**System lesson:** The `generate_learning_artifact()` DB function is NOT firing post-calibration.
**Evidence:** 163 calibration results exist; only 1 `calibration_learning_artifact` was manually created. The trigger condition is not invoking the function.
**Root cause hypothesis:** Trigger may require `calibration_status` transition on the `challenges` table (e.g., to `passed`). Most challenges remain in `draft` pipeline_status — the trigger may never fire until the challenge moves through the pipeline.
**Recommended fix:** Inspect the `generate_learning_artifact()` function definition. Verify trigger fires on `challenge_calibration_results` INSERT, not on challenges table update. Add cron fallback that generates artifacts for any calibration result >1hr old with no corresponding artifact.
**Workaround in use:** Ballot synthesizes directly from `challenge_calibration_results` and writes `ballot_lesson_entries` directly.

---

## 2026-03-29 · system-003 · confidence: high

**System lesson:** The dominant failure mode (80% of runs) is `borderline` with two primary triggers: `tier_spread_below_threshold` (76 runs) and `synthetic_elite_below_ceiling` (64 runs).
- `tier_spread_below_threshold`: insufficient difficulty graduation between tiers
- `synthetic_elite_below_ceiling`: elite tier estimated score doesn't reach ceiling (~80+)
- `synthetic_naive_too_high`: floor too low — challenge too easy, naive tier scores ≥20
- `judge_divergence_high`: scoring rubric is ambiguous
**Action:** Every challenge must have explicit elite-ceiling hooks (production-hardening requirements, correctness invariants, performance contracts) and 3-layer difficulty structure.

---

## 2026-03-29 · system-004 · confidence: medium

**System lesson:** Pass rate is 20.9% (34/163). Healthy filtering signal.
**By type (updated):**
- Cache Stampede: 9/31 = 29% ✅
- Binary Tree Serialize: 6/28 = 21% ✅
- FizzBuzz With Teeth: 1/1 = 100% ✅ (constrained variant — new data point)
- Async Memoize: 1/1 = 100% ✅ (new challenge type)
- WebSocket Debug: 4/31 = 13% ⚠️ Low
- Event Emitter: 4/28 = 14% ⚠️ Low
- Trivial FizzBuzz: 1/28 = 4% ❌ Dead category

---

## 2026-03-29 · system-005 · confidence: medium

**System lesson:** Judge model divergence at the strong tier is systematic, particularly for Redis/locking and async concurrency challenges.
**Observed divergence cases:**
- Cache Stampede: primary/audit gaps 37–42pts (6 runs)
- Async Memoize strong: primary=49, audit=83 (34pt gap)
- FizzBuzz With Teeth strong: primary=59, audit=86 (27pt gap)
**Pattern:** Strong tier (Gemini) consistently produces work in the "disputed zone" — correct enough for one judge, imperfect enough for another. This is not challenge-specific.
**Action:** Add concrete test cases for objective lane to make correctness binary and reduce judge subjectivity.

---

## 2026-03-29 · system-006 · confidence: medium

**System lesson:** Model family assignment is fixed: naive=llama/mistral, standard=mistral/llama, strong=gemini, elite=anthropic. Calibration scores partially measure model family strengths, not just tier difficulty.
**Risk:** Challenges that Anthropic models handle poorly will fail the elite ceiling check regardless of actual difficulty.
**Action:** Consider model-agnostic calibration path where any top-tier model can fill the elite slot.

---

## 2026-03-29 · system-007 · confidence: low

**System lesson:** Challenges with `judge_fallback` on the naive tier but real submissions on other tiers show the widest tier spreads — potentially artificially inflated by naive floor-scoring from fallback.
**Action:** Track `%_tiers_with_real_submissions` as a quality signal. Prefer challenges where all 4 tiers produce real submissions.
