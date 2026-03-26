---
name: advanced-react-patterns
description: Advanced React composition patterns, hooks architecture, Server Component patterns, and Next.js App Router patterns for building elegant, maintainable UIs.
---

# Advanced React Patterns

## Composition Patterns

### Compound Components (Shared State)
```tsx
// Like Shadcn's Tabs — children share implicit state via Context
const TabsContext = createContext<{ active: string; setActive: (v: string) => void } | null>(null)

function Tabs({ defaultValue, children }: { defaultValue: string; children: ReactNode }) {
  const [active, setActive] = useState(defaultValue)
  return (
    <TabsContext.Provider value={{ active, setActive }}>
      <div role="tablist">{children}</div>
    </TabsContext.Provider>
  )
}

function Tab({ value, children }: { value: string; children: ReactNode }) {
  const ctx = useContext(TabsContext)!
  return (
    <button role="tab" aria-selected={ctx.active === value} onClick={() => ctx.setActive(value)}>
      {children}
    </button>
  )
}

function TabPanel({ value, children }: { value: string; children: ReactNode }) {
  const ctx = useContext(TabsContext)!
  if (ctx.active !== value) return null
  return <div role="tabpanel">{children}</div>
}

// Usage — clean, composable API
<Tabs defaultValue="overview">
  <Tab value="overview">Overview</Tab>
  <Tab value="entries">Entries</Tab>
  <TabPanel value="overview"><Overview /></TabPanel>
  <TabPanel value="entries"><EntryList /></TabPanel>
</Tabs>
```

### Polymorphic Components (Type-Safe)
```tsx
// <Button as="a" href="/"> renders an anchor with button styles
type PolymorphicProps<E extends ElementType, P = {}> = P & 
  Omit<ComponentPropsWithoutRef<E>, keyof P> & { as?: E }

function Button<E extends ElementType = 'button'>({ 
  as, children, ...props 
}: PolymorphicProps<E, { variant?: 'primary' | 'ghost' }>) {
  const Component = as || 'button'
  return <Component className={cn('btn', props.variant)} {...props}>{children}</Component>
}

// Type-safe: <Button as="a" href="/"> works, <Button as="a" onClick={}> also works
// <Button as="a" disabled> → TypeScript error (anchor doesn't have disabled)
```

### Controlled vs Uncontrolled Hybrid
```tsx
// Works both ways — controlled if value/onChange provided, uncontrolled otherwise
function SearchInput({ value: controlledValue, onChange, defaultValue = '' }: {
  value?: string
  onChange?: (value: string) => void
  defaultValue?: string
}) {
  const [internalValue, setInternalValue] = useState(defaultValue)
  const isControlled = controlledValue !== undefined
  const value = isControlled ? controlledValue : internalValue
  
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    if (!isControlled) setInternalValue(e.target.value)
    onChange?.(e.target.value)
  }
  
  return <input value={value} onChange={handleChange} />
}
```

---

## Advanced Hooks

### useReducer with Discriminated Unions
```tsx
type ChallengeState = 
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'active'; startedAt: Date; timeRemaining: number }
  | { status: 'judging'; submittedAt: Date }
  | { status: 'complete'; results: Result[] }
  | { status: 'error'; message: string }

type ChallengeAction =
  | { type: 'START' }
  | { type: 'TICK'; remaining: number }
  | { type: 'SUBMIT'; submittedAt: Date }
  | { type: 'RESULTS'; results: Result[] }
  | { type: 'ERROR'; message: string }

function challengeReducer(state: ChallengeState, action: ChallengeAction): ChallengeState {
  switch (action.type) {
    case 'START': return { status: 'active', startedAt: new Date(), timeRemaining: 1800 }
    case 'TICK': return state.status === 'active' 
      ? { ...state, timeRemaining: action.remaining } : state
    case 'SUBMIT': return { status: 'judging', submittedAt: action.submittedAt }
    case 'RESULTS': return { status: 'complete', results: action.results }
    case 'ERROR': return { status: 'error', message: action.message }
  }
}
// TypeScript exhaustiveness: add a case for every action type or get a compile error
```

### useSyncExternalStore (WebSocket feeds)
```tsx
// Subscribe to external data source without useEffect
function useRealtimeLeaderboard(weightClass: string) {
  const subscribe = useCallback((callback: () => void) => {
    const channel = supabase.channel(`leaderboard:${weightClass}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'agent_ratings' }, callback)
      .subscribe()
    return () => { channel.unsubscribe() }
  }, [weightClass])
  
  const getSnapshot = useCallback(() => leaderboardCache.get(weightClass), [weightClass])
  
  return useSyncExternalStore(subscribe, getSnapshot)
}
```

---

## Server Component Patterns (Next.js App Router)

### The Donut Pattern
```tsx
// Server → Client → Server (server component as children of client component)
// layout.tsx (Server)
export default function Layout({ children }: { children: ReactNode }) {
  return (
    <ClientSidebar>        {/* Client: handles toggle state */}
      <ServerNavLinks />    {/* Server: fetches nav data from DB */}
    </ClientSidebar>
  )
}
// children are server-rendered, passed as serialized React tree to client component
```

### Streaming with Suspense
```tsx
// Page loads immediately, slow data streams in
export default function ChallengePage({ params }: { params: { id: string } }) {
  return (
    <div>
      <ChallengeHeader id={params.id} />  {/* Fast — renders immediately */}
      <Suspense fallback={<EntriesSkeleton />}>
        <ChallengeEntries id={params.id} /> {/* Slow — streams when ready */}
      </Suspense>
      <Suspense fallback={<LeaderboardSkeleton />}>
        <WeightClassLeaderboard />          {/* Independent — streams separately */}
      </Suspense>
    </div>
  )
}
```

### Server-Only Guard
```ts
// lib/server-utils.ts
import 'server-only' // Throws at build time if imported from client component

export async function getSecretConfig() {
  return { apiKey: process.env.ANTHROPIC_API_KEY }
}
// If a client component imports this → build error, not runtime leak
```

### Server Actions with Optimistic Updates
```tsx
'use client'
import { useOptimistic, useTransition } from 'react'

function VoteButton({ entryId, currentVotes }: { entryId: string; currentVotes: number }) {
  const [optimisticVotes, addOptimistic] = useOptimistic(
    currentVotes,
    (current, delta: number) => current + delta
  )
  const [isPending, startTransition] = useTransition()
  
  return (
    <button 
      disabled={isPending}
      onClick={() => {
        addOptimistic(1) // Immediately show +1
        startTransition(async () => {
          await voteForEntry(entryId) // Server Action — may fail
          // If fails, optimistic update auto-reverts
        })
      }}
    >
      ⬆ {optimisticVotes}
    </button>
  )
}
```

---

## Error and Loading States

### Skeleton > Spinner
```tsx
// ❌ Spinner — user sees blank then sudden content (jarring)
if (loading) return <Spinner />

// ✅ Skeleton — user sees content shape, perceives faster load
if (loading) return (
  <div className="space-y-4">
    <div className="h-8 w-48 bg-muted animate-pulse rounded" />
    <div className="h-4 w-full bg-muted animate-pulse rounded" />
    <div className="h-4 w-3/4 bg-muted animate-pulse rounded" />
  </div>
)
```

### Meaningful Empty States
```tsx
// ❌ "No data" — useless
{data.length === 0 && <p>No data</p>}

// ✅ Contextual and actionable
{data.length === 0 && (
  <div className="text-center py-12">
    <Trophy className="mx-auto text-muted mb-4" size={48} />
    <h3 className="text-lg font-medium mb-2">No challenges yet</h3>
    <p className="text-muted mb-4">Enter your first challenge to start climbing the ranks.</p>
    <Button asChild><Link href="/challenges">Browse Challenges</Link></Button>
  </div>
)}
```

## Sources
- bulletproof-react project structure and patterns
- shadcn-ui/ui compound component implementations
- Next.js App Router documentation (streaming, Server Actions, caching)
- React documentation (useOptimistic, useSyncExternalStore, Suspense)
- taxonomy (shadcn) — full App Router architecture reference

## Changelog
- 2026-03-21: Initial skill — advanced React patterns
