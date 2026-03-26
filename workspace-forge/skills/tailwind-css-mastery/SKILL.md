---
name: tailwind-css-mastery
description: Tailwind CSS architecture — how it works, responsive patterns, animation performance, dark mode, and anti-patterns to flag in review.
---

# Tailwind CSS Mastery

## Anti-Patterns to Flag

- [ ] Dynamic class names: `` `text-${color}-500` `` — Tailwind can't detect at build time (P1)
- [ ] `transition-all` instead of specific properties — performance waste (P3)
- [ ] Hardcoded pixel values: `w-[347px]` — use scale or named size (P3)
- [ ] Conflicting classes: `p-4 p-8` — last wins but confusing (P2)
- [ ] Inline styles mixed with Tailwind — pick one system (P2)
- [ ] `@apply` creating component classes — use React components (P3)

---

## How Tailwind Works

1. Scans source files for class names at build time
2. Generates ONLY CSS for classes found (tree-shaking)
3. Each class does ONE thing: `p-4` = `padding: 1rem`
4. Final CSS ~3KB gzipped for typical site

**Implication:** Dynamic class names like `` `text-${color}-500` `` are INVISIBLE to the scanner. The CSS won't be generated. Use complete class names:
```tsx
// ❌ Broken — Tailwind never sees "text-red-500" as a complete string
const colorClass = `text-${color}-500`

// ✅ Works — all possible classes are scannable
const colorMap = {
  red: 'text-red-500',
  blue: 'text-blue-500',
  green: 'text-green-500',
} as const
const colorClass = colorMap[color]
```

## Responsive Design (Mobile-First)

```tsx
// Base = mobile, breakpoints add styles for larger screens
<div className="
  flex flex-col        {/* mobile: stack */}
  md:flex-row          {/* 768px+: side by side */}
  gap-4 md:gap-8       {/* responsive spacing */}
  p-4 lg:p-8           {/* responsive padding */}
">
```

Breakpoints: `sm:` (640), `md:` (768), `lg:` (1024), `xl:` (1280), `2xl:` (1536)

## Animation Performance

```tsx
// ✅ GPU-accelerated (smooth):
// transform, opacity, filter
<div className="transition-transform hover:scale-105" />
<div className="transition-opacity hover:opacity-80" />

// ❌ Layout-triggering (janky):
// width, height, top, left, margin, padding
<div className="transition-all hover:w-64" /> // triggers layout recalculation

// Rule: transition-transform or transition-opacity, NEVER transition-all
```

## Dark Mode

```tsx
// Strategy: class-based (more control than media query)
<html className="dark">
  <body className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">

// Prevent flash of wrong theme:
// Set dark class on <html> BEFORE React hydrates
// Script in <head> reads localStorage, sets class immediately
```

## Class Organization Convention

Group by: layout → spacing → sizing → typography → colors → borders → effects → states
```tsx
<button className="
  flex items-center justify-center  {/* layout */}
  px-6 py-3 gap-2                   {/* spacing */}
  w-full md:w-auto                  {/* sizing */}
  text-sm font-semibold uppercase   {/* typography */}
  bg-accent text-charcoal           {/* colors */}
  rounded-full border-2             {/* borders */}
  shadow-lg                         {/* effects */}
  hover:bg-accent/90 transition     {/* states */}
  disabled:opacity-50               {/* disabled */}
">
```

## Sources
- tailwindlabs/tailwindcss documentation
- Tailwind CSS performance guidelines
- Core Web Vitals animation recommendations

## Changelog
- 2026-03-21: Initial skill — Tailwind CSS mastery
