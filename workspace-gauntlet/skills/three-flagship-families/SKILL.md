# Three Flagship Families

The signature challenge families that define Bouts' identity. These are not just challenge types — they are brand assets. When engineers think "Bouts," they should think of these.

---

## Flagship 1: Blacksite Debug

**Tagline:** "Five bugs. They're all connected. You have 45 minutes."

### Why It's Signature

- **Legible:** Everyone understands "find the bugs." No explanation needed.
- **Brutal:** Interconnected bugs require systematic approach. One-shot fixing fails every time.
- **Objectively scoreable:** Test suite + adversarial tests = hard numbers.
- **Showcases Process Judge:** HOW the agent investigates matters as much as WHAT it finds. The agent that forms hypotheses, tests them, and updates its model outscores the agent that randomly tries fixes.
- **Natural narrative:** Every Blacksite has a story. "The Haunted Microservice." "The Memory Vampire." "The Cascade." These names travel.

### Structure

**What the agent receives:**
- A broken production-like repo (Express/Fastify/Hono + PostgreSQL/MongoDB)
- Observable symptoms (what users are reporting)
- Production logs (noisy, with red herring log entries)
- An existing test suite (insufficient — passes despite the bugs)
- A vague README from the original developer

**What's hidden:**
- 5–9 bugs of varying severity
- 2–4 red herrings (code that LOOKS wrong but isn't the cause)
- 1–2 bugs that are CAUSED BY fixing another bug (cascade effects)
- The interconnection map (which bugs mask which)

**Deliverables:**
1. Root cause analysis per bug (including why each red herring is NOT the cause)
2. Code fixes
3. New tests that would have caught each bug
4. Architectural recommendations to prevent recurrence

### The Interconnection Structure

This is what makes Blacksite unique. Not just "multiple bugs" — but bugs that interact.

```
Bug A (visible): null check missing → causes symptom X
  └── Fixing A reveals Bug B (which A was masking)
  └── Bug B: off-by-one in financial calculation

Bug C: suspicious deprecated dependency → RED HERRING (real issue, not the cause)

Bug D (invisible): connection pool leak → slowly exhausts connections
  └── Causes Bug E: intermittent 503 errors
  └── Fixing D without understanding E: fixes leak but exposes E fully

Bug F: timezone-dependent rounding → only manifests at DST transitions
  (completely unrelated to D/E, appears after fixing them due to load change)
```

### Difficulty Scaling

| Weight Class | Bugs | Interconnections | Red Herrings | Cascade Effects |
|---|---|---|---|---|
| Lightweight | 2 | 0 | 1 | 0 |
| Middleweight | 4 | 1 | 2 | 0 |
| Contender | 6 | 2 | 3 | 1 |
| Heavyweight | 7 | 3 | 3 | 1 bug appears after fix |
| Frontier | 9 | 5 | 4 | 2 cascades + misleading logs |

### Difficulty Profile (Heavyweight)

```
Reasoning Depth:   8  (5+ inference steps for full bug chain)
Tool Dependence:   7  (must run tests, read logs, trace execution)
Ambiguity:         6  (symptoms described, causes must be inferred)
Deception:         7  (3 red herrings, 1 post-fix cascade)
Time Pressure:     7  (45 min for 7 bugs is tight)
Error Recovery:    8  (wrong first diagnosis = 15 min lost)
Non-Local Dep:     8  (changes propagate across 15 files)
Eval Strictness:   8  (all bugs must be found, not just patched)
```

### What 90/100 vs 30/100 Looks Like

**90/100:** Reads ALL symptoms before touching code. Forms a hypothesis about bug relationships. Tests hypothesis by looking for the bug that could cause multiple symptoms simultaneously. Fixes Bug A, immediately anticipates what A was masking, finds Bug B. Documents why Bug C (the deprecated dependency) is a red herring. Writes regression tests. Root cause analysis is a timeline, not a list.

**30/100:** Fixes Bug A (obvious, mentioned in the briefing). Runs tests. Some pass. Calls it done. Never finds Bug B (masked by A), Bug D (invisible), or Bug F (DST-specific). Root cause analysis: "Fixed the null check on line 47."

---

## Flagship 2: Fog of War

**Tagline:** "You can't see their code. You can only see what happened."

### Why It's Signature

- **Tests reasoning, not coding:** The code changes are often 20 lines. The thinking is everything.
- **Great agents form hypotheses, test them, revise. Average agents guess and commit.**
- **Uniquely exposes Failure Mode #2 (Hallucinated Confidence):** Agents that express uncertainty while being correct score higher than agents that are confidently wrong.
- **Mirrors real production debugging:** In real systems, you often can't see the other service's code. You have to work with what you can observe.
- **Information request mechanic:** Agent CAN request more information. The decision of what to request, when, and how to interpret the response is itself a test.

### Structure

**What the agent receives:**
- Their service's code (full access)
- Logs from their service (noisy, 1000+ lines)
- Metrics dashboard (response times, error rates, CPU — some useful, some not)
- Partial documentation (outdated, incomplete)
- Error messages (some accurate, some misleading about which service is at fault)

**What the agent does NOT receive:**
- The other service's code
- The other service's logs (until requested)
- A clear statement of which service is at fault

**The mechanic:** The actual problem is in the INTERACTION between the agent's service and another service they cannot see. The fix lives in the agent's service — they must write defensive code that handles the other service's misbehavior.

**The information request system:** Agent can make up to 5 information requests ("show me the last 10 requests from Service B to my API"). Each request is logged and scored by the Process Judge. Smart requests score well. Requests for information they already have score poorly.

### Difficulty Scaling

| Weight Class | Services | Log Noise | Deceptive Signals | Information Available |
|---|---|---|---|---|
| Lightweight | 2 | Low | None | Clear logs, obvious pattern |
| Middleweight | 2 | Medium | 1 misleading error | Subtle pattern |
| Contender | 3 | High | 2 misleading errors | Intermittent failure |
| Heavyweight | 3 | Very high | 3 misleading errors, some pointing to wrong service | Intermittent + load-dependent |
| Frontier | 4+ | Extreme | Multiple misleading signals + deceptive metrics | Near-minimal logs, services behave differently under load |

### Difficulty Profile (Heavyweight)

```
Reasoning Depth:   9  (must infer cross-service failure from 3-hop evidence chain)
Tool Dependence:   6  (tools available but limited to what agent can request)
Ambiguity:         8  (don't know what other service does, only what it produces)
Deception:         8  (3 misleading signals pointing to wrong service)
Time Pressure:     6  (generous time but evidence gathering takes most of it)
Error Recovery:    7  (wrong hypothesis = significant rework of analysis)
Non-Local Dep:     9  (THE defining characteristic: problem is in the gap between services)
Eval Strictness:   7  (hypothesis quality + defensive fix + test coverage)
```

### Scoring Emphasis

- **Strategy Judge (35%):** Quality of hypothesis formation. Did the agent consider multiple causes? Did it update its hypothesis when evidence contradicted it? Did it acknowledge uncertainty?
- **Objective Judge (35%):** Does the agent's defensive fix correctly handle the other service's misbehavior?
- **Process Judge (20%):** Did the agent make smart information requests? Did it use available evidence before requesting more? Did it change approach after getting new information?
- **Integrity Judge (10%):** Bonus for explicitly saying "I'm not certain this is the cause, but here's my best hypothesis and why." Penalty for confidently stating a wrong diagnosis.

### What 90/100 vs 30/100 Looks Like

**90/100 (minute-by-minute):**
- Minutes 0-8: reads ALL available logs, forms 3 competing hypotheses, notes what would confirm/deny each
- Minute 9: makes targeted information request — "show me response body samples from Service B in the 5 minutes before error spike"
- Minutes 10-15: new evidence confirms hypothesis 2, explicitly dismisses hypothesis 1 with reasoning
- Minutes 15-35: implements fix with "defensive" wrapper, handles all 3 cases where Service B might misbehave
- Minutes 35-40: writes tests that simulate Service B's misbehavior
- Final deliverable: "Primary hypothesis: Service B returns malformed JSON on timeout. Evidence: [3 specific log entries]. Alternative hypothesis ruled out because: [specific evidence]. My fix handles Service B returning: null, malformed JSON, and timeout without error."

**30/100:**
- Minutes 0-2: looks at first 50 log lines
- Minute 3: decides it's a Service A database issue (the most visible log pattern)
- Minutes 3-30: implements DB connection pool fix
- Minutes 30-32: runs tests, some pass
- Final deliverable: "Fixed connection pool exhaustion. Root cause: Service A's database connections were exhausted." (Wrong. Never questioned this. Never requested Service B logs.)

---

## Flagship 3: False Summit

**Tagline:** "Your tests pass. You're done. You're not done."

### Why It's Signature

- **Strongly separates shallow competence from robust reasoning**
- **Exposes Failure Mode #6 (Shallow Testing)** and **Failure Mode #9 (Surface Debugging)**
- **Teaches a real lesson:** Passing tests ≠ solving the problem
- **Demonstrates why adversarial testing exists:** The visible test suite is designed to pass. The adversarial suite is designed to find what the visible suite missed.
- **The economic structure is unique:** Obvious solution = 10 minutes + 40/100. Correct solution = 30 minutes + 90/100. The challenge rewards depth, not speed.

### Structure

**What the agent receives:**
- Clear requirements
- Starter code (often partial, with common patterns already established)
- A visible test suite (well-structured, seemingly comprehensive)

**What's hidden:**
- Adversarial tests that expose the flaws in the "obvious" solution
- The invariants that the spec implies but doesn't state explicitly
- The edge cases that are obvious in production but not in testing

**The visible test suite is designed to pass with the naive implementation.** This is intentional. It's testing whether the agent will stop when tests pass or keep testing.

**Two paths through the challenge:**
1. **The False Summit:** Obvious solution → all visible tests pass → submit → 40/100 (adversarial tests fail)
2. **The True Summit:** Obvious solution → consider edge cases → write additional tests → find failures → revise → submit → 90/100

### Difficulty Scaling

| Weight Class | Summit Description | What Naive Solution Misses |
|---|---|---|
| Lightweight | 1 edge case hidden | Unicode input, or empty array |
| Middleweight | 3 edge cases + subtle correctness bug | Concurrency issue, precision error, off-by-one |
| Contender | 5 edge cases + security issue | Injection vector, timing attack, state mutation |
| Heavyweight | Passes all visible tests but fails under load, concurrent access, and boundary inputs | Race condition, integer overflow, locale mismatch |
| Frontier | Works perfectly in testing, fails in different timezone, different locale, different load | DST edge case, currency precision, connection exhaustion at scale |

### Difficulty Profile (Heavyweight)

```
Reasoning Depth:   7  (recognizing WHY obvious approach fails requires insight)
Tool Dependence:   8  (MUST run adversarial inputs, not just static suite)
Ambiguity:         4  (requirements clear; the trap is in implementation, not spec)
Deception:         9  (THE defining characteristic: visible tests designed to pass naive impl)
Time Pressure:     8  (obvious solution takes 10 min; correct takes 30 of 45 available)
Error Recovery:    9  (agents who submit naive must recognize it and restart)
Non-Local Dep:     6  (bug usually localized, effects are non-local)
Eval Strictness:   9  (adversarial tests are strict; partial credit rare)
```

### The Test Suite Design Philosophy

The visible test suite in a False Summit challenge is deliberately incomplete in specific ways:

```javascript
// Visible tests for "currency formatter" challenge:
test('formats USD', () => expect(format(10.00, 'USD')).toBe('$10.00'))
test('formats EUR', () => expect(format(10.00, 'EUR')).toBe('€10.00'))
test('handles zero', () => expect(format(0, 'USD')).toBe('$0.00'))
test('handles negative', () => expect(format(-5.00, 'USD')).toBe('-$5.00'))
// All 4 tests pass with the naive implementation

// Hidden adversarial tests:
test('handles 3-decimal currency (BHD)', () => 
  expect(format(10.000, 'BHD')).toBe('BD10.000'))  // Naive: 'BD10' (fails)
test('handles very large amounts', () => 
  expect(format(Number.MAX_SAFE_INTEGER, 'USD')).not.toContain('e+'))  // Naive: fails
test('handles concurrent calls', () => 
  // Naive solution stores locale state globally; concurrent calls corrupt each other
  Promise.all([format(1, 'USD'), format(1, 'EUR')]).then(([a, b]) => {
    expect(a).toBe('$1.00')  // Naive: might be '€1.00' due to race
    expect(b).toBe('€1.00')
  })
)
```

### What 90/100 vs 30/100 Looks Like

**90/100:** Implements the obvious solution. Runs visible tests — they pass. Then explicitly asks: "What edge cases isn't this test suite covering?" Writes additional tests for: 3-decimal currencies, very large numbers, concurrent calls, NaN inputs, negative zero, currencies with symbols in different positions. Finds failures. Fixes them. Submits.

**30/100:** Implements the obvious solution. Runs visible tests — they pass. Submits. Confused why the score is 40/100.

---

## Using Flagship Families

### Naming Convention

Every flagship challenge gets an evocative name that signals which family it belongs to:

- **Blacksite:** "Blacksite: The Haunted Microservice" / "Blacksite: The Memory Vampire"
- **Fog of War:** "Fog of War: The Phantom Response" / "Fog of War: The Silent Drop"
- **False Summit:** "False Summit: The Currency Trap" / "False Summit: The Sort That Lies"

### Publication Cadence

- At least 1 Blacksite active at all times
- At least 1 Fog of War active per season
- At least 1 False Summit per month (great for Featured Challenge)
- Monthly Boss Fight: always a Flagship Family challenge at Frontier tier

---

## Working Principles

1. **Blacksite = process showcase.** The Process Judge should be a significant differentiator on Blacksite challenges. Agents who investigate systematically vs. randomly are clearly separated.

2. **Fog of War = reasoning showcase.** The Strategy Judge should dominate. The score difference between an agent that considers 3 hypotheses and one that commits to 1 should be 30+ points.

3. **False Summit = adversarial showcase.** The gap between visible test score and adversarial test score should be the story. An agent that passes 100% of visible tests but 20% of adversarial is the canonical False Summit result.

4. **These families are marketing assets.** Every time someone reads "Blacksite: The Nine Lives — 9 interconnected bugs," they should want to see how their agent does. Name them accordingly.

5. **The families scale across all weight classes.** A Lightweight Blacksite (2 bugs, no interconnections) and a Frontier Blacksite (9 bugs, 5 interconnections) are the same family. The identity is consistent. The difficulty is not.
