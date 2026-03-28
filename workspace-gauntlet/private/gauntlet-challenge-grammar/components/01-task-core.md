# Component 1: Task Core

## Definition
The fundamental engineering problem being tested. One sentence. Stripped of narrative, context, decoration.

## Discrimination Function
The Task Core defines what ACTUALLY matters. The gap between the Task Core and the Visible Objective is the first discrimination fork.

| Agent Tier | Behavior | Why |
|-----------|----------|-----|
| **Average** | Takes Visible Objective at face value. Solves what they're told. | Doesn't investigate whether the stated problem is the real problem. |
| **Strong** | Recognizes the Task Core may differ from the Visible Objective. Investigates before committing. | Reads more context, notices inconsistencies, questions assumptions. |
| **Elite** | Identifies the Task Core precisely, maps its full scope, and plans work around it — not around the Visible Objective. | Deep codebase understanding, traces cause chains, identifies what's really broken vs what's a symptom. |

**Why this widens spread:** Agents that solve the wrong problem can still score 20-40 (fixing symptoms, passing some visible tests) but cannot reach 60+ (hidden invariants test the real problem).

## Anti-Compression Rules
- The Task Core must NOT be identical to the Visible Objective for Tier 2+ challenges. If they're identical, there's no gap to exploit for discrimination.
- The Task Core must be DISCOVERABLE through the provided materials — not guessable. There must be a systematic path from the materials to the real problem.
- The Task Core must not require domain knowledge the agent can't derive from the codebase. Tests reasoning, not training data.

## Same-Model Separation Contribution
Low — Task Core understanding is mostly base model capability. BUT: the speed and method of discovery differs by scaffolding (some agents explore breadth-first, some depth-first, some follow heuristics).

## Composition Rules
- **All tiers**: One sentence. No ambiguity about what Gauntlet is testing.
- **Tier 0-1**: Task Core = Visible Objective (transparent)
- **Tier 2**: Task Core is adjacent to Visible Objective (e.g., visible = "fix the test", real = "the test is right, the upstream is broken")
- **Tier 3+**: Task Core may be substantially different from Visible Objective (e.g., visible = "implement this feature", real = "recognize this feature would create a vulnerability")

## Template
```
TASK CORE: [One sentence — what is actually being tested]
VISIBLE OBJECTIVE GAP: [none / adjacent / substantial]
DISCOVERY PATH: [How a strong agent finds the real problem through the materials]
```
