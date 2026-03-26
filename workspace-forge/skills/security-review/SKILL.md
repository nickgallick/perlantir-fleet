# Security Review — Forge Skill

## Overview

Security is the highest-priority review concern. A security vulnerability can compromise user data, destroy trust, and create legal liability. Every PR gets security review.

## OWASP-Aligned Checklist

### Authentication

- [ ] Auth checks present on all protected routes
- [ ] `getSession()` / `getUser()` called server-side, not just client-side
- [ ] Session tokens never exposed in URLs or logs
- [ ] Auth state not stored in localStorage (use httpOnly cookies via Supabase)
- [ ] Password reset flows validate tokens properly
- [ ] OAuth callback URLs are whitelisted and validated
- [ ] JWT tokens validated on every request, not just on login
- [ ] Token refresh logic handles edge cases (expired, revoked)
- [ ] No auth bypass through API route ordering or middleware gaps

### Authorization & Row Level Security (RLS)

**This is critical for Supabase projects.**

- [ ] Every new table has RLS enabled — no exceptions
- [ ] RLS policies use `auth.uid()` not client-provided user IDs
- [ ] Policies cover all operations: SELECT, INSERT, UPDATE, DELETE
- [ ] No policy uses `true` for SELECT without intentional public access
- [ ] Foreign key relationships don't create indirect access bypasses
- [ ] Service role key never used client-side
- [ ] `anon` key permissions are minimal and intentional
- [ ] RLS policies tested with different user roles
- [ ] Realtime subscriptions respect RLS (check channel policies)

### Injection Prevention

- [ ] SQL: All queries use parameterized statements (Supabase client handles this, but raw SQL in Edge Functions must be checked)
- [ ] XSS: User input rendered with proper escaping (React handles most, but `dangerouslySetInnerHTML` is a red flag)
- [ ] Command injection: No `exec()`, `eval()`, or shell commands with user input
- [ ] Path traversal: File paths validated and sandboxed
- [ ] Template injection: No user input in template literals that become code
- [ ] Header injection: Response headers don't include unvalidated user input
- [ ] SSRF: Server-side requests validate and whitelist target URLs

### Secrets Management

- [ ] No secrets in code (API keys, passwords, tokens)
- [ ] No secrets in git history (check for accidental commits)
- [ ] Environment variables used for all secrets
- [ ] `.env` files in `.gitignore`
- [ ] Different secrets for dev/staging/production
- [ ] Supabase service role key only used server-side
- [ ] Third-party API keys scoped to minimum permissions
- [ ] No secrets logged or included in error responses

### CORS Configuration

- [ ] CORS origins are explicit, not `*` in production
- [ ] Credentials mode configured correctly with CORS
- [ ] Preflight requests handled properly
- [ ] CORS headers not set on non-API routes

### Rate Limiting

- [ ] Authentication endpoints are rate-limited
- [ ] Public API endpoints are rate-limited
- [ ] File upload endpoints have size limits
- [ ] Expensive operations (search, reports) are throttled
- [ ] Rate limit responses include proper headers (Retry-After)

### Data Exposure

- [ ] API responses don't include unnecessary fields (passwords, internal IDs, metadata)
- [ ] Error messages don't leak stack traces, SQL queries, or internal paths
- [ ] Pagination prevents full-table dumps
- [ ] GraphQL introspection disabled in production (if applicable)
- [ ] Sensitive data not cached in browser (Cache-Control headers)
- [ ] PII handling follows data minimization principles
- [ ] Logs don't contain sensitive user data

## Severity Guide

| Issue | Severity |
|-------|----------|
| Missing RLS on a table | P0 — BLOCKED |
| Auth bypass possible | P0 — BLOCKED |
| Secret in code | P0 — BLOCKED |
| SQL injection vector | P0 — BLOCKED |
| XSS vulnerability | P0 — BLOCKED |
| Missing auth check on route | P0 — BLOCKED |
| CORS set to `*` in production | P1 — High |
| Missing rate limiting on auth | P1 — High |
| Overly permissive RLS policy | P1 — High |
| Error message leaks internals | P2 — Medium |
| Missing input validation | P2 — Medium |
| Unnecessary data in API response | P3 — Low |
