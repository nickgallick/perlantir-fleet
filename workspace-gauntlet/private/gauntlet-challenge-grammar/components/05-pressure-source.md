# Component 5: Pressure Source

## Definition
What creates urgency or constraint. Structural forces that prevent agents from converging to the same solution through exhaustive effort.

## Discrimination Function
Without pressure, given enough time, many agents converge to similar solutions. Pressure is the AMPLIFIER — it makes existing quality differences larger by forcing tradeoffs.

| Agent Tier | Behavior | Why |
|-----------|----------|-----|
| **Average** | Cracks under pressure. Skips verification, makes reckless choices, submits incomplete work, or freezes and produces nothing. | No prioritization framework. Can't distinguish important from urgent. |
| **Strong** | Manages pressure through prioritization. Works on the highest-value items first. Makes conscious tradeoffs and documents them. | Has a systematic approach to scarcity. |
| **Elite** | Thrives under pressure. Pressure reveals their efficiency — they produce clean work within constraints because their process is already lean. Uses pressure as a filter to focus on what matters most. | Internalized efficiency. Pressure doesn't change their approach, just their scope. |

**Why this widens spread:** Without time pressure, a 3-hour challenge lets every agent eventually explore everything. With 40 minutes, WHAT the agent chooses to do first determines the outcome. Prioritization IS discrimination.

## Pressure Types

| Type | Mechanism | Best For |
|------|-----------|----------|
| **Time** | Tight limit relative to work | Sprint format, triage challenges |
| **Resource** | Limited tool calls, iterations, context window | Efficiency testing, constraint challenges |
| **Scope** | Too much to do, must prioritize | Multi-bug debugging, large codebases |
| **Correctness** | Partial solutions score poorly, must get core right | Implementation challenges |
| **Competing** | Two good approaches, can only pursue one | Strategy challenges, tradeoff evaluation |

## Anti-Compression Rules
- Pressure must NOT be so extreme that ALL agents fail equally — that compresses scores at the bottom.
- Sweet spot: 60-70% of the "comfortable" time/resources. Strong agents finish with some margin. Average agents run out.
- Optimal time pressure per difficulty dimension data: 5-6 out of 10 produces best CDI. Above 8 all agents fail equally (CDI drops).
- Competing pressure is the highest-discrimination type — it forces visible strategic choices that create telemetry differences.

## Same-Model Separation Contribution
**High** — pressure reveals scaffolding quality more than any other component. Under pressure:
- Well-designed scaffolding prioritizes, checkpoints, and adapts
- Poorly-designed scaffolding panics, repeats, or freezes
- Same base model, same knowledge, completely different behavior under constraint

## Template
```
PRESSURE SOURCE:
  Primary type: [time / resource / scope / correctness / competing]
  Intensity: [1-10]
  Mechanism: [Specific description of what creates the pressure]
  Comfortable time: [How long it would take without pressure]
  Challenge time: [Actual time limit — should be 60-70% of comfortable]
  WHAT GETS SACRIFICED: [What average agents will skip that strong agents won't]
```
