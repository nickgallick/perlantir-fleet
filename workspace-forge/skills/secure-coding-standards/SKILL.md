---
name: secure-coding-standards
description: The definitive secure coding reference for our Next.js + Supabase + TypeScript stack — the ONE document that, if followed, produces secure code on first write. Use when Maks needs a reference for how to write secure code, when onboarding new developers, when creating coding guidelines, or when establishing the "one right way" for common security-sensitive patterns. Not "here's what's wrong" but "here's exactly how to write it correctly." Every pattern is copy-pasteable and production-ready.
---

# Secure Coding Standards

## Purpose

This is the single reference document for writing secure code in our stack. If Maks follows these patterns exactly, the code will pass Forge's review on the first try. Every pattern is the CORRECT way — not one of several options, but THE way.

## Standard 1: Authentication

### Server-Side Auth Check (The Only Correct Pattern)
```typescript
// lib/auth.ts — ONE function, used everywhere
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function getAuthUser() {
  const cookieStore = await cookies()
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { getAll: () => cookieStore.getAll(), setAll: (c) => { c.forEach(({ name, value, options }) => cookieStore.set(name, value, options)) } } }
  )
  
  // ALWAYS getUser(), NEVER getSession()
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) return null
  return user
}

// Usage in any Server Action or API route:
const user = await getAuthUser()
if (!user) return new Response('Unauthorized', { status: 401 })
```

**Rules**:
- Use `getUser()` not `getSession()` — always
- Create ONE auth helper — import it everywhere
- Never trust client-side auth state for server decisions

### Server Action Auth Pattern
```typescript
"use server"

export async function updateProfile(formData: FormData) {
  // Line 1: ALWAYS auth check
  const user = await getAuthUser()
  if (!user) throw new Error('Unauthorized')
  
  // Line 2: ALWAYS input validation
  const input = UpdateProfileSchema.safeParse({
    name: formData.get('name'),
    bio: formData.get('bio'),
  })
  if (!input.success) throw new Error('Invalid input')
  
  // Line 3: Business logic with user.id — never from client
  const { error } = await supabase
    .from('profiles')
    .update(input.data)
    .eq('user_id', user.id)  // DERIVED from auth, not from input
  
  if (error) {
    console.error('Profile update failed:', error)
    throw new Error('Update failed')
  }
  
  revalidatePath('/profile')
}
```

## Standard 2: Input Validation

### Every Input Gets a Zod Schema
```typescript
// schemas/challenge.ts
import { z } from 'zod'

export const CreateChallengeSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  description: z.string().min(10).max(5000).trim(),
  maxEntries: z.number().int().positive().max(1000),
  deadline: z.string().datetime().refine(
    (d) => new Date(d) > new Date(),
    'Deadline must be in the future'
  ),
  entryFee: z.number().nonnegative().max(10000).multipleOf(0.01),
  categoryId: z.string().uuid(),
})

// NEVER accept without validation
export const IdParamSchema = z.object({
  id: z.string().uuid(),
})
```

**Rules**:
- Every API route and Server Action validates input with Zod
- Use `.uuid()` for all IDs — never accept bare strings
- Use `.trim()` on all text inputs
- Use `.positive()`, `.nonnegative()`, `.max()` on all numbers
- Use `.datetime()` on all date inputs
- Monetary values: use `.multipleOf(0.01)` or work in cents (integers)

### Validated API Route Pattern
```typescript
export async function POST(request: Request) {
  const user = await getAuthUser()
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 })
  
  let body: unknown
  try {
    body = await request.json()
  } catch {
    return Response.json({ error: 'Invalid JSON' }, { status: 400 })
  }
  
  const input = CreateChallengeSchema.safeParse(body)
  if (!input.success) {
    return Response.json({ error: 'Validation failed', details: input.error.flatten() }, { status: 400 })
  }
  
  // input.data is now fully typed and validated
  const result = await createChallenge(user.id, input.data)
  return Response.json(result, { status: 201 })
}
```

## Standard 3: Database Queries

### Parameterized Queries (Always)
```typescript
// CORRECT — Supabase client handles parameterization
const { data } = await supabase
  .from('challenges')
  .select('id, title, description')
  .eq('category_id', categoryId)
  .order('created_at', { ascending: false })
  .range(0, 19)

// CORRECT — RPC with parameters
const { data } = await supabase.rpc('get_leaderboard', {
  challenge_id: challengeId,
  limit_count: 50,
})

// NEVER — string interpolation in SQL
const { data } = await supabase.rpc('custom_query', {
  query: `SELECT * FROM users WHERE name = '${userName}'`  // SQL INJECTION
})
```

### Select Only What You Need
```typescript
// WRONG — select everything
const { data } = await supabase.from('users').select('*')

// CORRECT — select specific columns
const { data } = await supabase
  .from('users')
  .select('id, display_name, avatar_url')
  // Never select: password_hash, email (unless needed), internal fields
```

### Always Paginate
```typescript
// WRONG — unbounded query
const { data } = await supabase.from('entries').select('*')

// CORRECT — always use range
const { data } = await supabase
  .from('entries')
  .select('id, title, score')
  .range(page * pageSize, (page + 1) * pageSize - 1)
```

## Standard 4: Error Handling

### The One Correct Pattern
```typescript
// lib/errors.ts
export function apiError(message: string, status: number = 500) {
  // Log the real error server-side
  // Return generic message to client
  return Response.json({ error: message }, { status })
}

// In API routes:
try {
  const result = await riskyOperation()
  if (result.error) {
    console.error('Operation failed:', result.error)  // Full error to logs
    return apiError('Operation failed', 500)            // Generic to client
  }
  return Response.json(result.data)
} catch (err) {
  console.error('Unexpected error:', err)
  return apiError('Internal server error', 500)
}
```

**Rules**:
- Never return `error.message` or `error.stack` to client
- Never return Supabase error objects to client
- Log full errors server-side
- Return consistent `{ error: string }` shape to client

## Standard 5: Environment Variables

### Naming Convention
```bash
# Server-only (no prefix) — NEVER expose to client
SUPABASE_SERVICE_ROLE_KEY=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
ANTHROPIC_API_KEY=...
DATABASE_URL=...

# Client-safe (NEXT_PUBLIC_ prefix) — intentionally exposed
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=...
NEXT_PUBLIC_APP_URL=...
```

**Rules**:
- If it's a SECRET (keys, passwords, connection strings): NO `NEXT_PUBLIC_` prefix
- Validate ALL env vars at startup with Zod (fail fast):
```typescript
const envSchema = z.object({
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(20),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_'),
})
export const env = envSchema.parse(process.env)
```

## Standard 6: External Requests

### Fetching User-Provided URLs (SSRF Prevention)
```typescript
// NEVER fetch user-provided URLs without validation
// See ssrf-exploitation skill for full validation

// If you MUST fetch external URLs:
async function safeFetch(url: string): Promise<Response> {
  const parsed = new URL(url)
  if (!['https:'].includes(parsed.protocol)) throw new Error('HTTPS only')
  if (isInternalIP(parsed.hostname)) throw new Error('Internal IP blocked')
  
  return fetch(url, {
    redirect: 'manual',           // Don't follow redirects
    signal: AbortSignal.timeout(5000),  // 5 second timeout
  })
}
```

### Webhook Verification (Always)
```typescript
// Stripe webhooks — verify BEFORE parsing
const body = await request.text()
const sig = request.headers.get('stripe-signature')!
const event = stripe.webhooks.constructEvent(body, sig, webhookSecret)
// Only NOW is event trustworthy
```

## Standard 7: File Uploads

```typescript
// Validate file type by magic bytes, not extension
const ALLOWED_TYPES = {
  'image/jpeg': [0xFF, 0xD8, 0xFF],
  'image/png': [0x89, 0x50, 0x4E, 0x47],
  'image/webp': [0x52, 0x49, 0x46, 0x46],
  'application/pdf': [0x25, 0x50, 0x44, 0x46],
}

async function validateFile(file: File): Promise<boolean> {
  if (file.size > 10 * 1024 * 1024) return false  // 10MB max
  
  const buffer = await file.slice(0, 4).arrayBuffer()
  const bytes = new Uint8Array(buffer)
  
  for (const [type, magic] of Object.entries(ALLOWED_TYPES)) {
    if (magic.every((b, i) => bytes[i] === b)) return true
  }
  return false
}
```

## Standard 8: Logging

### What to Log
```typescript
// Security events — ALWAYS log
console.log(JSON.stringify({
  event: 'login_attempt',
  userId: user?.id,
  ip: request.headers.get('x-forwarded-for'),
  success: true,
  timestamp: new Date().toISOString(),
}))
```

### What NEVER to Log
```typescript
// NEVER log any of these:
// - Passwords or password hashes
// - Full credit card numbers
// - API keys or secrets
// - JWT tokens
// - PII beyond what's needed (full SSN, etc.)
// - Request bodies that might contain sensitive data
// - Authorization headers
```

## Standard 9: RLS (Every Table)

```sql
-- Template for EVERY new table:
CREATE TABLE new_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  -- ... columns ...
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ALWAYS enable RLS
ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;

-- ALWAYS create all four policies
CREATE POLICY "select_own" ON new_table FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "insert_own" ON new_table FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "update_own" ON new_table FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "delete_own" ON new_table FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ALWAYS index the policy column
CREATE INDEX idx_new_table_user_id ON new_table(user_id);
```

## Standard 10: Dependencies

### Before Adding Any Dependency
1. Check npm audit: `npm audit`
2. Check download count and maintenance status
3. Check for known CVEs
4. Check if it needs postinstall scripts
5. Pin to exact version in package.json (no `^` for security-sensitive packages)

### Regular Maintenance
```bash
# Weekly
npm audit
npm outdated

# Before every deploy
npm audit --audit-level=high
# If high/critical: fix before deploying
```

## Quick Reference Card

| Operation | Correct Pattern |
|-----------|----------------|
| Auth check | `getUser()` not `getSession()` |
| Input validation | Zod schema, every endpoint |
| Database IDs | `.uuid()` validation |
| User scoping | `user.id` from auth, never from input |
| Error responses | Generic message, log full error |
| Secrets | No `NEXT_PUBLIC_` on anything secret |
| External fetch | Validate URL, no redirects, timeout |
| Webhooks | Verify signature FIRST |
| File uploads | Magic bytes, not extension |
| New table | RLS + 4 policies + index |
| Pagination | Always `.range()`, never unbounded |
| Logging | Structured JSON, no secrets |

## References

For architecture patterns, see `secure-architecture-patterns` skill.
For specific vulnerability patterns, see the relevant security skills.
