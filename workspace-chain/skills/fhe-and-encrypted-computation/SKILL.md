# FHE & Encrypted Computation

## What Fully Homomorphic Encryption Enables

Normal encryption: you must decrypt data to compute on it → data exposed during computation.

FHE: compute DIRECTLY on encrypted data → data never exposed.

```
Normal: Encrypt(5) + Encrypt(3) = ??? (must decrypt first → expose data)
FHE:    Encrypt(5) + Encrypt(3) = Encrypt(8) (sum computed without seeing 5 or 3)
```

## fhEVM (Zama) — FHE on EVM

Zama's fhEVM adds encrypted data types to the EVM:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "fhevm/lib/TFHE.sol";

contract SealedAuction {
    // Encrypted bid amounts — only bidder can see their own bid
    mapping(address => euint64) internal _bids;
    euint64 internal _highestBid;
    address internal _winner;

    // User submits encrypted bid
    function bid(bytes calldata encryptedBid) external {
        euint64 amount = TFHE.asEuint64(encryptedBid);

        // Validate: bid > 0 (works on encrypted value!)
        ebool isPositive = TFHE.gt(amount, TFHE.asEuint64(0));
        TFHE.optReq(isPositive);

        // Store encrypted bid
        _bids[msg.sender] = amount;

        // Update highest bid (comparison on encrypted values)
        ebool isHigher = TFHE.gt(amount, _highestBid);
        _highestBid = TFHE.cmux(isHigher, amount, _highestBid);
        // cmux: if isHigher then amount else _highestBid
        // The contract knows WHICH is higher but not the actual values!
    }

    // Reveal winner after auction ends
    // Requires threshold decryption (multiple key holders cooperate)
    function revealWinner() external onlyOwner {
        // Winner is whoever submitted the highest bid
        // Determination: compare each bid against _highestBid
        // Can only reveal the winner, not the losing bids
    }
}
```

## Supported Operations

```solidity
// Encrypted integer types
euint8, euint16, euint32, euint64

// Comparisons (return ebool)
TFHE.eq(a, b)   // a == b
TFHE.ne(a, b)   // a != b
TFHE.lt(a, b)   // a < b
TFHE.gt(a, b)   // a > b
TFHE.le(a, b)   // a <= b
TFHE.ge(a, b)   // a >= b

// Arithmetic
TFHE.add(a, b)
TFHE.sub(a, b)
TFHE.mul(a, b)  // VERY expensive — FHE multiplication is costly

// Conditional (encrypted if/else)
TFHE.cmux(condition, ifTrue, ifFalse)

// Boolean operations
TFHE.and(a, b)
TFHE.or(a, b)
TFHE.not(a)
```

## Performance Reality Check (2026)

| Operation | FHE Gas Cost | Standard Gas Cost | Ratio |
|-----------|-------------|------------------|-------|
| Addition (euint32) | ~200K gas | 3 gas | 66,000x |
| Comparison (lt) | ~500K gas | 3 gas | 166,000x |
| Multiplication | ~2M gas | 5 gas | 400,000x |
| Storage (euint64) | ~500K gas | 20,000 gas | 25x |

**Current verdict**: FHE is 1,000-400,000x more expensive than normal computation. Viable only for:
- Low-frequency operations where privacy value > massive gas cost
- Specific narrow use cases (sealed auctions, private voting)
- Chains with very low gas costs (planned zkTFHE with proof amortization)

**3-5 year outlook**: Hardware acceleration + proof systems will reduce costs by 100-1000x. Watch this space.

## Practical FHE Use Cases (Today)

### 1. Sealed Bid Auctions (Most Practical Now)
```solidity
// Small number of bids (≤100), each bid requires:
// ~500K gas for comparison = $0.10 on Base
// For 100 bids: $10 total to determine winner
// This is economically viable if NFT/asset is worth >$1K
```

### 2. Private Voting
```solidity
// DAO votes where you don't want vote buying (can't prove how you voted)
// 1000 voters × 200K gas/vote = 200M gas = ~$40 on Base
// Economically viable for high-stakes governance
```

### 3. Agent Sparta Sealed Scoring
```solidity
// FHE allows: judge scores submissions in encrypted form
// Ranking determined without revealing individual scores
// Only winner revealed — losing scores stay private
// Cost: ~10 submissions × 500K gas = 5M gas = ~$1 on Base — VIABLE
```

## Threshold Decryption

FHE ciphertexts can only be decrypted by combining N-of-M private key shards:

```
Key generation: Single FHE public key, private key split into 5 shards
              (held by 5 independent parties — no single party can decrypt)

Decryption: At least 3 parties must cooperate to decrypt any value
            This prevents the smart contract owner from seeing user data
```

For Agent Sparta: The FHE decryption key could be split between:
1. Perlantir
2. An independent auditor
3. The winning AI agent itself

This means Perlantir CANNOT unilaterally see losing bids/scores — a strong trust property.
