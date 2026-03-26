# Rollup Architecture

## Optimistic Rollup Internals

### Component Stack
```
User → Sequencer (accepts txs, orders them, executes, produces batches)
         ↓
      Batcher (compresses + submits batches to L1 as calldata/blobs)
         ↓
      L1 Inbox Contract (stores batch data permanently)
         ↓
      Proposer (submits claimed state root after executing batch)
         ↓
      7-day fraud proof window
         ↓
      Challenger (submits fraud proof if state root is wrong)
         ↓
      Dispute Game (bisection protocol → single instruction → execute on L1)
```

### Fraud Proof (Bisection Protocol)
The core of optimistic rollup security:
```
Proposer claims: "After executing 1,000,000 instructions, state root = X"
Challenger says: "Wrong — I compute state root = Y"

Bisection game:
1. Split into two halves: which half do they disagree on?
   - Proposer: "After 500,000 instructions: state root = A"
   - Challenger: "I agree with A"
   → Disagreement is in second half (500,001 - 1,000,000)

2. Bisect again: which quarter?
   → Continue until narrowed to ONE instruction

3. Execute that single instruction on L1
   → L1 is the ultimate arbiter of who's right
   → Loser's bond is slashed, winner gets the bond

Total bisection rounds: log₂(1,000,000) ≈ 20 rounds
```

### Force Inclusion (Anti-Censorship)
```
If sequencer censors your tx:
1. Submit tx directly to L1 Inbox contract
2. Wait timeoutPeriod (e.g., 24 hours)
3. If sequencer hasn't included it → it's automatically force-included
4. Sequencer CANNOT censor indefinitely while remaining honest

This is the critical safety property of rollups:
Even if sequencer is malicious, you can always get your tx executed.
```

## ZK Rollup Internals

### Proof Generation Pipeline
```
User transactions
      ↓
Sequencer batches them
      ↓
Prover generates validity proof
      ↓
Verifier contract on L1 verifies proof
      ↓
State root accepted immediately (no fraud window)
```

### Proof Types
```
SNARK (Groth16, PLONK):
  - Proof size: ~200 bytes (tiny)
  - Verification gas: ~200K gas (cheap)
  - Trusted setup required
  - Not post-quantum secure
  - Used by: zkSync Era, Polygon zkEVM, Scroll

STARK:
  - Proof size: ~50-500KB (larger)
  - Verification gas: ~1-5M gas (expensive)
  - No trusted setup
  - Post-quantum secure
  - Used by: StarkNet, StarkEx (dYdX V3, Immutable X)

KZG (polynomial commitments):
  - Used in: EIP-4844 blobs, various ZK schemes
  - Powers proto-danksharding
```

## Data Availability

Where rollup transaction data is stored:

```
Option 1: Ethereum Calldata (pre-Dencun)
  Cost: ~16 gas per byte
  1000 txs ≈ 300KB ≈ $50-200 per batch
  Security: maximum (L1 guarantees availability)

Option 2: Ethereum Blobs (EIP-4844, post-Dencun)
  Cost: ~0.0001 gwei per byte (100x cheaper)
  1000 txs ≈ $0.50-2 per batch
  Availability: ~18 days (then pruned from full nodes)
  Security: still high (light clients verify blob headers)

Option 3: Celestia / EigenDA / Avail
  Cost: even cheaper
  Availability: depends on DA layer security
  Security: trust assumption on DA layer validators
  Trade-off: cheaper but less secure than Ethereum DA
```

## Building Your Own Rollup

### OP Stack (Optimism)
```bash
# Clone OP Stack
git clone https://github.com/ethereum-optimism/optimism

# Configure your chain
cat > config.yaml << EOF
l1_rpc_url: "https://eth-mainnet.g.alchemy.com/v2/KEY"
l2_chain_id: 42069
block_time: 2  # seconds
gas_limit: 30000000
fee_recipient: "0xYourAddress"
EOF

# Deploy L1 contracts
forge script scripts/Deploy.s.sol \
    --rpc-url $L1_RPC \
    --broadcast

# Run sequencer, batcher, proposer
docker-compose up
```

Customizations available:
- **Gas token**: Use any ERC-20 as gas (not just ETH)
- **Block time**: Down to 2 seconds
- **Custom precompiles**: Add new opcodes for your use case
- **Sequencer**: Replace with your own ordering logic
- **DA layer**: Swap Ethereum blobs for Celestia/EigenDA

### Arbitrum Orbit
For L3s (settling to Arbitrum) or L2s (settling to Ethereum):
```bash
# Uses Arbitrum's BOLD fraud proof protocol
# Faster finality than standard optimistic (1 week → minutes in some configs)
```

### ZK Stack (zkSync)
For ZK rollup chains:
```bash
# Hyperchains: multiple ZK chains sharing one verification circuit
# Native account abstraction on every chain
# Same security model as zkSync Era
```

## When to Build Your Own Rollup

**Build if**:
- Need custom transaction ordering (prediction markets, order books)
- Need free transactions for certain operations (onboarding subsidy)
- Need custom precompiles (specialized crypto operations)
- >$10M/year revenue justifies $500K+/year infrastructure cost
- Need sovereign governance over the execution environment

**Don't build if**:
- MVP or early stage — too expensive, too complex
- Can achieve your UX on existing L2 with smart contracts
- Your transaction volume doesn't justify the overhead
- Team lacks blockchain infrastructure expertise

**Rule of thumb**: 10M+ transactions/month starts to justify app-chain economics.
