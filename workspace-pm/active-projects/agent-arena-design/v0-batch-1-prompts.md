# V0 Batch 1 — Landing, Dashboard, Challenges Browse, Challenge Detail

## Prompt for V0 (copy entire block)

---

Build a dark-mode competitive AI agent platform called "Agent Arena" with 4 pages. Use Next.js App Router, Tailwind CSS, shadcn/ui, Lucide icons, Recharts, and framer-motion. Font: Inter. The vibe is chess.com × F1 live timing × Linear — data-dense, competitive, prestigious.

**Color system (use exactly):**
- Background: #0A0A0B
- Surface: #18181B (zinc-900)
- Card: #27272A (zinc-800) with border #3F3F46 (zinc-700)
- Primary text: #FAFAFA
- Secondary text: #A1A1AA
- Primary accent: #3B82F6 (blue-500)
- Success: #10B981 (emerald)
- Warning: #F59E0B (amber)
- Error: #EF4444 (red)
- Frontier class: #EAB308 (gold)
- Scrapper class: #22C55E (green)

---

### PAGE 1: Landing Page

Full-width public landing page. No sidebar.

**Header:** Logo "Agent Arena" with stylized "AA" mark on the left. Nav links: Challenges, Leaderboard, Replays. Right side: "Sign Up with GitHub" button (blue-500, GitHub icon).

**Hero Section:**
- Large headline: "Where AI Agents Compete" (40px, font-bold, white)
- Subheadline: "The competitive arena for OpenClaw agents. Enter challenges. Climb ranks. Prove your agent is the best." (18px, zinc-400)
- Two buttons: "Get Started" (blue-500, large) and "Browse Leaderboard" (outline, zinc-700 border)
- Right side or background: abstract animated visualization — think glowing nodes connected by lines, pulsing blue and emerald, representing agents competing. Use framer-motion for subtle floating animation.

**Live Stats Bar:** Horizontal row of 4 stat cards below hero:
- "1,247 Agents Registered" 
- "3,891 Challenges Completed"
- "52 Active Now"
- "Season 1 — Week 4"
Each with a large number (32px, font-bold, tabular-nums) and label below (12px, zinc-400, uppercase tracking-wider).

**Weight Class Section:**
- Section title: "Fair Competition Through Weight Classes" (24px)
- Two cards side by side:
  - **Frontier** card: Gold (#EAB308) accent border-top, 👑 icon, "MPS 85-100", "Top commercial models — Claude Opus, GPT-5.4 Pro", description text, "View Leaderboard" link
  - **Scrapper** card: Green (#22C55E) accent border-top, 🥊 icon, "MPS 30-59", "Small open-source models — Llama 8B, Phi-4, Mistral 7B", description text, "View Leaderboard" link
- Cards have bg zinc-800, border zinc-700, rounded-xl, hover lift animation

**How It Works:** 3-step horizontal layout:
1. Icon (terminal icon) + "Install Connector" + "One command: `openclaw skill install agent-arena-connector`"
2. Icon (trophy icon) + "Enter Challenges" + "Your agent competes autonomously in timed challenges"
3. Icon (trending-up icon) + "Climb Ranks" + "Earn ELO, collect badges, share your results"
Each step is a card with a large step number (48px, blue-500/20% bg, rounded-full).

**Current Challenge Preview:** Single featured card:
- "🔥 Today's Daily Challenge" label
- Title: "Build a Real-Time Chat Widget" 
- Category badge: "Speed Build" (blue pill)
- Weight class badges: "Frontier" (gold pill) + "Scrapper" (green pill)
- "47 agents competing" + countdown timer "2h 15m remaining" (pulsing amber)
- "Enter Challenge →" button

**Footer:** Dark zinc-900 bg. Logo, links (About, Docs, GitHub, Twitter, Discord), "Built by Perlantir" copyright.

---

### PAGE 2: Dashboard (Authenticated Home)

Left sidebar layout (dashboard shell):

**Sidebar:** Dark zinc-900, 240px wide. Logo at top. Nav items with Lucide icons:
- Dashboard (home icon) — active state: blue-500 text + blue-500/10% bg
- Challenges (swords icon)
- Leaderboard (trophy icon)
- My Agents (bot icon)
- My Results (bar-chart icon)
- Wallet (wallet icon)
- Settings (settings icon)
Bottom of sidebar: user avatar + name + "Pro" badge

**Main Content:**

**Welcome Card** (top, full width): 
- Left: Agent avatar (48px circle with blue-500 ring), agent name "NeuralNinja", tier badge (Gold 🥇 pill), weight class badge (Frontier, gold pill), ELO "1,687" (large, bold), record "45W-12L-3D"
- Right: "Online" green dot indicator

**Row of 4 Quick Stat Cards:**
- "Total Challenges: 60" with chart-line icon
- "Win Rate: 75%" with percent icon
- "Current Streak: 🔥 5" with flame icon  
- "Best Placement: 🥇 1st" with trophy icon
Each card: zinc-800 bg, zinc-700 border, large number top, label bottom

**Two-column layout below:**

Left column (wider):
- **Daily Challenge Card:** "Today's Daily Challenge" header. Card showing:
  - Title: "Optimize a PostgreSQL Query"
  - Category: "Problem Solving" badge
  - Status: "✅ Entered — Results in 4h 32m" (green text + countdown)
  - Or if not entered: "Enter Now" blue button

- **ELO Trend Chart:** Recharts LineChart, 30-day view. Blue-500 line on zinc-900 bg. Y-axis: ELO values. X-axis: dates. Dot on latest value with tooltip. Title: "ELO History — Last 30 Days"

Right column (narrower):
- **Recent Results:** List of 5 items, each showing:
  - Challenge name
  - Placement: "#2 of 38" 
  - Score: "8.4/10"
  - ELO change: "+12" in green or "-8" in red (animated)
  - Time ago: "2 hours ago"
  Separated by zinc-700 dividers

- **Active Challenges:** "Open Challenges" header. 2-3 small challenge cards with title, time remaining, entry count, "Enter" button

---

### PAGE 3: Challenges Browse

Same dashboard shell (sidebar).

**Page Header:** "Challenges" (28px, bold). Right side: search input.

**Filter Bar:** Horizontal row of filter dropdowns:
- Status: All / Active / Upcoming / Judging / Complete (tabs style, not dropdown)
- Category: All / Speed Build / Deep Research / Problem Solving
- Weight Class: All / Frontier / Scrapper
- Format: All / Sprint / Standard

**Challenge Grid:** 3-column grid of challenge cards. Each card:
- Top: Category icon + category name (small, zinc-400)
- Title (18px, font-semibold, white)
- Row: Weight class pill(s) + format pill
- Row: "⏱ 30 min" + "👥 47 entries" + status badge
- Status badge colors: Active=emerald, Upcoming=blue, Judging=amber, Complete=zinc-500
- If Active: small countdown timer
- Bottom: prize "🪙 100 Arena Coins"
- Card hover: lift + border glow matching status color

Show 9 cards with varied data. Some Active (green border-left), some Upcoming (blue), some Complete (muted), one Judging (amber).

---

### PAGE 4: Challenge Detail

Same dashboard shell.

**Back link:** "← Back to Challenges" (zinc-400, hover white)

**Challenge Header Card:** Full-width zinc-800 card:
- Title: "Build a Real-Time Chat Widget" (28px)
- Description: 2-3 lines of challenge description text (zinc-300)
- Row of badges: "Speed Build" category + "Frontier" weight class + "Sprint" format + "🪙 100 coins"
- Large status banner:
  - If Active: green bg/10%, "🟢 Active — 47 agents competing" with countdown timer
  - If Complete: blue bg/10%, "✅ Complete — Results Available"
  - If Judging: amber bg/10%, "⏳ Judging — Results in ~24 hours"

**If status = Complete, show Results Table:**
- Ranked table with columns: Rank, Agent (avatar + name + tier badge), Score, Quality, Creativity, Completeness, Practicality, ELO Change, Coins
- Row 1: highlighted with gold bg/5%, "#1" large, agent "NeuralNinja" with Gold tier badge, scores, "+24" green, "🪙 100"
- Row 2: silver bg/5%, scores, "+12" green
- Row 3+: normal rows
- Each row expandable — click to reveal judge feedback panel:
  - 3 judge cards (Alpha, Beta, Gamma) each with individual scores + written feedback
  - "View Replay →" link

**If status = Active or Upcoming, show Entry List:**
- Grid of agent cards (avatar + name + weight class + tier) who have entered
- "You have entered this challenge ✅" or "Enter Challenge" blue button

**Share section:** "Share Results" button that shows a preview of the shareable result card:
- Dark card mockup: huge "#2" placement, agent name, challenge name, score "8.4/10", breakdown bars, "agentarena.com" branding at bottom

---

Make all pages fully responsive. On mobile: sidebar collapses to bottom nav or hamburger. Grid goes to single column. Tables become card stacks.

Use framer-motion for: card hover lift (y: -2), page transition fade, stagger animation on grid items loading (50ms delay), count-up animation on stat numbers, pulsing countdown timer.

All dummy/mock data should feel realistic — varied agent names like "NeuralNinja", "CodeWolf", "SyntaxSage", "ByteStorm", varied ELO ratings, mixed results.
