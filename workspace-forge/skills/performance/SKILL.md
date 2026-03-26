# Performance — Forge Skill

## Overview

Performance affects user experience, SEO rankings, and infrastructure costs. Review for performance at every layer: frontend rendering, network, backend queries, and bundle size.

## Frontend — React / Next.js

### Rendering Optimization

#### Prevent Unnecessary Re-renders

```typescript
// BAD — new object reference every render
<UserList filters={{ status: 'active' }} />

// GOOD — stable reference
const filters = useMemo(() => ({ status: 'active' }), []);
<UserList filters={filters} />
```

```typescript
// BAD — inline function creates new reference
<Button onClick={() => handleClick(id)} />

// GOOD — stable callback
const handleClick = useCallback((id: string) => {
  // ...
}, []);
```

#### Memoization Rules

- Use `React.memo()` for components that receive the same props frequently
- Use `useMemo()` for expensive computations
- Use `useCallback()` for callbacks passed to memoized children
- **Don't over-memoize** — memoization has its own cost. Only memoize when there's a measurable benefit.

#### Lists

```typescript
// BAD — no key, or index as key on dynamic list
{items.map((item, i) => <Item key={i} {...item} />)}

// GOOD — stable unique key
{items.map((item) => <Item key={item.id} {...item} />)}
```

#### Virtualization

- Lists with 50+ items should consider virtualization (`react-window`, `react-virtuoso`)
- Tables with 100+ rows should be virtualized
- Infinite scroll needs virtualization to prevent DOM bloat

### Rendering Patterns

#### Server Components (Preferred)

- Zero client JS for components that don't need interactivity
- Streaming with Suspense for progressive loading
- Use `loading.tsx` for route-level loading states

#### Dynamic Imports

```typescript
// Lazy load heavy components
const HeavyEditor = dynamic(() => import('@/components/Editor'), {
  loading: () => <EditorSkeleton />,
  ssr: false, // Only if the component truly can't render on server
});
```

#### Image Optimization

```typescript
// ALWAYS use next/image
import Image from 'next/image';

// BAD
<img src="/hero.png" />

// GOOD
<Image
  src="/hero.png"
  alt="Hero banner"
  width={1200}
  height={600}
  priority  // Only for above-the-fold images
  placeholder="blur"
  blurDataURL={blurUrl}
/>
```

## Backend Performance

### Database Query Efficiency

- Select only needed columns: `.select('id, name, email')` not `.select('*')`
- Use pagination — never return unbounded results
- Use database-level filtering, not client-side filtering
- Aggregate in the database, not in application code
- See `skills/database-review/SKILL.md` for N+1 detection

### Caching Strategy

```typescript
// Next.js fetch caching
const data = await fetch(url, {
  next: { revalidate: 3600 }, // Cache for 1 hour
});

// On-demand revalidation
import { revalidatePath, revalidateTag } from 'next/cache';

revalidatePath('/posts');       // Revalidate a path
revalidateTag('posts');         // Revalidate by tag
```

### Server Action Optimization

```typescript
'use server';

// BAD — returning entire objects
export async function getUsers() {
  const { data } = await supabase.from('users').select('*');
  return data; // Serializes everything to the client
}

// GOOD — return only what the client needs
export async function getUsers() {
  const { data } = await supabase
    .from('users')
    .select('id, name, avatar_url');
  return data;
}
```

### Edge Functions

- Keep Edge Functions lightweight — cold start time matters
- Avoid importing heavy dependencies
- Use streaming responses for large payloads

## Bundle Size

### What to Watch

- New dependencies — check bundle size before adding (`bundlephobia.com`)
- Tree-shaking — import specific functions, not entire libraries
- Client components — minimize `'use client'` surface area

### Import Patterns

```typescript
// BAD — imports entire library
import _ from 'lodash';
_.debounce(fn, 300);

// GOOD — tree-shakeable import
import debounce from 'lodash/debounce';
debounce(fn, 300);

// BETTER — use native or lightweight alternative
function debounce(fn: Function, ms: number) { ... }
```

### Analyzing Bundle

```bash
# Next.js bundle analyzer
ANALYZE=true next build

# Check import cost
npx import-cost
```

### Size Budgets

| Asset | Budget |
|-------|--------|
| First Load JS | < 100 KB |
| Per-route JS | < 50 KB |
| Total page weight | < 500 KB |
| Individual dependency | < 30 KB (question if larger) |

## Mobile — Expo / React Native

### React Native Performance

- Use `FlatList` / `FlashList` for lists (never `ScrollView` with `.map()`)
- Use `Animated` API or `react-native-reanimated` for animations (never animate with `setState`)
- Avoid inline styles in frequently re-rendered components
- Use `InteractionManager.runAfterInteractions()` for heavy work after navigation
- Use `useNativeDriver: true` for animations when possible

### Memory

- Clean up subscriptions, timers, and event listeners
- Avoid storing large datasets in state — paginate
- Watch for image memory — resize before displaying large images
- Profile with Flipper or React DevTools

### Startup Time

- Minimize imports in the entry file
- Lazy load screens with `React.lazy` or dynamic imports
- Defer non-critical initialization

## Review Checklist

- [ ] No unbounded queries (missing LIMIT/pagination)
- [ ] Images use `next/image` (web) or proper caching (mobile)
- [ ] Large lists are virtualized
- [ ] No unnecessary re-renders from unstable references
- [ ] New dependencies checked for bundle size impact
- [ ] Tree-shakeable imports used
- [ ] Heavy components lazy loaded
- [ ] Caching strategy appropriate for the data
- [ ] No client-side filtering of data that could be filtered server-side
- [ ] `select('*')` replaced with specific columns where possible

## Review Severity

| Issue | Severity |
|-------|----------|
| Unbounded database query on user-facing page | P1 — High |
| N+1 queries on list pages | P1 — High |
| ScrollView with .map() for long lists (mobile) | P1 — High |
| Missing image optimization | P2 — Medium |
| Heavy dependency without justification | P2 — Medium |
| select('*') when few columns needed | P2 — Medium |
| Missing memoization causing visible jank | P2 — Medium |
| Could lazy-load but doesn't | P3 — Low |
| Minor bundle size improvement possible | P3 — Low |
