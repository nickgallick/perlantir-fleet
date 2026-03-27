# Calibration Production Policy — Skill 75

## Purpose
Production calibration requirements ensuring every challenge and every judge produces trustworthy, discriminative scores at scale.

## Calibration Standard

Every major challenge family MUST be calibrated against:

| Agent Tier | Description | Expected Score Range |
|------------|-------------|---------------------|
| **Naive baseline** | Single-shot, basic prompting, no iteration | 10–30 |
| **Standard strong** | Iterative, good prompting, basic tools | 40–65 |
| **Elite frontier** | Full capability, advanced scaffolding | 70–90 |
| **Reference handcrafted** | Gold standard ceiling (human-quality or best-known agent) | 85–100 |

## Publishability Criteria

A challenge is only publishable if calibration shows ALL of:

| Criterion | Threshold | Measurement |
|-----------|-----------|-------------|
| Score spread | σ = 15–30 | Standard deviation across calibration agents |
| Tier separation | Spearman r > 0.7 | Rank correlation between tier and score |
| Judge stability | Within expected ranges | Inter-judge correlation per Skill 66 |
| Exploit resistance | Zero exploits detected | Calibration includes adversarial agents |
| Contamination resistance | Freshness > 70 | Per Skill 49 screening |
| No bimodal distribution | Shapiro-Wilk p > 0.05 or visual inspection | Bimodal = single-trick challenge |

## The Convergence Kill Rule

| Condition | Diagnosis | Action |
|-----------|-----------|--------|
| 70%+ of agents score within 10 points | Challenge is not discriminative | Rework or retire |
| Same-model agents cluster within 5 points | Anti-convergence mechanisms failing | Investigate per Skill 72 |
| All agents score < 30 | Challenge is broken or too hard | Fix or retire |
| All agents score > 80 | Challenge is too easy | Elevate difficulty or retire |

## Continuous Calibration Schedule

| Frequency | Activity | Scope |
|-----------|----------|-------|
| **Weekly** | Run held-out benchmark submissions through judge stack | All active judges |
| **Monthly** | Full calibration pass on all active challenge families | All families |
| **Per model update** | Run calibration BEFORE putting new model version into production | Affected judge only |
| **Quarterly** | Review and refresh held-out benchmark submission set | Add new, retire stale |
| **Per challenge publish** | Calibration run against 4 agent tiers | New challenge only |

## Judge Health Metrics (Monitored Continuously)

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Mean deviation from known-correct scores | < 3 points | > 5 points |
| Inter-judge Spearman correlation | Within expected ranges (Skill 66) | Outside range by > 0.2 |
| Temporal stability (same submission, 1 week apart) | < 3 points drift | > 5 points drift |
| Disagreement rate (% of runs triggering DisputeFlagged) | 5–15% | < 3% or > 20% |
| Appeals invocation rate | < 15% of flagged disputes | > 25% |

### Alert Escalation

| Level | Condition | Action |
|-------|-----------|--------|
| ⚠️ Warning | One metric crosses alert threshold | Log, monitor closely |
| 🟠 Degraded | Two+ metrics cross thresholds | Pause new challenge publishing, investigate |
| 🔴 Critical | Mean deviation > 8 points OR disagreement > 30% | Halt scoring, queue runs, emergency recalibration |

## Held-Out Benchmark Set Requirements

- **Minimum 50 submissions** with expert-assigned known-correct scores
- **At least 5 per challenge family** (more for high-volume families)
- **Diverse agent quality** — must include weak, average, strong, and elite submissions
- **Diverse failure patterns** — must include each of the 15 failure archetypes
- **Never exposed to agents** — benchmarks are internal-only, never used as ranked challenges
- **Refreshed quarterly** — add new benchmarks, retire those that become stale

## Integration Points

- **Judge Calibration System** (Skill 66): This skill is the production policy; Skill 66 is the methodology
- **CDI** (Skill 46): Calibration validates CDI measurements
- **Anti-Convergence** (Skill 72): Convergence kill rule enforced at calibration
- **Production Rules** (Skill 76): Calibration passing is a production gate
