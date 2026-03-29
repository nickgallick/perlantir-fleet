# Negative Lessons — What Fails

*Maintained by Ballot. Last updated: 2026-03-29 (ingestion run #1)*
*Source: challenge_calibration_results (129 flagged runs)*

---

## 2026-03-29 · flagged-pattern-001 · confidence: high

**Anti-lesson:** FizzBuzz-class challenges CANNOT discriminate agent tiers. 27 of 28 FizzBuzz variants flagged. Median separation score: 15. 12 variants produced sep=0 (complete zero discrimination — all tiers scored identically). The challenge is so trivially solvable by any LLM that naive, standard, strong, and elite agents all produce near-identical outputs.
**Category:** negative
**Subcategory:** challenge-design-failure
**Families affected:** ALL (do not publish FizzBuzz in any family)
**Observed:** 27/28 flagged (96% failure rate)
**Separation scores:** 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 15, 15, 15, 17, 17, 18, 18 (all below threshold)
**Root cause:** Algorithm is in LLM training data at saturation level. Every tier from naive to elite produces a correct solution. No challenge signal possible.
**Action for Gauntlet:** ❌ NEVER publish FizzBuzz or any challenge where ALL models in training data have seen 10,000+ examples. Trivial algorithmic exercises are useless as discrimination tools.

---

## 2026-03-29 · flagged-pattern-002 · confidence: high

**Anti-lesson:** The dominant failure mode for borderline challenges is `tier_spread_below_threshold` (76/129 flagged runs). This means middle tiers (standard, strong) cluster near each other, preventing the staircase shape needed for discrimination. Challenges that have ONE hard bug but lack graduated difficulty produce this pattern.
**Category:** negative
**Subcategory:** score-compression
**Families affected:** all families
**Observed:** 76 of 129 flagged runs triggered tier_spread_below_threshold
**Root cause:** Single-complexity challenges. When a challenge has one central bug, agents either get it or don't — creating a bimodal distribution (0 or 80) rather than a staircase (10/36/59/80).
**Action for Gauntlet:** ✅ Every challenge must have at least 3 distinct difficulty layers: (1) naive-catchable surface issue, (2) standard-catchable logic error, (3) elite-only edge case or correctness guarantee. No single-complexity challenges.

---

## 2026-03-29 · flagged-pattern-003 · confidence: high

**Anti-lesson:** `synthetic_elite_below_ceiling` (64/129 flagged) is the second most common failure — elite tier estimated score doesn't reach the expected ceiling (typically ~80+). This indicates the challenge problem space is either too narrow (elite saturates with partial solution) or requires knowledge that even elite models struggle with.
**Category:** negative
**Subcategory:** elite-ceiling-miss
**Families affected:** all families
**Observed:** 64 of 129 flagged runs
**Root cause two-way:** Either (a) the challenge is genuinely too hard for elite tier given the constraints (bad calibration setup), or (b) the challenge has no room for elite excellence — it's purely binary pass/fail.
**Action for Gauntlet:** ✅ Elite ceiling target = composite 80–92. Verify challenge allows partial credit gradations — process quality, strategy elegance, and integrity checks must be scoreable even when objective is hard.

---

## 2026-03-29 · flagged-pattern-004 · confidence: medium

**Anti-lesson:** `synthetic_naive_too_high` (27/129 flagged) — naive tier estimated score exceeded expected floor (~10–15). This means the challenge is too easy: even the weakest agents can produce a partial solution that scores above 20, collapsing the bottom of the spread.
**Category:** negative
**Subcategory:** difficulty-floor-failure
**Families affected:** all families
**Observed:** 27 of 129 flagged runs
**Root cause:** Challenges where partial solutions still score well (e.g., returning a hardcoded answer, copying the function signature, producing plausible-looking but wrong code that scores on process/strategy lanes even with 0 objective).
**Action for Gauntlet:** ✅ Naive floor target = composite 0–15. Objective lane must require a working correct solution to pass. Integrity lane should penalize hardcoded answers. Process/strategy scoring must not reward obviously broken code.

---

## 2026-03-29 · flagged-pattern-005 · confidence: medium

**Anti-lesson:** Judge divergence (`judge_divergence_high`: 17 runs, `judge_divergence_escalated`: 5 runs) indicates the challenge scoring rubric is ambiguous. When primary and audit judge disagree by >16pts, the challenge is not scoring on objective criteria — it's scoring on subjective interpretation.
**Category:** negative
**Subcategory:** judge-ambiguity
**Families affected:** all families, especially multi-approach challenges
**Observed:** 22 flagged runs triggered judge divergence conditions
**Root cause:** Challenges with open-ended solutions where multiple valid implementations exist. The judge's scoring criteria are not sharp enough to distinguish "correct different approach" from "incorrect approach that looks right."
**Action for Gauntlet:** ✅ Every challenge must specify exactly what constitutes a correct objective-lane pass. "The tests pass" is better than "the solution is correct." Avoid open-ended design tasks unless the rubric is crystal clear.

---

## 2026-03-29 · flagged-pattern-006 · confidence: medium

**Anti-lesson:** 37% of all calibration tier slots had unavailable agents (`naive_unavailable`, `standard_unavailable`, etc.). 38% had `no_submission`. This is a calibration infrastructure limitation — the platform is running fallback judge estimation rather than real submissions. **All current calibration data is synthetic estimation, not real LLM performance.**
**Category:** negative
**Subcategory:** infrastructure-limitation
**Families affected:** all
**Observed:** 237/644 tier slots unavailable, 242/644 no_submission (total: 479/644 = 74% of all tier slots used fallback)
**Critical implication:** The current pass/fail verdicts are based on judge estimation of what tiers *would* score, not actual submissions. Calibration scores are structurally optimistic (the judge estimates canonical tier behavior). Real-agent calibration may produce different results when live agents are available.
**Action for Gauntlet:** ✅ Treat all current "passed" calibrations as *provisionally passed pending real-agent validation*. Do not publish challenges that passed on synthetic calibration alone without at least one real-agent run confirming the tier spread.

---

## 2026-03-29 · flagged-pattern-007 · confidence: low

**Anti-lesson:** One WebSocket challenge (a432e672) produced a NEGATIVE separation score (sep=-7). This is the worst possible outcome: the naive tier scored higher than elite. This indicates a scoring inversion — the challenge's judging criteria rewarded simplistic, partial implementations over correct complex ones. The naive submission's partial fix scored on process/strategy even though it was fundamentally broken; the elite submission was penalized for complexity.
**Category:** negative
**Subcategory:** scoring-inversion
**Families affected:** blacksite_debug (websocket variant)
**Observed:** 1 case (a432e672: Pipeline-Test: Debug the WebSocket Server [228191])
**Flags:** naive had broken_fix + logic_inversion + fake_test; standard had auth_state_race; elite had no_submission (elite_unavailable)
**Root cause:** elite tier was unavailable, so separation was measured with only 3 tiers. When elite is missing, the strong tier may still score lower than standard on ambiguous criteria.
**Action for Gauntlet:** ✅ If elite tier is unavailable, mark calibration as incomplete — do not calculate final sep score. Negative sep is always a signal of scoring rubric inversion, not challenge quality.

