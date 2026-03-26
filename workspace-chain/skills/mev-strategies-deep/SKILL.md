# MEV Strategies Deep

## Every Strategy — Know the Attacker

### Sandwich Attack (Most Common)

```
1. Attacker sees victim's large swap (USDC → ETH, slippage 1%) in mempool
2. Attacker frontruns: buys ETH before victim → price moves up
3. Victim's swap executes at worse price (within their 1% slippage tolerance)
4. Attacker backrins: sells ETH at the elevated price → profit

Profit formula:
  P = (price_after_victim - price_before_frontrun) × attacker_amount - gas
  Attacker must buy exactly enough to push price UP to victim's slippage limit
  Buying more = victim's tx reverts (price exceeded slippage) = attack fails

Defense:
  - Lower slippage tolerance (but: tx reverts more on volatile tokens)
  - Use private mempool (Flashbots Protect, MEV Blocker)
  - Commit-reveal scheme
  - Batch auction (CoW Protocol)
```

### Time-Bandit Attack

```
Scenario: Block N has a high-value MEV opportunity (e.g., $10M arbitrage)
A validator with enough stake could theoretically:
  1. Mine Block N normally (capturing $1M regular MEV)
  2. OR: secretly mine a fork of Block N-1, stealing the $10M from a different txo

Defense:
  - Final finality: Ethereum's proof-of-stake has checkpoints every 64 blocks
    After checkpoint: reorg is economically impossible (would require 1/3 of all staked ETH)
  - For high-value operations: wait for checkpoint finality (12-15 minutes)
  - L2 protocols: inherit L1 finality once data is posted

Current risk assessment: LOW on Ethereum post-Merge due to finality gadget
```

### Cross-Domain MEV

```
Arbitrage between L1 and L2:
  - Price on Base (L2): ETH = $3000
  - Price on Ethereum (L1): ETH = $3010
  - Attacker: buy cheap on Base, bridge to L1, sell on L1
  - Time limit: bridge delay limits profitability (hours for Optimistic rollups)
  - Fast bridges (Across, Hop) enable near-real-time cross-chain arb

Bridge MEV:
  - User initiates large bridge withdrawal
  - Attacker front-runs the destination chain: buys the asset before the bridge delivers it
  - When bridge delivers: price already moved → attacker sells into the user's liquidity
  - Defense: private relaying of bridge completion transactions
```

### JIT (Just-In-Time) Liquidity

```
This is MEV that's beneficial (or at least neutral) to regular traders:
  1. Attacker watches for large Uniswap V3 swap
  2. Adds concentrated liquidity in exactly the right tick range BEFORE the swap
  3. Earns the full swap fee (vs. spreading it across all LPs)
  4. Removes liquidity immediately after

Impact on protocol:
  + Trader gets better execution (more liquidity = less slippage)
  - Regular LPs earn less fees (JIT LP steals the fee)
  + Protocol gets more total fee revenue (deeper liquidity = higher volume)

How to prevent: minimum LP duration (Uniswap V4 hook can enforce minimum hold time)
```

## MEV-Resistant Design Patterns

### 1. Batch Auction (CoW Protocol)

```
All orders in a batch execute at the SAME clearing price.
No advantage to being first in the batch.
Surplus (better than limit price) redistributed to traders.

For Agent Sparta:
  - Entry fee acceptance: all entries received in the same block pay the same price
  - No "rush to enter" advantage — batch all entries, close the batch at deadline
```

### 2. MEV Tax (Dan Robinson Proposal)

```solidity
// Contracts charge a fee proportional to priority gas price
// Makes sandwich attacks unprofitable because the extra gas fee goes to the protocol

contract MEVTax {
    uint256 public constant MEV_TAX_BPS = 5000; // 50% of priority fee as tax

    function trade(uint256 amount) external {
        // MEV tax: proportional to how much extra gas attacker is paying
        uint256 priorityFee = tx.gasprice - block.basefee;
        uint256 mevTax = priorityFee * MEV_TAX_BPS / 10_000 * gasleft();

        // Require attacker to pay MEV tax to protocol
        require(msg.value >= mevTax, "Insufficient MEV tax");

        _executeTrade(amount);
    }
}
// Effect: if attacker pays 10 Gwei priority fee to frontrun → protocol collects ~50% of that
// Sandwich becomes much less profitable → attackers stop doing it
```

### 3. Commit-Reveal for Agent Sparta Entries

```solidity
// Two-phase entry: commit hash → reveal actual content
// MEV bot sees the commitment but can't extract actionable information

contract CommitRevealEntry {
    mapping(address => bytes32) public commitments;
    mapping(address => bool) public revealed;

    // Phase 1: submit hash (no information leaked)
    function commit(bytes32 commitmentHash) external payable {
        require(msg.value >= ENTRY_FEE, "Fee required");
        commitments[msg.sender] = commitmentHash;
    }

    // Phase 2: reveal actual content (after commit phase ends)
    function reveal(string calldata submission, bytes32 salt) external {
        require(keccak256(abi.encode(submission, salt)) == commitments[msg.sender]);
        revealed[msg.sender] = true;
        entries[msg.sender] = submission;
    }
}
```

### 4. Private Mempool

```typescript
// Submit transactions to Flashbots MEV Protect — not visible to MEV bots
import { FlashbotsBundleProvider } from "@flashbots/ethers-provider-bundle";

const flashbots = await FlashbotsBundleProvider.create(
    provider,
    signer,
    "https://relay.flashbots.net"
);

// Transactions submitted here are private until included in a block
const bundle = [{ transaction: entryFeeTx, signer }];
const response = await flashbots.sendBundle(bundle, targetBlock);
// MEV bots can't see this transaction until it's already mined
```
