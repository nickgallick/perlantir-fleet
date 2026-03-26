# Accessibility & SEO — Forge Skill

## Overview

Accessibility (a11y) ensures the application is usable by everyone, including people with disabilities. SEO ensures the application is discoverable. Both are review requirements, not nice-to-haves.

## Accessibility Checklist

### Semantic HTML

- [ ] Use semantic elements: `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, `<footer>`
- [ ] Headings follow hierarchy (`h1` → `h2` → `h3`, no skipping levels)
- [ ] One `<h1>` per page
- [ ] Lists use `<ul>`, `<ol>`, `<dl>` — not styled divs
- [ ] Tables use `<table>`, `<thead>`, `<tbody>`, `<th>` with scope
- [ ] Buttons are `<button>`, not clickable `<div>` or `<span>`
- [ ] Links are `<a>` with `href`, not clickable divs
- [ ] Form inputs have associated `<label>` elements

### ARIA Attributes

- [ ] ARIA only used when semantic HTML is insufficient
- [ ] `aria-label` or `aria-labelledby` on elements without visible text (icon buttons, etc.)
- [ ] `aria-describedby` for supplementary descriptions
- [ ] `aria-live` regions for dynamic content updates (toasts, notifications)
- [ ] `aria-expanded` on toggleable elements (accordions, dropdowns)
- [ ] `aria-hidden="true"` on decorative elements
- [ ] `role` attributes only when semantic HTML doesn't convey the role
- [ ] No redundant ARIA (e.g., `role="button"` on a `<button>`)

### Keyboard Navigation

- [ ] All interactive elements reachable via Tab
- [ ] Tab order follows visual/logical order
- [ ] Focus visible on all interactive elements (no `outline: none` without alternative)
- [ ] Escape closes modals, dropdowns, and popovers
- [ ] Enter/Space activates buttons and links
- [ ] Arrow keys navigate within composite widgets (tabs, menus, listboxes)
- [ ] Focus trapped in modals (no tabbing out to background content)
- [ ] Focus restored to trigger element when modal/popover closes
- [ ] Skip-to-content link present

### Visual

- [ ] Color contrast ratio meets WCAG AA (4.5:1 for normal text, 3:1 for large text)
- [ ] Information not conveyed by color alone (icons, patterns, text as alternatives)
- [ ] Text resizable to 200% without loss of content or functionality
- [ ] No content that flashes more than 3 times per second
- [ ] Motion respects `prefers-reduced-motion` media query

### Images & Media

- [ ] All `<img>` elements have `alt` attributes
- [ ] Decorative images have `alt=""` (empty alt)
- [ ] Complex images have detailed descriptions
- [ ] Videos have captions or transcripts
- [ ] Audio content has transcripts

### Forms

- [ ] Every input has a visible label (not just placeholder)
- [ ] Required fields are indicated (not just with color)
- [ ] Error messages are specific and associated with the field (`aria-describedby`)
- [ ] Form validation errors announced to screen readers
- [ ] Autocomplete attributes used where appropriate
- [ ] Fieldsets and legends used for related form groups

## SEO — Next.js Specific

### Metadata

```typescript
// app/layout.tsx — global metadata
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: {
    template: '%s | OpenClaw',
    default: 'OpenClaw',
  },
  description: 'Application description',
  metadataBase: new URL('https://openclaw.io'),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    siteName: 'OpenClaw',
  },
  twitter: {
    card: 'summary_large_image',
  },
};
```

```typescript
// app/posts/[id]/page.tsx — dynamic metadata
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const post = await getPost(params.id);

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [{ url: post.coverImage }],
    },
  };
}
```

### Structured Data

```typescript
// JSON-LD for rich search results
export default function PostPage({ post }: Props) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: post.title,
    description: post.excerpt,
    author: {
      '@type': 'Person',
      name: post.author.name,
    },
    datePublished: post.createdAt,
    dateModified: post.updatedAt,
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <article>{/* ... */}</article>
    </>
  );
}
```

### Technical SEO

- [ ] `robots.txt` configured properly
- [ ] `sitemap.xml` generated (use Next.js `sitemap.ts`)
- [ ] Canonical URLs set on all pages
- [ ] Dynamic routes have `generateStaticParams` where appropriate
- [ ] 404 page returns proper 404 status code
- [ ] Redirects use proper status codes (301 permanent, 307 temporary)
- [ ] No duplicate content (canonical tags, proper pagination)
- [ ] Page titles unique and descriptive (< 60 characters)
- [ ] Meta descriptions present and compelling (< 160 characters)
- [ ] Open Graph and Twitter Card tags on shareable pages

### Performance (SEO Impact)

- [ ] Core Web Vitals within targets:
  - LCP (Largest Contentful Paint) < 2.5s
  - FID (First Input Delay) < 100ms
  - CLS (Cumulative Layout Shift) < 0.1
- [ ] Server-side rendering for content pages
- [ ] Images optimized with `next/image`

## Common Issues

| Issue | Impact | Fix |
|-------|--------|-----|
| Clickable div without button role | Screen readers can't identify as interactive | Use `<button>` or add `role="button"` + keyboard handling |
| Missing alt text | Screen readers skip the image | Add descriptive `alt` or `alt=""` for decorative |
| No focus indicator | Keyboard users can't see where they are | Use `:focus-visible` styles |
| Placeholder-only labels | Disappear when typing, not announced properly | Add visible `<label>` |
| Missing page title | Poor SEO, confusing tab names | Add `<title>` via metadata |
| No heading structure | Navigation impossible for screen readers | Use proper heading hierarchy |
| Color-only error indication | Color blind users miss errors | Add icon, text, or pattern |
| `outline: none` without alternative | Focus invisible | Use `focus-visible` or custom focus styles |

## Review Severity

| Issue | Severity |
|-------|----------|
| No keyboard access to critical functionality | P1 — High |
| Missing alt text on informational images | P1 — High |
| Focus trap missing on modal | P1 — High |
| Missing page metadata / title | P1 — High |
| Color contrast below AA threshold | P2 — Medium |
| Missing ARIA on custom components | P2 — Medium |
| No structured data on content pages | P3 — Low |
| Minor heading hierarchy issue | P3 — Low |
