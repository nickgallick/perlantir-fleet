# Family Health Tracker

*Maintained by Ballot. Last updated: 2026-03-29 20:04 KL (ingestion run #1)*
*Source: challenge_calibration_results synthesized by Ballot (no calibration_learning_artifacts yet generated)*

---

## Summary Table

| Family | Calibration Runs | Pass Rate | CDI Signal | Alert |
|--------|-----------------|-----------|------------|-------|
| blacksite_debug | 1 (calibrating) | 0% confirmed | Provisional | ⚠️ Only 1 real challenge |
| fog_of_war | 0 | — | No data | ⚠️ No challenges in family |
| false_summit | 0 | — | No data | ⚠️ No challenges in family |
| recovery_spiral | 0 | — | No data | ⚠️ No challenges in family |
| toolchain_betrayal | 0 | — | No data | ⚠️ No challenges in family |
| abyss_protocol | 0 | — | No data | ⚠️ No challenges in family |

**Note:** 161 calibration runs exist but only 1 challenge has a family_id set (`blacksite-debug`). All other calibration runs are for `family_id = null` (Pipeline-Test variants). Family health cannot be meaningfully computed until Gauntlet assigns family IDs to challenges during intake.

---

## blacksite_debug

**Status:** ⚠️ PROVISIONAL — Single challenge in calibration  
**Active challenge:** `b49871d9` — "Live E2E Test: Fix the Rate Limiter" (`calibration_status: calibrating`)  
**Pipeline status:** draft  
**Calibration history:** 0 completed runs with verdict (still calibrating)  
**CDI trend:** No data  
**Observation:** The only formally family-tagged challenge is mid-calibration. All 32 confirmed "passed" calibration results are on `family_id = null` Pipeline-Test variants. The blacksite-debug family has no confirmed passed challenges.  
**Alert threshold:** NOT triggered. Insufficient data for collapse detection.  
**Action required:** Gauntlet must tag Pipeline-Test variants with family IDs during intake. Cache Stampede variants → blacksite_debug. WebSocket Debug variants → blacksite_debug. Auth Regression variants → blacksite_debug.

---

## fog_of_war

**Status:** 🔴 EMPTY — No challenges in family  
**Calibration runs:** 0  
**Alert:** No collapse risk (no data), but family has never been populated.  
**Action:** Gauntlet should route fog-of-war style challenges (incomplete information, partial specs, hidden constraints) into this family.

---

## false_summit

**Status:** 🔴 EMPTY — No challenges in family  
**Calibration runs:** 0  
**Action:** Gauntlet should route false-summit challenges (challenges that appear solved but have a hidden correctness failure) into this family.

---

## recovery_spiral

**Status:** 🔴 EMPTY — No challenges in family  
**Calibration runs:** 0  
**Action:** Gauntlet should route recovery-spiral challenges (multi-stage debugging with cascading failures) into this family.

---

## toolchain_betrayal

**Status:** 🔴 EMPTY — No challenges in family  
**Calibration runs:** 0  
**Action:** Gauntlet should route toolchain-betrayal challenges (broken deps, incorrect type definitions, misleading error messages) into this family.

---

## abyss_protocol

**Status:** 🔴 EMPTY — No challenges in family  
**Calibration runs:** 0  
**Action:** Gauntlet should route abyss-protocol challenges (extreme difficulty, no partial credit paths, expert-only) into this family.

---

## Cross-Family Observations (from untagged Pipeline-Test data)

**Challenge type → recommended family mapping (Ballot inference):**

| Challenge Type | Recommended Family | Evidence |
|---|---|---|
| Fix the Cache Stampede | blacksite_debug | Concurrency bug in running system |
| Debug the WebSocket Server | blacksite_debug | Multi-bug debug in live server |
| Debug Authentication Regression | blacksite_debug | Auth regression in working system |
| Sliding Window Rate Limiter | blacksite_debug | Performance bug in rate limiting |
| Fix the Event Emitter | recovery_spiral | Sequential fix with chained failures |
| Fix the Async Queue | recovery_spiral | Ordering/backpressure recovery |
| Serialize Binary Tree | false_summit | Solution looks correct but fails edge cases |
| Debug the LRU Cache | blacksite_debug | Cache correctness regression |
| Flatten Nested Comments | false_summit | Deceptively simple, edge case traps |
| FizzBuzz variants | ❌ RETIRE | No discrimination possible |

**Family collapse alert conditions NOT triggered** (no family has 3+ consecutive failures — no family has enough data).

