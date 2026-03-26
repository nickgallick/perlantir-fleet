# Mechanism Design & Game Theory

## Core Concepts

### Incentive Compatibility
A mechanism is incentive compatible when each participant's best strategy is to behave honestly.
- **Dominant Strategy IC**: Honest behavior is optimal regardless of what others do (strongest)
- **Bayesian-Nash IC**: Honest behavior is optimal given beliefs about what others will do (weaker)

**Test**: For every participant, ask: "Can they do better by lying, cheating, or gaming the system?" If yes, the mechanism is broken — regardless of code quality.

### Individual Rationality
Each participant must benefit from participating (or at least not lose).
- **Ex-ante IR**: Expected value of participation > 0 before knowing anything
- **Ex-post IR**: Value of participation ≥ 0 after knowing everything
- If participation is costly and reward is uncertain, participants need expected reward > cost

### Budget Balance
Revenue ≥ Costs over time. Protocol must sustain itself.
- **Weak BB**: No external subsidy needed (fees ≥ operating costs)
- **Strong BB**: No surplus OR deficit (theoretical ideal, rarely achieved)
- Emission-based incentives (liquidity mining) violate budget balance — they're subsidies

### Collusion Resistance
Can participants coordinate to exploit the mechanism?
- Oracle cartels: validators collude to report false data
- Market manipulation: coordinated buying to move prices
- Governance attacks: vote buying, delegation concentration
**Mitigation**: Secret ballots, Schelling point oracles, slashing, reputation systems

### Sybil Resistance
Can one entity create multiple identities to game the system?
- Airdrops: farmers create 1000 wallets for more allocation
- Voting: one person, one thousand votes
**Mitigation**: Proof of Humanity, Gitcoin Passport, minimum stake requirements, quadratic mechanisms

## Game Theory for Smart Contracts

### Nash Equilibrium
State where no player can improve their outcome by changing strategy alone.
- **Pure NE**: Deterministic strategies
- **Mixed NE**: Probabilistic strategies (always exists)
- Design systems where the Nash equilibrium = honest behavior

### Dominant Strategy
A strategy that's best regardless of what others do.
- Second-price auction (Vickrey): bidding true value is dominant strategy
- First-price auction: bidding true value is NOT dominant (you'd overpay)
- In prediction markets: buying YES at price < true probability is dominant

### Schelling Points
Focal points that people naturally coordinate on without communication.
- UMA uses this: "What is the correct answer?" → most people converge on truth
- Works because the cost of being wrong (losing bond) exceeds the cost of research
- Fails when: answer is ambiguous, information asymmetry is extreme, or bribe > bond

## Tokenomics as Mechanism Design

### Staking Mechanisms
```
Stake(amount) → earn rewards + governance power
Slash(amount) → lose stake for misbehavior
Unstake(amount, delay) → withdrawal after cooldown
```
- **Slashing conditions must be objective** — if subjective, validators dispute
- **Reward rate**: Too high = inflationary death. Too low = no participation.
- **Cooldown period**: Prevents stake-and-dump. 7-21 days typical.

### Bonding Curves
```
Price = f(supply)
Common: P = m × S^n (power law)
Linear: P = m × S (constant marginal cost increase)
Sigmoid: S-curve — slow start, rapid middle, saturating end
```
Properties:
- **Continuous liquidity**: Always a buyer and seller at the curve price
- **Deterministic pricing**: Price is a mathematical function of supply
- **Automated market making**: No order book needed
- Use for: curation markets, token launches, reputation tokens

### veToken Model (Curve Innovation)
```
Lock CRV for 1-4 years → receive veCRV (vote-escrowed CRV)
veCRV power = locked_amount × remaining_lock_time / max_lock_time
```
- Longer lock = more voting power and more fee share
- Aligns incentives: only long-term holders influence governance
- Creates: "bribe markets" where protocols pay veCRV holders to vote for their pool
- Flywheel: More emissions → more LP → more fees → more value → more locking

### Real Yield vs Emission Yield
| Type | Source | Sustainable? | Example |
|------|--------|-------------|---------|
| Real yield | Protocol revenue (fees, interest) | Yes | Lido staking yield |
| Emission yield | New token minting | No (inflationary) | Most yield farms |
| Hybrid | Revenue + modest emissions | Maybe | Curve CRV |

**Rule**: If yield disappears when emissions stop, the yield wasn't real.

## Prediction Market Mechanism Design

### LMSR Mathematics
Cost function:
```
C(q) = b × ln(Σᵢ exp(qᵢ/b))

For binary market (YES/NO):
C(q_yes, q_no) = b × ln(exp(q_yes/b) + exp(q_no/b))

Price of YES:
p_yes = exp(q_yes/b) / (exp(q_yes/b) + exp(q_no/b))

Cost to buy Δ YES shares:
cost = C(q_yes + Δ, q_no) - C(q_yes, q_no)
```

Properties:
- **Prices always sum to 1**: p_yes + p_no = 1 (no-arbitrage)
- **Always liquid**: Market maker always offers a price
- **Bounded loss**: Max MM loss = b × ln(n) where n = number of outcomes
- **b parameter**: Higher b = more liquidity, more loss tolerance, less price impact per trade

### CLOB Design for Prediction Markets
```
Order book structure:
YES side: [buy YES at $0.55, buy YES at $0.50, buy YES at $0.45, ...]
NO side:  [buy NO at $0.45, buy NO at $0.50, buy NO at $0.55, ...]

Note: buy YES at $0.55 = sell NO at $0.45 (complementary)

Matching:
If buy YES at $0.60 and buy NO at $0.40 exist → match!
($0.60 + $0.40 = $1.00 → full collateralization)

Spread = best ask - best bid
Tighter spread = more liquid market
```

### Information Aggregation
Why prediction markets are accurate:
- **Marginal trader hypothesis**: Informed traders move prices toward truth
- **Wisdom of crowds**: Aggregating many estimates is more accurate than any individual
- **Skin in the game**: Real money forces honest assessment (unlike polls)
- **Continuous updating**: Prices reflect new information in real-time

### Manipulation Analysis
| Attack | Cost | Feasibility | Detection |
|--------|------|------------|-----------|
| Buy YES to inflate price | High (lose $$ if wrong) | Low for large markets | Volume spike analysis |
| Wash trading | Fees eaten | Low profit | On-chain volume/unique trader ratio |
| Oracle bribery | Cost of bribing asserter | Medium | UMA dispute mechanism |
| Correlated market manipulation | Profit from related market | Medium | Cross-market monitoring |

## Agent Sparta Mechanism Analysis (Preview)

### The Game
- Players: AI agents competing in challenges
- Entry fee: USDC (e.g., $10-$100)
- Prize pool: Sum of entry fees minus platform rake
- Judge: Oracle (Anthropic API or decentralized equivalent)
- Payout: Winners split prize pool based on ranking

### Incentive Compatibility Questions
1. **Is entering honest answers optimal?** Yes, if the judge accurately evaluates quality
2. **Can the judge be manipulated?** Centralized API = trust assumption. Decentralized = oracle game
3. **Is sandbagging profitable?** Enter weak response in easy challenge to lower competition? Only if matchmaking is skill-based
4. **Is collusion profitable?** Two agents coordinate to split wins? Detection: statistical analysis of win patterns
5. **Is Sybil attack profitable?** Enter same challenge with 10 agents to guarantee winning? Prevention: staking requirements, unique agent verification

### Design Principles Applied
For every mechanism decision in Agent Sparta:
1. What is each participant's optimal strategy?
2. Is honest play the Nash equilibrium?
3. What's the cost of the cheapest attack vs the maximum profit?
4. Does the mechanism sustain itself without subsidies?
5. What happens at scale (1000 participants, $1M pools)?
