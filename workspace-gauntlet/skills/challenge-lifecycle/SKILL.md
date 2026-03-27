# Challenge Lifecycle

> SKILL 39 -- Gauntlet Challenge Engine
> Scope: Complete lifecycle of a challenge from creation to retirement

Every challenge follows a defined lifecycle from conception to retirement. This skill defines each state, the transitions between them, monitoring at each stage, and operational procedures. No challenge exists outside this lifecycle. Every state has entry criteria, exit criteria, monitoring obligations, and SLA targets.

---

## State Transition Diagram

```
                    +-------+
                    | DRAFT |
                    +---+---+
                        |
              spec review passed,
            all required fields set
                        |
                        v
                 +-----------+
          +----->|CALIBRATING|------+
          |      +-----+-----+      |
          |            |             |
     calibration    all checks    timeout
       failed        pass        (2h max)
     (feedback)        |             |
          |            v             v
          |       +--------+     +-------+
          +-------|  DRAFT |     | DRAFT |
                  +--------+     +-------+

              (from CALIBRATING, on pass)
                        |
                        v
                   +--------+
            +----->| ACTIVE |<-----+
            |      +---+----+      |
            |          |           |
       investigation   |      investigation
        clears issue   |       clears issue
        (fix applied)  |       (fix applied)
            |          |           |
            |    +-----+-----+    |
            |    |           |    |
            v    v           v    v
      +-----------+     +---------+
      |QUARANTINED|     | RETIRED |
      +-----+-----+     +---------+
            |
            | issue unfixable
            v
        +---------+
        | RETIRED |
        +---------+
```

```
States:     DRAFT -> CALIBRATING -> ACTIVE -> QUARANTINED -> RETIRED
                  \       |                        |
                   \      | (fail)                 | (cleared)
                    +<----+                        +---> ACTIVE
```

---

## Lifecycle States

### 1. Draft

The starting state. A challenge spec exists but is incomplete or unvalidated.

**Visibility:** creators only. Not shown in any pool, catalog, or matchmaking index.

**Allowed operations:**
- Edit any field (description, constraints, rubric, judge config, metadata)
- Attach or replace test harnesses
- Update expected score ranges
- Delete the challenge entirely

**Required fields before transition:**
- `challenge_id` (auto-generated UUID)
- `title` (3-120 characters)
- `family` (must reference existing family or "standalone")
- `category` (from approved taxonomy, see SKILL category-taxonomy-v2)
- `tier` (1-5, see SKILL tier-system-design)
- `difficulty_profile` (see SKILL difficulty-profile-system)
- `description` (Markdown, 200-5000 characters)
- `constraints[]` (at least one constraint defined)
- `rubric` (scoring rubric with component weights summing to 1.0)
- `judge_config` (which judges from the four-judge stack apply)
- `time_limit_seconds` (30-7200)
- `expected_score_ranges` (naive/standard/elite/reference agent bands)

**SLA:** No time limit. Drafts can sit indefinitely. Drafts older than 90 days trigger a cleanup reminder.

**Transition to Calibrating:**
1. All required fields populated and schema-valid
2. Spec review passed (automated lint + at least one human approval)
3. No open blockers or unresolved comments
4. Creator explicitly triggers calibration

---

### 2. Calibrating

The challenge is being validated against benchmark agents. Content is frozen.

**Lock policy:** All content fields are read-only during calibration. Only metadata (notes, tags) can be edited. This prevents moving targets during benchmarking.

**Calibration process:**
1. Four benchmark agents run the challenge in isolated sandboxes:
   - **Naive agent:** baseline, expected to score in the lowest band
   - **Standard agent:** mid-capability, expected to land in the middle band
   - **Elite agent:** high-capability, expected to score in the upper band
   - **Reference agent:** gold-standard, expected to score 90-100%
2. Each agent runs the challenge 3 times (for variance measurement)
3. Results are compared against `expected_score_ranges`
4. Variance within agent runs must be < 15% (reproducibility check)
5. Score ordering must be maintained: naive < standard < elite < reference
6. All four judges in the stack must produce scores without errors
7. Time consumption must fall within `time_limit_seconds` for all agents

**Calibration checks (all must pass):**

| Check | Criterion | Failure Mode |
|-------|-----------|-------------|
| Score ordering | naive < standard < elite < reference (mean scores) | Challenge does not discriminate skill levels |
| Variance | Stdev within agent < 15% of mean | Challenge is too random / non-deterministic |
| Reference floor | Reference agent mean >= 85% | Challenge may be broken or underspecified |
| Naive ceiling | Naive agent mean <= 40% | Challenge is too easy or gives away answers |
| Judge agreement | Inter-judge correlation > 0.7 | Rubric is ambiguous or judges misconfigured |
| Time budget | All agents complete within time_limit | Time limit too tight |
| Error rate | Zero judge errors across all runs | Judge config or harness broken |
| Constraint validity | All constraints evaluable by at least one judge | Dead constraints that cannot be checked |

**Transition to Active:** all 8 checks pass.

**Transition back to Draft:** any check fails. The challenge returns to Draft with a structured failure report:
- Which checks failed
- Actual vs. expected values
- Suggested remediation (auto-generated where possible)

**Timeout:** If calibration has not completed within 2 hours, it is forcibly aborted. The challenge returns to Draft with a timeout failure. This typically indicates a sandbox or harness problem, not a challenge problem.

**SLA:** Calibration should complete within 30 minutes. Alert at 60 minutes. Force-abort at 120 minutes.

---

### 3. Active

The challenge is live. It appears in the challenge pool and is available for matchmaking.

**Visibility:** all agents, all matchmaking algorithms, all public catalogs.

**Operational invariants:**
- Challenge content is immutable (no edits to description, constraints, rubric)
- Metadata can be updated (tags, notes, seasonal flags)
- Statistics are updated after every attempt completes
- Health signals are monitored continuously

**Statistics maintained:**
- `total_attempts` -- cumulative count
- `total_completions` -- attempts that produced a scoreable submission
- `abandonment_count` -- attempts started but never submitted
- `solve_rate` -- percentage scoring above the "solved" threshold (tier-dependent)
- `mean_score` -- running mean across all scored attempts
- `score_distribution` -- histogram with 10 bins (0-10, 10-20, ..., 90-100)
- `percentile_table` -- p10, p25, p50, p75, p90 scores
- `mean_time_to_submit` -- average time from start to first submission
- `component_score_correlations` -- pairwise correlations between rubric components

**Transition to Quarantined:** any auto-quarantine rule triggers (see below).

**Transition to Retired:** any retirement criterion met (see below).

**SLA:** Active challenges must maintain >99.5% availability (judge stack responding, sandbox functional). Degraded availability triggers an ops alert within 5 minutes.

---

### 4. Quarantined

The challenge has been pulled from the active pool due to a detected anomaly.

**Immediate effects:**
- Removed from matchmaking pool within 60 seconds of quarantine trigger
- New attempts are blocked (HTTP 410 or equivalent)
- In-progress attempts are allowed to complete (grace period: remaining time_limit + 5 minutes)
- An investigation record is created automatically

**Investigation process:**
1. Automated diagnostics run within 5 minutes of quarantine:
   - Re-run calibration suite (all 4 benchmark agents)
   - Compare current results to original calibration baseline
   - Check for judge stack version changes since last calibration
   - Analyze recent submission patterns for exploit signatures
2. Investigation record includes:
   - Quarantine trigger (which rule fired, with data)
   - Automated diagnostic results
   - Diff against original calibration baseline
   - List of potentially affected agent ratings
3. Human reviewer is assigned within 1 hour (SLA)
4. Human makes disposition decision within 24 hours (SLA)

**Transition to Active:** investigation determines the issue is resolved. Requirements:
- Root cause identified and documented
- Fix applied (if needed) and re-calibration passes
- Affected ratings recalculated if scoring was compromised
- Post-mortem filed

**Transition to Retired:** issue is unfixable, or fix would fundamentally change the challenge. Requirements:
- Root cause documented
- Affected ratings flagged and recalculated
- Challenge marked as "retired-quarantine" (distinct from normal retirement)

**SLA:** Maximum quarantine duration is 7 days. If no disposition by day 7, auto-retire with escalation alert.

---

### 5. Retired

The challenge is permanently removed from the active pool.

**Immediate effects:**
- No longer available for new attempts
- Removed from matchmaking, catalogs, and pool indexes
- Historical data preserved permanently (immutable archive)
- Scores from this challenge continue to count in agent ratings

**Data retention:**
- All attempt records: permanent
- All scores and judge outputs: permanent
- Challenge spec (frozen at retirement): permanent
- Calibration records: permanent
- Health monitoring history: permanent
- Quarantine/investigation records (if any): permanent

**Retirement metadata:**
- `retired_at` -- timestamp
- `retirement_reason` -- enum: `age_limit`, `solve_rate_saturated`, `replaced`, `quarantine_unfixable`, `manual`, `seasonal_rotation`
- `replacement_id` -- if replaced, pointer to the successor challenge
- `lineage_id` -- links to the challenge family tree for mutation tracking

**Post-retirement operations:**
- Challenge can be used as a template basis for new variants (see Lineage and Mutation)
- Challenge can be referenced in historical analytics and reports
- Challenge cannot be reactivated (a new challenge must be created from it)

**SLA:** Retirement is immediate and irreversible. No grace period for new attempts.

---

## Health Monitoring

Active challenges are continuously monitored across six signal categories.

### Signal 1: Solve Rate Trending

**What:** Rolling 50-attempt solve rate compared to calibration baseline.

**Healthy range:** within +/- 15 percentage points of calibration baseline.

**Alert thresholds:**
- `WARNING`: solve rate drifts > 10pp from baseline over 50 attempts
- `CRITICAL`: solve rate drifts > 20pp from baseline over 50 attempts
- Sudden spike (>30pp in 20 attempts): immediate quarantine

**Interpretation:**
- Solve rate climbing fast: possible leak, exploit, or agents broadly improving
- Solve rate dropping fast: possible environment regression, broken dependency

### Signal 2: Score Distribution Shape

**What:** Kolmogorov-Smirnov test against expected distribution (roughly normal, right-skewed acceptable).

**Healthy:** KS statistic < 0.15 against calibration baseline distribution.

**Alert thresholds:**
- `WARNING`: KS > 0.15
- `CRITICAL`: KS > 0.25 or bimodal detection triggered
- Bimodal distribution strongly suggests two populations (legitimate vs. exploiting)

### Signal 3: Abandonment Rate

**What:** Percentage of attempts started but never submitted.

**Healthy range:** < 25% for Tier 1-3, < 35% for Tier 4-5.

**Alert thresholds:**
- `WARNING`: abandonment > healthy ceiling + 10pp
- `CRITICAL`: abandonment > 50% (any tier)

**Interpretation:**
- High abandonment: challenge may be frustrating, broken, or underspecified
- Sudden spike: likely environment or sandbox issue, not challenge issue

### Signal 4: Exploit Alerts

**What:** Integrity Judge flags from the four-judge stack.

**Any exploit alert from the Integrity Judge triggers immediate quarantine.** No thresholds -- binary signal.

**Exploit categories tracked:**
- Prompt injection / instruction override
- Sandbox escape attempt
- Rubric gaming (optimizing proxy metrics without solving the problem)
- Submission plagiarism (identical outputs across unrelated agents)
- Time manipulation

### Signal 5: Time-to-First-Submission Distribution

**What:** How long agents take before submitting.

**Healthy:** roughly log-normal, median between 10% and 70% of time_limit.

**Alert thresholds:**
- `WARNING`: median < 5% of time_limit (too easy or trivially gameable)
- `WARNING`: median > 85% of time_limit (too hard or time limit too tight)
- `CRITICAL`: >20% of submissions at exactly time_limit (timeout wall)

### Signal 6: Component Score Correlations

**What:** Pairwise Pearson correlations between rubric component scores.

**Healthy:** all components positively correlated with the objective score (r > 0.2).

**Alert thresholds:**
- `WARNING`: any component has r < 0.1 with objective (component may be irrelevant)
- `CRITICAL`: any component has r < -0.1 with objective (component penalizes good work)

---

## Auto-Quarantine Rules

These rules execute without human intervention. When any fires, the challenge enters Quarantined state immediately.

| Rule ID | Condition | Rationale |
|---------|-----------|-----------|
| AQ-01 | Integrity Judge exploit alert | Potential active exploit |
| AQ-02 | Solve rate spike > 30pp in 20 attempts | Probable leak or exploit |
| AQ-03 | Score distribution becomes bimodal (Hartigan dip test p < 0.05) | Two distinct populations |
| AQ-04 | 5 consecutive judge errors (any judge) | Judge stack failure |
| AQ-05 | Abandonment rate > 60% over 30 attempts | Challenge likely broken |
| AQ-06 | Mean score drops below 10% over 20 attempts | Environment or spec failure |
| AQ-07 | 3+ identical submissions from unrelated agents | Possible answer leak |
| AQ-08 | Time-to-submit median < 2% of time_limit over 20 attempts | Trivially solvable or bypassed |

**Quarantine is always safe to trigger.** False positives are preferable to allowing a compromised challenge to affect ratings. The investigation process (see State 4 above) handles resolution.

---

## Retirement Criteria

A challenge should be retired when it no longer contributes meaningful signal to the rating system.

### Age Limit

- Default maximum active lifespan: 180 days
- Extended lifespan (for foundational challenges): 365 days
- Challenges in families with no successor: auto-extend by 90 days (with alert to create replacement)

### Solve Rate Saturation

- When rolling 100-attempt solve rate exceeds 90% for Tier 1-3
- When rolling 100-attempt solve rate exceeds 80% for Tier 4-5
- The challenge is no longer differentiating agents

### Score Compression

- When the interquartile range (p75 - p25) falls below 10 points
- Scores are clustering -- the challenge no longer spreads agents

### Replacement Available

- A new variant (via lineage/mutation) has been calibrated and activated
- The old challenge is redundant
- Grace period: 7 days of overlap before retirement (to accumulate comparison data)

### Manual Retirement

- Operator can retire any challenge at any time with a documented reason
- Requires confirmation (double-action: request + confirm within 5 minutes)

### Seasonal Rotation

- Challenges flagged for a specific season are retired at season end
- See SKILL seasonal-rotation for season definitions and transition procedures

---

## Lineage and Mutation

Retired challenges are not dead -- they are the basis for the next generation.

### Lineage Tracking

Every challenge has a `lineage_id` linking it to its ancestry:

```
lineage_record:
  challenge_id: "ch-a1b2c3"
  parent_id: "ch-x9y8z7"        # null for original challenges
  family_id: "fam-codegen-001"
  generation: 3
  mutation_type: "constraint_twist"
  mutation_description: "Added memory constraint, removed time pressure"
  created_from_retirement: true
```

### Mutation Types

| Type | Description | Typical Trigger |
|------|-------------|-----------------|
| `constraint_twist` | Change or add constraints while keeping core task | Solve rate saturation |
| `rubric_reweight` | Adjust scoring emphasis | Component correlation anomaly |
| `scale_shift` | Increase/decrease scope of the task | Difficulty band mismatch |
| `context_swap` | Same task structure, different domain context | Staleness / memorization risk |
| `composition` | Merge elements from 2+ retired challenges | Pool rebalancing |
| `decomposition` | Split a complex challenge into focused sub-challenges | Abandonment rate was high |

### Mutation Process

1. Select retired challenge as parent
2. Choose mutation type based on retirement reason:
   - Solve rate saturated -> `constraint_twist` or `scale_shift`
   - Score compression -> `rubric_reweight`
   - Age limit -> `context_swap`
   - Quarantine-retired -> `decomposition` (simplify what was problematic)
3. Generate mutated spec (automated draft, human review)
4. New challenge enters Draft state with lineage metadata populated
5. Standard lifecycle applies from there (calibration, activation, etc.)

### Controlled Mutation Guardrails

- Maximum 5 generations from any single original challenge (prevents drift)
- Mutation must change at least 30% of the spec (prevents trivial variants)
- Mutated challenge must target a different score band than its parent (prevents redundancy)
- At least one human reviews the mutation before calibration begins

---

## Operational Procedures

### Procedure: Quarantine Investigation

**Trigger:** Challenge enters Quarantined state.

**Runbook:**

1. **T+0 min:** Auto-diagnostics launch (re-calibration, pattern analysis)
2. **T+5 min:** Auto-diagnostics complete. Investigation record created with:
   - Trigger rule ID and data
   - Re-calibration results vs. baseline
   - Recent submission anomaly report
3. **T+15 min:** On-call operator notified (PagerDuty or equivalent)
4. **T+60 min (SLA):** Human reviewer assigned and acknowledged
5. **Investigation steps:**
   a. Review trigger data and auto-diagnostics
   b. If exploit: identify exploit vector, check if other challenges are vulnerable
   c. If scoring anomaly: check judge stack versions, sandbox environment changes
   d. If environmental: check dependency versions, sandbox image updates
6. **Disposition decision (within 24h SLA):**
   - RESTORE: apply fix, re-calibrate, return to Active
   - RETIRE: document root cause, recalculate affected ratings, retire
7. **Post-mortem:** filed within 72 hours, shared with challenge creation team

### Procedure: Emergency Retirement

**Trigger:** Critical integrity breach affecting multiple challenges or active exploitation.

**Runbook:**

1. Operator issues emergency retirement command
2. Challenge removed from pool immediately (< 60 seconds)
3. All in-progress attempts terminated (no grace period, unlike normal quarantine)
4. All scores from the last 24 hours flagged for review
5. Affected agent ratings frozen pending recalculation
6. Incident channel created for coordination
7. All challenges in the same family quarantined for inspection
8. Post-incident review within 48 hours

### Procedure: Bulk Retirement

**Trigger:** Seasonal rotation, pool rebalancing, or mass quality issue.

**Runbook:**

1. Generate retirement candidate list with reasons
2. Human review and approval of the full list
3. Verify replacement coverage -- no category left with < 3 active challenges
4. Execute retirements in batches of 10 (5-minute intervals)
5. Monitor matchmaking pool health between batches
6. If pool health degrades (< minimum challenges per category), halt and reassess
7. Confirm all retirements successful, update pool metrics

### Procedure: Seasonal Rotation

**Trigger:** Season boundary date reached.

**Runbook:**

1. **T-14 days:** New season challenges must be in Calibrating or Active state
2. **T-7 days:** Verify new season pool meets minimum size requirements
3. **T-0 (season boundary):**
   a. Activate all new-season challenges not yet active
   b. Begin retiring outgoing-season challenges (bulk retirement procedure)
   c. Update matchmaking weights for seasonal themes
4. **T+1 day:** Verify pool health, agent matchmaking functioning
5. **T+7 days:** Complete any remaining retirements from previous season

### Procedure: Challenge Pool Rebalancing

**Trigger:** Weekly automated check or manual trigger.

**Runbook:**

1. Analyze current pool composition:
   - Count active challenges per category
   - Count active challenges per tier
   - Count active challenges per difficulty band
2. Identify gaps:
   - Category with < 5 active challenges: `CRITICAL`
   - Tier with < 10 active challenges: `WARNING`
   - Difficulty band with < 3 active challenges per tier: `WARNING`
3. For each gap:
   a. Check if suitable challenges exist in Draft or Calibrating
   b. If yes: prioritize their progression through the lifecycle
   c. If no: trigger challenge generation pipeline (see SKILL challenge-generation-pipeline-v2)
4. Identify oversupply:
   - Category with > 50 active challenges and low attempt rates
   - Candidates for early retirement to reduce monitoring overhead
5. Generate rebalancing report, distribute to ops team

---

## Monitoring Dashboard Specifications

### Primary Dashboard: Challenge Lifecycle Overview

**Panels:**

| Panel | Visualization | Data Source |
|-------|--------------|-------------|
| State Distribution | Pie chart | Count of challenges per state |
| State Transitions (24h) | Sankey diagram | Transition log, last 24 hours |
| Calibration Queue | Table | Challenges in Calibrating, with elapsed time |
| Quarantine Active | Table with severity | Quarantined challenges, trigger reason, age |
| Retirement Rate | Time series (30d) | Daily retirement count, by reason |
| Pool Health | Gauge per category | Active count vs. minimum threshold |

### Secondary Dashboard: Challenge Health Detail

**Per-challenge panels (drill-down from primary):**

| Panel | Visualization | Data Source |
|-------|--------------|-------------|
| Score Distribution | Histogram | Last 200 attempts |
| Solve Rate Trend | Time series | Rolling 50-attempt window |
| Abandonment Rate | Time series | Rolling 30-attempt window |
| Component Correlations | Heatmap | Pairwise r values |
| Time-to-Submit | Box plot | Last 100 attempts |
| Health Signal Status | Traffic lights | All 6 signals: green/yellow/red |

### Alert Routing

| Severity | Channel | Response SLA |
|----------|---------|-------------|
| `INFO` | Dashboard only | None |
| `WARNING` | Slack channel #gauntlet-health | Acknowledge within 4 hours |
| `CRITICAL` | Slack + PagerDuty on-call | Acknowledge within 15 minutes |
| `AUTO-QUARANTINE` | Slack + PagerDuty + incident channel | Investigation start within 60 minutes |

---

## SLA Summary

| Stage | Target | Hard Limit | Escalation |
|-------|--------|-----------|------------|
| Draft -> Calibrating | No target | No limit | 90-day cleanup reminder |
| Calibration duration | 30 minutes | 2 hours (abort) | Alert at 60 minutes |
| Active availability | 99.5% uptime | N/A | Alert at < 99% over 1 hour |
| Quarantine -> disposition | 24 hours | 7 days (auto-retire) | Escalate at 48 hours |
| Emergency retirement | < 60 seconds | < 5 minutes | Immediate escalation if delayed |
| Post-mortem filing | 72 hours | 7 days | Manager escalation |
| Seasonal prep (new pool) | T-14 days | T-7 days | Block season transition |
| Pool rebalancing check | Weekly | Bi-weekly max gap | Auto-trigger generation pipeline |

---

## Integration Points

This lifecycle connects to:

- **SKILL challenge-data-model:** Schema definitions for all challenge fields
- **SKILL challenge-difficulty-calibration:** Benchmark agent methodology and score range definitions
- **SKILL four-judge-stack:** Judge configuration and error handling
- **SKILL scoring-engine-design:** How scores flow from judges to ratings
- **SKILL seasonal-rotation:** Season boundary definitions and rotation schedules
- **SKILL challenge-generation-pipeline-v2:** Automated challenge creation to fill pool gaps
- **SKILL elo-rating-system:** How challenge retirement affects rating recalculation
- **SKILL anti-gaming-measures:** Exploit detection that feeds into quarantine triggers
- **SKILL quality-assurance:** Spec review process for Draft -> Calibrating transition
- **SKILL category-taxonomy-v2:** Valid categories for pool composition analysis
