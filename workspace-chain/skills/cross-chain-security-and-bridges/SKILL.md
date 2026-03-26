# Cross-Chain Security & Bridges

Expert reference for bridge architecture, security models, exploit analysis, message passing protocols, and secure cross-chain application development.

---

## 1. Bridge Architecture Taxonomy

Bridges move value or state between chains that share no native consensus. Every design makes a trade-off among trust minimization, latency, capital efficiency, and generality.

### 1.1 Lock-and-Mint

The canonical pattern for moving a native asset to a foreign chain.

```
Source Chain                          Destination Chain
─────────────────                     ─────────────────
User holds TOKEN                      Minter contract
    │                                        │
    ▼                                        │
Vault/Escrow locks TOKEN              mints wTOKEN 1:1
    │                                        ▲
    └──── Bridge message ────────────────────┘
           (proof of lock)
```

- The vault holds the canonical supply; wrapped tokens are IOUs on the destination.
- Risk: if the vault is drained, wrapped tokens become worthless.
- Examples: Wrapped Bitcoin (WBTC custodial), Wormhole wETH, Ronin ETH.

### 1.2 Burn-and-Mint

A variation where the token exists natively on multiple chains; no single canonical vault.

```
Source Chain          Bridge Layer          Destination Chain
────────────          ───────────           ─────────────────
burn TOKEN ──────────► relay proof ────────► mint TOKEN
```

- Requires a trusted or verified burn event before mint is authorised.
- Token supply is split across chains; total supply is conserved globally.
- Examples: Circle CCTP (USDC), LayerZero OFT standard.

### 1.3 Liquidity Networks (Pool-Based)

Liquidity providers pre-fund pools on each chain. The bridge is a cross-chain swap against local liquidity.

```
Source Chain          Bridge Protocol       Destination Chain
────────────          ───────────           ─────────────────
deposit USDC ────────► router ─────────────► release USDC from pool
                        │
                        └── rebalance mechanism (slow path)
```

- No minting; uses real assets on each side. Near-instant UX.
- LP capital risk: pool imbalance, LP losses if the fast path is exploited.
- Examples: Across Protocol, Connext, Stargate (LayerZero).

### 1.4 Atomic Swaps (HTLC)

Hash-Time-Locked Contracts enforce that both sides of a swap either complete or refund. Trustless but synchronous.

```
Alice (Chain A)                       Bob (Chain B)
────────────────                      ─────────────
lock(hash(secret), timeout_A) ──────► lock(hash(secret), timeout_B)
                                            │
reveal(secret) ◄──────────────────── claim with secret
claim(secret)
```

- Entirely trustless: cryptographic guarantees only.
- Limitations: both parties must be online; fungibility is poor; high latency.
- Not suitable for arbitrary message passing.

### 1.5 Rollup Bridges (Canonical)

Rollup bridges inherit security from L1 by posting state roots on-chain.

```
L2 (Rollup)                          L1 (Ethereum)
───────────                           ─────────────
withdraw initiated
    │
    ▼
state root posted ──────────────────► Bridge contract reads root
                                       verifies inclusion proof
                                       releases funds
```

- Optimistic rollups: 7-day challenge window before withdrawal finalises.
- ZK rollups: proof verified on-chain; withdrawal can finalise in minutes.
- Trust model: inherits L1 security if proofs are correct and contracts are not upgradeable with short timelocks.

---

## 2. Security Ranking of Bridge Types

From most to least trust-minimised:

```
MOST TRUSTED (closest to L1 security)
┌────────────────────────────────────────────────────────┐
│ 1. Canonical Rollup Bridge (validity proofs)           │
│    Trust: math + L1 consensus                          │
│                                                        │
│ 2. ZK Light Client Bridge                             │
│    Trust: ZK soundness + verifier contract correctness │
│                                                        │
│ 3. Optimistic Light Client Bridge (IBC model)         │
│    Trust: honest relayer + fraud proof liveness        │
│                                                        │
│ 4. Canonical Rollup Bridge (optimistic, 7-day window) │
│    Trust: at least one honest challenger online        │
│                                                        │
│ 5. Multisig / MPC Bridge                              │
│    Trust: majority of N signers are honest             │
│                                                        │
│ 6. Liquidity Network + Optimistic Verification        │
│    Trust: solver + fraud proof window                  │
│                                                        │
│ 7. Single Trusted Operator / Custodial                 │
│    Trust: operator honesty                             │
└────────────────────────────────────────────────────────┘
LEAST TRUSTED
```

### 2.1 Trust Assumption Breakdown

| Bridge Type | Validator Set | Consensus | Slashing | Light Client | ZK Proof |
|---|---|---|---|---|---|
| Canonical ZK Rollup | None (math) | N/A | N/A | No | Yes |
| IBC / Light Client | Relayers (no custody) | Source chain | Source chain | Yes | No |
| Optimistic Rollup | Challengers (permissionless) | L1 | N/A | Partial | No |
| Wormhole | 19 Guardians (⅔+1) | Guardian consensus | No slashing | No | No |
| Axelar | Validator set (PoS) | Tendermint | Yes | No | No |
| Multisig (5-of-8) | 8 known parties | Off-chain | No | No | No |
| Centralized | 1 operator | Off-chain | No | No | No |

---

## 3. Light Client Bridges — IBC Model

### 3.1 Architecture

IBC (Inter-Blockchain Communication) is the gold standard for trust-minimised message passing. Each chain runs an on-chain light client of every counterpart chain.

```
Chain A                           Chain B
───────                           ───────
Consensus (validators)            Consensus (validators)

IBC Module                        IBC Module
├── Light Client of B             ├── Light Client of A
│   (tracks B's headers)          │   (tracks A's headers)
├── Connection                    ├── Connection
└── Channel                       └── Channel

Relayer (off-chain, permissionless)
├── fetches headers from A → submits to Light Client on B
├── fetches headers from B → submits to Light Client on A
├── fetches packet commitments → submits with Merkle proofs
```

### 3.2 Header Verification

The light client verifies:
1. Header is signed by ≥ ⅔ of the validator set by stake weight.
2. Validator set hash matches the trusted state.
3. Header height advances monotonically.

```solidity
// Simplified on-chain light client update
function updateClient(
    bytes calldata signedHeader,    // header + validator signatures
    bytes calldata validatorSet,    // current validator set
    bytes calldata trustedConsensusState
) external {
    // 1. Verify validator set matches trusted hash
    require(keccak256(validatorSet) == trustedValHash, "bad validator set");

    // 2. Verify ≥ 2/3 stake signed this header
    uint256 signedPower = 0;
    uint256 totalPower  = 0;
    // ... iterate validators, recover signatures, sum voting power
    require(signedPower * 3 > totalPower * 2, "insufficient signatures");

    // 3. Store new consensus state
    latestConsensusState = keccak256(abi.encode(header.height, header.appHash));
}
```

### 3.3 Packet Verification

After a header is accepted, packets are verified via Merkle inclusion proofs against the accepted `appHash`.

```
Packet commitment on Chain A
    │
    ▼
Merkle proof (ICS-23 spec)
    │
    ▼
Verified against appHash in trusted Light Client state on Chain B
    │
    ▼
Packet processed — acknowledgement sent back to Chain A
```

### 3.4 Relay Networks

Relayers are permissionless: anyone can relay headers and packets. They have no custody of funds. A malicious relayer can delay packets but cannot forge them. Economic incentive: relayer fees paid by applications or protocol treasuries.

---

## 4. Optimistic Bridges

### 4.1 Core Mechanism

Optimistic bridges accept messages immediately but allow a challenge window during which fraud proofs can invalidate fraudulent messages.

```
Relayer posts message M on destination chain
    │
    ▼
Optimistic window opens (e.g., 30 min – 20 hours)
    │
    ├── [No challenge] → window expires → message executed
    │
    └── [Watcher submits fraud proof] → message rejected, relayer slashed
```

### 4.2 Fraud Proof Construction

A fraud proof demonstrates that the message root on the source chain does not contain the claimed message.

```solidity
// Nomad-style fraud proof submission
function proveAndProcess(
    bytes32[32] calldata proof,   // Merkle proof
    bytes calldata message,       // raw message
    uint256 leafIndex
) external {
    bytes32 leaf = keccak256(message);
    bytes32 root = merkleRoot(proof, leaf, leafIndex);

    // Verify root was committed on source (via an accepted snapshot)
    require(acceptedRoots[root], "unknown root");

    // Check not already processed
    bytes32 msgHash = keccak256(message);
    require(!processed[msgHash], "already processed");

    processed[msgHash] = true;
    _handle(message);
}

// Fraud proof: demonstrate committed root ≠ canonical source root
function improperUpdate(
    bytes32 oldRoot,
    bytes32 newRoot,
    bytes calldata signature
) external {
    // Recover signer of (oldRoot, newRoot)
    address signer = recoverSigner(oldRoot, newRoot, signature);
    require(signer == updater, "not updater");

    // If newRoot is not in the canonical root set → fraud
    require(!canonicalRoots[newRoot], "valid update");

    _slashUpdater();
    _pause();
}
```

### 4.3 Watcher Networks

Watchers monitor source chains and submit fraud proofs. Requirements for security:
- At least one watcher must be online and honest during every fraud window.
- Watchers should be geographically and organisationally diverse.
- Watcher incentives: bonds, insurance fees, or protocol grants.

### 4.4 Challenge Window Trade-offs

| Window Duration | Security | UX | Capital Cost |
|---|---|---|---|
| 7 days (OP rollup) | Very high | Poor | High (funds locked) |
| 4 hours (Across) | High (with solver) | Good | Medium |
| 30 minutes (Nomad-style) | Medium (watcher liveness) | Good | Low |
| 0 (instant finality) | Relies on source consensus | Excellent | None |

---

## 5. ZK Bridges

### 5.1 Architecture Overview

ZK bridges replace the fraud-proof window with a validity proof. Messages can be executed as soon as the proof is verified on-chain.

```
Source Chain                   Prover (off-chain)          Destination Chain
────────────                   ──────────────────          ─────────────────
Block N finalised ────────────► ZK circuit:                Verifier contract
                                 - verify N block header    receives proof
                                 - verify validator sigs    ├── verify proof
                                 - verify Merkle path       ├── extract message
                                 → generate SNARK/STARK     └── execute
                                        │
                                        └────────────────►  on-chain verifier
```

### 5.2 Proof Generation

Two dominant approaches:

**Groth16 / PLONK (SNARKs)**
- Trusted setup required (Groth16); universal setup (PLONK/UltraPLONK).
- Proof size: ~200–800 bytes. Verification: ~200k gas.
- Best for stable circuits (validator set changes are expensive to re-prove).

**STARKs / FRI**
- No trusted setup; post-quantum secure.
- Proof size: ~40–200 KB. Verification: ~1–5M gas (often wrapped in SNARK).
- Better for large computation.

### 5.3 Succinct Labs / SP1 Pattern

Succinct's SP1 prover compiles arbitrary Rust programs to ZK circuits. Used in bridges to prove:
1. The consensus of the source chain (e.g., Ethereum's sync committee PoS).
2. Specific storage slot values (Merkle Patricia Trie inclusion).

```
SP1 program (Rust):
    input:  signed beacon block headers
            validator set
    output: verified block hash

On-chain verifier (SP1Verifier):
    verify(proof, publicInputs) → bool

Bridge contract:
    verifyAndStore(proof, blockHash, slot, value, merkleProof) {
        require(SP1Verifier.verify(proof, [blockHash]));
        require(verifyMerkleProof(slot, value, merkleProof, blockHash));
        trustedValues[slot] = value;
    }
```

### 5.4 Polymer Protocol Pattern

Polymer brings IBC to Ethereum by proving Ethereum state (storage proofs) inside IBC light clients on other chains. The source chain's storage slot containing the packet commitment is proven via ZK Ethereum state proof.

### 5.5 On-Chain Verifier Risks

- **Trusted setup compromise**: For Groth16, a backdoored setup allows forged proofs. Mitigate with multi-party ceremony.
- **Soundness bugs in the circuit**: The circuit may accept invalid witnesses. Requires formal verification or extensive auditing.
- **Verifier contract bugs**: An incorrect Solidity implementation of the verifier. Mitigate with auto-generated verifiers from proof system tooling.
- **Upgrade keys**: If the verifier is upgradeable with a short timelock, an attacker with the upgrade key can swap in a trivially-passing verifier.

---

## 6. Bridge Exploit Analysis

### 6.1 Wormhole — February 2022 ($325M)

**Root cause**: Signature verification bypass via deprecated `solana_program::sysvar::instructions` account.

The Wormhole Solana program used `verify_signatures` which checked a system program account to validate guardian signatures. An attacker passed a spoofed system account. The program failed to verify that the account was the actual system program — it only checked the account's data, not its address.

**Lesson**: Always verify account addresses in addition to account data in Solana programs. Never trust `AccountInfo` without checking `key == expected_program_id`.

**Pattern to avoid**:
```rust
// VULNERABLE: only checks data, not address
fn verify_signatures(sysvar_account: &AccountInfo) {
    let data = sysvar_account.data.borrow();
    // parses data but never checks: sysvar_account.key == SYSVAR_INSTRUCTIONS_ID
}
```

**Fix**:
```rust
fn verify_signatures(sysvar_account: &AccountInfo) {
    require!(
        sysvar_account.key == &solana_program::sysvar::instructions::id(),
        "wrong sysvar account"
    );
    // now safe to read data
}
```

### 6.2 Nomad — August 2022 ($190M)

**Root cause**: Initialisation of `confirmAt` mapping with zero value treated as valid.

During a routine upgrade, the zero hash `0x00` was set as a valid root in the `confirmAt` mapping (with a timestamp in the past, meaning immediately valid). Because unset Solidity mappings return zero, any message with any fraudulent root was accepted as proven.

```solidity
// VULNERABLE (simplified):
// confirmAt[bytes32(0)] = 1 (past timestamp) was set during initialisation
function process(bytes memory message) external {
    bytes32 root = messages[keccak256(message)];
    // root is 0x00 for any message not in the mapping
    // confirmAt[0x00] = 1 → passes
    require(confirmAt[root] != 0 && confirmAt[root] <= block.timestamp);
    // executes arbitrary message
}
```

**Lesson**: Zero-value checks in Solidity mappings are a critical invariant. Never allow the zero hash to represent "valid". Use explicit sentinel values. The exploit was copycat — once one person found it, the entire bridge was drained by copy-paste transactions.

### 6.3 Ronin Network — March 2022 ($625M)

**Root cause**: Validator key compromise via social engineering + abandoned validator node.

Ronin used a 5-of-9 multisig. Sky Mavis (Axie Infinity developer) had been granted temporary access to 4 validator keys to handle transaction load. When this arrangement ended, the permission was not revoked. Combined with an Axie DAO validator key compromise via a malicious PDF job offer, the attacker controlled 5 of 9 keys.

**Lesson**: Key hygiene is operational security, not a smart contract problem. Bridge security is only as strong as its weakest key holder. Multisig bridges with small N are critically vulnerable to social engineering and key compromise.

### 6.4 Multichain — July 2023 ($130M)

**Root cause**: CEO arrested; private keys held by a single individual (not distributed MPC as advertised).

The router's MPC keys were allegedly controlled or accessible by the CEO alone. After arrest, funds were moved — either by law enforcement, the CEO, or an insider.

**Lesson**: MPC "decentralisation" must be verifiable. Key generation ceremonies should be auditable. Operational centralisation of ostensibly decentralised bridges is an existential risk.

### 6.5 Poly Network — August 2021 ($611M)

**Root cause**: Logic error in cross-chain manager allowed attacker to call `EthCrossChainData.putCurEpochConPubKeyBytes()` — the function that stores the authorised validator public key.

The attacker crafted a cross-chain message with `toContract = EthCrossChainData` and `method = putCurEpochConPubKeyBytes` with their own key. The bridge executed this message, replacing the trusted validator set with the attacker's key, then withdrawing all funds.

**Lesson**: Bridge contracts must maintain strict call allowlists. Cross-chain messages must never be able to call privileged functions on the bridge's own infrastructure contracts.

```solidity
// FIX PATTERN: block calls to sensitive contracts
function _executeCrossChainTx(
    address toContract,
    bytes calldata method,
    bytes calldata args
) internal {
    // Never allow messages targeting the bridge's own keeper/manager
    require(toContract != address(crossChainManager), "forbidden target");
    require(toContract != address(this), "forbidden target");

    (bool success,) = toContract.call(abi.encodePacked(bytes4(keccak256(method)), args));
    require(success, "execution failed");
}
```

### 6.6 Common Root Cause Taxonomy

| Category | Examples | Mitigations |
|---|---|---|
| Signature verification bypass | Wormhole | Formal verification of signature logic; account address validation |
| Initialisation / storage corruption | Nomad | Immutable initialisation; invariant testing |
| Key compromise / centralisation | Ronin, Multichain | Geographic key distribution; hardware HSMs; timelock on large withdrawals |
| Privileged function exposure | Poly Network | Call allowlists; separated bridge infrastructure contracts |
| Replay attacks | Various | Nonces; chain ID in message hash |
| Reentrancy | Various | CEI pattern; reentrancy guards |

---

## 7. Message Passing Protocols

### 7.1 LayerZero

**Model**: Ultra-Light Node (ULN). Each chain has an endpoint contract. Messages are delivered by two independent parties: a Relayer (delivers message bytes) and an Oracle (delivers block headers). V2 replaces oracle with a configurable DVN (Decentralised Verifier Network) set.

```
Source Chain Endpoint                  Destination Chain Endpoint
─────────────────────                  ──────────────────────────
send(dstChainId, payload) ────────────► lzReceive(srcChainId, srcAddr, payload)
    │                                            ▲
    ├──► Oracle/DVN delivers block hash ─────────┤
    └──► Relayer delivers proof + payload ───────┘
         (both must agree)
```

**Security**: Configurable DVN set per OApp. Default config uses LayerZero Labs DVN + a secondary. Custom apps should configure reputable secondary DVNs and set `requiredDVNCount` ≥ 2.

**V2 OApp receiver pattern**:
```solidity
import { OApp, Origin, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";

contract MyOApp is OApp {
    constructor(address _endpoint, address _owner)
        OApp(_endpoint, _owner) {}

    function _lzReceive(
        Origin calldata _origin,       // srcEid, sender, nonce
        bytes32 /*_guid*/,
        bytes calldata _message,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        // ALWAYS verify the source
        require(_origin.srcEid == TRUSTED_SOURCE_EID, "wrong source chain");
        require(
            _origin.sender == bytes32(uint256(uint160(TRUSTED_SOURCE_CONTRACT))),
            "wrong source contract"
        );
        // decode and process
        (address recipient, uint256 amount) = abi.decode(_message, (address, uint256));
        _mint(recipient, amount);
    }
}
```

### 7.2 Hyperlane

**Model**: Modular security. Sovereign consensus; anyone can permissionlessly deploy Hyperlane. Security is determined by the Interchain Security Module (ISM) configured on the mailbox.

```
Mailbox (source) ──► Dispatch event
                          │
                     Relayer picks up
                          │
                     Mailbox (dest) ──► ISM.verify(metadata, message)
                                              │ (multisig ISM, aggregation ISM,
                                              │  optimistic ISM, ZK ISM)
                                        IMessageRecipient.handle(origin, sender, body)
```

**ISM types**:
- `MultisigISM`: N-of-M threshold on validator signatures.
- `AggregationISM`: Require M-of-N sub-ISMs to approve (e.g., multisig AND watcher).
- `OptimisticISM`: Optimistic with fraud window; watchers can veto.
- `RoutingISM`: Different ISMs per source chain.

**Receiver**:
```solidity
import { IMessageRecipient } from "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";

contract MyHyperlaneReceiver is IMessageRecipient {
    address public immutable MAILBOX;

    modifier onlyMailbox() {
        require(msg.sender == MAILBOX, "not mailbox");
        _;
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external onlyMailbox {
        require(_origin == TRUSTED_ORIGIN_DOMAIN, "wrong domain");
        require(_sender == bytes32(uint256(uint160(TRUSTED_SENDER))), "wrong sender");
        // process _message
    }
}
```

### 7.3 Axelar

**Model**: Proof-of-Stake validator network with Tendermint consensus. Validators run full nodes of connected chains. Messages are verified by validator consensus on the Axelar network, then executed on destination via gateway contracts.

```
Source Gateway.callContract(destChain, destAddr, payload)
    │
    ▼
Axelar validators observe + vote (≥ ⅔ by stake)
    │
    ▼
Approved command written to Axelar chain
    │
    ▼
Relayer calls destination Gateway.execute(commandId, sourceChain, sourceAddr, payload)
    │
    ▼
IAxelarExecutable.execute(commandId, sourceChain, sourceAddr, payload)
```

**Receiver**:
```solidity
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";

contract MyAxelarReceiver is AxelarExecutable {
    constructor(address gateway) AxelarExecutable(gateway) {}

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        require(
            keccak256(bytes(sourceChain)) == keccak256(bytes("Ethereum")),
            "wrong chain"
        );
        require(
            keccak256(bytes(sourceAddress)) == keccak256(bytes(TRUSTED_SOURCE)),
            "wrong sender"
        );
        // process payload
    }
}
```

### 7.4 Chainlink CCIP

**Model**: Decentralised Oracle Networks (DON) plus a separate Risk Management Network (RMN) that provides an independent blessing/cursing layer. Two independent DONs must agree; RMN can curse (pause) a lane.

```
OnRamp (source) ──► Committing DON (posts merkle root to dest)
                ──► Executing DON  (executes messages + token transfers)
                ──► Risk Management Network (blesses committed roots or curses lanes)
```

**CCIP Receiver**:
```solidity
import { CCIPReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract MyCCIPReceiver is CCIPReceiver {
    bytes32 public constant TRUSTED_SENDER = keccak256("0xTrustedSender");

    constructor(address router) CCIPReceiver(router) {}

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        require(message.sourceChainSelector == TRUSTED_CHAIN_SELECTOR, "wrong chain");
        require(
            keccak256(message.sender) == keccak256(abi.encode(TRUSTED_SENDER_ADDRESS)),
            "wrong sender"
        );
        // process message.data
    }
}
```

### 7.5 Wormhole (Post-Exploit)

**Model**: 19 Guardians run full nodes on all connected chains. ≥13 of 19 must sign a Verifiable Action Approval (VAA). Wormhole v2 added Guardian set rotation.

**VAA structure**:
```
Header: version, guardian_set_index, signatures (13+)
Body:   timestamp, nonce, emitter_chain, emitter_address,
        sequence, consistency_level, payload
```

**Receiver (EVM)**:
```solidity
interface IWormhole {
    function parseAndVerifyVM(bytes calldata encodedVM)
        external view
        returns (IWormhole.VM memory vm, bool valid, string memory reason);
}

contract MyWormholeReceiver {
    IWormhole public immutable wormhole;
    mapping(bytes32 => bool) public processedVAAs;

    constructor(address _wormhole) { wormhole = IWormhole(_wormhole); }

    function receiveMessage(bytes calldata encodedVAA) external {
        (IWormhole.VM memory vm, bool valid, string memory reason)
            = wormhole.parseAndVerifyVM(encodedVAA);

        require(valid, reason);
        // Replay protection
        require(!processedVAAs[vm.hash], "already processed");
        processedVAAs[vm.hash] = true;

        // Source verification
        require(vm.emitterChainId == TRUSTED_EMITTER_CHAIN, "wrong chain");
        require(vm.emitterAddress == TRUSTED_EMITTER_ADDRESS, "wrong emitter");

        _process(vm.payload);
    }
}
```

### 7.6 Protocol Comparison

| Protocol | Security Model | Speed | Token Transfers | GMP | Permissionless Deploy |
|---|---|---|---|---|---|
| LayerZero V2 | Configurable DVN | Fast | OFT | Yes | Yes |
| Hyperlane | Modular ISM | Fast | Yes (HypERC20) | Yes | Yes |
| Axelar | PoS validator set | Medium | Yes | Yes | Yes (via Axelar) |
| CCIP | DON + RMN | Medium | Yes | Yes | No (whitelisted) |
| Wormhole | 19 Guardians | Fast | Yes | Yes | Yes |
| IBC | Light clients | Fast | ICS-20 | Yes | Yes (Cosmos) |

---

## 8. Building Secure Cross-Chain Applications

### 8.1 Message Validation Checklist

Every cross-chain message receiver must validate:

```
[ ] 1. msg.sender == bridge contract (not any EOA)
[ ] 2. Source chain ID / domain matches expected value
[ ] 3. Source contract address matches trusted sender
[ ] 4. Message has not been processed before (replay protection)
[ ] 5. Nonce is sequential if ordering matters
[ ] 6. Payload length and structure validated before decoding
[ ] 7. Value amounts are within expected ranges
[ ] 8. Recipient addresses are non-zero
[ ] 9. Reentrancy guard on handler function
[ ] 10. Pause mechanism exists for emergency
```

### 8.2 Replay Protection

Every message must include a unique identifier that is stored after processing.

```solidity
// Pattern 1: hash-based (order-agnostic)
mapping(bytes32 => bool) public executed;

function execute(bytes calldata message) external {
    bytes32 id = keccak256(message); // message must include nonce/sequence
    require(!executed[id], "replay");
    executed[id] = true;
    _handle(message);
}

// Pattern 2: per-sender nonce (enforces ordering)
mapping(uint32 => mapping(bytes32 => uint64)) public nextNonce;
// [srcChain][srcAddress] => expected nonce

function execute(uint32 srcChain, bytes32 srcAddr, uint64 nonce, bytes calldata payload)
    external
{
    require(nonce == nextNonce[srcChain][srcAddr], "wrong nonce");
    nextNonce[srcChain][srcAddr]++;
    _handle(payload);
}
```

### 8.3 Source Chain Verification — Layered Pattern

```solidity
abstract contract CrossChainReceiver {
    address public immutable BRIDGE;
    uint256 public immutable TRUSTED_CHAIN_ID;
    address public immutable TRUSTED_SENDER;

    mapping(bytes32 => bool) private _executed;

    modifier onlyBridge() {
        require(msg.sender == BRIDGE, "CCR: not bridge");
        _;
    }

    modifier validSource(uint256 srcChain, address srcSender) {
        require(srcChain == TRUSTED_CHAIN_ID, "CCR: wrong chain");
        require(srcSender == TRUSTED_SENDER,   "CCR: wrong sender");
        _;
    }

    modifier noReplay(bytes32 msgId) {
        require(!_executed[msgId], "CCR: replay");
        _executed[msgId] = true;
        _;
    }

    // Override in subclass; call with all three modifiers
    function _handleMessage(
        uint256 srcChain,
        address srcSender,
        bytes32 msgId,
        bytes calldata payload
    ) internal virtual;
}
```

### 8.4 Rate Limiting and Circuit Breakers

Large bridges should implement per-period rate limits to cap damage from exploits.

```solidity
contract RateLimitedBridge {
    uint256 public constant PERIOD   = 1 days;
    uint256 public constant MAX_FLOW = 1_000_000e6; // $1M USDC per day

    uint256 public periodStart;
    uint256 public flowInPeriod;

    function _checkAndUpdateRateLimit(uint256 amount) internal {
        if (block.timestamp >= periodStart + PERIOD) {
            periodStart  = block.timestamp;
            flowInPeriod = 0;
        }
        flowInPeriod += amount;
        require(flowInPeriod <= MAX_FLOW, "rate limit exceeded");
    }
}
```

### 8.5 Timelock on Large Withdrawals

```solidity
mapping(bytes32 => uint256) public pendingWithdrawals; // msgHash => earliest execution time

function queueLargeWithdrawal(bytes32 msgHash, address recipient, uint256 amount) internal {
    if (amount > LARGE_WITHDRAWAL_THRESHOLD) {
        pendingWithdrawals[msgHash] = block.timestamp + WITHDRAWAL_DELAY;
        emit WithdrawalQueued(msgHash, recipient, amount);
    } else {
        _executeWithdrawal(recipient, amount);
    }
}

function executeQueuedWithdrawal(bytes32 msgHash, address recipient, uint256 amount)
    external
{
    require(pendingWithdrawals[msgHash] != 0, "not queued");
    require(block.timestamp >= pendingWithdrawals[msgHash], "not ready");
    delete pendingWithdrawals[msgHash];
    _executeWithdrawal(recipient, amount);
}
```

### 8.6 Emergency Pause

Every bridge contract and cross-chain application should be pauseable by a trusted guardian (multisig or automated watcher).

```solidity
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

contract SecureBridgeReceiver is Pausable {
    address public guardian; // multisig

    modifier onlyGuardian() { require(msg.sender == guardian, "not guardian"); _; }

    function pause()   external onlyGuardian { _pause(); }
    function unpause() external onlyGuardian { _unpause(); }

    function receiveMessage(bytes calldata message)
        external
        whenNotPaused
    {
        // ...
    }
}
```

---

## 9. Canonical Rollup Bridges

### 9.1 Optimism Bridge Architecture

```
L2 (OP Chain)                              L1 (Ethereum)
─────────────                              ─────────────
L2ToL1MessagePasser                        OptimismPortal
    │                                           │
    │ withdrawal initiated                      │
    │ (stored in L2 state)                      │
    ▼                                           │
L2OutputOracle ────── output root ────────────► │
(posted by proposer every ~1 hour)              │
                                           [7 day window]
                                                │
                                           proveWithdrawal(
                                               outputRootProof,
                                               withdrawalProof
                                           )
                                                │
                                           [wait 7 days after proof]
                                                │
                                           finalizeWithdrawal()
                                                │
                                           L1CrossDomainMessenger
                                                │
                                           Target contract called
```

**Withdrawal steps**:
1. Initiate on L2: `L2ToL1MessagePasser.initiateWithdrawal(target, gasLimit, data)`.
2. Wait for output root to be posted to L2OutputOracle (~1 hour).
3. Prove withdrawal on L1: `OptimismPortal.proveWithdrawal(...)`.
4. Wait 7 days for challenge window.
5. Finalise: `OptimismPortal.finalizeWithdrawal(...)`.

### 9.2 Arbitrum Bridge Architecture

Arbitrum uses a different two-phase exit:

```
L2 Arbitrum                               L1 Ethereum
───────────                               ───────────
ArbSys.sendTxToL1(dest, data)
    │
    ▼
Outbox merkle tree (leaf added)
    │
State confirmed on L1 (after 7 days / challenge)
    │
    ▼
                                    Outbox.executeTransaction(
                                        proof, index, l2Sender,
                                        dest, l2Block, l1Block,
                                        timestamp, value, data
                                    )
```

For ERC-20 tokens, the canonical path is `L2GatewayRouter` → `L1GatewayRouter` → `L1ERC20Gateway`.

### 9.3 ZK Rollup Bridges (zkSync Era, Polygon zkEVM)

ZK rollup bridges do not need a 7-day window. Withdrawal is finalised when the validity proof is verified on L1.

```
L2 (zkSync Era)                           L1 (Ethereum)
───────────────                           ─────────────
withdraw(token, amount, recipient)
    │
    ▼
Batch posted to L1 DiamondProxy
    │
ZK proof generated (hours off-chain)
    │
    ▼
                                    DiamondProxy.proveBatches(proof)
                                    → verifyBatchProof() succeeds
                                    → withdrawal finalised
                                    → user calls finalizeEthWithdrawal()
```

**Withdrawal latency comparison**:
| Bridge | Typical Finality | Trust Model |
|---|---|---|
| Optimism / Base | 7 days | Optimistic; honest challenger |
| Arbitrum One | 7 days | Optimistic; honest challenger |
| zkSync Era | 1–24 hours | ZK validity proof |
| Polygon zkEVM | 1–24 hours | ZK validity proof |
| Starknet | 1–24 hours | ZK validity proof |

### 9.4 Fast Withdrawal Services

Third-party liquidity providers (e.g., Across, Hop) offer fast withdrawals from optimistic rollups by front-running the slow canonical path:

1. LP provides funds immediately on L1 against a claim on the L2 withdrawal.
2. After 7-day window, LP claims the canonical withdrawal to replenish liquidity.
3. User pays a fee (spread) for the liquidity.

---

## 10. Cross-Chain Token Standards

### 10.1 xERC20 (ERC-7281)

xERC20 defines a standard interface for tokens that can be minted and burned by multiple bridges, with per-bridge rate limits enforced at the token level.

```solidity
interface IXERC20 {
    // Set mint/burn limits for a specific bridge
    function setLimits(address bridge, uint256 mintingLimit, uint256 burningLimit) external;

    // Called by bridge contracts
    function mint(address user, uint256 amount) external;
    function burn(address user, uint256 amount) external;

    // Inspect current limits
    function mintingCurrentLimitOf(address bridge) external view returns (uint256);
    function burningCurrentLimitOf(address bridge) external view returns (uint256);
}
```

**Key properties**:
- Token issuer retains control over which bridges can mint/burn and at what rate.
- Limits replenish over time (sliding window, e.g., 24 hours).
- Multiple bridges can be authorised simultaneously → no single bridge monopoly.
- Limit breach reverts the bridge transaction, not a global pause.

**Implementation pattern (Superchain xERC20)**:
```solidity
// Per-bridge rate limit enforcement
function mint(address _user, uint256 _amount) external {
    uint256 currentLimit = mintingCurrentLimitOf(msg.sender);
    require(_amount <= currentLimit, "exceeds mint limit");
    _useMinterLimits(msg.sender, _amount);
    _mint(_user, _amount);
}

function _useMinterLimits(address _bridge, uint256 _amount) internal {
    uint256 elapsed   = block.timestamp - bridges[_bridge].lastUpdated;
    uint256 replenish = (bridges[_bridge].maxLimit * elapsed) / _DURATION;
    uint256 newCurrent = bridges[_bridge].currentLimit + replenish;
    if (newCurrent > bridges[_bridge].maxLimit) newCurrent = bridges[_bridge].maxLimit;
    bridges[_bridge].currentLimit  = newCurrent - _amount;
    bridges[_bridge].lastUpdated   = block.timestamp;
}
```

### 10.2 LayerZero OFT (Omnichain Fungible Token)

OFT integrates the burn-and-mint model directly into the token contract. Sending across chains burns on source and mints on destination, mediated by LayerZero.

```solidity
import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

contract MyToken is OFT {
    constructor(
        string memory name,
        string memory symbol,
        address lzEndpoint,
        address owner
    ) OFT(name, symbol, lzEndpoint, owner) {}

    // send() inherited: burns locally, sends LZ message, mints on dest
}
```

**OFT send flow**:
```
MyToken.send(SendParam{dstEid, to, amountLD, minAmountLD, ...}, fee, refundAddress)
    │
    ├── _debit(msg.sender, amountSentLD, minAmountLD, dstEid)  // burns tokens
    │
    └── _lzSend(dstEid, message, options, fee, refundAddress) // LZ message
            │
            ▼ (destination)
        _lzReceive → _credit(recipient, amount)  // mints tokens
```

### 10.3 Wrapped Tokens (Legacy)

Simple lock-and-mint wrappers with a trusted bridge operator. The main risk is that the operator can mint unbacked tokens. Avoid for new designs; prefer xERC20 or OFT which give the token issuer control.

### 10.4 Comparison

| Standard | Canonical Supply | Multi-Bridge | Rate Limits | Issuer Control |
|---|---|---|---|---|
| xERC20 (ERC-7281) | Distributed | Yes | Yes (per bridge) | Full |
| OFT (LayerZero) | Distributed (burn/mint) | Via LZ only | No native | Partial |
| CCTP (Circle USDC) | Distributed (burn/mint) | CCTP only | Yes | Full (Circle) |
| Wrapped (wETH, etc.) | Single vault | No | No | Operator only |

---

## 11. Cross-Chain Governance

### 11.1 Multi-Chain DAO Architecture

A cross-chain DAO has governance state (votes, proposals, execution) distributed across multiple chains.

```
Hub Chain (Governance)              Spoke Chains (Execution)
──────────────────────              ────────────────────────
Governor contract                   TimelockController (each chain)
├── Proposal created                      │
├── Voting (token holders on hub)         │
├── Proposal passes                       │
│                                         │
└── Dispatch via bridge ─────────────────► Timelock queues action
                                          │
                                    [delay expires]
                                          │
                                    Target contract called
```

### 11.2 Vote Aggregation

For DAOs where token holders are on multiple chains, votes must be aggregated cross-chain before the hub tallies.

**Option A — Hub-and-spoke (simple)**:
- Voting token lives on hub chain only.
- Users bridge tokens to hub to vote.
- Execution dispatched to spokes.

**Option B — Cross-chain vote collection**:
- Voting occurs on each chain.
- Vote counts sent to hub via bridge before proposal deadline.
- Hub tallies and executes.
- Risk: bridge liveness during voting window.

### 11.3 Timelock on Spoke Chains

Cross-chain governance should use a timelock on spoke chains to give communities time to react to malicious proposals.

```solidity
contract CrossChainTimelock is TimelockController {
    address public immutable BRIDGE;
    uint32  public immutable HUB_CHAIN;
    address public immutable HUB_GOVERNOR;

    function queueFromHub(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) external onlyBridge onlyFromHub {
        // validate bridge sender is hub governor
        _schedule(target, value, data, predecessor, salt, delay);
    }

    modifier onlyBridge() {
        require(msg.sender == BRIDGE, "not bridge");
        _;
    }

    modifier onlyFromHub() {
        // bridge-specific source check (varies by protocol)
        _;
    }
}
```

### 11.4 Security Considerations for Cross-Chain Governance

```
[ ] Timelock delay on spoke chains is at least as long as on hub
[ ] Bridge used for governance dispatch is trust-minimised (not multisig)
[ ] Proposal calldata is hashed on source; verified on destination
[ ] Emergency veto mechanism exists on each spoke
[ ] Bridge failure does not deadlock governance (fallback admin key?)
[ ] Large treasury actions require additional confirmations
[ ] Cancel mechanism exists for queued (but not yet executed) proposals
```

---

## 12. Testing Cross-Chain Applications

### 12.1 Fork Testing Multiple Chains (Foundry)

Foundry supports multiple active forks in a single test. Switch between forks with `vm.selectFork()`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

contract CrossChainForkTest is Test {
    uint256 ethFork;
    uint256 arbFork;

    address constant ETH_BRIDGE = 0x...;
    address constant ARB_BRIDGE = 0x...;

    function setUp() public {
        ethFork = vm.createFork(vm.envString("ETH_RPC_URL"), 19_000_000);
        arbFork = vm.createFork(vm.envString("ARB_RPC_URL"), 180_000_000);
    }

    function test_crossChainTransfer() public {
        // Act on Ethereum
        vm.selectFork(ethFork);
        vm.startPrank(user);
        IERC20(USDC_ETH).approve(ETH_BRIDGE, 1000e6);
        IBridge(ETH_BRIDGE).send{value: relayerFee}(
            ARB_CHAIN_ID, recipient, 1000e6
        );
        vm.stopPrank();

        // Simulate relay: capture emitted message
        bytes memory message = _captureLastBridgeMessage();

        // Deliver on Arbitrum
        vm.selectFork(arbFork);
        IBridge(ARB_BRIDGE).receiveMessage(message);

        // Assert recipient received funds
        assertEq(IERC20(USDC_ARB).balanceOf(recipient), 1000e6);
    }
}
```

### 12.2 Mock Relayer Pattern

For unit tests, replace the bridge with a mock that stores outbound messages and delivers them on demand.

```solidity
contract MockBridge {
    struct QueuedMessage {
        uint256 destChain;
        address destContract;
        bytes   payload;
    }

    QueuedMessage[] public queue;

    // Simulates outbound send — stores message
    function send(uint256 destChain, address destContract, bytes calldata payload)
        external payable
    {
        queue.push(QueuedMessage(destChain, destContract, payload));
    }

    // Test helper: deliver all queued messages
    function relayAll() external {
        for (uint256 i = 0; i < queue.length; i++) {
            QueuedMessage memory m = queue[i];
            // Call the destination contract's receive function
            (bool ok,) = m.destContract.call(
                abi.encodeWithSignature(
                    "receiveMessage(uint256,address,bytes)",
                    block.chainid, // source chain (this test environment)
                    address(this),
                    m.payload
                )
            );
            require(ok, "delivery failed");
        }
        delete queue;
    }

    function queueLength() external view returns (uint256) {
        return queue.length;
    }
}
```

### 12.3 Mock LayerZero Endpoint (OFT Testing)

LayerZero provides `TestHelper` and mock endpoints for OApp unit tests.

```solidity
import { TestHelper } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelper.sol";

contract OFTTest is TestHelper {
    uint32 constant EID_ETH = 1;
    uint32 constant EID_ARB = 110;

    MyToken tokenA;
    MyToken tokenB;

    function setUp() public override {
        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        tokenA = MyToken(_deployOApp(type(MyToken).creationCode, abi.encode(
            "MyToken", "MTK", address(endpoints[EID_ETH]), address(this)
        )));
        tokenB = MyToken(_deployOApp(type(MyToken).creationCode, abi.encode(
            "MyToken", "MTK", address(endpoints[EID_ARB]), address(this)
        )));

        address[] memory ofts = new address[](2);
        ofts[0] = address(tokenA);
        ofts[1] = address(tokenB);
        this.wireOApps(ofts);
    }

    function test_sendOFT() public {
        deal(address(tokenA), alice, 100e18);
        vm.startPrank(alice);
        tokenA.approve(address(tokenA), 100e18);

        (MessagingFee memory fee,) = tokenA.quoteSend(
            SendParam(EID_ARB, bytes32(uint256(uint160(bob))), 100e18, 100e18, "", "", ""),
            false
        );
        tokenA.send{value: fee.nativeFee}(
            SendParam(EID_ARB, bytes32(uint256(uint160(bob))), 100e18, 100e18, "", "", ""),
            fee, alice
        );
        vm.stopPrank();

        // Deliver via mock endpoint
        verifyPackets(EID_ARB, addressToBytes32(address(tokenB)));

        assertEq(tokenA.balanceOf(alice), 0);
        assertEq(tokenB.balanceOf(bob), 100e18);
    }
}
```

### 12.4 Invariant Testing for Cross-Chain Token Supply

```solidity
contract OFTInvariantTest is Test {
    MyToken tokenA;
    MyToken tokenB;
    MockBridge bridge;

    function invariant_totalSupplyConserved() public {
        // Sum of supplies across all chains must equal initial mint
        uint256 totalSupply = tokenA.totalSupply() + tokenB.totalSupply();
        assertEq(totalSupply, INITIAL_SUPPLY, "supply not conserved");
    }

    function invariant_noPendingMessages_impliesSupplyConserved() public {
        if (bridge.queueLength() == 0) {
            invariant_totalSupplyConserved();
        }
    }
}
```

### 12.5 Security Testing Checklist for Cross-Chain Apps

```
Source chain verification
[ ] Test: message from wrong chain rejected
[ ] Test: message from right chain, wrong contract rejected
[ ] Test: message from right chain, right contract accepted

Replay protection
[ ] Test: same message submitted twice → second reverts
[ ] Test: different messages with same payload but different nonces → both succeed
[ ] Test: nonce gap rejected (if sequential nonces enforced)

Amount validation
[ ] Test: amount = 0 handled correctly (reject or no-op)
[ ] Test: amount > balance → bridge-level or token-level revert
[ ] Test: overflow in amount arithmetic

Reentrancy
[ ] Test: malicious receiver contract that calls back into bridge
[ ] Verify: state updated before external call (CEI pattern)

Pause / emergency
[ ] Test: messages rejected when paused
[ ] Test: only guardian can pause / unpause

Rate limits (if applicable)
[ ] Test: limit not exceeded → succeeds
[ ] Test: limit exceeded → reverts
[ ] Test: limit replenishes after period
[ ] Test: multiple bridges share limits correctly (xERC20)

Governance (if applicable)
[ ] Test: proposal dispatched from hub arrives on spoke
[ ] Test: spoke rejects proposal from non-hub source
[ ] Test: timelock delay enforced on spoke
[ ] Test: cancelled proposal cannot be executed
```

---

## 13. Security Architecture Patterns — Summary

### 13.1 Defence-in-Depth Stack

```
Layer 6: Rate limits + timelocks (damage control)
    ▲
Layer 5: Pause / emergency mechanisms (rapid response)
    ▲
Layer 4: Cross-chain message validation (source + replay)
    ▲
Layer 3: Bridge-level security (DVNs, ISMs, validators)
    ▲
Layer 2: Smart contract correctness (audits, formal verification)
    ▲
Layer 1: Key management (HSMs, geographic distribution, rotation)
```

### 13.2 Bridge Selection Decision Tree

```
Need to move value cross-chain?
    │
    ├─► Is destination a rollup of the source chain?
    │       └─► YES → Use canonical rollup bridge
    │               (if 7-day delay acceptable → Optimism/Arbitrum)
    │               (if fast finality needed → ZK rollup)
    │
    ├─► Is this a Cosmos ecosystem?
    │       └─► YES → Use IBC (trust-minimised light client)
    │
    ├─► Is this a new token you control?
    │       └─► YES → Implement xERC20 (multi-bridge, rate-limited)
    │               OR OFT (LayerZero-native, simpler)
    │
    └─► Third-party bridge needed?
            ├─► Maximum security → CCIP (DON + RMN) or Hyperlane (ZK ISM)
            ├─► Best ecosystem coverage → LayerZero V2 (configure 2+ DVNs)
            ├─► PoS validator set → Axelar
            └─► Avoid: anonymous multisig, single-operator bridges
```

### 13.3 Upgrade Safety

```solidity
// Any bridge contract with an upgrade key is only as safe as that key
// Minimum safe upgrade configuration:

// 1. Timelock on all upgrades (≥ 2 days for bridges; ≥ 7 days for large TVL)
// 2. Multisig on the timelock proposer/executor (≥ 5-of-9)
// 3. Public announcement of upgrade before timelock expires
// 4. Ability for users to exit before upgrade takes effect

// Red flags:
// - upgradeToAndCall() callable by a single EOA
// - Proxy admin = deployer address
// - No timelock
// - Upgrade key held by anonymous team members
```

---

## 14. Quick Reference — Gas Costs

| Operation | Approximate Gas | Notes |
|---|---|---|
| LayerZero send (EVM→EVM) | 150k–300k source | DVN fees separate |
| Axelar execute | 100k–200k dest | Depends on payload |
| CCIP send | 200k–400k source | Includes token transfer |
| Wormhole publish message | 50k source | VAA verification ~100k dest |
| IBC (Cosmos) | ~200k source | Varies by chain |
| Groth16 proof verify (EVM) | ~200k | Constant |
| PLONK proof verify (EVM) | ~300k | Constant |
| Optimism withdrawal prove | ~300k | One-time per withdrawal |
| Optimism withdrawal finalise | ~100k | After 7-day window |

---

## Key Takeaways

1. **Trust assumptions are the primary security variable.** Choose the bridge type that matches the value at risk. Never use a 5-of-9 multisig bridge for hundreds of millions of dollars.

2. **Validate every dimension of every message**: caller address, source chain, source contract, nonce, payload structure.

3. **All major bridge exploits trace to one of**: key compromise, signature verification bypass, initialisation error, or privileged function exposure via cross-chain message.

4. **Rate limits and timelocks are non-negotiable** for any bridge handling >$1M TVL. They are the last line of defence when everything else fails.

5. **ZK bridges are the long-term direction** but introduce new risks: circuit soundness bugs and trusted setup compromise. Use battle-tested verifier implementations.

6. **xERC20 (ERC-7281) is the correct standard** for new cross-chain tokens. It gives the token issuer control over which bridges can mint and at what rate, breaking the dependency on any single bridge's security model.

7. **Test cross-chain apps with Foundry multi-fork and mock relayers.** Invariant: total token supply across all chains must be conserved at all times.
