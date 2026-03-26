# Sports Betting On-Chain (Azuro Architecture)

## Core Difference From Prediction Markets
| | Prediction Market (Polymarket) | Sports Betting (Azuro) |
|--|-------------------------------|----------------------|
| Events | User-created, custom questions | Provider-created, structured sports data |
| Outcomes | Binary (yes/no) | Multi-outcome (win/draw/loss, many teams) |
| Odds mechanism | Price discovery (CLOB/AMM) | Bookmaker model (pool-based odds) |
| Liquidity | Per-market | Shared liquidity pool across all events |
| Counterparty | Other traders | The liquidity pool (LPs = the house) |
| Margin | ~2-5% spread | Built into odds (~5-10% margin) |

## Liquidity Pool as Bookmaker

```solidity
contract LiquidityPool {
    IERC20 public immutable token; // Typically USDC
    uint256 public totalLiquidity;

    // LP deposits → receives LP tokens representing pool share
    function deposit(uint256 amount) external returns (uint256 lpTokens) {
        uint256 totalSupply = lpToken.totalSupply();
        lpTokens = totalSupply == 0 ? amount : (amount * totalSupply) / totalLiquidity;
        token.safeTransferFrom(msg.sender, address(this), amount);
        totalLiquidity += amount;
        lpToken.mint(msg.sender, lpTokens);
    }

    // Pool wins when bettors lose, loses when bettors win
    // LP profitability = (bettor losses) - (bettor winnings) over time
    // Expected value: house edge (5-10% per bet) → LPs profit long-term
}
```

## Condition & Outcome Model

```solidity
struct Condition {
    bytes32 conditionId;    // keccak256(gameId, marketId) — e.g., "EPL_Match_12345_Outcome"
    uint256[] outcomes;     // e.g., [1, 2, 3] for Win/Draw/Loss
    uint256[] oddsNumerators; // Stored as scaled integers (e.g., [2500, 3000, 2800] for 2.5x, 3.0x, 2.8x)
    uint256 resolutionTime;
    uint8 winningOutcome;   // Set by oracle after event
    bool isResolved;
}

// Decimal odds: 2.5 means bet $100 → win $250 total ($150 profit)
// American odds: +150 means bet $100 → win $250 (+$150 profit)
// Implied probability: 1 / decimal_odds
// House margin = 1 - Σ(1/odds_i) per market
```

## Odds Engine (Dynamic Updates)

```solidity
contract OddsEngine {
    // Odds adjust based on bet volume to maintain balanced book
    // Higher volume on outcome A → lower odds on A (less payout per bet)

    mapping(bytes32 => mapping(uint256 => uint256)) public totalBets; // conditionId → outcome → total bet amount

    function getCurrentOdds(bytes32 conditionId, uint256 outcome) public view returns (uint256) {
        uint256 totalMarket = getTotalBets(conditionId);
        if (totalMarket == 0) return initialOdds[conditionId][outcome];

        uint256 outcomeBets = totalBets[conditionId][outcome];
        uint256 otherBets = totalMarket - outcomeBets;

        // Simplified: odds proportional to money on other outcomes
        // Real: more sophisticated margin-maintaining model
        uint256 impliedProb = (outcomeBets * 1e18) / totalMarket;
        uint256 houseMargin = 0.05e18; // 5%

        // odds = 1 / (implied_prob + house_margin_allocation)
        return 1e36 / (impliedProb + houseMargin);
    }
}
```

## Bet Token (ERC-1155)

```solidity
contract BetToken is ERC1155 {
    struct Bet {
        bytes32 conditionId;
        uint256 outcome;
        uint256 odds;         // Locked-in odds at time of bet
        uint256 amount;       // Amount wagered
        uint256 potentialWin; // amount × odds
        address bettor;
    }

    mapping(uint256 => Bet) public bets;
    uint256 public betCount;

    function placeBet(
        bytes32 conditionId,
        uint256 outcome,
        uint256 amount,
        uint256 minOdds    // Slippage protection
    ) external returns (uint256 betId) {
        uint256 currentOdds = oddsEngine.getCurrentOdds(conditionId, outcome);
        require(currentOdds >= minOdds, "Odds too low");

        uint256 potentialWin = amount * currentOdds / 1e18;
        require(liquidityPool.canCover(potentialWin), "Insufficient liquidity");

        betId = ++betCount;
        token.safeTransferFrom(msg.sender, address(liquidityPool), amount);
        liquidityPool.lockForBet(potentialWin); // Reserve potential payout

        bets[betId] = Bet(conditionId, outcome, currentOdds, amount, potentialWin, msg.sender);
        _mint(msg.sender, betId, 1, ""); // ERC-1155 bet token
    }
}
```

## Resolution & Claims

```solidity
contract Resolution {
    mapping(bytes32 => uint8) public outcomes;

    // Data provider (oracle) reports result
    function resolveCondition(bytes32 conditionId, uint8 winningOutcome) external onlyDataProvider {
        require(!conditions[conditionId].isResolved, "Already resolved");
        conditions[conditionId].winningOutcome = winningOutcome;
        conditions[conditionId].isResolved = true;

        emit ConditionResolved(conditionId, winningOutcome);
    }

    // Bettor claims winning bet
    function claimReward(uint256 betId) external {
        Bet memory bet = bets[betId];
        require(bet.bettor == msg.sender || betToken.isApprovedForAll(bet.bettor, msg.sender));

        Condition memory condition = conditions[bet.conditionId];
        require(condition.isResolved, "Not resolved");

        betToken.burn(msg.sender, betId, 1);

        if (condition.winningOutcome == bet.outcome) {
            // Winner: receive full potential payout
            liquidityPool.payout(msg.sender, bet.potentialWin);
        }
        // Losers: nothing. Their bet amount stayed in the pool.
    }
}
```

## Parlay (Accumulator) Contracts

```solidity
// Combine N bets into one: all must win, odds multiply
contract ParlayBet {
    function placeParlay(
        bytes32[] calldata conditionIds,
        uint256[] calldata outcomes,
        uint256 amount
    ) external returns (uint256 parlayId) {
        // Multiply odds: parlay_odds = Π(individual_odds_i)
        uint256 combinedOdds = 1e18;
        for (uint i = 0; i < conditionIds.length; i++) {
            uint256 legOdds = oddsEngine.getCurrentOdds(conditionIds[i], outcomes[i]);
            combinedOdds = combinedOdds * legOdds / 1e18;
        }

        uint256 potentialWin = amount * combinedOdds / 1e18;
        // ... place bet, lock liquidity, mint parlay token
    }

    function claimParlay(uint256 parlayId) external {
        // All legs must be winning outcomes
        // If any leg loses → entire parlay loses
    }
}
```

## Live Betting Considerations

Critical challenge: preventing exploitation when result is known before oracle updates.
```
Goal scored at 89:42
Oracle updates at 89:55 (13 second delay)
Attacker at 89:43 bets on winning team at pre-goal odds

Mitigation:
1. Pause betting during live events for 30-60 seconds after any goal/score change
2. Oracle latency monitoring — pause if oracle is slow
3. Position size limits — limit individual bet size near end of game
4. Real-time odds freezing — freeze odds on large anomalous bets
```

## B2B2C Architecture (Azuro's Model)
```
Azuro Protocol (smart contracts)
         ↓
Frontend SDK (JavaScript)
         ↓
Any operator builds their own branded sportsbook UI
         ↓
End users bet through any operator's frontend

Revenue split: Protocol fee + Operator commission from house edge
```
This is brilliant: Azuro doesn't need to acquire users directly. Any developer can spin up a sportsbook using Azuro's liquidity.
