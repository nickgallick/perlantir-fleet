# Strategic Tempo Evaluation — Skill 54

## Purpose
Measure not just correctness, but the quality of TIMING decisions. Tempo is WHEN the agent explores, commits, verifies, pivots, escalates, and defers.

## Core Concept
Great agents often outperform average ones because they control tempo better — not because they write better code.

## Tempo Signals

### Negative Tempo Signals

| Signal | Description | Detection |
|--------|-------------|-----------|
| **Over-commitment** | Coding before reading the full codebase | First substantial edit < 2 min after start |
| **Unnecessary delay** | Reading every file when the bug is in one obvious place | > 50% of time in exploration with low information gain |
| **Bad verification timing** | Writing 500 lines before running a single test | Large diff with no intermediate test runs |
| **Failure to checkpoint** | No intermediate test runs between major changes | Edit streak > 10 files without any test execution |
| **Too-late pivoting** | 80% of time on wrong approach before switching | Major direction change after 80%+ time elapsed |
| **Reckless acceleration** | Submitting without testing after running out of patience | Final submission with no test run in last 20% of time |

### Positive Tempo Signals

| Signal | Description | Detection |
|--------|-------------|-----------|
| **Productive patience** | Spending time understanding before acting (when warranted) | Exploration phase proportional to problem complexity |
| **Well-timed tool use** | Using search/debug tools at the right moment | Tool calls that change the agent's approach productively |
| **Incremental verification** | Testing after each meaningful change | Test runs distributed throughout the session |
| **Early pivoting** | Recognizing wrong approach quickly and switching | Direction change before 30% of time elapsed |
| **Strategic escalation** | Moving to more powerful tools/approaches when simpler ones fail | Tool complexity increases with problem difficulty |

## Tempo Scoring

Tempo is NOT pure speed. It is the quality of timing decisions under uncertainty.

### Example: Two agents, both finish in 30 minutes

**Agent A** (Reckless):
```
0:00 - 2:00  → Quick scan
2:00 - 27:00 → Coded continuously
27:00 - 28:00 → Ran tests once
28:00 - 30:00 → Submitted
```
Tempo score: Low — no incremental verification, no exploration proportional to complexity

**Agent B** (Disciplined):
```
0:00 - 8:00  → Read codebase, identified key areas
8:00 - 11:00 → Planned approach, documented hypotheses
11:00 - 23:00 → Coded in chunks, tested 3 times
23:00 - 26:00 → Reviewed, refined based on test results
26:00 - 30:00 → Final verification, submitted
```
Tempo score: High — exploration matched complexity, incremental verification, hypothesis-driven

### Average vs Elite Tempo Patterns

Average agents either:
- **Rush and break things** (reckless tempo)
- **Hesitate and drown in context** (paralyzed tempo)

Elite agents:
- **Know when to act** (calibrated tempo)
- Phase transitions are deliberate and appropriately timed

## Measurement

Tempo is primarily evaluated by the **Process Judge**, using session telemetry:

| Telemetry Source | What It Reveals |
|-----------------|-----------------|
| Timestamps on tool calls | Exploration vs execution ratio |
| File read patterns | Breadth-first vs depth-first exploration |
| Edit-to-test intervals | Verification discipline |
| Direction changes with timestamps | Pivot timing quality |
| Tool call sequence | Escalation pattern |

## Tempo-CDI Interaction

Challenges that produce **high tempo variance** across agents are highly discriminative. If all agents have the same tempo pattern, the challenge doesn't test timing decisions.

Good challenge design should create tempo decision points — moments where:
- The right amount of exploration is non-obvious
- The right time to commit is ambiguous
- The right verification strategy depends on understanding the problem

## Integration Points

- **Process Legibility** (Skill 55): Tempo is one component of overall process quality
- **Failure Archetypes** (Skill 48): Premature Convergence and False Confidence Stop are tempo failures
- **Adaptive Phases** (Skill 53): Phase shifts create forced re-planning that tests tempo flexibility
- **CDI** (Skill 46): Tempo variance contributes to Score Variance Quality
