# Forge Full Site Audit — Agent Arena
**Date:** 2026-03-23 01:40 GMT+8
**URL:** https://agent-arena-roan.vercel.app

---

## Security Audit

### Fixed in this deploy:
- **P0: `profiles.role` column missing** — DB had `is_admin` boolean but code checked `role === 'admin'`. Added `role TEXT` column + migrated existing admin rows. Admin access now works.
- **P1: Callback XSS/open redirect** — `next` param was interpolated into HTML/JS. Fixed: sanitize to relative paths only, strip query params, use `JSON.stringify()` for JS, `encodeURI()` for HTML.
- **P1: Duplicate `authenticateConnector`** — `events/stream` had a local copy missing `is_active` check. Fixed: imports shared version.
- **P3: OAuth rate limit** — was 20 (testing), reset to 5/min.
- **P3: Middleware running on API routes** — excluded `api/v1`, `api/connector`, `api/internal`, `api/health` from middleware.

### Remaining (P2/P3, not blocking):
- `challenges/[id]/enter` and `admin/judge/[challengeId]` — no UUID validation on path params
- `leaderboard/[weightClass]` — no input validation on weight class param
- 2 routes leak Supabase error messages to client
- `agents` table RLS exposes `api_key_hash` to all authenticated SELECT queries (API routes use explicit columns, but direct client queries could read it)
- Rate limit fail-open when no Upstash configured

## Performance Audit

### Response Times (from VPS):
| Page | Status | Time |
|------|--------|------|
| `/` (landing) | 200 | 138ms |
| `/login` | 200 | 75ms |
| `/challenges` | 200 | 65ms |
| `/leaderboard` | 200 | 121ms |
| `/docs` | 200 | 70ms |
| `/status` | 200 | 637ms (ISR, hits Supabase) |
| `/api/health` | 200 | 294ms |
| `/api/challenges` | 200 | 430ms |

### Security Headers: ✅ All present
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`
- API routes: `Cache-Control: no-store, no-cache, must-revalidate`

### Build Quality:
- TypeScript strict: 0 errors ✅
- npm audit: 0 vulnerabilities ✅
- 20 deps, 8 devDeps (lean)
- .next build: 39MB
- Next.js 16.2.1

### Added in this deploy:
- **Error boundary** (`error.tsx`) — catch-all with "Try again" button
- **404 page** (`not-found.tsx`) — custom branded 404
- **Loading state** (`loading.tsx`) — global loading spinner
- **Dashboard layout metadata** — proper `<title>` template
- **next.config.ts security headers** — X-Frame-Options, CSP-adjacent, nosniff
- **Image optimization config** — remote patterns for GitHub avatars + Supabase

### Issues Found:
| # | Severity | Issue | Status |
|---|----------|-------|--------|
| 1 | P0 | `profiles.role` column missing | ✅ Fixed |
| 2 | P1 | Callback XSS via `next` param | ✅ Fixed |
| 3 | P1 | Duplicate authenticateConnector | ✅ Fixed |
| 4 | P2 | 2 routes missing UUID validation | Noted |
| 5 | P2 | leaderboard param unvalidated | Noted |
| 6 | P2 | Supabase errors leaked to client | Noted |
| 7 | P2 | api_key_hash in public SELECT | Noted |
| 8 | P3 | OAuth rate limit was 20 | ✅ Fixed |
| 9 | P3 | Middleware on API routes (latency) | ✅ Fixed |
| 10 | P3 | Rate limit fail-open | By design |
| 11 | — | Missing error boundary | ✅ Added |
| 12 | — | Missing 404 page | ✅ Added |
| 13 | — | Missing loading state | ✅ Added |
| 14 | — | Missing security headers | ✅ Added |
| 15 | — | No Image optimization config | ✅ Added |
| 16 | — | All mock data removed | ✅ Done |
| 17 | — | Debug logging removed | ✅ Done |

---

🔥 Forge
