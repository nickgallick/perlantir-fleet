---
name: caching-deep-dive
description: All caching layers in Next.js + Supabase — request memoization, data cache, route cache, router cache, invalidation strategies, stampede prevention.
---

# Caching Deep Dive

## Review Checklist

- [ ] `fetch()` calls have explicit cache strategy (not relying on defaults)
- [ ] Mutations call `revalidatePath`/`revalidateTag` (stale UI after mutation = cache bug)
- [ ] Server Actions revalidate after database writes
- [ ] No user-specific data in shared caches
- [ ] Cache keys include all relevant variables

---

## Next.js Caching Layers (Know ALL of Them)

### 1. Request Memoization (per-render dedup)
```tsx
// These two calls in the same render tree = ONE actual fetch
async function Header() { const user = await getUser() }
async function Sidebar() { const user = await getUser() } // deduped!
// Only during a single server render, not across requests
```

### 2. Data Cache (server-side, persists across requests)
```ts
// Cached indefinitely (default for fetch)
const data = await fetch(url) // force-cache by default

// Revalidate every hour
const data = await fetch(url, { next: { revalidate: 3600 } })

// Never cache (always fresh)
const data = await fetch(url, { cache: 'no-store' })

// Tag-based invalidation (surgical)
const data = await fetch(url, { next: { tags: ['challenges', `class:${weightClass}`] } })
// Later: revalidateTag('challenges') invalidates all, revalidateTag('class:Frontier') just one
```

### 3. Full Route Cache (rendered HTML at edge)
```ts
// Static: cached at build time
export default function AboutPage() { ... }

// Force dynamic: never cached
export const dynamic = 'force-dynamic'

// Revalidate periodically
export const revalidate = 3600 // re-render every hour
```

### 4. Router Cache (client-side, in-browser)
- Prefetched routes cached 30s (dynamic) or 5min (static)
- `router.refresh()` clears and refetches current route
- **The most common cache bug:** mutation happens, but client shows stale page because router cache wasn't invalidated

```ts
// Server Action MUST revalidate after mutations
'use server'
export async function createEntry(data: EntryInput) {
  await supabase.from('entries').insert(data)
  revalidatePath('/challenges/[id]', 'page') // ← without this, client sees stale data
}
```

## Supabase Caching Patterns

Supabase has NO built-in query caching. Every `.from().select()` hits the database.

### Materialized View Pattern (for leaderboards)
```sql
-- Create materialized view (pre-computed query result)
CREATE MATERIALIZED VIEW leaderboard_cache AS
SELECT a.agent_name, a.avatar_url, ar.elo_rating, ar.weight_class,
  ROW_NUMBER() OVER (PARTITION BY ar.weight_class ORDER BY ar.elo_rating DESC) as rank
FROM agent_ratings ar JOIN agents a ON a.id = ar.agent_id;

-- Refresh after ELO updates (not on every read)
REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_cache;

-- Index for fast reads
CREATE UNIQUE INDEX idx_leaderboard_agent ON leaderboard_cache (agent_name);
```

### Cache Table Pattern (TTL-based)
```sql
CREATE TABLE cache (
  key text PRIMARY KEY,
  value jsonb NOT NULL,
  expires_at timestamptz NOT NULL
);

-- pg_cron cleanup every 5 minutes
SELECT cron.schedule('clean-cache', '*/5 * * * *', $$
  DELETE FROM cache WHERE expires_at < now();
$$);
```

## Cache Stampede Prevention

**Problem:** Cache expires → 1000 simultaneous requests try to regenerate → database overwhelmed.

```ts
// Solution: locking with advisory lock
async function getOrCompute<T>(key: string, computeFn: () => Promise<T>, ttlMs: number): Promise<T> {
  // Check cache
  const cached = await getFromCache(key)
  if (cached && cached.expiresAt > Date.now()) return cached.value
  
  // Acquire lock (only one request regenerates)
  const lockAcquired = await tryAdvisoryLock(key)
  
  if (!lockAcquired) {
    // Another request is regenerating — serve stale or wait
    await sleep(100)
    return getOrCompute(key, computeFn, ttlMs) // retry
  }
  
  try {
    const value = await computeFn()
    await setInCache(key, value, Date.now() + ttlMs)
    return value
  } finally {
    await releaseAdvisoryLock(key)
  }
}
```

## What NOT to Cache

| Data | Why Not |
|------|---------|
| Wallet balance | Changes on every transaction, must be real-time |
| Active challenge timer | Must be server-authoritative |
| Auth session | Per-user, changes on login/logout |
| Webhook responses | Must always return fresh 200 |

## Sources
- Next.js caching documentation (all 4 layers)
- Vercel caching at the edge
- PostgreSQL materialized views

## Changelog
- 2026-03-21: Initial skill — caching deep dive
