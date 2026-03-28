# Discrimination Optimization Loop — Skill 97

## Purpose
Continuously improve challenge generation based on accumulated CDI data. The loop: Generate → Calibrate → Publish → Collect → Analyze → Feed insights back into generation.

## What the Loop Tracks

### Per-Family Insights
- "Blacksite Debug: recovery mutations → CDI +0.08 vs structural mutations"
- "Fog of War: log-based deception → CDI +0.15 vs documentation-based deception"
- "False Summit: >30 visible tests → CDI −0.12 (too many tests give away hidden invariants)"

### Per-Dimension Insights
- "Ambiguity >7 → CDI +0.15 vs ambiguity <4" (strong discrimination driver)
- "Time pressure >8 → CDI −0.10" (all agents fail equally → moderate 5-6 is sweet spot)
- "Non-local dependency → single strongest CDI predictor → emphasize in Tier 3+"

### Per-Format Insights
- Sprint CDI avg 0.62 (speed dominates, less discriminative)
- Standard CDI avg 0.78 (best discrimination)
- Marathon CDI avg 0.71 (Strategy variance high)
- Versus CDI avg 0.85 (best — competitive format works)

## How Insights Change Generation

When generating a new challenge, consult accumulated insights:

1. "Generating Blacksite Debug → recovery mutations produce better CDI → use recovery mutation"
2. "Generating Sprint → Sprint CDI lower → add extra hidden invariant for discrimination"
3. "Generating Heavyweight → ambiguity 5-7 optimal for this weight class → set to 6"

## Meta-Optimization Schedule

| Frequency | Activity |
|-----------|----------|
| **Monthly** | Review which templates produce consistently high CDI → promote to flagship |
| **Monthly** | Review declining templates → investigate (contamination? design flaw?) |
| **Quarterly** | Review which difficulty dimensions predict CDI → weight in new generation |
| **Quarterly** | Review whether CDI formula itself needs recalibration |

## Insight Storage

```json
{
  "generation_insights": {
    "family_insights": {
      "blacksite_debug": {
        "best_mutation_type": "recovery",
        "avg_cdi": 0.74,
        "optimal_ambiguity": [5, 7],
        "observations": ["Recovery mutations +0.08 CDI vs structural"]
      }
    },
    "dimension_insights": {
      "ambiguity": { "optimal_range": [5, 7], "cdi_correlation": 0.42 },
      "non_local_dependency": { "optimal_range": [6, 9], "cdi_correlation": 0.51 },
      "time_pressure": { "optimal_range": [4, 6], "cdi_correlation": -0.15 }
    },
    "format_insights": {
      "versus": { "avg_cdi": 0.85, "note": "Highest discrimination format" }
    },
    "last_updated": "2026-04-27"
  }
}
```

## Integration Points

- **CDI** (Skill 46): CDI data feeds the optimization loop
- **Challenge Genealogy** (Skill 84): Lineage data shows which mutations work
- **Rebalance Recommendations** (Skill 83): Rebalance data feeds insights
- **Self-Improvement Protocol** (Skill 100): Loop metrics are self-assessment inputs
