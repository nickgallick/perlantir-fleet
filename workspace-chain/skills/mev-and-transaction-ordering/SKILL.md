# MEV & Transaction Ordering

## What is MEV
Maximal Extractable Value — profit extracted by reordering, inserting, or censoring transactions within a block.
Validators and searchers (bots) monitor the mempool and exploit transaction ordering.

**Total MEV extracted on Ethereum**: Billions USD since 2020. It's structural, not a bug.

## Common MEV Types

### Sandwich Attack (Most Relevant for dApps)
User submits DEX swap → attacker buys before (front-run) and sells after (back-run):
```
User's tx: Swap 10 ETH → USDC at $2000/ETH

Attacker:
1. Front-run: Buy 100 ETH at $2000 (moves price to $2050)
2. User's tx: User gets USDC at $2050 (worse rate — the slippage they set)
3. Back-run: Attacker sells 100 ETH at $2050 → profit $50 per ETH
```

### Liquidation MEV
Searchers race to liquidate undercollateralized loans first.
Whoever wins earns the liquidation bonus. High-value, automated.

### Arbitrage MEV
Price discrepancy between DEXes. Searcher buys low on Uniswap, sells high on Curve.
This is generally beneficial — keeps prices in sync.

### Just-In-Time (JIT) Liquidity
Attacker adds massive liquidity to a Uniswap V3 position right before a large swap, earns the fee, removes liquidity immediately after. Legitimate LPs earn less.

## Protection Strategies

### 1. Private Mempools (Best for Large Trades)
```
Public mempool (visible to bots)  →  private submission via RPC
```
- **Flashbots Protect**: `https://rpc.flashbots.net` — transactions go directly to validators, not public mempool
- **MEV Blocker**: Sends to a set of searchers who can only backrun (no front-run/sandwich)
- **Coinbase Protect** (for Base): Similar protection on Coinbase's chain
- **Private RPC**: `eth_sendPrivateTransaction` via Alchemy/Infura

### 2. Slippage Protection (Mandatory in Smart Contracts)
```solidity
function buyShares(bytes32 marketId, uint256 maxCost) external {
    uint256 actualCost = _calculateCost(marketId);
    require(actualCost <= maxCost, "Slippage exceeded");  // ← CRITICAL
    // Execute trade
}
```
Without slippage protection, sandwich attacks always succeed.

### 3. Deadline Parameters
```solidity
function swap(uint256 amountIn, uint256 minOut, uint256 deadline) external {
    require(block.timestamp <= deadline, "Transaction expired");
    // ... swap
}
```
Prevents "stale" transactions sitting in mempool and executing at bad prices later.

### 4. Commit-Reveal (For Information-Sensitive Actions)
Two-phase: commit hash → reveal value. Prevents front-running on the value.
```solidity
// Phase 1: Commit
mapping(address => bytes32) public commitments;

function commit(bytes32 commitment) external {
    commitments[msg.sender] = commitment;
    commitmentBlock[msg.sender] = block.number;
}

// Phase 2: Reveal (separate transaction, at least 1 block later)
function reveal(uint256 value, bytes32 salt) external {
    require(block.number > commitmentBlock[msg.sender], "Same block");
    require(keccak256(abi.encode(value, salt)) == commitments[msg.sender]);
    // Process value — no front-running possible
}
```

### 5. Batch Auctions (CoW Protocol Model)
Aggregate orders over a time window, clear at uniform price.
All orders in a batch pay/receive the same price → sandwiching is impossible.
Used by: CoW Protocol, Gnosis Auction.

### 6. TWAP for Oracle Prices
```solidity
// Never use spot price for critical decisions
// spot price = can be manipulated in one block via flash loan

// Use TWAP (time-weighted average price)
uint32[] memory secondsAgos = [30 minutes, 0];
(int56[] memory tickCumulatives,) = uniPool.observe(secondsAgos);
int24 twapTick = int24((tickCumulatives[1] - tickCumulatives[0]) / 1800);
uint256 twapPrice = TickMath.getSqrtRatioAtTick(twapTick);
```

## Prediction Markets & MEV

### Key Risks
1. **Resolution front-running**: Someone learns the market outcome before oracle reports, buys winning shares
2. **Order book manipulation**: Large orders to move prices, then profit on correlated markets
3. **Operator MEV**: CLOB operator sees all orders, could insert their own advantageously

### Mitigations
- **Private oracle submission**: Oracle reports via Flashbots, not public mempool
- **Commitment scheme on resolution**: Oracle commits to result hash, reveals after block confirmation
- **CLOB operator cannot move funds**: Off-chain matching, on-chain settlement with signed orders — operator can reorder but can't steal
- **Rate limiting**: Limit position size changes near resolution time

## MEV on L2s
- **Sequencer MEV**: On Arbitrum/Optimism, the sequencer orders transactions. Single entity = centralized ordering.
- **Base/Coinbase**: Coinbase runs the sequencer — less MEV than public Ethereum but still exists
- **MEV on L2 is growing**: As L2 TVL grows, MEV opportunity grows
- **Flashbots SUAVE**: Future decentralized block building across chains (watch this space)
