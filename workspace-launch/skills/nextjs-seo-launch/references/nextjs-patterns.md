# Next.js SEO Patterns

## Rendering Strategy and Indexing

### Static (SSG) — Best for SEO
Pages generated at build time. Fastest TTFB. Google indexes easily.
**Use for:** Landing page, about, pricing, docs, blog posts.

### ISR (Incremental Static Regeneration) — Good for SEO
Static pages that revalidate after a time period.
```tsx
// In page or layout
export const revalidate = 3600 // Revalidate every hour
```
**Use for:** Challenge detail pages, agent profiles, leaderboard (data changes but not real-time critical for SEO).

### SSR (Server-Side Rendering) — OK for SEO
Generated on every request. Slower TTFB but always fresh.
**Use for:** Pages with auth-dependent content that must also be indexed (rare — usually just use ISR).

### Client-Side Only — Bad for SEO
Google can render JS but it's unreliable and slow to index.
**Never use for:** Any page you want indexed. All public pages must have server-rendered HTML.

## Common Next.js SEO Mistakes

### 1. Using `use client` on pages that need indexing
Client components don't SSR their dynamic content by default. If a page is mostly client-rendered, Google may see an empty shell.
**Fix:** Keep page.tsx as a server component. Use client components only for interactive widgets within the page.

### 2. Loading content in useEffect
```tsx
// ❌ BAD — Google won't wait for this
useEffect(() => { fetchData().then(setData) }, [])

// ✅ GOOD — Data is in the HTML
export default async function Page() {
  const data = await fetchData()
  return <div>{data.title}</div>
}
```

### 3. Missing generateMetadata on dynamic routes
Every dynamic route (`[id]`, `[slug]`) needs generateMetadata that pulls actual content for the title/description. Generic metadata = wasted indexing.

### 4. Not generating static params for dynamic routes
```tsx
// For ISR/SSG of dynamic routes
export async function generateStaticParams() {
  const challenges = await getChallenges()
  return challenges.map(c => ({ slug: c.slug }))
}
```
Without this, dynamic pages are only generated on first request — slower indexing.

### 5. Forgetting trailing slash consistency
Pick one and enforce it:
```js
// next.config.js
module.exports = { trailingSlash: false } // or true — just be consistent
```
Inconsistency = duplicate content.

### 6. Not handling 404s properly
```tsx
// app/not-found.tsx
export default function NotFound() {
  return <div>Page not found</div>
}
```
Must return a real 404 status code, not a 200 with "not found" text.

### 7. Blocking Googlebot in middleware
If you have auth middleware, make sure it doesn't redirect Googlebot away from public pages. Check user-agent or use a path allowlist.

## App Router Metadata API

### Static Metadata (simple pages):
```tsx
export const metadata: Metadata = {
  title: 'Challenges — Agent Arena',
  description: '...',
}
```

### Dynamic Metadata (data-driven pages):
```tsx
export async function generateMetadata({ params, searchParams }): Promise<Metadata> {
  const data = await fetch(...)
  return { title: data.name, description: data.summary }
}
```

### Template Titles:
```tsx
// app/layout.tsx
export const metadata: Metadata = {
  title: { template: '%s — Agent Arena', default: 'Agent Arena' },
}
// Page title "Challenges" → "Challenges — Agent Arena"
```

## Image Optimization for SEO

```tsx
import Image from 'next/image'

// ✅ Always include alt text (SEO + accessibility)
<Image src={src} alt="Leaderboard showing top 10 AI agents by ELO rating" width={800} height={400} />

// ✅ Use priority for above-the-fold images (improves LCP)
<Image src={heroImage} alt="..." priority />

// ✅ Use sizes for responsive images
<Image src={src} alt="..." sizes="(max-width: 768px) 100vw, 50vw" />
```

## Vercel-Specific

- **Edge functions** serve pages faster globally — good for TTFB
- **Automatic HTTPS** — no config needed
- **Preview deployments** should be noindexed (Vercel does this by default for non-production)
- **ISR** works natively on Vercel — on-demand revalidation via `revalidatePath()` or `revalidateTag()`
- **Analytics** — Vercel Web Analytics tracks Core Web Vitals automatically
