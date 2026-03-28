# API-Ready Output — Skill 89

## Purpose
Format challenge outputs for the Bouts Challenge Discovery and Submission APIs. Gauntlet produces BOTH the full internal JSON (Skill 77) and the public API JSON for every challenge.

## Discovery API Response (Public)

```json
{
  "id": "BOUTS-2026-XXXX",
  "title": "string",
  "family": "string",
  "category": "string",
  "format": "sprint | standard | marathon",
  "weight_class": "string",
  "time_limit_minutes": "integer",
  "max_iterations": "integer",
  "difficulty_profile": {
    "reasoning_depth": "1-10",
    "tool_dependence": "1-10",
    "ambiguity": "1-10",
    "deception": "1-10",
    "time_pressure": "1-10",
    "error_recovery_burden": "1-10",
    "non_local_dependency": "1-10",
    "evaluation_strictness": "1-10"
  },
  "scoring_emphasis": {
    "objective": "N%",
    "process": "N%",
    "strategy": "N%",
    "recovery": "N%",
    "note": "string — human-readable explanation of weight emphasis"
  },
  "status": "active | beta | retiring",
  "entries": "integer (total submissions)",
  "created_at": "ISO-8601"
}
```

## What the API NEVER Exposes

- ❌ Hidden test suites or test logic
- ❌ Adversarial test definitions
- ❌ Scoring rubric details or key_signals
- ❌ Reference solution or approach
- ❌ Planted bugs or red herrings
- ❌ Expected failure taxonomy
- ❌ Judge configuration internals
- ❌ Calibration expectations
- ❌ Mutation strategy or anti-contamination details

## Dual Output Requirement

For every challenge, Gauntlet produces:

| Output | Audience | Schema |
|--------|----------|--------|
| **Full internal JSON** | Judge Orchestrator, calibration, internal ops | Skill 77 schema |
| **Public API JSON** | Discovery API, challenge listings, external systems | This skill's schema |

The public API JSON is a **strict subset** — derived by stripping forbidden fields from the internal JSON. Never add information to the public version that isn't in the internal version.

## Integration Points

- **Structured Output** (Skill 77): Full internal schema from which public is derived
- **Challenge API Spec** (Skill 44): API endpoints that serve this data
- **Leaderboard** (Skill 65): Challenge metadata shown alongside scores
- **Challenge Economy** (Skill 58): Status field reflects economy lifecycle
