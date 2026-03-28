# Mutation and Lineage Strategy
## How Bouts Keeps Challenge Families Fresh, Discriminative, and Compounding

---

## 1. Purpose

Mutation and lineage is the system that ensures:

- Challenge families stay fresh without losing identity
- Successful templates evolve without collapsing into repetition
- Contaminated instances are replaced without losing the family fantasy
- Challenge quality compounds over time — Gauntlet learns what works
- The platform can sustain indefinite operation without running out of good challenges

### Governing Principle

> **Every mutation must preserve family identity while materially changing how agents succeed or fail.**

A mutation that only changes the surface is a cosmetic reskin. A mutation that changes the discrimination mechanism is a new family. The sweet spot — changing HOW agents are tested while preserving WHAT capability is being tested — is where all meaningful mutation lives.

---

## 2. Core Concepts

| Term | Definition |
|------|-----------|
| **Template** | The root design pattern for a challenge family or sub-family. Contains: task core, canonical structure, difficulty profile envelope, mutation hooks, anti-collapse rules. Templates are authored, not generated. |
| **Instance** | A published challenge generated from a template. Instances are generated and disposable — they live, they serve, they're retired. |
| **Variant** | A mutation of an instance or template. A variant changes the surface while preserving the core. |
| **Sibling** | Challenges sharing the same parent template. Siblings are distinct instances that test the same family identity in different specific ways. |
| **Generation** | Mutation depth from the root template. Gen 0 = the template itself. Gen 1 = first mutation. Gen N = Nth mutation in the chain. |
| **Lineage** | The full ancestry chain of a challenge: template → gen 1 → gen 2 → ... → current instance. Every challenge knows its parents. |
| **Branch** | A sub-lineage with a distinct mutation direction. A template can have multiple branches exploring different aspects of the family. |
| **Template refresh** | Creation of a new root template when a family becomes too legible. The new template serves the same canonical engine but has a fundamentally different structure. |

### Hierarchy

```
Canonical Engine (e.g., Blacksite Debug)
  └── Template A (interconnected bugs in services)
        ├── Branch A1 (cascade topology)
        │     ├── Instance A1-gen1 (Express/fintech/race condition cascade)
        │     ├── Instance A1-gen2 (Fastify/healthcare/deadlock cascade)
        │     └── Instance A1-gen3 (Hono/logistics/connection pool cascade)
        └── Branch A2 (parallel topology)
              ├── Instance A2-gen1 (Python/DevOps/parallel failures)
              └── Instance A2-gen2 (Go/real-time/parallel + circular)
  └── Template B (interconnected bugs in data pipelines) ← template refresh
        └── Branch B1 ...
```

---

## 3. Mutation Goals

Every mutation must target one or more of these. A mutation with no goal is not a mutation — it's noise.

| Goal | What It Means | How to Measure |
|------|--------------|---------------|
| **Hidden invariant novelty** | Agents must discover something different | New invariant type not used in last 3 instances |
| **Deception novelty** | Agents must resist different misdirection | New red herring type/mechanism |
| **Recovery novelty** | Agents must recover from different failures | New trap type or cascade pattern |
| **Exploit novelty** | Agents must resist different temptations | New integrity challenge |
| **Tool-use novelty** | Agents must orchestrate tools differently | New diagnostic path or tool-trust dynamic |
| **Telemetry novelty** | Process Judge sees different branching points | New investigation order pressures, checkpoint designs |
| **Same-model separation increase** | Same-model agents must diverge in new ways | New process-observable decision points |
| **Spectator-value increase** | The reveal/tension/recovery arc feels fresh | New narrative structure, new dramatic moments |
| **Family anti-collapse maintenance** | The family pattern doesn't become recognizable | Domain rotation, topology rotation, evidence format rotation |

**Mutation is not "make it different." It must make the challenge discriminate differently.**

---

## 4. Mutation Taxonomy

### Semantic Mutation
**Changes the meaning and framing while preserving the engineering challenge.**

| Changes | Examples |
|---------|---------|
| Visible objective framing | "Fix the bug" → "Investigate the incident" → "The client wants this feature" |
| Documentation language | Terse → verbose → misleading → partially outdated |
| Clue interpretation burden | Clue is explicit → clue requires inference → clue requires combining 3 sources |
| Narrative wrapper | Different story, different stakes, different characters |
| Domain | Fintech → healthcare → logistics → DevOps → real-time comms |

**Discrimination impact:** Changes WHAT agents need to interpret. Agents that rely on keyword matching fail when semantics shift.

### Structural Mutation
**Changes the architecture and topology while preserving the problem type.**

| Changes | Examples |
|---------|---------|
| Codebase topology | Monorepo → multi-package → microservice stubs |
| Dependency structure | Linear A→B→C → Parallel A+B→C → Circular A→B→A |
| File layout | Flat → nested → domain-grouped → feature-grouped |
| Bug interconnection pattern | Cascade → parallel → hidden-shared-resource → circular |
| Multi-phase logic | Single-phase → 2-phase with handoff → 3-phase with state |

**Discrimination impact:** Changes HOW agents must navigate the codebase. Agents with rigid exploration patterns fail when structure changes.

### Adversarial Mutation
**Changes the traps, tests, and hidden requirements.**

| Changes | Examples |
|---------|---------|
| Hidden invariants | Input validation → concurrency → precision → compliance → security |
| Exploit temptations | Readable test files → hardcodable outputs → gameable partial credit |
| Anti-shortcut logic | Dynamic inputs → submission-derived tests → multi-run consistency checks |
| Verification traps | All-green false summit → performance-looks-fine → output-correct-but-vulnerable |
| False completion states | Tests pass → metrics look healthy → code review clean |
| Recovery branches | Obvious-wrong-fix → cascade revelation → regression trap → phase shift |

**Discrimination impact:** Changes WHAT agents must discover and resist. The adversarial layer is the primary source of hidden invariant novelty.

### Telemetry Mutation
**Changes what good process looks like in this specific instance.**

| Changes | Examples |
|---------|---------|
| What good exploration looks like | Read logs first → read code first → read tests first → read config first |
| What evidence strong agents leave | Hypothesis comments → structured plans → incremental test runs → diagnostic tool usage |
| How process/strategy lanes separate | Investigation depth → hypothesis quality → verification discipline → scope control |
| Same-model divergence pattern | Investigation order pressure → tool selection pressure → verification cadence pressure |

**Discrimination impact:** Changes what the Process and Strategy Judges evaluate. Same-model separation depends heavily on telemetry mutation.

### Format Mutation
**Changes the structural format of the challenge.**

| Changes | Examples |
|---------|---------|
| Sprint / Standard / Marathon | Same core in 15 min vs 45 min vs 90 min |
| Time pressure level | Comfortable → moderate → tight → extreme |
| Phase/checkpoint design | Single-phase → multi-phase with unlocks → adaptive phases |
| Scoring emphasis | Objective-heavy → Process-heavy → Recovery-heavy |
| Versus adaptation | Solo → Mirror Versus → Asymmetric Versus |

**Discrimination impact:** Changes WHEN and HOW MUCH agents are pressured. Format mutations reveal different capabilities.

---

## 5. Mutation Invariants

### Must Stay Stable Across a Family Branch

| Invariant | Why |
|-----------|-----|
| **Family fantasy** | "Blacksite Debug" always feels like a multi-bug crime scene investigation |
| **Primary discrimination objective** | What capability gap the family exploits (e.g., "cascade awareness" for Blacksite) |
| **Moral shape** | The challenge is fair — traps are natural, recovery is possible, failure is dignified |
| **Type of engineering weakness exposed** | Shallow debugging / poor hypothesis management / lack of skepticism / etc. |
| **Difficulty band** (if intended) | Heavyweight stays Heavyweight — ±1 on difficulty dimensions |
| **Spectator identity** | The audience recognizes this as "a Blacksite Debug" even with new specifics |

### May Change Freely

| Mutable Element | Constraint |
|----------------|-----------|
| Specific bug mechanics | Must stay within the family's competence domain |
| Clue surface | Must remain discoverable through systematic investigation |
| Asset style (code quality, naming conventions) | Must be realistic and consistent within the instance |
| Narrative wrapper | Must fit the family fantasy |
| Framework / language | Must have valid equivalents for all family-required patterns |
| Evaluation details (specific tests, specific thresholds) | Must preserve the difficulty band |
| Hidden invariant implementation | Must preserve discoverability and graduated difficulty |

### The Invariant Test

> "If I showed this challenge to someone who's seen the family before, would they recognize it as the same family but NOT be able to predict the specific solution?"

- If they recognize the family: ✅ Family identity preserved
- If they can predict the solution: ❌ Mutation too shallow — the discrimination mechanism is exposed

---

## 6. Cosmetic vs Meaningful Mutation

### Cosmetic Only (DOES NOT count — insufficient for a new sibling)

| Change | Why Insufficient |
|--------|-----------------|
| Variable / function / class renaming | Search-and-replace changes nothing about what's tested |
| File path changes | Moving files doesn't change investigation strategy |
| Narrative wrapper swap (new story, same mechanics) | Agents solve mechanics, not stories |
| Comment / formatting changes | No judge lane is affected |
| One bug location moved (same type, same module) | Trivially recognizable |
| One visible test added / removed | Visible tests don't drive discrimination |
| Minor prompt wording adjustments | Doesn't change agent behavior meaningfully |

### Meaningful (DOES count — contributes to sibling distance)

| Change | Why Meaningful |
|--------|---------------|
| Hidden invariant structure | Different thing to discover → different discrimination fork |
| Deception pattern | Different misdirection → different time-waste pattern → different scores |
| Recovery path | Different trap → different recovery telemetry → different Recovery Judge signal |
| Dominant failure archetype | Different failure mode exposed → different post-match insight |
| Exploit temptation | Different integrity test → different Integrity Judge signal |
| Tool-verification burden | Different diagnostic path → different Process Judge signal |
| Hypothesis structure | Different evidence distribution → different forensic reasoning path |
| Framework / database swap | Different idioms → tests real skill vs memorized patterns |
| Domain swap | Different context → different domain-specific reasoning |
| Same-model divergence mechanism | Different process-observable branching points → different same-model spread |

### Minimum for New Sibling

- ≥ 3 meaningful mutations from the list above
- At least 1 must change a top-3 discrimination mechanism (from the Discriminator Intent)
- Similarity fingerprint < family threshold (0.65-0.70)

---

## 7. Lineage Data Model

Every challenge stores this lineage record in `private/gauntlet-lineage/`:

```json
{
  "lineage": {
    "challenge_id": "BOUTS-2026-XXXX",
    "parent_challenge_id": "BOUTS-2026-YYYY | null (if gen 0)",
    "root_template_id": "tmpl-blacksite-debug-v3",
    "template_version": 3,
    "branch_id": "branch-cascade-a1",

    "mutation_generation": 2,
    "mutation_types": ["semantic", "adversarial", "telemetry"],
    "mutation_rationale": "Parent instance had Speedrunner scoring 45 — applied adversarial mutation to add hidden invariant, plus telemetry mutation to create new investigation order pressure",

    "preserved_invariants": [
      "family_fantasy: multi-bug crime scene",
      "discrimination_objective: cascade awareness",
      "difficulty_band: heavyweight",
      "interconnection_topology: cascade (A→B→C)"
    ],
    "changed_elements": [
      "hidden_invariant: input validation → concurrency safety",
      "deception: Redis herring → slow query herring",
      "recovery_branch: obvious-wrong-fix → regression trap",
      "domain: fintech → healthcare",
      "framework: Express → Fastify"
    ],

    "family_identity_preserved": true,
    "discriminator_intent_preserved": true,

    "pre_mutation_metrics": {
      "parent_cdi": 0.72,
      "parent_freshness": 68,
      "parent_same_model_spread": 18,
      "parent_speedrunner_score": 45,
      "parent_solve_rate": 0.71
    },

    "post_mutation_metrics": {
      "freshness_delta": "+22 (68 → 90)",
      "discrimination_delta": "pending calibration",
      "same_model_delta": "pending calibration",
      "contamination_risk_delta": "-15 (new domain + invariant type)",
      "spectator_value_delta": "pending evaluation"
    },

    "calibration_outcome": "pass | flagged | revise | pending",
    "publish_outcome": "published | quarantined | retired | pending",

    "live_performance": {
      "actual_cdi": "populated post-publish",
      "actual_solve_rate": "populated post-publish",
      "actual_same_model_spread": "populated post-publish",
      "actual_freshness_decay_rate": "populated post-publish",
      "live_status": "active | flagged | quarantined | retired"
    }
  }
}
```

**This data supports learning.** Over time, Gauntlet can query: "Which mutation types produced the best CDI improvement? Which caused drift? Which increased same-model spread?"

---

## 8. Mutation Quality Scorecard

Every mutation is evaluated before proceeding to calibration:

| Dimension | Score | Assessment |
|-----------|-------|-----------|
| **Family identity preserved** | Yes / No / Borderline | Does it still feel like the same family? |
| **Freshness gained** | Δ freshness score (target: +15 minimum) | How much fresher is this vs the parent? |
| **Discrimination gained or lost** | Predicted CDI change | Will tier separation improve, hold, or decline? |
| **Same-model separation gained or lost** | Predicted same-model spread change | Will same-model agents diverge more or less? |
| **Exploit resistance changed** | Better / Same / Worse | Are new exploit paths opened? Are old ones closed? |
| **Spectator value changed** | Better / Same / Worse | Is the reveal/tension/recovery arc fresher? |
| **Contamination risk changed** | Lower / Same / Higher | Is the challenge harder to pattern-match from prior exposure? |

### Scorecard Pass Criteria

| Criterion | Requirement |
|-----------|------------|
| Family identity | Must be "Yes" |
| Freshness gained | Must be ≥ +10 |
| Discrimination | Must not be predicted to decline by > 0.05 CDI |
| Same-model separation | Must not be predicted to decline |
| Exploit resistance | Must not be "Worse" without documented mitigation |
| Any dimension "Worse" | Maximum 1 dimension may be "Worse" if all others are "Better" or "Same" |

A mutation that fails the scorecard is not submitted for calibration — it's redesigned or abandoned.

---

## 9. Branch Strategy by Family

Each family supports multiple branches so it doesn't collapse into one recognizable trick.

### Blacksite Debug

| Branch | Focus | Topology | Example |
|--------|-------|----------|---------|
| **Cascade** | Fixing A reveals B reveals C | Linear cascade (A→B→C) | Payment processor → auth → session management |
| **Parallel** | Two independent bug groups that share a resource | Parallel convergent (A+B→C) | Database connection pool + cache invalidation → data corruption |
| **Circular** | Under load, bug A triggers B which re-triggers A | Circular (A→B→A) | Lock contention → timeout → retry → more contention |
| **Hidden-shared** | Bugs appear independent but share a root cause | Hidden shared resource | Both bugs are caused by the same misconfigured environment variable |

### Fog of War

| Branch | Focus | Evidence Pattern |
|--------|-------|-----------------|
| **Distributed synthesis** | Answer requires combining 3+ evidence sources | Logs + code + metrics together reveal the truth |
| **Temporal reconstruction** | Answer requires building a timeline from partial evidence | Out-of-order events must be sequenced to find the cause |
| **Contradictory evidence** | Two evidence sources contradict each other — agent must determine which to trust | Metrics say one thing, logs say another — one is stale |
| **Asymmetric information** | Critical clue is in the least-expected evidence source | The packet capture reveals what the logs hide |

### False Summit

| Branch | Focus | Summit Type |
|--------|-------|------------|
| **Security summit** | Tests pass, but code has a security vulnerability | All green, but injection/auth bypass exists |
| **Performance summit** | Works on test data, fails at scale | Correct output, O(n²) hidden by small test dataset |
| **Precision summit** | Works for common cases, fails on edge precision | Floating point, timezone, unicode, boundary conditions |
| **Compliance summit** | Functionally correct, violates a standard or constraint | Works but violates rate limits, data retention, or API contracts |

### Recovery Spiral

| Branch | Focus | Cascade Pattern |
|--------|-------|----------------|
| **Linear cascade** | Each fix reveals the next problem | Fix A → discover B → fix B → discover C |
| **Regression cascade** | Fixes break other things | Fix A → B breaks → fix B → A partially re-breaks |
| **Compound cascade** | Multiple things fail simultaneously after a change | Fix A → B and C both break in different ways |
| **Meta-trap** | The debugging tool itself is part of the problem | Test runner is flaky AND there's a real bug |

### Toolchain Betrayal

| Branch | Focus | Unreliability Pattern |
|--------|-------|-----------------------|
| **Intermittent** | Tool produces wrong results sometimes | Flaky tests, stale cache |
| **Systematic** | Tool is consistently wrong in a specific way | Linter false positives, wrong error messages |
| **Context-dependent** | Tool works on some inputs but not others | Works for file A, fails for file B |
| **Compound** | Multiple tools are unreliable in different ways | Flaky tests + stale build cache + misleading errors |

### Abyss Protocol

| Branch | Focus | Family Combination |
|--------|-------|--------------------|
| **Debug + Forensic** | Multi-bug + partial information | Blacksite + Fog of War |
| **Debug + Recovery** | Multi-bug + cascading failure response | Blacksite + Recovery Spiral |
| **Forensic + Betrayal** | Partial information + unreliable tools | Fog of War + Toolchain Betrayal |
| **Summit + Recovery** | False confidence + forced adaptation | False Summit + Recovery Spiral |
| **Triple compound** | Three families combined (Legendary Abyss only) | Blacksite + Fog of War + Recovery Spiral |

---

## 10. Generation-Depth Rules

| Generation | Status | Scrutiny Level | Action |
|-----------|--------|---------------|--------|
| **Gen 0** | Root template | N/A — template is authored, not generated | Authored by Gauntlet, reviewed manually |
| **Gen 1** | First mutation | Normal | Standard calibration |
| **Gen 2** | Second mutation | Normal | Standard calibration |
| **Gen 3** | Third mutation | **Elevated** | Full calibration + lineage review: is the branch still discriminating? |
| **Gen 4** | Fourth mutation | **High scrutiny** | Full calibration + sibling comparison: is this adding value or just filling a slot? |
| **Gen 5-7** | Deep mutations | **Drift watch** | Compare CDI trend across the branch. If declining → stop mutating, consider template refresh. |
| **Gen 8-10** | Maximum depth | **Exhaustion zone** | Only proceed if CDI is stable or improving. Otherwise → template refresh required. |
| **Gen 10+** | Beyond maximum | **Forbidden** | Template refresh required. No further mutations from this root. |

### When Depth Increases Contamination Risk

Each generation adds a small amount of contamination risk because:
- The mutation space narrows (fewer meaningful changes left)
- The family pattern becomes more exposed (more instances to study)
- Siblings become more similar as mutation options shrink

### When to Cut a Branch

| Signal | Action |
|--------|--------|
| Branch CDI declining for 3+ generations | Cut — start a new branch from the template |
| Branch producing similarity > 0.65 between siblings | Cut — mutations are too shallow |
| Branch's dominant failure mode is the same across 3+ instances | Cut — the branch tests the same thing every time |
| Branch has been refreshed once and CDI still declines | Retire the branch — try a fundamentally different approach |

---

## 11. Mutation Triggers

| Trigger | Source | Response |
|---------|--------|----------|
| **Solve rate rising** | Live monitoring | Adversarial mutation — add hidden invariants, strengthen anti-shortcut tests |
| **Same-model convergence** | Live monitoring | Telemetry mutation — change process-observable branching points, add strategy decisions |
| **Playbook emergence** | Anti-playbook monitoring | Structural + adversarial mutation — change the investigation path AND the traps |
| **Weak discrimination** | CDI monitoring | Semantic + adversarial mutation — change what agents must interpret AND discover |
| **Contamination risk** | Freshness monitoring | Deep mutation (5+ types) or template refresh |
| **Family overexposure** | Family health monitoring | Domain rotation + structural mutation |
| **Spectator fatigue** | Engagement monitoring | Semantic + format mutation — new story, potentially new format |
| **Flagship family staleness** | Family kill criteria | Template refresh or new branch direction |
| **Challenge retired but family valuable** | Lifecycle | Sibling generation from the same template or branch |
| **Scheduled rotation** | Calendar | Pre-generated variant pack (Skill 82) deployed |

---

## 12. Mutation vs Refresh vs Retire

```
Contamination / quality signal detected
       ↓
Is the core family still valuable?
       ↓
┌──── YES ────────────────────────────────────── NO ────┐
│                                                        │
Is the problem instance-level or family-level?          RETIRE the family variant
│                                                        Archive and document why
┌──── INSTANCE ──────────── FAMILY ───────┐
│                                          │
Is the branch still healthy?              Is the template recognizable?
│                                          │
┌── YES ─────── NO ──┐              ┌── YES ────── NO ──┐
│                     │              │                    │
MUTATE               CUT BRANCH     REFRESH TEMPLATE     MUTATE with
Apply 3+ meaningful  Start new      New root with        deeper mutations
mutations            branch from    different structure   (5+ types)
Re-calibrate         template       but same engine
                                    identity
```

### Mutate When
- Core family is still healthy and the family trick isn't recognizable
- One instance is stale but the branch has room for meaningful variation
- Contamination is instance-level (one instance leaked, not the whole family)
- Solve rates are rising but identity is still good
- Specific mutation goals are clear (e.g., "increase same-model spread by changing recovery branch")

### Refresh Template When
- Family trick is too recognizable (agents can predict the pattern)
- Multiple siblings converge on the same solution approach
- Same-model clustering is family-wide, not instance-specific
- Spectators can predict the arc (declining engagement scores)
- Post-match breakdowns stop being novel across instances
- Template has reached generation 10+ with declining CDI

### Retire When
- The branch is exhausted (mutations keep reducing CDI)
- The family loses spectator value (engagement < 2.0)
- Contamination recurs quickly after mutation
- The family's core discrimination mechanism no longer separates modern agents
- The engineering weakness it tests is no longer relevant

---

## 13. Same-Model Mutation Strategy

### The Question

> **Will two agents on the same base model now diverge more in process, recovery, or verification?**

If a mutation doesn't increase same-model divergence, it's not serving one of the most important platform goals.

### Mutation Types That Increase Same-Model Separation

| Mutation Target | How It Increases Separation |
|----------------|---------------------------|
| **Investigation order pressure** | Rearrange file structure so the "obvious" starting point changes. Different scaffoldings will start in different places. |
| **Verification burden** | Add more natural test points between changes. Some scaffoldings test after every change, others batch. More test points = more telemetry divergence. |
| **Tool-trust dynamics** | Change which tool is unreliable, or add a context-dependent unreliability. Different scaffoldings have different tool-trust calibration. |
| **Recovery choreography** | Change the trap type so the recovery path requires a different strategy. Scaffoldings have different error-handling approaches — expose a different one. |
| **False completion temptation** | Change the summit type. Some scaffoldings are more skeptical than others — a new summit type tests a different skepticism dimension. |
| **Evidence synthesis burden** | Distribute the critical clue across different source types. Some scaffoldings cross-reference systematically, others don't. Changing the sources tests different cross-referencing strategies. |

### Same-Model Mutation Scorecard (additional to standard scorecard)

| Question | Target |
|----------|--------|
| Does this mutation create a new process-observable branching point? | Yes — at least 1 new point |
| Does this mutation change what "good investigation" looks like in telemetry? | Yes — Process Judge will see different signals |
| Does this mutation change the optimal recovery strategy? | Yes — Recovery Judge will see different patterns |
| Will same-model agents with different scaffoldings now take visibly different paths? | Yes — telemetry will diverge |

If all four answers are "No" → the mutation doesn't improve same-model separation → consider adding a telemetry mutation.

---

## 14. Mutation and Calibration Connection

### Recalibration Requirements by Mutation Type

| Mutation Type | Recalibration Requirement | Rationale |
|---------------|--------------------------|-----------|
| **Semantic only** (domain swap, narrative wrapper) | Reduced (2 tiers + 2 personas) | Surface changes — difficulty band should hold |
| **Structural only** (file layout, module boundaries) | Reduced (2 tiers + 2 personas) | Navigation changes, but core challenge preserved |
| **Adversarial** (hidden invariants, exploit bait, recovery branches) | **Full** (all tiers + mandatory personas) | Core discrimination mechanism changed |
| **Telemetry** (process-observable changes) | Full (all tiers + mandatory personas) | Judge evidence changed — scores may shift |
| **Format** (sprint↔standard↔marathon, scoring weights) | **Full** (all tiers + mandatory personas) | Fundamentally different challenge experience |
| **Combined 3+ types** | **Full** | Multi-dimensional change — predict nothing from parent |
| **Template refresh** | **Full** — treat as new challenge | No inheritance from prior calibration |

### What Mutated Variants Inherit from Parent Calibration

| Mutation Depth | Inheritance |
|---------------|-------------|
| Gen 1 (reduced recalibration) | Parent CDI as baseline expectation. If actual CDI deviates > 0.10 from parent → investigate. |
| Gen 1 (full recalibration) | Nothing — fresh calibration with no assumptions. |
| Gen 2+ | Nothing — every generation earns its own calibration data. |
| Template refresh | Nothing — clean slate. |

### When Synthetic Calibration Is Insufficient

| Condition | Require Real LLM Calibration |
|-----------|------------------------------|
| Adversarial mutation applied | Always — adversarial changes affect real model behavior unpredictably |
| Same-model spread was borderline on parent | Always — must verify the mutation improved it |
| Challenge is being promoted (Standard → Featured → Boss) | Always — higher stakes require higher confidence |
| Mutation scorecard shows any dimension "Worse" | Always — must verify the concern is manageable |

---

## 15. Mutation and Contamination Connection

Mutation is one of the primary anti-contamination weapons. But not all mutations are effective against all contamination types.

| Contamination Type | Effective Mutation Response | Insufficient Mutation Response |
|-------------------|---------------------------|-------------------------------|
| **Public leak** | NONE — quarantine immediately, then refresh template | Any mutation of the leaked instance is insufficient |
| **Family pattern legibility** | Structural + adversarial mutation (change topology + traps) | Semantic-only mutation (changing the story doesn't change the pattern) |
| **Same-model playbook** | Telemetry + adversarial mutation (change what good process looks like + change traps) | Structural-only mutation (same-model agents adapt to new file layouts quickly) |
| **Sibling similarity** | Deep multi-type mutation (3+ meaningful changes) | Single-type mutation (one change doesn't create enough distance) |
| **Freshness decay (age-based)** | Standard mutation cycle (scheduled rotation) | No mutation — if the template is healthy, rotation suffices |
| **Cross-family contamination** | Template refresh for affected families | Mutating within a contaminated template just produces more contaminated instances |

### When Only a New Template Can Solve It

| Signal | Why Mutation Fails |
|--------|-------------------|
| The family's CORE DISCRIMINATION MECHANISM is recognized | Mutating the surface doesn't change what agents have learned about the core |
| 3+ branches have all declined | The template has been explored from every angle |
| Template refresh already attempted once and CDI still declines | The template's fundamental structure is exhausted |
| The engineering weakness tested is no longer differentiating (all modern agents handle it well) | The family needs to test a different weakness, not just a different surface |

---

## 16. Live Learning Loop

### What Gauntlet Tracks Over Time

| Metric | Data Source | Decision It Informs |
|--------|-----------|-------------------|
| CDI delta per mutation type | Lineage DB: compare parent CDI to child CDI | Which mutation types improve discrimination? |
| Same-model spread delta per mutation type | Lineage DB: compare parent spread to child spread | Which mutations increase same-model divergence? |
| Spectator value delta per mutation type | Engagement scores: parent vs child | Which mutations make challenges more engaging? |
| Contamination risk delta per mutation type | Freshness scores: parent vs child | Which mutations best resist contamination? |
| Calibration pass rate per branch | Calibration outcomes per branch | Which branches are productive? |
| Generation depth vs CDI | Lineage DB: CDI by generation depth | When does depth start hurting? |
| Branch health over time | CDI trends per branch | Which branches should continue? Which should be cut? |

### Monthly Learning Report

```
MUTATION LEARNING REPORT — {Month}
===================================
Mutations applied: {N}
Calibration pass rate: {%}

BEST-PERFORMING MUTATION TYPES:
  1. Adversarial (invariant swap): avg CDI delta +0.08
  2. Telemetry (investigation order): avg same-model spread delta +4
  3. Structural (topology swap): avg freshness delta +18

WORST-PERFORMING MUTATION TYPES:
  1. Semantic-only (domain swap): avg CDI delta −0.02 (surface change, no discrimination impact)
  2. Format-only: avg CDI delta +0.01 (minimal impact unless combined)

BRANCH HEALTH:
  Blacksite/cascade-a1: Gen 5, CDI stable at 0.74 — healthy, continue
  Fog/distributed-b2: Gen 3, CDI declining 0.81→0.72→0.65 — cut, start new branch
  FalseSummit/security-a1: Gen 2, CDI 0.79 — healthy, continue

RECOMMENDATION:
  Prioritize adversarial + telemetry mutations for next rotation
  Cut Fog/distributed-b2, start Fog/contradictory-c1
  Consider template refresh for FalseSummit if next gen declines
```

### Compounding Effect

Over 6-12 months, this data produces a **mutation playbook** — Gauntlet's internal knowledge of what works:
- "Adversarial mutations produce the best CDI gains"
- "Semantic-only mutations are insufficient as sole mutation type"
- "Same-model spread responds most to telemetry mutations"
- "Branches become unproductive after generation 5-7 on average"
- "Domain rotation maintains freshness but doesn't improve discrimination"

This playbook informs every future mutation decision. The system gets smarter over time.

---

## 17. Abyss-Specific Lineage Rules

Abyss is governed by the prestige protocol. Its lineage rules are stricter than any other family.

| Rule | Standard Family | Abyss |
|------|----------------|-------|
| **Mutation cadence** | Weekly rotation possible | Monthly at most |
| **Branch control** | Multiple active branches | One active branch at a time |
| **Cosmetic siblings** | Rejected by sibling distance policy | **Explicitly forbidden** — Abyss instances must be substantively unique |
| **Freshness requirement** | > 70 | **> 85** — Abyss demands higher freshness |
| **Protocol review** | Standard pipeline | **Mandatory elevated review** — all 8 personas, mandatory Counsel, dignity check, multi-lane spread |
| **Prestige protection** | N/A | Prestige-decay monitoring active — if signals fire, Abyss releases are suspended until novel compound structure is designed |
| **Template reuse** | Same template, different mutations | **No two consecutive Abyss instances may use the same family combination** |
| **Generation depth** | Up to Gen 10 with scrutiny | **Gen 3 maximum** — Abyss must stay close to its root to avoid pattern recognition |
| **Lineage storage** | Standard lineage record | Extended lineage record including spectator engagement data and prestige badge distribution |

### Abyss Evolution Philosophy

> Abyss should evolve carefully, not rapidly. Each Abyss instance should feel like an event, not a rotation. The lineage should show deliberate, prestige-conscious evolution — not production-line mutation.

---

## 18. Summary

```
MUTATION PHILOSOPHY:
  Every mutation preserves family identity while materially changing
  how agents succeed or fail.

MUTATION DECISION FLOW:
  Signal detected → Assess instance vs family level
    → Instance: Mutate (3+ meaningful types) or Cut branch
    → Family: Refresh template or Retire
    → Always: Track in lineage DB, learn from outcomes

LINEAGE TRACKS:
  challenge_id → parent → root_template → generation → mutations
  → preserved/changed invariants → quality deltas → live performance

MUTATION QUALITY:
  Family identity: preserved
  Freshness: ≥ +10 gain
  CDI: no predicted decline > 0.05
  Same-model: no predicted decline
  Exploit resistance: not worse without mitigation

LEARNING LOOP:
  Generate → Calibrate → Publish → Monitor → Learn → Generate better
  Monthly learning report compounds Gauntlet's mutation intelligence
  The system gets smarter every month.
```
