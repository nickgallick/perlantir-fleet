# Toolchain Betrayal — Flagship Family Specification

---

## 1. Core Fantasy

**Why this family is memorable:** Your tools are lying to you. The test runner is flaky. The linter gives false positives. The documentation is outdated. The build system silently swallows errors. You can't trust your instruments — and you still have to ship working code.

**What kind of agent failure it exposes:** Blind tool trust. Agents that take every test result at face value. Agents that can't function when their workflow breaks. Agents that confuse "the tool said OK" with "the code is correct." In production, tools are imperfect. Toolchain Betrayal tests whether agents can reason ABOUT their tools, not just WITH them.

**The emotional hook:** Every developer has had a test that passes locally and fails in CI, a linter that flags correct code, a build system that caches stale artifacts. The moment you realize your tools are the problem, not the code.

---

## 2. Canonical Structure

### Always Present
- At least 1 unreliable tool (test runner with flaky tests, linter with false positives, build with silent errors)
- The unreliability is DISCOVERABLE (run the tool twice, compare results; read the tool config)
- The challenge CANNOT be solved by coding alone — requires tool orchestration
- A challenge that could be solved with reliable tools in 20 minutes takes 40 with unreliable ones
- The Process Judge weight is elevated (≥20%) — tool discipline is central

### May Vary
- Which tool is unreliable (test runner, linter, build system, database CLI, deployment script, monitoring dashboard)
- How the unreliability manifests (intermittent failures, false positives, stale cache, silent errors, wrong defaults)
- The core engineering task underneath the tool problems
- Domain and technology stack

### Must Never Vary
- At least 1 tool must be demonstrably unreliable
- The unreliability must be detectable through systematic investigation (run twice, compare, check config)
- The challenge must require the agent to reason about tool behavior, not just use tools
- Working around the tool problem must be part of the solution

---

## 3. Weight Class Scaling

### Lightweight
- **Unreliable tools:** 1 (test runner with 1 flaky test)
- **Core task:** Simple bug fix where the flaky test masks progress
- **Detection difficulty:** Easy — run tests twice, see different results
- **Time:** 20 minutes, 3 iterations
- **Score if agent doesn't detect flakiness:** 30-40 (can still fix the bug, but wastes time chasing phantom failures)

### Middleweight
- **Unreliable tools:** 1-2 (flaky test + linter false positive)
- **Core task:** Multi-file fix where tool unreliability creates confusion
- **Detection difficulty:** Moderate — need to correlate tool behavior with code changes
- **Time:** 35 minutes, 4 iterations
- **Three paths:** Trust tools blindly → chase phantoms (25-40) → Detect 1 problem, miss the other (45-60) → Detect all, work around them (70-90)

### Heavyweight
- **Unreliable tools:** 2-3 (flaky tests + stale build cache + misleading error messages)
- **Core task:** Complex implementation where every verification step is compromised
- **Detection difficulty:** Hard — unreliabilities interact (stale cache makes flaky test appear consistent, misleading errors about the wrong file)
- **Time:** 45 minutes, 5 iterations

### Frontier
- **Unreliable tools:** 3+ with compounding effects
- **The meta-betrayal:** Agent's own verification of tool reliability is compromised (testing the test runner gives wrong results the first time)
- **Time:** 60 minutes, 6 iterations

### Abyss / Boss Fight
- Tools are unreliable in CONTEXT-DEPENDENT ways (work on file A, fail on file B for the same input)
- The agent must build a mental model of when each tool can be trusted
- 8+ scoring milestones, prestige badges

---

## 4. Discrimination Design

### What Average Agents Do
- Trust every tool output at face value
- When a test fails, assume the code is wrong (even when the test is flaky)
- Waste iterations fixing code that was already correct based on wrong test results
- Never run the same test twice to check for flakiness
- **Score range:** 15-38
- **Dominant failure modes:** Toolchain Misuse, False Confidence Hallucination, Recovery Collapse

### What Strong Agents Do
- Notice when tool results seem inconsistent with code changes ("I didn't change anything and the test went from fail to pass?")
- Detect the most obvious unreliability
- Work around it for the primary task
- Miss subtler tool problems (stale cache, context-dependent behavior)
- **Score range:** 45-68
- **Dominant failure modes:** Constraint Blindness (assumes remaining tools are reliable)

### What Elite Agents Do
- Systematically verify tool reliability before trusting results
- Run tools multiple times, compare outputs, read configurations
- Build a mental model of which tools to trust and when
- Use alternative verification methods when primary tools are unreliable
- Document tool issues in deliverables
- **Score range:** 72-92

### Where Same-Model Agents Diverge
**Primary divergence:** Tool verification discipline. This is entirely scaffolding:
- Scaffolding A: Trusts all tools by default → caught off guard
- Scaffolding B: Has a "verify tool reliability" step → detects problems early
- Scaffolding C: Re-runs every test 3x by default → reliable but slow (efficiency penalty)
- Scaffolding D: Only verifies tools when results contradict expectations → efficient and accurate

**Process diversity expected:** ≥4 of 5

---

## 5. Mutation System

### Semantic Mutations
- Tool type rotation: test runner → linter → build system → database CLI → deployment script → monitoring
- Unreliability type: flaky results → false positives → stale cache → silent errors → wrong defaults
- Core task underneath: bug fix → implementation → refactoring → migration
- **Invariant:** At least 1 tool unreliable; unreliability detectable; requires tool reasoning

### Structural/Adversarial Mutations
- Tool configuration location variation (package.json → .toolrc → CI config → environment variables)
- Unreliability trigger variation (always → intermittent → conditional)
- **Invariant:** Detection path must remain systematic, not lucky

### Forbidden Sibling Overlap
- No two active siblings may share the same unreliable tool type
- No two active siblings may have the same unreliability manifestation
- Similarity < 0.65

---

## 6. Anti-Exploit Design

### Likely Shortcuts
| Shortcut | Mitigation |
|----------|------------|
| "Always run every test 3x" meta-strategy | Efficiency scoring penalizes blind re-running. Intermittent flakiness may require 5+ runs. Context-dependent flakiness isn't caught by simple re-running. |
| "Ignore all failing tests and just submit" | Objective Judge still checks — ignoring all tests means missing real failures too |
| "Fix the tool instead of working around it" | Sometimes correct, sometimes impossible — vary whether the tool is fixable or not |

### Family-Specific Exploit Traps
- Include one tool that's CORRECTLY reporting a real problem — agent that discounts ALL tool output (because they've been trained to distrust) misses a real bug
- Include one tool that's unreliable in a DIFFERENT way than previous instances to prevent pattern matching

---

## 7. Post-Match Breakdown Structure

### What the Audience Learns
- Which tools the agent trusted vs verified
- When tool unreliability was detected (or not)
- Time wasted chasing phantom tool failures
- Whether the agent adapted its tool usage strategy

### What the Losing Agent Visibly Missed
- "You ran the test suite 4 times and got 4 different results. You treated each result as ground truth and changed your code each time. If you'd compared the 4 results, you'd have seen that tests 7 and 23 are flaky (different results each run) while the rest are stable. That would have saved 15 minutes."

### Why the Winner Deserved to Win
- "Agent A detected the flaky test at minute 5 by running the suite twice with no code changes. It then used the stable tests as reliable indicators and treated the flaky tests as noise. This let it focus on the real bugs without distraction."

---

## 8. Format Examples

### Sprint: "The Lying Test"
- 1 flaky test, 15 minutes, 3 iterations
- Domain: API endpoint where 1 of 20 tests intermittently fails
- Key discrimination: does the agent detect the flakiness or keep "fixing" it?

### Standard: "The Broken Build"
- 2 unreliable tools, 35 minutes, 4 iterations
- Domain: CI pipeline with stale cache + misleading error messages
- Key discrimination: can the agent work effectively with compromised verification?

### Marathon: "The Instrument Failure"
- 3+ unreliable tools with compounding effects, 90 minutes, 6 iterations
- Domain: production debugging where monitoring, logging, AND testing are all partially compromised
- Key discrimination: building a mental model of tool reliability under degraded conditions

### Versus: "Toolchain Duel"
- Mirror Versus: same codebase, same unreliable tools
- Key spectator value: one agent detects the flakiness in minute 3, the other trusts results for 20 minutes

---

## 9. Kill Criteria

| Kill Signal | Threshold | Meaning |
|-------------|-----------|---------|
| **Immediate detection meta-strategy** | >70% of agents run tools twice immediately on 3+ instances | "Always verify tools" has become universal |
| **Tool-type predictability** | >60% of agents guess which tool is unreliable before testing on 3+ instances | The family pattern is too recognizable |
| **Process lane compression** | Process Judge scores cluster within 10 points for >70% of agents | Tool discipline differences aren't being captured |
| **CDI decay** | Average CDI < B (0.50) | Family losing discrimination power |

### Refresh vs Retire
- Meta-strategy detection → Refresh: make unreliability context-dependent (not catchable by simple re-running)
- Tool-type predictability → Refresh: new tool types (deployment scripts, monitoring, database CLIs)
- Post-2-refreshes → Retire variant
