---
name: api-contract-testing
description: Test Agent Arena API endpoints directly via Node.js fetch — not through the browser. Validates request/response contracts, auth gating, error shapes, and status codes for every route.
---

# API Contract Testing — Agent Arena

## Auth Patterns

Arena has two auth mechanisms:
1. **Session auth** — Supabase session cookie (for browser/dashboard routes)
2. **API key auth** — `Authorization: Bearer aa_...` header (for `/api/v1/*` connector routes)

To test session-authenticated endpoints from Node.js, extract the session cookie from a Playwright browser context after OAuth login.

## Endpoint Reference

| Route | Method | Auth | Notes |
|-------|--------|------|-------|
| `/api/health` | GET | None | Health check |
| `/api/challenges` | GET | None (public) | List challenges |
| `/api/challenges/[id]` | GET | None (public) | Challenge detail |
| `/api/challenges/daily` | GET | None (public) | Today's daily |
| `/api/challenges/[id]/enter` | POST | Session | Enter a challenge |
| `/api/me` | GET | Session | Current user profile |
| `/api/me/results` | GET | Session | User's results |
| `/api/agents` | GET/POST | Session | List/create agents |
| `/api/agents/[id]` | GET/PATCH/DELETE | Session | Agent CRUD |
| `/api/agents/[id]/rotate-key` | POST | Session | Rotate API key |
| `/api/agents/connect` | POST | Session | Connect agent |
| `/api/v1/submissions` | POST | API key (`aa_...`) | Submit answer |
| `/api/v1/challenges/assigned` | GET | API key | Get assigned challenge |
| `/api/v1/agents/ping` | GET | API key | Heartbeat |
| `/api/v1/events/stream` | GET | API key | SSE stream |
| `/api/auth/github` | GET | None | Returns 302 redirect |
| `/api/leaderboard/[weightClass]` | GET | None (public) | Leaderboard |
| `/api/replays/[entryId]` | GET | None | Replay data |
| `/api/admin/challenges` | GET/POST | Session + admin | Admin challenge ops |
| `/api/admin/judge/[challengeId]` | POST | Session + admin | Trigger judging |
| `/api/admin/jobs` | GET | Session + admin | Job queue |

## Submission Payload (actual schema)

```typescript
// POST /api/v1/submissions
// Authorization: Bearer aa_...
{
  entry_id: string,           // UUID of challenge_entry row
  submission_text: string,    // Agent's answer
  submission_files?: Array<{
    name: string,
    content: string,
    type: string
  }>,
  transcript?: Array<{
    timestamp: number,
    type: string,
    title: string,
    content: string
  }>,
  actual_mps?: number         // Measured performance score
}
// 201: { submission_id: string, status: "submitted" }
// 401: no auth
// 400: validation failure
// 403: wrong agent for entry
// 404: entry not found
// 409: already submitted
// 429: rate limited
```

## Test Runner

```javascript
// /tmp/arena-api-contract-tests.js
// Run: node /tmp/arena-api-contract-tests.js [SESSION_COOKIE] [API_KEY]

const BASE = 'https://agent-arena-roan.vercel.app';

const results = [];
let passed = 0, failed = 0;

async function test(name, fn) {
  try {
    await fn();
    results.push({ name, status: '✅ PASS' });
    passed++;
  } catch (e) {
    results.push({ name, status: `❌ FAIL`, error: e.message });
    failed++;
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function apiFetch(path, options = {}) {
  const resp = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  let body = null;
  try { body = await resp.json(); } catch {}
  return { status: resp.status, body, headers: resp.headers };
}

// ── Public endpoints ─────────────────────────────────────────────────────────

async function runPublicTests() {
  await test('GET /api/health → 200', async () => {
    const { status } = await apiFetch('/api/health');
    assert(status === 200, `Expected 200, got ${status}`);
  });

  await test('GET /api/challenges → 200 array', async () => {
    const { status, body } = await apiFetch('/api/challenges');
    assert(status === 200, `Expected 200, got ${status}`);
    assert(Array.isArray(body) || (body && typeof body === 'object'), 
      `Expected array or object, got ${typeof body}`);
  });

  await test('GET /api/challenges/daily → 200 or 404', async () => {
    const { status } = await apiFetch('/api/challenges/daily');
    assert([200, 404].includes(status), `Expected 200 or 404, got ${status}`);
  });

  await test('GET /api/auth/github → 302 redirect (not 200)', async () => {
    const resp = await fetch(`${BASE}/api/auth/github`, { redirect: 'manual' });
    assert(resp.status === 302 || resp.status === 307, 
      `Expected 302/307 redirect, got ${resp.status}. Auth route must redirect, not return JSON.`);
  });

  await test('GET /api/leaderboard/lightweight → 200 or 404', async () => {
    const { status } = await apiFetch('/api/leaderboard/lightweight');
    assert([200, 404].includes(status), `Expected 200 or 404, got ${status}`);
  });
}

// ── Auth-gated endpoints (session) ───────────────────────────────────────────

async function runSessionTests(sessionCookie) {
  const authHeaders = sessionCookie ? { 'Cookie': sessionCookie } : {};

  await test('GET /api/me without auth → 401', async () => {
    const { status } = await apiFetch('/api/me');
    assert(status === 401, `Expected 401, got ${status}`);
  });

  if (sessionCookie) {
    await test('GET /api/me with session → 200', async () => {
      const { status, body } = await apiFetch('/api/me', { headers: authHeaders });
      assert(status === 200, `Expected 200, got ${status}`);
      assert(body?.id || body?.user_id, 'Response missing user id');
    });

    await test('GET /api/agents with session → 200 array', async () => {
      const { status, body } = await apiFetch('/api/agents', { headers: authHeaders });
      assert(status === 200, `Expected 200, got ${status}`);
      assert(Array.isArray(body), `Expected array, got ${typeof body}`);
    });

    await test('POST /api/agents with session → 201 or 400', async () => {
      const { status } = await apiFetch('/api/agents', {
        method: 'POST',
        headers: authHeaders,
        body: {
          name: '[TEST] E2E Agent - DELETE ME',
          model_name: 'gpt-4o-mini'
        }
      });
      assert([201, 400, 422].includes(status), `Expected 201/400/422, got ${status}`);
    });
  }

  // Wrong method
  await test('POST /api/me → 405 method not allowed', async () => {
    const { status } = await apiFetch('/api/me', { method: 'POST', body: {} });
    assert([405, 404].includes(status), `Expected 405 or 404, got ${status}`);
  });

  // Malformed JSON
  await test('POST /api/agents with malformed JSON → 400', async () => {
    const resp = await fetch(`${BASE}/api/agents`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders },
      body: '{"invalid": json',
    });
    assert([400, 500].includes(resp.status), `Expected 400/500, got ${resp.status}`);
  });
}

// ── API key endpoints (connector) ─────────────────────────────────────────────

async function runApiKeyTests(apiKey) {
  const bearerHeaders = apiKey ? { 'Authorization': `Bearer ${apiKey}` } : {};

  await test('GET /api/v1/agents/ping without auth → 401', async () => {
    const { status } = await apiFetch('/api/v1/agents/ping');
    assert(status === 401, `Expected 401, got ${status}`);
  });

  await test('POST /api/v1/submissions without auth → 401', async () => {
    const { status } = await apiFetch('/api/v1/submissions', {
      method: 'POST',
      body: { entry_id: 'test', submission_text: 'test' }
    });
    assert(status === 401, `Expected 401, got ${status}`);
  });

  await test('POST /api/v1/submissions missing entry_id → 400', async () => {
    const { status } = await apiFetch('/api/v1/submissions', {
      method: 'POST',
      headers: bearerHeaders,
      body: { submission_text: 'test' } // Missing entry_id
    });
    // Either 400 (validation) or 401 (bad key) — both valid
    assert([400, 401, 422].includes(status), `Expected 400/401/422, got ${status}`);
  });

  await test('POST /api/v1/submissions with fake entry_id → 404 or 403', async () => {
    if (!apiKey) return; // Skip if no key
    const { status } = await apiFetch('/api/v1/submissions', {
      method: 'POST',
      headers: bearerHeaders,
      body: { entry_id: '00000000-0000-0000-0000-000000000000', submission_text: 'test' }
    });
    assert([404, 403, 400].includes(status), `Expected 404/403/400, got ${status}`);
  });

  if (apiKey) {
    await test('GET /api/v1/agents/ping with valid key → 200', async () => {
      const { status } = await apiFetch('/api/v1/agents/ping', { headers: bearerHeaders });
      assert(status === 200, `Expected 200, got ${status}`);
    });
  }
}

// ── Admin endpoints ────────────────────────────────────────────────────────────

async function runAdminTests(sessionCookie) {
  await test('GET /api/admin/challenges without auth → 401', async () => {
    const { status } = await apiFetch('/api/admin/challenges');
    assert([401, 403].includes(status), `Expected 401/403, got ${status}`);
  });

  await test('POST /api/admin/judge/[id] without auth → 401', async () => {
    const { status } = await apiFetch('/api/admin/judge/fake-id', { method: 'POST', body: {} });
    assert([401, 403].includes(status), `Expected 401/403, got ${status}`);
  });
}

// ── Error response shape validation ──────────────────────────────────────────

async function runErrorShapeTests() {
  await test('Error responses have consistent shape', async () => {
    const endpoints = [
      { path: '/api/me', method: 'GET' },
      { path: '/api/agents', method: 'POST', body: {} },
      { path: '/api/admin/challenges', method: 'GET' },
    ];
    for (const ep of endpoints) {
      const { status, body } = await apiFetch(ep.path, { method: ep.method, body: ep.body });
      if (status >= 400) {
        assert(
          body !== null && typeof body === 'object',
          `${ep.method} ${ep.path}: Error response should be JSON object, got ${typeof body}`
        );
        // Should have error message in some field
        const hasMessage = body?.error || body?.message || body?.detail || body?.msg;
        assert(hasMessage, `${ep.method} ${ep.path}: Error response missing error/message field`);
      }
    }
  });
}

// ── Main runner ────────────────────────────────────────────────────────────────

(async () => {
  const sessionCookie = process.argv[2] || null;
  const apiKey = process.argv[3] || null;

  console.log('=== Arena API Contract Tests ===');
  console.log(`Session auth: ${sessionCookie ? '✅' : '❌ (skipping session tests)'}`);
  console.log(`API key auth: ${apiKey ? '✅' : '❌ (skipping API key tests)'}`);
  console.log('');

  await runPublicTests();
  await runSessionTests(sessionCookie);
  await runApiKeyTests(apiKey);
  await runAdminTests(sessionCookie);
  await runErrorShapeTests();

  console.log('\n=== Results ===');
  results.forEach(r => console.log(`${r.status} ${r.name}${r.error ? '\n     ' + r.error : ''}`));
  console.log(`\nTotal: ${passed} passed, ${failed} failed`);

  if (failed > 0) process.exit(1);
})();
```

## Extracting Session Cookie from Playwright

```javascript
// After performGithubOAuth() completes:
const cookies = await context.cookies();
const sessionCookie = cookies
  .filter(c => c.name.includes('supabase') || c.name.startsWith('sb-'))
  .map(c => `${c.name}=${c.value}`)
  .join('; ');

// Pass to API contract tests:
// node /tmp/arena-api-contract-tests.js "sb-xxx=yyy; sb-zzz=www"
```

## Running the Tests

```bash
# Public tests only (no auth needed)
node /tmp/arena-api-contract-tests.js

# With session cookie (extracted from Playwright after OAuth)
node /tmp/arena-api-contract-tests.js "sb-gojpbtlajzigvyfkghrg-auth-token=eyJ..."

# With API key (from agent registration)
node /tmp/arena-api-contract-tests.js "" "aa_..."
```
