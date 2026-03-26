---
name: queue-and-background-jobs
description: Background job processing with Supabase — jobs table, FOR UPDATE SKIP LOCKED, pg_cron polling, webhook triggers, retry patterns, and when to use external queues.
---

# Queue & Background Jobs

## Review Checklist

1. [ ] Jobs table uses `FOR UPDATE SKIP LOCKED` (no double processing)
2. [ ] Handlers are idempotent (safe to run twice)
3. [ ] Failed jobs retry with backoff (not immediately)
4. [ ] Stuck jobs detected and reset (timeout on 'processing')
5. [ ] Job results stored for debugging
6. [ ] API rate limits respected in worker

---

## Jobs Table Schema

```sql
CREATE TABLE jobs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  type text NOT NULL,
  payload jsonb NOT NULL,
  status text DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'dead')),
  priority int DEFAULT 0,
  attempts int DEFAULT 0,
  max_attempts int DEFAULT 3,
  last_error text,
  result jsonb,
  scheduled_for timestamptz DEFAULT now(),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_jobs_pending ON jobs (type, priority DESC, created_at)
  WHERE status = 'pending';

ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
-- No client access — only service role via Edge Functions
```

## Atomic Job Picking (No Double Processing)

```sql
CREATE OR REPLACE FUNCTION pick_job(p_type text)
RETURNS SETOF jobs LANGUAGE sql AS $$
  UPDATE jobs
  SET status = 'processing',
      started_at = now(),
      attempts = attempts + 1
  WHERE id = (
    SELECT id FROM jobs
    WHERE type = p_type
      AND status = 'pending'
      AND scheduled_for <= now()
    ORDER BY priority DESC, created_at ASC
    FOR UPDATE SKIP LOCKED
    LIMIT 1
  )
  RETURNING *;
$$;
```

**Why `FOR UPDATE SKIP LOCKED`:** If two workers call `pick_job` simultaneously, each gets a DIFFERENT job. Without `SKIP LOCKED`, one would wait for the other — defeating parallelism. With `SKIP LOCKED`, locked rows are simply skipped.

## Worker Pattern (Edge Function)

```ts
// functions/process-jobs/index.ts
Deno.serve(async (req) => {
  const { type } = await req.json()
  const supabase = createServiceClient()
  
  // Pick a job atomically
  const { data: jobs } = await supabase.rpc('pick_job', { p_type: type })
  if (!jobs?.length) return new Response('No jobs')
  
  const job = jobs[0]
  
  try {
    // Process based on type
    const result = await processJob(job)
    
    // Mark completed
    await supabase.from('jobs').update({
      status: 'completed',
      result,
      completed_at: new Date().toISOString(),
    }).eq('id', job.id)
    
  } catch (error) {
    const shouldRetry = job.attempts < job.max_attempts
    
    await supabase.from('jobs').update({
      status: shouldRetry ? 'pending' : 'failed',
      last_error: String(error),
      // Exponential backoff: 30s, 2min, 10min
      scheduled_for: shouldRetry
        ? new Date(Date.now() + 30000 * Math.pow(4, job.attempts - 1)).toISOString()
        : undefined,
    }).eq('id', job.id)
  }
  
  return new Response(JSON.stringify({ processed: job.id }))
})
```

## Trigger Patterns

### Pattern 1: pg_cron Polling (Reliable)
```sql
-- Poll every 30 seconds
SELECT cron.schedule('process-judging', '*/30 * * * * *', $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT.supabase.co/functions/v1/process-jobs',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body := '{"type": "judge_challenge"}'::jsonb
  );
$$);
```

### Pattern 2: Database Webhook (Fast, Unreliable)
Insert into `jobs` → Supabase webhook fires → calls Edge Function instantly.
Use as primary trigger, with pg_cron as backup.

### Stuck Job Recovery
```sql
-- Reset jobs stuck in 'processing' for >5 minutes
UPDATE jobs
SET status = 'pending', started_at = NULL
WHERE status = 'processing'
  AND started_at < now() - interval '5 minutes'
  AND attempts < max_attempts;

-- Move exhausted jobs to 'dead' (manual review)
UPDATE jobs
SET status = 'dead'
WHERE status = 'failed'
  AND attempts >= max_attempts;
```

## When to Use External Queues

| Need | Supabase Native | Trigger.dev | Inngest |
|------|:--------------:|:-----------:|:-------:|
| <100 jobs/min | ✅ | Overkill | Overkill |
| Complex workflows | ⚠️ Manual | ✅ Step functions | ✅ Flow control |
| Job progress UI | Manual polling | ✅ Built-in | ✅ Built-in |
| >1000 jobs/min | ❌ Limits | ✅ | ✅ |
| **Arena MVP** | **✅** | Evaluate later | Evaluate later |

## Sources
- PostgreSQL advisory locks and FOR UPDATE SKIP LOCKED
- triggerdotdev/trigger.dev — serverless job patterns
- inngest/inngest — event-driven function patterns
- Supabase pg_cron + pg_net documentation

## Changelog
- 2026-03-21: Initial skill — queue and background jobs
