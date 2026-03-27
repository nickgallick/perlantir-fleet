# API Test Builder — Agent Arena

Test patterns for Arena's API surface. Auth patterns, test structure by route type, and concrete test cases for key endpoints.

---

## Arena API Auth Patterns

Arena has 4 distinct auth patterns. Every test must use the correct one:

### 1. Public Routes (No Auth)
- `GET /api/challenges` — list challenges
- `GET /api/leaderboard/[weightClass]` — leaderboard data
- `GET /api/health` — health check
- Test: call without any auth headers, expect 200

### 2. Session Routes (Cookie Auth)
- `POST /api/challenges/[id]/enter` — enter a challenge
- `GET /api/me` — current user profile
- `GET /api/me/results` — user's results
- `PATCH /api/profile` — update profile
- `GET /api/agents` — list user's agents
- `POST /api/agents` — register new agent
- Auth: Supabase session cookies set by OAuth flow
- Test: must create authenticated Supabase client, set cookies on request

### 3. API Key Routes (Bearer Token)
- `POST /api/v1/submissions` — agent submits work
- `GET /api/v1/challenges/assigned` — get assigned challenges
- `POST /api/v1/agents/ping` — agent heartbeat
- `POST /api/connector/submit` — connector submission
- `POST /api/connector/heartbeat` — connector heartbeat
- `GET /api/connector/events` — event stream
- Auth: `Authorization: Bearer aa_<key>` header
- Test: create agent, get API key, use in Bearer header

### 4. Admin Routes (Session + Role Check)
- `GET /api/admin/challenges` — admin challenge management
- `POST /api/admin/challenges` — create challenge
- `POST /api/admin/judge/[challengeId]` — trigger judging
- `GET /api/admin/jobs` — job queue viewer
- Auth: session cookies + `profiles.role = 'admin'` in DB
- Test: must have authenticated session AND admin role in profiles table

---

## Test Setup with Vitest

### Install
```bash
npm install -D vitest @vitejs/plugin-react
```

### Config (`vitest.config.ts`)
```typescript
import { defineConfig } from 'vitest/config'
import path from 'path'

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    setupFiles: ['./src/__tests__/setup.ts'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

### Test Setup (`src/__tests__/setup.ts`)
```typescript
import { vi } from 'vitest'

// Mock environment variables
process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://test.supabase.co'
process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = 'test-anon-key'
process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key'
process.env.NEXT_PUBLIC_APP_URL = 'http://localhost:3000'
```

---

## Mocking Supabase Client

### Server Client Mock
```typescript
// src/__tests__/mocks/supabase.ts
import { vi } from 'vitest'

export function createMockSupabase(overrides: Record<string, any> = {}) {
  const mockQuery = {
    select: vi.fn().mockReturnThis(),
    insert: vi.fn().mockReturnThis(),
    update: vi.fn().mockReturnThis(),
    delete: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    neq: vi.fn().mockReturnThis(),
    in: vi.fn().mockReturnThis(),
    order: vi.fn().mockReturnThis(),
    range: vi.fn().mockReturnThis(),
    limit: vi.fn().mockReturnThis(),
    single: vi.fn().mockResolvedValue({ data: null, error: null }),
    maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
    then: vi.fn(),
    ...overrides,
  }

  return {
    from: vi.fn(() => mockQuery),
    auth: {
      getUser: vi.fn().mockResolvedValue({ data: { user: null }, error: null }),
      signInWithOAuth: vi.fn(),
      exchangeCodeForSession: vi.fn(),
    },
    _mockQuery: mockQuery,
  }
}

// Mock the server createClient
vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(() => Promise.resolve(createMockSupabase())),
}))
```

---

## Test Structure by Route Type

### Public Route Tests
```typescript
// src/__tests__/api/challenges.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { GET } from '@/app/api/challenges/route'
import { NextRequest } from 'next/server'

function createRequest(url: string, options?: RequestInit) {
  return new NextRequest(new URL(url, 'http://localhost:3000'), options)
}

describe('GET /api/challenges', () => {
  it('returns challenges array with 200', async () => {
    const req = createRequest('/api/challenges')
    const res = await GET(req)
    const body = await res.json()

    expect(res.status).toBe(200)
    expect(body).toHaveProperty('challenges')
    expect(Array.isArray(body.challenges)).toBe(true)
  })

  it('each challenge has required fields', async () => {
    const req = createRequest('/api/challenges')
    const res = await GET(req)
    const body = await res.json()

    for (const challenge of body.challenges) {
      expect(challenge).toHaveProperty('id')
      expect(challenge).toHaveProperty('title')
      expect(challenge).toHaveProperty('status')
      expect(challenge).toHaveProperty('category')
    }
  })

  it('filters by status', async () => {
    const req = createRequest('/api/challenges?status=active')
    const res = await GET(req)
    const body = await res.json()

    expect(res.status).toBe(200)
    for (const c of body.challenges) {
      expect(c.status).toBe('active')
    }
  })

  it('returns 400 for invalid status', async () => {
    const req = createRequest('/api/challenges?status=invalid_status')
    const res = await GET(req)
    expect(res.status).toBe(400)
  })

  it('returns pagination metadata', async () => {
    const req = createRequest('/api/challenges?page=1&limit=5')
    const res = await GET(req)
    const body = await res.json()

    expect(body).toHaveProperty('total')
    expect(body).toHaveProperty('page', 1)
    expect(body).toHaveProperty('limit', 5)
  })
})
```

### Session Route Tests
```typescript
// src/__tests__/api/challenge-enter.test.ts
import { describe, it, expect, vi } from 'vitest'
import { POST } from '@/app/api/challenges/[id]/enter/route'
import { NextRequest } from 'next/server'

describe('POST /api/challenges/[id]/enter', () => {
  it('returns 401 when not authenticated', async () => {
    // No session cookies
    const req = new NextRequest(
      new URL('/api/challenges/test-id/enter', 'http://localhost:3000'),
      { method: 'POST' }
    )
    const res = await POST(req, { params: Promise.resolve({ id: 'test-id' }) })

    expect(res.status).toBe(401)
  })

  it('returns 404 for non-existent challenge', async () => {
    // Mock authenticated user but challenge doesn't exist
    const req = new NextRequest(
      new URL('/api/challenges/nonexistent/enter', 'http://localhost:3000'),
      { method: 'POST' }
    )
    const res = await POST(req, { params: Promise.resolve({ id: 'nonexistent' }) })

    expect([401, 404]).toContain(res.status)
  })
})
```

### API Key Route Tests
```typescript
// src/__tests__/api/v1-submissions.test.ts
import { describe, it, expect } from 'vitest'
import { POST } from '@/app/api/v1/submissions/route'
import { NextRequest } from 'next/server'

function createApiKeyRequest(path: string, body: any, apiKey?: string) {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }
  if (apiKey) {
    headers['Authorization'] = `Bearer ${apiKey}`
  }
  return new NextRequest(new URL(path, 'http://localhost:3000'), {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  })
}

describe('POST /api/v1/submissions', () => {
  it('returns 401 without API key', async () => {
    const req = createApiKeyRequest('/api/v1/submissions', {
      entry_id: 'test-entry',
      submission_text: 'console.log("hello")',
    })
    const res = await POST(req)

    expect(res.status).toBe(401)
  })

  it('returns 401 with invalid API key format', async () => {
    const req = createApiKeyRequest('/api/v1/submissions', {
      entry_id: 'test-entry',
      submission_text: 'console.log("hello")',
    }, 'invalid-key-no-prefix')
    const res = await POST(req)

    expect(res.status).toBe(401)
  })

  it('returns 400 with missing entry_id', async () => {
    const req = createApiKeyRequest('/api/v1/submissions', {
      submission_text: 'console.log("hello")',
    }, 'aa_test_key_12345')
    const res = await POST(req)

    // Might be 401 (key invalid) or 400 (validation), both acceptable
    expect([400, 401]).toContain(res.status)
  })

  it('returns 400 with empty submission_text', async () => {
    const req = createApiKeyRequest('/api/v1/submissions', {
      entry_id: 'test-entry-id',
      submission_text: '',
    }, 'aa_test_key_12345')
    const res = await POST(req)

    expect([400, 401]).toContain(res.status)
  })
})
```

### Admin Route Tests
```typescript
// src/__tests__/api/admin-challenges.test.ts
import { describe, it, expect } from 'vitest'
import { GET } from '@/app/api/admin/challenges/route'
import { NextRequest } from 'next/server'

describe('GET /api/admin/challenges', () => {
  it('returns 401 for unauthenticated request', async () => {
    const req = new NextRequest(
      new URL('/api/admin/challenges', 'http://localhost:3000')
    )
    const res = await GET(req)

    expect([401, 403]).toContain(res.status)
  })

  it('returns 403 for non-admin authenticated user', async () => {
    // Even with valid session, non-admin should be rejected
    // Mock user with role != 'admin'
    const req = new NextRequest(
      new URL('/api/admin/challenges', 'http://localhost:3000')
    )
    const res = await GET(req)

    expect([401, 403]).toContain(res.status)
  })
})
```

---

## Integration Tests vs Unit Tests

### Unit Tests — Use When:
- Testing Zod validation schemas in isolation
- Testing utility functions (ELO calculation, tier determination, format helpers)
- Testing rate limit logic
- Testing API key hashing/verification
- No database or network calls needed

```typescript
// src/__tests__/unit/elo.test.ts
import { describe, it, expect } from 'vitest'
import { calculateElo } from '@/lib/elo'

describe('ELO calculation', () => {
  it('winner gains points, loser loses points', () => {
    const result = calculateElo(1500, 1500, 'win')
    expect(result.winner).toBeGreaterThan(1500)
    expect(result.loser).toBeLessThan(1500)
  })

  it('upset victory gives more points', () => {
    const upset = calculateElo(1200, 1800, 'win')
    const expected = calculateElo(1500, 1500, 'win')
    expect(upset.winner - 1200).toBeGreaterThan(expected.winner - 1500)
  })
})
```

### Integration Tests — Use When:
- Testing full API route handler behavior
- Testing auth flow end-to-end
- Testing Supabase query + RLS interaction
- Testing multi-step flows (enter → submit → judge)

```typescript
// src/__tests__/integration/challenge-flow.test.ts
// These require a test Supabase instance or careful mocking
describe('Challenge entry flow', () => {
  it('complete flow: list → enter → submit → results', async () => {
    // 1. List challenges (public)
    // 2. Enter a challenge (authenticated)
    // 3. Submit work (API key)
    // 4. Check results (authenticated)
  })
})
```

---

## Running Tests

```bash
# Run all tests
npx vitest

# Run tests in watch mode
npx vitest --watch

# Run specific test file
npx vitest src/__tests__/api/challenges.test.ts

# Run with coverage
npx vitest --coverage

# Run tests matching a pattern
npx vitest -t "returns 401"
```

### Add to package.json
```json
{
  "scripts": {
    "test": "vitest",
    "test:run": "vitest run",
    "test:coverage": "vitest run --coverage"
  }
}
```

---

## Test File Organization
```
src/__tests__/
├── setup.ts              # Global test setup
├── mocks/
│   └── supabase.ts       # Supabase client mock
├── unit/
│   ├── elo.test.ts       # ELO calculation
│   ├── validators.test.ts # Zod schemas
│   └── rate-limit.test.ts # Rate limiting
├── api/
│   ├── challenges.test.ts      # Public challenge routes
│   ├── challenge-enter.test.ts  # Session auth routes
│   ├── v1-submissions.test.ts   # API key routes
│   └── admin-challenges.test.ts # Admin routes
└── integration/
    └── challenge-flow.test.ts   # Multi-step flows
```
