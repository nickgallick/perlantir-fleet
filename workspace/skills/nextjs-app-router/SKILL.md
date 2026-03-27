# Next.js App Router — Agent Arena Patterns

Next.js App Router patterns as used in Arena. Route groups, server vs client components, data fetching, server actions, middleware, and common mistakes.

---

## Route Groups (Arena's Structure)

Arena uses route groups to organize pages without affecting URL paths:

```
src/app/
├── (auth)/               # Auth-related pages
│   ├── callback/route.ts # OAuth callback handler
│   ├── login/page.tsx    # /login
│   └── onboarding/page.tsx # /onboarding
├── (dashboard)/          # Authenticated dashboard pages
│   ├── layout.tsx        # Shared DashboardShell layout
│   ├── page.tsx          # / (conflicts with root page.tsx — root wins)
│   ├── agents/page.tsx   # /agents
│   ├── results/page.tsx  # /results
│   ├── settings/page.tsx # /settings
│   └── wallet/page.tsx   # /wallet
├── (public)/             # Public browsing pages
│   ├── challenges/page.tsx      # /challenges
│   ├── challenges/[id]/page.tsx # /challenges/:id
│   ├── leaderboard/page.tsx     # /leaderboard
│   └── agents/[id]/page.tsx     # /agents/:id (public profile)
├── admin/page.tsx        # /admin (not in a group)
├── api/                  # API routes
├── page.tsx              # / (landing page — takes priority over (dashboard)/page.tsx)
└── layout.tsx            # Root layout (html, body, fonts, providers)
```

### Key Rules
- **Route groups don't add URL segments**: `(auth)/login/page.tsx` → `/login`, not `/(auth)/login`
- **Each group can have its own `layout.tsx`**: `(dashboard)/layout.tsx` wraps all dashboard pages with sidebar/nav
- **Root `page.tsx` wins over group `page.tsx`**: both `app/page.tsx` and `app/(dashboard)/page.tsx` map to `/`, but `app/page.tsx` takes priority
- **Groups share the root `layout.tsx`**: all pages get the html/body/fonts from `app/layout.tsx`

### Adding Layout to a Route Group
```typescript
// src/app/(dashboard)/layout.tsx
import { DashboardShell } from '@/components/layout/dashboard-shell'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return <DashboardShell>{children}</DashboardShell>
}
// All pages inside (dashboard)/ get the DashboardShell wrapper
// Pages outside (dashboard)/ don't — they only get root layout
```

### When to Use Route Groups
- **Auth pages**: different layout (no nav, centered card)
- **Dashboard**: shared sidebar/header layout
- **Public pages**: shared header/footer but no auth required
- **Marketing**: different header style than app pages

---

## Server vs Client Components

### Default: Server Component
Every `.tsx` file in `app/` is a Server Component by default. This means:
- Runs on the server only (Node.js)
- Can `await` directly (async component)
- Can access env vars, file system, database
- Cannot use `useState`, `useEffect`, `onClick`, or browser APIs
- HTML is rendered on the server and sent to the client

```typescript
// src/app/(public)/challenges/[id]/page.tsx — Server Component
import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'

export default async function ChallengePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: challenge, error } = await supabase
    .from('challenges')
    .select('*')
    .eq('id', id)
    .single()

  if (error || !challenge) notFound()

  return (
    <div>
      <h1>{challenge.title}</h1>
      <p>{challenge.description}</p>
      {/* Can pass data to client components as props */}
      <EnterChallengeButton challengeId={challenge.id} />
    </div>
  )
}
```

### Client Component: Add `'use client'`
Only add when the component needs interactivity:
```typescript
// src/components/challenges/enter-challenge-button.tsx
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export function EnterChallengeButton({ challengeId }: { challengeId: string }) {
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleEnter() {
    setLoading(true)
    const res = await fetch(`/api/challenges/${challengeId}/enter`, { method: 'POST' })
    if (res.ok) {
      router.push('/agents')
    }
    setLoading(false)
  }

  return (
    <button onClick={handleEnter} disabled={loading}>
      {loading ? 'Entering...' : 'Enter Challenge'}
    </button>
  )
}
```

### When to Use `'use client'`
| Need | Server or Client? |
|------|-------------------|
| `useState`, `useEffect` | Client |
| `onClick`, `onChange` handlers | Client |
| `useRouter`, `usePathname` | Client |
| Browser APIs (`window`, `localStorage`) | Client |
| Framer Motion animations | Client |
| TanStack Query hooks | Client |
| Supabase Realtime subscriptions | Client |
| Data fetching from Supabase | **Server** (preferred) |
| Reading env vars | Server |
| Accessing cookies/headers | Server |
| Static content rendering | Server |

### Pattern: Server Fetches, Client Interacts
```typescript
// Server component fetches data
export default async function ChallengesPage() {
  const supabase = await createClient()
  const { data: challenges } = await supabase.from('challenges').select('*')
  
  // Pass data to client component as props
  return <ChallengeGrid challenges={challenges ?? []} />
}

// Client component handles interaction
'use client'
export function ChallengeGrid({ challenges }: { challenges: Challenge[] }) {
  const [filters, setFilters] = useState({ status: 'all' })
  const filtered = challenges.filter(/* ... */)
  
  return (
    <>
      <FilterBar onChange={setFilters} />
      {filtered.map(c => <ChallengeCard key={c.id} challenge={c} />)}
    </>
  )
}
```

---

## Data Fetching Patterns

### Server Component (Preferred)
```typescript
// Direct Supabase query in an async server component
export default async function LeaderboardPage() {
  const supabase = await createClient()
  const { data } = await supabase
    .from('agent_ratings')
    .select('*, agents(name, avatar_url)')
    .order('rating', { ascending: false })
    .limit(100)

  return <LeaderboardTable data={data ?? []} />
}
```

### Route Handler (API Route)
```typescript
// src/app/api/challenges/route.ts
import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const supabase = await createClient()
  const { data, error } = await supabase.from('challenges').select('*')
  
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ challenges: data })
}
```

### Client Component with TanStack Query
```typescript
'use client'
import { useQuery } from '@tanstack/react-query'

function useChallenges() {
  return useQuery({
    queryKey: ['challenges'],
    queryFn: async () => {
      const res = await fetch('/api/challenges')
      if (!res.ok) throw new Error('Failed to fetch')
      return res.json()
    },
  })
}
```

### When to Use Each
| Pattern | When |
|---------|------|
| Server component | Initial page load data, SEO-critical content |
| Route handler | Client needs to fetch on interaction, external API proxying |
| TanStack Query | Client needs caching, polling, optimistic updates |

---

## Server Actions

### Defining a Server Action
```typescript
// src/app/(dashboard)/settings/actions.ts
'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { z } from 'zod'

const profileSchema = z.object({
  display_name: z.string().min(1).max(50),
})

export async function updateProfile(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) return { error: 'Not authenticated' }

  const parsed = profileSchema.safeParse({
    display_name: formData.get('display_name'),
  })
  
  if (!parsed.success) return { error: parsed.error.issues[0].message }

  const { error } = await supabase
    .from('profiles')
    .update({ display_name: parsed.data.display_name })
    .eq('id', user.id)

  if (error) return { error: error.message }

  revalidatePath('/settings')
  return { success: true }
}
```

### Using in a Client Component
```typescript
'use client'
import { updateProfile } from './actions'
import { useActionState } from 'react'

export function ProfileForm() {
  const [state, formAction, pending] = useActionState(updateProfile, null)

  return (
    <form action={formAction}>
      <input name="display_name" required />
      <button type="submit" disabled={pending}>
        {pending ? 'Saving...' : 'Save'}
      </button>
      {state?.error && <p className="text-red-500">{state.error}</p>}
    </form>
  )
}
```

---

## Middleware

Arena's middleware handles auth for protected routes:

```typescript
// middleware.ts (root level — not inside src/app/)
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

const PROTECTED_PATHS = ['/agents', '/results', '/wallet', '/settings', '/dashboard']
const ADMIN_PATHS = ['/admin']

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const isProtected = PROTECTED_PATHS.some(p => pathname === p || pathname.startsWith(p + '/'))
  const isAdmin = ADMIN_PATHS.some(p => pathname === p || pathname.startsWith(p + '/'))

  // Create Supabase client with cookie forwarding
  let response = NextResponse.next({ request })
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll() },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          response = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // Validate JWT server-side (not getSession — that trusts the JWT without verification)
  const { data: { user } } = await supabase.auth.getUser()

  if ((isProtected || isAdmin) && !user) {
    const loginUrl = request.nextUrl.clone()
    loginUrl.pathname = '/login'
    loginUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(loginUrl)
  }

  return response
}

export const config = {
  matcher: [
    // Match all paths except static files, API auth routes, and webhooks
    '/((?!_next/static|_next/image|favicon.ico|api/auth|api/webhooks|api/v1|api/connector|api/internal|api/health|callback|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### Key Middleware Rules
- **Use `getUser()` not `getSession()`**: `getUser()` validates the JWT server-side; `getSession()` trusts it blindly
- **Cookie forwarding**: middleware must forward cookies so Supabase can refresh expired tokens
- **Matcher excludes API routes**: API routes handle their own auth (session cookies or API keys)
- **Redirect to login with return URL**: set `?redirect=` so user returns to their page after login

---

## Common Mistakes

### ❌ Using `useRouter` in Server Component
```typescript
// WRONG — useRouter is client-only
export default function Page() {
  const router = useRouter() // ❌ Error: can't use hooks in server component
  return <div>...</div>
}

// FIX — use redirect() from next/navigation for server-side redirects
import { redirect } from 'next/navigation'
export default function Page() {
  redirect('/login') // ✅ Server-side redirect
}
```

### ❌ Fetching in useEffect Instead of Server Component
```typescript
// WRONG — unnecessary client-side fetch for initial data
'use client'
export default function ChallengesPage() {
  const [data, setData] = useState([])
  useEffect(() => { fetch('/api/challenges').then(r => r.json()).then(setData) }, [])
  // ❌ Shows loading spinner, then fetches, then renders — slow
}

// FIX — fetch in server component
export default async function ChallengesPage() {
  const supabase = await createClient()
  const { data } = await supabase.from('challenges').select('*')
  return <ChallengeGrid challenges={data ?? []} />
  // ✅ Data included in initial HTML — instant render
}
```

### ❌ Not Handling Loading/Error in Async Server Components
```typescript
// WRONG — if query fails, page crashes with unhandled error
export default async function Page() {
  const { data } = await supabase.from('challenges').select('*').single()
  return <div>{data.title}</div> // ❌ Crashes if data is null
}

// FIX — handle errors explicitly
export default async function Page() {
  const { data, error } = await supabase.from('challenges').select('*').single()
  if (error || !data) notFound()
  return <div>{data.title}</div> // ✅ Safe
}
```

### ❌ Mixing App Router and Pages Router
```typescript
// WRONG — Pages Router patterns in App Router
import { useRouter } from 'next/router' // ❌ Wrong import
export async function getServerSideProps() {} // ❌ Doesn't exist in App Router

// FIX — App Router equivalents
import { useRouter } from 'next/navigation' // ✅ App Router import
// getServerSideProps → just fetch in the server component directly
```

### ❌ Making Entire Page Client for One Interactive Element
```typescript
// WRONG — entire page is client just for a button
'use client'
export default function ChallengePage() {
  const [loading, setLoading] = useState(false)
  // All data fetching now happens client-side ❌
}

// FIX — server page with client island
export default async function ChallengePage() {
  const data = await fetchChallenge() // ✅ Server fetch
  return (
    <div>
      <h1>{data.title}</h1>
      <EnterButton challengeId={data.id} /> {/* ✅ Only this is client */}
    </div>
  )
}
```

---

## Special Files

| File | Purpose |
|------|---------|
| `layout.tsx` | Shared layout (persists across navigations, doesn't remount) |
| `template.tsx` | Like layout but remounts on every navigation (use for animations) |
| `page.tsx` | The actual page component |
| `loading.tsx` | Loading UI shown while page loads (Suspense boundary) |
| `error.tsx` | Error boundary for the route segment |
| `not-found.tsx` | 404 page for the route segment |
| `route.ts` | API route handler (GET, POST, etc.) |
| `middleware.ts` | Request middleware (root level only) |
