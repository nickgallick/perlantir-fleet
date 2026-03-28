# Per-Challenge Failure Taxonomy — Skill 80

## Purpose
Produce a specific failure map for every challenge — not just the global 15 archetypes. Predict exactly how each tier of agent will fail, what they'll miss, and what score range they'll land in.

## Required Output Structure

```json
{
  "failure_taxonomy": {
    "tier_1_weak_agents": {
      "primary_archetype": "archetype_name",
      "secondary_archetypes": ["archetype_name"],
      "predicted_behavior": "Specific description of what the agent will do",
      "predicted_score_range": [5, 20],
      "what_they_will_miss": "Specific elements they won't find or address"
    },
    "tier_2_standard_agents": {
      "primary_archetype": "archetype_name",
      "secondary_archetypes": ["archetype_name"],
      "predicted_behavior": "...",
      "predicted_score_range": [30, 50],
      "what_they_will_miss": "..."
    },
    "tier_3_strong_agents": {
      "primary_archetype": "archetype_name",
      "secondary_archetypes": ["archetype_name"],
      "predicted_behavior": "...",
      "predicted_score_range": [55, 75],
      "what_they_will_miss": "..."
    },
    "tier_4_elite_agents": {
      "primary_archetype": "archetype_name",
      "secondary_archetypes": [],
      "predicted_behavior": "...",
      "predicted_score_range": [75, 92],
      "what_they_will_miss": "..."
    }
  }
}
```

## Why This Matters

### For Calibration
- If actual results don't match the taxonomy → challenge design has a problem
- If weak agents score better than predicted → challenge is too easy or has a shortcut
- If elite agents score worse than predicted → challenge might be unfair or broken
- The taxonomy IS the expected result for the calibration run

### For Post-Match Breakdowns
- Powers archetype detection with challenge-specific context
- Generic: "Your agent exhibited Premature Convergence"
- Specific: "Your agent exhibited Premature Convergence — it spent only 45 seconds reading before coding, which meant it never discovered the session leak in auth/session.ts that's only visible through code review"

### For CDI Validation
- If adjacent tier score ranges overlap by more than 10 points → challenge isn't discriminative enough → redesign
- If a tier has no predicted archetype → the challenge doesn't test that skill level meaningfully

## Rules

1. Every challenge must have **all 4 tiers populated**
2. Each tier must predict: primary archetype, score range, specific behavior, what they'll miss
3. Score ranges must **not overlap more than 10 points** between adjacent tiers
4. Archetypes must reference the **standard 15** (Skill 48)
5. Predicted behaviors must be **specific to this challenge** — not generic descriptions
6. "What they'll miss" must reference **specific challenge elements** (bug IDs, file names, hidden invariants)

## Validation Check

After calibration, compare predicted vs actual:

| Metric | Pass | Investigate | Fail |
|--------|------|-------------|------|
| Tier 1 actual score within predicted range | ✅ | Actual ±10 of range | Actual ±20 of range |
| Tier 2 actual score within predicted range | ✅ | Actual ±10 of range | Actual ±20 of range |
| Tier 3 actual score within predicted range | ✅ | Actual ±10 of range | Actual ±20 of range |
| Tier 4 actual score within predicted range | ✅ | Actual ±10 of range | Actual ±20 of range |
| Primary archetype matches actual | ✅ | Secondary matches | Neither matches |
| Score ranges don't overlap >10 pts | ✅ | Overlap 10-15 | Overlap >15 |

## Integration Points

- **Structured Output** (Skill 77): Taxonomy is embedded in `expected_failure_taxonomy`
- **Failure Archetypes** (Skill 48): Per-challenge taxonomy maps to global archetypes
- **Post-Match Breakdown** (Skill 86): Drives specific, actionable diagnostics
- **Calibration Packaging** (Skill 81): Taxonomy is part of the calibration package
- **Rebalance Recommendations** (Skill 83): Taxonomy drift signals rebalance need
