# SKILL: Securities Law & Token Classification
**Version:** 1.0.0 | **Domain:** SEC, Howey Test, Token Structures

---

## The Howey Test
*SEC v. W.J. Howey Co., 328 U.S. 293 (1946)*

A token is a security (investment contract) if it involves ALL FOUR:
1. **Investment of money**
2. **In a common enterprise**
3. **With an expectation of profits**
4. **Derived primarily from the efforts of others**

Fail ANY one prong → stronger argument it's NOT a security.

---

## Breaking Down Each Prong

### Prong 1: Investment of Money
**Broad interpretation by courts:**
- Airdrop with no purchase = stronger argument against (but see below)
- If users staked assets, spent money on related product, or performed labor expecting token value → courts find "investment" broadly
- Points-to-token conversion: if users spent money to earn points → arguably an investment

**How to fail this prong:**
- Pure airdrop with no associated purchase, no staking requirement, no work requirement
- Free mint with no expectation created by issuer

### Prong 2: Common Enterprise
**Hardest prong to avoid — courts interpret VERY broadly:**
- "Horizontal commonality": all investors' returns from same pool → common enterprise
- "Vertical commonality": investors' returns depend on the promoter's efforts → common enterprise
- If all token holders' value depends on the same team's work OR same protocol → this prong is almost always met

**Practical reality:** You cannot reliably fail Prong 2 for most token projects.

### Prong 3: Expectation of Profits
**The marketing killer:**
- Purely consumptive utility (use token to pay for service) → no profit expectation
- ONE TWEET saying "we're going to the moon 🚀" or "early buyers will benefit" → profit expectation established
- Token price appreciation through secondary market trading → courts find profit expectation
- Staking yields → profit expectation

**How to fail this prong:**
- Stablecoin pegged to $1 → no appreciation expected → not a security
- Governance-only token with no economic rights → weaker profit expectation argument
- Meme coins (some argue): no team, no roadmap, no utility → no "efforts of others" creates profit

**Critical rule for Nick:** Marketing is the biggest risk. Legal team must review ALL communications before release. The team's words — not just the smart contract — determine securities classification.

### Prong 4: Efforts of Others
**The decentralization defense:**
- "Sufficient decentralization": if no single team's efforts drive value, Prong 4 fails
- Test: if the core team disappeared tomorrow, would the token function and retain value?
- SEC Hinman Speech (2018): Ethereum is "sufficiently decentralized" → not a security (but this is a speech, not law; no Chevron deference post-Loper Bright)

---

## Key Enforcement Precedents

### SEC v. Ripple Labs (2023) — SPLIT RULING
- **Programmatic sales** (on exchanges, no direct buyer-issuer relationship): NOT securities
- **Institutional sales** (direct sales to sophisticated buyers): ARE securities
- **Impact:** XRP on secondary markets can trade without SEC registration; institutional raises require registration
- **Docket:** SEC v. Ripple Labs Inc., 20-cv-10832 (S.D.N.Y.)
- **Status:** Settlement negotiations ongoing (2024-2025)

### SEC v. Terraform Labs / Do Kwon (2024)
- LUNA/UST ruled securities; jury found fraud
- Algorithmic stablecoin backing didn't save them from securities classification
- **Lesson:** "It's a stablecoin" is not a safe harbor if profit expectations were created

### SEC v. Coinbase (ongoing 2024-2025)
- SEC alleges multiple tokens listed on Coinbase are unregistered securities
- Affects: SOL, ADA, MATIC, FIL, SAND, AXS, CHZ, and others
- **Impact:** Secondary market listing could trigger securities law even if original issuance wasn't a security

### SEC v. Uniswap (Investigation dismissed 2024)
- SEC dropped investigation of Uniswap Labs
- Significant: SEC declined to pursue DEX operator for facilitating trading of allegedly unregistered tokens
- **Does NOT mean:** DEX operators are categorically exempt — this was a charging decision, not a legal ruling

### SEC Framework for Investment Contract Analysis (2019)
- SEC staff guidance applying Howey to digital assets
- Available at: https://www.sec.gov/corpfin/framework-investment-contract-analysis-digital-assets
- Note: Staff guidance, not a rule — persuasive but not binding (especially post-Loper Bright)

---

## How Major Projects Structure Tokens to Minimize Securities Risk

| Project | Token | Structure |
|---|---|---|
| Uniswap (UNI) | Governance-only | Airdropped, no profit promises from team, no fee distribution to holders (fee switch not activated until recently) |
| Bitcoin (BTC) | Commodity | Fully decentralized, no issuing team, SEC explicitly says not a security |
| Ethereum (ETH) | Commodity (SEC position) | "Sufficiently decentralized" per Hinman; but staking yields create renewed scrutiny |
| Compound (COMP) | Governance + incentives | Distributed via protocol usage, not sold in ICO |
| Lido (LDO) | Governance | No direct fee rights for token holders initially |

---

## For Agent Sparta Token (AST) — Specific Analysis

**High-risk scenario:** Users buy AST on secondary market expecting value to increase as Agent Sparta platform grows → almost certainly a security (Prongs 1, 2, 3, 4 all met)

**Lower-risk alternatives:**
1. **Utility-only token:** AST used ONLY to pay entry fees; no tradeable secondary market; team never promotes price appreciation
2. **No token:** Use USDC for all payments → zero securities risk from tokens
3. **Points system:** Non-transferable points that unlock features → not a security (no investment, no secondary market)
4. **Governance-only + airdrop:** Airdrop to existing users after platform is live; governance rights only; no financial rights
   - Risk: secondary market trading will emerge; SEC may still scrutinize

**Safest path for MVP:** No token. Use USDC. Add tokenomics only after legal counsel designs the structure and regulatory environment clarifies.

---

## Compliant Token Launch Mechanisms

| Mechanism | Who Can Participate | Disclosure Required | Cost |
|---|---|---|---|
| **Reg D (506b/c)** | Accredited investors only | No general solicitation (b) or with solicitation (c) | $50-200K legal |
| **Reg S** | Non-US persons only | Limited | $50-100K legal |
| **Reg A+** | Public (non-accredited OK) | SEC-qualified offering, up to $75M | $200-500K legal |
| **SAFT** | Accredited investors | Sell investment contract now, deliver utility tokens when network live | $100-200K legal |
| **No sale** | — | Airdrop only | $50-100K legal to structure |

**Most projects:** No US sales + later airdrop to US users (reduces but DOES NOT eliminate risk)

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
