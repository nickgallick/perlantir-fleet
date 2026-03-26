---
name: http-smuggling-desync
description: HTTP request smuggling, HTTP/2 desync attacks, and parser differential vulnerabilities. Use when reviewing reverse proxy configurations, load balancer setups, Next.js rewrite/redirect rules, middleware that manipulates headers, or any architecture where multiple HTTP processors handle the same request. Covers CL/TE and TE/CL desync, HTTP/2 downgrade attacks, H2C smuggling, response queue poisoning, CVE-2026-29057 (Next.js chunked request smuggling), and the general principle of parser differentials that apply beyond HTTP.
---

# HTTP Smuggling & Desync Attacks

## The Core Concept: Parser Differentials

HTTP smuggling exploits disagreements between two HTTP processors about where one request ends and the next begins. When a frontend proxy and backend server disagree on request boundaries, an attacker can "smuggle" a hidden request inside a legitimate one.

```
What the proxy sees:          What the backend sees:
┌─────────────────────┐       ┌─────────────────────┐
│ Request 1 (normal)  │       │ Request 1 (partial)  │
│                     │       ├─────────────────────┤
│                     │       │ Request 2 (smuggled) │
└─────────────────────┘       └─────────────────────┘
```

The smuggled request bypasses the proxy's security controls (auth, WAF, rate limiting) because the proxy doesn't know it exists.

## Classic Smuggling: CL/TE and TE/CL

### Content-Length vs Transfer-Encoding Disagreement

HTTP has two ways to specify body length:
- `Content-Length: 13` — body is exactly 13 bytes
- `Transfer-Encoding: chunked` — body is chunked-encoded

When BOTH headers are present, different servers may use different ones.

### CL.TE Attack (Proxy uses CL, Backend uses TE)
```http
POST / HTTP/1.1
Host: target.com
Content-Length: 13
Transfer-Encoding: chunked

0

SMUGGLED
```

**Proxy** reads 13 bytes (body = "0\r\n\r\nSMUGGLED") → forwards as one request.
**Backend** sees chunked: `0\r\n\r\n` = empty chunk (end of request 1). `SMUGGLED` = start of request 2.

### TE.CL Attack (Proxy uses TE, Backend uses CL)
```http
POST / HTTP/1.1
Host: target.com
Content-Length: 3
Transfer-Encoding: chunked

8
SMUGGLED
0

```

**Proxy** reads chunked: chunk of 8 bytes ("SMUGGLED"), then 0 = end. Forwards everything.
**Backend** reads Content-Length: 3 → body = "8\r\n". Remaining "SMUGGLED\r\n0\r\n\r\n" = next request.

## HTTP/2 Desync

### H2C Smuggling
HTTP/2 cleartext (H2C) upgrade can bypass proxy controls:
1. Client sends HTTP/1.1 upgrade request to proxy
2. Proxy forwards to backend as HTTP/1.1
3. Backend upgrades to HTTP/2
4. Client now speaks HTTP/2 directly to backend, bypassing proxy

### HTTP/2 → HTTP/1.1 Downgrade
When proxy speaks HTTP/2 to client but HTTP/1.1 to backend:
- HTTP/2 request can contain headers that are illegal in HTTP/1.1
- Backend reinterprets these as request boundaries
- Result: smuggled request

### Response Queue Poisoning
```
1. Attacker sends smuggled request via desync
2. Backend processes smuggled request, generates response
3. Response is queued for the NEXT user's connection
4. Victim receives attacker's response instead of their own
```

Impact: Victim sees attacker-controlled content, or attacker receives victim's response (data leak).

## CVE-2026-29057: Next.js Chunked Request Smuggling

### What Happened
Next.js rewrites that proxy to external backends had a desync on DELETE/OPTIONS with `Transfer-Encoding: chunked`:
- Next.js (as proxy) and the backend disagreed on request boundaries
- Attacker could smuggle a second request through the rewrite

### Affected Configuration
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

### Fix
Upgrade to Next.js ≥15.5.13 or ≥16.1.7.

### Architectural Fix
Prefer API routes over rewrites for proxying:
```typescript
// Instead of rewrite, use an API route that validates and forwards
export async function DELETE(request: Request) {
  const user = await getAuthUser()
  if (!user) return new Response('Unauthorized', { status: 401 })
  
  // Controlled forwarding — no parser differential possible
  const response = await fetch('https://backend.example.com/resource', {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${BACKEND_TOKEN}` },
  })
  return response
}
```

## Detection in Architecture Review

### When to Worry
- [ ] Application uses reverse proxy (Nginx, Cloudflare, Vercel Edge) in front of backend
- [ ] Next.js `rewrites()` proxy to external services
- [ ] Load balancer fronting multiple backend instances
- [ ] CDN caching responses (cache poisoning via smuggling)
- [ ] Mix of HTTP/1.1 and HTTP/2 in the request path

### Architecture-Level Questions
1. **How many HTTP processors touch each request?** (CDN → Edge → Proxy → App → Backend)
2. **Do all processors agree on Transfer-Encoding vs Content-Length precedence?**
3. **Does any processor perform HTTP/2 to HTTP/1.1 downgrade?**
4. **Are rewrites/proxies copying raw headers or normalizing them?**

### Code-Level Questions
- [ ] Any `rewrites()` in next.config.js?
- [ ] Any manual proxy logic using `fetch()` to forward requests?
- [ ] Any middleware that modifies `Content-Length` or `Transfer-Encoding` headers?
- [ ] Any custom HTTP server (not Next.js) in the architecture?

## Mitigation Strategies

### 1. Normalize at the Edge
Configure the frontend proxy (Nginx, Cloudflare) to normalize requests before forwarding:
- Reject requests with both `Content-Length` and `Transfer-Encoding`
- Reject ambiguous `Transfer-Encoding` values (e.g., `Transfer-Encoding: chunked, identity`)
- Strip HTTP/2 pseudo-headers before downgrading

### 2. Use HTTP/2 End-to-End
If both proxy and backend speak HTTP/2, there's no CL/TE desync possible (HTTP/2 doesn't use these headers for framing).

### 3. Avoid Proxying When Possible
```
Architecture 1 (risky):
  Client → CDN → Next.js → rewrites → External Backend
  (4 HTTP processors, multiple desync opportunities)

Architecture 2 (safer):
  Client → CDN → Next.js API Route → fetch() → External Backend
  (Next.js controls the outbound request entirely)
```

### 4. WAF Rules
```
Block requests with:
- Both Content-Length and Transfer-Encoding headers
- Transfer-Encoding values other than "chunked"
- Chunked encoding on DELETE/OPTIONS (CVE-2026-29057 specific)
```

## The General Principle: Parser Differentials

HTTP smuggling is one instance of a broader class: **parser differential attacks**. Anywhere two systems parse the same data differently:

| Domain | Differential | Attack |
|--------|-------------|--------|
| HTTP | CL vs TE interpretation | Request smuggling |
| URLs | Parser differences (`@`, `#`, encoded chars) | SSRF bypass, open redirect |
| JSON | Duplicate key handling | Logic confusion |
| Unicode | Normalization differences | Homoglyph, bypass filters |
| XML | Entity expansion, canonicalization | XXE, SAML bypass |
| Regex | Engine differences (PCRE vs RE2 vs JS) | ReDoS, bypass |
| File paths | `/` vs `\`, `..`, URL encoding | Path traversal |
| Content-Type | MIME sniffing vs declared type | XSS via content-type confusion |

**The 0.01% insight**: When you see two systems processing the same input, always ask: "What if they disagree?"

## Review Checklist

- [ ] No `rewrites()` proxying to external backends (use API routes instead)
- [ ] If rewrites exist: Next.js version patched for CVE-2026-29057
- [ ] Frontend proxy configured to reject ambiguous CL/TE combinations
- [ ] HTTP/2 used end-to-end where possible
- [ ] No middleware manually manipulating Content-Length or Transfer-Encoding
- [ ] CDN caching rules account for smuggling (no caching of responses to DELETE/POST)
- [ ] Request normalization at the edge before reaching application

## References

For SSRF via URL parser differentials, see `ssrf-exploitation` skill.
For Unicode parser differentials, see `unicode-steganography-detection` skill.
