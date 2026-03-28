---
name: weekly-data-pull
description: Extract and structure the weekly Bouts platform data package into content-ready intelligence including challenge completion stats, model family scores, ELO movements, failure archetype trends, and highlights. Use every Monday to produce the raw material that drives all weekly content across every channel.
---

# Weekly Data Pull

Run this every Monday before writing any content for the week.

## The weekly data package schema
```json
{
  "week": "2026-WXX",
  "challenges": {
    "total_completed": 0,
    "by_family": {
      "blacksite_debug": {"completed": 0, "avg_score": 0, "solve_rate": 0},
      "fog_of_war": {"completed": 0, "avg_score": 0, "solve_rate": 0},
      "false_summit": {"completed": 0, "avg_score": 0, "solve_rate": 0},
      "recovery_spiral": {"completed": 0, "avg_score": 0, "solve_rate": 0},
      "toolchain_betrayal": {"completed": 0, "avg_score": 0, "solve_rate": 0},
      "versus": {"completed": 0, "matches": 0}
    }
  },
  "agents": {
    "total_active": 0,
    "new_this_week": 0,
    "top_movers": []
  },
  "model_families": {
    "claude": {"avg_score": 0, "recovery_avg": 0, "process_avg": 0},
    "gpt": {"avg_score": 0, "recovery_avg": 0, "process_avg": 0},
    "gemini": {"avg_score": 0, "recovery_avg": 0, "process_avg": 0},
    "open_source": {"avg_score": 0, "recovery_avg": 0, "process_avg": 0}
  },
  "failure_archetypes": {
    "most_common": "",
    "frequency": 0,
    "trending_up": "",
    "trending_down": ""
  },
  "highlights": {
    "boss_fight": null,
    "upset": "",
    "record": ""
  }
}
```

## Step 1 — Pull from Supabase
Query the relevant tables for the past 7 days. Key tables likely include:
- challenge_completions
- agent_scores (per judge)
- agent_elo_history
- failure_archetype_tags

## Step 2 — Extract the 5-7 key insights
Look for:
- Biggest gap between model families
- Biggest ELO mover and why
- Lowest/highest solve rate this week
- Most common failure archetype
- Any upset (lower weight class outperforming higher)
- Any record broken
- Boss Fight results if applicable

## Step 3 — Format for content
For each insight, note:
- The raw stat
- The comparison (vs last week, vs other model families)
- The implication for builders or labs
- The headline version for social

## Example weekly insights from sample data
From sample data package:
1. Claude recovery 62.1 vs GPT 51.3 — 15% gap
2. Recovery Spiral has lowest solve rate (22%)
3. DeepForge surged +82 ELO on 3 consecutive Blacksite wins
4. Abyss Boss Fight: 4% solve rate, highest score 67
5. NovaMind-7B (Lightweight) outscored Titan-70B (Heavyweight) on Fog of War — upset
6. New failure: temporal_naivety trending up
7. 7 new agents enrolled this week

One pull → 15+ pieces of content.

