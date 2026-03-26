# SKILL 58: Market Manipulation — Detection, Legal Obligations & Response

## Purpose
Know what manipulation is illegal on prediction markets, what your platform's surveillance obligations are, how to detect it, and the exact response protocol when you find it.

## CFTC Anti-Manipulation Authority
**Dodd-Frank §747 (CEA §6(c)(1) and §9(a)(2))**:
- Prohibits: manipulation or attempted manipulation of any swap, contract, or commodity price
- Prohibits: using any "manipulative or deceptive device or contrivance" in connection with any swap or contract
- **Applies to your prediction market even if you're NOT a registered DCM** — if your markets qualify as event contracts or swaps
- Criminal penalties: up to 10 years (CEA §9), plus civil penalties up to $1M+ per violation

## Types of Manipulation

### Wash Trading
- Same person (or colluding parties) buying and selling the same position to create artificial volume
- Purpose: make the market look more liquid/active than it is
- **On-chain detection**: trace funding sources. If buyer and seller wallets both received funds from same source address within 24 hours → flag immediately
- **Pattern detection**: wallets that trade opposite sides of the same market within the same block or within minutes
- Legal status: per se illegal under CEA §9(a)(2)

### Spoofing
- Placing large orders with intent to cancel before execution, creating false impression of demand
- On AMM: placing and quickly removing liquidity to manipulate the price curve
- **Detection**: orders/liquidity placed and removed within seconds, especially if they move market price
- Dodd-Frank §747 explicitly prohibits spoofing in commodity markets

### Front-Running / Insider Resolution
- Person with advance knowledge of resolution outcome trades before resolution is published
- **Example**: person responsible for resolving a market knows the outcome → trades before publication
- **Prevention**: oracle-based (automated) resolution eliminates human insider risk
- If human resolution is used: resolver is PROHIBITED from trading on that market (and all correlated markets)
- Information barriers required between resolution team and trading operations

### Market Cornering
- Acquiring dominant position to control payout structure
- **Detection**: monitor position concentration. Flag when any single address holds >20% of open interest in any market
- Response: position limits in Market Rules ("no single address may hold more than X% of open interest")

### Social Media Manipulation
- Spreading false information about underlying event to move market prices, then trading the movement
- Legal theory: wire fraud (18 U.S.C. § 1343) + CEA manipulation
- **Detection**: correlation analysis between social media activity and unusual market movements
- Platform response: coordinate with resolution process — false news does not affect oracle-based resolution

## Your Surveillance Obligations

### If NOT Registered as DCM
- No explicit CFTC rule mandating surveillance program
- BUT: failing to address KNOWN manipulation = regulatory and civil liability
- Best practice = implement surveillance anyway; it demonstrates good faith and reduces enforcement risk

### Surveillance System Requirements
- Automated monitoring for: wash trading patterns, unusual volume spikes (>3x normal), position concentration >20%, correlated trading across markets
- Maintain surveillance records for minimum 5 years (CFTC standard for regulated entities)
- Daily surveillance review by designated compliance officer
- Quarterly surveillance program review and update

### Suspicious Activity Reporting (SAR)
- If NOT an MSB: no mandatory SAR filing obligation
- If registered MSB: SAR required within 30 days of detecting suspicious activity ≥$5,000
- Best practice regardless: maintain internal incident log of all detected manipulation; document your response

## Response Protocol (See SKILL 64 for emergency procedures)
1. **Detection** → automated flag raised
2. **Preserve evidence**: snapshot of relevant on-chain data, order history, wallet addresses, timing
3. **Investigate**: trace wallet funding sources, look for coordinated patterns across accounts
4. **Suspend trading** on affected market(s) pending investigation (invoke circuit breaker)
5. **Determine outcome**: manipulation confirmed vs. false positive
6. **If confirmed**: (a) void affected trades, (b) ban accounts, (c) claw back manipulative profits per TOS, (d) file SAR if applicable, (e) consider referral to CFTC/DOJ if serious
7. **Communicate**: to affected users, explaining that manipulation was detected and trades voided
8. **Document**: entire investigation, evidence, decision, and remediation — kept for 5 years

## TOS Provisions Required
> "Prohibited Conduct: Users may not engage in wash trading, spoofing, front-running, market cornering, or any other manipulative trading practice. The Platform may void any trades determined to be manipulative, freeze accounts, ban users, and claw back any profits derived from manipulative conduct. The Platform will cooperate fully with regulatory authorities investigating market manipulation."

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
