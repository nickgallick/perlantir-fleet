# FOUNDRY — LEGAL CHANGES & TECHNICAL SCOPE
## From Chain's Framework v0.1 → Legal-Approved v2
**Prepared by**: Counsel ⚖️
**For**: Chain, Maks, Forge (Development Team)
**Date**: 2026-03-27
**Status**: Approved — Build to this spec

---

## Overview

This document maps every change made from Chain's original framework (v0.1) to the legal-approved version (v2). It explains what changed, why it changed (legal reason), and exactly what the technical team needs to build differently.

Read this alongside FOUNDRY-PLATFORM-FRAMEWORK-V2.md which has the full spec.

---

## CHANGE 1: Remove Bonding Curve Pricing

### What Chain's v0.1 Said
> "Bonding curve during campaign: Optional — price increases slightly as more tokens sell (rewards earliest backers with lowest price, creates organic urgency)"

### What v2 Says
Fixed price per tier only. No automated price mechanisms of any kind.

### Why It Changed (Legal Reason)
A smart contract that automatically increases token price as more tokens sell is an engineered appreciation mechanism. Under SEC analysis (2019 Digital Asset Framework), automated price appreciation built into a contract is a factor indicating investment contract / securities classification. It signals to regulators that early buyers are rewarded for speculative timing — that's investment behavior, not reward-claim behavior.

Removing it eliminates one of the two strongest arguments a regulator could make against the product.

### Technical Change Required
- **Remove**: Any bonding curve logic from RewardToken.sol or CampaignEscrow.sol
- **Replace with**: Fixed price per tier stored at campaign creation, immutable after launch
- **Price set by**: Creator at campaign setup only
- **Secondary market prices**: Entirely set by individual sellers — no contract-level pricing logic at all

---

## CHANGE 2: Restructure Creator Stake — Refund Model, Not Distribution Model

### What Chain's v0.1 Said
> "Pro-rata share of slashed creator stake distributed to current reward holders" on campaign failure

### What v2 Says
Creator stake is a **performance bond**. On campaign failure it funds **refunds at original purchase price** — capped at what each backer paid. Any surplus goes to a platform consumer protection reserve.

### Why It Changed (Legal Reason)
If token holders receive a cash payment when a creator fails — that cash payment is a financial return on the token. It means the token can generate money beyond the stated reward. Under Howey Test prong 3 (expectation of profit), this creates securities classification risk.

The fix: Refund = returning what someone paid. That's a consumer protection mechanism, not a financial return. Backers cannot receive more than they originally paid through this mechanism.

### Technical Changes Required

**CampaignEscrow.sol — Change the failure distribution logic:**

| Old Logic | New Logic |
|-----------|-----------|
| Calculate each token holder's pro-rata share of creator stake | Calculate each backer's original purchase price (stored at time of purchase) |
| Distribute creator stake proportionally to current token holders | Refund each backer up to their original purchase price from creator stake |
| Any holder benefits regardless of what they paid | Buyer who paid $75 for a $100 claim gets max $75 refund — not $100 |
| Token holders could receive more than they paid if stake is large | Strictly capped at original purchase price — no windfalls |
| Surplus (if any) to... unspecified | Surplus to platform consumer protection reserve address |

**RewardToken.sol — Store original purchase price:**
- When a token is minted (lazy mint at marketplace listing), record the original backer's purchase price
- This data is needed to enforce the refund cap
- When token is transferred on secondary market, original purchase price travels with the token (stored in contract, not in token metadata visible to public)

**New function needed**: `getOriginalPurchasePrice(tokenId)` — returns the capped refund amount for any given token

---

## CHANGE 3: Lazy Minting — Tokens Created at Marketplace Listing, Not at Pledge

### What Chain's v0.1 Said
Implied tokens minted at time of backing (standard ERC-1155 mint flow)

### What v2 Says
**Lazy minting**: Tokens are NOT minted when a backer pledges. Tokens are only minted when a backer chooses to list their claim on the secondary marketplace.

### Why It Changed (Legal Reason)
Keeping most backers off-chain by default reinforces the "rewards crowdfunding" framing. If every backer automatically receives a tradeable token the moment they pledge, the product looks more like a token sale. Lazy minting means most users experience this as a normal crowdfunding platform — tokens only appear when someone actively chooses the marketplace exit.

Secondary benefit: simpler UX for the majority of users who just want the product.

### Technical Changes Required

**Platform database (Supabase)**:
- Store all pledge records off-chain in Supabase at time of pledge
- Record: user_id, campaign_id, tier_id, amount_paid, pledge_timestamp, reward_claim_id
- No on-chain transaction at pledge time (just Stripe/USDC payment + database record)

**RewardToken.sol**:
- Add `lazyMint(address recipient, uint256 tierId, uint256 originalPurchasePrice)` function
- Only callable by platform (authorized minter role)
- Triggered when backer requests marketplace listing — not at pledge time

**Marketplace.sol**:
- Before listing: platform backend calls `lazyMint` to create the token
- Token is then listed by the now-token-holding backer
- All subsequent transfers are standard ERC-1155 transfers

**User flow change**:
```
Old: Pledge → Token minted → Token held or listed
New: Pledge → Database record only → [If marketplace exit chosen] → Token minted → Listed
```

---

## CHANGE 4: Two-Layer Architecture — Platform Refund vs. Marketplace Exit

### What Chain's v0.1 Said
Single unified system where backing = receiving a token that can be redeemed or sold

### What v2 Says
Two explicit, separate exit paths that the user chooses between:

**Path A: Platform Refund**
- Backer requests refund through platform UI
- Receives refund at campaign's stated refund rate (e.g., 50%)
- No token ever minted
- Simple, off-chain process

**Path B: Marketplace Exit**
- Backer decides they want to try to recover more than the platform refund rate
- Chooses to tokenize their claim
- Token minted (lazy mint)
- Listed on marketplace at backer's chosen price
- If sold: backer receives sale proceeds; buyer receives token (reward claim)

### Why It Changed (Legal Reason)
The two-path structure reinforces the legal framing. Backers are not "investors exiting a position" — they are choosing between a defined refund and a marketplace transfer of a product claim. This maps cleanly to consumer contract language, not investment language.

It also means the majority of users (those who take the refund) never interact with the token/blockchain layer at all.

### Technical Changes Required

**Platform UI**:
- "Exit Campaign" screen must present two explicit options:
  - Option A: "Get [X]% refund — receive $[calculated amount] back to your payment method"
  - Option B: "Sell your reward claim — list on marketplace and set your own price"
- No language suggesting Option B is an "investment exit" or "position exit"
- Use language: "Transfer your reward claim to another backer"

**Backend**:
- Refund path: standard payment reversal / USDC transfer from escrow
- Marketplace path: triggers lazy mint → marketplace listing flow

---

## CHANGE 5: Secondary Marketplace — Framing and Constraints

### What Chain's v0.1 Said
> "Early backers can sell at premium to late interested parties" — in the price dynamics section

### What v2 Says
Secondary marketplace is a peer-to-peer transfer mechanism. No platform language about price appreciation, premiums, or investment-style dynamics.

### Why It Changed (Legal Reason)
The price dynamics section reads like investment marketing. Specifically "early backers can sell at premium" implies that early entry is a strategy for financial gain. That language in any user-facing material creates securities characterization risk regardless of how the product is actually structured.

The marketplace is fine. The language describing it cannot suggest investment behavior.

### Technical Changes Required

**No contract changes** — this is documentation and UI language only

**UI copy rules (mandatory)**:
- ❌ "Sell at a premium" → ✅ "Transfer your reward claim"
- ❌ "Exit your position" → ✅ "Sell your reward claim"
- ❌ "Early backers benefit from price appreciation" → ✅ "Back early to secure your reward"
- ❌ "Investment" → ✅ "Backing" / "Support"
- ❌ "Return" / "Profit" → ✅ "Reward" / "Product"
- ❌ "Token value" → ✅ "Reward claim"

**Marketplace listing UI**:
- Show: original price paid, current campaign status, reward description, refund rate
- Do NOT show: price charts, historical price data, "floor price," volume statistics
- These features are fine for V2 after securities opinion — avoid for V1

---

## CHANGE 6: No Pro-Rata Distribution to Token Holders on Any Event

### What v0.1 Said
Token holders receive distributions under certain conditions

### What v2 Says
Token holders receive exactly two things:
1. The stated reward on delivery (product/service/access)
2. A refund capped at original purchase price on campaign failure

Nothing else. No distributions. No payments. No yields.

### Why It Changed
Any payment to token holders beyond the stated reward or a return of their original purchase price = financial return on the token = securities risk.

### Technical Change
- **Audit all functions** in CampaignEscrow.sol and RewardToken.sol
- **Any function that sends value to token holders** beyond (a) reward delivery or (b) capped refund must be removed
- **Add a comment in code**: `// Legal constraint: payments to token holders capped at original purchase price per Counsel review 2026-03-27`

---

## CHANGE 7: TVL Cap for Launch (Risk Management)

### What v0.1 Said
No TVL cap mentioned

### What v2 Says
Launch with a hard TVL cap until full external audit is complete

### Why It Changed
Smart contract audit is deferred for lean launch. A TVL cap limits the blast radius of any undiscovered bug. This is a legitimate risk management approach used by DeFi protocols at launch.

### Technical Change Required

**CampaignFactory.sol or CampaignEscrow.sol**:
- Add `maxTVL` parameter (set to $10,000 USDC at launch)
- Check against total active escrow balance before accepting new deposits
- If `totalEscrow >= maxTVL`: new campaign deposits rejected with clear error message
- Admin function (multi-sig only) to raise the cap after audit completes
- Display current TVL cap prominently in platform UI ("Platform is in early access — maximum $10,000 in active campaigns")

---

## WHAT DID NOT CHANGE — Keep As-Is

These elements from v0.1 are legally approved and should be built exactly as Chain specified:

✅ **Non-custodial architecture** — platform wallet never holds USDC
✅ **CampaignFactory / CampaignEscrow / RewardToken / Marketplace** — four-contract structure is correct
✅ **Multi-sig (Safe) admin controls** — required, non-negotiable
✅ **Milestone-based fund release** — correct
✅ **On-chain backer vote for disputed milestones** — correct
✅ **UUPS proxy pattern** — correct
✅ **Reentrancy guards** — required
✅ **Foundry test suite** — required
✅ **External audit before mainnet** — required (scope reduced via TVL cap for lean launch)
✅ **ERC-1155 token standard** — correct
✅ **Base blockchain + USDC** — correct
✅ **5% primary fee / 2% secondary fee** — correct
✅ **No platform token** — correct
✅ **Creator stake as performance bond** — correct (restructured as refund mechanism)
✅ **AI campaign review gate** — correct
✅ **AI milestone verification** — correct
✅ **Creator KYC required** — correct

---

## Summary Table — All Changes

| # | Change | Type | Contract Affected | Priority |
|---|--------|------|------------------|----------|
| 1 | Remove bonding curve | Architecture | RewardToken.sol | 🔴 Must |
| 2 | Refund model (not distribution) | Logic | CampaignEscrow.sol, RewardToken.sol | 🔴 Must |
| 3 | Lazy minting | Architecture | RewardToken.sol + Backend | 🔴 Must |
| 4 | Two-path exit (refund vs. marketplace) | UX + Backend | Platform UI + Backend | 🔴 Must |
| 5 | Marketplace framing / copy rules | Language | UI only | 🔴 Must |
| 6 | No distributions to token holders | Logic audit | All contracts | 🔴 Must |
| 7 | TVL cap at launch | Feature | CampaignFactory.sol | 🟡 Strong Rec |

---

## Questions for Counsel

Chain / Maks / Forge — if anything in this document raises implementation questions that touch on legal structure, send them to Counsel before building. Do not make assumptions on the legally-sensitive items (Changes 1–6). Get confirmation first.

Contact: @TheGeneralCounselBot

---

*Prepared by Counsel ⚖️ — Perlantir AI Studio*
*Legal framework approved for development as specified above*
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
