# EVM Precompiles & Edge Cases

Expert-level reference for EVM precompiled contracts, low-level opcodes, and cross-chain compatibility. Covers gas optimization, assembly patterns, and correctness traps.

---

## 1. All EVM Precompiles (0x01–0x0a)

Precompiles are special contracts with fixed addresses that execute native code outside the EVM interpreter. They are available on all EVM-compatible chains unless explicitly noted.

### Address Map

| Address | Name               | Introduced  | EIP        |
|---------|--------------------|-------------|------------|
| 0x01    | ecrecover          | Frontier    | —          |
| 0x02    | SHA-256            | Frontier    | —          |
| 0x03    | RIPEMD-160         | Frontier    | —          |
| 0x04    | identity (datacopy)| Frontier    | —          |
| 0x05    | modexp             | Byzantium   | EIP-198    |
| 0x06    | ecAdd (BN254)      | Byzantium   | EIP-196    |
| 0x07    | ecMul (BN254)      | Byzantium   | EIP-196    |
| 0x08    | ecPairing (BN254)  | Byzantium   | EIP-197    |
| 0x09    | blake2f            | Istanbul    | EIP-152    |
| 0x0a    | point evaluation   | Cancun      | EIP-4844   |

### 0x01 — ecrecover

Recovers the Ethereum address from an ECDSA signature. Used for signature verification without deploying verification logic.

**Input (128 bytes):**
- `hash` (32 bytes): the keccak256 message hash
- `v` (32 bytes): recovery id, must be 27 or 28
- `r` (32 bytes): ECDSA r component
- `s` (32 bytes): ECDSA s component

**Output:** 32 bytes — left-padded recovered address, or empty on failure (does NOT revert).

**Gas:** 3000 (fixed)

**Critical behavior:** Returns empty bytes (not zero address) on invalid input. Always check return data length.

```solidity
function ecrecoverWrapper(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
) internal pure returns (address recovered) {
    assembly {
        let ptr := mload(0x40)
        mstore(ptr, hash)
        mstore(add(ptr, 0x20), v)
        mstore(add(ptr, 0x40), r)
        mstore(add(ptr, 0x60), s)
        // staticcall: (gas, addr, argsOffset, argsLen, retOffset, retLen)
        let success := staticcall(gas(), 0x01, ptr, 0x80, ptr, 0x20)
        // If success=0 or output is zero address, recovery failed
        if iszero(success) { revert(0, 0) }
        recovered := mload(ptr)
    }
    require(recovered != address(0), "ecrecover: invalid sig");
}
```

**Malleable signatures:** ECDSA allows two valid `s` values for any signature. Enforce `s <= secp256k1n/2` to prevent signature malleability (OpenZeppelin's ECDSA library does this).

### 0x02 — SHA-256

**Input:** arbitrary bytes
**Output:** 32-byte SHA-256 hash
**Gas:** `60 + 12 * ceil(input_len / 32)`

```solidity
function sha256Hash(bytes memory data) internal view returns (bytes32 result) {
    assembly {
        // data layout: length slot (32 bytes) then data
        let success := staticcall(
            gas(),
            0x02,
            add(data, 0x20),  // skip length prefix
            mload(data),       // actual byte length
            result,            // write directly to result slot
            0x20
        )
        if iszero(success) { revert(0, 0) }
        result := mload(result)
    }
}
```

Use SHA-256 (not keccak256) when interoperating with Bitcoin scripts, TLS certificates, or IPFS CIDs (which use multihash with SHA-256).

### 0x03 — RIPEMD-160

**Input:** arbitrary bytes
**Output:** 32 bytes (20-byte RIPEMD-160 hash, left-padded with 12 zero bytes)
**Gas:** `600 + 120 * ceil(input_len / 32)`

Primarily useful for Bitcoin address derivation (Bitcoin uses `RIPEMD160(SHA256(pubkey))`). Rarely used in modern contracts. Note: RIPEMD-160 is unavailable on some chain deployments — test before relying on it.

### 0x04 — identity (datacopy)

Copies input to output unchanged. Cheapest way to copy memory in older EVM versions before MCOPY (EIP-5656).

**Gas:** `15 + 3 * ceil(input_len / 32)`

```solidity
function memoryCopy(bytes memory src) internal view returns (bytes memory dst) {
    assembly {
        let len := mload(src)
        dst := mload(0x40)
        mstore(0x40, add(dst, add(len, 0x20)))
        mstore(dst, len)
        // identity precompile copies src data to dst data region
        pop(staticcall(
            gas(),
            0x04,
            add(src, 0x20),
            len,
            add(dst, 0x20),
            len
        ))
    }
}
```

**Optimization note:** Post-Cancun with MCOPY available, use the opcode directly — it avoids call overhead (call overhead = 700 gas base). Identity precompile costs 700 (call) + 15 + 3*chunks. MCOPY costs 3 + 3*words. Break-even is around 4 words; MCOPY wins for all sizes.

### 0x05 — modexp (EIP-198)

Computes `base^exp mod modulus` for arbitrary-precision integers. Essential for RSA verification and other number-theoretic operations.

**Input layout:**
```
Bsize (32 bytes) — byte length of base
Esize (32 bytes) — byte length of exponent
Msize (32 bytes) — byte length of modulus
B     (Bsize bytes)
E     (Esize bytes)
M     (Msize bytes)
```

**Output:** `Msize` bytes — the result, left-padded with zeros.

**Gas (EIP-2565, Berlin):**
```
gas = max(200, mult_complexity(max(Bsize,Msize)) * max(Esize_bits, 1) / GQUADDIVISOR)

mult_complexity(x):
  if x <= 64:  return x^2
  if x <= 1024: return x^2/4 + 96*x - 3072
  else:         return x^2/16 + 480*x - 199680

GQUADDIVISOR = 3
Esize_bits = bit length of exponent (not byte length)
```

**Pre-Berlin gas (EIP-198):** Different formula — GQUADDIVISOR was 20. Berlin (EIP-2565) made modexp dramatically cheaper.

```solidity
function modexp(
    bytes memory base,
    bytes memory exp,
    bytes memory mod
) internal view returns (bytes memory result) {
    uint256 bLen = base.length;
    uint256 eLen = exp.length;
    uint256 mLen = mod.length;

    bytes memory input = abi.encodePacked(
        bytes32(bLen),
        bytes32(eLen),
        bytes32(mLen),
        base,
        exp,
        mod
    );

    result = new bytes(mLen);

    assembly {
        let success := staticcall(
            gas(),
            0x05,
            add(input, 0x20),
            mload(input),
            add(result, 0x20),
            mLen
        )
        if iszero(success) { revert(0, 0) }
    }
}
```

### 0x06 — ecAdd (BN254 / alt_bn128)

Point addition on the BN254 elliptic curve. Used in ZK proof verification.

**Input:** 128 bytes — two G1 points (x1, y1, x2, y2), each coordinate 32 bytes
**Output:** 64 bytes — resulting G1 point (x, y)
**Gas:** 150 (post-Istanbul, EIP-1108; was 500 pre-Istanbul)

Points must be on the curve. If either point is invalid or not on curve, returns failure (empty output, not revert at EVM level — check `success`).

The point at infinity is encoded as (0, 0).

### 0x07 — ecMul (BN254)

Scalar multiplication: `point * scalar` on BN254 G1.

**Input:** 96 bytes — (x, y, scalar), each 32 bytes
**Output:** 64 bytes — resulting G1 point
**Gas:** 6000 (post-Istanbul; was 40000 pre-Istanbul)

```solidity
// Verify a BN254 G1 point is on the curve (simplified)
function isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
    // BN254: y^2 = x^3 + 3 (mod p)
    uint256 p = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 lhs = mulmod(y, y, p);
    uint256 rhs = addmod(mulmod(mulmod(x, x, p), x, p), 3, p);
    return lhs == rhs;
}
```

### 0x08 — ecPairing (BN254)

Bilinear pairing check. Core primitive for Groth16, PLONK, and other SNARK verification.

**Input:** n * 192 bytes — n pairs of (G1_x, G1_y, G2_x1, G2_x2, G2_y1, G2_y2)
**Output:** 32 bytes — 1 if pairing product equals identity, 0 otherwise
**Gas (Istanbul):** `45000 + 34000 * k` where k = number of pairs

**Critical:** The precompile checks if `product(e(Ai, Bi)) == 1` in GT. It does NOT compute individual pairings.

**Groth16 Verifier Pattern:**
```solidity
// Simplified Groth16 on-chain verifier
function verifyGroth16(
    uint256[2] calldata pA,     // proof.A in G1
    uint256[2][2] calldata pB,  // proof.B in G2
    uint256[2] calldata pC,     // proof.C in G1
    uint256[2] calldata vkAlpha,// vk.alpha in G1
    uint256[2][2] calldata vkBeta, // vk.beta in G2
    uint256[2][2] calldata vkGamma,
    uint256[2] calldata vkDelta_neg, // negated for pairing check
    uint256[2][2] calldata vkDelta_neg2,
    uint256[] calldata publicInputs,
    uint256[2][] calldata vkIC  // IC commitment points
) internal view returns (bool) {
    // Compute linear combination: vk_x = vk.IC[0] + sum(public[i] * vk.IC[i+1])
    uint256[2] memory vk_x = [vkIC[0][0], vkIC[0][1]];
    for (uint i = 0; i < publicInputs.length; i++) {
        // ecMul: publicInputs[i] * vkIC[i+1]
        // ecAdd: vk_x += result
        (bool ok, bytes memory res) = address(0x07).staticcall(
            abi.encode(vkIC[i+1][0], vkIC[i+1][1], publicInputs[i])
        );
        require(ok && res.length == 64);
        (uint256 px, uint256 py) = abi.decode(res, (uint256, uint256));
        (ok, res) = address(0x06).staticcall(abi.encode(vk_x[0], vk_x[1], px, py));
        require(ok && res.length == 64);
        (vk_x[0], vk_x[1]) = abi.decode(res, (uint256, uint256));
    }

    // Pairing check: e(A,B) * e(alpha,beta) * e(vk_x, gamma) * e(C, delta) == 1
    // Pack all pairs and call 0x08
    bytes memory input = abi.encode(
        pA[0], pA[1], pB[0][0], pB[0][1], pB[1][0], pB[1][1],
        vkAlpha[0], vkAlpha[1], vkBeta[0][0], vkBeta[0][1], vkBeta[1][0], vkBeta[1][1],
        vk_x[0], vk_x[1], vkGamma[0][0], vkGamma[0][1], vkGamma[1][0], vkGamma[1][1],
        pC[0], pC[1], vkDelta_neg[0], vkDelta_neg[1], vkDelta_neg2[0][0], vkDelta_neg2[0][1], vkDelta_neg2[1][0], vkDelta_neg2[1][1]
    );
    (bool success, bytes memory out) = address(0x08).staticcall(input);
    require(success && out.length == 32);
    return abi.decode(out, (uint256)) == 1;
}
```

**Gas for 4-pair Groth16:** `45000 + 34000*4 = 181000` gas just for the pairing check.

### 0x09 — blake2f (EIP-152)

BLAKE2b compression function. Used for Zcash note commitments and other BLAKE2 hash schemes.

**Input:** 213 bytes
- rounds (4 bytes, big-endian)
- h (64 bytes): state vector
- m (128 bytes): message block
- t (16 bytes): offset counters
- f (1 byte): final block indicator

**Output:** 64 bytes — updated state vector
**Gas:** `rounds` (1 gas per round; typically 12 rounds = 12 gas)

Extremely cheap. Enables Zcash interoperability: Zcash's sapling note commitments use BLAKE2s (different from BLAKE2b — note this is for PoW mining checks, not sapling directly).

### 0x0a — Point Evaluation (EIP-4844)

Verifies a KZG proof that a polynomial commitment evaluates to a value at a given point. Used with blob transactions.

**Input:** 192 bytes
- versioned_hash (32 bytes)
- z (32 bytes): evaluation point
- y (32 bytes): claimed value
- commitment (48 bytes): KZG commitment
- proof (48 bytes): KZG proof

**Output:** 64 bytes — `FIELD_ELEMENTS_PER_BLOB` (4096) and BLS_MODULUS if valid
**Gas:** 50000 (fixed)

Returns success only if the proof is valid AND the versioned_hash matches the commitment. See Section 11 for full blob transaction coverage.

---

## 2. Gas Costs Summary and Optimization

### Quick Reference Table

| Precompile  | Gas Formula                              | Typical Cost   |
|-------------|------------------------------------------|----------------|
| ecrecover   | 3000 (fixed)                             | 3000           |
| SHA-256     | 60 + 12*ceil(n/32)                       | ~72 (32 bytes) |
| RIPEMD-160  | 600 + 120*ceil(n/32)                     | ~720 (32 bytes)|
| identity    | 15 + 3*ceil(n/32)                        | ~18 (32 bytes) |
| modexp      | max(200, complexity)                     | 200–∞          |
| ecAdd       | 150                                      | 150            |
| ecMul       | 6000                                     | 6000           |
| ecPairing   | 45000 + 34000*k                          | 79000 (1 pair) |
| blake2f     | rounds                                   | 12 (typical)   |
| point eval  | 50000 (fixed)                            | 50000          |

**Call overhead:** Every precompile call incurs the CALL opcode overhead: 700 gas base (cold account: 2600 in EIP-2929 context). Pre-warm precompile addresses with access lists for batched verifications.

**Access list optimization for ecPairing:**
```solidity
// In transaction, include access list entry:
// {"address": "0x0000000000000000000000000000000000000008", "storageKeys": []}
// Reduces first access from 2600 to 100 gas
```

### Batching Strategy

For multiple ecrecover calls, batch off-chain and submit results. Recover on-chain only when necessary. For pairing checks, accumulate multiple pairs into one ecPairing call — each additional pair costs 34000 gas vs 45000+700 for a new call.

---

## 3. Using Precompiles from Solidity — Assembly Patterns

### Canonical Call Pattern

```solidity
function callPrecompile(
    address precompile,
    bytes memory input,
    uint256 outputLen
) internal view returns (bool success, bytes memory output) {
    output = new bytes(outputLen);
    assembly {
        success := staticcall(
            gas(),                    // forward all gas
            precompile,
            add(input, 0x20),        // skip ABI length prefix
            mload(input),            // input length
            add(output, 0x20),       // output buffer (skip length)
            outputLen
        )
    }
    // Critical: check both success AND output length
    if (!success || output.length == 0) revert PrecompileCallFailed();
}
```

### Stack-Allocated Pattern (no heap allocation)

```solidity
function ecAddStack(
    uint256 x1, uint256 y1,
    uint256 x2, uint256 y2
) internal view returns (uint256 rx, uint256 ry) {
    assembly {
        // Reuse scratch space (0x00–0x3f) — safe for intermediate work
        // Use free memory pointer for input (we need 128 bytes)
        let ptr := mload(0x40)
        mstore(ptr,        x1)
        mstore(add(ptr, 0x20), y1)
        mstore(add(ptr, 0x40), x2)
        mstore(add(ptr, 0x60), y2)
        // Write output to scratch space
        let ok := staticcall(gas(), 0x06, ptr, 0x80, 0x00, 0x40)
        if iszero(ok) { revert(0, 0) }
        rx := mload(0x00)
        ry := mload(0x20)
        // Do NOT advance free memory pointer — we didn't allocate output on heap
    }
}
```

### RETURNDATASIZE Checking

```solidity
assembly {
    let ok := staticcall(gas(), 0x01, ptr, 0x80, 0x00, 0x20)
    // Check both call success and that we got 32 bytes back
    if or(iszero(ok), iszero(eq(returndatasize(), 0x20))) {
        revert(0, 0)
    }
    recovered := mload(0x00)
}
```

**Trap:** `ecrecover` returns 0 bytes (not 32 zero bytes) on failure. Always check `returndatasize()`.

### Checking Return Data When Output Buffer Is Larger Than Actual Return

If `retLen` in STATICCALL exceeds actual return data, the extra bytes are zeroed in the output buffer but `returndatasize()` reflects the actual return length. Never rely on the output buffer being fully written.

---

## 4. BN254 (alt_bn128) Curve Operations

### Curve Parameters

```
Field modulus p = 21888242871839275222246405745257275088696311157297823662689037894645226208583
Group order  r = 21888242871839275222246405745257275088548364400416034343698204186575808495617

G1 generator: (1, 2)
G2 generator:
  x = (11559732032986387107991004021392285783925812861821192530917403151452391805634,
       10857046999023057135944570762232829481370756359578518086990519993285655852781)
  y = (4082367875863433681332203403145435568316851327593401208105741076214120093531,
       8495653923123431417604973247489272438418190587263600148770280649306958101930)
```

### Negating a G1 Point (for pairing checks)

```solidity
uint256 constant P = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

function negate(uint256[2] memory point) internal pure returns (uint256[2] memory) {
    if (point[0] == 0 && point[1] == 0) return point; // point at infinity
    return [point[0], P - (point[1] % P)];
}
```

### Pairing Equation for Groth16

Groth16 requires checking:
`e(A, B) = e(alpha, beta) * e(vk_x, gamma) * e(C, delta)`

Rearranged for a single ecPairing call (checking product == 1):
`e(A, B) * e(-alpha, beta) * e(-vk_x, gamma) * e(-C, delta) == 1`

Or equivalently:
`e(A, B) * e(alpha, -beta) * e(vk_x, -gamma) * e(C, -delta) == 1`

Negate G2 points by negating their y coordinate in Fp2 (negate the second component of each y coordinate).

### BN254 Subgroup Check

Not all bytes decode to valid curve points. The precompile returns failure (empty output) for off-curve points. For G2 points used in pairings, also check subgroup membership — the precompile does this internally for ecPairing.

---

## 5. Modular Exponentiation — RSA and Big Numbers

### RSA Verification On-Chain

RSA signature verification: check `sig^e mod n == hash` (with PKCS#1 v1.5 or PSS padding).

```solidity
library RSAVerifier {
    // Verify RSA-PKCS1v1.5 signature
    // n: modulus, e: public exponent (usually 65537), sig: signature, hash: sha256 digest
    function verify(
        bytes memory sig,
        bytes memory hash,
        bytes memory e,
        bytes memory n
    ) internal view returns (bool) {
        // Compute sig^e mod n
        bytes memory result = modexp(sig, e, n);
        if (result.length != n.length) return false;

        // PKCS#1 v1.5 padding check for SHA-256
        // Expected: 0x00 0x01 [0xff padding] 0x00 [SHA256 DigestInfo prefix] [hash]
        // DigestInfo for SHA-256 (19 bytes):
        // 30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20
        bytes memory prefix = hex"3031300d060960864801650304020105000420";
        bytes memory expected = abi.encodePacked(
            hex"0001",
            new bytes(result.length - 3 - prefix.length - hash.length), // 0xff padding
            hex"00",
            prefix,
            hash
        );
        // Fill padding with 0xff
        for (uint i = 2; i < result.length - 3 - prefix.length - hash.length + 2; i++) {
            expected[i] = 0xff;
        }
        return keccak256(result) == keccak256(expected);
    }

    function modexp(bytes memory base, bytes memory exp, bytes memory mod)
        internal view returns (bytes memory result)
    {
        uint256 bLen = base.length;
        uint256 eLen = exp.length;
        uint256 mLen = mod.length;
        result = new bytes(mLen);

        assembly {
            let inputLen := add(0x60, add(bLen, add(eLen, mLen)))
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, inputLen))
            mstore(ptr, bLen)
            mstore(add(ptr, 0x20), eLen)
            mstore(add(ptr, 0x40), mLen)
            // Copy base, exp, mod into ptr+0x60
            // (abbreviated — use calldatacopy or loop in practice)
            let ok := staticcall(gas(), 0x05, ptr, inputLen, add(result, 0x20), mLen)
            if iszero(ok) { revert(0, 0) }
        }
    }
}
```

### Gas Estimation for RSA-2048

- mLen = 256, eLen = 3 (e=65537 = 3 bytes), bLen = 256
- mult_complexity(256) = 256^2/4 + 96*256 - 3072 = 16384 + 24576 - 3072 = 37888
- Esize_bits for 65537 = 17
- Gas = 37888 * 17 / 3 = ~214,830 gas

RSA-2048 on-chain: ~215k gas. Practical but expensive. RSA-4096: ~860k gas — marginal.

### Montgomery Modular Multiplication Alternative

For chains without cheap modexp, Montgomery multiplication can be implemented in Yul. But modexp at 0x05 is always cheaper for large numbers.

---

## 6. EVM Edge Cases

### Empty Account Behavior

An account is "empty" if: nonce == 0, balance == 0, codeHash == keccak256("") (no code).

- **EXTCODESIZE** on empty account: returns 0
- **EXTCODEHASH** on empty account: returns 0 (not keccak256(""))
- **CALL** to empty account with value: creates the account (charges account creation gas: 25000)
- **CALL** to empty account without value: does NOT create account, costs 700 base

**Trap:** `EXTCODEHASH` returns `0` for non-existent accounts and `keccak256("")` for existing accounts with no code (EOAs that have sent transactions). Distinguish with `EXTCODESIZE == 0 && EXTCODEHASH != 0`.

```solidity
function isContract(address addr) internal view returns (bool) {
    // Returns true for contracts, false for EOAs and non-existent accounts
    // Trap: constructor context — during construction, EXTCODESIZE of self is 0
    return addr.code.length > 0;
}

function accountExists(address addr) internal view returns (bool) {
    // Exists if balance > 0 OR nonce > 0 OR has code
    // EXTCODEHASH is 0 for non-existent, non-zero for existing (even empty code)
    bytes32 h;
    assembly { h := extcodehash(addr) }
    return h != 0;
}
```

### SELFDESTRUCT Semantics Post-Dencun (EIP-6780)

**Before Dencun:** SELFDESTRUCT deletes contract code and storage, sends balance to target.

**After Dencun (EIP-6780):** SELFDESTRUCT only deletes code and storage if called in the **same transaction as the contract's creation** (CREATE or CREATE2). Otherwise, it only sends balance — code and storage remain.

```solidity
// This pattern ONLY works if called in same tx as deployment:
contract SelfDestructable {
    function kill(address payable target) external {
        selfdestruct(target);
        // If this tx did not create this contract:
        //   - balance is sent to target
        //   - code remains
        //   - storage remains
        //   - contract NOT deleted from state trie
    }
}
```

**Implications:**
- Flash loan patterns using SELFDESTRUCT for cleanup no longer work
- Proxy destruction patterns broken
- CREATE2 re-deployment at same address is no longer guaranteed to find clean state
- `SELFDESTRUCT` in a CREATE2 factory deployed and destructed in same tx still works

### EXTCODECOPY on EOAs

`EXTCODECOPY` on an EOA returns empty bytes (copies nothing). The length is 0.

```solidity
assembly {
    // Copy code of any address (EOA returns empty)
    let codeLen := extcodesize(target)
    let codeBuf := mload(0x40)
    mstore(0x40, add(codeBuf, codeLen))
    extcodecopy(target, codeBuf, 0, codeLen)
    // If target is EOA: codeLen == 0, nothing copied
}
```

**Gas:** `EXTCODESIZE` = 700 (warm) / 2600 (cold). `EXTCODECOPY` = 700 + 3*ceil(len/32) (warm) / 2600+3*ceil(len/32) (cold).

### RETURNDATASIZE Before Any Call

Before any CALL/STATICCALL/DELEGATECALL/CREATE in the current execution frame, `RETURNDATASIZE` is 0. After any such call (including failed ones), it reflects the last return data. A failed call clears return data to 0 bytes.

```solidity
assembly {
    // RETURNDATASIZE = 0 here (start of function/constructor)

    let ok := call(gas(), target, 0, ptr, 32, 0, 0)
    // Now RETURNDATASIZE reflects what target returned (even if ok=0)

    // To safely copy return data:
    let rdSize := returndatasize()
    let rdBuf := mload(0x40)
    mstore(0x40, add(rdBuf, rdSize))
    returndatacopy(rdBuf, 0, rdSize)
    // rdSize may be 0 even on ok=1 (e.g., if callee is an EOA)
}
```

**Trap:** A callee can return any size of data. If you use `CALL` with a fixed `retLen`, you only copy that many bytes but `RETURNDATASIZE` still shows full length. Use `returndatacopy` after checking `returndatasize()`.

### DELEGATECALL Storage Collisions

```solidity
// Vulnerable proxy — slot 0 in implementation overwrites slot 0 in proxy
contract UnsafeProxy {
    address public implementation; // slot 0

    fallback() external payable {
        address impl = implementation;
        assembly { // delegate to impl — impl's slot 0 writes proxy's slot 0!
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

// Safe: EIP-1967 uses keccak256("eip1967.proxy.implementation") - 1
bytes32 constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
```

### GAS Opcode Caveats

`GAS` returns remaining gas at that point in execution. After EIP-2929, warm/cold access costs vary dramatically. Never hardcode gas amounts in low-level calls; use `gas()` or explicit forwarding fractions (`gas()/63` for recursive calls in EIP-150 context).

---

## 7. Chain-Specific Quirks

### Arbitrum (One / Nova)

- **Gas model:** Two-dimensional — L2 gas (computation) + L1 calldata fee (for DA). `ArbGasInfo` precompile at `0x000000000000000000000000000000000000006C` provides L1 pricing.
- **No COINBASE mining:** `block.coinbase` returns the sequencer address.
- **`block.number`:** Returns L2 block number, not L1. Use `ArbSys(0x64).arbBlockNumber()` for L1 block equivalent.
- **`block.basefee`:** L2 base fee. L1 calldata fees are separate.
- **Precompiles:** All standard precompiles available. Additional Arbitrum precompiles at addresses `0x64`–`0x6F`.
- **SELFDESTRUCT:** Works but account deletion is deferred; use with caution.
- **`tx.gasprice`:** May differ from `block.basefee` due to L1 surcharge.

```solidity
// Arbitrum: get L1 gas price for calldata cost estimation
interface IArbGasInfo {
    function getL1BaseFeeEstimate() external view returns (uint256);
    function getCurrentTxL1GasFees() external view returns (uint256);
}
IArbGasInfo constant ARB_GAS_INFO = IArbGasInfo(0x000000000000000000000000000000000000006C);
```

### Optimism (OP Stack)

- **Gas model:** L2 execution gas + L1 data fee. Ecotone upgrade (March 2024) changed L1 fee formula to use blob-equivalent pricing.
- **`GasPriceOracle`** at `0x420000000000000000000000000000000000000F` provides L1 fee info.
- **`block.number`:** Increases at ~2 second intervals; not tied to L1.
- **`block.basefee`:** L2 base fee.
- **`PUSH0`:** Available post-Bedrock. Most EVM opcodes match mainnet.
- **No BLOBHASH** on most OP chains (blobs not posted to OP L2 directly).

```solidity
interface IGasPriceOracle {
    function getL1Fee(bytes memory data) external view returns (uint256);
    function baseFee() external view returns (uint256);
    function l1BaseFee() external view returns (uint256);
}
IGasPriceOracle constant GAS_ORACLE =
    IGasPriceOracle(0x420000000000000000000000000000000000000F);
```

### zkSync Era

- **Different gas model:** Computational gas is NOT equivalent to mainnet. Gas per pubdata byte is a key metric.
- **CREATE/CREATE2:** Address derivation differs from EVM. zkSync uses `keccak256(abi.encode(sender, salt, bytecodeHash, constructorInput))` where `bytecodeHash` is a different hash format.
- **`tx.origin`** behavior: May differ in meta-transactions.
- **Missing precompiles:** Some precompiles may not be available or may have different gas costs. As of 2024, ecPairing is supported via custom implementation.
- **SELFDESTRUCT:** NOT supported. Will revert.
- **`block.timestamp`:** L1 timestamp of the batch, not individual transaction time.
- **Fallback functions and receive:** Slightly different calling semantics.
- **`ecrecover` address:** Supported but `v` value handling can differ for some signature schemes.
- **Storage layout:** Compatible with Solidity/Yul but assembly must account for different gas costs.

```solidity
// zkSync: do NOT use assembly that assumes EVM gas costs
// Use zkSync SDK for cross-chain address computation:
// ZkSyncCreate2Factory.computeCreate2Address(salt, bytecodeHash, constructorHash)
```

### Polygon zkEVM (Hermez)

- **EVM-equivalent** but not identical. Aims for full EVM equivalence.
- **`SELFDESTRUCT`:** Supported but semantics match post-Dencun EIP-6780.
- **SHA-256 and RIPEMD-160:** Available but gas costs may differ from mainnet.
- **`block.difficulty` / PREVRANDAO:** Returns 0 (no PoW/randao in zkEVM context).
- **`BLOBHASH`:** Not available — zkEVM doesn't process blobs natively.
- **`ecrecover`:** Fully supported.
- **Proof system:** Plonky2-based; certain arithmetic-heavy contracts may hit prover limits not reflected in EVM gas.

### Chain Compatibility Table

| Feature              | Mainnet | Arbitrum | Optimism | zkSync  | Polygon zkEVM |
|----------------------|---------|----------|----------|---------|---------------|
| ecrecover (0x01)     | Yes     | Yes      | Yes      | Yes     | Yes           |
| ecPairing (0x08)     | Yes     | Yes      | Yes      | Yes*    | Yes           |
| point eval (0x0a)    | Yes     | Yes      | Yes      | No      | No            |
| SELFDESTRUCT         | EIP-6780| EIP-6780 | EIP-6780 | No      | EIP-6780      |
| BLOBHASH             | Yes     | No       | No       | No      | No            |
| PUSH0                | Yes     | Yes      | Yes      | Yes     | Yes           |
| TSTORE/TLOAD         | Yes     | Yes      | Yes      | Yes     | Yes           |
| MCOPY                | Yes     | Yes      | Yes      | Yes*    | Yes*          |

`*` — support added in 2024; verify deployment version.

---

## 8. Transient Storage (EIP-1153) — TSTORE/TLOAD

Available from Cancun (mainnet, March 2024). Transient storage slots are per-transaction, per-contract, zeroed at transaction start.

**Opcodes:**
- `TSTORE(slot, value)` — gas: 100
- `TLOAD(slot)` — gas: 100

**Behavior:** Like SSTORE/SLOAD but wiped after the transaction. No refunds (no dirty/clean distinction). Always costs 100 gas.

### Reentrancy Lock with Transient Storage

```solidity
// Gas cost: ~100 vs ~2200 (SSTORE cold) for traditional reentrancy lock
contract TransientReentrancyGuard {
    uint256 private constant REENTRANCY_SLOT = uint256(keccak256("reentrancy.guard.v1"));

    modifier nonReentrant() {
        assembly {
            if tload(REENTRANCY_SLOT) { revert(0, 0) }
            tstore(REENTRANCY_SLOT, 1)
        }
        _;
        assembly {
            tstore(REENTRANCY_SLOT, 0)
        }
    }
}
```

**Gas savings:** Traditional `nonReentrant` with SSTORE costs ~2200 gas (cold write) on enter + ~100 (warm) or 2900 (refund eligible) on exit. TSTORE costs 100 on enter + 100 on exit = 200 total. Saves ~2000–2800 gas per protected call.

### Callback Approval Pattern

Replace approval + call + revoke approval with transient approval:

```solidity
contract FlashLender {
    uint256 private constant CALLBACK_SLOT = uint256(keccak256("flash.callback.approved"));

    function flashLoan(address receiver, uint256 amount, bytes calldata data) external {
        IERC20(token).transfer(receiver, amount);

        // Set transient approval for callback
        assembly { tstore(CALLBACK_SLOT, receiver) }

        IFlashReceiver(receiver).onFlashLoan(msg.sender, token, amount, fee, data);

        // Clear (redundant — tx end clears, but explicit is safer for nested flash loans)
        assembly { tstore(CALLBACK_SLOT, 0) }

        // Pull back funds
        IERC20(token).transferFrom(receiver, address(this), amount + fee);
    }

    function isApprovedCallback(address caller) internal view returns (bool) {
        address approved;
        assembly { approved := tload(CALLBACK_SLOT) }
        return approved == caller;
    }
}
```

### Cross-Contract Transient Storage

Transient storage is contract-specific. Calling contract A from contract B does NOT share transient storage. Use for per-contract-per-tx state only.

### ERC-7562 Paymaster Context via Transient Storage

Account abstraction paymasters use transient storage to pass context from `validatePaymasterUserOp` to `postOp` within the same bundle transaction without SSTORE costs.

---

## 9. MCOPY (EIP-5656) — Memory Copying

Available from Cancun. The `MCOPY` opcode copies memory regions within the current execution frame.

**Opcode:** `MCOPY(dst, src, length)` — pops 3 stack items
**Gas:** `3 + 3 * ceil(length / 32)` (same as CALLDATACOPY/CODECOPY formula, but faster due to no I/O)

### Comparison: MCOPY vs Identity Precompile vs Loop

For 1024 bytes (32 words):
- **Loop (MSTORE32 * 32):** 32 * (MLOAD=3 + MSTORE=3 + ADD=3 + loop overhead) ≈ 32 * 12 = ~384 gas + setup
- **Identity precompile:** 700 (call) + 15 + 3*32 = 811 gas
- **MCOPY:** 3 + 3*32 = 99 gas

MCOPY is ~8x cheaper than identity precompile for 1KB copies.

```solidity
// Solidity 0.8.25+ uses MCOPY automatically for some memory copies
// For manual use, use assembly:
function mcopy(uint256 dst, uint256 src, uint256 length) internal pure {
    assembly {
        // MCOPY is opcode 0x5e (Cancun)
        // Solidity inline assembly supports it:
        mcopy(dst, src, length)
    }
}

// Practical example: efficient bytes memory copy
function copyBytes(
    bytes memory src,
    uint256 srcOffset,
    uint256 length
) internal pure returns (bytes memory dst) {
    dst = new bytes(length);
    assembly {
        mcopy(
            add(dst, 0x20),           // skip dst length slot
            add(add(src, 0x20), srcOffset), // skip src length slot + offset
            length
        )
    }
}
```

**Overlapping regions:** MCOPY handles overlapping src/dst correctly (like memmove, not memcpy). Direction of copy is implementation-defined to handle overlap — safe to use even for overlapping regions.

**Availability:** Solidity 0.8.25+ emits MCOPY in generated bytecode for internal memory copies. `--evm-version cancun` flag required. Older solc versions use identity precompile or MSTORE loops.

---

## 10. EOF (EVM Object Format) — EIP-3540, EIP-4200, EIP-4750

EOF introduces a structured container format for EVM bytecode, replacing the flat binary format. As of 2025, EOF is in development/testing phase (Osaka upgrade target).

### Container Format

```
magic:       0xEF 0x00
version:     0x01
type_section:  0x01 [size_2bytes] [n * 4-byte entries]
code_section:  0x02 [count_2bytes] [n * size_2bytes]
data_section:  0x04 [size_2bytes]
terminator:  0x00
[type section data]
[code section 0 data]
[code section n data]
[data section data]
```

### Type Section

Each code section has a 4-byte entry: `inputs (1) | outputs (1) | max_stack_height (2)`

### Key New Opcodes

| Opcode | Name      | Description                                         |
|--------|-----------|-----------------------------------------------------|
| 0x5c   | RJUMP     | Relative unconditional jump (static offset)         |
| 0x5d   | RJUMPI    | Relative conditional jump                           |
| 0x5e   | RJUMPV    | Jump table                                          |
| 0xb0   | CALLF     | Call a code section (function call)                 |
| 0xb1   | RETF      | Return from code section                            |
| 0xe0   | JUMPF     | Tail call to code section (no RETF needed)          |
| 0xec   | EOFCREATE | Create EOF contract                                 |
| 0xee   | RETURNCONTRACT | Return new EOF container               |

### Benefits

- **Static jumps only:** Dynamic JUMP/JUMPI removed → no JIT-hostile runtime jump analysis
- **No stack underflow at deploy:** Stack validation at deploy time, not runtime
- **Code/data separation:** CODECOPY forbidden inside EOF; data section is explicit
- **Smaller bytecode:** PUSH0 + structured sections reduce overhead
- **JUMPF for tail calls:** Gas-efficient function dispatch without stack growth

### JUMPF Example

```
; EOF code section 0: dispatcher
CALLF 1      ; call section 1 (compute)
STOP

; EOF code section 1: compute function
PUSH1 0x05
PUSH1 0x03
ADD          ; stack: [8]
JUMPF 2      ; tail-call section 2 (return result) — no RETF overhead

; EOF code section 2: store result
PUSH0
SSTORE       ; store result at slot 0
RETF
```

### Migration Considerations

- Legacy contracts remain valid and executed as before
- EOF contracts cannot use SELFDESTRUCT (removed in EOF)
- EOF contracts cannot use CALLCODE (deprecated)
- Tools (Foundry, Hardhat) have EOF compilation support in 2025

---

## 11. EIP-4844 Blob Transactions

Blob transactions carry "blob data" (128 KB chunks) committed via KZG commitments. Blobs are available to L2s for DA but are NOT accessible to EVM execution — only commitments are.

### Blob Transaction Type (Type 3)

New fields:
- `max_fee_per_blob_gas`: blob gas price cap
- `blob_versioned_hashes`: list of `keccak256(BLS12-381_commitment)[0] = 0x01 || keccak256(commitment)[1:32]`

### BLOBHASH Opcode (0x49)

```
BLOBHASH(index)
```

- Pops `index` from stack
- Pushes `tx.blob_versioned_hashes[index]` (or 0 if index out of range)
- Gas: 3

```solidity
function getBlobHash(uint256 index) internal view returns (bytes32 blobHash) {
    assembly {
        blobHash := blobhash(index)
        // Returns 0 if index >= number of blobs in tx
        // Format: 0x01 || keccak256(commitment)[1:]
    }
}
```

### Point Evaluation Precompile (0x0a) — Usage

Used by L2s to verify that a claimed value is part of a blob commitment:

```solidity
function verifyBlobProof(
    bytes32 versionedHash,
    bytes32 z,               // evaluation point (field element)
    bytes32 y,               // claimed value at z
    bytes memory commitment, // 48-byte G1 point
    bytes memory proof       // 48-byte KZG proof
) internal view returns (bool) {
    bytes memory input = abi.encodePacked(versionedHash, z, y, commitment, proof);
    require(input.length == 192, "bad input length");

    (bool success, bytes memory output) = address(0x0a).staticcall(input);
    if (!success || output.length != 64) return false;

    // Output: FIELD_ELEMENTS_PER_BLOB (32 bytes) || BLS_MODULUS (32 bytes)
    // Success means proof is valid
    return true;
}
```

### Blob Fee Market

Blob gas is separate from execution gas. Target: 3 blobs/block. Max: 6 blobs/block (pre-Pectra). Blob base fee formula:

```
blob_base_fee = MIN_BLOB_BASE_FEE * e^(excess_blob_gas / BLOB_BASE_FEE_UPDATE_FRACTION)

MIN_BLOB_BASE_FEE = 1 wei
BLOB_BASE_FEE_UPDATE_FRACTION = 3338477
```

Blob fee is paid by the transaction sender (not the blob poster's contract). L2 sequencers estimate blob cost and pass it to users via `GasPriceOracle`.

### Blob Data Access Pattern

L2 nodes read blob data from the beacon node (not the EL). The pattern:

1. L2 sequencer posts batch as blob(s) in a type-3 tx
2. Records `BLOBHASH` on L2 (via BLOBHASH opcode in inbox contract) as commitment
3. L2 verifier fetches blob data from beacon node and verifies against commitment
4. KZG point evaluation proves specific field elements are in the blob

---

## 12. CREATE2 Address Calculation

CREATE2 deploys contracts to deterministic addresses independent of sender nonce.

### Address Formula

```
address = keccak256(0xff ++ sender ++ salt ++ keccak256(initcode))[12:]
```

```solidity
function computeCreate2Address(
    address deployer,
    bytes32 salt,
    bytes memory initcode
) internal pure returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(
        bytes1(0xff),
        deployer,
        salt,
        keccak256(initcode)
    )))));
}
```

### Factory Pattern

```solidity
contract Create2Factory {
    event Deployed(address indexed addr, bytes32 indexed salt);

    function deploy(bytes32 salt, bytes calldata initcode) external returns (address addr) {
        assembly {
            addr := create2(0, add(initcode, 0x20), mload(initcode), salt)
            if iszero(addr) { revert(0, 0) }
        }
        emit Deployed(addr, salt);
    }

    function computeAddress(bytes32 salt, bytes32 initcodeHash)
        external view returns (address)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            initcodeHash
        )))));
    }
}
```

### Pre-fund and Deploy Pattern

```solidity
// Fund an address before deployment (works because address is known)
function prefundAndDeploy(
    bytes32 salt,
    bytes calldata initcode,
    uint256 prefundAmount
) external payable {
    address target = computeCreate2Address(address(this), salt, keccak256(initcode));

    // Transfer funds to the not-yet-deployed address
    (bool ok,) = target.call{value: prefundAmount}("");
    require(ok, "prefund failed");

    // Now deploy — constructor can use the balance
    address deployed;
    assembly {
        deployed := create2(0, add(initcode, 0x20), mload(initcode), salt)
        if iszero(deployed) { revert(0, 0) }
    }
    require(deployed == target, "address mismatch");
}
```

### Vanity Address Mining

```solidity
// Off-chain: mine salt for desired prefix
// Target: address starts with 0xdeadbeef...
bytes32 initcodeHash = keccak256(initcode);
for (uint256 i = 0; i < type(uint256).max; i++) {
    bytes32 salt = bytes32(i);
    address predicted = computeCreate2Address(factory, salt, initcodeHash);
    if (uint160(predicted) >> 132 == 0xdeadbeef >> 4) {
        // Found matching salt
        break;
    }
}
```

Tools: `create2crunch` (Rust), Foundry's `--salt` flag with `forge create --deterministic`.

### CREATE2 Re-deployment Trap (Post-EIP-6780)

Before EIP-6780: deploy → selfdestruct → create2 same address → fresh state
After EIP-6780: deploy → selfdestruct (in later tx) → code remains → create2 fails (address already has code)

The only working pattern post-EIP-6780: deploy → selfdestruct in SAME tx → same tx create2 at same address.

```solidity
// This still works (same transaction):
contract SelfDestructingDeployer {
    constructor(address factory, bytes32 salt, bytes calldata initcode) {
        // 1. Deploy at CREATE2 address (this constructor IS in the creating tx)
        // 2. selfdestruct is called in same tx — code IS deleted
        // 3. Factory can re-deploy at same address in same tx
        selfdestruct(payable(factory));
    }
}
```

### zkSync CREATE2 Difference

On zkSync, `keccak256(initcode)` is replaced with a different hash format. Use zkSync's `ContractDeployer` system contract:

```solidity
// zkSync create2 address:
// keccak256(bytes32(0x2020dba91b30cc0006188af794c2fb30dd8520db7e2c088b7fc7c103c00ca494)
//           ++ sender ++ salt ++ bytecodeHash ++ keccak256(constructorInput))
// where bytecodeHash is a specific zkSync format, not keccak256(initcode)
```

---

## 13. Advanced Assembly Patterns

### Scratch Space Usage

EVM scratch space (0x00–0x3f, 64 bytes) is safe to use as temporary memory in assembly without allocating from the free memory pointer. Solidity does not use this region during most operations.

```solidity
assembly {
    // Safe temporary storage in scratch space
    mstore(0x00, value1)
    mstore(0x20, value2)
    // Use for hashing — equivalent to keccak256(abi.encode(value1, value2))
    let hash := keccak256(0x00, 0x40)
    // Do NOT leave 0x00-0x3f in a modified state when calling external contracts
    // Some ABI decoders may depend on scratch space being predictable
}
```

### Return Data Forwarding

```solidity
// Pass through return data exactly from inner call
assembly {
    let ok := call(gas(), target, value, argsPtr, argsLen, 0, 0)
    returndatacopy(0, 0, returndatasize())
    switch ok
    case 0 { revert(0, returndatasize()) }
    default { return(0, returndatasize()) }
}
```

### Safe Calldata Slicing

```solidity
assembly {
    // Read 32 bytes at calldata offset, bounds-checked
    if lt(calldatasize(), add(offset, 32)) { revert(0, 0) }
    let value := calldataload(offset)
}
```

### Efficient Multi-Return

```solidity
// Return multiple values without ABI encoding overhead
assembly {
    mstore(0x00, value1)
    mstore(0x20, value2)
    mstore(0x40, value3)
    return(0x00, 0x60) // 96 bytes
}
```

---

## 14. Gas Benchmarks Summary

All figures are approximate mainnet gas costs (EVM post-Cancun):

| Operation                         | Gas      | Notes                                    |
|-----------------------------------|----------|------------------------------------------|
| ecrecover                         | 3,000    | Fixed; includes 700 call overhead        |
| SHA-256 (32 bytes)                | 772      | 60+12 + 700 call                         |
| ecAdd                             | 850      | 150 + 700 call                           |
| ecMul                             | 6,700    | 6000 + 700 call                          |
| ecPairing (2 pairs)               | 114,700  | 113000+700; warm access saves ~2500      |
| modexp RSA-2048                   | ~215,000 | Depends on exponent bits                 |
| blake2f (12 rounds)               | 712      | 12 + 700 call                            |
| point evaluation                  | 50,700   | 50000 + 700 call                         |
| TSTORE/TLOAD                      | 100 each | No cold/warm distinction                 |
| SSTORE (cold, new value)          | 22,100   | EIP-2929 + EIP-3529                      |
| SLOAD (cold)                      | 2,100    | EIP-2929                                 |
| SLOAD (warm)                      | 100      | —                                        |
| MCOPY (1KB)                       | 99       | 3 + 3*32 words                           |
| Identity precompile (1KB)         | 811      | 700 + 15 + 96                            |
| EXTCODESIZE (cold)                | 2,600    | EIP-2929                                 |
| CALL (cold address, no value)     | 2,600    | Base cold account access                 |
| CREATE2                           | 32,000+  | 32000 + 2*initcode_words + execution     |
| KECCAK256 (32 bytes)              | 36       | 30 + 6*1 word                            |

---

## 15. Common Pitfalls and Correctness Traps

1. **ecrecover returns empty on failure** — not zero address. Check `returndatasize() == 32`.
2. **ecAdd/ecMul return empty on invalid input** — off-curve points cause failure, not revert.
3. **modexp output is right-aligned** — if result < modulus byte length, left-padded with zeros.
4. **ecPairing result is 1 or 0** — not a point; decode as uint256.
5. **SELFDESTRUCT post-EIP-6780** — only deletes state in creation transaction.
6. **CREATE2 fails if address already has code** — includes non-zero nonce from previous deployment.
7. **EXTCODEHASH = 0 for non-existent, = keccak256("") for deployed-but-empty-code** — distinguish with balance/nonce checks.
8. **BLOBHASH returns 0 for out-of-range index** — not revert. Check != 0.
9. **TSTORE is NOT persisted** — cleared at transaction boundary; don't use for state you need across txs.
10. **RETURNDATASIZE is 0 at call entry** — only has data after at least one subcall.
11. **BN254 != BLS12-381** — EIP-4844 uses BLS12-381; precompiles 0x06-0x08 use BN254 (alt_bn128).
12. **zkSync CREATE2 addresses differ** — same salt and initcode produces different address on zkSync.
13. **Arbitrum block.number is L2 block** — not L1; use ArbSys for L1 equivalent.
14. **Access list precompile warm-up** — include precompile addresses in access lists for batched operations to save 2500 gas each.
15. **MCOPY available only post-Cancun** — falls back to invalid opcode on older EVM versions; check target chain upgrade.
