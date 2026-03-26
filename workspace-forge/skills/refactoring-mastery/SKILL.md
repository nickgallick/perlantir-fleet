---
name: refactoring-mastery
description: When and how to refactor — the refactoring catalog adapted for React/Next.js/TypeScript, safe refactoring process, and when NOT to refactor.
---

# Refactoring Mastery

## When to Refactor vs When NOT to

| ✅ REFACTOR | ❌ DON'T REFACTOR |
|------------|-------------------|
| Before adding a feature, if current structure makes it hard | During a bug fix (fix first, refactor separately) |
| Same pattern copied in 3+ places | Code that works and isn't being changed |
| Function does 3+ unrelated things | Right before a deadline |
| Test coverage exists for the code | Generated code, migrations, vendor code |
| The refactoring makes the NEXT change easier | Just because you'd write it differently |

## Refactoring Catalog (Our Stack)

### Extract Function
**When:** A block has a comment explaining what it does. The comment should BE the function name.
```ts
// ❌ Comment explaining what code does
// Calculate the final score from judge scores and community votes
const aiAvg = scores.reduce((s, j) => s + j.total, 0) / scores.length
const communityNorm = communityVotes / maxVotes * 10
const finalScore = aiAvg * 0.7 + communityNorm * 0.3

// ✅ Extract to named function
const finalScore = calculateFinalScore(scores, communityVotes, maxVotes)
```

### Extract Component
**When:** A component renders a distinct UI section or has multiple responsibilities.

### Extract Hook
**When:** Logic involves useState/useEffect and could be reused or clutters the component.
```tsx
// ❌ Timer logic mixed with UI
function ChallengeTimer({ endsAt }) {
  const [remaining, setRemaining] = useState(0)
  useEffect(() => { /* 15 lines of timer logic */ }, [endsAt])
  return <span>{formatTime(remaining)}</span>
}

// ✅ Logic extracted to hook
function ChallengeTimer({ endsAt }) {
  const remaining = useCountdown(endsAt)
  return <span>{formatTime(remaining)}</span>
}
```

### Replace Conditional with Discriminated Union
**When:** Adding a new case requires modifying existing if/else.
```ts
// ❌ Growing if/else chain
if (status === 'draft') { /* ... */ }
else if (status === 'active') { /* ... */ }
else if (status === 'judging') { /* ... */ }
// Adding new status = modify this chain + hope you don't miss a case

// ✅ Discriminated union + exhaustive switch
// TypeScript errors if you forget a case (see advanced-typescript-patterns)
```

### Inline Unnecessary Abstraction
**When:** An abstraction has one caller and adds no value.
```ts
// ❌ Wrapper that adds nothing
function createSupabaseQuery(table: string) {
  return supabase.from(table)
}
const data = await createSupabaseQuery('users').select('*')

// ✅ Just use the thing directly
const data = await supabase.from('users').select('*')
```

### Move to Server
**When:** Data fetching in a client component doesn't depend on client state.
```tsx
// ❌ Client-side fetch (extra round trip, shows loading spinner)
'use client'
function UserProfile({ userId }) {
  const [user, setUser] = useState(null)
  useEffect(() => { fetchUser(userId).then(setUser) }, [userId])
  if (!user) return <Spinner />
  return <div>{user.name}</div>
}

// ✅ Server component (data available immediately, no loading state needed)
async function UserProfile({ userId }) {
  const user = await getUser(userId) // direct DB call
  return <div>{user.name}</div>
}
```

## Safe Refactoring Process

1. **Ensure tests exist** for the code being refactored (write them first if missing)
2. **Make one refactoring change** at a time
3. **Run tests** after each change
4. **Commit each change** separately with descriptive message
5. **Never refactor AND change behavior** in the same commit

```
refactor: extract calculateFinalScore function     ← pure refactor, no behavior change
feat: add weighted scoring for community votes     ← behavior change, separate commit
```

## Sources
- Martin Fowler's Refactoring (adapted for React/TS)
- clean-code-javascript patterns
- bulletproof-react component organization

## Changelog
- 2026-03-21: Initial skill — refactoring mastery
