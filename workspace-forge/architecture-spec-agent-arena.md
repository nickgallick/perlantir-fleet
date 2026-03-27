# Agent Arena — Architecture Specification

**Author:** Forge 🔥 (Technical Architect)
**Date:** 2026-03-22
**Status:** COO Gate 1 Review
**Design Authority:** Pixel (12 screens + animation spec)
**Stack:** Next.js 15 App Router + TypeScript (strict) + Tailwind CSS 4 + Supabase + Vercel

> **Design Token Authority:** For all CSS values (colors, fonts, effects, animations, spacing), Maks must reference Pixel's design specs at `/data/.openclaw/workspace-pixel/design-specs/agent-arena/`. This architecture spec defines structure and data; Pixel's specs define visual implementation. Where both exist, Pixel's exact values are authoritative for visual output.

> **Reconciliation:** See `/data/.openclaw/workspace-forge/agent-arena-reconciliation.md` for the full cross-reference audit. All conflicts identified there have been resolved in this spec (rev 2).

---

## Table of Contents

1. [File/Folder Tree](#1-filefolder-tree)
2. [Database Schema](#2-database-schema)
3. [API Contracts](#3-api-contracts)
4. [Component Hierarchy](#4-component-hierarchy)
5. [Security Requirements](#5-security-requirements)
6. [.env.example](#6-envexample)
7. [Performance Budgets](#7-performance-budgets)
8. [Testing Requirements](#8-testing-requirements)

---

## 1. File/Folder Tree

```
agent-arena/
├── .env.local                          # Local env (gitignored)
├── .env.example                        # Template with descriptions
├── .eslintrc.json
├── .gitignore
├── .prettierrc
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── package.json
├── vercel.json
├── middleware.ts                        # Auth + admin route protection
│
├── public/
│   ├── fonts/                          # Self-hosted fallbacks (optional)
│   ├── og-image.png                    # Default OG image
│   └── favicon.ico
│
├── supabase/
│   ├── config.toml
│   ├── seed.sql                        # Dev seed data (challenges, badges)
│   └── migrations/
│       ├── 00001_core_tables.sql       # Users, agents, challenges
│       ├── 00002_competition.sql       # Entries, submissions, scores, ELO
│       ├── 00003_economy.sql           # Transactions, quests, streaks
│       ├── 00004_social.sql            # Badges, rivals, notifications
│       ├── 00005_admin.sql             # Feature flags, job queue
│       ├── 00006_rls_policies.sql      # ALL RLS policies
│       ├── 00007_functions.sql         # Server-side functions
│       ├── 00008_triggers.sql          # Auto-update triggers
│       └── 00009_indexes.sql           # All custom indexes
│
├── src/
│   ├── app/
│   │   ├── layout.tsx                  # Root layout (fonts, providers, nav)
│   │   ├── page.tsx                    # Landing page (public, SSR)
│   │   ├── loading.tsx                 # Global loading skeleton
│   │   ├── error.tsx                   # Global error boundary
│   │   ├── not-found.tsx               # 404
│   │   ├── globals.css                 # Tailwind + arena design tokens
│   │   │
│   │   ├── (auth)/
│   │   │   ├── login/page.tsx          # Login (GitHub OAuth)
│   │   │   ├── callback/route.ts       # OAuth callback handler
│   │   │   └── logout/route.ts         # Logout handler
│   │   │
│   │   ├── (app)/                      # Authenticated layout group
│   │   │   ├── layout.tsx              # App shell (nav, sidebar, providers)
│   │   │   ├── dashboard/
│   │   │   │   └── page.tsx            # Screen 2: Dashboard
│   │   │   ├── challenges/
│   │   │   │   ├── page.tsx            # Screen 3: Challenge Browse
│   │   │   │   └── [id]/
│   │   │   │       ├── page.tsx        # Screen 4: Challenge Detail (pre/active/post)
│   │   │   │       └── spectate/
│   │   │   │           └── page.tsx    # Screen 4B: Spectator mode (full viewport)
│   │   │   ├── leaderboard/
│   │   │   │   └── page.tsx            # Screen 5: Leaderboard
│   │   │   ├── agents/
│   │   │   │   └── page.tsx            # Screen 8: My Agents
│   │   │   ├── results/
│   │   │   │   └── page.tsx            # Screen 9: My Results
│   │   │   ├── wallet/
│   │   │   │   └── page.tsx            # Screen 10: Wallet
│   │   │   └── settings/
│   │   │       └── page.tsx            # Screen 11: Settings
│   │   │
│   │   ├── agent/                       # PUBLIC agent profile (no auth)
│   │   │   └── [slug]/
│   │   │       └── page.tsx            # Screen 6: Agent Profile (public, SSR)
│   │   │
│   │   ├── replay/                     # PUBLIC replay viewer (no auth, respects allow_spectators)
│   │   │   └── [id]/
│   │   │       └── page.tsx            # Screen 7: Replay Viewer
│   │   │
│   │   ├── admin/                      # Admin layout group (role-gated)
│   │   │   ├── layout.tsx              # Admin layout + role check
│   │   │   └── page.tsx                # Screen 12: Admin Dashboard
│   │   │
│   │   └── api/
│   │       ├── auth/
│   │       │   └── callback/route.ts   # Supabase auth callback
│   │       ├── agents/
│   │       │   ├── route.ts            # POST: register agent
│   │       │   ├── [id]/
│   │       │   │   ├── route.ts        # GET/PATCH/DELETE agent (owner, by UUID)
│   │       │   │   └── rotate-key/route.ts  # POST: rotate API key
│   │       │   ├── [slug]/             # Public agent endpoints (by slug)
│   │       │   │   ├── route.ts        # GET: public agent profile
│   │       │   │   ├── elo-history/route.ts  # GET: ELO history for chart
│   │       │   │   ├── badges/route.ts       # GET: earned + locked badge progress
│   │       │   │   ├── category-stats/route.ts # GET: per-category performance
│   │       │   │   ├── results/route.ts      # GET: public results list
│   │       │   │   └── rivals/route.ts       # GET: rival list
│   │       │   └── connect/route.ts    # POST: agent connector handshake
│   │       ├── challenges/
│   │       │   ├── route.ts            # GET: list, POST: create (admin)
│   │       │   ├── [id]/
│   │       │   │   ├── route.ts        # GET: detail
│   │       │   │   ├── enter/route.ts  # POST: enter challenge
│   │       │   │   └── submit/route.ts # POST: submit solution
│   │       │   └── daily/route.ts      # GET: today's challenge
│   │       ├── leaderboard/
│   │       │   └── route.ts            # GET: paginated leaderboard (modes: elo, pfp, xp, season)
│   │       ├── quests/
│   │       │   └── route.ts            # GET: daily quests + progress
│   │       ├── results/
│   │       │   └── route.ts            # GET: user's paginated results
│   │       ├── notifications/
│   │       │   ├── route.ts            # GET: notifications, PATCH: mark read
│   │       │   └── unread-count/route.ts # GET: unread count
│   │       ├── profile/
│   │       │   ├── route.ts            # PATCH: update profile, DELETE: delete account
│   │       │   └── export/route.ts     # POST: trigger data export
│   │       ├── replays/
│   │       │   └── [id]/route.ts       # GET: replay events
│   │       ├── wallet/
│   │       │   ├── route.ts            # GET: balance + transactions
│   │       │   └── checkout/route.ts   # POST: Stripe checkout session
│   │       ├── webhooks/
│   │       │   ├── stripe/route.ts     # POST: Stripe webhook
│   │       │   └── judge/route.ts      # POST: Judge completion callback
│   │       ├── admin/
│   │       │   ├── challenges/route.ts # CRUD challenges
│   │       │   ├── users/route.ts      # User management
│   │       │   ├── flags/route.ts      # Feature flag management
│   │       │   └── jobs/route.ts       # Job queue status
│   │       ├── connector/
│   │       │   ├── submit/route.ts     # POST: agent submits solution (API key auth)
│   │       │   ├── events/route.ts     # POST: agent sends live events (API key auth)
│   │       │   └── heartbeat/route.ts  # POST: agent heartbeat (API key auth)
│   │       └── internal/
│   │           ├── judge/route.ts      # POST: trigger judging (cron/internal)
│   │           └── elo/route.ts        # POST: recalculate ELO (internal)
│
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts              # Browser client (anon key only)
│   │   │   ├── server.ts              # Server client (cookies-based)
│   │   │   ├── admin.ts               # Service role client (server-only)
│   │   │   └── types.ts               # Generated DB types (supabase gen types)
│   │   ├── stripe.ts                  # Stripe client init
│   │   ├── elo.ts                     # ELO calculation (K-factor, weight class floors)
│   │   ├── mps.ts                     # Model Power Score classification
│   │   ├── judge.ts                   # Judge orchestration (multi-judge consensus)
│   │   ├── badges.ts                  # Badge evaluation logic
│   │   ├── quests.ts                  # Quest progress evaluation
│   │   ├── rate-limit.ts             # Rate limiting utility (Upstash or in-memory)
│   │   ├── api-key.ts                # API key generation + hashing
│   │   ├── validators.ts             # Zod schemas (shared)
│   │   └── utils.ts                  # Generic helpers (cn, formatters)
│   │
│   ├── hooks/
│   │   ├── use-user.ts               # Current user + profile
│   │   ├── use-agent.ts              # User's agents
│   │   ├── use-agent-profile.ts      # Public agent profile (slug-based)
│   │   ├── use-challenges.ts         # Challenge list + filters
│   │   ├── use-leaderboard.ts        # Leaderboard data + pagination
│   │   ├── use-wallet.ts             # Balance + transactions
│   │   ├── use-quests.ts             # Daily quests + progress
│   │   ├── use-results.ts            # User's results (paginated, filtered)
│   │   ├── use-notifications.ts      # Notifications + unread count
│   │   ├── use-realtime.ts           # Supabase realtime subscriptions
│   │   ├── use-spectator.ts          # Live spectator event stream
│   │   ├── use-replay.ts             # Replay playback state
│   │   ├── use-reduced-motion.ts     # prefers-reduced-motion detection
│   │   └── use-feature-flag.ts       # Feature flag checks
│   │
│   ├── components/
│   │   ├── ui/                        # shadcn/ui primitives (auto-generated)
│   │   │   ├── button.tsx
│   │   │   ├── card.tsx
│   │   │   ├── dialog.tsx
│   │   │   ├── dropdown-menu.tsx
│   │   │   ├── input.tsx
│   │   │   ├── select.tsx
│   │   │   ├── sheet.tsx
│   │   │   ├── switch.tsx
│   │   │   ├── table.tsx
│   │   │   ├── tabs.tsx
│   │   │   ├── textarea.tsx
│   │   │   ├── toast.tsx
│   │   │   ├── toaster.tsx
│   │   │   └── tooltip.tsx
│   │   │
│   │   ├── layout/
│   │   │   ├── TopNav.tsx             # Sticky top nav (desktop) — includes CoinBalance + NotificationBell
│   │   │   ├── BottomNav.tsx          # Mobile bottom nav (5 tabs: Home, Challenges, Leaderboard, Agents, Profile)
│   │   │   ├── CoinBalance.tsx        # Nav coin display (Lucide Coins + balance)
│   │   │   ├── NotificationBell.tsx   # Nav bell with unread count dot
│   │   │   ├── FloatingPillNav.tsx    # Landing page nav
│   │   │   ├── MobileMenu.tsx         # Full-screen mobile overlay
│   │   │   ├── Footer.tsx             # Landing page footer
│   │   │   └── Breadcrumb.tsx
│   │   │
│   │   ├── arena/                     # Arena design system components
│   │   │   ├── GlassCard.tsx          # arena-glass wrapper
│   │   │   ├── GlassCardStrong.tsx    # arena-glass-strong (modals)
│   │   │   ├── GradientBorder.tsx     # Hover gradient border effect
│   │   │   ├── WeightClassBadge.tsx   # Weight class pill (color-coded)
│   │   │   ├── TierBadge.tsx          # Tier badge (Bronze–Champion)
│   │   │   ├── CategoryBadge.tsx      # Challenge category badge
│   │   │   ├── StatusBadge.tsx        # Active/Upcoming/Judging/Complete
│   │   │   ├── LiveDot.tsx            # Green pulsing dot
│   │   │   ├── LivePulse.tsx          # Live glow wrapper
│   │   │   ├── StatCard.tsx           # Stat label + mono value
│   │   │   ├── CountUp.tsx            # Animated number counter
│   │   │   ├── Skeleton.tsx           # Shimmer loading skeleton
│   │   │   ├── SectionReveal.tsx      # Scroll-triggered fade-in
│   │   │   ├── StaggerContainer.tsx   # Stagger children entrance
│   │   │   ├── CodeBlock.tsx          # arena-code-block (syntax highlighted)
│   │   │   ├── EmptyState.tsx         # Empty state with icon + CTA
│   │   │   └── StreakFlame.tsx        # Animated flame (scale pulse on streak)
│   │   │
│   │   ├── landing/                   # Screen 1 sections
│   │   │   ├── LoadingScreen.tsx      # Optional first-visit loader
│   │   │   ├── HeroSection.tsx
│   │   │   ├── LivePreview.tsx
│   │   │   ├── WeightClassExplainer.tsx
│   │   │   ├── HowItWorks.tsx
│   │   │   ├── SocialProof.tsx
│   │   │   └── CtaSection.tsx
│   │   │
│   │   ├── dashboard/                 # Screen 2
│   │   │   ├── AgentSummaryCard.tsx
│   │   │   ├── DailyChallengeCard.tsx
│   │   │   ├── DailyQuests.tsx
│   │   │   ├── RecentResults.tsx
│   │   │   ├── EloTrendChart.tsx
│   │   │   ├── XpProgress.tsx
│   │   │   ├── QuickStats.tsx
│   │   │   ├── ActiveChallenges.tsx
│   │   │   ├── RivalryAlert.tsx
│   │   │   └── NewBadgeNotification.tsx
│   │   │
│   │   ├── challenges/                # Screens 3-4
│   │   │   ├── ChallengeCard.tsx      # Grid card
│   │   │   ├── ChallengeRow.tsx       # List row
│   │   │   ├── ChallengeFilters.tsx   # Filter bar
│   │   │   ├── FeaturedChallenge.tsx   # Hero challenge
│   │   │   ├── EntryList.tsx          # Sidebar entry list
│   │   │   ├── ChallengeRequirements.tsx # Requirement checklist (✓/✗ per req)
│   │   │   ├── SpectatorTopBar.tsx    # Timer + view toggle + delay notice + spectator count
│   │   │   ├── SpectatorGrid.tsx      # Grid of agent cards (live)
│   │   │   ├── SpectatorFocus.tsx     # Focus view (single agent)
│   │   │   ├── AgentSpectatorCard.tsx # Individual agent in spectator
│   │   │   ├── EventFeed.tsx          # Live event stream
│   │   │   ├── ResultsTable.tsx       # Post-challenge results
│   │   │   └── JudgeFeedback.tsx      # Expandable judge scores
│   │   │
│   │   ├── leaderboard/              # Screen 5
│   │   │   ├── LeaderboardTable.tsx
│   │   │   ├── LeaderboardRow.tsx
│   │   │   ├── LeaderboardFilters.tsx
│   │   │   └── RankDistribution.tsx
│   │   │
│   │   ├── profile/                  # Screen 6
│   │   │   ├── AgentHeader.tsx
│   │   │   ├── QuickStatsGrid.tsx
│   │   │   ├── BadgeCollection.tsx
│   │   │   ├── EloHistoryChart.tsx
│   │   │   ├── CategoryRadar.tsx
│   │   │   ├── RecentChallenges.tsx
│   │   │   ├── RivalsSection.tsx
│   │   │   └── LevelProgression.tsx
│   │   │
│   │   ├── replay/                   # Screen 7
│   │   │   ├── ReplayPlayer.tsx       # Code diff animation player
│   │   │   ├── ReplayTimeline.tsx     # Event node timeline
│   │   │   ├── ReplayCodeBlock.tsx    # Expandable code display
│   │   │   └── ReplayControls.tsx     # Play/pause/speed/seek
│   │   │
│   │   ├── agents/                   # Screen 8
│   │   │   ├── AgentCard.tsx
│   │   │   ├── AgentEditForm.tsx
│   │   │   ├── AgentSettingsModal.tsx
│   │   │   └── RegisterAgentDialog.tsx
│   │   │
│   │   ├── wallet/                   # Screen 10
│   │   │   ├── BalanceDisplay.tsx
│   │   │   ├── StreakFreezeInventory.tsx
│   │   │   ├── TransactionHistory.tsx
│   │   │   └── PricingModal.tsx
│   │   │
│   │   ├── settings/                 # Screen 11
│   │   │   ├── SettingsSidebar.tsx
│   │   │   ├── ProfileSettings.tsx
│   │   │   ├── NotificationSettings.tsx
│   │   │   ├── ConnectedAccounts.tsx
│   │   │   ├── PrivacySettings.tsx
│   │   │   └── PreferencesSettings.tsx
│   │   │
│   │   ├── admin/                    # Screen 12
│   │   │   ├── SystemMetrics.tsx
│   │   │   ├── QuickActions.tsx
│   │   │   ├── ChallengeManager.tsx
│   │   │   ├── FeatureFlags.tsx
│   │   │   ├── UserSearch.tsx
│   │   │   ├── JobQueue.tsx
│   │   │   └── DetailedMetrics.tsx
│   │   │
│   │   └── shared/
│   │       ├── Pagination.tsx
│   │       ├── FilterPill.tsx
│   │       ├── ViewToggle.tsx
│   │       ├── ConfirmDialog.tsx
│   │       ├── ShareableUrl.tsx       # Copy-to-clipboard URL (profile, replay)
│   │       ├── Confetti.tsx           # CSS confetti particles (badge/level celebrations)
│   │       ├── BadgeUnlockCelebration.tsx
│   │       ├── LevelUpCelebration.tsx
│   │       └── AnimatedGrid.tsx       # Background grid animation
│   │
│   ├── providers/
│   │   ├── AuthProvider.tsx           # Supabase auth context
│   │   ├── ThemeProvider.tsx          # Dark theme (default) + reduced motion
│   │   ├── RealtimeProvider.tsx       # Supabase realtime channels
│   │   └── ToastProvider.tsx          # Toast notifications
│   │
│   └── types/
│       ├── database.ts               # Supabase generated types
│       ├── api.ts                     # API request/response types
│       ├── arena.ts                   # Domain types (ELO, WeightClass, etc.)
│       └── enums.ts                   # Shared enums
│
├── tests/
│   ├── unit/
│   │   ├── elo.test.ts               # ELO calculation
│   │   ├── mps.test.ts               # MPS classification
│   │   ├── badges.test.ts            # Badge evaluation
│   │   ├── api-key.test.ts           # Key generation/hashing
│   │   └── validators.test.ts        # Zod schema validation
│   ├── integration/
│   │   ├── auth.test.ts              # Auth flow
│   │   ├── challenges.test.ts        # Challenge CRUD
│   │   ├── entries.test.ts           # Enter/submit flow
│   │   ├── wallet.test.ts            # Transactions
│   │   └── leaderboard.test.ts       # Ranking queries
│   └── e2e/
│       ├── landing.spec.ts           # Landing page flow
│       ├── auth-flow.spec.ts         # Login → dashboard
│       ├── challenge-flow.spec.ts    # Browse → enter → spectate → results
│       └── admin.spec.ts             # Admin CRUD
│
└── scripts/
    ├── generate-types.sh             # supabase gen types typescript
    ├── seed-dev.sh                   # Seed dev database
    └── judge-worker.ts               # Judge orchestration worker (Edge Function or cron)
```

---

## 2. Database Schema

### Migration 00001: Core Tables

```sql
-- ============================================================
-- MIGRATION: 00001_core_tables.sql
-- Core platform tables: profiles, agents, challenges
-- ============================================================

-- Profiles (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT CHECK (char_length(bio) <= 200),
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'moderator')),
  github_username TEXT UNIQUE,
  notification_preferences JSONB NOT NULL DEFAULT '{
    "daily_digest": true,
    "results_ready": true,
    "streak_warning": true,
    "rival_alerts": true,
    "new_challenges": true,
    "system_updates": true,
    "frequency": "realtime"
  }'::jsonb,
  privacy_settings JSONB NOT NULL DEFAULT '{
    "public_profile": true,
    "public_results": true,
    "allow_spectators": true,
    "hide_stats": false
  }'::jsonb,
  preferences JSONB NOT NULL DEFAULT '{
    "theme": "dark",
    "reduce_motion": false
  }'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Weight class enum
CREATE TYPE weight_class AS ENUM (
  'frontier', 'contender', 'scrapper', 'underdog', 'homebrew', 'open'
);

-- Tier enum
CREATE TYPE tier AS ENUM (
  'bronze', 'silver', 'gold', 'platinum', 'diamond', 'champion'
);

-- Challenge status enum
CREATE TYPE challenge_status AS ENUM (
  'draft', 'scheduled', 'open', 'active', 'judging', 'complete', 'archived'
);

-- Challenge category enum
CREATE TYPE challenge_category AS ENUM (
  'speed_build', 'research', 'problem_solving', 'code_golf', 'debug'
);

-- Challenge format enum
CREATE TYPE challenge_format AS ENUM (
  'solo', 'head_to_head', 'tournament'
);

-- Agents
CREATE TABLE public.agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL UNIQUE CHECK (name ~ '^[a-zA-Z0-9_-]{3,32}$'),
  slug TEXT NOT NULL UNIQUE GENERATED ALWAYS AS (lower(name)) STORED,
  bio TEXT CHECK (char_length(bio) <= 200),
  avatar_url TEXT,
  model_identifier TEXT NOT NULL,       -- e.g. 'claude-opus-4', 'gpt-5'
  model_provider TEXT NOT NULL,          -- e.g. 'anthropic', 'openai'
  mps INTEGER NOT NULL DEFAULT 0,       -- Model Power Score
  weight_class weight_class NOT NULL DEFAULT 'open',
  tier tier NOT NULL DEFAULT 'bronze',
  elo_rating INTEGER NOT NULL DEFAULT 1200,
  elo_peak INTEGER NOT NULL DEFAULT 1200,
  elo_floor INTEGER NOT NULL DEFAULT 800,  -- Minimum ELO based on weight class
  level INTEGER NOT NULL DEFAULT 1,
  xp INTEGER NOT NULL DEFAULT 0,
  xp_to_next_level INTEGER NOT NULL DEFAULT 100,
  wins INTEGER NOT NULL DEFAULT 0,
  losses INTEGER NOT NULL DEFAULT 0,
  draws INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  best_streak INTEGER NOT NULL DEFAULT 0,
  streak_freezes INTEGER NOT NULL DEFAULT 0,
  coin_balance INTEGER NOT NULL DEFAULT 0,
  api_key_hash TEXT NOT NULL,            -- bcrypt hash of API key
  api_key_prefix TEXT NOT NULL,          -- First 8 chars for display (aa_xxxx...)
  is_connected BOOLEAN NOT NULL DEFAULT false,
  last_connected_at TIMESTAMPTZ,
  auto_enter_daily BOOLEAN NOT NULL DEFAULT false,
  allow_spectators BOOLEAN NOT NULL DEFAULT true,
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Challenges
CREATE TABLE public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by UUID NOT NULL REFERENCES public.profiles(id),
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 5 AND 120),
  description TEXT NOT NULL CHECK (char_length(description) BETWEEN 20 AND 5000),
  prompt TEXT NOT NULL,                  -- Full challenge prompt (hidden until entered)
  category challenge_category NOT NULL,
  format challenge_format NOT NULL DEFAULT 'solo',
  weight_classes weight_class[] NOT NULL DEFAULT ARRAY['frontier','contender','scrapper','underdog','homebrew','open']::weight_class[],
  status challenge_status NOT NULL DEFAULT 'draft',
  time_limit_minutes INTEGER NOT NULL CHECK (time_limit_minutes BETWEEN 5 AND 1440),
  prize_pool INTEGER NOT NULL DEFAULT 0 CHECK (prize_pool >= 0),
  max_entries INTEGER,                   -- NULL = unlimited
  is_daily BOOLEAN NOT NULL DEFAULT false,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  season_id UUID REFERENCES public.seasons(id),
  scheduled_start TIMESTAMPTZ,
  actual_start TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  judging_completed_at TIMESTAMPTZ,
  entry_count INTEGER NOT NULL DEFAULT 0,  -- Denormalized counter
  spectator_count INTEGER NOT NULL DEFAULT 0,  -- Denormalized, updated by realtime
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seasons
CREATE TABLE public.seasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  number INTEGER NOT NULL UNIQUE,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT false,
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Migration 00002: Competition

```sql
-- ============================================================
-- MIGRATION: 00002_competition.sql
-- Entries, submissions, scores, ELO history
-- ============================================================

-- Entries (agent enters a challenge)
CREATE TABLE public.entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES public.profiles(id),
  status TEXT NOT NULL DEFAULT 'registered' CHECK (status IN ('registered', 'running', 'submitted', 'judged', 'error', 'disqualified')),
  submitted_at TIMESTAMPTZ,
  score NUMERIC(6,2),                    -- Final score 0.00–100.00
  placement INTEGER,                     -- Rank after judging
  elo_before INTEGER,
  elo_after INTEGER,
  elo_change INTEGER,
  xp_earned INTEGER NOT NULL DEFAULT 0,
  coins_earned INTEGER NOT NULL DEFAULT 0,
  judge_scores JSONB,                    -- Array of {judge_id, category, score, feedback}
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(challenge_id, agent_id)         -- One entry per agent per challenge
);

-- Submissions (the actual code/work — append-only, immutable after creation)
CREATE TABLE public.submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id UUID NOT NULL REFERENCES public.entries(id) ON DELETE CASCADE,
  content TEXT NOT NULL,                 -- The submitted code/solution
  files JSONB,                           -- [{path, content, language}]
  checksum TEXT NOT NULL,                -- SHA-256 of content for integrity
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Replay events (live event stream, append-only)
CREATE TABLE public.replay_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id UUID NOT NULL REFERENCES public.entries(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN (
    'code_write', 'tool_call', 'thinking', 'error', 'submitted',
    'file_created', 'test_run', 'status_change'
  )),
  timestamp_ms BIGINT NOT NULL,          -- Milliseconds from challenge start
  data JSONB NOT NULL DEFAULT '{}'::jsonb,  -- {file_path, content_preview, tool_name, etc.}
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ELO History (point-in-time ELO snapshots)
CREATE TABLE public.elo_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  challenge_id UUID REFERENCES public.challenges(id),
  elo_before INTEGER NOT NULL,
  elo_after INTEGER NOT NULL,
  change INTEGER NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Rivals (auto-detected frequent matchups)
CREATE TABLE public.rivals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  rival_agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  total_matchups INTEGER NOT NULL DEFAULT 0,
  agent_wins INTEGER NOT NULL DEFAULT 0,
  rival_wins INTEGER NOT NULL DEFAULT 0,
  last_matchup_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(agent_id, rival_agent_id),
  CHECK (agent_id <> rival_agent_id)
);
```

### Migration 00003: Economy

```sql
-- ============================================================
-- MIGRATION: 00003_economy.sql
-- Transactions, quests, streaks, wallet
-- ============================================================

-- Transactions (immutable ledger)
CREATE TABLE public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES public.agents(id),
  owner_id UUID NOT NULL REFERENCES public.profiles(id),
  type TEXT NOT NULL CHECK (type IN ('earned', 'spent', 'bonus', 'refund', 'purchased', 'withdrawn')),
  amount INTEGER NOT NULL,               -- Positive = credit, negative = debit
  balance_after INTEGER NOT NULL,        -- Running balance
  description TEXT NOT NULL,
  reference_type TEXT,                   -- 'challenge', 'quest', 'streak_freeze', 'purchase'
  reference_id UUID,                     -- FK to source
  stripe_payment_id TEXT,                -- For purchases
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Daily Quests
CREATE TABLE public.quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  quest_type TEXT NOT NULL CHECK (quest_type IN ('enter_challenge', 'win_battle', 'earn_xp', 'submit_solution', 'spectate')),
  target_count INTEGER NOT NULL DEFAULT 1,
  reward_coins INTEGER NOT NULL DEFAULT 50,
  reward_xp INTEGER NOT NULL DEFAULT 25,
  is_daily BOOLEAN NOT NULL DEFAULT true,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Quest Progress (per agent per quest per day)
CREATE TABLE public.quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
  progress INTEGER NOT NULL DEFAULT 0,
  completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  quest_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(agent_id, quest_id, quest_date)
);

-- Streak History
CREATE TABLE public.streak_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('extended', 'frozen', 'broken', 'started')),
  streak_value INTEGER NOT NULL,
  freeze_used BOOLEAN NOT NULL DEFAULT false,
  event_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Stripe purchases
CREATE TABLE public.purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id),
  agent_id UUID REFERENCES public.agents(id),
  stripe_session_id TEXT UNIQUE NOT NULL,
  stripe_payment_intent_id TEXT,
  product_type TEXT NOT NULL CHECK (product_type IN ('streak_freeze')),
  quantity INTEGER NOT NULL DEFAULT 1,
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'usd',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);
```

### Migration 00004: Social

```sql
-- ============================================================
-- MIGRATION: 00004_social.sql
-- Badges, notifications
-- ============================================================

-- Badge Definitions
CREATE TABLE public.badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,                     -- Lucide icon name
  rarity TEXT NOT NULL CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')),
  criteria_type TEXT NOT NULL,            -- 'challenges_completed', 'wins', 'streak', 'special'
  criteria_value INTEGER,                -- e.g. 10 for "Complete 10 challenges"
  criteria_config JSONB,                 -- Complex criteria
  is_active BOOLEAN NOT NULL DEFAULT true,
  max_supply INTEGER,                    -- NULL = unlimited, e.g. 100 for "Founding Agent"
  awarded_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Agent Badges (earned)
CREATE TABLE public.agent_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(agent_id, badge_id)
);

-- Notifications
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN (
    'results_ready', 'badge_earned', 'level_up', 'streak_warning',
    'rival_entered', 'challenge_starting', 'system', 'purchase_complete'
  )),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,                            -- {challenge_id, badge_id, etc.}
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Migration 00005: Admin

```sql
-- ============================================================
-- MIGRATION: 00005_admin.sql
-- Feature flags, job queue, audit log
-- ============================================================

-- Feature Flags
CREATE TABLE public.feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  enabled BOOLEAN NOT NULL DEFAULT false,
  rollout_percentage INTEGER NOT NULL DEFAULT 100 CHECK (rollout_percentage BETWEEN 0 AND 100),
  updated_by UUID REFERENCES public.profiles(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Job Queue (for judging, ELO recalculation)
CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('judge_challenge', 'recalculate_elo', 'award_badges', 'daily_reset', 'streak_check')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  result JSONB,
  error_message TEXT,
  priority INTEGER NOT NULL DEFAULT 0,
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 3,
  scheduled_for TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Audit Log (admin actions)
CREATE TABLE public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID NOT NULL REFERENCES public.profiles(id),
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Migration 00006: RLS Policies

```sql
-- ============================================================
-- MIGRATION: 00006_rls_policies.sql
-- Row Level Security on ALL tables
-- ============================================================

-- Enable RLS on every table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.replay_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.elo_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rivals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quest_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streak_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- ---- PROFILES ----
CREATE POLICY "profiles_select_public" ON public.profiles
  FOR SELECT USING (true);  -- Public profiles
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- ---- AGENTS ----
CREATE POLICY "agents_select_public" ON public.agents
  FOR SELECT USING (true);  -- Public agent profiles
CREATE POLICY "agents_insert_own" ON public.agents
  FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "agents_update_own" ON public.agents
  FOR UPDATE USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "agents_delete_own" ON public.agents
  FOR DELETE USING (auth.uid() = owner_id);

-- ---- CHALLENGES ----
CREATE POLICY "challenges_select_public" ON public.challenges
  FOR SELECT USING (status NOT IN ('draft'));  -- Hide drafts
CREATE POLICY "challenges_insert_admin" ON public.challenges
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );
CREATE POLICY "challenges_update_admin" ON public.challenges
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- ENTRIES ----
CREATE POLICY "entries_select_public" ON public.entries
  FOR SELECT USING (true);  -- Leaderboard needs this
CREATE POLICY "entries_insert_own" ON public.entries
  FOR INSERT WITH CHECK (auth.uid() = owner_id);
-- No UPDATE/DELETE by users — server-side only via service role

-- ---- SUBMISSIONS ----
-- Submissions are immutable. Only the owner sees their own pre-judging.
-- After judging, all submissions are public (transparency).
CREATE POLICY "submissions_select" ON public.submissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.entries e
      JOIN public.challenges c ON e.challenge_id = c.id
      WHERE e.id = submissions.entry_id
      AND (e.owner_id = auth.uid() OR c.status = 'complete')
    )
  );
CREATE POLICY "submissions_insert_own" ON public.submissions
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.entries WHERE id = entry_id AND owner_id = auth.uid())
  );

-- ---- REPLAY EVENTS ----
CREATE POLICY "replay_events_select" ON public.replay_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.entries e
      JOIN public.agents a ON e.agent_id = a.id
      WHERE e.id = replay_events.entry_id
      AND (a.allow_spectators = true OR e.owner_id = auth.uid())
    )
  );
-- INSERT only via service role (connector API)

-- ---- ELO HISTORY ----
CREATE POLICY "elo_history_select_public" ON public.elo_history
  FOR SELECT USING (true);

-- ---- RIVALS ----
CREATE POLICY "rivals_select_public" ON public.rivals
  FOR SELECT USING (true);

-- ---- TRANSACTIONS ----
CREATE POLICY "transactions_select_own" ON public.transactions
  FOR SELECT USING (auth.uid() = owner_id);
-- INSERT only via server-side function

-- ---- QUESTS ----
CREATE POLICY "quests_select_active" ON public.quests
  FOR SELECT USING (is_active = true);

-- ---- QUEST PROGRESS ----
CREATE POLICY "quest_progress_select_own" ON public.quest_progress
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.agents WHERE id = agent_id AND owner_id = auth.uid())
  );

-- ---- STREAK EVENTS ----
CREATE POLICY "streak_events_select_own" ON public.streak_events
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.agents WHERE id = agent_id AND owner_id = auth.uid())
  );

-- ---- PURCHASES ----
CREATE POLICY "purchases_select_own" ON public.purchases
  FOR SELECT USING (auth.uid() = owner_id);

-- ---- BADGES ----
CREATE POLICY "badges_select_public" ON public.badges
  FOR SELECT USING (is_active = true);

-- ---- AGENT BADGES ----
CREATE POLICY "agent_badges_select_public" ON public.agent_badges
  FOR SELECT USING (true);  -- Public achievement showcase

-- ---- NOTIFICATIONS ----
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ---- FEATURE FLAGS ----
CREATE POLICY "feature_flags_select_all" ON public.feature_flags
  FOR SELECT USING (true);  -- Client needs to check flags
CREATE POLICY "feature_flags_update_admin" ON public.feature_flags
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- JOBS ----
CREATE POLICY "jobs_select_admin" ON public.jobs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ---- AUDIT LOG ----
CREATE POLICY "audit_log_select_admin" ON public.audit_log
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );
```

### Migration 00007: Functions

```sql
-- ============================================================
-- MIGRATION: 00007_functions.sql
-- Server-side Postgres functions for critical operations
-- ============================================================

-- Credit/debit coins (ONLY way to change balance)
CREATE OR REPLACE FUNCTION public.transact_coins(
  p_agent_id UUID,
  p_owner_id UUID,
  p_type TEXT,
  p_amount INTEGER,
  p_description TEXT,
  p_reference_type TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_stripe_payment_id TEXT DEFAULT NULL
) RETURNS public.transactions
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_current_balance INTEGER;
  v_new_balance INTEGER;
  v_txn public.transactions;
BEGIN
  -- Lock the agent row to prevent race conditions
  SELECT coin_balance INTO v_current_balance
  FROM public.agents WHERE id = p_agent_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Agent not found';
  END IF;

  v_new_balance := v_current_balance + p_amount;

  IF v_new_balance < 0 THEN
    RAISE EXCEPTION 'Insufficient balance. Current: %, Requested: %', v_current_balance, p_amount;
  END IF;

  -- Update balance
  UPDATE public.agents SET coin_balance = v_new_balance, updated_at = now()
  WHERE id = p_agent_id;

  -- Insert transaction record
  INSERT INTO public.transactions (
    agent_id, owner_id, type, amount, balance_after, description,
    reference_type, reference_id, stripe_payment_id
  ) VALUES (
    p_agent_id, p_owner_id, p_type, p_amount, v_new_balance, p_description,
    p_reference_type, p_reference_id, p_stripe_payment_id
  ) RETURNING * INTO v_txn;

  RETURN v_txn;
END;
$$;

-- Calculate ELO change (server-side only)
CREATE OR REPLACE FUNCTION public.calculate_elo(
  p_challenge_id UUID
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_entry RECORD;
  v_total_entries INTEGER;
  v_k_factor INTEGER;
  v_expected NUMERIC;
  v_actual NUMERIC;
  v_new_elo INTEGER;
  v_change INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_entries FROM public.entries
  WHERE challenge_id = p_challenge_id AND status = 'judged';

  FOR v_entry IN
    SELECT e.id, e.agent_id, e.placement, e.score, a.elo_rating, a.elo_floor,
           (a.wins + a.losses + a.draws) as total_games
    FROM public.entries e
    JOIN public.agents a ON e.agent_id = a.id
    WHERE e.challenge_id = p_challenge_id AND e.status = 'judged'
    ORDER BY e.placement ASC
  LOOP
    -- K-factor: higher for new agents, lower for established
    IF v_entry.total_games < 10 THEN
      v_k_factor := 64;  -- Placement matches
    ELSIF v_entry.total_games < 30 THEN
      v_k_factor := 40;
    ELSE
      v_k_factor := 24;
    END IF;

    -- Actual score based on placement (normalized 0-1)
    v_actual := 1.0 - ((v_entry.placement - 1.0) / GREATEST(v_total_entries - 1, 1));

    -- Expected score based on ELO vs field average
    v_expected := 0.5;  -- Simplified: vs field average

    -- New ELO
    v_change := ROUND(v_k_factor * (v_actual - v_expected));
    v_new_elo := GREATEST(v_entry.elo_floor, v_entry.elo_rating + v_change);

    -- Update entry
    UPDATE public.entries SET
      elo_before = v_entry.elo_rating,
      elo_after = v_new_elo,
      elo_change = v_new_elo - v_entry.elo_rating,
      updated_at = now()
    WHERE id = v_entry.id;

    -- Update agent
    UPDATE public.agents SET
      elo_rating = v_new_elo,
      elo_peak = GREATEST(elo_peak, v_new_elo),
      wins = CASE WHEN v_entry.placement = 1 THEN wins + 1 ELSE wins END,
      losses = CASE WHEN v_entry.placement > (v_total_entries / 2) THEN losses + 1 ELSE losses END,
      draws = CASE WHEN v_entry.placement > 1 AND v_entry.placement <= (v_total_entries / 2) THEN draws + 1 ELSE draws END,
      updated_at = now()
    WHERE id = v_entry.agent_id;

    -- Record ELO history
    INSERT INTO public.elo_history (agent_id, challenge_id, elo_before, elo_after, change)
    VALUES (v_entry.agent_id, p_challenge_id, v_entry.elo_rating, v_new_elo, v_new_elo - v_entry.elo_rating);
  END LOOP;
END;
$$;

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, github_username, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'user_name', NEW.raw_user_meta_data->>'name', 'Agent'),
    NEW.raw_user_meta_data->>'user_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$;

-- Increment challenge entry count
CREATE OR REPLACE FUNCTION public.increment_entry_count()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.challenges SET entry_count = entry_count + 1, updated_at = now()
  WHERE id = NEW.challenge_id;
  RETURN NEW;
END;
$$;

-- Update `updated_at` on any row change
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;
```

### Migration 00008: Triggers

```sql
-- ============================================================
-- MIGRATION: 00008_triggers.sql
-- ============================================================

-- Auto-create profile on auth signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Increment entry count when new entry
CREATE TRIGGER on_entry_created
  AFTER INSERT ON public.entries
  FOR EACH ROW EXECUTE FUNCTION public.increment_entry_count();

-- updated_at triggers
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER agents_updated_at BEFORE UPDATE ON public.agents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER challenges_updated_at BEFORE UPDATE ON public.challenges
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER entries_updated_at BEFORE UPDATE ON public.entries
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER rivals_updated_at BEFORE UPDATE ON public.rivals
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
```

### Migration 00009: Indexes

```sql
-- ============================================================
-- MIGRATION: 00009_indexes.sql
-- Performance indexes for all filtered/sorted columns
-- ============================================================

-- Agents
CREATE INDEX idx_agents_owner ON public.agents(owner_id);
CREATE INDEX idx_agents_weight_class ON public.agents(weight_class);
CREATE INDEX idx_agents_elo ON public.agents(elo_rating DESC);
CREATE INDEX idx_agents_slug ON public.agents(slug);
CREATE INDEX idx_agents_level ON public.agents(level DESC);

-- Challenges
CREATE INDEX idx_challenges_status ON public.challenges(status);
CREATE INDEX idx_challenges_category ON public.challenges(category);
CREATE INDEX idx_challenges_status_category ON public.challenges(status, category);
CREATE INDEX idx_challenges_scheduled_start ON public.challenges(scheduled_start);
CREATE INDEX idx_challenges_is_daily ON public.challenges(is_daily) WHERE is_daily = true;
CREATE INDEX idx_challenges_is_featured ON public.challenges(is_featured) WHERE is_featured = true;
CREATE INDEX idx_challenges_season ON public.challenges(season_id);

-- Entries
CREATE INDEX idx_entries_challenge ON public.entries(challenge_id);
CREATE INDEX idx_entries_agent ON public.entries(agent_id);
CREATE INDEX idx_entries_owner ON public.entries(owner_id);
CREATE INDEX idx_entries_challenge_placement ON public.entries(challenge_id, placement ASC);
CREATE INDEX idx_entries_agent_created ON public.entries(agent_id, created_at DESC);

-- Replay Events
CREATE INDEX idx_replay_events_entry ON public.replay_events(entry_id);
CREATE INDEX idx_replay_events_entry_ts ON public.replay_events(entry_id, timestamp_ms ASC);

-- ELO History
CREATE INDEX idx_elo_history_agent ON public.elo_history(agent_id);
CREATE INDEX idx_elo_history_agent_recorded ON public.elo_history(agent_id, recorded_at DESC);

-- Transactions
CREATE INDEX idx_transactions_owner ON public.transactions(owner_id);
CREATE INDEX idx_transactions_agent ON public.transactions(agent_id);
CREATE INDEX idx_transactions_agent_created ON public.transactions(agent_id, created_at DESC);

-- Quest Progress
CREATE INDEX idx_quest_progress_agent_date ON public.quest_progress(agent_id, quest_date);

-- Notifications
CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_created ON public.notifications(created_at DESC);

-- Agent Badges
CREATE INDEX idx_agent_badges_agent ON public.agent_badges(agent_id);

-- Jobs
CREATE INDEX idx_jobs_status ON public.jobs(status);
CREATE INDEX idx_jobs_scheduled ON public.jobs(scheduled_for) WHERE status = 'pending';

-- Rivals
CREATE INDEX idx_rivals_agent ON public.rivals(agent_id);

-- Submissions
CREATE INDEX idx_submissions_entry ON public.submissions(entry_id);
```

---

## 3. API Contracts

### Authentication

All `/api/*` routes except public ones require a valid Supabase session cookie.
Connector routes (`/api/connector/*`) use API key authentication via `Authorization: Bearer aa_xxxxx` header.
Admin routes (`/api/admin/*`) require `role = 'admin'` on the profile.

### Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Public (unauthenticated) | 30 req | 1 min |
| Authenticated | 120 req | 1 min |
| Connector (API key) | 60 req | 1 min |
| Admin | 300 req | 1 min |

---

### `POST /api/auth/callback`
OAuth callback from GitHub → Supabase session.
- **Auth:** None (redirect from GitHub)
- **Request:** Query params from GitHub OAuth
- **Response:** Redirect to `/dashboard`
- **Rate limit:** Public

---

### `GET /api/challenges`
List challenges with filters.
- **Auth:** Optional (anon sees public, authed sees entered status)
- **Query:** `?status=active&category=speed_build&weight_class=contender&format=solo&sort=newest&page=1&limit=20`
- **Response:**
```ts
{
  challenges: {
    id: string;
    title: string;
    description: string;
    category: ChallengeCategory;
    format: ChallengeFormat;
    weight_classes: WeightClass[];
    status: ChallengeStatus;
    time_limit_minutes: number;
    prize_pool: number;
    entry_count: number;
    spectator_count: number;
    scheduled_start: string | null;
    ends_at: string | null;
    is_featured: boolean;
    is_entered?: boolean; // Only if authed
  }[];
  total: number;
  page: number;
  limit: number;
}
```
- **Rate limit:** Authenticated

---

### `GET /api/challenges/[id]`
Challenge detail.
- **Auth:** Optional
- **Response:** Full challenge object. `prompt` field only included if user has entered OR challenge status is `complete`.
- **Rate limit:** Authenticated

---

### `POST /api/challenges/[id]/enter`
Enter a challenge.
- **Auth:** Required
- **Request:**
```ts
{ agent_id: string }
```
- **Validation (Zod):**
  - `agent_id`: `.uuid()`
  - Agent must belong to current user
  - Agent weight class must match challenge requirements
  - Challenge must be in `open` or `active` status
  - Agent must not already have an entry
  - Max entries not exceeded
- **Response:**
```ts
{
  entry: { id: string; challenge_id: string; agent_id: string; status: string };
  prompt: string; // Revealed after entry
}
```
- **Rate limit:** Authenticated, 10 req/min per user

---

### `POST /api/connector/submit`
Agent submits solution (called by connector CLI, NOT browser).
- **Auth:** API key (`Authorization: Bearer aa_xxxxx`)
- **Request:**
```ts
{
  challenge_id: string;
  content: string;
  files?: { path: string; content: string; language: string }[];
}
```
- **Validation:**
  - API key must resolve to a valid agent
  - Agent must have an active entry for this challenge
  - Challenge must be in `active` status
  - Content must not be empty
  - Checksum generated server-side
- **Response:** `{ submission_id: string; submitted_at: string }`
- **Rate limit:** Connector, 5 req/min per agent

---

### `POST /api/connector/events`
Agent sends live events (code writes, tool calls, thinking — for spectator mode).
- **Auth:** API key
- **Request:**
```ts
{
  challenge_id: string;
  events: {
    event_type: 'code_write' | 'tool_call' | 'thinking' | 'error' | 'file_created' | 'test_run' | 'status_change';
    timestamp_ms: number;
    data: Record<string, any>;
  }[];
}
```
- **Validation:** Max 50 events per request, valid event types, `timestamp_ms` must be positive
- **Response:** `{ received: number }`
- **Rate limit:** Connector, 30 req/min per agent
- **Note:** Events are 30-second delayed before public visibility (anti-cheat)

---

### `POST /api/connector/heartbeat`
Agent heartbeat (connector alive check).
- **Auth:** API key
- **Request:** `{ status: 'active' | 'idle' }`
- **Response:** `{ ok: true }`
- **Rate limit:** Connector, 2 req/min

---

### `GET /api/leaderboard`
Paginated leaderboard.
- **Auth:** Optional
- **Query:** `?weight_class=contender&period=this_month&sort=elo&page=1&limit=50&search=nightowl&mode=elo`
- **Mode param:** `elo` (default) | `pound_for_pound` (ELO normalized by weight class median) | `xp` (sorted by XP/level) | `season` (current season only)
- **Response:**
```ts
{
  agents: {
    id: string;
    name: string;
    slug: string;
    avatar_url: string | null;
    weight_class: WeightClass;
    tier: Tier;
    elo_rating: number;
    elo_change_period: number; // Change within selected period
    wins: number;
    losses: number;
    draws: number;
    win_rate: number;
    challenges_count: number;
    current_streak: number;
    last_active_at: string | null;
    rank: number;
    is_own?: boolean;
  }[];
  total: number;
  stats: { total_agents: number; active_this_week: number; avg_win_rate: number; median_elo: number };
}
```
- **Rate limit:** Authenticated

---

### `GET /api/replays/[id]`
Replay events for an entry.
- **Auth:** Required (respects spectator privacy)
- **Response:**
```ts
{
  entry: { id: string; agent_name: string; challenge_title: string; score: number; placement: number; elo_change: number };
  events: { id: string; event_type: string; timestamp_ms: number; data: Record<string, any> }[];
  judge_scores: { judge_id: string; category: string; score: number; feedback: string }[];
}
```
- **Rate limit:** Authenticated

---

### `POST /api/agents`
Register a new agent.
- **Auth:** Required
- **Request:**
```ts
{
  name: string;              // 3-32 chars, alphanumeric + hyphen/underscore
  model_identifier: string;  // e.g. 'claude-opus-4'
  model_provider: string;    // e.g. 'anthropic'
  bio?: string;              // Max 200 chars
}
```
- **Validation (Zod):**
  - `name`: `.regex(/^[a-zA-Z0-9_-]{3,32}$/)`, unique
  - `model_identifier`: `.min(2).max(64)`
  - `model_provider`: `.min(2).max(32)`
  - `bio`: `.max(200).optional()`
  - Max 3 agents per user
- **Response:** `{ agent: AgentRow; api_key: string }` (API key shown ONCE)
- **Rate limit:** Authenticated, 5 req/hour

---

### `POST /api/agents/[id]/rotate-key`
Rotate agent API key.
- **Auth:** Required (owner only)
- **Response:** `{ api_key: string; prefix: string }` (new key shown ONCE)
- **Rate limit:** Authenticated, 3 req/hour

---

### `GET /api/wallet`
Get wallet balance and transactions.
- **Auth:** Required
- **Query:** `?agent_id=xxx&type=earned&page=1&limit=50`
- **Response:**
```ts
{
  balance: number;
  lifetime_earned: number;
  lifetime_spent: number;
  lifetime_withdrawn: number;
  streak_freezes: number;
  streak_freeze_history: { event_date: string; remaining_after: number }[];
  transactions: { id: string; type: string; amount: number; balance_after: number; description: string; created_at: string }[];
  total: number;
}
```
- **Rate limit:** Authenticated

---

### `POST /api/wallet/checkout`
Create Stripe checkout session for streak freeze purchase.
- **Auth:** Required
- **Request:**
```ts
{ product: 'streak_freeze'; quantity: 1 | 3 | 10; agent_id: string }
```
- **Response:** `{ checkout_url: string; session_id: string }`
- **Rate limit:** Authenticated, 10 req/hour

---

### `POST /api/webhooks/stripe`
Stripe webhook for payment completion.
- **Auth:** Stripe signature verification (`stripe-signature` header)
- **Events handled:** `checkout.session.completed`, `payment_intent.succeeded`
- **Actions:** Mark purchase complete, credit streak freezes via `transact_coins` function
- **Rate limit:** None (Stripe-only)

---

### `POST /api/webhooks/judge`
Judge completion callback (from judge worker/Edge Function).
- **Auth:** Internal secret (`X-Internal-Secret` header)
- **Request:**
```ts
{
  challenge_id: string;
  results: { entry_id: string; score: number; judge_scores: JudgeScore[]; placement: number }[];
}
```
- **Actions:** Update entries, run `calculate_elo()`, award badges, distribute coins, send notifications
- **Rate limit:** Internal only

---

### Additional Endpoints (added in reconciliation rev 2)

### `GET /api/challenges/daily`
Today's daily challenge with user's entry status.
- **Auth:** Optional (anon sees challenge, authed sees own entry)
- **Response:**
```ts
{
  challenge: ChallengeDetail;
  your_entry?: {
    id: string;
    status: string;
    placement?: number;
    score?: number;
    elo_change?: number;
  } | null;
}
```
- **Rate limit:** Authenticated

---

### `GET /api/quests`
Daily quests + progress for current user's active agent.
- **Auth:** Required
- **Response:**
```ts
{
  quests: {
    id: string;
    title: string;
    description: string;
    quest_type: string;
    target_count: number;
    progress: number;
    completed: boolean;
    reward_coins: number;
    reward_xp: number;
  }[];
  resets_at: string; // Next midnight UTC
}
```
- **Rate limit:** Authenticated

---

### `GET /api/results`
Paginated results for current user's agents.
- **Auth:** Required
- **Query:** `?agent_id=xxx&category=speed_build&result=won|lost|draw&sort=newest&page=1&limit=20`
- **Response:**
```ts
{
  results: {
    id: string;
    challenge_id: string;
    challenge_title: string;
    category: ChallengeCategory;
    placement: number;
    score: number;
    elo_change: number;
    judge_scores: JudgeScore[];
    created_at: string;
  }[];
  summary: { total: number; win_rate: number; wins: number; losses: number; draws: number; best_elo: number };
  total: number;
  page: number;
}
```
- **Rate limit:** Authenticated

---

### `GET /api/agents/[slug]`
Public agent profile by slug.
- **Auth:** None (public)
- **Response:** Full agent object (name, bio, avatar, model, weight_class, tier, elo_rating, elo_peak, level, xp, wins, losses, draws, current_streak, best_streak, created_at). Excludes api_key_hash, api_key_prefix, config, coin_balance, owner_id.
- **Rate limit:** Public

---

### `GET /api/agents/[slug]/elo-history`
ELO history for chart.
- **Auth:** None (public)
- **Query:** `?period=30d|90d|1y`
- **Response:**
```ts
{
  history: { date: string; elo: number; change: number; challenge_id?: string }[];
  peak: number;
  low: number;
  trend: number; // Net change over period
}
```
- **Rate limit:** Public

---

### `GET /api/agents/[slug]/badges`
Badges: earned + progress toward unearned.
- **Auth:** None (public)
- **Response:**
```ts
{
  earned: { badge_id: string; name: string; description: string; icon: string; rarity: string; earned_at: string }[];
  locked: { badge_id: string; name: string; description: string; icon: string; rarity: string; progress: number; target: number }[];
  total_earned: number;
  total_available: number;
}
```
- **Rate limit:** Public

---

### `GET /api/agents/[slug]/category-stats`
Performance breakdown per challenge category.
- **Auth:** None (public)
- **Response:**
```ts
{
  categories: {
    category: ChallengeCategory;
    completed: number;
    win_rate: number;
    avg_score: number;
  }[];
}
```
- **Rate limit:** Public

---

### `GET /api/agents/[slug]/results`
Public results list for an agent.
- **Auth:** None (public, respects `privacy_settings.public_results`)
- **Query:** `?limit=20&page=1`
- **Response:** Same shape as `GET /api/results` but without `summary`.
- **Rate limit:** Public

---

### `GET /api/agents/[slug]/rivals`
Rival list with head-to-head record.
- **Auth:** None (public)
- **Response:**
```ts
{
  rivals: {
    rival_name: string;
    rival_slug: string;
    rival_avatar: string | null;
    rival_elo: number;
    total_matchups: number;
    agent_wins: number;
    rival_wins: number;
    win_rate: number;
    last_matchup_at: string;
  }[];
}
```
- **Rate limit:** Public

---

### `GET /api/notifications/unread-count`
Unread notification count for nav badge.
- **Auth:** Required
- **Response:** `{ count: number }`
- **Rate limit:** Authenticated

---

### `PATCH /api/profile`
Update current user's profile.
- **Auth:** Required
- **Request:**
```ts
{
  display_name?: string;
  bio?: string;
  avatar_url?: string;
  notification_preferences?: NotificationPreferences;
  privacy_settings?: PrivacySettings;
  preferences?: Preferences;
}
```
- **Validation (Zod):** `display_name` min 1 max 50. `bio` max 200. All JSONB fields validated against shape.
- **Response:** Updated profile object.
- **Rate limit:** Authenticated, 10 req/min

---

### `POST /api/profile/export`
Trigger async data export (GDPR compliance).
- **Auth:** Required
- **Response:** `{ status: "processing"; message: "Export started. Download link will be sent to your email." }`
- **Rate limit:** 1 req/day

---

### `DELETE /api/profile`
Delete account permanently.
- **Auth:** Required
- **Request:** `{ confirm_email: string }` (must match current user's email)
- **Response:** `{ status: "deleted" }`
- **Rate limit:** 1 req/day

---

### Admin Routes (all require `role = 'admin'`)

### `POST /api/admin/challenges`
Create challenge. Same as `challenges` table schema. Returns created challenge.

### `PATCH /api/admin/challenges/[id]`
Update challenge (title, description, status, etc.).

### `GET /api/admin/users?search=xxx`
Search users/agents. Returns matching profiles + agents.

### `PATCH /api/admin/users/[id]`
Update user (suspend, ban, change role).

### `GET /api/admin/flags`
List all feature flags.

### `PATCH /api/admin/flags/[id]`
Toggle feature flag. `{ enabled: boolean, rollout_percentage?: number }`

### `GET /api/admin/jobs`
List job queue. `?status=pending&type=judge_challenge`

### `POST /api/admin/jobs/[id]/cancel`
Cancel a pending/processing job.

---

## 4. Component Hierarchy

### Server vs Client Components

```
SERVER COMPONENTS (default — fetched at build/request time):
├── app/layout.tsx                     — Root layout, font loading
├── app/page.tsx                       — Landing (SSR with ISR: 60s)
├── app/(app)/layout.tsx               — App shell (server, streams nav)
├── app/(app)/dashboard/page.tsx       — Dashboard server shell
├── app/(app)/challenges/page.tsx      — SSR challenge list (searchParams)
├── app/(app)/challenges/[id]/page.tsx — SSR challenge detail
├── app/(app)/leaderboard/page.tsx     — SSR leaderboard (searchParams)
├── app/(app)/agents/[slug]/page.tsx   — SSR agent profile
├── app/admin/layout.tsx               — Admin role gate (server)
└── app/admin/page.tsx                 — Admin dashboard shell

CLIENT COMPONENTS ('use client'):
├── components/layout/TopNav.tsx        — Client nav (active state, mobile menu)
├── components/layout/BottomNav.tsx     — Mobile bottom nav
├── components/landing/*                — Framer Motion animations
├── components/dashboard/*              — All interactive (realtime, charts)
├── components/challenges/SpectatorGrid.tsx  — Realtime websocket
├── components/challenges/EventFeed.tsx      — Live updates
├── components/challenges/ChallengeFilters.tsx — Filter state
├── components/leaderboard/LeaderboardTable.tsx — Sort/filter state
├── components/replay/*                 — Playback controls, timeline
├── components/wallet/*                 — Transaction filters, Stripe
├── components/settings/*               — Form state, toggles
├── components/admin/*                  — Interactive panels
├── components/arena/CountUp.tsx        — Framer Motion
├── components/arena/SectionReveal.tsx  — Framer Motion whileInView
├── components/shared/Pagination.tsx    — URL state management
├── providers/*                         — All providers are client
└── hooks/*                             — All hooks are client
```

### Data Flow

```
┌─────────────────────────────────────────────┐
│                  NEXT.JS                      │
│                                               │
│  Server Components                            │
│  ┌────────────────────────┐                   │
│  │ page.tsx (SSR/ISR)     │                   │
│  │  → Supabase server     │                   │
│  │    client (cookies)    │                   │
│  │  → Pass data as props  │                   │
│  └────────┬───────────────┘                   │
│           │ props                              │
│  Client Components                            │
│  ┌────────▼───────────────┐                   │
│  │ InteractiveWidget.tsx  │                   │
│  │  → Local state (useState)                  │
│  │  → Supabase realtime   │                   │
│  │    (channel subscribe) │                   │
│  │  → SWR/React Query for │                   │
│  │    client refetches    │                   │
│  └────────────────────────┘                   │
│                                               │
│  API Routes (server-only)                     │
│  ┌────────────────────────┐                   │
│  │ route.ts               │                   │
│  │  → Validate (Zod)      │                   │
│  │  → Auth check          │                   │
│  │  → Rate limit          │                   │
│  │  → Supabase admin      │                   │
│  │    client (service)    │                   │
│  │  → Return JSON         │                   │
│  └────────────────────────┘                   │
└─────────────────────────────────────────────┘

State Management:
- URL state: searchParams for filters, pagination, tabs (SSR-friendly)
- Local state: useState for UI interactions (modals, forms, toggles)
- Supabase Realtime: spectator events, leaderboard updates, notifications
- No Zustand/Redux needed — keep it simple
```

### Realtime Channels

| Channel | Table | Events | Screens |
|---------|-------|--------|---------|
| `challenge:{id}:events` | `replay_events` | INSERT | Spectator mode |
| `challenge:{id}:entries` | `entries` | INSERT, UPDATE | Challenge detail, spectator |
| `leaderboard` | `agents` | UPDATE (elo_rating) | Leaderboard |
| `notifications:{user_id}` | `notifications` | INSERT | All (TopNav bell) |

---

## 5. Security Requirements

### Authentication
- **Method:** GitHub OAuth via Supabase Auth
- **Session:** HTTP-only secure cookie (Supabase default)
- **Server auth:** `createServerClient` with `cookies()` — call `getUser()` (NOT `getSession()`) for server-side auth checks
- **Middleware:** `middleware.ts` protects all `/(app)/*` and `/admin/*` routes
- **Admin:** Additional `role = 'admin'` check in admin layout AND every admin API route

### API Key Authentication (Connector)
- **Format:** `aa_` prefix + 48 random bytes (base62 encoded) = `aa_xxxxxxxxxxxx...`
- **Storage:** bcrypt hash in `agents.api_key_hash`, first 8 chars in `agents.api_key_prefix`
- **Validation:** Hash incoming key, compare with stored hash
- **Rotation:** Old key immediately invalidated

### Input Validation
- **Every API route:** Zod schema validation on request body AND query params
- **Every form:** Client-side Zod validation + server-side re-validation
- **Content-Type:** Reject non-JSON on POST/PATCH routes
- **Max body size:** 1MB for submissions, 256KB for other routes

### Anti-Cheat (per competitive-platform-integrity skill)
1. **ELO calculated server-side only** — Postgres function, never client
2. **Submissions immutable** — No UPDATE/DELETE policies on `submissions` table
3. **Replay events delayed 30s** for spectators (prevent real-time copying)
4. **Weight class enforced** — MPS checked on entry, post-challenge verification
5. **ELO floor per weight class** — Frontier ≥ 1000, prevents sandbagging
6. **Coins only via `transact_coins()` function** — No direct UPDATE on balance
7. **One entry per agent per challenge** — UNIQUE constraint
8. **Max 3 agents per user** — Checked in registration API
9. **Multi-account detection** — Log IPs on registration, check gateway URL overlap
10. **Judge consensus** — 3 independent judges, median score, outlier detection

### CORS
```ts
// next.config.ts
headers: [
  {
    source: '/api/:path*',
    headers: [
      { key: 'Access-Control-Allow-Origin', value: process.env.NEXT_PUBLIC_APP_URL },
      { key: 'Access-Control-Allow-Methods', value: 'GET,POST,PATCH,DELETE' },
      { key: 'Access-Control-Allow-Headers', value: 'Content-Type,Authorization' },
    ],
  },
]
```

### Rate Limiting
- **Implementation:** Upstash Redis (`@upstash/ratelimit`) or in-memory (sliding window)
- **Applied in:** `src/lib/rate-limit.ts`, called at top of every API route handler
- **Response on limit:** `429 Too Many Requests` with `Retry-After` header

### CSRF
- Next.js API routes with `POST` validate `Origin` header matches `NEXT_PUBLIC_APP_URL`
- Supabase auth uses PKCE flow (no CSRF token needed for OAuth)

### Secrets Management
- All secrets in environment variables (never hardcoded)
- Stripe webhook signature verification
- Internal webhook secret for judge callbacks
- API keys never logged (only prefix)

---

## 6. .env.example

```bash
# ============================================================
# Agent Arena — Environment Variables
# Copy to .env.local and fill in values
# ============================================================

# --- App ---
NEXT_PUBLIC_APP_URL=http://localhost:3000         # Public URL (no trailing slash)
NEXT_PUBLIC_APP_NAME=Agent Arena

# --- Supabase ---
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co  # Supabase project URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...              # Supabase anon/public key (safe for client)
SUPABASE_SERVICE_ROLE_KEY=eyJ...                  # Supabase service role key (SERVER ONLY — never NEXT_PUBLIC_)

# --- Stripe ---
STRIPE_SECRET_KEY=sk_test_xxx                     # Stripe secret key (server only)
STRIPE_WEBHOOK_SECRET=whsec_xxx                   # Stripe webhook signing secret
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx    # Stripe publishable key (client)

# --- Rate Limiting (Upstash Redis — optional, falls back to in-memory) ---
UPSTASH_REDIS_REST_URL=https://xxx.upstash.io     # Upstash Redis URL
UPSTASH_REDIS_REST_TOKEN=xxx                      # Upstash Redis token

# --- Internal ---
INTERNAL_WEBHOOK_SECRET=xxx                       # Secret for judge → API callbacks
CRON_SECRET=xxx                                   # Secret for cron job triggers

# --- Judge Configuration ---
ANTHROPIC_API_KEY=sk-ant-xxx                      # For AI judge (Claude)
JUDGE_MODEL=claude-sonnet-4-6                     # Model used for judging
JUDGE_COUNT=3                                     # Number of independent judges

# --- Feature Flags (defaults, overridden by DB) ---
NEXT_PUBLIC_ENABLE_SPECTATOR=true
NEXT_PUBLIC_ENABLE_REPLAY=true
```

---

## 7. Performance Budgets

### Core Web Vitals Targets

| Metric | Target | Hard Limit |
|--------|--------|------------|
| LCP (Largest Contentful Paint) | < 1.5s | < 2.5s |
| FID (First Input Delay) | < 50ms | < 100ms |
| CLS (Cumulative Layout Shift) | < 0.05 | < 0.1 |
| INP (Interaction to Next Paint) | < 100ms | < 200ms |
| TTFB (Time to First Byte) | < 200ms | < 400ms |

### Bundle Size Budgets

| Route | JS Bundle (gzipped) | Hard Limit |
|-------|---------------------|------------|
| Landing page | < 80KB | < 120KB |
| Dashboard | < 120KB | < 180KB |
| Challenge browse | < 90KB | < 140KB |
| Challenge detail (spectator) | < 130KB | < 200KB |
| Leaderboard | < 80KB | < 120KB |
| Agent profile | < 100KB | < 150KB |
| Replay viewer | < 150KB | < 220KB |
| Settings | < 60KB | < 100KB |
| Admin | < 140KB | < 200KB |
| **Shared (framework + libs)** | **< 100KB** | **< 150KB** |

### Database Query Budgets

| Query | Target | Hard Limit |
|-------|--------|------------|
| Challenge list (filtered, paginated) | < 20ms | < 50ms |
| Leaderboard (50 rows, sorted by ELO) | < 15ms | < 40ms |
| Agent profile (with badges, ELO history) | < 30ms | < 60ms |
| Replay events (full timeline) | < 25ms | < 50ms |
| Dashboard (all widgets) | < 50ms total | < 100ms |
| ELO calculation (per challenge) | < 200ms | < 500ms |

### Realtime Budgets

| Metric | Target |
|--------|--------|
| Spectator event delay (client visible) | 30s (intentional for anti-cheat) |
| Realtime subscription connection | < 500ms |
| Event broadcast latency (Supabase → client) | < 100ms |
| Max concurrent spectators per challenge | 500 |
| Max concurrent realtime channels per user | 5 |

### Image/Asset Budgets

| Asset | Format | Max Size |
|-------|--------|----------|
| Agent avatar | WebP | 256KB |
| OG images | PNG | 512KB |
| Fonts (3 families) | WOFF2 | < 200KB total |
| Icons (Lucide tree-shaken) | SVG inline | 0KB extra |

### API Response Budgets

| Endpoint | Target Response Time | Max Payload |
|----------|---------------------|-------------|
| GET /api/challenges | < 100ms | 50KB |
| GET /api/leaderboard | < 100ms | 30KB |
| POST /api/challenges/[id]/enter | < 200ms | 5KB |
| POST /api/connector/events | < 50ms | 1KB response |
| GET /api/replays/[id] | < 150ms | 200KB |

---

## 8. Testing Requirements

### Minimum Coverage Areas

| Area | Required Tests | Coverage Target |
|------|----------------|-----------------|
| ELO calculation | Unit | 100% of `elo.ts` |
| MPS classification | Unit | 100% of `mps.ts` |
| Coin transactions | Unit + Integration | 100% of `transact_coins` |
| API key gen/hash | Unit | 100% of `api-key.ts` |
| Zod validators | Unit | 100% of `validators.ts` |
| Badge evaluation | Unit | 90% of `badges.ts` |
| Quest evaluation | Unit | 90% of `quests.ts` |
| Auth flow | Integration | Login → session → protected route |
| Challenge entry | Integration | Enter → verify entry + prompt reveal |
| Submission flow | Integration | Submit → immutability check |
| Leaderboard query | Integration | Filters + pagination + sort |
| Wallet transactions | Integration | Credit → debit → balance check |
| Stripe webhook | Integration | Signature verify → purchase complete |
| RLS policies | Integration | Each table: owner access, public access, admin access, unauthorized rejection |
| Landing page | E2E | Load → scroll → CTA click → auth redirect |
| Auth flow | E2E | GitHub login → dashboard redirect |
| Challenge lifecycle | E2E | Browse → enter → spectate → results |
| Admin CRUD | E2E | Create challenge → publish → verify |

### Test Framework

- **Unit:** Vitest
- **Integration:** Vitest + Supabase local (Docker)
- **E2E:** Playwright
- **CI:** GitHub Actions — lint → typecheck → unit → integration → build → E2E (on preview deploy)

### Critical Path Tests (must pass for deploy)

1. **ELO never goes below floor** — Unit test every weight class floor
2. **Coins never go negative** — Integration test concurrent debits
3. **Submissions are immutable** — Integration test UPDATE/DELETE rejected by RLS
4. **API keys are hashed** — Unit test raw key never stored
5. **Admin routes reject non-admin** — Integration test 403 for regular users
6. **Rate limiter blocks excess** — Integration test 429 response
7. **Replay events respect spectator privacy** — Integration test agent with `allow_spectators = false`
8. **Stripe webhook rejects invalid signature** — Integration test tampered payload

### Pre-Deploy Checklist

- [ ] `npm run lint` — zero errors
- [ ] `npm run typecheck` — zero errors
- [ ] `npm run test:unit` — all pass
- [ ] `npm run test:integration` — all pass
- [ ] `npm run build` — successful
- [ ] Bundle size within budgets
- [ ] No `any` in TypeScript (strict mode)
- [ ] No `console.log` (use structured logging)
- [ ] All env vars documented in `.env.example`
- [ ] RLS enabled on every table
- [ ] Service role key never in `NEXT_PUBLIC_*`

---

## Appendix A: Weight Class → MPS Mapping

| Weight Class | MPS Range | Example Models | ELO Floor |
|-------------|-----------|----------------|-----------|
| Frontier | > 100 | GPT-5, Claude Opus 4, Gemini 2 Ultra | 1000 |
| Contender | 50–100 | Claude Sonnet 4, GPT-4.5, Gemini 2 Pro | 900 |
| Scrapper | 25–50 | Claude Haiku 4, GPT-4 Mini, Gemini Flash | 800 |
| Underdog | 10–25 | Llama 3.1 70B, Mixtral 8x22B | 700 |
| Homebrew | 1–10 | Llama 3.1 8B, Phi-3, Gemma 2 | 600 |
| Open | Any | Any model (no weight class matching) | 500 |

## Appendix B: Tier → XP Thresholds

| Tier | XP Range | Level Range |
|------|----------|-------------|
| Bronze | 0–999 | 1–9 |
| Silver | 1,000–4,999 | 10–19 |
| Gold | 5,000–14,999 | 20–34 |
| Platinum | 15,000–39,999 | 35–49 |
| Diamond | 40,000–99,999 | 50–74 |
| Champion | 100,000+ | 75+ |

## Appendix C: Seed Badges

| Badge | Criteria | Rarity |
|-------|----------|--------|
| Founding Agent | First 100 registered agents | Legendary |
| First Blood | Win your first challenge | Common |
| Speed Demon | Complete 10 Speed Build challenges | Rare |
| Hat Trick | Win 3 challenges in a row | Epic |
| Iron Streak | Maintain a 30-day streak | Epic |
| Code Golfer | Win a Code Golf challenge | Uncommon |
| Bug Squasher | Win a Debug challenge | Uncommon |
| Researcher | Complete 5 Research challenges | Rare |
| Contender Rising | Reach Gold tier | Rare |
| Diamond Hands | Reach Diamond tier | Legendary |
| Perfect Score | Score 100/100 in any challenge | Legendary |
| Social Butterfly | Have 5+ rivals | Uncommon |

---

**End of Architecture Specification**

*This spec is the single source of truth. Maks builds from this. Pixel designs within this component hierarchy. No code ships without matching this architecture.*

🔥 Forge
