---
name: internationalization
description: i18n for Next.js App Router — next-intl, message files, date/number formatting, RTL support, pluralization, SEO for multi-language.
---

# Internationalization (i18n)

## Review Checklist

- [ ] All user-facing text uses translation keys (no hardcoded strings)
- [ ] Dates/numbers use `Intl` formatters (not manual formatting)
- [ ] Layout tested with 2x longer text (German is 30% longer)
- [ ] RTL tested if supporting Arabic/Hebrew
- [ ] `hreflang` tags present for SEO
- [ ] Pluralization handled correctly (not `count + " items"`)

---

## next-intl Setup (Our Stack)

```
messages/
├── en.json     # English (source)
├── es.json     # Spanish
├── ja.json     # Japanese
└── de.json     # German
```

```json
// messages/en.json
{
  "Challenges": {
    "title": "Active Challenges",
    "entries": "{count, plural, one {# entry} other {# entries}}",
    "timeRemaining": "Time remaining: {time}",
    "noResults": "No challenges match your search."
  }
}
```

```tsx
// Server component
import { getTranslations } from 'next-intl/server'

export default async function ChallengesPage() {
  const t = await getTranslations('Challenges')
  return (
    <div>
      <h1>{t('title')}</h1>
      <p>{t('entries', { count: 47 })}</p> {/* "47 entries" */}
    </div>
  )
}

// Client component
'use client'
import { useTranslations } from 'next-intl'

function ChallengeCard({ challenge }) {
  const t = useTranslations('Challenges')
  return <p>{t('timeRemaining', { time: formatTime(remaining) })}</p>
}
```

## What to Internationalize

| ✅ YES | ❌ NO |
|--------|-------|
| UI text, labels, buttons | User-generated content |
| Error messages | Code, API responses |
| Email templates | Log messages |
| Meta tags (title, description) | Proper nouns ("Agent Arena") |
| Dates, numbers, currencies | |

## Date/Time/Number Formatting

```ts
// ❌ Manual formatting breaks across locales
`${date.getMonth()}/${date.getDate()}/${date.getFullYear()}`
// US: 3/21/2026, but Germans expect 21.3.2026, Japanese expect 2026年3月21日

// ✅ Intl.DateTimeFormat — locale-aware
new Intl.DateTimeFormat('ja-JP', { dateStyle: 'long' }).format(date)
// → "2026年3月21日"

// ✅ Intl.NumberFormat — locale-aware
new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(1234.5)
// → "1.234,50 €" (note: dot for thousands, comma for decimal)

// ✅ Relative time
new Intl.RelativeTimeFormat('en', { numeric: 'auto' }).format(-3, 'hour')
// → "3 hours ago"
```

**Rule:** Store everything as UTC in database. Convert to user's timezone only for display.

## SEO for Multi-Language

```tsx
// In layout or page metadata
export function generateMetadata({ params }) {
  return {
    alternates: {
      languages: {
        en: '/en/challenges',
        es: '/es/challenges',
        ja: '/ja/challenges',
      }
    }
  }
}

// Generates:
// <link rel="alternate" hreflang="en" href="https://agentarena.com/en/challenges">
// <link rel="alternate" hreflang="es" href="https://agentarena.com/es/challenges">
// <link rel="alternate" hreflang="x-default" href="https://agentarena.com/challenges">
```

## RTL Support Basics

```tsx
// Use CSS logical properties (auto-flips for RTL)
// ❌ Physical: margin-left
// ✅ Logical: margin-inline-start (Tailwind: ms-4)

// Tailwind RTL support:
<div className="ms-4 me-2">  {/* margin-start, margin-end */}
  <p className="text-start">Text aligns correctly in LTR and RTL</p>
</div>
```

## Sources
- amannn/next-intl documentation
- formatjs/formatjs ICU message format
- MDN Intl API documentation
- Google i18n SEO guidelines

## Changelog
- 2026-03-21: Initial skill — internationalization
