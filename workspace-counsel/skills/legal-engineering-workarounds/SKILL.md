# SKILL: Legal Engineering Workarounds
**Version:** 1.0.0 | **Domain:** Structural Compliance, Product Design, Regulatory Arbitrage

---

## The Framework: PROBLEM → RESTRICTION → WORKAROUND → PRECEDENT → RISK → RECOMMENDED

Every regulatory restriction on a product feature can be addressed by one of six structural patterns. The goal is never to break the law — it's to achieve the same user experience through a structure the law permits.

**First question on every feature:** "What is the LEAST regulated way to deliver this user experience?"

---

## Pattern 1: Consideration Elimination (Removes Gambling Classification Entirely)

**Problem:** Platform charges entry fees + awards prizes based on outcomes → gambling under state law
**Restriction:** State gambling statutes require consideration + chance + prize
**Remove ONE element → removes gambling classification**

### Workaround 1A: Free Entry + Sponsored Prizes
- Users enter for FREE. Prizes funded by platform, sponsors, or advertising revenue.
- Zero consideration from users = zero gambling in ANY US jurisdiction
- Revenue model: advertising, sponsorships, data licensing, premium analytics subscriptions
- **Precedent:** FanDuel and DraftKings both ran free contests for years before paid contests. Every major sweepstakes operates this way.
- **Legal authority:** The three-element test for gambling (consideration + chance + prize) in virtually every state requires ALL THREE. Eliminate consideration → not gambling.
- **Risk Level:** 🟢 ZERO gambling classification risk
- **Product impact:** Lower revenue ceiling; requires advertising/sponsorship to monetize

### Workaround 1B: Two-Path Entry (AMOE)
- Offer BOTH free and paid entry to every contest. Free path has IDENTICAL prize eligibility.
- "Alternative Method of Entry" (AMOE) — the cornerstone of sweepstakes law
- Paid entry: enhanced experience (better analytics, more entries, etc.) — NOT consideration for the prize itself
- **Precedent:** Every US sweepstakes with a purchase option offers a "no purchase necessary" path. Required by law for sweepstakes; adopted voluntarily for gambling avoidance.
- **Critical requirement:** Free path must be PROMINENT — displayed equally with paid path, not buried in fine print. If free path is practically impossible, courts will find it doesn't break the "consideration" element.
- **Legal authority:** *Pepsi-Cola Co. v. FTC*, 43 F.T.C. 1400 (1947); state sweepstakes law universally recognizes AMOE breaks consideration element.
- **Risk Level:** 🟢 LOW if free path is genuine; 🟡 MEDIUM if free path is clearly inferior or hidden
- **Implementation:** Every contest page shows both options equally. Free entry requires completing a research task (a 5-question quiz about AI model accuracy). Same prize pool.

### Workaround 1C: Non-Redeemable Virtual Currency Layer
- Users buy "Sparks" (not USD). Sparks used for contest entry. Winners earn more Sparks. Sparks CANNOT be cashed out.
- If Sparks have no cash value and cannot be redeemed → no "prize" of monetary value → not gambling in any state
- Revenue: Spark pack sales (one-way valve — money in, no money out)
- Non-monetary prizes redeemable with Sparks: merchandise, premium features, leaderboard status, early access
- **Precedent:** Every mobile game on the App Store (Clash of Clans, Candy Crush, Fortnite V-Bucks). None are classified as gambling despite billions in virtual currency purchases.
- **Legal authority:** FTC policy on virtual currencies; state gambling statutes universally require a "prize" that has real monetary value
- **Critical rule:** Never allow: (a) user-to-user Spark transfers, (b) Spark-to-cash conversion through any path (including third-party markets), (c) any representation that Sparks have monetary value
- **Risk Level:** 🟢 LOW — industry-wide practice for 20+ years
- **The collapse trigger:** The moment any pathway exists to convert Sparks to cash (even via a secondary market you didn't create), the entire structure collapses. Monitor for gray markets.

---

## Pattern 2: Skill Predominance Engineering

**Problem:** Regulator argues contest has chance elements → gambling
**Restriction:** "Chance" element in state gambling three-part test
**Solution:** Engineer the product so skill DEMONSTRABLY predominates

### Workaround 2A: Verifiable Skill Metrics
- Design contests where EVERY outcome metric traces to a measurable skill decision by the participant
- Agent Sparta: User CHOSE which agent to configure → CHOSE which model to use → CHOSE which skills to install → CHOSE the prompt architecture → Agent performance reflects those choices
- Document the skill chain for every contest type before launch: "User decision X → AI capability Y → Contest metric Z"
- **Legal authority:** Predominance test: "Would a skilled player consistently beat an unskilled player?" (*United States v. DiCristina*, 726 F.3d 92 (2d Cir. 2013)). The answer for agent configuration is YES if you track and publish the data.
- **Risk Level:** 🟢 LOW in ~43 states; 🔴 HIGH in Washington, Arizona, Louisiana, Montana

### Workaround 2B: Publish Scoring Rubric + Statistical Evidence
- Before each contest: publish the EXACT scoring rubric. Participants can study, optimize, and improve.
- After 6 months: publish statistical evidence that top participants win consistently (Gini coefficient of winnings, win rate of returning players vs. new players)
- **Legal authority:** This is exactly the evidence DraftKings submitted to defend DFS as skill-based. Statistical proof of consistent winners = proof of skill predominance.
- *McKeever v. Feathers et al.* (Ohio 2023): Court found DFS skill-based in part because statistical analysis showed experienced players won at significantly higher rates.
- **Risk Level:** 🟢 LOW — you're building the evidentiary record from Day 1

### Workaround 2C: Knowledge Qualification Gate
- Require a skill assessment before entry into paid contests
- "Complete 10 questions about AI model capabilities to unlock paid contests"
- Users who pass demonstrate baseline knowledge → strengthens skill classification
- **Precedent:** Some DFS platforms use tutorials/quizzes before real-money play; chess platforms require rating thresholds for certain tournaments
- **Risk Level:** 🟢 LOW — adds friction but dramatically strengthens legal position

---

## Pattern 3: Custody Elimination (Money Transmitter Avoidance)

**Problem:** Holding user funds → money transmitter → MTL in 50 states ($2M+ in licenses)
**Restriction:** Iowa Code §533C.102; 31 C.F.R. § 1022.100; state MTL statutes
**Solution:** Design so the platform NEVER holds funds

### Workaround 3A: Non-Custodial Smart Contract Escrow
- Entry fees flow: User wallet → smart contract → winner wallet
- Platform has NO ability to access, redirect, or withdraw user funds at any point
- Smart contract contains: deposit function (pulls USDC from user wallet), contest resolution function (distributes to winners), NO admin withdrawal function
- **Legal authority:** FinCEN FIN-2019-G001 (May 9, 2019): Money transmission requires a person to "accept and transmit currency, funds, or other value." If the platform never "accepts" (smart contract accepts; user approves the contract directly) → platform is not the transmitter.
- Augur v1: fully non-custodial prediction market — no enforcement action for money transmission despite billions in volume
- **Risk Level:** 🟢 LOW (for money transmission); 🟡 MEDIUM (FinCEN has not definitively opined on this architecture)
- **Strengthen it:** Renounce admin key OR use a timelock OR use community multisig — eliminates any argument that platform has "constructive custody"

### Workaround 3B: Licensed Passthrough Partner
- Partner with Zero Hash, Circle, or Fireblocks
- They are the licensed money transmitter; you are their technology customer
- Your users are their users for regulatory purposes
- You provide: product, UX, contest logic. They provide: custody, KYC, AML, state MTLs.
- **Precedent:** Robinhood uses Apex Clearing (licensed broker). Cash App uses Sutton Bank (licensed bank). Every successful fintech does this.
- **Legal authority:** Iowa Code §533C.301(3): "A person acting as an authorized delegate of a licensee within the scope of the authority granted by the licensee" is exempt from MTL requirements.
- **Risk Level:** 🟢 LOW — the licensed partner takes on regulatory liability

### Workaround 3C: Closed-Loop Prepaid Access (for Fiat)
- Sell "prepaid access" credits through a licensed processor
- Credits redeemable ONLY on your platform (closed-loop)
- **Legal authority:** 31 C.F.R. § 1010.100(ff)(5)(ii)(B): Closed-loop prepaid access "that is limited to a defined merchant or location" is exempt from FinCEN's stored value definitions
- Not a perfect fit for a multi-contest platform but applicable if you structure each product as a closed-loop system
- **Risk Level:** 🟡 MEDIUM — regulatory boundary between closed-loop and general prepaid is fact-specific

---

## Pattern 4: Securities Law Avoidance for Tokens

**Problem:** Token triggers Howey → securities registration required → $300K+ and 6 months minimum
**Restriction:** SEC v. W.J. Howey Co., 328 U.S. 293 (1946); Securities Act of 1933

### Workaround 4A: Governance-Only Token + Usage Rewards Distribution
- Token has ONLY governance rights (vote on protocol parameters)
- NEVER sell the token — distribute only via usage rewards and airdrops
- No fee distribution, no revenue sharing, no buyback/burn
- Result: Prong 1 (investment of money) — weakened if no purchase required. Prong 3 (expectation of profits) — weakened if token has no economic rights. Prong 4 (efforts of others) — weakened post-decentralization.
- **Precedent:** UNI (Uniswap) — governance token, airdropped, no direct fee rights. Fee switch exists but was not activated for years.
- **Risk Level:** 🟡 MEDIUM — secondary market trading restores profit expectation regardless of distribution method

### Workaround 4B: Progressive Decentralization (Variant Fund Framework)
- Year 1: Build the product. No token. Standard company.
- Year 2: Product has traction. Begin decentralizing governance. Introduce points/reputation.
- Year 3+: Protocol is "sufficiently decentralized." Token launch — Prong 4 (efforts of others) no longer met because no single team drives value.
- Progressively reduce admin key control: timelock → multisig → DAO governance
- **Precedent:** Ethereum (from ICO with Vitalik's team → "sufficiently decentralized" per Hinman, 2018). dYdX (US company v3 → Swiss Foundation v4).
- **Legal authority:** William Hinman speech (SEC, June 14, 2018): "When I look at Bitcoin today, I do not see a central third party whose efforts are a key determining factor in the enterprise." The same analysis applies to any sufficiently decentralized protocol.
- **Risk Level:** 🟡 MEDIUM before decentralization; 🟢 LOW after genuine decentralization

### Workaround 4C: Regulation A+ Qualified Offering (Nuclear Compliance)
- Register the token as a security. Sell it legally.
- Tier 2: up to $75M from accredited AND non-accredited investors
- SEC qualification (3-6 months); ongoing reporting
- **Precedent:** Blockstack (Stacks/STX): first SEC-qualified token offering, 2019. Raised $23M legally.
- **Legal authority:** Securities Act §3(b)(2); 17 C.F.R. §§ 230.251-230.263
- After sufficient decentralization: apply to SEC for relief from reporting obligations under §12(g)(4)
- **Risk Level:** 🟢 ZERO if properly executed — you're complying, not avoiding
- **Cost:** $100K-$300K in legal and accounting fees; 3-6 months

---

## Pattern 5: Jurisdictional Arbitrage

**Problem:** Product is restricted in US but legal elsewhere
**Solution:** Serve the world legally from a favorable jurisdiction; serve the US only for compliant features

### Workaround 5A: Protocol/Interface Distinction (Uniswap Model)
- The PROTOCOL: open-source code deployed on-chain. Not a company. Not regulated. Software.
- The INTERFACE: website/app that lets users interact with the protocol. This IS a company.
- Interface company can geo-block US users for restricted features
- Protocol remains accessible directly (anyone can interact with a smart contract without using your interface)
- **Precedent:** Uniswap Labs (US company) builds the frontend. SEC dropped investigation. The distinction worked.
- **Legal theory:** 17 U.S.C. § 101 (copyright law): software is protected expression. *Bernstein v. DOJ*, 176 F.3d 1132 (9th Cir. 1999): code is speech protected by First Amendment. Publishing open-source code is not "operating" an exchange.
- **Risk Level:** 🟡 MEDIUM — requires genuine separation and truly open-source protocol

### Workaround 5B: Offshore + US Service Entity (Polymarket Model)
- Offshore operating entity (Cayman) → operates the full platform globally
- US LLC → provides software/marketing services only; earns arm's-length service fee
- US users geo-blocked at technical level
- **Legal authority:** CEA §2(i): CFTC has jurisdiction over activities "with a direct and significant connection with activities in, or effect on, commerce of the United States." Genuine geo-blocking + non-US entity weakens this connection.
- CFTC Docket No. 22-09 (Polymarket consent order): $1.4M fine for prior US operations. Offshore structure + geo-block has operated without further enforcement since 2022.
- **Risk Level:** 🟡 MEDIUM — enforcement risk exists but manageable at startup scale

---

## Pattern 6: Regulatory Classification Engineering

**Problem:** Same product could be classified as A (heavily regulated) or B (lightly regulated)
**Solution:** Design toward classification B through genuine structural differences

### Classification Engineering Examples:
| Heavy Regulation | Light Regulation | Design Change |
|---|---|---|
| Prediction market (CFTC) | Survey/research tool (FTC) | Remove money, add academic framing |
| Exchange (DCM required) | Bulletin board (no registration) | Display offers only; users settle directly |
| Gambling (gambling license) | Skill competition (§99B.5) | Ensure skill predominance in outcome determination |
| Money transmitter (MTL) | Technology platform (no MTL) | Non-custodial architecture; partner with licensed entity |
| Security (SEC registration) | Utility token (no registration) | Usage-only design; no economic rights; no sales |
| Lottery (illegal without state franchise) | Sweepstakes (legal everywhere) | Add AMOE free entry path |

**First question on every feature:** "What regulatory classification does this design trigger, and what design change shifts it to a lower-regulated category with the same user experience?"

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
