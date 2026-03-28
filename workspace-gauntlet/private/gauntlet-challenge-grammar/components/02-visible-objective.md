# Component 2: Visible Objective

## Definition
What the agent is told to accomplish. The briefing. The stated mission.

## Discrimination Function
The Visible Objective creates the first filter: agents that blindly follow instructions vs agents that verify whether the instructions lead to the right solution.

| Agent Tier | Behavior | Why |
|-----------|----------|-----|
| **Average** | Follows the Visible Objective literally. Implements exactly what's asked. | No critical evaluation of the request itself. |
| **Strong** | Follows the Visible Objective but notices inconsistencies with the codebase, tests, or logs. Adjusts approach. | Cross-references the briefing against evidence. |
| **Elite** | Evaluates the Visible Objective against the Task Core. May explicitly diverge from the stated objective when evidence warrants it. Documents why. | Treats the briefing as input to evaluate, not instructions to follow. |

**Why this widens spread:** Literal compliance with a misleading objective can score 15-35 (some visible tests pass). Adjusted compliance scores 40-65. Principled divergence with evidence scores 70+.

## Anti-Compression Rules
- The Visible Objective must be PLAUSIBLE — not obviously wrong. If agents can trivially see the objective is misleading, there's no discrimination.
- The Visible Objective must lead to PARTIAL success if followed literally — not zero. Binary outcomes (follow = 0, don't follow = 100) compress the middle.
- For Tier 2+, the Visible Objective should include at least one element that points agents in a productive-but-incomplete direction.

## Same-Model Separation Contribution
Low-Medium — some scaffolding designs validate objectives against evidence before starting, others don't. The WHEN of questioning the objective (immediately? after first failure? never?) is scaffolding-dependent.

## Composition Rules
- Must be written in the voice of a realistic stakeholder (PM, on-call engineer, client)
- Must include enough context to be actionable
- Must NOT include hints about the hidden invariant
- May include stakeholder opinions that are wrong (e.g., "I think it's a Redis issue")

## Template
```
VISIBLE OBJECTIVE: [Full briefing text — what the agent sees]
STAKEHOLDER VOICE: [PM / engineer / client / incident report]
MISLEADING ELEMENTS: [What in the objective points the wrong direction]
PRODUCTIVE ELEMENTS: [What in the objective is genuinely useful]
PARTIAL SUCCESS CEILING: [Max score if objective is followed literally — should be 25-45]
```
