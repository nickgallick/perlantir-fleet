# Advanced Token Engineering

## Bonding Curves — Mathematical Deep Dive

```python
import numpy as np
import matplotlib.pyplot as plt

# Five curve types — when to use each

def linear(supply, a=1e-6, b=0):
    """price = a*supply + b. Predictable, fair growth."""
    return a * supply + b

def polynomial(supply, a=1e-12, n=2):
    """price = a*supply^n. Exponential growth rewards early buyers."""
    return a * (supply ** n)

def sigmoid(supply, max_price=1.0, k=0.00001, midpoint=500_000):
    """S-curve. Stable at extremes, rapid middle growth."""
    return max_price / (1 + np.exp(-k * (supply - midpoint)))

def logarithmic(supply, a=0.1, b=1):
    """price = a*ln(supply) + b. Fast early growth, slows at scale."""
    return a * np.log(supply + 1) + b

def bancor(reserve_balance, supply, reserve_ratio=0.1):
    """price = reserve_balance / (supply * reserve_ratio). Bancor formula."""
    return reserve_balance / (supply * reserve_ratio)

# Cost to buy t tokens from supply s to s+t:
def buy_cost_linear(s, t, a, b):
    """∫[s→s+t] (a*x+b) dx = a*(s*t + t²/2) + b*t"""
    return a * (s * t + t**2 / 2) + b * t

# Use case matching:
# Linear: equal treatment, no early-buyer advantage, stable price growth
# Polynomial: strong early-buyer incentive (launch mechanics, NFT bonding curves)
# Sigmoid: real-world adoption curves, market saturation built in
# Logarithmic: gradual early reward, most equitable over time
# Bancor: adjustable reserve ratio = adjustable volatility
```

## veToken Economics (Curve War Deep Dive)

```solidity
contract VotingEscrow {
    struct LockedBalance {
        int128 amount;      // Tokens locked
        uint256 end;        // Lock end timestamp
    }

    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years max lock

    mapping(address => LockedBalance) public locked;

    // Lock tokens → receive veTokens (non-transferable)
    // veBalance decays linearly to 0 at lock end
    function createLock(uint256 amount, uint256 unlockTime) external {
        unlockTime = (unlockTime / WEEK) * WEEK; // Round to week
        require(unlockTime > block.timestamp);
        require(unlockTime <= block.timestamp + MAXTIME);

        locked[msg.sender] = LockedBalance(int128(int256(amount)), unlockTime);
        _token.transferFrom(msg.sender, address(this), amount);
    }

    // Current veBalance: decreases linearly until unlock
    function balanceOf(address user) external view returns (uint256) {
        LockedBalance storage lock = locked[user];
        if (lock.end <= block.timestamp) return 0;

        uint256 timeRemaining = lock.end - block.timestamp;
        // Max voting power at lock creation: amount * (timeRemaining/MAXTIME)
        // At 4-year lock: 1 token = 1 veToken
        // At 1-year lock: 1 token = 0.25 veToken
        // Decays to 0 at unlock
        return uint256(lock.amount) * timeRemaining / MAXTIME;
    }
}
```

## Gauge System

```solidity
contract GaugeController {
    mapping(address => uint256) public gaugeWeights;  // gauge → emission weight
    mapping(address => mapping(address => uint256)) public votes; // user → gauge → vote amount

    uint256 public constant WEEK = 7 * 86400;
    uint256 public totalWeight;

    // veToken holders vote for which gauges get emissions
    function vote(address gauge, uint256 weight) external {
        uint256 veBalance = votingEscrow.balanceOf(msg.sender);
        require(weight <= veBalance, "Insufficient veToken");

        // Remove old vote
        address oldGauge = userGauge[msg.sender];
        if (oldGauge != address(0)) {
            gaugeWeights[oldGauge] -= votes[msg.sender][oldGauge];
            totalWeight -= votes[msg.sender][oldGauge];
        }

        // Apply new vote
        votes[msg.sender][gauge] = weight;
        gaugeWeights[gauge] += weight;
        totalWeight += weight;
        userGauge[msg.sender] = gauge;

        // Once per epoch (week): emissions calculated based on gauge weights
    }

    // Each epoch: distribute SPARTA emissions proportional to gauge weights
    function distributeEmissions() external {
        require(block.timestamp >= lastDistribution + WEEK);
        lastDistribution = block.timestamp;

        uint256 totalEmissions = SPARTA.epochEmission();
        for (uint i = 0; i < gauges.length; i++) {
            uint256 gaugeEmission = totalEmissions * gaugeWeights[gauges[i]] / totalWeight;
            SPARTA.mint(gauges[i], gaugeEmission);
        }
    }
}
```

## Real Yield vs Ponzinomics Test

```
THE LITMUS TEST: Remove all token emissions. Does the protocol survive?

Uniswap: YES → still earns swap fees, LPs still provide liquidity (just less)
Curve: MAYBE → less TVL without CRV rewards, but core stableswap still works
Most "yield farming" protocols: NO → entirely dependent on inflation to attract TVL

Sustainable token design:
  Revenue sources:
    - Transaction fees (Uniswap: 0.05-1% per swap)
    - Liquidation fees (Aave: 5-15% bonus)
    - Borrowing spread (lending protocols)
    - Challenge entry fees (Agent Sparta)

  Token value accrual:
    - Fee sharing with stakers/veToken holders
    - Buyback and burn from fees
    - Governance rights over fee parameters

  NOT sustainable:
    - "Yield" paid in the protocol's own new tokens
    - TVL incentives where APY comes entirely from inflation
    - Points → token airdrop where there's no underlying business

Agent Sparta token model (sustainable):
  Revenue: 1-2% of all challenge prize pools
  Accrual: 50% burned, 30% to SPARTA stakers, 20% to treasury
  Test: remove SPARTA emissions → challenges still happen, fees still flow → PASSES
```

## SPARTA Token Design

```
Total supply: 100,000,000 SPARTA (fixed, no mint after launch)
Distribution:
  - Team: 15% (vested 2 years, 6-month cliff)
  - Investors: 15% (vested 18 months)
  - Community/DAO: 40% (emitted over 4 years, gauge-directed)
  - Treasury: 20% (DAO-governed)
  - Initial liquidity: 10% (permanent, LP burned)

Utility:
  - Stake to earn 30% of protocol fee revenue (fee share)
  - Vote on gauge weights (direct where SPARTA emissions go)
  - Governance (parameter changes, new challenge types, fee adjustments)
  - Long lock (veSPARTA) = 4x voting power + boosted rewards

Value accrual:
  - Fee buyback: 50% of fees buy SPARTA from market and burn
  - At $1M/month fees: $500K/month burned = deflationary pressure
  - Staker yield: $300K/month distributed to stakers
  - This is REAL yield (from protocol revenue, not inflation)
```
