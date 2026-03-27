# FOUNDRY — Frontend Architecture Spec
**Prepared by:** Forge 🔥
**For:** Nick (Design) → Maks (Implementation)
**Date:** 2026-03-28
**Based on:** FOUNDRY-MASTER-BUILD-MAP.md v1.2 + FOUNDRY-PLATFORM-FRAMEWORK-V2.md + FOUNDRY-LEGAL-CHANGES-FOR-DEV.md
**Status:** Ready for Design

---

## 1. STACK

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 14 App Router |
| Styling | Tailwind CSS + shadcn/ui |
| Web3 (crypto path) | wagmi v2 + viem + RainbowKit |
| Fiat on-ramp | Coinbase Commerce or Stripe + Coinbase SDK |
| Server state | TanStack Query (React Query v5) |
| Client state | Zustand |
| Forms | React Hook Form + Zod |
| Auth | Supabase Auth (email/fiat users) + wallet signature (crypto users) |
| Notifications | Resend (backend) + toast (frontend) |

---

## 2. FULL PAGE MAP

### Public (no auth required)

| Route | Page Name | Purpose |
|-------|-----------|---------|
| `/` | Homepage | Hero, how it works, featured campaigns, trust signals |
| `/campaigns` | Discover | Browse + filter all live campaigns |
| `/campaigns/[id]` | Campaign Detail | Full campaign info, milestone tracker, tiers, exit options |
| `/marketplace` | Marketplace | Browse reward claim listings |
| `/marketplace/[listingId]` | Listing Detail | Single listing — reward info, campaign status, buy |
| `/how-it-works` | Explainer (Backers) | Education — crowdfunding flow, exit options |
| `/for-creators` | Explainer (Creators) | Education — campaign creation, milestone system |
| `/apply` | Creator Application | Multi-step form to submit a campaign |
| `/login` | Login | Email or wallet connect |
| `/signup` | Sign Up | Email registration or wallet connect |

### Authenticated — Backer

| Route | Page Name | Purpose |
|-------|-----------|---------|
| `/dashboard` | Backer Dashboard | Overview of all backed campaigns, claims, pending rewards |
| `/dashboard/campaign/[id]` | Campaign View (Backer) | Status from backer's perspective, exit options |
| `/dashboard/exit/[claimId]` | Exit Flow | Two-path exit: refund OR marketplace listing |
| `/dashboard/rewards` | Delivered Rewards | History of received rewards |

### Authenticated — Creator

| Route | Page Name | Purpose |
|-------|-----------|---------|
| `/creator/dashboard` | Creator Dashboard | All campaigns, milestone status, fund tracking |
| `/creator/campaign/[id]` | Campaign Management | Manage a live campaign |
| `/creator/campaign/[id]/milestone/[n]/submit` | Milestone Submission | Upload proof for a milestone |
| `/creator/apply` | Campaign Application | Multi-step application (alias or redirect from `/apply`) |

### Admin (internal)

| Route | Page Name | Purpose |
|-------|-----------|---------|
| `/admin/campaigns` | Campaign Queue | All campaigns + AI review queue |
| `/admin/campaigns/[id]` | Campaign Review | Review a specific application |
| `/admin/milestones` | Milestone Queue | Milestone verification queue |
| `/admin/marketplace` | Marketplace Overview | Listings, flags, activity |

---

## 3. AUTH FLOWS

There are two distinct user types with fundamentally different auth paths. Design must accommodate both without forcing crypto on mainstream users.

### Path A — Email / Fiat User (mainstream backer)

```
User lands on site
  ↓
Browses campaigns (no auth required)
  ↓
Clicks "Back This Campaign"
  ↓
Prompted: "Sign in to continue"
  → Sign up with email + password (Supabase Auth)
  → OR: Google OAuth (optional — nice for conversion)
  ↓
Chooses card payment (Coinbase Commerce / Stripe)
  → Blockchain is invisible — user never sees a wallet prompt
  ↓
Supabase session established
wallet_address = NULL in users table
  ↓
[Later — only if they choose Marketplace Exit]:
  "To list on the marketplace, you'll need a crypto wallet"
  → Prompted to connect RainbowKit wallet at this point only
  → Wallet linked to existing Supabase account
  → wallet_address filled in
```

**Session management:** Supabase JWT. Standard cookie-based session via `@supabase/ssr`.

### Path B — Crypto Wallet User (existing crypto user)

```
User lands on site
  ↓
Clicks "Connect Wallet" (RainbowKit)
  → Connects MetaMask / Coinbase Wallet / WalletConnect
  ↓
Backend receives wallet address
  → Checks if user exists in Supabase (by wallet_address)
  → If new: creates user record with wallet_address, prompts for email (optional)
  → If existing: signs them in
  ↓
Wallet signature used to verify identity on sensitive actions
  (listing on marketplace, confirming milestone votes)
  ↓
Pays with USDC directly from wallet → CampaignEscrow.sol
```

**Session management:** Supabase JWT + wagmi wallet state. Both must be in sync.

### Auth State Matrix

| User Type | Supabase Session | Wallet Connected | Can Back (Fiat) | Can Back (Crypto) | Can List on Marketplace |
|-----------|-----------------|-----------------|-----------------|-------------------|------------------------|
| Logged out | ❌ | ❌ | ❌ | ❌ | ❌ |
| Email only | ✅ | ❌ | ✅ | ❌ | ❌ (prompted to connect wallet) |
| Email + wallet | ✅ | ✅ | ✅ | ✅ | ✅ |
| Wallet only | ✅ | ✅ | ❌ | ✅ | ✅ |

### Protected Route Behavior

- `/dashboard/*` — requires Supabase session (any auth type)
- `/creator/*` — requires Supabase session + `creator` role
- `/admin/*` — requires Supabase session + `admin` role
- Marketplace listing — requires Supabase session + connected wallet
- Crypto pledge — requires connected wallet (no Supabase session strictly required, but prompt to create one for dashboard tracking)

---

## 4. STATE MANAGEMENT

### Server State — TanStack Query

All data fetched from the backend or subgraph lives here. Never in Zustand.

```typescript
// Query keys (canonical)
campaigns.list({ status, category, page })
campaigns.detail(campaignId)
campaigns.milestones(campaignId)
campaigns.tiers(campaignId)
marketplace.listings({ campaignId, tierId, priceRange, sort })
marketplace.listing(listingId)
user.pledges()
user.creatorCampaigns()
user.rewards()
```

**Mutation patterns:**
- `pledge` → optimistic update on campaign funding bar
- `createListing` → optimistic add to marketplace
- `cancelListing` → optimistic remove
- `submitMilestoneProof` → status update
- `vote` → optimistic vote count

### Client State — Zustand

Only for UI state that doesn't belong in URL or server.

```typescript
// Wallet store
{
  address: string | null
  isConnected: boolean
  chainId: number | null
}

// Auth store
{
  user: SupabaseUser | null
  role: 'backer' | 'creator' | 'admin' | null
  isLoading: boolean
}

// Exit flow store (modal/wizard state)
{
  claimId: string | null
  selectedPath: 'refund' | 'marketplace' | null
  step: number
  listingPrice: string
}

// Campaign application store (multi-step form)
{
  step: number
  formData: Partial<CampaignApplicationForm>
  isDirty: boolean
}
```

### URL State

Filters and pagination live in the URL (not Zustand) so links are shareable:
```
/campaigns?category=tech&status=live&sort=newest&page=2
/marketplace?campaignId=xxx&minPrice=50&maxPrice=500&sort=lowest
```

---

## 5. COMPONENT HIERARCHY

### Global Layout Components

```
<RootLayout>
  <Providers>           ← Supabase, wagmi, RainbowKit, TanStack Query
    <Header>
      <NavLinks />
      <WalletButton />  ← RainbowKit ConnectButton (shows only when relevant)
      <AuthButton />    ← Login/Profile (Supabase session)
    </Header>
    <main>{children}</main>
    <Footer>
      <FooterLinks />
      <LegalDisclaimer />   ← "AI review is a quality filter, not a guarantee..."
    </Footer>
    <Toaster />
  </Providers>
</RootLayout>
```

---

### Homepage `/`

```
<HomePage>
  <HeroSection>
    <HeroHeadline />
    <HeroSubtext />
    <CTAButtons>
      <BrowseCampaignsButton />
      <StartCampaignButton />
    </CTAButtons>
  </HeroSection>

  <HowItWorksSection>
    <StepCard /> × 4   ← Creator stakes, Milestone gating, AI review, Backer exit
  </HowItWorksSection>

  <FeaturedCampaigns>
    <CampaignCard /> × 3-6   ← handpicked at launch
  </FeaturedCampaigns>

  <TrustSignals>
    <StatBlock />       ← TVL, campaigns funded, backers
    <SecurityNote />    ← "Funds locked in audited smart contracts"
    <AuditBadge />
  </TrustSignals>

  <ForCreatorsSection>
    <CreatorCTA />
  </ForCreatorsSection>
</HomePage>
```

---

### Campaign Discovery `/campaigns`

```
<CampaignsPage>
  <SearchAndFilters>
    <SearchInput />
    <CategoryFilter />      ← tech, games, physical, creative, etc.
    <StatusFilter />        ← live, funded, delivering, complete
    <SortSelect />          ← newest, ending soon, most funded, highest score
  </SearchAndFilters>

  <CampaignGrid>
    <CampaignCard> × N
      <AIReviewedBadge />     ← "AI Reviewed ✓" pass/fail ONLY — NO numerical score per Counsel 2026-03-28
      <FundingProgressBar />
      <MilestoneStatusDot />
      <DaysRemaining />
      <TierPriceRange />
    </CampaignCard>
  </CampaignGrid>

  <Pagination />
</CampaignsPage>
```

---

### Campaign Detail `/campaigns/[id]`

```
<CampaignDetailPage>
  <CampaignHeader>
    <CampaignTitle />
    <CreatorInfo />
    <CategoryBadge />
    <AIReviewedBadge />     ← "AI Reviewed ✓" pass/fail badge ONLY — no numerical score per Counsel 2026-03-28
    <AIReviewDisclaimer />  ← REQUIRED exact text: "AI review is a quality filter designed to screen for obvious red flags. It is not an assessment of investment merit, likelihood of delivery, or endorsement of the campaign. Back campaigns at your own discretion."
  </CampaignHeader>

  <CampaignSplit>           ← two-column on desktop
    <Left>
      <CampaignDescription />
      <TeamSection />
      <MilestoneTracker>
        <MilestoneRow> × N
          <MilestoneStatus />     ← Pending / Submitted / Verified / Disputed / Failed
          <MilestoneDeadline />
          <FundsLockedBadge />    ← "X% of escrow"
          <ProofLink />           ← IPFS link when available
        </MilestoneRow>
      </MilestoneTracker>
      <RewardTiers>
        <TierCard> × N
          <TierName />
          <TierPrice />
          <TierRewardDescription />
          <TierSupplyRemaining />
          <BackThisButton />
        </TierCard>
      </RewardTiers>
    </Left>

    <Right>
      <FundingPanel>
        <FundingGoal />
        <FundingProgressBar />
        <BackersCount />
        <DaysRemaining />
        <RefundRateDisplay />   ← "50% refund protection" — prominent per legal
      </FundingPanel>
      <BackCampaignCTA />
    </Right>
  </CampaignSplit>

  <BackingModal>            ← opens on "Back This Campaign"
    <TierSelector />
    <PaymentMethodChoice>
      <CardPaymentOption />   ← default for mainstream users
      <CryptoPaymentOption /> ← for wallet-connected users
    </PaymentMethodChoice>
    <RefundRateReminder />
    <LegalCopy />             ← "You are backing a project, not making an investment"
    <ConfirmButton />
  </BackingModal>
</CampaignDetailPage>
```

---

### Marketplace `/marketplace`

```
<MarketplacePage>
  <MarketplaceFilters>
    <CategoryFilter />
    <MilestoneStatusFilter />   ← "All milestones on track" / "One at risk" / etc.
    <PriceRangeSlider />
    <RefundProtectionFilter />  ← minimum refund rate
    <SortSelect />              ← newest / lowest ask / highest refund / closest delivery
  </MarketplaceFilters>

  <ListingGrid>
    <ListingCard> × N
      <RewardDescription />
      <CampaignNameAndStatus />
      <MilestoneProgress />     ← "2 of 4 milestones complete"
      <OriginalPrice />
      <AskPrice />
      <RefundProtectionRate />
      <EstimatedDelivery />
      <BuyButton />
    </ListingCard>
  </ListingGrid>
</MarketplacePage>
```

**What listing cards DO NOT show (V1 legal requirement):**
- Price history charts
- Volume statistics
- Floor price analytics
- Any investment-style metrics

---

### Listing Detail `/marketplace/[listingId]`

```
<ListingDetailPage>
  <ListingHeader>
    <RewardDescription />
    <CampaignLink />
  </ListingHeader>

  <ListingInfo>
    <PricingSection>
      <OriginalPrice />
      <AskPrice />
      <RefundProtectionExplainer />
    </PricingSection>
    <CampaignHealthSection>
      <MilestoneTracker />   ← read-only version
      <FundingStatus />
      <AIReviewedBadge />    ← pass/fail only, no score
    </CampaignHealthSection>
    <RewardDetails>
      <WhatYouGet />
      <EstimatedDelivery />
    </RewardDetails>
  </ListingInfo>

  <PurchasePanel>
    <BuyNowButton />
    <WalletPrompt />    ← if not connected
    <LegalCopy />       ← "You are purchasing a reward claim transfer"
  </PurchasePanel>
</ListingDetailPage>
```

---

### Backer Dashboard `/dashboard`

```
<BackerDashboard>
  <DashboardHeader>
    <WelcomeMessage />
    <WalletStatus />    ← connected wallet or "Connect wallet to access marketplace"
  </DashboardHeader>

  <ActiveClaims>
    <ClaimCard> × N
      <CampaignName />
      <TierName />
      <AmountPaid />
      <MilestoneProgress />
      <ClaimStatus />         ← active | refunded | tokenized | delivered
      <ClaimRewardButton />   ← PRIMARY CTA — visually dominant, filled button
      <ExitButton />          ← SECONDARY — outlined/ghost, less prominent than ClaimReward
      <RefundRateTag />
    </ClaimCard>
  </ActiveClaims>
  {/* UX RULE (Counsel 2026-03-28): "Claim Reward" must always be more visually prominent
      than "Sell on Marketplace" on every backer-facing screen. Default UX = hold for reward.
      Secondary market is an exit option, not the primary action. */}

  <DeliveredRewards>
    <RewardCard> × N
  </DeliveredRewards>
</BackerDashboard>
```

---

### Exit Flow `/dashboard/exit/[claimId]`

**This is the most legally sensitive UI in the product. Two explicit paths — never merged.**

```
<ExitFlowPage>
  <ExitHeader>
    <ClaimSummary />        ← what they're exiting, what they paid
  </ExitHeader>

  <ExitPathChoice>          ← Step 1: choose path (never default one)
    <PathCard variant="refund">
      <PathTitle>"Get [X]% back"</PathTitle>
      <ExactAmount />       ← "$50.00 returned to your payment method"
      <RefundExplainer />
      <SelectRefundButton />
    </PathCard>

    <PathCard variant="marketplace">
      <PathTitle>"Sell your reward claim"</PathTitle>
      <MarketplaceExplainer />
      <RefundFloor />       ← "You're protected at [X]% if campaign fails"
      <SelectMarketplaceButton />
    </PathCard>
  </ExitPathChoice>

  <RefundConfirmStep>       ← shown if Path A chosen
    <RefundSummary />
    <LegalAcknowledgment /> ← "By confirming, your reward claim is cancelled"
    <ConfirmRefundButton />
  </RefundConfirmStep>

  <MarketplaceListStep>     ← shown if Path B chosen
    <WalletConnectPrompt /> ← if no wallet connected yet
    <PriceInput />
    <ListingPreview />
    <LegalCopy>"You are transferring your reward claim to another backer, not exiting an investment position"</LegalCopy>
    <ConfirmListingButton />
  </MarketplaceListStep>
</ExitFlowPage>
```

---

### Creator Dashboard `/creator/dashboard`

```
<CreatorDashboard>
  <CampaignList>
    <CreatorCampaignCard> × N
      <CampaignTitle />
      <FundingProgress />
      <NextMilestone />
      <FundsReleased />
      <MilestoneSubmitCTA />
      <ManageButton />
    </CreatorCampaignCard>
  </CampaignList>
</CreatorDashboard>
```

---

### Milestone Submission `/creator/campaign/[id]/milestone/[n]/submit`

```
<MilestoneSubmitPage>
  <MilestoneDefinition />   ← read-only: what was promised
  <ProofTypeRequired />     ← 'link' | 'document' | 'video' | 'code_repo' | 'delivery_confirmation'
  <ProofUploadForm>
    <LinkInput />           ← if proof_type = link | code_repo
    <FileUpload />          ← if proof_type = document | video → uploads to IPFS
    <NotesTextarea />
  </ProofUploadForm>
  <SubmitButton />
  <ResubmissionWarning />   ← "You have 2 resubmissions remaining"
</MilestoneSubmitPage>
```

---

### Creator Application `/apply` (multi-step)

```
Step 1: Project Basics
  <ProjectNameInput />
  <CategorySelect />
  <DescriptionTextarea />
  <FundingGoalInput />
  <DurationSelect />        ← 30 / 60 / 90 days

Step 2: Team
  <TeamMemberForm> × N (add/remove)
    <NameInput />
    <RoleInput />
    <LinkedInInput />
    <GitHubInput />
    <PriorWorkTextarea />

Step 3: Milestones
  <MilestoneForm> × N (add/remove, min 3)
    <MilestoneNameInput />
    <MilestoneDescriptionTextarea />
    <ReleasePercentageInput />    ← must sum to 100%
    <ProofTypeSelect />
    <DeadlinePicker />

Step 4: Reward Tiers
  <TierForm> × N (add/remove, min 1 max 10)
    <TierNameInput />
    <TierPriceInput />
    <TierRewardDescription />
    <SupplyCapInput />
    <MaxPerWalletInput />         ← 0 = unlimited
    <RoyaltyBpsInput />           ← 0–10%, optional

Step 5: Terms
  <RefundRateInput />             ← 25–100%
  <RefundRateExplainer />
  <ReviewFeeDisplay />            ← $99/$199/$299 based on goal
  <TermsCheckbox />

Step 6: Review + Submit
  <ApplicationSummary />
  <SubmitButton />
  <PostSubmitExplainer />         ← "AI review takes 48-72 hours"
```

---

## 6. API CONTRACT SUMMARY (BY PAGE)

### `/campaigns` (Discovery)
```
GET /api/campaigns
  Query: ?status=live&category=tech&sort=newest&page=1&limit=12
  Response: { campaigns: CampaignSummary[], total: number, page: number }

CampaignSummary {
  id, title, creator_id, category, funding_goal, total_raised,
  ai_score, ai_score_public_summary, status, ends_at,
  milestone_count, milestones_verified_count,
  tier_price_min, tier_price_max
}
```

### `/campaigns/[id]` (Campaign Detail)
```
GET /api/campaigns/[id]
  Response: CampaignDetail (full object including tiers, milestones, creator)

GET /api/campaigns/[id]/milestones
  Response: Milestone[] (status, deadline, proof_ipfs_hash, ai_decision)

POST /api/campaigns/[id]/pledge/fiat-initiate   (auth required)
  Body: { tierId, amount }
  Response: { checkoutUrl: string }   ← Coinbase Commerce URL

POST /api/campaigns/[id]/pledge/crypto-confirm  (auth required)
  Body: { tierId, amount, txHash }
  Response: { pledgeId: string }
```

### `/marketplace` (Listings)
```
GET /api/marketplace
  Query: ?campaignId=&tierId=&minPrice=&maxPrice=&sort=lowest&page=1
  Response: { listings: ListingSummary[], total, page }

ListingSummary {
  id, token_id, campaign_id, campaign_title, tier_id, tier_name,
  reward_description, ask_price, original_price, refund_rate_bps,
  milestone_progress, estimated_delivery, campaign_ai_score, seller_id
}
```

### `/marketplace/[listingId]` (Listing Detail)
```
GET /api/marketplace/[listingId]
  Response: ListingDetail (full listing + campaign + tier details)

POST /api/marketplace/[listingId]/buy  (auth + wallet required)
  Body: { buyerWallet }
  Response: { txHash: string }   ← atomic settlement result
```

### `/dashboard` (Backer)
```
GET /api/user/backed
  Response: { pledges: UserPledge[] }

UserPledge {
  id, campaign_id, campaign_title, tier_name, amount_paid,
  status, token_id, created_at, campaign_status,
  milestone_progress, refund_amount_available
}
```

### `/dashboard/exit/[claimId]`
```
POST /api/user/exit/[claimId]
  Body: { path: 'refund' | 'marketplace', listingPrice?: number }
  Response: { success: true, refundAmount?: number, listingId?: string }
```

### `/creator/campaign/[id]/milestone/[n]/submit`
```
POST /api/campaigns/[id]/milestones/[n]/submit  (creator auth)
  Body: { proofType, proofLink?, proofIpfsHash?, notes }
  Response: { success: true, decision?: string }
```

### `/apply` (Creator Application)
```
POST /api/campaigns/apply  (creator auth + KYC)
  Body: CampaignApplicationPayload (full form data)
  Response: { campaignId: string, reviewEta: string }
```

### Webhooks (backend-only, no UI)
```
POST /api/webhooks/payment          ← Coinbase Commerce / Stripe completion
POST /api/webhooks/ai-review        ← AI review callback
POST /api/webhooks/chain-events     ← The Graph / Alchemy on-chain events
```

---

## 7. LEGAL COPY RULES (MANDATORY — BAKED INTO COMPONENTS)

These are non-negotiable per Counsel. Every component that shows relevant language must use this.

| ❌ Never Render | ✅ Always Render |
|----------------|----------------|
| "Invest" / "Investment" | "Back" / "Support" / "Fund" |
| "Return" / "Profit" | "Reward" / "Delivery" |
| "Exit your position" | "Sell your reward claim" |
| "Token value" | "Reward claim" |
| "Appreciate" / "Gain" | "Transfer" |
| "Portfolio" | "Backed campaigns" |
| "Yield" | "Reward" |
| "Early backers sell at premium" | *(don't say this at all)* |
| "Earn passive income from royalties" | "Receive compensation when your reward claims are transferred" |

**Hardcoded disclaimers (required on specific pages):**
- Campaign detail → "AI review is a quality filter, not a guarantee of delivery. Back campaigns at your own discretion."
- Exit flow marketplace path → "You are transferring your reward claim to another backer, not exiting an investment position."
- Marketplace listing card → No price charts, no floor price, no volume stats (V1)

---

## 8. IMPLEMENTATION CONCERNS

### Concern 1: Two Auth Systems Must Stay in Sync
The hardest frontend problem in this build. Supabase session and wagmi wallet state are independent. A user can:
- Have a Supabase session but no wallet connected
- Have a wallet connected but no Supabase session
- Have both

Recommend a single `useAuth()` hook that merges both:
```typescript
function useAuth() {
  const { data: session } = useSupabaseSession()
  const { address, isConnected } = useAccount()   // wagmi
  return {
    user: session?.user ?? null,
    wallet: isConnected ? address : null,
    canUseFiat: !!session?.user,
    canUseCrypto: !!session?.user && isConnected,
    canUseMarketplace: !!session?.user && isConnected,
    role: session?.user?.user_metadata?.role ?? null
  }
}
```

### Concern 2: Fiat Backer → Marketplace Upgrade Flow
A fiat backer who later wants to list on the marketplace needs to:
1. Connect a wallet for the first time
2. Have the platform link that wallet to their Supabase account
3. Then lazy mint their token to that wallet

This is a multi-step upgrade flow that needs its own UX (not just a single prompt). Design as a guided 3-step modal: "Connect wallet → Verify ownership → Your reward claim is ready to list."

### Concern 3: Milestone Tracker is Real-Time Data
Milestone status changes on-chain (and synced to Supabase via The Graph webhook). The milestone tracker on campaign detail pages should auto-refresh or use Supabase Realtime subscription so backers see status changes without page reload.

Use `useRealtimeSubscription` on the `milestones` table filtered by `campaign_id`.

### Concern 4: Exit Flow Must Never Default to One Path
The two-path exit (refund vs. marketplace) must always present both options with equal visual weight. No pre-selection. No default. Legal framing requires explicit choice. Don't let button placement or visual hierarchy push users toward either option.

### Concern 5: Pending On-Chain Transactions
When a backer submits a pledge (crypto path), the tx is pending for 1-10 seconds on Base. UI needs a pending state that:
- Shows "Transaction submitted..." while awaiting confirmation
- Polls/listens for confirmation (wagmi `useWaitForTransactionReceipt`)
- Updates Supabase record only after on-chain confirmation (via webhook, not optimistic)
- Handles failure case gracefully (tx reverted, gas too low)

### Concern 6: The Graph Latency
On-chain events indexed by The Graph have ~5-15 second latency. Milestone status, funding totals, and marketplace settlements won't be instant. Design for eventual consistency — show "updating..." states, don't assume instant reflection of on-chain actions.

### Concern 7: Campaign Application is Long
The 6-step creator application form has enough fields to be painful if users lose progress. Implement auto-save to localStorage (or Supabase drafts table) every step. The `campaign_application` Zustand store should persist to localStorage via `zustand/middleware/persist`.

### Concern 8: Marketplace V1 Scope
Per legal, V1 marketplace listings must NOT show: price history charts, floor price, volume statistics. Do not design these in. They're V2 features pending a securities opinion. If design templates are reused from a generic marketplace, these features need to be stripped.

---

## 9. PAGE → API → COMPONENT DEPENDENCY MAP

| Page | Primary API Calls | Key Components | Auth Required |
|------|------------------|----------------|---------------|
| `/` | `GET /api/campaigns?featured=true` | HeroSection, CampaignCard, HowItWorks | No |
| `/campaigns` | `GET /api/campaigns` | CampaignGrid, CampaignCard, Filters | No |
| `/campaigns/[id]` | `GET /api/campaigns/[id]`, `/milestones` | MilestoneTracker, TierCard, FundingPanel, BackingModal | Back action only |
| `/marketplace` | `GET /api/marketplace` | ListingGrid, ListingCard, Filters | No |
| `/marketplace/[id]` | `GET /api/marketplace/[id]` | ListingDetail, PurchasePanel | Buy action only |
| `/dashboard` | `GET /api/user/backed` | ClaimCard, ExitButton | ✅ |
| `/dashboard/exit/[id]` | `POST /api/user/exit/[id]` | ExitPathChoice, RefundConfirmStep, MarketplaceListStep | ✅ |
| `/creator/dashboard` | `GET /api/user/created` | CreatorCampaignCard | ✅ + creator role |
| `/creator/campaign/[id]` | `GET /api/campaigns/[id]`, `PUT /api/campaigns/[id]` | MilestoneTracker, FundingPanel | ✅ + creator role |
| `/creator/campaign/[id]/milestone/[n]/submit` | `POST /api/campaigns/[id]/milestones/[n]/submit` | ProofUploadForm | ✅ + creator role |
| `/apply` | `POST /api/campaigns/apply` | Multi-step ApplicationForm | ✅ + KYC |
| `/admin/*` | `/api/admin/*` | ReviewQueues, ApprovalControls | ✅ + admin role |

---

## 10. FOLDER STRUCTURE

```
/src
  /app
    /(public)
      /page.tsx                          → Homepage
      /campaigns
        /page.tsx                        → Discovery
        /[id]
          /page.tsx                      → Campaign Detail
      /marketplace
        /page.tsx                        → Marketplace
        /[listingId]
          /page.tsx                      → Listing Detail
      /how-it-works/page.tsx
      /for-creators/page.tsx
      /apply/page.tsx
    /(auth)
      /login/page.tsx
      /signup/page.tsx
    /(backer)
      /dashboard
        /page.tsx
        /campaign/[id]/page.tsx
        /exit/[claimId]/page.tsx
        /rewards/page.tsx
    /(creator)
      /creator
        /dashboard/page.tsx
        /campaign/[id]/page.tsx
        /campaign/[id]/milestone/[n]/submit/page.tsx
        /apply/page.tsx
    /(admin)
      /admin
        /campaigns/page.tsx
        /campaigns/[id]/page.tsx
        /milestones/page.tsx
        /marketplace/page.tsx
    /api
      /campaigns/route.ts
      /campaigns/[id]/route.ts
      /campaigns/[id]/pledge/crypto-confirm/route.ts
      /campaigns/[id]/pledge/fiat-initiate/route.ts
      /campaigns/[id]/milestones/route.ts
      /campaigns/[id]/milestones/[n]/submit/route.ts
      /campaigns/[id]/milestones/[n]/vote/route.ts
      /marketplace/route.ts
      /marketplace/list/route.ts
      /marketplace/[id]/buy/route.ts
      /marketplace/[id]/route.ts
      /user/backed/route.ts
      /user/created/route.ts
      /user/exit/[claimId]/route.ts
      /admin/campaigns/[id]/approve/route.ts
      /admin/campaigns/[id]/reject/route.ts
      /admin/milestones/[id]/verify/route.ts
      /admin/milestones/[id]/dispute/route.ts
      /admin/campaigns/[id]/fail/route.ts
      /webhooks/payment/route.ts
      /webhooks/ai-review/route.ts
      /webhooks/chain-events/route.ts

  /components
    /ui/                   ← shadcn/ui base components
    /campaigns/
      CampaignCard.tsx
      CampaignGrid.tsx
      MilestoneTracker.tsx
      FundingPanel.tsx
      TierCard.tsx
      BackingModal.tsx
      AIScoreBadge.tsx
    /marketplace/
      ListingCard.tsx
      ListingGrid.tsx
      PurchasePanel.tsx
    /exit/
      ExitFlowPage.tsx
      PathCard.tsx
      RefundConfirmStep.tsx
      MarketplaceListStep.tsx
    /forms/
      CampaignApplicationForm.tsx
      MilestoneProofForm.tsx
    /auth/
      WalletButton.tsx
      AuthButton.tsx
      WalletUpgradeModal.tsx   ← fiat → marketplace upgrade
    /layout/
      Header.tsx
      Footer.tsx

  /hooks
    useAuth.ts                 ← merged Supabase + wagmi state
    useCampaign.ts
    useMarketplace.ts
    usePledge.ts
    useExit.ts
    useRealtimeMilestones.ts

  /lib
    /supabase/
      client.ts
      server.ts
      middleware.ts
    /wagmi/
      config.ts
      chains.ts
    /query/
      queryClient.ts
      keys.ts
    /zod/
      campaignApplication.ts
      pledgeForm.ts
      milestoneProof.ts

  /store
    authStore.ts
    walletStore.ts
    exitFlowStore.ts
    applicationStore.ts

  /types
    campaign.ts
    marketplace.ts
    user.ts
    contracts.ts

  /constants
    legal-copy.ts           ← all legal strings in one place (never inline)
    routes.ts
```

---

*Prepared by Forge 🔥 — Perlantir AI Studio*
*Architecture review gate: complete. Ready for design.*
*Next: Nick designs from this spec → Maks implements*
