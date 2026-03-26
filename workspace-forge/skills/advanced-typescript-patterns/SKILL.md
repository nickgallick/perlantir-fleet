---
name: advanced-typescript-patterns
description: Type-level programming — discriminated unions, generics mastery, branded types, utility types, end-to-end type safety patterns for Next.js + Supabase.
---

# Advanced TypeScript Patterns

## Discriminated Unions (Making Impossible States Impossible)

```ts
// Arena challenge states — each status carries ONLY its relevant data
type ChallengeStatus =
  | { status: 'draft'; title: string; prompt: string }
  | { status: 'scheduled'; title: string; prompt: string; startsAt: Date }
  | { status: 'active'; title: string; prompt: string; startsAt: Date; entriesCount: number }
  | { status: 'judging'; submissionDeadline: Date; entriesCount: number }
  | { status: 'voting'; judgeScores: JudgeScore[]; votingEndsAt: Date }
  | { status: 'complete'; results: Result[]; completedAt: Date }

// Exhaustive handling with never
function getChallengeLabel(challenge: ChallengeStatus): string {
  switch (challenge.status) {
    case 'draft': return 'Draft'
    case 'scheduled': return `Starts ${challenge.startsAt.toLocaleDateString()}`
    case 'active': return `${challenge.entriesCount} entries`
    case 'judging': return 'Judging in progress'
    case 'voting': return `Voting ends ${challenge.votingEndsAt.toLocaleDateString()}`
    case 'complete': return `Winner: ${challenge.results[0].agentName}`
    default: {
      const _exhaustive: never = challenge // ← compile error if a case is missing
      throw new Error(`Unhandled status: ${_exhaustive}`)
    }
  }
}
```

## Generics Mastery

### Constrained Generics
```ts
// Only accept objects with an 'id' field
function findById<T extends { id: string }>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id)
}

// Generic API response wrapper
type ApiResponse<T> = 
  | { success: true; data: T }
  | { success: false; error: { code: string; message: string } }

// Conditional types
type IsArray<T> = T extends any[] ? true : false
type Test1 = IsArray<string[]>  // true
type Test2 = IsArray<string>    // false

// Template literal types for type-safe routes
type ApiRoute = `/api/${string}`
type ChallengeRoute = `/api/challenges/${string}`

function fetchApi(route: ApiRoute) { /* ... */ }
fetchApi('/api/challenges/123') // ✅
fetchApi('/random')              // ❌ compile error
```

### infer Keyword
```ts
// Extract return type of an async function
type AsyncReturnType<T extends (...args: any) => Promise<any>> = 
  T extends (...args: any) => Promise<infer R> ? R : never

// Extract element type from array
type ElementOf<T> = T extends (infer E)[] ? E : never
type User = ElementOf<User[]> // User

// Extract Zod inferred type (how z.infer works under the hood)
type InferZod<T extends z.ZodType> = T extends z.ZodType<infer O> ? O : never
```

## Branded/Opaque Types

```ts
// Prevent mixing up IDs — compile-time safety, zero runtime cost
type Brand<T, B extends string> = T & { readonly __brand: B }

type UserId = Brand<string, 'UserId'>
type AgentId = Brand<string, 'AgentId'>
type ChallengeId = Brand<string, 'ChallengeId'>
type Cents = Brand<number, 'Cents'>

// Constructor functions
function UserId(id: string): UserId { return id as UserId }
function Cents(amount: number): Cents { return Math.round(amount) as Cents }

// Now these are compile errors:
function getAgent(agentId: AgentId) { /* ... */ }
const userId = UserId('abc-123')
getAgent(userId) // ❌ Type 'UserId' is not assignable to 'AgentId'

// Money is always in cents — no floating point confusion
function transfer(from: UserId, to: UserId, amount: Cents) { /* ... */ }
transfer(UserId('a'), UserId('b'), Cents(500)) // $5.00 represented as 500 cents
transfer(UserId('a'), UserId('b'), 500)         // ❌ number is not Cents
```

## Utility Type Patterns

```ts
// DeepPartial — for patch/update operations
type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K]
}

// StrictOmit — errors if key doesn't exist (unlike Omit)
type StrictOmit<T, K extends keyof T> = Omit<T, K>

// satisfies — validate without widening
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
} satisfies Record<string, string | number>
// config.apiUrl is typed as 'https://api.example.com' (literal), not string

// as const — deep readonly + literal types
const WEIGHT_CLASSES = ['Frontier', 'Contender', 'Scrapper', 'Underdog'] as const
type WeightClass = typeof WEIGHT_CLASSES[number] // 'Frontier' | 'Contender' | 'Scrapper' | 'Underdog'
```

## End-to-End Type Safety

```ts
// 1. Zod schema (single source of truth)
const CreateEntrySchema = z.object({
  challengeId: z.string().uuid(),
  agentId: z.string().uuid(),
  idempotencyKey: z.string().uuid(),
})

// 2. TypeScript type (inferred from Zod)
type CreateEntryInput = z.infer<typeof CreateEntrySchema>

// 3. Server Action (validates at boundary)
'use server'
export async function createEntry(input: CreateEntryInput) {
  const parsed = CreateEntrySchema.safeParse(input)
  if (!parsed.success) return { error: parsed.error.flatten() }
  // parsed.data is fully typed
}

// 4. Client hook (type-safe call)
function useCreateEntry() {
  return useMutation({
    mutationFn: (input: CreateEntryInput) => createEntry(input)
    // TypeScript ensures client sends exactly the right shape
  })
}

// 5. Database types (generated from Supabase)
type Entry = Database['public']['Tables']['entries']['Row']
type InsertEntry = Database['public']['Tables']['entries']['Insert']
// Supabase client returns typed results
```

## Type-Safe API Client
```ts
// Centralized, typed API client
type Routes = {
  'GET /api/challenges': { response: Challenge[]; query: { weightClass?: string } }
  'GET /api/challenges/:id': { response: Challenge; params: { id: string } }
  'POST /api/entries': { response: Entry; body: CreateEntryInput }
}

async function api<R extends keyof Routes>(
  route: R,
  options?: Omit<Routes[R], 'response'>
): Promise<Routes[R]['response']> {
  // Implementation: parse route, substitute params, validate body
  // The type system ensures correct usage at every call site
}

const challenges = await api('GET /api/challenges', { query: { weightClass: 'Frontier' } })
// challenges is typed as Challenge[]
```

## Sources
- type-challenges repository (170+ exercises)
- ts-reset (Matt Pocock) — TypeScript improvement patterns
- trpc — end-to-end type safety implementation
- zod — schema-driven type inference

## Changelog
- 2026-03-21: Initial skill — advanced TypeScript patterns
