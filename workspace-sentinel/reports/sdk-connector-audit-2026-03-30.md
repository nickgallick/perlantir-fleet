# SDK + Connector Path Audit — 2026-03-30
**Auditor:** Sentinel 🛡️  
**Triggered by:** SDK test run (exec session `neat-meadow`) — `create_session` 500

---

## Executive Summary

**Overall Verdict: ❌ CONNECTOR PATH BROKEN — Launch Blocker**

Two independent root cause bugs prevent the connector/SDK flow from completing. Neither is a data state issue — both are code defects.

| Bug | Severity | Impact |
|-----|----------|--------|
| `time_limit_seconds` column does not exist in DB | **P0** | All `create_session` calls fail 404 for every challenge |
| `maybeSingle()` on agents with multiple rows per user | **P1** | `create_session` + `submit_result` fail for any user with >1 agent |
| MCP `list_challenges` returned 0 (SDK test config) | **P2** | SDK test not using `status` filter — intermittent false negative |

**P0 count: 1 | P1 count: 1 | Launch ready: NO**

The connector integration path — `list_challenges → create_session → submit → get_result` — is broken end-to-end. An AI agent connecting via SDK or MCP cannot start a competition session.

---

## What Was Tested

1. REST API `GET /api/v1/challenges` — with sandbox token ✅
2. REST API `POST /api/v1/challenges/:id/sessions` — with sandbox token ❌
3. REST API `POST /api/v1/sessions/:id/submissions` — ❌
4. MCP `tools/list` — ✅
5. MCP `list_challenges` — ✅ (3 sandbox challenges)
6. MCP `create_session` — ❌
7. SDK test run output (`neat-meadow` exec session)

---

## Defect Log

---

### BUG-001 — `create_session` fails 404 for all challenges
**Severity:** P0 — Launch Blocker  
**Environment:** Live (https://agent-arena-roan.vercel.app) + MCP  
**Affected role:** All API token users  
**Route:** `POST /api/v1/challenges/:id/sessions`

**Root Cause:**  
`src/app/api/v1/challenges/[id]/sessions/route.ts` line 48:
```ts
.select('id, format, time_limit_seconds, is_sandbox, status')
```
The column `time_limit_seconds` does **not exist** in the `challenges` table. The actual column is `time_limit_minutes`.

When Supabase receives a query for a non-existent column, it returns a `PGRST204` error. The error is caught at the `if (challengeFetchError || !challenge)` check on line ~53, which returns:
```json
{"error": {"message": "Challenge not found", "code": "NOT_FOUND"}}
```
This is HTTP 404 from the REST layer but the MCP server wraps it as 500.

**Reproduction steps:**
1. Get any valid challenge UUID (e.g. `69e80bf0-597d-4ce0-8c1c-563db9c246f2`)
2. `POST /api/v1/challenges/69e80bf0.../sessions` with a valid `challenge:enter` scoped token
3. Returns `{"error": {"message": "Challenge not found", "code": "NOT_FOUND"}}`

**Expected:** Session created (201) or existing session returned (200)  
**Actual:** 404 "Challenge not found" for every challenge ID

**Fix (exact):**  
In `src/app/api/v1/challenges/[id]/sessions/route.ts`:

Line 48 — change:
```ts
.select('id, format, time_limit_seconds, is_sandbox, status')
```
to:
```ts
.select('id, format, time_limit_minutes, is_sandbox, status')
```

Lines 121-135 — update all references from `time_limit_seconds` to `time_limit_minutes` and convert minutes → seconds:
```ts
// Before:
const time_limit_seconds = (challenge?.time_limit_seconds as number | null) ?? null
const expires_at = time_limit_seconds
  ? new Date(Date.now() + time_limit_seconds * 1000).toISOString()
  : null
// Insert:
  time_limit_seconds,

// After:
const time_limit_minutes = (challenge?.time_limit_minutes as number | null) ?? null
const time_limit_seconds = time_limit_minutes ? time_limit_minutes * 60 : null
const expires_at = time_limit_seconds
  ? new Date(Date.now() + time_limit_seconds * 1000).toISOString()
  : null
// Insert:
  time_limit_seconds,
```

**Reproducible:** Yes — 100%  
**Suspected state:** Was always broken. The column name was never correct.

---

### BUG-002 — `maybeSingle()` on agents blows up for users with multiple agents
**Severity:** P1  
**Environment:** Live  
**Affected role:** Any user with more than one registered agent  
**Routes:** `POST /api/v1/challenges/:id/sessions` (line ~68), `POST /api/v1/sessions/:id/submissions` (line ~62)

**Root Cause:**  
Both routes do:
```ts
const { data: agent, error: agentError } = await supabase
  .from('agents')
  .select('id, user_id')
  .eq('user_id', auth.user_id)
  .maybeSingle()
```

`maybeSingle()` returns an error (PGRST116: "Expected a single row but multiple rows were returned") when more than 1 agent exists for a user.

The QA user (`e6e37b08`) has **4 agents**: ForgeE2E-001, BoutsTest-Sonnet-46, BoutsTest-Haiku-45, QA-BOT-001. Any user who has registered more than one agent will hit this error, which maps to "No agent found for this user" (NOT_FOUND).

**Reproduction steps:**
1. Create 2+ agents for a user via `/api/v1/agents`
2. Attempt `POST /api/v1/challenges/:id/sessions`
3. Returns 404 "No agent found for this user"

**Expected:** Route picks the user's primary agent (or uses `agent_id` from the token if provided)  
**Actual:** Fails with NOT_FOUND

**Fix options (for Forge to decide):**
- Option A: API token should include `agent_id` in scope; pass it as `auth.agent_id` and select by both `user_id` + `agent_id`
- Option B: Use `.limit(1)` instead of `.maybeSingle()` and pick first — pragmatic but messy
- Option C: `session create` requires agent_id in request body when multiple agents exist

Recommend **Option A** — the auth token should carry agent identity. Token context already resolves `agent_id` for connector tokens (line in `resolveConnectorToken`); API tokens should do the same at token creation.

**Reproducible:** Yes — for any user with >1 agent  
**Suspected state:** Likely broken for all power users / QA users

---

### BUG-003 — SDK test `list_challenges` returned 0 (false negative in test)
**Severity:** P2 — Test Config Issue, Not a Platform Bug  
**Environment:** SDK test (`neat-meadow`)  
**Affected role:** SDK test authors

**Root Cause:**  
The SDK test called `list_challenges` without a `status` filter. The SDK's default call fetches all challenges. The MCP `list_challenges` test using `status=active` returned 3 challenges correctly.

The original test output showed 0 challenges, which caused the test to attempt `create_session` with a placeholder/empty challenge ID, producing the 500.

**Note:** The MCP `list_challenges` with `status=active` works correctly — 3 sandbox challenges returned. This is not a platform defect.

**Fix:** SDK test should either:
- Pass `status='active'` when calling `list_challenges`  
- Or use a hardcoded known-good sandbox challenge ID for connector path testing

---

## MCP Path — Additional Finding

The MCP `create_session` error is a downstream consequence of BUG-001. The edge function calls the REST API, which returns 404 "Challenge not found" → MCP wraps it as 500 (-32603). Fix BUG-001 and MCP create_session will work.

Verified MCP `tools/list` ✅ and `list_challenges` ✅ are both working correctly.

---

## Risk Register

| Risk | Likelihood | Notes |
|------|------------|-------|
| Other routes querying non-existent columns | Medium | Worth grepping all v1 routes for `time_limit_seconds` |
| `maybeSingle()` pattern used elsewhere | High | Pattern appears in both session and submission routes — audit all |
| Submission route also broken for multi-agent users | Confirmed | Same `.maybeSingle()` issue at `POST /api/v1/sessions/:id/submissions` line 62 |

---

## Recommended Fix Order

1. **P0 — Fix `time_limit_seconds` → `time_limit_minutes` in create_session route** (5 min fix)
2. **Audit all v1 routes for `time_limit_seconds`** column reference — may appear elsewhere
3. **P1 — Fix `maybeSingle()` → multi-agent safe lookup** in both create_session and submit routes
4. **Deploy and re-run SDK/connector test** to confirm full path green

---

## Fix Ownership

- **Forge** — receives this report, implements fixes
- **Sentinel** — re-tests after deploy
- **Maks** — if schema migration needed (none required here, column name issue is code-side only)
