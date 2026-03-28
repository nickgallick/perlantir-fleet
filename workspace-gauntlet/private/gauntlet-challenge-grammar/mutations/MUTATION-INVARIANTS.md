# Mutation Invariants

## Governing Rule
A mutation transforms the SURFACE of a challenge without destroying the DISCRIMINATION MECHANISM. If a mutation changes what the challenge tests (not just what it looks like), it's not a sibling — it's a new family.

---

## Per-Type Invariants

### 1. Structural Mutation (file layout, module boundaries, import paths)

| Must Stay the Same | May Change | Exploit Risk | Sibling Boundary |
|-------------------|-----------|-------------|-----------------|
| Logical dependency graph between components | File names, directory structure, import paths | Low — structural changes rarely create exploits | Becomes a new family if the dependency graph changes (e.g., circular → linear deps) |
| Number of modules the agent must read to solve | Module naming, file count within modules | | |
| Non-local dependency pattern | Physical location of the dependencies | | |

### 2. Semantic Mutation (requirements, invariants, failure conditions)

| Must Stay the Same | May Change | Exploit Risk | Sibling Boundary |
|-------------------|-----------|-------------|-----------------|
| Discriminator Intent — the 3-part discrimination thesis | Specific bug types, specific invariants, specific failure conditions | **Medium** — changing the invariant can accidentally make the challenge easier/harder | Becomes a new family if the discrimination mechanism changes (e.g., testing race conditions → testing auth bypass is a different skill) |
| Number of discrimination forks (score ceilings must be preserved) | The specific technical content of each fork | | |
| Difficulty profile (within ±1 on all dimensions) | Domain-specific details | | |

### 3. Evidence Mutation (logs, traces, observability artifacts)

| Must Stay the Same | May Change | Exploit Risk | Sibling Boundary |
|-------------------|-----------|-------------|-----------------|
| Signal-to-noise ratio | Specific log entries, timestamps, error messages | Low | Becomes a new family if evidence type changes fundamentally (e.g., logs → metrics → traces tests different forensic skills) |
| Deception layer effectiveness — misdirection must remain plausible | Specific misdirection targets | | |
| Clue discoverability — clues to the real problem must remain findable | Location and format of clues | | |

### 4. Interface Mutation (APIs, tool behavior, artifact formats)

| Must Stay the Same | May Change | Exploit Risk | Sibling Boundary |
|-------------------|-----------|-------------|-----------------|
| Integration complexity level | Specific API endpoints, response shapes, error codes | **Medium** — changing APIs can accidentally make error messages more revealing | Becomes a new family if the integration pattern changes (e.g., REST → GraphQL → event-driven tests fundamentally different skills) |
| Number of integration points agent must understand | Framework-specific implementation details | | |

### 5. Adversarial Mutation (decoys, false leads, deceptive affordances)

| Must Stay the Same | May Change | Exploit Risk | Sibling Boundary |
|-------------------|-----------|-------------|-----------------|
| Deception level (0-3) | Specific red herring content, stakeholder quotes | Low | Becomes a new family if deception mechanism changes (e.g., misleading logs → misleading tests → misleading docs tests different resistance skills) |
| Number of red herrings | Red herring type and location | | |
| Time cost of following misdirection (must remain comparable) | Specific distraction paths | | |

### 6. Recovery Mutation (repair pathways, rollback options, failure states)

| Must Stay the Same | May Change | Exploit Risk | Sibling Boundary |
|-------------------|-----------|-------------|-----------------|
| Number of recovery branches | Specific trap types, specific recovery paths | **Medium** — changing the trap can accidentally make it too obvious or too hidden | Becomes a new family if recovery difficulty fundamentally changes (1 easy trap → 3 interlocking traps is a different challenge class) |
| Recovery difficulty level | Specific failure modes, specific fix patterns | | |
| Trajectory shape expectation (dip-then-recover pattern) | Specific iteration scores | | |

### 7. Dependency Mutation (frameworks, databases, test runners)

| Must Stay the Same | May Change | Exploit Risk | Sibling Boundary |
|-------------------|-----------|-------------|-----------------|
| Core engineering challenge | Framework, database, test runner, language variant | **High** — framework swap can accidentally make the challenge trivially different (e.g., Express bug has no equivalent in Fastify) | Becomes a new family if the core engineering skill tested changes (swapping from SQL to NoSQL tests fundamentally different debugging skills) |
| Difficulty profile (within ±1) | Framework-specific idioms and patterns | | |
| Hidden invariant applicability — invariants must still be relevant | Framework-specific implementation of invariants | | |

---

## Universal Mutation Rules

1. **No mutation can destroy the Discriminator Intent.** If the mutation changes what average agents do wrong or what strong agents do differently, it's not a valid sibling.
2. **Reference solution must still score >85 after mutation.** If not, the mutation broke the challenge.
3. **Anti-repetition: <70% similarity** to any active instance from the same engine.
4. **Each instance must differ on at least 3 mutation types** from its parent.
5. **Maximum mutation depth: 10 generations** before template refresh.

## The Sibling Test

> "Could an agent that memorized the solution to instance A use that knowledge to solve instance B without real reasoning?"

- If yes → mutations are too shallow → increase mutation depth
- If no → valid siblings

## Mutation Exploit Risk Mitigation

For medium and high exploit risk mutations:
- Re-run the Speedrunner persona after mutation — if Speedrunner scores >10 points higher, the mutation accidentally made the challenge easier
- Re-run the Exploit Seeker persona — if new exploit paths opened, add mitigations
- Verify all 5 hidden test families still function correctly after mutation
