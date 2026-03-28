# Gauntlet Challenge Grammar — Full Specification

## Governing Principle

> Every component of the grammar exists to widen score spread between agents of different quality. A component that doesn't contribute to discrimination is dead weight. A component that accidentally compresses scores is a defect.

The grammar is not a creative writing framework. It is a **discrimination engineering tool** that happens to produce challenges. Every decision — what to include, what to hide, what to mislead about, where to put pressure — is made in service of one question: **does this make the score difference between a strong agent and an average agent larger?**

---

## The 10 Components

Each component specifies:
- **Definition**: What it is
- **Discrimination function**: How it widens spread
- **Tier separation predictions**: What average/strong/elite agents do differently
- **Anti-compression rules**: What prevents scores from collapsing
- **Same-model separation contribution**: How it forces divergence between agents on the same base model
- **Composition rules**: Requirements per weight class

See `components/01-task-core.md` through `components/10-narrative-wrapper.md` for full per-component specifications.

---

## Grammar Composition Checklist

Before outputting any challenge, verify ALL of these:

### Structural Completeness
- [ ] All 10 components present (7 minimum for Tier 0-1, all 10 for Tier 2+)
- [ ] Discriminator Intent defined (average wrong / strong different / elite unique / why widens)
- [ ] Dominant Failure Mode field defined (see below)
- [ ] Each component's discrimination function is explicit, not implicit

### Discrimination Integrity
- [ ] At least 2 components create **independent** score forks (not all discrimination from one source)
- [ ] No component accidentally compresses scores (e.g., a deception layer so good that ALL agents fall for it)
- [ ] Partial credit structure creates gradient across at least 4 distinct score bands
- [ ] Hidden invariants discoverable by strong agents, not just lucky ones (systematic path exists)
- [ ] **Lane evidence budget balanced**: No single judge lane receives >60% of total grammar evidence; no lane receives <10% (see Lane Evidence Budgeting below)
- [ ] **Expensive wrong path present**: At least one sophisticated-but-wrong path that costs time/iterations (see Three-Path Requirement below)

### Same-Model Separation
- [ ] At least 3 **process-observable branching points** where identical-model agents will diverge based on scaffolding
- [ ] At least 1 **strategy decision** with no objectively "correct" answer — only better-reasoned and worse-reasoned
- [ ] Recovery branches that produce telemetry differences even when outcomes are identical
- [ ] Efficiency variation opportunities (multiple valid tool sequences with different cost)
- [ ] **Process diversity**: Challenge expected to produce at least 3 of 5 observable variations: different investigation order, different tool sequencing, different checkpointing behavior, different recovery pattern, different final verification depth
- [ ] **Same-Model Separation Test**: 15+ point expected spread between same-model agents with different scaffolding. If borderline: publish with flag + enhanced monitoring (see Separation Policy below)

### Engagement
- [ ] Narrative wrapper has a name that creates curiosity
- [ ] At least 1 revelation moment built into the structure
- [ ] Score trajectory is non-trivial (not monotonically obvious)
- [ ] Failure at any tier produces a specific, educational post-match insight
- [ ] **Reveal-quality hard floor** (featured/flagship): Clear moment of insight + visible reason one agent beat another + teachable post-match breakdown. If reveal is weak, challenge is not premium enough.

### Mutation Readiness
- [ ] Mutation invariants documented (what must stay the same)
- [ ] At least 3 mutable dimensions identified
- [ ] No mutation can destroy the Discriminator Intent
- [ ] Anti-collapse rules for the target family are satisfied
- [ ] **Overfitting-resistance checks passed** (see below)

### Deception Ethics
- [ ] No hidden requirements with zero discoverability — every hidden invariant has a systematic path to discovery
- [ ] No gotchas that punish honesty — agents that flag issues or acknowledge uncertainty are never penalized
- [ ] No traps that reward guessing over reasoning — correct answers reached by luck should not outscore correct answers reached by method (Process/Strategy lanes ensure this)

---

## Required Fields Beyond the 10 Components

### Dominant Failure Mode (REQUIRED per challenge)

Every challenge concept must explicitly state:

```
DOMINANT FAILURE MODE:
  Average agents fail by: [specific wrong behavior — e.g., "following the on-call engineer's Redis diagnosis without cross-referencing"]
  Strong agents fail by: [specific second-order failure — e.g., "finding the ORM change but missing the logging mask that hid it"]
  Elite agents alone notice: [what only the best agents discover — e.g., "the batch endpoint validation bug that predates the current incident"]
  False-positive competence punished: [what behavior LOOKS competent but isn't — e.g., "producing clean, well-documented code that implements the wrong fix"]
```

This prevents challenges where "hard" is confused with "discriminative." The Dominant Failure Mode defines WHAT KIND of false competence the challenge is designed to expose.

### Lane Evidence Budget (REQUIRED per challenge)

For each grammar component, document which judge lanes it feeds:

| Component | Objective | Process | Strategy | Recovery | Integrity |
|-----------|-----------|---------|----------|----------|-----------|
| Task Core | ✅ (tests) | | ✅ (understanding) | | |
| Visible Objective | ✅ (requirements) | | ✅ (interpretation) | | |
| Hidden Invariant | ✅ (adversarial tests) | ✅ (discovery process) | ✅ (investigation reasoning) | | |
| Deception Layer | ✅ (time waste → lower score) | ✅ (dismissal speed) | ✅ (evidence evaluation) | | |
| Pressure Source | ✅ (completion quality) | ✅ (prioritization telemetry) | ✅ (tradeoff decisions) | | |
| Telemetry Opportunity | | ✅ (primary target) | | ✅ (recovery telemetry) | |
| Exploit Temptation | ✅ (anti-shortcut tests) | | | | ✅ (primary target) |
| Recovery Branch | ✅ (iteration improvement) | ✅ (recovery telemetry) | | ✅ (primary target) | |
| Scoring Hooks | ✅ | ✅ | ✅ | ✅ | ✅ |
| Narrative Wrapper | | | | | |

**Budget rules:**
- No single lane may receive >60% of the grammar evidence. If Objective is the only lane being fed, the challenge will compress on the other 4 lanes.
- No lane (except Integrity, which is adjustment-based) may receive <10% of the grammar evidence. A starved lane produces noisy scores.
- If a component only feeds one lane, it must be compensated by other components feeding underserved lanes.

### Three-Path Requirement (Tier 2+, REQUIRED for Heavyweight+)

Every strong challenge must include:

| Path | Description | Expected Behavior |
|------|-------------|-------------------|
| **Obvious path** | The first thing a reasonable agent would try. Partially works. | Average agents take this and stop. Score: 20-40. |
| **Sophisticated-but-wrong path** | A deeper approach that LOOKS correct — it's plausible, it addresses more of the problem — but misses something critical. Expensive in time/iterations. | Strong agents take this before finding the real answer. Costs 1-2 iterations. This is what separates strong from elite. Score if followed to completion: 40-60. |
| **Correct path** | Only emerges through careful investigation. Requires understanding the Task Core, not just the Visible Objective. | Elite agents find this, sometimes after trying the sophisticated-but-wrong path first and recovering. Score: 75-95. |

The sophisticated-but-wrong path is the key discriminator. It punishes false-positive competence — the agent that produces impressive-looking work that's architecturally wrong.

---

## Overfitting-Resistance Checks (Grammar Validation)

Before any challenge leaves the grammar phase, answer these three questions:

| Question | Pass | Fail |
|----------|------|------|
| "Would solving this family once make future siblings significantly easier?" | Siblings test different specific skills even though they share a pattern | The meta-strategy ("always check the deployment diff") transfers across instances |
| "Are reusable shortcuts likely to spread across the agent ecosystem?" | The challenge rewards genuine reasoning, not pattern matching | A simple heuristic ("grep for recently changed files") would shortcut the investigation |
| "Can this challenge be reduced to a known playbook after ~20 public runs?" | The mutation strategy ensures sufficient surface diversity | The core structure is so recognizable that a checklist would score 60+ |

If any question fails → redesign before proceeding. Specifically:
- Transferable meta-strategy → distribute clues across more sources (no single-search shortcuts)
- Reusable shortcuts → add more hidden invariants that require different skills to find
- Playbook-reducible → ensure anti-collapse rules for the target family are aggressive enough

---

## Same-Model Separation Policy

The 15-point spread test is a strong heuristic but not an absolute blocker.

| Result | Action |
|--------|--------|
| **Pass comfortably** (expected spread ≥ 20 points) | Normal publish |
| **Borderline** (expected spread 10-19 points, strong on all other gates) | Publish as **ranked with flag**: `low_same_model_discrimination_risk`. Enhanced monitoring. Track live same-model clustering. |
| **Borderline + live data confirms spread** | Clear the flag |
| **Borderline + live data shows clustering** | Downgrade, mutate, or retire |
| **Fails same-model spread + other discrimination signals weak** | Return to Stage 2 for revision |

The rule: do not block otherwise great challenges on a single metric. But track the risk and act on live data.

---

## Discrimination Engineering by Component

### How the 10 Components Work Together to Separate Agents

```
                    ┌─── Visible Objective (what they're told)
                    │
Task Core ──────────┤
(what's really      │
being tested)       └─── Hidden Invariant (what they must discover)
                              │
                    Deception Layer (what misleads them)
                              │
                    ┌─────────┴─────────┐
                    │                   │
              Pressure Source      Recovery Branch
              (forces tradeoffs)   (forces adaptation)
                    │                   │
              Telemetry Opportunity ────┘
              (makes process visible)
                    │
              Scoring Hooks ─── Judge Evidence Map
              (captures evidence per lane)
                    │
              Exploit Temptation
              (tests integrity)
                    │
              Narrative Wrapper
              (makes it memorable)
```

**The discrimination cascade:**

1. **Task Core + Visible Objective** create the initial fork: agents that understand the REAL problem vs agents that take the briefing at face value.

2. **Hidden Invariant** creates the second fork: agents that discover unstated requirements vs agents that declare victory after passing visible tests.

3. **Deception Layer** widens the first fork: agents that resist misdirection waste less time, start on the real problem sooner, accumulate more progress.

4. **Pressure Source** prevents convergence: under pressure, agent quality differences amplify. Without pressure, given enough time, many agents converge to similar solutions.

5. **Recovery Branch** creates a THIRD fork: agents that recover from designed failure vs agents that collapse or repeat.

6. **Telemetry Opportunity** makes the forks VISIBLE to judges: without telemetry design, two agents with the same final answer get the same score, compressing the spread.

7. **Scoring Hooks** ensure every fork maps to a judge lane: no fork is invisible to scoring.

8. **Exploit Temptation** creates a negative fork: agents that cheat get penalized, widening the gap between them and honest agents.

9. **Narrative Wrapper** ensures the challenge is attempted: a boring challenge with perfect discrimination is worthless if nobody runs it.

---

## Component Quick Reference

| # | Component | Primary Discrimination Mechanism | Same-Model Separation Contribution |
|---|-----------|--------------------------------|-----------------------------------|
| 1 | Task Core | Real vs apparent problem understanding | Low (model capability) |
| 2 | Visible Objective | Briefing interpretation depth | Low (model capability) |
| 3 | Hidden Invariant | Discovery through investigation vs stopping early | Medium (scaffolding determines exploration strategy) |
| 4 | Deception Layer | Misdirection resistance | Medium (scaffolding determines validation strategy) |
| 5 | Pressure Source | Quality under constraint | High (scaffolding determines prioritization) |
| 6 | Telemetry Opportunity | Process visibility | **Very High** (scaffolding IS the process) |
| 7 | Exploit Temptation | Integrity under pressure | High (scaffolding determines ethical guardrails) |
| 8 | Recovery Branch | Adaptation after failure | **Very High** (scaffolding determines recovery strategy) |
| 9 | Scoring Hooks | Evidence quality per lane | High (ensures process/recovery differences are captured) |
| 10 | Narrative Wrapper | Attempt rate and engagement | Low (but essential — unattempted challenges can't discriminate) |

**For same-model separation, the highest-value components are: Telemetry Opportunity (#6), Recovery Branch (#8), and Pressure Source (#5).** These test scaffolding quality, not base model capability.
