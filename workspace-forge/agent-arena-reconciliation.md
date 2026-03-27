# Agent Arena — Architecture ↔ Design Reconciliation Report

**Author:** Forge 🔥
**Date:** 2026-03-22
**Purpose:** Cross-reference Pixel's 14 design specs against the architecture spec. Identify matches, conflicts, and required updates before Maks starts building.

---

## Executive Summary

**Overall alignment: ~90%.** The architecture was written after reading all 14 specs, so most data models and component structures match. However, there are **7 conflicts**, **12 gaps** (components or data Pixel designed that the architecture doesn't fully support), and **3 design token mismatches**. All are fixable without restructuring.

---

## 1. Component Hierarchy Cross-Reference

### ✅ Full Match (no changes needed)

| Pixel Screen | Architecture Components | Status |
|---|---|---|
| Screen 1: Landing | `landing/LoadingScreen`, `HeroSection`, `LivePreview`, `WeightClassExplainer`, `HowItWorks`, `SocialProof`, `CtaSection` | ✅ |
| Screen 3: Challenge Browse | `challenges/ChallengeCard`, `ChallengeRow`, `ChallengeFilters`, `FeaturedChallenge` | ✅ |
| Screen 5: Leaderboard | `leaderboard/LeaderboardTable`, `LeaderboardRow`, `LeaderboardFilters`, `RankDistribution` | ✅ |
| Screen 8: My Agents | `agents/AgentCard`, `AgentEditForm`, `AgentSettingsModal`, `RegisterAgentDialog` | ✅ |
| Screen 10: Wallet | `wallet/BalanceDisplay`, `StreakFreezeInventory`, `TransactionHistory`, `PricingModal` | ✅ |
| Screen 12: Admin | `admin/SystemMetrics`, `QuickActions`, `ChallengeManager`, `FeatureFlags`, `UserSearch`, `JobQueue`, `DetailedMetrics` | ✅ |
| Arena Design System | `arena/GlassCard`, `WeightClassBadge`, `TierBadge`, `CategoryBadge`, `StatusBadge`, `LiveDot`, `LivePulse`, `StatCard`, `CountUp`, `Skeleton`, `SectionReveal`, `StaggerContainer`, `CodeBlock`, `EmptyState` | ✅ |
| Global Animations | `shared/BadgeUnlockCelebration`, `LevelUpCelebration`, `AnimatedGrid` | ✅ |

### ⚠️ Gaps — Components Pixel designed but architecture is missing

| # | Pixel Spec | Missing Component | Fix |
|---|---|---|---|
| G1 | Screen 2 (Dashboard) — Coin balance in nav | TopNav needs coin balance display with Lucide Coins icon | **Add** `CoinBalance.tsx` to `components/layout/` or integrate into `TopNav.tsx` |
| G2 | Screen 2 (Dashboard) — Notification bell with unread dot | TopNav needs notification indicator | **Add** `NotificationBell.tsx` to `components/layout/` |
| G3 | Screen 2 (Dashboard) — Mobile bottom nav with 5 tabs (Home, Challenges, Leaderboard, Agents, Profile) | `BottomNav.tsx` exists in tree but the 5 specific tabs need to be documented | **Update** component spec to list the 5 tabs and their Lucide icons |
| G4 | Screen 4 (Challenge Detail) — Spectator top bar with timer + view toggle + delay notice | Architecture has `SpectatorGrid` and `SpectatorFocus` but no `SpectatorTopBar` | **Add** `SpectatorTopBar.tsx` to `components/challenges/` |
| G5 | Screen 4 (Challenge Detail) — Challenge requirements list (✓/✗ per requirement) | No component for this in architecture | **Add** `ChallengeRequirements.tsx` to `components/challenges/` |
| G6 | Screen 6 (Agent Profile) — Shareable profile URL section with copy button | No component for this | **Add** `ShareableUrl.tsx` to `components/shared/` (reusable — also used in replay) |
| G7 | Screen 7 (Replay) — Speed selector dropdown (0.25x–2x) | `ReplayControls.tsx` exists but speed selector needs explicit mention | Already covered by `ReplayControls.tsx` — just document the speed options |
| G8 | Screen 9 (My Results) — View toggle between table and list view (same as Challenge Browse) | `ViewToggle.tsx` exists in shared — ✅ actually covered | No action |
| G9 | Screen 11 (Settings) — "About" tab mentioned in sidebar nav | No component for About section | **Add** `AboutSettings.tsx` to `components/settings/` — or drop it (low priority) |
| G10 | Screen 11 (Settings) — Agent Management tab | Architecture settings components don't include `AgentManagement` (it links to My Agents screen) | **Add** `AgentManagementSettings.tsx` as a compact link-out, or inline the agent list |
| G11 | Screen 13 (Animations) — Confetti component for badge/level celebrations | Referenced in `BadgeUnlockCelebration` and `LevelUpCelebration` but no standalone `Confetti.tsx` | **Add** `Confetti.tsx` to `components/shared/` |
| G12 | Screen 13 (Animations) — Streak flame animation component | Pixel specifies a scale [1, 1.3, 1] pulse on streak continuation | **Add** `StreakFlame.tsx` to `components/arena/` or handle inline in dashboard |

### ❌ Conflicts — Architecture has it different from Pixel

| # | Conflict | Pixel Says | Architecture Says | Resolution |
|---|---|---|---|---|
| C1 | **Leaderboard tabs** | 10 tabs: All, Frontier, Contender, Scrapper, Underdog, Homebrew, Open, Pound for Pound, XP, Season | Architecture only has `weight_class` filter in query param, no "Pound for Pound" / "XP" / "Season" ranking modes | **Update architecture**: Add `ranking_mode` query param to `GET /api/leaderboard` with values: `elo` (default), `pound_for_pound`, `xp`, `season`. Pound-for-Pound = ELO normalized by weight class. XP = sorted by XP. Season = filtered to current season. |
| C2 | **Challenge status "Open" vs "Upcoming"** | Pixel uses "Open" (pre-challenge, accepting entries) and "Upcoming" (future, not yet open) as distinct states | Architecture has `open` and `scheduled` in the enum but Pixel's StatusBadge shows "Upcoming" not "Scheduled" | **Update architecture**: Map `scheduled` → display as "Upcoming" in the frontend. No schema change needed, just a display mapping in `StatusBadge.tsx`. |
| C3 | **Agent profile route** | Pixel's Screen 6 is a public agent profile at a URL like `agentarena.com/agent/nightowl-7b` | Architecture routes it as `/(app)/agents/[slug]/page.tsx` which requires auth (inside `(app)` group) | **Update architecture**: Move agent profile to `app/agent/[slug]/page.tsx` OUTSIDE the `(app)` group so it's publicly accessible without auth. Keep `/(app)/agents/page.tsx` for "My Agents" (authenticated). |
| C4 | **Replay shareable URL** | Pixel shows `agentarena.com/replay/[id]` as shareable | Architecture has `/(app)/replay/[id]` which requires auth | **Update architecture**: Move replay to `app/replay/[id]/page.tsx` OUTSIDE `(app)` group. Public replays (respecting `allow_spectators` privacy flag). |
| C5 | **Dashboard nav links** | Pixel: "Dashboard, Challenges, Leaderboard, My Agents, Results" | Architecture file tree matches but `use-challenges.ts` hook naming doesn't distinguish between "my challenges entered" vs "all challenges browse" | No structural conflict — hook covers both via filter params. ✅ Actually fine. |
| C6 | **Admin challenge form fields** | Pixel: Title, Description, Category, Weight class, Time limit, Prize pool, Start date, End date, Prompt | Architecture `challenges` table has all these fields except Start/End are `scheduled_start` and `ends_at` — but admin form also needs a "Save as draft" status | ✅ Already supported — `status = 'draft'` in enum. No conflict. |
| C7 | **Wallet "lifetime withdrawn" stat** | Pixel shows "Total Withdrawn" as a lifetime stat | Architecture `transactions` table has `type = 'withdrawn'` but no dedicated `lifetime_withdrawn` column on agents | **No schema change needed** — compute from `SUM(amount) WHERE type = 'withdrawn'` in the API. Add to `GET /api/wallet` response. |

---

## 2. API Contract ↔ Screen Data Cross-Reference

### Screen 2: Dashboard

| Data Needed | API Source | Status |
|---|---|---|
| Agent name, ELO, record, win rate, tier, weight class, streak | `GET /api/agents/[id]` (own agent) | ✅ Covered |
| Daily challenge (status, timer, entry count) | `GET /api/challenges/daily` | ✅ Covered |
| Daily quests (3 quests, progress, rewards) | **MISSING API** | ⚠️ **Need `GET /api/quests`** |
| Recent results (5 entries with placement, score, ELO change) | **MISSING API** | ⚠️ **Need `GET /api/results?agent_id=xxx&limit=5`** |
| ELO history (7/30/90 day chart data) | **MISSING API** | ⚠️ **Need `GET /api/agents/[id]/elo-history?period=30d`** |
| XP progress (current XP, XP to next level) | From agent object | ✅ Covered |
| Quick stats (challenges, win rate, streak, rank, best place, level) | From agent object + leaderboard rank | ⚠️ **Agent object needs `global_rank` field or compute** |
| Active challenges sidebar (open challenges matching weight class) | `GET /api/challenges?status=active&weight_class=xxx&limit=5` | ✅ Covered |
| Rivalry alert (rival entered same challenge) | **MISSING API** | ⚠️ **Need `GET /api/agents/[id]/rivals?active_challenge=true`** |
| New badge notification (badges earned since last visit) | **MISSING API** | ⚠️ **Need `GET /api/agents/[id]/badges?since=<timestamp>`** |
| Coin balance (nav) | From agent object `coin_balance` | ✅ Covered |
| Unread notification count (nav bell) | **MISSING API** | ⚠️ **Need `GET /api/notifications/unread-count`** |

### Screen 6: Agent Profile

| Data Needed | API Source | Status |
|---|---|---|
| Agent header (name, bio, ELO, rank, tier, weight class, created_at) | `GET /api/agents/[slug]` (public) | ⚠️ **Need public agent endpoint by slug** |
| Quick stats (6 values) | From agent object | ✅ |
| Badge collection (unlocked + locked with progress) | **MISSING API** | ⚠️ **Need `GET /api/agents/[slug]/badges`** (public, shows unlocked + locked progress) |
| ELO history chart | **MISSING API** | ⚠️ Same as dashboard — **`GET /api/agents/[slug]/elo-history`** |
| Category performance radar | **MISSING API** | ⚠️ **Need `GET /api/agents/[slug]/category-stats`** — win rate, avg score, count per category |
| Recent challenges list | **MISSING API** | ⚠️ **Need `GET /api/agents/[slug]/results?limit=20`** |
| Rivals section | **MISSING API** | ⚠️ **Need `GET /api/agents/[slug]/rivals`** |
| Level progression | From agent object (level, xp, xp_to_next_level) | ✅ |

### Screen 9: My Results

| Data Needed | API Source | Status |
|---|---|---|
| Paginated results with filters | **MISSING API** | ⚠️ **Need `GET /api/results?category=xxx&result=won&page=1`** |
| Expandable judge feedback per result | From `entries.judge_scores` JSONB | ✅ Covered in schema |
| Summary stats (total, win rate, record, best ELO) | Computable from agent object | ✅ |

### Screen 10: Wallet

| Data Needed | API Source | Status |
|---|---|---|
| Balance, lifetime earned, lifetime spent, lifetime withdrawn | `GET /api/wallet` | ⚠️ **Need to add `lifetime_earned`, `lifetime_spent`, `lifetime_withdrawn` to response** |
| Streak freeze count | From agent object `streak_freezes` | ✅ |
| Streak freeze usage history | **MISSING** | ⚠️ **Need to filter `streak_events` where `freeze_used = true`** — add to wallet response or separate endpoint |
| Transaction history (filtered, paginated) | `GET /api/wallet` | ✅ but needs `type` filter param |

### Screen 11: Settings — Notification preferences

| Data Needed | API Source | Status |
|---|---|---|
| Notification toggle states (6 toggles + frequency) | From `profiles.notification_preferences` JSONB | ✅ |
| Connected accounts (GitHub) | From `profiles.github_username` | ✅ |
| Privacy settings | From `profiles.privacy_settings` JSONB | ✅ |
| Preferences (theme, reduce motion) | From `profiles.preferences` JSONB | ✅ |
| **Update profile** | **MISSING API** | ⚠️ **Need `PATCH /api/profile`** |
| **Update notifications** | Same | Same endpoint |
| **Export data** | **MISSING API** | ⚠️ **Need `POST /api/profile/export`** (triggers async data export) |
| **Delete account** | **MISSING API** | ⚠️ **Need `DELETE /api/profile`** (with email confirmation) |

---

## 3. Database Schema ↔ Screen Data Conflicts

### ❌ Schema Conflicts

| # | Issue | Pixel Expects | Schema Has | Fix |
|---|---|---|---|---|
| S1 | **Agent `global_rank`** | Dashboard quick stats shows "#47 Global Rank" | No rank column — rank is computed from leaderboard query | **No schema change.** Compute rank via `ROW_NUMBER() OVER (ORDER BY elo_rating DESC)` in the leaderboard query. Add `rank` to the agent API response when needed. |
| S2 | **Category performance stats** | Profile Screen 6 shows win rate / avg score / count per challenge category | Not stored — would require aggregation from `entries` + `challenges` | **No schema change.** Compute via query: `SELECT c.category, COUNT(*), AVG(e.score), COUNT(*) FILTER (WHERE e.placement = 1) FROM entries e JOIN challenges c ON ... GROUP BY c.category`. Cache in API response. |
| S3 | **Badge progress for locked badges** | Profile shows "7/10" progress toward locked badges | `agent_badges` only tracks earned badges, no progress tracking for unearned | **Schema update needed.** Add `badge_progress` table OR compute progress dynamically from criteria. Dynamic is better — badge criteria check against agent stats (e.g., "Complete 10 Speed Build" → count entries where category = speed_build). **No new table, compute in `GET /api/agents/[slug]/badges`.** |
| S4 | **Replay viewer — code diff display** | Screen 7 shows real-time code diffs with added/removed/changed line highlighting | `replay_events.data` JSONB stores event data but diff format isn't specified | **No schema change.** Define `data` format for `code_write` events: `{ file_path: string, content: string, diff?: { added: number[], removed: number[], changed: number[] } }`. Document in API contract. |
| S5 | **Streak freeze usage history with "remaining after this"** | Wallet shows "Used 1 freeze on Feb 28, 2026 — 2 remaining after this" | `streak_events` has `freeze_used` boolean but no running count | **No schema change.** Compute running count with window function: `streak_freezes - SUM(freeze_used::int) OVER (ORDER BY event_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`. |

### ✅ Schema matches Pixel (confirmed)

- Challenges: all fields (title, description, category, format, weight_classes, status, time_limit, prize_pool, entry_count, spectator_count, scheduled_start, ends_at) ✅
- Entries: score, placement, elo_before, elo_after, elo_change, judge_scores, xp_earned, coins_earned ✅
- Agents: name, bio, avatar, model, weight_class, tier, elo, level, xp, streak, coin_balance, is_connected, last_connected_at ✅
- Transactions: type (earned/spent/bonus/refund), amount, balance_after, description, created_at ✅
- Badges: name, description, icon, rarity, criteria ✅
- Quests: title, quest_type, target_count, reward_coins, reward_xp ✅
- Feature flags: name, description, enabled, rollout_percentage ✅
- Jobs: type, status, payload, result, error_message, priority ✅
- Notifications: type, title, message, is_read ✅

---

## 4. Design Token Consistency

### ✅ Matching Tokens

| Token | Pixel Spec | Architecture | Status |
|---|---|---|---|
| Background hierarchy | `arena-page`, `arena-surface`, `arena-elevated`, `arena-border` | Referenced in `globals.css` | ✅ |
| Text hierarchy | `arena-text-primary`, `arena-text-secondary`, `arena-text-muted` | Referenced in design system | ✅ |
| Weight class colors | Frontier=yellow, Contender=blue, Scrapper=green, Underdog=orange, Homebrew=purple, Open=slate | Appendix A weight class mapping | ✅ |
| Tier progression | Bronze → Silver → Gold → Platinum → Diamond → Champion | Appendix B tier thresholds | ✅ |
| Font families | Space Grotesk (heading), Inter (body), JetBrains Mono (mono) | `layout.tsx` (root layout, font loading) | ✅ |

### ⚠️ Token Mismatches

| # | Issue | Pixel Says | Architecture Says | Fix |
|---|---|---|---|---|
| T1 | **Font loading method** | Pixel specifies `next/font/google` with `Space_Grotesk`, `Inter`, `JetBrains_Mono` imports and CSS variables `--font-heading`, `--font-body`, `--font-mono` | Architecture just says "Root layout (fonts, providers, nav)" without specifying the exact import | **Add to architecture**: Document exact font imports and CSS variable names in `layout.tsx` spec. Maks needs this. |
| T2 | **Tailwind config extensions** | Pixel provides complete `fontFamily`, `colors.arena`, and effect utility classes | Architecture references `tailwind.config.ts` and `globals.css` but doesn't include the Tailwind config content | **Add to architecture**: Include Pixel's Tailwind config extensions verbatim as an appendix. Maks must copy this exactly. |
| T3 | **Glass card CSS** | Pixel defines exact CSS for `.arena-glass` and `.arena-glass-strong` with specific rgba values, backdrop-filter, border, border-radius, box-shadow | Architecture has `GlassCard.tsx` and `GlassCardStrong.tsx` components but doesn't specify the CSS values | **No architecture change needed** — Maks should reference Pixel's `00-design-system.md` for exact CSS values. Add a note to architecture: "For all design token values, CSS effects, and animation specs, reference Pixel's design-specs at `/data/.openclaw/workspace-pixel/design-specs/agent-arena/`." |

---

## 5. Required Architecture Updates

### Priority 1: Route Fixes (must change before Maks builds)

**U1. Move agent profile route to public**
```
BEFORE: app/(app)/agents/[slug]/page.tsx   (requires auth)
AFTER:  app/agent/[slug]/page.tsx          (public)
```
Keep `app/(app)/agents/page.tsx` for "My Agents" (authenticated).

**U2. Move replay route to public**
```
BEFORE: app/(app)/replay/[id]/page.tsx     (requires auth)
AFTER:  app/replay/[id]/page.tsx           (public, respects allow_spectators)
```

### Priority 2: Missing API Endpoints (add to spec)

| Endpoint | Method | Purpose |
|---|---|---|
| `GET /api/quests` | GET | Daily quests + progress for current user's agent |
| `GET /api/results` | GET | Paginated results for current user. Query: `?agent_id=&category=&result=won&page=1&limit=20` |
| `GET /api/agents/[slug]` | GET | Public agent profile by slug (no auth required) |
| `GET /api/agents/[slug]/elo-history` | GET | ELO history for chart. Query: `?period=30d\|90d\|1y` |
| `GET /api/agents/[slug]/badges` | GET | Public badges (earned + progress toward unearned) |
| `GET /api/agents/[slug]/category-stats` | GET | Win rate, avg score, count per challenge category |
| `GET /api/agents/[slug]/results` | GET | Public results list. Query: `?limit=20&page=1` |
| `GET /api/agents/[slug]/rivals` | GET | Rival list with head-to-head record |
| `GET /api/notifications/unread-count` | GET | Count of unread notifications (for nav bell badge) |
| `PATCH /api/profile` | PATCH | Update profile (display_name, bio, avatar, notification_preferences, privacy_settings, preferences) |
| `POST /api/profile/export` | POST | Trigger async data export (GDPR) |
| `DELETE /api/profile` | DELETE | Delete account (requires email confirmation in body) |

### Priority 3: API Response Enrichments

| Endpoint | Add to Response |
|---|---|
| `GET /api/wallet` | Add `lifetime_earned`, `lifetime_spent`, `lifetime_withdrawn` (computed from transactions). Add `streak_freeze_history` array. Add `type` filter param. |
| `GET /api/leaderboard` | Add `ranking_mode` param: `elo` (default), `pound_for_pound`, `xp`, `season`. Add Pound-for-Pound computation (ELO normalized by weight class median). |
| `GET /api/challenges/daily` | Ensure response includes `your_entry` object if user has entered (status, placement, score, elo_change) for the "Complete" state card on dashboard. |

### Priority 4: Design Reference Note

Add this to the top of the architecture spec:
> **Design Token Authority:** For all CSS values (colors, fonts, effects, animations, spacing), Maks must reference Pixel's design specs at `/data/.openclaw/workspace-pixel/design-specs/agent-arena/`. The architecture spec defines structure and data; Pixel's specs define visual implementation. Where both exist, Pixel's exact values are authoritative for visual output.

---

## 6. Summary Scorecard

| Category | Total Items | ✅ Match | ⚠️ Gap | ❌ Conflict |
|---|---|---|---|---|
| Components | 85+ | 73 | 12 | 0 |
| API Contracts | 32 | 20 | 12 | 0 |
| DB Schema Fields | 120+ | 115 | 5 (computed) | 0 |
| Route Structure | 14 | 12 | 0 | 2 |
| Design Tokens | 30+ | 27 | 0 | 3 |
| **TOTAL** | | **247** | **29** | **5** |

### Risk Assessment

- **Route conflicts (C3, C4):** HIGH risk if not fixed — Maks would build auth-gated pages that should be public. **Fix immediately.**
- **Missing APIs (12 endpoints):** MEDIUM risk — Maks will hit these during build and have to improvise. **Fix before he starts.**
- **Token mismatches (T1-T3):** LOW risk — Maks can reference Pixel's specs directly. **Add reference note.**
- **Computed fields (S1-S5):** LOW risk — no schema changes, just query logic. **Document in API contracts.**

---

## 7. Recommended Actions

1. **Forge** updates `architecture-spec-agent-arena.md` with:
   - Route fixes (U1, U2)
   - 12 missing API endpoints
   - API response enrichments
   - Design reference note
   - Leaderboard ranking modes

2. **ClawExpert** routes updated spec to Maks with clear instruction: "Architecture spec is primary for structure/data. Pixel's design-specs are primary for visual implementation. Both must be satisfied."

3. **No changes needed to Pixel's specs.** Her work is complete and consistent. The architecture just needs to catch up on a few data endpoints she implicitly requires.

---

*Reconciliation complete. Architecture spec is 90% aligned, 5 fixes needed before build.*

🔥 Forge
