---
name: error-handling-infodisclosure
description: Detection of information disclosure through error handling, stack traces, verbose error messages, debug endpoints, and response metadata leakage. Use when reviewing error handling patterns, API error response shapes, Next.js error boundaries, Supabase error forwarding, logging configuration, and any code that catches and returns errors to clients. Information disclosure is Step 1 in nearly every exploit chain — it provides the reconnaissance data attackers need to construct targeted attacks.
---

# Error Handling & Information Disclosure

## Why This Matters

Information disclosure is the **recon step in every exploit chain**. A verbose error message that leaks a database table name, a stack trace that reveals the file path, an API response that includes internal IDs — each piece helps the attacker construct the next step.

**From `exploit-chain-construction` skill**: the first link in most chains is an information leak that reveals what to attack next.

## Category 1: Stack Trace Leakage

### What Leaks
```
Error: relation "users_private" does not exist
    at /app/src/lib/supabase.ts:42:15
    at processTicksAndRejections (node:internal/process/task_queues:95:5)
    at async POST (/app/src/app/api/admin/users/route.ts:18:22)
```

This single error reveals:
- Database table name: `users_private`
- File structure: `/app/src/lib/supabase.ts`, `/app/src/app/api/admin/users/route.ts`
- Framework: Next.js App Router
- Node.js version: internal module path format
- Admin endpoint exists: `/api/admin/users`

### Detection in Code Review
```typescript
// VULNERABLE — raw error forwarded to client
export async function POST(request: Request) {
  try {
    const result = await supabase.from('users').insert(data)
    return Response.json(result)
  } catch (error) {
    return Response.json({ error: error.message, stack: error.stack }, { status: 500 })
    // Leaks everything
  }
}

// ALSO VULNERABLE — Supabase error forwarded directly
const { data, error } = await supabase.from('users').select()
if (error) {
  return Response.json({ error }, { status: 500 })
  // Supabase errors include SQL details, table names, constraint names
}
```

### Fix: Generic Client Errors, Detailed Server Logs
```typescript
export async function POST(request: Request) {
  try {
    const result = await supabase.from('users').insert(data)
    if (result.error) {
      console.error('Database error:', result.error)  // Detailed log
      return Response.json(
        { error: 'An error occurred. Please try again.' },  // Generic client message
        { status: 500 }
      )
    }
    return Response.json(result.data)
  } catch (error) {
    console.error('Unexpected error:', error)  // Full error to server logs
    return Response.json(
      { error: 'Internal server error' },  // Generic to client
      { status: 500 }
    )
  }
}
```

## Category 2: Supabase Error Forwarding

Supabase client errors contain rich information:
```json
{
  "code": "42P01",
  "details": null,
  "hint": null,
  "message": "relation \"public.admin_settings\" does not exist"
}
```

```json
{
  "code": "23505",
  "details": "Key (email)=(admin@example.com) already exists.",
  "hint": null,
  "message": "duplicate key value violates unique constraint \"users_email_key\""
}
```

This reveals: table names, column names, constraint names, actual data values, schema structure.

### Detection
- [ ] Search for `error` being returned directly from Supabase operations
- [ ] Check if any API route includes `.error` in the response
- [ ] Check Next.js error boundaries — do they render error details?

### Fix: Error Code Mapping
```typescript
function sanitizeSupabaseError(error: any): { message: string; code: string } {
  switch (error.code) {
    case '23505': return { message: 'This record already exists', code: 'DUPLICATE' }
    case '23503': return { message: 'Related record not found', code: 'NOT_FOUND' }
    case '42501': return { message: 'Permission denied', code: 'FORBIDDEN' }
    case '22P02': return { message: 'Invalid input format', code: 'INVALID_INPUT' }
    default: return { message: 'An error occurred', code: 'INTERNAL_ERROR' }
  }
}
```

## Category 3: Enumeration via Error Differences

### Username Enumeration
```typescript
// VULNERABLE — different errors reveal user existence
if (!user) return Response.json({ error: 'User not found' }, { status: 404 })
if (!validPassword) return Response.json({ error: 'Incorrect password' }, { status: 401 })
// Attacker: "User not found" = user doesn't exist. "Incorrect password" = user exists.

// SAFE — identical error regardless
if (!user || !validPassword) {
  return Response.json({ error: 'Invalid credentials' }, { status: 401 })
}
```

### Resource Enumeration via Status Codes
```typescript
// VULNERABLE
GET /api/documents/123 → 200 (exists, you have access)
GET /api/documents/456 → 403 (exists, no access)  // Reveals document exists!
GET /api/documents/789 → 404 (doesn't exist)

// SAFE — same response for "not found" and "no access"
GET /api/documents/456 → 404 (not found OR no access — attacker can't tell)
GET /api/documents/789 → 404 (same response)
```

### Timing-Based Enumeration
```typescript
// VULNERABLE — database lookup only if user exists
const user = await findUser(email)
if (!user) return error  // Fast response — no DB hit for bcrypt
const valid = await bcrypt.compare(password, user.hash)  // Slow response
// Timing difference reveals if email is registered

// SAFE — always do the same work
const user = await findUser(email)
const hash = user?.passwordHash || DUMMY_HASH
const valid = await bcrypt.compare(password, hash)  // Always runs bcrypt
if (!user || !valid) return { error: 'Invalid credentials' }
```

## Category 4: Debug Endpoints & Development Leaks

### Common Leaks in Production
- [ ] `/_next/data/` endpoints returning server-side props
- [ ] `/api/health` or `/api/status` returning version numbers, dependencies, uptime
- [ ] `/.env` or `/env.js` accidentally served as static files
- [ ] Source maps (`.map` files) in production build
- [ ] `/_next/static/` containing readable source
- [ ] GraphQL introspection enabled in production
- [ ] Swagger/OpenAPI docs at `/api/docs` in production

### Detection
```bash
# Check for source maps in production build
find .next -name '*.map' | head
# If present, add to next.config.js: productionBrowserSourceMaps: false

# Check for debug endpoints
curl -s https://your-app.com/api/health | jq
curl -s https://your-app.com/api/debug
curl -s https://your-app.com/_next/data/build-id/index.json
```

### Fix: next.config.js
```javascript
module.exports = {
  productionBrowserSourceMaps: false,
  poweredByHeader: false,
  // Disable GraphQL introspection in production
  // Restrict /_next/data to authenticated users if it contains sensitive data
}
```

## Category 5: Response Header Leakage

### Dangerous Headers
```
X-Powered-By: Next.js          // Framework identification
Server: nginx/1.24.0            // Server software + version
X-Request-Id: uuid-here         // Internal request tracking
X-Debug-Token: abc123            // Debug info
Via: 1.1 proxy-server-name      // Internal infrastructure
```

### Fix: Strip Unnecessary Headers
```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const response = NextResponse.next()
  response.headers.delete('X-Powered-By')
  response.headers.delete('Server')
  return response
}
```

## Category 6: Logging Sensitive Data

### What NOT to Log
```typescript
// DANGEROUS — logging credentials
console.log('Login attempt:', { email, password })  // Password in logs!
console.log('API request:', req.headers)  // Authorization header in logs!
console.log('Webhook payload:', JSON.stringify(event))  // Credit card data?

// SAFE — redact sensitive fields
console.log('Login attempt:', { email, password: '[REDACTED]' })
console.log('API request:', { method: req.method, path: req.url })
console.log('Webhook:', { type: event.type, id: event.id })
```

### Detection
- [ ] `console.log` in API routes — what data is being logged?
- [ ] Are passwords, tokens, API keys, or PII in log output?
- [ ] Are request/response bodies logged in production?
- [ ] Are error objects (which may contain user data) logged fully?

## Consistent Error Response Shape

### Standard Error Format
```typescript
type ApiError = {
  error: {
    code: string       // Machine-readable: 'VALIDATION_ERROR', 'NOT_FOUND', 'UNAUTHORIZED'
    message: string    // Human-readable but GENERIC
  }
}

// NEVER include in client responses:
// - Stack traces
// - SQL errors
// - File paths
// - Internal IDs that shouldn't be exposed
// - Specific field validation from database constraints
```

## Review Checklist

- [ ] No stack traces in any API response
- [ ] No Supabase/database errors forwarded to client
- [ ] Login/auth errors are identical for wrong username vs wrong password
- [ ] 403 vs 404 doesn't reveal resource existence (use 404 for both)
- [ ] No source maps in production
- [ ] No debug/status endpoints leaking version info
- [ ] `X-Powered-By` and `Server` headers removed
- [ ] No passwords, tokens, or PII in log output
- [ ] Error responses follow consistent shape
- [ ] Next.js error boundaries don't render error details in production

## References

For how information disclosure feeds into exploit chains, see `exploit-chain-construction` skill.
For secure logging patterns, see the production hardening skills.
