# SKILL: Offshore Entity Structuring for Crypto Platforms
**Version:** 1.0.0 | **Domain:** Corporate Law, International Tax, Regulatory Arbitrage

---

## Common Corporate Structures

### Structure 1: US LLC/Corp (Onshore, Fully Regulated)
- Delaware LLC or C-Corp
- Subject to all US federal and state regulations
- **Can serve US customers legally** (if compliant)
- Required for CFTC DCM/SEF registration
- Tax: US corporate tax on worldwide income (~21% federal + state)
- **When to use:** Kalshi model (full regulation) OR product doesn't trigger gambling/prediction market law

### Structure 2: Offshore Operating Entity + US Marketing Entity
- **Operating company:** Cayman Islands, BVI, Panama, or Singapore
- **US entity:** LLC providing marketing/support services only
- Platform technically operated by offshore entity
- US users geo-blocked (in theory)
- **This is the Polymarket structure**
- **Risk 1:** CFTC can still pursue offshore entity (proved with Polymarket $1.4M consent order)
- **Risk 2:** If US entity has too much operational control → CFTC pierces the structure
- **Key:** US entity should ONLY do: marketing, sales support, customer service — NO technical operations, NO treasury control

### Structure 3: Foundation + DAO
- Swiss or Cayman foundation holds IP and initial tokens
- DAO governs protocol decisions
- No single legal entity "operates" the platform
- **Precedent:** Uniswap (Uniswap Labs builds frontend; protocol governed by UNI holders)
- **Risk:** CFTC v. Ooki DAO — regulators CAN enforce against DAOs even without a legal entity
- **Risk:** Foundation may be deemed the operator if it controls: admin keys, deployments, or treasury
- **When to use:** Sufficiently decentralized protocol where no entity exercises operational control

### Structure 4: Dual Entity (US Compliance + Offshore Innovation)
- **US entity:** Fully compliant, limited features for US users
- **Offshore entity:** Full platform for non-US users
- Binance model (Binance.US vs. Binance.com)
- **Warning:** Binance faced massive DOJ enforcement action partly because US/offshore "separation" was not genuine
- **Complex to maintain** — regulators scrutinize closely; real operational independence required

---

## Jurisdiction Comparison

| Jurisdiction | Crypto Regulation | Tax | Setup Cost | Speed |
|---|---|---|---|---|
| **Cayman Islands** | No specific crypto regulation; highly flexible | 0% corporate | $10-25K | 2-4 weeks |
| **BVI** | Minimal regulation; popular for crypto | 0% corporate | $5-15K | 1-2 weeks |
| **Singapore** | Clear crypto framework (MAS); strong global reputation | 17% corporate | $5-10K | 2-4 weeks |
| **Switzerland (Zug)** | "Crypto Valley"; clear FINMA framework | ~15% effective | $20-50K | 4-8 weeks |
| **Dubai (DIFC/ADGM)** | Actively courting crypto; VARA framework | 0% for most | $15-30K | 4-8 weeks |
| **Panama** | No crypto-specific regulation; flexible | 0% on foreign income | $5-10K | 2-4 weeks |
| **Estonia** | Was crypto-friendly; tightening (many licenses revoked) | 20% on distributions | $5-15K | 4-8 weeks |
| **Delaware (US)** | Most favorable US state for corporate law | US federal + state | $1-5K | 1 week |

---

## What Makes an Offshore Structure ACTUALLY Work

### Requirements for Genuine Separation
1. **Independent directors** in the offshore jurisdiction (not Nick or US team)
2. **Local registered agent** with real office (not just a P.O. box)
3. **Operational control** genuinely exercised offshore (key technical decisions, contract signing)
4. **Treasury control** in offshore entity (US entity should NOT have control over funds)
5. **Documented services agreement** between US and offshore entities (arm's-length terms)
6. **Separate bank accounts** (US entity should have no access to offshore accounts)

### What Kills an Offshore Structure
- US persons making operational decisions for the offshore entity
- Admin keys controlled by US-based team members
- US entity receiving economic benefit from offshore operations (without arm's-length services agreement)
- CFTC/SEC can look through the structure if "economic substance" of operations is in the US

---

## For Nick's Products

### MVP / Testing Phase:
- **US Delaware LLC** — simplest, cheapest, fastest; no cross-border complexity
- Build and test with no real money on the line

### Scale (Serving Global Non-US Users):
- **Cayman operating entity** + US marketing LLC
- Cayman holds: IP, protocol, treasury, smart contract admin keys
- US LLC: marketing, business development, US customer support
- Estimated setup: $20-40K with experienced crypto counsel

### If Pursuing Kalshi Model (Full US Legality):
- **US C-Corp (Delaware)** → prepares for CFTC DCM application
- Requires $1-5M legal budget and 12-18 month timeline
- Only viable with significant investor backing

### If AI Prediction Market (No US Users):
- **Cayman Foundation** or **Cayman LLC**
- Geo-block US users technically (IP block) and legally (TOS prohibition)
- Accept: some US users will VPN in; your TOS addresses this; enforcement risk is proportional to market size

---

## Post-Loper Bright: Why Offshore Structures Are More Defensible Now

*Loper Bright v. Raimondo (2024): Chevron deference overruled*

- Courts now interpret the CEA independently — agencies can't rely on deference for expansive jurisdiction claims
- This makes legal challenges to CFTC enforcement MORE viable
- Offshore entities with genuine substance can contest CFTC jurisdiction more aggressively
- **Practical impact:** A well-structured offshore entity is a stronger shield post-2024 than it was before

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
