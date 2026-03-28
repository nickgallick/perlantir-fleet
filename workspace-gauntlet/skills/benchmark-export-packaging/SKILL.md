# Benchmark Export Packaging — Skill 88

## Purpose
Package challenge data for the Bouts Benchmark API and data licensing. AI labs purchase access — the export must be clean, structured, and valuable.

## Per-Challenge Export Structure

```json
{
  "challenge_meta": {
    "family": "string",
    "format": "string",
    "weight_class": "string",
    "difficulty_profile": {},
    "cdi_grade": "string",
    "total_attempts": "integer"
  },
  "aggregate_results": {
    "score_distribution": {
      "mean": "float",
      "median": "float",
      "std_dev": "float",
      "p10": "float",
      "p90": "float"
    },
    "component_averages": {
      "objective": "float",
      "process": "float",
      "strategy": "float",
      "recovery": "float",
      "integrity": "float (avg adjustment)"
    },
    "failure_archetype_distribution": {
      "archetype_name": "float (0-1 proportion)"
    },
    "by_model_family": {
      "family_name": { "mean": "float", "n": "integer" }
    }
  }
}
```

## What's NEVER in the Export

- ❌ Individual agent submissions (code, deliverables)
- ❌ Exact challenge instances (briefings, codebases, test suites)
- ❌ Individual agent identities or ELO ratings
- ❌ Judge prompts or exact scoring formulas
- ❌ Hidden test logic
- ❌ Reference solutions

## What IS in the Export

- ✅ Aggregate statistics per challenge family/format/weight class
- ✅ Failure archetype distributions
- ✅ Score distributions by model family
- ✅ Component score breakdowns
- ✅ CDI trends over time
- ✅ Headline insights: "AI agents in 2026 pass 72% of static tests but only 31% of adversarial tests"

## Export Tiers

| Tier | Audience | Content Depth |
|------|----------|---------------|
| **Public** | Community, press | Headline stats, quarterly Bouts Index |
| **Standard** | Registered labs | Per-family breakdowns, archetype distributions |
| **Premium** | Paying enterprise/labs | Model family comparisons, trend data, private lane results |

## The Bouts AI Agent Index (Public Report)

Quarterly publication:
- Overall agent capability trends
- Hardest challenge families
- Most common failure archetypes
- Model family performance comparison (anonymized)
- CDI trends (are challenges getting better at discriminating?)
- Headline insights for press and social media

## Integration Points

- **CDI** (Skill 46): CDI grades included in all exports
- **Failure Archetypes** (Skill 48): Archetype distributions are core export data
- **Defensibility Reporting** (Skill 57): Export methodology documented for trust
- **Challenge Economy** (Skill 58): Licensing value drives export packaging decisions
