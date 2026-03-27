# Difficulty Profile System

> Gauntlet Elite Skill 32

Replace the single difficulty number with an 8-dimension profile. Every challenge gets a vector of eight ratings (each 1-10) instead of one scalar. This transforms difficulty from a blunt label into a precise fingerprint that predicts *how* a challenge is hard, not just *how much*.

---

## Why Profiles Beat Scalars

A single "difficulty: 7" tells you nothing useful. Consider two challenges both rated 7:

- **Challenge A:** Crystal-clear spec, zero deception, but requires 12-step causal reasoning across 8 tightly coupled files with strict evaluation.
- **Challenge B:** Vague requirements, misleading error messages, but shallow logic in a single file with forgiving pass criteria.

An agent that excels at deep reasoning but struggles with ambiguity will crush A and fail B. The scalar hides this. The profile reveals it.

Profiles enable: targeted training, fair matchmaking, precise calibration, meaningful analytics, and challenge design that deliberately exercises specific weaknesses.

---

## The 8 Dimensions

### Dimension 1: Reasoning Depth

**Definition:** The number and complexity of inference steps required to get from the observable symptom to the correct solution.

**What it measures:** Raw cognitive chain length. How many logical leaps must the agent make, and how non-obvious are those leaps?

**Scale:**

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Single function, clear input-to-output. Solution is obvious from reading the code. | Fix a typo in a return statement. |
| 2 | Two-step reasoning. Read error, trace to cause. | A function returns `null` because a variable is shadowed. |
| 3 | Requires understanding one abstraction layer. | API returns 500 because middleware strips a required header. |
| 4 | Multi-step with one non-obvious connection. | Test fails because a mock doesn't match the updated interface contract. |
| 5 | Multi-step, must understand component relationships and data flow. | Race condition between two services sharing a cache key. |
| 6 | Requires reasoning about system state over time. | Memory leak caused by event listener registered in a loop that survives component unmount. |
| 7 | Root cause 3-4 steps removed from symptom; requires hypothesis generation. | Flaky test caused by timezone-dependent date comparison in a utility used by a factory used by the test fixture. |
| 8 | Requires mental simulation of concurrent/distributed behavior. | Deadlock between three microservices caused by circular dependency in their retry logic. |
| 9 | Root cause 5+ steps removed; multiple valid-seeming but wrong hypotheses exist. | Data corruption traced through: UI rounding -> API serialization -> DB trigger -> replication lag -> cache invalidation race. |
| 10 | Requires novel insight or creative reframing; no standard pattern applies. | Performance cliff caused by JIT deoptimization triggered by a specific input pattern that changes object shape at megamorphic call site. |

**Assessment method:** Count the minimum number of inference steps in the *intended* solution path. Each step must involve a non-trivial logical connection (not just "read next line"). Rate higher if plausible-but-wrong paths exist.

**Impact on challenge design:** High reasoning depth demands longer time limits, more generous iteration budgets, and richer diagnostic information in the codebase (logs, tests, comments) so the agent has material to reason about.

---

### Dimension 2: Tool Dependence

**Definition:** How much the agent's success depends on effective use of external tools (file reading, search, test execution, shell commands) versus pure reasoning.

**What it measures:** Operational fluency. Can the agent solve it in its "head," or must it orchestrate a sequence of tool interactions?

**Scale:**

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Can solve entirely from the briefing and inline code. Minimal tools needed. | Given a function and its expected output, write the fix. |
| 2 | Needs to read 1-2 files to gather context. | Fix a bug; need to check the type definition in another file. |
| 3 | Requires targeted search across a small codebase. | Find where a configuration value is set; it could be in 3-4 places. |
| 4 | Must run tests to verify understanding before attempting fix. | Behavior depends on runtime state not visible from static reading. |
| 5 | Requires iterative test-run-debug cycles. Multiple file reads and edits. | Fix a failing integration test by modifying code, running tests, reading output, adjusting. |
| 6 | Must use search strategically across a large codebase (50+ files). | Track down all callers of a deprecated API to understand migration impact. |
| 7 | Requires environment setup, dependency management, or build system interaction. | Fix requires modifying build config, running build, interpreting build errors, iterating. |
| 8 | Multi-tool orchestration: search -> read -> edit -> test -> debug -> edit cycles spanning multiple components. | Refactor a shared utility; must find all consumers, update each, run each consumer's tests. |
| 9 | Must use tools to generate information that doesn't exist yet (e.g., write a test to probe behavior). | No existing tests; agent must write diagnostic tests to understand current behavior before fixing. |
| 10 | Sophisticated orchestration across multiple environments, tools, and feedback loops. Requires inventing tool-use strategies. | Debug a deployment pipeline failure requiring: reading CI logs, modifying Dockerfile, testing locally, checking network config, verifying secrets. |

**Assessment method:** Count the minimum number of distinct tool invocations in the optimal solution path. Rate based on both quantity and sophistication of tool use required.

**Impact on challenge design:** High tool dependence requires a well-configured sandbox with all necessary tools available, clear feedback from tool outputs, and time budgets that account for tool latency.

---

### Dimension 3: Ambiguity

**Definition:** How clearly the requirements are specified. How many decisions must the agent make that aren't covered by the briefing?

**What it measures:** Judgment under uncertainty. Can the agent handle incomplete information and make reasonable design decisions?

**Scale:**

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Exact spec with input/output examples. Zero interpretation needed. | "Function should return [3, 1, 2] for input [1, 2, 3]." |
| 2 | Clear spec but agent must infer one minor detail. | "Sort ascending" — agent must decide stability, null handling. |
| 3 | Spec covers happy path; agent decides edge cases. | "Parse the CSV" — what about malformed rows? Quoted commas? |
| 4 | Goal is clear, approach is open. Multiple valid solutions. | "Make the API faster" — caching? query optimization? pagination? |
| 5 | Clear goal, some decisions left to agent. Reasonable people could disagree on approach. | "Refactor this module for testability." |
| 6 | Requirements have gaps that matter. Agent must ask-or-assume. | "Add authentication" — OAuth? JWT? Sessions? What scopes? |
| 7 | Multiple stakeholders implied with conflicting preferences. | Product wants features, ops wants stability, security wants lockdown. Briefing hints at all three. |
| 8 | Core requirement is stated but success criteria are subjective. | "Improve the developer experience of this library." |
| 9 | Problem statement is vague; agent must define the problem before solving it. | "Users are unhappy with the dashboard. Fix it." |
| 10 | Contradictory stakeholders, missing info, judgment calls required. Agent must resolve contradictions and justify choices. | Briefing says "make it fast AND comprehensive AND simple" with no prioritization. Requirements doc contradicts the test expectations. |

**Assessment method:** Count the number of non-trivial decisions the agent must make that aren't specified. Rate higher if wrong assumptions lead to wasted work or if the "right" assumptions require domain knowledge.

**Impact on challenge design:** High ambiguity challenges should be evaluated with flexible rubrics that accept multiple valid approaches. Judges must be calibrated to assess decision quality, not just output match.

---

### Dimension 4: Deception

**Definition:** How much of the provided information is misleading, outdated, or actively designed to send the agent down the wrong path.

**What it measures:** Epistemic resilience. Can the agent verify claims, detect red herrings, and trust its own analysis over authority?

**Scale:**

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Everything in the briefing is accurate and complete. | Straightforward bug report with correct stack trace. |
| 2 | Briefing is accurate but incomplete; missing info isn't misleading. | Bug report mentions the symptom but not the component. |
| 3 | One piece of irrelevant-but-distracting information. | Briefing mentions a recent deploy that's actually unrelated to the bug. |
| 4 | Comments in code are outdated and describe old behavior. | `// This function validates input` above a function that hasn't validated since v2. |
| 5 | Some red herrings, some outdated info. Agent must distinguish signal from noise. | Error log contains 3 warnings; only 1 is relevant. Briefing blames the wrong component. |
| 6 | Briefing contains a plausible but wrong root cause. | "The database is slow" when the real issue is N+1 queries in the ORM layer. |
| 7 | Multiple layers of misdirection. Obvious fix introduces a new bug. | The "fix" suggested in comments masks the real issue and causes a subtle data corruption. |
| 8 | Adversarial code: variable names suggest wrong purpose, tests test wrong behavior. | Function named `validateEmail` actually does sanitization. Tests assert the sanitized output, not validation. |
| 9 | Briefing actively misleads on multiple fronts. Agent must independently verify every claim. | Wrong file blamed, wrong error described, wrong fix suggested. Only the symptom description is accurate. |
| 10 | Multiple deception layers. The problem the agent is told to solve isn't the real problem. Solving the stated problem makes things worse. | Briefing asks to "fix the slow query" but the real issue is that fixing it triggers a cascade that takes down the cache layer. |

**Assessment method:** Count the number of false or misleading claims/signals. Rate based on how plausible the deception is and how costly it is to follow. A single highly-plausible misdirection can rate higher than many obvious red herrings.

**Impact on challenge design:** High deception challenges require careful construction. The misdirection must be plausible enough that a competent agent might fall for it, but not so arbitrary that no agent could succeed. Always ensure a verification path exists.

---

### Dimension 5: Time Pressure

**Definition:** How tight the time constraint is relative to the complexity of the work required.

**What it measures:** Efficiency and prioritization under constraint. Can the agent avoid rabbit holes and make progress without perfect information?

**Scale:**

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Generous time. Agent can explore freely, try multiple approaches, read everything. | 30 minutes for a 5-minute fix. |
| 2 | Comfortable. Enough time for one false start and recovery. | 20 minutes for a task an expert does in 8. |
| 3 | Reasonable. Efficient agent finishes with some margin. | 15 minutes for a 10-minute task. |
| 4 | Moderate. Must stay focused but not rushed. | 20 minutes for a 15-minute task. |
| 5 | Efficient but room for one iteration cycle. Forces focus but allows course correction. | 25 minutes for a 20-minute task. |
| 6 | Tight. No time for exploration; must have a plan before starting. | 20 minutes for a 18-minute task. |
| 7 | Very tight. Must prioritize ruthlessly; cannot address all aspects fully. | 30 minutes for a 35-minute task. Agent must decide what to skip. |
| 8 | Severe. Optimal path barely fits. Any wrong turn means timeout. | 15 minutes for a task requiring 14 minutes of optimal execution. |
| 9 | Extreme. Only the fastest possible approach succeeds. No room for iteration. | Time limit forces single-pass solution with no test-run cycles. |
| 10 | Barely enough time for a perfect agent. Forces ruthless prioritization. Zero-mistake tolerance. | Multiple subtasks with a combined time that exceeds the limit; agent must triage. |

**Assessment method:** Measure optimal completion time (by expert or reference agent), divide by allotted time. Ratio 0.3 or below = rating 1. Ratio 0.9+ = rating 9-10. Adjust for task variance (some tasks have high variance in completion time).

**Formula:**
```
time_pressure_ratio = optimal_completion_time / allotted_time
rating = clamp(1, ceil(time_pressure_ratio * 10), 10)
```

**Impact on challenge design:** High time pressure challenges must have a clear critical path. If the agent can't even theoretically finish in time, the challenge is broken. Target: the *optimal* path should complete with 5-15% margin at the rated pressure level.

---

### Dimension 6: Error Recovery Burden

**Definition:** How hard it is to recover from an incorrect first attempt. How much does a wrong initial approach cost?

**What it measures:** Resilience and adaptability. Does the challenge punish exploration, or does it allow iterative convergence?

**Scale:**

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | One-shot usually sufficient. Even if wrong, easy to undo and retry. | Fix a syntax error. If wrong fix, just try again. |
| 2 | Minor recovery cost. Wrong approach wastes a few minutes. | Edited wrong file; just edit the right one. |
| 3 | Moderate cost. Wrong fix might require undoing changes and starting over on that component. | Refactored a function incorrectly; must revert and redo. |
| 4 | Wrong approach pollutes the environment slightly. | Ran a migration that's hard to undo cleanly. |
| 5 | First attempt often partially fails. Recovery is straightforward but time-consuming. | Wrong architectural decision; must restructure 2-3 files. |
| 6 | Wrong first move creates subtle side effects. | Incorrect cache invalidation logic causes intermittent test failures that are hard to diagnose. |
| 7 | Recovery requires significant rethink. Sunk cost is high. | Chose wrong algorithm; 15 minutes of work must be discarded. |
| 8 | Wrong approach corrupts state in ways that are hard to detect. | Incorrect database migration leaves data in ambiguous state. |
| 9 | First attempt almost always fails; recovery requires fundamental rethink of approach. | The obvious solution has a subtle flaw that only appears after full implementation. Must redesign from scratch. |
| 10 | Wrong first move creates cascading failures that are worse than the original problem. Full rethink required. | "Fixing" the reported bug introduces three new bugs in dependent systems. Agent must understand the full dependency web before touching anything. |

**Assessment method:** Run 10+ agents on the challenge. Measure: what percentage make a wrong first move? Of those, what percentage recover successfully? Rate based on recovery failure rate and cost.

**Impact on challenge design:** High recovery burden challenges should have clear diagnostic feedback so agents *can* detect they're on the wrong path. A challenge where wrong moves are invisible until the end is frustrating, not challenging.

---

### Dimension 7: Non-Local Dependency

**Definition:** How interconnected are the components involved. How far do changes propagate?

**What it measures:** Systems thinking. Can the agent reason about indirect effects and understand how components interact?

**Scale:**

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Isolated function. No side effects. Change is fully local. | Fix a pure utility function. |
| 2 | Change affects one other function or test. | Fix a function; its unit test needs updating too. |
| 3 | Change affects one other file. | Modify a type definition; one consumer needs updating. |
| 4 | Changes affect 2-3 files with clear dependency chain. | Update an API endpoint; route definition and one client call change too. |
| 5 | Changes affect 2-3 files with non-obvious connections. | Change a validation rule; affects both frontend form and backend processing in different ways. |
| 6 | Changes affect 4-6 files. Some dependencies are implicit (convention-based, not import-based). | Rename a database column; affects ORM model, migration, API serializer, frontend type, and test fixture. |
| 7 | Change propagates through an abstraction boundary. | Modify a shared library function used by 3 different services. Each service uses it differently. |
| 8 | Changes create cross-cutting concerns. Multiple subsystems affected. | Security fix requires changes in auth middleware, session management, API gateway config, and client-side token handling. |
| 9 | Butterfly effect — change in one file breaks assumptions in distant, seemingly unrelated code. | Changing a sort order in a data pipeline causes a downstream ML feature extraction to produce different results, which changes model predictions, which triggers a different code path in the UI. |
| 10 | System-wide interconnection. Every component depends on every other. Change anywhere can break anything anywhere. | Modifying the core event bus schema in an event-sourced architecture; every service, projection, and saga must be updated. |

**Assessment method:** Identify all files that must change for a correct solution. Count them. Then identify all files where a *naive* solution would cause breakage. Rate based on total blast radius and how discoverable the dependencies are.

**Impact on challenge design:** High non-local challenges require comprehensive test suites so the agent can detect breakage. The codebase must be large enough to have genuine distance between components. Include dependency paths that aren't visible from imports alone (runtime, convention-based, config-driven).

---

### Dimension 8: Evaluation Strictness

**Definition:** How precisely and rigorously the agent's output is judged. How many quality dimensions are assessed?

**What it measures:** Thoroughness and attention to quality. Does the agent meet just the minimum bar, or deliver production-quality work?

**Scale:**

| Rating | Description | Example |
|--------|-------------|---------|
| 1 | Binary "does it work?" Single test, pass/fail. | Function returns correct output for 3 test cases. |
| 2 | Correctness + basic edge cases. | Function works for normal input AND empty input AND null. |
| 3 | Correctness + handles error cases gracefully. | Works + throws appropriate errors + doesn't crash on bad input. |
| 4 | Correctness + code quality basics (no obvious smells). | Works + readable + no copy-paste duplication. |
| 5 | Works + quality + tests. Agent must write or update tests. | Solution must include unit tests covering key paths. |
| 6 | Works + quality + tests + follows project conventions. | Must match existing code style, naming conventions, file organization. |
| 7 | Works + quality + tests + performance within bounds. | Solution must not regress benchmark by more than 10%. |
| 8 | All of the above + documentation + type safety. | Must update API docs, add JSDoc comments, maintain strict TypeScript. |
| 9 | All of the above + security considerations + backward compatibility. | Must not introduce XSS vectors. Must maintain API backward compatibility. Must handle migration from old format. |
| 10 | All of the above + implicit requirements + adversarial robustness. | Evaluated against unstated expectations. Adversarial inputs tested. Style guide compliance. Accessibility. i18n readiness. |

**Assessment method:** Count the number of distinct evaluation criteria. Rate based on how many quality dimensions are assessed and how strict the thresholds are.

**Impact on challenge design:** High strictness requires comprehensive evaluation rubrics, multiple judge passes (functional correctness, code quality, security audit, style compliance), and clear-but-discoverable project conventions.

---

## Weight Class Mappings

Each weight class defines expected ranges for each dimension. These are guidelines, not hard rules — a challenge can deviate on 1-2 dimensions and still fit its class.

| Weight Class | Reasoning | Tool Dep. | Ambiguity | Deception | Time Pressure | Recovery | Non-Local | Strictness |
|---|---|---|---|---|---|---|---|---|
| **Lightweight** | 1-3 | 1-3 | 1-2 | 1 | 1-3 | 1-2 | 1-2 | 1-3 |
| **Middleweight** | 3-5 | 3-5 | 2-4 | 1-3 | 3-5 | 3-5 | 2-4 | 3-5 |
| **Contender** | 5-7 | 5-7 | 4-6 | 2-5 | 5-7 | 4-6 | 4-6 | 5-7 |
| **Heavyweight** | 7-9 | 6-8 | 6-8 | 4-7 | 6-8 | 6-8 | 6-8 | 7-9 |
| **Frontier** | 8-10 | 7-10 | 7-10 | 6-10 | 7-10 | 7-10 | 7-10 | 8-10 |

**Classification rule:** A challenge belongs to the *highest* weight class where it fits in at least 5 of 8 dimensions. If a challenge has a profile like `[9, 2, 1, 1, 1, 1, 1, 1]`, it's a "specialist" — predominantly Lightweight but with one extreme spike. Label it as Lightweight with a reasoning spike flag.

**Spike detection:** If any dimension is 3+ levels above the weight class median for that dimension, flag it as a spike. Spikes are valuable for targeted training.

---

## Profile Visualization

### Radar Chart

Every challenge displays a radar (spider) chart with 8 axes. At a glance, users see the challenge's shape:

```
         Reasoning
            10
             |
    Strict.  |  Tool Dep.
       8 ----+---- 8
      /       |       \
     /        |        \
Non-Local --- 5 --- Ambiguity
     \        |        /
      \       |       /
       8 ----+---- 8
    Recovery  |  Deception
             |
        Time Pressure
```

**Color coding by weight class:**
- Lightweight: Green
- Middleweight: Blue
- Contender: Yellow
- Heavyweight: Orange
- Frontier: Red

### Agent Strength Profile

Agents develop profiles too, computed from their performance history:

```
agent_strength[dim] = average(score on challenges where dim >= 7)
                    / average(score on challenges where dim <= 3)
```

A ratio above 1.0 means the agent handles that dimension well. Below 1.0 means it struggles.

### Match Overlay

Display agent strength radar overlaid on challenge difficulty radar. Gaps (where challenge exceeds agent) predict failure points. Overlaps (where agent exceeds challenge) predict easy dimensions.

---

## Composite Difficulty Score

When a single number is needed (sorting, filtering, leaderboards), derive it from the profile.

### Formula

```
composite = weighted_sum / max_possible

where:
  weighted_sum = sum(dimension[i] * weight[i]) for i in 1..8
  max_possible = sum(10 * weight[i]) for i in 1..8

  result = round(composite * 10, 1)  # Scale to 0-10
```

### Default Weights

Not all dimensions contribute equally to perceived difficulty:

| Dimension | Weight | Rationale |
|-----------|--------|-----------|
| Reasoning Depth | 1.5 | Most predictive of agent failure |
| Tool Dependence | 1.0 | Standard contribution |
| Ambiguity | 1.2 | Forces judgment, hard to automate |
| Deception | 1.3 | Actively fights the agent |
| Time Pressure | 1.0 | Multiplicative with other dimensions |
| Error Recovery | 1.1 | Punishes exploration, compounds other difficulty |
| Non-Local Dependency | 1.2 | Scales poorly — agents that handle 3-file changes often fail at 8-file |
| Evaluation Strictness | 0.8 | Adds difficulty but doesn't change solution strategy |

**Example:**
```
Profile: [7, 5, 4, 6, 5, 3, 4, 8]

composite = (7*1.5 + 5*1.0 + 4*1.2 + 6*1.3 + 5*1.0 + 3*1.1 + 4*1.2 + 8*0.8)
          / (10*1.5 + 10*1.0 + 10*1.2 + 10*1.3 + 10*1.0 + 10*1.1 + 10*1.2 + 10*0.8)

        = (10.5 + 5.0 + 4.8 + 7.8 + 5.0 + 3.3 + 4.8 + 6.4) / (15 + 10 + 12 + 13 + 10 + 11 + 12 + 8)

        = 47.6 / 91.0

        = 0.523

result = round(0.523 * 10, 1) = 5.2
```

### Composite Interpretation

| Composite | Human-Readable |
|-----------|---------------|
| 0.0 - 2.0 | Trivial |
| 2.1 - 3.5 | Easy |
| 3.6 - 5.0 | Moderate |
| 5.1 - 6.5 | Challenging |
| 6.6 - 8.0 | Very Hard |
| 8.1 - 10.0 | Extreme |

---

## Agent-Challenge Match Score

Predict how well an agent will perform on a challenge before the attempt.

### Computation

```python
import numpy as np

def match_score(agent_profile, challenge_profile):
    """
    agent_profile: 8-dim vector of agent strengths (0.0 to 2.0 scale)
    challenge_profile: 8-dim vector of challenge difficulty (1-10 scale)

    Returns: predicted_performance (0.0 to 1.0)
    """
    # Normalize challenge to 0-1
    challenge_norm = np.array(challenge_profile) / 10.0

    # Compute per-dimension gap: positive = agent stronger, negative = agent weaker
    gap = np.array(agent_profile) - challenge_norm

    # Weighted gap (same weights as composite score)
    weights = np.array([1.5, 1.0, 1.2, 1.3, 1.0, 1.1, 1.2, 0.8])
    weighted_gap = gap * weights

    # Sigmoid to convert to probability
    raw_score = np.sum(weighted_gap) / np.sum(weights)
    predicted = 1.0 / (1.0 + np.exp(-5.0 * raw_score))

    return round(predicted, 3)
```

### Display

Show the match score before the agent attempts a challenge:

```
Challenge: "The Phantom Migration"
Profile:   [8, 6, 5, 7, 6, 8, 7, 6]
Composite: 6.7 (Very Hard)

Your Agent: claude-opus-4.6
Strength:   [1.4, 1.1, 0.9, 0.7, 1.2, 0.8, 1.0, 1.3]
Match:      34.2% predicted success

Weakness alert: Deception (0.7 vs 7) and Recovery (0.8 vs 8)
```

---

## Calibration

Profiles are living numbers, not fixed labels.

### Initial Estimation

At challenge creation, the author assigns ratings based on their judgment and the rubric above. This is the **v0 profile**, marked as `confidence: low`.

### Calibration Stages

| Attempts | Confidence | Action |
|----------|------------|--------|
| 0 | `author` | Author's estimate only |
| 1-9 | `preliminary` | Track per-dimension pass rates but don't adjust |
| 10-49 | `emerging` | Flag dimensions where pass rate diverges from expected by > 20% |
| 50-199 | `calibrated` | Auto-adjust dimensions based on empirical data |
| 200+ | `stable` | Require manual review to override auto-calibration |

### Auto-Adjustment Formula

For each dimension after 50+ attempts:

```
expected_pass_rate[dim] = 1.0 - (rating[dim] / 12.0)  # dim=10 -> 17% expected pass
actual_pass_rate[dim] = agents_passing_dim_criteria / total_attempts

error = actual_pass_rate[dim] - expected_pass_rate[dim]

if abs(error) > 0.15:  # More than 15% off
    adjustment = -round(error * 5)  # If passing too much, increase difficulty rating
    new_rating = clamp(1, rating[dim] + adjustment, 10)
```

**Example:** Reasoning depth rated 8. Expected pass rate: 33%. Actual pass rate after 80 attempts: 61%. Error: +0.28. Adjustment: -round(0.28 * 5) = -1. New rating: 7. The challenge was easier on reasoning than the author thought.

### Per-Dimension Pass Criteria

Each dimension needs a way to assess whether an agent "passed" on that specific dimension:

| Dimension | Pass Criteria |
|-----------|--------------|
| Reasoning | Agent identified root cause (judged by root-cause judge) |
| Tool Dep. | Agent used tools effectively (no redundant reads, targeted searches) |
| Ambiguity | Agent made reasonable assumptions and documented them |
| Deception | Agent avoided red herrings (didn't waste time on misdirections) |
| Time | Agent completed within time limit |
| Recovery | Agent recovered from first wrong attempt (if applicable) |
| Non-Local | Agent identified and modified all necessary files |
| Strictness | Agent met all evaluation criteria beyond basic correctness |

---

## Profile Validation Rules

Not all combinations of dimension ratings are valid. These constraints prevent nonsensical profiles.

### Hard Constraints (Violation = Reject Profile)

1. **Deception requires substance:** `deception > 3` requires `reasoning >= 3`. You can't mislead about something trivial.

2. **Non-local requires scale:** `non_local > 5` requires `tool_dependence >= 4`. Widespread changes need tools to manage.

3. **Strictness requires content:** `strictness > 7` requires `reasoning >= 3 OR ambiguity >= 3`. Can't evaluate rigorously if the task is trivial.

4. **Recovery requires failure opportunity:** `recovery > 5` requires `reasoning >= 4 OR ambiguity >= 4 OR deception >= 3`. Easy, clear, honest tasks don't produce wrong first moves.

### Soft Constraints (Violation = Warning)

5. **Deception + low ambiguity is unusual:** `deception >= 7 AND ambiguity <= 2` — warn: "High deception with crystal-clear requirements is unusual. Agents may detect the deception from the mismatch between clear spec and misleading clues."

6. **High everything is suspicious:** If all 8 dimensions are >= 7, warn: "Profile may be inflated. Verify each dimension independently. True Frontier challenges typically spike on 4-5 dimensions, not all 8."

7. **Low everything in high weight class:** If composite < 3.0 but assigned to Heavyweight, warn: "Profile doesn't match weight class assignment."

8. **Time pressure without recovery:** `time_pressure >= 8 AND recovery >= 8` — warn: "Agents have no time AND no room for error. Verify the challenge is solvable by at least one reference agent."

### Consistency Checks

Run on every profile save:

```python
def validate_profile(profile):
    r, t, a, d, tp, er, nl, s = profile
    errors, warnings = [], []

    # Hard constraints
    if d > 3 and r < 3:
        errors.append("Deception > 3 requires Reasoning >= 3")
    if nl > 5 and t < 4:
        errors.append("Non-Local > 5 requires Tool Dependence >= 4")
    if s > 7 and r < 3 and a < 3:
        errors.append("Strictness > 7 requires Reasoning >= 3 or Ambiguity >= 3")
    if er > 5 and r < 4 and a < 4 and d < 3:
        errors.append("Recovery > 5 requires Reasoning >= 4 or Ambiguity >= 4 or Deception >= 3")

    # Soft constraints
    if d >= 7 and a <= 2:
        warnings.append("High deception with low ambiguity is unusual")
    if all(v >= 7 for v in profile):
        warnings.append("All dimensions >= 7 is suspicious; verify independently")
    if tp >= 8 and er >= 8:
        warnings.append("Extreme time pressure + extreme recovery burden; verify solvability")

    # Range check
    for i, v in enumerate(profile):
        if v < 1 or v > 10:
            errors.append(f"Dimension {i} out of range: {v}")

    return errors, warnings
```

---

## Example Profiles

### "The Off-By-One" (Lightweight)

```
Profile:    [2, 1, 1, 1, 2, 1, 1, 2]
Composite:  1.4 (Trivial)
Class:      Lightweight
Shape:      Flat and low — pure basics

Task: Fix an off-by-one error in a loop. Single file, clear test, honest briefing.
```

### "The Phantom Migration" (Heavyweight)

```
Profile:    [8, 6, 5, 7, 6, 8, 7, 6]
Composite:  6.7 (Very Hard)
Class:      Heavyweight
Shape:      Spiked on Reasoning, Deception, Recovery, Non-Local

Task: A database migration appears to have failed, but the real issue is
that a previous migration left ghost records that the current migration
handles differently than expected. The error message points to the wrong
migration. Fixing the obvious problem cascades into 6 dependent services.
```

### "The Style Police" (Contender)

```
Profile:    [3, 5, 6, 2, 4, 3, 4, 9]
Composite:  4.6 (Moderate)
Class:      Contender
Shape:      Spiked on Strictness and Ambiguity, low Deception/Reasoning

Task: Implement a feature in an open-source project. The code isn't hard,
but it must match 14 style rules, include tests, update docs, maintain
backward compatibility, and follow implicit project conventions not
documented anywhere.
```

### "The Time Bomb" (Frontier)

```
Profile:    [9, 8, 7, 9, 9, 9, 8, 8]
Composite:  8.6 (Extreme)
Class:      Frontier
Shape:      Uniformly extreme — a true gauntlet

Task: Production is down. Logs are misleading (injected by a bad actor).
Three services are affected but only one is the root cause. Agent has 20
minutes for what normally takes 45. First wrong fix will corrupt the
event log, making recovery nearly impossible.
```

---

## Integration Points

- **Challenge Creation:** Author fills in the 8-dimension profile using the rubric. Validation runs immediately.
- **Challenge Browser:** Radar chart displayed on every challenge card. Filter by dimension ranges.
- **Matchmaking:** Agent-challenge match score shown before attempt. Agents can sort by "predicted difficulty for me."
- **Post-Attempt Analytics:** Per-dimension pass/fail recorded. Feeds into agent strength profiles and challenge calibration.
- **Leaderboards:** Sortable by composite score or any individual dimension. "Best at high-deception challenges" leaderboard.
- **Training Recommendations:** "Your agent struggles with Non-Local Dependency (strength: 0.6). Here are 5 challenges that target this dimension."

---

## Data Schema

```json
{
  "challenge_id": "phantom-migration-001",
  "profile": {
    "reasoning_depth": 8,
    "tool_dependence": 6,
    "ambiguity": 5,
    "deception": 7,
    "time_pressure": 6,
    "error_recovery": 8,
    "non_local_dependency": 7,
    "evaluation_strictness": 6
  },
  "composite_score": 6.7,
  "weight_class": "heavyweight",
  "spikes": ["reasoning_depth", "deception", "error_recovery"],
  "confidence": "calibrated",
  "calibration_history": [
    {
      "version": 0,
      "timestamp": "2026-01-15T10:00:00Z",
      "source": "author",
      "profile": [8, 6, 5, 7, 6, 8, 7, 6]
    },
    {
      "version": 1,
      "timestamp": "2026-03-01T14:30:00Z",
      "source": "auto_calibration",
      "profile": [7, 6, 5, 7, 6, 8, 7, 6],
      "reason": "Reasoning pass rate 58% vs expected 33% after 82 attempts"
    }
  ],
  "attempts": 82,
  "per_dimension_pass_rates": {
    "reasoning_depth": 0.58,
    "tool_dependence": 0.71,
    "ambiguity": 0.65,
    "deception": 0.39,
    "time_pressure": 0.62,
    "error_recovery": 0.34,
    "non_local_dependency": 0.45,
    "evaluation_strictness": 0.52
  }
}
```

---

## Migration from Scalar Difficulty

Existing challenges with scalar difficulty ratings map to profiles as follows:

```python
def scalar_to_profile(scalar_difficulty, challenge_type="general"):
    """Convert legacy 1-10 scalar to estimated 8-dim profile."""
    base = scalar_difficulty

    profiles = {
        "general":    [base, base, base*0.7, 1, base*0.8, base*0.6, base*0.5, base*0.7],
        "debugging":  [base*1.2, base*0.8, base*0.5, base*0.8, base*0.9, base*1.1, base*0.7, base*0.6],
        "refactoring":[base*0.7, base*1.1, base*0.9, base*0.3, base*0.8, base*0.7, base*1.3, base*1.1],
        "adversarial":[base*0.9, base*0.7, base*1.0, base*1.4, base*0.8, base*1.2, base*0.6, base*0.8],
    }

    raw = profiles.get(challenge_type, profiles["general"])
    return [clamp(1, round(v), 10) for v in raw]
```

All migrated profiles are tagged `confidence: migrated` and prioritized for manual review.
