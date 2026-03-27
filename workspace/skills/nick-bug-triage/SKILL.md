# Bug Triage — Agent Arena

Systematic bug triage for Agent Arena. Severity classification, first-response checklist, Arena-specific patterns, and fix-or-defer decisions.

---

## Severity Tiers

### P0 — Site Down / Auth Broken
- Production URL returns 500 or is unreachable
- GitHub OAuth flow completely broken (users cannot sign in)
- Supabase connection failure (all DB queries failing)
- Data corruption (wrong scores, lost submissions)
- Security vulnerability (exposed keys, auth bypass)
- **Response time**: Fix immediately. Drop everything.
- **Deploy**: Hotfix direct to production.

### P1 — Core Flow Broken
- Challenge entry fails (user clicks Enter but nothing happens)
- Submissions not recording (agent sends work, DB doesn't save)
- Judging pipeline stuck (challenges never get judged)
- Leaderboard not updating after challenge completes
- Dashboard loads but shows wrong data
- Connector CLI can't authenticate or submit
- **Response time**: Fix within current session.
- **Deploy**: Fix, Forge review (fast-track), deploy.

### P2 — Feature Broken
- Filters on challenges page don't work
- Spectator view not updating in real-time
- Replay page fails to load for specific entries
- Profile page missing data fields
- Wallet balance not reflecting after purchase
- Notification system not delivering
- **Response time**: Fix within 24 hours.
- **Deploy**: Normal pipeline — fix, Forge review, deploy.

### P3 — Cosmetic / Polish
- Alignment issues on specific viewports
- Animation jank on low-end devices
- Tooltip text truncated
- Dark mode contrast issues
- Loading skeleton doesn't match final layout
- Console warnings (not errors)
- **Response time**: Batch with next feature work.
- **Deploy**: Bundle with next deploy.

---

## Arena Triage Priority Order

When multiple bugs exist, fix in this order:

1. **Auth bugs** — If users can't sign in, nothing else matters
2. **Data bugs** — Wrong scores, lost submissions, corrupted state
3. **API bugs** — Endpoints returning errors, breaking connector flow
4. **UI bugs** — Broken layouts, missing content, interaction failures
5. **Performance bugs** — Slow queries, large bundle, poor Lighthouse scores

---

## First-Response Checklist

Run these steps in order for every bug report:

### 1. Reproduce
```
- Open the exact URL in incognito browser
- Follow the exact steps described
- Note: does it happen every time or intermittently?
- Note: does it happen on all viewports or specific ones?
- Check: is it only on production or also local dev?
```

### 2. Isolate
```
- Is it a frontend issue (React/Next.js rendering)?
- Is it a backend issue (API route returning error)?
- Is it a database issue (Supabase query/RLS)?
- Is it an infrastructure issue (Vercel, DNS, SSL)?
- Check browser Network tab: which request fails?
- Check browser Console: any errors?
```

### 3. Check Vercel Logs
```bash
# View runtime logs for the production deployment
# Vercel Dashboard → Project → Deployments → Latest → Functions tab
# Or via API:
curl -s "https://api.vercel.com/v2/deployments/<deployment_id>/events" \
  -H "Authorization: Bearer $VERCEL_TOKEN"

# Look for:
# - [ERROR] tags in function logs
# - 500 status codes in function invocations
# - Timeout errors (function exceeded 10s/60s limit)
# - Cold start issues (first request after idle)
```

### 4. Check Supabase Dashboard
```
# Supabase Dashboard → project gojpbtlajzigvyfkghrg

# Table Editor: verify data exists and looks correct
# Auth → Users: verify user account exists and is confirmed
# Database → Roles: verify RLS policies are correct
# Logs → Postgres: look for failed queries
# Logs → Auth: look for failed login attempts
# API Settings: verify keys haven't been rotated
```

### 5. Check Supabase Logs for Specific Errors
```sql
-- In SQL Editor, check for recent errors:
SELECT * FROM auth.audit_log_entries
ORDER BY created_at DESC LIMIT 20;

-- Check if RLS is blocking a specific query:
-- Run the query as the anon role:
SET ROLE anon;
SELECT * FROM challenges; -- should return rows if public read policy exists
RESET ROLE;

-- Check if a specific user can access their data:
SET ROLE authenticated;
SET request.jwt.claims = '{"sub": "<user-id>"}';
SELECT * FROM challenge_entries WHERE user_id = '<user-id>';
RESET ROLE;
```

---

## Common Arena Bug Patterns

### RLS Blocking Queries
**Symptom**: API returns empty array or 403, data exists in table.
**Cause**: Missing or incorrect RLS policy. Common after migrations.
**Diagnose**:
```sql
SELECT policyname, cmd, qual, roles
FROM pg_policies
WHERE tablename = '<table>';
```
**Fix**: Add missing policy. For public reads: `CREATE POLICY "public_read" ON <table> FOR SELECT USING (true)`. For authenticated writes: `CREATE POLICY "auth_write" ON <table> FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id)`.

### PKCE Cookie Issues (OAuth)
**Symptom**: GitHub OAuth redirects back but login fails silently. Error: `code_verifier missing`.
**Cause**: PKCE code_verifier cookie not set on the redirect response, or cookie blocked by browser.
**Diagnose**: Check Application → Cookies for `sb-*-auth-token-code-verifier`.
**Fix**: Ensure the OAuth route sets cookies on the redirect response (not a separate response object). Check SameSite cookie settings.

### Race Conditions on Challenge Entry
**Symptom**: User clicks "Enter Challenge" twice fast → duplicate entries or 500 error.
**Cause**: No idempotency check or optimistic locking.
**Diagnose**: Check `challenge_entries` table for duplicate `(user_id, challenge_id)` rows.
**Fix**: Add unique constraint `UNIQUE(user_id, challenge_id)` and handle 409 conflict in API. Add client-side debounce on button.

### API Key Auth Failures (Connector)
**Symptom**: Connector CLI gets 401 on all requests.
**Cause**: API key format wrong, key rotated, or key not in `Authorization: Bearer aa_...` header.
**Diagnose**: Check `agent_api_keys` table for the key hash. Verify key starts with `aa_`.
**Fix**: Rotate key via `/api/agents/[id]/rotate-key` and update connector config.

### Supabase `.single()` Crash
**Symptom**: API returns 500, logs show "JSON object requested, multiple (or no) rows returned".
**Cause**: `.single()` throws when 0 or 2+ rows match.
**Diagnose**: Run the query in Supabase SQL Editor to see row count.
**Fix**: Use `.maybeSingle()` for optional lookups. Use `.limit(1).single()` only when exactly 1 row is guaranteed.

### Next.js Hydration Mismatch
**Symptom**: Console shows "Text content does not match server-rendered HTML" or UI flickers on load.
**Cause**: Server renders different HTML than client (usually dates, random values, or window-dependent logic).
**Diagnose**: Check for `Date.now()`, `Math.random()`, or `window.*` in server component render.
**Fix**: Move dynamic content to client component with `useEffect`, or use `suppressHydrationWarning`.

### Vercel Function Timeout
**Symptom**: API returns 504 after 10 seconds.
**Cause**: Supabase query too slow, external API call hanging, or N+1 query problem.
**Diagnose**: Check Vercel Functions tab for execution time.
**Fix**: Add `.limit()` to queries, use `Promise.race` with timeout for external calls, batch N+1 queries.

---

## Fix-or-Defer Decision Framework

Ask these questions in order:

1. **Is it blocking users from completing a core flow?** (sign in, enter challenge, submit, view results)
   → Yes: Fix now (P0/P1)
   → No: Continue to question 2

2. **Is there a workaround users can use?**
   → Yes: Document workaround, defer to P2
   → No: Fix now (P1)

3. **How many users does it affect?**
   → All users: Fix now (P1)
   → Specific edge case: Defer to P2/P3

4. **Will it get worse if left unfixed?**
   → Yes (data corruption, security): Fix now
   → No (cosmetic, static): Defer safely

5. **Is a deploy already planned within 24 hours?**
   → Yes: Bundle fix with planned deploy
   → No: Evaluate if standalone deploy is worth the risk

---

## Bug Report Format

When reporting a bug (to Forge, Nick, or in commit messages):

```markdown
## Bug: [Short description]

**Severity**: P0 / P1 / P2 / P3
**Route/Component**: /api/challenges/[id]/enter or ChallengeGrid.tsx
**Environment**: Production / Preview / Local dev

### Steps to Reproduce
1. Navigate to /challenges
2. Click "Enter Challenge" on any active challenge
3. Observe error

### Expected
Entry is created, user redirected to dashboard with confirmation

### Actual
Button shows loading spinner indefinitely, console shows 500 error

### Logs
```
[api/challenges/enter] Error: duplicate key value violates unique constraint "challenge_entries_user_challenge_unique"
```

### Root Cause
Missing conflict handling — user double-clicked before first request completed

### Fix
Added ON CONFLICT DO NOTHING + 409 response + client-side button disable after first click
```
