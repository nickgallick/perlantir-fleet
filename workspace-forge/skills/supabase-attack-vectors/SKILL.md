---
name: supabase-attack-vectors
description: Supabase-specific security vulnerabilities, RLS bypass techniques, auth pitfalls, and attack vectors that are unique to the Supabase + Next.js stack.
---

# Supabase Attack Vectors

## 1. RLS Bypass Vectors

### 1.1 RLS Not Enabled
Tables created via SQL (not Dashboard) don't have RLS enabled by default.
```sql
-- CHECK: Is RLS on?
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
-- If rowsecurity = false → table is wide open through the API
```
**Review:** Every `CREATE TABLE` migration must include `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.

### 1.2 Missing Policies = Full Lockout (or Full Access)
- RLS enabled + no policies = no access via API (safe default)
- But `USING (true)` policy = public read to everyone
- Overly permissive policies are the most common Supabase vulnerability

**Review pattern:**
```sql
-- ❌ DANGEROUS: anyone can read everything
create policy "public" on users for select using (true);

-- ✅ SAFE: only own data
create policy "own_data" on users for select
  using ((select auth.uid()) = id);
```

### 1.3 Service Role Key Exposed
The `SUPABASE_SERVICE_ROLE_KEY` bypasses ALL RLS. If it's in:
- Client-side code (`NEXT_PUBLIC_*`)
- Git history
- Browser-accessible API route without auth
→ Attacker has god-mode access to entire database.

**Review:** Search entire codebase for `SERVICE_ROLE`. Must only appear in:
- Server-side code (Edge Functions, server-only utils)
- Environment variables (never `NEXT_PUBLIC_`)
- Never in git history

### 1.4 Views Bypass RLS
Views created with default `security_definer` bypass RLS entirely.
```sql
-- ❌ Bypasses RLS (default behavior)
create view public.user_emails as select id, email from auth.users;

-- ✅ Respects RLS (Postgres 15+)
create view public.user_profiles
  with (security_invoker = true)
  as select id, display_name from profiles;
```

### 1.5 Functions with SECURITY DEFINER
Functions marked `SECURITY DEFINER` run as the function owner (usually `postgres`), bypassing RLS.
- Necessary for operations like `transfer_funds` that need elevated access
- Must validate ALL inputs inside the function
- Must verify ownership/authorization within the function body

**Review:** Every `SECURITY DEFINER` function must have explicit auth checks inside.

## 2. Auth Vulnerabilities

### 2.1 getSession() vs getClaims()
```ts
// ❌ INSECURE on server — doesn't validate JWT, can be spoofed via cookies
const { data: { session } } = await supabase.auth.getSession()

// ✅ SECURE — validates JWT signature against Supabase public keys
const { data: { claims } } = await supabase.auth.getClaims()
```
**Impact:** Attacker can craft a fake session cookie. `getSession()` will trust it. `getClaims()` will reject it.

### 2.2 Anon Key Confusion
The `anon` key is PUBLIC — it's meant to be in the browser. It doesn't grant access; RLS does.
- `anon` key + no RLS = full database access
- `anon` key + proper RLS = safe
- Service role key = bypasses RLS entirely

### 2.3 JWT Expiry and Refresh
- Default Supabase JWT expiry: 3600 seconds (1 hour)
- If middleware doesn't refresh tokens, users get silent auth failures
- Stale JWTs mean `auth.jwt()` in RLS policies has outdated claims

**Review:** Next.js Proxy must call `supabase.auth.getClaims()` to refresh tokens.

### 2.4 User Metadata Manipulation
```ts
// Users can update their own user_metadata:
await supabase.auth.updateUser({ data: { role: 'admin' } })
```
- `raw_user_meta_data` is user-writable — NEVER use for authorization
- `raw_app_meta_data` is server-only — safe for roles/permissions

**Review:** Any RLS policy using `auth.jwt()->'user_metadata'` is vulnerable to privilege escalation.
```sql
-- ❌ VULNERABLE: user can set their own role
using (auth.jwt()->'user_metadata'->>'role' = 'admin')

-- ✅ SAFE: app_metadata can't be modified by user
using (auth.jwt()->'app_metadata'->>'role' = 'admin')
```

## 3. API Attack Vectors

### 3.1 PostgREST Query Manipulation
Supabase's REST API (PostgREST) allows complex queries via URL params:
- `?select=*,secret_table(*)` — join to tables the client shouldn't access
- `?or=(role.eq.admin)` — filter manipulation
- `?limit=1000000` — DoS via large result sets

**Mitigation:** RLS is the primary defense. But also:
- Limit exposed columns via RLS `SELECT` policies
- Use API Gateway rate limiting
- Consider using RPC functions instead of direct table access for sensitive operations

### 3.2 Supabase Realtime Leaks
Realtime subscriptions respect RLS, but:
- Subscribing to `INSERT` events may reveal data before policies are evaluated in edge cases
- Channel names are not authenticated — anyone can subscribe to any channel name
- Row-level changes broadcast to all subscribers on that table

**Review:** Sensitive data should use Realtime with Row Level Security or private channels.

### 3.3 Storage Bucket Permissions
Supabase Storage has its own RLS-like policies:
```sql
-- ❌ Public bucket = anyone can read
-- ✅ Private bucket with policies = access controlled
create policy "Users can upload to own folder"
on storage.objects for insert
with check (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = (select auth.uid())::text
);
```
**Review:** Every storage bucket must have explicit policies. Public buckets should only contain truly public assets.

## 4. Database-Level Attacks

### 4.1 Missing Indexes on RLS Columns
RLS policies add WHERE clauses to every query. Without indexes:
- `auth.uid() = user_id` scans full table on every request
- Performance degrades → potential DoS

**Review:** Every column used in an RLS policy must be indexed.
```sql
create index idx_user_id on my_table (user_id);
```

### 4.2 Function Call Performance in Policies
```sql
-- ❌ SLOW: auth.uid() called for every row
using (auth.uid() = user_id)

-- ✅ FAST: cached per-statement via initPlan
using ((select auth.uid()) = user_id)
```
Performance difference: 99%+ improvement on large tables (see Supabase benchmarks).

### 4.3 Missing CHECK Constraints
```sql
-- Financial data without constraints
-- ❌ Allows negative balances via race conditions
ALTER TABLE accounts ADD CONSTRAINT balance_non_negative CHECK (balance >= 0);
```

### 4.4 Trigger-Based Bypasses
Triggers run as the trigger owner, potentially bypassing RLS:
- `AFTER INSERT` triggers can modify data without RLS checks
- Be cautious with triggers that copy/move data between tables

## 5. Edge Function Vulnerabilities

### 5.1 No Auth by Default
Supabase Edge Functions don't check auth automatically:
```ts
// ❌ No auth check
Deno.serve(async (req) => {
  const { data } = JSON.parse(await req.text())
  // Anyone can call this
})

// ✅ Auth check
Deno.serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  const supabase = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader! } }
  })
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return new Response('Unauthorized', { status: 401 })
})
```

### 5.2 Secret Exposure
Edge Function logs may contain secrets if `console.log` is used carelessly.
Environment secrets should be set via Supabase Dashboard, not hardcoded.

## 6. Realtime Channel Security

### 6.1 How Realtime Authorization Works
Supabase Realtime now supports authorization via RLS on the `realtime.messages` table (Public Beta, supabase-js v2.44.0+).

**Key concepts:**
- RLS policies on `realtime.messages` control Broadcast and Presence access
- Use `realtime.topic()` helper to match channel names in policies
- Channels must be created with `{ config: { private: true } }` for RLS enforcement
- **Must disable "Allow public access" in Realtime Settings** for private channels to work
- Authorization is evaluated at connection time, then cached until JWT refresh

### 6.2 Channel Name Enumeration
**Risk:** Can users discover channels they shouldn't see?
- Channel names are not secret — anyone who knows the name can attempt to subscribe
- Private channels (`private: true`) reject unauthorized subscriptions via RLS
- **But:** if `private: true` is not set, ANY channel is accessible to any authenticated user

**Review check:** Every `supabase.channel()` call that handles sensitive data must use `{ config: { private: true } }`

### 6.3 Message Injection via Realtime
**Risk:** Can a user broadcast fake messages to a spectator channel?
- With proper RLS: users need INSERT policy to broadcast
- Spectator channels should have SELECT policy only (read) — no INSERT policy = no write
- **Without RLS or without `private: true`:** Any authenticated user can broadcast to any channel

```sql
-- Spectator read-only policy (no write = no injection)
CREATE POLICY "spectators_read_challenge_broadcasts" ON "realtime"."messages"
FOR SELECT TO authenticated
USING (
  realtime.messages.extension = 'broadcast'
  AND (select realtime.topic()) LIKE 'challenge:%:spectate'
  -- Optionally: restrict to users who are registered spectators
);
-- NO INSERT policy = spectators cannot broadcast
```

### 6.4 Presence Tracking Abuse
**Risk:** Tracking which users are online and which challenges they're watching.
- Presence data shows who's in a channel
- If spectator channels have Presence enabled, anyone in the channel sees who else is watching
- **For competitive integrity:** Disable Presence on spectator channels (or limit to authenticated participants)

### 6.5 Broadcast vs Postgres Changes Security
**Important distinction:**
- **Broadcast:** Messages go through Realtime — authorized by `realtime.messages` RLS
- **Postgres Changes:** Database changes streamed via WAL — authorized by TABLE-level RLS, not `realtime.messages`
- The `private: true` option does NOT apply to Postgres Changes
- **Review check:** If using Postgres Changes for sensitive data, ensure the TABLE has proper RLS, not just the Realtime channel

### 6.6 Connection Limits
- Supabase has connection limits per project (varies by plan)
- No built-in per-user Realtime connection limit
- A malicious user could open many channel subscriptions to exhaust project limits

**Mitigation:** Track Realtime connections per user in application code. Limit to N channels per user.

### 6.7 JWT Expiry and Realtime
- Realtime caches user permissions when they connect
- If JWT expires and no new JWT is sent, the client is disconnected
- **Risk:** If JWT has long expiry, cached permissions may be stale (user removed from room but still has access until JWT refreshes)
- **Mitigation:** Keep JWT expiry short (1 hour). Client libraries auto-refresh.

---

## Quick Reference — Code Review Checks

| Vector | How to Spot | Severity |
|--------|-------------|----------|
| RLS disabled | `ALTER TABLE` without `ENABLE ROW LEVEL SECURITY` | P0 |
| Service role in client | `NEXT_PUBLIC_.*SERVICE_ROLE` | P0 |
| `getSession()` on server | Any server file using `getSession()` | P0 |
| `user_metadata` in RLS | `auth.jwt()->'user_metadata'` in policies | P0 |
| `USING (true)` on sensitive table | Overly permissive SELECT policy | P1 |
| No index on RLS column | `user_id` without btree index | P2 |
| `auth.uid()` without `select` wrapper | Performance issue | P2 |
| View without `security_invoker` | View bypasses RLS | P1 |
| Storage bucket without policies | Public file access | P1 |
| Edge Function without auth | Unauthenticated endpoint | P1 |

## Sources
- Supabase RLS Documentation
- Supabase Server-Side Auth (Next.js) — `@supabase/ssr`
- Supabase RLS Performance Benchmarks
- PostgREST Documentation
- OWASP Broken Access Control (A01)

## Changelog
- 2026-03-20: Initial skill — Supabase-specific attack vectors documented
