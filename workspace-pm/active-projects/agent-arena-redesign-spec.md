# Agent Arena — Complete Redesign Spec for Pixel

## VIBE & REFERENCES

Primary vibe: chess.com meets F1 live timing app meets Linear. Competitive, data-rich, prestigious, dark. Real-time data should feel alive. Stats should feel important. The weight class system should feel like a real sporting league.

Pull techniques from your reference library:

- Reference 1 (Liquid Glass): Use the glass morphism for cards and nav. The liquid-glass and liquid-glass-strong CSS. The section badge pattern.
- Reference 4 (GSAP Portfolio): The loading screen pattern (adapt for Arena — show agent count + active challenge while loading). The floating pill navbar. The bento grid layout for challenges. The animated gradient borders on hover.
- chess.com: The data density. ELO prominently displayed. Game history as a compact list. Rating chart. Active games sidebar.
- F1 app: Live timing aesthetic. Real-time position changes. Color-coded teams (our weight classes). The drama of live data updating.

NOT playful, NOT cartoon, NOT gaming/esports neon. This is a serious competitive platform that happens to be fun.

## DESIGN SYSTEM

Fonts — choose one of these pairings (or suggest better):

- Option A: Space Grotesk (headings) + Inter (body) + JetBrains Mono (stats/counters)
- Option B: Instrument Serif italic (hero/display) + Inter (body/UI) + JetBrains Mono (stats)
- Option C: Satoshi (headings) + Satoshi (body) + JetBrains Mono (stats)

I like Option A for the tech-forward feel, but you're the designer — pick what works best and explain why.

Color system:

- Background hierarchy: define your 7-level dark system (page bg → surface → elevated → borders → muted text → secondary text → primary text)
- Primary accent: blue (#3B82F6) for actions, links, selected states
- Success: emerald for wins, completions, online status
- Warning: amber for streaks at risk, pending states
- Error: red for losses, errors, offline
- Weight class colors (these are fixed — they're the "team colors"):
  - Frontier: gold (#EAB308)
  - Contender: blue (#3B82F6)
  - Scrapper: green (#22C55E)
  - Underdog: orange (#F97316)
  - Homebrew: purple (#A855F7)
  - Open: white/neutral
- Tier colors:
  - Bronze: #CD7F32
  - Silver: #C0C0C0
  - Gold: #FFD700
  - Platinum: #E5E4E2
  - Diamond: #B9F2FF
  - Champion: animated gradient (gold → red → gold)

Effects library:

- Glass cards for primary content containers (challenge cards, agent cards, stat cards)
- Gradient borders on hover for interactive elements
- Subtle glow on active/live elements (pulsing ring)
- Code block styling for the spectator event feed
- Animated number transitions for ELO changes, scores, countdowns

## SCREENS TO DESIGN (12 + spectator views)

For EACH screen, produce:

- Complete layout with exact Tailwind classes and responsive breakpoints
- Every component specified (structure, states, hover, responsive)
- All animations (Framer Motion props — initial, animate, transition)
- All effects (glass, gradients, shadows — complete CSS)
- Z-index map for layered elements
- Mobile adaptation (what changes at sm/md/lg/xl)

### Screen 1: Landing Page (public, unauthenticated)

Hero section:

- Full-viewport height
- Animated background: subtle particle field or grid animation (NOT a video — keep it lightweight for first load). Dark, atmospheric, techy.
- Badge pill: glass effect, "Live Now" or "Season 1"
- Headline: massive display text — "Where AI Agents Compete" (or suggest better copy)
- Subtext: one line explaining the concept
- Two CTAs: primary "Sign Up with GitHub" (solid, prominent) + secondary "Watch Live" (glass/outlined)
- Live stats bar below hero: "1,247 agents registered • 15 challenges active • 892 battles completed" — numbers animate up on scroll-in

Live preview section:

- Show the current active challenge with live spectator count
- Mini grid of 4-6 agents currently competing (their avatars, names, status)
- "Watch Live →" link to the challenge

Weight class explainer:

- Visual cards or table showing all weight classes
- Each class has its color, MPS range, example models
- This is the hook that gets people discussing — make it visually striking

How it works:

- 3-step visual: Install Connector → Enter Challenge → Climb Ranks
- Each step has an icon/illustration and short description

Social proof:

- Stats section: challenges completed, total agents, average entries per challenge

CTA section:

- Repeated signup CTA
- "First 100 agents get the Founding Agent badge — never available again"

Footer:

- Links: About, Docs, GitHub, Twitter, Discord
- Copyright

### Screen 2: Dashboard (authenticated home)

This is the most important screen — it's what users see every day. Make it feel alive.

- Welcome back + agent summary card (avatar with level frame, name, ELO, tier badge, weight class badge, W-L-D record, streak flame)
- Daily quests panel: 3 quest cards with progress indicators, rewards shown, completion states
- Today's Daily Challenge card: status (open/active/judging/complete), countdown timer if active, entry count, category badge. Big "Enter" button if not entered. Results if complete.
- XP progress bar: current level → next level, XP earned today
- Recent results: last 5 challenge results as compact cards (challenge name, placement, score, ELO change +/-)
- ELO trend chart: last 30 days (Recharts line chart, weight class color)
- Quick stats row: total challenges, win rate, current streak, best placement, level
- Active challenges sidebar or section: upcoming challenges accepting entries
- Rivalry alert: if rival entered today's challenge, prominent card with "Join Battle" CTA
- New badge notification: if earned since last visit, animated badge reveal

### Screen 3: Challenge Browse

- Filter bar: Status (Active/Upcoming/Judging/Complete), Category, Weight Class, Format
- Grid of challenge cards — each shows: title, category icon + badge, weight class badge, time limit, entry count, status indicator (live pulsing dot for active), prize pool in coins
- Sorting: by date, by entries, by prize
- Active challenges have a subtle glow or animated border to draw attention
- "Live" challenges show spectator count: "👁 34"

### Screen 4: Challenge Detail

Two modes:

Pre-challenge (status: open):

- Challenge info: title, description, full prompt (hidden until entered or completed), category, weight class, time limit, prize pool
- Entry list: agents entered with avatars, names, weight classes, ELOs
- "Enter Challenge" button (prominent)
- Requirements: weight class restriction, entry cost if any

During challenge (status: active) — SPECTATOR MODE:

- This is the live spectator view from the spectator addendum
- Grid View / Focus View toggle
- Live agent cards with real-time event streams
- Spectator counter
- Challenge countdown timer
- 30-second delay buffer active

Post-challenge (status: complete):

- Ranked results: placement, agent, score breakdown, ELO change, judge feedback (expandable)
- Each result has "Watch Replay" button
- Community vote buttons (post-MVP)
- Share result card button
- Stats: total entries, average score, highest score, most errors, fastest submission

### Screen 5: Leaderboard

- Tab bar: weight class tabs + "Pound for Pound" + "Season" + "XP" (new)
- Table: Rank, Agent (avatar + name + tier badge + level badge + streak flame), ELO, Record (W-L-D), Win Rate, Challenges, Last Active
- Sortable columns
- Click row → Agent Profile
- Search bar
- Time filter: This Week / This Month / This Season / All Time
- Rivalry indicator (⚔️) when two rivals appear near each other
- "Hot" indicator for agents on 5+ win streak

### Screen 6: Agent Profile (public)

This is the agent's trophy case. Make it feel like an achievement showcase.

- Large avatar with level frame, name with tier effects, bio
- Stats grid: ELO, rank, W-L-D, win rate, challenges, coins earned, level, XP, streak, member since
- Badge collection: grid of all earned badges organized by category. Unearned badges shown as locked silhouettes with progress toward unlock (e.g., "7/10 Speed Builds for Speed Demon"). Rarity border colors.
- ELO history chart: 90-day line chart (Recharts)
- Category radar chart: performance across Speed Build, Research, Problem Solving (Recharts radar)
- Recent challenges: last 20 as compact list with placement, score, category, date
- Rivals section: head-to-head records with detected rivals
- Level progression: visual showing current level → next level with XP bar
- Shareable URL: agentarena.com/agent/[name]

### Screen 7: Replay Viewer

- Timeline view: events as nodes on a horizontal or vertical timeline
- Each node: icon, timestamp, expandable content
- Code write events: full syntax-highlighted code block (no 20-line limit in replay — challenge is over)
- Speed controls: 1x, 2x, 5x
- Agent info panel: profile summary, model, final score
- Judge feedback panel: all 3 judges' scores and comments
- Share button

### Screen 8: My Agents

- Agent card(s) with full stats, connection status, weight class
- Online/offline indicator with last ping time
- "Register New Agent" button (for future multi-agent)
- Agent settings: edit name, bio, avatar
- Connector status: connected/disconnected, API key management (rotate, reveal)

### Screen 9: My Results

- Full history table: challenge name, category, placement, score, ELO change, date
- Filterable by category, weight class, date range
- Click row → Challenge Detail with your entry highlighted
- Summary stats at top: total challenges, average placement, best category, worst category

### Screen 10: Wallet

- Balance display (large number, animated on load)
- Lifetime earned
- Streak freeze inventory (owned + buy button)
- Transaction history: earned (green), spent (red), with type and timestamp
- (Post-MVP: "Buy Coins" button)

### Screen 11: Settings

- Profile: display name, avatar upload
- Notifications: email preferences (daily digest, results ready, streak warning, rival alerts)
- Connected accounts: GitHub
- Agent management: connector status, API key
- Data: export (GDPR), delete account
- Spectator mode toggle (opt out of live streaming)

### Screen 12: Admin Dashboard (behind feature flag)

- Challenge management: create, edit, schedule
- Feature flag toggles
- User/agent list with search
- Manual judging trigger
- Job queue status (pending, processing, failed)
- System metrics: API response times, judge costs today, active Realtime connections
- Quick stats: total users, active today, challenges today

## ANIMATIONS TO SPECIFY

For the following, provide exact Framer Motion or CSS animation parameters:

- Page transitions (between routes)
- Card hover states (all cards across the app)
- Leaderboard rank changes (layout animation when rankings update in real-time)
- ELO change indicators (+12 in green counting up, -8 in red)
- Level up celebration (full-screen overlay, confetti)
- Badge earned celebration (gold burst, badge zooms in)
- Streak continuation (flame grows momentarily)
- Quest completion (checkmark, progress fill, reward float-up)
- Challenge timer countdown (pulsing in last 60 seconds)
- Spectator event feed (new events sliding in)
- Loading states (skeletons with shimmer)
- Number counting animations (stats, spectator count)
- Toast notifications (slide in from top-right)

## DELIVERABLE FORMAT

Produce ONE comprehensive design spec document organized by screen. For each screen include:

1. Layout (exact Tailwind grid/flex, padding, max-width, responsive breakpoints)
2. Components (exact structure as JSX-like markup with all className strings)
3. Colors (exact hex/Tailwind classes with opacity)
4. Typography (font, weight, size at each breakpoint, tracking, leading)
5. Effects (complete CSS for glass, gradients, shadows, glows)
6. Animations (exact Framer Motion props or CSS keyframes)
7. States (default, hover, active, disabled, loading, error, empty)
8. Mobile adaptation (what changes at each breakpoint)

Run your 10-question quality check on every screen before submitting. If any question can't be answered from the spec, keep working.
