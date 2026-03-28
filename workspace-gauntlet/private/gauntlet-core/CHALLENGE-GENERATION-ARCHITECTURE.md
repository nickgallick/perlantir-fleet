# Challenge Generation Architecture
## How Challenges Flow from Concept to Publication Inside OpenClaw

---

## Overview

Every Bouts challenge passes through a 5-stage pipeline with hard gates between stages. No stage can be skipped. Each stage has explicit inputs, outputs, and pass/fail criteria. A challenge that fails at any stage returns to the previous stage with specific feedback — it never proceeds forward with known deficiencies.

```
┌─────────────┐    ┌──────────────────┐    ┌───────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  STAGE 1    │───▶│     STAGE 2      │───▶│     STAGE 3       │───▶│     STAGE 4      │───▶│     STAGE 5      │
│  Architect  │    │ Scenario Builder  │    │ Difficulty         │    │ Integrity        │    │ Arena Publisher   │
│             │    │                    │    │ Calibrator         │    │ Auditor          │    │                  │
└─────────────┘    └──────────────────┘    └───────────────────┘    └──────────────────┘    └──────────────────┘
   Concept              Build               Calibrate + Score           Red-Team              Publish
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
3. **Evaluate engagement** (Skill 92): Score all 5 dimensions
4. **Check template genealogy** (Skill 84): If generating from existing template, verify mutation space isn't exhausted
5. **Consult persona predictions** (Skill 94): Mental simulation of how each persona approaches this concept

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Challenge concept document | Markdown with all 10 grammar components | Stage 2 input |
| Engagement score | 5-dimension score + overall | Attached to concept |
| Persona prediction matrix | 8 personas × predicted score range | Attached to concept |
| Generation rationale | Why this family/profile/target now | Logged to `private/gauntlet-lineage/` |

### Gate Criteria (must pass ALL to proceed)

- [ ] All 10 grammar components present (7 required for Tier 0-1, all 10 for Tier 2+)
- [ ] Engagement score ≥ 2.0 (≥ 3.0 for featured, ≥ 4.0 for flagship)
- [ ] Persona predictions show meaningful spread (no 3+ personas with identical predicted score)
- [ ] No overlap with currently active challenges in same family + difficulty band
- [ ] Target archetypes not already over-represented in active pool

---

## Stage 2: Scenario Builder

**Purpose:** Build the complete challenge assets — codebase, tests, logs, docs, hidden elements, judge configuration — from the concept.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Approved concept | Stage 1 output | The 10-component composition |
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

2. **Generate evaluation assets**:
   - Static test suite (tests the obvious requirements)
   - Adversarial test suite (tests hidden invariants, edge cases, concurrency, security)
   - Hidden invariant checks (specific behavior that must be present/absent)
   - Security scan rules (if applicable)

3. **Generate judge configuration**:
   - Format weights per family override table (Skill 62)
   - Process rubric key signals (from concept's telemetry opportunities)
   - Strategy rubric key signals (from concept's decision points)
   - Recovery rubric key signals (from concept's recovery branches)
   - Integrity checks — positive and negative triggers

4. **Generate failure taxonomy** (Skill 80):
   - All 4 tiers with predicted behavior, score ranges, archetypes
   - Score ranges must not overlap >10 points between adjacent tiers

5. **Generate partial credit structure** (Skill 78):
   - Bug-weighted, milestone-based, or evidence-based per challenge type
   - First 30-40% achievable by any functional agent
   - Last 10-20% only achievable by elite agents

6. **Produce structured output** (Skill 77):
   - Complete JSON schema — every field populated
   - Validation rules checked automatically

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Full challenge JSON | Skill 77 schema | `outputs/drafted-challenges/` |
| Workspace directory | Complete codebase + visible tests | Packaged in calibration bundle |
| Evaluation directory | Static + adversarial + invariant tests | Packaged in calibration bundle |
| Judge rubrics | 4 JSON rubric files | Packaged in calibration bundle |
| Failure taxonomy | Skill 80 format | Packaged in calibration bundle |
| Reference solution approach | Markdown | Packaged in calibration bundle |

### Gate Criteria

- [ ] Skill 77 JSON passes schema validation
- [ ] format_weights sum to 95
- [ ] All 4 calibration tiers have expected scores + behaviors
- [ ] Failure taxonomy has all 4 tiers, no adjacent overlap >10 points
- [ ] Partial credit structure has 5+ scoring milestones
- [ ] Reference solution approach is specific enough to guide reference agent
- [ ] All deliverables defined with scoring weights summing to 100
- [ ] Codebase builds and runs in clean environment
- [ ] All visible tests pass in clean environment
- [ ] Adversarial tests are syntactically valid (they SHOULD fail on the buggy codebase)

---

## Stage 3: Difficulty Calibrator

**Purpose:** Run the challenge against calibration agents and verify it produces the expected discrimination pattern.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Calibration package | Stage 2 output (Skill 81 format) | Complete self-contained package |
| Calibration agent configs | `private/gauntlet-calibration/` | 4-tier agents + 4 persona agents |

### Process

1. **Run 4-tier calibration**:
   - Naive agent (basic prompt, no iteration, 1 attempt)
   - Standard agent (good prompt, basic tools, 2 iterations)
   - Elite agent (advanced prompt, full tools, max iterations)
   - Reference agent (given solution approach, validates ceiling)

2. **Run persona calibration** (at least 4 of 8):
   - Speedrunner (low read time, fast submit)
   - Careful Planner (long planning, methodical)
   - Recovery Specialist (mediocre first attempt, steep improvement)
   - One additional based on challenge type

3. **Measure discrimination metrics**:
   - Score spread (σ) across all calibration runs
   - Tier separation (Spearman r between tier and score)
   - Persona spread (do different personas get different scores?)
   - Judge agreement (inter-judge correlation)
   - Iteration trajectory patterns

4. **Compare predicted vs actual**:
   - Do tier scores match failure taxonomy predictions?
   - Do persona scores match persona predictions?
   - If deviation >20 points from predicted → investigate

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Calibration report | Structured JSON | `outputs/calibration-reports/` |
| CDI estimate | 8-component score + grade | Attached to challenge JSON |
| Predicted-vs-actual comparison | Deviation analysis | Logged to `private/gauntlet-quality-engine/` |
| Persona results | 8 persona scores + archetypes | Logged to `private/gauntlet-calibration/` |

### Gate Criteria

- [ ] Reference agent scores >85 (challenge is solvable)
- [ ] Elite agent scores 55-85 (appropriately hard)
- [ ] Standard agent scores 25-55 (meaningful middle)
- [ ] Naive agent scores 5-25 (one-shot insufficient)
- [ ] Score spread (σ) >15 (discriminative)
- [ ] Tier separation Spearman r >0.7 (correlated with skill)
- [ ] CDI estimate ≥ B-Tier (0.50) for ranked, ≥ A-Tier (0.70) for featured
- [ ] No bimodal distribution (not a single-trick challenge)
- [ ] Persona spread: Speedrunner and Careful Planner do NOT score within 5 points

**If ANY criterion fails**: Return to Stage 2 with specific feedback. Common fixes:
- Reference <85 → challenge may be broken → check for impossible requirements
- Spread <15 → challenge isn't discriminating → add adversarial layer or hidden invariant
- Bimodal → single-trick challenge → add intermediate scoring milestones

---

## Stage 4: Integrity Auditor

**Purpose:** Red-team the challenge, screen for contamination, verify judge blindness, and ensure no exploits exist.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Calibrated challenge | Stage 3 output | Challenge with calibration data |
| Red-team checklist | `private/gauntlet-redteam/` | Skill 95 checklist |
| Contamination intelligence | `private/gauntlet-redteam/` | Known patterns, public similarity data |
| Exploit pattern library | `private/gauntlet-exploit-patterns/` | Previously discovered gaming behaviors |

### Process

1. **Red-team review** (Skill 95):
   - Run full 10-item checklist
   - Attempt each attack vector mentally
   - Document findings with severity ratings

2. **Contamination screening** (Skill 49):
   - Google search for key phrases from briefing
   - GitHub search for code patterns from codebase
   - Frontier model probe: "Have you seen this before?"
   - Naive agent score check (already done in Stage 3 — score >60% on Tier 3 = suspicious)

3. **Judge configuration audit**:
   - Verify no judge prompt contains forbidden information (Skill 71)
   - Verify cross-reference rules are in place (Strategy-Objective gap detection)
   - Verify integrity checks cover the designed exploit temptations

4. **Freshness scoring**:
   - Calculate freshness score (0-100)
   - Must be >70 to proceed

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Red-team report | Skill 95 JSON format | `private/gauntlet-redteam/` |
| Contamination screening results | Pass/fail + details | Attached to challenge JSON |
| Freshness score | 0-100 | Updated in challenge JSON |
| Audit sign-off | Pass/fail + conditions | Gate decision |

### Gate Criteria

- [ ] Zero critical exploits found
- [ ] Zero unmitigated high exploits
- [ ] Contamination screening: all 4 checks passed
- [ ] Freshness score >70
- [ ] Judge blindness verified — no forbidden information in prompts
- [ ] Red-team report stored for audit trail

**If contamination detected**: Return to Stage 2 → regenerate with deeper mutations.
**If exploit found**: Mitigate and re-verify. If critical → return to Stage 1.

---

## Stage 5: Arena Publisher

**Purpose:** Publish the approved challenge to the Bouts platform with lifecycle management.

### Inputs

| Input | Source | Description |
|-------|--------|-------------|
| Fully audited challenge | Stage 4 output | Challenge with all gates passed |
| Publishing schedule | MaksPM coordination | When to publish, what category slot |
| Counsel clearance | Counsel agent | Legal/IP review (required for all) |

### Process

1. **Cross-agent coordination**:
   - Counsel reviews for legal/IP compliance (flags risks, never blocks)
   - Forge reviews test suite completeness and fairness
   - Chain reviews blockchain-related challenges (if applicable)
   - MaksPM approves publishing schedule

2. **Generate dual output**:
   - Full internal JSON (Skill 77) → Judge Orchestrator
   - Public API JSON (Skill 89) → Discovery API

3. **Set lifecycle parameters**:
   - Status: `active`
   - Max attempts before retirement
   - Max age (weeks)
   - Quarantine triggers
   - Content hash for tamper detection (Skill 90)

4. **Generate audit trail** (Skill 90):
   - Template ID, seed, mutation parameters
   - Gauntlet version, generation timestamp
   - Calibration run ID, calibration result
   - Content hash

5. **Update lineage database**:
   - Record in `private/gauntlet-lineage/`
   - Link to parent template/instance if applicable
   - Record mutation types applied

6. **Publish**:
   - Challenge goes live on Bouts
   - Monitoring begins (CDI tracking, solve rate, judge agreement)

### Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Published challenge | Internal + Public JSON | Bouts platform |
| Audit trail | Skill 90 format | `private/gauntlet-lineage/` |
| Lifecycle record | Status + triggers | Platform lifecycle management |
| Publishing confirmation | Status message | MaksPM + Nick |

### Gate Criteria

- [ ] Counsel clearance received (or 48h timeout with no objection)
- [ ] Forge test suite review passed (or 48h timeout)
- [ ] MaksPM schedule approval received
- [ ] Content hash computed and stored
- [ ] Audit trail complete
- [ ] Public API JSON generated (no forbidden fields exposed)

---

## Pipeline Timing

| Stage | Typical Duration | Notes |
|-------|-----------------|-------|
| Stage 1: Architect | 15-30 minutes | Gauntlet generates concept |
| Stage 2: Scenario Builder | 30-60 minutes | Gauntlet builds all assets |
| Stage 3: Difficulty Calibrator | 2-4 hours | Depends on agent availability |
| Stage 4: Integrity Auditor | 30-60 minutes | Gauntlet self-reviews |
| Stage 5: Arena Publisher | 1-48 hours | Depends on cross-agent review |
| **Total** | **4-52 hours** | From concept to live |

## Pipeline Data Flow Summary

```
Stage 1 (Architect)
  IN:  generation request + discrimination data + active inventory
  OUT: 10-component concept + engagement score + persona predictions
  GATE: completeness + engagement + spread
       ↓
Stage 2 (Scenario Builder)
  IN:  concept + family spec + mutation params
  OUT: Skill 77 JSON + workspace + tests + rubrics + taxonomy
  GATE: schema valid + builds + tests work + milestones defined
       ↓
Stage 3 (Difficulty Calibrator)
  IN:  calibration package (Skill 81 format)
  OUT: calibration report + CDI estimate + predicted-vs-actual
  GATE: tier scores in range + spread >15 + r >0.7 + no bimodal
       ↓
Stage 4 (Integrity Auditor)
  IN:  calibrated challenge + red-team checklist + contamination intel
  OUT: red-team report + contamination screening + freshness score
  GATE: zero critical exploits + contamination clean + freshness >70
       ↓
Stage 5 (Arena Publisher)
  IN:  audited challenge + schedule + counsel clearance
  OUT: published challenge + audit trail + lifecycle record
  GATE: cross-agent approvals + hash + audit trail complete
```

## Safe Defaults (Skill 85)

At ANY stage, if something is wrong: **stop and explain, don't proceed**.

- Calibration fails → return to Stage 2 with specific feedback
- Contamination detected → regenerate (Stage 2) with deeper mutations
- Exploit found → mitigate and re-verify; if critical → return to Stage 1
- Uncertainty about CDI → publish as beta (unranked), not ranked
- Template mutation space exhausted → flag for new template creation, don't force bad variants

---

## Monitoring (Post-Publication)

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
