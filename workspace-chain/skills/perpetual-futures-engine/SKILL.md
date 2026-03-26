# Perpetual Futures Engine

## Core Mechanics

### What Makes Perpetuals Different from Spot
- **No expiry**: Hold forever (unlike quarterly futures)
- **Leverage**: Control $10K position with $1K collateral (10x)
- **Funding rate**: Periodic cash flow between longs and shorts keeps price anchored to spot
- **Mark price**: Manipulation-resistant price for liquidations (not last trade price)

## Funding Rate Mechanism

```
Purpose: Keep perpetual price ≈ spot price (index price)

If perp_price > index_price (perps overpriced):
  → Funding rate > 0
  → Longs PAY shorts
  → Opens incentive to short, close longs → price pushed down

If perp_price < index_price (perps underpriced):
  → Funding rate < 0
  → Shorts pay longs
  → Opens incentive to long, close shorts → price pushed up

Formula:
  premium = (mark_price - index_price) / index_price
  funding_rate = clamp(premium + clamp(premium - interest_rate, -0.05%, +0.05%), -0.05%, +0.05%)
  
  Typical: 8-hour funding periods
  Continuous model: accrue per second = funding_rate_8h / 28800
```

```solidity
contract FundingRate {
    int256 public cumulativeFundingRate; // Accumulates over time
    uint256 public lastFundingTime;
    int256 constant MAX_FUNDING_RATE = 0.0005e18; // 0.05% per 8h

    function updateFunding(int256 markPrice, int256 indexPrice) external {
        uint256 elapsed = block.timestamp - lastFundingTime;

        int256 premium = ((markPrice - indexPrice) * 1e18) / indexPrice;
        int256 fundingRate = _clamp(premium / 8, -MAX_FUNDING_RATE, MAX_FUNDING_RATE);

        // Accrue per second
        int256 fundingIncrement = (fundingRate * int256(elapsed)) / 8 hours;
        cumulativeFundingRate += fundingIncrement;
        lastFundingTime = block.timestamp;
    }

    function _clamp(int256 x, int256 min, int256 max) internal pure returns (int256) {
        if (x < min) return min;
        if (x > max) return max;
        return x;
    }
}
```

## Position Accounting

```solidity
struct Position {
    int256 size;              // Positive = long, negative = short (in base asset)
    uint256 entryPrice;       // Average entry price (WAP of all entries)
    uint256 margin;           // Collateral posted
    int256 entryFundingRate;  // Cumulative funding at position open
    uint256 lastUpdateTime;
}

function calculatePnL(address trader, uint256 markPrice) public view returns (int256) {
    Position memory pos = positions[trader];
    if (pos.size == 0) return 0;

    // Unrealized PnL
    int256 priceDiff = int256(markPrice) - int256(pos.entryPrice);
    int256 unrealizedPnL = (pos.size * priceDiff) / int256(1e18);

    // Funding PnL (positive = received funding, negative = paid funding)
    int256 fundingDiff = cumulativeFundingRate - pos.entryFundingRate;
    int256 fundingPnL = -(pos.size * fundingDiff) / int256(1e18);
    // Note: longs pay when funding positive, receive when negative

    return unrealizedPnL + fundingPnL;
}

function getMarginRatio(address trader, uint256 markPrice) public view returns (uint256) {
    Position memory pos = positions[trader];
    int256 equity = int256(pos.margin) + calculatePnL(trader, markPrice);
    if (equity <= 0) return 0;

    uint256 positionValue = uint256(abs(pos.size)) * markPrice / 1e18;
    return (uint256(equity) * 1e18) / positionValue;
}
```

## Liquidation Engine

```solidity
contract LiquidationEngine {
    uint256 constant MAINTENANCE_MARGIN = 0.05e18; // 5%
    uint256 constant LIQUIDATION_FEE = 0.01e18;    // 1% of position
    address public insuranceFund;

    function liquidate(address trader) external {
        uint256 markPrice = getMarkPrice();
        uint256 marginRatio = getMarginRatio(trader, markPrice);
        require(marginRatio < MAINTENANCE_MARGIN, "Healthy position");

        Position memory pos = positions[trader];
        uint256 positionValue = uint256(abs(pos.size)) * markPrice / 1e18;
        uint256 liquidationFee = positionValue * LIQUIDATION_FEE / 1e18;

        // Calculate bankruptcy price (where equity = 0)
        // For long: bankruptcy_price = entry_price - (margin / size)
        // For short: bankruptcy_price = entry_price + (margin / size)
        int256 bankruptcyPrice = calculateBankruptcyPrice(trader);

        // Close position at mark price
        int256 realizedPnL = calculatePnL(trader, markPrice);
        int256 remainingMargin = int256(pos.margin) + realizedPnL;

        if (remainingMargin >= int256(liquidationFee)) {
            // Normal liquidation: pay liquidator fee from remaining margin
            IERC20(collateral).safeTransfer(msg.sender, liquidationFee);
            if (remainingMargin > int256(liquidationFee)) {
                // Return leftover to trader
                IERC20(collateral).safeTransfer(trader, uint256(remainingMargin) - liquidationFee);
            }
        } else {
            // Deficit: insurance fund covers the gap
            uint256 deficit = uint256(int256(liquidationFee) - remainingMargin);
            // Pay liquidator from insurance fund
            IInsuranceFund(insuranceFund).cover(msg.sender, deficit);
        }

        delete positions[trader];
        emit Liquidated(trader, pos.size, markPrice);
    }
}
```

## Mark Price (Manipulation-Resistant)

```solidity
// Mark price = exponential moving average of index price
// Prevents spike attacks on last-traded price triggering cascading liquidations

contract MarkPriceOracle {
    uint256 public markPrice;
    uint256 public lastUpdateTime;
    uint256 constant EMA_FACTOR = 0.0003e18; // Decay factor per second

    function updateMarkPrice(uint256 indexPrice) external {
        uint256 elapsed = block.timestamp - lastUpdateTime;

        // EMA: mark = mark × decay^elapsed + index × (1 - decay^elapsed)
        // Simplified: weight = elapsed × EMA_FACTOR
        uint256 indexWeight = Math.min(elapsed * EMA_FACTOR / 1e18, 1e18);
        uint256 markWeight = 1e18 - indexWeight;

        markPrice = (markPrice * markWeight + indexPrice * indexWeight) / 1e18;
        lastUpdateTime = block.timestamp;
    }

    // Mark price cannot deviate more than X% from index price
    function getMarkPrice() external view returns (uint256) {
        uint256 indexPrice = chainlinkOracle.getPrice();
        uint256 maxDeviation = indexPrice * 5 / 100; // 5% max

        if (markPrice > indexPrice + maxDeviation) return indexPrice + maxDeviation;
        if (markPrice < indexPrice - maxDeviation) return indexPrice - maxDeviation;
        return markPrice;
    }
}
```

## ADL (Auto-Deleveraging)

```solidity
// Last resort when insurance fund depleted
// Forcibly close most profitable opposing positions

function autoDeleverage(address losingTrader) external {
    require(insuranceFund.balance() == 0, "Insurance fund not depleted");

    Position memory loser = positions[losingTrader];
    uint256 deficit = calculateDeficit(losingTrader);

    // Find most profitable opposing trader
    // Sorted by: profit × leverage (highest = most at risk of ADL)
    address winner = findTopADLCandidate(loser.size > 0 ? SHORT : LONG);

    // Close winner's position partially to cover deficit
    int256 closeSize = min(abs(positions[winner].size), deficit / markPrice);
    _closePosition(winner, closeSize, markPrice);
    _closePosition(losingTrader, closeSize, markPrice); // Offset
}
```

## Insurance Fund

```solidity
contract InsuranceFund {
    IERC20 public immutable collateral;
    uint256 public balance;

    // Funded by: liquidation penalties, protocol fees
    function deposit(uint256 amount) external {
        collateral.safeTransferFrom(msg.sender, address(this), amount);
        balance += amount;
    }

    // Used when: liquidation deficit (position was underwater)
    function cover(address liquidator, uint256 deficit) external onlyLiquidationEngine {
        if (deficit <= balance) {
            balance -= deficit;
            collateral.safeTransfer(liquidator, deficit);
        } else {
            // Fund depleted → trigger ADL
            uint256 available = balance;
            balance = 0;
            collateral.safeTransfer(liquidator, available);
            emit InsuranceFundDepleted();
        }
    }
}
```

## EVM Perpetuals vs dYdX V4 App-Chain

| Concern | EVM Smart Contracts | dYdX V4 App-Chain |
|---------|---------------------|-------------------|
| Order matching | Off-chain + on-chain settlement | In-memory on validators |
| Latency | 2-15 seconds | 1-2 seconds |
| Cost | Gas per trade | Gas abstracted (fee in DYDX) |
| MEV | Exposed to base chain MEV | Sequencer controls order |
| Decentralization | Inherits L2 security | Cosmos validator set |
| Composability | With other EVM protocols | Isolated (IBC for cross-chain) |

**EVM perpetuals work well on Base/Arbitrum with:**
- Off-chain order matching (signed orders, operator submits matches)
- On-chain margin + liquidation engine
- Oracle for mark price (Pyth — sub-second latency)
- Partial order matching in calldata (gas optimized)
- GMX-style: LP pool as counterparty (no order book needed)
