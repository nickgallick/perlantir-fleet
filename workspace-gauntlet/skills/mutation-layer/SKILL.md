# Mutation Layer — Skill 52

## Purpose
Formal mutation system that generates fresh challenge instances from canonical engines while preserving family identity, preventing memorization, and maintaining evaluation integrity.

## Seven Mutation Types

### 1. Structural Mutation
File graph changes, dependency order, subsystem recomposition. Same logical structure, different physical organization.
- Example: Move auth logic from `middleware/auth.js` to `lib/auth/index.ts`, rename modules, restructure imports
- Preserves: Problem logic
- Changes: File layout, import paths, module boundaries

### 2. Semantic Mutation
Altered requirements, changed hidden invariants, altered failure conditions. Same problem category, different specific details.
- Example: Bug changes from timezone offset error to locale formatting error
- Preserves: Problem category and difficulty
- Changes: Specific requirements, expected outputs, hidden test targets

### 3. Evidence Mutation
Log variants, misleading traces, shifted observability. Same symptom pattern, different specific entries.
- Example: Error log timestamps shifted, stack traces point to different files, metrics show different patterns
- Preserves: Diagnostic difficulty
- Changes: Specific log entries, trace content, misleading signals

### 4. Interface Mutation
Changed APIs, changed tool behavior, changed artifact formats. Same integration pattern, different specifics.
- Example: REST endpoint paths change, response shapes change, error codes differ
- Preserves: Integration complexity
- Changes: API contracts, data shapes, error formats

### 5. Adversarial Mutation
New decoys, stronger false leads, altered deceptive affordances. Prevents learning "the red herring is always X."
- Example: Previous instance's red herring was a misleading log entry; new instance's red herring is a misleading test failure
- Preserves: Deception difficulty level
- Changes: Specific deceptive elements, trap locations

### 6. Recovery Mutation
Changed repair pathways, altered rollback options, variable partial failure states. Prevents memorizing fix patterns.
- Example: Previous instance required reverting a migration; new instance requires patching a config
- Preserves: Recovery difficulty
- Changes: Available recovery paths, partial state configurations

### 7. Dependency Mutation
Swap frameworks, databases, test runners. Tests real skill vs framework-specific memorization.
- Example: Express → Fastify, PostgreSQL → MySQL, Jest → Vitest
- Preserves: Core engineering challenge
- Changes: Framework-specific patterns, API surfaces, conventions

## Mutation Rules

| Rule | Requirement |
|------|-------------|
| Minimum diversity | Each instance must differ on **at least 3 mutation types** from previous |
| Core preservation | No mutation can change the fundamental problem being tested |
| Reference validity | Reference solution must still score > 85 after mutation |
| Anti-repetition | New instance must be **< 70% similar** to any active instance from same engine |
| Validity preservation | Mutation must never destroy challenge integrity — freshness without integrity is useless |

## Mutation Pipeline

```
Engine Template
  ↓
Select 3-5 mutation types (based on freshness needs)
  ↓
Apply mutations (order: Structural → Semantic → Evidence → Interface → Adversarial → Recovery → Dependency)
  ↓
Validate: reference solution still scores > 85
  ↓
Validate: anti-repetition fingerprint < 70% similarity
  ↓
Contamination screening (Skill 49)
  ↓
Calibration run against benchmark agents
  ↓
Publish instance
```

## Similarity Fingerprint

Fingerprint components:
- File structure hash (weighted 20%)
- Requirements keyword vector (weighted 25%)
- Hidden invariant set hash (weighted 25%)
- Adversarial element set hash (weighted 15%)
- Framework/dependency fingerprint (weighted 15%)

Two instances from the same engine with fingerprint similarity > 70% → reject the newer one.

## Mutation Depth Tracking

Every instance records:
- Parent engine
- Mutation types applied
- Mutation depth (how many generations from original template)
- Specific mutation parameters
- Similarity score to nearest active sibling

Maximum mutation depth before full engine template refresh: **10 generations**.

## Integration Points

- **Canonical Engines** (Skill 51): Engines define mutation hooks
- **Contamination Doctrine** (Skill 49): Every mutated instance must pass contamination screening
- **CDI** (Skill 46): Mutation must preserve or improve CDI
- **Defensibility Reporting** (Skill 57): Mutation chain is part of the defensibility record
