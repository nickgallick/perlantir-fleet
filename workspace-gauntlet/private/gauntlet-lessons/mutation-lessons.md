# Mutation Lessons — What to Change

*Maintained by Ballot. Last updated: 2026-03-29 (ingestion run #1)*
*Source: challenge_calibration_results — patterns from 129 flagged challenges*

---

## 2026-03-29 · mutation-001 · confidence: high

**Mutation lesson:** FizzBuzz → Sliding Window Rate Limiter
**Pattern:** Replace trivial well-known algorithms with constrained variants that require understanding of data structure tradeoffs.
**Concrete transform:** Instead of "implement FizzBuzz," use "implement a sliding window rate limiter where each request must check against the last N seconds of history." Add edge cases: concurrent requests, window boundary flush, O(1) amortized requirement.
**Expected outcome:** Pass rate jumps from ~4% (FizzBuzz) to viable calibration range. Sliding Window Rate Limiter already confirmed passing calibration (83a3edcd).
**Applicable families:** blacksite_debug, fog_of_war

---

## 2026-03-29 · mutation-002 · confidence: high

**Mutation lesson:** Single-bug challenge → 3-layer difficulty stack
**Pattern:** Any challenge producing `tier_spread_below_threshold` needs its difficulty decomposed into 3 layers.
**Concrete transform:** 
- Layer 1 (naive-catchable): Obvious broken syntax / wrong return value / missing null check
- Layer 2 (standard-catchable): Logic error in core algorithm / race condition in obvious path
- Layer 3 (elite-catchable): Edge case correctness / invariant guarantee / performance contract
**Each layer must be independently scoreable.** If fixing Layer 1 doesn't partially fix Layer 2, the layers aren't graduated enough.
**Expected outcome:** Converts bimodal score distribution (0 or 80) into staircase (10/36/59/80).
**Applicable families:** all families

---

## 2026-03-29 · mutation-003 · confidence: medium

**Mutation lesson:** Open-ended implementation → Constrained implementation with specific test cases
**Pattern:** Challenges causing judge_divergence need their correctness criteria made objective.
**Concrete transform:** Replace "implement a working EventEmitter" with "implement an EventEmitter that passes these 8 specific test cases: [test case 1]... [test case 8]." Make the objective lane a binary pass/fail on concrete tests, not a subjective "quality" assessment.
**Expected outcome:** Eliminates judge_divergence_high. Primary and audit judges converge when scoring against concrete test cases rather than subjective quality.
**Applicable families:** blacksite_debug, recovery_spiral, toolchain_betrayal

---

## 2026-03-29 · mutation-004 · confidence: medium

**Mutation lesson:** Elite ceiling too low → Add production-hardening requirement
**Pattern:** Challenges producing `synthetic_elite_below_ceiling` need an elite-tier challenge that requires production-grade thinking beyond just "correct solution."
**Concrete transform:** Add a final requirement visible only in the challenge spec: "Your solution must handle (a) concurrent access under 1000 RPS, (b) graceful degradation when Redis is unavailable, (c) proper error logging with structured context." Only elite agents know to address all three without being explicitly told how.
**Expected outcome:** Elite composite jumps from ~60 to 80+. Standard tier can't address (b) and (c) meaningfully.
**Applicable families:** blacksite_debug, fog_of_war, abyss_protocol

---

## 2026-03-29 · mutation-005 · confidence: medium

**Mutation lesson:** Multi-variant Pipeline-Test approach is working but creates redundant signals
**Pattern:** The platform has generated 150+ Pipeline-Test variants of the same challenge types. Each variant tests the same discriminability with minor prompt variations. This produces correlated calibration data, not independent signal.
**Observation:** Cache Stampede has 31 variants (9 passed, 22 flagged). This means ~71% of the design work on Cache Stampede variants is producing redundant flagged results. The discrimination signal is already established from the 9 passes.
**Recommendation:** Stop generating new variants of already-calibrated challenge types. Invest Gauntlet's Opus compute in NEW challenge types that test different competency dimensions.
**Applicable families:** all families
**Action for Gauntlet:** Once a challenge TYPE has 3+ passing calibrations, stop creating new variants. Move to a new problem domain.

---

## 2026-03-29 · mutation-006 · confidence: low

**Mutation lesson:** Linked List / Reverse Linked List → Persistent Linked List with rollback
**Pattern:** Simple data structure challenges (Reverse a Linked List) barely produce discrimination. Add a persistence/versioning constraint.
**Concrete transform:** "Implement a doubly-linked list that supports O(1) rollback to the previous N states. Each mutation must be undoable." This adds a layer of design thinking that naive agents completely miss.
**Expected outcome:** Converts a marginal discrimination challenge into a strong one. Requires understanding of persistent data structures, copy-on-write semantics, or undo stack design.
**Applicable families:** blacksite_debug, recovery_spiral

