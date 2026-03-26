# Whitepaper Reading & Implementation

## How to Read a Crypto Whitepaper

### The Framework (30-minute read → implementation-ready)

**Step 1 — Abstract (2 min)**: What is the core claim? What problem does it solve? What's the key mechanism? If you can't summarize in 2 sentences, read it again.

**Step 2 — Problem Statement (5 min)**: Who has this problem? How do existing solutions fail? Is this a real problem or a solution looking for one?

**Step 3 — Mechanism (15 min)**: How does it actually work? This is the most important part.
- What are the participants?
- What are the incentives for each participant?
- What prevents participants from lying or cheating?
- Draw the flow diagram if one isn't provided.

**Step 4 — Security Analysis (5 min)**: What assumptions does the mechanism make? What breaks if those assumptions fail? What attack vectors did the authors miss (they always miss some)?

**Step 5 — Implementation Feasibility (3 min)**: Can this run in a smart contract? What's the on-chain computational complexity? What needs to be off-chain?

## Practice: Implementing Uniswap V3 From the Paper

### The Core Formula (from whitepaper, Section 2.1)
```
x = L / √P_upper - L / √P          (token X reserves in range)
y = L × (√P - √P_lower)            (token Y reserves in range)
Where: P = current price, P_lower/P_upper = range bounds, L = liquidity
```

**Implementation from formula**:
```solidity
function getAmountsForLiquidity(
    uint160 sqrtPriceX96,       // Current price as Q64.96 fixed point
    uint160 sqrtPriceLowerX96,  // Lower bound
    uint160 sqrtPriceUpperX96,  // Upper bound
    uint128 liquidity
) internal pure returns (uint256 amount0, uint256 amount1) {
    if (sqrtPriceX96 <= sqrtPriceLowerX96) {
        // All in token0 (price is below range)
        amount0 = uint256(liquidity) * Q96 / sqrtPriceLowerX96
                - uint256(liquidity) * Q96 / sqrtPriceUpperX96;
    } else if (sqrtPriceX96 < sqrtPriceUpperX96) {
        // Split between token0 and token1 (price is in range)
        amount0 = uint256(liquidity) * Q96 / sqrtPriceX96
                - uint256(liquidity) * Q96 / sqrtPriceUpperX96;
        amount1 = uint256(liquidity) * (sqrtPriceX96 - sqrtPriceLowerX96) / Q96;
    } else {
        // All in token1 (price is above range)
        amount1 = uint256(liquidity) * (sqrtPriceUpperX96 - sqrtPriceLowerX96) / Q96;
    }
}
```

This IS Uniswap V3's actual implementation pattern — derived directly from the formulas in the whitepaper.

## Practice: Implementing Curve StableSwap

### The Invariant (from the paper)
```
A × n^n × Σxᵢ + D = A × D × n^n + D^(n+1) / (n^n × Πxᵢ)
```

**Key question from paper**: How do you find D (the invariant) given current balances?
The paper shows you iterate using Newton's method:

```solidity
function getD(uint256[] memory xp, uint256 amp) internal pure returns (uint256) {
    uint256 n = xp.length;
    uint256 S = 0;
    for (uint256 i = 0; i < n; i++) S += xp[i];

    if (S == 0) return 0;

    uint256 Dprev = 0;
    uint256 D = S;
    uint256 Ann = amp * n;

    for (uint256 k = 0; k < 255; k++) {
        uint256 D_P = D;
        for (uint256 j = 0; j < n; j++) {
            D_P = D_P * D / (xp[j] * n + 1);  // +1 to prevent div by zero
        }
        Dprev = D;
        // Newton's method step
        D = (Ann * S + D_P * n) * D / ((Ann - 1) * D + (n + 1) * D_P);

        if (D > Dprev ? D - Dprev <= 1 : Dprev - D <= 1) return D;  // Converged
    }
    revert("Did not converge");
}
```

This is exactly how Curve's contracts compute the invariant — straight from the math in the paper.

## Evaluating Novel Mechanisms

### Red Flags in Whitepapers
- "We assume honest majority" — always ask what "honest" means and why they'd be honest
- Missing the attack where the mechanism's DESIGNER cheats
- Circular economic arguments ("token value supports yield which supports token value")
- Glossing over the oracle problem ("oracle will report X" — who is the oracle and why are they honest?)
- Claims of novel cryptography that isn't peer-reviewed
- No simulation or empirical evidence — only theoretical analysis

### Green Flags
- Formal security proofs with clear assumptions
- Live simulation results showing stable equilibria
- Precedent in traditional finance with blockchain adaptations
- Honest discussion of failure modes and edge cases
- Explicit game-theoretic analysis of each participant's strategy

## Building Novel Mechanisms (Process)

```
1. Identify the gap: What problem exists that current mechanisms solve poorly?
   Example: "Users can't get oracle-quality price discovery without centralized matching"

2. Define the participants: Who uses this?
   - Liquidity providers
   - Traders
   - Arbitrageurs
   - Attackers

3. Define each participant's optimal strategy
   - What maximizes LP profit?
   - What maximizes trader profit?
   - Is honest behavior the dominant strategy for each?

4. Identify failure modes:
   - What if one participant controls 51%?
   - What happens in a flash crash?
   - What happens if gas is 0?

5. Prototype in Python first (10x faster to iterate)
   → Then Solidity
   → Then fuzz testing
   → Then simulation (cadCAD)
   → Then audit

6. Red team it: give someone money to break it
```
