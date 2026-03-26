# SKILL: Bot and Automated Trading Policy

## Purpose
Design legal, compliant policies governing bots and automated trading on prediction market / skill-game / AI competition platforms. Covers regulatory requirements, competitive integrity, anti-manipulation rules, and product design considerations.

## Risk Level
🟡 Medium — Unaddressed bot activity creates market manipulation liability (CFTC), payment fraud risk, and competitive integrity problems that destroy user trust. Day-one operational issue for any real-money competition or prediction market.

---

## Why This Matters Legally

### CFTC Market Manipulation
**CEA § 9(a)(2)**: Prohibits any person from manipulating or attempting to manipulate commodity prices
**Regulation Part 180**: CFTC anti-manipulation and anti-disruptive practices rules

**Bot-related violations**:
- **Spoofing**: Placing and canceling orders to create false price signals (already major CFTC enforcement area for traditional futures)
- **Layering**: Similar to spoofing with layered fake orders
- **Wash trading**: Trading against yourself (bot-on-bot) to create artificial volume
- **Artificial price movements**: Bot-coordinated trades to move contract prices

**Enforcement risk**: CFTC has fined traditional exchanges hundreds of millions for spoofing. For prediction markets, same principles apply if the market is classified as a commodity contract market.

### Anti-Money Laundering (AML)
**BSA 31 U.S.C. § 5318**: Bots can be used for layering (AML technique)
- Automated accounts cycle funds through the platform to obscure source
- Pattern: Rapid deposits, trades, withdrawals that net near-zero financially but move money
- Platform must have automated bot detection as part of AML program

### Unfair Competition / FTC
- Bots that give operators or insiders information advantages over retail users = FTC deceptive practices risk
- "Fairness" representations in T&C/marketing create obligations

### For AI Coding Competition (Agent Arena / Bouts)
**Unique issue**: The PRODUCT is AI agents competing. The policy must distinguish:
- **Legitimate**: AI agents competing in authorized ways per contest rules
- **Prohibited**: Automated systems betting on competition outcomes using non-public information
- **Gray area**: Operators or contest participants using market information from their own agents' performance

---

## Categories of Bot Activity

### Category 1: Platform Operators (Explicitly Authorized)
- Market-making bots operated by the platform to provide liquidity
- Automated settlement and resolution bots
- Compliance monitoring bots
- Must be disclosed in platform rules; should not trade against users

### Category 2: Third-Party Market Makers (Conditionally Authorized)
- Liquidity providers authorized by the platform
- Must sign market maker agreement with anti-manipulation provisions
- Must be disclosed to users that market makers exist
- Subject to surveillance for wash trading and spoofing

### Category 3: Power Users / Automated Strategies (Regulated)
- Users who employ automated strategies through official API
- Permitted under platform rules with registration
- Subject to same anti-manipulation rules as manual traders
- Rate limits and position limits apply
- Must agree to bot/API terms

### Category 4: Unauthorized Bots (Prohibited)
- Scraping-based automation
- Account farming (multiple accounts per person)
- Bots that exploit platform vulnerabilities
- Coordinated manipulation rings
- Insider information bots (using non-public event information)
- **For AI competitions**: Bots that cheat the contest judging mechanism

---

## Required Policy Elements

### 1. Bot Registration / API Terms
**If you allow bots**: Require registration
- Separate API Terms of Service
- Disclosure of automated nature of account
- Agreement to anti-manipulation rules
- Rate limits per API key
- Contact information for bot operator
- Kill switch obligation (bot must stop on platform demand)

### 2. Prohibited Activities (Explicit List in Terms)
Must explicitly prohibit:
- Spoofing and layering
- Wash trading (trading against own accounts)
- Coordinated trading to artificially move prices
- Account sharing / multiple accounts
- Use of non-public information (insider trading — see separate skill)
- Reverse engineering platform mechanics to gain unfair advantage
- API key sharing or resale
- Exceeding rate limits or circumventing them

### 3. Surveillance and Detection
**Platform obligations**:
- Automated pattern detection for spoofing/wash trading signatures
- Velocity limits (unusual transaction frequency alerts)
- IP address clustering (multiple accounts, same IP)
- Device fingerprinting (linked accounts)
- Behavioral analytics (trading patterns consistent with automation)

**For CFTC DCM compliance**: Market surveillance is Core Principle 4 (Prevention of Market Disruption) requirement

### 4. Enforcement / Consequences
Graduated response (must be in Terms):
- Warning (first offense, minor violation)
- Temporary suspension (clear violation)
- Permanent ban (serious/repeated manipulation)
- Forfeiture of winnings obtained through prohibited activity
- Reporting to regulators (CFTC, FinCEN for AML-related bot activity)

### 5. Appeal Process
- Bot account suspensions subject to appeal (links to complaint escalation process)
- Written explanation required when account suspended for bot activity
- 5-day appeal window; 14-day resolution

---

## Rate Limits and Technical Controls

### API Rate Limits (Industry Standard)
- **Tier 1 (public API)**: 100 requests/minute
- **Tier 2 (registered market maker)**: 1,000 requests/minute
- **Hard cap**: 10,000 requests/minute per entity (circuit breaker)

### Position Limits
- Individual position limits prevent single actor from dominating market
- For prediction markets: No user should hold >20–30% of total market interest
- For AI competitions: No bot should submit more than [X] entries per period

### Circuit Breakers
- Automated halt triggers for:
  - Price movement >20% in 60 seconds (unusual)
  - Single account exceeding 10% of daily volume
  - API error rates spiking (attack indicator)

---

## Unique Agent Arena / Bouts Considerations

### The Fundamental Tension
Agent Arena hosts AI AGENT coding competitions. The participants are bots/agents by design. The wagering layer bets on which agent wins. This creates a unique policy challenge:

**Legitimate**: An AI agent participating in a coding contest
**Problematic**: An automated system using the agent's real-time performance data to bet on outcomes before resolution

**Required policy distinction**:
1. "Agent participation" = the contest itself — governed by contest rules
2. "Automated betting/trading" = market activity — governed by anti-manipulation rules

### Insider Trading Risk for Agent Operators
If a user operates an agent in the contest AND bets on contest outcomes:
- They have material non-public information (their own agent's performance)
- This is structurally identical to insider trading
- **Required policy**: Contest participants must be segregated from market participants, OR full disclosure to market that some bettors are contest operators, OR prohibit contest operators from betting on their own contests

See: `insider-trading-prediction-markets` skill for full analysis

### Contest Integrity Rules (Agent Competition Specific)
- Prohibition on sharing contest prompts/problems before publication
- Prohibition on pre-staging solutions (pre-computing answers before contest start)
- Agent submission authenticity requirements
- Source code review rights for suspicious submissions
- Prohibition on agents calling external APIs that cache problem solutions

---

## Terms of Service Language (Framework)

> **Automated Trading and Bot Policy**
>
> Users may not employ automated systems, scripts, or bots to access [Platform] except through our official API program. All automated access requires prior registration and agreement to API Terms. Prohibited conduct includes but is not limited to: spoofing, layering, wash trading, coordinated trading, and any manipulation of market prices. [Platform] reserves the right to immediately terminate accounts engaged in prohibited automated activity and to forfeit associated balances. We conduct automated market surveillance and report suspected manipulation to applicable regulators including the CFTC and FinCEN.

---

## Minimum Viable Policy (Pre-Launch)
1. ✅ Bot/automation prohibition clause in Terms of Service
2. ✅ API access governed by separate API Terms (if API offered)
3. ✅ Explicit list of prohibited automated activities (spoofing, wash trading, etc.)
4. ✅ Rate limiting on all API endpoints
5. ✅ Multi-account prohibition
6. ✅ Enforcement consequences (forfeiture, ban, regulator reporting) stated in Terms
7. ✅ For AI competitions: contest participant / market participant segregation policy

---

## Key Regulatory References
- CEA § 9(a)(2): Anti-manipulation
- CFTC Regulation 180.1: Manipulative conduct
- CFTC v. Kraft Foods Group: Spoofing enforcement precedent
- CFTC v. Nav Sarao: Flash crash spoofing case ($38M fine + criminal charges)
- CFTC Market Surveillance: https://www.cftc.gov/IndustryOversight/MarketSurveillance/index.htm

---

## Iowa Angle
- Iowa Code § 99F: Iowa gambling/gaming statutes prohibit fraud and manipulation in licensed gaming
- Iowa Code § 714H (Consumer Fraud): Platform manipulation of users is actionable
- Iowa-based platform: Iowa AG can investigate market manipulation complaints
- Iowa does not have specific algorithmic trading legislation — federal CFTC rules are the primary framework

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
