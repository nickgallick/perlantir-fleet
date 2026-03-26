---
name: design-pattern-recognition
description: Recognize and evaluate design patterns in code — repository, strategy, observer, factory, adapter, state machine, middleware. Plus anti-patterns to catch.
---

# Design Pattern Recognition

## Patterns We Use (Know These Cold)

### Repository Pattern
Data access behind a clean interface. Abstracts Supabase details.
```ts
// ✅ Clean repository — swappable, testable
// features/entries/repository.ts
export async function getEntryById(supabase: SupabaseClient, id: string) {
  const { data, error } = await supabase
    .from('entries').select('id, status, final_score, agent:agents(name)')
    .eq('id', id).single()
  if (error) throw new NotFoundError('Entry', id)
  return data
}
```
**When to use:** Any table accessed from >2 places.
**When NOT to use:** One-off queries in a single Server Action.

### Strategy Pattern
Swap algorithms at runtime.
```ts
// Different judging strategies per challenge category
type JudgingStrategy = (submission: string, rubric: Rubric) => Promise<JudgeScore>

const strategies: Record<ChallengeCategory, JudgingStrategy> = {
  speed_build: judgeCodeChallenge,
  deep_research: judgeResearchChallenge,
  creative_writing: judgeCreativeChallenge,
}

const judge = strategies[challenge.category]
const score = await judge(submission.text, challenge.rubric)
```

### Observer Pattern
Supabase Realtime IS the observer pattern. Components subscribe to changes.
**Key review check:** Every `.subscribe()` must have a cleanup `.unsubscribe()`.

### Factory Pattern
Create objects with appropriate configuration without exposing creation logic.
```ts
function createChallenge(category: ChallengeCategory): ChallengeConfig {
  switch (category) {
    case 'speed_build': return { timeLimit: 1800, maxEntries: 50, judgingCriteria: codeRubric }
    case 'deep_research': return { timeLimit: 7200, maxEntries: 30, judgingCriteria: researchRubric }
    // TypeScript exhaustive check ensures all categories handled
  }
}
```

### State Machine
Challenge status transitions. Invalid transitions should be compile-time errors.
```ts
const validTransitions: Record<ChallengeStatus, ChallengeStatus[]> = {
  draft: ['scheduled'],
  scheduled: ['active', 'draft'],  // can go back to draft
  active: ['judging'],
  judging: ['voting'],
  voting: ['complete'],
  complete: [],  // terminal state
}

function transitionChallenge(current: ChallengeStatus, next: ChallengeStatus) {
  if (!validTransitions[current].includes(next)) {
    throw new Error(`Invalid transition: ${current} → ${next}`)
  }
  // ... perform transition
}
```

### Middleware Pattern
Chain of functions processing a request. Next.js middleware, Express middleware.
```ts
// Composable middleware for API routes
type Middleware = (req: NextRequest, ctx: Context) => Promise<NextResponse | void>

const withAuth: Middleware = async (req, ctx) => {
  const user = await getUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  ctx.user = user
}

const withRateLimit: Middleware = async (req, ctx) => {
  const result = await checkRateLimit(ctx.user.id, 100, 60000)
  if (!result.allowed) return NextResponse.json({ error: 'Rate limited' }, { status: 429 })
}

// Compose
const handler = compose(withAuth, withRateLimit, async (req, ctx) => {
  // Business logic — user is authenticated and rate-limited
})
```

---

## Anti-Patterns to Catch

| Anti-Pattern | Symptom | Fix |
|-------------|---------|-----|
| **God Object** | One module >500 lines doing everything | Split by responsibility |
| **Premature Abstraction** | Generic framework built before 2 concrete uses | Wait for duplication, then abstract |
| **Leaky Abstraction** | Repository returns raw Supabase `{ data, error }` | Return domain objects, handle errors internally |
| **Cargo Cult** | Using a pattern "because best practices" without understanding why | Every pattern must justify its complexity |
| **Golden Hammer** | Using the same pattern for everything (everything is a class, everything is a hook) | Choose the right pattern for the problem |

### The Premature Abstraction Test
Before accepting an abstraction in a PR, ask:
1. Does this abstraction have 2+ concrete implementations TODAY? (not "might need later")
2. Does removing the abstraction make the code harder to understand?
3. Would a new developer understand the abstraction without explanation?

If any answer is NO → the abstraction is premature. Inline it.

## Sources
- refactoring.guru TypeScript design patterns
- bulletproof-react pattern usage
- lichess — state machine for game lifecycle
- cal.com — strategy pattern for different booking types

## Changelog
- 2026-03-21: Initial skill — design pattern recognition
