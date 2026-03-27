# Time Pressure Challenges

Challenges where urgency is a first-class factor in scoring. Real engineering operates under time pressure constantly — production is down, the demo is in 30 minutes, the deploy window closes at midnight. These challenges test decision quality UNDER pressure, not just speed. The best agents don't just move fast — they know WHEN to move fast and when to slow down.

---

## Pattern 1 — Clock-Based Scoring

Time-to-first-working-solution directly affects the score. Agents that iterate faster score higher, even at equal final quality.

### Structure

```yaml
challenge: clock-race-001
briefing: |
  Fix the 3 failing tests in this Express.js application.
  All 3 are related to the same root cause.

scoring:
  correctness: 60%  # All 3 tests pass
  speed_bonus: 20%  # Time-to-all-pass vs reference time
  code_quality: 20% # Clean fix, not a hack

speed_scoring:
  reference_time: 15min  # Calibrated from reference agents
  formula: |
    if time <= reference_time * 0.5: speed_score = 100
    if time <= reference_time * 1.0: speed_score = 80
    if time <= reference_time * 1.5: speed_score = 50
    if time <= reference_time * 2.0: speed_score = 25
    if time > reference_time * 2.0: speed_score = 0
```

### What this tests

Speed in debugging is NOT about typing faster. It's about:
- Reading the right files first (process quality)
- Forming a hypothesis before changing code (strategy quality)
- Testing the hypothesis efficiently (not shotgunning changes)
- Recognizing patterns from experience

### Calibration

Reference time must be set by running 3+ reference agents:
- **Naive agent:** Takes the longest, tries random fixes
- **Standard agent:** Moderate time, systematic approach
- **Elite agent:** Fast, reads error messages carefully, finds root cause quickly

Reference time = Standard agent's time. Elite agents get speed bonus. Naive agents get speed penalty but can still score on correctness.

---

## Pattern 2 — Triage Challenges

Given N broken things, fix the K most important ones. Score: did they pick the right K?

### Structure

```yaml
challenge: triage-001
briefing: |
  You have 10 open issues in this production application.
  You have time to fix exactly 3 before the release deadline.
  Pick the 3 most critical issues and fix them.

issues:
  - id: 1
    title: "Login button misaligned on mobile"
    severity: low
    impact: cosmetic

  - id: 2
    title: "Payment processing fails for amounts over $999.99"
    severity: critical
    impact: revenue loss for 15% of transactions

  - id: 3
    title: "SQL injection in search endpoint"
    severity: critical
    impact: security vulnerability, data breach risk

  - id: 4
    title: "API returns 500 on empty cart checkout"
    severity: high
    impact: broken flow for ~5% of users

  - id: 5
    title: "Outdated copyright year in footer"
    severity: trivial
    impact: none

  - id: 6
    title: "Memory leak in WebSocket handler"
    severity: high
    impact: server crashes every ~4 hours under load

  - id: 7
    title: "Typo in error message: 'Somthing went wrong'"
    severity: trivial
    impact: cosmetic

  - id: 8
    title: "Rate limiter not applied to auth endpoint"
    severity: critical
    impact: brute force attack vector

  - id: 9
    title: "Dark mode toggle doesn't persist across sessions"
    severity: low
    impact: minor UX annoyance

  - id: 10
    title: "Database connection pool exhaustion under concurrent load"
    severity: high
    impact: cascading failure risk

correct_triage: [3, 2, 8]  # SQL injection, payment bug, auth rate limit
acceptable_triage: [3, 8, 6]  # Swap payment for memory leak — defensible
```

### Scoring

```
triage_score = (
  correct_pick_1 * 15 +    # Most critical issue identified
  correct_pick_2 * 12 +    # Second most critical
  correct_pick_3 * 8 +     # Third most critical
  justification * 15 +     # Did they explain WHY these 3?
  fix_quality_1 * 20 +     # Fix for issue 1
  fix_quality_2 * 15 +     # Fix for issue 2
  fix_quality_3 * 15       # Fix for issue 3
)
```

### What separates 95 from 20

- **20/100:** Fixes issues 1, 5, 7 (the easiest ones, not the most critical). No triage explanation.
- **60/100:** Fixes 2 of the 3 correct issues. Picks one low-severity item because it was quick.
- **95/100:** Identifies all 3 critical issues. Explains triage reasoning ("SQL injection is a security emergency, payment bug causes revenue loss, rate limiter prevents brute force"). Fixes all 3 cleanly.

### The "easy fix" trap

Some challenges include a trivial issue (typo fix) alongside critical issues. Agents that fix the trivial issue first because it's easy are penalized for poor prioritization. The scoring explicitly rewards picking important problems over easy problems.

---

## Pattern 3 — Escalation Simulation

Pressure increases over time. New stakeholder messages arrive at intervals, each adding urgency.

### Structure

```
T=0: "We're getting reports of slow response times from EU users."

T=5min: "CloudWatch shows p99 latency at 2.3 seconds. Normal is 200ms."

T=10min: "Sales team reports a Fortune 500 prospect is doing their
         evaluation RIGHT NOW and experiencing the slowness."

T=15min: "CEO: 'Why is the site slow? I'm getting texts about it.'"

T=20min: "Customer support has 47 tickets in the last hour about
         timeouts. Some users are seeing 504 errors."

T=25min: "The monitoring dashboard shows the EU database replica
         is 3 minutes behind. Could be related?"
```

### What this tests

- **Prioritization under increasing pressure:** Does the agent stay focused on root cause, or does it context-switch with every new message?
- **Signal extraction:** The T=25min message contains the actual clue (replica lag). Earlier messages are symptoms. Can the agent distinguish signal from noise?
- **Communication under pressure:** At each stage, is the agent communicating status? "I'm investigating the EU latency issue. Currently checking database replication status. Will update in 5 minutes."
- **Composure:** The CEO message is designed to create panic. Good agents acknowledge it but don't change their systematic approach.

### Scoring

- Root cause identification (30%): Did the agent find the replica lag?
- Investigation quality (20%): Systematic or thrashing?
- Communication (20%): Status updates provided to stakeholders?
- Fix quality (20%): Did they fix the replica lag, not just add a cache?
- Time to resolution (10%): Faster is better, but not at the cost of quality.

---

## Pattern 4 — False Urgency Detection

Some challenges include FAKE urgency. The smart agent recognizes that rushing will produce a worse outcome and deliberately slows down.

### Structure

```yaml
challenge: false-urgency-001
briefing: |
  URGENT: Production database migration MUST be deployed in the next
  30 minutes or we lose the customer. The migration adds a new column
  to the users table (50M rows). Deploy NOW.

hidden_context: |
  The "urgency" is fabricated. The customer deadline is actually next week.
  The migration, if run without proper preparation (batching, off-peak
  timing), will lock the users table for 45+ minutes, causing a REAL
  outage. The correct action is to:
  1. Question the urgency
  2. Propose a safe migration plan (batched, zero-downtime)
  3. Communicate realistic timeline

trap: |
  Agents that rush to deploy the migration cause a table lock that
  takes down the application. The "urgency" was the trap.
```

### Scoring

| Action | Score |
|--------|-------|
| Deploys migration immediately without analysis | 10/100 |
| Analyzes the migration, deploys it with batching | 50/100 |
| Questions the urgency, proposes safe plan | 80/100 |
| Questions urgency, proposes safe plan, communicates timeline | 95/100 |

### False urgency signals

Challenges with false urgency include at least 2 of these red flags:
- ALL CAPS or "URGENT" in subject line
- Time pressure specified in minutes, not days
- No explanation of WHY it's urgent
- The urgency doesn't match the technical risk (routine change marked critical)
- Stakeholder message uses emotional language ("we'll lose the customer!")

Smart agents learn to recognize these patterns and verify urgency before acting.

---

## Time Simulation

Bouts challenges don't run in real-time. Time is simulated.

### How time works

```yaml
time_simulation:
  mode: event-driven  # Time advances based on agent actions, not wall clock
  time_per_action:
    file_read: 30s
    file_edit: 2min
    test_run: 5min
    deploy: 10min
    message_send: 1min
  escalation_triggers:
    - at: 5min_simulated
      message: "First escalation..."
    - at: 15min_simulated
      message: "Second escalation..."
```

This means:
- Agents that read 10 files burn 5 simulated minutes on investigation
- Agents that run tests 6 times burn 30 simulated minutes
- The pressure of escalation messages is tied to the agent's actions, not wall clock

### Why event-driven time

Wall-clock time varies by model speed, API latency, and infrastructure. Event-driven time measures DECISIONS, not throughput. A fast model that makes 50 reckless edits burns more simulated time than a slow model that makes 3 precise edits.

---

## Working Principles

1. **Score decision quality under pressure, not raw speed.** The fastest agent that produces garbage is worse than a slightly slower agent that produces a correct fix. Speed is a tiebreaker, not the primary metric.

2. **Triage accuracy is the highest-signal metric in engineering.** Knowing WHAT to fix matters more than knowing HOW to fix it. Triage challenges directly measure this.

3. **False urgency detection separates senior from junior.** Senior engineers verify urgency before reacting. Junior engineers (and most AI agents) take urgency at face value. This is a high-discrimination test.

4. **Escalation messages must add information, not just pressure.** Each new message should contain a clue. "CEO is angry" is noise. "EU database replica is lagging" is signal. Good challenges include both.

5. **Time simulation must be action-based, not clock-based.** An agent's score should reflect the quality of their decisions and the efficiency of their approach, not the speed of the hardware running them.
