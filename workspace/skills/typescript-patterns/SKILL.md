# TypeScript Patterns — Agent Arena

TypeScript patterns for Arena's codebase. Zod validation, type-safe API routes, Supabase generated types, strict mode rules, and utility types.

---

## Zod Schemas — Arena's Validation Layer

Arena uses Zod for all request validation. Every API route that accepts input validates through Zod before touching the database.

### Defining Schemas
```typescript
// src/lib/validators/submission.ts
import { z } from 'zod'

export const submissionSchema = z.object({
  entry_id: z.string().uuid('entry_id must be a valid UUID'),
  submission_text: z.string().min(1, 'Submission cannot be empty').max(50_000, 'Submission too large'),
  submission_files: z.array(z.object({
    filename: z.string().min(1).max(255),
    content: z.string().max(100_000),
    language: z.string().optional(),
  })).max(20, 'Maximum 20 files').optional(),
})

export type SubmissionInput = z.infer<typeof submissionSchema>
// SubmissionInput = { entry_id: string; submission_text: string; submission_files?: {...}[] }
```

### Arena's Existing Validators
```
src/lib/validators/
├── admin.ts          # Admin challenge creation, job management
├── agent.ts          # Agent registration, update
├── challenge.ts      # Challenge query params, challenge creation
├── connector.ts      # Connector heartbeat, submit payloads
├── event-stream.ts   # Event stream query params
└── submission.ts     # Agent submission payload
```

### Challenge Query Schema (Reusable Filter Pattern)
```typescript
// src/lib/validators/challenge.ts
import { z } from 'zod'

export const challengeQuerySchema = z.object({
  status: z.enum(['upcoming', 'active', 'judging', 'complete']).optional(),
  category: z.string().optional(),
  weight_class: z.string().optional(),
  format: z.enum(['standard', 'creative', 'speed']).optional(),
  page: z.number().int().min(1).default(1),
  limit: z.number().int().min(1).max(100).default(20),
})

export type ChallengeQuery = z.infer<typeof challengeQuerySchema>
```

### Agent Registration Schema
```typescript
// src/lib/validators/agent.ts
import { z } from 'zod'

export const registerAgentSchema = z.object({
  name: z
    .string()
    .min(2, 'Agent name must be at least 2 characters')
    .max(32, 'Agent name must be 32 characters or less')
    .regex(/^[a-zA-Z0-9_-]+$/, 'Only letters, numbers, hyphens, and underscores'),
  model_name: z.string().min(1, 'Model name is required'),
  description: z.string().max(500).optional(),
  avatar_url: z.string().url().optional(),
})

export type RegisterAgentInput = z.infer<typeof registerAgentSchema>
```

### Using Zod in API Routes
```typescript
export async function POST(request: NextRequest) {
  // Parse body as unknown first — never trust it
  const body = await request.json().catch(() => null)
  if (!body) {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
  }

  const parsed = registerAgentSchema.safeParse(body)
  if (!parsed.success) {
    // Return the first validation error
    return NextResponse.json(
      { error: parsed.error.issues[0].message },
      { status: 400 }
    )
  }

  // parsed.data is now fully typed as RegisterAgentInput
  const { name, model_name, description } = parsed.data
  // ... proceed with validated data
}
```

---

## Type-Safe API Routes

### Request Body Pattern
```typescript
// ❌ WRONG — never use `as any` or trust raw input
const body = await request.json() as any
const { name } = body // no type safety

// ❌ WRONG — type assertion without validation
const body = await request.json() as RegisterAgentInput
// assertion doesn't validate at runtime — user could send anything

// ✅ CORRECT — parse as unknown, validate with Zod
const raw: unknown = await request.json().catch(() => null)
const parsed = registerAgentSchema.safeParse(raw)
if (!parsed.success) return NextResponse.json({ error: parsed.error.issues[0].message }, { status: 400 })
const { name, model_name } = parsed.data // fully typed and validated
```

### Typed Response Pattern
```typescript
// Define response types
type ChallengesResponse = {
  challenges: Challenge[]
  total: number
  page: number
  limit: number
}

type ErrorResponse = {
  error: string
}

// Route handler returns typed responses
export async function GET(request: NextRequest): Promise<NextResponse<ChallengesResponse | ErrorResponse>> {
  // ... fetch data
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
  return NextResponse.json({ challenges: data, total: count ?? 0, page, limit })
}
```

### URL Params Pattern (App Router)
```typescript
// Next.js 15+ params are now a Promise
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params

  // Validate the ID format
  if (!z.string().uuid().safeParse(id).success) {
    return NextResponse.json({ error: 'Invalid challenge ID' }, { status: 400 })
  }

  // ... use id
}
```

---

## Supabase Generated Types

### Generating Types from Schema
```bash
# Generate types from your Supabase project
npx supabase gen types typescript --project-id gojpbtlajzigvyfkghrg > src/types/database.ts
```

### Using Generated Types
```typescript
// src/types/database.ts (auto-generated)
export type Database = {
  public: {
    Tables: {
      challenges: {
        Row: {
          id: string
          title: string
          description: string | null
          status: 'upcoming' | 'active' | 'judging' | 'complete'
          category: string
          // ... all columns
        }
        Insert: {
          id?: string
          title: string
          // ... required for insert
        }
        Update: {
          title?: string
          status?: 'upcoming' | 'active' | 'judging' | 'complete'
          // ... all optional for update
        }
      }
      // ... other tables
    }
  }
}

// Usage in code:
type Challenge = Database['public']['Tables']['challenges']['Row']
type ChallengeInsert = Database['public']['Tables']['challenges']['Insert']
type ChallengeUpdate = Database['public']['Tables']['challenges']['Update']
```

### Typed Supabase Client
```typescript
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabase = createClient<Database>(url, key)

// Now queries are fully typed:
const { data } = await supabase
  .from('challenges')
  .select('id, title, status')
  .eq('status', 'active')
// data type: Pick<Challenge, 'id' | 'title' | 'status'>[] | null
```

### Keep Types in Sync
- Run `supabase gen types` after every migration
- Add to CI: if types file changes after gen, fail the build (schema drift)
- Commit the generated file — it's the source of truth for client-side types

---

## Arena's Type Definitions

```
src/types/
├── agent.ts       # Agent, AgentRating, AgentProfile
├── api.ts         # ApiResponse<T>, ApiError, PaginatedResponse<T>
├── challenge.ts   # Challenge, ChallengeEntry, ChallengeResult
├── judge.ts       # JudgeResult, JudgingCriteria, Score
├── replay.ts      # ReplayEvent, ReplayTimeline
└── spectator.ts   # SpectatorEvent, SpectatorState
```

### Common Arena Types
```typescript
// src/types/challenge.ts
export type ChallengeStatus = 'upcoming' | 'active' | 'judging' | 'complete'

export type Challenge = {
  id: string
  title: string
  description: string | null
  prompt: string | null
  category: string
  format: string
  weight_class_id: string
  time_limit_minutes: number
  status: ChallengeStatus
  max_coins: number
  entry_count: number
  starts_at: string
  ends_at: string
  created_at: string
  is_daily: boolean
  is_featured: boolean
}

export type ChallengeEntry = {
  id: string
  challenge_id: string
  agent_id: string
  user_id: string
  status: 'entered' | 'submitted' | 'judged'
  submitted_at: string | null
  created_at: string
}
```

### ApiResponse Wrapper
```typescript
// src/types/api.ts
export type ApiResponse<T> = {
  data: T
  error?: never
} | {
  data?: never
  error: string
}

export type PaginatedResponse<T> = {
  data: T[]
  total: number
  page: number
  limit: number
}

// Usage:
async function fetchChallenges(): Promise<PaginatedResponse<Challenge>> {
  const res = await fetch('/api/challenges')
  return res.json()
}
```

---

## Discriminated Unions for Status Fields

Use discriminated unions when different statuses carry different data:

```typescript
// Each challenge status has different available actions
type ActiveChallenge = {
  status: 'active'
  starts_at: string
  ends_at: string
  time_remaining_ms: number
}

type CompletedChallenge = {
  status: 'complete'
  starts_at: string
  ends_at: string
  judging_completed_at: string
  winner_agent_id: string
}

type UpcomingChallenge = {
  status: 'upcoming'
  starts_at: string
  ends_at: string
}

type ChallengeWithStatus = ActiveChallenge | CompletedChallenge | UpcomingChallenge

// TypeScript narrows automatically:
function renderChallenge(c: ChallengeWithStatus) {
  switch (c.status) {
    case 'active':
      return `${c.time_remaining_ms}ms remaining` // ✅ time_remaining_ms available
    case 'complete':
      return `Winner: ${c.winner_agent_id}` // ✅ winner_agent_id available
    case 'upcoming':
      return `Starts at ${c.starts_at}` // ✅ only shared fields
  }
}
```

---

## Strict Mode Rules (Non-Negotiable)

Arena's `tsconfig.json` has `"strict": true`. These rules are enforced:

### No Implicit Any
```typescript
// ❌ Parameter 'e' implicitly has an 'any' type
function handleClick(e) { }

// ✅ Type the parameter
function handleClick(e: React.MouseEvent<HTMLButtonElement>) { }
```

### Strict Null Checks
```typescript
// ❌ Object is possibly null
const challenge = await getChallenge(id)
console.log(challenge.title) // might be null!

// ✅ Handle null explicitly
const challenge = await getChallenge(id)
if (!challenge) return notFound()
console.log(challenge.title) // safe — null handled above
```

### No Non-Null Assertion (`!`)
```typescript
// ❌ Avoid the ! operator — it hides potential null bugs
const user = session.user!
const email = user.email!

// ✅ Use explicit checks or optional chaining
const user = session.user
if (!user) return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })

const email = user.email ?? 'unknown'
```

### Prefer `type` for Data Shapes
```typescript
// ✅ Use type for plain data shapes (most Arena types)
type Challenge = {
  id: string
  title: string
  status: ChallengeStatus
}

// ✅ Use interface for extendable contracts (rare in Arena)
interface Judgeable {
  getSubmission(): string
  getScore(): number
}

// ✅ Use interface for component props (can be extended via declaration merging)
interface ChallengeCardProps {
  challenge: Challenge
  variant?: 'compact' | 'full'
}
```

---

## Utility Types

### Most Used in Arena

```typescript
// Partial<T> — all fields optional (for updates)
type ChallengeUpdate = Partial<Challenge>
// { id?: string; title?: string; status?: ChallengeStatus; ... }

// Required<T> — all fields required
type RequiredAgent = Required<AgentRegistration>

// Pick<T, K> — select specific fields
type ChallengePreview = Pick<Challenge, 'id' | 'title' | 'status' | 'category'>

// Omit<T, K> — exclude specific fields
type ChallengeWithoutId = Omit<Challenge, 'id' | 'created_at'>

// Record<K, V> — typed dictionary
type CategoryEmoji = Record<string, string>
const CATEGORY_EMOJI: CategoryEmoji = {
  'speed-build': '⚡',
  debug: '🐛',
  algorithm: '🧩',
}

// Extract<T, U> — narrow union types
type ActiveStatuses = Extract<ChallengeStatus, 'active' | 'judging'>
// 'active' | 'judging'

// Exclude<T, U> — remove from union
type ClosedStatuses = Exclude<ChallengeStatus, 'upcoming' | 'active'>
// 'judging' | 'complete'

// NonNullable<T> — remove null and undefined
type DefiniteChallenge = NonNullable<Challenge | null>
// Challenge
```

### Combining Utility Types
```typescript
// Create a type for updating a challenge (all optional except id)
type ChallengeUpdatePayload = Pick<Challenge, 'id'> & Partial<Omit<Challenge, 'id' | 'created_at'>>

// Create a type for API response with optional pagination
type ApiListResponse<T> = {
  data: T[]
} & Partial<{
  total: number
  page: number
  limit: number
  hasMore: boolean
}>
```

---

## Pattern: Type Guards

```typescript
// Type guard for challenge status
function isActiveChallenge(c: Challenge): c is Challenge & { status: 'active' } {
  return c.status === 'active'
}

// Type guard for API key format
function isValidApiKey(key: string): key is `aa_${string}` {
  return key.startsWith('aa_') && key.length > 10
}

// Usage:
const challenges = await fetchChallenges()
const active = challenges.filter(isActiveChallenge)
// active is typed as (Challenge & { status: 'active' })[]
```

---

## Strict Rules Checklist for New Files

```
□ No `any` — use `unknown` and narrow with Zod or type guards
□ No `!` (non-null assertion) — use `if` checks or `??`
□ No `as` casting on untrusted data — validate with Zod first
□ All function parameters typed
□ All return types explicit on exported functions
□ Null/undefined handled at every query result
□ Discriminated unions for status-dependent logic
□ Generated DB types regenerated after migrations
```
