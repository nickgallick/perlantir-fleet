---
name: concurrency-patterns
description: Race condition prevention, database concurrency, concurrent request handling, and real-time event ordering for Arena's high-concurrency architecture.
---

# Concurrency Patterns

## Quick Reference — Concurrency Review Checks

1. [ ] **Financial mutations use transactions** with SELECT FOR UPDATE or advisory locks
2. [ ] **ELO updates use advisory locks** keyed to agent_id (prevent concurrent updates)
3. [ ] **Votes have unique constraint** (user_id, entry_id) — DB-enforced idempotency
4. [ ] **External API calls have semaphore** — max N concurrent requests
5. [ ] **Promise.allSettled** used when partial failure is acceptable
6. [ ] **Supabase Realtime events handled idempotently** — same event twice = same result
7. [ ] **Consistent lock ordering** to prevent deadlocks

---

## Race Condition Prevention

### SELECT FOR UPDATE (Row-Level Lock)
```sql
-- ELO update: prevent concurrent modification
CREATE OR REPLACE FUNCTION update_elo_after_challenge(
  p_agent_id uuid, p_challenge_id uuid, p_new_elo int
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  -- Lock this agent's rating row — other transactions wait
  PERFORM 1 FROM agent_ratings 
  WHERE agent_id = p_agent_id 
  FOR UPDATE;
  
  UPDATE agent_ratings 
  SET elo_rating = p_new_elo, 
      updated_at = now()
  WHERE agent_id = p_agent_id;
  
  -- Insert history record
  INSERT INTO elo_history (agent_id, challenge_id, elo_after)
  VALUES (p_agent_id, p_challenge_id, p_new_elo);
END; $$;
```

### Advisory Locks (Lightweight Application Locks)
```sql
-- Advisory lock: keyed to agent_id, auto-released at transaction end
CREATE OR REPLACE FUNCTION process_agent_results(p_agent_id uuid)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  -- Acquire lock — blocks if another transaction holds it for same agent
  PERFORM pg_advisory_xact_lock(hashtext(p_agent_id::text));
  
  -- Safe to update — no other transaction can touch this agent concurrently
  -- ... update ELO, update stats, update leaderboard ...
END; $$;
```

### Optimistic Locking (Version Column)
```ts
// Application-level: check version before update
async function updateAgentProfile(agentId: string, updates: Partial<Agent>, expectedVersion: number) {
  const { data, error } = await supabase
    .from('agents')
    .update({ ...updates, version: expectedVersion + 1 })
    .eq('id', agentId)
    .eq('version', expectedVersion) // only succeeds if version matches
    .select()
    .single()
  
  if (!data) {
    throw new ConflictError('Agent was modified by another request. Please retry.')
  }
  return data
}
```

### Arena-Specific Race Conditions

| Race Condition | Where | Fix |
|---------------|-------|-----|
| Two entries from same agent in one challenge | `createEntry()` | Unique constraint `(agent_id, challenge_id)` |
| Simultaneous judge scores overwriting each other | `storeJudgeScore()` | INSERT only, unique constraint `(entry_id, judge_id)` |
| Concurrent votes from same user | `castVote()` | Unique constraint `(user_id, entry_id)` |
| Parallel ELO updates for same agent | `updateElo()` | Advisory lock keyed to `agent_id` |
| Coin balance going negative from concurrent deductions | `deductCoins()` | `CHECK (balance >= 0)` + transaction |
| Challenge timer checked at different times by different services | Timer expiry | Server-authoritative timestamp, single orchestrator |

---

## Concurrent Request Handling

### Promise.all vs Promise.allSettled
```ts
// Promise.all: fail-fast. If ONE judge fails, ALL fail.
// Use when: all results are required
const [scoreA, scoreB, scoreC] = await Promise.all([
  judgeSubmission(entry, 'alpha'),
  judgeSubmission(entry, 'beta'),
  judgeSubmission(entry, 'gamma'),
])

// Promise.allSettled: collect all results, even failures
// Use when: partial results are acceptable
const results = await Promise.allSettled([
  judgeSubmission(entry, 'alpha'),
  judgeSubmission(entry, 'beta'),
  judgeSubmission(entry, 'gamma'),
])
const scores = results
  .filter(r => r.status === 'fulfilled')
  .map(r => r.value)
// If only 2 of 3 judges succeed, still have scores
```

### Semaphore (Concurrency Limiter)
```ts
// Limit concurrent API calls to Anthropic (prevent rate limiting)
class Semaphore {
  private queue: (() => void)[] = []
  private current = 0
  
  constructor(private max: number) {}
  
  async acquire(): Promise<void> {
    if (this.current < this.max) {
      this.current++
      return
    }
    return new Promise(resolve => this.queue.push(resolve))
  }
  
  release(): void {
    this.current--
    const next = this.queue.shift()
    if (next) {
      this.current++
      next()
    }
  }
}

const anthropicSemaphore = new Semaphore(10) // max 10 concurrent judge calls

async function judgeWithLimit(entry: Entry, judgeId: string) {
  await anthropicSemaphore.acquire()
  try {
    return await judgeSubmission(entry, judgeId)
  } finally {
    anthropicSemaphore.release()
  }
}
```

### Queue-Based Sequential Processing
```ts
// ELO updates must be sequential per agent (but parallel across agents)
async function processEloUpdates(entries: Entry[]) {
  // Group by agent
  const byAgent = groupBy(entries, 'agent_id')
  
  // Process agents in parallel, but entries for same agent sequentially
  await Promise.all(
    Object.entries(byAgent).map(async ([agentId, agentEntries]) => {
      for (const entry of agentEntries) {
        await processAgentElo(agentId, entry) // sequential per agent
      }
    })
  )
}
```

---

## Database Concurrency

### MVCC (Multi-Version Concurrency Control)
PostgreSQL doesn't lock rows for reads. Readers never block writers, writers never block readers. This means:
- SELECT always sees a consistent snapshot (no dirty reads)
- But UPDATE + UPDATE on same row: second one waits for first to commit
- Transaction isolation levels control what snapshot you see

### FOR UPDATE SKIP LOCKED (Job Queue Pattern)
```sql
-- Process next unprocessed challenge without blocking other workers
CREATE OR REPLACE FUNCTION claim_next_challenge()
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE v_challenge_id uuid;
BEGIN
  SELECT id INTO v_challenge_id
  FROM challenges
  WHERE status = 'pending_judging'
  ORDER BY ends_at ASC
  FOR UPDATE SKIP LOCKED -- skip rows locked by other workers
  LIMIT 1;
  
  IF v_challenge_id IS NOT NULL THEN
    UPDATE challenges SET status = 'judging' WHERE id = v_challenge_id;
  END IF;
  
  RETURN v_challenge_id;
END; $$;
```

### Deadlock Prevention
**Rule:** Always acquire locks in consistent order.
```
// ❌ Deadlock-prone: Transaction A locks agent1 then agent2
//                    Transaction B locks agent2 then agent1
// They wait for each other forever

// ✅ Always lock in sorted order
const agentIds = [fromAgentId, toAgentId].sort()
await lockAgent(agentIds[0])
await lockAgent(agentIds[1])
```

---

## Real-Time Event Ordering

### Sequence Numbers
```ts
// Supabase Realtime doesn't guarantee message order
// Use sequence numbers for ordering

interface OrderedEvent<T> {
  seq: number     // monotonically increasing
  timestamp: number
  data: T
}

function processOrderedEvents<T>(
  buffer: OrderedEvent<T>[],
  lastProcessedSeq: number
): { processed: T[]; newLastSeq: number } {
  const sorted = buffer
    .filter(e => e.seq > lastProcessedSeq)
    .sort((a, b) => a.seq - b.seq)
  
  const processed: T[] = []
  let newLastSeq = lastProcessedSeq
  
  for (const event of sorted) {
    if (event.seq !== newLastSeq + 1) break // gap detected — wait for missing event
    processed.push(event.data)
    newLastSeq = event.seq
  }
  
  return { processed, newLastSeq }
}
```

### Idempotent Event Handlers
```ts
// Same event delivered twice must produce same result
const processedEvents = new Set<string>()

function handleRealtimeEvent(event: RealtimeEvent) {
  const eventId = `${event.table}:${event.id}:${event.commit_timestamp}`
  
  if (processedEvents.has(eventId)) return // already processed
  processedEvents.add(eventId)
  
  // Process event
  updateLocalState(event)
}
```

## Sources
- PostgreSQL documentation (MVCC, advisory locks, transaction isolation)
- lichess (Scala) — concurrent game state management
- system-design-primer — distributed concurrency patterns
- Supabase Realtime event ordering documentation

## Changelog
- 2026-03-21: Initial skill — concurrency patterns for Arena
