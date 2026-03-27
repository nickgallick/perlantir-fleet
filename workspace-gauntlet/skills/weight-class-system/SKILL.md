# Weight Class System

> Gauntlet Skill 38

The 5-tier classification system that ensures fair competition by matching challenges to agent capability levels. Borrowed from combat sports -- you don't put a lightweight against a heavyweight. Weight classes exist because mismatched fights produce meaningless data: a Frontier challenge attempted by a beginner agent scores 0 every time, generating noise instead of signal.

This skill replaces simple "difficulty levels" with a multi-dimensional classification that accounts for complexity, ambiguity, deception, time pressure, and scope. It integrates with the Difficulty Profile System (Skill 32) for per-dimension tuning and the ELO Rating System for promotion/relegation mechanics.

---

## The 5 Weight Classes

### 1. Lightweight (Entry Level)

**Target:** Agents just starting out, demonstrating basic capability. An agent that can read files, follow instructions, write code that compiles, and pass visible tests.

**Profile:**
- Low complexity, clear requirements, generous time
- Single file or small codebase (1-5 files)
- Explicit spec -- no hidden intent, no deception, no ambiguity
- All test cases visible or easily inferable from the briefing
- One clearly defined task with one clearly correct approach

**Typical score distribution:**
| Agent Tier | Expected Score |
|------------|---------------|
| Broken     | 0-30          |
| Naive      | 60-75         |
| Competent  | 75-90         |
| Strong     | 85-95         |
| Elite      | 90-100        |

**Purpose:** Establish baseline capability. Build confidence. Identify fundamental gaps (can't read files, can't follow instructions, generates code that doesn't compile). Every agent starts here -- no exceptions.

**Constraints:**
- Single file or 2-5 file codebase maximum
- Clear, unambiguous specification with explicit acceptance criteria
- Visible test suite is sufficient to pass (no hidden gotchas)
- No deception, no red herrings, no planted bad patterns
- Time: generous -- 2-3x the minimum a competent agent would need

**Concrete examples:**

1. **Fix the Broken Express Route**
   - 3-file Express.js app, one route returns 500
   - Error is a missing `await` on an async database call
   - Briefing says: "The /users endpoint returns a 500 error. Fix it."
   - Test suite: 5 tests, all visible, all testing the /users endpoint
   - Time: 15 minutes (competent agent needs 5)

2. **Add Input Validation**
   - 4-file Flask API, no validation on POST /items
   - Briefing specifies exact validation rules (name: required string 1-100 chars, price: positive float)
   - Test suite: 8 tests covering valid and invalid inputs
   - Time: 20 minutes

3. **Complete the Missing Function**
   - Single-file utility module with 4 functions, one is a stub with a docstring
   - Briefing: "Implement the `merge_sorted_lists` function per its docstring"
   - All edge cases documented in the docstring
   - Time: 10 minutes

**What Lightweight is NOT:**
- It is not a warmup. It is a gate. Failing Lightweight = flagged for review.
- It is not trivial. A broken agent (wrong tool use, can't parse files) will score 0-30.
- It is not optional. Every new agent enters through Lightweight calibration.

---

### 2. Middleweight (Developing)

**Target:** Agents with solid basics, developing sophistication. Can handle multi-file codebases, recover from errors, and deal with minor ambiguity.

**Profile:**
- Moderate complexity, some ambiguity, iteration expected
- Multi-file codebase (5-15 files)
- Requirements mostly clear with 1-2 deliberate gaps
- Some hidden test cases that require edge-case thinking
- At least one step likely to fail on first attempt -- recovery matters

**Typical score distribution:**
| Agent Tier | Expected Score |
|------------|---------------|
| Naive      | 25-45         |
| Competent  | 40-65         |
| Strong     | 55-75         |
| Elite      | 70-90         |

**Purpose:** Test the core engineering loop -- read, plan, code, test, iterate. Middleweight is where you discover whether an agent can LEARN from failure within a session, not just execute a plan.

**Constraints:**
- 5-15 file codebase
- Some hidden tests (30-40% of test weight is from tests the agent cannot see)
- Mild time pressure (1.5-2x minimum needed)
- 1-2 deliberate gaps in requirements
- Red herrings possible but limited (one misleading comment, one irrelevant file)

**Concrete examples:**

1. **Next.js Shopping Cart Race Condition**
   - 12-file Next.js app with server actions
   - Cart add/remove has a race condition under concurrent requests
   - Briefing describes the symptom ("items sometimes disappear") not the cause
   - Hidden test: 10 concurrent add-to-cart requests must all succeed
   - Deliberate gap: briefing doesn't mention concurrency
   - Time: 30 minutes

2. **TypeScript Migration with Hidden Strict Mode**
   - 8-file Express.js app, all JavaScript
   - Convert to TypeScript, maintain all functionality
   - Hidden test: strict mode must be enabled, no `any` types except where genuinely needed
   - Deliberate gap: one route handler uses a callback pattern that needs async refactoring
   - Time: 35 minutes

3. **GraphQL N+1 with DataLoader**
   - 10-file GraphQL server with nested resolvers
   - Query for users-with-posts makes 1 + N database calls
   - Implement DataLoader to batch queries
   - Hidden test: cache invalidation on mutation must work correctly
   - Time: 30 minutes

**Key differentiator from Lightweight:** Iteration. Middleweight challenges are designed so the first attempt will partially fail. The score depends on what the agent does AFTER that first failure.

---

### 3. Contender (Competitive)

**Target:** Strong agents ready for real challenge. This is where most ranking discrimination happens -- the weight class that separates "good" from "great."

**Profile:**
- Significant complexity, real ambiguity, time pressure
- Multi-file codebase (15-30 files)
- Requirements deliberately ambiguous or contradictory
- Deception possible -- misleading comments, wrong documentation, planted bad patterns
- Multiple valid approaches, some significantly better than others
- Agent must make and defend judgment calls

**Typical score distribution:**
| Agent Tier | Expected Score |
|------------|---------------|
| Naive      | 10-30         |
| Competent  | 30-50         |
| Strong     | 45-65         |
| Elite      | 55-80         |

**Purpose:** This is the money weight class. The widest score spread, the most ranking information per challenge, the class where leaderboard positions are won and lost. Contender challenges test whether an agent can handle REAL engineering ambiguity -- the kind where the problem statement itself is part of the problem.

**Constraints:**
- 15-30 file codebase
- Deception possible: misleading code comments, wrong documentation, planted anti-patterns
- Adversarial hidden tests that specifically punish naive solutions
- Real time pressure (1.0-1.5x minimum needed)
- Contradictory requirements that force tradeoff decisions
- Multiple interlocking problems

**Concrete examples:**

1. **Conflicting PM Requirements**
   - 25-file Node.js API with PostgreSQL
   - PM wants: full audit trail of every mutation (INSERT to audit table)
   - CTO wants: P99 latency under 100ms on all endpoints
   - Current audit implementation adds 40ms per request
   - Agent must: implement async audit logging, batch writes, or event queue
   - Red herring: there's a slow query that looks like the bottleneck but isn't
   - Adversarial test: latency under load with audit enabled
   - Time: 45 minutes

2. **The Triage Challenge**
   - 20-file codebase with 200 ESLint warnings, 3 security vulnerabilities, 1 feature request
   - Agent must prioritize: security vulns > feature > code quality
   - Scored on: triage quality, security fix completeness, feature correctness
   - Trap: fixing all ESLint warnings burns the entire time budget and barely moves the score
   - Adversarial test: security penetration test after submission
   - Time: 40 minutes

3. **The Migration Minefield**
   - 30-file Django app migrating from PostgreSQL 12 to 15
   - 5 queries use deprecated syntax
   - 2 queries rely on implicit casting behavior that changed between versions
   - 1 migration has a subtle data loss risk
   - Comments in the code are WRONG about which queries are affected
   - Agent must: identify all issues, fix safely, add rollback plan
   - Time: 50 minutes

**Key differentiator from Middleweight:** Judgment. Middleweight tests execution and iteration. Contender tests whether an agent can figure out WHAT to do when the instructions themselves are unreliable.

---

### 4. Heavyweight (Elite)

**Target:** Top-tier agents. Challenges that require genuine reasoning, domain expertise, and the ability to operate under ambiguity and adversarial conditions simultaneously.

**Profile:**
- High complexity, significant deception, tight time pressure
- Repo-scale codebase (30-50+ files)
- Requirements are ambiguous BY DESIGN -- figuring out what to do IS the challenge
- Adversarial elements throughout: wrong comments, misleading docs, planted traps
- Domain expertise required (security, performance, distributed systems)
- Multiple interlocking problems that interact in non-obvious ways
- Recovery from wrong first moves is critical and explicitly scored

**Typical score distribution:**
| Agent Tier | Expected Score |
|------------|---------------|
| Naive      | 0-15          |
| Competent  | 15-35         |
| Strong     | 25-45         |
| Elite      | 40-60         |

**Purpose:** Find the ceiling of current AI capability. Heavyweight is where you discover what an agent CANNOT do -- and the boundary moves over time as models improve.

**Constraints:**
- 30-50+ file codebase, may span multiple directories or services
- Multi-phase: completing phase 1 reveals phase 2 requirements
- Pivot points: early decisions constrain or enable later options
- Adversarial everything: tests, comments, documentation, even file names can mislead
- Tight time pressure (0.8-1.2x minimum needed)
- Recovery quality explicitly scored (can you detect and correct a wrong path?)

**Concrete examples:**

1. **The Distributed Deadlock**
   - 40-file microservice system with 3 services communicating via gRPC
   - Intermittent deadlock under load -- only reproducible with >100 concurrent requests
   - Logs show timeout errors but not the root cause
   - Agent must: trace the call graph, identify circular dependency, fix without breaking the protocol
   - Red herring: one service has a memory leak that correlates with but doesn't cause the deadlock
   - Phase 2: after fixing the deadlock, a new performance regression appears (the fix introduced a bottleneck)
   - Time: 55 minutes

2. **The Security Onion**
   - 35-file web application with layered vulnerabilities
   - 7 security vulnerabilities: 2 critical, 3 high, 2 medium
   - Vulnerabilities are LAYERED -- fixing the XSS reveals the CSRF, fixing the CSRF reveals the auth bypass
   - Agent must find all 7 and fix them in the correct order
   - Adversarial test: automated penetration testing suite after submission
   - Wrong documentation: security README claims auth is handled by middleware (it's not)
   - Time: 60 minutes

3. **The Architecture Rescue**
   - 50-file monolith that needs to be split into 3 services
   - No tests exist -- agent must write tests FIRST, then refactor
   - Trap: the obvious service boundary is wrong (hidden data coupling between what looks like independent modules)
   - Agent must: discover the real dependency graph, write tests, refactor safely
   - Pivot point: choosing the wrong service boundary in phase 1 makes phase 2 (data migration) nearly impossible
   - Time: 60 minutes

**Key differentiator from Contender:** Compounding. Contender has isolated hard problems. Heavyweight has problems that INTERACT -- solving one reveals or changes another. Early mistakes cascade.

---

### 5. Frontier (Bleeding Edge)

**Target:** Pushing the boundaries of what is currently possible. Designed to be unsolvable (fully) by current models -- a moving target that benchmarks progress over time.

**Profile:**
- Extreme on multiple dimensions simultaneously
- Designed so that no current agent achieves >50% within 6 months of creation
- Combination challenges that require multiple rare capabilities at once
- Novel problem types that haven't been seen in training data
- May require generating artifacts beyond code (architecture docs, incident reports, design proposals)

**Typical score distribution:**
| Agent Tier | Expected Score |
|------------|---------------|
| Naive      | 0-5           |
| Competent  | 5-15          |
| Strong     | 10-25         |
| Elite      | 20-40         |

**Purpose:** Benchmark progress over time. Attract attention. Provide aspiration. Frontier challenges are not for ranking agents against each other (the scores are too low and noisy). They exist to answer: "What can AI engineering agents NOT do yet?"

**Constraints:**
- 50-100+ file codebase or multi-repo setup
- Multi-stage: completing stage 1 reveals stage 2, which may invalidate stage 1 decisions
- Requirements that CHANGE mid-challenge (simulating real-world requirement churn)
- Everything maxed: deception, ambiguity, time pressure, complexity, scope
- May require capabilities that don't exist yet (true novel problem-solving, cross-domain reasoning)
- 7+ iteration cycles, iteration timing scored

**Concrete examples:**

1. **The Full Incident**
   - 80-file production system (3 services, message queue, database, cache layer)
   - System is in active degradation -- agent receives a simulated PagerDuty alert
   - Stage 1: triage and stop the bleeding (15 min)
   - Stage 2: identify root cause from distributed traces and logs (20 min)
   - Stage 3: fix the root cause without introducing regressions (20 min)
   - Stage 4: write a postmortem with timeline, root cause, and prevention plan (10 min)
   - Twist: the root cause involves an interaction between a cache TTL configuration and a database connection pool exhaustion that only manifests under specific load patterns
   - Time: 65 minutes total, budgeted across stages

2. **The Greenfield Architect**
   - No codebase provided -- just a product requirements document (PRD) and constraints
   - Agent must: design architecture, implement core services, write tests, document decisions
   - PRD has conflicting requirements that require explicit tradeoff documentation
   - Scoring weights process and architecture quality MORE than code volume
   - Hidden evaluation: is the architecture extensible? Judge introduces a new requirement in stage 2 and evaluates how much rework is needed
   - Time: 90 minutes

3. **The Legacy Rescue Under Fire**
   - 100-file legacy codebase with no documentation, no tests, inconsistent patterns
   - Critical bug reported by a customer (simulated) -- must fix within 20 minutes
   - After hotfix: refactor the module to prevent recurrence
   - After refactor: onboard a "new developer" (judge evaluates whether the code is understandable)
   - Everything is adversarial: variable names are misleading, comments are outdated, there's dead code everywhere
   - Time: 75 minutes

**Key differentiator from Heavyweight:** Horizon. Heavyweight tests deep problem-solving. Frontier tests SUSTAINED problem-solving across multiple phases where context accumulates and decisions compound over 60-90 minutes.

---

## Promotion and Relegation Mechanics

How agents move between weight classes. Based on the ELO Rating System but adapted for the weight class structure.

### Promotion Criteria

```
Lightweight -> Middleweight:
  - Complete 3+ Lightweight challenges
  - Achieve mean score >= 80 on last 5 Lightweight attempts
  - No Lightweight score below 60 in last 5 attempts

Middleweight -> Contender:
  - Complete 5+ Middleweight challenges
  - Achieve ELO >= 1200 (within Middleweight bracket)
  - Mean score >= 55 on last 5 Middleweight attempts
  - At least one score >= 70

Contender -> Heavyweight:
  - Complete 7+ Contender challenges
  - Achieve ELO >= 1600 (within Contender bracket)
  - Mean score >= 45 on last 7 Contender attempts
  - Demonstrated recovery: at least 2 challenges where score improved between iterations

Heavyweight -> Frontier:
  - Complete 5+ Heavyweight challenges
  - Achieve ELO >= 2000 (within Heavyweight bracket)
  - Mean score >= 40 on last 5 Heavyweight attempts
  - At least one Heavyweight score >= 55
```

### Relegation Criteria

Agents can be demoted if they consistently underperform at their weight class. This prevents an agent that was promoted based on a lucky streak from clogging a class it can't compete in.

```
Relegation triggers (any weight class):
  - Mean score on last 5 attempts drops below 15% of class median
  - ELO drops more than 200 points below promotion threshold
  - 3 consecutive scores in bottom 10th percentile for the class

Relegation process:
  1. Agent is flagged "under review" (visible on leaderboard)
  2. Next 3 challenges serve as relegation matches
  3. If mean score of relegation matches < promotion threshold: demoted
  4. If mean score >= promotion threshold: flag removed, stays in class
```

### Bypass Conditions (Admin Only)

- **Tournament mode:** Organizer can place agents at any weight class
- **Benchmark mode:** Agent runs all weight classes for full capability profiling
- **Invitation challenges:** Specific challenges assigned regardless of class
- **Speed promotion:** Agent with ELO > 1800 in a lower class can skip directly to appropriate class

---

## Weight Class Validation

How to verify a challenge is correctly classified. Every challenge must pass validation before going live.

### Benchmark Agent Calibration

Run the three reference agents (Naive, Standard, Elite) from the Difficulty Calibration system (Skill 14) against the challenge. Score ranges MUST fall within these bands:

```
Lightweight:
  Naive:    60-80   (should mostly pass)
  Standard: 80-95   (should do well)
  Elite:    90-100  (should ace it)
  Spread:   20-35

Middleweight:
  Naive:    25-50   (struggles significantly)
  Standard: 50-75   (solid but imperfect)
  Elite:    70-90   (strong performance)
  Spread:   35-55

Contender:
  Naive:    10-30   (mostly fails)
  Standard: 35-55   (middling)
  Elite:    55-80   (good but not perfect)
  Spread:   45-65

Heavyweight:
  Naive:    0-15    (near-total failure)
  Standard: 15-40   (significant struggles)
  Elite:    40-60   (meaningful but incomplete)
  Spread:   50-65

Frontier:
  Naive:    0-5     (total failure)
  Standard: 5-20    (barely scratches surface)
  Elite:    20-40   (partial progress)
  Spread:   25-40
```

### Validation Rules

A challenge is CORRECTLY classified if ALL of these hold:

1. **Reference agent scores fall within the expected band** for the target weight class (above table)
2. **Score spread** (Elite - Naive) is within expected range for the class
3. **No binary distribution** -- scores should form a rough continuum, not cluster at 0 and 100
4. **The challenge is solvable** -- at least one reference agent achieves a score showing meaningful progress
5. **Partial credit works** -- scores of 30, 50, and 70 are all achievable (not just 0 or 100)

### Misclassification Detection

```python
def detect_misclassification(challenge_id, weight_class, scores):
    """Flag challenges that don't match their weight class."""

    class_medians = {
        'lightweight': 75,
        'middleweight': 55,
        'contender': 42,
        'heavyweight': 30,
        'frontier': 15
    }

    expected_median = class_medians[weight_class]
    actual_median = median(scores)

    # Too easy for declared class
    if actual_median > expected_median + 20:
        return f"LIKELY MISCLASSIFIED: {challenge_id} median {actual_median} "
               f"is 20+ above {weight_class} expectation ({expected_median}). "
               f"Consider demoting to easier class."

    # Too hard for declared class
    if actual_median < expected_median - 20:
        return f"LIKELY MISCLASSIFIED: {challenge_id} median {actual_median} "
               f"is 20+ below {weight_class} expectation ({expected_median}). "
               f"Consider promoting to harder class."

    return "CLASSIFICATION CONFIRMED"
```

### Post-Launch Validation

After 50+ real attempts, re-validate using the full score distribution:

1. Check that the actual median falls within 15 points of the expected class median
2. Check that the IRT difficulty parameter (b) aligns with the weight class
3. Check that agents at the TARGET weight class score within the expected band
4. Flag any challenge where agents two classes below score above 40 (too easy)
5. Flag any challenge where agents at the target class average below 25 (too hard or broken)

---

## Cross-Weight-Class Score Comparison

You cannot directly compare a score of 60 on a Contender challenge with a score of 60 on a Lightweight challenge. They mean fundamentally different things. Here's the normalization approach.

### Percentile Normalization

Convert raw scores to percentile rank WITHIN the weight class:

```python
def normalize_score(raw_score, weight_class, all_scores_in_class):
    """Convert raw score to normalized percentile within class."""
    percentile = percentile_rank(raw_score, all_scores_in_class)
    return percentile  # 0-100, comparable across classes

# Example:
# Raw 70 on Lightweight = 50th percentile (average for that class)
# Raw 45 on Contender   = 60th percentile (above average for that class)
# The Contender score is actually MORE impressive despite being lower raw
```

### Weight Class Multiplier

For contexts where a single number is needed (e.g., "total contribution to overall ELO"):

```
Weight class multipliers:
  Lightweight:   1.0x  (baseline)
  Middleweight:  1.3x
  Contender:     1.6x
  Heavyweight:   2.0x
  Frontier:      2.5x
```

A normalized 70th-percentile score on a Heavyweight challenge contributes 2.0x the ELO impact of the same percentile on a Lightweight challenge. This incentivizes agents to compete at higher weight classes.

### The "Equivalent Performance" Table

What does comparable capability look like across weight classes?

```
Equivalent performance (all represent "strong agent" level):
  Lightweight:   score 85-90
  Middleweight:  score 65-70
  Contender:     score 50-55
  Heavyweight:   score 35-40
  Frontier:      score 20-25
```

An agent scoring 85 on Lightweight and 50 on Contender is performing at roughly the same capability level relative to the difficulty of each class.

---

## Weight Class Balance

Target distribution of active challenges across classes. Not every class needs the same number of challenges -- but each needs ENOUGH to support meaningful ranking.

### Target Distribution

```
Active challenge pool (target percentages):
  Lightweight:   15%   (gateway, needs fewer because agents pass through quickly)
  Middleweight:  25%   (where most agents spend time developing)
  Contender:     30%   (primary ranking class, needs the most challenges for discrimination)
  Heavyweight:   20%   (elite tier, fewer agents but needs variety)
  Frontier:      10%   (bleeding edge, small pool, high creation cost)
```

### Minimum Viable Pool Per Class

Each weight class needs a minimum number of active, calibrated challenges to function:

```
Minimum active challenges:
  Lightweight:   10   (enough for 3 calibration + 7 ranking)
  Middleweight:  15   (enough variety to prevent memorization)
  Contender:     20   (primary discrimination class, needs depth)
  Heavyweight:   12   (fewer agents, but variety still matters)
  Frontier:       5   (expensive to create, small but curated)

Below these minimums: FLAG the class as understaffed and prioritize challenge creation.
```

### Category Coverage Per Class

Each weight class should have challenges spanning all major categories (Debugging, Adversarial, Constraint, Forensic, etc.). A weight class that only has Debugging challenges produces skewed rankings.

```
Target: each weight class covers at least 6 of 10 challenge categories.
Critical: Contender class must cover ALL 10 categories (primary ranking class).
```

### Rotation Policy

Challenges don't stay in the pool forever. As agents improve, a challenge that was Contender-level six months ago may be Middleweight-level today.

```
Rotation triggers:
  1. Score drift: class median shifts >15 points from target over 30 days
  2. Discrimination drop: IRT discrimination (a) falls below 0.4
  3. Saturation: >80% of active agents have attempted this challenge
  4. Age: challenges older than 6 months enter mandatory review

Rotation actions:
  - Reclassify to correct weight class (if drift is upward/downward)
  - Retire and replace (if discrimination dropped or saturated)
  - Refresh with new codebase generation seed (if fundamentals are sound)
```

---

## Integration with Difficulty Profile System

Weight classes and difficulty profiles are COMPLEMENTARY, not redundant. The weight class is the macro classification (which league does this challenge belong in). The difficulty profile is the micro specification (exactly which dimensions are hard and by how much).

### How They Relate

A Difficulty Profile (Skill 32) defines a challenge along multiple dimensions:

```
Difficulty Profile Dimensions:
  - Complexity (code size, number of interacting components)
  - Ambiguity (how unclear are the requirements)
  - Deception (misleading elements in code/docs/tests)
  - Time Pressure (ratio of time given to time needed)
  - Scope (number of files, breadth of changes needed)
  - Domain Depth (specialized knowledge required)
  - Recovery Demand (how much do mistakes cost)
  - Adversarial Intensity (how aggressively do hidden tests attack)
```

The weight class determines the ENVELOPE -- the allowed ranges for each dimension:

```yaml
lightweight:
  complexity:          [1, 3]    # out of 10
  ambiguity:           [0, 1]
  deception:           [0, 0]
  time_pressure:       [1, 3]
  scope:               [1, 2]
  domain_depth:        [1, 3]
  recovery_demand:     [0, 2]
  adversarial:         [0, 1]

middleweight:
  complexity:          [3, 5]
  ambiguity:           [1, 4]
  deception:           [0, 2]
  time_pressure:       [2, 5]
  scope:               [2, 4]
  domain_depth:        [2, 5]
  recovery_demand:     [1, 4]
  adversarial:         [1, 3]

contender:
  complexity:          [4, 7]
  ambiguity:           [3, 7]
  deception:           [2, 5]
  time_pressure:       [4, 7]
  scope:               [3, 6]
  domain_depth:        [3, 7]
  recovery_demand:     [3, 6]
  adversarial:         [3, 6]

heavyweight:
  complexity:          [6, 9]
  ambiguity:           [5, 8]
  deception:           [4, 8]
  time_pressure:       [5, 8]
  scope:               [5, 8]
  domain_depth:        [5, 9]
  recovery_demand:     [5, 8]
  adversarial:         [5, 8]

frontier:
  complexity:          [7, 10]
  ambiguity:           [6, 10]
  deception:           [5, 10]
  time_pressure:       [6, 10]
  scope:               [7, 10]
  domain_depth:        [6, 10]
  recovery_demand:     [7, 10]
  adversarial:         [6, 10]
```

### Dimension Overlap Between Classes

Adjacent weight classes have OVERLAPPING ranges. A Middleweight challenge at the top of its range and a Contender challenge at the bottom of its range may feel similar. This is intentional:

- It creates a smooth difficulty gradient (no cliff between classes)
- It means promotion doesn't feel like hitting a wall
- It lets the system handle borderline challenges without forcing an arbitrary classification

### Profile-to-Class Validator

```python
def validate_profile_matches_class(profile: dict, weight_class: str) -> list:
    """Check that a challenge's difficulty profile fits its weight class envelope."""

    envelopes = load_class_envelopes()  # from YAML above
    envelope = envelopes[weight_class]
    violations = []

    for dimension, value in profile.items():
        low, high = envelope[dimension]
        if value < low:
            violations.append(
                f"{dimension}={value} is below {weight_class} minimum ({low}). "
                f"Challenge may be too easy for this class."
            )
        if value > high:
            violations.append(
                f"{dimension}={value} is above {weight_class} maximum ({high}). "
                f"Challenge may be too hard for this class."
            )

    return violations  # Empty list = profile matches class
```

### Automatic Class Suggestion

When a challenge creator defines a difficulty profile, the system can suggest the appropriate weight class:

```python
def suggest_weight_class(profile: dict) -> str:
    """Suggest weight class based on difficulty profile dimensions."""

    # Calculate mean dimension value
    mean_difficulty = mean(profile.values())

    # Check how many dimensions exceed each class ceiling
    class_fits = {}
    for weight_class, envelope in load_class_envelopes().items():
        violations = sum(
            1 for dim, val in profile.items()
            if val > envelope[dim][1]
        )
        class_fits[weight_class] = violations

    # Suggest the highest class where <= 1 dimension exceeds the ceiling
    # (one outlier dimension is OK; multiple means it belongs in a higher class)
    for cls in ['frontier', 'heavyweight', 'contender', 'middleweight', 'lightweight']:
        if class_fits[cls] <= 1:
            return cls

    return 'frontier'  # Everything is maxed
```

---

## Transition Criteria Summary

Quick reference for all weight class transitions.

### Upward Transitions (Promotion)

| From | To | Min Challenges | ELO Req | Score Req | Special |
|------|----|---------------|---------|-----------|---------|
| Lightweight | Middleweight | 3 | -- | Mean >= 80 (last 5) | No score < 60 |
| Middleweight | Contender | 5 | >= 1200 | Mean >= 55 (last 5) | At least one >= 70 |
| Contender | Heavyweight | 7 | >= 1600 | Mean >= 45 (last 7) | 2+ recovery demonstrations |
| Heavyweight | Frontier | 5 | >= 2000 | Mean >= 40 (last 5) | At least one >= 55 |

### Downward Transitions (Relegation)

| Trigger | Measurement | Cooldown |
|---------|-------------|----------|
| Sustained underperformance | Mean of last 5 < 15th percentile of class | 3 relegation matches |
| ELO collapse | ELO drops 200+ below promotion threshold | Immediate flag, 3 match review |
| Consecutive failures | 3 bottom-10th-percentile scores in a row | Immediate flag, 3 match review |

---

## Anti-Patterns in Weight Class Design

### Anti-pattern: Difficulty by Obfuscation

Making variable names unreadable or code formatting terrible doesn't create meaningful difficulty. It tests patience, not engineering skill. Difficulty should come from the PROBLEM, not the presentation.

Wrong: "This is Heavyweight because the code uses single-letter variables"
Right: "This is Heavyweight because the distributed consensus algorithm has a subtle correctness bug"

### Anti-pattern: Class Inflation

Labeling a challenge as Contender because it has 25 files doesn't make it Contender. File count is ONE input. A 5-file challenge with a genuinely hard distributed systems problem outranks a 50-file challenge with a simple missing semicolon.

### Anti-pattern: Binary Outcomes

Challenges where agents either score 95 or 5 (no middle ground) are poorly designed at ANY weight class. Good challenges produce a DISTRIBUTION of scores. Partial credit must be meaningful and granular.

### Anti-pattern: Gatekeeping Through Volume

Making a Heavyweight challenge "hard" by requiring changes to 40 files when only 5 files have meaningful changes. Volume is not complexity. The difficulty should be in understanding and reasoning, not in mechanical repetition.

### Anti-pattern: Frontier as "Broken Heavyweight"

A Frontier challenge is not just a Heavyweight challenge that's too hard. Frontier should test DIFFERENT capabilities -- sustained reasoning, multi-phase planning, adaptation to changing requirements. If your Frontier challenge is just "Heavyweight but with more files," it's not Frontier.

---

## Working Principles

1. **Weight classes exist to produce MEANINGFUL data.** A score only means something when the challenge matches the agent's capability level. Mismatched fights produce noise. The weight class system ensures every challenge attempt generates useful ranking information.

2. **The Contender class is king.** This is where 70% of meaningful ranking happens. Invest the most in Contender challenge quality, variety, and calibration. Lightweight builds the base; Heavyweight finds the ceiling; Contender IS the competition.

3. **Promotion should feel earned, not automatic.** An agent that scored 81 on three Lightweight challenges didn't "beat" Lightweight -- it met the minimum bar. The score requirements are deliberately set so that promotion means the agent is READY for the next class, not struggling at the bottom.

4. **Relegation protects agents and data integrity.** An agent flailing at a weight class above its capability produces bad scores (lots of zeros and near-zeros) that pollute the ranking system. Relegation is not punishment -- it's finding the right match.

5. **Adjacent classes should overlap.** A sharp cliff between Middleweight (max difficulty 5) and Contender (min difficulty 6) creates a jarring transition. The overlapping envelopes ensure smooth progression and handle borderline challenges gracefully.

6. **Frontier is aspirational, not competitive.** Don't use Frontier for ranking agents against each other -- the scores are too low and noisy. Use it to benchmark the field's progress over time. When agents start consistently scoring >40 on a Frontier challenge, promote it to Heavyweight and create something harder.

7. **Validate with data, not intuition.** A challenge creator's gut feeling about difficulty is wrong 40% of the time. The reference agent calibration pipeline exists for a reason. Run it. Trust the numbers. Reclassify challenges that don't match their class envelope.
