---
name: react-flight-security
description: Security hardening for React Server Components (RSC), React Flight protocol, and Next.js App Router against CVE-2025-55182 (React2Shell) and related deserialization attacks. Use when building, reviewing, or auditing any application using React Server Components, Next.js App Router, server actions, or the Flight protocol. Covers version verification, patch validation, server component boundary security, serialization attack surfaces, and HTTP request smuggling (CVE-2026-29057). Essential for any Next.js 13+ / React 19 application.
---

# React Flight Security

## Critical Vulnerabilities (Active Exploitation)

### CVE-2025-55182 — React2Shell (CRITICAL, CVSS 9.8)
**Status**: PoC public, active scanning in the wild as of March 2026

Unsafe deserialization in React's Flight protocol allows unauthenticated RCE on servers using React Server Components. Attackers send crafted payloads that, when processed by the server, execute arbitrary code.

**Affected packages**:
| Package | Vulnerable Versions |
|---------|-------------------|
| react-server-dom-parcel | 19.0, 19.1.0, 19.1.1, 19.2.0 |
| react-server-dom-turbopack | 19.0, 19.1.0, 19.1.1, 19.2.0 |
| react-server-dom-webpack | 19.0, 19.1.0, 19.1.1, 19.2.0 |
| Next.js | <15.0.5, <15.1.9, <15.2.6, <15.3.6, <15.4.8, <15.5.7, <16.0.7 |

**Patched versions**:
- react-server-dom-*: ≥19.0.1, ≥19.1.2, ≥19.2.1
- Next.js: ≥15.0.5, ≥15.1.9, ≥15.2.6, ≥15.3.6, ≥15.4.8, ≥15.5.7, ≥16.0.7

**Two additional vulnerabilities** found in the same RSC packages after initial React2Shell patch — upgrade to latest patched version, not just the first fix.

### CVE-2026-29057 — HTTP Request Smuggling in Next.js Rewrites (HIGH)
**Status**: Patched March 17, 2026

Crafted DELETE/OPTIONS requests with `Transfer-Encoding: chunked` through Next.js rewrites can cause request boundary disagreement between proxy and backend, enabling request smuggling.

**Affected**: Next.js using `rewrites()` to proxy external backends
**Patched**: Next.js ≥15.5.13 or ≥16.1.7

## Version Verification Procedure

### Step 1: Check current versions
```bash
# Check Next.js version
npx next --version
# or
cat node_modules/next/package.json | grep '"version"'

# Check react-server-dom packages
ls node_modules | grep react-server-dom
cat node_modules/react-server-dom-webpack/package.json | grep '"version"' 2>/dev/null

# Check React version
cat node_modules/react/package.json | grep '"version"'
```

### Step 2: Verify against patched versions
Compare output against the patched versions table above. Any version not meeting minimum = **BLOCKED** for deployment.

### Step 3: Upgrade if needed
```bash
# Upgrade Next.js (will pull patched React packages)
npm install next@latest

# Verify the upgrade
npm ls next react react-dom react-server-dom-webpack
```

## React Flight Protocol — Attack Surface

### What Is the Flight Protocol?
React Flight is the wire protocol for streaming React Server Component trees from server to client. It serializes:
- Component references
- Props (including functions via Server Actions)
- Promises and async data
- Error boundaries

### Why It's Dangerous
The Flight protocol deserializes server component payloads. Pre-patch, this deserialization was **unsafe by default** — no validation of payload structure, no allowlisting of deserializable types. An attacker who can send a crafted HTTP request to an RSC endpoint can inject a payload that deserializes into executable code.

### Attack Vector
```
Attacker → crafted HTTP POST to RSC endpoint → Flight deserializer → code execution on server
```

No authentication required. Default configuration is vulnerable. Any publicly reachable Next.js App Router app with RSC is a target.

## Server Component Security Checklist

### Boundary Security
- [ ] **Server components never accept raw user input as props from the client** without validation
- [ ] **Server actions validate all input** with Zod or equivalent before processing
- [ ] **`"use server"` directive** only on files that truly need it — minimize server action surface area
- [ ] **No `dangerouslySetInnerHTML`** in server components (XSS via SSR)
- [ ] **taintObjectReference / taintUniqueValue** used to prevent sensitive data from crossing to client

### Data Flow Security
- [ ] **Server components do not pass secrets, tokens, or connection strings** as props
- [ ] **Database queries in server components use parameterized queries** (never string interpolation)
- [ ] **Server actions that mutate data verify auth** — `getUser()` or `getClaims()` on every call
- [ ] **Revalidation calls (`revalidatePath`, `revalidateTag`)** are auth-gated
- [ ] **redirect()** calls use validated URLs, not user-provided paths

### RSC Endpoint Hardening
- [ ] **Rate limit RSC endpoints** — Flight requests should be rate-limited like any API
- [ ] **WAF rules for Flight payload inspection** — monitor for unusually large or malformed payloads
- [ ] **Log Flight protocol errors** — deserialization failures may indicate attack probing
- [ ] **CSP headers** include appropriate `connect-src` directives

### Next.js Rewrites Security (CVE-2026-29057)
- [ ] **Avoid proxying external backends through rewrites** when possible — use API routes instead
- [ ] **If rewrites are necessary**, ensure backend validates `Transfer-Encoding` properly
- [ ] **Monitor for unusual DELETE/OPTIONS requests** to rewritten paths
- [ ] **Upgrade to Next.js ≥15.5.13 / ≥16.1.7** to patch request smuggling

## Server Actions Hardening

Server Actions are the primary way clients invoke server-side code in App Router. Each action is an RPC endpoint.

### Input Validation (every action, no exceptions)
```typescript
"use server"

import { z } from "zod"

const UpdateProfileSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  bio: z.string().max(500).optional(),
})

export async function updateProfile(formData: FormData) {
  // 1. Auth check FIRST
  const user = await getUser()
  if (!user) throw new Error("Unauthorized")
  
  // 2. Validate input
  const parsed = UpdateProfileSchema.safeParse({
    name: formData.get("name"),
    email: formData.get("email"),
    bio: formData.get("bio"),
  })
  if (!parsed.success) throw new Error("Invalid input")
  
  // 3. Authorization check
  // Can this user update this profile?
  
  // 4. Execute mutation
  const { error } = await supabase
    .from("profiles")
    .update(parsed.data)
    .eq("id", user.id)
  
  if (error) throw new Error("Update failed")
  
  revalidatePath("/profile")
}
```

### Common Server Action Mistakes
| Mistake | Risk | Fix |
|---------|------|-----|
| No auth check | Any client can invoke the action | Always verify session/claims first |
| Trusting `formData.get()` directly | Type confusion, injection | Validate with Zod schema |
| Passing IDs from client | IDOR | Derive IDs from auth session |
| No rate limiting | DoS, brute force | Implement rate limiting middleware |
| Returning raw errors | Information leakage | Return generic error messages |

## Review Checklist for PRs

When reviewing any Next.js App Router code:

1. **Version check**: Is the project on a patched Next.js version? If not → BLOCKED
2. **Server actions**: Every `"use server"` function has auth + input validation?
3. **Data exposure**: Do server components pass sensitive data to client components via props?
4. **Taint API usage**: Are `taintObjectReference`/`taintUniqueValue` used for sensitive objects?
5. **Rewrite config**: If `next.config.js` has `rewrites()`, verify it's patched against smuggling
6. **Error boundaries**: Do error boundaries leak stack traces or internal state to client?
7. **Middleware**: Does middleware properly validate headers before forwarding to RSC endpoints?

## Monitoring and Detection

### Signs of React2Shell exploitation attempt
- Unusually large POST bodies to RSC/Flight endpoints
- 500 errors from RSC deserialization
- Unexpected process spawning from Node.js server
- Outbound network connections from server that shouldn't exist

### Signs of request smuggling attempt (CVE-2026-29057)
- DELETE/OPTIONS requests with `Transfer-Encoding: chunked` to rewritten routes
- Backend receiving requests that don't match what the proxy sent
- Mismatched request logs between proxy and backend

## References

- For detailed React Flight protocol internals, see `references/flight-protocol.md`
- For Next.js security configuration reference, see `references/nextjs-security-config.md`
