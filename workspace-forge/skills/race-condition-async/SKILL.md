---
name: race-condition-async
description: Race condition detection and exploitation patterns in Node.js, Next.js, and async JavaScript/TypeScript applications. Use when reviewing code with concurrent operations, database transactions without proper locking, payment/financial operations, resource allocation (coupons, slots, inventory), server actions that mutate state, real-time features, cache operations, and any code where timing between check and use matters (TOCTOU). Covers the Next.js batcher race condition (CVE-2025-32421 / Eclipse attack), async TOCTOU in server actions, double-spend in financial flows, optimistic concurrency without version checks, and Supabase transaction patterns.
---

# Race Condition & Async Attacks

## Why Race Conditions Are Different in Node.js

Node.js is **single-threaded** but **async**. Traditional thread-based race conditions don't apply, but async race conditions are just as dangerous:

```
Traditional (multithreaded):
Thread A: read balance → Thread B: read balance → Thread A: write → Thread B: write (lost update)

Node.js (async):
Request A: read balance → await DB → 
Request B: read balance → await DB → (B reads SAME old value as A)
Request A: write new balance →
Request B: write new balance → (B overwrites A's update)
```

Every `await` is a potential race window. Between two `await`s, another request can execute.

## Attack Pattern 1: Double-Spend / Double-Claim

### The Vulnerability
```typescript
// VULNERABLE — check-then-act with await gap
export async function claimCoupon(userId: string, couponId: string) {
  // CHECK: Has user already claimed?
  const { data: existing } = await supabase
    .from('claims')
    .select()
    .eq('user_id', userId)
    .eq('coupon_id', couponId)
    .single()
  
  if (existing) throw new Error('Already claimed')
  
  // ACT: Create claim (race window between CHECK and ACT)
  await supabase.from('claims').insert({ user_id: userId, coupon_id: couponId })
  await supabase.from('coupons').update({ uses: coupon.uses + 1 }).eq('id', couponId)
}
```

**Attack**: Send 10 concurrent requests. All 10 pass the CHECK before any ACT completes. User claims 10 coupons.

### The Fix: Database-Level Atomicity
```typescript
// SAFE — unique constraint prevents double-claim at DB level
// 1. Add unique constraint: UNIQUE(user_id, coupon_id) on claims table
// 2. Use INSERT with conflict handling

export async function claimCoupon(userId: string, couponId: string) {
  const { error } = await supabase
    .from('claims')
    .insert({ user_id: userId, coupon_id: couponId })
  
  if (error?.code === '23505') { // Unique violation
    throw new Error('Already claimed')
  }
  
  // Atomic increment (not read-then-write)
  await supabase.rpc('increment_coupon_uses', { coupon_id: couponId })
}
```

```sql
-- RPC function for atomic increment
CREATE OR REPLACE FUNCTION increment_coupon_uses(coupon_id UUID)
RETURNS void AS $$
  UPDATE coupons SET uses = uses + 1 WHERE id = coupon_id;
$$ LANGUAGE sql;
```

## Attack Pattern 2: Balance Manipulation

### The Vulnerability
```typescript
// VULNERABLE — read-modify-write without locking
export async function transferFunds(fromId: string, toId: string, amount: number) {
  const { data: sender } = await supabase
    .from('wallets')
    .select('balance')
    .eq('user_id', fromId)
    .single()
  
  if (sender.balance < amount) throw new Error('Insufficient funds')
  
  // RACE WINDOW: another transfer can read the same old balance
  
  await supabase.from('wallets')
    .update({ balance: sender.balance - amount })
    .eq('user_id', fromId)
  
  await supabase.from('wallets')
    .update({ balance: supabase.raw('balance + ?', [amount]) })
    .eq('user_id', toId)
}
```

**Attack**: Send 5 transfers of $100 each simultaneously from an account with $100. All 5 read balance as $100, all 5 pass the check, sender ends up at -$400.

### The Fix: SELECT FOR UPDATE + Transaction
```sql
-- Supabase RPC function with proper locking
CREATE OR REPLACE FUNCTION transfer_funds(
  p_from_id UUID, p_to_id UUID, p_amount NUMERIC
) RETURNS void AS $$
DECLARE
  v_balance NUMERIC;
BEGIN
  -- Lock the sender's row
  SELECT balance INTO v_balance FROM wallets 
    WHERE user_id = p_from_id FOR UPDATE;
  
  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient funds';
  END IF;
  
  UPDATE wallets SET balance = balance - p_amount WHERE user_id = p_from_id;
  UPDATE wallets SET balance = balance + p_amount WHERE user_id = p_to_id;
END;
$$ LANGUAGE plpgsql;
```

## Attack Pattern 3: TOCTOU in Server Actions

### The Vulnerability (Next.js Server Actions)
```typescript
"use server"

export async function submitEntry(challengeId: string, code: string) {
  const user = await getUser()
  
  // CHECK: Is challenge still accepting submissions?
  const { data: challenge } = await supabase
    .from('challenges')
    .select('status, max_entries')
    .eq('id', challengeId)
    .single()
  
  if (challenge.status !== 'active') throw new Error('Challenge closed')
  
  // CHECK: Has user exceeded entry limit?
  const { count } = await supabase
    .from('entries')
    .select('*', { count: 'exact' })
    .eq('challenge_id', challengeId)
    .eq('user_id', user.id)
  
  if (count >= challenge.max_entries) throw new Error('Limit reached')
  
  // ACT: Submit entry (race window — all checks passed by concurrent requests)
  await supabase.from('entries').insert({
    challenge_id: challengeId,
    user_id: user.id,
    code
  })
}
```

**Attack**: Send `max_entries + 10` concurrent requests. All pass the count check before any insert completes.

### The Fix: Database Constraint + Atomic Check
```sql
-- Trigger that enforces max entries atomically
CREATE OR REPLACE FUNCTION check_entry_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_count INTEGER;
  v_max INTEGER;
BEGIN
  SELECT max_entries INTO v_max FROM challenges WHERE id = NEW.challenge_id;
  SELECT COUNT(*) INTO v_count FROM entries 
    WHERE challenge_id = NEW.challenge_id AND user_id = NEW.user_id;
  
  IF v_count >= v_max THEN
    RAISE EXCEPTION 'Entry limit exceeded';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_entry_limit
  BEFORE INSERT ON entries
  FOR EACH ROW EXECUTE FUNCTION check_entry_limit();
```

## Attack Pattern 4: Cache Poisoning Race (Next.js Eclipse)

CVE-2025-32421: Next.js batcher uses a Map keyed by path for request deduplication. Two concurrent requests with the same cache key can race:
- Request A generates the error page HTML
- Request B generates the pageProps data
- Batcher shares Request A's promise with Request B (same key)
- Result: pageProps content served with text/html content-type → Stored XSS

**Relevance**: Affects self-hosted Next.js with Pages Router and external CDN caching. Vercel-hosted apps are less affected (Vercel controls caching).

**Detection**: Self-hosted Next.js versions 14.2.10 through 15.1.5 using Pages Router with external CDN.

## Attack Pattern 5: Optimistic Update Conflicts

### The Vulnerability
```typescript
// VULNERABLE — optimistic update without version check
export async function updateProfile(userId: string, updates: Partial<Profile>) {
  await supabase
    .from('profiles')
    .update(updates)
    .eq('id', userId)
  // Last write wins — no conflict detection
}
```

### The Fix: Optimistic Concurrency Control
```typescript
export async function updateProfile(
  userId: string, 
  updates: Partial<Profile>, 
  expectedVersion: number
) {
  const { data, error } = await supabase
    .from('profiles')
    .update({ ...updates, version: expectedVersion + 1 })
    .eq('id', userId)
    .eq('version', expectedVersion)  // Only update if version matches
  
  if (!data || data.length === 0) {
    throw new Error('Conflict — profile was modified by another request')
  }
}
```

## Detection Checklist for Code Review

### Red Flags (async race conditions)
- [ ] **Read-then-write pattern**: `await read()` ... `await write()` with no locking between them
- [ ] **Check-then-act pattern**: `if (await exists())` ... `await create()` with no unique constraint
- [ ] **Counter increment**: `value = await get(); await set(value + 1)` instead of atomic `UPDATE SET x = x + 1`
- [ ] **Balance check**: `if (balance >= amount)` followed by separate update
- [ ] **Limit check**: `if (count < max)` followed by separate insert
- [ ] **Status check**: `if (status === 'active')` followed by separate mutation

### Safe Patterns
- [ ] **Unique constraints** for preventing duplicate creation
- [ ] **SELECT FOR UPDATE** for critical read-modify-write sequences
- [ ] **Atomic SQL operations** (e.g., `UPDATE SET balance = balance - $1 WHERE balance >= $1`)
- [ ] **Serializable transactions** for complex multi-step operations
- [ ] **Idempotency keys** for API endpoints (prevent duplicate processing)
- [ ] **Optimistic concurrency** with version columns

### Supabase-Specific Patterns
```sql
-- Atomic decrement with check (returns empty if insufficient)
UPDATE wallets 
SET balance = balance - $1 
WHERE user_id = $2 AND balance >= $1
RETURNING *;

-- Use RETURNING to check if the update matched — if no rows returned, 
-- the balance was insufficient (atomically checked)
```

## Testing for Race Conditions

### Manual Testing
```bash
# Send 20 concurrent identical requests
for i in {1..20}; do
  curl -X POST https://app.com/api/claim -H "Cookie: $SESSION" -d '{"id":"coupon-1"}' &
done
wait
```

### Automated Testing Pattern
```typescript
// Concurrent request test
const promises = Array.from({ length: 20 }, () =>
  fetch('/api/claim', { method: 'POST', body: '{"id":"coupon-1"}', headers })
)
const results = await Promise.allSettled(promises)
const successes = results.filter(r => r.status === 'fulfilled' && r.value.ok)
// If successes > 1 for a one-time-claim, race condition exists
```

## References

For Next.js Eclipse attack details, see `references/eclipse-nextjs.md`.
For PostgreSQL locking patterns, see the `advanced-postgres` skill.
