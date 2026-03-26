# SKILL: User Complaint Escalation to Regulators

## Purpose
Design and operate a user complaint system that satisfies regulatory requirements, manages escalation to CFTC/SEC/FTC/state regulators, and reduces enforcement risk by demonstrating good-faith dispute resolution processes.

## Risk Level
🟡 Medium — Absence of a documented complaint process is a regulatory red flag. CFTC DCM Core Principle 10 requires complaint handling. FTC can take action on platforms that trap users without recourse. Having a process dramatically reduces exposure.

---

## Regulatory Requirements

### CFTC (DCM Core Principle 10)
**CEA § 5(d)(10)**: DCMs must establish and enforce disciplinary procedures for rule violations and a customer complaint process.

**Requirements**:
- Written complaint procedures
- Acknowledgment within defined timeframe
- Investigation and resolution process
- Record retention of all complaints
- Annual reporting of complaint data to CFTC (if DCM-registered)
- Referral process for complaints alleging fraud or manipulation

**Even for non-DCM operators**: CFTC has cited absence of complaint processes as evidence of bad faith in enforcement actions.

### FTC (Section 5 Unfair/Deceptive Practices)
- Cannot make it unreasonably difficult to lodge complaints
- Must honor complaint commitments made in Terms of Service
- Must have accessible contact information (physical address, working email minimum)
- **ROSCA (Restore Online Shoppers' Confidence Act)**: If subscriptions involved, must have easy cancellation and complaint path

### FinCEN (BSA Compliance)
- Must have process for users to report suspected money laundering or fraud
- SAR (Suspicious Activity Report) filing obligations — must have internal triage process
- Complaint records may be relevant to SAR investigation

### State Regulators
- **Iowa DIA**: Insurance/financial product complaints go to Iowa Division of Insurance
- **Iowa AG Consumer Protection Division**: Consumer complaint intake
- **CFPB**: Federal consumer financial protection; accepts complaints for fintech/payment products
- **State gaming commissions**: If state-licensed gaming, mandatory complaint process + reporting

### Payment Card Network Rules
- **Chargeback process**: Users disputing charges have card network rights; platform must respond within defined windows (Visa: 30 days; Mastercard: 45 days)
- **Chargeback rate**: Must stay below 1% (Mastercard), 0.9% (Visa) to maintain merchant account
- Dispute management process directly impacts payment processing viability

---

## Complaint Tier Structure

### Tier 1: Platform-Level Resolution (Internal)
**Target**: Resolve 80%+ of complaints here
**Timeline**: 24–72 hours acknowledgment; 7 days resolution
**Types handled**:
- Account access issues
- Incorrect market resolution
- Technical errors affecting bets/positions
- Prize/payout delays
- Promotional disputes

**Required**:
- Dedicated support email (support@[platform].com)
- Ticketing system (Zendesk, Freshdesk, or similar)
- Written response to every complaint
- **Record retention**: 5 years minimum (CFTC requirement for DCMs; best practice for all)

### Tier 2: Escalated Internal Review
**Target**: Complaints not resolved at Tier 1
**Timeline**: 14 days
**Process**:
- Senior/independent reviewer (not original decision-maker)
- Written explanation of decision with reasoning
- Offer of alternative resolution where possible

**Types handled**:
- Market resolution disputes claiming error
- Account closure disputes
- Claims of market manipulation
- Large-value disputes (>$1,000 or >10% of user's total deposits)

### Tier 3: External Dispute Resolution
**Target**: Unresolved after Tier 2
**Timeline**: User-initiated within 30 days of Tier 2 denial
**Options**:
- **Binding arbitration** (per Terms of Service) — AAA or JAMS
- **State AG referral** — Users can file with Iowa AG Consumer Protection
- **CFPB complaint** — Filed at consumerfinance.gov/complaint
- **CFTC complaint** — Filed at cftc.gov/ConsumerProtection/FileaTip (if commodity-related)
- **FTC complaint** — Filed at reportfraud.ftc.gov

**Platform obligation**: Must not obstruct Tier 3 escalation. Terms of Service must disclose external escalation paths.

---

## Regulatory Complaint Portals (Know These)

| Regulator | Portal | Timeframe |
|-----------|--------|-----------|
| CFTC | cftc.gov/ConsumerProtection/FileaTip | No set timeline for response |
| SEC | sec.gov/tcr (Tips, Complaints, Referrals) | No set timeline |
| FTC | reportfraud.ftc.gov | No set timeline |
| CFPB | consumerfinance.gov/complaint | Company must respond within 60 days |
| Iowa AG | iowaattorneygeneral.gov/for-consumers | Varies |
| BBB | bbb.org | 14 days to respond expected |

**Key**: CFPB is the most actionable — companies must respond, and public complaint data is published. High CFPB complaint rates attract regulatory attention.

---

## What Happens When a Regulator Receives a Complaint

### CFTC Process
1. Complaint logged in CFTC complaint system
2. Staff reviews for pattern (multiple complaints = investigation trigger)
3. If fraud/manipulation alleged: referred to Division of Enforcement
4. Platform may receive subpoena or information request
5. **Safe harbor**: Having documented complaint + good-faith resolution process demonstrates compliance culture

### FTC Process
1. Complaint enters consumer sentinel database (shared with law enforcement)
2. FTC aggregates patterns across complaints
3. Investigation if pattern emerges
4. Civil investigative demand (CID) is the formal start of investigation
5. **Risk trigger**: 50+ complaints on same issue = meaningful pattern risk

### Iowa AG Process
1. Complaint sent to company for response (30-day window typically)
2. AG mediates or escalates
3. Civil investigative demand if company unresponsive
4. Iowa Consumer Fraud Act (Iowa Code § 714H) — allows AG injunction and civil penalties

---

## Required Documentation / Policies

### 1. Complaint Handling Policy (Internal)
- Intake procedure
- Triage and routing
- Investigation standards
- Response timelines
- Escalation triggers
- Record retention (5 years minimum)
- Annual complaint report template

### 2. User-Facing Dispute Resolution Page
Must include:
- How to submit a complaint
- Expected response timeline
- What happens if not resolved
- External escalation options (regulators, arbitration)
- Contact information (physical address required by many state laws)

### 3. Terms of Service Provisions
- Arbitration clause (if using)
- Governing law and jurisdiction
- Class action waiver (enforceable in many contexts)
- Survival clause (complaint rights survive account closure)

---

## Red Flags That Trigger Regulatory Escalation
- No published contact information
- Form responses that don't address the substance of complaint
- Closing accounts when users file complaints (looks retaliatory)
- Refusing refunds on technical errors
- Not honoring stated Terms of Service in dispute resolutions
- Pattern of same complaint type (especially payout delays or market resolution errors)

---

## Minimum Viable Complaint System (Pre-Launch)
1. ✅ Support email address published on platform
2. ✅ Ticketing system with case numbers
3. ✅ Written response SLA (72 hours acknowledgment, 7 days resolution)
4. ✅ Escalation path to external regulators disclosed in T&C
5. ✅ Record retention of all complaints (5+ years)
6. ✅ Dispute resolution page linked from footer
7. ✅ No retaliation for complaints (account closure, suspension)

---

## Iowa Angle
- Iowa Consumer Fraud Act (Iowa Code § 714H): Broad consumer protection statute; AG has civil enforcement authority
- Iowa Code § 714H.5: Allows private right of action for consumers (not just AG)
- Iowa-based users have state law protections independent of federal law
- Iowa AG has historically been active in fintech complaints — need responsive process
- **Iowa-specific**: Display Iowa AG contact information for Iowa users: 515-281-5926

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
