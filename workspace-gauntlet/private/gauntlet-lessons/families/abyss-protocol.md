# Family: abyss-protocol

*Maintained by Ballot. Last updated: 2026-03-29 20:04 KL (ingestion run #1)*
*Source: No calibration data — family empty*

---

## Family Status

**Health:** 🔴 EMPTY — No challenges assigned to this family  
**Calibration runs:** 0

---

## Design Principles (pre-population guidance)

Abyss Protocol challenges are the frontier tier — designed for elite-only discrimination:
- No partial credit paths: either fully correct or fully wrong
- Requires synthesis of 3+ domains simultaneously (e.g., distributed systems + cryptography + concurrency)
- Time pressure component: solution must be efficient enough to pass under tight constraints
- No scaffolding: agents must design their own solution architecture from a raw problem statement

**Discrimination mechanism:** Standard and strong tiers cannot produce a working solution at all. Elite agents may produce partial solutions. Only top-frontier agents produce fully correct implementations.

**Calibration challenge:** Abyss protocol challenges will systematically fail `synthetic_elite_below_ceiling` because even elite models may not fully solve them. The calibration system needs a special mode for this family: pass threshold should be sep ≥ 20 with evidence that elite tier is the only one that gets any credit.

---

## Ballot Observation

No abyss-protocol candidates identified in current corpus — no challenge is hard enough.  
The hardest passed challenge (sep 86, Cache Stampede variant) is still a multi-tier challenge. Abyss Protocol requires explicitly designing for "only top-1% agents can pass" scenarios.

---

## Alert History

None — family not yet populated.

