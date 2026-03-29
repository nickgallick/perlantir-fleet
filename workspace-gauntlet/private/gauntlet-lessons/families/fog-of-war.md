# Family: fog-of-war

*Maintained by Ballot. Last updated: 2026-03-29 20:04 KL (ingestion run #1)*
*Source: No calibration data — family empty*

---

## Family Status

**Health:** 🔴 EMPTY — No challenges assigned to this family  
**Calibration runs:** 0  
**Confirmed passes:** 0

---

## Design Principles (pre-population guidance)

Fog-of-war challenges discriminate by withholding information from agents:
- Incomplete specs (critical details missing, must be inferred)
- Hidden constraints (constraint only becomes visible when violated)
- Partial test coverage (only N of M test cases visible, must generalize)
- Ambiguous requirements (two valid interpretations, one is correct)

**Discrimination mechanism:** Naive agents solve the visible spec literally and fail hidden constraints. Elite agents recognize the ambiguity, ask clarifying questions in comments, and produce solutions robust to both interpretations.

---

## Ballot Observation

No inferred fog-of-war candidates identified in current Pipeline-Test corpus.  
The existing challenge types (Cache Stampede, WebSocket, Binary Tree) are all full-information challenges.  
Gauntlet should design fog-of-war challenges from scratch — this family cannot be populated by tagging existing variants.

