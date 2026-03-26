---
name: systematic-debugging
description: Scientific debugging methodology — observe, hypothesize, isolate, fix, prevent. Stack-specific debugging patterns for Next.js, Supabase, and TypeScript.
---

# Systematic Debugging

## The Scientific Method for Bugs

### 1. Observe (be precise)
❌ "It's broken"
✅ "POST /api/entries returns 500 when payload includes `agent_id: null`. Error in logs: `TypeError: Cannot read properties of null (reading 'gateway_url')`"

### 2. Hypothesize (top 3, ranked)
Before touching code, list the most likely causes:
1. Missing null check on `agent_id` before querying agent details (80% likely)
2. Zod schema accepts null but shouldn't (15%)
3. Database has a null agent_id in entries table (5%)

### 3. Test (simplest first)
For hypothesis 1: add a log before the line that reads `gateway_url` — does `agent` exist?
For hypothesis 2: check the Zod schema — does it allow null?
Start with 2 (quickest to check).

### 4. Isolate (binary search)
```
Request comes in → parse body → validate → query agent → use agent.gateway_url
                                              ↑ error is here?
Add log: console.log('agent:', agent) → agent is null
Root: query returns null because agent_id doesn't match any row
```

### 5. Root Cause (ask WHY)
Don't stop at "agent is null." WHY is it null?
- The Zod schema allows any string for agent_id (no UUID validation)
- The client sent a malformed ID
- No `.single()` error check after the Supabase query

### 6. Fix + Verify
Fix: Add UUID validation in Zod, add null check after query, return 404 if agent not found.
Verify: Send the same null payload → expect 400 (validation error). Send valid payload → expect 200.

### 7. Prevent
- Add `z.string().uuid()` to all ID fields in schemas
- Add a linter rule or type-level check for Supabase `.single()` without error handling

---

## Stack-Specific Debugging

### Next.js

**Hydration mismatch:**
```
Warning: Text content does not match. Server: "March 21" Client: "March 22"
```
Causes: `Date.now()`, `Math.random()`, `typeof window !== 'undefined'` conditionals, browser-only APIs.
Debug: Add `suppressHydrationWarning` temporarily to narrow which element. Then fix the SSR/client divergence.

**Middleware redirect loop:**
Check: Does middleware redirect to a page that triggers middleware again? Common: redirect unauthenticated to `/login`, but `/login` also triggers middleware.
Fix: Matcher exclusion: `export const config = { matcher: ['/((?!login|api|_next).*)'] }`

**Build errors not in dev:**
Next.js dev mode is forgiving. Build is strict. Common causes:
- Dynamic import without `ssr: false` for client-only components
- `window` or `document` referenced in a server component
- Missing `'use client'` on a component that uses hooks
Debug: `npx next build` locally — read the FULL error, not just the first line.

### Supabase

**RLS blocking everything (data exists but query returns empty):**
```sql
-- Debug in SQL Editor: simulate authenticated user
SET role authenticated;
SET request.jwt.claims TO '{"sub":"actual-user-uuid-here","role":"authenticated"}';
SELECT * FROM my_table;
-- If empty: RLS policy is blocking. Check policies:
SELECT * FROM pg_policies WHERE tablename = 'my_table';
```

**Realtime not firing:**
Checklist:
1. Table has `REPLICA IDENTITY FULL`? (`ALTER TABLE my_table REPLICA IDENTITY FULL`)
2. Table is in the Realtime publication? (Check Dashboard → Database → Publications)
3. RLS allows the subscriber to read? (Postgres Changes respect table RLS)
4. Channel created with correct filter?

**Edge Function timeout:**
- Local works, production doesn't → check for missing env vars (throws at runtime)
- Heavy imports → lazy import infrequently used modules
- DNS resolution delay → use IP directly or configure DNS cache
- Function exceeds 60s default → request timeout extension (up to 300s)

**Auth token expired silently:**
- Default JWT expiry: 3600s. After that, `auth.uid()` returns null in RLS.
- Fix: ensure middleware calls `supabase.auth.getClaims()` to refresh tokens
- Debug: decode JWT at jwt.io → check `exp` field

### TypeScript

**Types correct, runtime crashes:**
Check for: `as` assertions, `any` types, `!` non-null assertions, missing `await`.
```ts
// TypeScript says this is fine:
const data = response as UserData  // but response could be null
data.name  // runtime: TypeError: Cannot read properties of null
```

**Stale generated types:**
After DB schema change: `supabase gen types typescript --local > types/database.ts`
After package update: delete `node_modules/.cache` and restart

---

## Binary Search Debugging (Unknown Codebases)

When you have no idea where the bug is:

```
1. Find entry point (API route? Event handler? Component?)
   → Add log → Does it fire? NO → Problem is routing/middleware
                                YES ↓
2. Find exit point (response, render, return)
   → Add log → Does it reach? NO → Binary search between entry and exit
                                YES → Problem is in the output formatting
3. Bisect: add log at midpoint
   → Fires? YES → bug is in second half
            NO  → bug is in first half
4. Repeat until you find the exact line
```

This is faster than reading every line when the codebase is unfamiliar. 5-6 bisections covers 64 lines of code.

---

## Debugging in Review Context

When Maks submits code with a bug you catch:

❌ "This is wrong"
✅ Walk through the scenario:
```
Scenario: User A and User B both enter challenge #5 simultaneously.

1. User A calls createEntry() at T=0
2. User B calls createEntry() at T=0.1s  
3. Both reach the balance check: balance >= ENTRY_FEE ← both pass (balance is 100)
4. Both deduct: balance = balance - 50
5. Result: balance = 50 (should be 0 or second should fail)

Root cause: balance check and deduction are not atomic.
Fix: Use a Postgres function with SELECT FOR UPDATE.
```

## Sources
- SWE-agent trajectory patterns — structured debugging in automated agents
- PostgreSQL debugging with RLS (SET role, request.jwt.claims)
- Next.js error documentation
- Supabase Realtime debugging guide

## Changelog
- 2026-03-21: Initial skill — systematic debugging
