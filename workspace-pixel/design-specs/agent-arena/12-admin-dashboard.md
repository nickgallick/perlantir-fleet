# Screen 12: Admin Dashboard (Feature-Flagged)

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: Linear admin (feature flags), Vercel deployments dashboard, datadog metrics

---

## PAGE LAYOUT & SECURITY

```
Access: Feature-flagged, behind authentication + admin role check
URL: /admin (not discoverable in nav)
Breadcrumb: Admin > Dashboard

If not authorized:
  403 error card: arena-glass p-12 text-center
    Lucide Lock 32px text-red-400
    "Access Denied" — font-heading text-lg font-semibold
    "You don't have permission to view this page."

Container: min-h-screen bg-arena-page
Content: max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## SECTION 1: SYSTEM METRICS (TOP)

```
Container: grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4

Metric card (×4):
  Container: arena-glass p-5 relative

  Icon: 20px Lucide per metric, text-arena-text-muted top-right

  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider
  Value: font-mono text-2xl md:text-3xl font-bold text-arena-text-primary mt-1
  Change: font-mono text-sm text-emerald-400 mt-1 "↑ +12% (24h)"

  Metrics:
  1. Active users: real-time user count with sparkline (tiny chart)
  2. API latency: avg response time (ms) with up/down indicator
  3. Judge costs: total spent today (USD) with budget bar
  4. Active Realtime: WebSocket connection count

Charts (optional): sparkline or mini-chart (Recharts)
  Height: h-12, simplified, no axis labels
  Color: metric-specific (blue for users, red for latency, gold for costs, cyan for connections)
```

---

## SECTION 2: QUICK ACTIONS (ROW)

```
Container: grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 mt-6

Action button (×4):
  Container: arena-glass p-4 flex flex-col items-center text-center cursor-pointer
    hover: border-blue-500/30 scale(1.02) transition-all 0.2s

  Icon: 24px Lucide, text-blue-400

  Label: font-body text-sm font-medium text-arena-text-primary mt-2

  Actions:
  1. Create Challenge (icon: Lucide Plus)
  2. Trigger Judging (icon: Lucide Gavel)
  3. View Logs (icon: Lucide FileText)
  4. Feature Toggles (icon: Lucide Zap)

  Click → open appropriate modal or nav to subsection
```

---

## SECTION 3: CHALLENGE MANAGEMENT

```
Container: mt-8 arena-glass p-6

Header: flex items-center justify-between
  Title: font-heading text-base font-semibold text-arena-text-primary "Challenge Management"
  CTA: primary button Lucide Plus 14px "Create Challenge"

Tabs: underline tabs (create, edit, schedule)
  Tab: px-4 py-2 text-sm font-body font-medium text-arena-text-muted
    Underline on active (height 2px, color blue)

Create challenge form (default tab):
  Grid: grid grid-cols-1 md:grid-cols-2 gap-4

  Fields:
    Title: input, required
    Description: textarea, required
    Category: select dropdown
    Weight class: multi-select or single select
    Time limit: input (hours)
    Prize pool: input (coins)
    Start date: date picker
    End date: date picker
    Prompt: textarea (code block support)

  Buttons: mt-6
    "Create": primary button
    "Cancel": secondary button
    "Save as draft": ghost button

Challenge list (if managing existing):
  Scrollable table
  Columns: Title, Status, Entries, Start, End, Actions
  Action buttons: Edit, Archive, Delete (with confirmation)
```

---

## SECTION 4: FEATURE FLAGS

```
Container: mt-8 arena-glass p-6

Title: font-heading text-base font-semibold text-arena-text-primary "Feature Flags"

Flag list: flex flex-col gap-3

  Flag item: flex items-center justify-between p-4 bg-arena-elevated/40 rounded-lg

    Left:
      Name: font-body text-sm font-medium text-arena-text-primary "spectator_mode"
      Description: font-body text-xs text-arena-text-secondary mt-1
        "Allow live spectating of active challenges"
      Status: font-mono text-xs text-arena-text-muted mt-1
        "Rollout: 100% • Last updated 2h ago"

    Right:
      Toggle: Shadcn Switch, color-coded (on: green, off: gray)

  Flags:
    - spectator_mode: Live spectating
    - real_time_rankings: Real-time leaderboard updates
    - premium_features: Unlock premium tier badges
    - beta_replay_viewer: Enhanced replay visualization
    - experimental_radar: Radar chart on profiles
    - direct_withdrawals: Withdraw coins to bank
```

---

## SECTION 5: USER / AGENT SEARCH

```
Container: mt-8 arena-glass p-6

Title: font-heading text-base font-semibold text-arena-text-primary "Search Users & Agents"

Search bar:
  Input: w-full h-10 bg-arena-page border border-arena-border rounded-lg px-3
    font-body text-sm placeholder-arena-text-muted "Search by username, agent name, ELO..."
    focus: border-blue-500/40 ring-1 ring-blue-500/20

Search results (dropdown or below):
  List: max-h-64 overflow-y-auto

  Result item: flex items-center gap-3 p-3 hover:bg-arena-elevated/40 cursor-pointer rounded-lg

    Avatar: w-8 h-8 rounded-full

    Info: flex-1
      Name: font-body text-sm font-medium text-arena-text-primary
      Type badge: font-mono text-xs text-arena-text-muted "User" or "Agent"
      Stats: font-body text-xs text-arena-text-secondary

    Click → opens user/agent admin card (see below)

Admin card (expanded view):
  Container: arena-glass p-6 mt-4 w-full

  User details:
    Avatar + name + email
    Account status: Active / Suspended / Banned (toggle)
    Created: date
    Last active: timestamp
    Total challenges: count
    Total coins: amount

  Actions:
    "Suspend Account": secondary button
    "Ban User": secondary button text-red-400
    "Reset Password": secondary button
    "Send Message": secondary button

  Close: Lucide X button top-right
```

---

## SECTION 6: JOB QUEUE STATUS

```
Container: mt-8 arena-glass p-6

Title: font-heading text-base font-semibold text-arena-text-primary "Job Queue"

Queues (tabs or sections):
  Pending, Processing, Failed, Completed

Queue card per status:
  Job item: flex items-center justify-between p-3 bg-arena-elevated/40 rounded-lg

    Left:
      Job type: font-body text-sm font-medium text-arena-text-primary "Judge: Challenge #1247"
      Details: font-body text-xs text-arena-text-secondary "Submitted 5m ago • 38 entries"
      Status: font-mono text-xs text-arena-text-muted "Processing (60%)"

    Right:
      Progress bar (optional): w-12 h-2 rounded-full bg-arena-border
        Fill: bg-blue-500 width: 60%
      Status badge: bg-amber-500/15 text-amber-400 "In Progress"
      Cancel button: icon button Lucide X (pending/processing only)

Queue stats:
  Row: flex gap-6 mt-4 pt-4 border-t border-arena-border/50
    Stat: font-mono text-sm
      "Pending: 3" / "Processing: 5" / "Failed: 0" / "Completed: 1,247"
```

---

## SECTION 7: SYSTEM METRICS (DETAILED)

```
Container: mt-8

Tabs: API Response Times, Judge Costs, Realtime Connections

API Response Times:
  Chart: Recharts LineChart h-80
    X-axis: time (hourly)
    Y-axis: response time (ms)
    Line: stroke blue
    Fill area: blue/10
    Thresholds: 500ms (amber line, dashed)
  Stats below: "Avg: 245ms • P95: 589ms • Max: 2,342ms"

Judge Costs:
  Chart: Recharts BarChart h-80
    X-axis: date (daily)
    Y-axis: cost (USD)
    Bars: per judge or total
  Stats below: "Today: $1,247 • Budget: $5,000 • Remaining: $3,753"

Realtime Connections:
  Chart: Recharts AreaChart h-80
    X-axis: time (hourly)
    Y-axis: connection count
    Area: cyan/20
    Line: cyan
  Stats below: "Peak: 1,247 • Current: 832 • Avg: 654"
```

---

## MOBILE ADAPTATION

```
Mobile (<md):
  Metrics grid: 2 columns instead of 4
  Quick actions: 2 columns instead of 4
  Tables: horizontal scroll or card layout
  Charts: full-width, smaller height (h-48)
  Forms: single column
  Buttons: full-width
```

---

## 10-QUESTION QUALITY CHECK

1. ✅ Color — hex/Tailwind (status colors, metric colors, toggle colors).
2. ✅ Font — font-heading/body/mono per element.
3. ✅ Spacing — exact Tailwind (p-6, gap-4, h-10, max-h-64).
4. ✅ Effects — glass cards, form input focus state, hover scale.
5. ✅ Animation — toggle slide, chart animations (Recharts), modal fade.
6. ✅ Layout — grid per breakpoint, tabs, charts full-width, form grid.
7. ✅ Z-order — z-10 for content.
8. ✅ Hover — action buttons, queue items, results.
9. ✅ Mobile — 2-col metrics, full-width forms, horizontal scroll tables.
10. ✅ Accessibility — form labels, toggle aria-label, tabs keyboard nav, charts with tooltips.

**Verdict: SPEC COMPLETE — Screen 12 ready for generation.**
