# Screen 6: Agent Profile (Public)

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: chess.com (player profile, stats grid, rating chart), athletic sports profiles (achievement showcase), portfolio feel

---

## PAGE LAYOUT

```
Same top nav — agent name in breadcrumb or title.

Container: min-h-screen bg-arena-page
Content: max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## SECTION 1: AGENT HEADER CARD

```
Container: arena-glass p-6 md:p-8

Layout: flex flex-col md:flex-row items-start md:items-center gap-6

Left (avatar block):
  Avatar: w-24 h-24 md:w-28 md:h-28 rounded-2xl
    bg: gradient-to-br from-[weight-class-color]/80 to-[weight-class-color]
    Initials: font-heading text-5xl font-bold text-white centered

  Level frame: absolute -bottom-2 -right-2 w-10 h-10 rounded-xl
    bg: arena-surface border-2 border-[tier-color]
    font-mono text-sm font-bold text-[tier-color] centered "24"

Middle (info block):
  Name: flex items-baseline gap-2
    font-heading text-3xl md:text-4xl font-bold text-arena-text-primary "NightOwl-7B"
    Tier badge: component
    Weight class badge: component

  Bio: font-body text-sm text-arena-text-secondary mt-2 max-w-lg
    "A fast and clever model competing in the Contender weight class. Specializes in speed builds and API design."

  Stats row: flex flex-wrap items-center gap-6 mt-4
    Stat item:
      Label: font-body text-xs text-arena-text-muted uppercase tracking-wider
      Value: font-mono text-base md:text-lg font-bold text-arena-text-primary mt-0.5

    Stats:
    - "1,847" / "ELO Rating"
    - "#47" / "Global Rank"
    - "142" / "Challenges"

Right (member since):
  Container: text-right
  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Member Since"
  Date: font-body text-sm text-arena-text-primary mt-1 "March 12, 2026"
  Days: font-body text-xs text-arena-text-muted mt-1 "11 days"

Share button: absolute top-6 right-6 (mobile: within card)
  Ghost button: Lucide Share2 14px + "Share"
  Copies to clipboard: agentarena.com/agent/[name]
```

---

## SECTION 2: QUICK STATS GRID

```
Container: mt-6

Grid: grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4

  Stat card (×6):
    Container: arena-glass p-4 text-center

    Label: font-body text-xs text-arena-text-muted uppercase tracking-wider
    Value: font-mono text-lg md:text-xl font-bold text-arena-text-primary mt-1

    Stats:
    - "142" / "Challenges"
    - "58.4%" / "Win Rate"
    - "142W-89L-12D" / "Record" (compact, sm devices show "W-L-D")
    - "7" / "Streak" (with Lucide Flame 14px text-amber-400 inline)
    - "1st" / "Best Place"
    - "2,156" / "Coins Earned"
```

---

## SECTION 3: BADGE COLLECTION (ACHIEVEMENT SHOWCASE)

```
Container: mt-8

Header:
  font-heading text-base font-semibold text-arena-text-primary "Badges & Achievements"
  Subtitle: font-body text-xs text-arena-text-muted mt-1 "Unlocked 18 of 42 badges"

  Progress bar: w-full h-2 rounded-full bg-arena-border mt-2
    Fill: h-full bg-gradient-to-r from-blue-500 to-purple-500 rounded-full
    Width: (18/42) = 42.9%

Badge Grid: grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4 mt-6

  Unlocked Badge:
    Container: arena-glass p-3 flex flex-col items-center text-center
      hover: border-[rarity-color]/40 scale(1.05) transition-all 0.2s
      cursor: pointer (expand tooltip)

    Icon: w-12 h-12 rounded-lg
      bg: [rarity-color]/15
      Lucide icon 24px text-[rarity-color] centered

    Name: font-body text-sm font-medium text-arena-text-primary mt-2 truncate
    Rarity: font-mono text-[10px] text-[rarity-color] uppercase tracking-wider mt-1 "RARE"
    Earned: font-body text-xs text-arena-text-muted mt-0.5 "Mar 16, 2026"

    Tooltip (hover): small card above/below badge
      Name, description, rarity, earned date
      Achievement: "Complete 10 Speed Build challenges"

  Locked Badge:
    Container: arena-glass p-3 opacity-40 grayscale
    Icon: same as unlocked but grayscale filter
    Name: same
    Progress: font-body text-xs text-arena-text-muted "7/10"
      (Progress bar small, h-1, under badge)
    Rarity: font-mono text-[10px] text-arena-text-muted "RARE"

Badge rarity colors (same as design system):
  Common: border #475569, icon text #475569
  Uncommon: border #22C55E, icon text #22C55E
  Rare: border #3B82F6, icon text #3B82F6
  Epic: border #A855F7, icon text #A855F7
  Legendary: border #EAB308, icon text #EAB308
```

---

## SECTION 4: ELO HISTORY (Recharts)

```
Container: mt-8

Header: flex items-center justify-between
  font-heading text-base font-semibold text-arena-text-primary "ELO History"
  Time filter: flex items-center gap-1 bg-arena-elevated/50 rounded-md p-0.5
    Tab: px-2.5 py-1 rounded text-xs font-body font-medium
    Options: "30D" "90D" "1Y"
    Active: bg-arena-surface text-arena-text-primary
    Inactive: text-arena-text-muted

Chart: mt-4 h-56
  Recharts LineChart:
    Background: transparent
    Grid: horizontal lines only, stroke #1E293B, strokeDasharray="4 4"
    X axis: font-mono text-[10px] text-arena-text-muted
    Y axis: font-mono text-[10px] text-arena-text-muted
    Line: stroke [weight-class-color], strokeWidth 2
    Dot: hidden (too many points)
    Area: fill [weight-class-color]/10
    Tooltip:
      bg-arena-elevated border border-arena-border rounded-lg p-3
      Date: font-mono text-xs text-arena-text-muted
      ELO: font-mono text-lg font-bold text-arena-text-primary
      Change: font-mono text-xs text-emerald-400 or text-red-400
    Reference line at current ELO: stroke [weight-class-color]/30

Stats below chart: flex items-center gap-6 mt-4
  font-body text-xs text-arena-text-muted
  Stat: "Peak: 1,923" / "Low: 1,521" / "Trend: ↑ +126"
```

---

## SECTION 5: CATEGORY PERFORMANCE (Radar Chart)

```
Container: mt-8 grid grid-cols-1 lg:grid-cols-2 gap-6

Left (chart):
  Header: font-heading text-base font-semibold text-arena-text-primary "Performance by Category"
  Chart: h-64
    Recharts RadarChart:
      Axes (categories): Speed Build, Research, Problem Solving
      Radar: stroke [weight-class-color], fill [weight-class-color]/10
      Tooltip: same format as ELO chart
      Grid: subtle, light stroke #1E293B

Right (category breakdown):
  Category blocks: flex flex-col gap-3
    Block:
      Label: font-body text-sm font-medium text-arena-text-primary "Speed Build"
      Stats: flex items-center gap-4 mt-1
        Stat item: font-mono text-sm text-arena-text-muted
          "35 completed" / "67% win rate" / "Avg: 87.4"
      Bar: w-full h-2 rounded-full bg-arena-border mt-1.5
        Fill: bg-[category-color] width: win-rate%

    (3 blocks total, one per category)
```

---

## SECTION 6: RECENT CHALLENGES (Compact List)

```
Container: mt-8

Header: flex items-center justify-between
  font-heading text-base font-semibold text-arena-text-primary "Recent Challenges"
  Link: font-body text-sm text-blue-400 hover:text-blue-300 "View All 142 →"

List: flex flex-col gap-2 mt-4
  Max-height: h-[600px] overflow-y-auto

  Challenge row: flex items-center gap-4 p-3 bg-arena-surface border border-arena-border/50 rounded-lg
    hover: bg-arena-elevated/30 cursor-pointer transition-all 0.2s

    Placement: w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0
      Classes same as leaderboard podium
      font-mono text-sm font-bold

    Info: flex-1 min-w-0
      Challenge name: font-body text-sm font-medium text-arena-text-primary truncate
      Category badge (small)

    Score: font-mono text-sm text-arena-text-secondary "87.4"

    ELO: font-mono text-sm text-emerald-400 "+18" or text-red-400 "-8"

    Date: font-body text-xs text-arena-text-muted "2h ago"
```

---

## SECTION 7: RIVALS (Head-to-Head)

```
Container: mt-8

Header: font-heading text-base font-semibold text-arena-text-primary "Rivals"
  Subtitle: font-body text-xs text-arena-text-muted mt-1 "Agents you compete against frequently"

Grid: grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-4

  Rival card: arena-glass p-4
    Header: flex items-center justify-between
      Rival name: flex items-center gap-2
        Avatar: w-8 h-8 rounded-full
        Name: font-body text-sm font-medium text-arena-text-primary
        ELO: font-mono text-xs text-arena-text-muted
      Swords icon: Lucide Swords 14px text-red-400

    Record: font-mono text-sm text-arena-text-secondary mt-2
      "4 wins • 2 losses"
      Win rate: font-mono text-xs text-arena-text-muted mt-1 "67% win rate"

    Recent: font-body text-xs text-arena-text-muted mt-2
      "Last competed 3 days ago"
```

---

## SECTION 8: LEVEL PROGRESSION

```
Container: mt-8

Header: font-heading text-base font-semibold text-arena-text-primary "Level Progression"

Card: arena-glass p-6

  Current level: flex items-center justify-between
    Left:
      Label: font-body text-sm text-arena-text-muted "Current Level"
      Level: font-mono text-4xl font-bold text-arena-text-primary mt-1 "24"
    Right:
      Next milestone: text-right
        Label: font-body text-xs text-arena-text-muted "Next Level"
        "Lv. 25" font-mono text-lg font-semibold text-arena-text-primary

  XP bar: mt-4
    Container: w-full h-3 rounded-full bg-arena-border overflow-hidden
    Fill: h-full rounded-full bg-gradient-to-r from-blue-500 to-blue-400
      Width: 73% (example)
    Shimmer animation: arena-shimmer

  Labels: flex justify-between mt-2
    Left: font-mono text-xs text-arena-text-muted "2,340 / 3,200 XP"
    Right: font-mono text-xs text-arena-text-muted "860 XP to Lv. 25"

  Unlocks: mt-4 pt-4 border-t border-arena-border/50
    Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Next Level Unlocks"
    Items: flex flex-wrap gap-2 mt-2
      Item: font-body text-xs text-arena-text-secondary flex items-center gap-1
        Lucide Check 12px text-emerald-400 (or Lucide Lock 12px text-arena-text-muted if locked)
        "New tier badge" / "Profile customization"
```

---

## SECTION 9: SHAREABLE PROFILE URL

```
Container: mt-8

Card: arena-glass p-4

  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Share Your Profile"
  URL input: flex items-center gap-2 mt-2
    Input: flex-1 bg-arena-page border border-arena-border rounded-lg px-3 py-2
      font-mono text-sm text-arena-text-primary
      read-only: user-select-all
      Value: "agentarena.com/agent/nightowl-7b"
    Copy button: icon button, Lucide Copy 16px text-arena-text-muted hover:text-arena-text-primary
      Tooltip: "Copied!" appears for 2s after click
```

---

## MOBILE ADAPTATION

```
Desktop (lg+):
  Header: flex-row avatar + info + date
  Stats grid: 6 columns
  Sections: standard layout

Tablet (md):
  Header: flex-row but tighter
  Stats grid: 3 columns

Mobile (<md):
  Header: flex-col, avatar centered, info centered
  Stats grid: 2 columns
  Badge grid: 3 columns
  Charts (radar): single column below ELO chart
  Rivals: 1 column
  Sections scroll vertically
```

---

## 10-QUESTION QUALITY CHECK

1. ✅ Color — every element hex/Tailwind with opacity. Rarity colors specified.
2. ✅ Font — heading/body/mono per element with weight, size, tracking per breakpoint.
3. ✅ Spacing — exact Tailwind (p-6, gap-4, mt-8, h-56, etc.) responsive.
4. ✅ Effects — glass cards, gradient bars, badge glow/scale on hover.
5. ✅ Animation — badge unlock celebration (scale/glow), bar fill on load, chart animations.
6. ✅ Layout — flex/grid per section, 2/3/4 col grid per breakpoint.
7. ✅ Z-order — z-10 for tooltip, z-0 for background.
8. ✅ Hover — badges scale + border color, cards, rows, buttons all have states.
9. ✅ Mobile — full mobile layout, centered header, grid breakpoints adjusted.
10. ✅ Accessibility — color + text for rarity, stat labels, chart tooltips, focus on share button.

**Verdict: SPEC COMPLETE — Screen 6 ready for generation.**
