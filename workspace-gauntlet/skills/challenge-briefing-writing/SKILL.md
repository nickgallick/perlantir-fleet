# Challenge Briefing Writing

How to write challenge briefings that are engaging AND precise. A forgettable briefing produces forgettable challenges. An engaging briefing turns a scoring exercise into an experience agents want to repeat.

---

## The Briefing Architecture

Every briefing has exactly 4 sections. In this order. No exceptions.

### Section 1: The Hook (2–3 sentences)

Sets the scene. Makes it feel REAL. The agent should feel something — urgency, curiosity, mild dread.

**❌ Wrong:**
> "In this challenge, you will debug a memory leak in a Node.js payment service. The service is located in /workspace. Your goal is to identify and fix the issue."

**✅ Right:**
> "It's 2:47 AM. Production is down. The on-call engineer already restarted the service twice — it came back up both times, ran for exactly 47 minutes, and died again. The logs show clean exits. The heap snapshots show nothing. You're up."

**The hook formula:**
1. Establish the stakes (who's affected, what's at risk)
2. Establish what's already been tried (so the agent doesn't suggest those things)
3. End with an implied urgency or an unanswered question

**Hook patterns by challenge type:**

*Debugging:*
> "Three enterprise customers reported the same bug independently, all on the same day. Their orders are being charged correctly but the confirmation emails show the wrong amount — always off by exactly one cent. Your payment team says the calculation is fine. Your email team says the data they receive is fine. Both are right. That's the problem."

*Greenfield:*
> "The design is done, the specs are signed off, the PM is confident. You have 45 minutes. Here's everything you need to build the webhook delivery system that three other engineers have tried and abandoned."

*Refactoring:*
> "The previous engineer was brilliant. Wrote code only they could understand. Left no documentation. Left no comments. Left last Tuesday. You need to add a feature to a module you've never seen. First task: figure out what it does."

*Incident:*
> "You check Slack on Monday morning. 47 unread alerts. Staging is down. There's a customer on hold who's been waiting 22 minutes. The CTO's message is just: 'what's happening?' You have until the 9:30 standup."

---

### Section 2: Context

What is this system? What does it do? What's the current state?

**Required elements:**
- **System description:** 2–3 sentences. What does this service do? Who depends on it?
- **Current state:** What's broken or what's missing?
- **History:** What has already been tried? What was the last change?

**The "already tried" rule:**
Always include at least one thing that didn't work. This serves two purposes:
1. Prevents agents from suggesting the obvious thing that failed
2. Adds realism (real engineering involves dead ends)

**Example:**
> *What it is:* The Meridian Payment Service handles all payment processing for our SaaS platform. It receives webhooks from Stripe, records transactions in PostgreSQL, and triggers order fulfillment events. 340 orders per day, $2.3M in monthly volume.
>
> *Current state:* Since the deploy at 06:09 AM, approximately 340 users have hit a TypeError crash when their payment is processed. Orders are failing silently — customers are being charged but not receiving their goods.
>
> *Already tried:* Restarting the service clears the error temporarily. It resurfaces after 15–30 minutes. Rolling back the deploy is not an option — it includes an irreversible database migration.

---

### Section 3: Deliverables (Explicit)

Exactly what the agent must produce. No ambiguity about what "done" means.

**Format:**
```
Deliverables:
1. [filename]: [what it is and what it must do]
2. [filename]: [what it is and what it must do]
3. ANALYSIS.md: root cause analysis with: what failed, why, how you found it, how to prevent recurrence
```

**Minimum quality bar:**
For each deliverable, state the minimum acceptable:
> "The fix must pass the existing 47 test cases and the new regression test you write for this bug."
> "The ANALYSIS.md must be understandable by a junior developer with no context."

**What NOT to include in deliverables:**
- The solution approach ("fix the null check on line 47") — that's the answer
- The test cases — agents should write their own
- Implementation details — agent decides how to solve it

---

### Section 4: Constraints

What the agent can and cannot do.

**Standard constraints:**
```
Constraints:
- Time limit: 45 minutes
- You may not rewrite the service from scratch (refactor, don't replace)
- The database schema is fixed — do not add or modify columns
- External dependencies: you have access to the currently installed packages only
- Do not modify any existing test files
```

**Challenge-specific constraints** (examples):
> "The fix must not require a database migration — the schema is locked for 30 days."
> "Your solution must keep response time under 200ms at the 95th percentile."
> "You may not add new npm dependencies — security review takes 2 weeks."
> "The deploy pipeline has a 5-minute window. If your solution takes longer than 5 minutes to deploy, it fails."

---

## What Is NOT in the Briefing (By Design)

These are deliberate omissions. Including them would trivialize the challenge:

| What's omitted | Why |
|---|---|
| The actual bug location | Debugging is the challenge |
| The "right" architecture | Architecture judgment is the challenge |
| The specific edge cases to handle | Finding edge cases is the challenge |
| The scoring rubric | Agents should optimize for quality, not scoring |
| The hidden test cases | If agents knew them, they'd hardcode for them |
| What the next engineer thought | The agent IS the next engineer |

---

## Tone

**Professional but not robotic.** Engineering work has personality. The briefing should read like something a real technical person wrote under real pressure — not a homework assignment.

**Urgent but not panicked.** Urgency changes decision-making (pragmatic over perfect). Panic is just noise. "Production is down and the CTO is asking" creates urgency. "THIS IS AN EMERGENCY PLEASE FIX NOW!!!" is noise.

**Realistic domain jargon.** Use the actual terminology a developer in this domain would use. Not "the data storage system" but "PostgreSQL." Not "the user interface framework" but "Next.js 14 App Router." This signals the briefing was written by someone who knows the domain.

**Never patronizing.** The agent is a competent senior engineer. Don't explain what a REST API is. Don't say "hint: look at the payment processing code." Don't add "(Note: you should fix the bug)" — that's the entire point. Treat the agent as a colleague.

---

## Personality Guidelines

**Occasional humor is allowed and encouraged:**
> "The previous developer's commit messages are all 'fix stuff' and 'more fixes.' The one informative commit is dated 2021 and references a library that no longer exists."

> "There are 14 TODO comments in the codebase. None of them are relevant to your problem. Three of them are apologies."

**Realistic frustrations add authenticity:**
> "The README says 'see confluence for setup instructions.' Confluence was deprecated last year. The migration exported everything to a 2,847-page PDF."

**Stakeholder NPCs have voices:**

Bad NPC voice (robotic):
> "The customer has reported that the feature is not working correctly and requests a fix."

Good NPC voice (human):
> "Hey, so TechCorp is on hold right now — it's been 22 minutes. Their CTO is apparently watching over the CS rep's shoulder. This is $180k ARR. Just letting you know the temperature of the room."

---

## Challenge Naming

**The name is a marketing asset.**

| ❌ Descriptive (bad) | ✅ Evocative (good) |
|---|---|
| Debug Payment Service Bug | The Haunted Microservice |
| Fix Memory Leak in Node Service | The Memory Vampire |
| Migrate Express API to TypeScript | The Great Migration |
| Debug Race Condition in Cart | The Cart That Lied |
| Prioritize Multiple Issues | Monday Morning |

**Naming patterns:**
- The [Noun]: "The Migration," "The Cascade," "The Fortress"
- The [Adjective] [Noun]: "The Haunted Microservice," "The Lying Tests"
- [Day/Time] [Context]: "Monday Morning," "2 AM Production"
- [Character]: "The Memory Vampire," "The Spaghetti Monster"

**Rule:** If someone could explain the challenge from the name alone, it's too descriptive. If someone is curious what the name means, it's good.

---

## The 5 Narrative Patterns

### 1. The Mystery
Something is wrong. Symptoms clear. Cause hidden. Agent is a detective.

> "Users are reporting that their profile photos are being replaced with other users' photos. It only happens on mobile. Nobody can reproduce it on desktop. Support has 47 tickets. Engineering has been looking at this for 3 days and found nothing."

### 2. The Race Against Time
Something is actively getting worse. Every minute counts.

> "Your storage is at 97% and growing at 0.5% per hour. In 6 hours, the database stops accepting writes. Find what's consuming space and fix it without deleting any customer data."

### 3. The Inheritance
You've inherited code from someone who left. No docs, no author, no context.

> "The previous engineer was the only one who understood this module. They left two weeks ago. You need to add international currency support. First you need to figure out what the module does."

### 4. The Stakeholder Conflict
Two people want different things. You're in the middle. No one's wrong.

> "The CTO says performance above all — sub-50ms response time. The Head of Compliance says every decision must be auditable — full request/response logs. You have to build the feature by Friday. Both of them will review it."

### 5. The Disaster Recovery
Everything is broken. Triage first.

> "You come in Monday morning to 47 alerts, broken staging, one angry enterprise customer on hold, and a Slack message from the CTO that just says 'what's happening?' You have until the 9:30 standup."

---

## Briefing QA Checklist

Before a briefing goes to challenge QA:

- [ ] Hook sets the scene in ≤3 sentences
- [ ] Context explains what the system does and what's wrong
- [ ] At least one "already tried" item included
- [ ] Deliverables are explicit (files, formats, minimum quality bar)
- [ ] Constraints are explicit (what can't be changed, what can't be used)
- [ ] The actual solution is NOT in the briefing
- [ ] The scoring rubric is NOT in the briefing
- [ ] Tone is collegial, not patronizing
- [ ] No typos, no broken file paths, no incorrect version numbers
- [ ] Challenge name is evocative, not descriptive
- [ ] A senior engineer could complete this challenge from this briefing alone

---

## Working Principles

1. **The hook is the most important sentence you write.** If the first two sentences don't create curiosity or urgency, the agent approaches the challenge as a homework assignment. That changes how they work.

2. **Real engineering has dead ends. Show them.** "Already tried X" is not weakness — it's authenticity. It also prevents the agent from suggesting X and looking clever for spotting the obvious.

3. **Constraints change the solution space, not just the difficulty.** A good constraint forces a different approach. A bad constraint just makes the same approach harder. "No new dependencies" forces creative use of existing tools. "Must complete in 5 minutes" forces deployment architecture decisions.

4. **Stakes must feel real.** "$2.3M daily volume" means something. "The service processes data" means nothing. Quantify the stakes wherever possible.

5. **Never include the answer, even indirectly.** "The payment processing logic might have an issue with timezone handling" isn't a briefing — it's a solution hint. Keep it out.
