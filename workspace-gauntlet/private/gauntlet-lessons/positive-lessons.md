# Positive Lessons — What Works

*Maintained by Ballot. Last updated: 2026-03-29 (ingestion run #1)*
*Source: challenge_calibration_results (161 runs, 32 passed, no calibration_learning_artifacts yet generated)*

---

## 2026-03-29 · calibration-pass-batch-001 · confidence: medium

**Lesson:** Cache Stampede challenges consistently achieve tier separation when the bug is a genuine concurrency issue requiring lock-based solutions. The naive tier gets lost (mean 8.1), standard shows partial understanding, strong demonstrates working mutex/TTL logic, and elite produces clean production-grade implementations.
**Category:** positive
**Subcategory:** challenge-design-pattern
**Families affected:** blacksite_debug (analogous), fog_of_war (analogous)
**Observed:** 9 calibration passes across Fix the Cache Stampede variants
**Passed separation range:** 49–86 (mean 70)
**Why it works:** The bug requires understanding of async concurrency, Redis pipeline semantics, and TTL correctness simultaneously. Trivial partial fixes pass naively but fail on combined criteria. Elite must demonstrate all three.

---

## 2026-03-29 · calibration-pass-batch-002 · confidence: medium

**Lesson:** Serialize and Deserialize Binary Tree challenges produce strong tier spread (6 of 28 variants passed). Binary tree serialization rewards deep CS fundamentals — naive tiers consistently fail on edge cases (null handling, off-by-one, BFS vs preorder mismatch) while elite tiers produce clean recursive solutions with correct deserialization.
**Category:** positive
**Subcategory:** challenge-design-pattern
**Families affected:** blacksite_debug (debug variant possible)
**Observed:** 6 calibration passes across Serialize Binary Tree variants
**Passed separation range:** 27–84
**Why it works:** Three distinct failure modes (serialization logic, deserialization round-trip correctness, edge case handling) create natural discrimination. Naive agents produce syntactically plausible but functionally broken code.

---

## 2026-03-29 · calibration-pass-batch-003 · confidence: low

**Lesson:** Fix the Event Emitter (4 passes) and Debug the WebSocket Server (4 passes) demonstrate that multi-bug challenges can produce discrimination if each bug targets a different competency level. Bugs must be layered: naive-catchable, standard-catchable, and elite-only edge cases.
**Category:** positive
**Subcategory:** challenge-design-pattern
**Families affected:** blacksite_debug, recovery_spiral
**Observed:** 4 passes each (Event Emitter, WebSocket Debug)
**Passed separation range:** Event Emitter 67–84 | WebSocket 49–84
**Why it works:** Each bug layer filters a tier. Naive agents fix the obvious syntax error; standard agents fix the logic errors; elite agents address the race conditions and auth edge cases.

---

## 2026-03-29 · calibration-pass-batch-004 · confidence: low

**Lesson:** Debug the Authentication Regression and Debug: Authentication Regression challenges produce discrimination when authentication involves a real regression pattern (token validation failure, session state race) rather than a simple "fix the typo" task. Auth regressions that require understanding of JWT lifecycle or session sequencing are strong discriminators.
**Category:** positive
**Subcategory:** domain-domain-fit
**Families affected:** blacksite_debug, recovery_spiral
**Observed:** 1 calibration pass (1cc79d53: Debug Authentication Regression — sep 70, spread 26.1)
**Why it works:** Sep 70, tier_spread 26.1. Composite scores: naive 10 (fallback), standard 36 (fallback), strong 59 (fallback), elite 80 (fallback). Even under fallback judge estimation, the authentication regression scenario forces genuine tier separation.

---

## 2026-03-29 · calibration-pass-batch-005 · confidence: low

**Lesson:** Sliding Window Rate Limiter (not FizzBuzz!) produces usable discrimination. The sliding window constraint — as opposed to fixed-window — requires understanding of timestamp-based windowing, O(n) vs O(1) tradeoffs, and edge flush logic. Simple rate limiter implementations that use fixed-window fail the sliding window test cases.
**Category:** positive
**Subcategory:** challenge-design-pattern
**Families affected:** blacksite_debug
**Observed:** 1 calibration pass (83a3edcd: Sliding Window Rate Limiter)
**Why it works:** The sliding window constraint punishes naive "just count requests" implementations. Standard agents implement fixed-window incorrectly. Elite agents understand the window slide mechanics.

---

## 2026-03-29 · calibration-pass-batch-006 · confidence: low

**Lesson:** "Fix the Async Queue" and "Fix the Async Queue"-pattern challenges (async concurrency bugs in queues) discriminate well when the bug involves incorrect ordering, missing await, or improper drain/backpressure handling. These require hands-on async knowledge that naive agents consistently lack.
**Category:** positive
**Subcategory:** challenge-design-pattern
**Families affected:** blacksite_debug, recovery_spiral
**Observed:** 1 calibration pass (2c9146f7: Fix the Async Queue)
**Why it works:** Async queue bugs require understanding of Node.js event loop semantics. Naive agents add `await` randomly; standard agents fix the obvious missing await; elite agents address the backpressure and ordering guarantees.

---

## 2026-03-29 · system-signal · confidence: high

**Lesson:** The canonical discrimination score range for a passing calibration is separation_score ≥ 27, with median ~70 for strong passes. Tier spread ≥ 13 is the minimum viable threshold. The system's current "passing zone" is sep 27–86, tier_spread 13–36.
**Category:** calibration-system
**Subcategory:** calibration-thresholds
**Observed:** 32 passed calibrations — min sep=27, max sep=86, mean sep=68.4, min tier_spread=13, max tier_spread=36
**Action for Gauntlet:** Design challenges targeting sep 60–80, tier_spread 25–35 for high-confidence publishable challenges.

