# Quantum-Resistant Blockchain

## The Threat Model

```
Shor's algorithm (quantum):
  Breaks: ECDSA (secp256k1 — used by Bitcoin/Ethereum), RSA, Diffie-Hellman
  Timeline: 4000+ stable qubits needed for Bitcoin; current best ~1000 unstable qubits
  Realistic threat: 10-20 years, but uncertainty is high

Grover's algorithm (quantum):
  Weakens: hash functions — SHA-256 becomes effectively 128-bit (still secure)
  Impact: low. Bitcoin/Ethereum hashes remain safe with current parameters.

Who is at risk today:
  - Addresses that have SENT a transaction: their public key is revealed → quantum can derive private key
  - Addresses that have only RECEIVED: public key not revealed → safe (only hash of pubkey known)
  - "Exposed" coins: Satoshi's early coins, exchange hot wallets, any address with transaction history

Why this matters for builders:
  - New protocols should plan for PQC migration paths
  - Don't design systems that are impossible to upgrade cryptography on
  - The 10-year horizon is long but not infinite
```

## NIST Post-Quantum Standards (Finalized August 2024)

```
ML-DSA (CRYSTALS-Dilithium) — PRIMARY SIGNATURE STANDARD
  - Lattice-based (Learning With Errors problem)
  - Security: quantum-resistant Level 2/3/5 options
  - Signature size: ~2.4KB (vs 64 bytes for ECDSA)
  - Verification: fast
  - Likely Ethereum's migration target

SLH-DSA (SPHINCS+) — CONSERVATIVE OPTION
  - Hash-based: security relies ONLY on hash function security
  - Most conservative: no algebraic structure to attack
  - Larger signatures: ~8-50KB
  - Slower: but ultra-secure
  - Best for: highest-value keys where signature size doesn't matter

ML-KEM (CRYSTALS-Kyber) — KEY ENCAPSULATION
  - For encrypted communication (not signatures)
  - Replaces ECDH for key exchange
```

## Hybrid Signature Scheme

```solidity
// Sign with BOTH ECDSA and post-quantum simultaneously
// If quantum eventually breaks ECDSA, PQ signature still valid
// This is the migration strategy recommended by security researchers

contract HybridSignatureVerifier {
    // Classical: secp256k1 ECDSA
    function verifyECDSA(
        bytes32 hash,
        bytes32 r, bytes32 s, uint8 v,
        address expectedSigner
    ) internal pure returns (bool) {
        return ecrecover(hash, v, r, s) == expectedSigner;
    }

    // Post-quantum: Dilithium (requires precompile or library)
    // Currently: no EVM precompile for Dilithium (would cost 5-50M gas)
    // Near-future: EIP for PQ signature precompile expected

    // Today's practical approach: off-chain PQ verification with on-chain hash commitment
    // 1. User signs with both ECDSA and Dilithium off-chain
    // 2. Store commitment hash(dilithiumPubKey + ecdsaPubKey) on-chain
    // 3. In quantum era: present Dilithium signature to prove ownership

    struct HybridKey {
        address ecdsaAddress;
        bytes32 dilithiumPubKeyHash;  // Hash of 1312-byte Dilithium public key
        bool quantumMigrated;
    }

    mapping(address => HybridKey) public hybridKeys;

    // Register a future-proof key pair
    function registerHybridKey(bytes32 dilithiumPubKeyHash) external {
        hybridKeys[msg.sender] = HybridKey({
            ecdsaAddress:       msg.sender,
            dilithiumPubKeyHash: dilithiumPubKeyHash,
            quantumMigrated:    false
        });
    }

    // In quantum era: prove ownership via Dilithium
    function migrateToQuantumSafe(
        address oldAddress,
        bytes calldata dilithiumPublicKey,
        bytes calldata dilithiumSignature
    ) external {
        HybridKey storage key = hybridKeys[oldAddress];
        require(keccak256(dilithiumPublicKey) == key.dilithiumPubKeyHash, "Key mismatch");
        require(_verifyDilithium(dilithiumPublicKey, dilithiumSignature, abi.encodePacked(oldAddress)));
        key.quantumMigrated = true;
        // Transfer all assets to new quantum-safe address
    }
}
```

## STARKs vs SNARKs — Quantum Context

```
STARKs (like StarkNet uses):
  ✅ Quantum-resistant: security relies only on hash functions (collision resistance)
  ✅ No trusted setup
  ❌ Larger proof sizes (~100KB vs ~250 bytes for SNARK)

SNARKs (like Groth16, used by many ZK rollups):
  ❌ NOT quantum-resistant: rely on elliptic curve pairings (broken by quantum)
  ❌ Require trusted setup ceremony
  ✅ Tiny proofs, fast verification

Implication:
  - StarkNet has a structural quantum-resistance advantage
  - Protocols using SNARKs (many ZK EVMs) will need to migrate to STARK-based proving systems
  - zkSync (uses SNARK) = quantum vulnerability; StarkNet = quantum safe
  - Timeline: this matters in 10-20 years, not today
```

## Builder Action Plan

```
Now (2026):
  □ Design contracts with upgradeable signature verification
  □ Use UUPS proxies where possible (can upgrade verification logic)
  □ Document which cryptographic assumptions your contract relies on
  □ If storing keys on-chain: store HASHES (quantum-safe) not raw public keys

Near future (2027-2030):
  □ Watch for EIP adding Dilithium/ML-DSA precompile to EVM
  □ Test hybrid signature schemes as they become available
  □ Plan migration path for high-value contracts

When EVM adds PQ precompile:
  □ Deploy migration contract
  □ Allow users to register PQ keys alongside ECDSA keys
  □ Communicate migration clearly to users before quantum threat is real
```
