# SKILL 62: Liquidity Provider Regulation

## Purpose
Understand whether your market makers need to be regulated, what the SEC "dealer" expansion means, and how to structure liquidity provision to minimize regulatory risk.

## The Core Question
Prediction markets need liquidity. Who provides it, and are they regulated?

## AMM Architecture (Lowest Regulatory Risk)
- Smart contract provides liquidity algorithmically — no human market maker involved
- No broker-dealer registration needed for the AMM itself
- **Passive LP provision**: users providing liquidity to an AMM pool are more like depositors than market makers — current analysis says passive LP is NOT market making requiring registration
- **Risk**: SEC has argued in *SEC v. Coinbase* (2023) that certain DeFi LP activities constitute acting as a dealer if there is active expectation of profit from the spread
- **Post-Loper Bright**: SEC's aggressive expansion of "dealer" definition is more contestable — no Chevron deference for broad regulatory re-interpretations

## SEC "Dealer" Definition Expansion (Rule 3b-16, Finalized 2024)
- **Applies if**: prediction market contracts qualify as securities (unlikely if properly structured as event contracts)
- **If contracts ARE securities**: persons who "engage in a regular pattern of buying and selling securities that has the effect of providing liquidity to other market participants" must register as broker-dealers
- **Your primary defense**: structure as event contracts (CFTC jurisdiction), not securities → Rule 3b-16 doesn't apply
- **Secondary defense**: passive AMM provision ≠ acting as a dealer in the traditional sense

## CFTC Market Maker Obligations (Registered DCMs Only)
- On registered DCMs: designated market makers have specific obligations (minimum quote sizes, maximum spreads, uptime requirements)
- Your platform can designate market makers via written agreement specifying obligations
- **Market Maker Agreement**: must cover obligations, compensation, termination conditions, information barriers

## Platform-Provided Liquidity (DO NOT DO THIS)
- If YOUR company provides liquidity on YOUR market → you're simultaneously the exchange AND the market maker
- **Conflict of interest problem**: platform profits when users lose → you're incentivized to let users lose → fiduciary breach, fraud
- **Regulatory problem**: potentially requires broker-dealer registration as both exchange and dealer
- **Best practice**: do NOT be your own market maker. Use AMM or independent third-party market makers.

## Independent Human/Institutional Market Makers
- Professional market makers should have their OWN legal counsel evaluate their registration obligations under:
  - SEC Rule 15a-1 (exemptions from broker-dealer registration)
  - CFTC §1a(23) (introducing broker, FCM definitions)
  - State securities dealer registration
- **Your obligation**: in the Market Maker Agreement, require them to represent and warrant that they comply with all applicable regulatory requirements
- You are NOT responsible for their regulatory compliance, but you need the representation in case they're wrong

## Market Maker Agreement Key Terms
*(See Question 4 in operational responses for full agreement)*
- Trading obligations: minimum daily volume, maximum spread
- Information barriers: no trading on MNPI, no sharing of platform operations data
- Regulatory representations: represent they are compliant with all applicable laws
- Compensation: fee rebates, spread-based compensation
- Prohibited conduct: no wash trading, no front-running, no coordination
- Termination: immediate if regulatory action, TOS violation, or manipulation detected

## Liquidity Architecture Recommendation
1. **Primary**: AMM (Gnosis conditional tokens + CLOB hybrid, as Polymarket uses)
2. **Secondary**: independent designated market makers via written agreement
3. **Never**: platform-provided liquidity on platform markets

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
