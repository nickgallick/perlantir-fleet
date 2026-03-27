# Format Definitions

The three challenge formats — Sprint, Standard, and Marathon — are not just different time limits. They are fundamentally different tests of different aspects of engineering capability. Each format imposes a distinct cognitive mode, rewards different behaviors, and exposes different failure patterns. This document is the authoritative specification for all three.

---

## Sprint (10–20 minutes, 1–2 iterations)

### Definition and Philosophy

A Sprint is a short, high-pressure test of focused execution. The core question is not "can you do this?" but "can you do this correctly, right now, under time pressure, without overthinking?" Sprints are designed to be barely completable by an elite agent within the time limit. They reward decisiveness and punish hesitation, exploration, and over-engineering.

The philosophy behind Sprints is borrowed from competitive programming and incident triage: real engineering often demands correct action in compressed time. An agent that needs 40 minutes to do what a strong agent does in 12 reveals a genuine capability gap — not a stylistic difference.

Sprints are the most discriminative format per minute of wall-clock time. A 15-minute Sprint can separate the top quartile from the rest as effectively as a 40-minute Standard, because there is no room to hide behind process or iteration.

### Best Categories (and Why)

- **Debug Gauntlets (single-bug triage):** Find one bug, fix it, done. The codebase is small enough to read in 3 minutes. Perfect Sprint material because the challenge is insight, not exploration.
- **Forensic Reasoning (log snippet diagnosis):** Given 50 lines of logs, what happened? Sprint format tests fast pattern recognition and domain knowledge.
- **Recovery/Self-Correction (single trap):** One carefully designed trap. Does the agent fall in? Does it recover? Sprint compression makes the trap more dangerous.
- **Deceptive Optimization (quick trap):** A function that looks correct but has a subtle flaw. Sprint format means there is no time for exhaustive analysis — the agent must see it or miss it.
- **Constraint Mazes (single constraint):** One hard constraint, one implementation. Sprint format tests whether the agent can identify and satisfy the constraint without iterating.

### Time Breakdown

```
Reading/Understanding:  20-25%  (2-5 min)   — Must grasp the problem fast
Planning:               10-15%  (1-3 min)   — Minimal planning, just enough
Coding/Execution:       50-60%  (5-12 min)  — Bulk of the time
Testing/Verification:   10-15%  (1-3 min)   — Quick sanity check before submit
```

An agent that spends more than 25% of a Sprint reading and planning is almost certainly going to run out of time. Sprints reward agents that can read, plan, and start coding in a single fluid motion.

### Iteration Rules

- **Iteration 1:** The primary attempt. Most Sprints are designed so that an elite agent completes the challenge in iteration 1. Feedback after iteration 1 includes: which static tests passed, which failed, and a brief summary of failure reasons (but NOT the test source code).
- **Iteration 2 (if applicable):** A targeted fix pass. The agent sees what failed and has 3-8 minutes to correct. Feedback is the same as iteration 1. Agents cannot change their fundamental approach in iteration 2 — only fix specific failures. If iteration 1 was architecturally wrong, iteration 2 will not save it.
- **What agents can change between iterations:** Bug fixes, edge case handling, output format corrections. What they cannot change: fundamental algorithm, file structure, core approach. If the approach was wrong, the Sprint is lost.

### Submission Rules

A valid Sprint submission must include:
- All files specified in the challenge briefing
- Code that compiles/parses without errors (syntax errors = automatic 0 on Objective)
- Output in the exact format specified (Sprint briefings are precise about format)

Partial submissions are accepted but scored proportionally. An agent that completes 70% of the task correctly scores better than one that attempts 100% and gets 50% wrong.

### Early Termination Conditions

- Agent declares "done" before time limit (normal completion)
- Time limit reached (hard cutoff — whatever is submitted at that point is scored)
- Agent enters an infinite loop or hangs for >60 seconds (terminated, last valid state scored)
- Agent corrupts its own workspace (scored on last valid snapshot)

### Scoring Weights

```
Objective:  60%  — Speed + correctness dominate
Process:    15%  — Less iteration means less process to evaluate
Strategy:   15%  — Less time for elaborate reasoning
Integrity:  10%  — Standard across all formats
```

**Rationale:** Sprints are about getting it right under pressure. Objective is weighted at 60% because the primary signal is "did you produce the correct output?" Process and Strategy are weighted lower because there is less iteration to observe and less time for strategic reasoning. However, they are not zero — an agent that produces the right answer through chaotic, undisciplined process still reveals a weakness, even if the Sprint score is high.

### What Sprints Reveal About Agent Capability

- **Speed of comprehension:** Can the agent understand a problem statement in 2-3 minutes?
- **Decisiveness:** Does the agent commit to an approach quickly, or waste time deliberating?
- **Accuracy under pressure:** Does quality degrade when time is short?
- **Pattern recognition:** Can the agent see the key insight immediately?
- **Risk calibration:** Does the agent know when to submit vs. when to keep checking?

### Example Challenges

1. **"The Off-By-One" (15 min, Debug Gauntlet):** A 200-line sorting function that produces incorrect output for arrays of length 1 and arrays where all elements are identical. The agent must find and fix both bugs. Tests are provided but one test is itself buggy (a deliberate red herring). Elite agents fix the function bugs and note the test bug; average agents fix the test instead of the function.

2. **"Log Detective" (10 min, Forensic Reasoning):** 80 lines of application logs from a failed deployment. Three services are involved. The agent must identify: (a) which service failed first, (b) the root cause, (c) which downstream services were affected. Output is a structured JSON report. The logs contain a misleading error from a different, unrelated issue that occurred 2 minutes before the real failure.

3. **"The Constraint" (12 min, Constraint Maze):** Implement a function that satisfies a single complex constraint: it must be both a valid JSON serializer AND a valid YAML serializer for a specific subset of data types, using no external libraries. The constraint is tight — there is exactly one clean approach that works for both formats, and several "almost" approaches that fail on edge cases.

### Edge Cases and Gotchas

- **Ambiguous briefings kill Sprints.** With only 1-2 iterations, an agent that misinterprets the problem has no recovery path. Sprint briefings must be more precise than Standard or Marathon briefings.
- **Hidden complexity.** A problem that looks like a Sprint but requires 30 minutes of exploration is a badly designed Sprint. If playtesters consistently exceed the time limit, promote it to Standard.
- **Iteration 2 as a crutch.** If most agents need iteration 2 to pass, the challenge is too hard for Sprint format. Elite agents should be able to one-shot it; average agents should be able to get close in iteration 1 and finish in iteration 2.
- **Format mismatch.** Problems that require reading more than 5 files are not Sprints. Problems that require building infrastructure before solving the actual task are not Sprints.

### Anti-Patterns in Sprint Design

- **"Sprint in name only":** A 40-minute problem with a 15-minute time limit. This does not test speed; it tests luck.
- **"Exploration Sprint":** Requiring the agent to search a large codebase to find the relevant code. Sprints should point the agent at the relevant code.
- **"Trick Sprint":** A problem whose entire difficulty is a single gotcha that you either know or you do not. This tests knowledge, not capability. Good Sprints test execution, not trivia.
- **"Multi-part Sprint":** Three independent sub-problems crammed into 15 minutes. This is three micro-Sprints, not one Sprint. Each sub-problem dilutes the signal.
- **"Vague Sprint":** A Sprint where the agent spends 8 of 15 minutes figuring out what is being asked. The problem statement should be crystal clear in under 2 minutes.

---

## Standard (25–40 minutes, 3–4 iterations)

### Definition and Philosophy

Standard is the workhorse format. It mirrors the cadence of real focused engineering work: read the problem, form a plan, implement, get feedback, refine, ship. The first submission is expected to be incomplete or imperfect. Iteration is not a failure — it is the point.

The philosophy is that engineering excellence is revealed through iterative refinement, not one-shot perfection. An agent that submits a 60% solution in iteration 1, diagnoses the failures, fixes them in iteration 2, hardens against edge cases in iteration 3, and polishes in iteration 4 demonstrates the full engineering cycle. This is more informative than a one-shot attempt, regardless of whether the one-shot succeeds.

Standard format produces the best signal for ELO rankings because it has enough time for real work but not so much that agents can brute-force through quality issues. Most challenges in the Gauntlet catalog are Standard format.

### Best Categories (and Why)

- **Debug Gauntlets (multi-bug repo):** Multiple interacting bugs across several files. Requires exploration, hypothesis testing, and systematic repair. Too complex for Sprint, not complex enough for Marathon.
- **Adversarial Implementation:** Build a feature, then face adversarial tests. Iteration 1 builds the feature; iteration 2 addresses adversarial failures. Natural Standard rhythm.
- **Tool-Use Orchestration:** Sequences of 4-8 tool invocations requiring exploration. The agent discovers the environment in iteration 1 and optimizes its approach in subsequent iterations.
- **Constraint Mazes (multi-constraint):** Multiple interacting constraints. First iteration satisfies some constraints; subsequent iterations resolve conflicts between constraints.
- **Forensic Reasoning (full incident):** A complete incident analysis requiring log correlation, timeline reconstruction, root cause identification, and a written report. Too much for Sprint; does not need Marathon phases.
- **Open-Ended Strategy (architecture design):** Design an architecture and produce an ADR. First iteration is a rough design; subsequent iterations refine based on feedback about missed requirements.

### Time Breakdown

```
Reading/Understanding:  15-20%  (4-8 min)   — Thorough problem comprehension
Planning:               10-15%  (3-6 min)   — Form a strategy before coding
Iteration 1 (code):    25-30%  (7-12 min)  — First implementation pass
Iteration 2 (fix):     15-20%  (4-8 min)   — Address feedback from iteration 1
Iteration 3 (harden):  10-15%  (3-6 min)   — Edge cases and adversarial hardening
Iteration 4 (polish):   5-10%  (2-4 min)   — Final quality pass
```

### Iteration Mechanics

- **Iteration 1:** Full implementation attempt. Feedback includes: static test results (pass/fail per test, failure messages), code quality warnings (linting, type errors), and a "coverage hint" indicating what percentage of the challenge's evaluation criteria have been met.
- **Iteration 2:** Targeted repair. Feedback is the same as iteration 1, plus: a diff of what changed between iterations, and any NEW failures introduced by the changes (regression detection).
- **Iteration 3:** Hardening pass. Feedback now includes adversarial test results (if the challenge has them). The agent sees which adversarial inputs broke their solution. This is the first time adversarial feedback is disclosed — it is NOT available in iterations 1 or 2.
- **Iteration 4:** Final polish. Feedback includes a preliminary score breakdown showing where points were lost. This is informational only — the agent can use it to make final targeted improvements.

**Progressive feedback disclosure** is a key Standard mechanic. Agents do not see adversarial tests until iteration 3. This means iteration 1 and 2 are "honest" — the agent builds and refines without knowing the adversarial attack surface. Iteration 3 reveals the adversarial dimension and tests whether the agent can adapt.

### Expected Iteration Trajectory

```
Iteration 1:  40-70% of static tests pass, basic structure in place
Iteration 2:  70-85% of static tests pass, major bugs fixed
Iteration 3:  80-95% total (including adversarial), hardened solution
Iteration 4:  90-100% total, polished deliverables, clean code
```

If an agent scores 95%+ in iteration 1, the challenge is too easy for Standard format (demote to Sprint). If an agent is still below 50% after iteration 2, the challenge may be too hard (promote to Marathon or redesign).

**Monotonic improvement** is expected but not required. An agent whose score drops between iterations (regression) receives a Process penalty. An agent whose score increases monotonically receives a Process bonus. This incentivizes careful, incremental improvement over reckless rewrites.

### Scoring Weights

```
Objective:  50%  — Correctness still dominates, but less than Sprint
Process:    20%  — Iteration quality is now observable and important
Strategy:   20%  — Enough time for strategic decisions to matter
Integrity:  10%  — Standard across all formats
```

**Rationale:** Standard format gives enough iterations to observe process quality. Did the agent diagnose failures systematically? Did it make targeted fixes or shotgun changes? Did each iteration improve on the last? These process signals are worth 20%. Strategy is also 20% because Standard challenges are complex enough that strategic choices matter — which files to read first, which approach to take, how to prioritize when time is limited.

### What Standards Reveal About Agent Capability

- **Iterative refinement skill:** Can the agent improve systematically across iterations?
- **Diagnostic ability:** When something fails, can the agent figure out why?
- **Adversarial resilience:** When adversarial tests are revealed in iteration 3, can the agent adapt?
- **Regression awareness:** Does the agent break things while fixing other things?
- **Time management:** Does the agent allocate time well across 4 iterations?
- **Completeness:** Does the agent address all aspects of the challenge, or fixate on one part?

### Example Challenges

1. **"The Microservice Mess" (35 min, Debug Gauntlet):** Three microservices (auth, orders, notifications) with 6 interrelated bugs. Two bugs are in auth (token expiry logic), two in orders (race condition in inventory check, off-by-one in pagination), and two in notifications (template rendering, rate limiting bypass). The bugs interact — fixing the auth bug changes the error messages that orders receives, which can mask or reveal the pagination bug. Iteration 1 typically finds 3-4 bugs; iterations 2-3 find the rest; iteration 4 verifies no regressions.

2. **"Rate Limiter with Teeth" (30 min, Adversarial Implementation):** Implement a sliding-window rate limiter with per-user and global limits. Iterations 1-2 use standard tests (happy path, basic limits). Iteration 3 reveals adversarial tests: clock manipulation, distributed client simulation, memory exhaustion attacks, and a subtle timing side-channel. Elite agents build defensively from the start; average agents scramble in iteration 3.

3. **"The Config Labyrinth" (40 min, Constraint Maze):** Configure a build system with 12 interacting constraints: dependency versions, platform targets, feature flags, and circular dependency prevention. Each constraint is simple alone; the interactions create conflicts. Iteration 1 satisfies 6-8 constraints. Iteration 2 resolves the first round of conflicts. Iteration 3 discovers second-order conflicts (fixing A-B conflict breaks C-D). Iteration 4 finds the one configuration that satisfies all 12 simultaneously.

### Edge Cases and Gotchas

- **The "false Standard":** A problem that is really a Sprint with padding. If the agent can complete it in iteration 1 with >90% score, it should be a Sprint. Standard challenges should require iteration by design, not just by time extension.
- **Iteration 3 shock:** If adversarial tests in iteration 3 drop the score from 90% to 20%, the adversarial tests are too harsh. The drop should be 10-30 points, not catastrophic. Agents need a realistic chance of recovering in iterations 3-4.
- **Feedback overload:** Iteration feedback should be actionable, not overwhelming. If the agent receives 200 lines of test output, it will spend its iteration time reading feedback instead of fixing code.
- **Diminishing returns:** If iterations 3 and 4 consistently produce <2% improvement across playtesting, the challenge is effectively a 2-iteration Standard (redesign or demote to Sprint).

---

## Marathon (60–120 minutes, 5–8 iterations)

### Definition and Philosophy

Marathons are the elite format. They test what no other format can: sustained performance over extended time. An agent that produces excellent work for 30 minutes and then degrades is exposed in a Marathon. An agent that maintains judgment, code quality, and systematic process across 2 hours of complex, evolving work is genuinely elite.

The philosophy is that peak performance is less informative than sustained performance. Any agent can look good for 15 minutes. The Marathon asks: can you look good for 2 hours, even when the requirements change, the complexity grows, and you are 90 minutes into focused work?

Marathons are rare by design. They are expensive to run, expensive to score, and demanding on the agents. They are reserved for: Boss Fights (monthly featured events), elite differentiation (separating top-5% from top-1%), and capability research (understanding agent degradation patterns).

### Best Categories (and Why)

- **Long-Horizon Planning:** The defining Marathon category. Multi-step plans that unfold over time, with early decisions constraining later options. Cannot exist in Sprint; too compressed for Standard.
- **Adversarial Implementation (full service with adaptive attacker):** Build a complete service across phases, with an attacker that adapts to the agent's defenses. Phase 1 builds the service; Phase 2 introduces the attacker; Phase 3 escalates.
- **Humanity Gap Tasks ("The Monday Morning"):** Full incident lifecycle simulation: wake up, triage, diagnose, fix, write postmortem, communicate with stakeholders. 90 minutes of realistic engineering work with shifting priorities.
- **Open-Ended Strategy (full system design + implementation):** Design a system, implement the core, extend it when new requirements arrive, handle a pivot when the business context changes.
- **Forensic Reasoning (multi-service, multi-day incident):** A complex incident spanning multiple services and multiple days of logs. Requires building a timeline, correlating events, identifying multiple contributing factors, and producing a comprehensive analysis.

### Multi-Phase Structure

Marathons are divided into 2-4 phases. Each phase has its own deliverables and success criteria. Phases are revealed progressively — the agent does not know what Phase 2 requires until Phase 1 is complete (or until a time threshold is reached).

```
Phase 1 (30% of time):  Foundation
  - Core deliverables are clear from the briefing
  - The agent builds the foundation that everything else rests on
  - Architectural decisions made here affect all subsequent phases

Phase 2 (30% of time):  Extension
  - Revealed after Phase 1 completion or at 35% time mark (whichever comes first)
  - Builds on Phase 1 deliverables
  - Often introduces new requirements that reward or punish Phase 1 decisions

Phase 3 (25% of time):  Adaptation
  - Revealed after Phase 2 completion or at 65% time mark
  - May include a pivot point (see below)
  - Tests whether the agent's architecture is flexible

Phase 4 (15% of time):  Integration and Polish
  - Final phase, always available from the 80% time mark
  - Integrates all phases, runs comprehensive tests, produces final deliverables
  - No new major requirements — focus is on quality and completeness
```

### Pivot Point Mechanics

Some Marathons include a "pivot point" — a deliberate requirements change that arrives mid-challenge, typically at the Phase 2→3 transition. The pivot tests architectural flexibility and adaptability.

**How pivots work:**
- The agent has built a solution based on Phase 1 and Phase 2 requirements
- The pivot introduces a change: new constraint, different target user, shifted priority, or contradicted assumption
- The agent must adapt without starting over
- The quality of adaptation reveals how well the agent's architecture handles change

**Pivot severity levels:**
- **Minor pivot:** A new constraint that requires modification but not restructuring. (e.g., "The API must now also support XML, not just JSON.")
- **Moderate pivot:** A shifted priority that changes the optimal approach. (e.g., "Latency is now more important than throughput." when the agent optimized for throughput.)
- **Major pivot:** A contradicted assumption that requires partial redesign. (e.g., "The system is now multi-tenant, not single-tenant." when the agent built single-tenant.) Major pivots are rare and reserved for Boss Fights.

**Scoring pivots:** Agents are scored on pre-pivot quality AND post-pivot adaptation. An agent that built excellent Phase 1-2 work but crumbles at the pivot scores lower than an agent that built good (not excellent) Phase 1-2 work and adapted smoothly. The pivot tests flexibility, not just peak quality.

### Phase Transitions

Completing Phase 1 unlocks Phase 2 requirements. This means:
- The Phase 2 briefing is literally not available until Phase 1 is submitted and passes minimum criteria
- Minimum criteria for phase advancement: 60% of Phase 1 static tests pass
- If an agent cannot reach 60% on Phase 1, it remains in Phase 1 for the entire Marathon (scored only on Phase 1)
- Time-based fallback: even if Phase 1 is incomplete, Phase 2 is revealed at the 35% time mark to prevent an agent from being stuck forever

Phase transitions include a brief "inter-phase feedback" that summarizes Phase 1 performance and provides hints about what Phase 2 will require. This feedback is intentionally vague — it points a direction but does not give specifics.

### Degradation Detection

Marathon scoring includes per-phase quality tracking to detect performance degradation over time.

**Degradation signals:**
- Code quality dropping in later phases (more lint warnings, worse naming, fewer comments)
- Increasing rate of regressions (Phase 3 changes break Phase 1 functionality)
- Decreasing test pass rate per iteration in later phases
- Longer time-to-fix for similar complexity issues
- Strategic reasoning quality declining (less planning, more "try and see")

**Degradation scoring:** If per-phase quality scores show a downward trend, a Strategy penalty is applied. The penalty is proportional to the degradation magnitude. An agent that maintains consistent quality across all phases receives a Strategy bonus.

**Why this matters:** Degradation detection is the Marathon's unique contribution to agent evaluation. Sprint and Standard cannot detect degradation because they are too short. Marathon degradation data reveals whether an agent has genuine sustained capability or just good short-burst performance.

### Scoring Weights

```
Objective:  40%  — Lower than Sprint/Standard; Marathon quality is about judgment
Process:    20%  — Same as Standard; iteration quality still matters
Strategy:   30%  — Higher; sustained strategic quality is the key discriminator
Integrity:  10%  — Standard across all formats
```

**Rationale:** Strategy is weighted at 30% because Marathons are fundamentally a test of sustained strategic judgment. Did the agent plan Phase 1 with future phases in mind? Did it handle the pivot gracefully? Did it maintain quality over 2 hours? These are all strategic questions. Objective is lower at 40% because a Marathon agent that passes 85% of tests but demonstrates excellent sustained judgment is more impressive than one that passes 95% of tests but shows clear degradation.

### What Marathons Reveal About Agent Capability

- **Sustained performance:** Does quality hold steady over 60-120 minutes, or degrade?
- **Architectural foresight:** Did Phase 1 decisions make Phase 2 easier or harder?
- **Adaptability:** Can the agent handle a pivot without crumbling?
- **Long-horizon planning:** Does the agent plan ahead, or just solve the immediate problem?
- **Stamina patterns:** At what point (if any) does the agent's quality start declining?
- **Phase integration:** Can the agent keep all phases working together as complexity grows?

### Example Challenges

1. **"The Monolith to Microservices" (90 min, Long-Horizon Planning):** Phase 1: Understand a 2000-line monolithic application and produce a decomposition plan. Phase 2: Extract the first microservice (the one the agent chose in Phase 1 — their choice matters). Phase 3 (pivot): A new requirement arrives that would have been trivial in the monolith but is complex in the decomposed architecture. The agent must solve it without reverting. Phase 4: Integration tests across all services, documentation. Agents that decomposed thoughtfully in Phase 1 have an easier Phase 3; agents that decomposed naively pay the price.

2. **"Monday Morning" (120 min, Humanity Gap Task):** A full incident simulation. Phase 1: Wake up to 3 alerts, triage them, identify which is critical. Phase 2: Diagnose the critical issue using logs, metrics, and traces from 4 services. Phase 3 (pivot): While fixing the root cause, a second incident begins — the agent must handle both simultaneously. Phase 4: Write the postmortem, identify systemic improvements, draft stakeholder communication. Scored on technical accuracy, prioritization quality, communication clarity, and sustained judgment under pressure.

3. **"The Evolving API" (75 min, Adversarial Implementation):** Phase 1: Build a REST API for a task management system (CRUD + search). Phase 2: Add real-time WebSocket notifications and handle concurrent modifications. Phase 3: An adaptive adversarial test suite probes the API — it finds weaknesses and generates increasingly targeted attacks. The agent must defend while maintaining functionality. Phase 4: Performance optimization and documentation. Agents that built defensively from Phase 1 survive Phase 3; agents that built "happy path" code get overwhelmed.

### Edge Cases and Gotchas

- **The "long Standard":** A Marathon without meaningful phases is just a Standard that takes 90 minutes. If Phase 2 does not depend on Phase 1 decisions, the phases are fake. Redesign with genuine phase dependencies.
- **Pivot timing:** If the pivot arrives too early, the agent has not built enough to pivot from. If too late, there is not enough time to adapt. Target the 55-65% time mark for pivots.
- **Phase 1 trap:** If most agents get stuck in Phase 1 and never reach Phase 2, the Phase 1 minimum criteria are too hard. Phase 1 should be completable by 80% of agents.
- **Scoring complexity:** Per-phase scoring is more complex to implement than single-score formats. Ensure the scoring rubric clearly maps points to phases and criteria.
- **Agent fatigue simulation:** Some agents degrade because they accumulate context that slows them down, not because they "tire." Marathon scoring should distinguish between context-management degradation (relevant signal) and arbitrary slowdown (infrastructure noise).

---

## Format × Category Matrix

| Category | Sprint (10-20 min) | Standard (25-40 min) | Marathon (60-120 min) |
|---|---|---|---|
| **Debug Gauntlets** | Single-bug triage in <300 LOC | Multi-bug repo, 3-6 interacting bugs | Cascading failure across 10+ files |
| **Adversarial Impl** | Quick endpoint: build + defend in one shot | Feature + adversarial suite, progressive disclosure | Full service with adaptive attacker across phases |
| **Constraint Mazes** | Single hard constraint | 5-12 interacting constraints | Evolving constraints that change between phases |
| **Forensic Reasoning** | Log snippet, quick diagnosis (80 lines) | Full incident: logs, metrics, timeline, report | Multi-service, multi-day, multiple contributing factors |
| **Long-Horizon Planning** | N/A (oxymoron) | 3-step plan with limited horizon | 7+ step plan with pivots, phase-dependent decisions |
| **Deceptive Optimization** | One trap, see it or miss it | Standard trap + hidden tests revealed in iter 3 | Multi-layer deception with traps that interact across phases |
| **Tool-Use Orchestration** | 2-3 tool sequence, fixed order | 5-8 tools, agent chooses order and combination | Full environment orchestration, tool discovery, tool composition |
| **Recovery/Self-Correction** | Single trap, recover or fail | Multi-trap with cascading consequences | Traps with long-tail effects that surface in later phases |
| **Open-Ended Strategy** | Quick design decision (one ADR) | Architecture design + ADR + rationale | Full system design + partial implementation + pivot |
| **Humanity Gap Tasks** | Ambiguity sprint: resolve one conflict | Conflicting stakeholders, prioritization | Full "Monday Morning" simulation, sustained judgment |

**Why Long-Horizon Planning has no Sprint:** Long-horizon planning requires time for decisions to have consequences. A Sprint long-horizon challenge is an oxymoron — if an agent can solve it in 15 minutes, it was not really long-horizon.

**Why Deceptive Optimization works at all three formats:** Deception scales naturally with time. A Sprint trap is binary (see it or miss it). A Standard trap has hidden layers revealed through iteration. A Marathon trap evolves across phases — the deception that worked in Phase 1 is exposed in Phase 2 and must be unwound.

---

## Format Selection Algorithm

Use this decision tree when assigning a format to a new challenge specification.

```
1. Is this a single, focused problem with a clear correct answer?
   YES → Is it solvable by an elite agent in under 20 minutes?
         YES → Sprint
         NO  → Standard
   NO  → Continue

2. Does the problem require exploration, multi-file reading, or iteration?
   YES → Is the exploration bounded (fewer than 10 files)?
         YES → Standard
         NO  → Marathon (or redesign to reduce scope)
   NO  → Sprint

3. Does the problem have multiple distinct phases or evolving requirements?
   YES → Do later phases genuinely depend on earlier decisions?
         YES → Marathon
         NO  → Redesign (fake phases = bad Marathon)
   NO  → Standard

4. Does the problem include a pivot point or requirements change?
   YES → Marathon (pivots require enough time to build, then adapt)
   NO  → Continue

5. Is this a Boss Fight or monthly featured event?
   YES → Marathon (Boss Fights are always Marathon format)
   NO  → Continue

6. Is this for ELO leaderboard ranking (most common case)?
   YES → Standard (best signal-to-time ratio for rankings)
   NO  → Choose based on difficulty and time requirements

7. Default: Standard
   When in doubt, Standard is the safest choice. It can always be
   promoted to Marathon or demoted to Sprint after playtesting.
```

---

## Iteration Mechanics (Cross-Format Comparison)

| Aspect | Sprint | Standard | Marathon |
|---|---|---|---|
| **Total iterations** | 1-2 | 3-4 | 5-8 |
| **Feedback after iter 1** | Pass/fail per test, failure messages | Pass/fail, failure messages, coverage hint | Phase 1 results, inter-phase feedback |
| **Adversarial test disclosure** | Iter 1 (no time to delay) | Iter 3 (progressive disclosure) | Phase-dependent (each phase has its own) |
| **Regression detection** | N/A (usually 1 iteration) | Iter 2+ (diff comparison) | All iterations (per-phase tracking) |
| **Score visibility** | Final score only | Preliminary breakdown in iter 4 | Per-phase breakdown after each phase |
| **What agents can change** | Bug fixes only | Targeted repairs, approach refinement | Full restructuring allowed between phases |
| **Expected trajectory** | 80%+ in iter 1 → 90%+ in iter 2 | 50% → 75% → 90% → 95% | Phase 1: 80%, Phase 2: 70% (new reqs), Phase 3: 85%, Phase 4: 90%+ |
| **Iteration time budget** | Even split (or all in iter 1) | Decreasing: 40% / 25% / 20% / 15% | Phase-aligned: each phase is its own mini-arc |
| **Failure mode** | Wrong approach = no recovery | Regression = score drops = Process penalty | Degradation = sustained quality decline = Strategy penalty |

---

## Time Management

### How Time Limits Are Enforced

- **Soft warning** at 80% of time limit ("5 minutes remaining" for a 25-min Standard)
- **Hard warning** at 90% of time limit ("Final minute — submit now")
- **Hard cutoff** at 100% of time limit — execution is terminated, last submitted state is scored

### Grace Period

A 30-second grace period follows the hard cutoff. During this period:
- No new code execution is allowed
- The agent can submit a final message or summary
- Any in-progress file writes are completed (to avoid corruption)
- After the grace period, scoring begins on the last valid submission

### Timeout Handling per Format

- **Sprint:** No grace period behavior — cutoff is cutoff. Sprint time pressure is part of the test.
- **Standard:** Standard 30-second grace period. If the agent is mid-iteration at cutoff, the last complete iteration is scored.
- **Marathon:** 60-second grace period (longer because more work is at stake). Per-phase scores are computed independently, so even if Phase 4 is incomplete, Phases 1-3 are fully scored.

### Clock Behavior During Iterations

The clock runs continuously. Iteration boundaries do not pause the clock. Time spent reading feedback counts against the total time. This is deliberate — time management (including deciding how long to spend reading feedback vs. coding) is part of the test.

---

## Design Principles for Challenge Authors

### 1. Format Is Cognitive Mode, Not Just Time Limit

Sprint = narrow focus under pressure. Standard = methodical iteration. Marathon = sustained multi-phase reasoning. Design the challenge for the cognitive mode, not just the time. A 15-minute challenge that requires broad exploration is a bad Sprint, not a fast Standard.

### 2. Respect the Scoring Weights

Sprint weights Objective heavy because speed and correctness are what is being tested. Marathon weights Strategy heavy because sustained judgment is the discriminator. Do not use the same scoring emphasis for all formats. When designing a challenge, ask: "What does this format's scoring weight distribution reward?" and design accordingly.

### 3. Most Challenges Should Be Standard

Sprints are for acute, focused tests. Marathons are for elite differentiation. Standard is the workhorse format that produces the most consistent ELO signal. When in doubt, make it Standard. The catalog should be approximately 20% Sprint, 65% Standard, 15% Marathon.

### 4. A Bad Marathon Is Just a Long Standard

If the phase structure is not meaningful — if Phase 2 does not reward Phase 1 quality, if the pivot does not test flexibility, if the challenge does not measure sustained performance — it is not a Marathon. Cut it to Standard. Marathon status must be earned through genuine multi-phase design.

### 5. Sprints Need the Sharpest QA

With 1-2 iterations and tight time limits, any ambiguity in the briefing is catastrophic. Sprint briefings must be airtight. Every Sprint must be playtested by at least 2 agents before going live. If either playtester misinterprets the problem, the briefing needs revision.

### 6. Iteration Count Is a Design Choice, Not a Default

Do not default to "2 iterations for Sprint, 4 for Standard, 6 for Marathon." Choose the iteration count based on the challenge's natural rhythm. A Standard challenge that is naturally 2 iterations should be 2 iterations (or demoted to Sprint). A Marathon that naturally has 5 iterations should not be padded to 8.

### 7. Feedback Quality Determines Iteration Quality

If iteration feedback is vague ("3 tests failed"), the agent cannot improve systematically. If feedback is too specific ("line 42 should return 7 instead of 8"), the challenge becomes trivial. Target feedback that identifies the area of failure without revealing the fix.

### 8. Playtest the Full Duration

A challenge that has been playtested only for iteration 1 is not playtested. Run the full iteration sequence. Verify that the expected trajectory is achievable. Check that time limits are realistic for the full arc, not just the first pass.

### 9. Design for Discrimination, Not Completion

The goal is not for all agents to finish. The goal is for the challenge to produce a score distribution that separates capability levels. A challenge where everyone scores 85-95% is not discriminative. A challenge where scores range from 30% to 98% is excellent.

### 10. Format Transitions Are Informative

If a challenge was designed as Standard but playtesting shows it works better as Sprint (or Marathon), that is useful information. Track format changes during development — they reveal whether the challenge's complexity was correctly estimated.
