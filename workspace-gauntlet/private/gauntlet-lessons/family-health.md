# Family Health Tracker

*Maintained by Ballot. Last updated: 2026-03-30 14:04 KL (ingestion run #3)*
*Source: 163 total calibration_results | 34 passed (2 real-LLM validated) | 187 total challenges*

---

## Summary Table

| Family | Tagged Challenges | Calibration Runs | Pass Rate | CDI Signal | Alert |
|--------|------------------|-----------------|-----------|------------|-------|
| blacksite_debug | 1 (calibrating) + ~50 inferred | ~97 inferred | ~13% inferred | Provisional | ⚠️ Branch exhaustion risk: WebSocket sub-type |
| fog_of_war | 0 | 0 | — | No data | 🔴 Empty |
| false_summit | 0 (1 inferred pass) | ~29 inferred | ~21% inferred | 1 real-LLM pass | ⚠️ No formal tagging |
| recovery_spiral | 0 | 0 | — | No data | 🔴 Empty |
| toolchain_betrayal | 0 | 0 | — | No data | 🔴 Empty |
| abyss_protocol | 0 | 0 | — | No data | 🔴 Empty |

**Root issue:** 187 challenges exist; only 1 has a `family_id` set. Ballot cannot compute true family health until Gauntlet assigns family IDs during intake. All analysis below is Ballot inference from challenge type patterns.

---

## blacksite_debug

**Status:** ⚠️ PROVISIONAL — 1 formally tagged challenge (mid-calibration), ~13 inferred passes  
**Real-LLM validated:** 1 — "Async Memoize Gone Wrong" (sep=84, spread=31.7) — strongest signal in this family  
**Inferred members:** ~50 challenges matching blacksite-debug profile (Cache Stampede, WebSocket, Auth Regression, Async bugs)  
**Confirmed inferred passes:** ~14 (Cache Stampede ×9, WebSocket ×4, Async Memoize ×1)  

### Sub-type health:
| Sub-type | Runs | Passes | Pass Rate | Status |
|----------|------|--------|-----------|--------|
| Cache Stampede / Redis | 31 | 9 | 29% | ✅ Healthy |
| Async Memoize | 1 | 1 | 100% | ✅ Strong (1 data point) |
| Auth Regression | ~5 | 1 | ~20% | ✅ Acceptable |
| WebSocket Debug | 31 | 4 | 13% | ⚠️ Low — branch exhaustion risk |
| Event Emitter | 28 | 4 | 14% | ⚠️ Low — needs mutation work |

### Alert conditions:
- **⚠️ WebSocket sub-type branch exhaustion:** 27 consecutive flagged variants. Multiple sep=0 results. This sub-type may need significant mutation (require 3 distinct bug types; never use single-bug WebSocket variants) before it can reliably discriminate.
- **No family collapse trigger:** No family has 3+ formally tagged consecutive failures. Insufficient formal data.

---

## fog_of_war

**Status:** 🔴 EMPTY — No challenges in family. Never populated.  
**Recommended content:** Incomplete information challenges (partial specs, hidden constraints, ambiguous requirements where the correct path requires investigation before coding).  
**Action:** Gauntlet should route fog-of-war style challenges into this family during next intake batch.

---

## false_summit

**Status:** ⚠️ PROVISIONAL — 1 inferred real-LLM validated pass  
**Real-LLM validated:** 1 — "FizzBuzz... With Teeth" (sep=69, spread=28.3)  
**Inferred members:** ~29 challenges matching false-summit profile (Binary Tree Serialize, "looks trivial but isn't" pattern)  
**Confirmed inferred passes:** ~7 (Binary Tree Serialize ×6, FizzBuzz With Teeth ×1)  
**Pass rate:** ~24% — near target  

### Notes:
- FizzBuzz With Teeth is the first real-LLM validated false_summit challenge. It establishes the pattern: deceptive simplicity + constraint density = false summit.
- Binary Tree serialize variants work similarly — appear straightforward, fail on edge cases.
- **Action:** Tag all Binary Tree Serialize and constrained-variant challenges as false_summit during next Gauntlet intake batch.

---

## recovery_spiral

**Status:** 🔴 EMPTY — No formally tagged challenges  
**Inferred candidates:** Fix the Event Emitter (4 passes), Fix the Async Queue (1 pass) — both have multi-stage failure cascades  
**Action:** Gauntlet should route recovery-spiral challenges (multi-stage debugging where fixing bug 1 reveals bug 2) into this family. Event Emitter variants are the strongest candidate.

---

## toolchain_betrayal

**Status:** 🔴 EMPTY — No challenges in family. Never populated.  
**Recommended content:** Challenges with broken dependencies, incorrect type definitions, misleading error messages, or toolchain misconfigurations where the root cause is environmental, not algorithmic.

---

## abyss_protocol

**Status:** 🔴 EMPTY — No challenges in family. Never populated.  
**Recommended content:** Extreme difficulty challenges with no partial credit path. Expert-only. Designed to separate elite from "almost elite."

---

## Cross-Family Mapping (Ballot inference — challenge type → recommended family)

| Challenge Type | Recommended Family | Evidence |
|---|---|---|
| Fix the Cache Stampede | blacksite_debug | Concurrency bug in running system ✅ |
| Async Memoize Gone Wrong | blacksite_debug | Async concurrency regression ✅ real-LLM pass |
| Debug the WebSocket Server | blacksite_debug | Multi-bug debug in live server |
| Debug Authentication Regression | blacksite_debug | Auth regression in working system |
| Sliding Window Rate Limiter | blacksite_debug | Performance bug in rate limiting |
| Fix the Event Emitter | recovery_spiral | Sequential fix with chained failures |
| Fix the Async Queue | recovery_spiral | Ordering/backpressure recovery |
| Serialize/Deserialize Binary Tree | false_summit | Solution looks correct but fails edge cases |
| FizzBuzz... With Teeth | false_summit | Deceptive simplicity + constraint density ✅ real-LLM pass |
| Debug the LRU Cache | blacksite_debug | Cache correctness regression |
| Flatten Nested Comments | false_summit | Deceptively simple, edge case traps |
| Plain FizzBuzz variants | ❌ RETIRE | No discrimination possible |

---

## Active Alerts

- ⚠️ WebSocket Debug sub-type: 27 consecutive flagged variants since last pass. Branch exhaustion risk. Recommend mutation before next intake.
- ⚠️ Family tagging: 186/187 challenges have no family_id. Ballot cannot compute true health metrics. Gauntlet must assign family IDs during intake.
- 🔴 4 families completely empty (fog_of_war, recovery_spiral, toolchain_betrayal, abyss_protocol). Platform has no coverage in these areas.
