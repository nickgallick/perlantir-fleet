# DeFi Primitives

## Automated Market Makers (AMMs)

### Uniswap V2 — Constant Product
`x * y = k` — reserves of token A × token B always equals constant k.
- Price = reserve ratio. Large trades move price significantly (price impact).
- LP tokens represent proportional pool share.
- **Impermanent loss**: LPs lose vs holding when price diverges from entry ratio. IL = 2√p/(1+p) - 1 where p = price ratio change.

### Uniswap V3 — Concentrated Liquidity
LPs provide liquidity in price ranges [tickLower, tickUpper]. Capital efficiency vs V2.
- 4000x more capital efficient at tight ranges.
- LPs earn fees only when price is in their range.
- Each position is an NFT (unique range + amount).
- Tick math: price = 1.0001^tick. Tick spacing varies by fee tier.

### Curve StableSwap
Hybrid invariant between constant product and constant sum. Optimized for like-kind assets (stablecoins, wrapped BTC, etc.).
- `A * n^n * sum(x_i) + D = A * D * n^n + D^(n+1) / (n^n * prod(x_i))`
- A = amplification coefficient. Higher A = tighter peg, less IL, worse for depeg events.
- Much lower slippage for stablecoin swaps than V2.

### LMSR (Logarithmic Market Scoring Rule)
Designed specifically for prediction markets. Robin Hanson's algorithm.
- Cost function: `C(q) = b * ln(sum(exp(q_i / b)))`
- b = liquidity parameter (higher = more liquidity = less price impact = more loss for market maker)
- Properties: prices always sum to 1, always has liquidity, bounded market maker loss = `b * ln(n)` where n = outcomes
- Trade-off vs CLOB: guarantees liquidity but market maker takes guaranteed loss

## Lending Protocols (Aave/Compound Model)

### Core Mechanics
1. Suppliers deposit assets → receive aTokens/cTokens (interest-bearing)
2. Borrowers provide collateral → borrow up to LTV (Loan-to-Value)
3. Interest rate = f(utilization) — higher utilization = higher rate
4. Liquidation triggered when health factor < 1

### Interest Rate Model
```
utilization = borrows / (borrows + available)
if utilization < optimal:
    rate = base + (utilization / optimal) * slope1
else:
    rate = base + slope1 + ((utilization - optimal) / (1 - optimal)) * slope2
```
slope2 is very steep — discourages utilization above optimal (~80-90%).

### Health Factor
`HF = sum(collateral_i * liquidationThreshold_i) / totalBorrows`
- HF < 1 = liquidatable
- Liquidator repays up to 50% of debt, receives collateral + liquidation bonus (5-15%)

### Flash Loans
Borrow any amount within one transaction with zero collateral. Must repay + fee by end of tx.
```solidity
// Implement IFlashLoanReceiver
function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
) external override returns (bool) {
    // Do profitable things here
    // Repay: amounts[0] + premiums[0]
    IERC20(assets[0]).approve(POOL, amounts[0] + premiums[0]);
    return true;
}
```

## Prediction Markets (Deep Dive)

### Binary Market Structure
Two outcomes: YES (token) and NO (token). Each pair always redeemable for $1 USDC total.
- YES + NO = $1 always (no-arbitrage condition enforced by contract)
- Price of YES = market's probability estimate of YES outcome
- If YES resolves: YES holders get $1, NO holders get $0

### Polymarket Architecture
1. **Collateral**: USDC deposited to contract
2. **Minting**: 1 USDC → 1 YES token + 1 NO token
3. **Trading**: CLOB (off-chain order matching, on-chain settlement via 0x-style signed orders)
4. **Resolution**: UMA Optimistic Oracle asserts outcome after deadline
5. **Redemption**: Winners call redeem(), get $1 USDC per winning token

### Gnosis Conditional Token Framework (CTF)
ERC-1155 based. Positions identified by `positionId = keccak256(collateralToken, collectionId)`.
- **Splitting**: Deposit collateral → receive outcome tokens
- **Merging**: Burn complete set of outcome tokens → receive collateral back
- **Redeeming**: Burn winning outcome tokens → receive collateral

### Central Limit Order Book (CLOB)
- Bid/ask order book with price-time priority
- Off-chain matching engine (operator) → on-chain settlement
- Signed orders (EIP-712) validated by contract, no trust in operator for fund safety
- Gas efficient: only settlement on-chain, not matching

## Staking & Yield

### Basic Staking Contract
```
stake(amount) → lock tokens, record timestamp
unstake(amount) → burn position, return tokens
claimRewards() → calculate accrued rewards, transfer
```
Reward per block/second × user_share × time_staked = user_rewards

### Gauge Systems (Curve/Convex)
- veToken model: lock token for 1-4 years → voting escrow token
- Voting power directs emissions to pools
- LPs earn base APY + boosted rewards based on veToken holdings

### Liquid Staking
- stETH (Lido): Rebasing token. Balance increases daily as staking rewards accrue.
- wstETH: Wrapped stETH. Non-rebasing, price appreciation model. Better for DeFi composability.
- rETH (Rocket Pool): Non-rebasing. Exchange rate vs ETH increases over time.

## Governance (OpenZeppelin Governor)

### Proposal Lifecycle
1. `propose()` — Proposer submits calldata to execute
2. Voting delay (N blocks before voting starts)
3. Voting period (N blocks for token holders to vote)
4. If passed + quorum met: `queue()` → Timelock
5. After timelock delay: `execute()`

### Timelock Security
- Delay between governance approval and execution gives users time to exit if they disagree
- Typical: 2-7 days for parameter changes, longer for critical changes
- Emergency operations: separate multisig path for security patches

### Governance Attack Vectors
- **Flash loan governance**: Borrow tokens, vote, return. **Prevention**: snapshot voting power at proposal creation block.
- **Low quorum attacks**: Pass proposals when participation is low. **Prevention**: quorum ≥ 4% of supply.
- **Proposal spam**: Exhaust voter attention. **Prevention**: proposal threshold (must hold N tokens to propose).
