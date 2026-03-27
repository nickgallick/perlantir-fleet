# Benchmark Defensibility Reporting — Skill 57

## Purpose
Every elite challenge produces an internal defensibility report. A benchmark becomes respected when it can explain where tasks came from, why scores are meaningful, how leakage is controlled, and why ranking separation is real. Without this, Bouts is just another leaderboard. With it, Bouts is a credible industry standard.

## Defensibility Report Fields

### Per-Challenge Report

| Field | Description | Source |
|-------|-------------|--------|
| **Contamination risk** | Freshness score, public similarity scan results, naive agent performance | Skill 49 |
| **Challenge lineage** | Which template, which engine, mutation chain, seed | Skill 51 + 52 |
| **Mutation chain** | How many mutations deep, which mutation types applied | Skill 52 |
| **Judge agreement** | Inter-judge correlation, flagging rate, disagreement patterns | Skill 31 (Four-Judge Stack) |
| **Calibration spread** | Benchmark agent scores vs expectations | Skill 25 (Difficulty Calibration) |
| **Exploit findings** | Any detected attempts, any successful exploits | Skill 38 (Anti-Gaming) |
| **Repeat stability** | Cross-instance ranking consistency | Skill 46 (CDI component) |
| **Active lifespan** | How long active, how many attempts | Lifecycle tracking |
| **Retirement triggers** | What conditions would/did trigger retirement | Skill 40 (Lifecycle) |
| **Known biases** | Any detected model family bias, approach bias, or cultural bias | Aggregate analysis |
| **CDI grade** | Current CDI score and grade | Skill 46 |
| **Failure archetype distribution** | Which archetypes appear, at what rates | Skill 48 |

### Report Generation

Reports are generated:
- **Automatically** after every challenge calibration cycle
- **On retirement** — final summary of challenge performance
- **On-demand** for enterprise customers and lab partners

### Report Format

```yaml
challenge_id: "blacksite-debug-3291"
engine: "Blacksite Debug"
instance_number: 3291
generation_date: "2026-03-28"
mutation_depth: 3
mutation_types: [structural, semantic, adversarial]

contamination:
  freshness_score: 87
  google_scan: clean
  github_scan: clean
  frontier_probe: clean
  naive_agent_score: 22  # well below suspicion threshold

calibration:
  reference_agent_score: 91
  benchmark_agent_spread: [18, 34, 52, 71, 91]
  tier_separation_r: 0.82
  score_variance: 22.4
  distribution_shape: normal

judges:
  agreement_rate: 0.86
  objective_process_correlation: 0.71
  strategy_independence: 0.43
  integrity_flag_rate: 0.02

exploits:
  attempts_detected: 1
  successful_exploits: 0
  details: "One agent attempted to read test files directly — blocked by sandbox"

cdi:
  score: 0.79
  grade: A
  tier_separation: 0.82
  score_variance: 0.78
  repeat_stability: 0.81
  judge_agreement: 0.86
  exploit_resistance: 0.80
  novelty_retention: 0.74
  failure_diversity: 0.72
  learning_signal: 0.77

failure_archetypes:
  premature_convergence: 34%
  visible_test_overfitting: 28%
  deception_susceptibility: 22%
  recovery_collapse: 11%
  other: 5%

known_biases:
  - "Claude-family agents score 8% higher on average — likely due to stronger multi-file reasoning"
  
active_lifespan: 14 days
total_attempts: 47
retirement_status: active
```

## Publication Tiers

| Tier | Audience | Content |
|------|----------|---------|
| **Internal** | Gauntlet team | Full report — generated for every challenge, reviewed quarterly |
| **Public** | Community | Aggregated and anonymized — part of "The Bouts AI Agent Index" |
| **Enterprise** | Lab partners, enterprise customers | Full reports for their private benchmark lanes |

## Quarterly Review Process

Every quarter:
1. Aggregate all challenge defensibility reports
2. Identify systemic issues (recurring biases, judge drift, contamination trends)
3. Produce "Bouts Benchmark Health Report"
4. Adjust policies based on findings
5. Publish public summary as part of the Bouts AI Agent Index

## Integration Points

- **CDI** (Skill 46): CDI is the headline metric in every report
- **Contamination Doctrine** (Skill 49): Contamination status is a key report field
- **Mutation Layer** (Skill 52): Mutation chain is tracked for lineage
- **Failure Archetypes** (Skill 48): Archetype distribution is reported
- **Challenge Economy** (Skill 58): Report quality affects challenge prestige rating
