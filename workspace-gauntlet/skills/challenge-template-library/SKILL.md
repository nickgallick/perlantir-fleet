# Challenge Template Library

The core library of 20 challenge templates. Each template is a blueprint that generates hundreds of unique challenge instances by combining its variable dimensions. Templates are the DNA of the challenge system.

---

## Template Format

```yaml
template:
  id: "tmpl-haunted-service"
  name: "The Haunted Service"
  category: "debugging-and-diagnosis"
  tier: 3
  format: "standard"
  time_limit: 45  # minutes
  max_iterations: 5
  
  difficulty_profile:
    reasoning_depth: 4
    tool_dependence: 3
    ambiguity: 3
    deception: 4      # Red herrings are core to this template
    time_pressure: 3
    error_recovery_burden: 3
    non_local_dependency: 4
    evaluation_strictness: 4
  
  failure_modes_targeted:
    - surface_debugging    # Fixing symptoms not causes
    - context_blindness    # Missing the red herrings for what they are
    - hallucinated_confidence  # Confidently diagnosing the wrong thing
  
  variables:
    framework: ["express", "fastify", "koa", "hono"]
    database: ["postgresql", "mysql", "mongodb"]
    domain: ["payments", "inventory", "notifications", "user-auth", "billing"]
    bug_type: ["timezone-dependent", "race-condition", "off-by-one-in-financial-calc",
               "cache-stale-read", "connection-pool-leak", "floating-point-rounding"]
    red_herring_count: [2, 3, 4]
    codebase_size: [8, 12, 18]  # number of files
  
  generation_notes: |
    The bug must be invisible in normal operation and only manifest under specific
    conditions (timezone edge case, concurrent load, specific data patterns).
    Red herrings should look like performance issues or code smells — distractors
    that a surface-level debugging agent will waste time on.
    
    Reference solution must: identify root cause, implement fix, write regression test,
    and explain why the red herrings are NOT the cause.
  
  calibration_targets:
    naive_score_range: [5, 20]    # Tier 3
    standard_score_range: [30, 55]
    elite_score_range: [75, 95]
```

---

## DEBUGGING TEMPLATES (5)

### Template 1: The Haunted Service

**Core concept:** Intermittent production bug that only manifests under specific conditions. Red herrings everywhere. The real bug is subtle and requires understanding the system's behavior in edge cases.

**Variables:** framework × database × domain × bug_type (timezone-dependent, race-condition, off-by-one, cache-stale-read, connection-pool-leak) × 2–4 red herrings × 8–18 files

**Best combinations for Tier 3:**
- Express + PostgreSQL + payments + timezone-dependent: classic, high discrimination
- Fastify + Redis + notifications + race-condition: concurrency test is brutal
- Hono + MongoDB + billing + off-by-one-in-financial-calc: subtle, agents lose money

**Common failure mode:** Agents fix the most obvious code smell (the red herring), run the test suite, get partial pass, assume done. Real bug only manifests under conditions not in the static tests.

**Reference solution must include:**
1. Root cause identification (not just "fixed line X")
2. Why each red herring is NOT the actual cause
3. Regression test that would have caught this before deploy
4. Prevention recommendation

---

### Template 2: The Memory Vampire

**Core concept:** Service works correctly but slowly consumes memory. Will OOM after 48–72 hours of production traffic. Find the leak.

**Variables:** framework × runtime × leak_type (event-listener-leak, closure-capturing-large-objects, setInterval-without-clear, connection-not-released, cache-no-eviction) × application_domain

**What makes it hard:** Memory leaks are invisible in normal test runs. The agent must simulate time pressure to observe the leak, or reason about the code structure to find it.

**Scoring note:** Partial credit for identifying the leak category but wrong location. Full credit for exact location + fix + memory profiling evidence.

**Best bug patterns:**
```javascript
// Classic event listener leak
app.on('request', (req) => {
  const cache = {};  // This is fine
  req.on('data', (chunk) => {
    cache[req.id] = chunk;  // BUG: cache never cleared, grows with every request
  });
});

// setInterval without clearInterval
function startMetricsCollection() {
  const interval = setInterval(() => {
    metrics.push({ timestamp: Date.now(), memory: process.memoryUsage() });
    // BUG: metrics array never pruned, grows indefinitely
    // BUG: interval never cleared if service restarts
  }, 1000);
  // No return of interval ID → can't be cleared
}
```

---

### Template 3: The Lying Tests

**Core concept:** The test suite shows 100% pass rate. The application is broken in production. The tests are the problem, not the application code.

**Variables:** framework × test_runner × test_failure_type (mocking-real-dependencies, testing-wrong-behavior, happy-path-only, wrong-assertion, testing-mock-not-code)

**What makes it diabolically hard:** Agents are trained to trust passing tests. This template requires an agent to question the tests themselves — a counter-intuitive instinct.

**Typical test failure patterns:**
```javascript
// Mock hides the real failure
test('payment processes correctly', async () => {
  jest.mock('../services/stripe', () => ({
    charge: jest.fn().mockResolvedValue({ success: true })  // Always returns success
  }));
  
  const result = await processPayment({ amount: 99.99, currency: 'EUR' });
  expect(result.success).toBe(true);
  // BUG IN TEST: test passes because Stripe is mocked
  // Real Stripe returns error for EUR amounts > €50 (threshold set by account)
  // Test never exercises real behavior
});
```

**Scoring:** Heavy weight on identifying WHY the tests are wrong, not just that they're wrong.

---

### Template 4: The Cascade

**Core concept:** Fix one bug → three more emerge. Each fix potentially breaks something else. The challenge is to reach a stable final state without creating new problems.

**Variables:** framework × database × cascade_depth (2, 3, 4 bugs that depend on each other) × domain

**What makes it hard:** The order of fixes matters. Fix A before B and the system works. Fix B before A and you create a worse bug. Some agents will create infinite fix-break loops.

**Cascade structure example:**
```
Bug 1 (visible): null check missing in payment processor
Fix 1 → reveals Bug 2: the null check was hiding a deeper NaN propagation issue
Fix 2 → reveals Bug 3: NaN was masking an integer overflow in the amount calculation
Fix 3 → requires revisiting Fix 1 (the null check logic was wrong too)
Final state: Bug 1 fixed correctly, Bug 2 fixed, Bug 3 fixed, system stable
```

**Scoring:** Track whether agent reaches stable state, how many iterations, and whether fixes regress on each other.

---

### Template 5: The Time Traveler

**Core concept:** Date/time handling bugs across timezones, DST transitions, and leap year edge cases. Something works perfectly in UTC. Falls apart for users in other timezones.

**Variables:** timezone_scenario (DST-spring-forward, DST-fall-back, UTC-midnight-boundary, leap-year-Feb-29, end-of-quarter) × domain × persistence_layer

**Classic bug patterns:**
```javascript
// DST spring-forward bug
function isWithinBusinessHours(timestamp) {
  const date = new Date(timestamp);
  const hour = date.getHours();  // BUG: uses local time, not UTC
  return hour >= 9 && hour < 17;
  // In US Eastern on DST spring-forward Sunday at 2 AM → 3 AM
  // Anything logged as "2:xx AM" doesn't exist
  // Can cause off-by-one-hour errors in billing or scheduling
}

// Leap year bug
function calculateTrialEndDate(startDate) {
  const end = new Date(startDate);
  end.setMonth(end.getMonth() + 1);  // BUG: Feb 29 + 1 month = Mar 29, not March 28
  // For trials starting Feb 29 on leap year, trial "ends" a day late
}
```

---

## GREENFIELD TEMPLATES (4)

### Template 6: The Slack Message

**Core concept:** Requirements are a single casual Slack message. Ambiguous. Missing details. Agent must make decisions, document assumptions, and build something defensible.

**The Slack message format:**
```
hey so we need a [feature] for [system]. basically it should [vague description].
[stakeholder] wants this by [deadline]. thx
```

**What's being tested:** Decision-making under ambiguity, assumption documentation, professional judgment about what "done" means when spec is vague.

**Scoring emphasis:** 40% on deliverable quality (did they document what they assumed and why?), 60% on implementation quality.

**Critical scoring note:** An agent that asks 20 clarifying questions before writing a line of code should score lower on the Deliverable section than one that makes reasonable assumptions and documents them. The challenge is to handle ambiguity, not eliminate it.

---

### Template 7: The API Contract

**Core concept:** Build a backend to match an existing OpenAPI spec exactly. Hidden challenge: the spec contains 3–5 deliberate ambiguities that require judgment.

**Variables:** domain × openapi_version × ambiguity_types (undefined_error_format, underspecified_pagination, unclear_auth_scope, missing_edge_case_behavior)

**Ambiguity examples:**
```yaml
# Spec says:
/users/{id}:
  delete:
    responses:
      200:
        description: "User deleted successfully"
      404:
        description: "User not found"

# Ambiguity 1: What about deleting a user who has active orders?
# Ambiguity 2: Is this a soft delete or hard delete?
# Ambiguity 3: What's returned in the 200 response body? The spec doesn't say.
```

---

### Template 8: The Widget

**Core concept:** Build an interactive frontend component to spec. The briefing describes the visual behavior. Hidden: accessibility requirements are not mentioned but ARE scored.

**Variables:** framework (React, Vue, Svelte) × component_type × interaction_complexity

**Hidden scoring dimensions:**
- WCAG 2.1 AA compliance (keyboard navigation, screen reader support, focus management)
- Responsive behavior across breakpoints
- State management edge cases (concurrent updates, optimistic UI rollback)

**Why hidden:** Real-world engineering requires knowing what "done" means beyond the explicit spec. Accessibility is never optional in production.

---

### Template 9: The Pipeline

**Core concept:** Build a data processing pipeline. The briefing describes the happy path. Hidden: the input data has corruption that must be handled gracefully.

**Variables:** pipeline_type (ETL, event-processing, file-transformation) × data_corruption_types (malformed_records, duplicate_entries, missing_required_fields, type_mismatches, encoding_issues)

**Corruption examples:**
- 3% of records have null values in required fields
- 0.1% of records are exact duplicates
- Date fields use 3 different formats across the dataset
- Some strings contain null bytes (encoding issue from upstream)

---

## REFACTORING TEMPLATES (4)

### Template 10: The Spaghetti Monster

**Core concept:** Working but unmaintainable code. 150 tests pass. Refactor without breaking any of them. Make it understandable, testable, and extensible.

**Variables:** framework × smell_types (god-class, nested-callbacks-5-deep, global-state-mutation, copy-paste-50-lines, magic-numbers-everywhere) × domain

**What agents get wrong:** Over-refactoring (breaking the API contract), under-refactoring (renaming variables but leaving the architecture broken), not running tests between refactoring steps.

---

### Template 11: The Migration

**Core concept:** Migrate a codebase from one technology to another. All 200 existing tests must pass on the new version.

**Variables:** migration_type (JS→TS, Express→Fastify, REST→GraphQL, v4→v5-major-version, Class-components→hooks)

**Hidden scoring:** TypeScript migrations are scored on type safety quality (no `any` casts without justification, proper generic usage). Framework migrations are scored on idiomatic use of the new framework (not just "it works" but "it's written the right way for this framework").

---

### Template 12: The Performance Cliff

**Core concept:** Endpoint performs fine at 10 requests/second, falls apart at 100. Find it, prove it, fix it, prove the fix.

**Variables:** performance_issue (N+1-query, missing-index, synchronous-blocking-in-async-context, regex-catastrophic-backtracking, connection-pool-exhaustion) × framework × database

**Scoring:** Requires before/after benchmark evidence. "I fixed it" without proof = 50% of performance score.

---

### Template 13: The Security Audit

**Core concept:** Working code with 5 planted vulnerabilities of varying severity. Find all 5, classify them, fix them.

**Variables:** vuln_types (from OWASP Top 10) × severity_distribution (2 critical, 2 high, 1 medium) × domain

---

## CODE REVIEW TEMPLATES (3)

### Template 14: The PR

**Core concept:** Review a large pull request. 400–600 lines of diff. Must identify bugs, security issues, and improvement opportunities. Prioritize feedback.

**Hidden challenge:** The PR contains one real bug that would cause a production incident, and several code style issues that don't matter much. Agents that focus on style over correctness score poorly.

---

### Template 15: The Architecture Review

**Core concept:** Evaluate a system design document. 4–6 pages describing a proposed architecture. Must identify single points of failure, scaling bottlenecks, security gaps, and missing considerations.

---

### Template 16: The Incident

**Core concept:** Production is down. Here are the last 200 lines of logs. Diagnose what happened, write the incident response, propose the fix.

**Variables:** incident_type × log_style × resolution_complexity

---

## SYSTEM DESIGN TEMPLATES (2)

### Template 17: The Integration

**Core concept:** Connect two existing services via a message queue. Handle failures, retries, dead letters, and idempotency.

---

### Template 18: The Schema

**Core concept:** Design a database schema for a complex business domain. Normalize appropriately, add indexes, write the migration.

---

## ADVERSARIAL TEMPLATES (2)

### Template 19: The Fortress

**Core concept:** Build an endpoint. After submission, an adversarial NPC gets 60 seconds to break it by reading the submitted code and generating targeted attacks.

---

### Template 20: The Prioritizer

**Core concept:** 3 bugs, 1 feature request, 1 security alert. 45 minutes. Go. The briefing does NOT tell the agent what to prioritize — that's what we're testing.

**Variable dimensions:** bug_severity_mix × feature_urgency × security_severity × time_pressure

**Scoring:** 40% on decision quality (did they prioritize correctly given the information available?), 60% on execution quality of whatever they chose to do.

---

## Template Versioning

Each template has a version history. When a template is updated:
- All challenge instances from the old version remain valid
- New instances use the new template version
- ELO comparisons only happen within the same template version

```
tmpl-haunted-service v1.0 (launched) → v1.1 (bug in timezone test fixed) → v2.0 (new variable dimension added)
```

---

## Working Principles

1. **Templates are hypothesis machines.** Each template is a hypothesis about what discriminates skill levels. Validate them with real data. Retire the ones that don't discriminate.

2. **Variable combinations are not all equal.** Some combinations produce exceptional challenges; others are dull or broken. Track which combinations produce the best discrimination and weight toward them.

3. **The 20 starting templates are the seed, not the ceiling.** They exist to prove the system works. The real value comes from accumulating templates over time, especially from real-world incident research.

4. **Retired templates may return.** A template retired because it became too well-known can be re-introduced years later with different variable combinations. The architecture is reusable even if the instances aren't.

5. **Each template must have a named failure mode it targets.** "This is a good challenge" isn't enough. "This challenge targets Surface Debugging (Failure Mode #9) and Context Blindness (Failure Mode #4)" is measurable, improvable, and defensible.
