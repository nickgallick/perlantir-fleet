# FOUNDRY — MASTER BUILD MAP
**Version:** 1.3 (Forge Architecture Review Applied)
**Prepared by:** Chain ⛓️ (Blockchain Architect)
**Legal Clearance:** Counsel ⚖️ (2026-03-27 + 2026-03-28)
**Market Research:** Scout 🔍 (2026-03-28)
**Status:** Ready for MaksPM Orchestration → Board Review → Build
**Date:** 2026-03-28

### Changelog
- **v1.3 (2026-03-28):** Forge architecture review applied — 15 issues resolved: DB schema gaps fixed (campaign_tiers, milestones, marketplace_listings, users), refund pull pattern, token ID scheme clarified, royaltyInfo() spec, split pledge API routes, added missing webhooks, indexes + RLS defined, locked ABI requirement, milestone deadline enforcement. P0 (fiat on-ramp architecture) + 5 Nick decisions flagged as open blockers.
- **v1.2 (2026-03-28):** Added Fiat On-Ramp as V1 requirement (Scout research: blockchain must be invisible to mainstream backers)
- **v1.1 (2026-03-28):** Added Creator Royalty (ERC-2981, Counsel approved) + Per-Wallet Purchase Cap (anti-bot)

---

## TABLE OF CONTENTS
1. [Product Vision](#1-product-vision)
2. [What We're Building](#2-what-were-building)
3. [Complete User Flows](#3-complete-user-flows)
4. [Smart Contract Architecture](#4-smart-contract-architecture)
5. [Backend Architecture](#5-backend-architecture)
6. [Frontend Architecture](#6-frontend-architecture)
7. [AI Layer](#7-ai-layer)
8. [Secondary Marketplace](#8-secondary-marketplace)
9. [Database Schema](#9-database-schema)
10. [Infrastructure & DevOps](#10-infrastructure--devops)
11. [Security Plan](#11-security-plan)
12. [Revenue Model](#12-revenue-model)
13. [Build Phases](#13-build-phases)
14. [Agent Assignments](#14-agent-assignments)
15. [Open Questions Before Build](#15-open-questions-before-build)

---

## 1. PRODUCT VISION

### The Problem
Crowdfunding is broken in three ways:
1. **No accountability**: Creators get 100% of money upfront. They can ghost with no consequences.
2. **No exit**: Backers are locked in for years. If a project fails, they lose everything.
3. **No transparency**: Nobody knows how funds are being used or whether anything is actually being built.

### The Solution
**Foundry** is a blockchain-native crowdfunding platform where:
- Creators **earn** their funding by hitting milestones — money is never released upfront
- Backers can **exit at any time** by selling their reward claim on a secondary marketplace
- Everything is **on-chain and verifiable** — fund flows, milestone status, votes, all public
- An **AI layer** vets campaigns before launch and verifies milestone completion

### One-Line Pitch
*"The crowdfunding platform where creators prove it to earn it — and backers are never stuck."*

### Core Design Principle (Scout Research — 2026-03-28)
**Blockchain must be invisible to mainstream backers.** Every prior blockchain crowdfunding attempt (KickICO, WeiFund, ICO era) failed by leading with crypto instead of the benefit. Foundry is a crowdfunding product that happens to use blockchain — not a crypto product. Fiat card payments are V1, not V2. Wallets are optional unless the backer chooses the marketplace exit.

### What Makes This Different from Kickstarter

| Feature | Kickstarter | Foundry |
|---------|------------|---------|
| Fund release | All upfront | Milestone-gated escrow |
| Creator accountability | None | Creator stake + milestone verification |
| Backer exit | None — fully locked | Sell reward claim on marketplace |
| Transparency | Zero | Full on-chain fund tracking |
| Campaign quality | Self-selected | AI-gated before launch |
| Fraud recourse | None | Creator stake → backer refunds |
| Backer liquidity | None | Secondary marketplace |

---

## 2. WHAT WE'RE BUILDING

### Platform Components (6 Core Systems)

```
┌─────────────────────────────────────────────────────────────┐
│                        FOUNDRY PLATFORM                      │
├───────────────┬──────────────┬──────────────┬───────────────┤
│   Campaign    │   Escrow &   │  Secondary   │   AI Review   │
│   Discovery   │  Milestone   │ Marketplace  │    Layer      │
│   & Launch    │   System     │              │               │
├───────────────┴──────────────┴──────────────┴───────────────┤
│              Smart Contract Layer (Base Blockchain)          │
├─────────────────────────────────────────────────────────────┤
│              Backend API + Database (Supabase)               │
└─────────────────────────────────────────────────────────────┘
```

**System 1: Campaign Discovery & Launch**
- Browse live campaigns
- Creator application and AI review portal
- Campaign detail pages with live milestone tracker

**System 2: Escrow & Milestone System**
- Smart contract escrow per campaign
- Milestone submission and verification flow
- On-chain backer vote for disputed milestones

**System 3: Secondary Marketplace**
- Peer-to-peer reward claim trading
- Lazy mint flow (token created at listing, not at backing)
- Two-path exit: platform refund OR marketplace listing

**System 4: AI Review Layer**
- Automated campaign intake screening
- Milestone delivery verification
- Feasibility scoring (publicly visible per campaign)

**System 5: Creator Dashboard**
- Campaign management
- Milestone submission
- Fund tracking and release history

**System 6: Backer Dashboard**
- Active campaigns backed
- Exit options (refund or marketplace)
- Reward delivery confirmation

---

## 3. COMPLETE USER FLOWS

### Flow A: Creator Launches a Campaign

```
Creator registers (KYC required)
  ↓
Submits campaign application:
  - Project name, description, category
  - Team info (names, LinkedIn, GitHub, prior work)
  - Funding goal ($10K–$5M)
  - Campaign duration (30 / 60 / 90 days)
  - Reward tiers (minimum 1, maximum 10)
    → Tier: name, price, reward description, supply cap
  - Milestone schedule (minimum 3, maximum 10)
    → Milestone: name, description, % of escrow released, proof type required, deadline
  - Refund rate (creator-set, minimum 25%, displayed to backers)
  ↓
AI Review runs (automated, 48-72 hrs):
  - Feasibility score generated
  - Red flag scan complete
  ↓
  [REJECTED] → Rejection reason provided → Creator can revise and reapply
  [CONDITIONALLY APPROVED] → Creator makes requested changes → Re-review
  [APPROVED] → Creator proceeds to contract deployment
  ↓
Creator pays AI review fee ($99–$299, based on campaign size)
  ↓
Creator stakes performance bond (2–5% of funding goal in USDC)
  → Stake goes directly into CampaignEscrow.sol (not platform wallet)
  ↓
Campaign contract deployed:
  - CampaignEscrow.sol deployed (holds all backer funds + creator stake)
  - RewardToken.sol deployed (ERC-1155, one per campaign)
  - Milestone schedule written to contract (immutable after deployment)
  - Refund rate written to contract (immutable after deployment)
  ↓
Campaign goes live on platform
  - Feasibility score displayed
  - Milestone tracker visible
  - Funding goal and progress live
  - Campaign duration countdown begins
```

### Flow B: Backer Funds a Campaign

```
Backer browses campaigns
  ↓
Views campaign detail page:
  - Project description
  - AI feasibility score
  - Team info
  - Milestone schedule + current status
  - Funding progress
  - Reward tiers available
  - Refund rate (prominently displayed)
  ↓
Selects tier and backs campaign
  ↓
Chooses payment method:
  → Option A: **Crypto wallet** (RainbowKit/wagmi — existing crypto users)
     USDC sent directly from wallet → CampaignEscrow.sol
  → Option B: **Credit/debit card** (mainstream backers — blockchain invisible)
     Card charged via Coinbase Commerce or Stripe + Coinbase SDK
     Fiat converted to USDC on-ramp → USDC deposited to CampaignEscrow.sol automatically
     Backer never sees a wallet, never touches MetaMask
  → USDC goes directly to CampaignEscrow.sol (never touches platform wallet — both paths)
  → Supabase records: backer ID, campaign ID, tier ID, amount paid, timestamp, payment_method
  → No token minted at this point (lazy mint — token only created if marketplace listed)

  ⚠️ NOTE: Fiat on-ramp backers who later want to use the marketplace must connect/create a wallet at that point. Platform guides them through this only if they choose the marketplace exit path.
  ↓
Backer receives:
  - Confirmation screen
  - Off-chain reward claim record (visible in Backer Dashboard)
  - Campaign updates via email/notification
  ↓
Backer waits for campaign milestones and eventual reward delivery
```

### Flow C: Creator Hits a Milestone

```
Creator completes milestone work
  ↓
Submits milestone completion in Creator Dashboard:
  - Proof type (code repo, prototype video, beta link, delivery confirmation, etc.)
  - Submission uploads to IPFS (hash stored on-chain)
  - Timestamp recorded
  ↓
AI Milestone Verification runs (automated, 24-48 hrs):
  - Compares submitted proof vs. original milestone definition
  - Checks for consistency and completeness
  ↓
  [VERIFIED] → CampaignEscrow.sol releases milestone tranche to creator wallet
  [NEEDS MORE INFO] → Creator notified, can resubmit
  [DISPUTED] → On-chain backer vote triggered
  ↓
  [If Disputed]:
    - All current backers notified (email + on-chain event)
    - 72-hour voting window opens
    - Backers vote: Accept or Reject milestone
    - Majority vote determines outcome
    - Platform has tiebreaker in deadlocked vote
    - Result executed on-chain (release or reject)
  ↓
Fund release to creator:
  - Milestone % of escrow released to creator wallet
  - Platform 5% fee deducted at release (not from escrow — from release amount)
  - Milestone marked complete on-chain and in UI
  ↓
Campaign continues to next milestone
```

### Flow D: Backer Exits via Platform Refund

```
Backer decides to exit campaign
  ↓
Opens Backer Dashboard → selects campaign → "Exit This Campaign"
  ↓
Platform shows two options:
  Option A: "Get [refund rate]% back — receive $[calculated] to your wallet"
  Option B: "List on marketplace — set your own price, may recover more"
  ↓
Backer selects Option A (Platform Refund)
  ↓
Refund processed:
  - If campaign still active: refund from creator stake (if available)
  - If campaign abandoned: refund from slashed creator stake
  - Amount: original purchase price × refund rate (e.g., $100 paid × 50% = $50)
  - Capped at original purchase price (cannot receive more than paid)
  - Refund processed as USDC transfer: CampaignEscrow.sol → backer wallet
  ↓
Reward claim record marked "refunded" in Supabase
No token was ever minted
Campaign continues for remaining backers
```

### Flow E: Backer Exits via Marketplace

```
Backer decides to exit but wants more than the platform refund rate
  ↓
Opens Backer Dashboard → selects campaign → "Exit This Campaign"
  ↓
Backer selects Option B (List on Marketplace)
  ↓
Platform explains:
  "Your reward claim will be tokenized and listed. If sold, the buyer
   receives your reward. You receive the sale price. This may be above
   or below what you originally paid."
  ↓
Backer sets listing price and confirms
  ↓
Lazy mint triggers:
  - RewardToken.sol mints one ERC-1155 token for this reward claim
  - Token stores: tier ID, campaign ID, original purchase price (for refund cap)
  - Token transferred to backer's wallet
  ↓
Token listed on Marketplace.sol at backer's chosen price
  ↓
  [If sold]:
    - Atomic settlement: USDC from buyer wallet → seller wallet
    - Token transfers: seller wallet → buyer wallet
    - 2% platform fee deducted from seller proceeds
    - Supabase updates reward claim ownership to buyer
    - Original backer's reward claim record marked "transferred"
  ↓
  [If not sold]:
    - Backer can delist, adjust price, or wait
    - Token remains in backer wallet until sold or delisted
    - Delisted: token burned, reward claim reverts to off-chain record
```

### Flow F: Secondary Buyer on Marketplace

```
User browses Marketplace
  ↓
Views listed reward claims:
  - Campaign name and status
  - Reward description (what they'll receive)
  - Current campaign milestone progress
  - Original backing price vs. current ask
  - Refund rate (what they're protected at on failure)
  - Campaign delivery timeline
  ↓
Purchases a listing
  ↓
Atomic on-chain settlement:
  - USDC transfers from buyer to seller (minus 2% fee to platform)
  - ERC-1155 token transfers from seller to buyer
  - Both happen in same transaction — no counterparty risk
  ↓
Buyer now holds reward claim:
  - Visible in their Backer Dashboard
  - Eligible for reward delivery when campaign completes
  - Eligible for refund (at original backer's rate) if campaign fails
  - Can resell on marketplace at any time
```

### Flow G: Campaign Fails / Creator Abandons

```
Creator abandons campaign (or deadline passes with milestones incomplete)
  ↓
Platform (or backers via vote) declares campaign failed
  ↓
CampaignEscrow.sol enters failure state:
  - Creator stake locked for refund distribution
  - No further milestone releases possible
  ↓
Refunds processed:
  - All current reward claim holders (on-chain token holders + off-chain pledge holders)
  - Each refund = original purchase price × refund rate
  - Capped at original purchase price (no windfalls)
  - USDC transfers: CampaignEscrow.sol → each backer wallet
  ↓
If creator stake insufficient to cover all refunds:
  - Distributed pro-rata (everyone gets same % of their eligible refund)
  ↓
If creator stake surplus after all refunds:
  - Surplus sent to platform consumer protection reserve address (NOT to token holders)
  ↓
All active tokens burned
All off-chain pledge records marked "refunded" or "partially refunded"
Campaign closed
```

### Flow H: Campaign Delivers Successfully

```
All milestones verified and complete
  ↓
Final milestone tranche released to creator
  ↓
Creator ships rewards:
  - Physical products: standard fulfillment
  - Digital products: access credentials/keys delivered via platform
  - Services: creator contacts backers to fulfill
  ↓
Backers confirm receipt in dashboard (or auto-confirmed after 30-day window)
  ↓
All active reward tokens burned
Creator stake returned to creator wallet
Campaign marked "Delivered" permanently on-chain
```

---

## 4. SMART CONTRACT ARCHITECTURE

### Overview — 4 Contracts

```
CampaignFactory.sol
  ├── Deploys → CampaignEscrow.sol (one per campaign)
  └── Deploys → RewardToken.sol (one per campaign)

Marketplace.sol
  └── Interfaces with → RewardToken.sol (transfer, burn)
  └── Interfaces with → CampaignEscrow.sol (refund data)
```

---

### Contract 1: CampaignFactory.sol

**Purpose:** Registry and deployer for all campaigns. The only entry point for creating new campaigns.

**Key State:**
```solidity
address public admin;                          // Multi-sig (Safe)
address public platformFeeRecipient;           // Platform treasury
uint256 public maxTVL;                         // $10,000 USDC at launch (raise post-audit)
uint256 public totalActiveTVL;                 // Running sum of all active escrow
mapping(uint256 => address) public campaigns;  // campaignId → escrow address
mapping(uint256 => address) public tokens;     // campaignId → token address
uint256 public campaignCount;
```

**Key Functions:**
```solidity
// Called by platform (approved campaigns only) — deploys escrow + token pair
function createCampaign(
    address creator,
    uint256 fundingGoal,
    uint256 duration,
    uint256 creatorStake,
    uint256 refundRateBps,           // e.g., 5000 = 50%
    MilestoneConfig[] calldata milestones,
    TierConfig[] calldata tiers
) external onlyPlatform returns (uint256 campaignId)

// Admin: raise TVL cap after audit
function setMaxTVL(uint256 newMax) external onlyAdmin

// Called by escrow contracts to update TVL tracking
function updateTVL(int256 delta) external onlyCampaignContract

// View: check if a new campaign deposit would exceed TVL cap
function checkTVLRoom(uint256 amount) external view returns (bool)
```

**Access Control:**
- `onlyPlatform`: Platform backend wallet (approved campaigns only)
- `onlyAdmin`: Safe multi-sig (TVL cap changes, emergency pause)

---

### Contract 2: CampaignEscrow.sol

**Purpose:** Holds all funds for a single campaign. Releases to creator on milestone verification. Processes refunds on failure.

**Key State:**
```solidity
address public creator;
address public factory;
address public platformFeeRecipient;
uint256 public fundingGoal;
uint256 public totalRaised;
uint256 public creatorStake;
uint256 public refundRateBps;            // e.g., 5000 = 50%
uint256 public campaignDeadline;
CampaignStatus public status;            // Active, Funded, Delivering, Failed, Complete
Milestone[] public milestones;
mapping(address => uint256) public pledges;          // backer → total USDC paid
mapping(address => bool) public refunded;             // backer → refunded
uint256 public platformFeeBps;           // 500 = 5%
address public consumerProtectionReserve;
```

**Milestone Struct:**
```solidity
struct Milestone {
    string name;
    uint256 releaseBps;          // % of total escrow to release (must sum to 10000)
    uint256 deadline;
    bytes32 proofIpfsHash;       // Set when creator submits
    MilestoneStatus status;      // Pending, Submitted, Verified, Disputed, Failed
    bool fundsReleased;
}
```

**Key Functions:**
```solidity
// Backer deposits USDC directly (no platform wallet involved)
// Enforces maxPerWallet per tier — reverts if backer exceeds limit (anti-bot / anti-scalper)
function pledge(uint256 tierId, uint256 amount) external nonReentrant

// Platform calls after AI verification confirms milestone
function releaseMilestone(uint256 milestoneIndex) external onlyPlatform nonReentrant

// Creator submits milestone proof
function submitMilestoneProof(uint256 milestoneIndex, bytes32 ipfsHash) external onlyCreator

// PULL PATTERN — backer claims own refund (Forge P1: avoids gas limit bomb on large campaigns)
// Refund = pledges[backer] * refundRateBps / 10000, capped at original pledge amount
function claimRefund() external nonReentrant
// Replaces push-based processAllRefunds — no gas limit issues at any campaign size

// Platform declares campaign failed (or auto-triggers via Supabase cron on deadline miss)
function declareFailed() external onlyPlatform
// Sets status = FAILED, locks creator stake for refund claims, emits CampaignFailed event

// Creator retrieves stake after successful delivery
function returnCreatorStake() external onlyCreator

// Emergency pause (multi-sig only)
function pause() external onlyAdmin
function unpause() external onlyAdmin
```

**Fund Flow Rules (Enforced in Contract):**
- USDC flows: Backer → Contract (pledge)
- USDC flows: Contract → Creator (milestone release, minus platform fee)
- USDC flows: Contract → Backer (refund, capped at original price)
- USDC flows: Contract → Platform fee recipient (5% on milestone release)
- USDC flows: Contract → Consumer protection reserve (surplus creator stake after refunds)
- Platform wallet NEVER receives custody of user USDC

---

### Contract 3: RewardToken.sol (ERC-1155)

**Purpose:** Manages reward claim tokens for a single campaign. Lazy minted — only created when backer chooses marketplace exit.

**Key State:**
```solidity
address public campaign;             // Parent CampaignEscrow address
address public marketplace;          // Authorized marketplace contract
address public platform;             // Authorized platform minter
mapping(uint256 => TierConfig) public tiers;          // tierId → tier details
mapping(uint256 => uint256) public tierSupplyCap;     // tierId → max tokens
mapping(uint256 => uint256) public tierMinted;        // tierId → minted count
mapping(uint256 => uint256) public tokenTier;         // tokenId → tierId (Forge P2: resolves fungibility vs per-token price contradiction)
address public creatorWallet;                         // stored for ERC-2981 royaltyInfo() (Forge P2)
uint256 public nextTokenId;                           // each lazy mint gets unique tokenId for tracking + burn
// NOTE: tokens are NOT fungible across different minted instances despite same tierId
// All tokens in same tier have identical price (derived from tiers[tierId].price) but unique IDs
```

**Tier Config Struct:**
```solidity
struct TierConfig {
    string name;
    string rewardDescription;
    uint256 price;               // Fixed in USDC (no bonding curve)
    uint256 supplyCap;
    uint256 maxPerWallet;        // Anti-bot: max pledges per wallet per tier (0 = unlimited)
    uint256 royaltyBps;          // Creator royalty on secondary sales (0–1000 bps, enforced by Marketplace.sol)
    bool active;
}
```

**Key Functions:**
```solidity
// Lazy mint: called by platform when backer lists on marketplace
// Only callable by platform — not by backers directly
function lazyMint(
    address recipient,           // Backer's wallet
    uint256 tierId,
    uint256 originalPurchasePrice  // Stored for refund cap enforcement
) external onlyPlatform returns (uint256 tokenId)

// Called by marketplace on successful sale (transfer happens via standard ERC-1155)
// Called by platform on reward delivery confirmation — burns token
function burnOnDelivery(uint256 tokenId) external onlyPlatform

// Called by escrow on campaign failure — burn all outstanding tokens
function burnAll(uint256[] calldata tokenIds) external onlyEscrow

// View: get original purchase price for refund cap calculation
function getOriginalPrice(uint256 tokenId) external view returns (uint256)

// Standard ERC-1155 transfers (freely transferable)
// Inherited from OpenZeppelin ERC-1155
```

**Legal Constraint (enforced in code + comment):**
```solidity
// LEGAL: Per Counsel review 2026-03-27
// Tokens entitle holder to reward delivery or refund at original purchase price.
// No financial distributions to token holders beyond these two mechanisms.
// originalPrice[tokenId] is the CEILING for any refund — never a floor for distribution.
```

---

### Contract 4: Marketplace.sol

**Purpose:** Peer-to-peer listing and settlement for reward claim tokens. Atomic swap — token and payment in same transaction.

**Key State:**
```solidity
address public platform;
address public platformFeeRecipient;
uint256 public platformFeeBps;          // 200 = 2%
mapping(uint256 => Listing) public listings;  // listingId → listing details
uint256 public listingCount;
```

**Listing Struct:**
```solidity
struct Listing {
    address seller;
    address tokenContract;       // RewardToken contract address
    uint256 tokenId;
    uint256 price;               // USDC ask price
    bool active;
    uint256 createdAt;
}
```

**Key Functions:**
```solidity
// Seller lists token (must hold token and have approved marketplace)
function createListing(
    address tokenContract,
    uint256 tokenId,
    uint256 price
) external returns (uint256 listingId)

// Buyer purchases listing — atomic settlement
function purchase(uint256 listingId) external nonReentrant
// 1. Transfer USDC from buyer to seller (minus 2% fee)
// 2. Transfer fee to platform fee recipient
// 3. Transfer ERC-1155 token from seller to buyer
// 4. All in one transaction — no partial fills, no custody

// Seller cancels listing
function cancelListing(uint256 listingId) external

// Admin: update fee (only admin, bounded by max fee cap)
function setFee(uint256 newFeeBps) external onlyAdmin
```

**Royalty Settlement (ERC-2981 — Counsel Approved):**
- `purchase()` calls `RewardToken.royaltyInfo(tokenId, salePrice)` to get creator royalty amount
- Royalty paid atomically to creator wallet in same transaction as sale settlement
- **Hardcoded max: 1000 bps (10%)** — contract rejects any royalty above this at campaign creation
- Settlement order: buyer USDC → seller (ask - royalty - 2% platform fee) + creator (royalty) + platform (2% fee)

**Security Notes:**
- Reentrancy guard on `purchase()`
- Atomic swap: if any transfer fails, entire transaction reverts
- Platform wallet never holds USDC during settlement
- No order book — simple listing model for V1

---

### Contract Security Requirements

**All Contracts Must Have:**
- [ ] UUPS upgradeable proxy (OpenZeppelin) — critical bug fix capability
- [ ] Multi-sig (Safe) as admin — no single key controls funds
- [ ] `ReentrancyGuard` on all fund-moving functions
- [ ] `Pausable` on CampaignEscrow and Marketplace (emergency stop)
- [ ] Access control: `onlyPlatform`, `onlyAdmin`, `onlyCreator` modifiers
- [ ] Events on every state change (for subgraph indexing)
- [ ] USDC SafeERC20 for all token transfers
- [ ] Input validation: zero-address checks, amount > 0, deadline > block.timestamp

**Testing Requirements (Foundry):**
- [ ] Unit tests: every function, every branch
- [ ] Fuzz tests: pledge amounts, milestone percentages, refund calculations
- [ ] Invariant tests:
  - `totalRaised == sum of all pledges`
  - `escrow balance >= totalRaised - releasedAmount`
  - `creator can never receive > (totalRaised - platformFees - refunds)`
  - `no backer refund ever exceeds their original pledge`
- [ ] Fork tests: Base mainnet fork, real USDC
- [ ] Integration tests: full campaign lifecycle (create → fund → milestone → deliver)

**External Audit:**
- Code4rena or Sherlock audit before mainnet
- TVL cap ($10K hard limit in CampaignFactory) active until audit clears
- Audit scope: all 4 contracts + integration tests

---

## 5. BACKEND ARCHITECTURE

### Stack
- **Framework:** Next.js 14 App Router (API routes)
- **Database:** Supabase (Postgres)
- **Auth:** Supabase Auth + wallet signature verification
- **Storage:** Supabase Storage (campaign images) + IPFS (milestone proof documents)
- **AI:** Claude API (campaign review + milestone verification)
- **Email:** Resend (transactional emails)
- **Jobs:** Supabase Edge Functions (cron — milestone deadline checks)

### Key API Routes

**Campaign Routes:**
```
POST   /api/campaigns/apply          → Submit campaign application
GET    /api/campaigns                → List campaigns (paginated, filtered)
GET    /api/campaigns/[id]           → Campaign detail
POST   /api/campaigns/[id]/pledge/crypto-confirm  → Record pledge after on-chain tx confirmed (Forge P2)
POST   /api/campaigns/[id]/pledge/fiat-initiate   → Initiate Coinbase Commerce charge (fiat path) (Forge P2)
GET    /api/campaigns/[id]/milestones → Milestone status
POST   /api/campaigns/[id]/milestones/[n]/submit → Creator submits proof
POST   /api/campaigns/[id]/milestones/[n]/vote   → Backer votes on disputed milestone
```

**Marketplace Routes:**
```
GET    /api/marketplace              → Browse listings (filtered by campaign, tier, price)
POST   /api/marketplace/list         → Backer lists reward claim (triggers lazy mint)
POST   /api/marketplace/[id]/buy     → Purchase listing
DELETE /api/marketplace/[id]         → Cancel listing
```

**User Routes:**
```
GET    /api/user/backed              → Backer's active pledges and claims
GET    /api/user/created             → Creator's campaigns
POST   /api/user/exit/[claimId]      → Request refund OR marketplace listing
```

**Webhook Routes:**
```
POST   /api/webhooks/ai-review       → AI review completion callback
POST   /api/webhooks/payment         → Coinbase Commerce / Stripe fiat charge completion (Forge P2)
POST   /api/webhooks/chain-events    → On-chain event listener (via The Graph or Alchemy webhooks)
POST   /api/admin/ai/review/trigger  → Platform triggers AI review job (async) (Forge P2)
```

**Admin Routes (platform use only):**
```
POST   /api/admin/campaigns/[id]/approve    → Approve campaign after AI review
POST   /api/admin/campaigns/[id]/reject     → Reject campaign
POST   /api/admin/milestones/[id]/verify    → Mark milestone verified (after AI check)
POST   /api/admin/milestones/[id]/dispute   → Flag milestone as disputed
POST   /api/admin/campaigns/[id]/fail       → Declare campaign failed
```

### On-Chain Event Handling
- **The Graph subgraph** indexes all contract events
- Backend polls subgraph for state changes
- Key events to index:
  - `CampaignCreated`, `PledgeReceived`, `MilestoneReleased`
  - `MilestoneDisputed`, `VoteCast`, `CampaignFailed`
  - `TokenMinted`, `TokenTransferred`, `TokenBurned`
  - `ListingCreated`, `ListingSold`, `ListingCancelled`
  - `RefundProcessed`

---

## 6. FRONTEND ARCHITECTURE

### Stack
- **Framework:** Next.js 14 App Router
- **Styling:** Tailwind CSS + shadcn/ui
- **Web3:** wagmi v2 + viem + RainbowKit (crypto wallet path)
- **Fiat on-ramp:** Coinbase Commerce or Stripe + Coinbase SDK on Base (card payment path)
- **State:** React Query (server state) + Zustand (client state)
- **Forms:** React Hook Form + Zod validation

### Page Map

**Public Pages:**
```
/                           → Homepage (hero, how it works, featured campaigns)
/campaigns                  → Campaign discovery (browse, filter, search)
/campaigns/[id]             → Campaign detail (full info, milestone tracker, tiers)
/marketplace                → Secondary marketplace (browse reward claim listings)
/marketplace/[listingId]    → Listing detail
/how-it-works               → Explainer page (backers)
/for-creators               → Creator explainer page
/apply                      → Creator application form
```

**Authenticated Backer Pages:**
```
/dashboard                  → Backer overview (backed campaigns, claims, pending rewards)
/dashboard/campaign/[id]    → Campaign detail from backer view (exit options)
/dashboard/exit/[claimId]   → Exit flow (refund vs. marketplace)
/dashboard/rewards          → Delivered rewards history
```

**Authenticated Creator Pages:**
```
/creator/dashboard          → Creator overview (campaigns, milestone status, funds received)
/creator/campaign/[id]      → Campaign management (submit milestones, track funding)
/creator/campaign/[id]/milestone/[n]/submit → Milestone proof submission
/creator/apply              → Campaign application (multi-step)
```

**Admin Pages (internal):**
```
/admin/campaigns            → All campaigns, review queue
/admin/campaigns/[id]       → Review a campaign application
/admin/milestones           → Milestone verification queue
/admin/marketplace          → Marketplace overview
```

### Key UI Components

**Campaign Card** — displays in discovery grid:
- Campaign name, creator, category
- AI feasibility score badge
- Funding progress bar
- Days remaining
- Earliest milestone status
- Tier price range

**Milestone Tracker** — displays on campaign detail:
- Visual timeline of all milestones
- Status per milestone (Pending / Submitted / Verified / Disputed / Failed)
- % of funds locked per milestone
- Proof link (IPFS) when available

**Exit Flow Modal** — critical legal UX:
- Explicitly shows two options (never one merged path)
- Option A: Platform Refund — shows exact USDC amount they'll receive
- Option B: Marketplace — shows refund rate as floor, explains market pricing
- Legal copy: "You are transferring your reward claim, not an investment position"

**Marketplace Listing Card:**
- Reward description
- Campaign name + milestone status
- Original price vs. current ask
- Refund protection rate
- Estimated delivery timeline
- Buy button

### Legal Copy Requirements (All UI)
Per Counsel — mandatory language rules:

| ❌ Never Use | ✅ Always Use |
|-------------|--------------|
| Invest / Investment | Back / Support |
| Return / Profit | Reward / Delivery |
| Exit your position | Sell your reward claim |
| Token value | Reward claim |
| Appreciate / Gain | Transfer |
| Portfolio | Backed campaigns |
| Yield | Reward |

---

## 7. AI LAYER

### System 1: Campaign Intake Review

**Trigger:** Creator submits campaign application
**Runtime:** Async (48-72 hr SLA displayed to creator)
**Model:** Claude API (claude-opus-4-6 for best reasoning on edge cases)

**Input (from application):**
- Project description
- Team info (names, links, prior work)
- Funding goal and budget breakdown
- Milestone schedule with deliverables
- Reward tier descriptions

**Review Dimensions:**
```
1. FEASIBILITY (0-25 pts)
   - Can this actually be built/made with the stated budget and timeline?
   - Is the milestone schedule realistic?
   - Are the deliverables specific and verifiable?

2. TEAM CREDIBILITY (0-25 pts)
   - Can we verify team members exist and have relevant experience?
   - Prior shipped products? Public profiles?
   - Anonymous team = lower score (not disqualifying but flagged)

3. RED FLAG SCAN (0-25 pts)
   - Plagiarized description?
   - Identical/recycled prior campaign?
   - Promises physically impossible outcomes?
   - Vague deliverables designed to make any milestone "complete"?
   - Price wildly disconnected from described work?

4. MARKET VIABILITY (0-25 pts)
   - Is there an obvious audience for this?
   - Is the reward tier pricing reasonable vs. market?
   - Has this exact product failed multiple times before?
```

**Output:**
```json
{
  "decision": "APPROVED | CONDITIONAL | REJECTED",
  "score": 82,
  "score_breakdown": {
    "feasibility": 22,
    "team_credibility": 20,
    "red_flag_scan": 23,
    "market_viability": 17
  },
  "conditions": ["Clarify milestone 3 deliverable — currently too vague to verify"],
  "rejection_reason": null,
  "red_flags": [],
  "public_summary": "Project shows a realistic timeline and credible team with prior shipped work. Milestone 3 needs clearer definition."
}
```

**What's Displayed Publicly:**
- Overall score (e.g., "AI Feasibility Score: 82/100")
- Public summary (plain English, no red flag details)
- Disclaimer: "AI review is a quality filter, not a guarantee of delivery"

**What's NOT Displayed:**
- Breakdown scores
- Internal red flag details
- Rejection reasons (shown only to creator)

---

### System 2: Milestone Verification

**Trigger:** Creator submits milestone completion proof
**Runtime:** Async (24-48 hr SLA)
**Model:** Claude API

**Input:**
- Original milestone definition (name, description, proof type required)
- Creator-submitted proof (IPFS hash → fetched document/link/media)
- Campaign context (what the project is, prior milestones)

**Verification Logic:**
```
1. Does the proof match the proof type required?
   (e.g., milestone requires "working beta link" — did creator submit a link?)

2. Does the proof demonstrate the stated deliverable was completed?
   (e.g., "complete user authentication system" — does the submitted code/demo show this?)

3. Is the proof authentic (not recycled, not irrelevant)?

4. Are there obvious red flags suggesting the milestone wasn't genuinely completed?
```

**Output:**
```json
{
  "decision": "VERIFIED | NEEDS_MORE_INFO | DISPUTED",
  "confidence": 0.91,
  "reasoning": "Creator submitted a working demo link. Authentication flow is functional per review. Login, logout, and session persistence verified.",
  "missing": null,
  "dispute_reason": null
}
```

**Decision Routing:**
- `VERIFIED` → CampaignEscrow.sol `releaseMilestone()` called by platform
- `NEEDS_MORE_INFO` → Creator notified, can resubmit (max 2 resubmissions)
- `DISPUTED` → On-chain backer vote triggered

---

## 8. SECONDARY MARKETPLACE

### Design Principles
- Peer-to-peer only — platform facilitates but never takes custody
- Simple listing model (no order book, no AMM) for V1
- Atomic settlement — no escrow period, instant finality
- Display campaign health clearly — buyers make informed decisions

### Marketplace Browse Page
**Filters:**
- Category (tech, games, physical goods, creative, etc.)
- Campaign milestone status (all milestones green vs. one+ at risk)
- Price range (ask price)
- Time to estimated delivery
- Refund protection rate

**Sort Options:**
- Newest listings
- Lowest ask
- Highest refund protection
- Closest to delivery

**What Each Listing Shows:**
- Reward description ("1x Premium Edition Hardcover Book")
- Campaign name and status
- Milestone progress (visual tracker, e.g., "2 of 4 milestones complete")
- Original backing price vs. current ask
- Refund rate (e.g., "50% refund protection if campaign fails")
- Estimated delivery window
- Campaign AI feasibility score

**What Listings Do NOT Show (V1):**
- Price history charts
- Volume statistics
- Floor price analytics
- Any investment-oriented metrics
(These can be added in V2 after securities opinion obtained)

### Settlement Flow (On-Chain)
```
Buyer clicks "Buy This Claim"
  ↓
Platform checks: listing still active, buyer has sufficient USDC
  ↓
Buyer approves USDC spend to Marketplace.sol
  ↓
Buyer calls Marketplace.sol.purchase(listingId)
  ↓
In single atomic transaction:
  1. USDC transfers: buyer wallet → seller wallet (98%)
  2. USDC transfers: buyer wallet → platform fee recipient (2%)
  3. ERC-1155 token transfers: seller wallet → buyer wallet
  ↓
If any step fails: entire transaction reverts (no partial state)
  ↓
Supabase updated: reward claim ownership transferred to buyer
Email confirmation to both buyer and seller
```

---

## 9. DATABASE SCHEMA

### Core Tables (Supabase / Postgres)

```sql
-- Users (creators and backers)
users
  id uuid PRIMARY KEY
  wallet_address text UNIQUE
  email text
  display_name text          -- (Forge P3)
  avatar_url text            -- (Forge P3)
  bio text                   -- (Forge P3)
  role text[] -- ['backer', 'creator', 'admin']
  kyc_status text -- pending | approved | rejected (creators only)
  kyc_verified_at timestamptz
  created_at timestamptz

-- Campaigns
campaigns
  id uuid PRIMARY KEY
  creator_id uuid REFERENCES users(id)
  contract_address text UNIQUE -- deployed escrow contract
  token_contract_address text UNIQUE -- deployed RewardToken contract
  title text
  description text
  category text
  funding_goal numeric
  duration_days int
  refund_rate_bps int -- e.g., 5000 = 50%
  creator_stake numeric
  ai_score int
  ai_score_public_summary text
  status text -- draft | under_review | approved | live | funded | delivering | complete | failed
  starts_at timestamptz
  ends_at timestamptz
  created_at timestamptz

-- Reward Tiers
campaign_tiers
  id uuid PRIMARY KEY
  campaign_id uuid REFERENCES campaigns(id)
  tier_index int -- matches contract tierId
  name text
  description text
  price numeric -- USDC
  supply_cap int
  minted_count int -- tracked off-chain, validated against contract
  max_per_wallet int NOT NULL DEFAULT 0 -- 0 = unlimited (Forge P1, Change 9)
  royalty_bps int NOT NULL DEFAULT 0    -- 0–1000 bps creator royalty (Forge P1, Change 8)
  active bool

-- Milestones
milestones
  id uuid PRIMARY KEY
  campaign_id uuid REFERENCES campaigns(id)
  milestone_index int -- matches contract milestoneIndex
  name text
  description text
  proof_type text -- 'link' | 'document' | 'video' | 'code_repo' | 'delivery_confirmation'
  release_bps int -- % of escrow to release
  deadline timestamptz
  status text -- pending | submitted | verified | disputed | failed
  proof_ipfs_hash text
  ai_decision text
  ai_reasoning text
  resubmission_count int DEFAULT 0        -- max 2 resubmissions allowed (Forge P3)
  dispute_vote_deadline timestamptz       -- 72-hour voting window end (Forge P3)
  dispute_result text                     -- final vote outcome (Forge P3)
  submitted_at timestamptz
  verified_at timestamptz

-- Pledges (off-chain record — source of truth for non-tokenized claims)
pledges
  id uuid PRIMARY KEY
  user_id uuid REFERENCES users(id)
  campaign_id uuid REFERENCES campaigns(id)
  tier_id uuid REFERENCES campaign_tiers(id)
  amount_paid numeric -- USDC
  tx_hash text -- on-chain pledge transaction
  payment_method text -- 'crypto' | 'fiat'
  fiat_payment_id text -- Coinbase Commerce or Stripe payment ID (fiat path only)
  wallet_address text -- NULL for fiat backers until they connect wallet
  status text -- active | refunded | tokenized | delivered
  token_id text -- set when lazy minted
  created_at timestamptz

-- Marketplace Listings
marketplace_listings
  id uuid PRIMARY KEY
  pledge_id uuid REFERENCES pledges(id)
  campaign_id uuid REFERENCES campaigns(id)  -- avoid join for browse (Forge P3)
  tier_id uuid REFERENCES campaign_tiers(id) -- tier-based filtering (Forge P3)
  token_contract text
  token_id text
  seller_id uuid REFERENCES users(id)
  ask_price numeric
  original_price numeric                     -- display "you paid $X, asking $Y" (Forge P3)
  status text -- active | sold | cancelled
  on_chain_listing_id int -- Marketplace.sol listingId
  created_at timestamptz
  sold_at timestamptz
  buyer_id uuid REFERENCES users(id)
  sale_price numeric

-- Backer Votes (on disputed milestones)
milestone_votes
  id uuid PRIMARY KEY
  milestone_id uuid REFERENCES milestones(id)
  voter_id uuid REFERENCES users(id)
  vote text -- 'accept' | 'reject'
  tx_hash text
  voted_at timestamptz

-- AI Review Log
ai_reviews
  id uuid PRIMARY KEY
  campaign_id uuid REFERENCES campaigns(id)
  review_type text -- 'intake' | 'milestone'
  milestone_id uuid REFERENCES milestones(id)
  input_data jsonb
  output_data jsonb
  decision text
  score int
  created_at timestamptz
```

### Required Indexes (Forge P3 — add to migration)
```sql
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_creator_id ON campaigns(creator_id);
CREATE INDEX idx_pledges_user_id ON pledges(user_id);
CREATE INDEX idx_pledges_campaign_id ON pledges(campaign_id);
CREATE INDEX idx_pledges_status ON pledges(status);
CREATE INDEX idx_milestones_campaign_id ON milestones(campaign_id);
CREATE INDEX idx_marketplace_listings_status ON marketplace_listings(status);
CREATE INDEX idx_marketplace_listings_campaign_id ON marketplace_listings(campaign_id);
CREATE UNIQUE INDEX ON milestone_votes(milestone_id, voter_id); -- prevent double voting
```

### Required RLS Policies (Forge P3 — minimum for launch)
```
campaigns:           SELECT = public | INSERT/UPDATE = creator (user_id = auth.uid()) only
pledges:             SELECT = own only (user_id = auth.uid()) | INSERT/UPDATE = service role only
milestone_votes:     SELECT = public | INSERT = own only | UPDATE = never
ai_reviews:          SELECT = campaign owner + admin only (contains internal scoring)
marketplace_listings: SELECT = public | INSERT/UPDATE = seller only
```

---

## 10. INFRASTRUCTURE & DEVOPS

### Environments
- **Local:** Docker Compose (Next.js + Supabase local + Anvil local chain)
- **Staging:** Vercel preview + Supabase staging project + Base Sepolia testnet
- **Production:** Vercel + Supabase production + Base mainnet

### Blockchain Infrastructure
- **RPC:** Alchemy (Base mainnet + Base Sepolia)
- **Indexing:** The Graph (subgraph deployed to The Graph Studio)
- **Contract verification:** Basescan API
- **Treasury:** Safe multisig (3-of-5 for production admin)
- **Monitoring:** OpenZeppelin Defender (transaction monitoring + alerts)

### Key Environment Variables
```
# Blockchain
ALCHEMY_BASE_MAINNET_RPC=
ALCHEMY_BASE_SEPOLIA_RPC=
BASESCAN_API_KEY=
DEPLOYER_PRIVATE_KEY=       (never in repo — Defender or hardware wallet for prod)

# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# AI
ANTHROPIC_API_KEY=

# Platform
PLATFORM_WALLET_ADDRESS=    (authorized minter / platform role in contracts)
PLATFORM_FEE_RECIPIENT=     (treasury address — Safe multisig)
CONSUMER_PROTECTION_RESERVE= (separate Safe address for failed campaign surplus)

# Email
RESEND_API_KEY=
```

### Deployment Sequence (Mainnet)
```
1. Deploy Safe multisig (3-of-5 signers)
2. Deploy Marketplace.sol (UUPS proxy)
3. Deploy CampaignFactory.sol (UUPS proxy, set admin = Safe)
4. Verify all contracts on Basescan
5. Deploy The Graph subgraph
6. Configure Alchemy webhooks for on-chain events
7. Set up OpenZeppelin Defender monitoring rules
8. TVL cap = $10,000 USDC (active until audit complete)
9. Deploy frontend to Vercel
10. Smoke test: full campaign lifecycle on mainnet (small test campaign)
11. Open to public
```

---

## 11. SECURITY PLAN

### Smart Contract Security
- [ ] Slither static analysis (before audit)
- [ ] Echidna fuzz testing (campaign escrow invariants)
- [ ] Full Foundry test suite (unit + fuzz + invariant + fork)
- [ ] External audit (Code4rena or Sherlock) — mandatory before mainnet
- [ ] TVL cap ($10K) enforced until audit clears
- [ ] Multi-sig for all admin functions (no single point of failure)
- [ ] UUPS upgradeable (critical bug fix path, governed by multi-sig)

### Application Security
- [ ] Wallet signature verification for all authenticated actions
- [ ] Creator KYC before campaign deployment
- [ ] Platform wallet (minter role) is a separate hot wallet — minimum USDC held
- [ ] API routes: auth checks on all non-public endpoints
- [ ] Input sanitization on all user-submitted content
- [ ] Rate limiting on AI review submissions
- [ ] IPFS content pinning for milestone proof permanence

### Operational Security
- [ ] Deployer private key: hardware wallet (Ledger) for mainnet — never in any repo
- [ ] Safe multi-sig: 3-of-5 minimum for production admin actions
- [ ] OpenZeppelin Defender monitoring: alert on large fund movements
- [ ] Seal 911 contact: t.me/seal_911_bot (exploit emergency response)
- [ ] Incident response plan documented before launch

---

## 12. REVENUE MODEL

| Revenue Source | Rate | Trigger | Who Pays |
|---------------|------|---------|----------|
| Primary campaign fee | 5% | On each milestone release | Creator (deducted from release) |
| Secondary marketplace fee | 2% | On each marketplace sale | Seller (deducted from proceeds) |
| AI review fee | $99–$299 | At campaign application | Creator |

**AI Review Fee Tiers:**
- $99: Campaigns up to $50K goal
- $199: Campaigns $50K–$500K goal
- $299: Campaigns over $500K goal

**No platform token. No yield products. No revenue sharing with backers.**

### Creator Royalty on Secondary Sales (Counsel Approved — 2026-03-28)
Creators may set a royalty % (0–10%) at campaign creation. Paid to creator wallet automatically on every secondary marketplace sale via ERC-2981.

| Source | Rate | Trigger | Who Pays |
|--------|------|---------|----------|
| Creator royalty | 0–10% (creator-set) | Every secondary sale | Deducted from seller proceeds |

**Legal conditions (Counsel — mandatory):**
- Max 10% cap enforced **in Marketplace.sol** (hardcoded 1000 bps) — not just policy
- Language rules for all creator-facing copy:

| ❌ Never Say | ✅ Always Say |
|-------------|--------------|
| "Earn passive income from secondary sales" | "Receive compensation when your reward claims are transferred" |
| "Royalty revenue stream" | "Creator royalty on transfers" |
| "Monetize your token" | "Ongoing creator compensation" |
| "Secondary market earnings" | "Transfer royalty" |

### Revenue Projections (Conservative)
- 10 campaigns/month × avg $50K goal × 3 milestones = $7,500/mo primary fees
- 20 marketplace transactions/month × avg $150 = $60/mo secondary fees
- 10 AI reviews/month × avg $150 = $1,500/mo review fees
- **Month 1-3 total: ~$9,000/mo** (conservative, assumes small launch)

---

## 13. BUILD PHASES

### Phase 0: Pre-Build (Complete Before Any Code)
**Owner:** MaksPM to coordinate
- [ ] Nick approves this document
- [ ] Counsel confirms legal framework is complete
- [ ] Pixel designs full UI (all pages, all flows) — Figma or Stitch
- [ ] Forge reviews smart contract architecture (this document, Section 4)
- [ ] Nick answers open questions (Section 15)
- [ ] Domain and branding decided (working title: Foundry)
- [ ] Supabase project created (staging)
- [ ] Alchemy account + Base Sepolia RPC configured
- [ ] Safe multisig deployed on Base Sepolia (testnet)
- [ ] Deployer wallet funded (Base Sepolia ETH for gas)

---

### Phase 1: Smart Contracts (Chain leads — 2-3 weeks)
**Owner:** Chain
**Gate:** Forge architecture review → Chain builds

**Deliverables:**
- [ ] Foundry project initialized
- [ ] CampaignFactory.sol (with TVL cap)
- [ ] CampaignEscrow.sol (with refund model, milestone logic)
- [ ] RewardToken.sol (ERC-1155, lazy mint, original price storage)
- [ ] Marketplace.sol (listing, atomic settlement, 2% fee)
- [ ] Full Foundry test suite (unit + fuzz + invariant + fork)
- [ ] Slither + Echidna analysis run and findings addressed
- [ ] Deployed to Base Sepolia (testnet)
- [ ] Contracts verified on Basescan Sepolia
- [ ] Integration test: full lifecycle on testnet
- [ ] **Locked ABI spec published** (interfaces only) before Maks starts Phase 2 — any ABI change requires formal flag to Maks (Forge P2)
- [ ] Milestone deadline enforcement: Supabase cron job calls `declareFailed()` when deadline passes (Forge P3)

**Forge review gate before Phase 2.**

---

### Phase 2: Backend (Maks leads — 2-3 weeks, parallel to Phase 1)
**Owner:** Maks
**Can start parallel with Phase 1 using mock contract addresses**

**Deliverables:**
- [ ] Next.js 14 project initialized
- [ ] Supabase schema deployed (all tables from Section 9)
- [ ] All API routes implemented (Section 5)
- [ ] AI review integration (Claude API — campaign intake + milestone verification)
- [ ] Fiat on-ramp integration (Coinbase Commerce or Stripe + Coinbase SDK — card → USDC → escrow)
- [ ] IPFS upload integration (milestone proof storage)
- [ ] The Graph subgraph deployed (Base Sepolia)
- [ ] Email notifications (Resend — campaign updates, milestone alerts)
- [ ] Platform wallet integration (lazy mint trigger, milestone release calls)
- [ ] Creator KYC flow (basic — manual review V1, can automate later)

**Forge code review gate before Phase 3.**

---

### Phase 3: Frontend (Maks + Pixel leads — 2-3 weeks)
**Owner:** Maks (implementation) — Pixel designs delivered before this phase starts

**Deliverables:**
- [ ] All public pages (homepage, discovery, campaign detail, marketplace)
- [ ] Backer dashboard (pledges, exit flow — both paths clearly separated)
- [ ] Creator dashboard (campaign management, milestone submission)
- [ ] RainbowKit wallet connect integration (crypto path)
- [ ] Fiat payment flow (card → Coinbase Commerce/Stripe → USDC → escrow, blockchain invisible)
- [ ] Wallet prompt only shown to fiat backers who choose marketplace exit
- [ ] wagmi hooks for all on-chain interactions
- [ ] Legal copy rules implemented throughout (Section 6 language table)
- [ ] Exit flow modal (two explicit paths, legal framing)
- [ ] Mobile responsive (all pages)
- [ ] Error states and loading states on all async operations

**Forge code review gate before Phase 4.**

---

### Phase 4: Integration & Testing (All hands — 1-2 weeks)
**Owner:** MaksPM coordinates, Maks + Chain execute

**Deliverables:**
- [ ] Full E2E test on Base Sepolia:
  - Creator applies → AI review → approved → stake → deploy → live
  - Backer pledges → sees dashboard
  - Creator submits milestone → AI verifies → funds released
  - Backer exits via refund
  - Backer exits via marketplace → lazy mint → listed → sold
  - Campaign failure → refunds processed
- [ ] TVL cap confirmed working in contract
- [ ] Multi-sig admin functions tested
- [ ] OpenZeppelin Defender monitoring configured
- [ ] Performance testing (API response times)
- [ ] Security review (Forge + Chain)

---

### Phase 5: Audit & Hardening (External — 4-6 weeks)
**Owner:** Chain coordinates

**Deliverables:**
- [ ] Audit submitted to Code4rena or Sherlock
- [ ] All audit findings addressed (CRITICAL and HIGH mandatory)
- [ ] MEDIUM findings reviewed and addressed or documented
- [ ] Contracts re-deployed on Base Sepolia post-audit
- [ ] Final integration test post-audit

---

### Phase 6: Mainnet Launch (Launch leads GTM)
**Owner:** Launch agent coordinates GTM, Chain coordinates contract deployment

**Deliverables:**
- [ ] All contracts deployed to Base mainnet
- [ ] Verified on Basescan
- [ ] TVL cap active ($10,000 USDC)
- [ ] Safe multisig live (3-of-5)
- [ ] Defender monitoring active
- [ ] First 3 campaigns seeded (handpicked, vetted, high quality)
- [ ] Launch coordinates: press, product hunt, community outreach

**Post-Launch:**
- [ ] Raise TVL cap after 30 days of stable operation
- [ ] Full TVL cap removal after full audit complete (if separate from Phase 5)

---

## 14. AGENT ASSIGNMENTS

| Phase | Work | Agent | Depends On |
|-------|------|-------|-----------|
| 0 | UI/UX design — all pages | **Pixel** 🎨 | This doc approved |
| 0 | Architecture review | **Forge** 🔥 | This doc |
| 0 | Infrastructure setup | **Maks** ⚡ | Nick decisions |
| 1 | Smart contracts | **Chain** ⛓️ | Forge review |
| 2 | Backend API + DB | **Maks** ⚡ | Parallel with Phase 1 |
| 3 | Frontend | **Maks** ⚡ | Pixel designs, Phase 2 done |
| 4 | Integration testing | **Maks + Chain** | Phases 1-3 done |
| 5 | Audit coordination | **Chain** ⛓️ | Phase 4 done |
| 6 | GTM + launch | **Launch** 🚀 | Audit done |
| All | Legal review of any changes | **Counsel** ⚖️ | On request |
| All | Pipeline coordination | **MaksPM** 📋 | This doc approved |

---

## 15. OPEN QUESTIONS BEFORE BUILD

**Nick needs to answer these before Phase 0 completes:**

1. **Product name** — "Foundry" (working title). Keep it or different direction?

2. **Creator KYC** — Individuals allowed or business entities only? How strict? (More strict = more compliance protection but fewer campaigns)

3. **Campaign size limits** — Minimum goal (suggest $5K floor) and maximum (suggest $2M ceiling for V1)?

4. **Reward types** — Physical products only, or also: digital downloads, software access, services, experiences?

5. **Refund rate range** — Creator-set between 25% minimum and 100% maximum? Or different bounds?

6. **Milestone count** — Require minimum 3 milestones? Or allow creators to define any structure?

7. **Campaign duration** — Fixed options (30/60/90 days) or fully flexible?

8. **Multi-sig signers** — Who are the 3-5 Safe signers for production treasury? Nick + who?

9. **Audit firm preference** — Code4rena (competitive, public) or Sherlock (private, more controlled)?

10. **Geographic restrictions** — Any countries to block at launch? (US allowed? Counsel should confirm.)

---

## APPENDIX: LEGAL REFERENCE

All development must comply with Counsel's framework. Key files:
- `FOUNDRY-LEGAL-CHANGES-FOR-DEV.md` — 7 specific changes from v0.1 → v2
- `FOUNDRY-PLATFORM-FRAMEWORK-V2.md` — Full legal-approved spec

**Contact Counsel before building anything that changes:**
- Token mechanics
- Refund logic
- Marketplace pricing features
- Any new financial flow to token holders
- Marketing copy

---

*Prepared by Chain ⛓️ — Perlantir AI Studio*
*Legal clearance: Counsel ⚖️ — 2026-03-27*
*Ready for: MaksPM pipeline coordination → Agent assignments → Build*
