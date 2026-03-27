# V0 Batch 3 — My Results, Wallet, Settings, Admin Dashboard

## Prompt for V0 (copy entire block)

---

Build 4 pages for a dark-mode competitive AI agent platform called "Agent Arena". Use Next.js App Router, Tailwind CSS, shadcn/ui, Lucide icons, Recharts, and framer-motion. Font: Inter. Vibe: chess.com × F1 live timing × Linear.

**Color system:**
- Background: #0A0A0B, Surface: #18181B, Card: #27272A, Border: #3F3F46
- Text: #FAFAFA (primary), #A1A1AA (secondary)
- Accent: #3B82F6, Success: #10B981, Warning: #F59E0B, Error: #EF4444
- Frontier: #EAB308 (gold), Scrapper: #22C55E (green)

All pages use a dashboard shell with left sidebar (zinc-900, 240px, logo, nav items with Lucide icons: Dashboard, Challenges, Leaderboard, My Agents, My Results, Wallet, Settings).

---

### PAGE 9: My Results

**Page Header:** "My Results" (28px). Right: "Export CSV" outline button.

**Summary Stats Row:** 4 stat cards across top:
- "Total Challenges: 60" 
- "Average Score: 7.8/10"
- "Average Placement: #4.2"
- "Net ELO Change: +187" (green, large, with trending-up icon)

**Filter Bar:** 
- Category filter: All / Speed Build / Deep Research / Problem Solving (tab pills)
- Weight Class: All / Frontier / Scrapper
- Date range: "Last 7 days" / "Last 30 days" / "Last 90 days" / "All Time"

**Results Table:** Full-width, sortable.
- Columns: Challenge, Category, Date, Placement, Score, ELO Change, Coins, Status
- **Challenge column:** Title text (clickable, blue on hover) 
- **Category:** Small colored pill badge
- **Placement:** "#1" gold, "#2" silver, "#3" bronze, "#4+" white. Large bold number.
- **Score:** "8.4/10" with mini horizontal bar (emerald fill proportional to score)
- **ELO Change:** "+24" in emerald-500 with ▲ arrow, "-8" in red-500 with ▼ arrow, "+2" in muted green. Use framer-motion count-up animation.
- **Coins:** "🪙 100" for 1st, "🪙 60" for 2nd, "🪙 30" for 3rd, "🪙 10" for rest
- **Status:** "Complete" gray badge, "Judging" amber badge with pulse, "In Progress" blue badge

Show 12 rows of varied realistic data. Some wins (#1, #2), some mid-pack (#5, #8), one poor (#15 of 18). Rows with #1 placement have subtle gold left border.

**Pagination:** "Showing 1-20 of 60 results" + prev/next.

**ELO Change Visualization:** Below the table, a small Recharts BarChart showing ELO changes per challenge (last 20). Green bars for positive, red for negative. Hover shows challenge name + exact change.

---

### PAGE 10: Arena Coins / Wallet

**Page Header:** "Arena Coins" (28px) with 🪙 icon.

**Balance Hero Card:** Large zinc-800 card, centered content:
- Huge coin icon or animated coin stack
- Balance: "2,450" (48px, bold, amber/gold gradient text, tabular-nums)
- "Arena Coins" subtitle
- "Lifetime Earned: 3,200" (zinc-400, smaller)
- Two action buttons below: "How to Earn More" (outline) + "Claim Rewards" (blue, disabled with "Coming Soon" tooltip)

**Earning Breakdown:** Row of 3 info cards:
- "🥇 1st Place: 100 coins" 
- "🥈 2nd Place: 60 coins"
- "🥉 3rd Place: 30 coins"
- "Participation: 10 coins"
Each card: zinc-800 bg, icon top, amount bold, subtle coin icon

**Transaction History:**
- "Transaction History" header + filter dropdown (All / Earned / Spent)
- Table or list view:
  - Columns: Date, Description, Amount, Balance After
  - Amount: "+100" green for earnings, "-50" red for spending
  - Description: "1st Place — Build a Chat Widget" or "Entry Fee — Premium Challenge"
  - Newest first
  - Show 10 transactions with varied data

Show mostly earnings (challenge rewards) since MVP has no purchases. Include one "Referral Bonus" and one "Admin Grant" for variety.

**Monthly Earnings Chart:** Small Recharts BarChart showing coins earned per week over last 8 weeks. Amber/gold bars. Title "Weekly Earnings".

---

### PAGE 11: Settings

**Page Header:** "Settings" (28px)

**Tabbed layout or sectioned form on single page. Sections:**

**Section 1 — Profile:**
- Avatar: circle preview (64px) + "Change Avatar" button (outline)
- Display Name: text input, current value "Nick G."
- All in a zinc-800 card with zinc-700 border

**Section 2 — Notifications:**
- Toggle switches (shadcn Switch component) for:
  - "Daily Challenge Reminder" — ON (green)
  - "Results Ready" — ON
  - "Weekly Digest" — OFF
  - "Leaderboard Changes" — OFF
- Each toggle: label + description text (zinc-400) + switch on the right
- In a zinc-800 card

**Section 3 — Connected Accounts:**
- GitHub: Shows icon + "Connected as @nickgallick" + green checkmark + "Disconnect" red text link
- In a zinc-800 card

**Section 4 — Agent Management:**
- "Connector API Key" section:
  - Masked key display: "sk-arena-••••••••••••7f3a"
  - "Copy Key" button + "Rotate Key" button (amber, with warning icon)
  - Warning text: "Rotating your key will disconnect your agent until you update the connector"
- "Reconnect Connector" button (outline)
- In a zinc-800 card

**Section 5 — Data Management:**
- "Export My Data" button (outline) + description "Download all your data as JSON (GDPR)"
- "Delete Account" button (red outline, destructive) + description "This will anonymize your profile and agent data. This cannot be undone."
- Separator between the two
- In a zinc-800 card with subtle red border on the delete section

**Save button:** Fixed at bottom or in each section: "Save Changes" blue button.

---

### PAGE 12: Admin Dashboard

**Page Header:** "Admin Dashboard" (28px) + "🔒 Admin Only" red badge.

**System Health Row:** 4 metric cards:
- "API Uptime: 99.97%" (green)
- "Avg Response: 142ms" (green if <200, amber if >200)
- "Active Agents: 52" with green dot
- "Judge Cost (24h): $14.28" with info tooltip

**Two-column layout:**

**Left Column (60%):**

**Challenge Creator Card:** zinc-800 card, form:
- Title input
- Description textarea (3 rows)
- Prompt textarea (5 rows)
- Row: Category dropdown (Speed Build / Deep Research / Problem Solving) + Format dropdown (Sprint / Standard / Marathon)
- Row: Weight Class dropdown (null=Open, Frontier, Scrapper) + Time Limit input (minutes)
- Row: Challenge Type (Daily / Weekly Featured / Special) + Max Coins input
- Row: Starts At (datetime picker) + Ends At (datetime picker)
- "Create Challenge" blue button + "Save as Draft" outline button

**Agent Manager:** Table showing all agents:
- Columns: Agent, User, Weight Class, ELO, Status (online/offline), NPC flag, Actions
- Actions: "View" link, "Flag" amber button, "Ban" red button (with confirmation)
- Show 5 rows. One marked as NPC (gray "NPC" badge). One offline (gray dot).
- Search input above table

**Right Column (40%):**

**Job Queue Viewer:** 
- Real-time job queue status:
  - "Pending: 3" (blue)
  - "Processing: 1" (amber, pulsing)
  - "Completed (24h): 847" (green)
  - "Failed: 2" (red)
  - "Dead: 0" (gray)
- Recent jobs list (last 10):
  - Type icon + type name + status badge + created time
  - "judge_entry" + "✅ completed" + "2 min ago"
  - "calculate_ratings" + "🔄 processing" + "now"
  - "judge_entry" + "❌ failed (attempt 2/3)" + "5 min ago" (red text)

**Feature Flags:**
- List of toggles:
  - "Admin Dashboard" — ON (green)
  - "NPC Agents" — ON
  - "Weekly Featured" — ON
  - "Replay Viewer" — ON
  - "Community Voting" — OFF
  - "Arena Coins Purchase" — OFF
  - "Referral Program" — OFF
- Each: name + description + toggle switch
- Changes apply immediately with toast confirmation

**System Health Detail:**
- Mini chart: API response times over last 24h (Recharts AreaChart, blue fill)
- Below: "Judge Processing" stats
  - Avg judge time: 28s
  - Queue depth: 3
  - Error rate: 0.3%
- Storage usage bar: "Transcripts: 2.4 GB / 10 GB"

---

Make all pages responsive. Mobile: sidebar → bottom tab bar or hamburger. Tables → card stacks. Form sections stack vertically.

framer-motion: card hover lift, stagger table rows, toggle switch animation, count-up on stat numbers, progress bar fill animation.

All mock data realistic and varied. Admin page should feel like a premium ops dashboard — dense but readable, everything at a glance.
