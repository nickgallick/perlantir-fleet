# SKILL: Stablecoin Legal Classification

## Purpose
Classify stablecoins under current US legal frameworks across SEC, CFTC, FinCEN, OCC, and state money transmitter law. Determine which stablecoins are safe to use in product operations, prize pools, and payment flows.

## Risk Level
🔴 High — Stablecoin classification is unsettled, actively regulated, and the subject of major pending legislation. Using the wrong stablecoin structure could trigger securities laws (SEC), money transmitter licensing (state), or bank licensing requirements (federal). Get this right before building payment rails.

---

## Current Regulatory Landscape (As of Q1 2026)

### Federal Regulatory Framework — In Flux

**GENIUS Act** (Guiding and Establishing National Innovation for US Stablecoins Act):
- Passed Senate Banking Committee; Senate floor vote pending as of Q1 2026
- Would establish federal stablecoin framework under Federal Reserve / OCC / FDIC oversight
- **Key provisions if passed**:
  - "Payment stablecoins" defined as fiat-backed, 1:1 reserve
  - Bank holding companies and non-bank issuers both permitted
  - Federal preemption of state money transmitter laws for compliant issuers
  - Algorithmic stablecoins largely prohibited
  - Reserve requirements: must hold US dollars, Treasury bills, or similar

**STABLE Act** (House version): More restrictive; requires bank-like charter for stablecoin issuers

**Status**: Congress has not passed comprehensive stablecoin law as of Q1 2026; existing patchwork applies

---

## Classification by Stablecoin Type

### Type 1: Fiat-Backed Stablecoins (USD 1:1)
**Examples**: USDC (Circle), USDT (Tether), PYUSD (PayPal), GUSD (Gemini)

**SEC Position**:
- Not securities under current SEC guidance (no Howey test satisfaction; no expectation of profit from others' efforts)
- SEC Chair Gensler (2023): "Some stablecoins may be securities" — not formally acted on
- Current (2025+) SEC under Atkins: More crypto-friendly; unlikely to pursue fiat-backed stablecoin enforcement

**CFTC Position**:
- Fiat-backed stablecoins used as margin/collateral in commodity contracts: subject to CFTC jurisdiction in that context
- USDC, USDT used as payment: Generally not a commodity contract in itself

**FinCEN / BSA**:
- Stablecoin **issuers** (Circle, Tether) are Money Services Businesses (MSBs) — must register with FinCEN
- **Users** of stablecoins for payments: depends on volume and business model
- **Platforms** that facilitate stablecoin transactions may be MSBs — fact-specific analysis required

**State Money Transmitter**:
- Pre-GENIUS Act: State MTL required if you "transmit" stablecoins in many states
- NY: BitLicense covers stablecoin transmission
- California: Money Transmission Act covers digital asset transmission
- Iowa: Iowa Code § 533C — "Money Services Act" — stablecoin transmission likely requires license
- **Risk**: Operating stablecoin payment flows without MTL in key states = enforcement risk

**Recommended use**: USDC (Circle) — most regulatory-compliant, US-regulated issuer, NYDFS-supervised, reserve transparency

### Type 2: Algorithmic / Endogenous Stablecoins
**Examples**: Terra/LUNA (collapsed 2022), Basis, FRAX (partially)

**Classification**: 
- SEC: Likely securities (profit expectation from algorithm/protocol performance)
- GENIUS Act (if passed): Would prohibit new algorithmic stablecoins
- **Risk level**: ⚫ Existential — Do NOT build products around algorithmic stablecoins

### Type 3: Commodity-Backed Stablecoins
**Examples**: PAX Gold (PAXG), Tether Gold (XAUT)

**Classification**:
- SEC: Commodity-backed = likely not a security
- CFTC: Gold-backed = commodity; may trigger commodity pool/derivative regulations in some contexts
- **Risk**: More complex; not recommended for simple payment use cases

### Type 4: Crypto-Collateralized Stablecoins
**Examples**: DAI (MakerDAO), LUSD (Liquity)

**Classification**:
- SEC: Gray area; governance tokens (MKR) more clearly securities risk; DAI itself borderline
- CFTC: DAI as payment medium — likely not commodity contract; DAI as CDP (collateralized debt position) — more complex
- **Risk**: More complexity than fiat-backed; avoid for prize pools unless you have CFTC counsel clearance

---

## Stablecoin Use Cases for Agent Arena / Bouts

### Use Case 1: Prize Pool Denomination
**Safest option**: USDC
- Circle is regulated, transparent reserves, US-based
- USDC widely accepted for prize pool administration
- IRS: USDC prize at FMV = ordinary income to winner (see user-facing tax treatment skill)
- **Watch**: If you hold USDC in escrow awaiting contest resolution, you may be a money transmitter

### Use Case 2: User Deposits / Withdrawals
**Risk**: This is where MTL licensing becomes critical
- Accepting USDC from users and holding it = money transmission in most states
- **Safe path**: Use a licensed third-party payment processor that handles USDC (Stripe Crypto, Transak, MoonPay)
- **Risky path**: Direct USDC custody by the platform without MTL licensing

### Use Case 3: On-Chain Smart Contract Prize Pools (Base/Ethereum)
**Structure**: Prize pool funds held in smart contract, auto-released on contest resolution
- CFTC: Automated settlement via smart contract doesn't change underlying classification of the market
- SEC: Smart contract custody ≠ securities issuance if underlying assets are USDC
- **Practical risk**: Smart contract code is law — bugs = losses; get audited
- **Legal risk**: If contest resolution is disputed, who controls the smart contract? Platform must retain override authority for disputes

### Use Case 4: USDC as Platform Revenue (Fee Collection)
- Generally fine — USDC denominated fees = same as USD fees for most purposes
- Must report USDC revenue at FMV for income tax (IRC § 61)
- FinCEN: Receiving USDC as business revenue is not itself money transmission

---

## Money Transmitter Licensing (MTL) Analysis

### Trigger Analysis: Do You Need an MTL for Stablecoin Use?

**Likely YES (MTL Required)**:
- Accepting stablecoin deposits from users and holding on their behalf
- Allowing users to withdraw stablecoins to external wallets
- Moving stablecoins between users (peer-to-peer)
- Operating a stablecoin exchange or conversion service

**Likely NO (MTL Not Required)**:
- Using stablecoin as internal unit of account with no user custody
- Instant delivery (no holding period) — some state exemptions
- Using licensed third-party processor for all stablecoin movement
- Business-to-business payments only (some state B2B exemptions)

### Iowa MTL Analysis
- Iowa Code § 533C.102: "Money services" includes "money transmission"
- Iowa Code § 533C.103: Definition of "monetary value" may include digital assets / stablecoins
- Iowa Division of Banking: Regulates money transmitters; crypto coverage unclear pre-GENIUS Act
- **Iowa approach**: Iowa has not issued definitive guidance on crypto MTL requirements; FDIC-insured bank alternative may be cleanest path
- **Risk in Iowa**: Low enforcement history on crypto MTL; medium legal risk

### Multi-State MTL Reality
- 49 states + DC + Puerto Rico + USVI = 52 jurisdictions with MTL requirements
- Cost: ~$500K–$2M+ to obtain nationwide MTL coverage
- Timeline: 12–24 months
- **Alternative**: Partner with a licensed money transmitter (Green Dot, West Union, Stripe) and operate under their umbrella

---

## Recommended Stablecoin Stack for Bouts/Agent Arena

| Function | Recommended | Why |
|----------|-------------|-----|
| Prize pool denomination | USDC | Most regulated, transparent reserves |
| Smart contract escrow | USDC on Base | Low fees, Coinbase-backed chain, USDC native |
| User fiat on-ramp | Stripe (fiat) or Transak/MoonPay for crypto | Licensed, handles MTL compliance |
| Revenue/fee receipt | USDC or direct fiat | Simpler for accounting |
| Avoid entirely | USDT, algorithmic stablecoins | Tether offshore/less transparent; algo stablecoins = regulatory risk |

---

## Regulatory Resources
- FinCEN Stablecoin Guidance: FIN-2019-G001 (crypto as money)
- OCC Interpretive Letter 1179 (2021): National banks may hold stablecoin reserves
- GENIUS Act bill text: S.394 (119th Congress)
- Circle USDC Regulatory page: https://www.circle.com/en/usdc
- Iowa Division of Banking: https://idob.iowa.gov

---

## Iowa Angle
- Iowa Code § 533C: Money Services Act — primary MTL statute
- Iowa has limited crypto-specific guidance; default to federal framework
- Iowa Division of Banking has discretion on enforcement; proactive engagement recommended
- No Iowa AG enforcement history specifically on stablecoins (as of 2026)

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
