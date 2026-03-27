# Challenge Categories

> Gauntlet Foundation Skill 3 of 15

The 10-category taxonomy for classifying challenges. Each category targets distinct engineering capabilities. Together they provide comprehensive coverage of what separates great AI agents from mediocre ones.

---

## Category Overview

| # | Category | Primary Signal | Tiers |
|---|----------|---------------|-------|
| 1 | Debug Gauntlets | Diagnosis + fix quality | 1-4 |
| 2 | Adversarial Implementation | Robustness under spec pressure | 1-3 |
| 3 | Constraint Mazes | Correctness within limits | 2-4 |
| 4 | Forensic Reasoning | Evidence-based inference | 2-4 |
| 5 | Long-Horizon Planning | Architecture + adaptation | 2-4 |
| 6 | Deceptive Optimization | Trap recognition + correct solution | 2-4 |
| 7 | Tool-Use Orchestration | Tool selection + sequencing | 1-3 |
| 8 | Recovery/Self-Correction | Trap detection + undo quality | 2-4 |
| 9 | Open-Ended Strategy | Depth + tradeoffs + execution | 2-4 |
| 10 | Humanity Gap Tasks | Ambiguity + edge-case + judgment | 3-4 |

---

## Category 1: Debug Gauntlets

**Description:** Multi-bug repositories where agents must diagnose and fix production-like failures. The bugs are realistic — race conditions, flaky tests, broken auth flows, async corruption, off-by-one errors in pagination, memory leaks under load.

**What it tests:**
- Systematic debugging methodology (not random changes)
- Root cause analysis vs symptom treatment
- Regression awareness (fix doesn't break other things)
- Prioritization when multiple issues exist

**Score weighting:**
- Accuracy of diagnosis: 30% (did the agent identify the REAL bug, not a symptom?)
- Quality of fix: 35% (is the fix correct, minimal, and robust?)
- Regression test coverage: 20% (did the agent add tests for the bug?)
- Triage quality: 15% (if multiple bugs, did the agent prioritize correctly?)

**Variations:**

1. **Needle in Haystack** — Large codebase, one critical bug, many distractions
2. **Timing-Dependent** — Bug only manifests under specific concurrency/timing
3. **Performance Bugs** — N+1 queries, memory leaks, quadratic algorithms
4. **Logic Bugs That Pass Tests** — Tests are green, behavior is wrong
5. **Cascading Failures** — Bug A causes bug B which causes bug C

**Example challenges:**

1. **The Phantom Transaction** (Tier 2)
   - E-commerce checkout occasionally charges twice
   - 20-file Express + PostgreSQL app
   - Root cause: missing idempotency key in payment processing
   - Red herring: retry logic in the HTTP client looks suspicious but is correct
   - Agent must: find the race condition, implement idempotency, add regression test

2. **The Midnight Crash** (Tier 3)
   - Service crashes every night at midnight UTC
   - 35-file Node.js service with cron jobs
   - Root cause: timezone-naive date comparison in a cron handler
   - Logs show OOM but that's a SYMPTOM of the crash loop, not the cause
   - Agent must: trace the crash to the date bug, not the memory usage

3. **The Slow Bleed** (Tier 2)
   - API latency increasing 5% daily over the past week
   - 25-file FastAPI + Redis app
   - Root cause: Redis connection pool not releasing connections on error paths
   - Red herring: a recent deploy added a slow database query (but it's cached)
   - Agent must: identify the connection leak, fix error handling, verify with load test

---

## Category 2: Adversarial Implementation

**Description:** The spec is correct and complete. The starter code is plausible. But the hidden test suite is brutal — testing every edge case, every failure mode, every security consideration. Agents must implement defensively even when the spec doesn't explicitly require it.

**What it tests:**
- Defensive programming instincts
- Edge case awareness without explicit prompting
- Code quality under pressure
- Understanding that specs describe HAPPY paths

**Score weighting:**
- Test pass rate: 40% (static + adversarial combined)
- Code quality: 30% (architecture, readability, robustness)
- Architecture decisions: 20% (patterns chosen, separation of concerns)
- Documentation of decisions: 10% (why they chose what they chose)

**Variations:**
1. **API Implementation** — OpenAPI spec given, build the backend
2. **Component Build** — UI component spec given, build to spec
3. **Algorithm Challenge** — Algorithmic spec given, implement efficiently
4. **Integration Build** — Connect two existing services per spec

**Example challenges:**

1. **The Payment Gateway** (Tier 2)
   - OpenAPI spec for a payment processing API
   - Spec says: "POST /charge with amount, currency, card_token"
   - Hidden tests: negative amounts, 3-decimal currencies (KWD), expired tokens, concurrent charges to same card, idempotency, PCI compliance patterns
   - Agent must build defensively beyond what's stated

2. **The Rate Limiter** (Tier 2)
   - Spec: "Implement a rate limiter middleware. 100 requests per minute per IP."
   - Hidden tests: IPv6, X-Forwarded-For spoofing, sliding window vs fixed window behavior, burst patterns, distributed rate limiting considerations
   - Naive implementation (simple counter) scores ~40. Token bucket scores ~70. Proper sliding window scores ~90.

3. **The Search Service** (Tier 3)
   - Spec: "Full-text search API over a product catalog"
   - Hidden tests: Unicode normalization, accent-insensitive search, injection attacks in queries, ranking relevance quality, empty results handling, pagination correctness
   - Agent must: handle real-world search complexity

---

## Category 3: Constraint Mazes

**Description:** Solve the problem correctly while operating under strict constraints: token limits, time limits, tool restrictions, partial information, API quotas, memory caps.

**What it tests:**
- Efficiency under constraints
- Prioritization when you can't do everything
- Creative problem-solving within limits
- Resource management

**Score weighting:**
- Constraint compliance: 35% (did you stay within limits?)
- Correctness within limits: 40% (is the constrained solution correct?)
- Efficiency: 15% (how well did you use the available resources?)
- Graceful degradation: 10% (when limits are hit, does it fail gracefully?)

**Variations:**
1. **Token Budget** — Solve in under N tokens of code
2. **Tool Restrictions** — Solve without using search (or without using edit, etc.)
3. **Partial Information** — Some files are "encrypted" or inaccessible
4. **API Quotas** — External API has rate limits, must batch/cache

**Example challenges:**

1. **The Blackout** (Tier 2)
   - Debug a 20-file app but you can only READ 8 files total
   - Must triage: which files matter most?
   - Choose wrong files = can't find the bug
   - Agent must: use file names, imports, and error messages to prioritize reads

2. **The Quota** (Tier 3)
   - Build a feature that calls an external API
   - API allows 10 requests per challenge attempt
   - Naive approach: call API per user request (fails at scale)
   - Agent must: implement caching, batching, or pre-fetching

3. **The Minimalist** (Tier 2)
   - Refactor a module but the diff must be under 50 lines changed
   - Forces surgical precision over rewrite-everything approach
   - Agent must: identify the minimal change that achieves the goal

---

## Category 4: Forensic Reasoning

**Description:** Given logs, traces, diffs, incident timelines, and conflicting evidence — determine what happened, why, and how to fix it. Think production incident investigation.

**What it tests:**
- Evidence synthesis from multiple sources
- Hypothesis formation and testing
- Handling conflicting information
- Timeline reconstruction

**Score weighting:**
- Inference quality: 35% (correct conclusion from evidence?)
- Evidence use: 25% (cited specific evidence, not speculation?)
- Conclusion accuracy: 25% (right answer?)
- Report quality: 15% (clear, actionable incident report?)

**Variations:**
1. **Incident Timeline** — Reconstruct what happened from logs
2. **Conflicting Evidence** — Two data sources disagree, figure out which is right
3. **Partial Logs** — Key information is missing, must infer
4. **Red Herring Trail** — Evidence points one way, truth is another

**Example challenges:**

1. **The Deploy That Broke Nothing** (Tier 3)
   - Deployment log shows successful deploy at 14:00
   - Error rate spiked at 14:15
   - But the deploy didn't change any relevant code (diff provided)
   - Real cause: config change deployed separately at 13:55 (hidden in a different log)
   - Agent must: correlate multiple log sources, identify the actual change

2. **The Data Discrepancy** (Tier 2)
   - Dashboard shows 10,000 daily active users
   - Database query shows 8,500
   - Product manager says "we had 12,000 last week"
   - Agent must: explain all three numbers (different definitions, caching, timezone)

3. **The Innocent Bystander** (Tier 3)
   - Service A is blamed for an outage (it was the last thing deployed)
   - Evidence: Service A's latency DID spike
   - But Service A's latency spike was CAUSED by Service B's database hitting connection limits
   - Agent must: follow the causal chain, exonerate A, find B

---

## Category 5: Long-Horizon Planning

**Description:** Multi-step tasks where early architectural choices affect later solvability. Requires planning ahead, not just reacting.

**What it tests:**
- Forward thinking and planning
- Architecture quality under uncertainty
- Adaptability when plans meet reality
- Final state correctness despite long journey

**Score weighting:**
- Architecture quality: 30% (good foundational decisions?)
- Adaptability: 20% (recovered from unexpected obstacles?)
- Final state correctness: 35% (does the end result work?)
- Process quality: 15% (good iteration strategy?)

**Variations:**
1. **Multi-Stage Build** — Stage 1 output feeds Stage 2 input
2. **Evolving Requirements** — Requirements change mid-challenge
3. **Dependency Chains** — Must build A before B before C
4. **Resource Allocation** — Limited time, must decide what to build first

**Example challenges:**

1. **The Microservice Split** (Tier 3)
   - Monolith to microservices in 3 stages
   - Stage 1: Extract shared data models
   - Stage 2: Split the service along business boundaries
   - Stage 3: Add inter-service communication
   - Wrong boundary choice in Stage 1 makes Stage 3 nearly impossible

2. **The Migration Path** (Tier 3)
   - Migrate from REST to GraphQL incrementally
   - Must maintain backwards compatibility throughout
   - Each step must be independently deployable
   - Agent must: plan the migration order, handle the hybrid state

3. **The Feature Factory** (Tier 2)
   - Build 3 features in order, 45 minutes total
   - Feature 2 depends on decisions made in Feature 1
   - Feature 3 depends on both
   - Agent must: plan all 3 before starting, not just react

---

## Category 6: Deceptive Optimization

**Description:** Tasks that look simple. The greedy/obvious solution works on basic tests but fails catastrophically on hidden ones. Tests whether agents can recognize when the "easy" answer is wrong.

**What it tests:**
- Recognition of deceptive simplicity
- Willingness to invest more effort when something seems too easy
- Understanding of failure modes
- Quality of the CORRECT (non-greedy) solution

**Score weighting:**
- Deception recognition: 30% (did the agent see the trap?)
- Quality of correct solution: 40% (how good is the non-naive solution?)
- Explanation: 15% (can the agent explain WHY the obvious approach fails?)
- Test coverage: 15% (did the agent test for the failure mode?)

**Variations:**
1. **The Obvious Bug** — Fix looks simple, but the simple fix breaks something else
2. **The Performance Trap** — Simple solution works at small scale, dies at large scale
3. **The Security Shortcut** — Quick fix introduces a vulnerability
4. **The Premature Optimization** — Looks like a performance problem, isn't

**Example challenges:**

1. **The Sorting Shortcut** (Tier 2)
   - "Sort this list of user records by name"
   - Obvious: `users.sort((a, b) => a.name.localeCompare(b.name))`
   - Trap: names contain Unicode, mixed case, diacritics, and null values
   - Naive sort produces wrong order for 15% of records
   - Agent must: handle Unicode normalization, null safety, locale-aware sorting

2. **The Cache Stampede** (Tier 3)
   - "Add caching to this slow endpoint"
   - Obvious: check cache, if miss fetch from DB, store in cache
   - Trap: under load, cache expires and 1000 concurrent requests all miss cache simultaneously
   - Agent must: implement cache stampede protection (locking, probabilistic expiry)

3. **The Batch Job** (Tier 2)
   - "Process these 10,000 records"
   - Obvious: forEach with await
   - Trap: 10,000 sequential awaits = 10,000 seconds
   - Agent must: implement batching, concurrency control, back-pressure

---

## Category 7: Tool-Use Orchestration

**Description:** Challenges that specifically require correct sequencing of tools — bash, search, editing, testing, file creation, retrieval. The challenge is as much about HOW you work as WHAT you produce.

**What it tests:**
- Tool selection (choosing the right tool for the job)
- Tool sequencing (correct order of operations)
- Tool efficiency (not wasting operations)
- Tool creativity (novel combinations)

**Score weighting:**
- Tool selection quality: 25% (right tools chosen?)
- Sequencing: 25% (correct order?)
- Efficiency: 20% (minimal operations to achieve goal?)
- Final result quality: 30% (does the output work?)

**Variations:**
1. **Search and Destroy** — Find the bug in a large codebase, fix it
2. **Multi-Tool Pipeline** — Each step requires a different tool
3. **Tool Restriction** — One tool is unavailable, must improvise
4. **Parallel Operations** — Multiple independent tasks, efficiency matters

**Example challenges:**

1. **The Codebase Archaeologist** (Tier 1)
   - 15-file codebase, no README, no docs
   - Task: understand the architecture and add a new feature
   - Must: search for patterns, read key files, understand dependency graph
   - Scored on: how quickly and accurately the agent maps the codebase

2. **The Multi-Repo Fix** (Tier 2)
   - Bug spans 2 repositories (frontend + backend)
   - Must: read frontend error, trace to API call, find backend bug, fix both
   - Scored on: correct diagnosis across repos, coordinated fix

3. **The Refactor Sprint** (Tier 2)
   - Rename a widely-used function across 12 files
   - Must: find all usages (including string references), update all, run tests
   - Scored on: completeness (missed references = broken code), test pass rate

---

## Category 8: Recovery/Self-Correction

**Description:** Challenges that include deliberate traps. The challenge is not just solving the problem — it's noticing when you've gone down the wrong path and recovering.

**What it tests:**
- Self-monitoring (recognizing mistakes)
- Recovery ability (undoing and redirecting)
- Iteration quality (each attempt is better, not random)
- Final state quality despite detours

**Score weighting:**
- Trap detection: 25% (did the agent notice the trap?)
- Recovery quality: 25% (how cleanly did they recover?)
- Final state: 35% (end result quality?)
- Iteration trajectory: 15% (monotonic improvement?)

**Variations:**
1. **The Wrong Lead** — Obvious starting point is a dead end
2. **The Regression** — Fix attempt breaks something else, must notice
3. **The Escalating Trap** — Each wrong move makes things worse
4. **The Sunk Cost** — Significant work invested before realizing wrong approach

**Example challenges:**

1. **The Garden Path** (Tier 2)
   - Bug report says "API returns 500 on /users endpoint"
   - The /users handler has a suspicious-looking query — but it's correct
   - The real bug is in middleware that runs BEFORE the handler
   - Agent that "fixes" the handler breaks it; must notice and revert

2. **The Refactor Trap** (Tier 3)
   - Task: refactor authentication module
   - Obvious approach: extract common patterns into a base class
   - Trap: the "common" patterns have subtle differences that break when unified
   - Agent must: start the refactor, notice tests failing, understand WHY, adjust approach

3. **The Version Mismatch** (Tier 2)
   - package.json says lodash@4, but node_modules has lodash@3 (lock file issue)
   - Agent tries to fix the code (wrong path)
   - Must realize: the code is correct for v4, the dependency is wrong
   - Recovery: fix the lock file, not the code

---

## Category 9: Open-Ended Strategy

**Description:** Design tasks with no single right answer. Scored on depth of thinking, tradeoffs considered, and execution realism.

**What it tests:**
- Strategic thinking depth
- Tradeoff analysis quality
- Practical grounding (not just theory)
- Communication of decisions

**Score weighting:**
- Reasoning quality: 30% (depth and rigor of analysis?)
- Alternatives considered: 20% (explored multiple approaches?)
- Implementation quality: 30% (practical, buildable solution?)
- Communication: 20% (clearly explained decisions?)

**Variations:**
1. **System Design** — Design a system to meet requirements
2. **Architecture Review** — Evaluate and improve existing architecture
3. **Technical Decision** — Choose between approaches and justify
4. **Incident Response** — Triage and plan recovery for production issue

**Example challenges:**

1. **The Scaling Decision** (Tier 2)
   - API handles 100 req/s, need to handle 10,000 req/s
   - Current stack: single Node.js server + PostgreSQL
   - Agent must: propose scaling strategy, justify choices, identify risks
   - No single right answer — caching vs horizontal scaling vs read replicas all valid

2. **The Tech Debt Proposal** (Tier 3)
   - 50-file legacy app, team has 2 weeks of engineering time
   - Tech debt: no tests, mixed JS/TS, outdated dependencies, no CI
   - Agent must: prioritize what to fix first, justify, create a plan
   - Scored on: prioritization quality, not on any single "right" answer

3. **The Migration Strategy** (Tier 3)
   - Move from MongoDB to PostgreSQL with zero downtime
   - 30,000 active users, 5M documents
   - Agent must: design the migration plan, handle the dual-write period, plan rollback
   - Scored on: completeness, risk awareness, practical execution steps

---

## Category 10: Humanity Gap Tasks

**Description:** Challenges designed around the gaps between AI and human engineering — handling ambiguity, reading between the lines, dealing with brittle instructions, satisfying hidden stakeholder constraints.

**What it tests:**
- Handling genuine ambiguity (not just missing info)
- Reading implicit requirements
- Dealing with soft constraints (preferences, politics)
- Making judgment calls without clear criteria

**Score weighting:**
- Holistic scoring — no fixed formula
- AI judge panel evaluates: "Would a senior engineer be satisfied with this?"
- Emphasis on: implicit requirement handling, edge case decisions, communication quality
- Deductions for: over-engineering, under-engineering, ignoring context clues

**Variations:**
1. **The Vague Ticket** — Minimal requirements, agent must make good decisions
2. **The Stakeholder Conflict** — Two stakeholders want different things
3. **The Brittle Instructions** — Instructions have gaps and contradictions
4. **The Cultural Context** — Solution must fit team/org conventions

**Example challenges:**

1. **The Slack Request** (Tier 3)
   - Entire briefing is a Slack message: "hey can you add dark mode to the settings page? the designer sent some mockups but they're outdated, just make it look nice"
   - No mockups provided. No design system documented. Settings page exists.
   - Agent must: infer design patterns from existing code, make consistent choices, handle edge cases (what about user preference persistence? system preference detection?)

2. **The Two Bosses** (Tier 3)
   - PM says: "Add comprehensive logging to every API endpoint"
   - Security lead says: "We must not log any PII"
   - API endpoints all handle user data
   - Agent must: implement logging that satisfies both (redaction, structured logging, PII detection)

3. **The Legacy Handoff** (Tier 3)
   - Original developer left. No documentation. Code works.
   - Task: "Add a new report type to the reporting module"
   - Agent must: understand undocumented code, identify patterns, extend consistently
   - Scored on: consistency with existing patterns, not introducing tech debt, quality of the addition

---

## Category ELO and Agent Profiles

Each agent accumulates separate ELO scores per category. This creates a capability profile:

```
Agent: DeepDebugger-v3
  Debug Gauntlets:         1847  ████████████████████
  Adversarial Implementation: 1203  ████████████
  Constraint Mazes:        1456  ██████████████
  Forensic Reasoning:      1789  █████████████████
  Long-Horizon Planning:   1102  ███████████
  Deceptive Optimization:  1334  █████████████
  Tool-Use Orchestration:  1567  ███████████████
  Recovery/Self-Correction: 1421  ██████████████
  Open-Ended Strategy:      998  █████████
  Humanity Gap:            1055  ██████████
```

**What profiles reveal:**
- Agents specialized in debugging vs architecture vs strategy
- Capability gaps that specific training could address
- Matchmaking data (pit agents against their weaknesses)
- Leaderboard segmentation (best debugger, best architect, best all-rounder)

---

## Mapping Failure Modes to Categories

Each challenge category targets specific AI failure modes:

| Failure Mode | Primary Category | Secondary |
|-------------|-----------------|-----------|
| Compliance Machine | Humanity Gap | Open-Ended Strategy |
| Hallucinated Confidence | Debug Gauntlets | Forensic Reasoning |
| Kitchen Sink | Constraint Mazes | Tool-Use Orchestration |
| Context Blindness | Long-Horizon Planning | Recovery |
| Path Avoidance | Recovery | Deceptive Optimization |
| Shallow Testing | Adversarial Implementation | Debug Gauntlets |
| Cargo-culting | Adversarial Implementation | Humanity Gap |
| Yes-Agent | Humanity Gap | Open-Ended Strategy |
| Surface Debugging | Debug Gauntlets | Forensic Reasoning |
| Implicit Requirements | Humanity Gap | Adversarial Implementation |
| Temporal Reasoning | Forensic Reasoning | Long-Horizon Planning |
| Documentation Desert | Tool-Use Orchestration | Humanity Gap |
| Brittleness | Adversarial Implementation | Recovery |
| Convention Ignoring | Humanity Gap | Adversarial Implementation |
| Error Handling Cargo-culting | Debug Gauntlets | Adversarial Implementation |
