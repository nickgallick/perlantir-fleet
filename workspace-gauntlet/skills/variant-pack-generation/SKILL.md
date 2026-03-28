# Variant Pack Generation — Skill 82

## Purpose
Generate multiple challenge instances simultaneously with controlled diversity. Enables weekly rotation, A/B testing, and contamination resistance.

## Variant Pack Structure

```json
{
  "pack": {
    "template_id": "tmpl-{family}-v{N}",
    "family": "string",
    "pack_size": 3-8,
    "generated_at": "ISO-8601",
    "cross_instance_similarity": "float (must be <0.70 for any pair)",
    "instances": [
      {
        "instance_id": "BOUTS-2026-XXXX",
        "seed": "8-char hex",
        "mutations_applied": ["mutation_type"],
        "framework": "string",
        "database": "string",
        "domain": "string",
        "bug_types": ["string"],
        "difficulty_profile": {},
        "similarity_to_others": [0.0-1.0]
      }
    ]
  }
}
```

## Pack Generation Rules

| Rule | Requirement |
|------|-------------|
| Mutation diversity | Each instance differs on at least 3 mutation types |
| Cross-instance similarity | < 0.70 for any pair |
| Difficulty consistency | Profiles within ±1 on each dimension across the pack |
| Shared attributes | Same family, weight class, and format |
| Independent calibration | Each instance gets its own calibration package |
| Similarity matrix | Included in pack for publisher verification |

## When to Generate Packs

| Context | Pack Size | Rationale |
|---------|-----------|-----------|
| Weekly rotation | 4-pack | 1 per week, retire after use |
| Flagship families | 8-pack | Long-term freshness for Blacksite/Fog of War/False Summit |
| Boss Fights | 1 (single) | Monthly events are unique |
| Versus (asymmetric) | 2-pack | One for each side |
| Seasonal events | 4-6 pack | Cover the season with rotation |
| A/B testing | 2-pack | Compare CDI between variants |

## Quality Control

| Check | Threshold | Action if Failed |
|-------|-----------|-----------------|
| Any pair similarity > 0.70 | Hard fail | Regenerate the offending instance |
| Difficulty profile variance > 2 on any dimension | Soft fail | Constrain mutations, regenerate |
| Any instance fails calibration independently | Hard fail | Regenerate that instance only |
| Pack average CDI < B-Tier | Soft fail | Review template, consider redesign |

## Pack Diversity Dimensions

Each instance in a pack should vary across:

| Dimension | Example Variations |
|-----------|--------------------|
| Framework | Express → Fastify → Hono → Koa |
| Database | PostgreSQL → MySQL → SQLite → MongoDB |
| Domain | Payment processing → Inventory → Notifications → User management |
| Bug types | Race condition → Deadlock → Connection pool → Memory leak |
| Red herring style | Misleading TODO → Suspicious import → Dead code → Wrong error message |
| Log content | Different timestamps, different error patterns, different noise level |

## Integration Points

- **Mutation Layer** (Skill 52): Pack generation applies mutations per instance
- **Calibration Packaging** (Skill 81): Each instance gets its own calibration package
- **Contamination Doctrine** (Skill 49): Diversity is a contamination defense
- **Challenge Economy** (Skill 58): Packs feed weekly rotation and seasonal events
