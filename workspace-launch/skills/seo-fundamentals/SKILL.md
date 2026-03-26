---
name: seo-fundamentals
description: SEO fundamentals for every launch — technical SEO, on-page, meta tags, schema markup.
---

# SEO Fundamentals

## Technical SEO Checklist (for every launch)
- [ ] SSL/HTTPS active
- [ ] sitemap.xml generated and submitted to Google Search Console
- [ ] robots.txt configured (not blocking important pages)
- [ ] Canonical URLs on all pages
- [ ] Mobile responsive (Core Web Vitals passing)
- [ ] Page load < 3 seconds
- [ ] No broken links (404s)
- [ ] Clean URL structure (/about not /page?id=2)
- [ ] Favicon and apple-touch-icon present
- [ ] 404 page is branded (not default framework 404)

## On-Page SEO (from Backlinko + Moz)
- **Title tag**: Primary keyword + compelling (50-60 chars / 600px)
  - Keyword closer to beginning = better rankings
  - Use modifiers: "best", "guide", "checklist", "fast", "review"
  - Every page needs unique title
- **Meta description**: Summarize + CTA (150-160 chars) — affects CTR
- **H1**: One per page, includes primary keyword
- **H2s**: Section headers with secondary keywords
- **URL**: Short, descriptive, includes keyword
- **Image alt text**: Descriptive, includes keyword naturally
- **Internal links**: Link to related pages
- **External links**: Link to authoritative sources
- **Content length**: 300+ words per page minimum

## Meta Tags Template
```html
<title>[Primary Keyword] — [Brand] | [Benefit]</title>
<meta name="description" content="[Compelling description with keyword. 150-160 chars.]" />
<meta property="og:title" content="[Title for social sharing]" />
<meta property="og:description" content="[Description for social sharing]" />
<meta property="og:image" content="[1200x630 image URL]" />
<meta property="og:url" content="[Canonical page URL]" />
<meta property="og:type" content="website" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="[Title]" />
<meta name="twitter:description" content="[Description]" />
<meta name="twitter:image" content="[Image URL]" />
<link rel="canonical" href="[Canonical URL]" />
```

## Schema Markup (JSON-LD)

### Organization
```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "[Company]",
  "url": "[URL]",
  "logo": "[Logo URL]",
  "sameAs": ["[Social URLs]"]
}
```

### LocalBusiness (for local businesses)
```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "[Business Name]",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "[Street]",
    "addressLocality": "[City]",
    "addressRegion": "[State]",
    "postalCode": "[Zip]"
  },
  "telephone": "[Phone]",
  "openingHours": ["Mo-Fr 09:00-17:00"],
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "[Rating]",
    "reviewCount": "[Count]"
  }
}
```

### Product
```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "[Product]",
  "description": "[Description]",
  "offers": {
    "@type": "Offer",
    "price": "[Price]",
    "priceCurrency": "USD"
  }
}
```

### FAQ (rich results in Google)
```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [{
    "@type": "Question",
    "name": "[Question]",
    "acceptedAnswer": {
      "@type": "Answer",
      "text": "[Answer]"
    }
  }]
}
```

## Mozlow's Hierarchy of SEO Needs
1. Crawl accessibility (foundation)
2. Compelling content answering searcher's query
3. Keyword optimized for searchers + engines
4. Great user experience (fast load, compelling UX)
5. Share-worthy content earning links/citations
6. Title, URL, description for high CTR
7. Snippet/schema markup for SERP standout

## Keyword Research Process
1. Seed keywords from product description
2. Expand with Google autocomplete, "People also ask"
3. Check search volume (Google Keyword Planner or free alternatives)
4. Assess competition (are results dominated by huge sites?)
5. Target long-tail keywords (less competition, higher intent)
6. Map keywords to pages (one primary keyword per page)

## 2026 Updates (from Backlinko)
- LLM-friendly content formatting matters for AI search visibility
- Google still uses traditional keyword signals as "most basic signal"
- User experience signals increasingly important
- Schema markup helps both traditional search and AI platforms

## Reference Docs
- repos/launch-docs/backlinko-on-page-seo.md
- repos/launch-docs/moz-seo-beginners.md
- repos/awesome-seo/

## Changelog
- 2026-03-20: Initial SEO fundamentals with Backlinko + Moz source material
