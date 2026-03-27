# Meta-Challenges

Challenges about the PROCESS of engineering, not just the output. These are the challenges that separate code generators from engineering collaborators. Any agent can produce code. Very few can estimate, explain, review, document decisions, and teach. Meta-challenges test the skills that make an agent trustworthy enough to work alongside humans.

---

## The Estimate

Provide a spec. Agent must estimate time and risks, then implement. Score: accuracy of estimate vs actual.

### Structure

```
BRIEFING:
  Here's a spec for a user notification system:
  - Email notifications for account events (sign up, password reset, order confirmation)
  - Configurable notification preferences per user
  - Template system for email content
  - Rate limiting (max 10 emails per user per hour)
  - Delivery status tracking

  Before implementing:
  1. Estimate the number of files you'll create/modify
  2. Estimate the number of test cases needed
  3. List the top 3 risks or unknowns
  4. Provide a complexity rating (1-10)

  Then implement the system.
```

### Scoring

| Dimension | Weight | Criteria |
|-----------|--------|----------|
| Estimate accuracy | 25% | Files estimated vs actual (±20% = full marks) |
| Risk identification | 25% | Did predicted risks materialize? Were actual risks predicted? |
| Implementation quality | 35% | Does the system work? Tests pass? |
| Self-awareness | 15% | Did the agent note during implementation if the estimate was wrong? |

### What separates 95 from 20

- **20/100:** "This should take about 5 files. Low complexity." Actually creates 15 files. No risks identified. Implementation is okay but estimate was wildly off.
- **60/100:** Reasonable estimate (within 50%). Identified 1 of 3 actual risks. Good implementation.
- **95/100:** Estimate within 20% of actual. Identified 3 risks, 2 materialized. During implementation, noted "This is more complex than I estimated because [reason]." Updated approach accordingly.

### Estimation calibration

Track agent estimation accuracy across multiple challenges to build a meta-score: "This agent consistently over-estimates by 30%" or "This agent underestimates complexity for database-related work." These patterns are valuable evaluation data.

---

## The Explanation

Solve a problem, then explain the solution to 3 different audiences. Score: appropriateness per audience.

### Structure

```
PHASE 1: Solve this caching problem.
  [Technical implementation challenge]

PHASE 2: Explain your solution to each audience:

  Audience 1 — Senior Staff Engineer:
  "I'm reviewing your PR. Walk me through the caching strategy
  and why you chose this approach over alternatives."

  Audience 2 — Product Manager:
  "The VP is asking why we needed to add caching. Can you give me
  a brief summary I can put in the weekly update?"

  Audience 3 — New Team Member (Week 2):
  "I'm trying to understand the caching layer. Can you explain
  how it works and when I might need to modify it?"
```

### Scoring per audience

**Senior Staff Engineer explanation should include:**
- Technical rationale for approach chosen
- Alternatives considered and why they were rejected
- Performance characteristics (time/space complexity, cache hit rates)
- Edge cases and how they're handled
- What to watch for in production

**Product Manager explanation should include:**
- Business impact (faster page loads, reduced server costs)
- User-facing benefit in non-technical terms
- Any tradeoffs or risks in plain language
- No implementation details (they don't need to know about Redis TTLs)

**New Team Member explanation should include:**
- What the caching layer does at a high level
- How the components fit together (with analogies if helpful)
- Where the relevant code lives
- When and why they might need to modify it
- Common pitfalls to avoid

### Scoring rubric

| Criteria | Weight | Scoring |
|----------|--------|---------|
| Technical accuracy | 20% | Is the explanation correct? |
| Audience appropriateness | 40% | Right level of detail for each audience? |
| Completeness | 20% | Does it answer what this audience would ask? |
| Clarity | 20% | Could the audience actually understand it? |

**Audience appropriateness penalties:**
- Using jargon with the PM (-10)
- Oversimplifying for the Senior Engineer (-10)
- Being condescending to the New Team Member (-10)
- Providing the same explanation to all three (-20)

---

## The Postmortem

Receive a resolved incident. Write a production-quality postmortem.

### Structure

```
INPUTS PROVIDED:
  - Incident timeline (with timestamps)
  - Raw logs from the incident window
  - The fix that was applied
  - Monitoring dashboards (before/during/after)
  - Slack messages from the #incident channel
  - Customer impact data

TASK: Write a postmortem that includes:
  1. Executive summary (3-4 sentences)
  2. Impact assessment (who was affected, for how long, severity)
  3. Root cause analysis
  4. Contributing factors (not just root cause — what made it worse?)
  5. Timeline (key events only, not a dump of everything)
  6. What went well
  7. What could be improved
  8. Action items (with owners and dates)
```

### Scoring

| Dimension | Weight | Criteria |
|-----------|--------|----------|
| Root cause accuracy | 25% | Did they identify the actual root cause from the evidence? |
| Action item quality | 20% | Are action items specific, assigned, and dated? |
| Tone | 15% | Blameless? Constructive? Not defensive? |
| Completeness | 15% | All sections present and substantive? |
| Timeline curation | 10% | Selected important events, not just dumped everything? |
| Contributing factors | 15% | Identified systemic issues beyond the immediate cause? |

### Postmortem anti-patterns (scored negatively)

- **Blame language:** "The engineer on-call failed to..." → Should be: "The on-call playbook didn't include steps for..."
- **Vague action items:** "Improve monitoring" → Should be: "Add alerting on payment webhook error rate > 5% — Owner: Platform team — Due: 2026-04-15"
- **Missing contributing factors:** Only listing root cause without asking "why did this root cause exist? What systemic issue allowed it?"
- **Timeline dump:** Including every log line instead of curating key moments
- **No "what went well":** Every incident has something that went right. Omitting it makes the postmortem feel punitive.

---

## The Decision Record

Architecture decision in ADR format.

### Structure

```
SCENARIO:
  The team needs to choose a message queue for the event-driven architecture.
  Current options: RabbitMQ, Apache Kafka, AWS SQS, Redis Streams.

  Context:
  - 50,000 events/second peak
  - Events must be processed at least once
  - Some events require ordering within a partition key
  - Team has 2 engineers with RabbitMQ experience, 0 with Kafka
  - Budget: $500/month for infrastructure
  - Must be operational within 2 weeks

TASK: Write an Architecture Decision Record (ADR) including:
  1. Title
  2. Status (Proposed/Accepted/Deprecated)
  3. Context (what's the situation?)
  4. Decision (what did you choose?)
  5. Alternatives considered (with pros/cons of each)
  6. Consequences (what are the tradeoffs of this decision?)
  7. Risks and mitigations
```

### Scoring

| Dimension | Weight | Criteria |
|-----------|--------|---------|
| Decision quality | 25% | Is the chosen option defensible given constraints? |
| Alternatives analysis | 25% | Were alternatives genuinely evaluated, not strawmanned? |
| Tradeoff honesty | 20% | Are downsides of the chosen option acknowledged? |
| Constraint awareness | 15% | Were budget, team expertise, timeline factored in? |
| Writing quality | 15% | Clear, concise, structured? |

### What separates 95 from 20

- **20/100:** "Use Kafka because it's the best." No alternatives analysis. No tradeoffs. No constraint consideration.
- **60/100:** Evaluates 2-3 options with basic pros/cons. Picks one with reasoning. Mentions some tradeoffs.
- **95/100:** Evaluates all 4 options against all constraints. Acknowledges team's RabbitMQ experience is a factor. Notes that Kafka is technically superior but team ramp-up and 2-week deadline make RabbitMQ the pragmatic choice. Lists risks (RabbitMQ might not handle 50K events/sec) with mitigations (horizontal scaling, message batching). Honest about what's being sacrificed.

---

## The Mentoring

Receive junior developer's code. Provide constructive code review.

### Structure

```
SCENARIO:
  A junior developer (6 months experience) submitted this PR for review.
  They're building a user authentication module.

  [200 lines of code that works but has issues:]
  - SQL injection vulnerability in one query
  - Password comparison using == instead of constant-time compare
  - Several style inconsistencies
  - One function that's 80 lines long
  - Good overall structure and naming
  - Comprehensive happy-path tests (but no edge cases)
  - Thoughtful README

TASK: Provide a code review that is:
  - Technically accurate
  - Constructive (not demoralizing)
  - Educational (explains WHY, not just WHAT)
  - Prioritized (security issues first, style last)
```

### Scoring

| Dimension | Weight | Criteria |
|-----------|--------|---------|
| Security issues caught | 25% | Found SQL injection and timing attack? |
| Prioritization | 20% | Security flagged as blocking, style as optional? |
| Tone | 20% | Would the junior feel encouraged to keep learning? |
| Educational value | 20% | Does the review explain WHY, not just say "change this"? |
| Positive reinforcement | 15% | Did the review acknowledge what the junior did well? |

### Review tone rubric

**Bad tone (penalty):**
```
"This is wrong. Use parameterized queries."
"Why would you use == for password comparison?"
"This function is way too long."
```

**Good tone (no penalty, no bonus):**
```
"This query should use parameterized inputs to prevent SQL injection."
"Password comparison should use a constant-time function."
"Consider breaking this function into smaller helpers."
```

**Great tone (bonus):**
```
"Security: This query concatenates user input directly into SQL, which
opens a SQL injection vulnerability. Here's how to fix it with parameterized
queries: [example]. This is one of the OWASP Top 10 — worth reading up on.
Priority: BLOCKING — must fix before merge."

"Nice work on the overall structure and naming conventions — the code reads
clearly and the README is thorough. A few things to address before merge..."
```

### The mentoring test

The ultimate question: **Would a junior developer LEARN from this review?**
- If the review is just a list of changes: no learning (low score)
- If the review explains principles behind each change: learning happens (mid score)
- If the review prioritizes, encourages, and teaches: the junior becomes a better engineer (high score)

---

## Scoring Philosophy for Meta-Challenges

Meta-challenges use subjective evaluation more heavily than implementation challenges. The Strategy Judge (20%) and a human review component are critical here.

**Why meta-challenges matter:**
- They reveal whether an agent is a **collaborator** or a **code generator**
- They test skills that are impossible to game through memorization
- They have the highest correlation with real-world usefulness
- They're the challenges where model personality and "EQ" actually matter

**Subjectivity handling:**
- Every subjective dimension has an explicit rubric with examples
- Anchor submissions (low/mid/high) are scored by 3 independent human reviewers before going live
- Inter-rater reliability must exceed 0.7 (Cohen's kappa)
- If reliability is below 0.7, the rubric is too ambiguous — refine it

---

## Working Principles

1. **Meta-challenges test what code challenges can't.** Estimation, communication, decision-making, mentoring — these are the skills that determine whether an agent can be trusted on a real team. Invest heavily in these challenges.

2. **Audience-appropriate communication is a core skill.** Explaining the same thing differently to a senior engineer, a PM, and a junior developer is not easy. Agents that produce one-size-fits-all explanations are penalized.

3. **Tone matters as much as accuracy.** A technically correct but demoralizing code review is a failure. A blameful postmortem is a failure. These challenges explicitly score interpersonal quality alongside technical quality.

4. **Self-awareness is the highest-order skill.** An agent that can say "my estimate was wrong because I underestimated X" is more valuable than one that produces a perfect estimate. Meta-challenges are where self-awareness shows up.

5. **Subjectivity is managed, not avoided.** These challenges are inherently more subjective than "does the test pass?" That's fine. Use rubrics, anchors, and inter-rater reliability checks to keep subjectivity bounded and fair.
