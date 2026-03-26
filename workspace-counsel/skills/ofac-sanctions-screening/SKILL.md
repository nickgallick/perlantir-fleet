# SKILL: OFAC / Sanctions Screening

## Purpose
Implement and maintain OFAC (Office of Foreign Assets Control) and broader sanctions screening for a prediction market / fintech platform. Covers legal requirements, screening triggers, provider selection, false positive handling, and record-keeping obligations.

## Risk Level
🔴 High — OFAC violations carry strict liability civil penalties up to $1,032,684 per violation (2024 inflation-adjusted figure) regardless of intent. "We didn't know" is not a defense. This must be implemented before any real-money transaction.

---

## What Is OFAC?

OFAC is the US Treasury Department office that administers and enforces economic and trade sanctions. They maintain several key lists:

### Key Lists to Screen Against

**1. Specially Designated Nationals (SDN) List**
- The primary list: ~7,000+ individuals and entities
- Includes: terrorists, narcotics traffickers, WMD proliferators, sanctioned government officials
- Maintained at: https://ofac.treasury.gov/sdn-list
- Updated: Multiple times per day
- **All US persons are prohibited from transacting with anyone on this list**

**2. Consolidated Sanctions List**
- Combines SDN + all other OFAC sanctions programs
- Broader than SDN alone
- API available from OFAC at no cost: https://ofac.treasury.gov/sanctions-list-service

**3. Sectoral Sanctions Identifications (SSI) List**
- Targets specific sectors of Russian economy (finance, energy, defense)
- More nuanced restrictions — may not prohibit all transactions

**4. Country-Based Sanctions Programs**
- Comprehensive sanctions (no transactions whatsoever):
  - Cuba
  - Iran
  - North Korea (DPRK)
  - Syria
  - Crimea / Donetsk / Luhansk (Ukraine regions under Russian occupation)
  - Russia (broad financial sanctions since 2022)
  - Belarus (targeted sanctions)
- **Geo-block all these countries** — see `blocked-jurisdiction-list` skill

---

## Legal Requirements

### Who Must Screen
**31 CFR Parts 500–599**: All US persons must comply with OFAC regulations
- "US person" includes: any US citizen, US resident, entity organized under US law, anyone in US territory
- **Your platform is a US person** (Iowa-incorporated entity) — mandatory compliance

### When Screening Is Required
- Before any financial transaction (deposit, prize payout, entry fee processing)
- At account opening (screen new user)
- On an ongoing basis (SDN list updates daily; existing users could become listed)
- Before any wire transfer or crypto transaction

### Penalties for Non-Compliance
- **Civil penalty**: Up to $1,032,684 per violation (2024 CMP; adjusted annually for inflation)
- **Criminal penalty**: Up to $1M fine and 20 years imprisonment for willful violations
- **Strict liability**: Civil penalties apply even without knowledge of violation
- **Egregious violations**: OFAC may add company to Specially Designated Nationals list itself (business death sentence)

---

## Screening Implementation

### What Information to Screen

**Minimum required (name + DOB)**:
- Full legal name (first + last)
- Date of birth
- Country of residence

**Enhanced (reduces false positives)**:
- Full address (city, state, country)
- Government ID number (passport, driver's license)
- SSN (for US persons at prize claim stage)

**For crypto transactions (additional)**:
- Wallet address (OFAC has sanctioned specific crypto addresses — must screen wallet addresses)
- Reference: OFAC's digital currency addresses list

### Fuzzy Matching
- Don't do exact name match only — "Mohammad Al-Hassan" ≠ "Mohammed Al-Hasan" but could be same person
- Use fuzzy/phonetic matching: 85–95% similarity threshold recommended
- OFAC guidance: "reasonable screening" — must catch obvious name variants

### Screening Frequency
- **At account creation**: Screen all new users before account activation
- **At first transaction**: Screen before processing any deposit
- **Periodic re-screening**: Screen all active users quarterly (SDN list changes daily)
- **On list update**: Major list updates (new country sanctions, etc.) may trigger immediate re-screen
- **At prize payout**: Screen immediately before sending any prize payment

---

## Provider Selection

### Standalone OFAC Screening

**Castellan (formerly Comply Systems)**:
- US-focused OFAC + BSA screening
- $0.05–0.20 per check
- Good for high-volume, low-complexity use cases

**LexisNexis Risk Solutions (WorldCompliance)**:
- Comprehensive global sanctions + PEP screening
- $0.25–1.00 per check depending on data sets
- Best for international users

**Dow Jones Risk & Compliance**:
- Premium data; comprehensive screening
- Higher cost; better for financial institution-level compliance

**OFAC Direct API (Free)**:
- OFAC provides free API access to SDN list
- Requires building your own fuzzy matching logic
- Not recommended for production without significant engineering investment
- Use as supplement, not primary

### Combined KYC + OFAC Screening

**Persona** (recommended for Agent Arena / Bouts):
- Includes OFAC SDN screening + watchlist as part of KYC flow
- Fuzzy matching included
- Pricing bundles KYC + OFAC
- Best integration path if using Persona for ID verification

**Socure**:
- Industry-leading fraud + identity + OFAC combo
- More sophisticated than Persona for financial institution use cases
- Higher cost; enterprise-focused

**Jumio**:
- Integrated OFAC screening in ID verification flow
- Good for international coverage

**Stripe** (limited):
- Stripe Radar does some OFAC screening internally
- Not transparent about their screening; cannot rely on Stripe alone for OFAC compliance
- Supplement with dedicated provider

### Crypto Wallet Screening

**Chainalysis Sanctions Screening**:
- Screens crypto wallet addresses against OFAC's digital asset list
- Required if accepting crypto deposits/payouts
- $0.10–0.50 per address check
- Also flags high-risk transaction patterns (darknet markets, mixers)

**TRM Labs**:
- Alternative to Chainalysis; competitive pricing
- Strong blockchain analytics + sanctions screening

**Elliptic**:
- Third major crypto analytics provider
- Good for DeFi protocol interactions

---

## False Positive Handling

### False Positives Are Common
- "John Smith" will match hundreds of SDN list names
- ~2–10% of name searches produce potential matches that must be cleared
- Must have a process — cannot just block all potential matches

### Resolution Process

**Step 1: Automated pre-screening** (tool does this)
- Exact match: Block immediately, escalate to compliance review
- High confidence (>90%): Hold transaction, trigger manual review
- Low confidence (50–90%): Flag for review within 24 hours
- Below threshold: Clear automatically, no action

**Step 2: Manual Review (Compliance Team)**
Timeline: Same-day for blocked transactions; 24 hours for flagged
Review includes:
- Compare DOB, address, nationality against SDN entry
- Check passport/ID numbers if available
- Document review decision and reasoning

**Step 3: Clearance or Block**
- Cleared: Document decision, allow transaction, no further action
- Blocked: File OFAC report (required), freeze account, contact OFAC if unclear

**Step 4: OFAC Reporting (If Blocked)**
- If you block a transaction involving potential SDN hit: Must report to OFAC within 10 days
- **Blocked property report**: Required within 10 days of blocking
- Annual filing of all blocked property: Due September 30 each year
- OFAC reporting form: Available at ofac.treasury.gov

---

## Record-Keeping Requirements
- All OFAC screening records: **5 years minimum** (31 CFR § 501.601)
- Blocked transactions: Indefinite until OFAC resolution
- Screening decisions (including false positive clearances): Document reason for clearance
- Must be producible on OFAC examination

---

## OFAC Compliance Program Components

A complete OFAC compliance program includes (OFAC's own framework — "A Framework for OFAC Compliance Commitments"):

1. **Management commitment**: Written policy approved by senior management
2. **Risk assessment**: Document your business's specific OFAC exposure
3. **Internal controls**: Screening procedures, approval workflows
4. **Testing and auditing**: Periodic testing of screening effectiveness
5. **Training**: Annual training for all employees handling transactions

**For early-stage companies**: A 2-3 page written OFAC compliance policy + documented screening provider + incident response procedure = sufficient for initial compliance demonstration

---

## Crypto-Specific OFAC Issues

### Sanctioned Wallet Addresses
- OFAC has published dozens of specific crypto wallet addresses as SDN
- Transacting with sanctioned wallet = violation even if you don't know the owner
- Example: OFAC sanctioned Tornado Cash (crypto mixer) wallet addresses in 2022
- **Must screen wallet addresses**, not just user identities, for crypto transactions

### Smart Contract Interactions
- OFAC v. Tornado Cash: OFAC sanctioned a smart contract itself (controversial; litigation ongoing)
- **Risk**: If your smart contract interacts with a sanctioned contract, may trigger OFAC violation
- Screen all smart contracts your platform interacts with against OFAC's digital asset list

### Chainalysis Reactor / TRM Labs
- Use blockchain analytics to screen transaction history of incoming crypto wallets
- "Tainted" crypto (funds that passed through sanctioned addresses) creates OFAC exposure
- Recommended: Screen all incoming crypto deposits for >$500 transactions

---

## Iowa Angle
- Iowa Code § 533C: Iowa money transmission law incorporates federal BSA/AML/OFAC requirements
- Iowa Division of Banking: Examines Iowa money transmitter licensees for OFAC compliance
- Iowa-based company: Same OFAC obligations as any US entity — no state-specific carve-outs
- Iowa AG: Could refer OFAC violations to federal authorities; cooperation strongly advised if violation occurs

---

## Minimum Viable OFAC Program (Pre-Launch)

1. ✅ **Persona** or equivalent: OFAC SDN screening at account creation + first transaction
2. ✅ **Geo-block**: All OFAC comprehensive sanctions countries (see `blocked-jurisdiction-list`)
3. ✅ **Crypto wallet screening**: Chainalysis or TRM for any crypto transactions
4. ✅ **Written OFAC compliance policy**: 2-3 pages; management approved
5. ✅ **False positive resolution SOP**: Same-day review process documented
6. ✅ **Blocked property reporting**: Know the OFAC reporting form and timeline
7. ✅ **Record retention**: 5-year minimum for all screening records
8. ✅ **Quarterly re-screen**: All active users against updated SDN list

---

## Key Resources
- OFAC SDN List: https://ofac.treasury.gov/sdn-list
- OFAC Compliance Framework: https://ofac.treasury.gov/faqs/topic/1541
- OFAC Reporting Portal: https://home.treasury.gov/policy-issues/financial-sanctions/reporting-procedures
- Persona OFAC screening: https://withpersona.com
- Chainalysis: https://chainalysis.com

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
