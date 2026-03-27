# Evolving Challenges

Challenges that change mid-execution to test adaptability. Static challenges test whether an agent can build. Evolving challenges test whether an agent can ADAPT — the skill that separates a tool from a teammate. These challenges simulate the reality of software engineering: requirements shift, scope creeps, contradictions emerge, and features get cut.

---

## Pattern 1 — The Pivot

Requirements change fundamentally at ~50% completion. The agent must adapt without starting over.

### Structure

```
PHASE 1 (delivered at start):
  Build a REST API for a todo-list application.
  - CRUD endpoints for tasks
  - SQLite database
  - Basic authentication

PIVOT MESSAGE (delivered when Phase 1 tests pass):
  "The product team just decided we're pivoting to a real-time collaborative
  todo app. We need WebSocket support for live updates. Multiple users should
  see changes instantly. Keep everything from Phase 1 working."

PHASE 2 (new requirements):
  - WebSocket connections for real-time sync
  - Conflict resolution when two users edit the same task
  - All Phase 1 REST endpoints still work
  - Both REST and WebSocket clients see the same data
```

### Scoring

| Dimension | Weight | What to measure |
|-----------|--------|-----------------|
| Phase 1 correctness | 20% | All Phase 1 tests pass before pivot |
| Adaptation quality | 30% | How gracefully did the architecture absorb the change? |
| Phase 2 correctness | 30% | WebSocket tests pass, real-time sync works |
| Regression | 20% | Phase 1 tests STILL pass after Phase 2 changes |

### What separates 95 from 20

- **20/100:** Phase 1 is hardcoded and brittle. Pivot requires near-total rewrite. Agent starts over or produces a mess.
- **60/100:** Phase 1 works. Phase 2 works. But the integration is awkward — REST and WebSocket have separate data paths, inconsistencies possible.
- **95/100:** Phase 1 was built with clean abstractions. Adding WebSocket was a matter of adding a new transport layer on top of existing business logic. Zero regression. Clean architecture.

### Pivot timing

The pivot message arrives when the Phase 1 test suite passes. This ensures the agent has committed to an architecture before being asked to change it. Agents that over-engineer Phase 1 "just in case" are NOT rewarded — they waste time on speculation. Agents that build clean, modular code are naturally rewarded because modularity aids adaptation.

---

## Pattern 2 — The Escalation

Scope starts small and grows incrementally. Each stage adds complexity. Tests whether the agent can maintain quality as scope increases.

### Structure

```
STAGE 1: Build a function that validates email addresses.
STAGE 2: Now also validate phone numbers (international formats).
STAGE 3: Now also validate postal addresses (US, UK, Canada).
STAGE 4: Now build a validation pipeline that chains all three,
         with per-field error messages and i18n support.
STAGE 5: Now add a REST endpoint that accepts a JSON payload with
         all three fields, validates them, and returns structured errors.
```

### Scoring per stage

Each stage is scored independently. The final score is a weighted average:
- Stage 1: 10%
- Stage 2: 15%
- Stage 3: 20%
- Stage 4: 25%
- Stage 5: 30%

**Key metric:** quality degradation curve. Does code quality drop as scope increases? A great agent maintains consistent quality. A weak agent produces clean Stage 1 code and spaghetti by Stage 5.

### Anti-pattern: premature abstraction

Agents that build a "universal validation framework" at Stage 1 are NOT rewarded. The correct behavior is to build what's needed NOW and refactor incrementally as patterns emerge. Scoring checks for YAGNI violations at each stage.

---

## Pattern 3 — The Contradiction

New information arrives that contradicts earlier requirements. The agent must notice, surface, and resolve.

### Structure

```
INITIAL REQUIREMENT:
  Build a user profile page. All user data must be stored in a single
  PostgreSQL table for query simplicity.

CONTRADICTION (delivered after initial implementation):
  "New compliance requirement: user PII (name, email, phone) must be stored
  in a separate encrypted database for GDPR compliance. But we still need
  fast query performance for the profile page."
```

### Expected behavior progression

1. **Notice the contradiction:** The new requirement directly conflicts with "single table for query simplicity." Agents that silently implement one or the other without acknowledging the conflict are penalized.

2. **Surface it clearly:** The agent should state: "The new GDPR requirement conflicts with the single-table design. Here's why: [explanation]. Here are the options: [list]."

3. **Propose resolution:** Options might include: (a) separate tables with a view for query convenience, (b) encrypted columns in the same table, (c) separate database with a caching layer. Each has tradeoffs.

4. **Implement the resolution:** After proposing, implement the chosen approach.

### Scoring

- Conflict identification (25%): Did the agent explicitly call out the contradiction?
- Tradeoff analysis (25%): Did the agent articulate the tradeoffs of each option?
- Resolution quality (25%): Is the chosen approach sound?
- Implementation quality (25%): Does it work?

### What separates 95 from 20

- **20/100:** Silently implements the new requirement, breaking the old one. Or silently ignores the new requirement.
- **60/100:** Notices the conflict, picks a resolution, implements it — but doesn't explain the tradeoffs.
- **95/100:** Explicitly states the conflict, analyzes 2-3 options with tradeoffs, recommends one with reasoning, implements it cleanly, and notes what was sacrificed.

---

## Pattern 4 — The Retraction

A requirement is removed mid-challenge. The agent must cleanly remove code, not just add.

### Structure

```
INITIAL REQUIREMENTS:
  Build a blog platform with:
  1. Post creation and editing
  2. Comment system with threading
  3. Real-time notifications for new comments
  4. Full-text search across posts

RETRACTION (delivered after implementation):
  "We're cutting the real-time notifications feature — it's causing scope
  creep on the mobile team. Remove it completely. The rest must still work
  perfectly. No dead code, no unused dependencies, no orphaned database
  columns."
```

### What this tests

Most agents are good at ADDING code. Very few are good at REMOVING it. Removing a feature cleanly requires:
- Understanding all the places the feature touched
- Removing code without breaking dependent features
- Cleaning up database migrations (remove notification tables)
- Removing unused dependencies from package manifests
- Ensuring no dead code remains
- Verifying no regressions in remaining features

### Scoring

- Completeness of removal (30%): Is ALL notification-related code gone? Database tables, routes, middleware, frontend components, WebSocket handlers?
- Zero dead code (20%): No unused imports, no orphaned functions, no commented-out code
- Zero regression (30%): Comments still work. Posts still work. Search still works.
- Clean git history (20%): Removal is a clean operation, not a series of "oops forgot this" fixes

### What separates 95 from 20

- **20/100:** Comments out the notification code. Leaves the database table. Leaves the WebSocket dependency in package.json.
- **60/100:** Removes most notification code but misses some dead imports or an orphaned migration.
- **95/100:** Complete, surgical removal. No traces of the feature remain. All other features unaffected. Dependencies cleaned up.

---

## Delivery Mechanism

Evolving challenges use a **message queue** pattern for mid-challenge updates:

```yaml
challenge:
  id: evolving-pivot-001
  initial_briefing: |
    [Phase 1 requirements]

  triggers:
    - condition: phase1_tests_pass
      message: |
        [Pivot message]
      new_tests: [Phase 2 test suite]

    - condition: time_elapsed > 30min AND phase1_tests_not_pass
      message: |
        "Phase 1 deadline passed. Moving to Phase 2 anyway.
         Phase 1 failures will count against your score."
      new_tests: [Phase 2 test suite]
```

### Trigger types

- **Test-pass triggers:** New phase unlocks when previous phase tests pass
- **Time triggers:** New information arrives after elapsed time
- **Action triggers:** New information arrives after specific agent actions (e.g., first commit)
- **Unconditional triggers:** Arrives at a fixed point regardless of agent state

---

## Generating Pivots That Are Fair

A pivot must be:
1. **Plausible** — something that actually happens in real projects
2. **Impactful** — changes the optimal architecture, not just adds a feature
3. **Survivable** — a well-architected Phase 1 can adapt; it's not a total rewrite
4. **Testable** — Phase 2 requirements have objective acceptance criteria

Bad pivots:
- "Now rewrite it in a different language" — not a pivot, it's a new project
- "Add a button" — not impactful enough to test adaptability
- "The database must now be encrypted at rest" — infra change, not an architecture test

Good pivots:
- REST → real-time (transport layer change)
- Single-user → multi-tenant (data isolation change)
- Monolith → microservice split (architecture change)
- File storage → cloud storage (abstraction layer change)

---

## Working Principles

1. **Changes must be plausible.** Every pivot, escalation, contradiction, or retraction should be something that actually happens in real engineering. If it feels contrived, it IS contrived.

2. **The agent's Phase 1 architecture predicts Phase 2 success.** Good modular design naturally handles pivots. This is the core insight: evolving challenges reward engineering quality, not just feature completion.

3. **Score adaptation, not just final output.** An agent that produces a perfect final product but completely rewrote it from scratch scores LOWER than one that gracefully evolved its architecture. The process matters.

4. **Always preserve regression testing.** Every phase adds tests but NEVER removes old tests. The full test suite grows monotonically. This ensures evolution doesn't come at the cost of stability.

5. **Time the trigger carefully.** Too early = agent hasn't committed to an architecture. Too late = not enough time to adapt. The sweet spot is when Phase 1 tests pass — the agent has committed but still has runway.
