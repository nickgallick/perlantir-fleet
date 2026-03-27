# Agent Arena — Phase 4 Design Delivery

## Status: V0 Prompts Ready for Generation

### What's Delivered

4 V0 prompt files, production-ready, designed to generate all 12 screens + the viral shareable card:

| File | Screens | Components |
|------|---------|------------|
| `v0-batch-1-prompts.md` | Landing, Dashboard, Challenges Browse, Challenge Detail | HeroSection, LiveStatsBar, WeightClassCards, HowItWorks, CurrentChallenge, WelcomeCard, DailyChallengeCard, EloTrendChart, QuickStats, RecentResults, ChallengeGrid, ChallengeFilters, ChallengeDetailHeader, ResultsTable, JudgeFeedback, EntryList, ShareButton |
| `v0-batch-2-prompts.md` | Leaderboard, Agent Profile, Replay Viewer, My Agents | LeaderboardTable, WeightClassTabs, TimeFilter, SearchAgents, ProfileHeader, StatsGrid, EloHistoryChart, CategoryRadar, BadgesCollection, ReplayTimeline, TimelineNode, SpeedControls, SubmissionPanel, JudgePanel, AgentCard (detailed), ConnectionStatus |
| `v0-batch-3-prompts.md` | My Results, Wallet, Settings, Admin Dashboard | ResultsHistoryTable, EloChangeBar, WalletBalance, TransactionHistory, WeeklyEarningsChart, ProfileForm, NotificationPreferences, ConnectedAccounts, AgentManagement, DataManagement, ChallengeCreator, JobQueueViewer, FeatureFlags, SystemHealth, AgentManager |
| `v0-shareable-card-prompt.md` | Shareable Result Card (viral priority) | ShareableResultCard (3 variants: champion, mid-pack, participation) |
| `design-system.md` | Design system reference | Color tokens, tier system, typography, component patterns, animation specs |

### Component Count: 50+ unique components across 12 screens

### Shared Components (reused across screens):
- `agent-card.tsx` — avatar + name + tier + weight class + ELO + record
- `challenge-card.tsx` — category + title + weight class + time + entries + status
- `tier-badge.tsx` — pill with tier color + icon
- `weight-class-badge.tsx` — colored pill with class name
- `elo-change.tsx` — +/- with color and animation
- `countdown-timer.tsx` — live countdown with pulse
- `stat-card.tsx` — number + label
- `empty-state.tsx` — illustrated empty state
- `share-button.tsx` — social share
- `status-indicator.tsx` — online/offline dot

### Design Decisions Made:
1. **Dashboard shell** with persistent left sidebar (collapses on mobile)
2. **Weight classes as visual identity** — gold for Frontier, green for Scrapper, prominent everywhere
3. **Tier system** with distinct colors and icons — recognizable at a glance
4. **Shareable result card** designed for OG image ratio (1200×630) — works on Twitter, Discord, Reddit
5. **Data density balanced with whitespace** — F1 timing screen feel without overwhelming
6. **Consistent card pattern** — zinc-800 bg, zinc-700 border, rounded-xl, everywhere
7. **Animation budget** — lift on hover, stagger on load, count-up on numbers, pulse on timers
8. **Mobile-first responsive** — sidebar → bottom nav, tables → cards, grids → single column

### V0 Execution Instructions:
1. Open v0.dev
2. Start new chat for each batch (3 batches + 1 bonus)
3. Paste the entire prompt block from each file
4. V0 will generate the pages — review and iterate
5. For each batch, copy the generated component code
6. The component hierarchy matches Forge's architecture spec exactly

### Key Alignment with Forge Architecture:
- All component names match `src/components/` file tree
- Page routes match `src/app/` folder structure
- Shared components match `src/components/shared/` directory
- Layout components match `src/components/layout/` directory
- Screen-specific components organized per Forge's component hierarchy

### What Pixel Cannot Do (needs Nick or Maks):
- V0 requires authenticated browser access — prompts need to be pasted manually
- Generated code needs to be adapted to the actual Supabase data fetching patterns
- Real Recharts data needs to replace mock data
- Framer Motion animations may need tuning for performance
- OG image generation (server-side) for shareable cards needs Edge Function implementation
