# Testing & Quality — Forge Skill

## Overview

Tests exist to catch regressions and verify behavior. We value meaningful test coverage over 100% line coverage. Every test should have a clear reason to exist.

## What Must Be Tested

### Always Test (Non-Negotiable)

- **Auth flows** — login, logout, registration, password reset, token refresh
- **Authorization logic** — RLS policies, role-based access, permission checks
- **Payment/billing logic** — charges, subscriptions, refunds, webhooks
- **Data mutations** — create, update, delete operations
- **API routes** — request validation, response format, error handling, auth
- **Critical user paths** — core workflows that users depend on
- **Complex business logic** — algorithms, calculations, state machines
- **Database migrations** — verify data integrity after migration

### Should Test (Expected)

- **Utility functions** — pure functions with multiple edge cases
- **Custom hooks** — complex hooks with state management
- **Form validation** — Zod schemas and validation logic
- **Error handling** — error boundaries, fallback behaviors
- **Integration points** — third-party API integrations
- **Data transformations** — serialization, normalization, formatting

### Can Skip (Use Judgment)

- Simple getter/setter components with no logic
- Direct pass-through components
- Framework-provided functionality (Next.js routing, React rendering)
- Generated code (Supabase types, GraphQL codegen)
- Simple UI components that are just styling (unless they have interaction logic)

## Test Quality Checks

### Every Test Must

- [ ] Have a clear, descriptive name that explains the expected behavior
- [ ] Test one behavior per test case
- [ ] Be deterministic (no flaky tests)
- [ ] Be independent (no dependency on other tests or test order)
- [ ] Clean up after itself (no side effects on other tests)
- [ ] Assert the right thing (not just "doesn't crash")

### Test Naming Convention

```typescript
// BAD
test('user', () => { ... });
test('test 1', () => { ... });
test('it works', () => { ... });

// GOOD
test('creates user with valid email and returns user object', () => { ... });
test('returns 401 when auth token is missing', () => { ... });
test('filters posts by category and sorts by date descending', () => { ... });

// Using describe blocks
describe('createUser', () => {
  it('creates user with valid input', () => { ... });
  it('throws ValidationError when email is invalid', () => { ... });
  it('throws ConflictError when email already exists', () => { ... });
});
```

### Assertion Quality

```typescript
// BAD — weak assertions
expect(result).toBeDefined();
expect(result).not.toBeNull();
expect(users.length).toBeGreaterThan(0);

// GOOD — specific assertions
expect(result).toEqual({
  id: expect.any(String),
  email: 'user@example.com',
  role: 'user',
});
expect(users).toHaveLength(3);
expect(users[0].name).toBe('Alice');
```

### Avoid Test Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Testing implementation details | Brittle, breaks on refactor | Test behavior and outputs |
| Excessive mocking | Tests pass but code is broken | Use integration tests for critical paths |
| Copy-paste test data | Hard to maintain | Use factories or fixtures |
| `test.skip` without explanation | Unknown if intentional | Add comment or remove |
| `any` in test files | Hides type errors in test setup | Type test data properly |
| Snapshot tests for logic | Don't catch behavioral bugs | Use explicit assertions |
| Testing third-party code | Not our responsibility | Mock at the boundary |
| Sleeping in tests | Slow and flaky | Use proper async utilities (waitFor, etc.) |

### Test Organization

```typescript
// Arrange-Act-Assert pattern
test('creates post and returns it with generated id', async () => {
  // Arrange
  const input = { title: 'Test Post', body: 'Content', authorId: userId };

  // Act
  const result = await createPost(input);

  // Assert
  expect(result.id).toEqual(expect.any(String));
  expect(result.title).toBe('Test Post');
  expect(result.authorId).toBe(userId);
});
```

## Coverage Expectations

### Coverage Targets

| Area | Minimum Coverage |
|------|-----------------|
| Auth & authorization | 90%+ |
| API routes | 85%+ |
| Business logic | 85%+ |
| Utility functions | 80%+ |
| UI components (with logic) | 70%+ |
| Overall project | 70%+ |

### Coverage Is Not the Goal

- High coverage with weak assertions is worse than moderate coverage with strong assertions
- Don't write tests just to hit a coverage number
- Focus on **behavioral coverage** — are the important behaviors verified?
- Missing coverage in critical paths is more concerning than missing coverage in UI components

## Test Types

### Unit Tests (Vitest)

- Pure functions, utilities, transformations
- Isolated component logic (custom hooks)
- Fast, no external dependencies

### Integration Tests (Vitest + Supabase)

- API routes with database
- Auth flows
- Service layer functions with real dependencies

### E2E Tests (Playwright)

- Critical user journeys
- Cross-page flows
- Auth + protected routes
- Form submissions

### Component Tests (React Testing Library)

- User interaction patterns
- Conditional rendering
- Form behavior
- Accessibility (role queries)

```typescript
// GOOD — test from user's perspective
test('shows error message when form submitted with empty email', async () => {
  render(<LoginForm />);

  await userEvent.click(screen.getByRole('button', { name: /sign in/i }));

  expect(screen.getByText(/email is required/i)).toBeInTheDocument();
});

// BAD — testing implementation
test('sets error state when email is empty', () => {
  const { result } = renderHook(() => useLoginForm());
  act(() => result.current.submit());
  expect(result.current.errors.email).toBe('required');
});
```

## Review Severity

| Issue | Severity |
|-------|----------|
| No tests for auth/authorization changes | P0 — BLOCKED |
| No tests for payment/billing changes | P0 — BLOCKED |
| No tests for API route changes | P1 — High |
| Flaky test introduced | P1 — High |
| Tests with weak/missing assertions | P2 — Medium |
| Missing edge case coverage | P2 — Medium |
| Test naming doesn't describe behavior | P3 — Low |
| Test could be simplified | P3 — Low |
