# Sequencer & Block Building

## The Sequencer's Role and Power

The sequencer is the most powerful entity in any rollup — it sees all transactions before execution and controls ordering.

```
Sequencer powers:
1. Transaction ordering — first in, first executed (within a block)
2. Transaction exclusion — can delay or exclude transactions (censorship)
3. MEV extraction — can insert its own transactions at favorable positions
4. Latency advantage — knows what's in the next block before everyone else

Constraints (on honest sequencer):
1. Force inclusion — after timeout, L1 force-includes censored txs
2. State root validity — committed state roots must be correct
3. Data availability — all tx data must be posted to L1
```

## Sequencer Architectures

### Centralized (Current Standard: Base, Optimism, Arbitrum)
```
One entity runs the sequencer
  + Fast (sub-second confirmations)
  + Simple (no consensus needed)
  - Single point of failure
  - Can be censored by regulator
  - MEV captured by sequencer operator
```

### Decentralized Sequencing (Future)
```
Multiple sequencers rotate or share duties
  + No single point of failure
  + Censorship resistant
  - Higher latency (need some consensus)
  - More complex
  
Projects: Espresso Systems, Astria, Radius
```

### Based Sequencing (Ethereum Validators as Sequencer)
```
L2 blocks are proposed by Ethereum L1 validators
  + Maximum decentralization (inherits Ethereum validator set)
  + No separate sequencer to trust
  - Higher latency (tied to L1 block time ~12 seconds)
  - Less MEV optimization
  
Projects: Taiko, some future OP Stack configurations
```

## Flashbots MEV-Boost (PBS — Proposer-Builder Separation)

```
Traditional: Validator builds block themselves
  → Validator can extract MEV by reordering transactions

PBS: Validator proposes, specialized Builder constructs the block
  1. Builders receive transactions (public mempool + private order flow)
  2. Builders construct optimally ordered blocks (maximizing MEV)
  3. Builders bid for the right to have their block proposed
  4. Validator picks highest bid (earns MEV revenue without technical work)
  5. Validator proposes block — validator CANNOT see contents before committing

MEV-Boost relay: Trusted intermediary that:
  - Receives blocks from builders
  - Reveals block contents to validator only AFTER they commit to the block header
  - Prevents validator from stealing the builder's MEV strategy
```

```go
// Simplified block submission flow (from Flashbots relay)
type BuilderSubmission struct {
    Slot           uint64
    ParentHash     common.Hash
    Value          *big.Int       // MEV + fees paid to validator
    Payload        ExecutionPayload // The actual block
    BuilderPubkey  [48]byte
    Signature      [96]byte
}
```

## Block Value Optimization (Builder Logic)

```python
class BlockBuilder:
    def build_optimal_block(self, pending_txs: list, bundles: list) -> Block:
        """
        Maximize: Σ(MEV_i) + Σ(priority_fee_i) subject to gas limit
        """
        # 1. Identify arbitrage opportunities
        arb_txs = self.find_arbitrage(pending_txs)

        # 2. Order transactions to extract maximum MEV
        # Back-running (non-harmful): insert arb after large trade
        # Sandwich (harmful to user): insert buy before + sell after

        # 3. Include Flashbots bundles (pre-built atomic MEV strategies)
        bundle_profits = [(b, self.simulate_bundle(b)) for b in bundles]
        profitable_bundles = [(b, p) for b, p in bundle_profits if p > b.min_gas_price * b.gas]

        # 4. Fill remaining gas with highest priority fee transactions
        regular_txs = sorted(pending_txs, key=lambda tx: tx.effective_gas_price, reverse=True)

        # 5. Combine for maximum total value
        return self.assemble_block(profitable_bundles + regular_txs)
```

## SUAVE: The Future of MEV Infrastructure

```
SUAVE = Single Unified Auction for Value Expression

Problem: Current MEV flows are:
  - Fragmented (different auction for each chain)
  - Opaque (bidders don't know how bids are evaluated)
  - Wasteful (lots of compute for redundant simulations)

SUAVE solution: a dedicated blockchain for MEV auctions
  - Users submit "preferences" (encrypted intents)
  - Solvers bid to fill preferences
  - SUAVE's TEE (Trusted Execution Environment) evaluates bids fairly
  - Winning solver's block template submitted to target chain
  - Users get MEV rebates

For Agent Sparta: SUAVE's "preferences" model is similar to intent-based architecture.
Users say "I want to enter this challenge" → solvers find optimal execution path.
```

## Custom Sequencer for Agent Sparta

If building a dedicated app-chain for Sparta challenges:

```go
// Custom mempool ordering: challenges ordered by entry fee (higher stakes first)
// This is fair and actually improves experience (big prize challenges get priority)

type SpartaSequencer struct {
    challenges map[common.Hash]*Challenge
    pendingTxs []*SpartaTx
}

func (s *SpartaSequencer) selectTransactions() []*SpartaTx {
    // Sort by: challenge prize pool size (larger prize → higher priority)
    sort.Slice(s.pendingTxs, func(i, j int) bool {
        prizeI := s.challenges[s.pendingTxs[i].ChallengeId].PrizePool
        prizeJ := s.challenges[s.pendingTxs[j].ChallengeId].PrizePool
        return prizeI > prizeJ
    })
    return s.pendingTxs[:maxTxsPerBlock]
}
```
