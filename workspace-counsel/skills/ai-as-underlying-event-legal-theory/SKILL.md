# SKILL 82: AI-as-Underlying-Event — The Legal Theory

## Purpose
This is Perlantir's legal whitespace. "Betting on whether an AI correctly predicts X" is legally distinct from "betting on X." This skill develops the complete legal theory for why AI performance markets are in a different — and more favorable — regulatory category than traditional prediction markets.

## The Core Distinction

### Traditional Prediction Market
- **Underlying event**: the election outcome, the Fed decision, the earnings report
- **User bets on**: whether the real-world event occurs
- **Regulatory concern**: (1) insider trading (participants may have MNPI about the event), (2) market manipulation (participants can influence the underlying event), (3) election integrity concerns

### AI Performance Prediction Market
- **Underlying event**: whether AI Model X correctly predicts Y within a specified timeframe
- **User bets on**: the AI's predictive accuracy — NOT on Y itself
- **Regulatory profile**: fundamentally different on every dimension

## Why This Is Legally Stronger — Argument by Argument

### Argument 1: The "Public Interest" Test Is Easily Satisfied
CFTC's primary tool to block event contracts is CEA §5c(c)(5)(C) — contracts "contrary to the public interest." The test: does market participation incentivize harmful conduct?

**Traditional election market**: a large YES bettor on Candidate A is slightly incentivized to take actions (legal or illegal) that help Candidate A win. This is the CFTC's concern with election markets.

**AI performance market**: a large YES bettor on "Claude correctly predicts the election" cannot take any action to make Claude predict more accurately. Claude's prediction accuracy is:
- Fixed by Anthropic's training (outside any user's control)
- Based on publicly available information (no MNPI advantage)
- Determined by the AI's internal processes (not influenceable by market participants)

**The public interest concern is zero.** No harmful incentive is created. This is the strongest possible argument for CFTC approval.

### Argument 2: No Insider Trading Is Possible (By Design)
Traditional prediction markets have an insider trading problem: people with MNPI about elections, corporate earnings, or government decisions can trade ahead of public knowledge.

AI performance markets eliminate this entirely:
- **Who has MNPI about Claude's accuracy?** Anthropic employees, potentially. But they cannot influence the AI's prediction — they can only know it early.
- **Resolution is based on public benchmark publications** — the same information is available to everyone at the same time
- **No trading window before resolution**: markets can close before the AI's prediction is published, eliminating the front-running window
- **Market design solution**: resolve markets only on publicly scheduled benchmark releases (e.g., "Claude's MMLU score in the official Q1 2026 technical report"). If there's no pre-release leak possible, there's no MNPI problem.

### Argument 3: Skill Is Maximized, Chance Is Minimized
For gambling/skill-game classification:
- Traditional prediction markets: betting on future events involves substantial chance (no one can know the future with certainty)
- AI performance markets: users can analyze publicly available data to make educated predictions:
  - Historical benchmark performance of each AI model
  - Rate of improvement over time (scaling laws)
  - Published capability evaluations
  - AI company announcements about model releases
  - Academic research on AI capabilities

This is MORE skill-intensive than DraftKings DFS (where player performance has irreducible randomness) and much more skill-intensive than pure chance games. **Skill argument for gaming attorney opinion is stronger here than for any other prediction market type.**

### Argument 4: No Commodity Underlying = CFTC Jurisdiction Is Weaker
CFTC has jurisdiction over contracts involving commodities (7 U.S.C. §1a(9)). Classic commodities: agricultural products, energy, metals, financial instruments (currencies, interest rates), and by extension, Bitcoin/ETH (per CFTC guidance).

**Is "Claude Opus's prediction accuracy" a commodity?** No. It is:
- Not an agricultural product
- Not an energy product
- Not a metal
- Not a currency or interest rate
- Not a defined "digital asset" (it's a performance metric, not a token)
- Post-Loper Bright: CFTC cannot expand "commodity" beyond the statutory text without Congressional action

**If the underlying is not a commodity**: CFTC's jurisdiction under the CEA may not attach at all. The product may fall entirely outside CFTC's reach — leaving it subject only to state skill-game law (which you can handle with a gaming attorney opinion).

**This is the strongest legal argument for your specific product.** Get this analysis in writing from a CFTC attorney.

### Argument 5: The Informational Value Argument
CFTC permits event contracts that serve a "legitimate economic purpose" — hedging or price discovery. AI performance markets serve a legitimate informational purpose:
- **Price discovery**: what does the market believe about AI capability trajectories?
- **Economic value**: AI labs, investors, and companies making AI deployment decisions would benefit from market-based forecasts of AI capability
- **Hedging**: a company that has bet its business strategy on GPT-5 outperforming human analysts has a genuine economic interest in hedging that exposure
- This is a STRONGER informational purpose argument than election markets ("what does the market think about election outcomes?")

## Structuring Markets to Maximize Legal Protection

### Market Design Rules for AI Performance Markets
1. **Resolve on publicly published, independently verifiable data only** — never on private demonstrations, internal benchmarks, or pre-release access
2. **Define the exact benchmark, model, and publication source in the market terms** — before the market opens
3. **Close trading before the resolution event** — no open trading window when anyone might have advance knowledge of results
4. **Use scheduled releases only** — quarterly technical reports, official benchmark publications, peer-reviewed papers
5. **No markets on AI performance in real-time applications** — only on standardized, reproducible benchmarks
6. **No markets on AI from companies where participants may have insider relationships** — consider disclosure requirements

### Market Language That Strengthens Legal Position
**Use**: "AI model performance evaluation," "benchmark accuracy," "capability measurement," "prediction calibration score"
**Avoid**: "gambling on AI," "betting on AI predictions," "wagering on AI outcomes"
**Framing**: this is a market for price discovery of AI capability — an informational product, not a gambling product

## The "Two-Hop" Legal Theory
When users bet on "whether Claude correctly predicts the election":
- **Hop 1**: Claude makes a prediction about the election (this is information, not a bet)
- **Hop 2**: users bet on whether Claude's prediction was accurate (this is a bet on AI performance, not on the election)

The user's contract resolves based on AI performance — not on the election outcome. A user who correctly bets that Claude will be wrong about the election wins even if the election goes the way Claude predicted. This two-hop structure means:
- The market is NOT an election prediction market (the election outcome doesn't directly determine payouts)
- The market IS an AI evaluation market (Claude's accuracy is what determines payouts)
- Users are essentially betting on AI calibration — a machine learning concept, not a political concept

## Patent/IP Protection for This Theory
This market structure — betting on AI prediction accuracy rather than on the underlying event — may be patentable as a novel market mechanism. Consider:
- Defensive publication (blog post or whitepaper) to create prior art and prevent others from patenting it
- Patent application for the specific mechanism (two-hop resolution, AI calibration market structure)
- Trade secret protection for the scoring methodology used to evaluate AI prediction accuracy

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
