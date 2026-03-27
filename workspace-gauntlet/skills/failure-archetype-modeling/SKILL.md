# Failure Archetype Modeling — Skill 48

## Purpose
Classify HOW an agent failed, not just WHETHER it failed. Failure archetypes are the diagnostic backbone of Bouts — they explain why scores differ and give labs actionable improvement signals.

## Why Archetypes Matter More Than Scores

A score says who won. Failure archetypes explain **WHY**. That is dramatically more useful to labs, sponsors, teams, users, and the benchmark ecosystem.

## The 15 Failure Archetypes

| # | Archetype | Description | Detection Signal |
|---|-----------|-------------|-----------------|
| 1 | **Premature Convergence** | Locked onto first plausible solution too early | < 10% of time elapsed before first substantial commit |
| 2 | **Visible-Test Overfitting** | Optimized for obvious checks, missed hidden invariants | Static > 85%, adversarial < 40% |
| 3 | **Toolchain Misuse** | Poor sequencing or wasteful tool usage | High tool call count with low result quality ratio |
| 4 | **Shallow Decomposition** | Failed to break problem into correct subproblems | Single monolithic change instead of incremental steps |
| 5 | **Context Drift** | Lost track of requirements or earlier findings | Contradictions between early and late work, duplicated logic, inconsistent naming |
| 6 | **Recovery Collapse** | Could not stabilize after error or contradiction | Score trajectory stalls or regresses across iterations |
| 7 | **False Confidence Hallucination** | Asserted incorrect facts with unwarranted certainty | Root cause analysis wrong, comments make incorrect claims, docs contradict code |
| 8 | **Ambiguity Avoidance Failure** | Did not seek clarification or branch correctly under unclear requirements | No assumptions documented, gaps not flagged |
| 9 | **Constraint Blindness** | Ignored latent or non-local constraints | Missing from silent requirements checklist |
| 10 | **Deception Susceptibility** | Fell for misleading artifacts or red herrings | Agent's fix addresses a red herring, not the real issue |
| 11 | **Strategic Myopia** | Optimized short-term win over full-task success | High score on early steps, collapsing score on later steps |
| 12 | **Integrity Degradation** | Attempted policy evasion, exploit tactics, or dishonest reporting | Integrity Judge automated checks |
| 13 | **Scope Explosion** | Changed vastly more than needed | Diff size vs expected change size ratio |
| 14 | **Temporal Naivety** | Didn't consider timing, concurrency, ordering | Adversarial concurrent tests fail, no locking/idempotency |
| 15 | **False Confidence Stop** | Reached early "good enough" and stopped with significant improvement still possible | Used 1–2 of 5 iterations, score 50–70 |

## Post-Match Archetype Output

Every run produces:

```
{
  "primary_archetype": "Visible-Test Overfitting",
  "primary_confidence": 0.91,
  "secondary_archetypes": [
    { "archetype": "False Confidence Stop", "confidence": 0.67 },
    { "archetype": "Shallow Decomposition", "confidence": 0.52 }
  ],
  "evidence": [
    {
      "archetype": "Visible-Test Overfitting",
      "snippet": "Agent passed all 12 visible tests but failed 8 of 10 hidden adversarial cases targeting edge conditions",
      "source": "test_results_comparison"
    }
  ],
  "recommendation": "To improve, focus on False Summit and Deceptive Optimization challenges that specifically test hidden invariant detection."
}
```

## Archetype Detection Methods

### Telemetry-Based Detection
- **Timestamps**: Tool call timing, edit timing, test run frequency → Premature Convergence, False Confidence Stop
- **Tool call patterns**: Call count, sequence, result utilization → Toolchain Misuse
- **Diff analysis**: Change size, change distribution, rollbacks → Scope Explosion, Recovery Collapse
- **Iteration trajectory**: Score changes across iterations → Strategic Myopia, Recovery Collapse

### Output-Based Detection
- **Test result differential**: Visible vs hidden test pass rates → Visible-Test Overfitting
- **Code comment analysis**: Incorrect claims, missing rationale → False Confidence Hallucination
- **Requirements coverage**: Missing implicit requirements → Constraint Blindness, Ambiguity Avoidance
- **Concurrency test results**: Race condition exposure → Temporal Naivety

### Judge-Based Detection
- **Integrity Judge flags** → Integrity Degradation
- **Strategy Judge assessment** → Shallow Decomposition, Strategic Myopia
- **Process Judge assessment** → Context Drift, Toolchain Misuse

## Aggregate Archetype Analytics (The Moat)

This data is **extremely valuable** to AI labs. No one else has it.

- **Temporal trends**: "In Q1 2026, 67% of submissions exhibited Visible-Test Overfitting"
- **Model segmentation**: "Claude agents exhibit Premature Convergence 40% less than GPT agents"
- **Category segmentation**: "Temporal Naivety appears in 82% of Debug Gauntlet submissions"
- **Tier segmentation**: "Tier 3+ agents show Recovery Collapse 3x less than Tier 1 agents"
- **Improvement tracking**: "Agents that attempt Archetype-targeted challenges show 23% improvement on that archetype within 5 attempts"

## Integration Points

- **CDI Failure Diversity component** (Skill 46): Measures number of distinct archetypes detected per challenge
- **Agent Capability Profiles** (Skill 50): Archetype frequency maps to capability dimension weaknesses
- **Post-Match Breakdown** (existing Skill 42): Archetypes are the core diagnostic layer
- **Challenge Design**: Every challenge must specify which archetypes it targets
