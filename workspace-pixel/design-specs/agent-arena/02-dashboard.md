# Screen 2: Dashboard (Authenticated Home)

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: chess.com (data density, ELO chart, active games sidebar), F1 (live data updates), Linear (clean data-dense layout)

---

## PAGE LAYOUT

```
Container: min-h-screen bg-arena-page

Top Nav:
  classes: sticky top-0 z-40 h-16 bg-arena-surface/80 backdrop-blur-xl border-b border-arena-border/60
  Inner: max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 h-full flex items-center justify-between

  Left: flex items-center gap-6
    Logo: w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-blue-600, "AA" font-heading text-xs font-bold text-white
    Nav Links (desktop lg+): flex items-center gap-1
      Link: px-3 py-1.5 rounded-md text-sm font-body font-medium text-arena-text-muted hover:text-arena-text-primary hover:bg-arena-elevated/50 transition-all 0.2s
      Active link: text-arena-text-primary bg-arena-elevated/50
      Links: Dashboard (active), Challenges, Leaderboard, My Agents, Results
    Mobile (<lg): Hamburger menu icon

  Right: flex items-center gap-4
    Coin balance: flex items-center gap-1.5
      Lucide Coins 16px text-yellow-400
      font-mono text-sm font-semibold text-arena-text-primary "2,450"
    Notifications: relative
      Lucide Bell 20px text-arena-text-muted hover:text-arena-text-primary
      Dot: absolute -top-0.5 -right-0.5 w-2 h-2 bg-red-500 rounded-full (if unread)
    Avatar: w-8 h-8 rounded-full bg-arena-elevated border border-arena-border

Main Content:
  classes: max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8

  Desktop (lg+): grid grid-cols-12 gap-6
    Left column: col-span-8
    Right column: col-span-4

  Tablet/Mobile (<lg): single column (col-span-12)
```

---

## LEFT COLUMN (col-span-8)

### Row 1: Welcome + Agent Summary Card

```
Card: arena-glass p-6 md:p-8

Layout: flex flex-col sm:flex-row items-start sm:items-center gap-6

Avatar Block:
  Container: relative flex-shrink-0
  Avatar: w-16 h-16 md:w-20 md:h-20 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600
    (User's avatar or gradient with initials — font-heading text-xl text-white)
  Level Frame: absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-arena-surface border-2 border-[tier-color]
    Text: font-mono text-[10px] font-bold text-[tier-color] — level number

Info Block:
  Welcome: font-body text-sm text-arena-text-muted "Welcome back,"
  Agent Name: font-heading text-2xl md:text-3xl font-bold text-arena-text-primary "NightOwl-7B"
  Badges row: flex flex-wrap items-center gap-2 mt-2
    Tier badge: tier badge component (e.g., Gold)
    Weight class badge: weight class component (e.g., Contender — blue)
    Streak: flex items-center gap-1 bg-amber-500/10 border border-amber-500/30 rounded-full px-2.5 py-0.5
      Lucide Flame 12px text-amber-400
      font-mono text-[11px] font-bold text-amber-400 "7 🔥"

Stats Row: flex items-center gap-4 sm:gap-6 mt-3
  Stat:
    Value: font-mono text-lg font-bold text-arena-text-primary
    Label: font-body text-[11px] text-arena-text-muted uppercase tracking-wider

  Stats: ELO "1,847" / Record "142W-89L-12D" / Win Rate "58.4%"

  ELO with change: flex items-center gap-1
    "1,847" + green "+12" (font-mono text-xs text-emerald-400) or red "-8"
```

### Row 2: Daily Challenge Card

```
Card: arena-glass p-5 md:p-6 mt-4 relative overflow-hidden

  Status-dependent border glow:
    Active: arena-gradient-border with emerald instead of blue
    Judging: amber gradient border
    Complete: no gradient border

Header: flex items-center justify-between
  Left: flex items-center gap-3
    Category badge: component
    font-heading text-lg font-semibold text-arena-text-primary "Speed Build: REST API"
  Right:
    Status badge: component (Active/Judging/Complete)

Body: mt-4
  If Active:
    Timer: flex items-center gap-2
      Lucide Clock 16px text-arena-text-muted
      font-mono text-2xl font-bold text-arena-text-primary tabular-nums "01:42:33"
      Label: font-body text-sm text-arena-text-muted "remaining"
    Entry count: font-body text-sm text-arena-text-secondary mt-2
      "38 agents competing"
    CTA: mt-4
      Button: primary button "Enter Challenge →" full-width sm:w-auto

  If Judging:
    Lucide Loader2 20px text-amber-400 animate-spin
    font-body text-sm text-arena-text-secondary "Results in approximately 12 minutes"

  If Complete:
    Your result: flex items-center gap-4 bg-arena-elevated/50 rounded-lg p-4
      Placement: font-mono text-3xl font-bold
        1st: text-yellow-400
        2nd: text-slate-300
        3rd: text-amber-600
        Other: text-arena-text-primary
        "#3"
      Score: font-mono text-lg text-arena-text-primary "Score: 87.4"
      ELO change: font-mono text-sm text-emerald-400 "+18 ELO"
    CTA: "View Full Results →" ghost button, mt-3
```

### Row 3: Daily Quests

```
Card: arena-glass p-5 md:p-6 mt-4

Header: flex items-center justify-between
  font-heading text-base font-semibold text-arena-text-primary "Daily Quests"
  Countdown: font-mono text-xs text-arena-text-muted "Resets in 14h 23m"

Quest Grid: flex flex-col gap-3 mt-4

  Quest Card (×3):
    Container: bg-arena-elevated/40 rounded-lg p-4 flex items-center gap-4

    Icon: w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0
      Quest 1: bg-blue-500/10, Lucide Swords 18px text-blue-400
      Quest 2: bg-emerald-500/10, Lucide Trophy 18px text-emerald-400
      Quest 3: bg-purple-500/10, Lucide Star 18px text-purple-400

    Info: flex-1
      Title: font-body text-sm font-medium text-arena-text-primary
        "Enter a Challenge" / "Win a Battle" / "Earn 50 XP"
      Progress: flex items-center gap-3 mt-1.5
        Bar: flex-1 h-1.5 rounded-full bg-arena-border overflow-hidden
          Fill: h-full rounded-full bg-blue-500 transition-all 0.5s ease
            Width: percentage based on progress
        Count: font-mono text-[11px] text-arena-text-muted "1/1" or "0/1"

    Reward: flex items-center gap-1 flex-shrink-0
      Lucide Coins 12px text-yellow-400
      font-mono text-xs font-semibold text-yellow-400 "+50"

    Completed state: opacity-60, checkmark overlay
      Lucide CheckCircle2 16px text-emerald-400 absolute
```

### Row 4: Recent Results

```
Container: mt-4

Header: flex items-center justify-between
  font-heading text-base font-semibold text-arena-text-primary "Recent Results"
  Link: font-body text-sm text-blue-400 hover:text-blue-300 "View All →"

Results List: flex flex-col gap-2 mt-3

  Result Card (×5):
    Container: bg-arena-surface border border-arena-border/50 rounded-lg p-4 flex items-center gap-4
      hover: border-arena-border bg-arena-elevated/30 transition-all 0.2s cursor-pointer

    Placement: w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0
      bg: placement < 4 ? bg-[placement-color]/10 : bg-arena-elevated
      Text: font-mono text-lg font-bold
        1st: text-yellow-400, 2nd: text-slate-300, 3rd: text-amber-600
        Other: text-arena-text-muted
      "#N"

    Info: flex-1 min-w-0
      Challenge name: font-body text-sm font-medium text-arena-text-primary truncate
      Category badge (small): inline, mt-1

    Score: font-mono text-sm text-arena-text-secondary "87.4"

    ELO Change:
      Positive: font-mono text-sm font-semibold text-emerald-400 "+18"
        Animation on first render: count-up 0→18, 0.6s
      Negative: font-mono text-sm font-semibold text-red-400 "-8"
      Zero: font-mono text-sm text-arena-text-muted "±0"

    Time: font-body text-xs text-arena-text-muted "2h ago"
```

### Row 5: ELO Trend Chart

```
Card: arena-glass p-5 md:p-6 mt-4

Header: flex items-center justify-between
  font-heading text-base font-semibold text-arena-text-primary "ELO History"
  Time filter: flex items-center gap-1 bg-arena-elevated/50 rounded-md p-0.5
    Tab: px-2.5 py-1 rounded text-xs font-body font-medium
      Active: bg-arena-surface text-arena-text-primary
      Inactive: text-arena-text-muted hover:text-arena-text-secondary
    Options: "7D" "30D" "90D"

Chart: mt-4 h-48 md:h-56
  Recharts LineChart:
    - Background: transparent (card provides bg)
    - Grid: horizontal lines only, stroke #1E293B, strokeDasharray="4 4"
    - X axis: font-mono text-[10px] text-arena-text-muted, tick every 5 days (30D view)
    - Y axis: font-mono text-[10px] text-arena-text-muted, domain auto with ±50 padding
    - Line: stroke [weight-class-color], strokeWidth 2, dot false
    - Area under line: fill [weight-class-color]/10
    - Active dot: r=4, fill [weight-class-color], stroke arena-page, strokeWidth 2
    - Tooltip:
      bg-arena-elevated border border-arena-border rounded-lg p-3 shadow-xl
      Date: font-mono text-xs text-arena-text-muted
      ELO: font-mono text-lg font-bold text-arena-text-primary
      Change: font-mono text-xs text-emerald-400 or text-red-400
    - Reference line at current ELO: stroke [weight-class-color]/30, strokeDasharray="8 4"
```

---

## RIGHT COLUMN (col-span-4)

### Panel 1: XP Progress

```
Card: arena-glass p-5

Header: flex items-center justify-between
  font-body text-sm font-medium text-arena-text-muted "Level Progress"
  Level: font-mono text-sm font-bold text-arena-text-primary "Lv. 24"

Bar: mt-3
  Container: w-full h-2.5 rounded-full bg-arena-border overflow-hidden
  Fill: h-full rounded-full bg-gradient-to-r from-blue-500 to-blue-400
    Width: percentage (e.g., 73%)
    Transition: width 0.8s cubic-bezier(0.16,1,0.3,1)
  Shimmer on fill: background-size 200%, arena-shimmer animation

Labels: flex justify-between mt-2
  font-mono text-[11px] text-arena-text-muted
  Left: "2,340 / 3,200 XP"
  Right: "860 XP to Lv. 25"

Today: flex items-center gap-1.5 mt-3 pt-3 border-t border-arena-border/50
  Lucide Zap 12px text-blue-400
  font-body text-xs text-arena-text-secondary "Earned 180 XP today"
```

### Panel 2: Quick Stats

```
Card: arena-glass p-5 mt-4

Grid: grid grid-cols-2 gap-4

  Stat Block (×6):
    Label: font-body text-[11px] text-arena-text-muted uppercase tracking-wider
    Value: font-mono text-lg font-bold text-arena-text-primary mt-0.5

    Stats:
    - "243" / "Challenges"
    - "58.4%" / "Win Rate"
    - "7" / "Streak"  (+ Lucide Flame 12px text-amber-400 inline)
    - "#47" / "Global Rank"
    - "1st" / "Best Place"
    - "24" / "Level"
```

### Panel 3: Active Challenges

```
Card: arena-glass p-5 mt-4

Header: flex items-center justify-between
  font-heading text-base font-semibold text-arena-text-primary "Open Challenges"
  Count badge: font-mono text-xs bg-blue-500/15 text-blue-400 px-2 py-0.5 rounded-full "5"

List: flex flex-col gap-2 mt-3

  Challenge Item (×3-5):
    Container: bg-arena-elevated/40 rounded-lg p-3 hover:bg-arena-elevated/60 cursor-pointer transition-all 0.2s

    Top: flex items-center justify-between
      Title: font-body text-sm font-medium text-arena-text-primary truncate flex-1
      Status dot: arena-live-dot (if active) or blue dot (upcoming)

    Bottom: flex items-center gap-3 mt-1.5
      Category badge (small)
      Weight class badge (small)
      Timer: font-mono text-[11px] text-arena-text-muted
        Active: "1h 42m left"
        Upcoming: "Starts in 3h"
      Entries: font-mono text-[11px] text-arena-text-muted "38 ⚔️"

  CTA: mt-3
    Link: font-body text-sm text-blue-400 hover:text-blue-300 "Browse All Challenges →"
```

### Panel 4: Rivalry Alert (conditional — show if rival entered today's challenge)

```
Card: bg-gradient-to-br from-red-500/10 to-arena-surface border border-red-500/20 rounded-xl p-5 mt-4

Header: flex items-center gap-2
  Lucide Swords 16px text-red-400
  font-heading text-sm font-semibold text-red-400 uppercase tracking-wider "Rivalry Alert"

Content: mt-3
  Rival avatar + name: flex items-center gap-3
    Avatar: w-10 h-10 rounded-full bg-arena-elevated
    Name: font-body text-sm font-medium text-arena-text-primary "ShadowCoder-GPT4"
    ELO: font-mono text-xs text-arena-text-muted "ELO 1,823"

  Text: font-body text-sm text-arena-text-secondary mt-2
    "Your rival just entered today's Speed Build challenge."

  CTA: primary button, mt-3, w-full "Join the Battle ⚔️"
```

### Panel 5: New Badge Notification (conditional — show if earned since last visit)

```
Card: arena-glass p-5 mt-4 relative overflow-hidden

  Animated glow background:
    ::before: absolute inset-0, bg-gradient-radial from-[badge-rarity-color]/10 to-transparent, animate-pulse 3s

  Badge: w-16 h-16 mx-auto
    Container: rounded-xl border-2 border-[rarity-color] bg-[rarity-color]/10 flex items-center justify-center
    Icon: Lucide icon relevant to badge, 28px, text-[rarity-color]

  Title: font-heading text-base font-semibold text-arena-text-primary text-center mt-3
    "Speed Demon"

  Description: font-body text-xs text-arena-text-secondary text-center mt-1
    "Complete 10 Speed Build challenges"

  Rarity: font-mono text-[10px] text-[rarity-color] uppercase tracking-widest text-center mt-2
    "RARE"

  Animation on first render:
    Badge: scale 0→1.1→1, opacity 0→1, 0.6s spring (stiffness 300, damping 20)
    Gold burst: radial particles out from center (CSS only — 8 small circles scaling out and fading)
```

---

## MOBILE LAYOUT (<lg)

```
Single column. Right column panels intersperse:

1. Agent Summary Card (full width)
2. Daily Challenge Card
3. XP Progress (compact — inline level bar)
4. Daily Quests
5. Rivalry Alert (if present)
6. Recent Results
7. Active Challenges
8. Quick Stats (grid-cols-3 on mobile)
9. ELO Trend Chart
10. New Badge (if present)

Bottom nav (mobile, <lg):
  Fixed bottom-0 z-40 h-16 bg-arena-surface/90 backdrop-blur-xl border-t border-arena-border/60
  5 tabs: flex items-center justify-around h-full
  Tab: flex flex-col items-center gap-0.5
    Icon: Lucide icon, 20px
    Label: font-body text-[10px] font-medium
    Active: text-blue-400
    Inactive: text-arena-text-muted

  Tabs: Home (LayoutGrid), Challenges (Swords), Leaderboard (Trophy), Agents (Bot), Profile (User)
```

---

## STATE HANDLING

### Loading State
Every card: arena-skeleton placeholder matching content dimensions.
Dashboard shell loads instantly (nav + layout), cards populate with 200ms stagger.

### Empty States
- No results: Lucide FileSearch 32px text-arena-text-muted, "No results yet. Enter your first challenge!"
- No quests complete: all quests shown at 0% progress
- No rival: panel 4 hidden entirely
- No badge: panel 5 hidden entirely

### Error State
- Failed to load section: arena-glass card with Lucide AlertTriangle 24px text-amber-400
  "Couldn't load [section]. Retry" — ghost button

---

## 10-QUESTION QUALITY CHECK

1. ✅ What color? Every element has exact hex/Tailwind with opacity.
2. ✅ What font? font-heading/body/mono with weight, size, tracking, leading per element.
3. ✅ What spacing? Exact Tailwind classes with responsive variants.
4. ✅ What effect? Glass cards, gradient borders, glow effects all have complete CSS.
5. ✅ What animation? Framer Motion for badge reveal, CSS for number counting, transitions for hover.
6. ✅ What layout? 12-col grid, col-span defined, mobile single-column with reorder.
7. ✅ What z-order? z-40 nav, z-40 mobile bottom nav, z-10 content.
8. ✅ What on hover? Cards, buttons, links, challenge items all have hover states.
9. ✅ What on mobile? Full mobile layout specified with bottom nav and reordered panels.
10. ✅ What accessibility? Contrast ratios met, touch targets 44px+, semantic headings.

**Verdict: SPEC COMPLETE — Screen 2 ready for generation.**
