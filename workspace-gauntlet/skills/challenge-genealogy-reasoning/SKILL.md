# Challenge Genealogy Reasoning — Skill 84

## Purpose
Reason about challenge lineage to improve future generation. Track which template/mutation combinations produce the best CDI and use that data to make better decisions.

## Genealogy Data Structure

```json
{
  "template": "tmpl-{family}-v{N}",
  "lineage": [
    {
      "instance_id": "BOUTS-2026-XXXX",
      "generation": 1,
      "parent": null,
      "mutations": ["none — original"],
      "cdi": 0.82,
      "attempts": 145,
      "status": "retired",
      "framework": "express",
      "domain": "payment_processing"
    }
  ],
  "analysis": "Text analysis of CDI trends, mutation effectiveness, and recommendations"
}
```

## Genealogy Queries

### "Why are recent instances scoring lower?"
- Check: what mutations have been applied? Common factor?
- Check: is a specific framework/domain becoming recognizable?
- Example: "Last 4 instances all used Express. Agents have pattern-matched Express debugging. Switch to Fastify/Hono."

### "Which canonical engine produces the best CDI?"
- Compare average CDI across all engines, all instances
- Identify: which engines naturally create discrimination vs which need more work

### "Should this template be retired or refreshed?"
- CDI trend across last 10 instances — declining = contamination accumulating
- Mutation space remaining — exhausted meaningful dimensions? → retire
- Structural refresh possible? Change interconnection topology, not just surface

### "What makes the best mutations?"
- Track: which mutation types correlate with high CDI
- Semantic mutations (changing bug type) typically produce more CDI than structural mutations (changing file layout)
- The bug matters more than the scaffolding

### "Is this a template problem or an instance problem?"
- If one instance has low CDI but siblings are fine → instance problem (retire it, generate new)
- If last 3+ instances all have declining CDI → template problem (need new template)
- If ALL templates in a family are declining → family-level contamination (need new engine variant)

## Genealogy-Informed Generation

When generating a new instance, check:
1. What mutations produced the best CDI in this template's history?
2. What mutations produced the worst CDI?
3. What frameworks/domains have been overused?
4. What is the maximum mutation depth before template refresh?

Use this data to select mutations that are statistically more likely to produce high CDI.

## Template Lifecycle Stages

```
New Template → Instance Gen 1 (high CDI expected)
  → Instance Gen 2-5 (mutations, CDI monitored)
  → Instance Gen 6-10 (CDI typically starts declining)
  → Template Refresh (structural change, resets mutation depth)
  → Instance Gen 1-5 of refreshed template
  → ...
  → Template Retirement (mutation space exhausted, pattern too recognizable)
  → New Template for same engine family
```

Maximum mutation depth before refresh: **10 generations**

## Integration Points

- **Mutation Layer** (Skill 52): Genealogy informs mutation selection
- **Rebalance Recommendations** (Skill 83): Template health assessment uses genealogy
- **Contamination Doctrine** (Skill 49): Genealogy tracks contamination accumulation
- **Admin Diagnostics** (Skill 87): Template evolution trends shown in dashboards
