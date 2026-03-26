# TypeScript Mastery — Forge Skill

## Overview

TypeScript is our primary language. Strict type safety prevents entire categories of runtime errors. We enforce zero tolerance for type shortcuts.

## Zero Tolerance List

These are NEVER acceptable in reviewed code:

| Pattern | Why It's Banned | Fix |
|---------|----------------|-----|
| `any` | Defeats the type system entirely | Use `unknown`, generics, or proper types |
| `// @ts-ignore` | Hides real errors | Fix the type error properly |
| `// @ts-expect-error` without explanation | Suppresses without documenting why | Add a comment explaining the specific issue, or fix it |
| `as` type assertions (most cases) | Lies to the compiler | Use type guards or narrowing |
| Non-null assertions `!` (most cases) | Assumes without checking | Use optional chaining or null checks |
| `Object`, `Function`, `{}` as types | Too broad to be useful | Use specific interfaces or type aliases |
| Implicit `any` from missing return types on exports | Public API contract unclear | Add explicit return types on exported functions |

### Exceptions

- `as const` is fine — it narrows, not widens
- `as` after a type guard in the same scope — acceptable when TypeScript can't infer
- `// @ts-expect-error` in test files for intentional negative testing — acceptable with comment
- `!` after `.getElementById()` in controlled DOM (rare in React) — acceptable with comment

## Required Patterns

### Discriminated Unions for State

```typescript
// BAD
type State = {
  loading: boolean;
  error: string | null;
  data: User[] | null;
};

// GOOD
type State =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'error'; error: string }
  | { status: 'success'; data: User[] };
```

### Exhaustive Switch Checks

```typescript
function handleStatus(status: State['status']): string {
  switch (status) {
    case 'idle': return 'Waiting';
    case 'loading': return 'Loading...';
    case 'error': return 'Failed';
    case 'success': return 'Done';
    default: {
      const _exhaustive: never = status;
      return _exhaustive;
    }
  }
}
```

### Const Assertions for Literals

```typescript
// BAD
const ROUTES = {
  home: '/',
  profile: '/profile',
};
// type: { home: string; profile: string }

// GOOD
const ROUTES = {
  home: '/',
  profile: '/profile',
} as const;
// type: { readonly home: '/'; readonly profile: '/profile' }
```

### Branded Types for IDs

```typescript
type UserId = string & { readonly __brand: 'UserId' };
type PostId = string & { readonly __brand: 'PostId' };

// Prevents accidentally passing a PostId where UserId is expected
function getUser(id: UserId): Promise<User> { ... }
```

## Zod Integration

Zod is our runtime validation library. It bridges the gap between TypeScript's compile-time checks and runtime data.

### Schema as Single Source of Truth

```typescript
// GOOD — derive type from schema
const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'user', 'viewer']),
});

type User = z.infer<typeof UserSchema>;

// BAD — duplicating type and schema
interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user' | 'viewer';
}
const UserSchema = z.object({ ... }); // duplicated!
```

### Validate at Boundaries

```typescript
// API route — validate incoming request
export async function POST(request: Request) {
  const body = await request.json();
  const result = CreateUserSchema.safeParse(body);

  if (!result.success) {
    return Response.json(
      { error: result.error.flatten() },
      { status: 400 }
    );
  }

  // result.data is fully typed from here
  const user = await createUser(result.data);
}
```

### Transform and Refine

```typescript
const DateRangeSchema = z.object({
  start: z.string().datetime(),
  end: z.string().datetime(),
}).refine(
  (data) => new Date(data.start) < new Date(data.end),
  { message: 'Start date must be before end date' }
);
```

## Type Narrowing Examples

### User-Defined Type Guards

```typescript
function isApiError(error: unknown): error is ApiError {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    'message' in error
  );
}
```

### `in` Operator Narrowing

```typescript
type Success = { data: User };
type Failure = { error: string };
type Result = Success | Failure;

function handle(result: Result) {
  if ('error' in result) {
    // TypeScript knows: result is Failure
    console.error(result.error);
  } else {
    // TypeScript knows: result is Success
    console.log(result.data);
  }
}
```

### `satisfies` Operator

```typescript
// Validates type without widening
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
  retries: 3,
} satisfies Config;
// config.apiUrl is still string literal type, not just string
```

## Review Severity

| Issue | Severity |
|-------|----------|
| `any` in production code | P1 — High |
| Missing Zod validation at API boundary | P1 — High |
| Type assertion hiding a real bug | P1 — High |
| Missing return type on exported function | P2 — Medium |
| Could use discriminated union but doesn't | P2 — Medium |
| Missing exhaustive check in switch | P2 — Medium |
| Unnecessary type assertion (compiler can infer) | P3 — Low |
