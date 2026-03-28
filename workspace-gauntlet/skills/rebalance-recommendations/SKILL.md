# Rebalance Recommendations — Skill 83

## Purpose
Produce specific, actionable rebalance recommendations based on live performance data. Every recommendation must be structured JSON with a diagnosis, specific action, and template health assessment.

## Required Output Structure

```json
{
  "rebalance_report": {
    "instance_id": "BOUTS-2026-XXXX",
    "template_id": "tmpl-...",
    "attempts": "integer",
    "current_cdi_grade": "S|A|B|C|Reject",
    "previous_cdi_grade": "S|A|B|C|Reject",
    "degradation_cause": "string",

    "metrics": {
      "solve_rate": "float 0-1",
      "average_score": "float 0-100",
      "score_spread": "float (σ)",
      "tier_separation_r": "float 0-1",
      "judge_disagreement_rate": "float 0-1",
      "exploit_rate": "float 0-1"
    },

    "diagnosis": "Specific explanation of WHY the metrics changed",

    "recommendation": {
      "action": "retire_and_replace | rebalance_in_place | quarantine | increase_difficulty | decrease_difficulty | sharpen_rubric | no_action",
      "urgency": "immediate | this_week | next_rotation | low_priority",
      "details": {}
    },

    "template_health": {
      "instances_generated": "integer",
      "instances_with_cdi_A_or_above": "integer",
      "instances_with_cdi_C_or_below": "integer",
      "trend": "improving | stable | declining",
      "template_recommendation": "string"
    }
  }
}
```

## Rebalance Decision Matrix

| Situation | Action | Urgency |
|-----------|--------|---------|
| Solve rate > 90% | Retire instance, generate fresh | Immediate |
| Solve rate < 5% after 100 attempts | Quarantine, investigate (broken or too hard?) | Immediate |
| CDI drops from A to C | Retire and replace, diagnose cause | This week |
| Score spread < 10 | Add adversarial layer or increase non-local dependency | This week |
| Tier separation < 0.5 | Redesign difficulty gradient | This week |
| Judge disagreement > 25% | Sharpen rubric criteria | This week |
| Same-model agents cluster within 5pts | Add process-observable steps, decision points, recovery opportunities | Next rotation |
| Freshness score < 70 | Retire or apply deep mutation | This week |
| Template CDI declining across last 3 instances | Consider new template with different core structure | Next rotation |

## Rules

1. Rebalance reports are **structured JSON, not prose**
2. Every report must include: **diagnosis** (WHY), **recommendation** (WHAT to do), **template health** (instance problem or template problem?)
3. Recommendations must be **specific enough to execute without additional input**
4. ❌ "Make it harder" is NEVER acceptable
5. ✅ "Swap bug type from timezone to connection pool and add a 2nd red herring in the middleware chain" IS acceptable
6. Template health must distinguish between **instance-level problems** (one bad instance) and **template-level problems** (the whole pattern is stale)

## Integration Points

- **CDI** (Skill 46): CDI grade triggers rebalance evaluation
- **Challenge Genealogy** (Skill 84): Lineage data informs template health
- **Variant Pack Generation** (Skill 82): Replacement instances come from new packs
- **Admin Diagnostics** (Skill 87): Rebalance reports feed the health dashboard
