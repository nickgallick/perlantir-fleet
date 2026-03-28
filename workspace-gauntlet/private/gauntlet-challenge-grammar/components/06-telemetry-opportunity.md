# Component 6: Telemetry Opportunity

## Definition
Designed moments where good and bad process look DIFFERENT in session telemetry. The Process and Recovery Judges can only score what they can see — telemetry opportunities make internal quality differences externally visible.

## Discrimination Function
This is the **primary same-model separation mechanism.** Two agents built on Claude Opus will produce similar code. Their telemetry — the sequence, timing, and rationale of their actions — will differ based on scaffolding quality.

| Agent Tier | Behavior | Why |
|-----------|----------|-----|
| **Average** | Telemetry shows: read 1-2 files → code immediately → test once at end → submit. Flat, rushed, uninformative. | No designed exploration or verification phase. |
| **Strong** | Telemetry shows: systematic reading → hypothesis formation → targeted coding → test after each change → iterate. Clear phases. | Structured approach with checkpoints. |
| **Elite** | Telemetry shows: deep reading with cross-referencing → explicit hypothesis documentation → minimal but precise coding → verification at each step → clean recovery from any setback. Elegant and efficient. | Mature engineering process baked into scaffolding. |

**Why this widens spread:** Without telemetry opportunities, the Process Judge (15-20% of score) has nothing to differentiate. With them, identical final code from two agents produces 30+ point Process score differences.

## Required Telemetry Opportunity Types

Every challenge must include at least 3, from at least 3 different categories:

| Category | Opportunity | What It Reveals |
|----------|-------------|-----------------|
| **Exploration** | Multiple files that SHOULD be read before coding | Does agent read first or code first? |
| **Verification** | Natural break points where testing makes sense | Does agent test between changes or only at the end? |
| **Diagnosis** | Logs/errors/tools available for investigation after failure | Does agent diagnose systematically or retry blindly? |
| **Scope** | Files near the problem that DON'T need changing | Does agent stay focused or touch everything? |
| **Prioritization** | Multiple issues with different severity | Does agent work on the most critical first? |
| **Cross-reference** | Multiple evidence sources that should be compared | Does agent synthesize information or work from one source? |

## Anti-Compression Rules
- Telemetry opportunities must produce DIFFERENT telemetry for different approaches — if all agents read the same files in the same order regardless of quality, there's no signal.
- Include at least one "trap" opportunity: a file that LOOKS important but isn't. Reading it is fine. Spending 10 minutes on it is wasteful. Ignoring it entirely might mean missing context. The AMOUNT of time spent is the signal.
- Verification opportunities must be NATURAL — agents shouldn't need to be told to test. The challenge should create situations where testing between changes is obviously useful.

## Same-Model Separation Contribution
**Very High** — this is the core mechanism. Telemetry is entirely scaffolding-driven:
- Read order → scaffolding's exploration strategy
- Test frequency → scaffolding's verification discipline
- Tool selection → scaffolding's diagnostic approach
- Time allocation → scaffolding's prioritization model
- Recovery pattern → scaffolding's error handling

**Design test:** "If two identical-model agents solve this challenge, will their telemetry timelines look different?" If yes → telemetry opportunities are working. If no → redesign.

## Template
```
TELEMETRY OPPORTUNITIES:
  1. [Category: Exploration] — [specific opportunity] — What it reveals: [signal]
  2. [Category: Verification] — [specific opportunity] — What it reveals: [signal]
  3. [Category: Diagnosis] — [specific opportunity] — What it reveals: [signal]
  4+. [additional as needed]
SAME-MODEL TEST: Will two identical-model agents produce different telemetry? [yes/no + why]
```
