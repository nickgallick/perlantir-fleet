# Admin Diagnostics — Skill 87

## Purpose
Produce human-readable diagnostics for platform operators. Dashboard outputs, health reports, flagged items, and next actions.

## Report Types

### Daily Summary (1 paragraph)
Quick health check — everything OK or flagged items need attention.

### Weekly Report (Full Dashboard)

```
CHALLENGE HEALTH REPORT — {DATE}
=====================================

ACTIVE CHALLENGES: {N}
  CDI S-Tier: {N} ({%})
  CDI A-Tier: {N} ({%})
  CDI B-Tier: {N} ({%})
  CDI C-Tier: {N} ({%}) ⚠️ flagged for review
  CDI Reject: {N} ({%}) 🚨 quarantined

FLAGGED FOR ACTION:
  {INSTANCE_ID} ({Family}) — CDI dropped {from}→{to}
    Cause: {specific diagnosis}
    Action: {specific recommendation}

TEMPLATE HEALTH:
  {template_id}: {N} instances, avg CDI {X}, {TREND}

FRESHNESS:
  Challenges >{N} weeks old: {count} (schedule retirement)
  Challenges >{N} attempts: {count} (approaching threshold)

JUDGE HEALTH:
  Calibration deviation: {avg points}
  Disagreement rate: {%}
  Appeals invocation rate: {%}

CONVERGENCE WATCH:
  Same-model clusters detected: {count}
  Worst cluster: {details}

NEXT ACTIONS:
  1. {Specific action with instance ID}
  2. {Specific action}
  3. {Specific action}
```

### On-Demand Report
Triggered when any challenge hits quarantine or CDI drops below B. Includes full diagnosis and recommended immediate actions.

### Post-Season Report
Comprehensive season review:
- Template evolution analysis
- Best/worst performing challenges
- CDI trends across the season
- Failure archetype trends
- Model family performance shifts
- Recommendations for next season

## Report Content Rules

1. **Always include instance IDs** — operators need to know exactly which challenge
2. **Always include specific diagnosis** — not just "CDI dropped" but WHY
3. **Always include specific actions** — not "investigate" but "retire BOUTS-2026-0042 and generate replacement from tmpl-blacksite-debug-v3 with semantic + dependency mutations"
4. **Trend indicators** on everything — STABLE / IMPROVING / DECLINING
5. **Priority ordering** — most urgent action first

## Integration Points

- **CDI** (Skill 46): CDI grades drive all flagging
- **Rebalance Recommendations** (Skill 83): Detailed recommendations feed the report
- **Challenge Genealogy** (Skill 84): Template trends from lineage data
- **Judge Calibration** (Skill 66): Judge health metrics in the report
- **Production Rules** (Skill 76): Operational state included
