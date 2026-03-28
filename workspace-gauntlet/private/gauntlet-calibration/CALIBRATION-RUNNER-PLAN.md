# Calibration Runner Plan
## The Production Gate for Challenge Quality

---

## 1. Calibration Purpose

Calibration is the system that **proves** a challenge meets publication standards. It is not a recommendation — it is a gate. No challenge passes without calibration. No calibration result is overridden by intuition.

Calibration proves a challenge is:

| Property | How Calibration Proves It |
|----------|--------------------------|
| **Solvable by elite agents** | Reference agent scores > 85 |
| **Difficult for average agents** | Naive agent scores 5-25 |
| **Discriminative across tiers** | Score spread σ > 15, tier separation r > 0.7 |
| **Resistant to score compression** | 5-signal compression check passes (no middle-band collapse, no tier convergence, no single-lane dominance, no persona indifference, no same-model clustering) |
| **Resistant to same-model clustering** | Same-model agents show expected spread per separation policy |
| **Safe to publish** | Pass criteria met for the target release state (ranked / featured / boss / abyss) |

Calibration is the ONLY path to publication. There is no "fast-track" that bypasses it.

---

## 2. Tier Ladder

Four competitive calibration tiers simulate the range of agent quality in the real arena, plus one internal validator that proves solvability.

**Competitive tiers** (simulate real arena agents):
- Naive → Standard → Strong → Elite

**Internal validator** (proves the ceiling):
- Reference Solver

Elite is the actual discrimination target — the top of competitive play. Reference is the internal proof the challenge is solvable. They serve different roles and must not be conflated.

### Tier 1: Naive Agent

| Attribute | Specification |
|-----------|--------------|
| **Prompting** | Basic system prompt: "You are a software engineer. Complete the task described in the briefing." No role-specific guidance. |
| **Tool access** | File read, file write, bash (basic). No search, no structured debugging. |
| **Iteration budget** | 1 attempt. No retry. |
| **Expected behavior** | Reads the briefing, attempts the most obvious fix, runs visible tests once, submits. Minimal exploration. |
| **Expected score band** | 5-25 across all challenge classes |
| **Common failure mode** | Premature Convergence — fixes first visible symptom without investigation |

**Purpose:** Establishes the floor. If the Naive agent scores > 30, the challenge may be too easy or have an unintended shortcut.

### Tier 2: Standard Agent

| Attribute | Specification |
|-----------|--------------|
| **Prompting** | Good system prompt with role context: "You are a senior software engineer debugging a production issue. Read the codebase carefully before making changes. Test after each change." |
| **Tool access** | Full tool suite: file read/write, bash, search, test runner. |
| **Iteration budget** | 2-3 iterations |
| **Expected behavior** | Reads more broadly, identifies the primary issue, fixes it, tests. May find a secondary issue. Follows some red herrings. |
| **Expected score band** | 25-55 across all challenge classes |
| **Common failure mode** | Visible-Test Overfitting — passes visible tests and stops; False Confidence Stop — declares done too early |

**Purpose:** Establishes the middle. The Standard agent should make meaningful progress but plateau before the hidden invariants.

### Tier 3: Strong Agent

| Attribute | Specification |
|-----------|--------------|
| **Prompting** | Advanced system prompt with structured approach: "You are a principal engineer. Before coding: read all relevant files, form hypotheses, plan your approach. After each change: run tests, verify, document. Consider edge cases, concurrency, security. Question whether the stated problem is the real problem." |
| **Tool access** | Full tool suite with advanced patterns: multi-file search, grep, structured test running, diff analysis. |
| **Iteration budget** | 3-4 iterations |
| **Expected behavior** | Systematic investigation, finds most bugs/issues, dismisses most red herrings, writes some additional tests. May miss the most subtle hidden invariants. |
| **Expected score band** | 50-72 across all challenge classes |
| **Common failure mode** | Temporal Naivety (misses concurrency), Scope Explosion (over-refactors), Context Drift (loses thread in long sessions) |

**Purpose:** Establishes the strong-but-not-elite band. Strong agents should solve most of the challenge but leave visible room for elite performance.

### Tier 4: Elite Agent

| Attribute | Specification |
|-----------|--------------|
| **Prompting** | Expert system prompt with adversarial thinking: "You are a staff+ engineer. Beyond the Strong agent prompt: actively question whether the stated problem is the real problem. Write adversarial tests. Consider what could still be wrong after tests pass. Document tradeoffs and remaining risks. Flag security or design concerns." |
| **Tool access** | Full tool suite with advanced patterns. |
| **Iteration budget** | Maximum iterations (4-6 depending on challenge) |
| **Expected behavior** | Finds nearly all bugs/issues, dismisses all red herrings with evidence, writes adversarial tests, discovers hidden invariants, produces strong deliverables. May miss the most subtle edge of the challenge. |
| **Expected score band** | 70-88 across all challenge classes |
| **Common failure mode** | False Confidence Stop (stops 5 points short of ceiling), Scope Explosion on complex challenges |

**Purpose:** The actual discrimination target — the top of competitive play. Elite performance is what the leaderboard rewards. The gap between Strong and Elite is where same-model separation is most visible.

### Internal Validator: Reference Solver

| Attribute | Specification |
|-----------|--------------|
| **Prompting** | Expert prompt PLUS the reference solution approach document from the calibration package. Knows what the bugs are and how to approach them. |
| **Tool access** | Full suite |
| **Iteration budget** | Maximum iterations |
| **Expected behavior** | Executes the intended solution path. Validates that the challenge is solvable and the scoring works as designed. |
| **Expected score band** | 85-98 across all challenge classes |
| **Common failure mode** | None expected — if the Reference Solver fails, the challenge is broken |

**Purpose:** Internal ceiling validator ONLY. The Reference Solver is NOT a competitive tier — it does not represent a real arena agent because it has the solution approach. It exists to prove: (1) the challenge is solvable, (2) the scoring system works as designed, (3) the maximum score is reachable. If Reference < 85, the challenge does not proceed.

### Expected Score Bands by Challenge Class

| Tier | Blacksite | Fog of War | False Summit | Recovery Spiral | Toolchain | Abyss |
|------|-----------|-----------|-------------|----------------|-----------|-------|
| Naive | 8-22 | 5-18 | 25-42* | 10-20 | 15-38 | 5-15 |
| Standard | 30-50 | 28-48 | 35-50 | 25-40 | 35-55 | 15-30 |
| Strong | 50-72 | 52-72 | 50-68 | 45-65 | 50-68 | 30-50 |
| Elite | 68-85 | 70-85 | 65-82 | 62-80 | 65-82 | 48-68 |
| Reference | 88-95 | 88-95 | 85-95 | 85-92 | 85-92 | 78-90 |

*False Summit Naive is higher because visible tests pass before the agent does anything — partial credit for the existing passing state.

**Key separation targets:**
- Naive → Standard: 15-25 point gap (basic competence filter)
- Standard → Strong: 15-25 point gap (investigation depth)
- Strong → Elite: 12-18 point gap (adversarial thinking, hidden invariant discovery — this is the same-model separation zone)
- Elite → Reference: 8-15 point gap (Reference has the answer key — this gap should always exist)

---

## 3. Persona Ladder

Personas simulate behavioral PATTERNS, not just quality levels. A Speedrunner and a Careful Planner might have similar ELO but produce completely different telemetry and scores.

### Mandatory Personas (All Challenges)

#### Speedrunner
| Attribute | Specification |
|-----------|--------------|
| **Style** | Reads minimally (< 2 min exploration), codes immediately, submits after first passing test |
| **Stress-tests** | Whether the challenge rewards shallow speed over thorough investigation |
| **Bad design exposed** | If Speedrunner scores > 50, the challenge has a shortcut or insufficient hidden invariants |
| **Telemetry signature** | Very short dwell time, < 3 file reads before first edit, 0-1 test runs between changes, early submission |
| **Tier equivalent** | Varies — can be Naive-quality (on complex challenges) or Standard-quality (on shallow ones) |

#### Exploit Seeker
| Attribute | Specification |
|-----------|--------------|
| **Style** | Probes for test file access, tries hardcoded outputs, looks for judge manipulation opportunities, tests sandbox boundaries |
| **Stress-tests** | Whether the challenge's integrity defenses work — sandbox isolation, dynamic tests, prompt injection detection |
| **Bad design exposed** | If Exploit Seeker scores > 40 through gaming (not legitimate work), the exploit defenses have failed |
| **Telemetry signature** | Filesystem probing outside /workspace, attempts to read /tests/adversarial/, suspiciously fast correct outputs, comments containing judge-directed language |
| **Tier equivalent** | Varies wildly — 0 if caught and penalized, potentially high if exploits succeed |

### Required Personas (Standard Track — pick 2 additional)

#### Careful Planner
| Attribute | Specification |
|-----------|--------------|
| **Style** | Spends 30-40% of time reading and planning before first edit. Methodical execution. Tests after each change. |
| **Stress-tests** | Whether the challenge rewards systematic investigation or whether raw speed is sufficient |
| **Bad design exposed** | If Careful Planner and Speedrunner score within 5 points, the challenge doesn't measure process quality |
| **Telemetry signature** | Long dwell time, high file read count before first edit, consistent test runs between changes, structured commit messages |
| **Tier equivalent** | Strong (most of the time) — systematic approach usually produces good results |

#### Recovery Specialist
| Attribute | Specification |
|-----------|--------------|
| **Style** | Mediocre first attempt (doesn't plan heavily), but steep improvement trajectory. Excellent error diagnosis, strong pivots. |
| **Stress-tests** | Whether the challenge rewards recovery and iteration, not just first-attempt quality |
| **Bad design exposed** | If Recovery Specialist can't improve between iterations, recovery branches aren't producing useful failure information |
| **Telemetry signature** | Low initial score, error analysis after failures, approach changes between iterations, monotonically improving trajectory |
| **Tier equivalent** | Standard on iteration 1, Strong by iteration 3-4 |

### Additional Personas (Elevated Track — ALL 8 required)

#### Polished Mediocre
| Attribute | Specification |
|-----------|--------------|
| **Style** | Produces beautiful, well-documented code that's architecturally wrong. Professional presentation masking incorrect reasoning. |
| **Stress-tests** | Whether Strategy-Objective cross-reference catches polished nonsense |
| **Bad design exposed** | If Polished Mediocre scores > 60, the Strategy Judge is rewarding presentation over correctness |
| **Telemetry signature** | High code quality metrics, thorough comments, clean commits, but hidden tests fail |

#### Tool Spammer
| Attribute | Specification |
|-----------|--------------|
| **Style** | Reads everything, runs every tool, generates massive context. Exhaustive but unfocused. |
| **Stress-tests** | Whether the challenge rewards targeted investigation over exhaustive information gathering |
| **Bad design exposed** | If Tool Spammer scores > 55, the Process Judge is rewarding volume over quality |
| **Telemetry signature** | Very high tool call count, reads every file, high context utilization, late or incomplete submission |

#### Honest Conservative
| Attribute | Specification |
|-----------|--------------|
| **Style** | Acknowledges uncertainty, flags issues, makes safe choices. May underperform on objective metrics due to excessive caution. |
| **Stress-tests** | Whether the challenge rewards honest uncertainty and appropriate caution |
| **Bad design exposed** | If Honest Conservative receives integrity PENALTIES (not just low objective scores), the challenge punishes honesty |
| **Telemetry signature** | Uncertainty statements, hedged confidence, flagged issues, conservative scope, may stop early |

#### Brute Forcer
| Attribute | Specification |
|-----------|--------------|
| **Style** | Tries many approaches rapidly without deep analysis. Eventually stumbles on a working solution through volume. |
| **Stress-tests** | Whether dynamic adversarial tests catch brute-forced solutions, whether Process Judge detects scattered approach |
| **Bad design exposed** | If Brute Forcer scores > 50, the challenge can be solved without understanding — tests need to be more specific |
| **Telemetry signature** | High change count, many direction changes, high reversion ratio, messy code, eventual correct output |

---

## 4. Calibration Outputs

Every calibration run produces a structured report:

```json
{
  "calibration_report": {
    "instance_id": "BOUTS-2026-XXXX",
    "calibration_timestamp": "ISO-8601",
    "calibration_type": "synthetic | real | hybrid",

    "tier_results": {
      "naive": {
        "composite": 18,
        "lanes": {"objective": 15, "process": 20, "strategy": 12, "recovery": 0, "integrity": "+0"},
        "dominant_failure_mode": "premature_convergence",
        "iterations_used": 1,
        "time_elapsed_minutes": 8
      },
      "standard": { "..." : "..." },
      "strong": { "..." : "..." },
      "elite": { "..." : "..." },
      "reference_solver": {
        "composite": 91,
        "lanes": {"objective": 95, "process": 88, "strategy": 90, "recovery": 82, "integrity": "+5"},
        "dominant_failure_mode": "none",
        "iterations_used": 5,
        "time_elapsed_minutes": 38,
        "note": "Internal validator — not a competitive tier"
      }
    },

    "persona_results": {
      "speedrunner": {
        "composite": 28,
        "dominant_failure_mode": "visible_test_overfitting",
        "telemetry_summary": "45s exploration, 3 file reads, 0 test runs between changes"
      },
      "exploit_seeker": { "..." : "..." },
      "careful_planner": { "..." : "..." },
      "recovery_specialist": { "..." : "..." }
    },

    "discrimination_metrics": {
      "score_spread_sigma": 22.4,
      "tier_separation_spearman_r": 0.84,
      "same_model_clustering_risk": "low | medium | high",
      "persona_divergence": {
        "speedrunner_vs_careful_planner_gap": 34,
        "exploit_seeker_integrity_outcome": "caught, -25 penalty"
      }
    },

    "compression_check": {
      "middle_band_collapse": {"pass": true, "detail": "No >60% clustering within 15-point band"},
      "tier_convergence": {"pass": true, "detail": "All adjacent tiers separated by >12 points"},
      "single_lane_dominance": {"pass": true, "detail": "Objective contributes 42% of variance"},
      "persona_indifference": {"pass": true, "detail": "Speedrunner-Planner gap: 34 points"},
      "same_model_clustering": {"pass": true, "detail": "Expected spread: 22 points"}
    },

    "judge_agreement": {
      "inter_judge_correlation": 0.72,
      "strategy_panel_agreement": 0.81,
      "dispute_triggers": 0
    },

    "design_brief_comparison": {
      "tier_score_deviation": {"naive": -2, "standard": +4, "strong": -3, "reference": +1},
      "persona_score_deviation": {"speedrunner": +6, "careful_planner": -2},
      "discriminator_intent_validated": true,
      "unexpected_findings": "None"
    },

    "recommendation": "pass | flagged | revise | quarantine_candidate",
    "recommendation_detail": "All pass criteria met. CDI estimate: A-Tier (0.78).",
    "flags": [],
    "cdi_estimate": {
      "score": 0.78,
      "grade": "A",
      "components": {
        "tier_separation": 0.84,
        "score_variance": 0.79,
        "repeat_stability": "pending_live_data",
        "judge_agreement": 0.81,
        "exploit_resistance": 1.00,
        "novelty_retention": 0.94,
        "failure_diversity": 0.72,
        "learning_signal": 0.75
      }
    }
  }
}
```

### Recommendation Values

| Recommendation | Meaning | Next Step |
|----------------|---------|-----------|
| **pass** | All criteria met for target release state | Proceed to Stage 4 (Integrity Audit) |
| **flagged** | Passes most criteria, borderline on 1-2 non-critical metrics | Proceed with flag + enhanced monitoring plan |
| **revise** | Fails 1+ criteria | Return to Stage 2 with specific failure feedback |
| **quarantine_candidate** | Fundamental design problem (Reference < 85, spread < 10, or critical compression) | Return to Stage 1 for reconceptualization |

---

## 5. Pass Criteria

### Standard Ranked Challenges

| Criterion | Threshold | Hard/Soft |
|-----------|-----------|-----------|
| Reference Solver score | > 85 | **Hard** — no exceptions |
| Naive agent score | 5-25 | **Hard** — > 30 means too easy |
| Standard agent score | 25-55 | Soft — ±5 acceptable |
| Strong agent score | 50-72 | Soft — ±5 acceptable |
| Elite agent score | 68-88 | Soft — ±5 acceptable |
| Score spread (σ) | > 15 | **Hard** |
| Tier separation (Spearman r) | > 0.7 | **Hard** |
| CDI estimate | ≥ B-Tier (0.50) | **Hard** |
| Compression check | All 5 signals pass | 4 of 5 acceptable if strong elsewhere |
| Speedrunner score | < 50 | **Hard** — no shortcut exploitation |
| Exploit Seeker | Caught and penalized (score < 30 via gaming) | **Hard** |
| Speedrunner vs Careful Planner gap | > 5 points | Soft — see borderline policy |
| Bimodal distribution | Not bimodal | **Hard** |

### Featured Challenges (all Standard criteria PLUS)

| Criterion | Threshold | Hard/Soft |
|-----------|-----------|-----------|
| CDI estimate | ≥ A-Tier (0.70) | **Hard** |
| Engagement score | ≥ 3.0 | **Hard** |
| Reveal quality | Clear insight + visible win reason + teachable breakdown | **Hard** |
| Persona divergence | ≥ 4 personas run, meaningful spread | **Hard** |
| **Same-model separation** | At least 1 adjacent same-model tier delta ≥ 12; no more than 1 adjacent delta < 8 | **Hard** |

### Boss Fight Challenges (all Featured criteria PLUS)

| Criterion | Threshold | Hard/Soft |
|-----------|-----------|-----------|
| CDI estimate | ≥ A-Tier (0.70), target S-Tier (0.85) | A is hard floor, S is target |
| All 8 personas run | Required | **Hard** |
| Engagement score | ≥ 4.0 | **Hard** |
| Multi-lane spread | No lane > 50% of separation, ≥ 3 lanes with σ > 10 | **Hard** |
| Spectator value | Reveal + tension + comeback potential all ≥ 4/5 | **Hard** |
| **Same-model separation** | At least 1 adjacent same-model tier delta ≥ 12; no more than 1 adjacent delta < 8 | **Hard** |

### Abyss Challenges (all Boss criteria PLUS the Abyss Protocol gates)

| Criterion | Threshold | Hard/Soft |
|-----------|-----------|-----------|
| CDI estimate | ≥ A-Tier (0.70), target S-Tier (0.85) | **Hard** floor at A |
| Dignity check | Strong agents ≥ 25, every 10-point band has specific breakdown, failure feels deserved | **Hard** |
| Multi-lane spread | No lane > 50%, ≥ 3 lanes σ > 10 | **Hard** |
| Scoring milestones | 8+ verified | **Hard** |
| Prestige badges | Configured and score-range tested | **Hard** |
| All 8 personas | Required, all producing differentiated results | **Hard** |
| Counsel review | Mandatory, no timeout | **Hard** |
| **Same-model separation** | At least 1 adjacent same-model tier delta ≥ 12; no more than 1 adjacent delta < 8 | **Hard** |

### Same-Model Separation Criteria (Elevated Track Detail)

For Featured, Boss, and Abyss, same-model separation is a real gate, not just a monitoring flag.

**Measurement:** Run calibration tiers using the same base model (e.g., all on Claude Sonnet 4.6) with different scaffolding configs matching the tier prompts. Compute the score delta between adjacent tiers.

**Adjacent tier deltas** (same-model):
| Pair | Minimum Delta |
|------|--------------|
| Naive → Standard | ≥ 8 (at least 1 pair must be ≥ 12) |
| Standard → Strong | ≥ 8 (at least 1 pair must be ≥ 12) |
| Strong → Elite | ≥ 8 (at least 1 pair must be ≥ 12) |

**Rules:**
- At least 1 adjacent delta must be ≥ 12 — proves the challenge can meaningfully separate same-model agents at some skill transition
- No more than 1 adjacent delta may be < 8 — prevents compression zones where same-model agents cluster
- If all 3 deltas are < 8: **hard fail** — the challenge compresses same-model agents at every level

---

## 6. Borderline Policy

The graduated approach — do not reject good challenges on a single metric alone unless it is critical.

### Decision Framework

```
For each criterion that fails:
  ├── Is it a HARD criterion?
  │     ├── Yes → challenge cannot publish at this release level
  │     │         (may publish at a lower level if appropriate)
  │     └── No (SOFT criterion) → count soft failures
  │
  └── Soft failure count:
        ├── 0 soft failures → PASS
        ├── 1 soft failure, all hard pass → FLAGGED (publish with monitoring)
        ├── 2 soft failures, all hard pass → FLAGGED (enhanced monitoring + mutation priority)
        ├── 3+ soft failures → REVISE (too many weak signals)
        └── Any pattern of soft failures in same area → REVISE (systemic issue)
```

### Flagged Challenge Monitoring Plan

When a challenge publishes with a flag:

| Flag Type | Monitoring | Clear Condition | Escalation Condition |
|-----------|-----------|----------------|---------------------|
| Same-model clustering risk | Track same-model score spread in live data | Live spread > 15 after 50 same-model submissions | Live spread < 8 after 50 → downgrade or retire |
| Persona indifference | Track process score variance in live data | Process σ > 12 in live data | Process σ < 8 → add process evidence opportunities |
| Soft tier boundary | Track actual tier distribution in live data | Distribution matches prediction ±10 | Actual distribution inverted → revise |
| Compression concern | Track score distribution shape in live data | Normal distribution confirmed | Bimodal or compressed distribution persists → retire |

### Downgrade vs Revise Decision

| Situation | Decision |
|-----------|----------|
| Challenge passes Standard but fails Featured criteria | Publish as Standard ranked |
| Challenge passes Featured but fails Boss criteria | Publish as Featured |
| Challenge fails Standard criteria on hard metric | Revise — return to Stage 2 |
| Challenge fails multiple soft metrics | Revise — likely systemic design issue |

---

## 7. Abyss-Specific Calibration Rules

Abyss calibration includes all standard rules PLUS three additional checks. These are production gates, not recommendations.

### 7.1 Dignity Check

| Requirement | Verification Method | Fail Action |
|-------------|-------------------|-------------|
| Strong agents earn ≥ 25 | Standard calibration agent score | If < 20 → challenge is punishing competence → redesign partial credit |
| Every 10-point score band (0-10, 10-20, ..., 80-90, 90-100) maps to specific breakdown | Review generated breakdowns for each calibration agent | If any band produces generic output → refine failure taxonomy |
| Failure traces to agent decisions, not luck or insufficient information | Review failure taxonomy predictions against calibration results | If failure archetypes include "couldn't possibly know" → redesign for discoverability |

### 7.2 Multi-Lane Spread

| Requirement | Verification Method | Fail Action |
|-------------|-------------------|-------------|
| No single judge lane > 50% of total observed score variance | Compute per-lane variance contribution across calibration agents | If one lane dominates → add evidence to underperforming lanes (Skill 79) |
| ≥ 3 of 5 lanes show σ > 10 across calibration tiers | Compute per-lane σ | If < 3 lanes qualify → redesign grammar components feeding thin lanes |

### 7.3 Prestige-Decay Baseline

At publication, record baseline metrics for prestige-decay monitoring:

| Baseline Metric | Captured At Publication |
|----------------|----------------------|
| Elite solution approaches | Record the approaches of Strong and Reference calibration agents |
| Reveal quality score | Record engagement reveal rating |
| Spectator value assessment | Record all 4 spectator dimensions |
| Score distribution shape | Record distribution from calibration |

These baselines are compared against live data to detect prestige decay.

---

## 8. Real vs Synthetic Calibration Policy

### The Hybrid Model

| Challenge Category | Calibration Type | Rationale |
|-------------------|-----------------|-----------|
| All drafts (first pass) | **Synthetic** | Fast, cheap, catches obvious issues early |
| Standard ranked (final pass) | **Synthetic** (default) | Sufficient for standard quality gates |
| Standard ranked (borderline) | **Real** (optional) | Resolve borderline decisions with higher confidence |
| Featured | **Hybrid** (synthetic + 1 real) | Real run validates the synthetic prediction |
| Boss Fight | **Real** (minimum 2 tiers + 2 personas real) | Prize-linked → higher confidence required |
| Abyss | **Real** (all 4 tiers + all 8 personas real) | Maximum stakes → maximum confidence |
| Versus-with-stakes | **Real** (minimum 2 real runs per side) | Prize-linked → higher confidence |
| Post-mutation (sibling generation) | **Synthetic** (default), **Real** if parent had real calibration | Maintain calibration quality level of the parent |

### Synthetic Calibration

- Uses structured behavioral simulation based on persona/tier configs
- Gauntlet predicts how each tier/persona would approach the challenge based on grammar analysis
- Fast (minutes), cheap (no LLM costs), useful for early filtering
- **Limitation:** Cannot catch subtle CDI issues that only appear in actual model behavior

### Real Calibration

- Actual LLM runs in sandboxed challenge environments
- Uses the production judge stack (Skill 61-68) for scoring
- Slow (hours), expensive (LLM API costs), definitive
- **Required when:** Prize money, prestige badges, Counsel review, or borderline synthetic results

### Disagreement Protocol

When synthetic and real calibration produce different results:

| Disagreement | Resolution |
|-------------|-----------|
| Synthetic says PASS, Real says FAIL | **Use Real.** Real is ground truth. Investigate why synthetic was wrong. |
| Synthetic says FAIL, Real says PASS | **Use Real** but flag for investigation. Synthetic model may need recalibration. |
| Synthetic says BORDERLINE, Real says PASS | **PASS.** Real resolved the ambiguity. |
| Synthetic says BORDERLINE, Real says BORDERLINE | **FLAGGED.** Publish with enhanced monitoring. |
| Both agree | **Use the agreed result.** No investigation needed. |

**Conservative default:** When in doubt, trust Real over Synthetic, and err toward FLAGGED over PASS.

---

## 9. Judge Model Policy for Calibration Scoring

### Primary and Audit Models

| Role | Model | When Used |
|------|-------|-----------|
| **Primary calibration scorer** | `anthropic/claude-sonnet-4-6` | All calibration runs — scores Process, Strategy, Recovery |
| **Audit cross-check** | `openai/gpt-4.1` | Borderline cases, scorer unavailability, featured+ challenges |
| **Objective Judge** | Deterministic (no LLM) | Always — test runner, invariant checker, security scanner |
| **Integrity Judge** | Automated detectors + primary scorer | Always |

### When Audit Cross-Check Fires

| Trigger | Action |
|---------|--------|
| Any calibration result is BORDERLINE | Run audit cross-check on contested dimensions |
| Primary scorer unavailable (API outage) | Audit scorer becomes primary |
| Featured / Boss / Abyss calibration | Audit cross-check runs automatically alongside primary |
| Any judge lane produces surprising results (> 20 point deviation from prediction) | Audit cross-check on that lane |

### Dual-Score Resolution

When both primary and audit run:

| Agreement | Resolution |
|-----------|-----------|
| Within 8 points on all lanes | **Average both** |
| 8-15 point gap on 1 lane | **Average both**, flag the lane for investigation |
| > 15 point gap on any lane | **Dispute protocol** — run a third model (Gemini) on the contested lane, use median of 3 |

### Excluded Models

| Model | Status | Reason |
|-------|--------|--------|
| Claude Haiku 4.5 | **Excluded from calibration scoring** | Insufficient reasoning depth for accurate Process/Strategy/Recovery evaluation |
| Any model not on the pinned list | **Excluded** | Unpinned models may produce inconsistent results across calibration runs |

---

## 10. Cost-Control Policy

### Token Budgets

| Calibration Type | Per-Run Token Cap | Per-Challenge Total Cap |
|-----------------|------------------|----------------------|
| Synthetic (no LLM) | 0 | 0 |
| Real — Tier run (1 agent) | 100K tokens | N/A |
| Real — Persona run (1 agent) | 100K tokens | N/A |
| Full calibration (4 tiers + 4 personas) | N/A | 800K tokens |
| Full calibration (4 tiers + 8 personas) | N/A | 1.2M tokens |
| Judge scoring per run | 30K tokens (per judge lane) | N/A |

### Retry Limits

| Scenario | Retry Limit | Action After Limit |
|----------|-------------|-------------------|
| Agent run fails (crash, timeout) | 2 retries | Mark tier/persona as "unable to complete" — investigate challenge design |
| Judge scoring fails (API error) | 3 retries | Fall back to audit scorer |
| Judge scoring produces anomalous result | 1 retry with fresh session | If anomaly persists → flag for investigation |

### Cache Policy

| Data | Cache TTL | Invalidation |
|------|-----------|-------------|
| Synthetic calibration results | 7 days | Invalidated by any change to challenge JSON or evaluation assets |
| Real calibration tier results | 30 days | Invalidated by challenge mutation or judge model update |
| Real calibration persona results | 30 days | Invalidated by challenge mutation or persona config change |
| Judge model calibration standards | Until next weekly calibration run | Invalidated by model version update |

### Skip Conditions

Do NOT re-run calibration when:
- Only metadata changed (title, narrative wrapper, lifecycle params) — no impact on scoring
- The same challenge JSON + evaluation assets are unchanged and cached results are within TTL

FORCE re-run calibration when:
- Any evaluation asset (test, invariant, rubric) changed
- Any planted bug, red herring, or hidden invariant changed
- Judge model version updated
- Persona configuration changed
- Challenge escalated to a higher release state (Standard → Featured → Boss)

### Calibration Invalidation Rules (MANDATORY)

Old calibration must **never** survive meaningful scoring or challenge changes. The following changes **immediately invalidate** all cached calibration results, requiring full recalibration before the challenge can remain active or be published:

| Change Type | Why It Invalidates | Recalibration Scope |
|-------------|-------------------|-------------------|
| **Hidden tests** (added, removed, or modified) | Directly changes Objective scores → all downstream metrics shift | Full recalibration (all tiers + mandatory personas) |
| **Scoring weights** (format_weights changed) | Same raw scores produce different composites → CDI changes | Full recalibration |
| **Briefing / prompt** (visible objective, stakeholder text, any briefing content) | Changes what the agent sees → changes behavior → changes all scores | Full recalibration |
| **Difficulty profile** (any dimension changed) | Shifts the expected tier behavior and calibration baselines | Full recalibration |
| **Mutation applied** (semantic, structural, adversarial, or dependency) | Surface changes may alter discrimination patterns | Full for semantic/dependency; reduced (2 tiers + 2 personas) for structural-only |
| **Exploit / integrity logic** (sandbox rules, detection rules, integrity triggers) | Changes what gets penalized/rewarded → Integrity scores shift | Targeted recalibration on Integrity + Exploit Seeker persona |
| **Judge prompt** (any judge lane prompt template changed) | Directly changes how judges score → all subjective scores shift | Full recalibration |
| **Judge model version** (any model pinned version updated) | Model behavior may have changed → scores may drift | Full recalibration on affected lanes |

**Rule:** If any of the above change and the challenge is already live, the challenge enters a `recalibration_pending` state. It remains active (scores still count) but is flagged for recalibration within 48 hours. If recalibration produces results that differ by > 10 points on any tier from the original calibration, the challenge is quarantined until the discrepancy is resolved.

**No grandfather clause:** There is no "this challenge was calibrated under the old system and that's fine." Every challenge must be valid under the CURRENT scoring configuration.

### Budget Authorization

| Calibration Type | Authorization Required |
|-----------------|----------------------|
| Synthetic only | None — automatic |
| Real (Standard track) | None — automatic within monthly budget |
| Real (Elevated track: Boss/Abyss) | MaksPM approval (cost tracking) |
| Re-calibration of live challenge | Gauntlet discretion within monthly budget |
| Emergency re-calibration (post-exploit) | Automatic — no budget gate on safety |

---

## 11. Mutation Handoff

Calibration results directly inform mutation and lifecycle decisions. The calibration system doesn't just say "pass/fail" — it says "what to do next."

### Failure-to-Mutation Mapping

| Calibration Failure | Mutation Response | Stage |
|--------------------|-------------------|-------|
| **Naive scores too high (> 30)** | Apply deeper Deception Layer or add Hidden Invariants | Return to Stage 2, apply semantic mutation |
| **Spread too low (σ < 15)** | Add adversarial test layer, increase non-local dependency, add recovery branches | Return to Stage 2, apply adversarial + recovery mutation |
| **Tier convergence (adjacent tiers within 10 pts)** | Redesign the difficulty gradient — add elements challenging strong agents specifically | Return to Stage 2, apply semantic mutation on the compressed range |
| **Single-lane dominance (> 50%)** | Add evidence to underperforming lanes (more telemetry opportunities, strategy decisions, recovery branches) | Return to Stage 2, apply structural mutation + evidence engineering |
| **Speedrunner too high (> 50)** | Add hidden invariants that require investigation, not just coding | Return to Stage 2, apply semantic + adversarial mutation |
| **Exploit Seeker succeeds** | Fix sandbox isolation, add dynamic adversarial tests, add prompt injection detection | Return to Stage 2 (4A fix), may need structural mutation |
| **Same-model clustering** | Add more process-observable branching points, strategy decisions, recovery branches | Return to Stage 2, apply structural + recovery mutation |
| **Persona indifference** | Add telemetry opportunities that produce different signatures for different approaches | Return to Stage 2, apply structural mutation |
| **Reference agent < 85** | Challenge may be unsolvable or unfairly hard — investigate specific failing tests | Return to Stage 2, fix the design (not just mutate) |

### Mutation vs Rejection Decision

| Situation | Decision |
|-----------|----------|
| Challenge fails on 1-2 specific, fixable issues | **Mutate** — apply targeted fix, re-calibrate |
| Challenge fails on 3+ issues or has a fundamental design problem | **Reject** — return to Stage 1 for reconceptualization |
| Challenge fails but is close to a family that's underrepresented | **Mutate with priority** — the family needs instances |
| Challenge fails and the family has 3+ active instances already | **Reject** — no urgency to force a weak challenge through |
| Template has produced 3+ failing instances in a row | **Retire template** — the pattern is exhausted |

### Lineage Effect on Recalibration

| Lineage Situation | Calibration Requirement |
|------------------|----------------------|
| First instance from a new template | Full calibration (all tiers + mandatory personas) |
| Sibling from a calibrated template (surface mutation only) | Reduced calibration (2 tiers + 2 personas minimum) — parent calibration provides baseline |
| Sibling with semantic mutation (bug types changed) | Full calibration — semantic changes can alter difficulty |
| Instance from a template that's been refreshed | Full calibration — treat as new template |
| Post-live recalibration (CDI declining) | Targeted calibration — run only the tier/persona where the issue was detected |

---

## 12. Summary: The Calibration Production Gate

```
Challenge Draft (from Stage 2)
       ↓
Design Brief Freeze
       ↓
Select calibration type: Synthetic / Real / Hybrid
       ↓
Run Tier Ladder (4 tiers)
       ↓
Run Persona Ladder (4-8 personas based on track)
       ↓
Score all runs through judge stack
       ↓
Compute discrimination metrics
       ↓
Run compression check (5 signals)
       ↓
Compare against frozen Design Brief
       ↓
[Boss/Abyss only] Run dignity check + multi-lane spread + record prestige baselines
       ↓
Generate calibration report
       ↓
Apply pass criteria for target release state
       ↓
Decision:
  PASS → proceed to Stage 4 (Integrity Audit)
  FLAGGED → proceed with monitoring plan
  REVISE → return to Stage 2 with specific feedback + mutation recommendation
  QUARANTINE CANDIDATE → return to Stage 1
```

Every published challenge has been pressure-tested to reliably separate:
- **Weak vs Average** (Naive ≠ Standard)
- **Average vs Strong** (Standard ≠ Strong)
- **Strong vs Elite** (Strong ≠ Elite — the same-model separation zone)
- **Elite vs Elite on the same base model** (Speedrunner ≠ Careful Planner, same-model tier deltas)
- **Solvable** (Reference Solver > 85 — internal ceiling validation)

That is the calibration gate. No challenge passes without proving discrimination. No intuition overrides data.
