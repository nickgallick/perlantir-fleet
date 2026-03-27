# React Flight Protocol — Technical Reference

## What Is Flight?

React Flight is React's wire protocol for streaming serialized React component trees from server to client. It's the underlying transport for React Server Components (RSC).

### How It Works

1. **Server renders** a component tree that may include Server Components and Client Components
2. **Flight serializer** encodes the tree into a streaming format:
   - Server Component output (rendered HTML/data)
   - Client Component references (module ID + props)
   - Chunks (streamed pieces of the tree)
   - Server Action references (callable endpoints)
3. **Client Flight deserializer** reconstructs the tree and hydrates Client Components

### Wire Format

Flight uses a line-delimited format where each line is a chunk:
```
0:{"type":"module","id":"./src/Counter.js","name":"Counter","chunks":["chunk-1"]}
1:{"children":"Hello World"}
2:D{"action":"updateProfile","id":"abc123"}
```

Each chunk has:
- An ID (integer)
- A type marker (optional)
- JSON-encoded data

### Attack Surface

The Flight deserializer on both server and client must parse and reconstruct objects from this wire format. Pre-CVE-2025-55182 patch:

- **No type allowlisting**: Any serializable type could be deserialized
- **No payload size limits**: Unbounded deserialization
- **No depth limits**: Deeply nested payloads could cause stack overflow
- **Prototype pollution**: Crafted payloads could modify object prototypes
- **Code execution**: Certain deserialized types could trigger code execution during reconstruction

### Post-Patch Security

The patched versions add:
- Type allowlisting for deserialized objects
- Payload validation before deserialization
- Size and depth limits
- Stricter handling of module references

## Server Components vs Client Components — Security Boundary

### Server Components
- Execute ONLY on the server
- Can access databases, file system, secrets
- Their code is NEVER sent to the client
- Their rendered OUTPUT is sent via Flight protocol
- **Risk**: If compromised, attacker has server-side access

### Client Components
- Execute on the client (and server for SSR)
- Cannot access server-side resources directly
- Communicate with server via Server Actions
- **Risk**: XSS, client-side manipulation

### The Boundary
```
Server Component → Flight Protocol → Client Component
                   ↑
        This is the attack surface
```

The Flight protocol is the serialization boundary between server and client. Attacks target:
1. **Incoming Flight payloads** (malicious client → server) — React2Shell
2. **Outgoing Flight payloads** (compromised server → client) — data injection
3. **Server Action invocations** (client → server RPC) — input validation

## Server Actions — RPC Attack Surface

### How Server Actions Work

```typescript
// app/actions.ts
"use server"

export async function createPost(formData: FormData) {
  // This function is callable from the client
  // React generates an endpoint for it
  // The client calls it via POST request
}
```

Under the hood:
1. Next.js assigns each server action a unique ID (hash of module + export name)
2. Client calls `POST /<page>` with a special header identifying the action
3. Server deserializes the arguments and invokes the function
4. Result is serialized back via Flight protocol

### Attack Vectors on Server Actions

| Vector | Description | Mitigation |
|--------|-------------|------------|
| Unauthenticated invocation | Anyone can POST to the action endpoint | Check auth in every action |
| Argument manipulation | Client sends unexpected types/values | Zod validation on all args |
| CSRF | Cross-site action invocation | Next.js includes CSRF protection, but verify it's not disabled |
| Replay attacks | Re-sending valid action calls | Use nonces or idempotency keys |
| Action enumeration | Discovering available actions | Action IDs are hashed but predictable if source is known |
| Mass invocation | DoS via rapid action calls | Rate limiting per user/IP |

## React Taint API

React 19 introduced taint APIs to prevent accidental data leakage:

### taintObjectReference
```typescript
import { experimental_taintObjectReference as taintObjectReference } from 'react'

// In a server component
const user = await getUser()
taintObjectReference("Do not pass user object to client", user)

// If this object is accidentally passed as a prop to a client component,
// React will throw an error instead of serializing it
```

### taintUniqueValue
```typescript
import { experimental_taintUniqueValue as taintUniqueValue } from 'react'

const apiKey = process.env.API_KEY
taintUniqueValue("API key must not be sent to client", globalThis, apiKey)

// If this string value appears in any prop to a client component,
// React throws an error
```

### When to Use
- Taint database connection objects
- Taint API keys and tokens
- Taint user objects that contain sensitive fields (password hashes, etc.)
- Taint any server-only configuration

## Next.js Middleware Security

### Middleware and RSC
Middleware runs BEFORE RSC rendering. Use it for:
- Auth validation (redirect unauthenticated users)
- Request validation (block malformed requests)
- Rate limiting (prevent abuse)
- Header injection (add security headers)

### Security Headers for RSC Apps
```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const response = NextResponse.next()
  
  // Prevent Flight endpoint from being framed
  response.headers.set('X-Frame-Options', 'DENY')
  
  // Strict CSP for RSC apps
  response.headers.set('Content-Security-Policy', 
    "default-src 'self'; script-src 'self' 'unsafe-inline'; connect-src 'self'")
  
  // Prevent MIME type sniffing
  response.headers.set('X-Content-Type-Options', 'nosniff')
  
  return response
}
```

## Next.js Rewrites — Request Smuggling (CVE-2026-29057)

### How Rewrites Work
```javascript
// next.config.js
module.exports = {
  async rewrites() {
    return [
      {
        source: '/api/external/:path*',
        destination: 'https://backend.example.com/:path*',
      },
    ]
  },
}
```

Next.js acts as a reverse proxy, forwarding requests to the backend.

### The Vulnerability
When proxying, Next.js and the backend can disagree on where one HTTP request ends and the next begins when `Transfer-Encoding: chunked` is used on DELETE/OPTIONS requests. This disagreement allows an attacker to "smuggle" a second request inside the first.

### Impact
- Bypass authentication (smuggled request may not carry auth headers)
- Cache poisoning (smuggled response gets cached for other users)
- Request routing manipulation

### Mitigation
1. Upgrade to patched Next.js
2. Prefer API routes over rewrites for external backends
3. If rewrites are necessary, ensure backend strictly validates Transfer-Encoding
4. Consider adding a WAF rule to block chunked DELETE/OPTIONS to rewritten paths
