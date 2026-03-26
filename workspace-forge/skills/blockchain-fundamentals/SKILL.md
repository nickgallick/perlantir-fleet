---
name: blockchain-fundamentals
description: How blockchain actually works — consensus, EVM, gas, transactions, smart contracts, token standards, L1 vs L2. The engineering, not the hype.
---

# Blockchain Fundamentals

## Core Concepts

### How It Works
A blockchain is an **append-only linked list of blocks**. Each block contains a hash of the previous block. Changing any past block invalidates all subsequent hashes — this is immutability.

### Consensus
| Mechanism | How | Used By | Trade-off |
|-----------|-----|---------|-----------|
| Proof of Work | Miners solve puzzles | Bitcoin | Secure but energy-intensive |
| Proof of Stake | Validators stake tokens, slashed if dishonest | Ethereum | Efficient, ~99.95% less energy |
| Proof of Authority | Trusted validators | Private chains | Fast but centralized |

### Key Numbers
| Metric | Ethereum L1 | Base (L2) | Bitcoin |
|--------|------------|-----------|---------|
| Block time | ~12s | ~2s | ~10min |
| TPS | ~15 | ~1000 | ~7 |
| Finality | ~12min | ~minutes | ~60min |
| Gas cost | $$$  | $ | N/A |

## The EVM (Ethereum Virtual Machine)

- Stack-based VM executing smart contract bytecode
- Every node runs the same computation → deterministic consensus
- **Storage is EXPENSIVE:** writing 32 bytes costs ~20,000 gas (~$0.50-$50)
- **Memory is cheap.** Design accordingly: compute at read time, store minimally
- **No floating point.** All math is integer. Use fixed-point (amounts in wei, not ETH)

## Key Concepts for Developers

```
Wallet:       public/private key pair. Address = identity. Private key = NEVER expose.
Transaction:  signed message. Contains: to, value, data, gas limit, gas price.
Smart Contract: code at a blockchain address. Immutable once deployed.
ABI:          JSON describing contract functions/events. The "API spec."
Events/Logs:  cheap data emission (vs storage). Frontends listen to these.
```

## Token Standards

| Standard | Type | Use Case |
|----------|------|----------|
| **ERC-20** | Fungible tokens | Arena Coins (interchangeable units) |
| **ERC-721** | NFTs | Badges, trophies (each unique) |
| **ERC-1155** | Multi-token | Batch of different items (mixed badges) |

## L1 vs L2

| Layer | Examples | Cost | Speed | Security |
|-------|----------|------|-------|----------|
| L1 | Ethereum mainnet | $$$ | Slow | Maximum |
| L2 Optimistic | Optimism, Base, Arbitrum | $ | Fast | Ethereum (fraud proofs) |
| L2 ZK | zkSync, Starknet, Polygon zkEVM | $ | Fast | Ethereum (validity proofs) |

**For new projects: ALWAYS build on L2.** Base (by Coinbase) is the current default — low fees, high throughput, Ethereum security.

**Optimistic vs ZK rollups:**
- Optimistic: assume valid, fraud proofs if challenged. 7-day withdrawal delay. Easier to build.
- ZK: cryptographic proof of validity. No delay. Harder to build. Better long-term scaling.

## What Goes On-Chain vs Off-Chain

| On-Chain (expensive, permanent, verifiable) | Off-Chain (cheap, fast, mutable) |
|---------------------------------------------|-----------------------------------|
| Token balances (Arena Coins) | User profiles |
| Badge ownership (NFTs) | Challenge descriptions |
| Challenge results (hash) | Full transcripts |
| ELO snapshots (end of season) | Real-time leaderboards |
| Reputation scores | Session data |

**Rule:** Store the minimum needed for verification on-chain. Everything else stays in Supabase.

## Sources
- ethereum/solidity documentation
- OpenZeppelin/openzeppelin-contracts
- Ethereum.org developer documentation
- Vitalik Buterin's "Endgame" L2 vision

## Changelog
- 2026-03-21: Initial skill — blockchain fundamentals
