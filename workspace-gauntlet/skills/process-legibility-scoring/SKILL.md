# Process Legibility Scoring — Skill 55

## Purpose
Reward process quality when it predicts durable success. Two agents can both score 85/100 on objective tests — but one got there by disciplined engineering and the other by brittle lucky flailing. The first is dramatically more valuable in real deployment.

## Core Concept
Process legibility measures whether the agent's REASONING is visible and sound, not just its output.

## Process Legibility Dimensions

| Dimension | Description | Detection Method |
|-----------|-------------|-----------------|
| **Explicit hypotheses** | Agent forms and states hypotheses before acting | Comments/commits containing "I believe...", "Testing whether...", "My hypothesis is..." |
| **Subproblem tracking** | Agent breaks work into named steps and tracks progress | Structured approach with labeled phases, checkpoints |
| **Test interpretation quality** | When tests fail, agent analyzes WHY, not just tries again | Specific failure analysis vs blind retry patterns |
| **Contradiction detection** | Agent notices when new evidence contradicts earlier conclusions | Explicit acknowledgment of conflicting information |
| **State management** | Agent tracks what's changed, tested, and remaining | Running notes, structured commit messages, progress markers |
| **Uncertainty acknowledgment** | Agent says "I'm not sure about X" when appropriate | Hedged statements where warranted, confidence calibration |
| **Tool invocation rationale** | Agent explains WHY it's using a specific tool | Tool calls preceded by reasoning about expected outcome |
| **Transparent recovery reasoning** | When changing approach, agent explains why the old approach failed | Pivot accompanied by failure analysis |

## Scoring Weight

Process legibility is evaluated by:
- **Process Judge** (20% of total): Telemetry analysis — tool patterns, edit sequences, test frequency
- **Strategy Judge** (20% of total): Reasoning quality in deliverables — comments, commit messages, documentation

Together these account for **40% of the final score** — significant enough to matter but never able to override terrible code.

## Critical Constraint

> Process legibility should NEVER overpower objective success.

Between two agents with similar objective scores, the one with legible process is more trustworthy and more useful as a collaborator. But a well-documented wrong answer is still a wrong answer.

| Scenario | Interpretation |
|----------|---------------|
| High Objective + High Process | Elite — reliable AND transparent |
| High Objective + Low Process | Lucky or brittle — high risk of inconsistency |
| Low Objective + High Process | Methodical but wrong — good process, needs more skill |
| Low Objective + Low Process | Weak — neither output nor process is trustworthy |

## Legibility vs Verbosity

Legibility is NOT:
- Writing long comments that repeat what the code says
- Over-documenting trivial decisions
- Narrating every tool call with boilerplate

Legibility IS:
- Documenting non-obvious decisions
- Explaining WHY, not WHAT
- Acknowledging uncertainty where it exists
- Tracking state across a complex task

## Measurement Examples

### High Legibility
```
# Hypothesis: The race condition occurs in the order processing pipeline.
# Evidence: Logs show interleaved writes to order_items table.
# Plan: 1) Add row-level locking 2) Verify with concurrent test 3) Check for other shared state

# After testing: Row-level locking fixed the order_items issue, but I'm seeing a
# second potential race in the payment callback handler. Investigating before final submission.
```

### Low Legibility
```
# Fixed bug
# Updated code
# Should work now
```

## Integration Points

- **Strategic Tempo** (Skill 54): Tempo is a sub-component — when the agent acts reveals process quality
- **Failure Archetypes** (Skill 48): Many archetypes (Premature Convergence, Context Drift) are visible through process analysis
- **CDI** (Skill 46): High-legibility challenges produce better Learning Signal Quality
- **Agent Profiles** (Skill 50): Process Cleanliness dimension fed by legibility scores
