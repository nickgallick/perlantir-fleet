# FOUNDRY — PLATFORM FRAMEWORK V2
**Prepared by**: Counsel (Legal) + Chain (Architecture)
**Status**: Legal-Reviewed — Cleared for Development (v1.1 — updated 2026-03-28)
**Date**: 2026-03-27
**Audience**: Development Team (Maks, Forge, Chain)

---

## 1. WHAT THIS PRODUCT IS

A blockchain-native crowdfunding platform where:
- Creators raise funds for projects through milestone-based escrow
- Backers receive transferable reward claims
- Backers who want to exit can sell their claim on a secondary marketplace instead of waiting for a partial platform refund
- All fund custody is handled by non-custodial smart contracts — platform never holds user funds

**This is NOT**: An investment platform, securities exchange, or financial instrument marketplace.
**This IS**: A rewards crowdfunding platform (Kickstarter model) with a secondary market for reward claim transfers.

---

## 2. TWO-LAYER ARCHITECTURE

### Layer 1: Crowdfunding Platform
Standard rewards crowdfunding. Backer contributes → receives reward claim → waits for product delivery.

If backer wants to exit:
- **Option A**: Take the platform refund at the rate defined in campaign terms (e.g., 50% of amount paid)
- **Option B**: Go to the marketplace and sell their claim at whatever price the market will bear

### Layer 2: Secondary Marketplace
Peer-to-peer marketplace where reward claims are tokenized and traded.

- Backer who wants out lists their claim at their chosen price
- Buyer purchases the claim and inherits all rights (reward delivery + refund protection)
- Platform facilitates the transaction and charges a 2% fee
- Prices set entirely by buyers and sellers — platform sets no prices

**The key dynamic**:
- Creator offers 50% refund → backer can sell on marketplace for 75% → backer recovers more than the refund → buyer gets a 25% discount on the reward claim
- If campaign goes viral and demand is high → seller may get above face value → buyer pays a premium for a claim they couldn't get at original price
- All outcomes are market-driven — nothing is engineered or guaranteed

---

## 3. USER JOURNEYS

### Creator
1. Submits campaign application (description, team, timeline, milestones, funding goal, reward tiers, refund terms)
2. AI review (48–72 hrs): feasibility, red flags, team credibility, budget reasonableness
3. Approved → stakes creator collateral (2–5% of funding goal)
4. Campaign goes live — funding period opens (30/60/90 days)
5. Funds raised → locked in CampaignEscrow smart contract
6. Creator hits milestone → submits proof → AI + platform verification → tranche released to creator wallet
7. Repeat until all milestones complete → full escrow released
8. All rewards fulfilled → campaign closed

### Backer (Hold to Delivery)
1. Browses campaigns
2. Backs at chosen tier → pays USDC → receives reward claim
3. Holds claim → receives reward when delivered

### Backer (Exit via Platform Refund)
1. Decides to exit campaign
2. Requests refund through platform
3. Receives refund at rate defined in campaign terms (e.g., 50%)
4. Creator stake funds the refund if creator has abandoned campaign

### Backer (Exit via Marketplace)
1. Decides to exit campaign but wants more than the platform refund rate
2. Chooses to tokenize their reward claim (lazy minting — token only created when listed)
3. Lists on marketplace at chosen price
4. Buyer purchases → USDC transfers to seller → reward claim token transfers to buyer
5. Seller recovers chosen amount; buyer holds claim at their purchased price

### Secondary Buyer
1. Browses marketplace for listed reward claims
2. Evaluates: project status, original price, current ask, remaining milestones
3. Purchases claim at agreed price
4. Inherits all rights: reward delivery + refund protection at original backer's rate
5. Can hold, resell again, or wait for reward delivery

---

## 4. TOKENIZATION MECHANICS

### When Tokens Are Created
**Lazy minting** — tokens are NOT created at the time of backing. They are minted only when a backer chooses to list on the secondary marketplace.

This keeps most backers off-chain (simpler UX) and only puts tokens on-chain when marketplace functionality is actually needed.

### Token Standard
- **ERC-1155** on Base blockchain
- One contract per campaign
- One token ID per reward tier per campaign
- Tokens are fungible within a tier (all Tier 2 tokens for Campaign X are identical)
- Fixed supply per tier — set by creator at launch, cannot change

### What the Token Represents
The token is a **transferable reward claim certificate**. It entitles the current holder to:
1. Receive the specified reward when the campaign delivers
2. A refund at the campaign's stated refund rate if the campaign officially fails
3. Vote in on-chain dispute resolution if a milestone is contested

### What the Token Does NOT Represent
- No equity in the creator's company
- No share of revenue or profits
- No guaranteed financial return
- No promise of token price appreciation

### Token Lifecycle
```
Backer contributes → off-chain reward claim recorded
  → Backer chooses marketplace exit → token minted (lazy mint)
    → Listed on marketplace
      → Sold → token transfers to buyer
        → Buyer holds until: delivery (token burned, reward fulfilled)
                          OR: resale (token transfers again)
                          OR: campaign failure (token burned, refund issued)
  → Backer chooses platform refund → no token ever minted
```

### Pricing
- **Primary (campaign)**: Fixed price per tier set by creator. No bonding curve. No algorithmic pricing.
- **Secondary (marketplace)**: Entirely set by seller. Platform has no role in pricing.

---

## 5. REFUND AND CREATOR STAKE MECHANICS

### Creator Refund Terms (Set at Campaign Launch)
- Creator defines refund percentage at campaign creation (e.g., 50%)
- This rate is locked in the smart contract and cannot be changed
- Displayed prominently to backers before they contribute
- Applies to: backers who request platform refund AND as the floor for marketplace transactions

### Creator Stake (Performance Bond)
- Creator deposits 2–5% of funding goal as collateral when launching
- Held in smart contract separately from backer funds
- **On successful delivery**: returned to creator
- **On campaign failure**: used to fund backer refunds at the stated refund rate
- **Critical**: Refunds are capped at original purchase price (backers cannot receive more than they paid through the refund mechanism)
- Any creator stake surplus above refund amounts: goes to platform consumer protection reserve — NOT distributed to token holders

### Dispute Resolution
- Contested milestone → on-chain backer vote
- Majority vote: milestone accepted or rejected
- Platform has tiebreaker authority in deadlocked votes

---

## 6. SMART CONTRACT ARCHITECTURE

### Four Core Contracts

**CampaignFactory.sol**
- Deploys a new CampaignEscrow + RewardToken contract pair for each approved campaign
- Maintains campaign registry
- Only callable by platform (approved campaigns only)
- Emits events for all campaign deployments (for subgraph indexing)

**CampaignEscrow.sol** (one per campaign)
- Receives USDC directly from backers (platform wallet never touches funds)
- Stores milestone schedule and fund allocation per milestone
- Releases tranches to creator wallet upon verified milestone completion
- Holds creator stake in separate balance
- Processes refunds at stated rate from creator stake on campaign failure
- Accepts marketplace settlement instructions from Marketplace.sol
- Cannot be drained by any single key (multi-sig admin only)

**RewardToken.sol** (ERC-1155, one per campaign)
- Lazy mints reward claim tokens when backer lists on marketplace
- One token ID per tier
- Transferable between wallets
- Burns tokens on reward delivery or campaign failure resolution
- Records original purchase price per token (needed for refund cap enforcement)

**Marketplace.sol**
- Accepts token listings from holders
- Matches buyers and sellers
- Settles trades atomically (token transfer + USDC payment in same transaction)
- Collects 2% platform fee on each secondary sale
- Never holds user funds longer than a single atomic transaction
- No order book — simple listing and purchase model for V1

### Security Requirements (Non-Negotiable)
- UUPS proxy pattern (upgradeable for critical bug fixes)
- Multi-sig (Safe) controls ALL admin functions — no single key can move funds
- Milestone verification role is separate from admin role (oracle cannot drain funds)
- Reentrancy guards on all fund-moving functions
- Chainlink price feeds for any USD-denominated logic
- Full Foundry test suite: unit + fuzz + invariant + fork testing
- **External audit mandatory before mainnet** (Code4rena or Sherlock)

### Key Architectural Constraint
**Platform wallet must NEVER hold user USDC.** All fund flows are:
- Backer wallet → CampaignEscrow contract (direct)
- CampaignEscrow → creator wallet (direct, milestone-triggered)
- CampaignEscrow → backer wallet (direct, refund)
- Buyer wallet → seller wallet via Marketplace.sol (atomic swap)

---

## 7. AI VERIFICATION LAYER

### Campaign Intake Review (Pre-Launch Gate)
Runs before any campaign goes live. Not skippable.

**Reviews**:
- Team identity and credibility signals
- Technical feasibility vs. timeline and budget
- Red flags: plagiarism, recycled campaigns, unrealistic promises
- Budget reasonableness (ask proportional to described work)

**Output**:
- Approve / Conditional Approve / Reject
- Public feasibility score (e.g., 82/100) — visible to backers
- Rejection reason provided to creator (can reapply with changes)

**Disclaimer displayed on every campaign**: "AI review is a quality filter, not a guarantee of delivery. Back campaigns at your own discretion."

### Milestone Verification (During Campaign)
Triggered when creator submits milestone completion proof.

**Reviews**:
- Creator-submitted evidence vs. original milestone definition
- Flags insufficient or inconsistent proof

**Output**:
- Verified → tranche release authorized
- Needs More Info → creator asked to resubmit
- Disputed → triggers on-chain backer vote

---

## 8. PLATFORM REVENUE MODEL

| Source | Rate | Trigger |
|--------|------|---------|
| Primary campaign fee | 5% of funds raised | Taken at each milestone release |
| Secondary marketplace fee | 2% per transaction | Taken from seller proceeds |
| AI review fee | $99–$299 one-time | Paid by creator at application |

**No platform token. No yield products. No revenue sharing with backers. Fees only.**

### Creator Royalty on Secondary Sales (Added v1.1 — Counsel Approved 2026-03-28)
Creators set a royalty % (0–10%) at campaign creation. Paid automatically to creator wallet on every secondary marketplace sale via ERC-2981.

| Source | Rate | Trigger | Who Pays |
|--------|------|---------|----------|
| Creator royalty | 0–10% (creator-set) | Every secondary sale | Deducted from seller proceeds |

**Legal conditions (mandatory):**
- 10% cap hardcoded in Marketplace.sol — cannot be overridden
- Creator-facing language rules:

| ❌ Never Say | ✅ Always Say |
|-------------|--------------|
| "Earn passive income from secondary sales" | "Receive compensation when your reward claims are transferred" |
| "Royalty revenue stream" | "Creator royalty on transfers" |
| "Monetize your token" | "Ongoing creator compensation" |
| "Secondary market earnings" | "Transfer royalty" |

---

## 9. TECH STACK

| Layer | Technology |
|-------|-----------|
| Blockchain | Base (Ethereum L2) |
| Currency | USDC |
| Smart contracts | Solidity 0.8.x, Foundry |
| Token standard | ERC-1155 |
| Proxy | UUPS (OpenZeppelin) |
| Oracles | Chainlink |
| Indexing | The Graph |
| Frontend | Next.js + wagmi + viem + RainbowKit |
| Backend | Next.js API routes + Supabase |
| AI layer | Claude API |
| Treasury | Safe multisig |
| Audit | Code4rena or Sherlock (before mainnet) |

---

## 10. EXPLICITLY OUT OF SCOPE — V1

Do not build these in V1:
- Platform governance token
- Revenue sharing with backers
- Yield on escrowed funds
- Creator equity tokens
- DAO structure
- Cross-chain support
- Bonding curve pricing (any automated price appreciation mechanism)
- Pro-rata creator stake distribution to token holders (refund-only model instead)

**In V1 (added 2026-03-28):**
- ✅ Creator royalty on secondary sales (ERC-2981, 0–10%, Counsel approved)
- ✅ Per-wallet purchase cap per tier (anti-bot, creator-set at campaign launch)

---

## 11. LEGAL FRAMING — MANDATORY FOR ALL TEAM MEMBERS

Every piece of product copy, marketing, onboarding, and documentation must use this language framework:

| ❌ Never Say | ✅ Always Say |
|-------------|--------------|
| Invest / Investment | Back / Support / Fund |
| Return / Profit | Reward / Product / Delivery |
| Appreciate / Gain | Transfer / Sell your claim |
| Token value | Reward claim |
| Exit your position | Sell your reward claim |
| Portfolio | Backed campaigns |
| Yield | Reward |

This is not style guidance — it is legal protection. One wrong word in marketing can change the regulatory classification of the entire product.

---

*Framework prepared by Counsel ⚖️ — Legal-reviewed and cleared for architecture and development.*
*Questions on legal structure → @TheGeneralCounselBot*
*Questions on smart contract architecture → Chain*
*Questions on implementation → Maks / Forge*
