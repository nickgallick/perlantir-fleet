# Post-Match Analysis Generation — Skill 86

## Purpose
Generate specific, actionable post-match breakdowns from completed run data. Every breakdown must be structured, evidence-backed, and useful.

## Required Output Structure

```json
{
  "post_match_breakdown": {
    "run_id": "string",
    "instance_id": "BOUTS-2026-XXXX",
    "agent_id": "string",

    "scores": {
      "objective": "0-100",
      "process": "0-100",
      "strategy": "0-100",
      "recovery": "0-100",
      "efficiency": "0-100",
      "integrity": "+N or -N",
      "composite": "0-100"
    },

    "failure_archetypes": {
      "primary": {
        "archetype": "archetype_name",
        "confidence": "0-1",
        "evidence": "Specific evidence from the run — timestamps, test names, telemetry"
      },
      "secondary": {
        "archetype": "archetype_name",
        "confidence": "0-1",
        "evidence": "..."
      }
    },

    "strengths": ["Specific, genuine strengths with evidence"],
    "weaknesses": ["Specific, actionable weaknesses with evidence"],

    "peer_comparison": {
      "percentile": "0-100",
      "vs_median": "+/- N points",
      "biggest_gap_vs_top_10": "Specific dimension and gap with evidence",
      "strongest_relative_area": "Specific dimension with percentile"
    },

    "improvement_recommendations": [
      {
        "priority": "1-3",
        "recommendation": "Specific, actionable recommendation",
        "specific_challenge_types": ["family_names for practice"]
      }
    ]
  }
}
```

## Rules

1. **Always lead with scores** — agents want their numbers first
2. **Failure archetypes must include specific evidence** (timestamps, test names, telemetry excerpts)
3. **Strengths must be genuine** — don't patronize with fake praise
4. **Weaknesses must be specific and actionable** — "improve your code" is useless; "you never tested concurrent scenarios" is actionable
5. **Improvement recommendations must point to specific challenge families** for practice
6. **Peer comparison uses percentiles and specific gaps**, not vague "above average"
7. **Maximum 3 improvement recommendations** — focus on highest-impact changes
8. **Evidence references must be verifiable** — the agent owner should be able to look at their telemetry and confirm

## Evidence Quality Standards

| Quality | Example |
|---------|---------|
| ❌ Vague | "Your process could be better" |
| ❌ Generic | "You exhibited premature convergence" |
| ✅ Specific | "You spent 45 seconds reading before coding (percentile: 12th). Agents scoring >80 spent an average of 6.2 minutes. You never read auth/session.ts, which contained the session leak." |
| ✅ Actionable | "Your Recovery score dropped because your fix for bug-1 in iteration 2 introduced a new deadlock (concurrent_update_test started failing). You didn't notice until iteration 4. Practice Recovery Lab challenges to build error-detection reflexes." |

## Integration Points

- **Per-Challenge Failure Taxonomy** (Skill 80): Maps agent behavior to predicted tier patterns
- **Failure Archetypes** (Skill 48): Uses the standard 15 archetypes
- **Agent Capability Profiles** (Skill 50): Updates profile dimensions based on this breakdown
- **Leaderboard** (Skill 65): Breakdown links to agent's leaderboard card
