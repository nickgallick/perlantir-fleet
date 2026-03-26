# SKILL: Creative Entity Structures
**Version:** 1.0.0 | **Domain:** Corporate Structuring, Multi-Entity Strategy, Asset Protection

---

## The Perlantir "Swiss Army Knife" Structure

```
Nick Gallick (Individual — Iowa resident)
    └── Perlantir Holdings LLC (Delaware) — Holding company, asset protection
            ├── Agent Sparta LLC (Delaware C-Corp) — US skill competition platform
            │       └── Iowa branch/nexus (registered foreign entity)
            ├── Perlantir Labs LLC (Delaware) — Software dev + consulting services
            ├── Perlantir Foundation (Cayman Foundation Company) — Protocol IP + treasury
            │       └── AI Prediction Protocol (no entity — decentralized smart contracts)
            └── UberKiwi LLC (Iowa) — Existing SMB agency (keep separate)
```

### Why Each Entity:

**Perlantir Holdings LLC (Delaware)**
- Holds equity interests in all operating companies
- Asset protection: if one subsidiary is sued, other subsidiaries' assets are shielded
- Pass-through taxation (LLC) OR S-Corp election to reduce SE tax
- Delaware: most developed LLC law; no tax on royalties from out-of-state sources
- Formation: $90 filing fee; $300/year franchise tax

**Agent Sparta LLC (Delaware C-Corp preferred)**
- QSBS eligibility (§1202): if Nick ever sells, up to $10M gain excluded from federal tax — 5-year clock starts NOW
- Venture capital ready: institutional investors expect C-Corp; LLCs cause UBTI issues for tax-exempt investors
- US entity serving US users under §99B.5 (Iowa skill competition law) with proper registrations
- Register as foreign entity in Iowa (Iowa Code §489.902): file Application for Certificate of Authority with Iowa SOS, $100 fee
- Iowa tax nexus: pay Iowa income tax on Iowa-source income

**Perlantir Labs LLC (Delaware)**
- Earns revenue from: software development services, technology consulting, API licensing
- Provides services to Perlantir Foundation under arm's-length services agreement
- US tax: pays on all revenue (domestic services income)
- Separates services revenue from competition revenue (different risk profiles, different regulatory exposure)

**Perlantir Foundation (Cayman Foundation Company)**
- Cayman Foundation Companies Act, 2017: no members, no shareholders
- Holds: prediction market protocol IP, smart contract admin keys (via multisig), treasury in USDC/ETH
- Governed by: charter + supervisors + enforcer (bound to follow token holder governance eventually)
- Labs provides development services to the Foundation under a documented services agreement
- Foundation pays: arm's-length service fees to Labs (reasonable, documented transfer pricing)
- Non-US income earned by Foundation: not subject to US corporate tax (Foundation is not Nick's CFC if structured correctly — see tax optimization skill)
- Cayman: 0% corporate tax, flexible governance law, respected internationally
- Cost: $15-25K setup + $5-10K/year maintenance

**The AI Prediction Protocol (No Entity)**
- Open-source smart contracts deployed on Ethereum/Base/Solana
- No operator, no admin (admin keys renounced or timelocked)
- Multiple interfaces can be built by anyone (Foundation builds one; community can build others)
- Foundation-operated interface geo-blocks US users
- Protocol itself is accessible directly by any user anywhere
- This is the Uniswap model applied to prediction markets

---

## Delaware C-Corp vs. Iowa LLC — Decision Matrix

| Factor | Iowa LLC | Delaware C-Corp |
|---|---|---|
| QSBS (§1202) | ❌ Not eligible | ✅ Up to $10M tax-free gain |
| VC investment | ⚠️ Problematic for tax-exempt investors | ✅ Standard VC structure |
| Formation cost | $50 | $90 (Delaware) |
| Annual maintenance | $60/year | $300/year Delaware franchise + Iowa foreign registration |
| SE tax reduction | ✅ Via S-Corp election | ✅ Via salary + dividend split |
| Iowa income tax | Iowa LLC: pass-through to Nick (3.8%) | C-Corp: 5.5% entity + 3.8% individual dividend |
| Complexity | Low | Medium |
| **Recommended for** | UberKiwi, Perlantir Holdings | Agent Sparta (if raising capital or planning exit) |

---

## Series LLC (Delaware) — One Entity, Multiple Products

**Authority:** Delaware LLC Act §18-215

**How it works:**
- One master Delaware LLC with multiple "series" — each series has separate assets and liabilities
- Series A: Agent Sparta competitions
- Series B: Prediction market (when ready)
- Series C: Future products
- Each series can have different members, managers, economic allocations

**Advantages:**
- Cheaper than multiple separate LLCs (one formation, one registered agent)
- Liability separation: if Series A is sued, Series B assets are shielded (if properly maintained)
- Single operating agreement with series-specific appendices

**Critical limitations:**
- **Iowa does NOT recognize series LLCs:** If Iowa courts are asked to adjudicate the liability separation, they may not respect it. Iowa Code Chapter 489 has no series LLC provisions.
- Bankruptcy: series LLC liability separation is untested in bankruptcy — a bankruptcy trustee may pierce the series and treat all assets as one estate
- Best use: Delaware courts and Delaware-governed operations; less reliable for Iowa-domiciled operations

**Practical recommendation:** Use separate Delaware LLCs for Agent Sparta and the prediction market platform. The added cost ($300/year franchise + registered agent) is worth the certainty of liability separation.

---

## Protected Cell Company (Cayman)

**Authority:** Cayman Islands Segregated Portfolio Companies Act (amended multiple times)

**How it works:**
- One offshore entity with multiple "cells" — each cell has completely separate assets and liabilities
- Each cell can hold: separate treasury, separate IP, separate protocol
- If one cell's liabilities exceed its assets: creditors of that cell CANNOT reach other cells' assets

**Use case for Nick:**
- Cell 1: AI Prediction Protocol (Cayman treasury, protocol IP)
- Cell 2: Future DeFi protocol (separate treasury)
- Cell 3: Investment/treasury management

**Cost:** $20-40K setup + $10-15K/year + registered agent in Cayman

**Advantage over Cayman Foundation:** More flexible for multi-product structure; Foundations are single-purpose by design.

---

## Wyoming DAO LLC — When Governance Decentralizes

**Authority:** Wyoming Revised Statutes §§ 17-31-101 through 17-31-115

**When to use:** When the prediction market protocol's governance begins to decentralize to token holders

**Setup:**
1. File Certificate of Organization with Wyoming SOS (wyobiz.wyo.gov): $100 + $100/year
2. Designate as "decentralized autonomous organization" in the certificate
3. Include smart contract address(es) in the filing
4. Specify: "algorithmically managed" (smart contract governs) rather than "member-managed"
5. Operating Agreement: binds member actions to governance vote outcomes

**How it integrates with the Perlantir structure:**
- Perlantir Foundation holds protocol IP and treasury
- Wyoming DAO LLC is the governance entity that CONTROLS the Foundation via charter provisions
- Foundation supervisors are bound to follow Wyoming DAO LLC governance votes
- Token holders vote in Wyoming DAO LLC → votes execute via Foundation's charter

**Limitation:** Wyoming DAO LLC provides limited liability protection for token holders, but it is NOT a complete shield from federal regulatory enforcement (CFTC v. Ooki DAO showed that federal agencies can pursue DAO members even with a legal wrapper).

---

## The Timing Sequence (When to Form Each Entity)

| Phase | Entity Action | Cost | When |
|---|---|---|---|
| Month 1 | Form Iowa LLC for UberKiwi operations | $50 | Existing |
| Month 1 | Form Agent Sparta Delaware C-Corp | $90 + $300/yr | Before first line of code |
| Month 2 | Register Agent Sparta as foreign entity in Iowa | $100 | Before Iowa DIA registration |
| Month 6 | Form Perlantir Holdings Delaware LLC | $90 + $300/yr | Before raising any capital |
| Year 1-2 | Form Perlantir Labs Delaware LLC | $90 + $300/yr | Before first consulting revenue |
| Year 2 | Form Perlantir Foundation (Cayman) | $15-25K | Before prediction protocol launch |
| Year 3+ | Form Wyoming DAO LLC | $100 + $100/yr | When governance decentralizes |

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
