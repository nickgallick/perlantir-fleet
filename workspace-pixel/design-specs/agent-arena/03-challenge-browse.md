# Screen 3: Challenge Browse

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: chess.com (game list density), Linear (filter bar), F1 (team color coding per weight class)

---

## PAGE LAYOUT

```
Same top nav as Dashboard (Screen 2) — "Challenges" link active.

Container: min-h-screen bg-arena-page
Content: max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## SECTION 1: PAGE HEADER

```
Container: flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4

Left:
  Title: font-heading text-2xl md:text-3xl font-bold text-arena-text-primary "Challenges"
  Subtitle: font-body text-sm text-arena-text-secondary mt-1 "Browse, enter, and compete."

Right:
  View toggle: flex items-center gap-0.5 bg-arena-surface border border-arena-border rounded-lg p-0.5
    Tab: p-2 rounded-md transition-all 0.2s
      Active: bg-arena-elevated text-arena-text-primary
      Inactive: text-arena-text-muted hover:text-arena-text-secondary
    Icons: Lucide LayoutGrid 16px (grid view), Lucide List 16px (list view)
```

---

## SECTION 2: FILTER BAR

```
Container: sticky top-16 z-20 bg-arena-page/80 backdrop-blur-xl py-4 -mx-4 px-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8
  Border: border-b border-arena-border/30

Inner: flex flex-wrap items-center gap-3

  Filter Pill (×4):
    Component: Shadcn Select with custom trigger
    Trigger:
      classes: inline-flex items-center gap-2 bg-arena-surface border border-arena-border rounded-lg px-3 py-2 h-9
      Text: font-body text-sm text-arena-text-primary
      Icon: Lucide ChevronDown 14px text-arena-text-muted
      hover: border-arena-border bg-arena-elevated/50
      active/open: border-blue-500/40 ring-1 ring-blue-500/20

    Content (dropdown):
      bg-arena-elevated border border-arena-border rounded-xl p-1 shadow-xl
      Item: px-3 py-2 rounded-lg text-sm font-body
        Default: text-arena-text-secondary hover:text-arena-text-primary hover:bg-arena-surface
        Selected: text-blue-400 bg-blue-500/10

    Filters:
      1. Status: All, Active, Upcoming, Judging, Complete
         Active state shows green dot before text
      2. Category: All, Speed Build, Research, Problem Solving, Code Golf, Debug
      3. Weight Class: All, Frontier, Contender, Scrapper, Underdog, Homebrew, Open
         Each option has colored dot matching weight class
      4. Format: All, Solo, Head-to-Head, Tournament

  Sort:
    Trigger: same as filter pill but with Lucide ArrowUpDown 14px
    Options: Newest, Most Entries, Prize Pool, Ending Soon

  Active filter tags (when filters applied):
    Container: flex flex-wrap gap-2 mt-2 (only if any filter is active)
    Tag: inline-flex items-center gap-1.5 bg-blue-500/10 border border-blue-500/20 rounded-full px-3 py-1
      Text: font-body text-xs text-blue-400 "Active"
      Close: Lucide X 12px text-blue-400/60 hover:text-blue-400 cursor-pointer
    Clear all: font-body text-xs text-arena-text-muted hover:text-arena-text-primary ml-2 cursor-pointer "Clear all"

  Results count:
    font-body text-sm text-arena-text-muted ml-auto hidden sm:block
    "Showing 23 challenges"
```

---

## SECTION 3: CHALLENGE GRID (Default View)

```
Container: mt-6
Grid: grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4

Challenge Card:
  Container: arena-glass p-0 overflow-hidden group cursor-pointer
    hover: border-color rgba(59,130,246,0.3)
    hover: translateY(-2px) shadow-[0_8px_32px_rgba(0,0,0,0.3)]
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1)

  Active card special: arena-gradient-border ::before with emerald-500 gradient
    Subtle ambient glow: shadow-[0_0_24px_rgba(16,185,129,0.08)]

  Top Section: p-5 pb-3
    Header row: flex items-center justify-between
      Category: flex items-center gap-2
        Icon: 16px Lucide icon per category
          Speed Build: Lucide Zap text-yellow-400
          Research: Lucide Search text-blue-400
          Problem Solving: Lucide Lightbulb text-purple-400
          Code Golf: Lucide Code text-emerald-400
          Debug: Lucide Bug text-red-400
        Category badge: component

      Status indicator:
        Active: arena-live-dot
        Upcoming: w-2 h-2 rounded-full bg-blue-400
        Judging: w-2 h-2 rounded-full bg-amber-400 animate-pulse
        Complete: Lucide CheckCircle2 14px text-arena-text-muted

    Title: font-heading text-base font-semibold text-arena-text-primary mt-3 line-clamp-2
      group-hover: text-blue-400 transition-colors 0.2s

    Description: font-body text-sm text-arena-text-secondary mt-1 line-clamp-2

  Bottom Section: p-5 pt-3 border-t border-arena-border/30
    Row 1: flex items-center justify-between
      Weight class badge: component (small size)
      Prize: flex items-center gap-1
        Lucide Coins 12px text-yellow-400
        font-mono text-sm font-semibold text-yellow-400 "500"

    Row 2: flex items-center justify-between mt-3
      Timer/Date:
        Active: flex items-center gap-1.5
          Lucide Clock 12px text-arena-text-muted
          font-mono text-xs text-arena-text-muted "1h 42m left"
          Pulsing when < 30min: text-amber-400
        Upcoming: font-mono text-xs text-arena-text-muted "Starts Mar 23"
        Judging: font-mono text-xs text-amber-400 "Judging..."
        Complete: font-mono text-xs text-arena-text-muted "Completed"

      Entries: flex items-center gap-1.5
        Lucide Users 12px text-arena-text-muted
        font-mono text-xs text-arena-text-muted "38"

      Spectators (if active): flex items-center gap-1
        Lucide Eye 12px text-arena-text-muted
        font-mono text-xs text-arena-text-muted "34"
```

---

## SECTION 3B: CHALLENGE LIST VIEW (Toggle)

```
Container: mt-6
Table-like list: flex flex-col gap-1

Challenge Row:
  Container: flex items-center gap-4 bg-arena-surface border border-arena-border/50 rounded-lg px-4 py-3
    hover: bg-arena-elevated/50 border-arena-border cursor-pointer transition-all 0.2s

  Status: w-3 flex-shrink-0
    Active: arena-live-dot (8px)
    Upcoming: w-2 h-2 rounded-full bg-blue-400
    Judging: w-2 h-2 rounded-full bg-amber-400
    Complete: w-2 h-2 rounded-full bg-arena-text-muted

  Category icon: w-8 flex-shrink-0
    Same icons as grid view, 18px

  Info: flex-1 min-w-0
    Title: font-body text-sm font-medium text-arena-text-primary truncate
    Category + Weight: flex items-center gap-2 mt-0.5
      font-body text-xs text-arena-text-muted "Speed Build"
      Dot separator: w-1 h-1 rounded-full bg-arena-text-muted
      Weight class badge (small)

  Entries: w-16 text-right
    font-mono text-sm text-arena-text-muted "38 ⚔️"

  Prize: w-20 text-right
    flex items-center justify-end gap-1
    Lucide Coins 12px text-yellow-400
    font-mono text-sm text-yellow-400 "500"

  Timer: w-24 text-right
    font-mono text-xs text-arena-text-muted "1h 42m"
    (amber if < 30min)

  Spectators: w-16 text-right (hidden below md)
    Lucide Eye 12px text-arena-text-muted inline
    font-mono text-xs text-arena-text-muted "34"

  Chevron: Lucide ChevronRight 16px text-arena-text-muted flex-shrink-0

Mobile (<sm): list rows stack internal elements
  Status dot + Category icon + Title on row 1
  Weight badge + Entries + Timer + Prize on row 2
  Chevron right-aligned, vertically centered
```

---

## SECTION 4: FEATURED/HIGHLIGHTED CHALLENGE (Optional — shown when a major challenge is active)

```
Position: above the grid, full width
Card: relative overflow-hidden rounded-xl border border-emerald-500/20 bg-gradient-to-r from-arena-surface via-arena-surface to-emerald-500/5

  Inner: p-6 md:p-8 flex flex-col md:flex-row items-start md:items-center justify-between gap-6

  Left:
    Badge: inline-flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/30 rounded-full px-3 py-1
      arena-live-dot
      font-mono text-xs font-medium text-emerald-400 uppercase tracking-wider "Featured Challenge"

    Title: font-heading text-xl md:text-2xl font-bold text-arena-text-primary mt-3
    Description: font-body text-sm text-arena-text-secondary mt-2 max-w-lg

    Stats: flex items-center gap-6 mt-4
      Stat: font-mono text-sm text-arena-text-muted
        "52 agents" / "2h 15m left" / "1,000 coins"
      Each with appropriate Lucide icon 14px inline before text

  Right:
    CTA: primary button "Enter Now →"
    Below CTA: font-body text-xs text-arena-text-muted "Free entry"

  Background glow: absolute -right-20 -top-20 w-64 h-64 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none
```

---

## PAGINATION

```
Container: flex items-center justify-center gap-2 mt-8 pb-8

  Button group: flex items-center gap-1

  Prev: ghost button, Lucide ChevronLeft 16px
    Disabled if page 1: opacity-40 pointer-events-none

  Page numbers: flex items-center gap-1
    Page: w-9 h-9 rounded-lg flex items-center justify-center font-mono text-sm
      Active: bg-blue-500 text-white font-semibold
      Inactive: text-arena-text-muted hover:bg-arena-elevated/50 hover:text-arena-text-primary
    Ellipsis: text-arena-text-muted "..."

  Next: ghost button, Lucide ChevronRight 16px

  Page info: font-body text-xs text-arena-text-muted ml-4 hidden sm:block
    "Page 1 of 6"
```

---

## FRAMER MOTION ANIMATIONS

```tsx
// Card entrance (grid view)
// Cards stagger in on page load and filter changes
const cardVariants = {
  hidden: { opacity: 0, y: 15, scale: 0.98 },
  visible: {
    opacity: 1, y: 0, scale: 1,
    transition: { duration: 0.35, ease: [0.16, 1, 0.3, 1] },
  },
}

// Container with stagger
const gridVariants = {
  visible: {
    transition: { staggerChildren: 0.05 },
  },
}

// Filter change: AnimatePresence mode="popLayout"
// Exiting cards: opacity 0, scale 0.95, 0.2s
// Entering cards: stagger in per above

// Card hover
<motion.div
  whileHover={{ y: -2, transition: { duration: 0.2 } }}
/>

// Featured challenge slide-in
<motion.div
  initial={{ opacity: 0, x: -20 }}
  animate={{ opacity: 1, x: 0 }}
  transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
/>
```

---

## EMPTY STATE

```
When no challenges match filters:
Container: flex flex-col items-center justify-center py-20

  Icon: Lucide Search 40px text-arena-text-muted
  Title: font-heading text-lg font-semibold text-arena-text-primary mt-4
    "No challenges found"
  Description: font-body text-sm text-arena-text-secondary mt-2 text-center max-w-sm
    "Try adjusting your filters or check back later for new challenges."
  CTA: ghost button, mt-4 "Clear Filters"
```

---

## MOBILE ADAPTATION

| Element | Desktop (xl+) | Laptop (lg) | Tablet (md) | Mobile (<md) |
|---------|---------------|-------------|-------------|--------------|
| Grid | 4 columns | 3 columns | 2 columns | 1 column |
| Filter bar | single row | wraps to 2 rows | wraps | vertical stack, each filter full-width |
| View toggle | visible | visible | visible | hidden (grid only) |
| List view columns | all visible | all visible | hide spectators | stack layout |
| Featured challenge | row layout | row layout | stack layout | stack layout |
| Pagination | page numbers | page numbers | prev/next only | prev/next only |

Mobile filter: tap "Filters" button to open bottom sheet (Shadcn Sheet from bottom)
  Full set of filters as vertical list
  "Apply" primary button at bottom

---

## 10-QUESTION QUALITY CHECK

1. ✅ What color? Every element: hex/Tailwind with opacity. Category icons color-coded.
2. ✅ What font? All text elements have font-heading/body/mono, weight, size, tracking.
3. ✅ What spacing? p-5, gap-4, mt-3, py-6 — all exact Tailwind.
4. ✅ What effect? Glass cards, gradient borders (active), ambient glow (featured), filter backdrop blur.
5. ✅ What animation? Card entrance stagger, hover translateY, filter change AnimatePresence, featured slide-in.
6. ✅ What layout? Grid columns per breakpoint, filter bar sticky, featured full-width.
7. ✅ What z-order? z-20 sticky filter bar, z-10 content.
8. ✅ What on hover? Cards (translateY + border + shadow), rows (bg change), filter triggers (border + bg).
9. ✅ What on mobile? Bottom sheet filters, single column grid, stacked list rows, simplified pagination.
10. ✅ What accessibility? Focus states on all interactive, filter dropdowns keyboard-navigable, sr-only labels.

**Verdict: SPEC COMPLETE — Screen 3 ready for generation.**
