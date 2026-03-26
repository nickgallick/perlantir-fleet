---
name: error-handling-review
description: Error handling patterns and anti-patterns — catching silent failures, inconsistent error shapes, missing error boundaries, and logging hygiene.
---

# Error Handling Review

## Quick Reference — Top 10 Error Handling Red Flags

1. [ ] **Empty catch block** — `catch(e) {}` silently swallows errors
2. [ ] **Generic error message** — `"Something went wrong"` with no context logged
3. [ ] **Missing `.error` check on Supabase** — Supabase doesn't throw by default
4. [ ] **No error boundary** in React — one crash takes down the whole page
5. [ ] **Sensitive data in error responses** — stack traces, SQL queries, file paths sent to client
6. [ ] **Unhandled promise rejection** — `async` function without try/catch or .catch()
7. [ ] **Catching too broadly** — 50 lines in one try/catch
8. [ ] **Using exceptions for control flow** — throwing NotFoundError instead of returning null
9. [ ] **Missing retry logic** on network operations
10. [ ] **Logging passwords, tokens, or PII**

---

## Error Handling Anti-Patterns

### Silent Swallowing
```ts
// ❌ Error disappears — bugs become invisible
try {
  await saveData(input)
} catch (e) {} // silent failure

// ❌ Log and continue — user thinks it worked
try {
  await saveData(input)
} catch (e) {
  console.error(e) // logged but user sees "success"
}

// ✅ Handle meaningfully
try {
  await saveData(input)
} catch (e) {
  console.error('[saveData] Failed:', { input: sanitize(input), error: e })
  return { success: false, error: 'Failed to save. Please try again.' }
}
```

### Supabase Error Handling (CRITICAL — most common mistake)
```ts
// ❌ Supabase does NOT throw on errors — this silently uses null data
const { data } = await supabase.from('users').select('*').eq('id', userId).single()
// If user doesn't exist: data is null, no error thrown, code continues

// ✅ Always destructure and check error
const { data, error } = await supabase.from('users').select('*').eq('id', userId).single()
if (error) {
  console.error('[getUser]', error.code, error.message)
  return { success: false, error: 'User not found' }
}
if (!data) {
  return { success: false, error: 'User not found' }
}
// data is now safely typed as non-null
```
**Rule:** Every Supabase call must destructure `{ data, error }` and check `error`. This is the #1 most common error handling mistake in our stack.

### Overly Broad Try/Catch
```ts
// ❌ Which line failed? No idea.
try {
  const user = await getUser(id)
  const orders = await getOrders(user.id)
  const processed = processOrders(orders)
  await saveReport(processed)
  await sendEmail(user.email, processed)
} catch (e) {
  return { error: 'Something went wrong' }
}

// ✅ Targeted error handling
const user = await getUser(id)
if (!user) return { error: 'User not found' }

const { data: orders, error: orderError } = await getOrders(user.id)
if (orderError) return { error: 'Failed to load orders' }

const processed = processOrders(orders)

const { error: saveError } = await saveReport(processed)
if (saveError) return { error: 'Failed to save report' }

// Email is non-critical — log but don't fail
try {
  await sendEmail(user.email, processed)
} catch (e) {
  console.warn('[sendEmail] Non-critical failure:', e)
  // Continue — report is saved, email can be retried
}
```

---

## Correct Error Patterns

### Custom Error Classes
```ts
// lib/errors.ts
export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500,
    public details?: unknown
  ) {
    super(message)
    this.name = 'AppError'
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', 404)
  }
}

export class ValidationError extends AppError {
  constructor(details: unknown) {
    super('Validation failed', 'VALIDATION_ERROR', 400, details)
  }
}

export class AuthError extends AppError {
  constructor(message = 'Authentication required') {
    super(message, 'AUTH_ERROR', 401)
  }
}
```

### Consistent API Error Responses
```ts
// lib/api-response.ts
export function errorResponse(error: unknown): NextResponse {
  if (error instanceof AppError) {
    return NextResponse.json(
      { error: { code: error.code, message: error.message, details: error.details } },
      { status: error.statusCode }
    )
  }
  
  // Unknown error — log full details, return generic message
  console.error('[API] Unexpected error:', error)
  return NextResponse.json(
    { error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } },
    { status: 500 }
  )
}
```

### Server Action Error Handling
```ts
// ❌ Throwing in Server Actions crashes the UI
'use server'
export async function createItem(formData: FormData) {
  throw new Error('Something broke') // unhandled on client
}

// ✅ Return error state
'use server'
export async function createItem(formData: FormData) {
  const parsed = ItemSchema.safeParse(Object.fromEntries(formData))
  if (!parsed.success) {
    return { success: false as const, error: parsed.error.flatten() }
  }
  
  const { error } = await supabase.from('items').insert(parsed.data)
  if (error) {
    console.error('[createItem]', error)
    return { success: false as const, error: 'Failed to create item' }
  }
  
  revalidatePath('/items')
  return { success: true as const }
}
```

### React Error Boundaries
```tsx
// ❌ No error boundary — one crash kills the whole page
export default function DashboardPage() {
  return (
    <div>
      <CriticalWidget />    {/* if this crashes... */}
      <NonCriticalWidget /> {/* ...this disappears too */}
    </div>
  )
}

// ✅ Error boundary isolates failures
export default function DashboardPage() {
  return (
    <div>
      <CriticalWidget />
      <ErrorBoundary fallback={<p>Widget unavailable</p>}>
        <NonCriticalWidget />
      </ErrorBoundary>
    </div>
  )
}

// Next.js App Router: error.tsx acts as an error boundary
// app/dashboard/error.tsx
'use client'
export default function DashboardError({ error, reset }) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  )
}
```

---

## Logging Hygiene

### Never Log
- Passwords (even hashed)
- API keys, tokens, secrets
- Full credit card numbers (log last 4 only)
- Personal data subject to GDPR/CCPA (email, phone, address)
- Full request bodies that may contain sensitive fields

### Always Log
- Error code and message
- Which function/route the error occurred in
- User ID (not PII) for tracing
- Request ID for correlation
- Timestamp (automatic with structured logging)

### Structured Format
```ts
// ❌ Unstructured — hard to search, parse, or alert on
console.error('Error in createOrder for user ' + userId + ': ' + error.message)

// ✅ Structured JSON — searchable, parseable, alertable
console.error(JSON.stringify({
  level: 'error',
  function: 'createOrder',
  userId,
  error: error.message,
  code: error.code,
  timestamp: new Date().toISOString()
}))
```

## Sources
- Next.js Error Handling documentation (error.tsx, loading.tsx)
- Supabase client library error handling patterns
- Clean Code (Robert C. Martin) — Chapter 7: Error Handling

## Changelog
- 2026-03-21: Initial skill — error handling review
