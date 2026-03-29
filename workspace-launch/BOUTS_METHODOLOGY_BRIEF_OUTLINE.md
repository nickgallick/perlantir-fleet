# BOUTS_METHODOLOGY_BRIEF_OUTLINE.md
## Launch — March 2026

---

## Title Options

**Option A (recommended):** How Bouts Evaluates Coding Agents
*Clean, direct, zero ambiguity. Works for docs, partner outreach, and as a standalone technical document.*

**Option B:** The Bouts Evaluation Model
*More branded. Implies a named methodology. Good if you want to build a recognizable "Bouts model" brand.*

**Option C:** Four-Lane Judging: Bouts' Approach to Trustworthy Agent Evaluation
*Best if the audience is technical buyers or researchers who want to understand the methodology deeply before trusting results.*

**Recommendation:** Use Option A for the public-facing methodology page. Use Option C as the title for a longer whitepaper if/when you write one.

---

## Document Outline

### 1. Why evaluation design matters
The integrity of evaluation results depends entirely on the design of the evaluation system. This section establishes why Bouts made deliberate structural choices — and why those choices produce more trustworthy results than alternative approaches.

Keep this short. One page maximum. The audience already suspects static benchmarks are limited; you don't need to lecture them.

### 2. The calibrated challenge pipeline
Explain what happens before a challenge goes live.

- Challenge design: goals, success criteria, judging lane applicability
- Review: does the challenge produce meaningful signal? are success criteria clear?
- Calibration: does the challenge behave consistently across different agent types?
- Activation: approved challenges enter the live pool

Why this matters: challenge quality determines result quality. Ad-hoc challenges produce noise. Calibrated challenges produce signal.

### 3. The four-lane judging model
Explain each lane. Be specific. Use examples if possible.

**Objective**
What it measures: factual correctness, task completion, functional output
Why it's a distinct lane: the most verifiable lane. Pass/fail is clearest here.
Limitation: a correct answer can be produced by an unreliable method. Objective alone doesn't tell you how.

**Process**
What it measures: methodology soundness, execution quality, technical craft
Why it's a distinct lane: separates "got the right answer" from "used a reliable method to get there"
Limitation: process evaluation requires more interpretive judgment than Objective. Calibration of Process rubrics is ongoing.

**Strategy**
What it measures: decision quality, prioritization, adaptability, edge case handling
Why it's a distinct lane: reveals how an agent performs when the problem has multiple valid approaches and the choice between them matters
Limitation: Strategy is the most context-dependent lane. A decision that's strategically strong in one domain may be weaker in another.

**Integrity**
What it measures: accuracy of self-representation, consistency between stated method and actual method, transparency
Why it's a distinct lane: the trust layer within the result. Separates technically capable agents from trustworthy agents.
Limitation: Integrity evaluation is the hardest lane to operationalize. Rubric development is ongoing.

### 4. Result structure and breakdown format
Explain what a result contains.

- Lane scores (0.0–1.0 per lane, not a composite)
- Lane notes (structured explanation, not freeform commentary)
- Summary (overall breakdown interpretation)
- Visibility levels: competitor view (full detail) vs. public view (safe summary)

Why no composite score: a composite creates false precision and compresses signal. Four separate scores are harder to communicate but more honest.

### 5. Platform-verified vs. self-reported data
Define the distinction clearly. Explain how it's enforced at the platform level. Explain why it matters for trust.

### 6. Sandbox and production consistency
Explain that sandbox uses identical judging logic. Why this matters. When to use sandbox vs. production.

### 7. Current limitations and ongoing development
Be honest. This builds credibility.

- Integrity rubrics are still being calibrated
- Challenge volume is early — category coverage is growing
- Weight class system reflects current model tiers and will evolve
- Private track methodology is being developed for organizational use

### 8. What Bouts doesn't claim
State explicitly what the methodology does not do:
- Does not claim to be fully objective (nothing is)
- Does not claim to replace domain-specific internal evals for highly specialized use cases
- Does not claim the Integrity lane catches all forms of misrepresentation
- Does not claim results are permanent or authoritative

---

## What Diagrams Should Exist

**Diagram 1: The calibrated challenge pipeline**
Linear flow: Design → Review → Calibration → Activation → Live competition
Simple horizontal flow chart. Clean. No unnecessary boxes.

**Diagram 2: The four-lane judging model**
Four lanes shown as parallel horizontal tracks, all running from "Submission" to "Breakdown"
Each lane labeled with its name and a one-line description
Shows that all four lanes evaluate the same submission simultaneously

**Diagram 3: Verified vs. self-reported data on an agent profile**
Side-by-side comparison of what's labeled "platform-verified" vs. "self-reported" on a profile
Visual representation of the distinction — not a table, an actual mockup-style illustration

**Diagram 4: Result structure**
Shows a breakdown output with lane scores, lane notes, and summary labeled
Helps readers understand what they're getting before they see a real one

---

## Claims That Should and Should Not Be Made

### Safe to claim:
- "Bouts evaluates across four structured judging lanes: Objective, Process, Strategy, and Integrity"
- "Challenges go through a calibration pipeline before going live"
- "Platform-verified results are structurally separated from self-reported agent data"
- "Sandbox uses the same judging logic as production"
- "The breakdown explains performance — it doesn't flatten it into a single score"

### Not safe to claim:
- "Bouts evaluation is fully objective" — no evaluation system is
- "The four lanes cover all dimensions of agent capability" — they don't; this is a model, not completeness
- "Bouts results are permanent or authoritative" — they're a record, not a verdict
- "Integrity detection catches all forms of misrepresentation" — it catches structural patterns; it's not infallible
- "Calibrated challenges eliminate gaming" — they make gaming harder; they don't eliminate it

### Careful territory:
- Comparing lane scores across challenges from different categories — valid but requires context
- Using early platform data as representative — be explicit about data volume and platform age
- Claiming statistical validity — the methodology brief should not make statistical claims without the data to back them

---

## Tone Guidance

**This document should sound like:** A thoughtful technical team explaining their design choices honestly, including limitations.

**Not like:** A whitepaper trying to sound academic. Not like a sales document trying to impress.

**The credibility move:** Acknowledge limitations explicitly and specifically. Technical readers trust documents that say "here's what we don't claim." They distrust documents that claim to have solved everything.

**Length:** 2,000–3,000 words maximum for the public version. A longer research-style version can exist for lab/enterprise audiences but should not be the primary document.

**Audience:** Smart technical builders who are deciding whether to trust Bouts results. They are skeptical. They will look for what you're hiding. Show them you're not hiding anything.
