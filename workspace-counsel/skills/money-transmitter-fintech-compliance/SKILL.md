# SKILL: Money Transmitter & FinTech Compliance
**Version:** 1.0.0 | **Domain:** FinCEN, BSA, MSB, State MTL

---

## Federal Level: FinCEN

### When You're a Money Services Business (MSB)
FinCEN Guidance FIN-2019-G001: "Convertible virtual currency" businesses that transmit value are money transmitters.

**You ARE an MSB if you:**
- Accept, transmit, or hold funds on behalf of users
- Hold entry fees in custodial account before distributing to winners
- Convert between currencies/tokens on behalf of users
- Process deposits and withdrawals

**You are NOT an MSB if:**
- Users interact directly with smart contracts; platform NEVER custodies funds
- "Non-custodial" model: user's wallet → smart contract → user's wallet
- Note: FinCEN has NOT provided clear guidance on non-custodial DeFi protocols — gray area

---

## FinCEN Registration (if MSB)

### How to Register
1. File **FinCEN Form 107** at bsaefiling.fincen.treas.gov
2. **Cost:** Free to file
3. **Timeline:** Immediate upon filing (no approval required — it's a registration, not a license)
4. **Deadline:** Within 180 days of starting business

### MSB Compliance Obligations
| Obligation | Requirement |
|---|---|
| **BSA/AML Program** | Written program: policies, procedures, controls |
| **Customer ID (CIP)** | Name, DOB, address, government ID for all users |
| **Identity Verification** | Verify against gov databases or third-party (Persona, Jumio, Onfido) |
| **Sanctions Screening** | Check all users against OFAC SDN list and FinCEN 311 lists |
| **Ongoing Monitoring** | Transaction monitoring for suspicious activity |
| **SAR Filing** | Suspicious Activity Report within 30 days of detection |
| **CTR Filing** | Currency Transaction Report for cash transactions >$10,000 |
| **Record Retention** | 5 years for all KYC records and transaction data |

---

## State Money Transmitter Licenses (MTL)

### The Problem
- Most states require separate MTL
- **Cost:** $50K-$500K per state (surety bonds + application fees + legal fees)
- **Timeline:** 6-18 months per state
- **Total for all 50 states:** $2M-$10M+ over 2-3 years
- This is why most startups avoid being money transmitters

### Iowa MTL Specifics
- Iowa Division of Banking regulates money transmitters
- Iowa Code § 533C — Iowa Uniform Money Services Act
- Iowa requires MTL for "money transmission" — broadly defined
- **For Nick:** Iowa-first license is required if operating as custodial money transmitter from Iowa

---

## Avoiding MTL Requirements — Structural Options

### Option 1: Non-Custodial Smart Contracts ✅ RECOMMENDED
- Users deposit directly into smart contracts from their own wallets
- Smart contracts handle entry fees, prize pools, payouts
- Platform NEVER custodies or controls funds
- **Strongest argument against money transmission**
- **Risk:** If platform controls smart contract admin keys → CFTC/FinCEN may pierce the structure
- **Design requirement:** Use multisig or timelock on admin keys; minimize admin controls

### Option 2: Licensed Payment Processor Partnership ✅ PRACTICAL
- Partner with licensed money transmitter: Circle, Zero Hash, Fireblocks, Stripe (if eligible), Sardine
- They handle all money movement under THEIR license
- **You focus on the product; they handle compliance**
- **Cost:** Revenue share (0.5-2%) or per-transaction fee
- **This is what most compliant crypto startups do for fiat**

### Option 3: Fully Crypto-Native (USDC-only) ✅ EFFICIENT
- Accept deposits only in USDC, USDT, ETH, or SOL
- No fiat on/off ramp in YOUR platform
- Users bring their own crypto from Coinbase, MetaMask, Phantom
- Entry fees: USDC → smart contract escrow → payout in USDC to winner
- **Platform never touches fiat = no payment processor dependency**
- Use MoonPay/Transak/Ramp Network widget for on-ramp if needed (they handle fiat KYC)

### Option 4: Bank Charter (Not for MVP)
- OCC fintech charter or state bank charter
- Exempts from state MTL requirements (banks are exempt)
- **Extreme cost** — only viable at large scale
- Examples: Anchorage Digital (OCC), Kraken (Wyoming SPDI)

---

## FinCEN MSB Registration: Exact Steps

1. **Determine if registration required:** Are you transmitting money on behalf of others? Use non-custodial structure to avoid this if possible.
2. **Gather entity information:** Legal name, EIN, principal office address, ownership structure, services offered
3. **File Form 107:** BSA E-Filing system at bsaefiling.fincen.treas.gov
   - Select "Money Transmitter" under money services
   - Identify states of operation
   - List affiliated MSBs
4. **Designate BSA Compliance Officer:** Named individual responsible for AML program
5. **Develop Written AML Program:** Must include: (a) policies and procedures, (b) designation of compliance officer, (c) training program, (d) independent testing
6. **Implement KYC/CIP:** Collect and verify ID for all customers before account activation
7. **Set up transaction monitoring:** Software or manual review for suspicious patterns
8. **Set up sanctions screening:** OFAC SDN list check on all new customers and periodically
9. **Train employees:** Annual BSA/AML training required
10. **File SARs and CTRs:** Ongoing reporting obligations from day of registration

**Timeline:** Steps 1-3 take 1 day. Steps 4-9 take 2-6 weeks with legal counsel. Step 10 is ongoing.

---

## For Nick's Platforms

### Agent Sparta / AI Prediction Market: Non-Custodial Design
- Entry fees → smart contract escrow (not a platform wallet)
- Payouts → directly from contract to winner's wallet
- Platform never touches funds
- **This structure avoids MSB classification if properly implemented**
- Caveat: consult counsel on admin key governance to ensure you don't have "constructive custody"

### If Custodial Is Required for UX Reasons:
- Partner with Zero Hash or Circle for payment rails
- They hold the MTL; you are their customer, not a money transmitter yourself
- ZERO HASH: https://zerohash.com/crypto-as-a-service — built for exactly this

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
