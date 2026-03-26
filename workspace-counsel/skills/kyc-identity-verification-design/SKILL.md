# SKILL: KYC / Identity Verification Design

## Purpose
Design a legally compliant, operationally practical KYC (Know Your Customer) and identity verification system for prediction market, skill-game, and fintech platforms. Covers regulatory triggers, tier structure, provider selection, UX considerations, and data retention.

## Risk Level
🔴 High — Inadequate KYC creates FinCEN/BSA violations, tax reporting failures, OFAC sanction exposure, and payment processor termination. Over-aggressive KYC creates friction that kills conversion. This balance must be designed before launch, not retrofitted.

---

## Why KYC Is Required

### FinCEN / Bank Secrecy Act (BSA)
- 31 U.S.C. § 5318(l): "Customer identification program" required for financial institutions
- FinCEN definition of "money services business" (MSB): if you're an MSB, full BSA/AML KYC required
- FIN-2019-G001: Virtual currency businesses that accept/transmit are MSBs
- **Trigger for prediction markets**: If you hold user funds (even briefly), you may be an MSB

### CFTC (For DCMs and Registered Entities)
- DCM Core Principle 12: Customer protection requirements
- Requires verification of customer identity before account opening
- CFTC does not set specific KYC standards — defaults to FinCEN BSA standards

### Tax Reporting (IRS)
- W-9 collection required before any reportable payment ($600+ prize)
- Cannot issue 1099 without taxpayer ID (TIN/SSN)
- Without TIN: must implement backup withholding (24%)
- See `user-facing-tax-treatment` skill

### OFAC / Sanctions
- Must screen all users against OFAC Specially Designated Nationals (SDN) list
- Cannot process any transaction for sanctioned person or entity
- See `ofac-sanctions-screening` skill

### Payment Processor Requirements
- Stripe, Braintree, etc. require platforms to have "reasonable" KYC
- Chargeback defense: KYC records help prove legitimate transactions
- Fraud prevention: KYC reduces synthetic identity fraud

### Age Verification
- COPPA: No collection of data from users under 13
- Platform minimum: 18+ (21+ in some states for certain activities)
- Must have documented age verification process

---

## KYC Tier Structure

Design a tiered system that matches verification depth to transaction risk:

### Tier 0: Anonymous / Browse-Only
**Who**: Visitors, non-registered users
**What they can do**: View public contests, leaderboards, demo features
**KYC required**: None
**Risk**: None

### Tier 1: Basic Registration (Free Play / No Real Money)
**Who**: Registered users, free-to-play participants
**What they can do**: Enter free contests, track performance, view paid contests
**KYC required**:
- Email verification
- Username / display name
- Date of birth attestation (18+ checkbox)
- Agreement to Terms of Service
- Jurisdiction attestation (not from blocked state)
**Risk**: Low — no money movement

### Tier 2: First Deposit / First Entry Fee (Real Money Entry)
**Who**: Users making first real-money transaction
**What they can do**: Enter paid contests, deposit funds
**KYC required** (in addition to Tier 1):
- Full legal name
- Date of birth (verified, not just attestation — DOB must match ID in Tier 3+)
- Physical address (state-level for geo-block confirmation)
- Email (already collected)
- Basic OFAC screening on name + DOB
**Risk**: Medium — real money flows begin

### Tier 3: Prize Claim / Tax Threshold ($600+)
**Who**: Users claiming prizes ≥ $600 cumulative in calendar year
**What they can do**: Receive reportable prize payments
**KYC required** (in addition to Tier 2):
- **W-9 collection**: Legal name, address, SSN/EIN
- Government ID verification (driver's license or passport scan)
- ID selfie match (liveness check)
- OFAC enhanced screening
- Address verification (must match ID)
**Risk**: High — tax reporting obligation triggered

### Tier 4: Large Transactions / High-Volume Users (AML Threshold)
**Who**: Users with cumulative deposits > $3,000 in 30 days OR > $10,000 in 12 months
**What they can do**: Continue using platform with enhanced monitoring
**KYC required** (in addition to Tier 3):
- Source of funds declaration
- Enhanced due diligence (EDD) review
- Ongoing transaction monitoring
- Possible SAR filing if suspicious patterns
**Risk**: Very High — AML obligations most acute here

---

## Provider Selection

### Document Verification + Liveness
**Persona** (persona.com):
- Best-in-class for startups
- Modular: use only the checks you need
- Pricing: $1.50–$3.00 per verification
- Supports: US driver's license, passport, ITIN, W-9 flow integration
- Developer-friendly API + prebuilt UI
- **Recommended for Agent Arena / Bouts**

**Jumio**:
- Enterprise-grade; higher cost ($3–8 per verification)
- Better for large volumes; overkill for early stage

**Stripe Identity**:
- Integrated with Stripe payments
- $1.50 per verification
- Seamless if already using Stripe for payments
- Limited international document coverage

**Onfido**:
- Global coverage; strong for international users
- $2–5 per verification

### OFAC / Sanctions Screening
**Socure** (also does ID + fraud):
- Real-time SDN + watchlist screening
- Strong fraud scoring layer
- Pricing: Volume-based; ~$0.10–0.50 per check

**ComplyAdvantage**:
- Comprehensive sanctions + PEP (politically exposed persons) screening
- Better for high-risk users; overkill for standard users
- ~$0.15–0.50 per check

**Persona** (built-in):
- Persona includes basic OFAC screening in their product
- Sufficient for most use cases at early stage

### Address Verification
**USPS Address Validation API** (free): Verify US address format
**Smarty** (smarty.com): Geocoding + address standardization ($15/month starter)
**Easypost**: Address validation as part of shipping stack

### Tax ID / W-9 Collection
**Stripe Tax** (partial): Helps with 1099 generation; doesn't do W-9 collection itself
**Yearli / Track1099**: Tax form collection and IRS filing services
**Persona**: Can collect W-9 equivalent information as part of KYC flow

---

## UX Design Principles for KYC

### Progressive Disclosure
- Don't ask for SSN at registration — ask when payment is triggered
- Don't ask for ID photo upfront — ask when prize threshold is crossed
- "Just-in-time" KYC reduces abandonment by 30–50%

### Clear "Why We Need This" Messaging
- "To issue your prize payment, federal tax law requires us to verify your identity"
- "We're required to confirm you're 18+ before you can enter paid contests"
- Users who understand the reason comply at higher rates

### Friction Budget
- Tier 1 (registration): < 2 minutes
- Tier 2 (first deposit): < 3 minutes; no ID photo
- Tier 3 (prize claim): < 5 minutes; ID photo required but user is motivated (they won)

### Failure Handling
- ID verification failure: Give users 3 attempts before manual review
- Manual review queue: 24-hour resolution SLA
- Clear error messages (not "verification failed" — say WHY it failed)
- Human escalation path for false positives

---

## Data Retention & Security

### Retention Requirements
- **AML/BSA records**: 5 years from account closure (31 CFR § 1010.430)
- **Tax records (W-9)**: 4 years after tax year filed
- **Transaction records**: 5 years (FinCEN requirement for MSBs)
- **ID documents**: Delete after verification + retention period; don't hold indefinitely

### Security Requirements
- PII (SSN, ID documents) must be encrypted at rest (AES-256 minimum)
- SSN: Store hashed or tokenized after verification; never store plaintext
- ID document images: Store separately from user records; delete after required period
- Access controls: KYC data accessible only to compliance team, not general engineering

### ICDPA / CCPA Implications
- Iowa ICDPA: KYC data = "personal data" subject to Iowa privacy law
- CCPA: California users' KYC data subject to CCPA rights
- Privacy policy must disclose: what KYC data is collected, why, how long retained, who can access

---

## FinCEN Customer Identification Program (CIP) Requirements

If classified as MSB, must maintain a formal CIP with:
1. Written program approved by Board/management
2. Collection of: name, address, DOB, ID number (SSN for US persons)
3. Identity verification (documentary or non-documentary methods)
4. Recordkeeping (5-year retention)
5. Comparison against government lists (OFAC minimum)
6. Customer notification (must tell users they're collecting ID for CIP purposes)

**CIP Notice language (required)**:
> "Important Information About Procedures for Opening a New Account: To help the government fight the funding of terrorism and money laundering activities, federal law requires all financial institutions to obtain, verify, and record information that identifies each person who opens an account."

This notice must be displayed to all new users at registration.

---

## Iowa-Specific Considerations

### Iowa DIA (Skill Contest Registration)
- Iowa Code § 99B.5: Iowa skill contest registration requires identifying the sponsor
- Iowa DIA may review contest operator's identity — KYC records for the business itself, not just users
- Iowa-based operator: Iowa Division of Banking may inspect KYC program if platform is classified as money transmitter

### Iowa Privacy (ICDPA)
- Iowa Code § 715D: Data privacy obligations kick in at 100K Iowa users
- KYC data is "sensitive personal data" under ICDPA
- Must have data processing agreements with KYC providers (they're processors)

---

## Minimum Viable KYC Stack (Pre-Launch)
1. ✅ **Persona** for ID verification (Tier 3 triggers)
2. ✅ **Stripe Identity** for Tier 2 if already on Stripe (age + basic fraud)
3. ✅ **Built-in OFAC screening** via Persona (covers SDN list)
4. ✅ **W-9 collection flow** before first prize payment
5. ✅ **CIP notice** displayed at registration
6. ✅ **Data retention policy** — 5 years for financial records, delete ID docs after period
7. ✅ **Jurisdiction attestation** at registration (not from blocked state — user confirms)

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
