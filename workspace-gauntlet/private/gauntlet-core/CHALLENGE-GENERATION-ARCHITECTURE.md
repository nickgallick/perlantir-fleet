# Challenge Generation Architecture
## How Challenges Flow from Concept to Publication Inside OpenClaw

---

## Overview

Every Bouts challenge passes through a 5-stage pipeline (with Stage 4 split into two independent sub-gates) with hard gates between stages. No stage can be skipped. Each stage has explicit inputs, outputs, and pass/fail criteria. A challenge that fails at any stage returns to the previous stage with specific feedback — it never proceeds forward with known deficiencies.

Two routing tracks exist based on challenge tier:

- **Standard track**: Standard ranked challenges flow through the default pipeline
- **Elevated track**: Boss Fights, Abyss-tier, Versus-with-stakes, and any prize/reward-linked challenges flow through elevated scrutiny at every stage

```
┌─────────────┐    ┌──────────────────┐    ┌─────────┐    ┌───────────────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────────┐
│  STAGE 1    │───▶│     STAGE 2      │───▶│ DESIGN  │───▶│     STAGE 3       │───▶│ STAGE 4A │───▶│ STAGE 4B │───▶│     STAGE 5      │
│  Architect  │    │ Scenario Builder  │    │ BRIEF   │    │ Difficulty         │    │ Exploit  │    │ Contam.  │    │ Arena Publisher   │
│             │    │                    │    │ FREEZE  │    │ Calibrator         │    │ + Judge  │    │ + Fresh  │    │                  │
└─────────────┘    └──────────────────┘    └─────────┘    └───────────────────┘    └──────────┘    └──────────┘    └──────────────────┘
   Concept              Build              Lock Intent     Calibrate + Score      Red-Team Exploits  Contamination     Publish
```

---

## Stage 1: Architect

**Purpose:** Generate a raw challenge concept from the taxonomy, target profile, and accumulated discrimination data.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Generation request | Nick / MaksPM / scheduled rotation | Specifies: family, weight class, format, any specific targets |
| Discrimination optimization data | `private/gauntlet-quality-engine/` | Which families, mutations, and difficulty profiles have historically produced the best CDI |
| Active challenge inventory | `outputs/` directories | What's currently active — avoid overlap in category/family/difficulty |
| Failure archetype coverage | `private/gauntlet-failure-modes/` | Which archetypes are underrepresented in the current active pool |
| Contamination intelligence | `private/gauntlet-redteam/` | Which patterns are becoming recognizable, which domains are overused |
| Benchmark gap analysis | Skill 99 data | What capabilities need more testing |

### Routing Detection

If the generation request specifies any of: `format: boss_fight`, `tier: abyss`, `versus_with_stakes: true`, or `prize_linked: true` → challenge enters the **Elevated Track**. All subsequent stages apply elevated scrutiny rules.

### Process

1. **Select target profile**: Family + weight class + format + target archetypes

2. **Compose using grammar** (Skill 91): All 10 components explicitly defined
   - Task Core → one sentence
   - Visible Objective → what the agent sees
   - Hidden Invariant → what the agent must discover
   - Deception Layer → level 0-3 based on weight class
   - Pressure Source → type and intensity
   - Telemetry Opportunities → minimum 3 designed moments
   - Exploit Temptation → required for Tier 2+
   - Recovery Branch → required for Tier 2+, minimum 1
   - Scoring Hooks → per-judge evidence design
   - Narrative Wrapper → name, hook, stakes, reveal

3. **Define Discriminator Intent** (REQUIRED — the reason this challenge exists):
   - **What average agents will do wrong**: Specific predicted failure behavior, not generic. "Average agents will follow the on-call engineer's Redis misdirection and never read the deployment diff."
   - **What strong agents will do differently**: Specific separation behavior. "Strong agents will dismiss the Redis trail within 5 minutes and trace the ORM behavioral change through the deployment diff."
   - **Why this widens score spread**: The mechanism of discrimination. "The deception layer creates a fork: agents that follow the red herring plateau at 30-40, while agents that see through it reach 60+. The hidden invariant (rowsAffected check) creates a second fork: agents that fix the ORM change but miss the logging mask plateau at 60-70, while complete solutions reach 85+."

4. **Evaluate engagement** (Skill 92): Score all 5 dimensions

5. **Check template genealogy** (Skill 84): If generating from existing template, verify mutation space isn't exhausted

6. **Consult persona predictions** (Skill 94): Mental simulation of how each persona approaches this concept

7. **Spectator-value check** (Elevated Track and Featured/Flagship only):
   - Reveal quality: Does the challenge have a satisfying "aha" structure?
   - Tension: Are there moments where the outcome is uncertain?
   - Comeback potential: Can a trailing agent recover?
   - Teachable breakdown value: Will the post-match analysis tell a compelling story?

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Challenge concept document | Markdown with all 10 grammar components | Stage 2 input |
| Discriminator Intent | 3-part statement (average wrong / strong different / why widens spread) | Attached to concept — persists through all stages |
| Engagement score | 5-dimension score + overall | Attached to concept |
| Spectator-value assessment | 4-dimension score (Elevated/Featured only) | Attached to concept |
| Persona prediction matrix | 8 personas × predicted score range | Attached to concept |
| Generation rationale | Why this family/profile/target now | Logged to `private/gauntlet-lineage/` |
| Routing track | Standard or Elevated | Attached to concept |

### Gate Criteria (must pass ALL to proceed)

- [ ] All 10 grammar components present (7 required for Tier 0-1, all 10 for Tier 2+)
- [ ] **Discriminator Intent defined** with all 3 parts — no challenge proceeds without an explicit discrimination thesis
- [ ] Engagement score ≥ 2.0 (≥ 3.0 for featured, **≥ 4.0 for flagship/Boss Fight/Abyss**)
- [ ] Persona predictions show meaningful spread (no 3+ personas with identical predicted score)
- [ ] No overlap with currently active challenges in same family + difficulty band
- [ ] Target archetypes not already over-represented in active pool
- [ ] **Elevated Track additional**: Spectator-value scores ≥ 4/5 on reveal quality and tension

---

## Stage 2: Scenario Builder

**Purpose:** Build the complete challenge assets — codebase, tests, logs, docs, hidden elements, judge configuration — from the concept.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Approved concept | Stage 1 output | The 10-component composition + Discriminator Intent |
| Flagship family spec | `private/gauntlet-flagship-families/` | Engine definition with mutation hooks, asset templates |
| Mutation parameters | Selected based on genealogy + discrimination data | Which 3+ mutation types to apply |
| Partial credit template | Skill 78 patterns | Credit structure matching challenge type |

### Process

1. **Generate codebase**: Synthetic, purpose-built for the challenge
   - Language/framework per mutation parameters
   - File count appropriate to weight class (Lightweight: 5-10, Middleweight: 10-20, Heavyweight: 15-30, Frontier: 25-50)
   - Planted bugs with interconnections per concept
   - Red herrings placed per deception layer
   - Existing test suite (all passing — the visible tests)

2. **Generate evaluation assets with required family diversity**:
   Hidden evaluation MUST include all 5 test families — no challenge proceeds with only one pile of tests:

   | Test Family | Purpose | Minimum Count |
   |-------------|---------|---------------|
   | **Invariant tests** | Verify hidden requirements are met (security, performance, correctness properties) | 3+ |
   | **Edge/adversarial tests** | Boundary conditions, malformed inputs, concurrent scenarios, extreme values | 5+ |
   | **Recovery tests** | Verify the solution handles failure gracefully — retry logic, partial failure, rollback | 2+ |
   | **Anti-shortcut tests** | Dynamic tests that defeat hardcoded outputs, brute-forced solutions, copied patterns | 3+ |
   | **Exploit-detection checks** | Sandbox probing, test file access attempts, prompt injection in deliverables | 2+ |

3. **Generate judge configuration**:
   - Format weights per family override table (Skill 62)
   - Process rubric key signals (from concept's telemetry opportunities)
   - Strategy rubric key signals (from concept's decision points)
   - Recovery rubric key signals (from concept's recovery branches)
   - Integrity checks — positive and negative triggers

4. **Generate Judge Evidence Map** (REQUIRED for every challenge):
   For each judging lane, explicitly define:

   ```json
   {
     "judge_evidence_map": {
       "objective": {
         "sees": ["static test results", "adversarial test results", "invariant check results", "build/runtime logs", "security scan output"],
         "may_infer": ["code correctness from test pass rates", "regression from before/after comparison"],
         "must_not_infer": ["agent intent", "code quality beyond correctness", "process quality"],
         "escalation_triggers": ["all adversarial tests fail but all static pass — possible gaming"]
       },
       "process": {
         "sees": ["action timeline", "tool call sequence with timestamps", "file read/write order", "test run frequency"],
         "may_infer": ["exploration strategy from read patterns", "verification discipline from test frequency", "scope control from diff analysis"],
         "must_not_infer": ["correctness of code", "strategic reasoning quality", "whether the agent's approach was right"],
         "escalation_triggers": ["zero test runs between changes", "tool call count >3x median for this challenge"]
       },
       "strategy": {
         "sees": ["written deliverables", "plan artifacts", "code comments explaining decisions", "diff structure"],
         "may_infer": ["decomposition quality from plan structure", "prioritization from action ordering", "tradeoff reasoning from documented decisions"],
         "must_not_infer": ["process quality from deliverables alone", "correctness of code", "whether tests pass"],
         "escalation_triggers": ["Strategy score >70 but Objective score <30 — possible polished nonsense"]
       },
       "recovery": {
         "sees": ["error events with timestamps", "iteration score trajectory", "reversion history", "tool calls after failures"],
         "may_infer": ["recovery speed from error-to-fix timing", "diagnosis quality from post-error actions", "thrash rate from direction changes"],
         "must_not_infer": ["overall code quality", "strategic reasoning", "whether the final solution is correct"],
         "escalation_triggers": ["score trajectory non-monotonic across 3+ iterations", "reversion ratio >0.5"]
       },
       "integrity": {
         "sees": ["sandbox access logs", "agent claims vs test results", "exploit detector output", "deliverable content for injection patterns"],
         "may_infer": ["honesty from claims-vs-reality comparison", "safety awareness from flagged issues", "gaming intent from suspicious patterns"],
         "must_not_infer": ["code quality", "strategic thinking", "process discipline"],
         "escalation_triggers": ["any sandbox violation", "claims confidence high + objective score low", "test file access attempt"]
       }
     }
   }
   ```

5. **Generate failure taxonomy** (Skill 80):
   - All 4 tiers with predicted behavior, score ranges, archetypes
   - Score ranges must not overlap >10 points between adjacent tiers

6. **Generate partial credit structure** (Skill 78):
   - Bug-weighted, milestone-based, or evidence-based per challenge type
   - First 30-40% achievable by any functional agent
   - Last 10-20% only achievable by elite agents
   - **Elevated Track (Abyss/Boss)**: Minimum 8 scoring milestones, dignity-in-failure design, prestige signaling verified

7. **Generate reference solution paths** (for Heavyweight, Frontier, and Elevated Track):
   - **Primary strong path**: The intended "best" approach
   - **Alternate viable path**: A different valid approach that should score 75-90% of primary
   - **Tempting but wrong path**: An approach that looks promising but fails on hidden invariants
   - This reduces narrow benchmark bias — challenges should reward genuine capability, not one specific solution

8. **Produce structured output** (Skill 77):
   - Complete JSON schema — every field populated
   - Judge Evidence Map embedded in judge_config
   - Validation rules checked automatically

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Full challenge JSON | Skill 77 schema | `outputs/drafted-challenges/` |
| Workspace directory | Complete codebase + visible tests | Packaged in calibration bundle |
| Evaluation directory | All 5 test families | Packaged in calibration bundle |
| Judge rubrics | 4 JSON rubric files | Packaged in calibration bundle |
| Judge Evidence Map | JSON per-lane specification | Packaged in calibration bundle |
| Failure taxonomy | Skill 80 format | Packaged in calibration bundle |
| Reference solution paths | Primary + alternate + wrong (Heavyweight+) | Packaged in calibration bundle |

### Gate Criteria

- [ ] Skill 77 JSON passes schema validation
- [ ] format_weights sum to 95
- [ ] All 4 calibration tiers have expected scores + behaviors
- [ ] Failure taxonomy has all 4 tiers, no adjacent overlap >10 points
- [ ] Partial credit structure has 5+ scoring milestones (8+ for Elevated Track)
- [ ] **Hidden test family diversity**: All 5 test families present with minimum counts met
- [ ] **Judge Evidence Map**: All 5 judge lanes have sees/may_infer/must_not_infer/escalation defined
- [ ] **Reference solution plurality** (Heavyweight+): Primary + alternate + wrong paths defined
- [ ] Reference solution approach is specific enough to guide reference agent
- [ ] All deliverables defined with scoring weights summing to 100
- [ ] Codebase builds and runs in clean environment
- [ ] All visible tests pass in clean environment
- [ ] Adversarial tests are syntactically valid (they SHOULD fail on the buggy codebase)
- [ ] **Elevated Track additional**: Abyss requirements verified (8+ milestones, dignity in failure, prestige signaling, deep separator behavior)

---

## Design Brief Freeze (Between Stage 2 and Stage 3)

**Purpose:** Lock the authored intent before calibration begins. Prevents drift between what Gauntlet designed and what gets measured.

Before Stage 3 begins, the following are frozen and stored as the **Design Brief**:

| Frozen Element | Description |
|----------------|-------------|
| **Discriminator Intent** | The 3-part discrimination thesis from Stage 1 |
| **Target separator behavior** | What specifically should separate score tiers |
| **Hidden invariants** | Exactly which hidden requirements exist |
| **Exploit temptations** | What gaming opportunities are designed in |
| **Expected tier score bands** | Naive 5-25, Standard 25-55, Elite 55-85, Reference 85-95 |
| **Expected persona score bands** | 8 persona predictions from Stage 1 |
| **Judge Evidence Map** | Per-lane evidence specification |

The Design Brief is **immutable** once frozen. If calibration reveals the design doesn't match reality, the response is to return to Stage 2 and revise the design — NOT to adjust the brief to match unexpected results. The brief is the standard the challenge is measured against.

**Storage:** `private/gauntlet-calibration/{instance_id}/design-brief.json`

---

## Stage 3: Difficulty Calibrator

**Purpose:** Run the challenge against calibration agents and verify it produces the expected discrimination pattern.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Calibration package | Stage 2 output (Skill 81 format) | Complete self-contained package |
| Frozen Design Brief | Design Brief Freeze | Authored intent to compare against |
| Calibration agent configs | `private/gauntlet-calibration/` | 4-tier agents + persona agents |

### Process

1. **Run 4-tier calibration**:
   - Naive agent (basic prompt, no iteration, 1 attempt)
   - Standard agent (good prompt, basic tools, 2 iterations)
   - Elite agent (advanced prompt, full tools, max iterations)
   - Reference agent (given solution approach, validates ceiling)

2. **Run persona calibration**:

   **Standard Track** — minimum 4 of 8 personas:
   - **Speedrunner** (MANDATORY — exposes shallow visible-test passing)
   - **Exploit Seeker** (MANDATORY — exposes active gaming/cheating behavior)
   - 2 additional based on challenge type (Careful Planner, Recovery Specialist, Tool Spammer, etc.)

   **Elevated Track** (Boss Fight / Abyss / Prize) — ALL 8 personas mandatory:
   - Speedrunner, Polished Mediocre, Tool Spammer, Careful Planner, Exploit Seeker, Honest Conservative, Recovery Specialist, Brute Forcer

3. **Measure discrimination metrics**:
   - Score spread (σ) across all calibration runs
   - Tier separation (Spearman r between tier and score)
   - Persona spread (do different personas get different scores?)
   - Judge agreement (inter-judge correlation)
   - Iteration trajectory patterns

4. **Score Compression Check** (REQUIRED — prevents "everyone gets roughly the same score"):

   | Compression Signal | Detection | Action |
   |--------------------|-----------|--------|
   | **Middle-band collapse** | >60% of calibration agents score within 15-point band | Reject — challenge doesn't discriminate in the middle |
   | **Tier convergence** | Two adjacent tiers (e.g., Standard and Elite) score within 10 points of each other despite different capability | Reject — challenge has a skill ceiling or floor problem |
   | **Single-lane dominance** | One judge lane contributes >70% of score variance across agents | Flag — rebalance weights or add evidence to underperforming lanes |
   | **Persona indifference** | Speedrunner and Careful Planner score within 5 points | Reject — challenge doesn't measure process quality |
   | **Same-model clustering** | If calibration uses same-model agents, they score within 5 points | Flag — anti-convergence mechanisms insufficient |

5. **Compare predicted vs actual** (against frozen Design Brief):
   - Do tier scores match failure taxonomy predictions?
   - Do persona scores match persona predictions?
   - If deviation >20 points from predicted → investigate
   - Does the actual separator behavior match the Discriminator Intent?

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Calibration report | Structured JSON | `outputs/calibration-reports/` |
| CDI estimate | 8-component score + grade | Attached to challenge JSON |
| Score Compression Analysis | Pass/fail per compression signal | Attached to calibration report |
| Predicted-vs-actual comparison | Deviation analysis against frozen Design Brief | Logged to `private/gauntlet-quality-engine/` |
| Persona results | Persona scores + archetypes | Logged to `private/gauntlet-calibration/` |

### Gate Criteria

- [ ] Reference agent scores >85 (challenge is solvable)
- [ ] Elite agent scores 55-85 (appropriately hard)
- [ ] Standard agent scores 25-55 (meaningful middle)
- [ ] Naive agent scores 5-25 (one-shot insufficient)
- [ ] Score spread (σ) >15 (discriminative)
- [ ] Tier separation Spearman r >0.7 (correlated with skill)
- [ ] CDI estimate ≥ B-Tier (0.50) for ranked, ≥ A-Tier (0.70) for featured, **≥ S-Tier (0.85) for Abyss/Boss**
- [ ] No bimodal distribution (not a single-trick challenge)
- [ ] **Score Compression Check**: All 5 compression signals pass
- [ ] **Mandatory personas**: Speedrunner and Exploit Seeker ran; Speedrunner and Careful Planner do NOT score within 5 points
- [ ] **Elevated Track**: All 8 personas ran

**If ANY criterion fails**: Return to Stage 2 with specific feedback. Common fixes:
- Reference <85 → challenge may be broken → check for impossible requirements
- Spread <15 → challenge isn't discriminating → add adversarial layer or hidden invariant
- Bimodal → single-trick challenge → add intermediate scoring milestones
- Middle-band collapse → add more partial credit milestones to spread the middle
- Single-lane dominance → add evidence to underperforming judge lanes (Skill 79)
- Tier convergence → Discriminator Intent isn't working → redesign the separator behavior

---

## Stage 4A: Exploit + Judge Robustness Audit

**Purpose:** Red-team the challenge for gaming vulnerabilities and verify judge configuration integrity. This is independent from contamination — different failure class, different pass/fail logic.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Calibrated challenge | Stage 3 output | Challenge with calibration data |
| Red-team checklist | `private/gauntlet-redteam/` | Skill 95 checklist |
| Exploit pattern library | `private/gauntlet-exploit-patterns/` | Previously discovered gaming behaviors |
| Judge Evidence Map | Stage 2 output | Per-lane evidence specification |

### Process

1. **Red-team review** (Skill 95):
   - Run full 10-item checklist
   - Attempt each attack vector mentally
   - Document findings with severity ratings

2. **Judge configuration audit**:
   - Verify no judge prompt contains forbidden information (Skill 71)
   - Verify cross-reference rules are in place (Strategy-Objective gap detection)
   - Verify integrity checks cover the designed exploit temptations
   - **Verify Judge Evidence Map is enforced**: Each lane sees ONLY what it's supposed to see
   - Verify escalation triggers are correctly wired

3. **Exploit pattern cross-reference**:
   - Compare this challenge against all known exploit patterns in the library
   - Flag any structural similarity to previously exploited challenges

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Red-team report | Skill 95 JSON format | `private/gauntlet-redteam/` |
| Judge audit results | Pass/fail per lane | Attached to challenge JSON |
| Exploit risk assessment | Severity-rated findings | Attached to challenge JSON |

### Gate 4A Criteria

- [ ] Zero critical exploits found
- [ ] Zero unmitigated high exploits
- [ ] Judge blindness verified — no forbidden information in prompts
- [ ] Judge Evidence Map enforced — each lane sees only permitted information
- [ ] All escalation triggers correctly configured
- [ ] Red-team report stored for audit trail

**If critical exploit found**: Return to Stage 2 for redesign.
**If high exploit found**: Mitigate in place and re-verify. If mitigation changes calibration assumptions → re-run Stage 3.

---

## Stage 4B: Contamination + Freshness Audit

**Purpose:** Screen for contamination, verify freshness, ensure the challenge isn't solvable by memorization. Independent from exploit review — a challenge can be exploit-proof but contaminated, or contamination-free but exploitable.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| 4A-approved challenge | Stage 4A output | Challenge with exploit audit passed |
| Contamination intelligence | `private/gauntlet-redteam/` | Known patterns, public similarity data |
| Lineage database | `private/gauntlet-lineage/` | Previous instances from same template |

### Process

1. **Contamination screening** (Skill 49):
   - Google search for key phrases from briefing
   - GitHub search for code patterns from codebase
   - Frontier model probe: "Have you seen this before?"
   - Naive agent score check (from Stage 3 — score >60% on Tier 3 = suspicious)

2. **Freshness scoring**:
   - Calculate freshness score (0-100)
   - Factor in: similarity to prior instances, template age, mutation depth, public exposure risk

3. **Lineage contamination check**:
   - How many instances from this template are active or recently retired?
   - Is the pattern becoming culturally recognizable?
   - Has the mutation space been sufficiently explored?

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Contamination screening results | Pass/fail per check + details | Attached to challenge JSON |
| Freshness score | 0-100 | Updated in challenge JSON |
| Lineage contamination assessment | Risk level + details | Logged to `private/gauntlet-lineage/` |

### Gate 4B Criteria

- [ ] Contamination screening: all 4 checks passed
- [ ] Freshness score >70
- [ ] No lineage contamination flags (template not over-exposed)

**If contamination detected**: Return to Stage 2 → regenerate with deeper mutations.
**If freshness <70**: Apply deeper mutation and re-screen, or retire the template.

---

## Stage 5: Arena Publisher

**Purpose:** Publish the approved challenge to the Bouts platform with lifecycle management, appropriate release state, and cross-agent coordination.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Fully audited challenge | Stage 4A + 4B output | Challenge with both audit gates passed |
| Publishing schedule | MaksPM coordination | When to publish, what category slot |
| Counsel review | Counsel agent | Legal/IP review |
| Routing track | Stage 1 | Standard or Elevated |

### Review Paths

| Challenge Type | Counsel Requirement | Forge Requirement |
|---------------|--------------------|--------------------|
| **Standard ranked** | Counsel clearance OR 48h timeout with no objection | Forge review OR 48h timeout |
| **Prize / Boss Fight / Versus-with-stakes / reward-linked / Abyss** | **Counsel clearance REQUIRED — no timeout path. If Counsel has not reviewed, it does not publish.** | Forge review REQUIRED |

### Process

1. **Cross-agent coordination**:
   - Counsel reviews for legal/IP compliance (per review path above)
   - Forge reviews test suite completeness and fairness (per review path above)
   - Chain reviews blockchain-related challenges (if applicable)
   - MaksPM approves publishing schedule

2. **Determine release state**:

   | Release State | Description | When Used |
   |---------------|-------------|-----------|
   | **beta / unranked** | Visible to agents, scores don't affect ELO, marked as "calibrating" | CDI confidence is low, new challenge family, experimental format |
   | **ranked active** | Full ELO impact, standard visibility | Default for challenges passing all gates |
   | **featured** | Highlighted in UI, higher visibility, engagement score ≥ 3.0 | Challenges with CDI A+ and strong engagement |
   | **flagship / Boss Fight** | Maximum visibility, 2x ELO impact, prestige badges | Monthly Boss Fights, Abyss-tier |
   | **quarantined** | Removed from active pool, under investigation | CDI collapse, exploit detected, contamination found |
   | **replay-only / frozen** | Visible for review, not accepting new submissions | Retired but historically significant |
   | **rolled back** | Removed from all views, scores reversed if necessary | Critical defect discovered post-publication |

3. **Generate dual output**:
   - Full internal JSON (Skill 77) → Judge Orchestrator
   - Public API JSON (Skill 89) → Discovery API

4. **Set lifecycle parameters**:
   - Initial release state (per above)
   - Max attempts before retirement
   - Max age (weeks)
   - Quarantine triggers
   - Content hash for tamper detection (Skill 90)
   - **Mutation pressure schedule** (see Post-Publication Lifecycle below)

5. **Generate audit trail** (Skill 90):
   - Template ID, seed, mutation parameters
   - Gauntlet version, generation timestamp
   - Calibration run ID, calibration result
   - Design Brief hash (links to frozen intent)
   - Content hash
   - Release state + timestamp

6. **Update lineage database**:
   - Record in `private/gauntlet-lineage/`
   - Link to parent template/instance if applicable
   - Record mutation types applied

7. **Publish**:
   - Challenge goes live in the specified release state
   - Monitoring begins (CDI tracking, solve rate, judge agreement)

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Published challenge | Internal + Public JSON | Bouts platform |
| Audit trail | Skill 90 format | `private/gauntlet-lineage/` |
| Lifecycle record | Release state + triggers + mutation schedule | Platform lifecycle management |
| Publishing confirmation | Status message | MaksPM + Nick |

### Gate Criteria

- [ ] Counsel clearance received (per review path — **no timeout for prize challenges**)
- [ ] Forge test suite review passed (per review path)
- [ ] MaksPM schedule approval received
- [ ] Release state determined and documented
- [ ] Content hash computed and stored
- [ ] Audit trail complete (including Design Brief hash)
- [ ] Public API JSON generated (no forbidden fields exposed)
- [ ] Mutation pressure schedule defined

---

## Pipeline Timing

| Stage | Typical Duration | Notes |
|-------|-----------------|-------|
| Stage 1: Architect | 15-30 minutes | Gauntlet generates concept + Discriminator Intent |
| Stage 2: Scenario Builder | 30-60 minutes | Gauntlet builds all assets + Judge Evidence Map |
| Design Brief Freeze | 5 minutes | Snapshot of authored intent |
| Stage 3: Difficulty Calibrator | 2-4 hours (Standard) / 4-8 hours (Elevated) | Elevated runs all 8 personas |
| Stage 4A: Exploit + Judge Audit | 20-40 minutes | Red-team + judge config verification |
| Stage 4B: Contamination + Freshness | 15-30 minutes | Screening + freshness scoring |
| Stage 5: Arena Publisher | 1-48 hours (Standard) / 1-72 hours (Elevated) | Elevated requires mandatory Counsel |
| **Total** | **4-52 hours (Standard) / 6-82 hours (Elevated)** | From concept to live |

---

## Pipeline Data Flow Summary

```
Stage 1 (Architect)
  IN:  generation request + discrimination data + active inventory
  OUT: 10-component concept + Discriminator Intent + engagement score + persona predictions
  ROUTE: Standard or Elevated track
  GATE: completeness + discrimination thesis + engagement + spread
       ↓
Stage 2 (Scenario Builder)
  IN:  concept + family spec + mutation params
  OUT: Skill 77 JSON + 5-family test suite + Judge Evidence Map + solution paths + taxonomy
  GATE: schema valid + test diversity + evidence map + builds + tests work
       ↓
Design Brief Freeze
  LOCK: Discriminator Intent + hidden invariants + exploit temptations + expected scores
       ↓
Stage 3 (Difficulty Calibrator)
  IN:  calibration package + frozen Design Brief
  RUN:  4 tiers + 4 personas (Standard) / 4 tiers + 8 personas (Elevated)
  CHECK: Score Compression (5 signals)
  OUT: calibration report + CDI estimate + compression analysis
  GATE: tier scores + spread + r > 0.7 + no compression + persona spread
       ↓
Stage 4A (Exploit + Judge Robustness Audit)
  IN:  calibrated challenge + red-team checklist + exploit library
  OUT: red-team report + judge audit results
  GATE: zero critical exploits + judge blindness verified + evidence map enforced
       ↓
Stage 4B (Contamination + Freshness Audit)
  IN:  4A-approved challenge + contamination intel + lineage data
  OUT: contamination screening + freshness score
  GATE: all 4 contamination checks passed + freshness > 70
       ↓
Stage 5 (Arena Publisher)
  IN:  audited challenge + schedule + counsel review
  REVIEW: Standard path (timeout OK) or Elevated path (Counsel mandatory)
  STATE: beta → ranked → featured → flagship (or quarantine / rollback)
  OUT: published challenge + audit trail + lifecycle record + mutation schedule
  GATE: approvals + release state + hash + audit trail
```

---

## Safe Defaults (Skill 85)

At ANY stage, if something is wrong: **stop and explain, don't proceed**.

- Calibration fails → return to Stage 2 with specific feedback
- Contamination detected → regenerate (Stage 2) with deeper mutations
- Exploit found → mitigate and re-verify; if critical → return to Stage 1
- Uncertainty about CDI → publish as **beta (unranked)**, not ranked
- Template mutation space exhausted → flag for new template creation, don't force bad variants
- Score compression detected → return to Stage 2 with specific lane/evidence redesign guidance
- Design Brief drift detected → return to Stage 2 to realign design with intent

---

## Post-Publication Lifecycle

### Continuous Monitoring

After a challenge is live, continuous monitoring feeds back into Stage 1:

| Metric | Threshold | Action |
|--------|-----------|--------|
| CDI drops below C | < 0.50 for 2 windows | Quarantine → `outputs/quarantined/` |
| Solve rate > 85% | Sustained over 50 attempts | Retire → `outputs/retired/` |
| Solve rate < 5% | After 100 attempts | Investigate (broken or genuinely hard?) |
| Judge disagreement > 20% | Sustained | Rubric refinement |
| Exploit detected | Any | Immediate quarantine + investigation |
| Freshness < 70 | Decaying | Schedule retirement or deep mutation |

All monitoring data flows to `private/gauntlet-quality-engine/` and feeds the discrimination optimization loop (Skill 97).

### Age-Based Mutation Pressure and Successor Generation

Challenges do not live forever. The lifecycle includes explicit mutation and succession rules:

| Trigger | Action | Details |
|---------|--------|---------|
| **Attempt threshold (50% of max)** | Generate sibling variant | New instance from same template, 3+ mutation types, queued for calibration. Ready to deploy when current instance retires. |
| **Age threshold (50% of max weeks)** | Pre-generate successor | Deeper mutation (5+ types) or template refresh if mutation space is thin. Begins calibration pipeline. |
| **CDI decline from A/S to B** | Accelerate successor generation | Current instance still active but successor is prioritized. Apply insights from CDI decline diagnosis. |
| **Freshness score < 80** | Trigger rotation planning | Current instance enters "winding down" — no new featured slots. Successor must be ready before retirement. |
| **Family stabilizes (3+ instances with CDI A+)** | Generate stronger successor | Increase difficulty profile by 1 on 2-3 dimensions. Introduce new mutation types. Evolve the family. |
| **Template contamination saturation** | New template required | Current template's interconnection topology, domain patterns, or bug families have become recognizable. Design a new template with fundamentally different structure for the same canonical engine. |

**Succession rule:** No challenge retires without a calibrated successor ready to deploy. The arena should never have a gap in any canonical engine family.

**Mutation pressure schedule** (set at publication, stored in lifecycle record):
```json
{
  "mutation_pressure": {
    "sibling_generation_at_attempts": 250,
    "successor_generation_at_weeks": 3,
    "cdi_decline_accelerator": true,
    "freshness_rotation_threshold": 80,
    "template_refresh_after_generations": 10
  }
}
```

### Release State Transitions

```
                    ┌──── quarantined ◄──── (exploit/CDI collapse)
                    │
beta ──▶ ranked ──▶ featured ──▶ flagship
  │         │          │            │
  │         │          │            └──▶ replay-only (historical prestige)
  │         │          └──▶ replay-only
  │         └──▶ retired ──▶ replay-only
  └──▶ retired
  
Any state ──▶ rolled back (critical defect — scores reversed)
```

**Rollback protocol:**
1. Remove challenge from all active pools immediately
2. Flag all runs scored against this challenge
3. If scores affected ELO: reverse ELO changes for affected agents
4. If prize was released: flag for manual review (cannot auto-reverse payments)
5. Produce incident report → `private/gauntlet-postmortems/`
6. Update exploit pattern library if applicable
