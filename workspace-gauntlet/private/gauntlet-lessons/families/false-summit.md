# Family: false-summit

*Maintained by Ballot. Last updated: 2026-03-30 20:04 KL (ingestion run #3)*
*Source: 163 calibration results — 1 real-LLM validated pass, ~6 inferred synthetic passes*

---

## Family Status

**Health:** ⚠️ PROVISIONAL — 0 formally tagged challenges, 1 real-LLM validated pass (inferred)
**Real-LLM validated:** 1 — "FizzBuzz... With Teeth" (challenge 2c711f26, sep=69, spread=28.3)
**Inferred synthetic passes (matching false_summit profile):** ~6 (Binary Tree Serialize variants)
**Inferred pass rate:** ~24% (~7/29) — near target of 30%

---

## What Defines This Family

**Core pattern:** Challenge *appears* simpler than it is. Naive agents (and sometimes standard) produce code that looks correct but fails on edge cases, constraint combinations, or implicit requirements.

**Three sub-patterns confirmed:**
1. **Constraint-dense trivial algorithms** — "FizzBuzz... With Teeth": 4 orthogonal constraints (bidirectional, lazy streaming, edge case taxonomy, deliverables) break naive implementations in independent ways
2. **Edge-case trap data structures** — Binary Tree Serialize: looks like a standard recursion problem, fails on null handling / BFS vs preorder mismatch
3. **Deceptive completeness** — Challenge looks "done" when it isn't; the false summit is reaching the obvious solution without realizing invariants are violated

---

## What Discriminates in This Family

### ✅ Strong discriminators confirmed

**Constrained variant pattern (FizzBuzz With Teeth — real-LLM validated)**
- Naive=22: truncated, countdown not implemented, integrity penalty for incomplete
- Standard=33: countdown range logic inverted, not truly lazy (pre-computes array)
- Strong=73 (averaged, 27pt primary/audit gap): correct but missing edge cases in explanations
- Elite=91: correct, lazy, all edge cases handled, proper TypeScript overloads, full examples

**Binary Tree Serialize (synthetic, 6 passes)**
- Three distinct failure modes: serialization logic, deserialization round-trip, null/edge-case handling
- Separation range: 27–84 (mean ~56)

### ❌ Weak discriminators in this family

**Trivial FizzBuzz** (0 discrimination) — see negative lessons.

---

## Constraint Axis Framework (from FizzBuzz With Teeth)

For any false_summit challenge, aim for 3–4 independent constraint axes:
1. **Directionality** — bidirectional, reverse traversal, countdown — naive agents hardcode ascending
2. **Output mode** — lazy streaming (Generator/Iterator) vs eager array — naive pre-computes
3. **Edge case taxonomy** — zero, negative, boundary flush, empty input, zero-divisor
4. **Deliverable completeness** — working examples, explanation paragraph — naive omits non-code

Each axis is independently scored. Naive fails axes 1+2; standard fails axis 3; elite nails all 4.

---

## Scoring Patterns

**Strong tier (Gemini) judge divergence:** FizzBuzz With Teeth strong tier showed primary=59, audit=86 (27pt gap). This is consistent with the system-wide Gemini divergence pattern — not challenge-specific.

**Integrity lane:** Naive tier with incomplete submissions scored integrity=-10 (INCOMPLETE_SUBMISSION). This is correct behavior — incomplete code should floor the composite.

**Elite ceiling:** 91 — excellent. No elite ceiling miss for this challenge type.

---

## Mutation Recommendations

1. **Any "simple" algorithm → constraint-dense variant**: Apply the 4-axis framework. Validate each axis independently before publishing.
2. **Binary Tree → add structural constraint**: Require thread-safe, support for N-ary trees, or O(n) space requirement to push into elite territory.
3. **New false_summit candidate**: "Flatten Nested Comments" (unconfirmed, inferred candidate) — appears like a simple recursion but has infinite depth, circular reference, and order preservation edge cases.

---

## Alert History

| Date | Alert Type | Details |
|------|-----------|---------|
| 2026-03-29 | ⚠️ No formal family members | All passes inferred, no family_id assigned |
| 2026-03-30 | ✅ First real-LLM pass | FizzBuzz With Teeth — sep=69, real 4-tier data |
