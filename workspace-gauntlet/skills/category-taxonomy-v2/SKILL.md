# Category Taxonomy v2

The refined 10-category system for Bouts challenges. Each category is a distinct test of a different kind of engineering intelligence — not just different topics, but fundamentally different cognitive demands.

**SKILL 35** — Gauntlet challenge engine taxonomy. This document is the canonical reference for category definitions, scoring, difficulty scaling, and challenge design.

---

## The 10 Categories

---

### 1. Debug Gauntlets

**Definition:** Multi-bug repositories where bugs are interconnected — fixing one reveals, unmasks, or triggers another. The defining characteristic test: "Does fixing Bug A change the behavior of Bug B?" If yes, it's a Debug Gauntlet. If the bugs are independent, it's just a bug list.

**What it tests:**
- Systematic diagnosis over reactive patching
- Mental model construction of an entire system from partial information
- Holding multiple hypotheses simultaneously while gathering evidence
- Distinguishing root causes from symptoms
- Recognizing when a "fix" introduces a new failure (regression awareness)
- Prioritizing which bug to fix first when order matters

**Scoring emphasis:**
- Objective (40%) — did all bugs get fixed, zero regressions
- Process (30%) — how systematically did the agent investigate (read before edit, hypothesis before fix)
- Strategy (20%) — was the debugging sequence efficient, was the dependency graph understood
- Integrity (10%) — did the agent acknowledge uncertainty about root causes rather than guessing

**Difficulty scaling:**
- **Lightweight (D1-D3):** 2-3 bugs, 1 interconnection, 1 file. Clear stack traces provided.
- **Middleweight (D3-D5):** 4-5 bugs, 2-3 interconnections, 3-5 files. Some misleading error messages.
- **Cruiserweight (D5-D7):** 5-7 bugs, 3-4 interconnections across modules, 1-2 red herrings. Logs are noisy.
- **Heavyweight (D7-D9):** 7-9 bugs, deep interconnection chains (A→B→C→D), 3+ red herrings, some bugs only manifest after others are fixed.
- **Frontier (D9-D10):** 9+ bugs across an entire system, circular dependencies between bugs, adversarial red herrings that look more convincing than real bugs, timing-dependent bugs.

**Concrete examples:**
1. *"The Memory Vampire"* (Cruiserweight) — Service OOMs after 72 hours. Find the leak without profiler output. 4 red herrings in the codebase. The real leak is in an event emitter that looks correct. Fits Debug Gauntlets because the OOM masks a secondary connection-pool exhaustion bug.
2. *"The Cascade"* (Middleweight) — Fix the auth bug → session store breaks → fix that → audit log breaks. Stabilize all three with no regressions. Fits because each fix destabilizes the next component.
3. *"The Nine Lives"* (Heavyweight) — 9 bugs, 5 interconnected, 4 red herrings, 1 bug only appears AFTER fixing another. The agent must map the dependency graph before touching code.

**Best formats:**
- **Sprint:** Poor — interconnected bugs need time to map; sprints reward speed over understanding
- **Standard:** Best — enough time to systematically investigate and fix
- **Marathon:** Good — works for Heavyweight/Frontier difficulty where bug chains are deep

**Common failure modes:**
- Fixing symptoms instead of root causes, leading to whack-a-mole
- Not running full test suite after each fix (missing regressions)
- Spending too long on red herrings because they look "interesting"
- Fixing bugs in the wrong order, creating more breakage

**Anti-patterns for challenge design:**
- Bugs that are truly independent (just a task list, not a gauntlet)
- Red herrings that are impossible to distinguish from real bugs without information the agent cannot access
- Bug chains so deep that the challenge becomes a guessing game rather than a reasoning exercise

---

### 2. Adversarial Implementation

**Definition:** The challenge looks easy and the spec is clear. Visible tests pass quickly. Then hidden adversarial test suites destroy naive implementations. The defining characteristic test: "Would a confident, fast-moving agent ship something that passes all visible tests but fails catastrophically on hidden ones?" If yes, it's Adversarial Implementation.

**What it tests:**
- Defensive programming instincts
- Anticipating attack vectors and edge cases before being shown them
- Reading requirements deeply vs. skimming for the happy path
- Writing self-generated tests beyond what's provided
- Handling malicious, malformed, and extreme inputs gracefully
- Understanding the difference between "works" and "robust"

**Scoring emphasis:**
- Objective (55%) — hidden adversarial test pass rate is the primary signal
- Process (20%) — did the agent write its own edge-case tests before being told to
- Strategy (15%) — did the agent reason about attack surfaces before implementing
- Integrity (10%) — did the agent express doubt about edge cases it couldn't test

**Difficulty scaling:**
- **Lightweight (D1-D3):** 3-5 hidden edge cases, all in the same input dimension (e.g., string length). Visible tests hint at the pattern.
- **Middleweight (D3-D5):** 8-12 hidden cases across 2-3 dimensions. Some visible tests are misleading (they pass for wrong reasons).
- **Cruiserweight (D5-D7):** 15-20 hidden cases including security-relevant inputs (injection, overflow). Spec has subtle ambiguities.
- **Heavyweight (D7-D9):** 25+ hidden cases including concurrency attacks, timing attacks, and precision attacks. Spec is deliberately vague in critical areas.
- **Frontier (D9-D10):** Hidden test suite is adversarially generated. Includes protocol-level attacks, state-machine violations, and inputs that exploit common library bugs.

**Concrete examples:**
1. *"The Input Grinder"* (Cruiserweight) — Build a URL parser. Visible tests: basic cases. Hidden tests: null bytes, 10MB URLs, RTL characters, unicode normalization attacks, IPv6 with zone IDs, credentials in URL. Fits because the spec says "parse URLs" and the naive regex approach fails on every edge.
2. *"The Payment Gate"* (Heavyweight) — Build a payment endpoint. Visible tests: happy path. Hidden: double-submit within 10ms, negative amounts, currency precision attacks (3-decimal currencies), replay attacks, idempotency key collisions. Fits because payment code that "works" and payment code that's "correct" are vastly different.
3. *"The Rate Limiter"* (Middleweight) — Build a rate limiter that can't be bypassed. Hidden tests: distributed clients coordinating to bypass per-IP limits, header spoofing, connection reuse attacks. Fits because rate limiting looks trivial until adversaries get creative.

**Best formats:**
- **Sprint:** Good — time pressure increases the temptation to skip edge cases, which is exactly what this category tests
- **Standard:** Best — enough time to be thorough, but not so much that even sloppy agents eventually cover everything
- **Marathon:** Poor — too much time dilutes the adversarial pressure; agents will stumble into robustness eventually

**Common failure modes:**
- Shipping the first implementation that passes visible tests
- Not generating own test cases before submitting
- Trusting library defaults for security-sensitive operations
- Handling errors by swallowing them instead of failing safely

**Anti-patterns for challenge design:**
- Hidden tests that require knowledge the agent cannot reasonably infer from the spec
- Edge cases that are so obscure they test trivia rather than defensive thinking
- Visible test suites that are so comprehensive they eliminate the need for agent-generated tests

---

### 3. Constraint Mazes

**Definition:** The constraints force non-obvious approaches. The standard textbook solution violates at least one constraint. The defining characteristic test: "Does removing the constraints make this problem trivially solvable with a standard approach?" If yes, it's a Constraint Maze.

**What it tests:**
- Problem-solving creativity under restrictions
- Constraint satisfaction across multiple simultaneous limits
- Ability to work within limits rather than ignoring or violating them
- Recognizing when a constraint eliminates entire solution families
- Finding the intersection of multiple constraint spaces
- Distinguishing hard constraints (must satisfy) from soft constraints (should satisfy)

**Scoring emphasis:**
- Objective (45%) — constraints actually respected AND solution correct
- Strategy (30%) — was the constrained approach reasonable and elegant
- Process (15%) — did the agent verify constraint compliance before submitting
- Integrity (10%) — did the agent flag when constraints might be contradictory

**Difficulty scaling:**
- **Lightweight (D1-D3):** 1-2 constraints, single obvious alternative approach exists. Constraint is clearly stated.
- **Middleweight (D3-D5):** 2-3 constraints that interact. The alternative approach requires insight but is findable.
- **Cruiserweight (D5-D7):** 3-4 constraints that create a narrow solution corridor. Agent must combine techniques.
- **Heavyweight (D7-D9):** 4-5 constraints where satisfying any 4 is easy but satisfying all 5 requires a non-obvious synthesis.
- **Frontier (D9-D10):** Constraints appear contradictory. Solution requires reframing the problem space entirely. Some constraints are implicit (resource limits, time limits enforced by the environment).

**Concrete examples:**
1. *"The Migration"* (Cruiserweight) — Migrate 10GB of data. Hard constraint: <500MB temp space. Standard approach (dump and reload) needs 10GB temp. Actual solution: streaming migration with incremental verification. Fits because the memory constraint eliminates the default approach.
2. *"The Deploy Window"* (Middleweight) — Fix a critical bug. Hard constraint: deploy pipeline takes 5 minutes max. The normal fix takes 7 minutes to deploy. Must restructure the fix to be deployable within the window. Fits because the time constraint changes HOW you fix, not just WHAT you fix.
3. *"The Offline Fix"* (Heavyweight) — Fix a bug in a service. Constraints: no network access, no package manager, only standard library, must maintain backward compatibility with existing clients. Must solve with what's available, reimplementing what you'd normally import. Fits because each constraint eliminates a category of solutions.

**Best formats:**
- **Sprint:** Good — constraint awareness under time pressure is a strong differentiator
- **Standard:** Best — enough time to explore the constraint space and find the narrow valid path
- **Marathon:** Good — works for Heavyweight/Frontier where the constraint space is genuinely complex

**Common failure modes:**
- Violating a constraint and not noticing (no verification step)
- Treating hard constraints as soft ("it's close enough to 500MB")
- Giving up and declaring the constraints impossible instead of searching harder
- Over-engineering: finding a solution that respects constraints but is 10x more complex than necessary

**Anti-patterns for challenge design:**
- Constraints that are genuinely contradictory (no valid solution exists)
- Constraints so loose that the standard approach still works
- Artificial constraints that don't map to real-world scenarios (agents can't form intuition)

---

### 4. Forensic Reasoning

**Definition:** The agent does NOT get direct access to the failing component's internals. It gets logs, error messages, metrics, traces, and other indirect evidence. It must infer the root cause from circumstantial data. The defining characteristic test: "Is the agent reasoning from evidence rather than reading source code?" If the solution requires reading and understanding the buggy code directly, it's Debug Gauntlets, not Forensic Reasoning.

**What it tests:**
- Hypothesis formation from incomplete data
- Evidence evaluation and weighing conflicting signals
- Distinguishing signal from noise in messy production data
- Bayesian updating — revising beliefs as new evidence arrives
- Admitting uncertainty instead of committing to a wrong answer
- Constructing experiments to test hypotheses (not just reading more logs)

**Scoring emphasis:**
- Strategy (40%) — quality of reasoning process, hypothesis formation, evidence chain
- Objective (25%) — did the agent identify the correct root cause
- Integrity (20%) — did the agent express appropriate uncertainty, avoid false confidence
- Process (15%) — was evidence gathered systematically, were hypotheses tested

**Difficulty scaling:**
- **Lightweight (D1-D3):** Clear error in logs points to the problem area. 1-2 hypotheses to consider. Evidence is clean.
- **Middleweight (D3-D5):** Multiple plausible hypotheses. Some evidence is misleading. Agent must weigh evidence to pick the right one.
- **Cruiserweight (D5-D7):** Evidence is noisy (irrelevant log lines outnumber relevant ones 10:1). Multiple interacting causes. Timeline matters.
- **Heavyweight (D7-D9):** Evidence is contradictory (some logs point to Cause A, other metrics point to Cause B). The actual cause is C, which explains both. Agent must synthesize across evidence types.
- **Frontier (D9-D10):** Evidence is actively misleading (a monitoring bug makes healthy components look sick). The agent must question the reliability of the evidence itself. Meta-reasoning required.

**Concrete examples:**
1. *"The Phantom Response"* (Middleweight) — Service returns 200 but clients report errors. Logs show success. The problem is in the response body format — logs don't capture response bodies. Agent must infer this gap in observability. Fits because the answer isn't in the code — it's in reasoning about what the logs DON'T show.
2. *"The Midnight Spike"* (Cruiserweight) — Every night at midnight, latency triples for 4 minutes. Logs show nothing abnormal. The cause: a scheduled job that doesn't log, competing for DB connections. Agent must correlate timing patterns with system behavior. Fits because the cause is invisible in the provided evidence.
3. *"The Silent Drop"* (Heavyweight) — 0.3% of requests return stale data. Intermittent. No errors. Cause: a cache with an off-by-one TTL that occasionally serves data 1 second past expiry, combined with a clock skew between cache nodes. Agent must reason about distributed systems behavior from statistical evidence.

**Best formats:**
- **Sprint:** Poor — forensic reasoning needs time for hypothesis formation and testing
- **Standard:** Best — enough time to form, test, and revise hypotheses
- **Marathon:** Best — complex forensic scenarios benefit from extended investigation time

**Common failure modes:**
- Jumping to conclusions from the first piece of evidence
- Anchoring on an early hypothesis and ignoring contradicting evidence
- Confusing correlation with causation in log analysis
- Not questioning the reliability of the evidence sources themselves

**Anti-patterns for challenge design:**
- Evidence that makes the answer obvious (no reasoning needed)
- Insufficient evidence to distinguish between hypotheses (unfair guessing game)
- Requiring domain-specific knowledge that an agent cannot reasonably have

---

### 5. Long-Horizon Planning

**Definition:** Multi-step tasks where early choices affect later solvability. A bad architectural decision in Phase 1 makes Phase 3 impossible without starting over. The defining characteristic test: "If you could redo Phase 1 after seeing Phase 3's requirements, would you do it differently?" If yes, it tests long-horizon planning.

**What it tests:**
- Architectural foresight and anticipation of future requirements
- Planning under uncertainty (later phases may not be fully specified)
- Recognizing irreversible vs. reversible decisions and treating them differently
- Building extensible solutions that accommodate change
- Sequencing work to minimize rework
- Knowing when to invest in flexibility vs. when to commit

**Scoring emphasis:**
- Strategy (40%) — quality of planning, foresight demonstrated, alternatives considered
- Process (25%) — did the agent plan before executing, was the plan revised as new information arrived
- Objective (25%) — did the final deliverable work end-to-end
- Integrity (10%) — did the agent flag risks or assumptions about future phases

**Difficulty scaling:**
- **Lightweight (D1-D3):** 2 phases, clear dependency. The "wrong" Phase 1 choice is obviously wrong if you read Phase 2 first.
- **Middleweight (D3-D5):** 3 phases, Phase 3 requirements not revealed until Phase 2 is complete. The natural Phase 1 approach works but is suboptimal.
- **Cruiserweight (D5-D7):** 3-4 phases with branching dependencies. Some Phase 1 choices make Phase 3 impossible. Agent must reason about future state.
- **Heavyweight (D7-D9):** 4-5 phases, some requirements deliberately ambiguous. Agent must make decisions under uncertainty and build in flexibility.
- **Frontier (D9-D10):** 5+ phases with circular dependencies between phase requirements. Some phases have competing constraints. Agent must negotiate tradeoffs across the entire plan.

**Concrete examples:**
1. *"The Schema Migration"* (Cruiserweight) — Migrate a 50-column table to a new schema without downtime. Naive approach locks the table for 90 seconds. Must plan expand→migrate→contract. Fits because the approach must be chosen before execution begins and wrong choices are catastrophic.
2. *"The Refactor Path"* (Heavyweight) — Refactor a module. Phase 1 requirements are revealed, then Phase 2 (which requires Phase 1 to be done differently than the obvious approach), then Phase 3 (which requires both). Agent that hardcoded Phase 1 must restart. Fits because foresight is the differentiator.
3. *"The Dependency Upgrade"* (Middleweight) — Upgrade 3 interdependent libraries. Order matters: wrong order breaks prod, right order is seamless. Agent must analyze the dependency graph before touching anything. Fits because sequencing IS the challenge.

**Best formats:**
- **Sprint:** Poor — planning requires time; sprints reward execution speed
- **Standard:** Good — works for Middleweight, but may rush Heavyweight planning
- **Marathon:** Best — extended time allows proper planning, execution, and revision across all phases

**Common failure modes:**
- Diving into Phase 1 without reading all available requirements
- Making irreversible decisions early without considering downstream impact
- Not building extension points for anticipated future requirements
- Sunk cost fallacy — continuing with a bad Phase 1 approach instead of restarting

**Anti-patterns for challenge design:**
- Phases that are actually independent (no planning benefit)
- Future requirements so unpredictable that no amount of planning helps (feels unfair)
- Only one valid sequence (becomes a puzzle rather than a planning exercise)

---

### 6. Deceptive Optimization

**Definition:** The obvious solution works for visible cases but fails on cases the agent didn't anticipate. Greedy or naive approaches produce something that looks correct but has subtle bugs. The defining characteristic test: "Does the first solution that passes visible tests have a hidden correctness flaw?" If yes, it's Deceptive Optimization. Differs from Adversarial Implementation in that the challenge doesn't LOOK adversarial — it looks like a normal task.

**What it tests:**
- Thoroughness beyond "it passes the tests"
- Resistance to premature satisfaction and early stopping
- The instinct to keep probing after the obvious case works
- Understanding of mathematical or logical edge cases
- Recognizing when visible tests are insufficient coverage
- Questioning whether "correct-looking output" is actually correct

**Scoring emphasis:**
- Objective (50%) — adversarial/hidden test pass rate dominates
- Strategy (25%) — did the agent probe beyond the visible test suite, did it reason about edge cases
- Process (15%) — did the agent test its own implementation thoroughly
- Integrity (10%) — did the agent acknowledge areas of uncertainty in its solution

**Difficulty scaling:**
- **Lightweight (D1-D3):** 1-2 hidden failure modes, all in predictable categories (off-by-one, empty input). Agent with basic diligence catches them.
- **Middleweight (D3-D5):** 3-5 hidden failure modes spanning different categories. The "false summit" is convincing — visible tests are 100% green.
- **Cruiserweight (D5-D7):** 5-8 hidden failure modes. Some require domain knowledge (floating point precision, unicode, timezone). The naive solution is elegant, which makes it harder to doubt.
- **Heavyweight (D7-D9):** 8-12 hidden failure modes including subtle mathematical incorrectness. The naive solution works for 99% of inputs — the 1% is the test.
- **Frontier (D9-D10):** The naive solution is provably incorrect but produces correct output for all "reasonable" inputs. Failure only occurs on inputs that exploit specific mathematical properties. Requires formal reasoning.

**Concrete examples:**
1. *"The Currency Formatter"* (Cruiserweight) — Format currency amounts. Obvious solution handles USD fine. Hidden: 3-decimal currencies (BHD, KWD), negative amounts, NaN, very large numbers (> Number.MAX_SAFE_INTEGER), rounding modes. Fits because the task feels trivial and the traps are invisible.
2. *"The Date Parser"* (Middleweight) — Parse user-submitted dates. Obvious: MM/DD/YYYY. Hidden: Feb 29 on non-leap years, timezone-ambiguous inputs, ISO 8601 edge cases, years before 1970, years after 2038. Fits because date parsing is a classic "false summit."
3. *"The Sort"* (Heavyweight) — Sort a list of user names. Obvious: alphabetical. Hidden: Unicode normalization (e-acute vs e + combining accent), RTL names, names with only symbols, locale-dependent ordering, case-insensitive collation that differs by language. Fits because "sort alphabetically" hides enormous complexity.

**Best formats:**
- **Sprint:** Good — time pressure amplifies the temptation to stop at the false summit
- **Standard:** Best — enough time to be thorough, rewards agents who probe deeper
- **Marathon:** Poor — too much time means even careless agents may discover the traps

**Common failure modes:**
- Stopping as soon as visible tests pass ("green means done")
- Not generating edge case inputs beyond what's provided
- Trusting that library defaults handle all cases correctly
- Confusing "no errors" with "correct behavior"

**Anti-patterns for challenge design:**
- Hidden failure modes that are unrelated to the core task (testing trivia, not judgment)
- False summits that are too obvious (agent sees through them immediately)
- No visible test suite at all (becomes Adversarial Implementation instead)

---

### 7. Tool-Use Orchestration

**Definition:** The challenge cannot be solved by writing code alone. The agent must search files, read logs, run commands, interpret output, edit code, run tests, and iterate. The SEQUENCE of tool use matters. The defining characteristic test: "Does tool selection order significantly affect success probability or efficiency?" If yes, it's Tool-Use Orchestration.

**What it tests:**
- Tool selection intelligence — choosing the right tool for the current sub-task
- Sequencing quality — not running tests before understanding the codebase
- Efficiency — solving in fewer tool invocations
- Output interpretation — extracting the right signal from tool output
- Knowing when to stop gathering information and start acting
- Recovering from inefficient tool use without spiraling

**Scoring emphasis:**
- Process (45%) — tool use quality, sequencing, efficiency, information extraction
- Objective (30%) — did the task actually get completed
- Strategy (15%) — was the overall approach to tool use well-planned
- Integrity (10%) — did the agent avoid wasteful or destructive tool use

**Difficulty scaling:**
- **Lightweight (D1-D3):** 2-3 tools needed in a linear sequence. Clear which tool to use when.
- **Middleweight (D3-D5):** 4-5 tools needed, some parallelizable. Agent must choose between equivalent tools.
- **Cruiserweight (D5-D7):** 5-7 tools across multiple domains (filesystem, network, database). Order matters — wrong sequence wastes budget.
- **Heavyweight (D7-D9):** 7-10 tool invocations required. Some tools produce misleading output if used at the wrong time. Tool budget is tight.
- **Frontier (D9-D10):** 10+ tools, some tools modify state (destructive reads). Agent must plan tool use like a chess game — each move changes the board.

**Concrete examples:**
1. *"The Grep-and-Fix"* (Middleweight) — Bug somewhere in 15 files. No hints about location. Must read→search→hypothesize→verify→fix. Agent that greps intelligently finds it in 3 steps. Agent that reads every file wastes 12 steps. Fits because the search strategy IS the skill being tested.
2. *"The Profiler"* (Cruiserweight) — Endpoint is slow. No profiler output provided. Must use available tools (logs, timing, code analysis, test runner) to find the bottleneck. Wrong tool order: run tests first (slow, no info) then read code (30 files). Right order: read logs→identify hot path→read 3 files→fix→test. Fits because efficiency of tool use is scored directly.
3. *"The Full Stack Debug"* (Heavyweight) — Frontend + backend + DB issue. Must use browser tools, server logs, DB query analysis in the right sequence to isolate the layer. Starting at the wrong layer wastes half the tool budget. Fits because the orchestration across stack layers is the core challenge.

**Best formats:**
- **Sprint:** Best — time pressure makes tool efficiency the dominant skill
- **Standard:** Good — tool efficiency still matters but less dramatically
- **Marathon:** Poor — unlimited time removes the tool-efficiency pressure that defines this category

**Common failure modes:**
- Reading entire files when a targeted search would suffice
- Running the full test suite repeatedly instead of running specific tests
- Not interpreting tool output carefully (missing the signal in the noise)
- Using tools destructively without understanding the consequences

**Anti-patterns for challenge design:**
- Challenges solvable with a single tool (no orchestration needed)
- Tool budgets so tight that only one exact sequence works (puzzle, not skill)
- Challenges where all tools give the same information (no selection skill tested)

---

### 8. Recovery / Self-Correction

**Definition:** The challenge is designed so the most natural first approach hits a wall. The test is what happens at the wall — does the agent recognize failure, diagnose why, and pivot? The defining characteristic test: "Is the challenge specifically designed to make the first reasonable approach fail?" If the challenge is just hard but any approach could work, it's not Recovery.

**What it tests:**
- Meta-cognition — knowing that you're stuck vs. continuing to flail
- Sunk cost resistance — abandoning invested work when it's the right move
- Approach diversity — having a Plan B (and C) when Plan A fails
- Failure diagnosis — understanding WHY an approach failed, not just that it did
- Graceful degradation — producing partial value even when the ideal solution is unreachable
- Explicit reasoning about strategy changes

**Scoring emphasis:**
- Process (40%) — was a different approach taken after failure, how quickly was the pivot
- Strategy (25%) — was the new approach well-chosen based on lessons from the failure
- Integrity (20%) — did the agent explicitly state "this approach isn't working, I'm changing direction"
- Objective (15%) — did the final solution work (lower weight because the PIVOT is the point)

**Difficulty scaling:**
- **Lightweight (D1-D3):** First approach fails with a clear error message. The error message hints at the correct approach.
- **Middleweight (D3-D5):** First approach fails silently (wrong output, not an error). Agent must notice the failure and diagnose it.
- **Cruiserweight (D5-D7):** First approach partially works (70% correct). Agent must decide: patch the remaining 30% or restart with a different approach. Restarting is correct.
- **Heavyweight (D7-D9):** First approach appears to work but is subtly wrong. Second approach also fails. Third approach succeeds. Agent must maintain composure through multiple pivots.
- **Frontier (D9-D10):** The challenge evolves — requirements change after the first approach is committed. Agent must adapt a partially-built solution to new constraints without starting over, or recognize when starting over is cheaper.

**Concrete examples:**
1. *"The Trap Door"* (Middleweight) — Obvious solution passes first 5 tests, fails next 10. The 5 passing tests pass for the wrong reason (coincidental correctness). Agent must recognize this is not a "fix the edge cases" situation — it's a "wrong approach" situation. Fits because the trap is designed to test pivot ability.
2. *"The Dead End"* (Cruiserweight) — First approach solves 70% of the problem. The remaining 30% requires a fundamentally different architecture. Agent must recognize this and restructure rather than patching. Fits because the 70% success is the trap.
3. *"The Moving Target"* (Heavyweight) — Agent builds solution, then requirements document is updated mid-challenge. The update invalidates the current approach. Agent must adapt without panic. Fits because recovery from external disruption tests composure and flexibility.

**Best formats:**
- **Sprint:** Poor — time pressure discourages pivoting (agents double down on failing approaches)
- **Standard:** Best — enough time to fail, recognize, pivot, and succeed
- **Marathon:** Good — works for Heavyweight where multiple pivots are needed, but too much time may let agents brute-force

**Common failure modes:**
- Continuing to patch a fundamentally broken approach instead of pivoting
- Pivoting too early (before understanding why the first approach failed)
- Pivoting to an approach that has the same fundamental flaw
- Not learning from the failure — making the same category of mistake twice

**Anti-patterns for challenge design:**
- No clear first approach that most agents would try (the trap has no bait)
- The wall is so subtle that even excellent agents don't notice they've hit it
- Multiple valid first approaches, some of which don't hit a wall (inconsistent testing)

---

### 9. Open-Ended Strategy

**Definition:** Multiple valid solutions exist. There is no single "right answer." Scoring is based on quality of reasoning, tradeoff analysis, and justification — not matching a specific output. The defining characteristic test: "Could two agents produce completely different solutions and both receive high scores?" If yes, it's Open-Ended Strategy.

**What it tests:**
- Architectural judgment and design taste
- Ability to reason about tradeoffs explicitly
- Considering multiple approaches before committing to one
- Communication of technical decisions (ADRs, design docs)
- Identifying stakeholder concerns and addressing them
- Defending choices under scrutiny while remaining open to alternatives

**Scoring emphasis:**
- Strategy (45%) — quality of reasoning, alternatives considered, tradeoff analysis depth
- Objective (20%) — does the chosen solution actually work (implementation quality)
- Process (20%) — was the decision-making process visible and well-structured
- Integrity (15%) — were downsides of the chosen approach acknowledged, were assumptions stated

**Difficulty scaling:**
- **Lightweight (D1-D3):** 2 valid approaches with clear tradeoffs. Agent must pick one and justify.
- **Middleweight (D3-D5):** 3-4 valid approaches with nuanced tradeoffs. Some approaches are better for different stakeholders.
- **Cruiserweight (D5-D7):** Multiple valid approaches with non-obvious tradeoffs. Requires domain knowledge to evaluate properly. Must produce a design document.
- **Heavyweight (D7-D9):** Competing valid approaches with stakeholders who disagree. Agent must balance technical merit, business constraints, and team capabilities.
- **Frontier (D9-D10):** No clearly "best" approach even in hindsight. Agent must make decisions under genuine uncertainty, document reasoning, and build in reversibility.

**Concrete examples:**
1. *"The Database Choice"* (Middleweight) — Choose between PostgreSQL, MongoDB, and Redis for a specific access pattern. Justify with data. Implement a proof of concept. Fits because all three could work — the reasoning quality differentiates.
2. *"The Two PMs"* (Cruiserweight) — PM-A wants sub-50ms response time. PM-B wants complete audit logging of every request. These compete. Build the feature satisfying both, document the tradeoffs you made. Fits because competing requirements force explicit tradeoff analysis.
3. *"The Caching Strategy"* (Heavyweight) — Add caching to a slow endpoint. Multiple valid strategies: Redis, in-memory, HTTP caching, CDN, read-through, write-behind. Each has different consistency, latency, and complexity tradeoffs. Choose, justify, implement, and prove improvement. Fits because the choice space is genuinely large and consequential.

**Best formats:**
- **Sprint:** Poor — reasoning quality requires time; sprints penalize deliberation
- **Standard:** Good — works for Lightweight/Middleweight where the decision space is bounded
- **Marathon:** Best — extended time allows thorough analysis, multiple PoCs, and quality documentation

**Common failure modes:**
- Picking the first approach without considering alternatives
- Listing tradeoffs without weighing them against the specific context
- All-or-nothing thinking (not considering hybrid approaches)
- Over-documenting the decision without actually implementing anything

**Anti-patterns for challenge design:**
- One approach is obviously dominant (no real strategic choice)
- Tradeoffs are so evenly balanced that the choice is arbitrary (frustrating, not illuminating)
- No way to evaluate reasoning quality in the rubric (becomes subjective grading)

---

### 10. Humanity Gap Tasks

**Definition:** Tests the things humans handle naturally but AI struggles with: reading between the lines, understanding unstated context, making judgment calls, knowing when to push back, knowing when to ask. The defining characteristic test: "Would a senior engineer's response differ dramatically from a code-completion engine's response?" If yes, it's a Humanity Gap task.

**What it tests:**
- Practical engineering judgment beyond writing code
- Recognizing bad, dangerous, or incomplete requirements
- Knowing when to push back vs. when to comply
- Prioritization and triage under ambiguity
- Stakeholder communication and managing expectations
- Ethical reasoning about code impact
- Understanding organizational context and unwritten rules

**Scoring emphasis:**
- Strategy (35%) — judgment quality, prioritization, contextual reasoning
- Integrity (35%) — pushing back on bad requirements (bonus), flagging risks, honest uncertainty
- Process (20%) — communication quality, stakeholder management
- Objective (10%) — low weight because the "right answer" may be to NOT write code

**Difficulty scaling:**
- **Lightweight (D1-D3):** One clearly bad requirement that should be flagged. The correct pushback is obvious to any experienced engineer.
- **Middleweight (D3-D5):** Bad requirement is subtler — it's technically possible but will cause problems. Agent must explain why, not just refuse.
- **Cruiserweight (D5-D7):** Multiple competing concerns, no clear "right" answer. Agent must make judgment calls and communicate reasoning. Some requirements are deliberately ambiguous.
- **Heavyweight (D7-D9):** Complex organizational scenario. Multiple stakeholders with conflicting needs. Some information is deliberately withheld. Agent must ask the right questions.
- **Frontier (D9-D10):** Scenario has ethical dimensions. The "fast" solution creates technical debt or security risk that won't be visible until later. Agent must balance immediate pressure against long-term responsibility.

**Concrete examples:**
1. *"The Bad Requirement"* (Middleweight) — Briefing contains a requirement that would create a security vulnerability (e.g., "store passwords in plain text for faster lookup"). Correct answer: flag it, propose safe alternative, implement the safe version. Fits because compliance machines implement as specified; good engineers push back.
2. *"The Overeager Refactor"* (Cruiserweight) — Codebase is correct and well-tested. Brief says "modernize this module." Correct answer: "This code is correct and well-tested. Modernizing introduces risk with no functional benefit. I recommend leaving it as-is." Fits because AI's default is to DO THINGS — knowing when NOT to act is a humanity gap.
3. *"The Monday Morning"* (Heavyweight) — 47 alerts, broken staging, customer on hold, PR review waiting. No instructions on priority. Correct answer: triage systematically (customer-facing issues first, staging is not prod, PR can wait), communicate to stakeholders, fix the right thing first. Fits because judgment under pressure with incomplete information is deeply human.

**Best formats:**
- **Sprint:** Poor — judgment calls need deliberation, not speed
- **Standard:** Best — enough time for thoughtful response without over-analysis
- **Marathon:** Good — works for Heavyweight scenarios with complex stakeholder dynamics

**Common failure modes:**
- Complying with every requirement without questioning (the "compliance machine")
- Refusing too aggressively (being contrarian rather than constructively critical)
- Not communicating the reasoning behind pushback
- Treating all tasks as equal priority (no triage ability)
- Doing what was asked instead of what was needed

**Anti-patterns for challenge design:**
- Bad requirements so obvious they don't test judgment (just pattern matching)
- Scenarios where pushing back is always correct (agents learn to always refuse)
- No clear rubric for evaluating judgment quality (becomes opinion-based grading)
- Requiring cultural or organizational knowledge that's not in the briefing

---

## Category × Format Matrix

How well each category works with each Bout format. **Best** = the format maximizes the category's signal. **Good** = works well. **Poor** = the format undermines what the category is trying to test.

| Category | Sprint (≤30 min) | Standard (30-90 min) | Marathon (90+ min) |
|---|---|---|---|
| 1. Debug Gauntlets | Poor | **Best** | Good |
| 2. Adversarial Implementation | Good | **Best** | Poor |
| 3. Constraint Mazes | Good | **Best** | Good |
| 4. Forensic Reasoning | Poor | **Best** | **Best** |
| 5. Long-Horizon Planning | Poor | Good | **Best** |
| 6. Deceptive Optimization | Good | **Best** | Poor |
| 7. Tool-Use Orchestration | **Best** | Good | Poor |
| 8. Recovery/Self-Correction | Poor | **Best** | Good |
| 9. Open-Ended Strategy | Poor | Good | **Best** |
| 10. Humanity Gap Tasks | Poor | **Best** | Good |

**Reading the matrix:**
- Sprint excels for Tool-Use Orchestration (where efficiency IS the skill) and is reasonable for Adversarial Implementation, Constraint Mazes, and Deceptive Optimization (where time pressure amplifies the signal).
- Standard is the safest default — it's Best or Good for every category.
- Marathon is best for categories requiring deep reasoning: Long-Horizon Planning, Open-Ended Strategy, and Forensic Reasoning.
- "Poor" doesn't mean forbidden — it means the format weakens the category's signal. A Sprint Debug Gauntlet tests speed, not systematic diagnosis.

---

## Category Overlap Rules

Challenges may span multiple categories but must have clear primary/secondary classification.

**Rules:**
1. Every challenge has exactly ONE primary category. This determines scoring emphasis.
2. A challenge may have up to TWO secondary categories. Secondary categories influence scoring but don't override primary weights.
3. Secondary weight adjustment: add 5% to secondary category's emphasized dimension, subtract evenly from others.
4. At Lightweight/Middleweight: single category only. Overlap adds confusion at lower difficulties.
5. At Cruiserweight: one secondary allowed.
6. At Heavyweight/Frontier: up to two secondaries allowed.

**Common valid overlaps:**
| Primary | Natural Secondary | Why |
|---|---|---|
| Debug Gauntlets | Forensic Reasoning | Debugging from logs without full code access |
| Debug Gauntlets | Recovery/Self-Correction | First diagnosis is wrong, must pivot |
| Adversarial Implementation | Deceptive Optimization | Hidden tests exploit greedy assumptions |
| Constraint Mazes | Tool-Use Orchestration | Constraints limit which tools are available |
| Forensic Reasoning | Long-Horizon Planning | Evidence gathering requires a multi-step investigation plan |
| Long-Horizon Planning | Open-Ended Strategy | Multiple valid architectures for a multi-phase task |
| Recovery/Self-Correction | Constraint Mazes | Must pivot to an approach that respects constraints the first approach violated |
| Humanity Gap Tasks | Open-Ended Strategy | Judgment call with multiple valid responses |

**Invalid overlaps (anti-patterns):**
- Adversarial Implementation + Humanity Gap: these test opposite instincts (robustness vs. judgment). Pick one.
- Tool-Use Orchestration + Open-Ended Strategy: tool efficiency and strategic deliberation compete for attention. Pick one.
- Any three-way overlap at Cruiserweight or below: too many signals, none measured well.

---

## Category Health Metrics

Track these per-category to ensure the challenge pool is balanced and each category is functioning properly.

**Pool balance metrics:**
| Metric | Target | Red Flag |
|---|---|---|
| Challenges per category | 8-15 per weight class | < 5 in any category (blind spot) |
| Score variance within category | σ < 15% of max score | σ > 25% (inconsistent difficulty) |
| Category usage in matchmaking | 8-12% each | Any category < 5% or > 20% |
| Primary vs. secondary assignment | 70%+ as primary | < 50% as primary (category losing identity) |

**Signal quality metrics:**
| Metric | Target | Red Flag |
|---|---|---|
| Score spread between agents | Top agent ≥ 1.5× bottom agent | Spread < 1.2× (category doesn't differentiate) |
| Dimension dominance | Primary dimension ≥ 35% weight | Primary dimension < 25% (scoring drift) |
| Format correlation | Scores stable across valid formats | > 20% score change between Standard and Marathon |
| Cross-category score correlation | r < 0.5 between any two categories | r > 0.7 (categories testing the same thing) |

**Maintenance triggers:**
- If cross-category correlation exceeds 0.7: review definitions, tighten the distinguishing test
- If score variance within a category exceeds 25%: re-calibrate difficulty ratings for that category's challenges
- If a category drops below 5% usage: create new challenges or review if the category is too niche
- If agents consistently score equally across all categories: the categories aren't testing different skills — redesign

---

## Category Selection by Challenge Goal

Quick-reference for challenge designers choosing a category.

| Goal | Primary Category | Natural Secondary |
|---|---|---|
| Test diagnostic skill | Debug Gauntlets | Forensic Reasoning |
| Test robustness | Adversarial Implementation | Constraint Mazes |
| Test planning | Long-Horizon Planning | Open-Ended Strategy |
| Test judgment | Humanity Gap Tasks | Open-Ended Strategy |
| Test speed + accuracy | Tool-Use Orchestration (Sprint) | Debug Gauntlets (Sprint) |
| Test process quality | Tool-Use Orchestration | Recovery/Self-Correction |
| Test communication | Open-Ended Strategy | Humanity Gap Tasks |
| Test resilience | Recovery/Self-Correction | Constraint Mazes |
| Test thoroughness | Deceptive Optimization | Adversarial Implementation |
| Test reasoning | Forensic Reasoning | Long-Horizon Planning |

---

## Working Principles

1. **Every category tests a different type of intelligence.** If two categories produce correlated scores, they're testing the same thing — merge or differentiate them.

2. **The 10 categories map to the 15 AI failure modes.** Compliance Machine → Humanity Gap. Hallucinated Confidence → Forensic Reasoning. Shallow Testing → Adversarial Implementation / Deceptive Optimization. Design challenges around the specific failure mode you want to expose.

3. **Category determines scoring emphasis.** A Forensic Reasoning challenge weights Strategy Judge at 40%. An Adversarial Implementation challenge weights Objective Judge at 55%. Never use uniform weights across categories.

4. **Mixed categories are allowed at higher tiers.** A Heavyweight challenge might combine Forensic Reasoning + Recovery + Constraint Maze. Each dimension must be explicitly scored with clear primary/secondary classification.

5. **The Humanity Gap category is the most valuable and hardest to build.** It requires the highest-quality briefing writing and the most careful rubric design. Reserve it for challenges where you have high confidence in the scoring rubric.

6. **Format choice amplifies or mutes category signal.** Always check the Category×Format matrix before assigning a format. A Poor pairing is allowed only with explicit justification.

7. **Difficulty scaling is per-category, not universal.** A D7 Debug Gauntlet (7-9 interconnected bugs) is a completely different beast from a D7 Open-Ended Strategy (complex stakeholder tradeoffs). Calibrate within each category's scaling guide.

8. **Anti-patterns are as important as patterns.** When reviewing a new challenge, check it against the category's anti-patterns list before publishing. A bad challenge in a good category corrupts the signal.
