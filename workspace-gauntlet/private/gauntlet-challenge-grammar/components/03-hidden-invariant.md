# Component 3: Hidden Invariant

## Definition
Requirements that exist but are not stated. The agent must discover or infer them from the codebase, tests, logs, architecture, or domain knowledge.

## Discrimination Function
Hidden invariants create the second major score fork. Agents that only satisfy stated requirements plateau. Agents that discover unstated requirements break through.

| Agent Tier | Behavior | Why |
|-----------|----------|-----|
| **Average** | Satisfies only what's explicitly stated. Passes visible tests. Declares done. | No investigation beyond the briefing. |
| **Strong** | Discovers 1-2 hidden invariants through systematic code review or testing. Addresses them. | Reads beyond the immediate problem area. Notices patterns. |
| **Elite** | Discovers all hidden invariants. Understands WHY they exist (security, performance, correctness). Addresses them with appropriate solutions, not patches. | Deep architectural understanding. Asks "what else could be wrong?" |

**Why this widens spread:** Visible tests only cover stated requirements. Hidden invariants are only tested by adversarial/invariant test suites. This creates a clean score ceiling: agents that don't discover hidden invariants max at ~55 on the Objective Judge.

## Anti-Compression Rules
- Hidden invariants must be DISCOVERABLE through systematic investigation — not requiring lucky guesses or obscure knowledge.
- There must be CLUES in the provided materials (e.g., a `// TODO: add input validation` comment, a `.env.example` with unused variables, a test helper that tests for something the main suite doesn't).
- Hidden invariants should have GRADUATED difficulty: one should be findable with moderate effort, one should require deep investigation. This prevents bimodal scoring (found all / found none).
- At least one hidden invariant must be testable by the agent if they think to write a test for it.

## Same-Model Separation Contribution
Medium — the discovery PATH differs by scaffolding. Some agents do systematic file-by-file review. Some search for patterns. Some test first and investigate failures. The approach (and therefore the telemetry) differs even when the discovery is the same.

## Composition Rules
- **Tier 0-1**: 0-1 hidden invariants (mostly transparent)
- **Tier 2**: 1-2 hidden invariants with clear clues
- **Tier 3**: 2-3 hidden invariants, some with subtle clues
- **Tier 4/Frontier**: 3+ hidden invariants with interconnections

## Template
```
HIDDEN INVARIANTS:
  1. [invariant] — Clue: [what points to it] — Discovery effort: [easy/moderate/hard]
  2. [invariant] — Clue: [what points to it] — Discovery effort: [easy/moderate/hard]
SCORE CEILING WITHOUT DISCOVERY: [max objective score if all hidden invariants are missed — should be 45-60]
INTERCONNECTIONS: [do any hidden invariants depend on each other?]
```
