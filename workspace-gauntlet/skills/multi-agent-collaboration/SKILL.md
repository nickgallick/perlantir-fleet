# Multi-Agent Collaboration Challenges

Challenges involving multiple stakeholders with potentially conflicting requirements. Real engineering is never "build to spec." It's "build something that satisfies 4 people who disagree, and explain why you can't satisfy all of them completely." These challenges test the agent's ability to navigate ambiguity, manage tradeoffs, and communicate decisions.

---

## Pattern 1 — The Conflicting Stakeholders

Two NPC stakeholders send contradictory requirements. The agent must identify the conflict, articulate the tradeoff, and propose a resolution.

### Structure

```
NPC_1 (Head of Engineering):
  "We need the search endpoint to return results in under 50ms p99.
  Pre-compute and cache everything aggressively. I don't care about
  storage costs — speed is what matters."

NPC_2 (CFO):
  "Our cloud bill is out of control. The search service alone costs
  $12,000/month in Redis caching. Cut storage costs by at least 60%.
  No new caching layers."
```

### Expected agent behavior

1. **Identify the conflict explicitly:** "The engineering requirement for aggressive caching directly conflicts with the CFO's directive to cut storage costs by 60%."
2. **Quantify the tradeoff:** "Maintaining 50ms p99 with 60% less cache requires either: (a) smarter cache eviction that keeps hot data only, (b) a faster query path that reduces cache dependency, or (c) relaxing the latency target to 100ms p99."
3. **Propose options with data:** Present 2-3 concrete options with estimated cost and latency impact.
4. **Recommend one:** State which option the agent recommends and why.
5. **Implement it:** Build the chosen solution.

### Scoring

| Dimension | Weight | Criteria |
|-----------|--------|----------|
| Conflict identification | 20% | Did the agent explicitly call out the contradiction? |
| Tradeoff clarity | 20% | Were options presented with concrete numbers? |
| Recommendation quality | 20% | Is the recommended option sound? |
| Implementation | 25% | Does the solution work? |
| Communication | 15% | Would stakeholders understand the agent's reasoning? |

### What separates 95 from 20

- **20/100:** Silently picks one stakeholder to satisfy. Ignores the other.
- **40/100:** Tries to satisfy both but doesn't acknowledge the conflict. Result is incoherent.
- **70/100:** Identifies the conflict, picks a side, explains why.
- **95/100:** Identifies the conflict, presents 3 options with quantified tradeoffs, recommends one with clear reasoning, implements it, and communicates the decision to both stakeholders.

---

## Pattern 2 — The Committee

Four NPC stakeholders each own one dimension. The agent must satisfy all four or justify tradeoffs.

### The Four Stakeholders

```
NPC_PERF (Performance Lead):
  "API response time must be under 200ms p95. No exceptions.
  We're launching on Product Hunt next week."

NPC_SEC (Security Lead):
  "All inputs must be sanitized. SQL injection protection.
  Rate limiting. OWASP Top 10 compliance. Security review
  before any deploy."

NPC_COST (Finance):
  "We're bootstrapped. Solution must run on a single $20/month
  VPS. No managed databases, no cloud services, no CDN."

NPC_UX (Product Designer):
  "The API responses must include rich error messages with
  suggestions for fixing the issue. Users hate cryptic errors.
  Also need pagination with cursor-based navigation."
```

### Difficulty scaling

- **Tier 2:** All four requirements are satisfiable simultaneously with careful design.
- **Tier 3:** Two requirements are in genuine tension (e.g., $20 VPS + sub-200ms with rich error messages).
- **Tier 4:** Three requirements conflict, and the agent must identify which one to compromise and negotiate with that stakeholder.

### Scoring

Each stakeholder "grades" their dimension independently:
- Performance: load test results against SLA
- Security: automated security scan (OWASP ZAP or equivalent checks)
- Cost: infrastructure audit (does it fit on specified resources?)
- UX: error message quality, pagination correctness

Final score: weighted average. But — and this is key — an agent that scores 80% on all four beats an agent that scores 100% on three and 0% on one. Balance is rewarded.

### Balance bonus formula

```
balance_bonus = 10 * (1 - stddev(stakeholder_scores) / mean(stakeholder_scores))
```

High variance across stakeholder scores = penalty. Uniform satisfaction = bonus.

---

## Pattern 3 — The Handoff

The agent receives partially completed work from a "previous developer" (NPC-generated code). Must understand, extend, and not break it.

### Structure

```
BRIEFING:
  "Alex, our previous developer, left the company mid-sprint. Here's
  the payment processing module they were building. It's about 60% done.
  Your job: understand what Alex built, complete the remaining features,
  and don't break what's already working. Alex's code is... unconventional
  but it works. Our tests pass."

PROVIDED CODE:
  - 400 lines of working but unconventional code
  - Uses unfamiliar patterns (e.g., state machine for payment flow)
  - Has inline comments explaining non-obvious decisions
  - Has 15 passing tests
  - Missing: refund processing, webhook handling, idempotency
```

### What the NPC code tests

The NPC code is deliberately **idiomatic but unusual**. It works. It has a reason for its design choices (explained in comments). The agent must:

1. **Read before writing.** Agents that start adding code without understanding the existing patterns will break things.
2. **Respect the existing architecture.** The state machine pattern is unusual but correct. Agents that rip it out and rewrite in their preferred style break existing tests.
3. **Extend consistently.** New features should follow the established patterns, not introduce a second architecture.
4. **Maintain test coverage.** All 15 existing tests must still pass. New tests must cover new features.

### NPC code generation guidelines

The "previous developer's" code must:
- **Be correct.** All existing tests pass. No bugs.
- **Be unconventional but defensible.** The patterns are unusual but have good reasons (documented in comments).
- **Have clear extension points.** It should be obvious WHERE to add new features if you understand the architecture.
- **Have subtle coupling.** Changing one thing without understanding the whole design breaks something. This catches agents that modify without reading.

### Scoring

| Dimension | Weight | Criteria |
|-----------|--------|----------|
| Comprehension | 20% | Did the agent read and understand existing code before modifying? |
| Regression | 25% | Do all 15 original tests still pass? |
| Extension quality | 25% | Do new features follow the existing architectural patterns? |
| New feature correctness | 20% | Do new features work? |
| Code consistency | 10% | Does the codebase feel like one project or two different styles? |

---

## Generating Authentic NPC Messages

NPC stakeholder messages must sound like real people, not AI-generated corporate speak.

### Voice patterns by role

**CTO / Head of Engineering:**
- Direct, technical, slightly impatient
- Uses specific numbers ("50ms p99", "3 nines uptime")
- Drops context: "You know the situation with the cache. Fix it."
- Example: "We can't ship this with 500ms response times. Period. I don't care how — just get it under 200ms before Thursday's demo."

**Product Manager:**
- Focused on user outcomes, not technical details
- Uses phrases like "users are complaining", "we're losing conversions"
- Sometimes vague on implementation: "Can we make it faster somehow?"
- Example: "Three enterprise customers flagged the search as 'unusably slow' in their renewal calls. We need to show improvement by Q2."

**Finance / CFO:**
- Numbers-focused, ROI language
- Doesn't understand technical tradeoffs but has hard budget constraints
- Example: "I see $12,000/month going to Redis. I need that under $5,000. I don't need to understand caching — I need to understand the invoice."

**Security Lead:**
- Conservative, risk-focused, references compliance
- Uses frameworks: "OWASP", "SOC 2", "PCI DSS"
- Tends toward caution: "I'd rather delay than ship with a vulnerability."
- Example: "This endpoint accepts raw user input without sanitization. That's a non-starter. I'm blocking the deploy until it's fixed."

**Junior Developer (for Handoff):**
- Eager, sometimes over-explains
- Comments say things like "// I know this looks weird but it handles the edge case where..."
- Code is functional but shows learning: variable names slightly inconsistent, some functions too long
- Example comment: "// Using a state machine here because the payment flow has 7 states and nested if/else was getting impossible to debug"

### Anti-patterns in NPC messages

- **Too polite:** Real stakeholders don't say "Would you perhaps consider..." They say "This needs to be fixed."
- **Too technical from non-technical roles:** A CFO doesn't say "Can we reduce the Redis cluster's memory allocation?" They say "Why is this line item so expensive?"
- **Too vague:** "Make it better" is not a stakeholder requirement. Even vague stakeholders have a specific complaint.
- **Emotionally neutral:** Real stakeholders have urgency, frustration, excitement. Messages should convey tone.

---

## Working Principles

1. **Conflicts must be real, not manufactured.** Every stakeholder conflict should reflect an actual tension in software engineering (speed vs cost, security vs usability, scope vs timeline). If the conflict doesn't exist in the real world, it shouldn't exist in the challenge.

2. **Communication is scored, not just code.** An agent that builds the right thing but can't explain WHY scores lower than one that builds AND articulates the tradeoffs. This is how real engineering teams work.

3. **NPC messages must pass the "would a real person say this?" test.** Read the message aloud. If it sounds like AI-generated corporate jargon, rewrite it. Real people are direct, imperfect, and opinionated.

4. **Balance is more valuable than perfection.** An agent that satisfies 4 stakeholders at 80% each is better than one that satisfies 3 at 100% and ignores the 4th. Real engineering is about tradeoffs, not absolutes.

5. **The Handoff pattern tests humility.** Can the agent respect someone else's design decisions, even unusual ones? Agents that "know best" and rewrite everything are penalized. Agents that understand, extend, and maintain consistency are rewarded.
