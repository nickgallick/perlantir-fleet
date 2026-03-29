# Family: blacksite-debug

*Maintained by Ballot. Last updated: 2026-03-29 20:04 KL (ingestion run #1)*
*Source: challenge_calibration_results — inferred from Pipeline-Test variants matching blacksite-debug profile*

---

## Family Status

**Health:** ⚠️ PROVISIONAL — 1 formally tagged challenge (mid-calibration), 0 confirmed passes  
**Inferred candidates (family_id = null, matching blacksite-debug profile):** ~50 challenges  
**Confirmed passed (inferred blacksite-debug type):** ~13 challenges (Cache Stampede ×9, WebSocket ×4)

---

## What Discriminates in This Family

### ✅ Strong discriminators observed

**Cache Stampede / Redis Locking bugs** — sep 49–86, consistent discrimination
- Naive tier fails completely on concurrency understanding
- Standard tier gets the mutex but breaks the TTL or pipeline usage
- Strong tier implements working lock but misses error cleanup
- Elite tier writes production-grade solution with all edge cases

**WebSocket multi-bug debug** — sep 49–84 when elite tier available
- 4 variants passed; 27 flagged (14% pass rate — needs improvement)
- The challenge works when: bugs are layered (auth + sequencing + broadcast logic)
- The challenge fails when: only 1 bug type is present, or elite tier is unavailable

**Authentication Regression** — sep 70, confirmed pass
- Works when regression is non-obvious (state race in JWT validation, not just a typo)
- Requires understanding of auth lifecycle, not just "find the broken line"

### ❌ Weak discriminators in this family

**FizzBuzz** — 0 discrimination. Never assign to blacksite-debug or any family.

---

## Scoring Patterns

**Judge divergence risk:** HIGH for Redis/locking challenges.
- Observed: 6 Cache Stampede runs triggered `judge_divergence_escalated` (primary/audit delta 37–42pts)
- Root cause: "partial correct lock" is ambiguous — judges disagree on whether broken-but-present mutex attempt gets partial credit
- Fix: Add concrete test cases that make Redis lock correctness binary

**Naive tier behavior:** Consistent floor at composite 0–15 for concurrency bugs (good)
- Naive models produce syntactically plausible but semantically broken fixes
- Common naive flags: `broken_fix`, `wrong_locking_mechanism`, `logic_inversion`, `fake_test`

**Elite tier behavior:** Composite 67–92 when model is available (solid ceiling)
- Elite ceiling is occasionally missed on challenges where the "correct" solution requires obscure Redis API knowledge
- Avoid challenges where correctness depends on knowing a specific Redis command variant

---

## Mutation Recommendations

1. **Cache Stampede → add concurrency invariant test**: Add a test that launches 50 concurrent requests and verifies only one DB call is made. This makes the objective lane binary and kills judge divergence.

2. **WebSocket Debug → require 3 distinct bug types**: Any WebSocket debug challenge with <3 bug types is likely to flag. Layering: (1) syntax/obvious logic, (2) auth/session state, (3) sequence number correctness.

3. **Auth Regression → require JWT lifecycle specificity**: The passing auth regression challenge worked because it required understanding of JWT token invalidation timing. Shallow auth bugs (wrong password check) won't discriminate.

---

## Alert History

| Date | Alert Type | Details |
|------|-----------|---------|
| 2026-03-29 | ⚠️ No confirmed family members | Only 1 formally tagged challenge (mid-calibration). Family ID not being assigned during intake. |

---

## Consecutive Failure Tracking

*Reset on any pass. Trigger Ballot→Gauntlet alert at 3 consecutive failures.*

- WebSocket Debug variants: 27 flagged since last pass. **⚠️ Branch exhaustion risk.** Multiple variants are generating zero-separation results (sep=0, spread=0). This sub-type may need significant mutation before it discriminates reliably.
- Cache Stampede variants: 22 flagged but 9 passed (non-consecutive). No collapse.
- Auth Regression: 1 pass, 0 subsequent failures. Healthy.

