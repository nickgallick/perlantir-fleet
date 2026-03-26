---
name: handoff-checklist
description: Structured handoff document template for delivering designs to Maks. Use after all screens are generated and approved. Produces ONE document per project that gives Maks everything he needs to build — no scattered specs, no guessing.
---

# Handoff Checklist

## When to Use
After all screens for a project are generated in Stitch and approved. Before notifying MaksPM that design is ready for build.

## The Rule
**ONE handoff document per project.** Maks reads this single file and knows everything. No hunting across 14 scattered spec files.

## Output
Create `HANDOFF.md` in the project's design directory (e.g., `design-specs/[project]/HANDOFF.md`).

## Template

Use this exact structure. Fill every section. If a section doesn't apply, write "N/A" — don't delete it.

````markdown
# [Project Name] — Design Handoff

**Design Authority:** Pixel
**Date:** [YYYY-MM-DD]
**Design System:** [CANONICAL NAME]
**Stitch Project ID:** [ID]
**Architecture Spec:** [path to Forge's architecture-spec.md]

---

## 1. Screen Index

Every screen with its Stitch ID, spec file, and screenshot URL.

| # | Screen | Stitch Screen ID | Spec File | Screenshot |
|---|--------|-----------------|-----------|------------|
| 01 | Landing Page | `abc123...` | `design-specs/project/01-landing.md` | [link] |
| 02 | Dashboard | `def456...` | `design-specs/project/02-dashboard.md` | [link] |

**To pull HTML/CSS for any screen:**
```bash
mcporter call stitch.get_screen projectId="[PROJECT_ID]" screenId="[SCREEN_ID]"
# Use the htmlCode.downloadUrl from the response
```

---

## 2. Typography

### Fonts to Load
```html
<!-- Google Fonts -->
<link href="https://fonts.googleapis.com/css2?family=[Font1]:wght@[weights]&family=[Font2]:wght@[weights]&display=swap" rel="stylesheet">
```

### Font Stack
| Role | Family | Weights | Tailwind Config |
|------|--------|---------|-----------------|
| Headings | [Font] | 600, 700 | `fontFamily: { heading: ['Font', 'sans-serif'] }` |
| Body | [Font] | 400, 500 | `fontFamily: { body: ['Font', 'sans-serif'] }` |
| Data/Mono | [Font] | 400, 700 | `fontFamily: { mono: ['Font', 'monospace'] }` |

### Type Scale
| Token | Size | Weight | Line Height | Letter Spacing | Use |
|-------|------|--------|-------------|----------------|-----|
| display-lg | 3.5rem | 700 | 0.95 | -0.02em | Hero headlines |
| heading-xl | 2rem | 700 | 1.1 | -0.01em | Page titles |
| ... | ... | ... | ... | ... | ... |

---

## 3. Color Tokens

### Core Palette
| Token | Hex | Tailwind | Use |
|-------|-----|----------|-----|
| page-bg | #0A1628 | `bg-arena-page` | Page background |
| surface | #141B2D | `bg-arena-surface` | Card backgrounds |
| elevated | #1E2642 | `bg-arena-elevated` | Hover/active states |
| border | #2A3040 | `border-arena-border` | Ghost borders (15% opacity) |
| text-primary | #F1F3F8 | `text-arena-text-primary` | Primary text |
| text-secondary | #8A92A8 | `text-arena-text-secondary` | Secondary text |
| text-muted | #5A6178 | `text-arena-text-muted` | Muted text |
| accent | #3B82F6 | `text-blue-500` | Primary accent |

### Semantic Colors
| Token | Hex | Use |
|-------|-----|-----|
| success | #22C55E | Win states, active, positive |
| warning | #F59E0B | Timers, pending, caution |
| error | #EF4444 | Loss states, errors, destructive |
| info | #3B82F6 | Links, primary actions |

### Tailwind Config Extension
```ts
// tailwind.config.ts
theme: {
  extend: {
    colors: {
      arena: {
        page: '#0A1628',
        surface: '#141B2D',
        // ... all tokens
      }
    }
  }
}
```

---

## 4. Component Naming Convention

Map design components to Forge's architecture hierarchy.

| Design Element | Forge Component | Location |
|---------------|-----------------|----------|
| Glass card | `GlassCard.tsx` | `components/arena/` |
| Weight class pill | `WeightClassBadge.tsx` | `components/arena/` |
| Live green dot | `LiveDot.tsx` | `components/arena/` |
| ... | ... | ... |

---

## 5. Spacing & Layout

### Spacing Scale (4px base)
4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96

### Layout Rules
- Max content width: `max-w-[1440px]` (app) or `max-w-6xl` (landing)
- Page padding: `px-4 sm:px-6 lg:px-8`
- Card padding: `p-6 md:p-8`
- Card gap: `gap-6`
- Border radius: cards `rounded-xl` (12px), buttons `rounded-lg` (8px), pills `rounded-full`

### Responsive Breakpoints
| Breakpoint | Width | Behavior |
|------------|-------|----------|
| Mobile | < 640px | Single column, bottom nav, collapsed cards |
| Tablet | 640-1024px | 2-column grids, top nav |
| Desktop | > 1024px | Full layout, sidebar columns |

---

## 6. Effects & Treatments

### Glass Morphism (arena-glass)
```css
background: rgba(20, 27, 45, 0.6);
backdrop-filter: blur(20px);
border: 1px solid rgba(42, 48, 64, 0.4);
```

### Ghost Borders
```css
border: 1px solid rgba(42, 48, 64, 0.15);
/* NEVER solid borders. Always ≤40% opacity. */
```

### Gradient Border (hover effect)
```css
/* Use CSS gradient border technique or pseudo-element */
background: linear-gradient(135deg, rgba(59,130,246,0.3), transparent);
```

---

## 7. Animation Specs

### Global Defaults
| Property | Value |
|----------|-------|
| Duration (micro) | 150ms |
| Duration (standard) | 300ms |
| Duration (page) | 500ms |
| Easing | cubic-bezier(0.16, 1, 0.3, 1) |
| Reduced motion | `prefers-reduced-motion: reduce` → disable all |

### Framer Motion Patterns
```tsx
// Card hover
whileHover={{ y: -2, transition: { duration: 0.2 } }}

// Page enter
initial={{ opacity: 0, y: 20 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}

// Stagger children
staggerChildren: 0.1
```

[Include project-specific animation specs here]

---

## 8. Icons

- **Library:** Lucide React (`lucide-react`)
- **Default size:** 16px (inline), 20px (standalone), 24px (featured)
- **Stroke width:** 1.5px (default)
- **Color:** inherit from parent text color

### Key Icons Used
| Icon | Lucide Name | Screens |
|------|------------|---------|
| [describe] | `icon-name` | 01, 02 |

---

## 9. Image Assets Needed

| Asset | Type | Dimensions | Screen | Notes |
|-------|------|------------|--------|-------|
| OG Image | PNG | 1200×630 | Meta | Social sharing |
| [Asset] | [Type] | [Size] | [Screen] | [Notes] |

---

## 10. Design System Rules (for Maks)

Critical rules that MUST be followed. Violations will be flagged in review.

1. **No solid borders.** Ghost borders only (≤40% opacity). See Effects section.
2. **JetBrains Mono for ALL numbers.** ELO, scores, timestamps, counts, prices — never Inter or Space Grotesk for data.
3. **[Project-specific rules...]**

---

## 11. Known Gaps / Future Work

- [ ] [Any screens or states not yet designed]
- [ ] [Components that need mobile-specific Stitch screens]
- [ ] [Edge states described in specs but not in Stitch output]
````

## Process

1. Create HANDOFF.md using the template above
2. Fill every section from your design specs + Stitch output
3. Verify all Stitch screen IDs are correct (run `get_screen` for each)
4. Cross-check component names against Forge's architecture spec
5. Save to `design-specs/[project]/HANDOFF.md`
6. Notify MaksPM that handoff is ready
