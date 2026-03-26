# API Design — Forge Skill

## Overview

API routes are the contract between frontend and backend. Consistency, validation, and proper error handling are non-negotiable.

## Route Structure

### Next.js App Router Convention

```
app/
  api/
    users/
      route.ts          # GET /api/users, POST /api/users
      [id]/
        route.ts        # GET /api/users/:id, PATCH /api/users/:id, DELETE /api/users/:id
    posts/
      route.ts
      [id]/
        route.ts
        comments/
          route.ts      # GET /api/posts/:id/comments
```

### Naming Rules

- Use plural nouns for resources: `/api/users` not `/api/user`
- Use nested routes for relationships: `/api/posts/:id/comments`
- Use query parameters for filtering: `/api/users?role=admin&status=active`
- Avoid verbs in URLs: `/api/users` with POST, not `/api/createUser`
- Use kebab-case for multi-word resources: `/api/blog-posts`

## Request Validation

### Every API Route Must Validate Input

```typescript
import { z } from 'zod';
import { NextRequest, NextResponse } from 'next/server';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin']).default('user'),
});

export async function POST(request: NextRequest) {
  const body = await request.json();
  const result = CreateUserSchema.safeParse(body);

  if (!result.success) {
    return NextResponse.json(
      { error: { code: 'VALIDATION_ERROR', details: result.error.flatten() } },
      { status: 400 }
    );
  }

  // result.data is validated and typed
  const user = await createUser(result.data);
  return NextResponse.json({ data: user }, { status: 201 });
}
```

### Validate Path Parameters

```typescript
const ParamsSchema = z.object({
  id: z.string().uuid(),
});

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const result = ParamsSchema.safeParse(params);
  if (!result.success) {
    return NextResponse.json(
      { error: { code: 'INVALID_PARAMS', message: 'Invalid ID format' } },
      { status: 400 }
    );
  }
  // ...
}
```

### Validate Query Parameters

```typescript
const QuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  sort: z.enum(['created_at', 'name', 'updated_at']).default('created_at'),
  order: z.enum(['asc', 'desc']).default('desc'),
});
```

## Response Standards

### Consistent Response Format

```typescript
// Success response
{
  "data": { ... } | [...],
  "meta": {  // Optional, for paginated responses
    "page": 1,
    "limit": 20,
    "total": 150
  }
}

// Error response
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User not found",
    "details": { ... }  // Optional, for validation errors
  }
}
```

### HTTP Status Codes

| Status | When to Use |
|--------|-------------|
| 200 | Successful GET, PATCH, DELETE |
| 201 | Successful POST (resource created) |
| 204 | Successful DELETE (no content to return) |
| 400 | Validation error, malformed request |
| 401 | Not authenticated |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 409 | Conflict (duplicate, state conflict) |
| 422 | Valid JSON but semantically invalid |
| 429 | Rate limited |
| 500 | Unexpected server error |

### Never Return 200 for Errors

```typescript
// BAD
return NextResponse.json({ success: false, error: 'Not found' }, { status: 200 });

// GOOD
return NextResponse.json({ error: { code: 'NOT_FOUND', message: 'User not found' } }, { status: 404 });
```

## Error Handling

### Catch All Errors

```typescript
export async function GET(request: NextRequest) {
  try {
    // ... route logic
  } catch (error) {
    console.error('GET /api/users failed:', error);

    // Don't expose internal errors to clients
    return NextResponse.json(
      { error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } },
      { status: 500 }
    );
  }
}
```

### Custom Error Classes

```typescript
class AppError extends Error {
  constructor(
    public code: string,
    public statusCode: number,
    message: string,
    public details?: unknown
  ) {
    super(message);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super('NOT_FOUND', 404, `${resource} with id ${id} not found`);
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'You do not have permission to perform this action') {
    super('FORBIDDEN', 403, message);
  }
}
```

## Rate Limiting

### Implementation

```typescript
// Use middleware or per-route rate limiting
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
  analytics: true,
});

export async function POST(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') ?? '127.0.0.1';
  const { success, limit, reset, remaining } = await ratelimit.limit(ip);

  if (!success) {
    return NextResponse.json(
      { error: { code: 'RATE_LIMITED', message: 'Too many requests' } },
      {
        status: 429,
        headers: {
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Reset': reset.toString(),
          'Retry-After': Math.ceil((reset - Date.now()) / 1000).toString(),
        },
      }
    );
  }

  // ... route logic
}
```

### Rate Limit Tiers

| Endpoint Type | Rate Limit |
|---------------|-----------|
| Auth (login, register, reset) | 5 requests / minute |
| Write operations (POST, PATCH, DELETE) | 30 requests / minute |
| Read operations (GET) | 100 requests / minute |
| File uploads | 10 requests / minute |
| Search / expensive queries | 20 requests / minute |

## Auth in API Routes

### Always Verify Auth

```typescript
export async function GET(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    return NextResponse.json(
      { error: { code: 'UNAUTHORIZED', message: 'Authentication required' } },
      { status: 401 }
    );
  }

  // Use user.id for queries, never trust client-provided user IDs
  const { data } = await supabase
    .from('posts')
    .select('*')
    .eq('author_id', user.id);

  return NextResponse.json({ data });
}
```

## Review Checklist

- [ ] Input validated with Zod (body, params, query)
- [ ] Consistent response format (`data` / `error`)
- [ ] Correct HTTP status codes
- [ ] Auth check on protected routes
- [ ] Error handling with no internal details leaked
- [ ] Rate limiting on write/auth endpoints
- [ ] No business logic in route handler (delegate to services)
- [ ] Proper HTTP methods used (GET for reads, POST for creates, etc.)

## Review Severity

| Issue | Severity |
|-------|----------|
| No auth check on protected route | P0 — BLOCKED |
| No input validation | P1 — High |
| Internal errors exposed to client | P1 — High |
| Inconsistent response format | P2 — Medium |
| Missing rate limiting on auth | P1 — High |
| Wrong HTTP status codes | P2 — Medium |
| Business logic in route handler | P3 — Low |
