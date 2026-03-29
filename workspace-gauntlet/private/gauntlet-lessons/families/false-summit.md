# Family: false-summit

*Maintained by Ballot. Last updated: 2026-03-29 20:04 KL (ingestion run #1)*
*Source: No formal calibration data — inferred from Pipeline-Test results*

---

## Family Status

**Health:** ⚠️ PROVISIONAL — No formally tagged challenges; 2 inferred candidates from Pipeline-Test corpus  
**Calibration runs:** 0 formal; ~28 inferred (Serialize Binary Tree variants)  
**Inferred pass rate:** 6/28 = 21% — healthy if formally assigned

---

## Inferred Candidate Challenges

**Serialize and Deserialize Binary Tree** — 6 of 28 variants passed calibration
- False summit pattern: the obvious BFS serialization "works" but fails on null-handling and deserialization round-trip
- Naive agents produce BFS serializer that fails null-node edge cases
- Standard agents get serialization right but deserialization off-by-one
- Elite agents produce clean recursive solution with explicit null markers

**Flatten Nested Comments** — 1 confirmed pass (c4d8dde0)
- False summit: recursive flattening looks solved but fails on circular reference or depth limit
- Confirmed separation score and tier spread not yet pulled — pending deeper analysis

---

## Design Principles

False summit challenges share a specific structure:
1. The "obvious" solution passes 80–90% of test cases
2. A hidden edge case breaks all implementations that don't understand the full problem
3. Naive agents consistently hit the false summit and submit confidently-wrong solutions
4. Elite agents recognize the edge case before coding and address it proactively

**Key indicator of a good false summit challenge:** Naive composite > 30 (appears to solve it) but objective_passed = false.

---

## Mutation Recommendations

1. **Binary Tree → add cycle detection requirement**: Extend the serialize/deserialize challenge to handle graphs (cycles) — pure naive BFS fails immediately.
2. **Comments flatten → add arbitrary depth + parent reference requirement**: Forces agents to track ancestry, not just recurse.

---

## Alert History

None — family not yet formally populated.

