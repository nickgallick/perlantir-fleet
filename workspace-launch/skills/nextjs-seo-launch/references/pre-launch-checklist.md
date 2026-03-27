# Pre-Launch SEO Checklist

Every item must be verified before launch. Missing any of these means lost indexing time.

## Meta Tags

### Every Page Must Have:
```tsx
// app/layout.tsx or per-page generateMetadata
export const metadata: Metadata = {
  title: 'Page Title — Brand Name',  // 50-60 chars
  description: 'Compelling description with primary keyword.', // 150-160 chars
  robots: { index: true, follow: true },
}
```

### Homepage Meta (Arena example):
```tsx
export const metadata: Metadata = {
  title: 'Agent Arena — Where AI Agents Compete',
  description: 'The competitive platform for AI coding agents. Enter challenges, earn ELO ratings, climb the leaderboard. Weight classes ensure fair competition.',
  keywords: ['AI agent competition', 'AI coding challenge', 'ELO rating AI', 'AI leaderboard'],
}
```

### Dynamic Pages (challenges, agents, results):
```tsx
export async function generateMetadata({ params }): Promise<Metadata> {
  const challenge = await getChallenge(params.id)
  return {
    title: `${challenge.name} — Agent Arena`,
    description: `${challenge.category} challenge: ${challenge.description.slice(0, 120)}`,
    openGraph: {
      title: challenge.name,
      description: challenge.description,
      images: [`/api/og/challenge/${params.id}`],
    },
  }
}
```

## Open Graph & Social Cards

### Required OG Tags:
```tsx
openGraph: {
  type: 'website', // or 'article' for blog posts
  siteName: 'Agent Arena',
  title: 'Page Title',
  description: 'Page description',
  url: 'https://agentarena.com/page',
  images: [{
    url: '/api/og/default', // Dynamic OG image
    width: 1200,
    height: 630,
    alt: 'Agent Arena — AI Agent Competitions',
  }],
}
```

### Twitter Card:
```tsx
twitter: {
  card: 'summary_large_image',
  title: 'Page Title',
  description: 'Page description',
  images: ['/api/og/default'],
  creator: '@agentarena',
}
```

### Dynamic OG Images (Next.js ImageResponse):
```tsx
// app/api/og/route.tsx
import { ImageResponse } from 'next/og'

export async function GET(request: Request) {
  return new ImageResponse(
    <div style={{ /* your OG image template */ }}>
      <h1>Agent Arena</h1>
      {/* Dynamic content based on URL params */}
    </div>,
    { width: 1200, height: 630 }
  )
}
```

Create OG image routes for: homepage, challenge detail, agent profile, leaderboard, results.

## Sitemap

```tsx
// app/sitemap.ts
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const challenges = await getChallenges()
  const agents = await getPublicAgents()

  return [
    { url: 'https://agentarena.com', lastModified: new Date(), changeFrequency: 'daily', priority: 1.0 },
    { url: 'https://agentarena.com/challenges', lastModified: new Date(), changeFrequency: 'hourly', priority: 0.9 },
    { url: 'https://agentarena.com/leaderboard', lastModified: new Date(), changeFrequency: 'hourly', priority: 0.9 },
    ...challenges.map(c => ({
      url: `https://agentarena.com/challenges/${c.slug}`,
      lastModified: c.updatedAt,
      changeFrequency: 'daily' as const,
      priority: 0.7,
    })),
    ...agents.map(a => ({
      url: `https://agentarena.com/agents/${a.slug}`,
      lastModified: a.updatedAt,
      changeFrequency: 'weekly' as const,
      priority: 0.5,
    })),
  ]
}
```

## Robots.txt

```tsx
// app/robots.ts
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/api/', '/dashboard/', '/settings/', '/admin/'],
      },
    ],
    sitemap: 'https://agentarena.com/sitemap.xml',
  }
}
```

## Canonical URLs

Every page must have a self-referencing canonical:
```tsx
alternates: {
  canonical: 'https://agentarena.com/challenges/speed-build-42',
}
```

Prevent duplicate content from query params, trailing slashes, www vs non-www.

## Structured Data (JSON-LD)

### Organization Schema (homepage):
```tsx
<script type="application/ld+json">
{JSON.stringify({
  '@context': 'https://schema.org',
  '@type': 'Organization',
  name: 'Agent Arena',
  url: 'https://agentarena.com',
  logo: 'https://agentarena.com/logo.png',
  sameAs: ['https://twitter.com/agentarena', 'https://github.com/agentarena'],
})}
</script>
```

### WebApplication Schema:
```tsx
{
  '@context': 'https://schema.org',
  '@type': 'WebApplication',
  name: 'Agent Arena',
  applicationCategory: 'DeveloperApplication',
  operatingSystem: 'Web',
  description: 'Competitive platform for AI coding agents with ELO ratings and weight classes',
  offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
}
```

### BreadcrumbList (navigation pages):
```tsx
{
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://agentarena.com' },
    { '@type': 'ListItem', position: 2, name: 'Challenges', item: 'https://agentarena.com/challenges' },
    { '@type': 'ListItem', position: 3, name: challenge.name },
  ],
}
```

## Final Verification

```
□ Every page has unique title (50-60 chars) and description (150-160 chars)
□ OG images render correctly (test: https://www.opengraph.xyz/)
□ Twitter cards render correctly (test: https://cards-dev.twitter.com/validator)
□ sitemap.xml accessible and lists all public pages
□ robots.txt allows public pages, blocks private routes
□ Canonical URLs set on all pages
□ JSON-LD structured data validates (test: https://search.google.com/test/rich-results)
□ No orphaned pages (every page linked from at least one other page)
□ 404 page exists and returns proper 404 status code
□ Redirects configured for any changed URLs (next.config.js redirects)
□ HTTPS enforced everywhere
□ favicon.ico and apple-touch-icon present
□ lang attribute set on <html> tag
```
