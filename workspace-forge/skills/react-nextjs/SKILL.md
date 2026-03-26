# React & Next.js — Forge Skill

## Overview

We use Next.js with the App Router. Understanding the server/client boundary is the most critical aspect of reviewing React code in this project.

## Server/Client Boundary

### The Rule

Components are **Server Components by default** in the App Router. They only become Client Components when marked with `'use client'`.

### When `'use client'` Is Required

- Using hooks (`useState`, `useEffect`, `useContext`, etc.)
- Using browser APIs (`window`, `document`, `localStorage`)
- Adding event handlers (`onClick`, `onChange`, etc.)
- Using `useRouter()` from `next/navigation` for programmatic navigation
- Using third-party libraries that use any of the above

### When `'use client'` Should NOT Be Used

- Components that only render data (no interactivity)
- Components that fetch data from the database
- Layout components that just compose children
- Components that only use server-side imports

### Common Mistakes

```typescript
// BAD — entire page is a client component because of one click handler
'use client';

export default function ProductPage({ params }: Props) {
  const product = await fetchProduct(params.id); // Can't await in client!
  return (
    <div>
      <h1>{product.name}</h1>
      <AddToCartButton productId={product.id} />
    </div>
  );
}

// GOOD — server component with client island
export default async function ProductPage({ params }: Props) {
  const product = await fetchProduct(params.id);
  return (
    <div>
      <h1>{product.name}</h1>
      <AddToCartButton productId={product.id} /> {/* This is 'use client' */}
    </div>
  );
}
```

## Data Fetching

### Server Components (Preferred)

```typescript
// Direct database/API calls in Server Components
export default async function UsersPage() {
  const users = await getUsers(); // Direct call, no useEffect
  return <UserList users={users} />;
}
```

### Server Actions

```typescript
// app/actions.ts
'use server';

export async function createPost(formData: FormData) {
  const title = formData.get('title');
  // Validate with Zod
  // Write to database
  // Revalidate cache
  revalidatePath('/posts');
}
```

### Client-Side Fetching (When Needed)

- Use for real-time data, user-specific data after initial load, or infinite scroll
- Use SWR or React Query for client-side data fetching — not raw `useEffect` + `fetch`
- Always handle loading, error, and empty states

### Anti-Pattern: Fetching in useEffect

```typescript
// BAD — fetch in useEffect (waterfall, no cache, no error handling)
useEffect(() => {
  fetch('/api/users').then(r => r.json()).then(setUsers);
}, []);

// GOOD — use the data fetching library
const { data, error, isLoading } = useSWR('/api/users', fetcher);
```

## Component Architecture

### Composition Over Props Drilling

```typescript
// BAD — prop drilling
<App user={user}>
  <Layout user={user}>
    <Sidebar user={user}>
      <UserAvatar user={user} />

// GOOD — composition
<App>
  <Layout sidebar={<Sidebar><UserAvatar user={user} /></Sidebar>}>
    {children}
  </Layout>
</App>
```

### Component Size

- Components should do ONE thing
- If a component file exceeds ~150 lines, consider splitting
- Extract custom hooks for complex logic
- Keep render logic readable

### File Organization

```
app/
  (auth)/
    login/page.tsx
    register/page.tsx
  (dashboard)/
    layout.tsx
    page.tsx
  api/
    users/route.ts
components/
  ui/           # Generic, reusable (Button, Input, Modal)
  features/     # Feature-specific (UserProfile, PostEditor)
hooks/
  useAuth.ts
  useDebounce.ts
lib/
  supabase/
    client.ts
    server.ts
  utils.ts
```

## State Management

### Decision Tree

1. **Server state** → Fetch in Server Components (preferred)
2. **URL state** → Use `searchParams`, `useSearchParams()`
3. **Form state** → Use `useActionState()` or React Hook Form
4. **Local UI state** → `useState` (toggle, modal open, etc.)
5. **Shared client state** → React Context (small), Zustand (complex)
6. **Real-time state** → Supabase Realtime subscriptions

### Anti-Pattern: Global State for Server Data

```typescript
// BAD — putting server data in Zustand
const useStore = create((set) => ({
  users: [],
  fetchUsers: async () => {
    const users = await fetch('/api/users').then(r => r.json());
    set({ users });
  },
}));

// GOOD — fetch in Server Component, or use SWR/React Query for client
```

## Anti-Patterns to Flag

| Pattern | Issue | Fix |
|---------|-------|-----|
| `'use client'` on a page that fetches data | Loses server rendering benefits | Split into server page + client islands |
| `useEffect` for data fetching | No caching, waterfalls, race conditions | Use Server Components or SWR/React Query |
| Prop drilling more than 2-3 levels | Hard to maintain, brittle | Use composition, context, or restructure |
| Importing server-only code in client components | Build error or security risk | Check import boundaries |
| Using `router.push()` instead of `<Link>` | Loses prefetching | Use `<Link>` for navigation |
| `key={index}` on dynamic lists | Incorrect reconciliation | Use stable unique IDs |
| Large `'use client'` components | Increases client bundle | Extract server parts out |
| Missing `loading.tsx` or `error.tsx` | No loading/error UI for the route | Add route-level loading and error boundaries |
| Direct DOM manipulation in React | Bypasses React's reconciliation | Use refs and React patterns |

## Review Severity

| Issue | Severity |
|-------|----------|
| Server-only code exposed to client | P0 — BLOCKED |
| Missing error boundary on critical routes | P1 — High |
| Unnecessary `'use client'` on data-fetching page | P1 — High |
| Data fetching in `useEffect` without good reason | P2 — Medium |
| Missing loading states | P2 — Medium |
| Prop drilling (3+ levels) | P3 — Low |
