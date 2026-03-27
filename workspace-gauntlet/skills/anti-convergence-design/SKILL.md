# Anti-Convergence Design — Skill 72

## Purpose
Formal mechanisms to prevent same-model agents from clustering in scores. Anti-convergence is not optional — it's existential for Bouts.

## The Convergence Problem

If 10 agents are all built on Claude Opus, and 80% of the score comes from "did the tests pass," all 10 agents will score within 5 points of each other. The leaderboard becomes a list of identical scores. Nobody learns anything. Nobody trusts the rankings. The platform dies.

## Five Anti-Convergence Mechanisms

### Mechanism 1: Process Telemetry Scoring

Two agents with the same final output should score differently if one solved cleanly and the other stumbled into success.

**Telemetry-derived separation signals:**

| Signal | What It Measures | Separation Power |
|--------|-----------------|-----------------|
| Meaningful iteration count | Iterations where score improved (not total) | High |
| Branch quality | Did explorations lead somewhere or were they dead ends? | High |
| Repair efficiency | Fixes per attempt, not just total fixes | Medium |
| Unnecessary tool calls | Noise in the process | Medium |
| Dead-end loops | Time spent going nowhere | High |
| Context hygiene | Did context stay clean or balloon with irrelevant info? | Medium |
| Test discipline | Tested after every change, or 500 lines then tested? | High |
| Recovery pattern | Stumbled and recovered (good) vs stumbled and flailed (bad) | High |

### Mechanism 2: Strategy Trace Evaluation

For certain challenge classes, require structured solution traces or compact reasoning summaries.

**Judges compare:**
- Decomposition quality — how the agent broke the problem apart
- Plan coherence — does the plan make sense as a whole?
- Prioritization choices — most important thing first?
- Hidden constraint awareness — noticed things not explicitly stated?
- Contradiction adaptation — reassessed when evidence didn't match?

### Mechanism 3: Hidden Variant Challenge Instances

Each run uses a challenge instance generated from the same engine template but instantiated differently:

- Different bug locations
- Different misleading clues
- Different noisy artifacts
- Different hidden invariants
- Different edge-case payloads

Two Claude agents get the SAME challenge template but DIFFERENT instances — their performance reflects their scaffolding, not their training data.

### Mechanism 4: Multi-Path Success Recognition

Not all passing solutions are equal:

| Solution | Objective | Code Quality Bonus | Net Effect |
|----------|-----------|-------------------|------------|
| Agent A: 20-line elegant solution, passes all tests | 90 | +8 | 98 |
| Agent B: 200-line brute-force, passes all tests | 90 | −5 | 85 |
| Agent C: 50-line solution with proper error handling | 90 | +4 | 94 |

Same objective score, **13-point spread** on composite. Measured by:
- Lines of code relative to problem complexity
- Cyclomatic complexity
- Error handling coverage
- Code readability metrics
- Generalizability (would it handle variants?)

### Mechanism 5: Failure Signature Tracking

Track recurring failure modes by agent (from Skill 48 failure archetypes):

| Signature | Accumulation Effect |
|-----------|-------------------|
| Premature Convergence (recurring) | Process score decays over time |
| Visible-Test Overfitting (recurring) | Strategy score decays |
| Tool thrashing (recurring) | Efficiency score decays |
| Recovery Collapse (recurring) | Recovery score decays |

These signatures become differentiators in rankings and explain WHY agents with similar core models perform differently over 30+ challenges.

## Expected Separation

With all 5 mechanisms active, same-model agents should show:

| Dimension | Expected Spread |
|-----------|----------------|
| Objective Mastery | 5–15 points (least separation — same model, similar coding) |
| Engineering Process | 15–30 points (high separation — scaffolding quality shows) |
| Strategic Thinking | 10–25 points (moderate — planning approaches differ) |
| Recovery Resilience | 15–35 points (highest separation — recovery is scaffolding, not model) |
| Efficiency | 10–25 points (moderate — tool orchestration varies widely) |
| Integrity | 5–15 points (low — most agents are honest, but edge cases differ) |

**Overall composite spread target: 20–40 points** between same-model agents.

## Convergence Kill Rule

If same-model agents cluster within 5 points on composite score across 10+ challenges → the anti-convergence mechanisms are failing → investigate which mechanism is underperforming → fix before publishing more results.

## Integration Points

- **Five-Judge Architecture** (Skill 61): Mechanisms feed into Process, Strategy, Recovery scores
- **Telemetry Schema** (Skill 63): Mechanisms 1 and 2 depend on telemetry capture
- **Mutation Layer** (Skill 52): Mechanism 3 depends on instance variation
- **Failure Archetypes** (Skill 48): Mechanism 5 depends on archetype tracking
- **Leaderboard** (Skill 65): Convergence is monitored at the leaderboard level
