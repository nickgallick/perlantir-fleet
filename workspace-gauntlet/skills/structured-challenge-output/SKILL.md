# Structured Challenge Output — Skill 77

## Purpose
The exact JSON schema every challenge must conform to. When Gauntlet generates a challenge, the output is THIS schema — not prose, not a description, the actual JSON.

## Required Schema

```json
{
  "challenge": {
    "id": "BOUTS-2026-XXXX",
    "template_id": "tmpl-{family}-v{N}",
    "instance_seed": "8-char hex",
    "title": "string — evocative name",
    "family": "enum: blacksite_debug | fog_of_war | false_summit | constraint_maze | forensic_cascade | toolchain_disaster | recovery_lab | versus_arena | humanity_gap | deceptive_optimization",
    "category": "enum from 10 categories (Skill 35)",
    "format": "sprint | standard | marathon",
    "weight_class": "calibration | lightweight | middleweight | heavyweight | frontier",
    "time_limit_minutes": "integer",
    "max_iterations": "integer (1-8)",

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

    "briefing": "Full markdown briefing text — what the agent sees",

    "provided_assets": [
      {
        "path": "string",
        "type": "file | directory",
        "description": "string",
        "file_count": "integer (directories only)"
      }
    ],

    "deliverables": [
      {
        "id": "string",
        "label": "string",
        "format": "markdown | git-diff | test-files | code-file",
        "required": "boolean",
        "scoring_weight": "integer (0-100)"
      }
    ],

    "judge_config": {
      "format_weights": {
        "objective": "30-55",
        "process": "5-25",
        "strategy": "5-30",
        "recovery": "0-35",
        "efficiency": "0-10"
      },
      "objective_config": {
        "static_test_suite": "path",
        "adversarial_test_suite": "path",
        "hidden_invariants": "path",
        "performance_benchmarks": "path | null",
        "security_scan": "boolean"
      },
      "process_rubric": { "key_signals": ["string"] },
      "strategy_rubric": { "key_signals": ["string"] },
      "recovery_rubric": { "key_signals": ["string"] },
      "integrity_checks": {
        "positive_triggers": ["string"],
        "negative_triggers": ["string"]
      }
    },

    "hidden_elements": {
      "planted_bugs": [
        {
          "id": "string",
          "severity": "critical | high | medium | low",
          "location": "file:line",
          "description": "string",
          "visible_symptom": "string",
          "interconnected_with": ["bug-id"]
        }
      ],
      "red_herrings": [
        {
          "location": "string",
          "description": "string",
          "why_its_distracting": "string"
        }
      ],
      "reference_solution_approach": "string",
      "reference_solution_score": "integer (must be >85)"
    },

    "calibration_expectations": {
      "naive_agent": { "expected_score": "range string", "expected_behavior": "string" },
      "standard_agent": { "expected_score": "range string", "expected_behavior": "string" },
      "elite_agent": { "expected_score": "range string", "expected_behavior": "string" },
      "reference_agent": { "expected_score": "range string", "expected_behavior": "string" }
    },

    "expected_failure_taxonomy": {
      "weak_agents": ["archetype names"],
      "standard_agents": ["archetype names"],
      "strong_agents": ["archetype names"],
      "elite_agents": ["archetype names"]
    },

    "mutation_strategy": {
      "mutable_dimensions": ["string"],
      "fixed_dimensions": ["string"],
      "variant_notes": "string"
    },

    "anti_contamination": {
      "fingerprint": "sha256:...",
      "public_similarity_check": "passed | failed | pending",
      "freshness_score": "integer 0-100 (must be >70)",
      "generated_at": "ISO-8601"
    },

    "lifecycle": {
      "status": "draft | calibrating | active | quarantined | retired",
      "max_attempts_before_retirement": "integer",
      "max_age_weeks": "integer",
      "quarantine_triggers": ["string"]
    }
  }
}
```

## Validation Rules

| Rule | Requirement |
|------|-------------|
| All required fields populated | No nulls on required fields |
| difficulty_profile values | Integers 1-10 |
| format_weights sum | Must equal 95 (5% implicit for integrity) |
| calibration_expectations | All four tiers present |
| expected_failure_taxonomy | References only standard 15 archetypes |
| mutation_strategy | Must specify both mutable and fixed dimensions |
| freshness_score | Must be >70 to proceed to calibration |
| reference_solution_score | Must be >85 or challenge is rejected |
| deliverables scoring_weight | Must sum to 100 |

## Integration Points

- **Calibration Packaging** (Skill 81): JSON becomes the core of the calibration package
- **Variant Pack Generation** (Skill 82): Each variant outputs this same schema
- **API-Ready Output** (Skill 89): Public API is a subset of this schema
- **Deterministic Packaging** (Skill 90): Audit trail references this schema
