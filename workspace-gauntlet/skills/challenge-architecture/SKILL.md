# Challenge Architecture

> Gauntlet Foundation Skill 2 of 15

Every challenge in Bouts is a precisely engineered assessment instrument. This skill defines the structural blueprint — what components make up a challenge, how they interrelate, and what makes a challenge well-formed.

---

## The 7 Components of a Complete Challenge

Every challenge instance must contain ALL of the following:

### 1. Briefing
The problem statement presented to the agent. Written in narrative form with realistic context. See Skill 12 (Challenge Briefing Writing) for detailed writing guidelines.

**Requirements:**
- Sets the scene and establishes urgency/context
- Specifies deliverables explicitly
- Specifies constraints explicitly
- Does NOT reveal the solution, the bug location, the "right" architecture, or the scoring rubric
- Contains deliberate ambiguity at Tier 2+ (see Skill 1 for tier expectations)

### 2. Codebase
The generated repository the agent works in. See Skill 4 (Codebase Generation) for the generation pipeline.

**Requirements:**
- Realistic, production-like code (not toy examples)
- Appropriate size for tier (5-15 files Tier 1, 15-30 Tier 2, 30-50+ Tier 3-4)
- Contains intentional imperfections (inconsistent naming, TODOs, commented-out code)
- Includes realistic project artifacts: package.json, README, .env.example, CI config
- Pre-configured to run: `npm install && npm test` (or equivalent) must work out of the box

### 3. Static Test Suite
Validates core functionality. Represents 35% of the composite score.

**Requirements:**
- Tests fundamental correctness (does the solution work?)
- Covers: happy path, common edge cases, integration between components
- All tests pass on the reference solution
- Tests are deterministic (no flaky tests — validated by 10 consecutive runs)
- Test names do NOT leak the expected solution approach

**Structure:**
```
tests/
  static/
    unit/           # Individual function/module tests
    integration/    # Cross-module interaction tests
    e2e/            # End-to-end workflow tests (if applicable)
```

### 4. Adversarial Test Suite
Tests robustness beyond basic correctness. Represents 15% of the composite score.

**Requirements:**
- Tests things the briefing DIDN'T mention but production code SHOULD handle
- Categories: input attacks, concurrency attacks, state attacks, resource attacks
- See Skill 5 (Adversarial Test Generation) for detailed methodology
- Some tests generated AFTER submission based on agent's code (dynamic adversarial)
- Weighted by severity: Critical 3x, High 2x, Medium 1x, Low 0.5x

**Structure:**
```
tests/
  adversarial/
    input/          # Malformed input, injection, edge cases
    concurrency/    # Race conditions, double-submit, interleaving
    state/          # Out-of-order operations, replay, stale data
    resource/       # Large payloads, memory pressure, CPU pressure
```

### 5. Scoring Rubric
Defines exactly how each component contributes to the final score.

**Requirements:**
- Maps every test to its score contribution
- Defines passing thresholds per component
- Specifies AI judge dimensions and weight per dimension
- Includes tiebreaker rules (iteration count, improvement trajectory)
- See Skill 6 (Scoring Engine Design) for the composite formula

**Structure:**
```yaml
scoring:
  static_tests:
    weight: 0.35
    tests:
      - name: "user-creation"
        points: 10
        category: "unit"
      - name: "auth-flow-complete"
        points: 15
        category: "integration"
  adversarial_tests:
    weight: 0.15
    severity_multipliers:
      critical: 3.0
      high: 2.0
      medium: 1.0
      low: 0.5
  code_quality:
    weight: 0.20
    dimensions:
      readability: 0.25
      architecture: 0.25
      robustness: 0.25
      idiomaticity: 0.25
  deliverables:
    weight: 0.15
  security:
    weight: 0.10
  stability:
    weight: 0.05
```

### 6. Reference Solution
The gold-standard implementation that validates the challenge is solvable.

**Requirements:**
- Scores >85/100 on the full scoring rubric
- Completes within 60% of the time limit
- Represents a GOOD solution, not necessarily the ONLY solution
- Used during QA to validate test suite correctness
- Never exposed to agents or the public

**Reference solution must:**
- Pass all static tests
- Pass >80% of adversarial tests
- Score well on code quality (clean, idiomatic, well-structured)
- Address all deliverables in the briefing
- Handle the deliberate ambiguities with reasonable decisions

### 7. Difficulty Profile
An 8-dimension rating that characterizes what makes this challenge hard.

---

## The 8 Difficulty Dimensions

Rate each dimension 1-5 for every challenge. This creates a fingerprint that enables matching challenges to agent weaknesses and building balanced challenge pools.

### Dimension 1: Reasoning Depth (1-5)
How many inference steps are required to solve the challenge?

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Direct — answer is in the code | Fix syntax error on line 42 |
| 2 | One hop — read A to understand B | Read error log, find the function |
| 3 | Multi-hop — chain of reasoning | Trace data flow across 3 files |
| 4 | Deep inference — synthesize from multiple signals | Correlate logs + code + config |
| 5 | Novel reasoning — no direct path, must hypothesize | Infer root cause from symptoms only |

### Dimension 2: Tool Dependence (1-5)
How many tools must be correctly orchestrated?

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Single tool (read file) | Read and answer a question |
| 2 | Two tools (read + edit) | Fix a bug in one file |
| 3 | Multiple tools in sequence | Search, read, edit, test |
| 4 | Complex tool orchestration | Grep patterns, edit multiple files, run tests, iterate |
| 5 | Tool strategy is the challenge | Must decide WHICH tools and in WHAT order |

### Dimension 3: Ambiguity (1-5)
How much is left unstated or open to interpretation?

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Fully specified | Exact function signature + behavior defined |
| 2 | Minor gaps | "Handle errors appropriately" |
| 3 | Deliberate gaps | Requirements don't cover 2-3 scenarios |
| 4 | Substantial ambiguity | Multiple valid interpretations |
| 5 | Ambiguity IS the challenge | Must figure out what to build |

### Dimension 4: Deception (1-5)
How many traps and misleading signals exist?

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | None | What you see is what you get |
| 2 | Noise | Irrelevant files/code present |
| 3 | Red herrings | Plausible but wrong leads |
| 4 | Active misdirection | Comments/docs point wrong way |
| 5 | Adversarial deception | The "obvious" solution is a trap |

### Dimension 5: Time Pressure (1-5)
How tight is the time limit relative to the work required?

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Generous | 3x the time a senior engineer needs |
| 2 | Comfortable | 2x the time needed |
| 3 | Moderate | 1.5x the time needed |
| 4 | Tight | About the time a senior engineer needs |
| 5 | Extreme | Less time than ideal, must triage |

### Dimension 6: Error Recovery Burden (1-5)
How hard is it to recover from a wrong first move?

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Trivial — undo and retry | Wrong edit, just revert |
| 2 | Minor setback | Wrong approach, but easy to pivot |
| 3 | Moderate cost | Wrong architecture choice, partial rewrite |
| 4 | Significant cost | Bad early decision affects many files |
| 5 | Catastrophic | Wrong first move makes challenge nearly unsolvable |

### Dimension 7: Non-Local Dependency (1-5)
How much cross-file/cross-module reasoning is required?

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Single file | Bug and fix are in same file |
| 2 | Adjacent files | Bug in A, fix in A+B |
| 3 | Cross-module | Understanding requires 3-5 files |
| 4 | System-wide | Fix requires understanding full architecture |
| 5 | Cross-system | Multiple services/repos/concerns interact |

### Dimension 8: Evaluation Strictness (1-5)
How tight are the correctness criteria?

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Lenient — general direction counts | Design doc scored on reasoning |
| 2 | Moderate — partial credit generous | Tests check behavior, not implementation |
| 3 | Standard — correct behavior required | All tests must pass |
| 4 | Strict — edge cases matter | Adversarial tests, exact output matching |
| 5 | Exacting — perfection required | Security audit, zero tolerance for vulns |

---

## Challenge Dimension Profiles by Tier

Typical dimension profiles (not rigid rules, but calibration guides):

**Tier 0 Profile:** [1, 1, 1, 1, 1, 1, 1, 2] — everything easy
**Tier 1 Profile:** [2, 3, 2, 2, 2, 2, 2, 3] — moderate tool use + evaluation
**Tier 2 Profile:** [3, 3, 3, 3, 3, 3, 3, 3] — everything moderate
**Tier 3 Profile:** [4, 4, 4, 4, 3, 4, 4, 4] — high across the board
**Tier 4 Profile:** [5, 5, 4, 5, 4, 5, 5, 4] — extreme on most dimensions

---

## The 3 Challenge Formats

### Sprint (15-20 minutes)
- Short, vicious, highly discriminative
- Best for: debugging, triage, logic repair, quick implementation
- Characteristics: small codebase (3-10 files), clear deliverable, tight time pressure
- Iteration model: 1-2 iterations
- Scoring emphasis: speed + correctness (static tests weighted higher)
- Agent profile signal: reaction speed, tool efficiency, pattern recognition

### Standard (30-45 minutes)
- Main ranked format for competitive play
- Best for: implementation, multi-file repair, tool orchestration, refactoring
- Characteristics: medium codebase (10-30 files), multiple deliverables, moderate ambiguity
- Iteration model: 2-4 iterations depending on tier
- Scoring emphasis: balanced across all 6 scoring components
- Agent profile signal: overall engineering capability

### Marathon (60+ minutes)
- Long-horizon, multi-stage, recursive
- Best for: repo-scale reasoning, planning + execution, architecture decisions
- Characteristics: large codebase (30-100+ files), evolving requirements, multi-stage
- Iteration model: 5-7 iterations
- Scoring emphasis: process + strategy weighted higher (architecture decisions matter more)
- Agent profile signal: planning depth, sustained reasoning, adaptation

---

## The 3 Flagship Challenge Families

These are recurring challenge archetypes that define the Bouts brand.

### Blacksite Debug
A broken production-like repository with 5-9 interlocking failures. Only some are visible upfront.

**Structure:**
- Initial symptoms: 2-3 visible (failing tests, error logs, crash reports)
- Hidden symptoms: 2-3 that only appear after fixing the visible ones
- Deep symptoms: 1-3 that require understanding system architecture to find
- The interlocking nature means fixing bug A may expose bug B, and fixing B incorrectly breaks the fix for A

**What it tests:** Systematic debugging, dependency analysis, regression awareness

### Fog of War
Agents receive incomplete information: partial logs, outdated docs, misleading artifacts. They must infer the real issue.

**Structure:**
- Incomplete logs: key timestamps missing, some entries truncated
- Outdated docs: README describes architecture that was refactored 6 months ago
- Misleading artifacts: error messages point to the wrong component
- The real issue is discoverable but requires triangulating multiple incomplete signals

**What it tests:** Information synthesis, hypothesis formation, evidence-based reasoning

### False Summit
The obvious solution passes all visible checks but fails hidden invariants.

**Structure:**
- Visible tests: straightforward, the "obvious" solution passes them all
- Hidden invariants: performance requirements, security constraints, edge cases
- The gap between obvious and correct is WHERE the challenge lives
- Agents that stop at "all tests pass" score 40-60. Agents that go deeper score 70-90+.

**What it tests:** Thoroughness, skepticism, understanding beyond test suites

---

## Challenge Lifecycle

```
Draft → QA → Beta → Live → Retired
```

### Draft
- Template selected, variables randomized
- Codebase generated
- Test suites created
- Reference solution written
- Scoring rubric defined

### QA
- Full QA checklist (see Skill 13) validated
- Reference solution confirmed >85 score
- Naive solution confirmed in expected range for tier
- Test suite: 10 consistent runs, no flaky tests
- AI judge panel: 3 runs, scores within 5 points

### Beta
- Released to 3 beta-test AI agents
- Score distribution analyzed: must show meaningful spread
- Timing validated: agents use expected portion of time limit
- Feedback incorporated: brief adjustments, test refinements
- If spread <30 points → challenge needs adjustment

### Live
- Active in the ranked challenge pool
- Available for the assigned tier
- Metrics tracked: attempt rate, pass rate, score distribution, common failure points
- Instance rotated weekly (same template, new variables)

### Retired
- Removed from active pool
- Reasons: too easy (>80% pass rate), too hard (<5% attempt rate), outdated stack, better challenge exists
- May return in modified form
- Historical scores preserved

---

## Challenge Instance vs Template

**Template:** The reusable blueprint (e.g., "The Haunted Service" — intermittent production bug)
**Instance:** A specific generated challenge from that template (specific framework, specific bug, specific domain)

One template generates many instances. This is critical for:
- Preventing memorization (agents can't learn "the answer")
- Enabling fair competition (different agents get different instances of same template)
- Supporting weekly rotation (same template, fresh instance)

Variables that change between instances:
- Framework stack (Express → Fastify → Hono)
- Domain (e-commerce → social media → project management)
- Specific bug/feature (race condition → memory leak → auth bypass)
- File names, variable names, business logic terminology
- Red herring placement and content
- Test case specifics (while testing the same patterns)

---

## Anti-Patterns in Challenge Architecture

**Missing reference solution:** If you can't solve it, it might not be solvable. Every challenge MUST have a validated reference.

**Scoring rubric mismatch:** If the rubric rewards X but the briefing emphasizes Y, agents get confused and scores become noisy.

**Overfitted adversarial tests:** If adversarial tests only pass for the EXACT reference solution approach, they penalize valid alternatives.

**Format mismatch:** A Marathon-length problem shoved into Sprint format produces a time-pressure challenge, not the intended challenge type. Match format to what you're testing.

**Dimension flatness:** A challenge that's [3,3,3,3,3,3,3,3] across all dimensions tests nothing specifically. The best challenges have 2-3 HIGH dimensions and the rest moderate, creating a clear capability signal.
