---
name: performance-review
description: Performance anti-patterns in React/Next.js, Supabase queries, API design, and general algorithms. Catches code that works but will be painfully slow at scale.
---

# Performance Review

## Quick Reference — Top 15 Performance Red Flags

1. [ ] **N+1 queries** — fetching a list then querying each item individually
2. [ ] **SELECT * on Supabase** — `.select('*')` when only 3 fields needed
3. [ ] **Unbounded queries** — no LIMIT on queries that could return millions of rows
4. [ ] **Waterfall requests** — sequential API calls that should be `Promise.all`
5. [ ] **`'use client'` too high** — marking a layout/page client when only a child needs it
6. [ ] **Missing `next/image`** — raw `<img>` tags without optimization
7. [ ] **Full library imports** — `import _ from 'lodash'` instead of `import debounce from 'lodash/debounce'`
8. [ ] **O(n²) hidden in .map/.find** — nested `.find()` inside `.map()` on large arrays
9. [ ] **useEffect infinite loop** — missing or wrong dependency array
10. [ ] **Memory leaks** — event listeners, intervals, subscriptions not cleaned up
11. [ ] **Missing abort controllers** — fetch requests on unmounted components
12. [ ] **No pagination** — loading all records into memory
13. [ ] **Missing `sizes` prop** on `next/image` — serves full-resolution to mobile
14. [ ] **Render-blocking fonts** — missing `display: 'swap'`
15. [ ] **Redundant queries** — fetching same data multiple times in one render cycle

---

## React/Next.js Performance Anti-Patterns

### Unnecessary Re-renders
```tsx
// ❌ Creates new object every render → child re-renders every time
function Parent() {
  const style = { color: 'red' } // new reference each render
  return <Child style={style} />
}

// ✅ Stable reference
const style = { color: 'red' } // outside component
function Parent() {
  return <Child style={style} />
}

// ✅ Or useMemo if it depends on props
function Parent({ color }) {
  const style = useMemo(() => ({ color }), [color])
  return <Child style={style} />
}
```

### When NOT to Memoize
Don't flag missing `React.memo`/`useMemo`/`useCallback` when:
- The component renders fast anyway (<1ms)
- The component rarely re-renders
- The memoization overhead exceeds the render cost (primitive props, simple components)
- **Rule:** Only flag memoization issues when there's evidence of expensive renders or frequent re-renders on large lists

### Bundle Size Killers
```ts
// ❌ Imports entire lodash (71KB gzipped)
import _ from 'lodash'
const result = _.debounce(fn, 300)

// ✅ Tree-shakeable import (1KB)
import debounce from 'lodash/debounce'

// ❌ Imports entire date-fns
import { format } from 'date-fns'

// ✅ Direct import
import format from 'date-fns/format'
```

Common bundle killers to flag: `moment` (use `date-fns` or `dayjs`), `lodash` (use individual imports), `@mui/material` (use deep imports), `@fortawesome/fontawesome` (use specific icon imports).

### 'use client' Placement
```tsx
// ❌ Entire page is client-side (no SSR, no streaming, larger bundle)
'use client'
export default function DashboardPage() {
  const [filter, setFilter] = useState('')
  return (
    <div>
      <h1>Dashboard</h1>
      <FilterInput value={filter} onChange={setFilter} /> {/* only this needs client */}
      <DataTable data={serverData} /> {/* this could be server component */}
    </div>
  )
}

// ✅ Push 'use client' to the leaf
export default function DashboardPage() { // Server component
  return (
    <div>
      <h1>Dashboard</h1>
      <FilterInput /> {/* 'use client' in this file only */}
      <DataTable data={await getData()} /> {/* Server component, direct DB access */}
    </div>
  )
}
```

### Image Optimization
```tsx
// ❌ No optimization, causes layout shift
<img src="/hero.jpg" />

// ❌ next/image without sizes (serves full res to all devices)
<Image src="/hero.jpg" fill alt="Hero" />

// ✅ Proper next/image usage
<Image 
  src="/hero.jpg" 
  fill 
  alt="Hero"
  sizes="(max-width: 768px) 100vw, 50vw"
  priority // only for above-fold LCP image
/>

// ❌ unoptimized prop (bypasses all optimization)
<Image src={url} fill alt="Photo" unoptimized />
```

### useEffect Mistakes
```tsx
// ❌ Infinite loop — object in dependency creates new ref each render
useEffect(() => {
  fetchData(filters)
}, [{ page: 1, sort: 'name' }]) // new object every render!

// ❌ Missing cleanup — memory leak
useEffect(() => {
  const interval = setInterval(poll, 5000)
  // missing: return () => clearInterval(interval)
}, [])

// ❌ Stale closure
useEffect(() => {
  const handler = () => console.log(count) // captures stale count
  window.addEventListener('scroll', handler)
  return () => window.removeEventListener('scroll', handler)
}, []) // missing count in deps
```

---

## Database Query Performance

### N+1 Query Detection
```ts
// ❌ N+1: 1 query for list + N queries for each item's author
const { data: posts } = await supabase.from('posts').select('*')
for (const post of posts) {
  const { data: author } = await supabase
    .from('users').select('name').eq('id', post.author_id).single()
}

// ✅ Single query with join
const { data: posts } = await supabase
  .from('posts')
  .select('id, title, content, users(name)')
```

### Unbounded Queries
```ts
// ❌ Could return 10 million rows
const { data } = await supabase.from('events').select('*')

// ✅ Paginated with limit
const { data } = await supabase
  .from('events')
  .select('id, name, date')
  .order('date', { ascending: false })
  .range(0, 49) // first 50 rows
```

### Supabase-Specific Performance
```ts
// ❌ Over-fetching with deep relations
const { data } = await supabase
  .from('orders')
  .select('*, customer(*), items(*, product(*, category(*)))')

// ✅ Select only what you need
const { data } = await supabase
  .from('orders')
  .select('id, total, customer(name, email), items(quantity, product(name, price))')
```

### Missing Indexes
Flag when:
- A query filters on a column that isn't the primary key and likely has no index
- ORDER BY on a non-indexed column
- Full-text search without a GIN index
```sql
-- RLS policies MUST have indexes on the filtered column
CREATE INDEX idx_user_id ON orders (user_id);
-- Without this, every RLS check does a full table scan
```

---

## API and Network Performance

### Waterfall vs Parallel
```ts
// ❌ Sequential — total time = sum of all requests
const user = await fetchUser(id)
const orders = await fetchOrders(id)
const notifications = await fetchNotifications(id)
// Total: 200ms + 300ms + 150ms = 650ms

// ✅ Parallel — total time = slowest request
const [user, orders, notifications] = await Promise.all([
  fetchUser(id),
  fetchOrders(id),
  fetchNotifications(id),
])
// Total: max(200, 300, 150) = 300ms
```

### Missing Abort Controllers
```tsx
// ❌ Fetch continues after unmount, may set state on unmounted component
useEffect(() => {
  fetch('/api/data').then(r => r.json()).then(setData)
}, [])

// ✅ Aborts on unmount
useEffect(() => {
  const controller = new AbortController()
  fetch('/api/data', { signal: controller.signal })
    .then(r => r.json())
    .then(setData)
    .catch(e => { if (e.name !== 'AbortError') throw e })
  return () => controller.abort()
}, [])
```

---

## General Performance Patterns

### Hidden O(n²)
```ts
// ❌ O(n²) — .find() inside .map() scans array for each element
const enriched = orders.map(order => ({
  ...order,
  customer: customers.find(c => c.id === order.customerId) // O(n) each time
}))

// ✅ O(n) — build lookup map first
const customerMap = new Map(customers.map(c => [c.id, c]))
const enriched = orders.map(order => ({
  ...order,
  customer: customerMap.get(order.customerId)
}))
```

### Memory Leaks
Always clean up:
- `addEventListener` → `removeEventListener`
- `setInterval` → `clearInterval`
- `setTimeout` → `clearTimeout`
- Supabase `.subscribe()` → `.unsubscribe()`
- `IntersectionObserver.observe()` → `.disconnect()`

### Core Web Vitals (from web-vitals repo)
| Metric | What It Measures | Good Threshold | Common Causes of Poor Score |
|--------|-----------------|----------------|---------------------------|
| LCP | Largest Contentful Paint | <2.5s | Unoptimized images, render-blocking resources, slow server |
| INP | Interaction to Next Paint | <200ms | Long tasks, heavy JS, synchronous operations |
| CLS | Cumulative Layout Shift | <0.1 | Images without dimensions, dynamic content injection, web fonts |

## Sources
- Google web-vitals library documentation
- Next.js Performance documentation
- Supabase Performance Best Practices (RLS benchmarks)
- React documentation on rendering optimization

## Changelog
- 2026-03-21: Initial skill — performance review patterns for our stack
