# Component 9: Scoring Hooks

## Definition
Specific, designed points where each judge lane has clear evidence to evaluate. Scoring hooks ensure that every discrimination fork maps to a judge lane — no fork is invisible to scoring.

## Discrimination Function
A discrimination fork that isn't captured by any judge is wasted. Scoring hooks make the abstract concrete: "this decision point maps to this judge lane with this evidence type."

| Agent Tier | Behavior | Why |
|-----------|----------|-----|
| **Average** | Produces few hook events. Low Process signal, empty Strategy deliverables, no Recovery events. Judges score from limited evidence → scores cluster around defaults. | Minimal engagement with the designed decision points. |
| **Strong** | Engages with most hooks. Produces clear Process signal, decent Strategy deliverables, some Recovery events. Judges have enough evidence to differentiate. | Engages with the challenge structure as designed. |
| **Elite** | Produces rich evidence at every hook. Process shows systematic approach. Strategy deliverables explain reasoning. Recovery shows clean adaptation. Integrity shows proactive flagging. | The challenge is designed to reward exactly this behavior. |

**Why this widens spread:** Without hooks, 40% of the composite score (Process + Strategy + Recovery) lacks specific evidence, and judges produce noisy scores. With hooks, each lane has designed evaluation points, producing reliable separation.

## Per-Lane Hook Requirements

### Objective Hooks
- Map each deliverable to specific tests
- Map each bug/invariant to specific test groups
- Map partial credit milestones to test results

### Process Hooks
- Map telemetry opportunities to specific rubric questions
- Define what "good process" looks like in THIS challenge's telemetry
- Identify the 3 most discriminative telemetry signals

### Strategy Hooks
- Map each strategic decision to a rubric question
- Define what a required deliverable should contain
- Identify tradeoff moments and what constitutes good/bad reasoning

### Recovery Hooks
- Map each recovery branch to specific telemetry patterns
- Define what detection/diagnosis/recovery look like in session data
- Map iteration trajectory expectations to scoring

### Integrity Hooks
- Map each exploit temptation to a specific detection check
- Map honesty opportunities to specific bonus triggers
- Define escalation triggers (e.g., Strategy high + Objective low)

## Anti-Compression Rules
- Every judge lane must have at least 2 independent hooks — a lane with only 1 hook becomes binary (did it / didn't).
- Hooks must produce GRADUATED evidence — not just yes/no, but how well, how efficiently, how thoroughly.
- No single lane should have >60% of the total hook count — evidence should be distributed.

## Same-Model Separation Contribution
High — hooks ensure that process and recovery differences (which ARE scaffolding differences) are captured in scoring. Without hooks, same-model agents might produce identical objective scores and undifferentiated subjective scores. With hooks, the Process and Recovery lanes have specific, designed evidence to evaluate.

## Template
```
SCORING HOOKS:
  Objective: [deliverable → test mapping, partial credit → test groups]
  Process: [telemetry opportunity → rubric question, 3 most discriminative signals]
  Strategy: [decision point → rubric question, tradeoff → reasoning evaluation]
  Recovery: [recovery branch → telemetry pattern, trajectory → scoring]
  Integrity: [exploit temptation → detection check, honesty opportunity → bonus trigger]
  
JUDGE EVIDENCE MAP: [Reference the full map from Stage 2 — this hook list is the summary]
```
