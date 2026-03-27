# FOUNDRY — Market Research Report
**Prepared by:** Scout 🔍  
**Date:** 2026-03-27  
**For:** Chain ⛓️ + Nick / Perlantir Team  
**Classification:** Internal Research — Pre-Build Validation

---

## EXECUTIVE SUMMARY

The crowdfunding market is enormous, deeply broken, and wide open for a trust-first alternative. Backers are getting burned at scale — Kickstarter and Indiegogo have Trustpilot ratings that would get any SaaS company shut down. The specific pain points Foundry targets (creator ghosting, no refunds, locked-in positions) are real, documented, and screamed about in public.

**Verdict: GO — but with a critical caveat. The crypto UX layer must not be the front door.**

The demand is validated. The competitors are failing their users. But every prior blockchain crowdfunding attempt failed because they led with crypto. Foundry should lead with the outcome ("your money only releases when the creator delivers") and let the blockchain be invisible infrastructure.

---

## 1. MARKET SIZE

### Global Crowdfunding Market
- **2025 projection:** ~$1 trillion in total global crowdfunding volume (Wikipedia/industry consensus)
- **2015 baseline:** $34 billion raised globally
- **Growth trajectory:** Consistent double-digit YoY growth since 2012
- **North America:** Largest single market, followed by Asia

### Rewards-Based Crowdfunding Specifically (Kickstarter Model)
- **Kickstarter lifetime:** $5.6B raised across 197,425 projects (as of Jan 2021)
- **Reward-based share:** Approximately 30-35% of total crowdfunding volume (vs. equity and lending)
- **Rough SAM estimate for reward-based:** ~$15-20B annually globally

### TAM / SAM / SOM Estimate for Foundry

| Layer | Estimate | Basis |
|---|---|---|
| **TAM** | $300B+ | Global reward + project crowdfunding (incl. crypto/web3 adjacent) |
| **SAM** | $20B | English-language, internet-native rewards crowdfunding |
| **SOM (Year 1)** | $5-50M in GMV | Realistic early capture through a single high-profile launch + creator community |

**Note:** Even 0.1% of the $20B SAM = $20M GMV. At 5% platform take, that's $1M revenue. This is very achievable with 1-2 successful flagship campaigns.

---

## 2. COMPETITOR LANDSCAPE

### Traditional Platforms

#### Kickstarter
- **Model:** All-or-nothing. Creator gets 100% of funds if goal reached. No milestones. No refunds.
- **Take rate:** 5% platform fee + 3-5% payment processing
- **Creator accountability:** Zero. Kickstarter explicitly states "we are not responsible for creator fulfillment"
- **Backer protection:** None. Bank chargeback is the only recourse.
- **Trustpilot score:** ~1.8/5 (hundreds of recent negative reviews)
- **Key weakness:** Scam enablement. Backers publicly rage that "Project We Love" badges appear on failed campaigns. Creator vetting is nonexistent.
- **Size/moat:** Network effect is real. $5.6B raised. Strong creator supply. But trust is crumbling.

#### Indiegogo
- **Model:** Flexible (keep what you raise) + Fixed (all-or-nothing). Keep-what-you-raise model is particularly dangerous for backers.
- **Take rate:** 5% + payment processing
- **Creator accountability:** Even worse than Kickstarter. Terms of service openly ignored.
- **Trustpilot score:** ~1.3/5 — worse than Kickstarter
- **Key weakness:** Multiple documented cases of $500K-$850K raised with zero product delivery and zero platform intervention. E.g., Avarax E-Bike ($850K, 1,000+ backers, never shipped, Indiegogo did nothing).
- **Current state:** Recently changed ownership and rebuilt their platform. UX degraded. Creators and backers fleeing.

#### BackerKit
- **Model:** Post-campaign fulfillment management tool, not a primary platform
- **Role:** Helps successful Kickstarter campaigns manage shipping/rewards
- **Gap:** Doesn't solve the trust/accountability problem at all — only helps AFTER a successful campaign

### Blockchain / Crypto Native Platforms

#### Juicebox (juicebox.money)
- **Model:** DAO treasury management + programmable funding rounds. Ethereum-based.
- **Audience:** Crypto-native DAOs and projects. Not mainstream creators.
- **Milestone escrow:** No — funds go into treasury immediately
- **Secondary market:** No tradeable backer positions
- **Gap:** Too crypto-native, no consumer interface, no accountability layer for mainstream use

#### Mirror (mirror.xyz)
- **Model:** Writing platform + crowdfund raises for essays/projects. NFT-based.
- **Audience:** Web3 writers and creators only
- **Milestone escrow:** No
- **Secondary market:** NFT resale exists but niche and illiquid
- **Gap:** Tiny audience, no mainstream traction, blocked from most users (403 response on fetch)

#### Gitcoin
- **Model:** Quadratic funding for open source / public goods. Ethereum-based.
- **Audience:** Developers only
- **Gap:** Not for consumer product campaigns at all. Different category.

### Does Anything Do Milestone Escrow OR Secondary Trading Today?

**Milestone escrow crowdfunding:** No mainstream platform does this. There have been whitepapers and crypto experiments (KickICO, WeiFund) but none with mainstream traction.

**Secondary trading of backer positions:** No one. This is genuinely unexplored territory. The closest analogy is secondary markets for event tickets (StubHub model applied to crowdfunding).

**The gap is real and undefended.**

---

## 3. PAIN POINT VALIDATION

This section is evidence-heavy. The following are verbatim complaints pulled from Trustpilot (March 2026):

### Kickstarter — Top Complaint Categories

**1. Creator ghosting / no accountability**
> *"The creator of ENOR E1 collected the pledges and has gone MIA ever since. Kickstarter has provided no meaningful support."*

> *"As of March 1st, there have been no meaningful project updates for months, and the creator's last recorded login was January 30th, 2026... I backed a campaign labeled 'Project We Love.'"*

> *"I am giving 1 star only because zero is not an option. How is it possible that the creator banked $480,609 from 2,758 contributors and no responsibility is owned by nobody?"*

**2. Platform refuses accountability**
> *"Kickstarter's answer: life is tough, keep pushing."*

> *"Kickstarter ignores the problem, it will be your fault for betting on a product that was actually a scam."*

> *"A bank chargeback is your ONLY way out."*

**3. Algorithm favors scammers over legitimate creators**
> *"A GAME was setting their pledge goal at $1 and they approved and promoted it like crazy. False AI games with no demo gets promoted like crazy. Mine? An honest game with actual demo and release date? Buried to oblivion."*

> *"They say they do background check? False AI games with no demo, no nothing but used bots to raise their pledges also gets promoted like crazy."*

**4. No refund mechanism**
> *"Paid €500 for a product and after 12 creator status updates... stopped answering emails and I never received the product."*

### Indiegogo — Even Worse

**Documented scale failures:**
- **Avarax E-Bike:** $850,000 raised, 1,000+ backers, never went into production, Indiegogo did nothing
- **G7 Haul Pack:** $500+ backer, 3 years of delays, creator ghosted, no platform action
- **CarDongle:** Backers still waiting, no product

> *"Indiegogo is built on a good concept, but with an extremely dangerous lack of any kind of protections for backers against scam and malicious projects."*

> *"Terms of Service broken, no products, money gone. They just get some generic automated response."*

### The Core Pain Points Foundry Solves (Validated)
1. ✅ **Creator takes money and disappears** → Milestone escrow eliminates this by design
2. ✅ **Backers locked in with no exit** → Tradeable reward claim tokens give them an out
3. ✅ **Platform refuses accountability** → Smart contract enforces accountability, not platform discretion
4. ✅ **No way to know if creator will deliver** → On-chain milestone history creates verifiable creator reputation

---

## 4. BLOCKCHAIN CROWDFUNDING ATTEMPTS — LESSONS FROM FAILURES

### ICO Era (2017-2018) — The Original Blockchain Crowdfunding Wave
**What happened:** Hundreds of projects raised millions via token sales under the guise of "crowdfunding" for products. Most were speculative or outright scams.

**Why they failed:**
- Led with speculation ("buy our token") instead of product delivery
- No accountability mechanism — token buyers had no recourse
- Regulatory backlash (SEC classified many ICOs as unregistered securities)
- 90%+ of ICO projects failed to deliver any product
- Market association: "blockchain crowdfunding" = scam in mainstream consciousness

**Lesson for Foundry:** Never use the word "token" in the front-facing product. Reward claim tokens are a UX feature, not a speculative asset. Position them as "transferable backer positions" or "claim rights."

### KickICO (2017)
- Raised $18.5M ICO, pivoted to being a "blockchain Kickstarter"
- Never gained mainstream traction
- Crypto-only payment requirement killed mainstream adoption
- Now essentially dead

**Lesson:** Crypto-payment wall = product graveyard

### WeiFund (Ethereum, 2016)
- Open-source crowdfunding protocol on Ethereum
- Technically functional
- Zero users
- No UX, no creator acquisition, no marketing

**Lesson:** Infrastructure without distribution is a GitHub repo, not a product

### What All Blockchain Crowdfunding Failures Have in Common
1. Led with blockchain/crypto as the feature, not the benefit
2. Required crypto wallets from day one (massive onboarding friction)
3. No mainstream creator acquisition strategy
4. No fiat payment support — excluded 99% of buyers

**Foundry's differentiation:** If it supports fiat on-ramps (credit card → smart contract under the hood), it bypasses every failure mode above.

---

## 5. VIRAL/BREAKOUT CAMPAIGNS — WHAT MADE THEM EXPLODE

### Pebble Watch (2012) — $10.3M raised (goal: $100K)
- **What worked:** Solved a real problem (smartphone notifications on wrist) before Apple Watch existed
- **Creator track record:** Founder had prior product experience — trust signal
- **What secondary market would have looked like:** Early backers at $99 reward tier, product later retailed at $150. Those positions would have traded at a premium as campaign exploded. Estimated secondary market: $2-5M in trade volume.

### Coolest Cooler (2014) — $13.3M raised (goal: $50K)
- **What worked:** Absurd product differentiation (cooler with blender, Bluetooth speaker, LED). Pure fun.
- **Massive failure story:** Delivered to late backers years late. Creator sold product on Amazon before fulfilling Kickstarter backers. One of Kickstarter's most infamous failures.
- **Secondary market implication:** If backer positions were tradeable, early backers could have sold before the failure was obvious. Late backers who paid higher prices on secondary market would have been taking on risk they could price — a functioning market.

### OUYA (2012) — $8.6M raised (goal: $950K)
- **What worked:** Android gaming console at $99 attracted developer community
- **What failed:** Delivered but product was mediocre. Backers wished they could exit.
- **Secondary market implication:** Positions would have peaked during the viral moment and declined as reality set in. Price discovery would have been far more honest than blind faith.

### Critical Role (2019) — $11.4M raised (goal: $750K)
- **What worked:** Massive pre-existing fanbase. Not speculative — buying into a known quantity.
- **Key insight:** The campaigns that work best are where there's already a community. The platform is distribution, not discovery.
- **Foundry implication:** Onboard creators who already have audiences. Don't rely on Foundry discovery for first campaigns.

### The Common Thread in Viral Campaigns
1. Strong pre-existing fanbase or very shareable concept
2. Tangible, understandable product (not abstract)
3. Clear value proposition to early backers
4. Social proof momentum (herding behavior accelerates)

**For Foundry's launch:** The first campaign needs to be from a creator with an existing following who makes the milestone escrow and secondary market features the talking point.

---

## 6. TARGET CREATOR SEGMENTS — WHERE IS THE PAIN HIGHEST?

### Tier 1 — Hardware / Consumer Electronics ⭐⭐⭐
**Pain level:** Extreme. Most Kickstarter horror stories are hardware projects.
- Manufacturing delays are inherent to hardware
- Supply chain issues routinely kill campaigns
- Backers wait 2-4 years regularly
- **Perfect for milestone escrow:** "Funding releases when prototype certified, then when manufacturing contract signed, then when first batch ships"
- Examples of failures: Coolest Cooler, countless drone/gadget projects

**Why Foundry wins here:** Milestone escrow is the perfect mechanism for hardware. Backers can see exactly which manufacturing stage triggered fund release. Creators get working capital at each stage. Trust is built incrementally.

### Tier 2 — Video Games ⭐⭐⭐
**Pain level:** High. Games are routinely delayed 3-5 years post-funding.
- Star Citizen: $900M raised, still in alpha after 13+ years
- Massive communities that track delivery progress obsessively
- **Perfect for milestone escrow:** Alpha → Beta → Gold master → Launch milestones
- Secondary market would be very active — speculators and fans both participate

### Tier 3 — Film & Media ⭐⭐
**Pain level:** Medium. Smaller individual pledge amounts ($25-100) mean lower stakes.
- Veronica Mars, Critical Role prove mainstream viability
- Film projects are harder to milestone (creative work doesn't have clean delivery stages)
- **Better fit for secondary market than milestone escrow**

### Tier 4 — Software / Tech Tools ⭐⭐
**Pain level:** Medium. Founders often pivot or abandon.
- Less catastrophic dollar losses (lower pledge amounts)
- Developer communities are crypto-friendly — best early adopters for Foundry mechanics

### Tier 5 — Consumer Goods / Apparel ⭐
**Pain level:** Low-medium. Simpler supply chains.
- Less interesting for milestone mechanics
- Could be early volume campaigns

### Scout's Recommendation
**Lead with hardware and games.** These categories have the highest pain, the most vocal communities, and the clearest milestone structure. A single hardware campaign that uses Foundry's milestone escrow successfully — and where backers can visibly track fund release against deliverables — becomes the proof of concept for the entire platform.

---

## 7. GO-TO-MARKET ANGLE

### The Launch Strategy That Proves the Product

**Phase 1: One flagship campaign (3-4 weeks)**

Don't launch with 50 campaigns. Launch with ONE creator who:
- Has an existing audience (10K+ followers minimum)
- Has a hardware or game product with clear milestones
- Is willing to be publicly transparent about the milestone escrow
- Is ideally a creator who was burned by Kickstarter before

The narrative writes itself: *"Creator who lost backers on Kickstarter builds their comeback on Foundry — a platform that puts backer protection first."*

**Phase 2: Make the milestone releases a content event**

Each milestone unlock = press moment. "Foundry releases $50K to hardware creator as they hit prototype milestone" is a story. Do a livestream. Make the smart contract execution visible.

**Phase 3: Activate the secondary market**

When the first campaign goes viral, positions will trade. The first Foundry secondary market transaction should be a press event. "Backers can now buy and sell positions in live campaigns" is genuinely new and genuinely newsworthy.

### Distribution Channels

| Channel | Why It Works |
|---|---|
| Subreddit targeting (r/Kickstarter, r/BackerKit, r/hardware) | These communities are ACTIVELY ANGRY at current platforms. Hot audience. |
| Creator newsletter/YouTube | Creators who've been burned by Kickstarter are a warm audience |
| TikTok (@ogfinancebro angle) | "Kickstarter stole $500 from me — here's what I wish existed" is viral content |
| Hacker News Show HN | Developer credibility for the blockchain infrastructure layer |
| Product Hunt | Launch day amplification |

### The One-Line Pitch That Works
**"Kickstarter, but your money only releases when the creator actually delivers."**

That's it. That's the hook. Secondary market is the power feature you explain after you've got their attention.

---

## 8. CRITICAL RISKS SCOUT FLAGS

### Risk 1: Crypto UX Kills Mainstream Adoption ⭐⭐⭐ HIGH
Every prior blockchain crowdfunding attempt died on this hill. Foundry MUST support fiat payment from day one. The blockchain should be invisible to backers unless they specifically want to use wallet features.

**Mitigation:** Credit card → escrow smart contract. Users don't need to know what chain it's on.

### Risk 2: Regulatory Classification of Reward Tokens ⭐⭐ MEDIUM
Tradeable reward claim tokens could be classified as securities depending on how they're structured. The Howey Test is the relevant standard. If tokens appreciate based on project success and backers buy them expecting profit, that's a security.

**Mitigation:** Frame tokens as "transferable delivery claims" not investment instruments. Ensure rewards are tied to product delivery, not financial returns. Get a fintech lawyer to review before launch. Nick's financial compliance background is relevant here.

### Risk 3: Cold Start Problem ⭐⭐ MEDIUM
A marketplace with no campaigns is a ghost town. Unlike Kickstarter which had years to build supply, Foundry needs creator supply from day one.

**Mitigation:** Seed with 3-5 guaranteed first campaigns before public launch. Approach creators who were burned by Kickstarter directly — they're already motivated.

### Risk 4: Creator Milestone Gaming ⭐ LOW (but worth noting)
What stops a creator from defining milestones so loosely that they always qualify for fund release? "Completed Phase 1" could mean anything.

**Mitigation:** Milestone definitions must be approved by Foundry before campaign goes live. Clear, verifiable, ideally third-party confirmable milestones only.

---

## 9. DEMAND VALIDATION SCORE

Using the 6-factor framework:

| Factor | Score | Notes |
|---|---|---|
| **Problem intensity** | 5/5 | Trustpilot screaming. Hundreds of documented failures. Real money lost. |
| **Willingness to pay** | 4/5 | Backers already pay Kickstarter's 5% (buried in creator fees). Creators will pay for a platform that actually helps them succeed. |
| **Market size** | 5/5 | $20B+ SAM in rewards crowdfunding alone |
| **Competition weakness** | 5/5 | Kickstarter 1.8/5 stars. Indiegogo 1.3/5 stars. Neither has milestone escrow. Nobody has secondary market. |
| **Founder fit** | 4/5 | Nick's fintech background = payment flow expertise. OpenClaw = smart contract build speed. |
| **Distribution path** | 3/5 | Clear channel via disgruntled backer communities, but cold start is real work. |

**Total: 26/30 — Strong GO**

---

## 10. FINAL RECOMMENDATION

**GO. Foundry is one of the strongest ideas I've validated in this research cycle.**

The pain is real, documented, and CURRENT (reviews are from March 2026). The competition is actively failing users. The mechanic is genuinely novel. The tech to build it exists in-house.

**The single most important design decision:**
Make the milestone escrow work with a credit card. If a backer can pay with Visa and never touch a crypto wallet, Foundry can go mainstream. If they have to set up MetaMask on day one, Foundry will stay niche.

**Build sequence:**
1. Milestone escrow + fiat payment layer (core trust product)
2. Campaign management UI for creators
3. Tradeable reward claim tokens (secondary market — launch after first campaign proves milestone mechanic)

**First campaign target persona:**
A hardware or game creator with 10K+ existing community who was burned by Kickstarter. They have the motivation and the audience. Foundry gives them the story.

---

*Scout 🔍 | Research complete | Handoff ready for Chain + Maks*
