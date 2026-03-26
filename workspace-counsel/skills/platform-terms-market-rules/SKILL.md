# SKILL 66: Platform Terms Architecture & Market Rules

## Purpose
Build the complete legal document stack for a prediction market platform. Know what each document must contain and the provisions that protect you from the specific lawsuits this type of platform attracts.

## Document Hierarchy (All Required at Launch)
1. **Terms of Service (TOS)** — master agreement, all platform use
2. **Privacy Policy** — data collection, use, sharing, rights (CCPA/ICDPA/GDPR compliance)
3. **Market Rules** — how markets operate (resolution, disputes, prohibited conduct)
4. **Fee Schedule** — all fees, clearly disclosed before first transaction
5. **Risk Disclosures** — all risks, prominently displayed (not buried)
6. **Responsible Participation Policy** — self-exclusion, position limits, resources
7. **API Terms** — if offering API access to third parties
8. **Market Maker Agreement** — if using designated market makers
9. **Affiliate/Referral Program Terms** — if offering referral bonuses

## Market Rules Document (Most Critical for Prediction Markets)

### Market Creation Section
- How markets are proposed, reviewed, and published (platform-only vs. user-created)
- Prohibited market categories (explicit list: terrorism, assassination, specific individuals' health/safety, etc.)
- Market metadata requirements: resolution source, resolution date, resolution criteria, trading deadline — ALL required before market goes live

### Trading Rules Section
- Order types available
- Minimum and maximum position sizes (per trade and per market)
- Position limits per user per market (e.g., no more than X% of open interest)
- Margin/collateral requirements (if applicable)
- Trading hours (24/7 or specified hours)
- Fee structure (per trade, percentage, flat fee)

### Resolution Rules Section
- Resolution process (oracle-based, committee-based, hybrid — specify)
- Resolution timeline (within X hours of event outcome)
- Source hierarchy (primary → secondary → tertiary → void)
- Dispute process and timeline
- Void conditions (exhaustive list)
- Partial resolution / edge cases

### Prohibited Conduct (Explicit List)
- Wash trading
- Spoofing
- Front-running / insider trading (trading on MNPI)
- Market cornering (position limits enforce this)
- Multi-accounting (one person, multiple accounts)
- Collusion (coordinated trading to manipulate prices)
- Automated trading without platform authorization
- Sanctions evasion (trading from prohibited jurisdictions)
- Underage participation (under 18)

### Enforcement
- Investigation procedures (platform has sole discretion to investigate)
- Account suspension/termination
- Position liquidation
- Profit disgorgement (clawback of manipulative profits — this is the critical clause)
- Reporting to regulators and law enforcement
- Right to modify rules with [30-day] advance notice

## Fee Schedule Requirements
- All fees disclosed BEFORE the user transacts (FTC requirement)
- Trading fees: percentage of trade volume or flat fee per trade
- Withdrawal fees: if any (specify amount and conditions)
- Market creation fees: if user-created markets
- Inactivity fees: if any — disclose clearly and prominently (these generate complaints and regulatory scrutiny)
- Fee changes: minimum 30-day notice before any fee increases
- No hidden fees: if it costs the user anything, it's in this document

## Risk Disclosures — Required Content and Placement

### Required Statements
- "You may lose your entire deposit"
- "Prediction market outcomes are uncertain"
- "AI predictions may be incorrect" (if AI used)
- "Smart contracts may contain vulnerabilities" (if applicable)
- "Regulatory changes may affect the availability of this platform"
- "Past performance does not guarantee future results"
- "This platform is not regulated by [CFTC/SEC] unless otherwise stated"
- "This is not investment advice"

### Required Placement (Not Buried)
- **Registration page**: before account creation
- **Deposit page**: before first deposit
- **Every page footer**: accessible link to full Risk Disclosures
- **Market page**: abbreviated risk disclosure near "enter position" button

## TOS Critical Provisions Checklist
- [ ] Arbitration clause (individual, not class, remote, AAA rules)
- [ ] Class action waiver (*AT&T Mobility v. Concepcion* basis)
- [ ] Limitation of liability (cap at entry fees paid; no consequential damages)
- [ ] AI judging disclaimer ("as-is," no warranty of accuracy)
- [ ] Force majeure (comprehensive list including blockchain, oracle, regulatory failures)
- [ ] Market pause/void authority (platform's sole discretion)
- [ ] Clawback/disgorgement authority (manipulative profits can be seized)
- [ ] Governing law (Iowa, or jurisdiction of choice)
- [ ] Dispute resolution (exhaust internal process before arbitration)
- [ ] Prohibition on assignment (users can't assign their TOS rights)
- [ ] No third-party beneficiaries
- [ ] Entire agreement clause
- [ ] Severability clause
- [ ] Modification with notice

## Clickwrap vs. Browsewrap
- **Always use clickwrap**: user must affirmatively click "I agree to the Terms of Service" with a link to the document
- **Never use browsewrap**: "by using this site, you agree..." (unenforceable in most courts)
- Critical moments for clickwrap: account creation, first deposit, each new major TOS version
- Store clickwrap acceptance records: timestamp, IP address, user ID, TOS version — for 7 years

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
