---
name: system-design-patterns
description: Distributed system patterns applied to Next.js + Supabase + Vercel — idempotency, circuit breakers, caching, event-driven architecture, sagas, and rate limiting.
---

# System Design Patterns

## Quick Reference — When to Apply Each Pattern

| Pattern | Apply When | Example |
|---------|-----------|---------|
| Idempotency | Any mutation endpoint | Challenge entry, coin transfer, vote |
| Circuit Breaker | Calling external APIs | Anthropic judge calls, gateway connections |
| Rate Limiting | Any public endpoint | API routes, webhook receivers |
| Saga | Multi-step mutations | Entry creation (wallet deduction + entry + notification) |
| Cache | Frequently read, rarely changed | Leaderboards, agent profiles, model registry |
| Event-driven | Decoupled processing | Post-challenge judging, ELO updates, notifications |

---

## Idempotency

Every mutation must be safely retryable. Network failures, timeouts, and client retries are normal — they shouldn't create duplicate entries.

```ts
// Middleware pattern — reusable across all mutation routes
const IdempotencyKeySchema = z.string().uuid()

async function withIdempotency<T>(
  key: string,
  operation: () => Promise<T>,
  supabase: SupabaseClient
): Promise<T> {
  // Check if this key was already processed
  const { data: existing } = await supabase
    .from('idempotency_keys')
    .select('response')
    .eq('key', key)
    .single()
  
  if (existing) return existing.response as T
  
  // Execute operation
  const result = await operation()
  
  // Store result with TTL (24 hours)
  await supabase.from('idempotency_keys').insert({
    key,
    response: result,
    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000)
  })
  
  return result
}
```

## Circuit Breaker

```ts
type CircuitState = 'closed' | 'open' | 'half-open'

class CircuitBreaker {
  private state: CircuitState = 'closed'
  private failures = 0
  private lastFailure = 0
  
  constructor(
    private threshold: number = 5,     // failures before opening
    private resetTimeout: number = 30000, // ms before half-open
  ) {}
  
  async call<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() - this.lastFailure > this.resetTimeout) {
        this.state = 'half-open'
      } else {
        throw new Error('Circuit is open — service unavailable')
      }
    }
    
    try {
      const result = await fn()
      this.onSuccess()
      return result
    } catch (error) {
      this.onFailure()
      throw error
    }
  }
  
  private onSuccess() {
    this.failures = 0
    this.state = 'closed'
  }
  
  private onFailure() {
    this.failures++
    this.lastFailure = Date.now()
    if (this.failures >= this.threshold) this.state = 'open'
  }
}

// Usage: one circuit per external service
const anthropicCircuit = new CircuitBreaker(3, 60000)
const judgeScore = await anthropicCircuit.call(() => 
  anthropic.messages.create({ ... })
)
```

## Rate Limiting (Token Bucket)

```ts
// Supabase Edge Function rate limiter using advisory locks
async function checkRateLimit(
  supabase: SupabaseClient,
  key: string,
  limit: number,
  windowMs: number
): Promise<{ allowed: boolean; remaining: number; resetAt: Date }> {
  const { data } = await supabase.rpc('check_rate_limit', {
    p_key: key,
    p_limit: limit,
    p_window_ms: windowMs
  })
  return data
}
```
```sql
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_key text, p_limit int, p_window_ms int
) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  v_count int;
  v_window_start timestamptz := now() - (p_window_ms || ' milliseconds')::interval;
BEGIN
  -- Clean old entries
  DELETE FROM rate_limits WHERE key = p_key AND created_at < v_window_start;
  -- Count current
  SELECT count(*) INTO v_count FROM rate_limits WHERE key = p_key;
  
  IF v_count >= p_limit THEN
    RETURN jsonb_build_object('allowed', false, 'remaining', 0);
  END IF;
  
  INSERT INTO rate_limits (key) VALUES (p_key);
  RETURN jsonb_build_object('allowed', true, 'remaining', p_limit - v_count - 1);
END; $$;
```

## Saga Pattern (Multi-Step with Compensation)

```ts
// Arena example: creating a challenge entry
async function createChallengeEntry(userId: string, challengeId: string) {
  const compensations: (() => Promise<void>)[] = []
  
  try {
    // Step 1: Deduct entry fee
    await deductCoins(userId, ENTRY_FEE)
    compensations.push(() => refundCoins(userId, ENTRY_FEE))
    
    // Step 2: Create entry record
    const entry = await createEntry(userId, challengeId)
    compensations.push(() => deleteEntry(entry.id))
    
    // Step 3: Reserve gateway connection slot
    await reserveSlot(challengeId)
    compensations.push(() => releaseSlot(challengeId))
    
    return { success: true, entry }
  } catch (error) {
    // Compensate in reverse order
    for (const compensate of compensations.reverse()) {
      try { await compensate() } catch (e) {
        console.error('[saga] Compensation failed:', e)
        // Log for manual intervention
      }
    }
    return { success: false, error: 'Entry creation failed' }
  }
}
```

## Caching Strategies (Next.js)

| Layer | Scope | Invalidation | Use For |
|-------|-------|-------------|---------|
| `fetch` cache | Per-request dedup | `revalidate: 60` or `revalidateTag()` | External API calls |
| Full Route Cache | Pre-rendered pages | `revalidatePath()` | Static/ISR pages |
| Router Cache | Client-side nav | Time-based (30s dynamic, 5min static) | Previously visited routes |
| Supabase cache table | Custom TTL | `pg_cron` cleanup | Computed leaderboards, rankings |

```ts
// revalidateTag for surgical cache invalidation
// In data fetcher:
const data = await fetch(url, { next: { tags: ['leaderboard', `class:${weightClass}`] } })

// After ELO update:
revalidateTag(`class:${weightClass}`) // only invalidates this weight class
```

## Event-Driven Architecture (Supabase)

```sql
-- Database webhook: trigger Edge Function on new entry
CREATE OR REPLACE FUNCTION notify_new_entry()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/on-entry-created',
    body := jsonb_build_object('entry_id', NEW.id, 'challenge_id', NEW.challenge_id)
  );
  RETURN NEW;
END; $$;

CREATE TRIGGER on_entry_created AFTER INSERT ON entries
FOR EACH ROW EXECUTE FUNCTION notify_new_entry();
```

## Sources
- system-design-primer (donnemartin) — distributed systems patterns
- cal.com — production saga and webhook patterns
- Next.js caching documentation
- Supabase pg_net and database webhooks

## Changelog
- 2026-03-21: Initial skill — system design patterns for Arena
