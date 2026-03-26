---
name: architecture-review
description: Architecture patterns and anti-patterns for Next.js App Router + Supabase applications. Catches code that works today but creates nightmares tomorrow.
---

# Architecture Review

## Quick Reference — Top 15 Architecture Red Flags

1. [ ] **Business logic in components** — fetching, transforming, validating all in one component
2. [ ] **God component** — one component >300 lines doing everything
3. [ ] **API route doing too much** — should delegate to service layer
4. [ ] **DB queries scattered** — no data access layer, queries in components and routes
5. [ ] **`'use client'` on layout** — forces entire subtree client-side
6. [ ] **Prop drilling >3 levels** — should use composition, context, or state management
7. [ ] **Multiple sources of truth** — same data duplicated in different stores
8. [ ] **Missing loading/error states** — no loading.tsx, error.tsx, or not-found.tsx
9. [ ] **No input validation on API routes** — missing Zod schemas
10. [ ] **No pagination on list endpoints** — returns unbounded results
11. [ ] **Inconsistent error response shapes** — different formats across routes
12. [ ] **Barrel exports killing tree-shaking** — index.ts re-exporting everything
13. [ ] **Circular dependencies** — module A imports B imports A
14. [ ] **Global state for local concerns** — form state in global store
15. [ ] **Missing Server Action validation** — trusting client-side input

---

## Separation of Concerns

### The Layered Architecture (for our stack)
```
┌─────────────────────────┐
│   Components (UI only)  │  React components render UI, handle user interaction
│   No business logic     │  Import hooks, not services directly
├─────────────────────────┤
│   Hooks / Actions       │  Custom hooks for client state, Server Actions for mutations
│   Orchestrate calls     │  Call services, handle loading/error states
├─────────────────────────┤
│   Services / Lib        │  Business logic, validation, transformation
│   Framework-agnostic    │  Testable without React, reusable across routes
├─────────────────────────┤
│   Data Access (Supabase)│  All DB queries centralized here
│   Type-safe queries     │  Generated types, consistent error handling
└─────────────────────────┘
```

### God Component Anti-Pattern
```tsx
// ❌ Everything in one component
export function Dashboard() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [filter, setFilter] = useState('')
  const [sort, setSort] = useState('name')
  // 20 more state variables...
  
  useEffect(() => {
    // 30 lines of data fetching
  }, [filter, sort])
  
  function handleDelete(id) {
    // 15 lines of delete logic with confirmation
  }
  
  function handleExport() {
    // 20 lines of CSV export logic
  }
  
  // 200 more lines of JSX
}

// ✅ Decomposed
export function Dashboard() {
  return (
    <DashboardProvider>
      <DashboardFilters />
      <UserTable />
      <ExportButton />
    </DashboardProvider>
  )
}
```

---

## Next.js App Router Architecture

### Server Actions: Security + Architecture
```ts
// ❌ No validation, no auth, business logic inline
'use server'
export async function updateProfile(formData: FormData) {
  const name = formData.get('name')
  await supabase.from('profiles').update({ name }).eq('id', '???')
}

// ✅ Validated, authenticated, delegated
'use server'
import { z } from 'zod'
import { createClient } from '@/lib/supabase/server'
import { updateUserProfile } from '@/lib/services/profile'

const UpdateProfileSchema = z.object({
  name: z.string().min(1).max(100).trim(),
})

export async function updateProfile(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Unauthorized' }
  
  const parsed = UpdateProfileSchema.safeParse({ name: formData.get('name') })
  if (!parsed.success) return { error: 'Invalid input', details: parsed.error.flatten() }
  
  return updateUserProfile(supabase, user.id, parsed.data)
}
```

### API Routes vs Server Actions
| Use Case | Use API Route | Use Server Action |
|----------|:------------:|:-----------------:|
| Form submission from own UI | | ✅ |
| Third-party webhook receiver | ✅ | |
| Public API for external consumers | ✅ | |
| File upload with progress | ✅ | |
| Simple mutation (create/update/delete) | | ✅ |
| CORS-required endpoint | ✅ | |

### Data Fetching Hierarchy
```
layout.tsx   → Fetch data shared across all child pages (user session, nav data)
page.tsx     → Fetch data specific to this page (page content, list data)
component    → Only fetch in client components for real-time/interactive data
```
**Rule:** Fetch as high as possible, as specific as needed. Don't fetch in layouts what only one page needs.

### Loading/Error/Not-Found Pattern
Every route segment should consider:
```
app/
  dashboard/
    page.tsx         # Main content
    loading.tsx      # Shown while page.tsx fetches (Suspense boundary)
    error.tsx        # Shown if page.tsx throws ('use client' required)
    not-found.tsx    # Shown when notFound() is called
```
**Flag missing:** If a page does async data fetching but has no loading.tsx or error.tsx.

---

## State Management Red Flags

| Red Flag | Better Approach |
|----------|----------------|
| Form state in Zustand/Redux | `useState` in the form component |
| Server data in global store | SWR/TanStack Query with cache |
| UI state (modal open) in global store | `useState` or URL params |
| Derived data stored separately | Compute from source (`useMemo`) |
| Same data in multiple stores | Single source of truth + selectors |

---

## API Design Review

### Consistent Error Responses
```ts
// ❌ Inconsistent — different shapes across routes
// Route A: { message: 'Not found' }
// Route B: { error: 'Invalid input' }
// Route C: { errors: [{ field: 'email', msg: 'required' }] }

// ✅ Consistent shape everywhere
type ApiError = {
  error: {
    code: string           // machine-readable: 'NOT_FOUND', 'VALIDATION_ERROR'
    message: string        // human-readable
    details?: unknown      // optional: field errors, context
  }
}

// 404: { error: { code: 'NOT_FOUND', message: 'User not found' } }
// 400: { error: { code: 'VALIDATION_ERROR', message: 'Invalid input', details: {...} } }
// 500: { error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } }
```

### File Structure: Feature-Based
```
// ❌ Layer-based (hard to navigate at scale)
src/
  components/
    UserCard.tsx
    OrderList.tsx
    ProductGrid.tsx
  hooks/
    useUser.ts
    useOrders.ts
  services/
    userService.ts
    orderService.ts

// ✅ Feature-based (everything related is together)
src/
  features/
    users/
      components/UserCard.tsx
      hooks/useUser.ts
      services/userService.ts
      types.ts
    orders/
      components/OrderList.tsx
      hooks/useOrders.ts
      actions/createOrder.ts
  shared/
    components/Button.tsx
    lib/supabase.ts
```

## Sources
- Next.js App Router documentation
- React Server Components architecture
- Clean Architecture (Robert C. Martin)

## Changelog
- 2026-03-21: Initial skill — architecture review for Next.js + Supabase
