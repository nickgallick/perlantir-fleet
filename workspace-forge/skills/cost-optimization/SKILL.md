---
name: cost-optimization
description: Building profitably — Vercel, Supabase, and Anthropic cost optimization, model tiering, cost tracking per feature, and budget alerting.
---

# Cost Optimization

## Review Checklist

- [ ] AI calls use cheapest viable model (Haiku for classification, Sonnet for most tasks, Opus only for complex judging)
- [ ] System prompts identical across calls (enables Anthropic cache — 90% savings)
- [ ] Database queries SELECT only needed columns (not `select('*')`)
- [ ] No polling when webhooks/Realtime could work
- [ ] Cost tracked per feature in `api_costs` table
- [ ] Batch API used for non-urgent AI work (50% cheaper)

---

## Cost Breakdown by Service

### Vercel
| Resource | Free | Pro ($20/mo) | Watch For |
|----------|------|-------------|-----------|
| Function invocations | 100K | 1M (then $0.60/M) | High-traffic API routes |
| Bandwidth | 100GB | 1TB (then $0.15/GB) | Large transcript downloads |
| Edge Middleware | Runs on EVERY request | Same | Keep middleware lightweight |
| Build time | 100h | 400h | Turborepo caching saves ~70% |

**Optimizations:**
- `runtime = 'edge'` for simple routes (cheaper than Node.js runtime)
- `next/image` optimization reduces bandwidth significantly
- Incremental builds with Turborepo — only rebuild changed packages

### Supabase
| Resource | Free | Pro ($25/mo) | Watch For |
|----------|------|-------------|-----------|
| Database | 500MB | 8GB (then $0.125/GB) | Transcript storage |
| Egress | 2GB | 50GB (then $0.09/GB) | Large query results |
| Edge Functions | 500K | 2M invocations | Judge pipeline calls |
| Realtime | 200 connections | 500 | Spectator feeds at scale |
| Storage | 1GB | 100GB (then $0.021/GB) | Submission files |

**Optimizations:**
- SELECT only needed columns (reduces egress)
- Paginate queries (never unbounded)
- Compress transcripts (gzip → 80% size reduction)
- Expire idle Realtime channels
- Use materialized views for leaderboards (compute once, read many)

### Anthropic API (Biggest Variable Cost)
| Model | Input $/M tokens | Output $/M tokens | Use For |
|-------|-----------------|-------------------|---------|
| Opus 4.6 | $15 | $75 | Complex architecture decisions ONLY |
| Sonnet 4.6 | $3 | $15 | Default: judging, email writing, research |
| Haiku 4.5 | $0.25 | $1.25 | Classification, routing, extraction, hints |

**Optimizations:**
- **Prompt caching:** Identical system prompts are cached by Anthropic — 90% savings on input tokens. Keep system prompts consistent across calls.
- **Batch API:** 50% cheaper for non-urgent work. Arena judge scoring is a perfect candidate — results don't need to be instant.
- **Model tiering:** Don't use Sonnet for what Haiku can do. Don't use Opus for what Sonnet can do.
- **Cost tracking:**

```ts
// Log every AI call with cost estimate
async function trackedAICall(model: string, fn: () => Promise<APIResponse>) {
  const result = await fn()
  const cost = estimateCost(model, result.usage.input_tokens, result.usage.output_tokens)
  
  await supabase.from('api_costs').insert({
    service: 'anthropic',
    model,
    feature: 'arena_judge', // tag by feature
    input_tokens: result.usage.input_tokens,
    output_tokens: result.usage.output_tokens,
    estimated_cost_usd: cost,
  })
  
  return result
}

// Daily rollup + budget alert
// pg_cron: if daily spend > $50, alert Nick
```

## Cost-Per-Feature Tracking

| Feature | Cost Driver | Estimated $/challenge |
|---------|------------|----------------------|
| Arena Judge (3× Sonnet) | 3 API calls × ~2K tokens each | ~$0.12 |
| Arena Judge (3× Opus) | 3 API calls × ~2K tokens each | ~$0.60 |
| Spectator Feed | Realtime connections + egress | ~$0.01 |
| Transcript Storage | Supabase Storage | ~$0.001 |
| Email Notification | Resend ($0.003/email) | ~$0.003 |

**Budget rule:** Set monthly spending caps per service. Alert at 80%. Hard limit at 100%.

## Sources
- Vercel pricing documentation
- Supabase pricing documentation
- Anthropic API pricing (2026)
- Resend pricing

## Changelog
- 2026-03-21: Initial skill — cost optimization
