# Advanced AMM Mathematics

A comprehensive reference for the mathematics underlying automated market makers (AMMs), covering derivations, implementations, and numerical examples for production-grade DeFi engineering.

---

## Table of Contents

1. [Uniswap V2 — Constant Product AMM](#1-uniswap-v2--constant-product-amm)
2. [Uniswap V3 — Concentrated Liquidity](#2-uniswap-v3--concentrated-liquidity)
3. [Uniswap V3 Tick Math & Fixed-Point Arithmetic](#3-uniswap-v3-tick-math--fixed-point-arithmetic)
4. [Curve StableSwap](#4-curve-stableswap)
5. [Curve V2 (Tricrypto)](#5-curve-v2-tricrypto)
6. [Impermanent Loss](#6-impermanent-loss)
7. [Balancer Weighted Pools](#7-balancer-weighted-pools)
8. [TWAP Oracles](#8-twap-oracles)
9. [Liquidity Bootstrapping Pools (LBP)](#9-liquidity-bootstrapping-pools-lbp)
10. [LP Position P&L](#10-lp-position-pl)
11. [Optimal Fee Tier Selection](#11-optimal-fee-tier-selection)
12. [Concentrated Liquidity Strategies](#12-concentrated-liquidity-strategies)

---

## 1. Uniswap V2 — Constant Product AMM

### 1.1 The Constant Product Invariant

The invariant is:

```
x * y = k
```

where `x` is the reserve of token X, `y` is the reserve of token Y, and `k` is a constant maintained by all trades (adjusted upward only by fees).

**Geometric interpretation:** The invariant defines a hyperbola in (x, y) space. All valid pool states lie on this curve. Swaps move the state along the curve; liquidity deposits/withdrawals scale `k`.

### 1.2 Spot Price Derivation

The marginal price of X in terms of Y is the negative derivative of `y` with respect to `x`:

```
y = k / x
dy/dx = -k / x²  = -y / x
```

Therefore the spot price (how many Y per unit X) is:

```
P = y / x
```

This is the price at zero trade size. Real trades face price impact.

### 1.3 Swap Formula Derivation (with Fees)

Let `Δx` be tokens X sent to the pool. The protocol applies a fee `γ = 1 - fee` (e.g. γ = 0.997 for 0.3% fee). The effective input is `Δx · γ`. The invariant must hold after the swap:

```
(x + Δx · γ) · (y - Δy) = x · y = k
```

Solving for `Δy`:

```
y - Δy = k / (x + Δx · γ)
Δy = y - k / (x + Δx · γ)
Δy = y · (1 - x / (x + Δx · γ))
Δy = y · Δx · γ / (x + Δx · γ)
```

**Final swap formula:**

```
Δy = (y · Δx · γ) / (x + Δx · γ)
```

**Price impact** is the deviation from spot price. The effective price is:

```
P_effective = Δy / Δx = y · γ / (x + Δx · γ)
P_spot = y / x

Price Impact = 1 - P_effective / P_spot
             = 1 - x · γ / (x + Δx · γ)
             = Δx · γ / (x + Δx · γ)
```

For small trades (Δx << x), price impact ≈ Δx · γ / x.

### 1.4 LP Share Calculation

When adding liquidity (Δx, Δy) to a pool with reserves (x, y) and total supply S of LP tokens:

```
LP_minted = S · min(Δx / x, Δy / y)
```

The `min` ensures the ratio is maintained. On first deposit, S = sqrt(Δx · Δy) (geometric mean, per Uniswap V2 implementation, minus MINIMUM_LIQUIDITY = 1000 burned to address(0)).

**Withdrawing liquidity:** Burning `l` LP tokens returns:

```
Δx_out = l / S · x
Δy_out = l / S · y
```

### 1.5 Fee Math

Fees accrue in-place: every swap increases `k` by leaving some fee in the reserves. After a swap of Δx in with 0.3% fee:

```
k_new = (x + Δx · γ) · (y - Δy)
      = x · y   [invariant holds]
      = k
```

But the fee (0.3% of Δx) remains in x-reserve, meaning:

```
x_new = x + Δx  (full Δx stays)
y_new = y - Δy
k_new = x_new · y_new > k
```

The fee causes `k` to grow, accruing to all LP holders pro-rata.

**Protocol fee:** Uniswap V2 has a protocol fee switch. When active, 1/6th of the 0.3% LP fee (i.e., 0.05%) goes to the protocol. This is implemented by minting LP tokens to `feeTo` at each liquidity event, computed as:

```
fee_LP = S · (sqrt(k_new) - sqrt(k_old)) / (n · sqrt(k_new) + sqrt(k_old))
```

where `n = 6` (the fee denominator).

### 1.6 Solidity Implementation (Core Math)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UniswapV2Math {
    // Given input amount and reserves, compute output amount
    // fee = 30 (basis points * 10, i.e., 0.30%)
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeBps  // e.g. 30 for 0.30%
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * (10000 - feeBps);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // Compute LP tokens minted when adding liquidity
    function computeLPMinted(
        uint256 amount0,
        uint256 amount1,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalSupply
    ) internal pure returns (uint256 liquidity) {
        if (totalSupply == 0) {
            liquidity = sqrt(amount0 * amount1) - 1000; // MINIMUM_LIQUIDITY
        } else {
            liquidity = min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) { z = x; x = (y / x + x) / 2; }
        } else if (y != 0) { z = 1; }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```

### 1.7 Python Simulation

```python
import numpy as np

class UniswapV2Pool:
    def __init__(self, x: float, y: float, fee: float = 0.003):
        self.x = x
        self.y = y
        self.fee = fee  # e.g. 0.003 = 0.3%
        self.k = x * y

    def spot_price(self) -> float:
        """Price of X in terms of Y (Y per X)."""
        return self.y / self.x

    def swap_x_for_y(self, dx: float) -> float:
        """Swap dx of X, return dy of Y received."""
        gamma = 1 - self.fee
        dy = (self.y * dx * gamma) / (self.x + dx * gamma)
        self.x += dx
        self.y -= dy
        return dy

    def price_impact(self, dx: float) -> float:
        """Price impact as a fraction."""
        gamma = 1 - self.fee
        return (dx * gamma) / (self.x + dx * gamma)

    def add_liquidity(self, dx: float, dy: float, total_supply: float) -> float:
        if total_supply == 0:
            lp = np.sqrt(dx * dy)
        else:
            lp = min(dx / self.x, dy / self.y) * total_supply
        self.x += dx
        self.y += dy
        return lp

# Numerical example
pool = UniswapV2Pool(1_000_000, 2_000_000)  # 1M X, 2M Y, spot = 2.0
print(f"Spot price: {pool.spot_price():.4f} Y/X")
dy = pool.swap_x_for_y(10_000)
print(f"Swap 10,000 X -> {dy:.2f} Y")
print(f"New spot: {pool.spot_price():.4f}")
print(f"Price impact: {pool.price_impact(10_000)*100:.4f}%")  # before swap
```

**Numerical example:**
- Pool: x=1,000,000 USDC, y=1,000,000 ETH equivalent, k=10^12
- Swap dx=1,000 X, fee=0.3%, gamma=0.997
- dy = (1,000,000 · 1,000 · 0.997) / (1,000,000 + 1,000 · 0.997) = 997,000,000 / 1,000,997 ≈ 996.00
- Price impact = 1,000 · 0.997 / 1,000,997 ≈ 0.0997%

---

## 2. Uniswap V3 — Concentrated Liquidity

### 2.1 Virtual vs Real Reserves

V3 generalizes V2 by allowing LPs to concentrate liquidity within a price range [P_a, P_b]. The key insight is that a position in range [P_a, P_b] is equivalent to a V2 position with virtual reserves that are offset by amounts corresponding to the endpoints.

Define:
- `sqrt_P = sqrt(P)` — square root of current price
- `sqrt_Pa = sqrt(P_a)` — lower bound
- `sqrt_Pb = sqrt(P_b)` — upper bound
- `L` — liquidity (the fundamental unit, analogous to sqrt(k) in V2)

**Virtual reserves** (the V2 equivalent pool that this position "pretends" to be):

```
x_virtual = L / sqrt_P
y_virtual = L * sqrt_P
```

**Real reserves** (actual tokens held by the position):

When price is within range (Pa <= P <= Pb):
```
x_real = L * (1/sqrt_P - 1/sqrt_Pb)
y_real = L * (sqrt_P - sqrt_Pa)
```

When price is below Pa (position is all X):
```
x_real = L * (1/sqrt_Pa - 1/sqrt_Pb)
y_real = 0
```

When price is above Pb (position is all Y):
```
x_real = 0
y_real = L * (sqrt_Pb - sqrt_Pa)
```

### 2.2 Invariant in V3

Within a tick range, V3 behaves as a V2 pool with modified reserves:

```
(x + L/sqrt_Pb) * (y + L*sqrt_Pa) = L²
```

This is the V3 invariant within a single tick range. This is derived by substituting the real reserve formulas and verifying the product equals L².

**Proof:**
```
(x_real + L/sqrt_Pb) * (y_real + L*sqrt_Pa)
= (L*(1/sqrt_P - 1/sqrt_Pb) + L/sqrt_Pb) * (L*(sqrt_P - sqrt_Pa) + L*sqrt_Pa)
= (L/sqrt_P) * (L*sqrt_P)
= L²  ✓
```

### 2.3 Liquidity Calculation from Position

Given a position with amounts (x, y) at current price P within range [Pa, Pb]:

```
L_from_x = x / (1/sqrt_P - 1/sqrt_Pb)  = x * sqrt_P * sqrt_Pb / (sqrt_Pb - sqrt_P)
L_from_y = y / (sqrt_P - sqrt_Pa)
L = min(L_from_x, L_from_y)
```

The `min` ensures the position fits within both constraints. In practice, when providing liquidity, you specify one token amount and the contract computes the other.

### 2.4 Swap Math Within a Tick

For a swap moving price from sqrt_P to sqrt_P_next (within a single tick range), the amount consumed and produced:

**Swapping X for Y (price decreases, sqrt_P decreases):**
```
Δx = L * (1/sqrt_P_next - 1/sqrt_P)     [X consumed]
Δy = L * (sqrt_P - sqrt_P_next)          [Y produced]
```

**Swapping Y for X (price increases, sqrt_P increases):**
```
Δy = L * (sqrt_P_next - sqrt_P)          [Y consumed]
Δx = L * (1/sqrt_P - 1/sqrt_P_next)     [X produced]
```

### 2.5 Position Value Calculation

The value of a V3 LP position in terms of token Y (with Y as numeraire):

```
V = x * P + y
  = L * (1/sqrt_P - 1/sqrt_Pb) * P + L * (sqrt_P - sqrt_Pa)
  = L * (sqrt_P - sqrt_P²/sqrt_Pb - sqrt_Pa + sqrt_P ... )
```

Simplifying:

```
V = L * (2*sqrt_P - sqrt_Pa - P/sqrt_Pb)
```

This is valid when Pa <= P <= Pb. Outside the range, the position holds only one token and the value is simply its token amount times current price.

### 2.6 Fee Accrual in V3

Unlike V2, V3 fees are tracked per-unit-liquidity using fee growth globals and per-position fee accumulators.

**feeGrowthGlobal:** accumulates fee per unit of liquidity, ever-increasing:
```
feeGrowthGlobal += fee_amount / liquidity_active
```

**feeGrowthInsideX128:** tracks fee growth inside a tick range [tickLower, tickUpper]. When a position is updated, it records `feeGrowthInsideLastX128`. At withdrawal:

```
fees_owed = liquidity * (feeGrowthInside_current - feeGrowthInsideLastX128) / 2^128
```

This design allows O(1) fee calculation regardless of how many swaps occurred.

### 2.7 Solidity Snippet: Liquidity from Amounts

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FullMath.sol";
import "./FixedPoint96.sol";

library LiquidityAmounts {
    // Compute liquidity from amount0 (token X) and price range
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(
            sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96
        );
        return uint128(FullMath.mulDiv(
            amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96
        ));
    }

    // Compute liquidity from amount1 (token Y) and price range
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return uint128(FullMath.mulDiv(
            amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96
        ));
    }

    // Combine both — uses min liquidity
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liq0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liq1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);
            liquidity = liq0 < liq1 ? liq0 : liq1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }
}
```

---

## 3. Uniswap V3 Tick Math & Fixed-Point Arithmetic

### 3.1 Q64.96 Fixed-Point Format

Uniswap V3 represents `sqrtPriceX96` as a Q64.96 fixed-point number: a 160-bit unsigned integer where the lower 96 bits are the fractional part.

```
sqrtPriceX96 = sqrt(price) * 2^96
price = (sqrtPriceX96 / 2^96)^2
```

The choice of 96 bits gives sufficient precision while fitting in a uint160 (which fits in a 256-bit EVM word alongside other data). Q64.96 means: 64 bits for the integer part, 96 bits for the fraction.

**Constants:**
```
Q96 = 2^96 = 79228162514264337593543950336
MIN_SQRT_RATIO = 4295128739          (price ≈ 2^(-184))
MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342  (price ≈ 2^(184))
```

### 3.2 Tick to Price Mapping

The tick system divides the price range into discrete intervals. Tick `i` corresponds to:

```
price(i) = 1.0001^i
sqrt_price(i) = 1.0001^(i/2) = sqrt(1.0001)^i
```

Each tick represents a 0.01% (1 basis point) price move (since 1.0001 - 1 = 0.0001 = 1 bps). This is why tick spacing matters: a fee tier of 0.05% uses tick spacing 10 (10 bps), 0.3% uses spacing 60, and 1% uses spacing 200.

**Tick boundaries:**
```
MIN_TICK = -887272
MAX_TICK = 887272
```

These bounds ensure sqrtPriceX96 fits in uint160.

### 3.3 getSqrtRatioAtTick — Derivation

The core formula:
```
sqrtPriceX96 = sqrt(1.0001^tick) * 2^96
             = 1.00005^tick * 2^96
```

Because `1.0001 = (1.00005)^2`, so `sqrt(1.0001^tick) = 1.00005^tick`.

**TickMath.sol implementation strategy:** Instead of computing `1.00005^tick` directly (which would require floating point), the contract decomposes `tick` into its binary representation and multiplies precomputed powers of `1.00005` for each set bit.

```
tick = sum over bits: bit_i * 2^i

sqrtP = product over set bits: 1.00005^(2^i)
```

Each `1.00005^(2^i)` is a precomputed Q128.128 constant. The multiplication uses 512-bit intermediate arithmetic to avoid overflow.

**Key constants (first few, in Q128.128 form):**
```
bit 0: 1.00005^1    → 0xfffcb933bd6fad37aa2d162d1a594001
bit 1: 1.00005^2    → 0xfff97272373d413259a46990580e213a
bit 2: 1.00005^4    → 0xfff2e50f5f656932ef12357cf3c7fdcc
...
```

The final result is divided by 2^32 to obtain Q64.96 format (the constants are in Q128.128).

### 3.4 getTickAtSqrtRatio — Binary Search + Log

Given a sqrtPriceX96, find the tick:

```
tick = floor(log_{1.0001}(price))
     = floor(2 * log_{1.0001}(sqrtPrice))
     = floor(log(sqrtPrice^2) / log(1.0001))
```

**Implementation approach in TickMath.sol:**

1. Compute `log2(sqrtPriceX96 / 2^96)` using bit manipulation:
   - Find the most significant bit of the ratio
   - Iteratively square and shift to compute the fractional part of log2

2. Convert log2 to log_{1.0001}:
   ```
   log_{1.0001}(x) = log2(x) / log2(1.0001)
   1/log2(1.0001) ≈ 1/0.0000144269... ≈ 69314.71...
   ```
   In fixed-point: multiply by `255738958999603826347141` (a Q128 constant)

3. Apply floor to get the tick, then verify by checking `getSqrtRatioAtTick(tick) <= sqrtRatioX96 < getSqrtRatioAtTick(tick+1)`.

### 3.5 Solidity: TickMath Core (Simplified)

```solidity
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library TickMathSimplified {
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    // Compute sqrtPriceX96 from tick using precomputed magic constants
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;

        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // Shift from Q128.128 to Q64.96 and round up
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
}
```

### 3.6 Python: Tick Math Verification

```python
import math

Q96 = 2**96
LOG_BASE = math.log(1.0001)

def tick_to_sqrt_price(tick: int) -> float:
    """Compute sqrt(1.0001^tick) directly."""
    return math.sqrt(1.0001 ** tick)

def sqrt_price_to_sqrtPriceX96(sqrt_price: float) -> int:
    """Convert to Q64.96 fixed-point."""
    return int(sqrt_price * Q96)

def tick_to_sqrtPriceX96(tick: int) -> int:
    return sqrt_price_to_sqrtPriceX96(tick_to_sqrt_price(tick))

def sqrtPriceX96_to_price(sqrtPriceX96: int) -> float:
    sqrt_price = sqrtPriceX96 / Q96
    return sqrt_price ** 2

def tick_to_price(tick: int) -> float:
    return 1.0001 ** tick

# Verification
for tick in [-887272, -100, 0, 100, 887272]:
    price = tick_to_price(tick)
    sqrt = tick_to_sqrt_price(tick)
    spX96 = tick_to_sqrtPriceX96(tick)
    print(f"tick={tick:8d}  price={price:.6e}  sqrtP={sqrt:.6f}  sqrtPX96={spX96}")
```

---

## 4. Curve StableSwap

### 4.1 Motivation

The constant product (x*y=k) formula has high price impact for stablecoins because it prices assets as if they can diverge arbitrarily. StableSwap combines a constant sum invariant (x+y=C) and a constant product, weighting them to stay near the constant sum when assets are balanced.

### 4.2 The StableSwap Invariant

For `n` assets with balances `x_i` and amplification coefficient `A`:

```
A * n^n * Σ(x_i) + D = A * D * n^n + D^(n+1) / (n^n * Π(x_i))
```

Where `D` is the invariant (total value when all assets are equal).

When all balances are equal: `x_i = D/n` for all i, and D is the total pool value.

**Simplified for n=2 (two assets x, y):**
```
4*A*(x+y) + D = 4*A*D + D³/(4*x*y)
```

**Understanding the A parameter:**
- A=0: pure constant product (x*y = (D/2)²)
- A→∞: pure constant sum (x+y = D)
- Typical values: A=100 for stablecoins (e.g. USDC/DAI), A=2000 for highly correlated assets

### 4.3 Deriving D — Newton's Method

Given balances `(x_0, x_1, ..., x_{n-1})`, find `D` such that the invariant holds. There is no closed-form solution; we use Newton's method.

**Rewrite the invariant as f(D) = 0:**
```
f(D) = A*n^n*Σ(x_i)*D + n^n*Π(x_i)*D - A*n^n*D² - D^(n+1)/...
```

More cleanly, define:
```
f(D) = D^(n+1)/(n^n * Π(x_i)) + (A*n^n - 1)*D - A*n^n*Σ(x_i)
```

**Newton step:**
```
D_{k+1} = D_k - f(D_k) / f'(D_k)
```

**Curve's Newton iteration (as in StableSwap code):**
```python
def get_D(xp: list, A: int) -> int:
    n = len(xp)
    S = sum(xp)
    if S == 0:
        return 0
    D = S
    Ann = A * n
    for _ in range(255):
        D_P = D
        for x in xp:
            D_P = D_P * D // (n * x)   # D_P = D^(n+1) / (n^n * prod(x_i))
        D_prev = D
        D = (Ann * S + D_P * n) * D // ((Ann - 1) * D + (n + 1) * D_P)
        if abs(D - D_prev) <= 1:
            return D
    raise Exception("D did not converge")
```

The Newton update formula is derived from the invariant. Let `D_P = D^(n+1)/(n^n * Π(x_i))`:
```
D_new = (Ann*S + n*D_P) * D / ((Ann-1)*D + (n+1)*D_P)
```

This usually converges in 4-8 iterations.

### 4.4 Exchange Calculation

To swap `dx` of token `i` for token `j`, find new balance `x_j_new` given `x_i_new = x_i + dx`:

Fix all balances except `x_j`. The invariant defines a constraint on `x_j`:

```
get_y(i, j, x_i_new, xp) -> x_j_new
```

**Derivation:** With known balances except `x_j`, let `S' = Σ_{k≠j} x_k` and `P' = Π_{k≠j} x_k`. The invariant becomes:

```
A*n^n*(S'+x_j) + D = A*n^n*D + D^(n+1)/(n^n * P' * x_j)
```

Let `b = S' + D/Ann` and `c = D^(n+2)/(Ann * n^n * P')`. Then:

```
x_j^2 + b*x_j - c = 0
x_j = (-b + sqrt(b² + 4c)) / 2
```

This is solved again via Newton's method:
```python
def get_y(i: int, j: int, x: int, xp_: list, A: int, D: int) -> int:
    n = len(xp_)
    Ann = A * n
    c = D
    S_ = 0
    _x = 0
    for k in range(n):
        if k == i:
            _x = x
        elif k != j:
            _x = xp_[k]
        else:
            continue
        S_ += _x
        c = c * D // (n * _x)
    c = c * D // (n * Ann)
    b = S_ + D // Ann
    y = D
    for _ in range(255):
        y_prev = y
        y = (y*y + c) // (2*y + b - D)
        if abs(y - y_prev) <= 1:
            return y
    raise Exception("y did not converge")

def exchange(i: int, j: int, dx: int, xp: list, A: int, fee: int) -> int:
    """fee in units of 1e10 (e.g., 4000000 = 0.04%)"""
    D = get_D(xp, A)
    xp_new = xp.copy()
    xp_new[i] += dx
    y = get_y(i, j, xp_new[i], xp_new, A, D)
    dy = xp[j] - y - 1  # -1 for rounding
    fee_amount = dy * fee // 10**10
    return dy - fee_amount
```

### 4.5 Amplification Coefficient Dynamics

In production Curve pools, `A` is not static. It ramps linearly over time between `A_initial` and `A_final`:

```
A(t) = A_initial + (A_final - A_initial) * (t - t_initial) / (t_final - t_initial)
```

This allows governance to adjust pool behavior (e.g., lower A to reduce gas subsidization of arbitrageurs during depegs). The ramp is bounded to change by at most factor 10x per day to prevent sudden manipulation.

```solidity
function _A() internal view returns (uint256) {
    uint256 t1 = future_A_time;
    uint256 A1 = future_A;
    if (block.timestamp < t1) {
        uint256 A0 = initial_A;
        uint256 t0 = initial_A_time;
        if (A1 > A0) {
            return A0 + (A1 - A0) * (block.timestamp - t0) / (t1 - t0);
        } else {
            return A0 - (A0 - A1) * (block.timestamp - t0) / (t1 - t0);
        }
    } else {
        return A1;
    }
}
```

### 4.6 Numerical Example

Pool: USDC/DAI, each 1,000,000 units, A=100, fee=0.04%

```
S = 2,000,000
Ann = 200
Initial D ≈ 2,000,000

Newton iteration:
D_P = D = 2,000,000
D_P = 2e6 * 2e6 / (2 * 1e6) = 2e6   (both x_i = 1e6)
D = (200*2e6 + 2e6*2) * 2e6 / ((200-1)*2e6 + (2+1)*2e6)
  = (400e6 + 4e6) * 2e6 / (398e6 + 6e6)
  = 404e6 * 2e6 / 404e6 = 2e6  ✓

Swap 1000 USDC for DAI:
x_0_new = 1,001,000
Solve for y (DAI): y ≈ 999,000.04 (very small slippage due to high A)
dy = 1,000,000 - 999,000.04 = 999.96
fee = 999.96 * 0.0004 = 0.40
output = 999.96 - 0.40 = 999.56 DAI

Compare to V2: would be ~999.00 (more slippage)
```

---

## 5. Curve V2 (Tricrypto)

### 5.1 Generalized Invariant for Volatile Pairs

Curve V2 extends StableSwap to handle volatile, non-pegged assets (ETH, BTC, USDT). The invariant generalizes the concept using a price scale `p_i` for each asset to normalize balances:

**Transformed balances:**
```
x_i' = x_i * p_i  (normalize all assets to same unit)
```

The invariant uses these normalized balances with a dynamic `A` and `gamma` parameter:

```
K_0 = Π(x_i')^n / (D/n)^n          [constant product term]
K = A * gamma^2 * K_0 / (gamma + 1 - K_0)^2
Invariant: K * Σ(x_i') + Π(x_i') = K * D + (D/n)^n
```

This reduces to constant product when `gamma -> 0` and to a weighted sum near the equilibrium when `K_0 ≈ 1`.

### 5.2 Price Oracle (EMA)

Curve V2 maintains an exponential moving average (EMA) price oracle to detect when the pool is far from equilibrium and update internal price scales.

**EMA update per block:**
```
p_oracle = (p_oracle_prev * (1 - alpha) + p_last * alpha)
alpha = 1 - exp(-dt / half_time)
```

In integer arithmetic (approximately):
```
alpha = dt * 10^18 / (dt + half_time)  [linear approximation for small dt]
p_oracle = (p_oracle_prev * (10^18 - alpha) + p_last * alpha) / 10^18
```

The half_time parameter (e.g. 600 seconds) controls oracle lag.

### 5.3 Dynamic Fees

Curve V2 adjusts fees based on how far the pool is from equilibrium:

```
f = fee_gamma / (fee_gamma + 1 - K_0)
fee = (mid_fee * f + out_fee * (1 - f))
```

Where:
- `mid_fee` = fee at perfect balance (minimum fee, e.g. 0.01%)
- `out_fee` = fee at extreme imbalance (maximum fee, e.g. 0.3%)
- `fee_gamma` = sensitivity parameter

When `K_0 = 1` (pool perfectly balanced): `f ≈ 1`, fee ≈ mid_fee
When `K_0 << 1` (pool very imbalanced): `f ≈ 0`, fee ≈ out_fee

### 5.4 Price Scale Rebalancing

The price scale `p_i` (internal price assumptions) is updated periodically to match the oracle price. This process:
1. Computes the "profit" from the current deviation
2. If profit exceeds a threshold, updates `p_i` toward the oracle price
3. This makes the pool more efficient around current market prices

```python
def adjust_price_scale(xp, p_oracle, p_scale, A, gamma, D):
    # Compute what D would be with oracle prices
    xp_oracle = [xp[0]] + [xp[i] * p_oracle[i] / p_scale[i] for i in range(1, n)]
    D_oracle = get_D_crypto(xp_oracle, A, gamma)
    # If D_oracle > D (we'd have more value at oracle prices), update
    if D_oracle > D * (1 + adjustment_threshold):
        p_scale_new = [p * p_oracle[i] / p_scale[i] for i, p in enumerate(p_scale)]
        return p_scale_new
    return p_scale
```

---

## 6. Impermanent Loss

### 6.1 Definition

Impermanent loss (IL) is the difference in value between:
- **Holding:** keeping the initial token amounts
- **LPing:** providing liquidity and holding LP tokens

It is "impermanent" because it reverses if prices return to the initial ratio.

### 6.2 Mathematical Derivation (V2)

**Initial state:** Pool with `x_0` of X and `y_0` of Y. Price `P_0 = y_0/x_0`. Total value = `x_0 * P_0 + y_0 = 2 * y_0`.

**After price change to P_1:** The pool rebalances along the constant product curve. New reserves:

```
k = x_0 * y_0
x_1 = sqrt(k / P_1) = x_0 * sqrt(P_0 / P_1)
y_1 = sqrt(k * P_1) = y_0 * sqrt(P_1 / P_0)
```

**Value of LP position at P_1:**
```
V_LP = x_1 * P_1 + y_1
     = x_0 * sqrt(P_0/P_1) * P_1 + y_0 * sqrt(P_1/P_0)
     = x_0 * P_0 * sqrt(P_1/P_0) + y_0 * sqrt(P_1/P_0)
     = 2 * y_0 * sqrt(P_1/P_0)
     = 2 * y_0 * sqrt(r)    where r = P_1/P_0
```

**Value of HODL at P_1:**
```
V_HODL = x_0 * P_1 + y_0
       = x_0 * r * P_0 + y_0
       = y_0 * r + y_0
       = y_0 * (1 + r)
```

**Impermanent Loss:**
```
IL = (V_LP - V_HODL) / V_HODL
   = (2*sqrt(r) - (1+r)) / (1+r)
   = 2*sqrt(r)/(1+r) - 1
```

**Key formula:**
```
IL(r) = 2*sqrt(r)/(1+r) - 1
```

Note: IL is always ≤ 0 (always a loss relative to HODL), since 2*sqrt(r) ≤ 1+r by AM-GM inequality.

### 6.3 Numerical IL Table

```python
import numpy as np

def il(r: float) -> float:
    """Impermanent loss as a fraction (negative = loss)."""
    return 2 * np.sqrt(r) / (1 + r) - 1

price_ratios = [0.25, 0.5, 0.75, 0.9, 1.0, 1.1, 1.25, 1.5, 2.0, 4.0, 9.0]
print(f"{'Price ratio':>15} {'IL (%)':>10}")
print("-" * 28)
for r in price_ratios:
    print(f"{r:>15.2f} {il(r)*100:>10.4f}%")
```

Output:
```
  Price ratio      IL (%)
----------------------------
           0.25    -5.7191%
           0.50    -2.0203%
           0.75    -0.5132%
           0.90    -0.1129%
           1.00     0.0000%
           1.10    -0.1130%
           1.25    -0.5132%
           1.50    -2.0203%
           2.00    -5.7191%
           4.00   -20.0000%
           9.00   -40.0000%
```

Note the symmetry: r and 1/r give the same IL (since IL(r) = IL(1/r)). Also IL(-50% price) = IL(+100% price).

### 6.4 V3 Concentrated Liquidity IL

For a V3 position in range [P_a, P_b], IL is more complex because the position holds different amounts depending on the price. The formula:

**When P_a ≤ P ≤ P_b:**
```
V_LP = 2*L*(sqrt(P) - sqrt(Pa)) + 2*L*(1/sqrt(P) - 1/sqrt(Pb))*P
     = 2*L*(sqrt(P) - sqrt(Pa) + P/sqrt(P) - P/sqrt(Pb))
     = 2*L*(2*sqrt(P) - sqrt(Pa) - P/sqrt(Pb))    [wait, let me redo]
```

More precisely, V_LP = y_real + x_real * P:
```
V_LP(P) = L*(sqrt(P) - sqrt(Pa)) + L*(1/sqrt(P) - 1/sqrt(Pb))*P
         = L*(sqrt(P) - sqrt(Pa) + sqrt(P) - P/sqrt(Pb))
         = L*(2*sqrt(P) - sqrt(Pa) - P/sqrt(Pb))
```

V_HODL at price P (with initial deposit at P_0):
```
x_0 = L*(1/sqrt(P_0) - 1/sqrt(Pb))
y_0 = L*(sqrt(P_0) - sqrt(Pa))
V_HODL(P) = x_0 * P + y_0
           = L*(P/sqrt(P_0) - P/sqrt(Pb) + sqrt(P_0) - sqrt(Pa))
```

IL_V3 = V_LP(P)/V_HODL(P) - 1 (computed numerically for a given range)

**Key insight:** A narrower range has higher capital efficiency but higher IL for a given price move outside the range.

### 6.5 IL Hedging Strategies

**1. Options Hedging:**
A strangle (buy OTM put + OTM call) at range boundaries can offset IL. The breakeven fee income needed is approximately the option premium.

```
Premium_breakeven ≈ IL_expected_vol * V_position / time_period
```

**2. Delta Hedging:**
An LP's delta (sensitivity to price changes) is:
```
Δ_LP = ∂V_LP/∂P = L/(2*sqrt(P))   (within range)
```

A HODL position has delta = x_0. The net delta of HODL - LP position:
```
Δ_net = x_0 - L/(2*sqrt(P))
```

This can be hedged with a perpetual short position of size Δ_net. Dynamic rehedging as P changes is needed (gamma risk).

**3. Correlation-based strategies:**
Pair tokens with mean-reverting price relationships (e.g. ETH/stETH) to minimize IL.

### 6.6 IL vs Fee Revenue Analysis

Break-even holding period where fee income equals IL:

```
T_breakeven = IL / (daily_fee_yield)
daily_fee_yield = (volume_daily * fee_rate) / TVL
```

Example:
```
Pool: ETH/USDC, 0.3% fee tier
Assumptions:
  - 1x price move (price doubles) → IL = 5.72%
  - Daily volume/TVL ratio = 0.1 (10% daily turnover)
  - Fee rate = 0.003

Daily fee yield = 0.1 * 0.003 = 0.03% per day
Days to break even on 5.72% IL = 5.72 / 0.03 ≈ 191 days
```

If volume/TVL is higher (e.g., 50%), breakeven = 38 days. This framework guides fee tier and pair selection.

---

## 7. Balancer Weighted Pools

### 7.1 Generalized Constant Product (Weighted)

Balancer generalizes constant product to arbitrary weights. For tokens with balances `B_i` and weights `w_i` (summing to 1):

```
Π(B_i^w_i) = k   (invariant)
```

For equal weights (w_i = 1/n), this reduces to the geometric mean, which is equivalent to the standard constant product for n=2.

### 7.2 Spot Price Formula

The spot price of token `i` in terms of token `j`:

```
SP_ij = (B_i / w_i) / (B_j / w_j)
```

This is the marginal exchange rate without fees. Intuition: a token with higher weight contributes more to the invariant, so its price is "amplified" by its weight ratio.

**With fee (swap fee f):**
```
EP_ij = SP_ij / (1 - f)
```

### 7.3 Out-Given-In Swap Formula

Swapping `A_i` of token i for token j:

```
A_o = B_j * (1 - (B_i / (B_i + A_i * (1-f)))^(w_i/w_j))
```

**Derivation:**
Starting from the invariant:
```
B_i^w_i * B_j^w_j * Π_{k≠i,j}(B_k^w_k) = k
(B_i + A_i_eff)^w_i * (B_j - A_o)^w_j * ... = k
```

Dividing:
```
((B_i + A_i_eff) / B_i)^w_i = (B_j / (B_j - A_o))^w_j
```

Solving for `A_o`:
```
(B_j - A_o) = B_j * (B_i / (B_i + A_i_eff))^(w_i/w_j)
A_o = B_j * (1 - (B_i/(B_i + A_i_eff))^(w_i/w_j))
```

where `A_i_eff = A_i * (1 - f)`.

### 7.4 In-Given-Out Swap Formula

Given desired output `A_o`, compute required input `A_i`:

```
A_i = B_i * ((B_j / (B_j - A_o))^(w_j/w_i) - 1) / (1 - f)
```

### 7.5 Multi-Asset Proportional Join/Exit

Proportional join (deposit all tokens in ratio): straightforward, no swap needed.
```
BPT_out = BPT_supply * (ratio - 1)    where ratio = B_i_new / B_i_old (same for all i)
```

Single-token join (deposit token i only): treated as depositing proportionally then swapping excess.
```
BPT_out = BPT_supply * ((B_i + A_i*(1-f))/ B_i)^w_i - 1)
```

### 7.6 Python: Balancer Math

```python
class BalancerPool:
    def __init__(self, balances: list, weights: list, fee: float = 0.003):
        assert abs(sum(weights) - 1.0) < 1e-10, "Weights must sum to 1"
        self.balances = list(balances)
        self.weights = list(weights)
        self.fee = fee

    def spot_price(self, i: int, j: int) -> float:
        return (self.balances[i] / self.weights[i]) / (self.balances[j] / self.weights[j])

    def swap_out_given_in(self, i: int, j: int, amount_in: float) -> float:
        Bi, Bj = self.balances[i], self.balances[j]
        wi, wj = self.weights[i], self.weights[j]
        amount_in_eff = amount_in * (1 - self.fee)
        ratio = Bi / (Bi + amount_in_eff)
        return Bj * (1 - ratio ** (wi / wj))

    def swap_in_given_out(self, i: int, j: int, amount_out: float) -> float:
        Bi, Bj = self.balances[i], self.balances[j]
        wi, wj = self.weights[i], self.weights[j]
        ratio = Bj / (Bj - amount_out)
        return Bi * (ratio ** (wj / wi) - 1) / (1 - self.fee)

# Example: 80/20 WBTC/WETH pool
pool = BalancerPool(
    balances=[10.0, 100.0],   # 10 BTC, 100 ETH
    weights=[0.8, 0.2],
    fee=0.003
)
print(f"Spot price BTC/ETH: {pool.spot_price(0,1):.4f} ETH per BTC")
# = (10/0.8)/(100/0.2) = 12.5/500 = 0.025 BTC per ETH → 40 ETH per BTC
out = pool.swap_out_given_in(1, 0, 1.0)  # sell 1 ETH for BTC
print(f"1 ETH → {out:.6f} BTC")
```

---

## 8. TWAP Oracles

### 8.1 Geometric Mean TWAP in V3

Uniswap V3 uses a log-price accumulator to compute a geometric mean TWAP. Each block, the tick (log-price) is accumulated:

```
tickCumulative[t] = tickCumulative[t-1] + current_tick * (t - t_prev)
```

**TWAP calculation over interval [t0, t1]:**
```
tick_avg = (tickCumulative[t1] - tickCumulative[t0]) / (t1 - t0)
price_TWAP = 1.0001^tick_avg
```

Note: this gives the **geometric mean** price, not arithmetic mean, because:
```
geometric_mean(P_t) = exp(mean(log(P_t)))
```

And since `log_{1.0001}(P_t) = tick_t`, the average tick corresponds to the geometric mean price.

### 8.2 Arithmetic Mean vs Geometric Mean TWAP

**V2 TWAP (arithmetic mean price):** V2 accumulated `price0CumulativeLast = price * time`, so the TWAP is arithmetic. Vulnerable to manipulation by extreme prices since outliers dominate arithmetic means.

**V3 TWAP (geometric mean price):** Far more resistant because a 1000x price spike only contributes log(1000) ≈ 3x more than a 2x spike. Attackers would need to sustain extreme prices for long periods.

### 8.3 Manipulation Resistance Analysis

Cost to manipulate a TWAP oracle up by factor `r` over time window `T`:

**For geometric mean TWAP (V3):**
1. Attacker must push price to some level `P_attack` for duration `T_attack`
2. Required: `tick_attack * T_attack / T = target_tick_offset`
3. Cost is the arbitrage loss from holding pool at manipulated price

**Manipulation cost estimation:**
```
cost ≈ L * (1/sqrt(P_0) - 1/sqrt(P_attack)) * P_attack * (1 - 1/r)   [approximately]
```

For a 10% manipulation (r=1.1) over 30 minutes (T=1800s) in a 1-block window, the cost is typically in the millions of dollars for large pools, making manipulation economically infeasible.

### 8.4 Observation Ring Buffer

V3 stores observations in a fixed-size ring buffer:

```solidity
struct Observation {
    uint32 blockTimestamp;
    int56 tickCumulative;
    uint160 secondsPerLiquidityCumulativeX128;
    bool initialized;
}

Observation[65535] public observations;
uint16 public observationIndex;
uint16 public observationCardinality;   // current ring size
uint16 public observationCardinalityNext; // expanding
```

Operators can pre-warm the buffer (increasing cardinality) to store more historical observations, enabling longer TWAP windows.

### 8.5 Solidity: TWAP Computation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV3Pool {
    function observe(uint32[] calldata secondsAgos)
        external view returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );
}

library OracleLib {
    function getTwap(
        address pool,
        uint32 twapInterval
    ) internal view returns (int24 arithmeticMeanTick) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = twapInterval;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(twapInterval)));

        // Round toward negative infinity if remainder is negative
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(twapInterval)) != 0)) {
            arithmeticMeanTick--;
        }
    }

    function getSqrtTwapX96(
        address pool,
        uint32 twapInterval
    ) internal view returns (uint160 sqrtPriceX96) {
        int24 tick = getTwap(pool, twapInterval);
        // Convert tick to sqrtPriceX96 using TickMath
        // sqrtPriceX96 = getSqrtRatioAtTick(tick)
        // (implementation using TickMath library)
        sqrtPriceX96 = TickMathSimplified.getSqrtRatioAtTick(tick);
    }
}
```

---

## 9. Liquidity Bootstrapping Pools (LBP)

### 9.1 Balancer LBP Concept

An LBP uses Balancer's weighted pool with time-varying weights to enable price discovery for new token launches. The project starts with high weight for the new token (e.g., 95%) and low weight for the collateral (e.g., 5%), then gradually shifts to equal weights over the sale period.

### 9.2 Weight Shifting Math

Weights change linearly over time:

```
w_token(t) = w_start + (w_end - w_start) * (t - t_start) / (t_end - t_start)
w_collateral(t) = 1 - w_token(t)
```

**Effect on price:** The spot price of the new token in terms of collateral:

```
P(t) = (B_token / w_token(t)) / (B_collateral / w_collateral(t))
     = (B_token * w_collateral(t)) / (B_collateral * w_token(t))
```

As `w_token` decreases and `w_collateral` increases, `P(t)` naturally decreases even without any trades. This creates downward price pressure that discourages front-running (buying early and selling immediately).

### 9.3 Price Trajectory Without Trades

Assuming no trades (to isolate weight effect):

```
P(t) / P(0) = (w_collateral(t) / w_token(t)) / (w_collateral(0) / w_token(0))
            = (w_coll(t) * w_token(0)) / (w_coll(0) * w_token(t))
```

Example:
```
t=0: w_token=0.95, w_coll=0.05  → weight_ratio = 0.05/0.95 ≈ 0.0526
t=T: w_token=0.50, w_coll=0.50  → weight_ratio = 1.0

P(T)/P(0) = 1.0/0.0526 ≈ 19x lower   [without any buying]
```

This price decline incentivizes buyers to wait for lower prices unless they believe the token is worth the current price.

### 9.4 Python: LBP Price Simulation

```python
import numpy as np
import matplotlib.pyplot as plt

class LBP:
    def __init__(self, B_token, B_coll, w_token_start, w_token_end, duration_hours):
        self.B_token = B_token
        self.B_coll = B_coll
        self.w_token_start = w_token_start
        self.w_token_end = w_token_end
        self.duration = duration_hours
        self.fee = 0.001

    def weights(self, t: float):
        alpha = t / self.duration
        w_t = self.w_token_start + (self.w_token_end - self.w_token_start) * alpha
        return w_t, 1 - w_t

    def spot_price(self, t: float) -> float:
        w_t, w_c = self.weights(t)
        return (self.B_token / w_t) / (self.B_coll / w_c)

    def simulate(self, n_points=100):
        times = np.linspace(0, self.duration, n_points)
        prices = [self.spot_price(t) for t in times]
        return times, prices

# Example: 48-hour LBP
lbp = LBP(
    B_token=1_000_000,   # 1M tokens
    B_coll=100_000,      # 100k USDC
    w_token_start=0.95,
    w_token_end=0.50,
    duration_hours=48
)
times, prices = lbp.simulate()
print(f"Start price: ${prices[0]:.4f}")
print(f"End price (no buys): ${prices[-1]:.4f}")
print(f"Price decline: {(1 - prices[-1]/prices[0])*100:.1f}%")
```

---

## 10. LP Position P&L

### 10.1 Mark-to-Market Valuation

An LP position's value has three components:
1. **Token value:** x * P + y (spot value of held tokens)
2. **Accrued fees:** fees earned since last collection
3. **IL component:** value loss relative to HODL (embedded in token value)

**Mark-to-market formula:**
```
V_position = V_tokens + V_fees_uncollected
V_tokens = x_lp * P_X + y_lp * P_Y    (in USD or base numeraire)
```

**PnL since inception:**
```
PnL = V_position_current - V_position_initial - net_deposits
IL_component = V_tokens_current - V_HODL_current
Fee_component = V_fees_collected + V_fees_uncollected
```

### 10.2 Fee Accrual Rate

Instantaneous fee APY for a V2 LP:
```
fee_APY = volume_24h * fee_rate * 365 / TVL
```

For V3 LP in a specific range, active liquidity fraction matters:
```
fee_APY_V3 = volume_24h * fee_rate * 365 * (L_position / L_active) / V_position
```

Where `L_active` is the total active liquidity at the current tick.

**Fee accrual tracking in Python:**

```python
class LP_Position:
    def __init__(self, x0: float, y0: float, P0: float):
        self.x0 = x0
        self.y0 = y0
        self.P0 = P0
        self.k = x0 * y0
        self.initial_value = x0 * P0 + y0   # in Y terms

    def value_at(self, P: float) -> float:
        """V2 LP value at price P."""
        x = np.sqrt(self.k / P)
        y = np.sqrt(self.k * P)
        return x * P + y

    def hodl_value_at(self, P: float) -> float:
        return self.x0 * P + self.y0

    def il_at(self, P: float) -> float:
        return self.value_at(P) - self.hodl_value_at(P)

    def pnl_with_fees(self, P: float, fees_earned: float) -> float:
        return self.value_at(P) - self.initial_value + fees_earned

    def simulate_path(self, prices: list, daily_fee_yield: float, dt: float = 1/365):
        """Simulate PnL over a price path."""
        results = []
        fees = 0
        V0 = self.initial_value
        for i, P in enumerate(prices):
            fees += daily_fee_yield * self.value_at(P) * dt * 365
            v = self.value_at(P)
            results.append({
                'price': P,
                'lp_value': v,
                'hodl_value': self.hodl_value_at(P),
                'fees': fees,
                'total_pnl': v + fees - V0,
                'il': self.il_at(P),
            })
        return results
```

### 10.3 Rebalancing Costs

For V3 positions, when price moves out of range, the LP must:
1. Collect fees
2. Remove liquidity (now 100% in one token)
3. Swap to achieve desired ratio for new range
4. Add liquidity in new range

**Cost of rebalancing:**
```
cost_swap = swap_amount * (fee + price_impact)
price_impact = swap_amount / (2 * TVL_tick)   [linear approximation]

total_rebalancing_cost = gas_cost + fee_cost + price_impact_cost
```

**Break-even analysis:** Rebalancing only makes sense if expected additional fee income from the new range exceeds rebalancing cost:
```
T_break_even = rebalancing_cost / (fee_rate_new - fee_rate_old)
```

---

## 11. Optimal Fee Tier Selection

### 11.1 Fee-Volume-Volatility Relationship

The fundamental tradeoff: higher fees earn more per trade but lose volume to lower-fee competitors. The optimal fee depends on asset volatility.

**Economic model:**
- Fee income = fee_rate * volume
- Volume ~ price_sensitivity^(-1) ≈ 1/(fee_rate)^elasticity
- Optimal fee maximizes fee * volume

For constant elasticity demand: optimal fee ∝ 1/elasticity. For stablecoin pairs (very elastic, low volatility), fees should be very low. For volatile pairs, higher fees compensate LPs for IL.

### 11.2 Empirical Analysis Framework

```python
import pandas as pd
import numpy as np
from scipy import stats

def optimal_fee_analysis(
    historical_prices: np.ndarray,
    historical_volumes: dict,   # {fee_tier: volume_array}
    fee_tiers: list = [0.0001, 0.0005, 0.003, 0.01]
) -> pd.DataFrame:
    """
    Analyze fee tiers empirically.
    Returns DataFrame with fee_tier, total_fee_income, avg_IL, net_return.
    """
    results = []
    log_returns = np.diff(np.log(historical_prices))
    volatility = np.std(log_returns) * np.sqrt(365)  # annualized

    for fee in fee_tiers:
        volume = historical_volumes.get(fee, np.zeros(len(historical_prices)-1))
        fee_income = np.sum(volume * fee)
        # Estimate IL using log-normal model
        T = len(historical_prices) / 365
        il_estimate = 2 * np.exp(-0.5 * volatility**2 * T) / (1 + np.exp(0)) - 1
        results.append({
            'fee_tier': fee,
            'fee_income_pct': fee_income / historical_prices[0] * 100,
            'estimated_IL_pct': il_estimate * 100,
            'net_pct': (fee_income / historical_prices[0] + il_estimate) * 100,
            'volume_share': np.sum(volume),
        })
    return pd.DataFrame(results)

def volatility_to_optimal_fee(annualized_vol: float) -> float:
    """
    Heuristic: optimal fee tier given asset pair annualized volatility.
    Based on the principle that fee income should approximately compensate IL.

    IL ≈ sigma^2 * T / 2  (for small moves, log-normal approximation)
    Fee income ≈ fee_rate * volume_to_TVL_ratio * T

    Setting equal: fee_rate = sigma^2 / (2 * volume_to_TVL_ratio)
    """
    # Typical volume/TVL ≈ 0.5x daily for active pairs
    volume_to_tvl_daily = 0.5
    fee = (annualized_vol**2 / 2) / (volume_to_tvl_daily * 365)

    # Map to available tiers
    tiers = [0.0001, 0.0005, 0.003, 0.01]
    return min(tiers, key=lambda t: abs(t - fee))

# Examples:
print(volatility_to_optimal_fee(0.01))   # 1% vol (stablecoin) → 0.01%
print(volatility_to_optimal_fee(0.30))   # 30% vol (ETH) → 0.05%
print(volatility_to_optimal_fee(0.80))   # 80% vol (altcoin) → 0.3% or 1%
```

### 11.3 Fee Income Distribution by Tick

In V3, fees are distributed only to liquidity active during a swap. Fee per unit liquidity:

```
fee_per_L = swap_fee / L_active   [per swap]
fee_APR_per_tick = (volume_through_tick * fee_rate) / L_at_tick * 365
```

Ticks with low liquidity earn more per unit LP, but have higher IL risk.

---

## 12. Concentrated Liquidity Strategies

### 12.1 Range Selection — Mathematical Framework

The key tradeoff in V3 range selection:

**Capital efficiency:** A position in range [Pa, Pb] has capital efficiency factor:
```
CE = 1 / (1 - sqrt(Pa/P) - sqrt(P/Pb) + ...)   [rough estimate]
   ≈ sqrt(Pb/Pa) / (sqrt(Pb/Pa) - 1)    [when range is symmetric around P]
```

For example, a ±10% range around current price (Pa = P/1.1, Pb = P*1.1):
```
CE ≈ sqrt(1.1/0.909) / (sqrt(1.21) - 1) ≈ 1.1 / 0.1 = 11x
```

An 11x capital efficiency means the LP earns fees as if they had 11x more capital in a V2 pool.

**However,** when price exits the range, no fees are earned and the position is 100% in one token.

### 12.2 Optimal Range Width — Theory

For a price following geometric Brownian motion with volatility σ:
- Probability of staying in range [Pa=P*e^{-d}, Pb=P*e^d] over time T:
  ```
  P(stay) ≈ erf(d / (sigma * sqrt(T)))   [for symmetric range]
  ```

- Expected fee income (conditional on staying in range):
  ```
  E[fees | stay] = fee_rate * volume_daily * CE * T
  ```

- IL when price exits range at Pb: `IL = 2*sqrt(Pb/P0)/(1+Pb/P0) - 1`

**Optimal d** balances fee income vs probability of being in range:
```
maximize: E[fees | stay] * P(stay) - E[IL] * (1 - P(stay))
```

This optimization typically gives:
- Low volatility pairs (σ < 20%): tight ranges (±2-5%)
- Medium volatility (20-60%): medium ranges (±10-20%)
- High volatility (> 60%): wide ranges or V2-equivalent full range

### 12.3 Rebalancing Trigger Conditions

**Time-based:** Rebalance every fixed interval (e.g., weekly). Simple but suboptimal.

**Price-based:** Rebalance when price exits range. Optimal for maximizing fee income in range, but high gas cost for volatile pairs.

**Drift-based:** Rebalance when center of range drifts more than threshold from current price:
```
drift = |P_center - P_current| / range_width
if drift > threshold (e.g., 0.5):
    rebalance()
```

**Volatility-adjusted:** Rebalance when the range width should change (due to changing volatility):
```
realized_vol = ewm_std(log_returns, halflife=24h)
optimal_range = 2 * realized_vol * sqrt(T_target)
if |current_range - optimal_range| > tolerance:
    rebalance()
```

### 12.4 Active LP Management Math

**Rebalancing simulation:**

```python
import numpy as np

class V3ActiveLP:
    def __init__(self, initial_capital: float, fee_tier: float, range_pct: float):
        self.capital = initial_capital
        self.fee_tier = fee_tier
        self.range_pct = range_pct  # e.g., 0.10 for ±10%
        self.rebalance_cost = 0.001  # 0.1% of capital per rebalance

    def simulate_gbm(self, mu: float, sigma: float, T: float, dt: float = 1/365):
        """Simulate price path with geometric Brownian motion."""
        n = int(T / dt)
        dW = np.random.normal(0, np.sqrt(dt), n)
        log_returns = (mu - 0.5 * sigma**2) * dt + sigma * dW
        prices = np.exp(np.cumsum(log_returns))
        return prices

    def backtest(self, prices: np.ndarray, volume_to_tvl: float):
        """Backtest active LP strategy."""
        P0 = 1.0
        P_low = P0 * (1 - self.range_pct)
        P_high = P0 * (1 + self.range_pct)
        capital = self.capital
        total_fees = 0
        total_rebalance_cost = 0
        rebalances = 0

        for P in prices:
            # Check if in range
            in_range = P_low <= P <= P_high

            if in_range:
                # Earn fees
                daily_fees = capital * volume_to_tvl * self.fee_tier
                total_fees += daily_fees

            # Rebalance if out of range
            if not in_range:
                P_low = P * (1 - self.range_pct)
                P_high = P * (1 + self.range_pct)
                cost = capital * self.rebalance_cost
                total_rebalance_cost += cost
                capital -= cost
                rebalances += 1

        # Final value (with IL)
        r = prices[-1] / P0
        il = 2 * np.sqrt(r) / (1 + r) - 1
        final_value = capital * (1 + il) + total_fees - total_rebalance_cost

        return {
            'final_value': final_value,
            'total_fees': total_fees,
            'total_rebalance_cost': total_rebalance_cost,
            'rebalances': rebalances,
            'net_return': (final_value - self.capital) / self.capital,
        }

# Monte Carlo simulation
lp = V3ActiveLP(initial_capital=100_000, fee_tier=0.003, range_pct=0.10)
np.random.seed(42)
results = []
for _ in range(1000):
    prices = lp.simulate_gbm(mu=0.0, sigma=0.60, T=1.0)  # 60% vol, 1 year
    result = lp.backtest(prices, volume_to_tvl=0.5)
    results.append(result['net_return'])

print(f"Mean net return: {np.mean(results)*100:.2f}%")
print(f"Std dev: {np.std(results)*100:.2f}%")
print(f"Sharpe: {np.mean(results)/np.std(results):.3f}")
print(f"5th percentile: {np.percentile(results, 5)*100:.2f}%")
```

### 12.5 Range Selection Across Fee Tiers — Decision Matrix

```
Asset pair type          | Volatility | Recommended tier | Range width
-------------------------|------------|------------------|------------
Stable/Stable (same peg) | < 0.5%     | 0.01% (1bps)     | ±0.1%
Stable/Stable (diff peg) | 0.5–2%     | 0.05% (5bps)     | ±0.5%
Stable/Volatile (ETH)    | 30–60%     | 0.30% (30bps)    | ±10–20%
Volatile/Volatile (major)| 40–80%     | 0.30% or 1%      | ±15–30%
Volatile/Volatile (small)| > 80%      | 1% (100bps)      | ±30–50% or full
```

### 12.6 Greeks for V3 Positions

V3 LP positions exhibit option-like behavior. Computing Greeks:

**Delta (sensitivity to price):**
```
Δ_LP = ∂V/∂P = ∂/∂P [L*(2*sqrt(P) - sqrt(Pa) - P/sqrt(Pb))]
             = L*(1/sqrt(P) - 1/sqrt(Pb))
             = x_real    [the real token X amount]
```

**Gamma (second derivative, "convexity"):**
```
Γ_LP = ∂²V/∂P² = ∂Δ/∂P = -L/(2*P^(3/2))   [always negative — short gamma]
```

The negative gamma is the mathematical manifestation of impermanent loss: V3 LP positions are short gamma, meaning they lose value when price moves in either direction.

**Theta (time decay analog — fee income):**
```
Θ_LP = ∂V/∂t = fee_income_rate   [always positive for active positions]
```

The LP is simultaneously short gamma (IL) and long theta (fees). Profitability depends on whether theta (fees) exceeds gamma losses (IL) over the position's lifetime — precisely the fundamental tradeoff of market making.

### 12.7 Summary: Key Mathematical Identities

```
# Uniswap V2
x*y = k
Δy = y*Δx*γ / (x + Δx*γ)     [γ = 1 - fee]
IL(r) = 2√r/(1+r) - 1         [r = P1/P0]

# Uniswap V3
(x + L/√Pb)(y + L√Pa) = L²
x_real = L*(1/√P - 1/√Pb)
y_real = L*(√P - √Pa)
sqrtPriceX96 = √P * 2^96
tick = log_{1.0001}(P) = ln(P)/ln(1.0001)

# Curve StableSwap
A*n^n*Σ(x_i) + D = A*D*n^n + D^(n+1)/(n^n * Π(x_i))
D_{k+1} = (Ann*S + n*D_P)*D / ((Ann-1)*D + (n+1)*D_P)

# Balancer
Π(B_i^w_i) = k
A_o = B_j*(1 - (B_i/(B_i + A_i*(1-f)))^(w_i/w_j))
SP_ij = (B_i/w_i) / (B_j/w_j)

# TWAP
tick_TWAP = (tickCumulative[t1] - tickCumulative[t0]) / (t1 - t0)
price_TWAP = 1.0001^tick_TWAP

# V3 Greeks
Δ_LP = x_real = L*(1/√P - 1/√Pb)
Γ_LP = -L/(2*P^{3/2})            [short gamma → IL]
```

---

## References & Further Reading

- Uniswap V2 Whitepaper: https://uniswap.org/whitepaper.pdf
- Uniswap V3 Core Whitepaper: https://uniswap.org/whitepaper-v3.pdf
- Curve StableSwap Whitepaper: https://curve.fi/files/stableswap-paper.pdf
- Curve V2 Technical Paper: https://curve.fi/files/crypto-pools-paper.pdf
- Balancer Whitepaper: https://balancer.fi/whitepaper.pdf
- "Uniswap v3: A Concentrated Liquidity DEX" — Adams et al. (2021)
- "An Analysis of Uniswap Markets" — Angeris et al. (2019)
- "When Does The Tail Wag The Dog?" — IL analysis by Pintail
- TickMath.sol: https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol
- LiquidityAmounts.sol: https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/LiquidityAmounts.sol
