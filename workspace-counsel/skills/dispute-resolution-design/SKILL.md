# SKILL 42: Dispute Resolution Design

## Purpose
Design legally enforceable, tiered internal dispute resolution systems for contest and prediction market platforms. Minimize external arbitration. Handle AI judge challenges, payment disputes, and smart contract integration.

## Agent Sparta Contest Disputes

### What Gets Disputed
- AI judge scoring (user claims their agent was scored incorrectly)
- Technical failures during competition (network issues, submission errors)
- Disqualification decisions
- Weight class/tier classification

### Tiered Resolution System

**Tier 1 — Automated Review (0-24 hours)**
- Re-run the AI judge with identical inputs using a fresh instance
- If scores within ±5% tolerance → original score stands, dispute closed
- If significant discrepancy (>5%) → escalate to Tier 2
- Log: timestamp, inputs, original score, re-run score, disposition

**Tier 2 — Human Review (24-48 hours)**
- Designated human reviewer (Nick or Forge) examines submission + judge output
- Reviewer has access to: full submission, judge prompt, scoring rubric, all intermediate outputs
- Decision is documented with reasoning
- User notified with explanation (not just outcome)
- If Tier 2 overturns Tier 1: document the specific error and use to improve judge

**Tier 3 — Panel Review (48-168 hours / 7 days)**
- 3-person panel: 1 platform representative, 2 community members with earned reputation score ≥X
- Majority vote (2/3)
- Decision: final and binding within the platform
- Compensation for panelists: small token allocation or reputation reward

**External Arbitration**
- After Tier 3, user may pursue binding arbitration per TOS arbitration clause
- Arbitration: AAA Consumer Rules or JAMS, conducted remotely, individual (no class)
- Fee-shifting: if user prevails, platform pays arbitration costs; if user loses, split

### Smart Contract Integration
- Prize pool held in smart contract escrow
- Tier 1 & 2 outcomes: executed by platform multisig (2-of-3)
- Tier 3 outcome: executed by panel multisig (2-of-3 panel vote triggers release)
- No outcome = no payout; funds locked until resolution
- 30-day timeout: if user doesn't initiate dispute within 30 days of result → result is final, smart contract auto-releases

## Prediction Market Disputes

### Resolution Oracle Design
- Define EXACTLY what data source determines the outcome BEFORE market opens
- Must be specified in the market description: "Resolved using: [URL/feed] at [timestamp]"
- Examples:
  - "Fed rate decision" → Federal Reserve press release at federalreserve.gov
  - "Election result" → Associated Press official call
  - "AI model accuracy" → specified API/benchmark at specified date/time

### Tiered Resolution

**Tier 1 — Automated Oracle Resolution**
- Primary oracle + backup oracle (two independent sources)
- If both agree → resolved automatically
- If they disagree → escalate to Tier 2

**Tier 2 — Dispute Bond System (UMA Optimistic Oracle model)**
- User posts dispute bond (e.g., 5% of their position or $50 minimum)
- Platform has 48 hours to respond
- If dispute succeeds: bond returned + 20% reward
- If dispute fails: bond forfeited (split between platform treasury and successful respondent)
- This eliminates frivolous disputes without blocking legitimate ones

**Tier 3 — Resolution Committee**
- Odd number (3 or 5) qualified members
- Must recuse if they had a position in the market
- Decision: majority, binding
- Timeline: 7 days maximum
- Smart contract execution upon decision

### Payment Disputes

**Chargeback Prevention (for Fiat Payments)**
- Require 2FA for all purchases
- Maintain detailed transaction logs (amount, timestamp, IP, device fingerprint)
- Prominent TOS acknowledgment before purchase (clickwrap agreement)
- Respond to EVERY chargeback with: transaction receipt, TOS acceptance proof, IP logs
- Chargeback threshold: >1% of transactions → payment processor terminates you
- **Best solution**: crypto-only payments eliminate chargebacks entirely (irreversible transactions)

**If Using Fiat**
- Use Stripe or Braintree (both have built-in chargeback management)
- Pre-draft dispute response template (don't write it during a crisis)
- Keep 90-day rolling transaction records
- Subscription vs. one-time: one-time contest entries have higher chargeback rates (buyer's remorse after loss)

## Legal Enforceability Requirements

### TOS Language Required
- "By using the platform, you agree to the dispute resolution process described in Section X"
- "You waive the right to bring disputes outside of this process except as provided herein"
- "The internal dispute resolution process must be exhausted before initiating arbitration"
- "Disputes must be initiated within [30/60] days of the event giving rise to the dispute"

### Enforceability Checklist
- [ ] Disclosed BEFORE user transacts (not buried in TOS no one reads — use clickwrap at purchase)
- [ ] Reasonably fair (multi-tier, human review available, not arbitrary)
- [ ] Not unconscionable (user can still reach external arbitration)
- [ ] Time limits disclosed and reasonable (30-60 days)
- [ ] Arbitration clause: individual arbitration only, no class actions (AT&T Mobility v. Concepcion, 563 U.S. 333 (2011))

## Reference Protocols
- **UMA Optimistic Oracle**: dispute bond model for prediction markets
- **Kleros**: decentralized dispute resolution using token-holder juries
- **Aragon Govern**: DAO governance with integrated dispute resolution
- **AAA Commercial Arbitration Rules**: for external arbitration fallback

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
