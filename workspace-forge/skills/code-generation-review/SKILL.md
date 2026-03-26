---
name: code-generation-review
description: Reviewing AI-generated code — catching hallucinated APIs, outdated patterns, plausible-but-wrong logic, security blind spots, and over-engineering. The specific skill for reviewing Maks's output.
---

# AI Code Generation Review

## The Core Problem

AI-generated code looks clean, compiles, and passes a casual review — but can be **plausible-but-wrong**. Beautiful formatting creates false confidence. This skill trains you to distrust surface appearance and verify substance.

## Common AI Coding Mistakes

### 1. Hallucinated APIs
AI uses functions or methods that don't exist in our library versions.

```ts
// ❌ AI hallucinated — this method doesn't exist in supabase-js v2
const { data } = await supabase.from('users').upsertMany([...])
// Actual: .upsert([...])

// ❌ AI hallucinated — Next.js 15 param change
export default function Page({ params }: { params: { id: string } }) {
// Actual in Next.js 15+: params is a Promise
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
```

**Review check:** For every API call, verify: does this method exist? Does it accept these params? Is this the right import path?

### 2. Outdated Patterns
AI trained on older data suggests deprecated approaches.

| Outdated | Current |
|----------|---------|
| `getServerSideProps` | Server Components (direct async) |
| `pages/` router | `app/` router |
| `@supabase/auth-helpers-nextjs` | `@supabase/ssr` |
| `getSession()` on server | `getClaims()` on server |
| Class components | Function components with hooks |
| `useRouter` from `next/router` | `useRouter` from `next/navigation` |
| `fetch` in `getStaticProps` | `fetch` in Server Component with caching |

### 3. Plausible-But-Wrong Logic
Code that looks correct but has subtle bugs.

```ts
// ❌ Looks right, but off-by-one in pagination
const page = searchParams.page || 1
const offset = page * PAGE_SIZE  // should be (page - 1) * PAGE_SIZE

// ❌ Looks right, but wrong null coalescing
const name = user.displayName ?? user.email ?? 'Anonymous'
// What if displayName is empty string ""? ?? doesn't catch empty strings.
// Should it? Depends on business logic — AI doesn't know.

// ❌ Looks right, but missing await
const result = supabase.from('entries').insert(data) // returns Promise, not result
if (result.error) { ... } // result.error is undefined (it's a Promise, not the response)
```

### 4. Over-Engineering
AI produces more complex solutions than necessary.

```ts
// ❌ AI builds a generic data fetching framework for one use case
class DataFetcherFactory<T extends Record<string, unknown>> {
  private cache: Map<string, CacheEntry<T>> = new Map()
  private observers: Set<Observer<T>> = new Set()
  // 80 more lines...
}

// ✅ What was actually needed
const { data } = await supabase.from('challenges').select('*').eq('status', 'active')
```

**Complexity heuristic:** If the solution is >3x more lines than the simplest working version, ask: is the complexity justified by a real requirement, or is the AI building for hypothetical future needs?

### 5. Security Blind Spots
AI-generated code frequently omits:

| Missing | Frequency |
|---------|-----------|
| Input validation (Zod) | ~70% of AI-generated routes |
| Auth check | ~50% |
| Error handling on Supabase calls | ~80% |
| Rate limiting | ~90% |
| RLS consideration | ~60% |
| XSS prevention on rendered user content | ~40% |

### 6. Inconsistency with Codebase
AI generates in its own style, ignoring established conventions.

**Review check:** Does the new code match existing:
- Error handling pattern (our `AppError` classes vs generic try/catch)
- File organization (our feature-based structure vs AI's flat structure)
- Naming conventions (our camelCase vs AI mixing styles)
- Import patterns (our `@/` alias vs AI's relative paths)
- Type patterns (our Zod inference vs AI's hand-written interfaces)

### 7. Test-Free Code
AI rarely generates tests unless explicitly asked. Flag any new business logic, API route, or Server Action submitted without tests.

### 8. Copy-Paste Remnants
Watch for:
- TODO comments referencing other projects
- Imports that aren't used
- Variables named after different domain concepts
- Placeholder values: `YOUR_API_KEY`, `example.com`, `test@test.com` in production code

---

## The AI Code Review Protocol

```
1. Don't trust it because it looks clean
   → AI generates beautiful, well-formatted code that can be completely wrong

2. Verify every import
   → Does this package exist? Is it in our dependencies? Correct import path?

3. Verify every API call
   → Does this method exist? Correct params? Right library version?

4. Check types
   → Any `any`? Type assertions (`as`)? Non-null assertions (`!`)?

5. Check error handling
   → Supabase `{ data, error }` destructured and checked?
   → Server Action returns error state, not throws?

6. Check security
   → Auth, validation, RLS, rate limiting?

7. Trace execution
   → Pick a specific input, mentally walk through every line
   → Does the output match expectations?

8. Check for hallucinated complexity
   → Is there a simpler way? Is the abstraction justified?

9. Check consistency
   → Does it match our existing patterns? Or is it AI-style?

10. Check for tests
    → Business logic without tests = P1 flag
```

## Confidence Calibration for AI Code

| What I See | Confidence It's Correct |
|-----------|----------------------|
| Standard CRUD with Supabase | High — AI handles this well |
| Auth flows | Medium — check getSession vs getClaims |
| Financial/concurrent logic | Low — AI almost always misses race conditions |
| Complex TypeScript generics | Medium — verify with `tsc --noEmit` |
| Database migrations | Low — AI doesn't consider locking or rollback |
| WebSocket/Realtime code | Low — AI often gets cleanup wrong |
| Security-critical code | LOW — always full manual review |

## Sources
- SWE-bench results — common AI coding failures
- OpenHands CodeActAgent — how AI agents self-correct
- Personal review patterns from Maks's code submissions

## Changelog
- 2026-03-21: Initial skill — AI code generation review
