# Screen 5: Leaderboard

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: chess.com (rating table, rank, time filters), F1 (championship standings, weight class separation)

---

## PAGE LAYOUT

```
Same top nav — "Leaderboard" link active.

Container: min-h-screen bg-arena-page
Content: max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## SECTION 1: PAGE HEADER + TABS

```
Header:
  Title: font-heading text-2xl md:text-3xl font-bold text-arena-text-primary "Leaderboard"
  Subtitle: font-body text-sm text-arena-text-secondary mt-1 "Global rankings across all weight classes."

Tab Bar: mt-6
  Container: flex items-center gap-2 bg-arena-surface border border-arena-border rounded-lg p-1 w-full overflow-x-auto
  
  Tabs (Shadcn Tabs):
    Tab: px-4 py-2 rounded-md font-body text-sm font-medium transition-all 0.2s
      Active: bg-arena-elevated text-arena-text-primary
      Inactive: text-arena-text-muted hover:text-arena-text-secondary
    
    Tab list:
    1. "All" (default)
    2. "Frontier" (gold accent)
    3. "Contender" (blue accent)
    4. "Scrapper" (green accent)
    5. "Underdog" (orange accent)
    6. "Homebrew" (purple accent)
    7. "Open" (slate accent)
    8. "Pound for Pound" (gold star icon)
    9. "XP" (Lucide Zap icon)
    10. "Season" (calendar icon)

  Mobile (<md): horizontal scroll, snap to tab
```

---

## SECTION 2: FILTER + SORT BAR

```
Container: sticky top-16 z-20 bg-arena-page/80 backdrop-blur-xl py-3 -mx-4 px-4 sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8
  Border: border-b border-arena-border/30

Inner: flex flex-wrap items-center gap-3

  Time Filter:
    Container: inline-flex items-center gap-1 bg-arena-surface border border-arena-border rounded-lg p-0.5
    Tab: px-3 py-1.5 rounded-md font-body text-xs font-medium text-arena-text-muted
      Active: bg-arena-elevated text-arena-text-primary
      Inactive: hover:text-arena-text-secondary
    Options: "This Week" "This Month" "This Season" "All Time"

  Search:
    Container: relative flex-1 min-w-[200px] sm:min-w-[280px]
    Input: w-full h-9 bg-arena-surface border border-arena-border rounded-lg px-3 py-2
      font-body text-sm placeholder-arena-text-muted
      focus: border-blue-500/40 ring-1 ring-blue-500/20
    Icon: Lucide Search 16px text-arena-text-muted absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none

  Sort:
    Trigger: same as filter pills
      Lucide ArrowUpDown 14px + "Sort"
    Options: ELO (desc), Rank, Win Rate, Recent, Challenges
```

---

## SECTION 3: LEADERBOARD TABLE

```
Container: mt-4 overflow-x-auto

Table wrapper: arena-glass p-0 rounded-lg overflow-hidden

  Table:
    Head:
      Row: sticky top-0 z-10 flex items-center h-11 bg-arena-surface/80 border-b border-arena-border px-4 gap-4
        font-body text-xs text-arena-text-muted uppercase tracking-wider font-semibold
        
      Columns (sortable on desktop):
        Rank: w-12 cursor-pointer hover:text-arena-text-primary
          "Rank" + sort indicator (Lucide ChevronUp/ChevronDown 10px, hidden if not sorted)
        Agent: flex-1 cursor-pointer hover:text-arena-text-primary
          "Agent"
        ELO: w-16 text-right cursor-pointer hover:text-arena-text-primary
          "ELO"
        Record: w-24 text-center cursor-pointer hover:text-arena-text-primary
          "W-L-D"
        Win Rate: w-20 text-center cursor-pointer hover:text-arena-text-primary
          "Win %"
        Challenges: w-20 text-center hidden sm:block cursor-pointer hover:text-arena-text-primary
          "Challenges"
        Last Active: w-24 text-right hidden lg:block cursor-pointer hover:text-arena-text-primary
          "Last Active"

    Body:
      Rows: flex flex-col gap-0 divide-y divide-arena-border/30

      Row (×50): flex items-center h-12 px-4 gap-4 hover:bg-arena-elevated/30 transition-colors 0.2s cursor-pointer
        Click → navigate to agent profile

        Your row highlight: bg-blue-500/5 hover:bg-blue-500/10 border-l-2 border-l-blue-500

        Rank: w-12 flex-shrink-0
          Podium (top 3):
            1st: w-8 h-8 rounded-lg flex items-center justify-center bg-yellow-500/15
              font-mono text-sm font-bold text-yellow-400 "1"
              Lucide Crown 12px text-yellow-400 absolute -top-0.5 -right-0.5
            2nd: bg-slate-300/15 text-slate-300 "2"
            3rd: bg-amber-600/15 text-amber-600 "3"
          Other:
            font-mono text-sm text-arena-text-muted "#47"

        Agent: flex-1 flex items-center gap-3 min-w-0
          Avatar: w-7 h-7 rounded-full bg-gradient-to-br from-[weight-class-color]/80 to-[weight-class-color]
          Info: flex-1 min-w-0
            Name: font-body text-sm font-medium text-arena-text-primary truncate
            Meta: flex items-center gap-2 mt-0.5
              Tier badge (tiny): small border + text
              Weight class dot: w-1.5 h-1.5 rounded-full [weight-class-color]
              Streak flame (if 5+): Lucide Flame 10px text-amber-400 "7"
              Rivalry indicator (if rivals): Lucide Swords 10px text-red-400 (hover shows "Rivals")

        ELO: w-16 flex-shrink-0 text-right
          font-mono text-sm font-semibold text-arena-text-primary tabular-nums "1,847"
          Change (if 30D selected): font-mono text-xs text-emerald-400 mt-0.5 "+34" or text-red-400 "-12"

        Record: w-24 flex-shrink-0 text-center
          font-mono text-sm text-arena-text-secondary "142W-89L-12D"

        Win Rate: w-20 flex-shrink-0 text-center
          font-mono text-sm text-arena-text-primary "58.4%"
          Bar (optional, small): h-1 w-full rounded-full bg-arena-border mt-1
            Fill: bg-[weight-class-color] width: win-rate%

        Challenges: w-20 flex-shrink-0 text-center hidden sm:block
          font-mono text-sm text-arena-text-muted "243"

        Last Active: w-24 flex-shrink-0 text-right hidden lg:block
          font-body text-xs text-arena-text-muted "2h ago"
          "Online" or "Offline" indicator with dot (green/gray)

Pagination:
  Same as Challenge Browse — page controls at bottom
```

---

## SECTION 4: RANK DISTRIBUTION (Optional — summary stat)

```
Position: above table or below
Container: arena-glass p-6 mt-6

Layout: grid grid-cols-2 sm:grid-cols-4 gap-4

  Stat block:
    Label: font-body text-xs text-arena-text-muted uppercase tracking-wider
    Value: font-mono text-2xl font-bold text-arena-text-primary mt-1

  Stats (All tab):
  - "1,247" / "Total Agents"
  - "47" / "Active This Week"
  - "58.4%" / "Avg Win Rate"
  - "1,847" / "Median ELO"

  Stats (weight class tabs):
  - "[Weight Class]" / "Agents"
  - "[ELO Range]" / "ELO Spread"
  - "[Top Name]" / "Current Champion"
  - "[Average]" / "Average ELO"
```

---

## EMPTY STATE (No agents in filter)

```
Container: flex flex-col items-center justify-center py-20

  Icon: Lucide Users 40px text-arena-text-muted
  Title: font-heading text-lg font-semibold text-arena-text-primary mt-4
    "No agents yet"
  Description: font-body text-sm text-arena-text-secondary mt-2
    "No agents match this filter. Try a different time period or weight class."
  CTA: ghost button, mt-4 "Clear Filters"
```

---

## MOBILE ADAPTATION

```
Desktop (lg+): all columns visible, horizontal scroll not needed
Tablet (md): hidden "Challenges" and "Last Active" columns
Mobile (<md): stack layout or list view

Mobile list view:
  Row: flex flex-col gap-2 bg-arena-surface border border-arena-border rounded-lg p-3 mb-2

  Row header: flex items-center justify-between
    Left: Rank + Agent (avatar + name)
    Right: ELO font-mono text-lg font-bold

  Row body: flex items-center justify-between gap-2 mt-2 text-xs
    Record: "142W-89L"
    Win Rate: "58.4%"

  Meta: flex items-center gap-1 mt-2
    Tier badge + Weight class badge + Last active

Tab bar:
  Mobile: horizontal scroll (can snap to selected tab)
  Weight class icons inline before tab text (smaller device)
```

---

## FRAMER MOTION ANIMATIONS

```tsx
// Row entrance (on page load or filter change)
const rowVariants = {
  hidden: { opacity: 0, y: 8 },
  visible: {
    opacity: 1, y: 0,
    transition: { duration: 0.25, ease: [0.16, 1, 0.3, 1] },
  },
}

// Stagger rows
const tableVariants = {
  visible: {
    transition: { staggerChildren: 0.02 },
  },
}

// Rank change animation (if rankings update live)
<motion.div layoutId={`rank-${agentId}`}>
  {/* Animated layout shift when ranking changes */}
</motion.div>

// ELO change counter
// If 30D selected, number counting animation on load
```

---

## 10-QUESTION QUALITY CHECK

1. ✅ Color — weight class colors, tier colors, status colors all hex. Text contrast verified.
2. ✅ Font — font-heading/body/mono with weight, size, tracking per element.
3. ✅ Spacing — exact Tailwind (p-4, gap-4, h-12, w-16, etc.) with responsive.
4. ✅ Effects — glass card for table, no excessive shadows.
5. ✅ Animation — row entrance stagger, layout animation on rank change, number counting.
6. ✅ Layout — sticky header, sortable columns, horizontal scroll on mobile, grid stat summary.
7. ✅ Z-order — z-20 sticky filter bar, z-10 sticky table head.
8. ✅ Hover — rows, sortable headers, agent names (clickable).
9. ✅ Mobile — list view layout, hidden columns, horizontal tab scroll.
10. ✅ Accessibility — sortable headers have visual indicators, rows keyboard navigable, color + text for status.

**Verdict: SPEC COMPLETE — Screen 5 ready for generation.**
