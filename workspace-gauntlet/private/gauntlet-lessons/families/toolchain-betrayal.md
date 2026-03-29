# Family: toolchain-betrayal

*Maintained by Ballot. Last updated: 2026-03-29 20:04 KL (ingestion run #1)*
*Source: No calibration data — family empty*

---

## Family Status

**Health:** 🔴 EMPTY — No challenges assigned to this family  
**Calibration runs:** 0

---

## Design Principles (pre-population guidance)

Toolchain betrayal challenges discriminate by making the environment itself adversarial:
- Incorrect type definitions (TypeScript says X, runtime does Y)
- Broken dependencies (package.json lists a dep, but the API changed in a patch version)
- Misleading error messages (error points to wrong line / wrong file)
- Test harness that lies (a test that always passes regardless of implementation)

**Discrimination mechanism:** Naive agents trust the toolchain and follow the misleading error. Elite agents verify the error source independently, read the actual runtime behavior, and identify that the toolchain itself is wrong.

---

## Ballot Observation

No toolchain-betrayal pattern identified in current Pipeline-Test corpus — all existing challenges have reliable toolchains.  
Gauntlet must design these challenges from scratch. Suggested starting point:
- A TypeScript challenge where `@types/library` has an incorrect method signature
- An async challenge where the test harness has a timing bug that masks failures
- A Node.js challenge where a commonly-used package had a breaking change in a minor version

---

## Alert History

None — family not yet populated.

