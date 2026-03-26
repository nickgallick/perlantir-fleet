# Supabase Patterns — Forge Skill

## Overview

Supabase is our backend platform (PostgreSQL, Auth, Edge Functions, Realtime, Storage). Correct usage of Supabase patterns — especially RLS — is critical to application security.

## Auth Patterns

### Server-Side Auth (Next.js)

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          );
        },
      },
    }
  );
}
```

### Client-Side Auth

```typescript
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

### Auth Guards

```typescript
// middleware.ts — protect routes
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  // Create supabase client with request/response cookie handling
  const supabase = createServerClient(/* ... */);

  const { data: { user } } = await supabase.auth.getUser();

  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}
```

### Anti-Patterns

- **Never** use `getSession()` alone for auth checks — it reads from the JWT without validation. Use `getUser()` which validates with the auth server.
- **Never** trust client-provided user IDs — always use `auth.uid()` in RLS policies and server-side code.
- **Never** expose the service role key to the client.

## RLS — Critical Section

**Every table MUST have RLS enabled.** This is non-negotiable.

### Enabling RLS

```sql
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
```

### Policy Patterns

```sql
-- Users can read their own data
CREATE POLICY "Users read own data"
  ON profiles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own data
CREATE POLICY "Users insert own data"
  ON posts
  FOR INSERT
  WITH CHECK (auth.uid() = author_id);

-- Users can update their own data
CREATE POLICY "Users update own data"
  ON posts
  FOR UPDATE
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

-- Users can delete their own data
CREATE POLICY "Users delete own data"
  ON posts
  FOR DELETE
  USING (auth.uid() = author_id);

-- Public read access (intentional)
CREATE POLICY "Public read access"
  ON public_posts
  FOR SELECT
  USING (true);  -- Only acceptable when data is intentionally public
```

### RLS Review Checklist

- [ ] RLS enabled on the table
- [ ] Policies exist for every operation the app performs (SELECT, INSERT, UPDATE, DELETE)
- [ ] Policies use `auth.uid()`, not client-provided values
- [ ] `USING` clause for read/update/delete operations
- [ ] `WITH CHECK` clause for insert/update operations
- [ ] No overly permissive policies (`USING (true)`) without documented justification
- [ ] Foreign key chains don't create access bypasses
- [ ] Service role bypass only used in trusted server-side code

## Realtime

### Subscription Patterns

```typescript
// GOOD — subscribe with proper cleanup
useEffect(() => {
  const channel = supabase
    .channel('posts-changes')
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'posts' },
      (payload) => {
        // Handle change
      }
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}, [supabase]);
```

### Realtime Checklist

- [ ] Channels cleaned up on unmount (memory leak prevention)
- [ ] Subscriptions filtered to relevant data (not subscribing to entire tables)
- [ ] RLS policies apply to realtime (check publication settings)
- [ ] Error handling for subscription failures
- [ ] Reconnection logic for dropped connections

## Edge Functions

### Best Practices

```typescript
// supabase/functions/my-function/index.ts
import { serve } from 'https://deno.land/std/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js';

serve(async (req) => {
  // CORS headers
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  // Auth check
  const authHeader = req.headers.get('Authorization');
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader! } } }
  );

  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
    });
  }

  // Function logic here...
});
```

### Edge Function Checklist

- [ ] Auth validation at the start
- [ ] CORS headers for browser access
- [ ] Input validation (Zod recommended)
- [ ] Error handling with appropriate status codes
- [ ] Secrets via `Deno.env.get()`, not hardcoded
- [ ] Response format consistent with API standards

## Storage

### Secure File Uploads

```typescript
// Upload with auth
const { data, error } = await supabase.storage
  .from('avatars')
  .upload(`${user.id}/avatar.png`, file, {
    upsert: true,
    contentType: 'image/png',
  });
```

### Storage Checklist

- [ ] Bucket policies restrict access appropriately
- [ ] File paths include user ID to prevent collisions and enforce ownership
- [ ] File type validation (don't trust client-provided content types)
- [ ] File size limits enforced
- [ ] Public buckets only for intentionally public content
- [ ] Signed URLs used for private content with expiration

## Common Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| RLS not enabled on new table | Full data exposure | Enable RLS immediately |
| Using `getSession()` for auth checks | Session can be spoofed from JWT | Use `getUser()` instead |
| Service role key in client code | Full database access bypass | Move to server-side only |
| Missing Realtime cleanup | Memory leaks, stale subscriptions | Add cleanup in `useEffect` return |
| No file type validation on upload | Malicious file upload | Validate MIME type server-side |
| Overly broad RLS policy | Data accessible to wrong users | Scope policies to `auth.uid()` |

## Review Severity

| Issue | Severity |
|-------|----------|
| Missing RLS on table | P0 — BLOCKED |
| Service role key client-side | P0 — BLOCKED |
| `getSession()` for auth validation | P1 — High |
| Missing Realtime cleanup | P1 — High |
| Overly permissive storage policy | P1 — High |
| Missing Edge Function auth check | P1 — High |
| No file type validation | P2 — Medium |
| Missing CORS on Edge Function | P2 — Medium |
