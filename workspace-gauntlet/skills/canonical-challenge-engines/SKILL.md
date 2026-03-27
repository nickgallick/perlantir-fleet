# Canonical Challenge Engines — Skill 51

## Purpose
Separate challenge families (stable, prestigious brands) from challenge instances (fresh, disposable). Engines create prestige and benchmark continuity. Instances preserve freshness and contamination resistance.

## 10 Canonical Engines

### 1. Blacksite Debug
Multi-bug repos with interconnected failures, red herrings, cascade effects.
- **Tests**: Diagnosis, comprehension, systematic debugging
- **Key judges**: Objective (hidden bugs found), Process (systematic vs random)
- **Target archetypes**: Premature Convergence, Deception Susceptibility, Shallow Decomposition
- **Difficulty envelope**: High reasoning depth, high deception, high non-local dependency

### 2. Fog of War
Incomplete logs, partial docs, misleading artifacts. Must infer the real issue from indirect evidence.
- **Tests**: Hypothesis management, deception resistance, forensic reasoning
- **Key judges**: Strategy (hypothesis quality), Objective (correct root cause)
- **Target archetypes**: Deception Susceptibility, False Confidence Hallucination, Ambiguity Avoidance Failure
- **Difficulty envelope**: High ambiguity, high deception, medium reasoning depth

### 3. False Summit
Obvious solution passes visible tests, fails hidden invariants.
- **Tests**: Thoroughness, adversarial thinking, knowing when you're NOT done
- **Key judges**: Objective (hidden invariant pass rate), Strategy (skepticism)
- **Target archetypes**: Visible-Test Overfitting, False Confidence Stop, Premature Convergence
- **Difficulty envelope**: High deception, high evaluation strictness, low apparent difficulty

### 4. Constraint Maze
Must solve under token/time/tool limits, partial information, or API quotas. Standard approach violates at least one constraint.
- **Tests**: Creative problem-solving, constraint satisfaction
- **Key judges**: Objective (constraint compliance), Strategy (creative approach)
- **Target archetypes**: Scope Explosion, Constraint Blindness, Strategic Myopia
- **Difficulty envelope**: High time pressure, medium reasoning depth, high tool dependence

### 5. Forensic Cascade
Incident investigation with conflicting evidence, multiple potential root causes, and cascading failures.
- **Tests**: Systematic elimination, evidence evaluation, postmortem quality
- **Key judges**: Strategy (elimination methodology), Objective (correct root cause)
- **Target archetypes**: Context Drift, False Confidence Hallucination, Deception Susceptibility
- **Difficulty envelope**: High ambiguity, high non-local dependency, high reasoning depth

### 6. Toolchain Disaster
Challenge can't be solved by coding alone. Requires sophisticated tool orchestration.
- **Tests**: Tool discipline, process quality
- **Key judges**: Process (tool sequence quality), Objective (task completion)
- **Target archetypes**: Toolchain Misuse, Shallow Decomposition, Recovery Collapse
- **Difficulty envelope**: High tool dependence, medium reasoning depth, high error recovery burden

### 7. Recovery Lab
Challenge includes traps the agent WILL fall into. The test is recognizing the trap, backing out, and taking a different path.
- **Tests**: Recovery quality, intellectual humility, adaptability
- **Key judges**: Process (recovery speed/quality), Strategy (pivot decision)
- **Target archetypes**: Recovery Collapse, Premature Convergence, Strategic Myopia
- **Difficulty envelope**: High error recovery burden, high deception, medium reasoning depth

### 8. Versus Arena
Head-to-head competitive challenges across all Versus modes.
- **Tests**: Competitive intelligence, adaptation speed, resource efficiency, strategy under pressure
- **Key judges**: All four weighted equally
- **Target archetypes**: Strategic Myopia, False Confidence Stop, Toolchain Misuse
- **Difficulty envelope**: Variable — adapts to matchup

### 9. Humanity Gap Studio
Ambiguity, edge-case handling, brittle instructions, hidden stakeholder constraints. Specifically targets the 15 AI failure modes.
- **Tests**: Judgment, knowing when to push back, knowing when to stop
- **Key judges**: Strategy (judgment quality), Integrity (appropriate pushback)
- **Target archetypes**: Ambiguity Avoidance Failure, Constraint Blindness, False Confidence Hallucination
- **Difficulty envelope**: High ambiguity, high evaluation strictness, low tool dependence

### 10. Deceptive Optimization Forge
Easy-looking tasks where greedy solutions fail badly. Visible tests pass with naive approach, hidden tests destroy it.
- **Tests**: Thoroughness, skepticism, testing discipline
- **Key judges**: Objective (hidden test rate), Process (verification discipline)
- **Target archetypes**: Visible-Test Overfitting, Premature Convergence, False Confidence Stop
- **Difficulty envelope**: High deception, high evaluation strictness, low apparent difficulty

## Engine Requirements Checklist

Every canonical engine defines:
- [ ] Challenge goal and world model
- [ ] Required assets (repo, logs, traces, docs)
- [ ] Hidden invariants and mutation hooks
- [ ] Scoring logic (which judges weight most)
- [ ] Known exploit risks
- [ ] Telemetry expectations
- [ ] Difficulty profile envelope (which dimensions are high/low)
- [ ] Target failure archetypes
- [ ] Mutation compatibility (which mutation types apply — Skill 52)
- [ ] Format compatibility (Sprint/Standard/Marathon)

## Engine ≠ Instance

| Concept | Stable? | Public? | Example |
|---------|---------|---------|---------|
| **Engine** | Yes — evolves slowly | Yes — branded | "Blacksite Debug" |
| **Instance** | No — fresh per generation | No — disposable | "Blacksite Debug #2847" |

Engines are the brand. Instances are the ammunition. The Mutation Layer (Skill 52) converts engines into instances.
