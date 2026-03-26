---
name: typescript-strictness
description: TypeScript type safety review — catching any, unsafe assertions, weak validation, and common TS mistakes in Next.js + Supabase applications.
---

# TypeScript Strictness Review

## Quick Reference — Top 10 TypeScript Red Flags

1. [ ] **`any` type** — every instance must be justified in a comment
2. [ ] **`as` assertion** — usually means the types are wrong, not the code
3. [ ] **Non-null assertion `!`** — hiding potential null/undefined runtime crash
4. [ ] **`@ts-ignore`** — technical debt. Must have a TODO with ticket/issue link.
5. [ ] **Missing Zod validation** at API boundaries (Route Handlers, Server Actions, webhooks)
6. [ ] **Duplicated types** — hand-written type that duplicates a Zod schema or DB type
7. [ ] **`Object`, `Function`, `{}`** as types — too broad, accept anything
8. [ ] **Missing return type** on exported functions — implicit `any` in some configs
9. [ ] **Supabase queries without generated types** — using `any` for query results
10. [ ] **`strict: true` disabled** in tsconfig — non-negotiable, must be enabled

---

## Type Safety Violations

### The `any` Audit
```ts
// ❌ P1 — always flag
function processData(data: any) { ... }
const result: any = await fetchSomething()
catch (error: any) { ... }

// ✅ Proper types
function processData(data: UserInput) { ... }
const result: ApiResponse = await fetchSomething()
catch (error) {
  if (error instanceof Error) { ... }
  // or use a type guard
}

// ⚠️ Acceptable WITH comment
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const parsed = JSON.parse(raw) as any // TODO: add Zod schema — JIRA-123
```

### `as` Assertions
```ts
// ❌ Lying to the compiler
const user = data as User // what if data is null? or missing fields?

// ❌ Double assertion (the compiler is screaming)
const id = input as unknown as number

// ✅ Type narrowing
if (isUser(data)) {
  // data is now typed as User — verified at runtime
}

// ✅ Zod parse (validates AND types)
const user = UserSchema.parse(data) // throws if invalid
const user = UserSchema.safeParse(data) // returns { success, data, error }
```

### Non-null Assertions `!`
```ts
// ❌ Runtime crash waiting to happen
const user = users.find(u => u.id === id)
console.log(user!.name) // TypeError if user not found

// ✅ Handle the null case
const user = users.find(u => u.id === id)
if (!user) {
  return { error: 'User not found' }
}
console.log(user.name) // safely typed as User, not User | undefined
```

---

## Zod + TypeScript Patterns

### Infer Types from Schemas (DRY)
```ts
// ❌ Duplicated — types and schema can drift apart
interface CreateUserInput {
  name: string
  email: string
}
const CreateUserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
})

// ✅ Single source of truth
const CreateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
})
type CreateUserInput = z.infer<typeof CreateUserSchema>
```

### Trust Boundaries (where Zod is MANDATORY)
1. **API Route Handlers** — any `req.json()` or `req.formData()`
2. **Server Actions** — any `formData.get()` parameters
3. **Webhook handlers** — external services send untrusted payloads
4. **URL search params** — user-controlled strings from `searchParams`
5. **External API responses** — third-party APIs can change without notice

```ts
// Server Action with Zod validation
'use server'
const schema = z.object({ email: z.string().email() })

export async function subscribe(formData: FormData) {
  const result = schema.safeParse({ email: formData.get('email') })
  if (!result.success) return { error: result.error.flatten() }
  // result.data is typed and validated
}
```

### Supabase Type Generation
```bash
# Generate types from your database schema
npx supabase gen types typescript --project-id YOUR_PROJECT > src/types/database.ts
```
```ts
// ❌ Untyped query — result is any
const { data } = await supabase.from('users').select('*')

// ✅ Typed with generated types
import { Database } from '@/types/database'
type User = Database['public']['Tables']['users']['Row']
const { data } = await supabase.from('users').select('id, name, email')
// data is typed as Pick<User, 'id' | 'name' | 'email'>[] | null
```

---

## tsconfig Enforcement

### Non-Negotiable Settings
```json
{
  "compilerOptions": {
    "strict": true,                    // enables all strict checks
    "noUncheckedIndexedAccess": true,  // arr[0] returns T | undefined
    "exactOptionalProperties": true,   // { x?: string } means "missing", not "undefined"
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

**Flag immediately if `strict: true` is disabled or any of these are set to `false`.**

### What ts-reset Fixes (from the repo)
The `@total-typescript/ts-reset` package patches TypeScript's built-in types:
- `JSON.parse()` returns `unknown` instead of `any`
- `.filter(Boolean)` properly narrows types (removes falsy)
- `Array.isArray()` narrows correctly
- `.includes()` and `.has()` work with wider types
- `Map` constructor infers key/value types

**Review check:** If `ts-reset` is installed, these patterns are safer. If not, flag `JSON.parse()` results used without validation.

---

## Common Next.js TypeScript Mistakes

```tsx
// ❌ Untyped params
export default function UserPage({ params }) { // params is any
  return <div>{params.id}</div>
}

// ✅ Typed params
export default async function UserPage({ 
  params 
}: { 
  params: Promise<{ id: string }> // Next.js 15+ async params
}) {
  const { id } = await params
  return <div>{id}</div>
}

// ❌ Untyped searchParams
export default function SearchPage({ searchParams }) { // any
  const query = searchParams.q // could be string | string[] | undefined
}

// ✅ Validate searchParams
const SearchParamsSchema = z.object({
  q: z.string().optional().default(''),
  page: z.coerce.number().int().positive().default(1),
})
```

## Sources
- total-typescript/ts-reset documentation
- colinhacks/zod documentation
- TypeScript strict mode documentation
- Supabase type generation guide

## Changelog
- 2026-03-21: Initial skill — TypeScript strictness review
