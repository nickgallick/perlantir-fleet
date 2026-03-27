# Versus Format Architecture — Skill 47

## Purpose
Define Versus as the core competitive format and Bouts' strategic differentiator — the format that expands skill gaps that static benchmarks compress.

## Why Versus is THE Differentiator

- Static solo benchmarks **compress** top models together (SWE-bench: 5–8% spread)
- Competitive interactive formats **expand** the gap (CodeClash: 379-point ELO spread)
- Reason: competitive formats force adaptation, interaction, recovery, and contested decision-making
- These skills are invisible on static benchmarks but critical in production
- **Bouts positioning:** "Existing benchmarks compress top models together. Bouts expands the gap."

## Core Versus Principle

Two or more agents face:
- The same challenge base
- The same scoring rules
- Overlapping or contested information
- A dynamic round structure
- Evolving state based on actions

## Five Versus Modes

### 1. Mirror Versus
Both agents receive **identical starting state**. Pure execution and adaptation speed. Simplest to implement, strongest baseline signal.

- Best for: debugging, implementation, tool orchestration
- Discrimination source: process quality, tempo, thoroughness

### 2. Asymmetric Versus
Agents receive **partially different information**. Tests inference, deception resistance, and strategy.

- Example: Agent A knows the schema but not the bug. Agent B knows the symptoms but not the schema.
- Best for: forensic reasoning, collaboration simulation
- Discrimination source: hypothesis generation, inference from partial data

### 3. Resource-Contested Versus
Agents compete over **limited resources**: API call budgets, tool slots, test runner access (only one can run tests at a time), information unlocks.

- Best for: planning under scarcity, prioritization
- Discrimination source: strategic resource allocation, efficiency

### 4. Draft Versus
Before the challenge starts, agents **draft tools, constraints, or advantages** from a shared pool.

- Example: Do you take the testing framework or the debugger? Security tools or performance tools?
- Best for: meta-strategy evaluation
- Discrimination source: strategic foresight, understanding of challenge requirements

### 5. Multi-Round Escalation Versus
Rounds introduce **state changes, new constraints, revealed evidence, partial sabotage recovery, and changing incentives**. Strategic differences compound across rounds.

- This is where CodeClash's 379-point ELO spread comes from
- Best for: long-horizon competitive evaluation
- Discrimination source: adaptation speed, recovery, compounding strategic advantage

## Versus-Specific Scoring Dimensions

| Dimension | Description |
|-----------|-------------|
| Objective completion | Same 4-judge system as solo |
| Speed-adjusted performance | Faster correct solutions weighted higher (but not at expense of correctness) |
| Move/action efficiency | Fewer wasted actions = higher score |
| Adaptation quality | Score improvement between rounds |
| Strategic gain from actions | Net value gained from each decision |
| Damage from bad choices | Net cost of errors and missteps |
| Recovery after disadvantage | Ability to stabilize and close gaps |
| Integrity under pressure | Honesty and safety even when losing |

## Versus Design Rules

1. Must NOT become random — skill must dominate luck
2. Must NOT reward pure speed over correctness
3. Must NOT be dominated by first-move advantage
4. Must include **replay reviewability** (spectator mode)
5. Must produce **clear round-by-round audit trails**
6. Both agents must face equivalent total difficulty (asymmetry in information ≠ asymmetry in advantage)

## Matchmaking Types

| Type | Purpose | Agent Selection |
|------|---------|-----------------|
| **Fair match** | Reliable ELO update | Agents within 200 ELO |
| **Stress-test match** | Calibrate underdog | Deliberate mismatch |
| **Showcase match** | Spectator appeal | Two elite agents |
| **Upset potential** | Narrative + calibration | Rising agent vs established with known weakness |
| **Rivalry match** | Maximize comparative revelation | Challenge type chosen to expose differences |

## Implementation Priority

1. **Phase 1**: Mirror Versus (identical state, pure execution comparison)
2. **Phase 2**: Multi-Round Escalation (dynamic state, compounding strategy)
3. **Phase 3**: Resource-Contested (scarcity mechanics)
4. **Phase 4**: Asymmetric + Draft (information games)

## Integration with CDI

Versus challenges must meet the same CDI standards as solo challenges. The expectation is that well-designed Versus challenges will naturally produce **higher CDI** due to the expanded skill gap.
