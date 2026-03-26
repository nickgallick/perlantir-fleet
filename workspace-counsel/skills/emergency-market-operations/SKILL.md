# SKILL 64: Emergency Market Operations

## Purpose
When things go wrong on a live prediction market, the first 60 minutes determine whether it's a recoverable incident or a company-ending event. This skill covers the exact protocols.

## Circuit Breaker — When to Pause

### Triggers (Any One Sufficient)
- Market price moves >30% in under 5 minutes (manipulation signal)
- Suspected wash trading detected by surveillance system
- Oracle/resolution source down or returning anomalous data
- Smart contract vulnerability reported or suspected
- Major news event creates ambiguity about an open market's outcome
- Regulatory action received (subpoena, CID, cease and desist)
- Platform infrastructure failure (site down, API unresponsive)

### How to Pause
- **Smart contract**: invoke `pause()` function via admin multisig (2-of-3 minimum)
- **Legal authority (required in TOS)**: "The Platform may pause, suspend, or terminate any market at any time, in its sole discretion, for operational, regulatory, or security reasons."
- **User notification**: within 15 minutes — push notification + email to all users with active positions in paused markets + platform banner
- **Message**: "Market [X] has been temporarily paused for [security / technical / operational] review. We will provide an update within [timeframe]. Your funds are safe."
- **Maximum pause duration**: specify in Market Rules (e.g., 72 hours). If not resolved within maximum pause duration → market voids.

## Emergency Market Voiding

### When to Void
- Resolution is impossible (event cancelled, source permanently unavailable)
- Market was created in error (wrong parameters, duplicate)
- Manipulation confirmed and market integrity is compromised
- Regulatory order to cease operations on specific market
- Force majeure event prevents resolution (see SKILL 51)

### How to Void
- Smart contract: invoke `voidMarket()` → all positions refunded at entry price
- **Refund at entry price, NOT current market value** — current value may be distorted by the manipulation/incident
- **Legal basis (TOS required)**: "The Platform may void any market if: (a) the integrity of the market is compromised; (b) the market cannot be fairly resolved; (c) the underlying event is cancelled or does not occur; or (d) required by regulatory authority."
- **Communication**: explain WHY the market was voided. Vague communications generate lawsuits; transparent communications generally don't.
- **Record**: document the voiding decision, evidence reviewed, who made the decision, time of decision — keep for 5 years.

## Smart Contract Compromise Protocol

### First 15 Minutes
1. **Confirm the exploit**: have your smart contract engineer verify the reported vulnerability
2. **Execute emergency withdrawal** to safe cold multisig if your contract has this function
3. **Contact Seal 911** (security.ethereum.org) for white hat coordination
4. **Pause ALL markets** — not just the compromised one
5. **Disable all deposits** — stop more funds flowing into the compromised contract

### First Hour
1. **Quantify**: how much is at risk? How much has already been moved by the attacker?
2. **On-chain monitoring**: track where stolen funds are moving; coordinate with Chainalysis
3. **Exchange coordination**: if stolen funds move to an exchange → contact that exchange's security team to freeze
4. **Preserve evidence**: screenshot everything, pull transaction hashes, preserve server logs

### User Communication (First Hour)
> "We have detected a security issue affecting the platform. All markets are paused and new deposits are disabled. We are actively investigating and working to protect user funds. Existing positions are secured. We will provide a detailed update within [2 hours]. We are cooperating with blockchain security experts. Your safety is our top priority."

DO NOT: speculate on the amount lost before you know; admit liability; identify the vulnerability publicly before it's fixed.

### Within 24 Hours
- Post-incident report framework: what happened, when it was detected, what funds were affected, what has been recovered, what steps are being taken
- Notify your insurance carrier (cyber liability / smart contract cover)
- Engage outside counsel

## Regulatory Action Emergency (Subpoena/CID/Cease and Desist)

### Receipt Protocol
1. Note exact date and time of receipt — response deadlines start running
2. DO NOT begin producing documents before consulting outside counsel
3. Issue litigation hold IMMEDIATELY: preserve all documents, all Slack/Telegram/Discord, all code, all financial records
4. Contact outside counsel within 2 hours
5. Minimal public communications: "We are cooperating with regulatory inquiries."
6. Brief only: Nick + outside counsel. Not all employees. Not investors yet.

### User Communication (If Required)
If you must pause markets due to regulatory action:
> "Due to a regulatory matter, certain platform operations are temporarily paused. We are cooperating fully with the relevant authorities and working to resume normal operations as quickly as possible. User funds remain secure."

DO NOT admit wrongdoing. DO NOT speculate on the outcome or timeline.

## Communication Templates (Pre-Draft These Before You Need Them)

| Incident Type | Channel | Timing | Tone |
|--------------|---------|--------|------|
| Market pause | Email + push + banner | Within 15 min | Calm, factual |
| Market void | Email + push + banner | Within 1 hour | Transparent, apologetic |
| Smart contract issue | All channels simultaneously | Within 1 hour | Urgent but calm |
| Regulatory inquiry | Minimal public + direct user communication | As needed | Cooperative, neutral |
| Resolution dispute | Email to affected users | Within 24 hours | Explanatory, procedural |

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
