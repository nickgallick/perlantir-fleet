# Screen 9: My Results

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: chess.com (game history), Linear (filtered table), dashboard analytics

---

## PAGE LAYOUT

```
Same top nav — "Results" link.

Container: min-h-screen bg-arena-page
Content: max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## SECTION 1: PAGE HEADER + SUMMARY STATS

```
Title: font-heading text-2xl md:text-3xl font-bold text-arena-text-primary "My Results"

Summary row: grid grid-cols-2 sm:grid-cols-4 gap-4 mt-6

  Stat card (×4): arena-glass p-4 text-center
    Label: font-body text-xs text-arena-text-muted uppercase tracking-wider
    Value: font-mono text-2xl font-bold text-arena-text-primary mt-1

    Stats:
    - "243" / "Total Challenges"
    - "58.4%" / "Win Rate"
    - "142W-89L-12D" / "Record" (compact on mobile)
    - "1,847" / "Best ELO"
```

---

## SECTION 2: FILTER BAR

```
Container: sticky top-16 z-20 bg-arena-page/80 backdrop-blur-xl py-4 -mx-4 px-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8
  Border: border-b border-arena-border/30

Inner: flex flex-wrap items-center gap-3

  Filter pills (×4):
    Same as Challenge Browse filter bar

    Filters:
    1. Category: All, Speed Build, Research, Problem Solving, Code Golf, Debug
    2. Weight Class: All, + 6 weight classes
    3. Result: All, Won, Lost, Draw
    4. Date Range: All, Last Week, Last Month, Last 3 Months

  Sort: Newest, Oldest, Best Score, Worst Score, Most Recent ELO Gain, Most Recent ELO Loss

  Results count: font-body text-sm text-arena-text-muted ml-auto hidden sm:block
    "Showing 243 results"

Active filter tags: flex gap-2 mt-2 (only if filters applied)
  Same tag format as Challenge Browse
  Clear all link
```

---

## SECTION 3: RESULTS TABLE

```
Container: mt-4 overflow-x-auto

Table: arena-glass p-0 rounded-lg overflow-hidden

  Head:
    Row: flex items-center h-11 bg-arena-surface/80 border-b border-arena-border px-4 gap-4
    Columns: (sortable, same styling as leaderboard)

    "Challenge Name" / "Category" / "Placement" / "Score" / "ELO Change" / "Date" / "Details"

  Body:
    Rows: flex flex-col divide-y divide-arena-border/30

    Result row (×243): flex items-center h-12 px-4 gap-4 hover:bg-arena-elevated/30 cursor-pointer transition-colors 0.2s
      Click → expand detailed view (see below)

      Challenge name: flex-1 flex items-center gap-3 min-w-0
        Category icon: 16px Lucide per category, text-[category-color]
        Name: font-body text-sm font-medium text-arena-text-primary truncate

      Category badge (small): component, hidden <md

      Placement: w-12 text-center
        Same podium styling as leaderboard
        Ranked (1-3): colored background + tier name
        Other: font-mono text-sm text-arena-text-muted "#47"

      Score: w-16 text-right
        font-mono text-sm font-semibold text-arena-text-primary tabular-nums "87.4"

      ELO Change: w-20 text-right
        Positive: font-mono text-sm text-emerald-400 font-semibold "+18"
        Negative: font-mono text-sm text-red-400 font-semibold "-8"
        Zero: font-mono text-sm text-arena-text-muted "±0"

      Date: w-20 text-right
        font-body text-xs text-arena-text-muted "2h ago"
        (relative time, updates live)

      Actions: w-16 text-right flex items-center gap-2
        "Replay": icon button Lucide Play 14px text-blue-400 hover:text-blue-300
          Opens replay viewer (Screen 7)
        Expand: Lucide ChevronRight 14px text-arena-text-muted

Expandable details row (click anywhere on row to expand):
  Container: bg-arena-page/50 px-4 py-4 border-b border-arena-border/30
  Animation: height 0 → auto, opacity 0 → 1, 0.3s ease

  Grid: grid grid-cols-1 sm:grid-cols-2 gap-4

  Left:
    Judge scores: flex flex-col gap-2
      Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Judge Scores"
      Scores (×3):
        font-body text-sm text-arena-text-secondary "Judge 1 (Functionality): " font-mono font-semibold text-arena-text-primary "92/100"

    Challenge prompt: flex flex-col gap-2 mt-3
      Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Challenge Prompt"
      Preview: font-body text-xs text-arena-text-secondary line-clamp-2
        (truncated preview of prompt)

  Right:
    Stats: flex flex-col gap-2
      Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Performance"
      Stat items:
        font-body text-sm text-arena-text-secondary "[stat name]: " font-mono font-semibold text-arena-text-primary "[value]"
        Examples: "Time spent: 1h 23m" / "Code lines written: 247" / "Errors: 2"

    CTA buttons: mt-3 flex flex-wrap gap-2
      "View Challenge →": ghost button text-blue-400
      "Watch Replay →": ghost button text-blue-400
```

---

## MOBILE ADAPTATION

```
Mobile (<md):
  Summary stats: grid-cols-2 (not 4)
  Table header: hidden columns (Category, Date) — show in expanded detail
  Result row: 
    Challenge name (full width)
    Placement | Score | ELO on row 2
    Date | Actions on row 3
  Expand row: single column (stacked)
  Filter bar: tap "Filters" → bottom sheet
```

---

## LIST VIEW TOGGLE (Optional — alternative to table)

```
View toggle button: same as Challenge Browse
  "Grid" (list view — default on mobile)
  "Table" (table view — default on desktop)

List view card (mobile):
  Container: bg-arena-surface border border-arena-border/50 rounded-lg p-4 mb-3

  Header:
    Challenge: font-body text-sm font-medium text-arena-text-primary truncate
    Category badge (small)

  Row 2: flex items-center justify-between gap-2 mt-2 text-xs
    Placement: font-mono font-semibold
    Score: font-mono
    ELO: font-mono text-emerald-400 or text-red-400

  Row 3: flex items-center justify-between gap-2 text-xs text-arena-text-muted
    Date: "2h ago"
    Actions: "Replay" + "Details" links

  Expanded details: same as table expand row, shown below card when clicked
```

---

## EMPTY STATE

```
Container: flex flex-col items-center justify-center py-20

  Icon: Lucide Trophy 40px text-arena-text-muted
  Title: font-heading text-lg font-semibold text-arena-text-primary mt-4
    "No challenges completed yet"
  Description: font-body text-sm text-arena-text-secondary mt-2
    "Your results will appear here as your agent competes. Browse challenges to get started."
  CTA: primary button "Browse Challenges"
```

---

## PAGINATION

```
Same as leaderboard and challenge browse
  Prev / page numbers / Next buttons
  Page info: "Page 1 of 10"
  Jump to page: hidden <md
```

---

## FRAMER MOTION ANIMATIONS

```tsx
// Row entrance on load
const rowVariants = {
  hidden: { opacity: 0, y: 8 },
  visible: {
    opacity: 1, y: 0,
    transition: { duration: 0.25, ease: [0.16, 1, 0.3, 1] },
  },
}

// Stagger all rows
const tableVariants = {
  visible: {
    transition: { staggerChildren: 0.02 },
  },
}

// Expand row animation
<motion.div
  initial={{ height: 0, opacity: 0 }}
  animate={{ height: "auto", opacity: 1 }}
  exit={{ height: 0, opacity: 0 }}
  transition={{ duration: 0.3, ease: "easeOut" }}
/>

// Filter change: AnimatePresence mode="popLayout"
```

---

## 10-QUESTION QUALITY CHECK

1. ✅ Color — every element hex/Tailwind (placement colors, ELO colors, category icons).
2. ✅ Font — font-heading/body/mono per element with weight, size, tracking.
3. ✅ Spacing — exact Tailwind (p-4, gap-4, h-12, w-16, mt-3).
4. ✅ Effects — glass cards, table hover state, expand row smooth animation.
5. ✅ Animation — row entrance stagger, expand height transition, filter AnimatePresence.
6. ✅ Layout — sticky filter bar, sortable columns, 2-view (table + list), expand details.
7. ✅ Z-order — z-20 sticky filter bar, z-10 content.
8. ✅ Hover — rows, buttons, sortable headers, expand chevron rotation.
9. ✅ Mobile — list view card layout, 2-col stats, bottom sheet filters, full-width buttons.
10. ✅ Accessibility — sortable headers marked, expand/collapse with aria-expanded, color + text for ELO change.

**Verdict: SPEC COMPLETE — Screen 9 ready for generation.**
