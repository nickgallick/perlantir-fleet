# CROWDFUNDING PLATFORM — PRODUCT FRAMEWORK
**Version:** 0.1 (Pre-Legal Review)
**Prepared by:** Chain (Blockchain Architect)
**Audience:** Counsel (Legal Review), Nick Gallick (CEO)
**Date:** 2026-03-27
**Status:** DRAFT — Pending Counsel review before any development begins

---

## ⚠️ LEGAL REVIEW NOTICE
This document is prepared specifically for Counsel's review. The tokenization and secondary marketplace mechanics described below are intentionally structured to stay within crowdfunding (reward-based) classification rather than securities. Counsel should review Section 5 (Token Mechanics) and Section 6 (Marketplace) with particular attention and flag any structural changes needed before development begins.

---

## 1. PRODUCT OVERVIEW

### Name (Working Title)
TBD — Placeholder: **Foundry** (crowdfunding + blockchain resonance)

### One-Line Description
A blockchain-native crowdfunding platform where backers receive tradeable reward claim tokens, enabling them to exit their position on a secondary marketplace rather than being locked in for the life of a campaign.

### The Problem We're Solving
1. **Creator accountability**: Kickstarter/Indiegogo release 100% of funds upfront with no mechanism to enforce delivery. Creators ghost. Backers lose everything with no recourse.
2. **Backer liquidity**: Current platforms lock backers in for 1-3+ years with no exit. If a project goes sideways, you're stuck holding nothing.
3. **Zero transparency**: Backers have no visibility into how funds are being used or whether milestones are being hit.
4. **No skin in the game**: Creators risk nothing. If they fail, only backers lose.

### What We're NOT Building
- An investment platform
- A securities exchange
- A token speculation product
- A DeFi yield product

### What We ARE Building
- A crowdfunding platform (like Kickstarter) where backing a project gives you a **transferable reward claim**
- The reward claim can be transferred to another person via a marketplace
- Smart contracts enforce milestone-based fund release so creators can't take all the money and disappear
- AI vetting filters out bad-faith campaigns before they go live

---

## 2. CORE PRODUCT PILLARS

### Pillar 1: AI-Gated Campaign Launch
Every campaign must pass an automated AI review before going live. This creates a quality floor that centralized platforms cannot credibly offer at scale.

### Pillar 2: Milestone Escrow (Creator Accountability)
Funds are never given to creators upfront. They are held in a smart contract and released in tranches as verifiable milestones are hit.

### Pillar 3: Creator Stake (Skin in the Game)
Creators must stake a small amount of collateral when launching a campaign. If they fail to deliver and the campaign is formally abandoned, staked collateral is distributed to current reward holders.

### Pillar 4: Transferable Reward Claims
Backing a project gives you a digital reward claim token. This token can be sold or transferred to another person on the platform marketplace. You are not locked in.

### Pillar 5: Secondary Marketplace
A live marketplace where current reward claims trade between users. Price is set by supply/demand — not the platform.

---

## 3. USER JOURNEYS

### Journey A: Creator
1. Submits campaign application (project description, team, timeline, milestones, funding goal, reward tiers)
2. AI review runs (48-72 hrs): feasibility score, red flag scan, team credibility check
3. Approved → deploys campaign smart contract, defines milestone schedule, stakes creator collateral
4. Campaign goes live — funding period opens (30-90 days configurable)
5. Funds raised → locked in escrow contract
6. Creator hits milestone → submits proof → AI + platform verification → tranche released
7. Repeat until fully funded and delivered
8. Campaign closes: rewards fulfilled, remaining escrow released

### Journey B: Early Backer
1. Browses live campaigns
2. Backs a project at current price → receives reward claim tokens (e.g., "1 Tier-2 Reward Claim for Project X")
3. Token represents: the right to receive the reward when delivered
4. Can hold and wait for reward delivery
5. OR: list token on marketplace at any time, sell to another user, exit position
6. If project abandons: receives share of slashed creator stake pro-rata

### Journey C: Secondary Buyer (Marketplace)
1. Browses marketplace for listed reward claims
2. Buys a claim from an exiting backer at agreed price
3. Now holds the reward claim — inherits all rights (reward delivery + failure protection)
4. Can hold, resell again, or wait for delivery

### Journey D: Backer Exiting at a Loss
1. Project hits a bad milestone (delay, missed target)
2. Backer decides risk is too high, wants out
3. Lists reward claim on marketplace at below-purchase price
4. Another buyer (who may believe in the project at lower price) buys it
5. Original backer exits with partial recovery — not total loss like Kickstarter

---

## 4. AI VERIFICATION LAYER

### Campaign Intake Review (Pre-Launch)
**Purpose:** Quality gate — prevents obviously fraudulent or undeliverable campaigns from reaching backers.

**What AI Reviews:**
- Team identity and credibility signals
- Technical feasibility of stated deliverables vs. timeline
- Budget reasonableness (is the ask proportional to the work described?)
- Red flags: plagiarism, recycled campaigns, unrealistic promises
- Market context: is this product category viable?

**Output:**
- Approve / Conditional Approve (modifications required) / Reject
- Public feasibility score visible to backers (e.g., 82/100)
- Rejection reason provided to creator (they can reapply)

**What AI Does NOT Do:**
- Guarantee outcomes
- Endorse or recommend campaigns
- Replace human judgment for investment decisions

### Milestone Verification (During Campaign)
**Purpose:** Determines whether a creator has legitimately hit a milestone before funds are released.

**What AI Reviews:**
- Creator-submitted evidence (prototype video, beta link, delivery confirmation, etc.)
- Cross-references original milestone definition
- Flags inconsistencies or insufficient proof

**Output:**
- Verified / Needs More Info / Disputed
- Disputed milestone → community backer vote (on-chain) to break tie

---

## 5. TOKEN MECHANICS
### ⚠️ COUNSEL: Primary Review Section

### What the Token Is
The token is a **Reward Claim Certificate** — a digital representation of a backer's right to receive a specific reward tier from a specific campaign.

**Analogous to:** A concert ticket. A ticket entitles the holder to attend the show. Tickets can be resold on secondary markets (StubHub). The original purchaser does not profit from the show's success — they just want the experience. If the show is canceled, the ticket holder gets a refund.

**This is NOT:**
- An equity stake in the creator's company
- A share of future revenue or profits
- A financial instrument
- An investment contract

### Token Structure
- **Standard:** ERC-1155 (multi-token standard — one contract per campaign, multiple tiers)
- **One token type per reward tier per campaign**
  - Example: Campaign X has 3 tiers: Tier 1 ($25), Tier 2 ($75), Tier 3 ($200)
  - Each tier = its own token ID within the campaign contract
- **Tokens are fungible within a tier** (all Tier 2 tokens for Campaign X are identical)
- **Fixed supply per tier** — set by the creator, cannot be changed after launch

### What Holding the Token Gets You
1. The reward when delivered (physical product, digital access, service, etc.)
2. Pro-rata share of creator stake if campaign officially fails (partial recovery)
3. The right to vote in dispute resolution if a milestone is contested

### What Holding the Token Does NOT Get You
- Any share of creator profits or revenue
- Equity in the creator's company
- Any financial return beyond the stated reward
- Any promise of appreciation in token value

### Token Pricing
- **Initial price:** Set by creator per tier (e.g., $25, $75, $200) — mirrors Kickstarter tier pricing
- **Bonding curve during campaign:** Optional — price increases slightly as more tokens sell (rewards earliest backers with lowest price, creates organic urgency)
- **Secondary market price:** Set by supply and demand between users — platform has no role in setting secondary prices

### Token Lifecycle
```
Created (campaign launch)
  → Sold to backer (primary sale)
    → Held by backer (awaiting reward)
    → OR: Transferred on marketplace (reward claim changes hands)
      → New holder awaits reward OR resells again
        → Campaign delivers: token burned, reward fulfilled
        → Campaign fails: token burned, creator stake distributed
```

---

## 6. SECONDARY MARKETPLACE
### ⚠️ COUNSEL: Secondary Review Section

### What It Is
A peer-to-peer marketplace where backers can list their reward claim tokens for sale and other users can purchase them.

**The marketplace transfers the reward claim — not an investment position.**

A buyer on the secondary market is buying the right to receive the reward. They are NOT buying a financial instrument or speculating on creator success for profit.

### How It Works
- Backer lists token at any price they choose (above or below what they paid)
- Other users can browse and purchase listed tokens
- Transaction settles on-chain: token transfers to buyer, USDC/ETH transfers to seller
- Platform takes a small transaction fee (e.g., 2%)
- No minimum holding period — sellers can list immediately after purchase

### Price Dynamics (Intentional Design)
- Project hits milestone → demand increases → secondary price rises (backers sell at premium)
- Project misses milestone → demand drops → sellers accept lower prices to exit
- Project goes viral organically → early backers can sell at premium to late interested parties
- Project in trouble → price drops → value seekers buy at discount betting on recovery

**Importantly:** Price movements reflect reward delivery expectations — not financial return speculation. The token only has value because it entitles the holder to a reward.

### Platform Role in Marketplace
- Provides infrastructure (listing, matching, settlement)
- Does NOT set prices
- Does NOT operate an order book as a regulated exchange
- Does NOT take custody of user funds beyond transaction escrow
- Facilitates peer-to-peer transfers only

---

## 7. SMART CONTRACT ARCHITECTURE

### Contract System (4 Core Contracts)

**1. CampaignFactory.sol**
- Deploys a new CampaignEscrow contract for each approved campaign
- Stores campaign registry
- Only callable by platform (approved campaigns only)

**2. CampaignEscrow.sol** (one per campaign)
- Holds all backer funds in escrow
- Stores milestone schedule and fund allocation per milestone
- Releases tranche to creator upon verified milestone completion
- Holds creator stake in separate balance
- Slash and distribute creator stake if campaign formally fails
- Accepts reward token burn as proof of delivery claim

**3. RewardToken.sol** (ERC-1155, one per campaign)
- Mints reward claim tokens to backers on purchase
- One token ID per tier
- Burns tokens on reward delivery or campaign failure resolution
- Transferable (enables marketplace)

**4. Marketplace.sol**
- Accepts token listings from holders
- Matches buyers and sellers
- Settles trades atomically (token ↔ payment, same transaction)
- Collects platform fee on each secondary sale
- No ability to hold user funds longer than a single transaction

### Key Security Considerations
- All contracts upgradeable via UUPS proxy (allows critical bug fixes)
- Multi-sig (Safe) controls all admin functions
- Milestone verification role is separate from admin role
- Reentrancy guards on all fund-moving functions
- Chainlink price feeds for any USD-denominated logic
- Full Foundry test suite: unit + fuzz + invariant + fork testing
- External audit before mainnet deployment (mandatory)

---

## 8. PLATFORM ECONOMICS (REVENUE MODEL)

| Revenue Source | Rate | Notes |
|---------------|------|-------|
| Primary campaign fee | 5% of funds raised | Taken at each milestone release, not upfront |
| Secondary marketplace fee | 2% per transaction | Paid by seller |
| AI review fee | $99-$299 one-time | Paid by creator at application |
| Creator stake | 2-5% of goal | Held in escrow, returned on successful delivery, slashed on failure |

**No token launch. No platform token. No yield products.** Revenue is purely from service fees.

---

## 9. WHAT'S INTENTIONALLY OUT OF SCOPE (V1)

To maintain legal clarity and product focus, the following are explicitly NOT in V1:
- Platform governance token
- Revenue sharing with backers
- Yield on escrowed funds
- Creator equity tokens
- DAO structure
- Cross-chain support (Base only at launch)
- Anonymous campaigns (KYC required for creators)

These can be evaluated for later versions after legal framework is established.

---

## 10. TECH STACK

| Layer | Technology |
|-------|-----------|
| Blockchain | Base (Ethereum L2) |
| Payment currency | USDC |
| Smart contracts | Solidity 0.8.x, Foundry toolchain |
| Token standard | ERC-1155 |
| Proxy pattern | UUPS (OpenZeppelin) |
| Oracles | Chainlink (price feeds if needed) |
| Indexing | The Graph (subgraph for campaign data) |
| Frontend | Next.js + wagmi + viem + RainbowKit |
| Backend | Next.js API routes + Supabase |
| AI layer | Claude API (campaign review + milestone verification) |
| Wallet | EOA + Safe multisig for treasury |
| Audit | External (TBD — Code4rena or Sherlock before launch) |

---

## 11. QUESTIONS FOR COUNSEL

The following are the specific legal questions this framework raises, in priority order:

1. **Reward claim tokens on secondary market** — Does the ability to sell a reward claim token at a price higher than purchase price trigger Howey Test analysis? Our position: No, because the token entitles holder to a reward (product/service), not profit from another's efforts. But Counsel should confirm this framing holds.

2. **Bonding curve pricing** — Does a rising price curve during the campaign period create any securities characterization risk? We can remove this feature if it creates issues.

3. **Creator stake slashing → distributed to token holders** — Does the distribution of slashed collateral to current token holders look like a financial return? We want backers to have downside protection but not if it triggers securities classification.

4. **KYC requirements** — What level of creator KYC is required? Is backer KYC needed? Are there AML considerations for USDC flows?

5. **Money transmission** — Does holding USDC in escrow smart contracts trigger money transmitter licensing requirements? (We believe smart contract escrow is different from custodial holding but need confirmation.)

6. **Jurisdiction** — Are there specific states or countries where this model has heightened risk? Should we geo-block at launch?

7. **Terms of service structure** — What disclaimers and terms are required to make clear this is not an investment platform?

---

## 12. OPEN PRODUCT QUESTIONS (For Nick)

1. **Product name** — Working title is "Foundry." Other directions?
2. **Creator KYC** — How strict? Business-only or allow individuals?
3. **Minimum/maximum campaign size** — Floor (e.g., $10K) and ceiling (e.g., $5M)?
4. **Reward types** — Physical products only? Or also digital goods, services, access passes?
5. **Campaign duration** — Fixed windows (30/60/90 days) or flexible?
6. **Milestone structure** — Do we define a standard (e.g., 3-5 milestones required) or let creators define freely?

---

## SUMMARY: THE DIFFERENTIATION

| Feature | Kickstarter | This Platform |
|---------|------------|---------------|
| Fund release | Upfront (all at once) | Milestone escrow (earned) |
| Creator accountability | None | Creator stake + milestone verification |
| Backer exit | None — fully locked | Tradeable reward claims |
| Transparency | Low | On-chain milestone + fund tracking |
| Campaign quality | Self-selected | AI-gated at launch |
| Fraud recourse | None | Creator stake slashing |
| Backer liquidity | Zero | Secondary marketplace |

**Core value proposition:** The only crowdfunding platform where creators earn their funding by building, and backers can exit their position at any time.

---

*Document prepared by Chain (Blockchain Architect) — Perlantir AI Studio*
*For legal review by Counsel before any product development or deployment*
