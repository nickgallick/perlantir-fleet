# SKILL 51: Force Majeure & Smart Contract Failure

## Purpose
Handle legal liability when blockchain networks fail, oracles return bad data, or smart contracts malfunction. Know what's force majeure vs. negligence, and what TOS provisions protect you.

## Crypto-Specific Force Majeure Events
- Blockchain network outage or extreme congestion (Ethereum gas spikes)
- Oracle failure (Chainlink returns incorrect price, feed goes offline)
- Smart contract bug (exploited or malfunctioning)
- Bridge failure (cross-chain bridge hacked or paused)
- Regulatory action (sudden government ban of the activity)
- AI API provider termination (Anthropic/OpenAI cuts access mid-contest)
- DDoS attack on platform infrastructure
- Hard fork creating network ambiguity

## Required TOS Force Majeure Clause

```
Force Majeure: The Platform shall not be liable for any failure or delay in 
performance resulting from causes beyond its reasonable control, including but 
not limited to: blockchain network congestion, outages, or forks; smart contract 
vulnerabilities or exploits; oracle data feed interruptions or inaccuracies; 
natural disasters; government actions or regulatory changes; third-party service 
provider failures (including AI model providers); cyberattacks; or any other 
circumstances beyond the Platform's reasonable control.

In the event of a force majeure event affecting an active contest or market, 
the Platform may, in its sole discretion:
(a) extend the contest/market deadline until normal operations resume;
(b) pause the contest/market until the event is resolved;
(c) void the contest/market and refund entry fees at the smart contract level; or
(d) resolve the contest/market based on the most recent valid data available 
    prior to the force majeure event.

The Platform's exercise of discretion under this section shall not constitute 
a breach of contract or give rise to any claim for damages beyond a refund 
of entry fees paid.
```

## Smart Contract Bug Liability Analysis

### Force Majeure Argument
- Smart contract bugs are inherent risks of blockchain technology
- Disclosed in TOS as an accepted risk
- Users chose to interact with smart contracts knowing this risk

### Negligence Argument (Counterargument You Must Defeat)
- You wrote the code → you should have audited it → bug is negligence, not force majeure
- Standard of care: professional smart contract audit is the industry standard
- If you didn't get an audit: hard to argue force majeure for a discoverable bug

### Protecting Against Smart Contract Bug Liability
1. **Professional audit**: Certik, Trail of Bits, OpenZeppelin Audits, Halborn — before mainnet deploy
2. **TOS smart contract disclaimer**:
   > "Smart contracts may contain bugs, vulnerabilities, or errors despite reasonable efforts to test them. Users interact with smart contracts at their own risk. Platform liability for smart contract errors is limited to the entry fees paid."
3. **Bug bounty program**: demonstrates ongoing good faith and reduces negligence argument
4. **Upgrade mechanism**: use upgradeable proxy pattern so bugs can be fixed (but document governance of upgrades)
5. **Insurance**: smart contract cover (Nexus Mutual, InsurAce, Sherlock)

## Oracle Failure Analysis

### Who is Liable for Oracle Failure?
- **Chainlink's TOS**: provides the protocol but doesn't guarantee accuracy of any specific data feed
- **Your platform**: if you chose the oracle and it failed → you may be liable to users

### Oracle Failure TOS Protection
```
"Market resolution is determined by the oracle specified in the market description. 
The Platform is not responsible for inaccuracies, delays, or outages of third-party 
oracle services. In the event of an oracle failure or data dispute, the Platform 
may invoke its dispute resolution process to determine the correct resolution."
```

### Multi-Oracle Architecture (Best Practice)
- Use 2–3 independent oracles: Chainlink + UMA + API3
- Resolution: median of all available feeds
- If one oracle is >5% from others → pause market, invoke dispute process
- Eliminates single point of oracle failure

## Network Outage / Congestion Handling

### Pre-Contest Disclosure
- Disclose in contest rules: "If Ethereum network becomes congested or unavailable, the contest deadline may be extended. Participants are responsible for ensuring their transactions are submitted with adequate gas fees."
- Gas price guarantee: consider refunding the difference if gas spikes beyond a threshold

### Smart Contract Pause Mechanism
- Include a pause function (OpenZeppelin Pausable) controlled by platform multisig
- Can pause new entries but not freeze existing locked funds
- TOS authorizes pause: "Platform may pause contests due to technical or regulatory factors"

## Relevant Case Law
- *Bitfinex hack litigation* (2016): users sought recovery of stolen Bitcoin; courts analyzing force majeure vs. negligence in crypto context
- *Compound Finance governance attack* (2023): protocol voted to send $83M to wrong address; no legal action but demonstrates smart contract governance risk
- General contract law: force majeure clauses are narrowly construed; courts require the event to be truly unforeseeable and beyond reasonable control

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
