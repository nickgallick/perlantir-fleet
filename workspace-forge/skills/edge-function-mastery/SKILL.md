---
name: edge-function-mastery
description: Supabase Edge Function patterns — Deno runtime, cold start optimization, challenge orchestration, judge pipeline, ELO calculation, long-running operations.
---

# Edge Function Mastery

## Architecture Overview

```
Arena Edge Functions:
├── challenge-orchestrator  — Coordinate challenge start, monitor, trigger judging
├── judge-submissions      — Call 3 AI judges in parallel, collect scores
├── calculate-elo          — Compute new ELO for all participants
├── update-leaderboard     — Refresh materialized leaderboard views
├── webhook-receiver       — Accept callbacks from gateway/external services
├── health-check           — Dependency status endpoint
└── process-transcript     — Parse and store session transcripts
```

## Deno Runtime Essentials

### Available
- `fetch()` — standard Web Fetch API
- `crypto` — Web Crypto API (SHA-256, HMAC, random values)
- `TextEncoder` / `TextDecoder`
- `WebSocket` — client WebSocket connections
- `console` — standard logging
- `Deno.env.get()` — environment variables
- `import` from `npm:` — npm packages that don't require Node-specific APIs

### NOT Available
- `fs` / `path` — no file system access
- `child_process` — no spawning processes
- `net` / `dgram` — no raw network sockets
- `crypto.createHash()` — use Web Crypto instead
- Node.js streams — use Web Streams API

### Cold Start Optimization
```ts
// ❌ Heavy top-level imports (loaded on every cold start)
import { createClient } from 'npm:@supabase/supabase-js'
import Anthropic from 'npm:@anthropic-ai/sdk'
import { z } from 'npm:zod'

// ✅ Lazy imports for infrequently used code
const supabase = createClient(/* ... */) // OK — always needed

Deno.serve(async (req) => {
  const path = new URL(req.url).pathname
  
  if (path === '/judge') {
    // Only import Anthropic when actually judging
    const { default: Anthropic } = await import('npm:@anthropic-ai/sdk')
    // ...
  }
})
```

---

## Arena Function Patterns

### Challenge Orchestrator
```ts
// functions/challenge-orchestrator/index.ts
Deno.serve(async (req) => {
  const { challengeId } = await req.json()
  const supabase = createServiceClient()
  
  // 1. Get challenge and entries
  const { data: challenge } = await supabase
    .from('challenges').select('*').eq('id', challengeId).single()
  
  const { data: entries } = await supabase
    .from('entries').select('*, agents(*)').eq('challenge_id', challengeId)
  
  // 2. Connect to each agent's gateway (staggered)
  const results = []
  for (const entry of entries) {
    try {
      const result = await withTimeout(
        () => spawnAgentSession(entry, challenge),
        challenge.time_limit_seconds * 1000 + 30000 // time limit + 30s buffer
      )
      results.push({ entryId: entry.id, status: 'submitted', ...result })
    } catch (error) {
      results.push({ entryId: entry.id, status: 'timeout', error: String(error) })
    }
    
    // Stagger: 200ms between connections
    await new Promise(r => setTimeout(r, 200))
  }
  
  // 3. Update entries with results
  for (const result of results) {
    await supabase.from('entries').update({
      status: result.status,
      submission_text: result.output,
      session_transcript: result.transcript,
    }).eq('id', result.entryId)
  }
  
  // 4. Trigger judging
  await supabase.functions.invoke('judge-submissions', {
    body: { challengeId }
  })
  
  return new Response(JSON.stringify({ processed: results.length }))
})
```

### Judge Pipeline
```ts
// functions/judge-submissions/index.ts
Deno.serve(async (req) => {
  const { challengeId } = await req.json()
  const supabase = createServiceClient()
  const anthropic = new Anthropic()
  
  const { data: entries } = await supabase
    .from('entries')
    .select('*')
    .eq('challenge_id', challengeId)
    .eq('status', 'submitted')
  
  const { data: challenge } = await supabase
    .from('challenges').select('*').eq('id', challengeId).single()
  
  for (const entry of entries) {
    // 3 judges in parallel
    const judgeResults = await Promise.allSettled([
      judgeEntry(anthropic, entry, challenge, 'alpha'),
      judgeEntry(anthropic, entry, challenge, 'beta'),
      judgeEntry(anthropic, entry, challenge, 'gamma'),
    ])
    
    const scores = judgeResults
      .filter(r => r.status === 'fulfilled')
      .map(r => r.value)
    
    if (scores.length < 2) {
      await supabase.from('entries').update({ status: 'judge_failed' }).eq('id', entry.id)
      continue
    }
    
    // Consensus check (median, outlier detection)
    const consensus = validateConsensus(scores)
    
    // Store scores
    for (const score of scores) {
      await supabase.from('judge_scores').insert({
        entry_id: entry.id,
        judge_id: score.judgeId,
        scores_json: score.scores,
        feedback_text: score.feedback,
      })
    }
    
    // Update entry with final AI score
    await supabase.from('entries').update({
      ai_scores_json: consensus.finalScores,
      status: 'judged',
    }).eq('id', entry.id)
  }
  
  // Trigger ELO calculation
  await supabase.functions.invoke('calculate-elo', { body: { challengeId } })
  
  return new Response(JSON.stringify({ judged: entries.length }))
})
```

### ELO Calculator
```ts
// functions/calculate-elo/index.ts
Deno.serve(async (req) => {
  const { challengeId } = await req.json()
  const supabase = createServiceClient()
  
  // Use RPC to calculate ELO atomically with advisory locks
  const { error } = await supabase.rpc('calculate_challenge_elo', {
    p_challenge_id: challengeId
  })
  
  if (error) {
    console.error('ELO calculation failed:', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
  
  // Trigger leaderboard refresh
  await supabase.functions.invoke('update-leaderboard', { body: { challengeId } })
  
  return new Response(JSON.stringify({ success: true }))
})
```

---

## Long-Running Operations

### Problem: Edge Function timeout (60s default, 300s max)
A challenge with 50 agents might take 30+ minutes for all agents to submit.

### Solution: Fan-Out Pattern
```
challenge-orchestrator (short-lived)
  ├── Spawns: agent-session-1 (per-agent function, up to 300s)
  ├── Spawns: agent-session-2
  ├── ...
  └── Spawns: agent-session-N
  
Each agent-session writes results to DB when done.
pg_cron job checks: are all entries submitted? → trigger judging
```

### Status Tracking
```sql
-- Jobs table for tracking long operations
CREATE TABLE jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL, -- 'judge_challenge', 'calculate_elo'
  status text NOT NULL DEFAULT 'pending', -- pending, running, complete, failed
  payload jsonb,
  result jsonb,
  progress int DEFAULT 0, -- 0-100
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Client polls this table for progress
-- Or use Supabase Realtime to push updates
```

---

## Testing Edge Functions

```bash
# Local development
supabase functions serve challenge-orchestrator --env-file .env.local

# Test with curl
curl -i --request POST 'http://localhost:54321/functions/v1/challenge-orchestrator' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"challengeId": "test-123"}'

# Deploy
supabase functions deploy challenge-orchestrator
```

### Integration Test Pattern
```ts
// tests/edge-functions/judge-submissions.test.ts
import { describe, it, expect } from 'vitest'

describe('judge-submissions', () => {
  it('judges all submitted entries', async () => {
    // Seed test data
    const challengeId = await createTestChallenge()
    await createTestEntries(challengeId, 3)
    
    // Invoke function
    const response = await supabase.functions.invoke('judge-submissions', {
      body: { challengeId }
    })
    
    expect(response.error).toBeNull()
    
    // Verify all entries have scores
    const { data: entries } = await supabase
      .from('entries')
      .select('status, ai_scores_json')
      .eq('challenge_id', challengeId)
    
    expect(entries).toHaveLength(3)
    expect(entries.every(e => e.status === 'judged')).toBe(true)
    expect(entries.every(e => e.ai_scores_json !== null)).toBe(true)
  })
})
```

## Sources
- Supabase Edge Functions documentation (Deno runtime)
- judge0 — code execution and submission evaluation patterns
- Supabase pg_net + pg_cron for async processing
- Deno documentation

## Changelog
- 2026-03-21: Initial skill — Edge Function mastery for Arena
