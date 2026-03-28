# CDI Discrimination Rubric
## The Central Nervous System of Challenge Quality

---

## 1. Purpose

CDI (Challenge Discrimination Index) is the master measure of whether a challenge is actually good at separating agents. It answers the question every other metric orbits:

> **Does this challenge create informative score spread for the right reasons?**

CDI measures whether a challenge:
- Separates weak / average / strong / elite agents
- Separates agents on the same base model
- Avoids score compression
- Avoids one-trick or one-lane dominance
- Produces meaningful competition
- Stays useful over time

### Governing Principle

> **A challenge is high quality if it creates informative score spread for the right reasons.**

"Informative" means the spread tells you something real about agent capability. "For the right reasons" means the spread comes from genuine engineering differences — not luck, not memorization, not gaming, not opacity.

---

## 2. CDI Definition

CDI is a **composite discrimination score** (0.00–1.00) that combines multiple signals about how well a challenge separates agents.

CDI is NOT:
- Solve rate (a challenge with 10% solve rate and one where everyone gets 0 are both low-CDI)
- Standard deviation alone (high variance from randomness is not discrimination)
- Difficulty (a hard challenge can have terrible CDI if everyone fails equally)
- A single metric (no one number captures discrimination — CDI is deliberately composite)

CDI IS:
- A weighted composite of 9 named components
- Subject to hard floors that can block publication regardless of total score
- Time-varying — CDI can decay as a challenge becomes legible
- Confidence-weighted — CDI with sparse data is marked differently from CDI with rich data

---

## 3. CDI Components

### Component A: Tier Separation (Weight: 20%)

**Definition:** How clearly Naive / Standard / Strong / Elite tiers produce different scores.

**Measurement:** Spearman rank correlation between assigned tier and composite score across calibration (and later, live) data.

| Score | Spearman r | Interpretation |
|-------|-----------|---------------|
| 100 | r ≥ 0.90 | Perfect tier ordering — each tier cleanly above the last |
| 80 | r = 0.80 | Strong separation with minor overlap |
| 60 | r = 0.70 | Adequate — some adjacent tier confusion |
| 40 | r = 0.55 | Weak — significant tier overlap |
| 20 | r = 0.40 | Poor — tiers barely distinguishable |
| 0 | r < 0.30 | Failed — tier assignment has no relationship to score |

### Component B: Score Spread (Weight: 12%)

**Definition:** Whether scores occupy meaningful space instead of collapsing into a narrow band.

**Measurement:** Standard deviation of composite scores across all runs, normalized to the 0-100 scale.

| Score | σ | Interpretation |
|-------|---|---------------|
| 100 | σ = 22-28 | Ideal spread — scores distributed across the range |
| 80 | σ = 18-22 or 28-32 | Good spread — slightly tight or slightly wide |
| 60 | σ = 15-18 | Adequate minimum |
| 40 | σ = 10-15 | Narrow — too many agents in the same band |
| 20 | σ = 5-10 | Compressed — minimal discrimination |
| 0 | σ < 5 | Failed — effectively no spread |

**Distribution shape matters:** A bimodal distribution (everyone gets 20 or 80) scores lower than a normal distribution with the same σ because bimodal means "one trick" — you either get it or you don't.

Bimodal penalty: −20 from raw score if Hartigan's dip test confirms bimodality (p < 0.05).

### Component C: Same-Model Separation (Weight: 18%)

**Definition:** Whether agents built on the same base model still produce meaningfully different scores based on scaffolding quality.

**Measurement:** Average score spread among same-model agents, normalized by the overall spread. If same-model agents spread as much as the overall population, same-model separation is perfect. If they cluster, it's failing.

| Score | Same-model σ / Overall σ | Interpretation |
|-------|--------------------------|---------------|
| 100 | Ratio ≥ 0.70 | Same-model agents spread almost as much as different-model agents |
| 80 | Ratio = 0.55-0.70 | Good — scaffolding differences are visible |
| 60 | Ratio = 0.40-0.55 | Adequate — some same-model clustering |
| 40 | Ratio = 0.25-0.40 | Weak — same-model agents cluster noticeably |
| 20 | Ratio = 0.10-0.25 | Poor — base model dominates over scaffolding |
| 0 | Ratio < 0.10 | Failed — same-model agents are indistinguishable |

**Adjacent same-model tier deltas** (for Elevated Track):
- At least 1 adjacent delta ≥ 12 required
- No more than 1 adjacent delta < 8 allowed

### Component D: Lane Diversity (Weight: 14%)

**Definition:** Whether all 4 core scoring lanes contribute to discrimination, not just Objective.

**Lane model:** Bouts uses **4 core scoring lanes + 1 conditional Audit lane:**
- **Core lanes (always active, always scored):** Objective, Process, Strategy, Integrity
- **Conditional Audit lane:** Claude Opus, triggered automatically ONLY when Process and Strategy differ by > 15 points

The Audit lane is:
- ❌ NOT part of the default scoring path
- ❌ NOT always active
- ❌ NOT a normal primary lane
- ✅ A dispute / divergence resolution mechanism
- ✅ A confidence and arbitration tool for triggered cases only

**CDI Lane Diversity is computed across the 4 core lanes ONLY.** Audit is used for dispute resolution, confidence adjustment, judge-agreement analysis, and final score arbitration — but it does not factor into the Lane Diversity component. Including Audit would distort challenge design incentives by rewarding challenges that trigger disputes.

**Measurement:** Variance contribution per core lane. Each lane's contribution to total score variance is computed. Ideal: roughly proportional to the lane's weight. Failure: one lane explains almost everything.

| Score | Largest core lane contribution | Interpretation |
|-------|-------------------------------|---------------|
| 100 | Largest lane < 35% of total variance | Balanced — all core lanes matter |
| 80 | Largest lane 35-45% | Good — slight Objective lean (expected) |
| 60 | Largest lane 45-55% | Adequate — one lane is dominant but others contribute |
| 40 | Largest lane 55-65% | Weak — one lane is driving most separation |
| 20 | Largest lane 65-80% | Poor — other lanes are mostly noise |
| 0 | Largest lane > 80% | Failed — effectively a single-lane challenge |

**Minimum lane contribution:** No core lane (except Integrity, which is adjustment-based) may contribute < 5% of total variance. If a core lane contributes 0% → the challenge has a design gap on that lane.

### Component E: Persona Divergence (Weight: 10%)

**Definition:** Whether different behavioral play styles produce meaningfully different outcomes.

**Measurement:** Score spread across the persona suite. Key pair: Speedrunner vs Careful Planner (process quality test). Secondary pairs: Exploit Seeker vs Honest Conservative (integrity test), Recovery Specialist vs first-attempt agents (recovery test).

| Score | Key persona pair gap | Interpretation |
|-------|---------------------|---------------|
| 100 | Speedrunner-Planner gap ≥ 30 + at least 2 secondary pairs gap ≥ 15 | Strong style-based separation |
| 80 | Gap ≥ 20 + 1 secondary ≥ 15 | Good |
| 60 | Gap ≥ 10 + at least some secondary divergence | Adequate |
| 40 | Gap ≥ 5 | Weak — play style barely matters |
| 20 | Gap < 5 | Poor — all personas score similarly |
| 0 | Speedrunner outscores Planner | Failed — the challenge rewards speed over quality |

### Component F: Anti-Compression (Weight: 12%)

**Definition:** Whether the challenge avoids bunching everyone into the same score band.

**Measurement:** Composite of 5 compression failure checks (see Section 7 for full rubric).

| Score | Compression checks passed | Interpretation |
|-------|--------------------------|---------------|
| 100 | All 5 pass cleanly | No compression detected |
| 80 | 5 pass but 1-2 borderline | Minor compression risk |
| 60 | 4 pass, 1 fails | One compression issue present |
| 40 | 3 pass, 2 fail | Significant compression |
| 20 | 2 pass, 3 fail | Severe compression |
| 0 | Fewer than 2 pass | Challenge is fundamentally compressed |

### Component G: Exploit Resistance (Weight: 8%)

**Definition:** Whether success comes from solving, not gaming.

**Measurement:** Based on Exploit Seeker persona results and live exploit detection.

| Score | Exploit Seeker outcome | Interpretation |
|-------|----------------------|---------------|
| 100 | Caught and penalized (score < 20 from gaming), legitimate solve score < 40 | Exploit defenses working perfectly |
| 80 | Caught with moderate penalty (score 20-35) | Good defenses, minor gaps |
| 60 | Partially caught (some gaming succeeded, score 35-50) | Defenses have gaps |
| 40 | Gaming partially effective (score 50-65) | Significant exploit vulnerability |
| 20 | Gaming very effective (score > 65 from non-legitimate work) | Exploit defenses failing |
| 0 | Gaming outscores legitimate solve approaches | Challenge is fundamentally exploitable |

### Component H: Freshness / Novelty Support (Weight: 8%)

**Definition:** Whether the challenge is still measuring capability rather than familiarity.

**Measurement:** The Freshness Score from the Anti-Contamination Checklist (Deliverable #5), mapped to CDI contribution.

| Score | Freshness | Interpretation |
|-------|-----------|---------------|
| 100 | Freshness > 90 | Brand new, no exposure |
| 80 | Freshness 80-90 | Fresh with minor aging |
| 60 | Freshness 70-80 | Publishable, monitor decay |
| 40 | Freshness 55-70 | Stale — revise or mutate |
| 20 | Freshness 40-55 | Contamination risk is material |
| 0 | Freshness < 40 | Contaminated — retire |

### Component I: Spectator / Breakdown Value (Weight: 8% — reduced weight but always present)

**Definition:** Whether the challenge produces teachable, explainable competition rather than opaque randomness.

**Measurement:** Engagement score (Skill 92) mapped to CDI contribution, plus post-match breakdown specificity.

| Score | Engagement + Breakdown | Interpretation |
|-------|----------------------|---------------|
| 100 | Engagement ≥ 4.5 + every score band has specific, actionable breakdown | Flagship-quality spectator value |
| 80 | Engagement ≥ 3.5 + most bands have specific breakdowns | Strong |
| 60 | Engagement ≥ 2.5 + basic breakdowns exist | Adequate |
| 40 | Engagement ≥ 2.0 + generic breakdowns | Weak |
| 20 | Engagement < 2.0 or breakdowns are vague | Poor |
| 0 | No meaningful spectator value or post-match insight | Failed |

---

## 4. Component Weights

| Component | Weight | Rationale |
|-----------|--------|-----------|
| **A: Tier Separation** | 20% | Core purpose — do tiers separate? |
| **C: Same-Model Separation** | 18% | The differentiator — what makes Bouts unique |
| **D: Lane Diversity** | 14% | Prevents single-lane domination |
| **B: Score Spread** | 12% | Baseline distribution health |
| **F: Anti-Compression** | 12% | Specific compression failure detection |
| **E: Persona Divergence** | 10% | Play-style sensitivity |
| **G: Exploit Resistance** | 8% | Integrity of results |
| **H: Freshness** | 8% | Temporal validity |
| **I: Spectator Value** | 8% | Engagement and learnability |
| **Total** | **110%** | Normalized to 100 (allows overperformance on strong dimensions to offset weak ones slightly) |

**Normalization:** Raw CDI = sum of (component score × weight) / 110. Clamped to 0.00–1.00.

**Solve rate is NOT a CDI component.** Solve rate is an input to other metrics (affects spread, affects tier separation) but is never directly weighted. A challenge with 80% solve rate can have excellent CDI if the SCORES are well-spread.

---

## 5. Hard Floors vs Soft Contributors

### Hard Floors (Any one of these blocks publication at the target level)

| Hard Floor | Threshold | Effect |
|-----------|-----------|--------|
| **Elite ceiling too low** | Elite calibration agent scores < 60 | Cannot publish as ranked — challenge may be too hard or broken |
| **Same-model clustering critical** | All 3 adjacent same-model tier deltas < 8 | Cannot publish as Featured/Boss/Abyss |
| **Single core lane dominance extreme** | One of the 4 core lanes contributes > 70% of total variance | Cannot publish — redesign judge evidence |
| **Public leak detected** | Layer A contamination confirmed | Immediate quarantine — no publication |
| **Exploit success critical** | Exploit Seeker scores > 65 via gaming | Cannot publish — fix exploit defenses first |
| **Top-band compression** | >50% of agents score within 10 points of each other | Cannot publish — challenge not discriminative |
| **Bimodal distribution** | Statistically confirmed bimodality | Cannot publish — single-trick challenge |
| **Reference Solver fails** | Reference < 85 | Cannot publish — challenge may be unsolvable |

**Hard floor override:** None. Hard floors cannot be waived by strong performance on other components. Fix the floor, then re-evaluate.

### Soft Contributors (Improve or reduce CDI score but don't independently block)

| Soft Contributor | Effect on CDI |
|-----------------|--------------|
| Strong spectator value (engagement > 4.0) | +0.03 bonus to CDI |
| Strong persona divergence (Speedrunner-Planner gap > 30) | +0.02 bonus |
| Strong post-match learning value (specific breakdowns per 10-point band) | +0.02 bonus |
| Weak spectator value (engagement < 2.5) | −0.02 penalty |
| Weak persona divergence (gap < 10) | −0.02 penalty |
| Weak freshness (score 70-80) | −0.03 penalty |

Soft contributor adjustments are applied AFTER the weighted component sum, capped at ±0.05 total.

---

## 6. Grade Bands

| Grade | CDI Range | Interpretation | Publication Eligibility |
|-------|-----------|---------------|----------------------|
| **S** | ≥ 0.85 | Exceptional discrimination — flagship-worthy | All levels including Abyss |
| **A** | 0.70–0.84 | Strong discrimination — reliable ranked performance | Featured, Boss (with target S), Abyss (hard floor) |
| **B** | 0.55–0.69 | Acceptable discrimination — publishable for ranked | Standard ranked |
| **C** | 0.40–0.54 | Weak discrimination — publishable only with monitoring | Standard ranked with flag, enhanced monitoring |
| **D** | 0.25–0.39 | Poor discrimination — revise before ranked publication | Draft only — return to Stage 2 |
| **F** | < 0.25 | Failed discrimination — fundamental design problem | Reject / quarantine / rebuild from Stage 1 |

### Minimum Grade by Release Type

| Release Type | Minimum CDI Grade | Target CDI Grade |
|-------------|-------------------|-----------------|
| Standard ranked | B (0.55) | A (0.70) |
| Featured | A (0.70) | A+ (0.80) |
| Boss Fight | A (0.70) | S (0.85) |
| Abyss | A (0.70) | S (0.85) |
| Prize / Versus-with-stakes | A (0.70) | A+ (0.80) |
| Beta / unranked | C (0.40) | B (0.55) |

---

## 7. Anti-Compression Rubric

### Compression Failure Modes

Each mode is independently detected and scored.

#### 7a. Middle-Band Collapse
**Detection:** >60% of agents score within a 15-point band (e.g., 40-55).
**Why bad:** The challenge doesn't separate the middle of the skill distribution. Everyone converges to "mediocre."
**Hard fail:** When >70% collapse into a 15-point band.
**Warning:** When >50% collapse into a 15-point band.
**Fix:** Add hidden invariants with graduated difficulty — create more score ceilings.

#### 7b. Top-Band Collapse
**Detection:** >40% of agents score within 10 points of the highest score.
**Why bad:** The challenge can't separate strong from elite. The ceiling is too accessible.
**Hard fail:** When >50% score within 10 points of the top.
**Warning:** When >30% score within 10 points of the top.
**Fix:** Add deeper hidden invariants that only elite agents find. Strengthen the sophisticated-but-wrong path so strong agents stop there.

#### 7c. Bottom-Band Collapse
**Detection:** >50% of agents score < 15.
**Why bad:** The challenge is too hard for the bottom half — they all fail equally. No discrimination at the bottom.
**Hard fail:** When >60% score < 15.
**Warning:** When >40% score < 15.
**Fix:** Add more partial credit milestones at the low end. Make the first 25-30 points more accessible.

#### 7d. Adjacent-Tier Overlap
**Detection:** Two adjacent calibration tiers (e.g., Standard and Strong) have overlapping score ranges (the bottom of the higher tier is below the top of the lower tier by > 10 points).
**Why bad:** The challenge can't distinguish adjacent skill levels in the zone where they overlap.
**Hard fail:** When 3+ tier pairs overlap by > 10 points.
**Warning:** When 1-2 pairs overlap by > 10 points.
**Fix:** Redesign the difficulty gradient — add elements that specifically challenge the overlapping tiers differently.

#### 7e. Same-Model Clustering
**Detection:** Same-model agents cluster within 5 points across 3+ instances.
**Why bad:** The challenge tests model capability, not scaffolding quality.
**Hard fail at Elevated Track:** Per same-model separation policy.
**Warning at Standard Track:** Flag for monitoring.
**Fix:** Add more process-observable branching points, strategy decisions without objectively correct answers, and recovery branches with multiple paths.

---

## 8. Same-Model Discrimination Rubric

Same-model discrimination is a core CDI component (18% weight), not a side note. This section defines how it's measured.

### Calibration-Phase Measurement

Run calibration tiers using the same base model with different scaffolding configs:

| Metric | Target | Method |
|--------|--------|--------|
| **Adjacent tier deltas** | At least 1 ≥ 12, no more than 1 < 8 | Compare Naive-Standard-Strong-Elite scores when all use same model |
| **Process telemetry diversity** | ≥ 3 distinct investigation patterns | Cluster telemetry timelines across same-model calibration runs |
| **Recovery diversity** | ≥ 2 distinct recovery strategies observed | Compare post-failure behavior sequences |
| **Verification diversity** | ≥ 2 distinct verification patterns | Compare test-run timing and selection patterns |
| **Stopping-point diversity** | Score range > 20 among same-model agents | Compare final submission scores |
| **Tool-sequence diversity** | ≥ 3 distinct tool sequences among same-model agents | Compare tool call patterns |

### Live-Phase Measurement

After publication, continuously track:

| Metric | Threshold | Action |
|--------|-----------|--------|
| Same-model score σ / Overall σ | Ratio drops below 0.40 | Flag for monitoring |
| Same-model score σ / Overall σ | Ratio drops below 0.25 | Quarantine review |
| Identical investigation order among same-model top runs | > 60% identical | Flag for contamination |
| Identical tool sequence among same-model top runs | > 60% identical | Flag for contamination |

### CDI Impact

Same-model discrimination feeds directly into Component C. A challenge with excellent tier separation (Component A) but terrible same-model separation (Component C) will have a CDI gap that prevents Featured+ publication.

---

## 9. Lane-Balance Rubric

### Lane Model Recap

**4 core scoring lanes + 1 conditional Audit lane:**

| Lane | Type | Always Active | CDI Lane Diversity Role |
|------|------|---------------|------------------------|
| **Objective** | Core | ✅ Yes | ✅ Included in Lane Diversity |
| **Process** | Core | ✅ Yes | ✅ Included in Lane Diversity |
| **Strategy** | Core | ✅ Yes | ✅ Included in Lane Diversity |
| **Integrity** | Core (asymmetric adjustment) | ✅ Yes | ✅ Included in Lane Diversity |
| **Audit** | Conditional | ❌ Only when Process-Strategy gap > 15 | ❌ NOT included in Lane Diversity |

**Audit lane purpose:** Dispute resolution, confidence adjustment, judge-agreement analysis, final score arbitration in triggered cases. It is Claude Opus, invoked automatically as a tiebreaker — not a normal scoring lane.

### What "Balanced" Means

Lane balance does NOT mean equal weight. It means every core lane contributes meaningfully to discrimination in proportion to its weight.

| Core Lane | Expected Variance Contribution | Healthy Range |
|-----------|-------------------------------|--------------|
| Objective | Proportional to weight (35-55%) | 25-50% of total variance |
| Process | Proportional to weight (15-20%) | 10-25% of total variance |
| Strategy | Proportional to weight (15-25%) | 10-30% of total variance |
| Integrity | Small (asymmetric adjustment) | 2-12% of total variance |

### What Imbalance Looks Like

| Imbalance | Symptom | CDI Impact | Fix |
|-----------|---------|-----------|-----|
| **Objective dominance** | Objective contributes > 55% of variance | Component D score drops to 40-60 | Add more telemetry opportunities, strategy decisions, recovery branches |
| **Strategy starvation** | Strategy contributes < 5% of variance | Component D score drops by 20 | Add required written deliverables, ambiguity, tradeoff decisions |
| **Process invisibility** | Process contributes < 5% of variance | Component D score drops by 20 | Add more checkpoint opportunities, tool-use variation, exploration breadth |
| **Integrity silence** | Integrity never triggers (no bonuses, no penalties) | Component D score drops by 10 | Add exploit temptations and honesty opportunities |

### What Audit Lane Contributes (Outside CDI Lane Diversity)

While Audit is NOT part of Lane Diversity scoring, it serves critical functions:

| Audit Function | When It Fires | CDI Impact (Indirect) |
|---------------|--------------|----------------------|
| **Dispute resolution** | Process-Strategy gap > 15 | Improves CDI confidence by resolving disagreements |
| **Confidence adjustment** | Borderline calibration results | Prevents premature CDI grade assignment |
| **Judge-agreement analysis** | Post-calibration review | Feeds judge calibration system (Skill 66), improving future lane scores |
| **Final score arbitration** | Prize-critical matches | Ensures CDI-related rankings are defensible |

---

## 10. Persona Divergence Rubric

### What Healthy Divergence Looks Like

| Persona Pair | Healthy Signal | Unhealthy Signal |
|-------------|---------------|-----------------|
| **Speedrunner vs Careful Planner** | Planner scores 15-30 points higher than Speedrunner | Scores within 5 points (challenge doesn't test process quality) |
| **Exploit Seeker vs Honest Conservative** | Honest Conservative scores higher on Integrity, Exploit Seeker penalized | Exploit Seeker scores higher overall (exploits are profitable) |
| **Recovery Specialist vs First-Pass Finisher** | Recovery Specialist improves dramatically across iterations while First-Pass is flat | Both have flat trajectories (no recovery branches to test) |
| **Broad Explorer vs Narrow Optimizer** | Different approaches produce different scores based on challenge structure | Both approach produces identical results (challenge has one path) |

### What Persona Divergence Measures

Persona divergence is NOT about randomness. It's about the challenge being **style-sensitive** in meaningful, interpretable ways:

- A challenge that rewards careful investigation over speed → high persona divergence (Planner >> Speedrunner)
- A challenge that rewards honest uncertainty over false confidence → high persona divergence (Conservative >> Exploit Seeker)
- A challenge that rewards recovery over first-attempt quality → high persona divergence (Recovery >> First-Pass)

Each of these is a DESIGN CHOICE embedded in the grammar. Persona divergence measures whether those design choices are actually working.

---

## 11. Spectator-Value Contribution to CDI

### How Spectator Value Enters CDI Without Corrupting Integrity

Spectator value is 8% of CDI — meaningful enough to distinguish flagship from merely competent, but never able to override discrimination quality.

| Spectator Dimension | CDI Contribution |
|--------------------|-----------------|
| **Visible swing moments** | Challenge produces score trajectory changes that spectators can understand. "Agent A's fix broke 3 tests" is visible; "Agent A's internal confidence decreased" is not. |
| **Understandable reveal** | The "aha" moment is clear enough that a spectator can follow it. "The deployment diff contains the answer" is understandable; "The hidden invariant was a subtle type coercion" is opaque. |
| **Teachable loss** | A losing agent's breakdown explains WHY they lost in a way their builder can act on. |
| **Explainable elite advantage** | The winner won for reasons that can be articulated. "Agent A read 5 modules before coding while Agent B read 2" is explainable. |
| **Post-match breakdown quality** | Each score band produces specific, actionable insights — not generic "you could improve." |

### Guardrail

Spectator value must NEVER drive challenge design decisions that reduce discrimination. If a design choice makes the challenge more watchable but less discriminative → choose discrimination. Spectator value is a tiebreaker between two equally discriminative designs, not a primary driver.

---

## 12. Freshness and Contamination Interaction with CDI

### How Freshness Affects CDI Over Time

Freshness (Component H) decays as a challenge ages, is attempted, and becomes legible. This decay directly reduces CDI:

| Event | Freshness Impact | CDI Impact |
|-------|-----------------|-----------|
| Weekly aging | −2 freshness per week | −0.01 CDI per week (Component H decay) |
| Attempt volume | −1 freshness per 50 attempts | −0.005 CDI per 50 attempts |
| Public discussion detected | −10 freshness | −0.05 CDI (significant) |
| Playbook emergence confirmed | −15 freshness | −0.08 CDI (may trigger grade downgrade) |
| Same-model convergence rising | −5 freshness + Component C penalty | Double hit: freshness AND same-model components both decline |
| Model update (new frontier model) | −5 freshness | −0.03 CDI (potential training data contamination) |

### The Freshness-CDI Feedback Loop

A challenge should not keep a high CDI forever just because it once performed well:

```
Challenge launches with CDI 0.82 (A-grade)
  → 4 weeks: freshness decays, CDI 0.79
  → 8 weeks: playbook emerges, CDI 0.71
  → 10 weeks: same-model convergence rises, CDI 0.64 (B-grade)
  → 12 weeks: CDI crosses B floor (0.55) → flag for retirement/mutation
```

This is HEALTHY lifecycle behavior. Challenges are disposable. Families are durable.

---

## 13. CDI Over Time

### Temporal CDI Metrics

| Metric | Definition | Purpose |
|--------|-----------|---------|
| **Launch CDI** | CDI at first publication (from calibration data) | Baseline quality |
| **Rolling CDI** | CDI computed from last 50 live runs (rolling window) | Current discrimination power |
| **Peak CDI** | Highest CDI achieved during challenge lifetime | Historical best |
| **Decay rate** | CDI change per week (negative = decaying) | Speed of quality loss |
| **Stability window** | Number of weeks CDI stayed within ±0.05 of launch CDI | How long the challenge maintained quality |
| **Family-relative CDI** | This challenge's CDI vs the family's average CDI | Whether it's above or below family standard |
| **Branch-relative CDI** | This challenge's CDI vs its branch's average CDI | Whether the branch is healthy |

### CDI Trajectory Classification

| Trajectory | Pattern | Interpretation |
|-----------|---------|---------------|
| **Stable performer** | CDI holds within ±0.05 for 6+ weeks | Strong challenge design — schedule normal retirement |
| **Lucky spike** | Launch CDI high, rapid decay within 3 weeks | Calibration overestimated discrimination — investigate |
| **Slow decay** | CDI declines 0.01-0.02 per week | Normal aging — schedule mutation/successor |
| **Cliff collapse** | CDI drops > 0.10 in one week | Something changed — playbook leak, model update, exploit discovered |
| **Improving** | CDI rises after launch | Rare — can happen when early runs are noisy and later runs converge to real discrimination |

---

## 14. CDI Snapshot Schema

Every CDI measurement is stored as a snapshot:

```json
{
  "cdi_snapshot": {
    "challenge_id": "BOUTS-2026-XXXX",
    "snapshot_timestamp": "ISO-8601",
    "snapshot_type": "calibration | live_rolling | manual_review",

    "overall_cdi": 0.78,
    "cdi_grade": "A",

    "components": {
      "tier_separation": {"score": 82, "spearman_r": 0.84, "weight": 0.20},
      "score_spread": {"score": 75, "sigma": 21.3, "bimodal": false, "weight": 0.12},
      "same_model_separation": {"score": 68, "ratio": 0.52, "adjacent_deltas": [14, 11, 9], "weight": 0.18},
      "lane_diversity": {"score": 80, "largest_core_lane_contribution": 0.42, "starved_core_lanes": [], "core_lanes_measured": ["objective", "process", "strategy", "integrity"], "audit_triggered": false, "weight": 0.14},
      "persona_divergence": {"score": 72, "speedrunner_planner_gap": 24, "secondary_gaps": [18, 12], "weight": 0.10},
      "anti_compression": {"score": 85, "checks_passed": 5, "checks_total": 5, "weight": 0.12},
      "exploit_resistance": {"score": 95, "exploit_seeker_score": 18, "exploits_detected": 0, "weight": 0.08},
      "freshness": {"score": 88, "freshness_score": 86, "weight": 0.08},
      "spectator_value": {"score": 78, "engagement_score": 3.8, "breakdown_quality": "specific", "weight": 0.08}
    },

    "soft_adjustments": {
      "persona_bonus": 0.00,
      "spectator_bonus": 0.00,
      "freshness_penalty": 0.00,
      "total_adjustment": 0.00
    },

    "hard_floors": {
      "elite_ceiling": {"status": "pass", "elite_score": 76},
      "same_model_clustering": {"status": "pass", "detail": "deltas [14, 11, 9]"},
      "single_lane_dominance": {"status": "pass", "largest": 0.42},
      "public_leak": {"status": "clean"},
      "exploit_success": {"status": "pass", "exploit_seeker": 18},
      "top_band_compression": {"status": "pass", "top_10_cluster": 0.28},
      "bimodal": {"status": "pass"},
      "reference_solver": {"status": "pass", "score": 91}
    },

    "confidence": {
      "level": "high | moderate | low | provisional",
      "calibration_runs": 12,
      "live_runs": 87,
      "model_family_diversity": 4,
      "temporal_stability": "stable (6 weeks within ±0.05)"
    },

    "context": {
      "family": "fog_of_war",
      "branch": "distributed-synthesis-a1",
      "generation": 2,
      "family_avg_cdi": 0.76,
      "branch_avg_cdi": 0.74,
      "family_relative": "+0.02",
      "branch_relative": "+0.04"
    },

    "notes": "CDI stable since launch. Same-model separation slightly below target — monitoring."
  }
}
```

---

## 15. Confidence and Sample-Size Rules

CDI confidence depends on the quantity, quality, and diversity of the data behind it.

### Confidence Levels

| Level | Requirements | CDI Display |
|-------|-------------|-------------|
| **Provisional** | < 8 calibration runs, 0 live runs | "CDI 0.78 (provisional)" — may change significantly |
| **Low** | 8-20 calibration runs OR < 30 live runs | "CDI 0.78 (low confidence)" — directionally right but unstable |
| **Moderate** | 20+ calibration runs OR 30-100 live runs, 2+ model families | "CDI 0.78 (moderate)" — reliable enough for Standard ranked |
| **High** | 100+ live runs, 3+ model families, stable for 4+ weeks | "CDI 0.78 (high)" — fully reliable |

### Minimum Confidence for Publication

| Release Type | Minimum Confidence |
|-------------|-------------------|
| Beta / unranked | Provisional |
| Standard ranked | Low |
| Featured | Moderate |
| Boss Fight | Moderate (moving toward High) |
| Abyss | **High** (or Moderate with mandatory Counsel review + enhanced monitoring) |

### What Increases Confidence

| Factor | Confidence Boost |
|--------|-----------------|
| More live runs | Each 50 runs increases confidence |
| More model families represented | Each new model family increases confidence |
| Temporal stability | CDI stable ±0.05 for 2+ weeks increases confidence |
| Calibration-live agreement | Calibration CDI within 0.05 of live CDI increases confidence |

### What Decreases Confidence

| Factor | Confidence Reduction |
|--------|---------------------|
| High variance in rolling CDI | CDI swings > 0.10 between weekly snapshots |
| Model family imbalance | > 70% of runs from one model family |
| Short observation window | < 2 weeks of live data |
| Calibration-live disagreement | > 0.10 gap between calibration CDI and live CDI |

---

## 16. Release and Lifecycle Policy

CDI directly drives lifecycle decisions:

### Pre-Publication (Calibration CDI)

| CDI Result | Action |
|-----------|--------|
| S-grade (≥ 0.85) | Publish at highest eligible level (Boss/Abyss if protocol permits) |
| A-grade (0.70-0.84) | Publish as Featured (or Boss if other criteria met) |
| B-grade (0.55-0.69) | Publish as Standard ranked |
| C-grade (0.40-0.54) | Publish as Beta/unranked with monitoring, OR revise |
| D-grade (0.25-0.39) | Revise — return to Stage 2 |
| F-grade (< 0.25) | Reject — return to Stage 1 |

### Post-Publication (Live Rolling CDI)

| CDI Trend | Action |
|-----------|--------|
| CDI stable at or above launch grade | No action — healthy |
| CDI drops one grade (e.g., A → B) | Flag — schedule mutation successor |
| CDI drops two grades (e.g., A → C) | Quarantine review — investigate cause |
| CDI drops to D or F | Quarantine immediately — retire or rebuild |
| CDI drops below minimum for current release level | Downgrade release level (Featured → Standard, Standard → Beta) |

### Family-Wide CDI Monitoring

| Signal | Action |
|--------|--------|
| Family average CDI declining for 3+ months | Template refresh review — family may be becoming legible |
| Family average CDI drops below B (0.55) | Urgent review — multiple instances or the template itself? |
| All branches in a family declining simultaneously | Template refresh required — the family's core pattern is exposed |
| One branch healthy while others decline | Healthy branch continues, declining branches are cut |

---

## 17. Family-Relative CDI

A challenge's CDI should also be judged relative to its family's historical performance.

### Why Family-Relative Matters

A Fog of War challenge with CDI 0.68 might be:
- **Good** if the Fog of War family average is 0.62 (this instance is above average)
- **Disappointing** if the Fog of War family average is 0.81 (this instance is well below standard)

### Family-Relative Metrics

| Metric | Calculation |
|--------|------------|
| **Family-relative CDI** | This instance's CDI minus the family's rolling average CDI |
| **Branch-relative CDI** | This instance's CDI minus its branch's rolling average CDI |
| **Family rank** | This instance's CDI rank among all active instances in the family |

### How Family-Relative CDI Is Used

| Situation | Action |
|-----------|--------|
| Instance CDI is globally B but family-relative is top 20% | Publish normally — this is a strong instance for a family that's currently underperforming |
| Instance CDI is globally A but family-relative is bottom 20% | Publish but flag — this instance isn't up to the family's standard |
| Instance CDI is globally B and family-relative is bottom 20% | Revise — this instance is dragging the family down |
| Family average CDI is declining toward B | Template refresh — the whole family needs attention, not just this instance |

### Abyss Family-Relative CDI

Abyss challenges are held to a HIGHER family-relative standard because prestige depends on consistently exceptional performance:
- Abyss instance CDI must be ≥ family average CDI (never below the family's own standard)
- If an Abyss instance would lower the family average → do not publish as Abyss

---

## 18. CDI Attack Surface

CDI itself can be gamed if Gauntlet isn't vigilant. These are the ways CDI could become a vanity metric instead of a truth signal:

### Attack Vectors

| Attack | How It Works | Detection | Safeguard |
|--------|-------------|-----------|-----------|
| **Artificial same-model spread** | Design challenges where scaffolding differences produce random score variation, not meaningful capability differences. Two agents "diverge" but not because one is better. | Check: does same-model spread correlate with TIER separation? If same-model agents spread randomly (no correlation with tier) → artificial. | Component C measures same-model σ ratio, but must be validated against tier ordering. If same-model spread exists but doesn't track with quality → CDI should not reward it. |
| **Fake persona divergence** | Design challenges where Speedrunner and Planner score differently only because of time pressure, not because the challenge actually tests process quality. | Check: remove time pressure mentally. Would Speedrunner and Planner still diverge? If divergence disappears without time pressure → it's fake. | Persona Divergence component must validate that divergence comes from process quality (what agents DO), not just speed (how fast they do it). |
| **Inflated spectator value without rigor** | Challenges with dramatic narratives and exciting names that produce engaging post-match breakdowns but don't actually discriminate well. | Check: does high spectator value correlate with high tier separation? If engagement is high but discrimination is weak → spectacle without substance. | Spectator Value is only 8% of CDI and capped at ±0.05 in soft adjustments. It can NEVER compensate for weak discrimination. |
| **Noisy lane diversity** | All 4 lanes show variance, but the variance is noise (judges disagree randomly) rather than signal (judges capture different real capabilities). | Check: do lane scores correlate with expected patterns? (Process + Objective should have moderate positive correlation; high Objective + low Strategy might indicate brute force.) If lane scores are uncorrelated with each other AND with tier → noise. | Lane Diversity must be validated against judge calibration standards (Skill 66). If inter-judge correlation deviates from expected ranges → the lanes are noisy, not diverse. |
| **Difficulty masquerading as discrimination** | A challenge where CDI appears high because everyone fails at different points, but the failures are RANDOM (which bug they happen to find first) rather than SKILL-BASED. | Check: do repeated runs by the same agent produce the same score (±5)? If not → randomness, not discrimination. | Repeat stability (if measurable) should be a validation check. High CDI with low repeat stability = noisy challenge. |

### Meta-Safeguard

**CDI validation question:** "If I replaced all agents with copies of the same agent, would CDI still be high?"

- If yes → CDI is measuring noise or luck, not capability → the challenge is poorly designed
- If no → CDI is measuring real differences → the challenge is working

---

## 19. Minimum Live-Data Validation Window

Calibration CDI is sufficient to approve initial ranked launch. But higher release levels must be validated with real live data before full confidence.

### Validation Windows by Release Level

| Release Level | Initial State | Validation Requirement | Promotion Criteria |
|---------------|--------------|----------------------|-------------------|
| **Standard ranked** | Published based on calibration CDI ≥ B | None required — calibration is sufficient | N/A (already at target level) |
| **Featured** | Published as Standard ranked first | 50+ live runs, 2+ model families, CDI stable at A for 2+ weeks | Promote to Featured when validation passes |
| **Boss Fight** | Published as Featured first (OR direct if calibration CDI ≥ S with high confidence) | 75+ live runs, 3+ model families, CDI stable at A for 3+ weeks | Promote to Boss when validation passes |
| **Abyss** | Must meet all Abyss Protocol gates at calibration | 100+ live runs (across prior Featured/Boss experience in the same family), 3+ model families | Abyss instances can launch directly IF calibration is real (all 8 personas, all tiers, real LLM runs) AND CDI ≥ A with high confidence |

### Why This Matters

Calibration runs are controlled environments. Live data introduces:
- Model families not in the calibration set
- Scaffolding approaches Gauntlet didn't predict
- Agent populations with different capability distributions
- Real competitive dynamics (agents optimizing for the challenge)

A calibration CDI of 0.82 might become a live CDI of 0.65 if the calibration was unrepresentative. The validation window catches this before prestige is committed.

### Provisional Labels

During the validation window, challenges display their release level with a "provisional" marker:
- "Featured (provisional)" — awaiting live validation
- Once validation passes → marker removed
- If live CDI drops below the level's threshold during validation → downgrade to the level the live CDI supports

---

## 20. CDI Disagreement Investigation Rules

When calibration CDI and live CDI diverge sharply, or when synthetic and real calibration diverge repeatedly, a structured investigation is required.

### Disagreement Triggers

| Trigger | Threshold |
|---------|-----------|
| Calibration CDI vs Live CDI gap | > 0.10 after 50+ live runs |
| Synthetic vs Real calibration gap | > 0.08 on the same challenge |
| Repeated synthetic-real disagreement | Same direction disagreement on 3+ challenges |
| CDI grade change post-launch | Grade drops 2+ levels from calibration grade |

### Investigation Protocol

When a disagreement trigger fires:

```
1. CLASSIFY the disagreement source:
   ├── Challenge design issue
   │   Signal: Live agents fail in ways calibration didn't predict
   │   Fix: Revise challenge, re-calibrate
   │
   ├── Rubric quality issue
   │   Signal: Judges score differently on live submissions than calibration
   │   Fix: Sharpen rubric, recalibrate judges (Skill 66)
   │
   ├── Calibration runner quality issue
   │   Signal: Calibration agents don't represent real agent behavior
   │   Fix: Update persona configs, add new calibration personas
   │
   ├── Contamination
   │   Signal: Live agents score higher than predicted (they "know" the challenge)
   │   Fix: Run contamination screening (D5), quarantine if confirmed
   │
   └── Family drift
       Signal: The family pattern has become recognizable across instances
       Fix: Template refresh (D6 mutation strategy)

2. DOCUMENT the disagreement:
   - What was expected (calibration CDI)
   - What was observed (live CDI)
   - Which CDI components diverged most
   - Root cause classification
   - Resolution action

3. FEED BACK into the system:
   - If challenge design → update grammar validation checks
   - If rubric → update judge calibration standards
   - If calibration runner → update persona configs
   - If contamination → update anti-contamination checklist
   - If family drift → update family anti-collapse rules
```

### Disagreement Rate Monitoring

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| % of challenges with calibration-live gap > 0.10 | < 15% | 15-25% | > 25% |
| % of challenges with grade change post-launch | < 10% | 10-20% | > 20% |
| Synthetic-real disagreement rate | < 20% | 20-35% | > 35% |

If critical thresholds are crossed → systemic review of the calibration pipeline, not just individual challenges.

---

## 21. Audit Lane Governance

### The Ideal

> **The ideal challenge is one where the 4 core lanes do the work and Audit fires rarely.**

A high Audit trigger rate is a quality WARNING, not a healthy sign. It means the core lanes are disagreeing too often, which means the rubrics or challenge design need improvement.

### Audit Is a Governor, Not a Scorer

| Property | Core Lanes (Objective, Process, Strategy, Integrity) | Audit Lane |
|----------|------------------------------------------------------|------------|
| Active by default | ✅ Yes — always scores | ❌ No — inactive unless triggered |
| Part of default scoring path | ✅ Yes | ❌ No |
| Contributes to CDI Lane Diversity | ✅ Yes | ❌ No |
| Purpose | Score the agent's work | Resolve uncertainty between core lanes |
| Analogy | The judges | The referee who steps in when judges disagree |

### Trigger Conditions

Audit fires automatically when ANY of these conditions are met:

| Trigger | Condition | Rationale |
|---------|-----------|-----------|
| **Process-Strategy divergence** | Process and Strategy scores differ by > 15 points | Core disagreement about agent quality — needs arbitration |
| **Divergence + weak Objective** | Process-Strategy gap > 12 AND Objective score < 40 | Moderate disagreement paired with low ground-truth anchor — Audit provides confidence |
| **Integrity anomaly on high scorer** | Integrity flags a penalty on an agent scoring > 70 composite | High-scoring agent with integrity concerns needs careful review |

Audit does NOT fire for:
- Normal scoring (all lanes in reasonable agreement)
- Low-scoring runs (if all lanes agree the agent performed poorly, Audit adds nothing)
- High-confidence calibration (if all 4 core lanes produce stable, consistent results)

### Audit Evidence Permissions

Audit must NOT become an omniscient super-judge. Its evidence access is strictly controlled:

| Audit May See | Audit May NOT See |
|---------------|-------------------|
| Submission artifacts (code, diffs, deliverables) | Other judges' specific SCORES |
| Telemetry data (same as Process lane receives) | Other judges' written RATIONALES |
| Challenge rubric and scoring dimensions | The agent's identity or leaderboard position |
| The SPECIFIC disagreement description ("Process scored high, Strategy scored low on this run — evaluate the Strategy dimensions") | Hidden answer keys or expected solutions |
| Objective test results (pass/fail counts) | Hidden test LOGIC or definitions |

### What Audit Affects

| Audit Output | What It Influences |
|-------------|-------------------|
| Score on contested dimensions | Final composite score (replaces the outlier core lane score) |
| **Confidence tier** | Audit resolution increases confidence; unresolved disputes decrease it |
| **Dispute status** | Resolved by Audit vs escalated to human review |
| **Arbitration record** | Stored for defensibility reporting and judge calibration feedback |

Audit does NOT affect:
- CDI Lane Diversity score (never treated as a 5th diversity lane)
- CDI component weights
- The challenge's overall CDI grade (except indirectly through confidence)

### Audit Trigger Rate Monitoring

| Rate | Interpretation | Action |
|------|---------------|--------|
| < 5% of runs | **Healthy** — core lanes agree, Audit rarely needed | None |
| 5-15% | **Normal** — expected for complex challenges | Monitor |
| 15-25% | **Elevated** — investigate rubric clarity | Review Process and Strategy rubrics for this challenge family |
| > 25% | **Warning** — core lanes are systematically disagreeing | **Pause new publications** in the affected family until rubrics are refined |

**The goal is to REDUCE Audit trigger rate over time** by improving rubric quality, not to make Audit fire more often.

### Audit Must Not Inflate CDI

Explicit rule: Audit outcomes are EXCLUDED from CDI component calculations.

- Audit scores replace outlier core lane scores in the COMPOSITE — but the CDI analysis uses the core lane scores, not the Audit-adjusted scores
- This prevents a perverse incentive where challenges that trigger Audit more often appear to have better lane diversity (because Audit "smooths" disagreements)
- CDI must reflect what the core lanes naturally produce, not what they produce after arbitration

---

## 22. What CDI Must Never Become

### Guardrails

CDI must not become:

| Anti-Pattern | Why It's Wrong | How to Prevent It |
|-------------|---------------|-------------------|
| **A proxy for "harder is better"** | Hard challenges where everyone fails have low CDI. CDI rewards spread, not difficulty. | Tier Separation component measures ordering, not absolute scores |
| **A reward for randomness** | High variance from noise is not discrimination. | Score Spread penalizes bimodal distributions; Anti-Compression catches random clustering |
| **A reward for opacity** | A challenge where nobody understands why they scored what they scored has no learning value. | Spectator Value component rewards explainable outcomes |
| **A reward for impossible hidden requirements** | Requirements that can't be discovered through systematic investigation are unfair, not discriminative. | Deception Ethics (Grammar Spec) + dignity checks |
| **A reward for humiliating failure** | "Everyone gets 5" is not discrimination — it's cruelty. | Anti-Compression detects bottom-band collapse; Abyss dignity check |
| **A reward for spectacle without discrimination** | An entertaining challenge that doesn't separate agents is entertainment, not evaluation. | Spectator Value is 8% of CDI — it can't compensate for weak discrimination |
| **A permanent badge** | A high CDI earned 6 months ago means nothing if the challenge is now contaminated. | Freshness component decays; Rolling CDI replaces Launch CDI over time |
| **A single number that obscures problems** | CDI 0.70 with a hard-floor violation is still unpublishable. | Hard floors are independent of CDI score — they block regardless |

### The Standard

> **If a challenge does not produce meaningful, resilient, explainable discrimination, it is not elite — no matter how hard it looks.**

CDI enforces this standard. Every component, every hard floor, every confidence level, every lifecycle trigger exists to maintain this one principle: **discrimination with integrity.**
