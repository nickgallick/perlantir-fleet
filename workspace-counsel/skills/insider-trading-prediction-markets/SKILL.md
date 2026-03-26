# SKILL 59: Insider Trading on Prediction Markets

## Purpose
Know when trading on non-public information in prediction markets is illegal, who the likely insiders are on YOUR markets, and what your platform's obligations are.

## The Legal Landscape

### Federal Securities Law (SEC Rule 10b-5)
- Illegal to trade securities based on material non-public information (MNPI)
- **Applies to prediction markets ONLY if**: the prediction market contract qualifies as a "security" under the Howey test
- If your market is a CFTC-regulated event contract (not a security): Rule 10b-5 does NOT directly apply
- **Counsel's take**: design your markets to be event contracts, not securities. Insider trading law follows the security classification.

### CFTC Anti-Fraud Rules (CEA §6(c)(1))
- Prohibits fraud and manipulation in connection with swaps and commodity contracts
- **Could cover MNPI trading in prediction markets** — CFTC has not brought a pure insider trading case on event contracts specifically, but the authority exists
- Theory: trading on MNPI constitutes fraud on other market participants (you're taking from them based on information they don't have)
- Watch: *CFTC v. Ooki DAO* and subsequent enforcement show CFTC expanding its theories aggressively

### Wire Fraud (18 U.S.C. § 1343) — The Catch-All
- Prohibits schemes to defraud using wire communications
- Does NOT require the contract to be a security
- DOJ could prosecute prediction market insider trading under wire fraud regardless of SEC/CFTC classification
- **This is the most dangerous theory**: no registration requirement, no classification debate — just: did you know something others didn't, did you trade, did you profit, did you use the internet?

## Who Are Your Insiders?

### AI Benchmark Markets
- **AI lab employees**: know upcoming model capabilities before public release
- Example: OpenAI employee knows GPT-5 aces a specific benchmark → trades on "Will GPT-5 score >90%?" before announcement
- **Mitigation**: markets resolve based on PUBLICLY AVAILABLE benchmark results, not private demos or pre-release data. If the resolution source is public, insider timing advantage is minimized.

### Economic/Fed Markets
- **Government officials**: Fed employees, Treasury officials with advance knowledge
- **Private sector**: Goldman Sachs economists, hedge fund analysts with proprietary models
- **Mitigation**: resolution based on public Federal Reserve announcements. The announcement IS the public information — trading before it on leaked advance knowledge is the risk. Position limits help.

### Political Markets
- **Campaign insiders, unreleased polling data**: someone with internal polling showing a 20-point lead before public release
- **Government officials with advance knowledge**: counting officials, election administrators
- **Hardest to police** — and why CFTC has been historically cautious about political markets
- **Mitigation**: Kalshi's approach — resolution based on AP election call, which is independent. Position concentration monitoring.

### Sports Markets
- **Athletes, coaches, referees with injury knowledge or game-fixing information**
- **Why sports betting is heavily regulated**: intersection with sports integrity
- **Mitigation**: if you launch sports markets, require market makers to represent no material non-public information

### Platform Employees (ALWAYS)
- Anyone at your company with knowledge of: market operations, resolution timing, internal AI scoring, unreleased features
- **ALL platform employees are prohibited from trading on your platform's markets** — no exceptions
- Resolution team: prohibited from trading on ANY market on the platform while they are on the resolution team

## Platform Obligations

### Prohibited Persons Policy
- **Employee trading ban**: all employees, contractors, advisors, board members → prohibited from trading on any platform markets
- **Resolution team**: persons involved in resolving any market → additionally prohibited from trading correlated markets
- **Information barriers**: if you have relationships with AI labs, government entities, or data providers → information barriers between those relationships and trading-accessible personnel
- **Policy implementation**: written policy, annual certification, monitoring of platform accounts associated with employee email addresses

### TOS Prohibition
> "Users may not trade based on material non-public information about the underlying event for any market. Employees, contractors, and agents of the Platform are prohibited from trading on any Platform market. Violation of this policy may result in immediate account termination, disgorgement of profits, and referral to regulatory authorities."

### Monitoring
- Flag: unusually large positions established shortly before market resolution (within 24-48 hours of a known resolution event)
- Flag: accounts that consistently take profitable positions right before resolution across multiple markets (statistical anomaly)
- Investigate: wallet addresses connected to known institutional entities (AI labs, hedge funds, government)
- Document: all flagged investigations, outcomes, and actions taken

## If Insider Trading Is Discovered
1. Preserve evidence: trading records, wallet addresses, timing, profit amounts
2. Freeze account(s)
3. Engage outside counsel immediately
4. Do NOT tip off the potential insider before investigation is complete
5. Evaluate: SAR filing obligation (if MSB); voluntary cooperation with CFTC/DOJ
6. Clawback: void trades, disgorge profits per TOS enforcement authority
7. Document: entire investigation for regulatory files

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
