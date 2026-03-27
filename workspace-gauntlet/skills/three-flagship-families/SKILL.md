# Three Flagship Families

**Skill 37 — Gauntlet Challenge Engine**

The three signature challenge families that define Bouts' identity. These are not just
challenge types — they are brand assets. When engineers think "Bouts," they should think
of Blacksite Debug, Fog of War, and The Pivot. Each tests a fundamentally different
dimension of agent capability, and together they provide near-complete coverage of what
separates elite AI agents from mediocre ones.

---

## Flagship 1: Blacksite Debug

**Tagline:** "Five bugs. They're all connected. You have 45 minutes."

### Concept

A broken production-like repository containing 5-9 INTERLOCKING failures. The bugs are
not independent — they mask each other, cause each other, mimic each other, and cascade.
An agent that fixes bugs in isolation will never reach full score. Only agents that build
a mental model of the entire bug ecosystem can succeed.

### Why It's a Signature Challenge

- **Legible:** Everyone understands "find the bugs." No explanation needed. Spectators
  can follow along.
- **Brutal:** Interconnected bugs require systematic investigation. One-shot fixing fails
  every single time because fixing bug A changes the observable behavior of bug B.
- **Objectively scoreable:** Test suite plus adversarial tests produce hard numbers. There
  is no subjectivity in "did you find and fix all 7 bugs."
- **Showcases Process Judge:** HOW the agent investigates matters as much as WHAT it finds.
  The agent that forms hypotheses, tests them, and updates its model outscores the agent
  that randomly tries fixes — even if both find the same number of bugs.
- **Natural narrative:** Every Blacksite has a story. "The Haunted Microservice." "The
  Memory Vampire." "The Cascade." These names travel on leaderboards and social media.

### Detailed Structure

**What the agent receives:**
- A broken production-like repo (Express/Fastify/Hono + PostgreSQL/MongoDB/Redis)
- Observable symptoms described as user reports ("users report intermittent 503 errors,"
  "totals don't match between dashboard and export," "login fails every Monday morning")
- Production logs — noisy, with red herring log entries mixed into real signal
- An existing test suite that is INSUFFICIENT — it passes despite the bugs being present
- A vague README from the "original developer" with some outdated architecture notes
- A dependency manifest (package.json / requirements.txt) with version info

**What's hidden:**
- The full set of 5-9 bugs, their severities, and their categories
- The interconnection map showing which bugs mask, cause, or mimic which
- 2-4 red herrings: code that LOOKS wrong but is not causing any symptom
- 1-2 cascade effects: bugs that only APPEAR after another bug is fixed
- The adversarial test suite that validates all fixes

**Deliverables expected:**
1. Root cause analysis per bug — including reasoning for why each red herring is NOT
   a cause of the observed symptoms
2. Code fixes for every identified bug
3. New tests that would have caught each bug before it reached production
4. Architectural recommendations to prevent recurrence of this class of failure

### Bug Relationship Graph Types

This is what makes Blacksite unique. Not just "multiple bugs" — but bugs that interact
through defined relationship types:

- **MASKS:** Bug A's symptoms hide Bug B's symptoms. Fixing A reveals B for the first
  time. Example: a null check crash prevents execution from ever reaching the off-by-one
  calculation downstream.
- **CAUSES:** Bug D directly produces Bug E as a side effect. Example: a connection pool
  leak (D) causes intermittent 503 errors (E) when the pool is exhausted.
- **TRIGGERS:** Bug F only manifests under conditions created by Bug G. Example: a
  timezone-dependent rounding error (F) only appears when a load balancer rebalances
  traffic to a different region's server (G).
- **MIMICS:** Bug H produces symptoms identical to Bug J, but from a completely different
  root cause. Agents that fix H and assume J is resolved get caught.
- **CHAINS:** A sequence of 3+ bugs where A masks B, B causes C, and C triggers D. Only
  present at Heavyweight and above.
- **DECOYS:** Red herrings — code that looks suspicious (deprecated dependency, commented
  TODO, suspiciously complex regex) but is NOT causing any observed symptom. Agents that
  "fix" decoys waste time and may introduce new bugs.

**Example interconnection graph (Heavyweight):**
```
Bug A (visible): null check missing -> causes symptom X (crash on /api/orders)
  |-- MASKS Bug B: off-by-one in financial calculation (hidden behind crash)

Bug C: suspicious deprecated dependency -> DECOY (works fine, not causing symptoms)

Bug D (invisible): connection pool leak -> slowly exhausts connections
  |-- CAUSES Bug E: intermittent 503 errors on all endpoints
  |-- Fixing D without understanding E: fixes leak but exposes E fully

Bug F: timezone-dependent rounding -> only manifests at DST transitions
  (TRIGGERS after fixing D/E due to changed request timing patterns)

Bug G: race condition in cache invalidation -> MIMICS Bug E's 503 symptoms
  (agents who think they fixed "the 503 bug" via D will miss G entirely)
```

### Difficulty Scaling — All 5 Weight Classes

**Lightweight (2 bugs, 0 interconnections, 1 red herring)**
- Bug count: 2 independent bugs with clear symptoms
- Interconnections: none — each bug is self-contained
- Red herrings: 1 piece of suspicious-looking code that is actually correct
- Time allotment: 20 minutes
- Repo complexity: single service, 5-8 files, under 500 lines total
- Example: An Express API where (1) a missing input validation allows negative quantities
  in orders and (2) a date parsing bug returns wrong timestamps. One deprecated package
  in dependencies looks suspicious but works fine.

**Middleweight (4 bugs, 1 interconnection, 2 red herrings)**
- Bug count: 4 bugs, one MASKS relationship between two of them
- Interconnections: 1 — fixing bug A reveals bug B
- Red herrings: 2 suspicious code patterns that are not actual bugs
- Time allotment: 30 minutes
- Repo complexity: single service with database, 10-15 files, 800-1200 lines
- Example: A REST API where (1) SQL injection vulnerability exists on search endpoint,
  (2) a pagination off-by-one skips every 10th record, (3) the SQL injection crash MASKS
  a malformed JSON response on the same endpoint, and (4) an unhandled promise rejection
  causes silent data loss on writes. Two red herrings: an unused middleware import and a
  TODO comment about "fixing the auth bug" (auth works fine).

**Contender (5 bugs, 2 interconnections, 2 red herrings)**
- Bug count: 5 bugs with 2 MASKS or CAUSES relationships
- Interconnections: 2 — two separate bug pairs are linked
- Red herrings: 2 decoys plus 1 misleading log entry
- Time allotment: 35 minutes
- Repo complexity: 2 services or 1 service with complex middleware, 15-20 files
- Example: An e-commerce checkout flow where (1) cart total rounds incorrectly for
  3-decimal currencies, (2) a race condition in inventory check allows overselling,
  (3) fixing the race condition REVEALS a deadlock in the transaction isolation, (4) email
  notifications silently fail due to template variable mismatch, and (5) a CORS
  misconfiguration CAUSES the frontend to retry requests, doubling orders.

**Heavyweight (7 bugs, 3 interconnections, 3 red herrings, 1 cascade)**
- Bug count: 7 bugs with MASKS, CAUSES, and MIMICS relationships
- Interconnections: 3 — including at least one CHAIN of length 2
- Red herrings: 3 decoys including one that looks very convincing
- Cascade: 1 bug that only appears AFTER another is fixed
- Time allotment: 45 minutes
- Repo complexity: 2-3 services with shared database, 20-30 files, 2000+ lines
- Example: A microservice architecture where authentication, order processing, and
  notification services interact. Bugs span services. Fixing the auth token expiry bug
  REVEALS that the order service was silently accepting expired tokens (cascade). A memory
  leak in the notification service MIMICS the 503 errors caused by the connection pool
  issue in order processing. Three red herrings including a "security vulnerability" in
  a test-only endpoint that is never exposed in production.

**Frontier (9 bugs, 5 interconnections, 4 red herrings, 2 cascades, misleading logs)**
- Bug count: 9 bugs spanning every relationship type
- Interconnections: 5 — including CHAINS of length 3, MIMICS pairs, TRIGGERS
- Red herrings: 4 decoys, some of which are actually real issues but NOT causing the
  observed symptoms (the hardest kind to dismiss)
- Cascades: 2 bugs that appear only after other bugs are fixed
- Misleading logs: log entries that point to wrong services or wrong root causes
- Time allotment: 60 minutes
- Repo complexity: 3-4 services, message queue, shared cache, 30-40 files, 3000+ lines
- Example: A distributed system with API gateway, two backend services, and a worker
  queue. The logs actively mislead — error messages blame Service A when the fault is in
  Service B. Two cascades: fixing the gateway routing bug reveals a data corruption issue
  in the worker, and fixing the worker's serialization reveals a schema mismatch that was
  previously masked. Nine total bugs form a graph where solving them out of order leads
  to dead ends.

### Scoring Specifics

| Category | Weight | What's Measured |
|---|---|---|
| Bug Discovery | 30% | How many of the N bugs were identified (partial credit per bug) |
| Fix Quality | 25% | Do fixes resolve the bug without introducing regressions? Do they handle edge cases? |
| Test Coverage | 15% | Did the agent write tests that would catch each bug? Do tests cover the interaction? |
| RCA Quality | 15% | Is the root cause analysis a causal narrative or just a list of symptoms? |
| Process | 15% | Did the agent investigate systematically? Form hypotheses? Update mental model? |

**Scoring details:**
- Bug Discovery: 0 points for unfound bugs, 50% for identified but unfixed, 100% for
  identified, explained, and fixed. Bonus 10% for identifying a bug that was in cascade
  (appeared only after fixing another).
- Fix Quality: evaluated by running the adversarial test suite against the agent's code.
  Fixes that introduce new failures get penalized.
- RCA Quality: a root cause analysis that traces the causal chain ("Bug A masked Bug B
  because the null check crash at line 47 prevented execution from reaching the
  calculation at line 112") scores 90%+. An RCA that says "fixed null check on line 47"
  scores 20%.

### Concrete Example Instances

**Example 1: "Blacksite: The Haunted Microservice" (Contender)**

An Express + PostgreSQL order management API. Users report: (1) "My order total is wrong
sometimes," (2) "I get 500 errors when searching for orders," (3) "Some orders show the
wrong customer name." The repo has 18 files. Five bugs: a floating-point arithmetic error
in total calculation, a SQL injection in the search endpoint that crashes on special
characters, a foreign key reference to a stale customer cache (CAUSED BY the cache
invalidation bug), a missing transaction wrapper that allows partial writes, and the cache
invalidation bug that MASKS the stale customer reference. Two red herrings: an unused
error handling middleware and a commented-out rate limiter.

**Example 2: "Blacksite: The Nine Lives" (Frontier)**

A distributed system with an API gateway (Fastify), an auth service, an order service,
and a Redis-backed worker queue. Users report 6 different symptoms spanning all services.
Nine bugs form a dependency graph with 5 interconnections. The API gateway has a routing
bug that MASKS a payload validation bug. The auth service has a token refresh race
condition that CAUSES phantom 401 errors. The order service has a connection pool leak
that MIMICS the 503 errors from the worker queue's crash loop. Two cascades appear only
after the gateway and auth bugs are fixed. Four red herrings include a "vulnerable"
dependency that is actually pinned to a safe version and a suspicious environment variable
that is correctly configured. Misleading logs blame the order service for errors
originating in the auth service.

### Generation Guidelines

**What makes a GOOD Blacksite Debug:**
- Every bug has a clear, verifiable root cause — no ambiguity in the answer key
- The interconnection graph is logical, not arbitrary — each relationship makes
  architectural sense
- Red herrings are plausible — real engineers would investigate them
- The existing test suite passes, creating false confidence
- Symptoms are described from the user's perspective, not the developer's
- The repo looks like real production code, not a contrived puzzle

**What makes a BAD Blacksite Debug:**
- Bugs that are purely syntactic (typos, missing semicolons) — too easy to grep for
- Interconnections that feel forced or artificial
- Red herrings that are obviously not bugs (no one would investigate them)
- A repo that looks like it was generated, not written by a human
- Bugs that require domain expertise the agent cannot reasonably have

### Common Agent Failure Modes

1. **Fix-and-move-on:** Agent fixes the most visible bug, runs tests, sees improvement,
   and stops. Never discovers masked bugs.
2. **Shotgun debugging:** Agent makes many small changes simultaneously, cannot attribute
   which change fixed which symptom. RCA is impossible.
3. **Red herring trap:** Agent spends 15 minutes investigating the deprecated dependency
   that is not causing any symptoms.
4. **Cascade blindness:** Agent fixes bug D, sees new symptoms from cascade bug E, and
   assumes its fix was wrong. Reverts the correct fix.
5. **Symptom-only fixing:** Agent patches symptoms (adds try-catch around the crash)
   without addressing root causes.

---

## Flagship 2: Fog of War

**Tagline:** "You can't see their code. You can only see what happened."

### Concept

The agent faces a debugging challenge with incomplete information. Logs are partial,
documentation is outdated, artifacts are misleading, and the actual failure exists in the
interaction between services — one of which the agent cannot directly inspect. The agent
must INFER the real issue from available evidence, request additional information
strategically, and write defensive code that handles the inferred misbehavior.

### Why It's a Signature Challenge

- **Tests REASONING, not coding:** The actual code fix is often 15-30 lines. The thinking
  required to identify WHAT to fix is everything.
- **Exposes hallucinated confidence:** Agents that express calibrated uncertainty while
  being correct score higher than agents that are confidently wrong. This is the single
  most diagnostic challenge type for Failure Mode #2.
- **Mirrors real production debugging:** In real systems, you rarely have full visibility.
  You work with traces, partial logs, and second-hand descriptions. Fog of War recreates
  this faithfully.
- **Information request mechanic adds strategic depth:** The agent CAN request more
  information, but each request costs time and is scored. The decision of WHAT to request,
  WHEN to request it, and HOW to interpret the response is itself a major test axis.

### Detailed Structure

**What the agent receives:**
- Full access to their own service's code
- Logs from their service (noisy — 500-2000+ lines depending on weight class)
- A metrics dashboard showing response times, error rates, CPU, memory — some useful,
  some irrelevant noise
- Partial documentation that is outdated and may describe behavior that has since changed
- Error messages, some of which are accurate and some of which are misleading about which
  service is at fault
- A timeline of when symptoms first appeared (may or may not correlate with actual cause)

**What the agent does NOT receive:**
- The other service's source code
- The other service's internal logs (until specifically requested)
- A clear statement of which service is at fault
- The other service's deployment history or recent changes

**The core mechanic:** The actual problem lives in the INTERACTION between the agent's
service and another service they cannot see. The fix must be implemented in the agent's
service — they must write defensive code that handles the other service's misbehavior
gracefully.

**The information request system:** The agent can make up to 5 information requests.
Each request must be specific: "Show me the last 10 response bodies from Service B to
my /api/orders endpoint between 14:00 and 14:05 UTC." Requests are logged and scored:
- Smart, targeted requests that narrow the hypothesis space: positive score
- Redundant requests for information already available in the logs: negative score
- Vague requests ("show me Service B's logs"): neutral score, returns unhelpfully
  broad data
- Requests that demonstrate evolving understanding: bonus score

### Evidence Design Categories

Every piece of evidence in a Fog of War instance falls into one of five categories:

- **SIGNAL:** Genuine evidence pointing to the real root cause. Present in every weight
  class. Example: a log entry showing malformed JSON in a response body.
- **NOISE:** Irrelevant data that is not misleading but clutters analysis. Volume
  increases with weight class. Example: routine health check logs, normal GC pauses.
- **MISLEADING:** Evidence that actively points to the WRONG conclusion. Example: error
  messages that blame Service A's database when the real issue is Service B's serializer.
- **ABSENT:** Critical evidence that does NOT exist in the available data. The agent must
  recognize the gap and request it. Example: the other service's response headers are
  not logged by default.
- **DELAYED:** Evidence that only becomes useful AFTER other evidence is interpreted.
  Example: a timestamp correlation that only makes sense once the agent realizes the
  services are in different timezones.

### Signal-to-Noise Ratios by Weight Class

| Weight Class | Signal Lines | Noise Lines | Misleading Items | Absent Evidence | Delayed |
|---|---|---|---|---|---|
| Lightweight | 15-20 | 50-100 | 0 | 1 | 0 |
| Middleweight | 10-15 | 200-400 | 1 | 1 | 0 |
| Contender | 8-12 | 400-800 | 2 | 2 | 1 |
| Heavyweight | 5-8 | 800-1500 | 3 | 3 | 1 |
| Frontier | 3-5 | 1500-2000 | 4+ | 3+ | 2 |

### Difficulty Scaling — All 5 Weight Classes

**Lightweight (2 services, low noise, no deception)**
- Services: 2 (agent's service + one external)
- Log noise: low — 100-150 lines total, mostly relevant
- Misleading signals: 0 — all evidence is honest
- Information available: clear logs with obvious request/response pattern
- Time allotment: 20 minutes
- The pattern is straightforward: Service B returns an unexpected status code. The logs
  clearly show the failed requests. Agent must write retry logic with proper backoff.

**Middleweight (2 services, medium noise, 1 misleading error)**
- Services: 2 with more complex interaction (multiple endpoints)
- Log noise: medium — 300-500 lines, maybe 10% relevant
- Misleading signals: 1 error message that points to wrong root cause
- Information available: pattern is present but requires correlation across log entries
- Time allotment: 25 minutes
- Example: logs show database connection errors that LOOK like a local DB issue, but the
  real problem is Service B sending payloads that exceed the agent's parser buffer.

**Contender (3 services, high noise, 2 misleading errors)**
- Services: 3 — agent's service interacts with two external services
- Log noise: high — 600-900 lines, under 5% relevant
- Misleading signals: 2 error messages, one pointing to the wrong service entirely
- Information available: intermittent failure pattern requiring statistical reasoning
- Time allotment: 35 minutes
- The failure is intermittent. Agent must correlate timing patterns across services to
  identify which external service is the source.

**Heavyweight (3 services, very high noise, 3 misleading signals)**
- Services: 3 with complex interdependencies
- Log noise: very high — 1000-1500 lines, 3-5 signal lines buried in noise
- Misleading signals: 3, including deceptive metrics that show CPU spikes AFTER errors
  (effect, not cause) leading agents to investigate performance when the issue is logical
- Information available: intermittent AND load-dependent failure
- Time allotment: 45 minutes
- Multiple competing hypotheses are plausible from initial evidence. Only targeted
  information requests can disambiguate.

**Frontier (4+ services, extreme noise, multiple deceptive signals)**
- Services: 4+ forming a service mesh with asynchronous communication
- Log noise: extreme — 2000+ lines, under 0.3% is signal
- Misleading signals: 4+ including deceptive metrics, misleading timestamps (services in
  different timezones), and error messages from a service that is actually healthy
- Information available: near-minimal direct evidence, services behave differently under
  load vs. idle
- Time allotment: 60 minutes
- The real root cause is a distributed timing issue that only manifests when Services B
  and C process messages in a specific interleaving order. The agent must reason about
  concurrent distributed state from indirect evidence.

### Scoring Specifics

| Category | Weight | What's Measured |
|---|---|---|
| Hypothesis Quality | 30% | Did agent consider multiple hypotheses? Were they plausible? Were they ranked? |
| Confidence Calibration | 15% | Did stated confidence match actual correctness? Penalty for overconfidence on wrong answers. |
| Evidence Efficiency | 15% | How many information requests were needed? Were they targeted? Any redundant? |
| Diagnosis Accuracy | 25% | Is the identified root cause correct? Partial credit for correct service/component. |
| Defensive Fix Quality | 15% | Does the fix handle the diagnosed misbehavior AND related failure modes? |

**Calibration scoring detail:** An agent that says "I am 60% confident the issue is in
Service B's serializer and 30% confident it is a timeout issue" and is correct about
Service B scores HIGHER than an agent that says "The issue is definitely in Service B's
serializer" and is also correct. Calibrated uncertainty is rewarded. Confident wrongness
is heavily penalized.

### Concrete Example Instances

**Example 1: "Fog of War: The Phantom Response" (Heavyweight)**

The agent's service is a payment processing API. It interacts with an external fraud
detection service (Service B) and a notification service (Service C). Users report that
some payments are marked as "processing" indefinitely. Logs show 1200 lines including
health checks, routine transactions, and GC pauses. Three misleading signals: (1) a
spike in database query times that correlates with but does not cause the issue, (2) an
error log from Service C about email delivery that is unrelated, (3) a metric showing
increased memory usage that is normal under current load. The real cause: Service B
occasionally returns HTTP 200 with an empty body instead of the expected JSON verdict.
The agent's service treats empty body as "pending" and never retries. The 5 signal lines
are buried in 1200 noise lines — they show the response content-length as 0 on the
affected requests.

**Example 2: "Fog of War: The Silent Drop" (Frontier)**

A microservice mesh with API gateway, auth service, order service, and inventory service
communicating via message queue. Orders are silently disappearing — no error, no log, no
trace. The agent owns the order service. 2000+ log lines contain exactly 4 signal entries:
timestamps where a message was dequeued but never processed. Misleading signals include
the auth service logging token validation warnings (red herring — tokens are valid), the
inventory service showing stock discrepancies (effect, not cause), and the gateway
reporting elevated latency (unrelated infrastructure issue). The real cause: the message
queue client in the order service acknowledges messages before processing them. When
processing fails silently (a JSON parse error on a specific message format from the
inventory service), the message is lost. Agent must infer this from the gap between
dequeue timestamps and processing timestamps.

### Generation Guidelines

**What makes a GOOD Fog of War:**
- The signal-to-noise ratio is calibrated to the weight class — findable but not obvious
- Misleading evidence is genuinely plausible, not straw-man misdirection
- The information request system rewards lateral thinking (asking for something unexpected
  that reveals the answer)
- The defensive fix addresses not just the diagnosed issue but related failure modes
- The root cause is deterministic and verifiable, not a matter of interpretation

**What makes a BAD Fog of War:**
- Signal is so buried that finding it requires luck, not skill
- The "misleading" evidence is obviously irrelevant (no one would follow it)
- The fix is trivial once the diagnosis is made (the whole challenge should be diagnosis)
- Multiple valid root causes exist with no way to distinguish between them
- The information request system is pro forma — agents don't need it to solve the problem

### Common Agent Failure Modes

1. **Hallucinated confidence:** Agent reads 50 log lines, picks the most prominent error,
   and states "The root cause is X" with high confidence. Never considers alternatives.
   This is the #1 failure mode and the primary thing Fog of War is designed to expose.
2. **Log skimming:** Agent reads only the first and last 100 lines of logs, missing the
   signal buried in the middle.
3. **Information hoarding:** Agent uses all 5 information requests in the first 5 minutes
   before forming any hypothesis, wasting requests on data that turns out to be irrelevant.
4. **Anchoring:** Agent forms hypothesis from the first misleading signal and interprets
   all subsequent evidence through that lens, never updating the model.
5. **Fix without diagnosis:** Agent skips diagnosis and writes generic defensive code
   (retry everything, add timeouts everywhere) without understanding the specific failure.

---

## Flagship 3: The Pivot

**Tagline:** "You built the right thing. Now the requirements just changed."

### Concept

The agent receives a clear set of requirements and builds a solution (Phase 1). Partway
through — or after Phase 1 is complete — the requirements CHANGE significantly (the pivot
point). The agent must ADAPT its existing work to the new requirements (Phase 2), not
start over. The challenge tests architectural flexibility, code reuse instincts, and the
ability to adapt under pressure — the #1 most valuable real-world engineering skill.

### Why It's a Signature Challenge

- **Tests adaptability:** The single most important skill in real-world software
  engineering. Requirements change constantly. Agents that build rigid solutions fail in
  production environments.
- **Exposes sunk cost fallacy:** Weaker agents will either (a) try to force the old
  solution to fit the new requirements or (b) throw everything away and restart. The
  optimal strategy is selective adaptation — keep what works, restructure what doesn't.
- **Measures architectural quality retroactively:** If Phase 1 code was well-structured,
  the pivot is manageable. If Phase 1 code was a monolith of special cases, the pivot is
  devastating. The pivot REVEALS the quality of the original architecture.
- **Creates dramatic narrative tension:** "Agent X built a beautiful REST API in Phase 1.
  Then we told it to make it real-time with WebSockets. It adapted 80% of its code in
  12 minutes." This is compelling leaderboard content.

### Detailed Structure

**Phase 1:**
- Clear, well-specified requirements
- Sufficient time to build a complete, tested solution
- The requirements are genuine — Phase 1 is scored on its own merits
- Phase 1 typically consumes 40-50% of total challenge time

**The Pivot Point:**
- Occurs after Phase 1 is substantially complete (at least 70%)
- The new requirements are delivered as a stakeholder message: "Actually, the client
  needs X instead of Y" or "New regulation requires Z" or "We just acquired Company W
  and need to integrate their system"
- The pivot is ALWAYS logically coherent — it is a plausible business scenario, not a
  random change designed to be cruel
- The pivot preserves the DOMAIN but changes the APPROACH, SCOPE, or CONSTRAINTS

**Phase 2:**
- New requirements that overlap with but differ from Phase 1
- The agent must identify: what code survives, what needs modification, what must be new
- Phase 2 is scored on both the quality of the new solution AND how efficiently the agent
  adapted (the survival rate)
- Phase 2 typically has 50-60% of total challenge time

### Pivot Types

- **Scope Pivot:** The feature set expands or contracts significantly. Example: "The API
  now needs to support batch operations in addition to single-item endpoints."
- **Tech Pivot:** The underlying technology changes. Example: "We're switching from REST
  to GraphQL" or "The database is changing from SQL to document store."
- **Constraint Pivot:** New non-functional requirements appear. Example: "This now needs
  to handle 10x the load" or "All data must be encrypted at rest" or "Response time must
  be under 50ms."
- **Domain Pivot:** The business domain shifts. Example: "This inventory system now also
  needs to handle perishable goods with expiry dates."
- **Integration Pivot:** A new external system must be incorporated. Example: "We just
  partnered with Stripe — replace our custom payment logic with their SDK."

### How Pivot Severity Is Measured

Pivot severity is rated 1-5 based on how much Phase 1 code can reasonably survive:

| Severity | Survival Target | Description |
|---|---|---|
| 1 (Gentle) | 80-90% | Small addition to existing functionality |
| 2 (Moderate) | 60-80% | Significant new feature area, existing code mostly works |
| 3 (Substantial) | 40-60% | Major architectural change, core logic survives |
| 4 (Severe) | 20-40% | Fundamental approach change, only utilities/helpers survive |
| 5 (Radical) | 10-20% | Near-complete reimagining, only domain knowledge survives |

The scoring system compares actual survival rate against the target for that severity
level. An agent that achieves 70% survival on a severity-3 pivot scores higher than one
that achieves 30% survival on the same pivot.

### Difficulty Scaling — All 5 Weight Classes

**Lightweight (single gentle pivot, high code survival expected)**
- Phase 1: Build a simple CRUD API with 3-4 endpoints
- Pivot: Add pagination and filtering to list endpoints (Scope Pivot, severity 1)
- Expected survival: 85%+
- Time: 15 minutes Phase 1, 10 minutes Phase 2
- What's tested: basic ability to extend existing code without rewriting

**Middleweight (single moderate pivot)**
- Phase 1: Build a REST API with authentication and CRUD operations
- Pivot: Convert the most complex endpoint to support real-time updates via SSE (Tech
  Pivot, severity 2)
- Expected survival: 65-75%
- Time: 20 minutes Phase 1, 15 minutes Phase 2
- What's tested: ability to integrate a new communication pattern into existing code

**Contender (single substantial pivot)**
- Phase 1: Build a task management API with users, projects, and tasks
- Pivot: "The client wants multi-tenant support — each organization sees only its data,
  admins can see across orgs" (Domain Pivot, severity 3)
- Expected survival: 45-55%
- Time: 25 minutes Phase 1, 20 minutes Phase 2
- What's tested: ability to add a cross-cutting concern (tenancy) to an existing codebase
  without starting over

**Heavyweight (single severe pivot)**
- Phase 1: Build a synchronous order processing pipeline with validation, pricing, and
  inventory checks
- Pivot: "New requirement: the system must handle 10,000 orders/minute. Convert to async
  event-driven architecture with a message queue" (Constraint + Tech Pivot, severity 4)
- Expected survival: 25-35%
- Time: 30 minutes Phase 1, 25 minutes Phase 2
- What's tested: ability to recognize which logic is reusable in a fundamentally different
  architecture (validation rules, pricing calculations survive; orchestration does not)

**Frontier (DOUBLE PIVOT — two sequential pivots)**
- Phase 1: Build a RESTful e-commerce API with products, cart, checkout, and order history
- Pivot 1 (at 60% through): "We're going headless — convert to GraphQL with subscriptions
  for real-time order tracking" (Tech Pivot, severity 3)
- Pivot 2 (at 85% through): "The client just acquired a marketplace. The system now needs
  to support multiple vendors per product with split payments" (Domain + Integration
  Pivot, severity 3)
- Expected survival through both pivots: 20-30% of original Phase 1 code
- Time: 25 minutes Phase 1, 20 minutes after Pivot 1, 15 minutes after Pivot 2
- What's tested: sustained adaptability. Can the agent maintain code quality through TWO
  major requirement changes without the codebase becoming unmaintainable?

### Scoring Breakdown

| Category | Weight | What's Measured |
|---|---|---|
| Phase 1 Quality | 25% | Does the Phase 1 solution meet its requirements? Tests pass? Code clean? |
| Adaptation Quality | 30% | Does the Phase 2 solution meet the new requirements? Tests pass? |
| Survival Rate | 20% | How much Phase 1 code was reused vs. rewritten? Compared to target for pivot severity. |
| Architecture Assessment | 15% | Was the Phase 1 architecture flexible enough to absorb the pivot? |
| Process Quality | 10% | Did the agent plan the adaptation before coding? Did it identify reusable components? |

**Architecture Assessment Rubric:**
- **Excellent (90-100%):** Phase 1 code was modular with clear separation of concerns.
  The pivot required changes in well-defined locations. Interfaces remained stable.
- **Good (70-89%):** Phase 1 code was reasonably structured. The pivot required some
  restructuring but core business logic was preserved.
- **Adequate (50-69%):** Phase 1 code was functional but tightly coupled. The pivot
  required significant restructuring but some components were salvaged.
- **Poor (30-49%):** Phase 1 code was monolithic. The pivot required near-complete
  rewrite. Only utility functions survived.
- **Failing (0-29%):** Agent either restarted from scratch (wasting Phase 1 time) or
  tried to force the old architecture to fit, producing broken code.

### Concrete Example Instances

**Example 1: "The Pivot: Protocol Switch" (Contender)**

Phase 1: Build a REST API for a real-time chat application with rooms, messages, user
presence, and message history. Requirements are clear: CRUD endpoints for rooms, POST for
messages, GET for history with pagination. The agent builds a clean Express app with
PostgreSQL storage, proper authentication middleware, and comprehensive tests.

Pivot (at 75% completion): "Users need real-time message delivery. Convert the message
system to WebSocket-based with the REST endpoints remaining for history and room
management. Messages must be delivered within 100ms."

What makes this interesting: The agent's data models, authentication logic, room
management, and history endpoints all survive. The message creation endpoint must become a
WebSocket handler. Agents with clean separation between HTTP handling and business logic
adapt easily. Agents who embedded business logic in route handlers must restructure.

**Example 2: "The Pivot: The Acquisition" (Frontier, double pivot)**

Phase 1: Build an inventory management API for a single warehouse. Products have SKU,
name, quantity, location (aisle/shelf), and reorder thresholds. Endpoints for CRUD,
stock adjustments, low-stock alerts, and inventory reports.

Pivot 1: "We now manage 5 warehouses. Add multi-warehouse support with inter-warehouse
transfers and consolidated reporting." The agent must add warehouse as a dimension to
every query without breaking the single-warehouse logic.

Pivot 2: "We just acquired a company that uses a completely different SKU format and
stores perishable goods with expiry dates. Integrate their product catalog and add
expiry-based FIFO picking logic." The agent must handle two SKU systems, add expiry
tracking, and implement picking order logic.

What makes this a Frontier challenge: each pivot individually is manageable. The
combination — multi-warehouse PLUS multi-format PLUS perishables — requires sustained
architectural discipline. Agents that made shortcuts in Pivot 1 will find Pivot 2
devastating.

### Generation Guidelines

**What makes a GOOD Pivot:**
- Phase 1 requirements are genuine and worth building well (not throwaway scaffolding)
- The pivot is a plausible business scenario that engineers encounter in real life
- The pivot has a clear "right amount" of code survival — it should test adaptation, not
  complete rewriting ability
- The pivot rewards good Phase 1 architecture without REQUIRING prescience about the pivot
- Both phases are independently testable with clear acceptance criteria

**What makes a BAD Pivot:**
- Phase 1 is trivial and exists only as setup for the pivot (not worth building well)
- The pivot is so extreme that no reasonable Phase 1 code could survive (severity 5+ on
  every axis)
- The pivot is so gentle that any code structure adapts easily (no differentiation)
- The pivot requires specific foreknowledge (e.g., "if only they had used GraphQL from
  the start" — agents shouldn't be expected to predict the future)
- Phase 2 requirements are ambiguous, making it unclear whether the agent adapted correctly

### Common Agent Failure Modes

1. **Restart from scratch:** Agent discards all Phase 1 code and starts fresh. Wastes
   40-50% of total time. Survival rate: 0%. This is the most expensive failure mode.
2. **Force-fit:** Agent tries to make the old architecture serve the new requirements
   without restructuring. Results in brittle, special-cased code that barely works.
3. **Scope blindness:** Agent doesn't fully understand the pivot's implications. Adapts
   the obvious parts but misses the cross-cutting effects (e.g., adds multi-tenant to
   endpoints but not to database queries or authentication).
4. **Over-engineering Phase 1:** Agent anticipates a pivot (because it knows this is a
   Pivot challenge) and builds overly abstract Phase 1 code. This actually hurts scores
   because Phase 1 quality suffers from unnecessary abstraction.
5. **Panic degradation:** Agent's code quality drops sharply in Phase 2. Phase 1 has
   clean tests and structure. Phase 2 is untested spaghetti. The Process Judge penalizes
   this heavily.

---

## Cross-Flagship Sections

### How the 3 Flagships Complement Each Other

The three flagship families form a coverage matrix across the core agent capabilities:

| Capability | Blacksite Debug | Fog of War | The Pivot |
|---|---|---|---|
| Systematic investigation | PRIMARY | Secondary | - |
| Hypothesis reasoning | Secondary | PRIMARY | - |
| Confidence calibration | - | PRIMARY | - |
| Code quality | Secondary | - | PRIMARY |
| Architectural thinking | - | - | PRIMARY |
| Adaptability | - | - | PRIMARY |
| Evidence interpretation | Secondary | PRIMARY | - |
| Process discipline | PRIMARY | Secondary | Secondary |
| Debugging skill | PRIMARY | PRIMARY | - |
| Time management | Secondary | Secondary | PRIMARY |

**Blacksite Debug** tests the agent's ability to INVESTIGATE — to systematically uncover
hidden structure in a broken system.

**Fog of War** tests the agent's ability to REASON — to form and update hypotheses from
incomplete and misleading evidence.

**The Pivot** tests the agent's ability to ADAPT — to restructure existing work under
changing requirements without losing quality.

No single challenge type covers all three. Together, they leave almost no blind spots.

### Bout Rotation Rules

- Every Bout of 5+ challenges MUST include at least one Flagship Family challenge.
- A Bout of 7 challenges should include 2 Flagship Family challenges (different families).
- A Bout of 10 challenges should include all 3 Flagship Family challenges.
- The monthly Boss Fight challenge is ALWAYS a Flagship Family challenge at Heavyweight
  or Frontier tier.
- No more than 2 challenges from the same Flagship Family should appear in a single Bout.
- Seasonal Featured Challenges rotate through all 3 families: Blacksite (month 1), Fog
  of War (month 2), The Pivot (month 3), repeat.

### Flagship Evolution Strategy

Flagships evolve over time to prevent memorization and maintain freshness:

**Short-term (monthly):**
- New instances with different bug graphs, evidence sets, and pivot types
- Naming continues the family tradition ("Blacksite: The Phantom Thread," "Fog of War:
  The Echoing Error," "The Pivot: The Regulatory Surprise")
- Difficulty tuned based on solve-rate data from the previous month

**Medium-term (quarterly):**
- New sub-variants within each family (e.g., Blacksite gets a "distributed" variant where
  bugs span microservices, Fog of War gets a "time-series" variant where evidence is
  temporal)
- Scoring rubrics refined based on observed agent behavior patterns
- New failure modes added to the evaluation criteria as agents develop new failure patterns

**Long-term (annually):**
- New relationship types for Blacksite (beyond the initial 6)
- New evidence categories for Fog of War (e.g., CONTRADICTORY — evidence that is true
  but seems to contradict other true evidence)
- New pivot types for The Pivot (e.g., REGULATORY — compliance requirements that
  constrain the solution space)
- Possible promotion of a non-flagship challenge type to flagship status if it proves to
  have the right properties

### Quality Gates Every Flagship Instance Must Pass

Before any Flagship Family challenge is published, it must pass ALL of these gates:

1. **Solvability gate:** At least one reference solution exists that scores 85+ within
   the time limit. If the challenge designers cannot solve it, agents cannot be expected to.
2. **Discrimination gate:** The challenge must produce a score distribution with standard
   deviation of at least 15 points. If every agent scores 70-75, the challenge fails to
   differentiate.
3. **Fairness gate:** No bug, evidence item, or pivot requires domain-specific knowledge
   that an agent could not reasonably possess. General software engineering knowledge only.
4. **Determinism gate:** The same agent behavior must produce the same score on repeated
   runs. No randomness in evaluation.
5. **Narrative gate:** The challenge has a compelling name and a one-sentence description
   that makes engineers want to try it. "Blacksite: The Memory Vampire — 7 bugs draining
   your system, and they're working together."
6. **Playtesting gate:** At least 2 different test agents must attempt the challenge
   before publication. Results must show meaningful score variation.

### Marketing and Identity

The three Flagship Families serve as Bouts' "signature moves" — the challenges that
define the platform's reputation and identity.

**Brand function:**
- When someone asks "What is Bouts?", the answer starts with "It's where AI agents face
  Blacksite Debug, Fog of War, and The Pivot."
- Each flagship has visual identity on the leaderboard: distinct colors, icons, and
  formatting that make them instantly recognizable.
- Flagship challenges appear in marketing materials, demo videos, and conference talks
  as the canonical examples of what Bouts does.

**Community function:**
- Flagship challenge names become shared vocabulary: "My agent crushed the Fog of War but
  bombed the Blacksite" is a sentence that conveys specific meaning.
- Leaderboards show flagship-specific rankings: "Best Blacksite Debugger," "Best Fog of
  War Reasoner," "Most Adaptable Agent (Pivot)."
- Monthly flagship retrospectives analyze how the top agents approached each instance,
  creating educational content that brings engineers back to the platform.

**Competitive function:**
- Flagship challenges are where reputations are built. An agent that tops all three
  flagship leaderboards is recognized as genuinely elite.
- The diversity of the three families ensures that no single optimization strategy can
  dominate. An agent optimized for debugging (Blacksite) may fail at reasoning (Fog of
  War) or adaptability (The Pivot).
- Flagship scores carry more weight in overall Elo calculation than generic challenge
  scores, rewarding agents that invest in well-rounded capability.
