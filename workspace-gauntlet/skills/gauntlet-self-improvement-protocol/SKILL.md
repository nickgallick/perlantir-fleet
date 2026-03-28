# Gauntlet Self-Improvement Protocol — Skill 100

## Purpose
How Gauntlet evaluates and improves its own challenge generation over time. The meta-question: Is Gauntlet getting BETTER — not just different?

## Self-Evaluation Metrics (Tracked Monthly)

### Quality Metrics
| Metric | Good Trend | Target |
|--------|-----------|--------|
| Average CDI of new challenges | ↑ Increasing | > 0.75 |
| Rejection rate at calibration | ↓ Decreasing | < 15% |
| Average engagement score | ↑ Increasing | > 3.5 |
| Red-team findings per challenge | ↓ Decreasing | < 0.5 |

### Diversity Metrics
| Metric | Good Trend | Target |
|--------|-----------|--------|
| Category distribution balance | Even | No category > 25% or < 5% |
| Difficulty profile diversity | Varied | All 8 dimensions used across range |
| Failure archetype coverage | Complete | All 15+ archetypes exposed monthly |
| Family freshness | Current | No family > 4 weeks without fresh instance |

### Efficiency Metrics
| Metric | Good Trend | Target |
|--------|-----------|--------|
| Calibration pass rate | ↑ Increasing | > 85% |
| Time from generation to publication | ↓ Decreasing | < 48 hours |
| Variant similarity scores | Low | < 0.70 within packs |

## Monthly Self-Improvement Report Format

```
GAUNTLET SELF-ASSESSMENT — {Month Year}
========================================
Challenges generated: N
Challenges published: N (X% pass rate)
Average CDI: X.XX
Average engagement: X.X/5.0
Red-team findings: X.X/challenge

STRONGEST AREA: {family/dimension producing best results}
WEAKEST AREA: {family/dimension needing attention}
ACTION: {specific improvement action}

NEW FAILURE ARCHETYPES DISCOVERED: {count and names}
ACTION: {challenges designed to target them}

BENCHMARK GAP ANALYSIS: {competitive developments and Bouts response}

TEMPLATE HEALTH: {templates promoted/retired/refreshed}

NEXT MONTH PRIORITIES:
1. {specific action}
2. {specific action}
3. {specific action}
```

## Improvement Actions Gauntlet CAN Take

- Generate new narrative templates when existing ones get repetitive
- Adjust difficulty dimension targeting based on CDI correlation data
- Create new challenge families for newly discovered failure archetypes
- Retire templates with declining CDI trends
- Experiment with new mutation types
- Refine red-team checklist based on exploit discoveries
- Update calibration persona configurations based on observed agent behaviors

## Actions Requiring Human/ClawExpert

- Modify SOUL.md or training files
- Change judge system configuration
- Alter CDI formula weights
- Override quarantine decisions
- Publish challenges that failed calibration
- Change the 5-judge architecture

## Integration Points

- **All skills**: This is the meta-skill that evaluates the entire system
- **CDI** (Skill 46): CDI trends are the primary quality signal
- **Discrimination Loop** (Skill 97): Optimization data feeds self-assessment
- **Compounding Failure Library** (Skill 96): New archetype discovery is a quality metric
- **Benchmark Gap Analysis** (Skill 99): Competitive position is assessed monthly
