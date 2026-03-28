# LAUNCH_DECISION_RULES.md — Polish Launch Decision Framework

Every major Polish audit must end with one of three decisions:
**SHIP** / **CONDITIONAL SHIP** / **NO-SHIP**

This file makes those decisions rules-based, not impression-based.

---

## Decision Definitions

### NO-SHIP
**Meaning**: Polish cannot recommend launch. Platform is not ready.
**When to use**: Any of the following conditions are true.

**Automatic NO-SHIP triggers (one is enough):**

| Trigger | Reason |
|---------|--------|
| Any P0 finding unresolved | Trust-destroying or brand-damaging issue present |
| Trust Signal Quality score ≤ 4 | Platform cannot be trusted |
| Anti-AI-Built Quality score ≤ 3 | Platform embarrasses the brand at launch |
| Weighted overall score < 6.0 | Below minimum acceptable product quality |
| Legal pages are placeholder/empty | Legal non-compliance is a blocker |
| Onboarding compliance fields missing | Iowa Code § 99B compliance breach |
| Homepage communicates wrong product identity | Wrong brand, wrong promise |
| Admin/operator surface looks like a prototype | Operator trust destroyed |

---

### CONDITIONAL SHIP
**Meaning**: Platform can launch if and only if specific named conditions are resolved.
**When to use**: No P0s, but P1s or score gaps exist.

**All of the following must be true for Conditional Ship:**
- [ ] Zero unresolved P0 findings
- [ ] All P1 findings documented with assigned owner and explicit fix timeline
- [ ] Weighted overall score ≥ 6.5
- [ ] No individual category score < 5
- [ ] Trust Signal Quality ≥ 6
- [ ] Anti-AI-Built Quality ≥ 6
- [ ] Legal pages confirmed real content
- [ ] Onboarding compliance confirmed (DOB + state + 6 checkboxes)

**Conditions must be explicit and specific:**
❌ Bad: "Fix the homepage copy before launch"
✅ Good: "Replace hardcoded stats (src/app/page.tsx lines 50-59) with real data or remove them before launch — P2 finding P-004"

---

### SHIP
**Meaning**: Polish recommends launch. Platform meets the quality standard.
**When to use**: All quality bars are met.

**All of the following must be true for Ship:**
- [ ] Zero P0 findings
- [ ] P1 findings are either resolved or explicitly accepted by Nick with documented reasoning
- [ ] Weighted overall score ≥ 7.5
- [ ] No individual category score < 6
- [ ] Trust Signal Quality ≥ 7
- [ ] Anti-AI-Built Quality ≥ 7
- [ ] Visual Maturity ≥ 7
- [ ] Copy Maturity ≥ 7
- [ ] Enterprise Readiness ≥ 7
- [ ] All P0 routes audited and confirmed (no ❌ in ROUTE_INVENTORY.md)

---

## P0/P1 Count → Launch Impact Matrix

| P0 count | P1 count | Decision |
|----------|----------|----------|
| 0 | 0 | SHIP (if scores pass) |
| 0 | 1–2 | CONDITIONAL SHIP |
| 0 | 3–5 | CONDITIONAL SHIP (conditions require timeline) |
| 0 | 6+ | NO-SHIP (too many major failures) |
| 1+ | Any | NO-SHIP |

---

## Score Floor Matrix

| Category | SHIP floor | CONDITIONAL SHIP floor | NO-SHIP trigger |
|----------|-----------|----------------------|-----------------|
| Visual Maturity | ≥ 7 | ≥ 6 | < 5 |
| Copy Maturity | ≥ 7 | ≥ 6 | < 5 |
| Enterprise Readiness | ≥ 7 | ≥ 6 | < 5 |
| Product Consistency | ≥ 7 | ≥ 5 | < 4 |
| Anti-AI-Built Quality | ≥ 7 | ≥ 6 | ≤ 3 |
| Trust Signal Quality | ≥ 7 | ≥ 6 | ≤ 4 |
| Mobile Quality | ≥ 7 | ≥ 5 | < 4 |
| Interaction Maturity | ≥ 6 | ≥ 5 | < 4 |
| **Weighted overall** | **≥ 7.5** | **≥ 6.5** | **< 6.0** |

---

## Decision Output Format

Every Polish audit must end with this exact block:

```
## LAUNCH DECISION

**Decision**: SHIP / CONDITIONAL SHIP / NO-SHIP

**Weighted Score**: X.X / 10
**Letter Grade**: X

**P0 findings**: X (all must be resolved before SHIP)
**P1 findings**: X

**Blocking conditions** (if CONDITIONAL SHIP):
1. [Specific fix] — [assigned to] — [deadline if known]
2. 

**Non-blocking P1s accepted for launch** (with Nick's approval):
1. [Finding] — [reason accepted] — [post-launch fix owner]

**Confidence level**: High / Medium / Low
**Coverage**: [X / Y P0 routes audited, X / Y P1 routes audited]
```

---

## Who Makes the Final Call
Polish recommends. Nick decides.

If Polish says NO-SHIP and Nick wants to override:
- Nick must explicitly accept each unresolved P0 with documented reasoning
- ClawExpert must be notified of the override
- The override is logged in Polish's audit report

Polish does not have authority to approve a launch over a P0. That is Nick's call. But Polish's job is to ensure Nick makes that call with full information.
