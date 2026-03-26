# Advanced Cryptography for Blockchain

## Elliptic Curve Cryptography (secp256k1)

### The Math
- Curve: y² = x³ + 7 over a prime field Fp where p = 2²⁵⁶ - 2³² - 977
- Generator point G is known, order n = number of points on curve
- Private key: random 256-bit integer k ∈ [1, n-1]
- Public key: K = k × G (scalar multiplication — computationally easy forward, infeasible to reverse)
- Address: last 20 bytes of keccak256(publicKey)

### ECDSA Signing
```
Input: message hash z, private key k
1. Pick random nonce r ∈ [1, n-1]
2. Compute point R = r × G
3. r_component = R.x mod n
4. s_component = r⁻¹ × (z + r_component × k) mod n
5. Signature = (r_component, s_component, v)
   v = recovery id (27 or 28) — which of 2 possible public keys
```

### ecrecover in Solidity
```solidity
// Returns ADDRESS, not public key
// ecrecover(hash, v, r, s) → address
// If signature is invalid, returns address(0) — ALWAYS check != address(0)

function verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s, address expected) internal pure returns (bool) {
    address recovered = ecrecover(hash, v, r, s);
    require(recovered != address(0), "Invalid signature");
    return recovered == expected;
}
```

### Signature Malleability
For any valid signature (r, s), the signature (r, n-s) is ALSO valid (different v).
**Prevention**: Enforce s to be in the lower half of the curve order (EIP-2).
OpenZeppelin's ECDSA library handles this automatically.

```solidity
// Check lower-s (OpenZeppelin does this for you)
require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);
```

## EIP-712: Typed Structured Data Signing

The standard for off-chain signed messages in DeFi. Used by: Permit, UniswapX, 0x orders, CLOB order books.

```solidity
// Domain separator — unique per contract deployment
bytes32 public immutable DOMAIN_SEPARATOR;

constructor() {
    DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("PredictionMarket")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
    ));
}

// Type hash for the specific struct
bytes32 constant ORDER_TYPEHASH = keccak256(
    "Order(address maker,uint8 outcome,uint256 price,uint256 amount,uint256 nonce,uint256 expiry)"
);

function hashOrder(Order memory order) public view returns (bytes32) {
    bytes32 structHash = keccak256(abi.encode(
        ORDER_TYPEHASH,
        order.maker,
        order.outcome,
        order.price,
        order.amount,
        order.nonce,
        order.expiry
    ));

    return keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        structHash
    ));
}

function verifyOrder(Order memory order, bytes memory signature) public view returns (bool) {
    bytes32 digest = hashOrder(order);
    address signer = ECDSA.recover(digest, signature);
    return signer == order.maker;
}
```

### EIP-191: Personal Sign
```solidity
// Prefix: "\x19Ethereum Signed Message:\n" + length
// Used by MetaMask's personal_sign
bytes32 ethSignedHash = keccak256(abi.encodePacked(
    "\x19Ethereum Signed Message:\n32",
    messageHash
));
address signer = ecrecover(ethSignedHash, v, r, s);
```

## BLS Signatures (Aggregatable)
- One signature can prove that N signers ALL agreed on a message
- Used in: Ethereum beacon chain (validator attestations), future governance vote aggregation
- BLS12-381 curve (different from secp256k1)
- On-chain verification via ecPairing precompile (0x08) on alt_bn128

```
Individual signatures: σ₁, σ₂, ..., σₙ
Aggregated signature: σ_agg = σ₁ + σ₂ + ... + σₙ
Verification: e(σ_agg, G₂) == Π e(Hᵢ, PKᵢ)
// One pairing check instead of N signature verifications
```

**Use case**: Batch verify 1000 oracle attestations with one on-chain verification.

## Merkle Trees

### Standard Merkle Tree
```
        Root
       /    \
     H(AB)  H(CD)
     /  \    /  \
   H(A) H(B) H(C) H(D)
    |    |    |    |
    A    B    C    D
```

Proof for B: [H(A), H(CD)] — only log₂(n) hashes needed.

```solidity
// OpenZeppelin MerkleProof
function verifyAllowlist(bytes32[] calldata proof, address account) external view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(account));
    return MerkleProof.verify(proof, merkleRoot, leaf);
}
```

### Sparse Merkle Tree
- Can prove NON-membership (leaf is empty/default)
- Used in: rollup state trees, exclusion proofs

### Merkle Mountain Range
- Append-only, no need to rebuild tree on new entries
- Used in: Ethereum light clients, commitment chains

## Commitment Schemes

### Commit-Reveal
```solidity
mapping(address => bytes32) public commitments;
mapping(address => uint256) public commitBlock;

// Phase 1: Commit hash
function commit(bytes32 commitment) external {
    commitments[msg.sender] = commitment;
    commitBlock[msg.sender] = block.number;
}

// Phase 2: Reveal (must be different block)
function reveal(uint256 value, bytes32 salt) external {
    require(block.number > commitBlock[msg.sender], "Same block");
    require(keccak256(abi.encode(value, salt)) == commitments[msg.sender], "Invalid reveal");
    delete commitments[msg.sender];
    // Process value — front-running impossible
}
```

### Pedersen Commitments
Additively homomorphic: C(a) + C(b) = C(a+b) without revealing a or b.
Used for: confidential transactions, range proofs, private voting.
```
C = v×G + r×H
// v = value (hidden), r = blinding factor (random), G and H are generator points
// Can verify: C₁ + C₂ = C₃ iff v₁ + v₂ = v₃
```

## VRF (Verifiable Random Functions)

### Chainlink VRF
1. Contract requests random number + provides seed
2. VRF node computes: (randomNumber, proof) = VRF(nodeSecretKey, seed)
3. Node submits proof on-chain
4. Contract verifies proof (mathematically guaranteed correct)
5. If proof is valid → randomNumber is provably fair

### RANDAO (Ethereum Consensus)
- Each validator commits to a random value
- Block proposer's RANDAO mix = XOR of all validators' values
- Biasable by the last validator (can choose to publish or withhold)
- Good enough for most on-chain randomness, not for high-stakes gambling

### Commit-Reveal Multi-Party
1. All participants commit hash(secret)
2. All participants reveal secrets
3. Random = hash(secret₁ || secret₂ || ... || secretₙ)
4. Last revealer can bias by choosing not to reveal — add slashing/bonds

## ZK Deep Dive (Beyond Skill 23)

### KZG Commitments (EIP-4844)
- Polynomial commitment scheme used for blob data verification
- Commit to a polynomial, later prove evaluation at a specific point
- Precompile 0x0a: `point_evaluation_precompile` verifies KZG proofs
- This is what makes proto-danksharding work (cheap L2 data)

### Circuit Design Principles
- Minimize constraints (each constraint = gas for proof verification)
- Avoid branching (if/else is expensive in circuits — use arithmetic: `result = condition * a + (1 - condition) * b`)
- Use lookup tables for complex operations (Plookup)
- Field arithmetic: everything is modular arithmetic in a prime field
