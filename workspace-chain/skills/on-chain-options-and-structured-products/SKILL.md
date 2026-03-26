# On-Chain Options & Structured Products

## Options Fundamentals

```
Call option: right to BUY at strike. Value = max(spot - strike, 0) at expiry.
Put option: right to SELL at strike. Value = max(strike - spot, 0) at expiry.

Premium = intrinsic value + time value
Intrinsic: max(spot - strike, 0) for call
Time value: uncertainty that it could become more valuable before expiry

Greeks:
  Delta (Δ): dOption/dSpot — how much option price moves per $1 spot move
  Gamma (Γ): dΔ/dSpot — how fast delta changes (convexity)
  Theta (Θ): dOption/dTime — time decay (options lose value as expiry approaches)
  Vega (ν): dOption/dVolatility — sensitivity to implied volatility
  Rho (ρ): dOption/dRate — sensitivity to interest rates (small for crypto)
```

## Black-Scholes On-Chain

```solidity
library BlackScholes {
    // Approximate Black-Scholes using integer math
    // Full BS requires ln(), e^x, N() (cumulative normal distribution)
    // All approximated for Solidity

    function callPrice(
        uint256 S,      // Spot price (WAD)
        uint256 K,      // Strike price (WAD)
        uint256 T,      // Time to expiry in seconds
        uint256 sigma,  // Implied volatility (WAD, e.g., 0.8e18 = 80% vol)
        uint256 r       // Risk-free rate (WAD, e.g., 0.05e18 = 5%)
    ) internal pure returns (uint256 price) {
        // T in years
        uint256 t = T * 1e18 / 365 days;

        // d1 = [ln(S/K) + (r + σ²/2) × t] / (σ × √t)
        int256 d1 = _calcD1(S, K, t, sigma, r);
        int256 d2 = d1 - int256(sigma * _sqrt(t) / 1e18);

        // C = S × N(d1) - K × e^(-r×t) × N(d2)
        price = S * _normalCDF(d1) / 1e18
              - K * _expNeg(r * t / 1e18) * _normalCDF(d2) / 1e36;
    }

    // Abramowitz and Stegun approximation for N(x)
    function _normalCDF(int256 x) internal pure returns (uint256) {
        // Accurate to 7.5×10^-8
        // ...polynomial approximation...
    }
}
```

## Lyra AMM (Options Market Making)

```
Lyra's innovation: AMM that quotes options using Black-Scholes + dynamic hedging

1. LP deposits collateral (USDC) → provides options liquidity
2. Trader buys call option → Lyra quotes price using BS + IV surface
3. Lyra's AMM now has net delta exposure (it's short a call)
4. Lyra hedges: buys underlying spot to become delta-neutral
5. As vol changes, LP position value changes (vega exposure)
6. Lyra charges a fee for the vega risk

LP risks:
  - Vega risk: if vol increases, LP loses
  - Gamma risk: large price moves hurt LP
  - Skew risk: demand imbalance (everyone buying calls) → one-sided risk
```

## Options Vaults (Structured Products)

### Covered Call Vault
```solidity
contract CoveredCallVault is ERC4626 {
    // Strategy: hold ETH + sell weekly call options
    // Users deposit ETH → vault sells OTM calls → earns premium
    // If ETH doesn't moon above strike: keep premium (positive yield)
    // If ETH moons: upside capped at strike price

    uint256 public strikePrice;    // Set weekly by governance/oracle
    uint256 public optionExpiry;   // Friday 8:00 UTC
    uint256 public premiumAccrued;

    function startNewEpoch() external onlyKeeper {
        // 1. Settle previous week's options
        _settleExpiredOptions();

        // 2. Calculate new strike (e.g., 10% OTM)
        uint256 spotPrice = oracle.getPrice();
        strikePrice = spotPrice * 110 / 100; // 10% out of the money

        // 3. Sell calls at the new strike (to options buyers)
        uint256 premium = _sellCalls(strikePrice);
        premiumAccrued += premium;

        optionExpiry = block.timestamp + 7 days;
    }

    // Distribute accumulated premiums to LP depositors
    function harvestPremiums() external {
        // Convert premiums to more ETH → reinvest
        // Share price appreciation = yield to LPs
    }
}
```

### Put Selling Vault (USDC-denominated)
```
Users deposit USDC
Vault sells ETH puts (OTM) → earns premium
If ETH stays above strike: keep premium (~15-30% APY)
If ETH crashes below strike: vault buys ETH at strike (buying the dip)

Risk: "picking up pennies in front of a steamroller"
      Steady income until black swan event → large loss
```

## Panoptic (Perpetual Options on Uniswap V3)

The most novel options primitive:

```
Key insight: A Uniswap V3 LP position IS equivalent to a short option.
  - LP at range [1900, 2100] while ETH = $2000:
    - If ETH goes to $2100 → LP is fully in USDC (you sold ETH at $2100 = short call)
    - If ETH goes to $1900 → LP is fully in ETH (you bought ETH at $1900 = short put)
  - LP earns fees while in range = option premium

Panoptic makes this explicit:
  - "Panoption seller" = normal LP position (earns fees)
  - "Panoption buyer" = borrows the LP position, pays fees for the "option premium"
  - No expiry: as long as fees are paid, position stays open
  - The fee rate IS the options premium
  - This creates perpetual options with market-determined IV
```

## For Agent Sparta — Yield on Idle Prize Pool Capital

While prize money sits locked waiting for challenge resolution (1-7 days), it can earn yield:

```solidity
contract YieldBearingPrizePool {
    // Idle USDC earns yield during the challenge period
    IPool aave = IPool(AAVE_POOL);
    IERC20 usdc = IERC20(USDC);
    IERC20 aUsdc = IERC20(AUSDC);

    function lockPrizePool(bytes32 challengeId, uint256 amount) external {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        usdc.approve(address(aave), amount);
        aave.supply(address(usdc), amount, address(this), 0); // Deposits to Aave → earns ~5% APY
        prizePoolDeposited[challengeId] = amount;
        prizePoolTimestamp[challengeId] = block.timestamp;
    }

    function payWinners(bytes32 challengeId, address[] calldata winners, uint256[] calldata shares) external {
        uint256 aBalance = aUsdc.balanceOf(address(this));
        aave.withdraw(address(usdc), aBalance, address(this)); // Withdraw principal + interest

        uint256 principal = prizePoolDeposited[challengeId];
        uint256 interest = aBalance - principal;

        // Pay winners their share of principal
        for (uint i = 0; i < winners.length; i++) {
            usdc.safeTransfer(winners[i], principal * shares[i] / 10_000);
        }

        // Interest → protocol treasury or split with participants
        usdc.safeTransfer(treasury, interest);
    }
}
// On a $100K prize pool with 7-day challenge:
// Aave yield: ~5% APY = 5% × 7/365 × $100K = ~$96 interest
// Not huge but adds up at scale
```
