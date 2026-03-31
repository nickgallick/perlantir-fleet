# Positive Lessons — What Works

*Maintained by Ballot. Last updated: 2026-03-31 14:04 KL (ingestion run #4)*
*Source: 4 new real-LLM calibration passes (total: 9 real-LLM validated | previous synthetic count revised — see calibration-system-lessons)*

---

## 2026-03-30 · new-pass-001 · confidence: medium

**Lesson:** "FizzBuzz... With Teeth" (sep=69, spread=28.3) — Constrained FizzBuzz **with sufficient complexity** discriminates agent tiers. The plain algorithm fails; this version passed because of 4 distinct constraint layers:
1. Bidirectional range (start > end requires countdown logic — naive fails completely)
2. Lazy streaming via Generator (not truly lazy = flag; pre-computing the array = penalised)
3. Custom rule system with edge cases (zero divisibility, negative numbers, zero-divisor guard)
4. Required deliverables: working examples, explanation paragraph (omission = integrity penalty)
**Tier breakdown:** naive=22 (truncated, countdown not implemented), standard=33 (countdown range inverted, not lazy), strong=73, elite=91
**Key takeaway:** The anti-lesson about FizzBuzz applies to TRIVIAL FizzBuzz only. A sufficiently constrained variant that requires compositional thinking (generators + directionality + edge case hygiene) CAN discriminate. The constraint density is what matters, not the domain name.
**Category:** positive
**Subcategory:** challenge-design-pattern
**Families:** false_summit (looks simple, isn't), blacksite_debug (constrained variant pattern)
**Observed:** 1 new calibration pass (challenge 2c711f26)
**Separation score:** 69, tier_spread=28.3
**Real LLM:** ✅ All 4 tiers submitted (first FizzBuzz-type to produce real tier staircase)

---

## 2026-03-30 · new-pass-002 · confidence: medium

**Lesson:** "Async Memoize Gone Wrong" (sep=84, spread=31.7) — Three-bug async memoization challenges produce strong discrimination. The bugs: (1) race condition — inflight check placed after expired-cache check, so concurrent callers both start new fetches; (2) cache poisoning after rejection — expired entry with `value: undefined` remains, subsequent callers return undefined instead of retrying; (3) stale-while-revalidate absent — system must serve stale + background-refresh in final TTL window.
**Tier breakdown:** naive=0 (truncated, INCOMPLETE_SUBMISSION, integrity=-10), standard=38 (stale-while-revalidate broken, race condition persists, test-plan missing), strong=66 (judge_fallback; 34pt audit delta — primary=49, audit=83; race not fully fixed, inflight check unreachable), elite=84 (correct full implementation, all 3 bugs identified and fixed)
**Key takeaway:** Async memoization is a strong new challenge type. It requires understanding of Promise semantics, TTL management, and concurrent access patterns simultaneously. All 4 tiers produced real submissions — this is validated real-agent discrimination data.
**Category:** positive
**Subcategory:** challenge-design-pattern
**Families:** blacksite_debug (async concurrency regression), recovery_spiral (3-stage fix cascade)
**Observed:** 1 new calibration pass (challenge 8ff50ba1)
**Separation score:** 84, tier_spread=31.7
**Real LLM:** ✅ All 4 tiers submitted (real, not fallback estimation)

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

## 2026-03-29 · system-signal · confidence: high

**Lesson:** The canonical discrimination score range for a passing calibration is separation_score ≥ 27, with median ~70 for strong passes. Tier spread ≥ 13 is the minimum viable threshold. The system's current "passing zone" is sep 27–86, tier_spread 13–36.
**Category:** calibration-system
**Subcategory:** calibration-thresholds
**Observed:** 34 passed calibrations (updated) — min sep=27, max sep=86, mean sep~68.6
**Action for Gauntlet:** Design challenges targeting sep 60–80, tier_spread 25–35 for high-confidence publishable challenges.

