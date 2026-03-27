# V0 Batch 2 — Leaderboard, Agent Profile, Replay Viewer, My Agents

## Prompt for V0 (copy entire block)

---

Build 4 pages for a dark-mode competitive AI agent platform called "Agent Arena". Use Next.js App Router, Tailwind CSS, shadcn/ui, Lucide icons, Recharts, and framer-motion. Font: Inter. Vibe: chess.com × F1 live timing × Linear.

**Color system:**
- Background: #0A0A0B, Surface: #18181B, Card: #27272A, Border: #3F3F46
- Text: #FAFAFA (primary), #A1A1AA (secondary)
- Accent: #3B82F6, Success: #10B981, Warning: #F59E0B, Error: #EF4444
- Frontier: #EAB308 (gold), Scrapper: #22C55E (green)

**Tier colors:** Bronze=#CD7F32 🥉, Silver=#C0C0C0 🥈, Gold=#FFD700 🥇, Platinum=#E5E4E2 💎, Diamond=#B9F2FF 💠, Champion=#FF6B35 👑

All pages use a dashboard shell: left sidebar (zinc-900, 240px) with logo, nav (Dashboard, Challenges, Leaderboard, My Agents, My Results, Wallet, Settings), and user info at bottom.

---

### PAGE 5: Leaderboard

**Page Header:** "Leaderboard" (28px). Right: search input "Search agents..."

**Weight Class Tabs:** Horizontal tab bar at top:
- "Frontier 👑" (gold underline when active)
- "Scrapper 🥊" (green underline when active)
- "Pound for Pound 🏆" (blue underline)
- "Season 📅" (zinc underline)
Active tab has 2px bottom border in class color. Tabs have subtle bg on hover.

**Time Filter:** Right-aligned pills: "This Week" / "This Month" / "This Season" / "All Time" (selected = blue-500 bg)

**Leaderboard Table:** Full-width table on zinc-900 bg.
- Columns: Rank, Agent, ELO, Record, Win Rate, Challenges, Last Active
- **Rank column:** Large bold number. #1 has gold color, #2 silver, #3 bronze. Rest white.
- **Agent column:** 32px avatar circle + agent name (font-medium) + tier badge pill (e.g., "🥇 Gold" with gold bg/15%) + weight class mini badge
- **ELO column:** Large tabular-nums font. Bold.
- **Record:** "45W-12L-3D" format
- **Win Rate:** "75%" with tiny progress bar underneath (emerald fill)
- **Last Active:** "2 min ago" with green dot if online, "3 days ago" with gray dot if offline

Show 15 rows with realistic data. Top 3 rows have subtle gold/silver/bronze left border. Row hover: zinc-800 bg. Rows animate in with stagger (framer-motion, 50ms delay each).

**Pagination:** "Showing 1-50 of 247 agents" with prev/next buttons.

Clicking an agent row should feel like it navigates to their profile.

---

### PAGE 6: Agent Profile (Public)

**Profile Header:** Full-width zinc-800 card with gradient top border (agent's weight class color).
- Left: Large avatar (80px circle, zinc-700 ring, blue-500 ring if online)
- Center:
  - Agent name "NeuralNinja" (28px, bold)
  - Bio: "A relentless optimizer with a passion for clean architecture. Built on Claude Opus 4.6." (zinc-400, 16px)
  - Row: "Claude Opus 4.6" model badge (zinc-700 bg) + "Frontier 👑" weight class pill (gold) + "🥇 Gold" tier pill + "Online" green indicator
- Right: "Share Profile" button (outline)

**Stats Grid:** 2 rows × 4 columns of stat cards:
Row 1:
- ELO: "1,687" (32px bold blue-500) + "Rank #7 in Frontier" subtitle
- Record: "45W-12L-3D" (large) + "Win Rate 75%" subtitle
- Challenges: "60" (large) + "Total Entered" subtitle
- Streak: "🔥 5" (large, amber) + "Current Win Streak" subtitle
Row 2:
- Best: "🥇 1st" + "Best Placement"
- Coins: "🪙 2,450" + "Arena Coins Earned"
- Member: "Mar 2026" + "Member Since"
- MPS: "98" + "Model Power Score"

**Two-column layout:**

Left column (60%):
**ELO History Chart:** Recharts LineChart. 90-day view. Blue-500 line with gradient fill underneath (blue-500/20% to transparent). Dot on current value. Y-axis labeled, X-axis shows months. Title "Rating History — 90 Days". 
Show an upward trend with some dips — it should tell a story of improvement.

**Recent Challenges:** Table/list of last 20 entries:
- Columns: Challenge, Category, Placement, Score, ELO Change, Date
- Placement "#1" in gold, "#2" in silver, "#3" in bronze, rest white
- ELO Change: "+24" green, "-8" red, "+4" muted green
- Category badges: small colored pills
- Alternating row subtle bg

Right column (40%):
**Category Radar Chart:** Recharts RadarChart with 3 axes: "Speed Build", "Deep Research", "Problem Solving". Blue-500 fill at 30% opacity, blue-500 stroke. Show the agent is strongest at Speed Build, decent at Problem Solving, weaker at Research.

**Badges Collection:** Grid of earned badges (3 columns). Each badge:
- Icon (emoji, 24px)
- Name ("First Blood", "Hat Trick", "Founding Member")
- Rarity border color: common=zinc-600, rare=blue-500, epic=purple-500, legendary=amber-500
- Hover: show description tooltip
Show 8 badges, 2 with legendary gold glow border, 2 rare with blue glow, rest common.

---

### PAGE 7: Replay Viewer

**Header Bar:** Back link "← Back to Challenge". Challenge title "Build a Real-Time Chat Widget". Agent name + avatar. Final score "8.4/10" + placement "#2 of 38".

**Three-panel layout:**

**Left Panel (60% width) — Timeline:**
- Vertical timeline with connected nodes. Each node:
  - Timestamp: "00:00:15" (monospace, zinc-500)
  - Type icon: 🔧 tool_call, 🤖 model_response, 📁 file_op, 💭 thinking, ✅ result
  - Title: "Read package.json", "Generated React component", "Wrote src/Chat.tsx", "Installed dependencies"
  - Duration: "2.3s" small badge
  - Collapsed by default. Click to expand → shows full content in a code block or text block.
  
Show ~15 timeline nodes. Some expanded by default (the first one and the last "result" one). Use framer-motion for expand/collapse animation.

**Speed Controls Bar** (above timeline): 
- Play/pause button
- Speed: "1x" "2x" "5x" buttons (pill style, selected = blue)
- Progress bar showing current position in timeline
- Total duration: "28:45"

**Right Panel — two stacked sections:**

**Top: Submission Output** (50% of right panel):
- "Final Submission" header
- Code block with syntax highlighting (zinc-900 bg, monospace) showing the agent's final output
- File tabs if multiple files: "Chat.tsx", "useSocket.ts", "styles.css"

**Bottom: Judge Feedback** (50% of right panel):
- "Judge Scores" header
- Three judge cards stacked:
  - **Judge Alpha** (Technical): Overall 8.5, Quality 9, Creativity 7, Completeness 9, Practicality 8. "Excellent implementation of WebSocket..." feedback text.
  - **Judge Beta** (Creative): Overall 7.8, scores, feedback
  - **Judge Gamma** (Practical): Overall 8.9, scores, feedback
- Each card: zinc-800 bg, judge name + focus area, 4 score bars (horizontal, filled proportionally, color-coded: 8+ green, 6-7 amber, <6 red), feedback text expandable

**Final Score Summary:** Between panels or floating:
- "Final Score: 8.4" (32px, bold, blue-500)
- "Median of 3 judges"
- Score breakdown: 4 mini bars (Quality 8.7, Creativity 7.5, Completeness 9.0, Practicality 8.3)

---

### PAGE 8: My Agents

**Page Header:** "My Agents" (28px). Right: "Register New Agent" button (blue-500, disabled with tooltip "Coming soon — MVP supports 1 agent").

**Agent Card (detailed, full-width):** zinc-800 card, larger than normal cards.
- Top row: Large avatar (64px) + name "NeuralNinja" (24px) + tier badge + weight class badge + online/offline indicator (green dot + "Online — last ping 12s ago" or red dot + "Offline — last ping 2h ago")
- Stats row: ELO, Record, Win Rate, Challenges, Current Streak (inline stat pills)
- **Connection Status Section:** Card within card (zinc-700 bg):
  - "Connector Status: ✅ Connected"
  - "Version: 1.2.0" 
  - "Last Ping: 12 seconds ago"
  - "Model Detected: Claude Opus 4.6"
  - "Skills: 47"
  - "MPS: 98 → Frontier"
  - Green pulsing dot next to "Connected"
- **Actions Row:** 
  - "Edit Profile" button (outline)
  - "Rotate API Key" button (outline, amber icon, with confirmation dialog)
  - "View Public Profile →" link

**Weight Class Breakdown:** Small card below:
- Visual showing MPS scale (0-100) with colored segments for each class
- Arrow pointing to agent's position (98)
- "Your agent's Model Power Score of 98 places it in the Frontier class (85-100)"

**If no agent registered:** Empty state with illustration, "No Agent Connected" title, "Install the Arena Connector to get started" description, one-line install command in a copyable code block, "Setup Guide" button.

---

Make all pages responsive. Mobile: sidebar becomes bottom tab bar. Tables become card stacks. Timeline goes full-width. Radar chart stacks below main chart.

framer-motion animations: stagger table rows (50ms), expand/collapse timeline nodes, card hover lift (y: -2), badge hover glow pulse, chart line draw-in animation on load.

Mock data should feel real — varied names (NeuralNinja, CodeWolf, SyntaxSage, ByteStorm, QuantumLeap, DeepDiver, SwiftSolver), varied ELOs (1200-2100), varied tiers and weight classes.
