# Mempool & Transaction Engineering

## Transaction Lifecycle (Deep)

```
1. User constructs tx: {to, value, data, gasLimit, maxFeePerGas, maxPriorityFeePerGas, nonce, chainId}
2. Sign with ECDSA → {v, r, s}
3. RLP encode → raw transaction bytes
4. Submit via eth_sendRawTransaction → enters node's txpool
5. Gossip: node propagates to peers → public mempool visibility
6. Block builder: selects txs ordered by priority fee (MEV considerations)
7. Validator proposes block containing builder's bundle
8. Block finalized → tx executed → state changes applied → receipt generated
```

## EIP-1559 Fee Market (Mastery Level)

```
baseFee: Set by protocol, burned. Adjusts ±12.5% per block based on utilization.
  - Block > 50% full → baseFee increases next block
  - Block < 50% full → baseFee decreases
  - Max change: 12.5% per block (prevents fee spikes)

priorityFee (tip): Goes to validator. Pure auction for priority.
maxFeePerGas: Ceiling you'll pay. actualFee = min(maxFee, baseFee + priorityFee)

effectiveGasPrice = min(maxFeePerGas, baseFee + maxPriorityFeePerGas)
totalCost = gasUsed × effectiveGasPrice
burnedAmount = gasUsed × baseFee
validatorTip = gasUsed × (effectiveGasPrice - baseFee)
```

### Fee Estimation Strategies
```typescript
// Conservative (for time-sensitive txs)
const block = await provider.getBlock('latest')
const baseFee = block.baseFeePerGas
const maxFeePerGas = baseFee * 2n + parseGwei('2')  // 2x buffer + tip
const maxPriorityFeePerGas = parseGwei('2')

// Aggressive (for MEV or urgent txs)
const maxFeePerGas = baseFee * 3n + parseGwei('50')
const maxPriorityFeePerGas = parseGwei('50')

// Economy (can wait)
const maxFeePerGas = baseFee + parseGwei('0.1')
const maxPriorityFeePerGas = parseGwei('0.1')
```

## Nonce Management

### The Problem
Nonces must be sequential with no gaps. If tx with nonce 5 is pending and you submit nonce 7, nonce 7 is stuck until 5 confirms.

### Production Nonce Manager
```typescript
class NonceManager {
  private localNonce: number
  private pending: Map<number, string> = new Map()

  async getNextNonce(): Promise<number> {
    // Start from on-chain nonce
    const onChainNonce = await provider.getTransactionCount(address, 'pending')
    // Use the higher of on-chain pending or local tracking
    this.localNonce = Math.max(this.localNonce ?? 0, onChainNonce)
    return this.localNonce++
  }

  // Speed up: resubmit same nonce with higher gas
  async speedUp(nonce: number, newMaxFee: bigint) {
    // Same nonce, same data, higher gas → replaces pending tx
  }

  // Cancel: send 0 ETH to self with same nonce and higher gas
  async cancel(nonce: number) {
    return wallet.sendTransaction({
      to: address, value: 0, nonce, maxFeePerGas: highFee
    })
  }
}
```

## EIP-2930 Access Lists
Pre-declare storage slots you'll access → cheaper cold reads.

```typescript
// Generate access list
const accessList = await provider.send('eth_createAccessList', [{
  from: sender,
  to: contractAddress,
  data: encodedCalldata,
}])

// Include in transaction
const tx = {
  type: 1,  // EIP-2930 transaction type
  accessList: accessList.accessList,
  // ... other fields
}
```

Saves 100 gas per pre-declared cold storage slot (2100 → 2000).

## EIP-4844 Blob Transactions
```typescript
// Type 3 transaction with blob data
const tx = {
  type: 3,
  to: blobStorageContract,
  maxFeePerBlobGas: parseGwei('1'),
  blobVersionedHashes: [hash1, hash2],
  blobs: [blob1, blob2],
  // ... standard EIP-1559 fields
}
```

Used by L2 sequencers to post data cheaply. Each blob = ~128KB, temporary (pruned after ~18 days).

## Private Transaction Submission

### Flashbots Protect
```typescript
import { FlashbotsBundleProvider } from '@flashbots/ethers-provider-bundle'

const flashbotsProvider = await FlashbotsBundleProvider.create(
  provider,
  authSigner,
  'https://relay.flashbots.net'
)

// Submit private transaction
const signedTx = await wallet.signTransaction(tx)
const result = await flashbotsProvider.sendPrivateTransaction({
  transaction: { signedTransaction: signedTx },
  maxBlockNumber: currentBlock + 5
})
```

### MEV-Share (User Captures MEV)
```typescript
// User submits to MEV-Share → searchers bid to backrun
// User captures portion of MEV their tx creates
const mevShareProvider = new MevShareClient('https://mev-share.flashbots.net')
await mevShareProvider.sendTransaction(signedTx, {
  hints: ['calldata', 'logs'],  // What searchers can see
  maxBlockNumber: currentBlock + 25
})
```

## Searcher Architecture (Know Thy Enemy)

### Sandwich Bot Flow
```
1. Monitor mempool via WebSocket: pending_transactions
2. Decode calldata: is this a DEX swap? What token? What amount?
3. Simulate: what's the price impact of this swap?
4. Calculate: front-run profit minus gas costs
5. If profitable:
   a. Construct front-run tx: buy same token, push price up
   b. Bundle: [front-run, victim_tx, back-run]
   c. Submit bundle to Flashbots/builder
   d. back-run tx: sell token at inflated price
6. Profit = price_difference × victim_amount - gas_costs
```

### Liquidation Bot Flow
```
1. Index all lending protocol positions (health factors)
2. Monitor: when health factor approaches 1.0
3. When HF < 1.0:
   a. Flash loan the repayment amount
   b. Call liquidate() on the lending protocol
   c. Receive collateral + liquidation bonus
   d. Swap collateral → repay flash loan
   e. Profit = liquidation bonus - gas - flash loan fee
```

### Arbitrage Bot Flow
```
1. Monitor prices across DEXes (Uniswap, Curve, Balancer, etc.)
2. Graph search: find profitable path A→B→C→A where output > input
3. Flash loan initial capital
4. Execute atomic swap sequence
5. Repay flash loan + fee
6. Profit = output - input - gas - flash loan fee
```

## Defense Checklist for Protocol Developers
- [ ] All swaps have `minAmountOut` / `maxAmountIn` (slippage protection)
- [ ] All time-sensitive txs have `deadline` parameter
- [ ] Oracle prices use TWAP, not spot
- [ ] Large operations use commit-reveal
- [ ] Frontend suggests private submission for large trades
- [ ] Circuit breakers pause on extreme price movements
- [ ] Resolution/oracle updates submitted via Flashbots
