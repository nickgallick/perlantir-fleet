---
name: testing-review
description: Test coverage and quality review — what needs tests, test quality assessment, anti-patterns, and the testing pyramid for Next.js + Supabase applications.
---

# Testing Review

## Quick Reference — PR Test Checklist

**When reviewing a PR, check:**
1. [ ] Every new function with branching logic has a test
2. [ ] Every new API route has at least one happy-path + one error-path test
3. [ ] Every new Server Action has validation tested
4. [ ] Financial/payment logic has comprehensive tests (P0 if missing)
5. [ ] Auth flows have test coverage
6. [ ] Edge cases covered: empty arrays, null inputs, boundary values
7. [ ] Tests are deterministic (no time-dependent, no random, no network)
8. [ ] Test descriptions describe behavior, not implementation

---

## What to Flag When Tests Are Missing

### P0 — Block merge without tests:
- Payment/financial logic (transfers, billing, coin transactions)
- Authentication flows (login, signup, token refresh, logout)
- Authorization checks (RLS policies, ownership verification)
- Data migrations that modify existing data

### P1 — Should have tests:
- Complex business logic with branching (>2 branches)
- API routes with input validation
- Server Actions that mutate data
- Utility functions used in >2 places
- Error handling paths

### OK without tests (don't flag):
- Pure UI components (just layout/styling, no logic)
- Type-only files (`types.ts`, `interfaces.ts`)
- Configuration files (`next.config.ts`, `tailwind.config.ts`)
- One-line utility functions that are trivially correct
- Generated code (Supabase types, migration files)

---

## Test Quality Review

### Anti-Pattern 1: Testing Implementation, Not Behavior
```ts
// ❌ Tests internal state — breaks if you refactor
it('sets loading to true', () => {
  const { result } = renderHook(() => useUsers())
  expect(result.current.loading).toBe(true)
})

// ✅ Tests behavior — survives refactors
it('shows loading spinner while fetching users', async () => {
  render(<UserList />)
  expect(screen.getByRole('progressbar')).toBeInTheDocument()
  await waitFor(() => {
    expect(screen.getByText('John Doe')).toBeInTheDocument()
  })
})
```

### Anti-Pattern 2: Tests with No Assertions
```ts
// ❌ Passes but verifies NOTHING
it('renders without crashing', () => {
  render(<Dashboard />)
})

// ✅ Actually verifies something
it('renders the dashboard title', () => {
  render(<Dashboard />)
  expect(screen.getByRole('heading', { name: 'Dashboard' })).toBeInTheDocument()
})
```

### Anti-Pattern 3: Over-Mocking
```ts
// ❌ Testing mocks, not code — this test will pass even if fetchUsers is broken
vi.mock('@/lib/api', () => ({
  fetchUsers: vi.fn().mockResolvedValue([{ id: 1, name: 'Test' }])
}))
it('displays users', async () => {
  render(<UserList />)
  await waitFor(() => expect(screen.getByText('Test')).toBeInTheDocument())
})
// This tells you the component renders mock data, not that your API integration works

// ✅ Integration test with real data layer (test database)
it('displays users from the database', async () => {
  await seedTestDatabase([{ id: 1, name: 'Test' }])
  render(<UserList />)
  await waitFor(() => expect(screen.getByText('Test')).toBeInTheDocument())
})
```

### Anti-Pattern 4: Only Happy Path
```ts
// ❌ Only tests success case
it('creates a user', async () => {
  const result = await createUser({ name: 'John', email: 'john@test.com' })
  expect(result.success).toBe(true)
})

// ✅ Tests error cases too
it('rejects invalid email', async () => {
  const result = await createUser({ name: 'John', email: 'not-an-email' })
  expect(result.success).toBe(false)
  expect(result.error).toContain('email')
})

it('rejects duplicate email', async () => {
  await createUser({ name: 'John', email: 'john@test.com' })
  const result = await createUser({ name: 'Jane', email: 'john@test.com' })
  expect(result.success).toBe(false)
})

it('handles database errors gracefully', async () => {
  // Simulate DB failure
  vi.spyOn(supabase, 'from').mockRejectedValueOnce(new Error('connection lost'))
  const result = await createUser({ name: 'John', email: 'john@test.com' })
  expect(result.success).toBe(false)
  expect(result.error).not.toContain('connection lost') // no internal details leaked
})
```

### Anti-Pattern 5: Flaky Tests
Sources of flakiness:
- `Date.now()` or `new Date()` in assertions (use `vi.useFakeTimers()`)
- `setTimeout` races (use `vi.advanceTimersByTime()`)
- Order-dependent tests (test B depends on state from test A)
- Network calls to real APIs (mock them or use MSW)

### Anti-Pattern 6: Array Index as Key
```tsx
// Not a test issue, but flag in component tests:
// ❌ Causes bugs on reorder, delete, insert
{items.map((item, i) => <ListItem key={i} item={item} />)}

// ✅ Stable identity
{items.map(item => <ListItem key={item.id} item={item} />)}
```

---

## Testing Architecture for Our Stack

### The Pyramid
```
         ┌──────┐
         │ E2E  │  Playwright: 5-10 critical user journeys
         │      │  Login → Create → View → Edit → Delete
         ├──────┤
         │ Integ│  Vitest + real DB: API routes, Server Actions,
         │ation │  data layer, auth flows (20-50 tests)
         ├──────┤
         │ Unit │  Vitest: pure functions, utils, hooks,
         │      │  validation schemas, transforms (100+ tests)
         └──────┘
```

### Tool Mapping
| Layer | Tool | What to Test |
|-------|------|-------------|
| Unit | Vitest | Pure functions, Zod schemas, transforms, hooks |
| Integration | Vitest + Supabase test project | API routes, Server Actions, DB queries, RLS policies |
| E2E | Playwright | Full user journeys: signup → use feature → logout |
| Component | Vitest + Testing Library | User interaction, form submission, error states |

### React Testing Library Philosophy (from the repo)
> "The more your tests resemble the way your software is used, the more confidence they can give you."

- Query by role, label, text — not by class, ID, or test-id
- Fire real events (`userEvent.click`) not synthetic (`fireEvent.click`)
- Assert on what the user sees, not on component internals
- If you can't test something without accessing component internals, your component API needs refactoring

---

## Database/RLS Test Patterns

```ts
// Test RLS policies directly
describe('RLS: users table', () => {
  it('user can only read own profile', async () => {
    const userA = await createTestUser()
    const userB = await createTestUser()
    
    const clientA = createClientAs(userA)
    const { data } = await clientA.from('profiles').select('*')
    
    expect(data).toHaveLength(1)
    expect(data[0].id).toBe(userA.id)
    // userB's profile is not visible
  })
  
  it('unauthenticated user cannot read profiles', async () => {
    const anonClient = createAnonClient()
    const { data, error } = await anonClient.from('profiles').select('*')
    expect(data).toHaveLength(0) // RLS blocks everything
  })
})
```

## Sources
- testing-library/react-testing-library documentation and guiding principles
- vitest-dev/vitest configuration and best practices
- Kent C. Dodds: Testing Implementation Details
- Supabase testing documentation

## Changelog
- 2026-03-21: Initial skill — test review for Next.js + Supabase
