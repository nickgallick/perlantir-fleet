# Weekly Security Scan — 2026-03-22

**Run by:** Forge 🔥
**Time:** 2026-03-22 13:16 MYT

---

## 1. Secret Scan

| Project | Status | Details |
|---------|--------|---------|
| barber-book | ✅ Clean | .env.local exists but not tracked |
| booksy-app | ✅ Clean | .env exists but not tracked |
| brew-and-bean | ✅ Clean | No env files |
| glow-play-app | ✅ Clean | No env files |
| glowup-kids | ✅ Clean | No env files |
| glowup-kids-web | ✅ Clean | No env files |
| grwm-studio-web | ✅ Clean | No env files |
| mathmind | ✅ Clean | No env files |
| perlantir-mission-control | ⚠️ Warning | `.env` tracked in git — contains anon key (public) only. Service key comment confirms removal. Low risk but should be .gitignored. |

**No hardcoded secrets found in source files across any project.**

---

## 2. Dependency Vulnerabilities (high/critical)

| Project | High | Critical | Total |
|---------|------|----------|-------|
| barber-book | 1 | 0 | 2 |
| booksy-app | 7 | 0 | 15 |
| brew-and-bean | 0 | 0 | 0 ✅ |
| glow-play-app | 7 | 0 | 15 |
| glowup-kids | 0 | 0 | 0 ✅ |
| glowup-kids-web | 0 | 0 | 0 ✅ |
| perlantir-mission-control | 1 | 0 | 4 |

**booksy-app and glow-play-app** have 7 high-severity vulnerabilities each — likely shared Expo/RN dependency tree.

---

## 3. RLS Coverage

No Supabase migration files found in any project's local directory. RLS check inconclusive — schemas may be managed via Supabase dashboard or deployed elsewhere.

---

## 4. Auth Boundary Check

| Project | Unprotected Routes | Severity |
|---------|-------------------|----------|
| barber-book | `app/api/setup/route.ts` — executes raw SQL to create schema, no auth | **P0 🔴** |
| barber-book | `app/api/seed/route.ts` — deletes ALL data and reseeds using admin client, no auth | **P0 🔴** |

**These are destructive admin endpoints accessible to anyone.** If barber-book is deployed, any unauthenticated request to `/api/setup` or `/api/seed` can wipe the database.

---

## Summary

| Category | Status |
|----------|--------|
| Secrets | ✅ Clean (1 minor: perlantir .env tracked but safe) |
| Dependencies | ⚠️ booksy-app & glow-play-app need `npm audit fix` |
| RLS | ⏭️ Inconclusive (no local migrations) |
| Auth boundaries | 🔴 **barber-book: 2 unauthenticated destructive endpoints** |

### Action Required
1. **barber-book /api/setup and /api/seed** — must be removed or auth-gated before any production deploy. These allow full DB wipe without authentication.
2. **booksy-app / glow-play-app** — run `npm audit fix` to address 7 high vulnerabilities each.
3. **perlantir-mission-control** — add `.env` to `.gitignore` and remove from git tracking.
