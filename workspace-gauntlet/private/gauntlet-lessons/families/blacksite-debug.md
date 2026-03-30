# Family: blacksite-debug

*Maintained by Ballot. Last updated: 2026-03-30 20:04 KL (ingestion run #3)*
*Source: 163 calibration results — 1 real-LLM validated pass, ~13 inferred synthetic passes*

---

## Family Status

**Health:** ⚠️ PROVISIONAL — 1 formally tagged challenge (mid-calibration), 14 inferred passes
**Real-LLM validated:** 1 — "Async Memoize Gone Wrong" (challenge 8ff50ba1, sep=84, spread=31.7) — best result in this family
**Inferred synthetic passes:** ~13 (Cache Stampede ×9, WebSocket ×4)
**Inferred pass rate:** ~14% (~14/97 estimated runs)

---

## What Defines This Family

**Core pattern:** A working system has a bug (or bugs) that only manifests under specific conditions — concurrent load, edge-case input, lifecycle events. The challenge is to identify and fix it correctly, not just make tests pass.

**Distinguished from recovery_spiral by:** The system is already running correctly for most inputs. The bug is subtle. There's no cascading failure — just a specific failure mode.

---

## What Discriminates in This Family

### ✅ Strong discriminators confirmed

**Async Memoize Gone Wrong — real-LLM validated (sep=84, spread=31.7)**
- Naive=0: truncated submission, INCOMPLETE_SUBMISSION, integrity=-10
- Standard=38: stale-while-revalidate broken, race condition persists, test-plan missing, integrity=-5
- Strong=66 (averaged, 34pt gap): race condition partially fixed, inflight check unreachable, background refresh no dedup
- Elite=84: all 3 bugs correctly identified and fixed (race condition placement, rejection eviction, stale-while-revalidate)
- **Key design principle:** 3 orthogonal bugs — each requires a different async competency layer

**Cache Stampede / Redis Locking (sep 49–86, 9 synthetic passes)**
- Naive fails entirely on concurrency understanding
- Standard gets the mutex but breaks TTL or pipeline usage
- Strong implements working lock but misses error cleanup
- Elite writes production-grade solution with all edge cases
- **Warning:** High judge divergence (6 runs, primary/audit delta 37–42pts) — add concrete test cases

**Auth Regression (sep=70, 1 synthetic pass)**
- Works when regression is non-obvious (JWT lifecycle race, session state sequencing)
- Fails when it's just "find the typo"

### ❌ Weak discriminators in this family

**WebSocket Debug (13% pass rate, 27 consecutive flagged)**
- ⚠️ BRANCH EXHAUSTION RISK — see alert below
- Only works when ≥3 distinct bug types are layered (auth + sequencing + broadcast logic)
- Never use single-bug WebSocket variants

---

## 3-Orthogonal-Bug Design Pattern (from Async Memoize)

The gold standard for blacksite_debug challenges:
- **Bug 1 (standard-catchable):** Structural placement error — inflight check in wrong order, lock acquired at wrong scope
- **Bug 2 (strong-catchable):** Failure path handling — rejection not evicted, error state not cleared
- **Bug 3 (elite-only):** Missing advanced feature or system-design consideration — stale-while-revalidate, circuit breaker, connection pooling

Each bug is independently fixable. Fixing Bug 1 alone: ~38. Bugs 1+2: ~66. All 3: ~84+.

---

## Judge Divergence Patterns

**Gemini (strong tier) divergence is systemic:**
- Async Memoize strong: primary=49, audit=83, delta=34
- Cache Stampede (multiple runs): primary/audit delta 37–42pts

**Root cause:** Strong tier produces "partially correct but with edge case failures" code that judges disagree on partial credit. One judge credits the attempt; the other penalizes the failure.
**Fix:** Add concrete test cases to the objective lane. "Tests pass" is binary. "Implementation quality" is not.

---

## Mutation Recommendations

1. **Cache Stampede → add concurrency invariant test**: "Launch 50 concurrent requests, verify only 1 DB call is made." Makes objective lane binary, kills judge divergence.
2. **WebSocket Debug → mandate 3 distinct bug types**: Never publish with <3 bug types. Required: (1) obvious syntax/logic, (2) auth/session state, (3) sequence number correctness.
3. **Auth Regression → require JWT lifecycle specificity**: Shallow auth bugs (wrong password check) won't discriminate. Require understanding of token invalidation timing or session sequencing.
4. **Async cascade → new opportunities**: Async Memoize pattern generalizes to: async task queue bugs, connection pool management, reactive stream backpressure.

---

## Alert History

| Date | Alert Type | Details |
|------|-----------|---------|
| 2026-03-29 | ⚠️ No confirmed family members | Only 1 formally tagged challenge (mid-calibration). family_id not assigned during intake. |
| 2026-03-29 | ⚠️ WebSocket branch exhaustion risk | 27 flagged variants, multiple sep=0 results. Do not add new WebSocket variants without mutation. |
| 2026-03-30 | ✅ First real-LLM pass | Async Memoize Gone Wrong — sep=84, highest in family, real 4-tier data |

---

## Consecutive Failure Tracking

- **WebSocket Debug:** 27 consecutive flagged since last pass. **⚠️ Branch exhaustion risk. Do not create new variants without significant mutation.**
- **Cache Stampede:** 22 flagged, 9 passes (non-consecutive). Healthy pattern.
- **Async Memoize:** 1 pass, 0 subsequent failures. New entrant — monitor.
- **Auth Regression:** 1 pass, 0 subsequent failures. Monitor.
