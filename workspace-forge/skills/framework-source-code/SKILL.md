---
name: framework-source-code
description: Index of cloned framework repos and how to use them for review validation.
---

# Framework Source Code Index

## Local Repos (200MB total, read-only reference)

| Framework | Path | TS Files | Use For |
|-----------|------|----------|---------|
| Anthropic JS SDK | repos/anthropic-sdk-js | 177 | Claude API calls, streaming, tool use patterns |
| Anthropic Python SDK | repos/anthropic-sdk | 624 py | Cross-reference Python SDK patterns |
| Expo (router + secure-store) | repos/expo | 401 | expo-router, expo-secure-store, React Native |
| Fastify | repos/fastify | 35 | Server framework, plugin system, validation |
| Next.js | repos/nextjs | 1,588 | App router, server components, caching, API routes |
| OWASP Cheat Sheets | repos/owasp | — | Security review bible (markdown, not code) |
| React | repos/react | 6 | Core hooks, reconciler internals |
| Supabase JS | repos/supabase-js | 270 | Client SDK, auth, RLS, realtime patterns |
| Tailwind CSS | repos/tailwindcss | 300 | Utility class system, config |
| TypeScript | repos/typescript | 245 | Compiler internals, type system |
| Zod | repos/zod | 389 | Validation, schema patterns, error handling |

## Web Fetch Fallback (use for files outside local sparse checkout)

For supabase server patterns, edge functions, or any specific file not in local repos:

```
# Supabase edge functions are now LOCAL:
# repos/supabase/examples/edge-functions/
# repos/supabase/apps/docs/ (full Supabase docs)

# Next.js specific files
web_fetch("https://raw.githubusercontent.com/vercel/next.js/canary/packages/next/src/...")

# React specific source
web_fetch("https://raw.githubusercontent.com/facebook/react/main/packages/react/src/...")

# Expo packages not in local clone
web_fetch("https://raw.githubusercontent.com/expo/expo/main/packages/expo-notifications/src/...")
```

Forge ALWAYS has access to any framework's source — local clone for fast access, web_fetch as complete fallback.

## How to Search Local Repos

```bash
# Find how a specific function works
grep -r "functionName" repos/nextjs/packages/next/src/ --include="*.ts" -l

# Find security patterns
grep -r "sanitize\|escape\|validate\|csrf\|xss" repos/supabase-js/src/ --include="*.ts" -l

# OWASP cheat sheet for a specific topic
ls repos/owasp/cheatsheets/ | grep -i "auth\|sql\|xss"
cat repos/owasp/cheatsheets/Authentication_Cheat_Sheet.md
```

## OWASP Cheat Sheets Available
```bash
ls repos/owasp/cheatsheets/ | head -30
```
Key ones: Authentication, SQL_Injection, XSS_Filter_Evasion, CSRF_Prevention, Input_Validation, Secrets_Management, Session_Management, Authorization_Testing

## Changelog
- 2026-03-20: Supabase monorepo restored (79GB free on disk). Full edge-functions + auth-helpers + docs. Total: 754MB.
