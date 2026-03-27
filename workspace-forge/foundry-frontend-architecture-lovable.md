# FOUNDRY — Frontend Architecture Spec (Lovable Edition)
**Prepared by:** Forge 🔥
**For:** Nick — building in Lovable AI
**Date:** 2026-03-28
**Based on:** FOUNDRY-MASTER-BUILD-MAP.md v1.2 + original frontend architecture spec
**Status:** Ready for Lovable build

---

## LOVABLE VS NEXT.JS — KEY DIFFERENCES

Before anything else: Lovable generates **React + Vite (SPA)**, not Next.js. This changes several things from the original spec.

| Original Spec | Lovable Reality |
|--------------|----------------|
| Next.js App Router | React Router v6 (client-side SPA) |
| Server Components | Client components only — everything runs in browser |
| Next.js API routes (`/api/*`) | Supabase Edge Functions |
| `@supabase/ssr` | `@supabase/supabase-js` (client SDK) |
| Next.js `metadata` API | React Helmet or document title hooks |
| File-based routing (`/app/page.tsx`) | React Router `<Route>` definitions |
| Server Actions | Supabase RPC or Edge Functions |

**Everything else — TanStack Query, Zustand, React Hook Form, Zod, Tailwind, shadcn/ui, Supabase Auth — stays the same. Lovable supports all of these natively.**

---

## 1. STACK (LOVABLE-NATIVE)

| Layer | Technology | Lovable Support |
|-------|-----------|----------------|
| Framework | React 18 + Vite | ✅ Native |
| Routing | React Router v6 | ✅ Native |
| Styling | Tailwind CSS + shadcn/ui | ✅ Native (Lovable's default) |
| Server state | TanStack Query v5 | ✅ Works great |
| Client state | Zustand | ✅ Works great |
| Forms | React Hook Form + Zod | ✅ Works great |
| Auth | Supabase Auth (client SDK) | ✅ Native integration |
| Database | Supabase Postgres + RLS | ✅ Native integration |
| Realtime | Supabase Realtime | ✅ Native integration |
| Backend functions | Supabase Edge Functions | ✅ Can generate these |
| Web3 (crypto path) | wagmi v2 + viem + RainbowKit | ⚠️ Manual setup needed — see Section 8 |
| Fiat on-ramp | Coinbase Commerce (redirect link) | ✅ Simple URL redirect |

---

## 2. FULL PAGE MAP (REACT ROUTER)

All routes are client-side. Define these in your root `App.tsx`.

### Public Routes (no auth)

| Route | Page | Purpose |
|-------|------|---------|
| `/` | Homepage | Hero, how it works, featured campaigns |
| `/campaigns` | Discover | Browse + filter campaigns |
| `/campaigns/:id` | Campaign Detail | Full info, milestones, tiers, backing |
| `/marketplace` | Marketplace | Browse reward claim listings |
| `/marketplace/:listingId` | Listing Detail | Single listing, buy button |
| `/how-it-works` | Explainer (Backers) | Education page |
| `/for-creators` | Explainer (Creators) | Creator education |
| `/apply` | Creator Application | Multi-step form |
| `/login` | Login | Email or wallet |
| `/signup` | Sign Up | Email registration |

### Protected Routes — Backer (requires Supabase session)

| Route | Page | Purpose |
|-------|------|---------|
| `/dashboard` | Backer Dashboard | Claims, backed campaigns |
| `/dashboard/campaign/:id` | Campaign View | Status from backer's view |
| `/dashboard/exit/:claimId` | Exit Flow | Refund OR marketplace |
| `/dashboard/rewards` | Delivered Rewards | History |

### Protected Routes — Creator

| Route | Page | Purpose |
|-------|------|---------|
| `/creator` | Creator Dashboard | Campaigns, milestones, funds |
| `/creator/campaign/:id` | Campaign Management | Manage a live campaign |
| `/creator/campaign/:id/milestone/:n/submit` | Milestone Submit | Upload proof |

### Protected Routes — Admin

| Route | Page | Purpose |
|-------|------|---------|
| `/admin/campaigns` | Campaign Queue | Review queue |
| `/admin/campaigns/:id` | Campaign Review | Single application |
| `/admin/milestones` | Milestone Queue | Verification queue |

---

## 3. AUTH FLOWS (SUPABASE CLIENT-SIDE)

Two user types. Design and build them as completely separate paths.

### Path A — Email / Fiat User (mainstream backer)

This user never sees a wallet prompt unless they choose the marketplace exit.

```
1. Browse site freely (no auth)
2. Click "Back This Campaign" → redirected to /login
3. Sign up / log in with email + password (Supabase Auth)
4. Returns to campaign → selects tier → pays by card
   → Coinbase Commerce redirect URL (simple link, no crypto)
   → Supabase webhook confirms payment → pledge recorded
5. Lands in /dashboard with their claim visible
6. wallet_address = NULL in users table — that's fine
7. [Only if they choose Marketplace Exit]:
   → Prompted to connect wallet for the first time
   → Wallet linked to their Supabase account
```

**Supabase session management:** `supabase.auth.onAuthStateChange()` listener in your root `App.tsx`. Store user in Zustand `authStore`.

### Path B — Crypto Wallet User

```
1. Click "Connect Wallet" → RainbowKit modal
2. Wallet connected → backend checks if user exists by wallet_address
   → New user: auto-creates Supabase record, prompts for email (optional)
   → Existing: signs them in (or links wallet to existing session)
3. Pays with USDC directly from wallet → contract
4. Full dashboard access
```

**Note for Lovable:** RainbowKit needs manual setup (see Section 8). Tell Lovable to stub the wallet UI as a placeholder button initially and you'll wire in RainbowKit separately.

### Auth State in Zustand

```typescript
// authStore.ts
{
  user: SupabaseUser | null,
  role: 'backer' | 'creator' | 'admin' | null,
  walletAddress: string | null,
  isLoading: boolean,

  // Derived
  canUseMarketplace: user !== null && walletAddress !== null,
  canUseFiat: user !== null,
  canUseCrypto: user !== null && walletAddress !== null,
}
```

### Protected Route Wrapper

In React Router, use a layout route with an auth check:

```typescript
// ProtectedRoute.tsx
// If no Supabase session → redirect to /login
// If wrong role → redirect to /
```

Tell Lovable: "Create a `ProtectedRoute` component that checks Supabase auth session. If not logged in, redirect to `/login`. Accept a `requiredRole` prop — if the user's role doesn't match, redirect to `/`."

---

## 4. STATE MANAGEMENT

### TanStack Query — Server Data

All data from Supabase lives here. Give Lovable these query key patterns when building each page:

```typescript
// Canonical query keys
['campaigns', 'list', filters]           // /campaigns page
['campaigns', 'detail', campaignId]      // /campaigns/:id
['campaigns', 'milestones', campaignId]  // milestone tracker
['campaigns', 'tiers', campaignId]       // tier cards
['marketplace', 'listings', filters]     // /marketplace
['marketplace', 'listing', listingId]    // /marketplace/:id
['user', 'pledges']                      // /dashboard
['user', 'creator-campaigns']            // /creator
```

### Zustand — Client UI State

```typescript
// authStore — Supabase user + wallet
// exitFlowStore — which path chosen, price entered
// applicationStore — multi-step form, auto-saved to localStorage
// walletStore — wagmi wallet state (address, chainId, isConnected)
```

### URL State — Filters and Pagination

Filters belong in the URL, not Zustand. Use React Router's `useSearchParams`:
```
/campaigns?category=tech&status=live&sort=newest&page=2
/marketplace?minPrice=50&maxPrice=500&sort=lowest
```

---

## 5. COMPONENT HIERARCHY

Structured for how you'll prompt Lovable — page by page.

---

### Homepage `/`

**Prompt Lovable:** "Build a homepage for a blockchain crowdfunding platform called Foundry. Dark/professional aesthetic. Include: (1) Hero section with headline, subheadline, 'Browse Campaigns' and 'Launch a Campaign' CTAs. (2) 'How It Works' section with 4 steps: Creator stakes collateral → Milestones gate fund release → AI reviews every campaign → Backers can exit anytime. (3) Featured Campaigns grid (3 cards, use mock data). (4) Trust signals strip: total funds protected, campaigns funded, backer count. (5) Footer with legal disclaimer."

**Components:**
```
HomePage
├── HeroSection (headline + 2 CTAs)
├── HowItWorksSection (4 StepCards)
├── FeaturedCampaigns (3 CampaignCards — mock data)
├── TrustSignalsStrip (stats)
├── ForCreatorsSection (creator CTA)
└── Footer (with legal copy)
```

---

### Campaign Discovery `/campaigns`

**Prompt Lovable:** "Build a campaign discovery page. Left sidebar with filters: category (multi-select), status (live/funded/delivering/complete), sort (newest/ending soon/most funded/highest AI score). Main area: responsive grid of CampaignCards. Each card shows: campaign name, creator name, AI score badge (e.g. '82/100'), funding progress bar (% funded), days remaining, milestone status (2/4 complete), tier price range ($50–$500). Clicking a card navigates to /campaigns/:id. Use mock data for 9 campaigns."

**Components:**
```
CampaignsPage
├── FilterSidebar
│   ├── CategoryMultiSelect
│   ├── StatusFilter
│   └── SortSelect
└── CampaignGrid
    └── CampaignCard (×N)
        ├── AIScoreBadge
        ├── FundingProgressBar
        ├── MilestoneStatusPill
        ├── DaysRemainingTag
        └── TierPriceRange
```

---

### Campaign Detail `/campaigns/:id`

This is the most complex public page. Build it in 2-3 Lovable prompts.

**Prompt 1 — Layout + header:**
"Build a campaign detail page. Two-column layout on desktop, single column on mobile. Left column (wider): campaign title, creator info, category badge, AI score badge with disclaimer text 'AI review is a quality filter, not a guarantee of delivery.' Campaign description (long text). Team section (names, roles, links). Right column (sticky): funding panel showing goal, progress bar, backer count, days remaining, refund rate ('50% refund protection' — make this prominent), and a 'Back This Campaign' button."

**Prompt 2 — Milestone Tracker:**
"Add a milestone tracker component below the description. Show a vertical timeline of milestones. Each milestone row: milestone name, status badge (Pending/Submitted/Verified/Disputed/Failed), deadline, what percentage of escrow it unlocks, and an IPFS proof link (show only when status is Verified). Use mock data with 4 milestones, 2 verified and 2 pending."

**Prompt 3 — Reward Tiers + Backing Modal:**
"Add a reward tiers section below the milestone tracker. Show 3 tier cards in a grid. Each card: tier name, price in USDC, reward description, supply remaining (e.g. '42 of 100 remaining'). Clicking 'Back This Tier' opens a modal. The modal shows: tier summary, two payment options ('Pay by Card' and 'Pay with Crypto Wallet'), the campaign's refund rate, and legal copy: 'You are backing a project to receive a reward, not making an investment.' Confirm button at the bottom."

**Components:**
```
CampaignDetailPage
├── CampaignHeader (title, creator, badges)
├── [Two-column layout]
│   ├── Left
│   │   ├── CampaignDescription
│   │   ├── TeamSection
│   │   ├── MilestoneTracker
│   │   │   └── MilestoneRow (×N)
│   │   └── RewardTiers
│   │       └── TierCard (×N)
│   └── Right (sticky)
│       └── FundingPanel
│           ├── FundingProgressBar
│           ├── RefundRateDisplay ← must be prominent
│           └── BackCampaignButton
└── BackingModal
    ├── TierSummary
    ├── PaymentMethodChoice (Card | Crypto)
    ├── RefundRateReminder
    ├── LegalCopy
    └── ConfirmButton
```

---

### Marketplace `/marketplace`

**Prompt Lovable:** "Build a marketplace page for trading reward claim certificates. Filter bar at top: milestone status filter, price range slider, refund protection minimum %, sort (newest/lowest ask/highest refund/closest delivery). Below: responsive grid of ListingCards. Each card shows: reward description, campaign name + status, milestone progress ('2 of 4 complete'), original price paid vs current ask price, refund protection rate, estimated delivery, Buy button. IMPORTANT: Do NOT include price history charts, floor price stats, or volume statistics. Use mock data for 8 listings."

**Components:**
```
MarketplacePage
├── MarketplaceFilterBar
│   ├── MilestoneStatusFilter
│   ├── PriceRangeSlider
│   ├── RefundProtectionFilter
│   └── SortSelect
└── ListingGrid
    └── ListingCard (×N)
        ├── RewardDescription
        ├── CampaignStatusBadge
        ├── MilestoneProgressBar
        ├── PriceComparison (original vs ask)
        ├── RefundProtectionBadge
        ├── DeliveryEstimate
        └── BuyButton
```

---

### Exit Flow `/dashboard/exit/:claimId`

**This is legally critical. Prompt Lovable carefully.**

**Prompt Lovable:** "Build a two-step exit flow page. Step 1: show two large equal-sized option cards side by side. Left card: 'Get [50]% Back' — shows exact refund amount ($50.00), explains this is a platform refund, has a 'Choose Refund' button. Right card: 'Sell Your Reward Claim' — explains they can list on the marketplace and set their own price, shows the refund rate as a floor ('Protected at 50% if campaign fails'), has a 'List on Marketplace' button. Cards must be visually equal — no default, no pre-selection, no visual hierarchy favoring one over the other.

Step 2a (if Refund chosen): Show refund summary, a checkbox 'I understand my reward claim will be cancelled', and a 'Confirm Refund' button.

Step 2b (if Marketplace chosen): Show a price input ('Set your listing price in USDC'), a wallet connect prompt if no wallet is connected, legal copy 'You are transferring your reward claim to another backer. This is not an investment exit.', and a 'List on Marketplace' button."

**Components:**
```
ExitFlowPage
├── ClaimSummaryHeader
├── Step1: ExitPathChoice
│   ├── PathCard (refund) — equal visual weight
│   └── PathCard (marketplace) — equal visual weight
├── Step2a: RefundConfirmStep
│   ├── RefundSummary
│   ├── AcknowledgmentCheckbox
│   └── ConfirmRefundButton
└── Step2b: MarketplaceListStep
    ├── PriceInput
    ├── WalletConnectPrompt (conditional)
    ├── LegalCopy (hardcoded — see legal copy rules)
    └── ConfirmListingButton
```

---

### Backer Dashboard `/dashboard`

**Prompt Lovable:** "Build a backer dashboard. Header shows welcome message and wallet connection status (if wallet not connected: 'Connect a wallet to access the marketplace'). Main area: 'Active Claims' section with claim cards. Each claim card shows: campaign name, tier name, amount paid, milestone progress, claim status badge (Active/Refunded/Listed/Delivered), refund rate, and an 'Exit' button. Below: 'Delivered Rewards' section. Use mock data."

---

### Creator Application `/apply` (Multi-Step)

**Build this as 6 sequential steps in Lovable. One prompt per step.**

**Step 1 — Project Basics:** project name, category dropdown, description textarea, funding goal (USD), duration (30/60/90 days selector)

**Step 2 — Team:** repeatable team member form (add/remove). Fields per member: name, role, LinkedIn URL, GitHub URL, prior work description.

**Step 3 — Milestones:** repeatable milestone form (min 3, max 10). Fields per milestone: name, description, release % (must sum to 100%), proof type dropdown (link/document/video/code_repo/delivery_confirmation), deadline date picker. Show running total of % allocated.

**Step 4 — Reward Tiers:** repeatable tier form (min 1, max 10). Fields per tier: name, price (USDC), reward description, supply cap, max per wallet (0 = unlimited), royalty % (0–10%).

**Step 5 — Terms:** refund rate input (25–100%), explanation of what this means for backers, AI review fee display (auto-calculated: $99/$199/$299 based on funding goal), terms checkbox.

**Step 6 — Review & Submit:** full application summary, submit button, post-submit message "AI review takes 48–72 hours."

**Tell Lovable:** "Persist form state across steps using localStorage so users don't lose progress if they navigate away."

---

## 6. SUPABASE SETUP IN LOVABLE

Lovable has native Supabase integration — use it.

**When prompting Lovable, tell it to:**

1. Connect to Supabase (use the Integrations panel in Lovable)
2. Create these tables (paste the schema from FOUNDRY-MASTER-BUILD-MAP.md Section 9 directly into your prompt):
   - `users`
   - `campaigns`
   - `campaign_tiers` (include `max_per_wallet int DEFAULT 0` and `royalty_bps int DEFAULT 0`)
   - `milestones`
   - `pledges`
   - `marketplace_listings`
   - `milestone_votes`
   - `ai_reviews`

3. Enable Row Level Security on all tables
4. Enable Supabase Auth (email provider)
5. Enable Supabase Realtime on `milestones` table (for live status updates)

**Prompting Lovable for RLS:**
"Enable RLS on all tables. Policies: campaigns — public read, creator-only write. pledges — read own only (user_id = auth.uid()), service role write only. milestone_votes — public read, insert own, no updates. ai_reviews — campaign owner and admin read only."

---

## 7. BACKEND FUNCTIONS (SUPABASE EDGE FUNCTIONS)

Since Lovable is a SPA (no Next.js API routes), backend logic runs as Supabase Edge Functions. Key ones:

| Function | Trigger | Purpose |
|----------|---------|---------|
| `campaign-apply` | POST from `/apply` form | Validates application, queues AI review |
| `pledge-fiat-initiate` | POST from backing modal | Creates Coinbase Commerce charge, returns checkout URL |
| `pledge-confirm` | Webhook from Coinbase Commerce | Records pledge in Supabase after payment confirmed |
| `exit-refund` | POST from exit flow | Processes platform refund |
| `exit-marketplace-list` | POST from exit flow | Triggers lazy mint + creates marketplace listing |
| `milestone-submit` | POST from creator submit form | Stores proof, queues AI verification |
| `milestone-vote` | POST from backer vote | Records vote on-chain + Supabase |
| `ai-review-callback` | Webhook from AI service | Processes AI review result, updates campaign status |

**When prompting Lovable for these:** "Create a Supabase Edge Function called `[name]` that does [description]. Call it from the frontend using `supabase.functions.invoke('[name]', { body: {...} })`."

---

## 8. WEB3 (WALLET + ON-CHAIN) — MANUAL SETUP REQUIRED

Lovable does not natively support wagmi/RainbowKit. Here's how to handle this:

### Approach: Build UI First, Wire Web3 After

1. **In Lovable:** Build the full UI with stub wallet state. Tell Lovable: "Create a `WalletButton` component that shows 'Connect Wallet' when disconnected and shows a truncated address '0x1234...5678' when connected. Use a Zustand store for wallet state (address, isConnected). The button is a placeholder — we'll wire in RainbowKit later."

2. **After Lovable export (via GitHub sync):** Add wagmi + RainbowKit manually:
   ```bash
   npm install wagmi viem @rainbow-me/rainbowkit
   ```
   Wire into the existing Zustand `walletStore`.

3. **Crypto pledge flow in Lovable:** Build the UI (tier selection, payment modal). Tell Lovable the crypto path calls `supabase.functions.invoke('pledge-confirm', ...)` after a transaction hash is returned. The actual `writeContract` call to the escrow contract will be added post-export.

### Why This Approach
Lovable generates clean React code that you can export to GitHub. The web3 wallet parts can be added in a normal code editor after the UI is built. This lets you get 95% of the design done in Lovable without hitting its web3 limitation.

---

## 9. PROMPTING STRATEGY FOR LOVABLE

How to get the best output from Lovable on this project:

### Build Page by Page
Don't paste the whole spec. One page per session. Start with the design system, then build pages in order of complexity (simple → complex).

**Recommended build order:**
1. Design system / global components (Header, Footer, color palette)
2. Homepage
3. Campaign Discovery + CampaignCard component
4. Campaign Detail (3 prompts)
5. Marketplace + ListingCard
6. Backer Dashboard
7. Exit Flow (most complex — be precise)
8. Creator Dashboard + Milestone Submit
9. Creator Application multi-step form
10. Admin pages (last — least user-facing)

### Include Mock Data in Prompts
Lovable produces much better output when you give it realistic mock data. Example:
> "Use this mock campaign: title 'Luminary — Smart Home Lighting', creator 'Aria Chen', category 'Tech', AI score 87/100, funding goal $120,000, raised $94,500, 28 days remaining, refund rate 50%, 4 milestones (2 verified, 1 submitted, 1 pending)."

### Specify the Design Direction
Lovable needs a visual direction or it'll default to generic. Set it early:
> "Design language: dark background (#0f0f0f), accent color electric blue (#3b82f6), clean sans-serif typography, minimal and professional. Think 'Kickstarter meets Coinbase' — trustworthy and modern, not crypto-bro."

### Name Your Components
When asking Lovable to build a component that appears multiple times (CampaignCard, ListingCard, MilestoneRow), name it explicitly. Then when building pages that use it, reference it by name: "Use the `CampaignCard` component we built earlier."

### Legal Copy — Give Lovable the Exact Strings
Don't let Lovable write the legally-sensitive copy. Paste the exact strings:
> "Use exactly this text for the exit flow marketplace disclaimer: 'You are transferring your reward claim to another backer. This is not an investment exit or financial transaction.' Do not paraphrase."

---

## 10. LEGAL COPY RULES (MANDATORY)

All components rendering user-visible text must follow these rules. Paste this table into your Lovable prompts when building components that involve backing, exiting, or marketplace activity.

| ❌ Never Render | ✅ Always Render |
|----------------|----------------|
| "Invest" / "Investment" | "Back" / "Support" / "Fund" |
| "Return" / "Profit" | "Reward" / "Delivery" |
| "Exit your position" | "Sell your reward claim" |
| "Token value" | "Reward claim" |
| "Appreciate" / "Gain" | "Transfer" |
| "Portfolio" | "Backed campaigns" |
| "Yield" | "Reward" |
| "Earn passive income from royalties" | "Receive compensation when your reward claims are transferred" |

**Hardcoded strings — paste these exactly into Lovable when building these components:**

Campaign detail page (under AI score):
> *"AI review is a quality filter, not a guarantee of delivery. Back campaigns at your own discretion."*

Exit flow — marketplace path:
> *"You are transferring your reward claim to another backer. This is not an investment exit."*

Marketplace listing cards — DO NOT include price charts, floor price, volume stats (V1 legal requirement).

---

## 11. IMPLEMENTATION CONCERNS (LOVABLE-SPECIFIC)

### 1. Auth State Initialization Flicker
Lovable's Supabase auth setup sometimes causes a flicker on protected routes (user appears logged out for 1 frame). Tell Lovable: "Show a loading spinner on protected routes until `supabase.auth.getSession()` resolves. Don't redirect to /login until the session check completes."

### 2. TanStack Query + Supabase Pattern
Tell Lovable: "Wrap all Supabase queries in TanStack Query `useQuery` hooks, not raw `useEffect` + `useState`. Example: `useQuery({ queryKey: ['campaigns', filters], queryFn: () => supabase.from('campaigns').select('*') })`."

### 3. Exit Flow — Don't Let Lovable Merge the Paths
Lovable might try to simplify the exit flow into one form. Explicitly tell it: "The refund path and marketplace path are entirely separate UI flows. Never combine them. Step 1 shows two cards — after selecting one, show only that path's form. The other path disappears."

### 4. Multi-Step Form State
Tell Lovable: "Use Zustand with `persist` middleware for the campaign application form. Persist to localStorage so state survives page refresh. Key: `foundry-application-draft`."

### 5. Realtime Milestones
For the milestone tracker on campaign detail: "Subscribe to Supabase Realtime on the milestones table filtered by campaign_id. Update the UI without a page refresh when milestone status changes."

### 6. Mobile Responsive
Lovable defaults to desktop. Specify for every page: "Fully responsive. On mobile: single column layout, filter sidebar becomes a bottom sheet/drawer, cards stack vertically."

### 7. Marketplace V1 Scope
Tell Lovable explicitly: "Do NOT add price charts, price history, floor price displays, or volume statistics to any marketplace component. These are not in scope."

---

## 12. FOLDER STRUCTURE (VITE SPA)

```
/src
  /pages
    Home.tsx
    Campaigns.tsx
    CampaignDetail.tsx
    Marketplace.tsx
    ListingDetail.tsx
    HowItWorks.tsx
    ForCreators.tsx
    Apply.tsx
    Login.tsx
    Signup.tsx
    /dashboard
      Dashboard.tsx
      CampaignView.tsx
      ExitFlow.tsx
      Rewards.tsx
    /creator
      CreatorDashboard.tsx
      CampaignManage.tsx
      MilestoneSubmit.tsx
    /admin
      AdminCampaigns.tsx
      AdminCampaignReview.tsx
      AdminMilestones.tsx

  /components
    /ui/              ← shadcn/ui base components
    /campaigns/
      CampaignCard.tsx
      CampaignGrid.tsx
      MilestoneTracker.tsx
      MilestoneRow.tsx
      FundingPanel.tsx
      TierCard.tsx
      BackingModal.tsx
      AIScoreBadge.tsx
    /marketplace/
      ListingCard.tsx
      ListingGrid.tsx
      PurchasePanel.tsx
    /exit/
      PathCard.tsx
      RefundConfirmStep.tsx
      MarketplaceListStep.tsx
    /forms/
      CampaignApplicationForm.tsx
      MilestoneProofForm.tsx
    /auth/
      ProtectedRoute.tsx
      WalletButton.tsx       ← stub for RainbowKit
      AuthButton.tsx
    /layout/
      Header.tsx
      Footer.tsx
      Layout.tsx

  /hooks
    useAuth.ts             ← merged Supabase + wallet state
    useCampaigns.ts
    useMarketplace.ts
    usePledge.ts
    useExit.ts
    useRealtimeMilestones.ts

  /store
    authStore.ts
    walletStore.ts
    exitFlowStore.ts
    applicationStore.ts    ← persisted to localStorage

  /lib
    supabase.ts            ← createClient
    queryClient.ts
    validations/
      campaignApplication.ts
      pledgeForm.ts

  /types
    campaign.ts
    marketplace.ts
    user.ts

  /constants
    legal-copy.ts          ← all legally-required strings, never inline
    routes.ts

  App.tsx                  ← React Router route definitions
  main.tsx
```

---

*Prepared by Forge 🔥 — Perlantir AI Studio*
*Lovable-specific. Use this spec, not the Next.js version.*
