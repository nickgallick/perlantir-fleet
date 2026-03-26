---
name: layout-specification
description: "Spacing system, section structure pattern, grid patterns, z-index system, container widths. All exact Tailwind values. Use when defining page layout, section spacing, grid columns, z-layering, or responsive structure."
---

# Layout Specification

Reference this skill for every layout decision. Every value is an exact Tailwind class or CSS value.

## Spacing System (4px Base Grid)

| Token | Value | Tailwind | Use For |
|-------|-------|----------|---------|
| space-1 | 4px | `p-1`, `gap-1` | Tight internal spacing |
| space-2 | 8px | `p-2`, `gap-2` | Icon-to-text gap |
| space-3 | 12px | `p-3`, `gap-3` | Badge padding, small gaps |
| space-4 | 16px | `p-4`, `gap-4` | Card internal padding, list gaps |
| space-5 | 20px | `p-5`, `gap-5` | Panel padding |
| space-6 | 24px | `p-6`, `gap-6` | Section internal padding |
| space-8 | 32px | `p-8`, `gap-8` | Between content blocks |
| space-10 | 40px | `p-10` | Large section padding |
| space-12 | 48px | `p-12` | Section vertical padding |
| space-16 | 64px | `py-16` | Section breathing room |
| space-20 | 80px | `py-20` | Major section breaks |
| space-24 | 96px | `py-24` | Between major sections |
| space-32 | 128px | `py-32` | Hero/footer separation |

---

## Container Widths

| Token | Width | Tailwind | Use For |
|-------|-------|----------|---------|
| container-sm | 640px | `max-w-screen-sm` | Forms, narrow content |
| container-md | 768px | `max-w-screen-md` | Blog posts, articles |
| container-lg | 1024px | `max-w-screen-lg` | Standard pages |
| container-xl | 1280px | `max-w-7xl` | Full layouts |
| container-2xl | 1440px | `max-w-[1440px]` | Dashboards, data-dense |
| full | 100% | `max-w-full` | Hero sections (with inner constraint) |

**Standard page:** `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`
**Dashboard:** `max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8`
**Landing hero content:** `max-w-6xl mx-auto` (1152px)

---

## Section Structure Pattern

Every page is a stack of full-width sections with constrained inner content:

```html
<section className="py-20 md:py-28"> <!-- Section spacing -->
  <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8"> <!-- Container -->
    <!-- Section badge (optional) -->
    <!-- Section heading -->
    <!-- Section content -->
  </div>
</section>
```

**Section spacing by importance:**

| Section Type | Vertical Padding | Notes |
|--------------|-----------------|-------|
| Hero | `min-h-screen` or `py-32` | Full viewport or very generous |
| Major content | `py-20 md:py-28` | Standard section |
| Sub-section | `py-12 md:py-16` | Within a larger section |
| Compact | `py-8 md:py-12` | Lists, tables, dense content |
| Footer | `py-12` | Consistent, not huge |

**Background alternation:** Alternate `bg-page`, `bg-surface/30`, `bg-page` for visual rhythm.

---

## Grid Patterns

### Card Grids

| Context | Grid Classes | Gap |
|---------|-------------|-----|
| Challenge cards | `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4` | 16px |
| Stat cards | `grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4` | 16px |
| Badge grid | `grid grid-cols-3 sm:grid-cols-4 lg:grid-cols-6 gap-3` | 12px |
| Feature grid | `grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6` | 24px |
| Stats summary | `grid grid-cols-2 sm:grid-cols-4 gap-4` | 16px |

### Dashboard Layouts

**Two-column with sidebar:**
```html
<div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
  <div className="lg:col-span-8">{/* Main */}</div>
  <div className="lg:col-span-4">{/* Sidebar */}</div>
</div>
```

**Settings sidebar:**
```html
<div className="grid grid-cols-1 md:grid-cols-4 gap-6">
  <div className="md:col-span-1">{/* Nav */}</div>
  <div className="md:col-span-3">{/* Content */}</div>
</div>
```

### Bento Grid (Asymmetric)

```html
<div className="grid grid-cols-1 md:grid-cols-12 gap-5 md:gap-6">
  <div className="md:col-span-7">{/* Large */}</div>
  <div className="md:col-span-5">{/* Small */}</div>
  <div className="md:col-span-5">{/* Small */}</div>
  <div className="md:col-span-7">{/* Large */}</div>
</div>
```

---

## Z-Index System

| Layer | z-index | Elements |
|-------|---------|----------|
| Background | `z-0` | Page bg, animated patterns, particles |
| Overlays | `z-[1]`–`z-[3]` | Video overlays, section dividers |
| Content | `z-10` | Standard cards, sections |
| Sticky elements | `z-20` | Sticky filter bars, sticky sidebars |
| Dropdowns | `z-30` | Dropdown menus, popovers, tooltips |
| Navigation | `z-40` | Main nav bar |
| Overlays/Sheets | `z-50` | Mobile nav, bottom sheets, drawers |
| Modal | `z-[60]` | Dialog modals |
| Toast | `z-[70]` | Toast notifications |
| Lightbox | `z-[100]` | Image/video lightbox |
| Loading screen | `z-[9999]` | Full-page loading overlay |

**Rule:** Never use arbitrary z-index values. Always reference this system.

---

## Responsive Breakpoints

| Breakpoint | Width | Tailwind | Target |
|------------|-------|----------|--------|
| Default | 0–639px | (no prefix) | Phone portrait |
| sm | 640px | `sm:` | Phone landscape, small tablet |
| md | 768px | `md:` | Tablet portrait |
| lg | 1024px | `lg:` | Tablet landscape, laptop |
| xl | 1280px | `xl:` | Standard desktop |
| 2xl | 1536px | `2xl:` | Large desktop, ultrawide |

**Testing widths:** 375px (phone), 768px (tablet), 1280px (laptop), 1920px (desktop)

---

## Navigation Heights

| Element | Height | Platform |
|---------|--------|----------|
| Desktop nav | 64px (`h-16`) | Web |
| Mobile top nav | 56px (`h-14`) | Web |
| Mobile bottom nav | 64px (`h-16`) | Web |
| iOS nav bar | 44pt + status (54pt) = 98pt | iOS |
| iOS tab bar | 49pt + home (34pt) = 83pt | iOS |

**Content offset:** `pt-16` below fixed nav, `pb-16` above fixed bottom nav.

---

## Sticky Elements

```html
<!-- Sticky filter bar below nav -->
<div className="sticky top-16 z-20 bg-page/80 backdrop-blur-xl py-4 border-b border-border/30">
  {/* filters */}
</div>

<!-- Sticky sidebar -->
<div className="sticky top-20 h-fit">
  {/* sidebar nav */}
</div>
```

---

## Rules
- All spacing from the 4px grid. No arbitrary pixel values.
- Container always has horizontal padding: `px-4 sm:px-6 lg:px-8`.
- Grid gap matches content density: 12px for dense (badges), 16px for standard (cards), 24px for spacious (features).
- Mobile: single column unless content is inherently two-column (stats grid stays 2-col).
- Never use horizontal scroll on the main content area (tables are the exception, contained within their card).
- Section padding scales down on mobile: `py-20 md:py-28` → effective ~80px on mobile, ~112px on desktop.
