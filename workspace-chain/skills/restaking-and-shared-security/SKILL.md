# Restaking & Shared Security

## Mental Model

Restaking lets ETH (or LSTs) that already secures Ethereum consensus be pledged as cryptoeconomic collateral for additional services. The same stake can be slashed by multiple parties simultaneously. This creates a security marketplace: operators rent pooled stake to new protocols that cannot yet bootstrap their own validator set. The core tension is yield amplification vs. cascading slashing risk.

---

## 1. EigenLayer Architecture

### Core Contract Topology

```
                        ┌─────────────────────────────────────────────────┐
                        │                   EigenLayer Core                │
                        │                                                   │
                        │  ┌─────────────┐     ┌──────────────────────┐   │
                        │  │StrategyMgr  │────▶│  Strategy Contracts  │   │
                        │  │             │     │  (wstETH, rETH, cbETH│   │
                        │  │ - deposit() │     │   stETH, EIGEN, etc) │   │
                        │  │ - withdraw()│     └──────────────────────┘   │
                        │  └──────┬──────┘                                 │
                        │         │ shares                                  │
                        │  ┌──────▼──────────────┐                        │
                        │  │  DelegationManager   │                        │
                        │  │                      │                        │
                        │  │ - delegateTo()       │                        │
                        │  │ - undelegate()       │◀──── Operators         │
                        │  │ - queueWithdrawal()  │                        │
                        │  └──────────────────────┘                        │
                        │         │                                         │
                        │  ┌──────▼──────────────┐                        │
                        │  │       Slasher        │                        │
                        │  │                      │◀──── AVS Contracts     │
                        │  │ - freezeOperator()   │                        │
                        │  │ - resetFrozenStatus()│                        │
                        │  └──────────────────────┘                        │
                        │                                                   │
                        │  ┌──────────────────────┐                        │
                        │  │    EigenPodManager   │  (native restaking)   │
                        │  │                      │                        │
                        │  │ - createPod()        │                        │
                        │  │ - verifyWithdrawal() │                        │
                        │  └──────────────────────┘                        │
                        └─────────────────────────────────────────────────┘
                                      │
                         ┌────────────▼──────────────┐
                         │      AVS Registry          │
                         │                            │
                         │ - registerOperatorToAVS()  │
                         │ - deregisterOperator()     │
                         │ - updateOperatorMetadata() │
                         └────────────────────────────┘
```

### StrategyManager

Manages deposits of LSTs and other ERC-20 tokens into Strategy contracts. Each Strategy wraps a single token and tracks exchange rates (shares vs. underlying).

Key invariants:
- `stakerStrategyShares[staker][strategy]` — shares owned per staker per strategy
- Shares are non-transferable within StrategyManager (transferability lives in LRTs above it)
- Withdrawal is a two-phase process: queue + complete after `withdrawalDelayBlocks`

```solidity
interface IStrategyManager {
    function depositIntoStrategy(
        IStrategy strategy,
        IERC20 token,
        uint256 amount
    ) external returns (uint256 shares);

    function queueWithdrawal(
        uint256[] calldata strategyIndexes,
        IStrategy[] calldata strategies,
        uint256[] calldata shares,
        address withdrawer,
        bool undelegateIfPossible
    ) external returns (bytes32 withdrawalRoot);

    function completeQueuedWithdrawal(
        IDelegationManager.Withdrawal calldata withdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    ) external;
}
```

### DelegationManager

Operators register once, then stakers delegate their strategy shares. Delegation is all-or-nothing per operator — you cannot split across multiple operators. Undelegation queues all shares for withdrawal.

```solidity
interface IDelegationManager {
    struct OperatorDetails {
        address earningsReceiver;
        address delegationApprover;   // optional: gatekeep who can delegate
        uint32  stakerOptOutWindowBlocks;
    }

    function registerAsOperator(
        OperatorDetails calldata registeringOperatorDetails,
        string calldata metadataURI
    ) external;

    function delegateTo(
        address operator,
        SignatureWithExpiry memory approverSignatureAndExpiry,
        bytes32 approverSalt
    ) external;

    function undelegate(address staker) external returns (bytes32[] memory withdrawalRoots);

    // Called by AVS registry to get operator's total delegated shares
    function operatorShares(
        address operator,
        IStrategy strategy
    ) external view returns (uint256);
}
```

### Slasher (v1 / ELIP-002 Slashing)

The original Slasher was a "freeze" mechanism — it could freeze operators, blocking withdrawals but not actually burning stake. True slashing (destructive, burning tokens) was introduced in the ELIP-002 upgrade.

ELIP-002 Slashing model:
- Each AVS defines a `SlashingParams` struct with `wadsToSlash` per strategy
- Slashing is executed via `AllocationManager.slashOperator()`
- Operators pre-allocate "slashable magnitude" to each AVS — this bounds their exposure
- `ALLOCATION_CONFIGURATION_DELAY` = 21 days before new allocations are active

```solidity
interface IAllocationManager {
    struct SlashingParams {
        address operator;
        uint32  operatorSetId;
        IStrategy[] strategies;
        uint256[] wadsToSlash;      // 1e18 = 100%
        string description;
    }

    function slashOperator(
        address avs,
        SlashingParams calldata params
    ) external;

    function modifyAllocations(
        MagnitudeAllocation[] calldata allocations
    ) external;
}
```

### AVS Registry Contracts

Every AVS deploys (or inherits):
1. `ServiceManagerBase` — integrates with EigenLayer core, handles deregistration
2. `RegistryCoordinator` — BLS key registry + operator set management
3. `BLSApkRegistry` — aggregated BLS public keys per quorum
4. `StakeRegistry` — tracks operator stake weights
5. `IndexRegistry` — ordered operator list for gas-efficient iteration

```
Operator ──registerOperatorWithSignature()──▶ RegistryCoordinator
                                                      │
                                         ┌────────────┼────────────┐
                                         ▼            ▼            ▼
                                   BLSApkReg    StakeReg      IndexReg
```

### Operator Lifecycle

```
1. registerAsOperator(details)          ← DelegationManager
2. opt into AVS slashing                ← AllocationManager
3. registerOperatorToAVS(sig)           ← AVSDirectory
4. registerOperatorWithCoordinator()    ← RegistryCoordinator (AVS-side)
   - provide BLS key
   - join quorums
5. receive tasks, submit responses
6. [optional] deregisterOperator()
7. undelegate() → queued withdrawal
8. completeQueuedWithdrawal() after delay
```

---

## 2. AVS Design Patterns

### Task-Based AVS (Oracle / Computation)

The canonical pattern: a contract posts tasks on-chain, operators perform off-chain work, submit responses with BLS signatures, a threshold check validates aggregated signatures.

```
TaskCreator ──createNewTask()──▶ TaskManager (on-chain)
                                       │
                          off-chain notification (events)
                                       │
                              Operators (n of them)
                              - fetch task
                              - compute result
                              - sign(taskHash, result)
                                       │
                              Aggregator service
                              - collect signatures
                              - verify BLS aggregate
                                       │
                    respondToTask(aggSig, nonSignerPubkeys)
                                       │
                               TaskManager validates:
                               - quorum threshold met?
                               - response window not expired?
                               - record response
```

```solidity
interface IServiceManager {
    struct Task {
        bytes   taskData;
        uint32  taskCreatedBlock;
        bytes   quorumNumbers;
        uint32  quorumThresholdPercentage;
    }

    struct TaskResponse {
        uint32  referenceTaskIndex;
        bytes32 responseHash;
    }

    function createNewTask(
        bytes calldata taskData,
        uint32 quorumThresholdPercentage,
        bytes calldata quorumNumbers
    ) external returns (Task memory);

    function respondToTask(
        Task calldata task,
        TaskResponse calldata taskResponse,
        NonSignerStakesAndSignature memory nonSignerStakesAndSignature
    ) external;
}
```

### Slashing Conditions (Objective vs Subjective)

**Objective slashing** — provable on-chain without external information:
- Double signing (two valid signatures on conflicting messages, same block)
- Invalid state transition with fraud proof
- DA withholding with KZG proof of unavailability

**Subjective slashing** — requires off-chain committee judgment:
- Liveness failure (operator goes offline)
- Incorrect oracle value (requires ground truth)
- SLA violation

EigenLayer currently enforces objective slashing only in its base layer. Subjective slashing is pushed to AVS-level governance.

```solidity
// Example: Double-sign slashing proof
struct BLSDoubleSignProof {
    BN254.G1Point pubkey;
    BN254.G2Point sig1;
    BN254.G2Point sig2;
    bytes32 msgHash1;
    bytes32 msgHash2;
    // msgHash1 != msgHash2, both verify under pubkey
}

function slashForDoubleSign(
    address operator,
    BLSDoubleSignProof calldata proof
) external {
    require(proof.msgHash1 != proof.msgHash2, "same message");
    require(BN254.verify(proof.pubkey, proof.msgHash1, proof.sig1));
    require(BN254.verify(proof.pubkey, proof.msgHash2, proof.sig2));
    // slash is now provable — call AllocationManager
    allocationManager.slashOperator(address(this), SlashingParams({
        operator: operator,
        operatorSetId: QUORUM_ID,
        strategies: slashableStrategies,
        wadsToSlash: [0.1e18], // 10% slash
        description: "double-sign"
    }));
}
```

---

## 3. Restaking Flow

### Native Restaking (EigenPods)

For solo stakers and node operators — restake validator withdrawal credentials directly.

```
Validator (32 ETH on beacon chain)
      │
      │  set withdrawal credential to EigenPod address
      │
      ▼
   EigenPod (per-operator contract)
      │
      │  verifyWithdrawalCredentials() — proves via beacon state proof
      │  EigenPodManager records virtual "beaconChainETH" shares
      │
      ▼
   StrategyManager (internal accounting)
      │
      │  delegate shares to operator
      │
      ▼
   DelegationManager
```

Beacon chain proofs use the SSZ Merkle proof of the validator's `withdrawal_credentials` field pointing to the EigenPod address. The proof is verified against the `beaconBlockRoot` available via EIP-4788.

```solidity
interface IEigenPodManager {
    function createPod() external returns (address);

    function stake(
        bytes calldata pubkey,
        bytes calldata signature,
        bytes32 depositDataRoot
    ) external payable;
}

interface IEigenPod {
    function verifyWithdrawalCredentials(
        uint64 beaconTimestamp,
        BeaconChainProofs.StateRootProof calldata stateRootProof,
        uint40[] calldata validatorIndices,
        bytes[] calldata validatorFieldsProofs,
        bytes32[][] calldata validatorFields
    ) external;

    function verifyAndProcessWithdrawals(
        uint64 beaconTimestamp,
        BeaconChainProofs.StateRootProof calldata stateRootProof,
        BeaconChainProofs.WithdrawalProof[] calldata withdrawalProofs,
        bytes[] calldata validatorFieldsProofs,
        bytes32[][] calldata validatorFields,
        bytes32[][] calldata withdrawalFields
    ) external;
}
```

### LST Restaking

Simpler path: deposit stETH/rETH/cbETH directly into StrategyManager.

```
User holds stETH
      │
      ├─ approve(StrategyManager, amount)
      │
      └─ depositIntoStrategy(stETHStrategy, stETH, amount)
             │
             ▼
         stETHStrategy.deposit() → mint shares
             │
             ▼  (user delegates)
         DelegationManager.delegateTo(operator)
```

Exchange rate risk: `stETH` accrues rebasing yield. Strategy shares track underlying token amount, not shares-of-shares. When stETH rebases, the strategy's `sharesToUnderlying()` rate increases — restakers automatically capture staking yield AND AVS yield.

### Delegation Mechanics

```
Staker delegates to Operator A:
  operatorShares[A][stETHStrategy] += deposited_shares

Staker undelegates:
  - all shares queued for withdrawal
  - operator's stake weight drops immediately
  - AVS may see operator fall below quorum threshold

Withdrawal completes after withdrawalDelayBlocks (~7 days):
  - staker receives underlying tokens
```

Key nuance: **operator magnitude allocation** determines how much of a delegator's stake can be slashed by each AVS. If an operator allocates 30% magnitude to AVS-X and 40% to AVS-Y, a 100% slash by AVS-X burns 30% of delegators' stake, not 100%.

---

## 4. Symbiotic Protocol

### Architecture Comparison

```
EigenLayer                          Symbiotic
──────────────────────────────      ──────────────────────────────
StrategyManager (deposits)    ←→    Vault (deposits + accounting)
DelegationManager (routing)   ←→    Network + Operator registry
Slasher / AllocationMgr       ←→    Network-defined slashing
AVSDirectory                  ←→    NetworkRegistry + OperatorRegistry
ServiceManager (per-AVS)      ←→    Network middleware (per-network)
```

Symbiotic is more modular: vaults, networks, and operators are independent registries with no privileged central contract. Any vault can back any network; any operator can register with any network.

### Vault Architecture

```solidity
interface IVault {
    // Depositors provide collateral
    function deposit(address onBehalfOf, uint256 amount)
        external returns (uint256 depositedAmount, uint256 mintedShares);

    function withdraw(address claimer, uint256 amount)
        external returns (uint256 burnedShares, uint256 mintedShares);

    // Epoch-based withdrawal queue
    function currentEpoch() external view returns (uint256);
    function epochDuration() external view returns (uint256);

    // Slashing — called by network's slasher contract
    function slash(
        bytes32 subnetwork,
        address operator,
        uint256 amount,
        uint48 captureTimestamp,
        bytes calldata hints
    ) external returns (uint256 slashedAmount);
}
```

Vaults can be:
- **Instant withdrawal** — no lock, low yield (unsuitable for slashable collateral)
- **Epoch-based** — withdrawals processed at epoch boundaries (14-day typical)
- **Custom delegator** — vault owner defines how stake routes to operators/networks

### Networks and Operators

Networks register themselves, define their own slashing middleware, and independently negotiate with operators. There is no EigenLayer-style "opt-in to slashing" through a central contract — instead each network deploys a Slasher contract.

```
Network (e.g., an oracle protocol)
    ├── deploys NetworkMiddleware contract
    ├── deploys ISlasher (VetoSlasher or InstantSlasher)
    └── registers in NetworkRegistry

Operator
    ├── registers in OperatorRegistry
    ├── opts into network: optIn(network)
    └── opts into vault: optIn(vault)
```

**VetoSlasher**: slash requests can be vetoed by a resolver within a veto window before execution. Useful for subjective slashing.

**InstantSlasher**: slash executes immediately upon authorized network call. Used for objective, on-chain-provable faults.

### Collateral

Symbiotic uses a `IDefaultCollateral` interface allowing any ERC-20 to serve as vault collateral. This enables restaking of non-ETH assets (USDC, BTC wrappers, protocol tokens) natively — a broader design than EigenLayer's ETH-centric model.

---

## 5. Karak

### DSS (Distributed Secure Services)

Karak's equivalent of AVS. DSS contracts implement `IDSS`:

```solidity
interface IDSS {
    function registrationHook(address operator, bytes memory data) external;
    function unregistrationHook(address operator, bytes memory data) external;

    // Called when a vault is allocated to this DSS
    function requestUpdateVaultStakeHook(
        address vault,
        StakeUpdateRequest memory request
    ) external;

    // Slashing
    function finishSlashingHook(address vault, uint256 slashPercentageWad) external;
    function cancelSlashingHook(address vault) external;
}
```

### Vault System

Karak vaults are ERC-4626-compatible with added slashing and delegation logic. The `Core` contract is the central registry:

```
Core (registry + coordinator)
    ├── registerDSS()
    ├── registerOperatorToDSS()
    ├── requestSlashing()
    └── finalizeSlashing() / cancelSlashing()

Vault (ERC-4626)
    ├── deposit() / withdraw()
    ├── transferFundsToDSS()  ← stake delegation
    └── slashAssets()         ← burning on finalize
```

Two-phase slashing: `requestSlashing` → veto window → `finalizeSlashing`. A `vetoCommittee` can cancel within the window. This mirrors Symbiotic's VetoSlasher pattern.

### Multi-asset Support

Karak supports arbitrary ERC-20 assets as collateral from day one. Each vault is single-asset; operators can manage multiple vaults across assets. DSS defines which asset types it accepts.

---

## 6. Shared Security Economics

### Security Pooling Model

```
Traditional PoS:
  Protocol security ∝ market cap of staked token
  Cost to attack = 33% of staked token × current price

With restaking:
  AVS security = Σ (operator_stake_i × allocation_to_AVS_i) for all operators
  Cost to attack AVS = must outweigh slashable stake from all opted-in operators
```

The key insight: if ETH price = $3,000 and 1M ETH is restaked, the total slashable pool is $3B (at 100% allocation). An AVS capturing 10% of that pool has $300M of cryptoeconomic security for near-zero bootstrapping cost.

### Security Attribution

```
Operator A: 1000 ETH delegated
  - 40% magnitude to AVS-X  →  400 ETH slashable by AVS-X
  - 30% magnitude to AVS-Y  →  300 ETH slashable by AVS-Y
  - 30% magnitude to AVS-Z  →  300 ETH slashable by AVS-Z

If AVS-X slashes 50% of its allocation:
  - 200 ETH destroyed (from Operator A's delegators)
  - AVS-Y and AVS-Z still have full 300 ETH each (independent)
```

Cascading risk arises when a single economic event causes correlated slashing:
- A market crash causes operators to behave maliciously across multiple AVSs simultaneously
- Smart contract bug in shared infrastructure triggers slashing across all dependent AVSs

### Cascading Slashing Risk Model

```
Let S = operator stake
Let a_i = allocation to AVS_i (Σa_i ≤ 1)
Let p_i = probability of slash event for AVS_i
Let s_i = slash percentage if slashed

Expected loss for delegator:
  E[loss] = S × Σ(a_i × p_i × s_i)

Correlated scenario (market crash):
  p_i correlated → E[loss] >> independent case
  Tail risk: all AVSs slash simultaneously
  Max loss = S × min(1, Σ(a_i × s_i))
```

**Key constraint in EigenLayer**: allocations must sum to ≤ 1 (100% of magnitude). So maximum loss is 100% of stake regardless of how many AVSs slash. This prevents "over-leverage" of stake.

---

## 7. Operator Economics

### Yield Sources

```
Operator total yield =
    consensus_yield (base ETH staking ~3-4%)
  + Σ(AVS_i payment × operator_commission_i)
  + MEV capture (if running MEV-boost or proposer commitments)
  - infrastructure_costs
  - slash_events (expected value, hopefully near zero)
```

### AVS Payment Models

1. **Inflation model**: AVS mints protocol tokens to pay operators (high risk of token dilution)
2. **Fee model**: AVS collects user fees, distributes to operators pro-rata by stake
3. **Hybrid**: base fee + token incentive

```solidity
// Typical payment flow via EigenLayer's RewardsCoordinator
interface IRewardsCoordinator {
    struct RewardsSubmission {
        StrategyAndMultiplier[] strategiesAndMultipliers;
        IERC20 token;
        uint256 amount;
        uint32 startTimestamp;
        uint32 duration;
    }

    function createAVSRewardsSubmission(
        RewardsSubmission[] calldata rewardsSubmissions
    ) external;

    function processClaim(
        RewardsMerkleClaim calldata claim,
        address recipient
    ) external;
}
```

### Risk Management for Operators

1. **Diversification**: spread across AVSs with uncorrelated slashing risks
2. **Magnitude limits**: cap allocation to any single high-risk AVS
3. **Due diligence**: audit AVS slashing conditions before opting in
4. **Insurance**: purchase coverage from protocols like Nexus Mutual or Unslashed
5. **Monitoring**: real-time alerting for slashing proposal events

### MEV from Validation

Operators running validators (native restaking) can also:
- Run MEV-boost, capturing block-level MEV
- Enter proposer commitment schemes (mev-commit, Bolt, Primev)
- Offer preconfirmations as an AVS service itself

This creates a flywheel: operators with more ETH staked get more block proposals → more MEV → more attractive to delegators → more stake delegated.

---

## 8. AVS Development Patterns

### Building an Oracle AVS

**Architecture:**

```
Off-chain:
  PriceFetcher (aggregates CEX/DEX prices)
       │
  Operator node (signs price feed)
       │
  Aggregator (collects n-of-m signatures)
       │
On-chain:
  OracleServiceManager.respondToTask(aggSig, price)
       │
  Price stored, verified by threshold
```

```solidity
contract OracleServiceManager is ServiceManagerBase {
    struct PriceTask {
        bytes32 assetPair;      // e.g. keccak256("ETH/USD")
        uint32  createdBlock;
        uint32  respondByBlock;
    }

    struct PriceResponse {
        uint32  taskIndex;
        uint256 price;          // 18 decimals
        uint256 confidence;     // 0-1e18
    }

    PriceTask[] public allTasks;
    mapping(uint32 => bytes32) public taskResponseHashes;

    function createPriceTask(bytes32 assetPair) external returns (uint32) {
        PriceTask memory task = PriceTask({
            assetPair: assetPair,
            createdBlock: uint32(block.number),
            respondByBlock: uint32(block.number) + RESPONSE_WINDOW
        });
        uint32 idx = uint32(allTasks.length);
        allTasks.push(task);
        emit NewTaskCreated(idx, task);
        return idx;
    }

    function respondToPriceTask(
        PriceTask calldata task,
        PriceResponse calldata response,
        NonSignerStakesAndSignature memory sig
    ) external onlyAggregator {
        require(block.number <= task.respondByBlock, "expired");

        bytes32 msgHash = keccak256(abi.encode(
            PRICE_RESPONSE_TYPEHASH,
            response.taskIndex,
            response.price,
            response.confidence
        ));

        // Verify BLS aggregate signature meets quorum threshold
        (
            QuorumStakeTotals memory totals,
            bytes32 hashOfNonSigners
        ) = checkSignatures(msgHash, task.quorumNumbers, task.createdBlock, sig);

        require(
            totals.signedStakeForQuorum[0] * THRESHOLD_DENOMINATOR
            >= totals.totalStakeForQuorum[0] * QUORUM_THRESHOLD_PERCENTAGE,
            "below threshold"
        );

        taskResponseHashes[response.taskIndex] = keccak256(abi.encode(response));
        emit TaskResponded(response.taskIndex, response, msg.sender);
    }
}
```

### Building a Bridge AVS

Bridge AVS validates cross-chain messages. Operators run light clients for source chains.

```
Source Chain:
  User locks tokens → emits BridgeRequest(nonce, dst, amount, recipient)
      │
      │  operators observe event
      │
Operators (BLS sign attestation):
  keccak256(chainId, nonce, dst, amount, recipient)
      │
Aggregator collects, submits on Destination Chain:
  BridgeServiceManager.attestBridge(attestation, aggSig)
      │
  Threshold verified → mint/unlock tokens on dst chain
```

Slashing condition: operator signs contradictory attestations for same nonce (double-bridge attempt).

### Building a DA (Data Availability) AVS

EigenDA is the reference implementation. Core design:

```
Disperser (off-chain):
  - receives blob data from rollup
  - encodes into chunks (using KZG + erasure coding)
  - distributes chunks to operators by quorum assignment
  - collects storage confirmations (signed)
  - posts BatchHeader + BlobHeaders on-chain

Operators:
  - store their assigned chunk
  - serve chunk on request (for fraud provers)
  - sign confirmation: keccak256(blobHash, chunkIndex, epoch)

On-chain:
  EigenDAServiceManager.confirmBatch(batchHeader, blobVerificationProofs, sig)
  - verifies aggregate sig over stored batch
  - any rollup can reference blobIndex to confirm DA
```

KZG commitment scheme ensures:
- Operator can prove their chunk is correct subset of blob
- Missing chunk can be proven absent (via polynomial evaluation proof)
- Blob can be reconstructed from any `k` of `n` chunks

---

## 9. Slashing Mechanism Design

### Objective vs Subjective Comparison

| Property | Objective | Subjective |
|---|---|---|
| Proof | On-chain, trustless | Requires committee |
| Examples | Double-sign, invalid proof | Liveness, oracle error |
| Latency | Instant | Hours to days (veto window) |
| Manipulation risk | Low | Committee capture risk |
| UX | Hard to accidentally trigger | Easier to trigger unfairly |

### Slashing Committee Design

For subjective slashing, a committee provides a veto or confirmation:

```
Slashing Lifecycle (with committee):

1. AVS detects fault → proposes slash
   SlashingProposed(operator, reason, amount, vetoDeadline)

2. Veto window (e.g., 3 days):
   - Committee members can VETO slash
   - If majority veto → slash cancelled
   - If no veto by deadline → slash proceeds

3. Execution:
   - AllocationManager.slashOperator() burns stake

Committee composition best practices:
  - Multisig of independent security researchers
  - Token-weighted governance (risk: collusion)
  - Hybrid: DAO veto + time-lock execution
```

```solidity
contract SlashingCommittee {
    uint256 public constant VETO_PERIOD = 3 days;
    uint256 public constant VETO_THRESHOLD = 3; // of 5 signers

    struct SlashProposal {
        address operator;
        address avs;
        uint256 wadToSlash;
        uint256 proposedAt;
        uint256 vetoCount;
        bool executed;
        bool vetoed;
        mapping(address => bool) hasVetoed;
    }

    mapping(bytes32 => SlashProposal) public proposals;

    function proposeSlash(
        address operator,
        address avs,
        uint256 wadToSlash,
        bytes calldata evidence
    ) external onlyAVS returns (bytes32 proposalId) {
        proposalId = keccak256(abi.encode(operator, avs, block.timestamp));
        SlashProposal storage p = proposals[proposalId];
        p.operator = operator;
        p.avs = avs;
        p.wadToSlash = wadToSlash;
        p.proposedAt = block.timestamp;
        emit SlashProposed(proposalId, operator, wadToSlash);
    }

    function veto(bytes32 proposalId) external onlyCommitteeMember {
        SlashProposal storage p = proposals[proposalId];
        require(block.timestamp < p.proposedAt + VETO_PERIOD, "veto expired");
        require(!p.hasVetoed[msg.sender], "already vetoed");
        p.hasVetoed[msg.sender] = true;
        p.vetoCount++;
        if (p.vetoCount >= VETO_THRESHOLD) {
            p.vetoed = true;
            emit SlashVetoed(proposalId);
        }
    }

    function executeSlash(bytes32 proposalId) external {
        SlashProposal storage p = proposals[proposalId];
        require(!p.vetoed && !p.executed, "invalid state");
        require(block.timestamp >= p.proposedAt + VETO_PERIOD, "veto pending");
        p.executed = true;
        // call AllocationManager.slashOperator(...)
        emit SlashExecuted(proposalId);
    }
}
```

### Slashing Insurance

Protocols like **Nexus Mutual** and **Unslashed** offer parametric slash coverage:
- Cover triggers when `SlashExecuted` event emitted
- Payout proportional to loss, up to cover limit
- Premium = f(covered amount, slash probability, protocol risk score)

Operators can hedge by purchasing cover that pays out on their own slashing events — this is not a conflict of interest since the event is objectively observable.

---

## 10. LRT (Liquid Restaking Tokens)

### Overview

LRTs abstract the complexity of EigenLayer deposit + delegation + AVS selection into a single ERC-20 token. Users deposit ETH or LSTs; they receive a liquid token representing their restaked position.

```
User deposits ETH
      │
      ▼
LRT Protocol (e.g., EtherFi)
  - selects operators (by criteria: yield, risk, geography)
  - deposits into EigenLayer on behalf of user
  - delegates to chosen operators
  - receives AVS rewards, compounds or distributes
      │
      ▼
eETH (or weETH) — liquid ERC-20
  - redeemable for underlying (with delay)
  - tradeable on DEXs at slight premium/discount
  - usable as DeFi collateral
```

### Major Protocols

**EtherFi**
- Native validator operation (solo-staker equivalent)
- Non-custodial node operators via T-NFT / B-NFT split
- eETH (rebasing) + weETH (non-rebasing wrapper)
- Largest by TVL (~$7B+ peak)
- Withdrawal NFTs for partial/full exits

**Renzo**
- Operator-agnostic, whitelisted operator set
- ezETH token; Balancer pool for liquidity
- Concentrated liquidity events caused depeg in May 2024 (ezETH/ETH pool imbalance when withdrawals opened)

**Kelp DAO**
- rsETH backed by stETH + ETHx deposits
- Multi-asset deposits; converts to EigenLayer shares

**Puffer Finance**
- Anti-slashing focus: operators post 2 ETH bond (pufETH)
- Enclave-based validator signing to prevent accidental double-sign
- AVS-level insurance built in

**Risks Common to All LRTs:**

| Risk | Description |
|---|---|
| Smart contract risk | Bugs in LRT contracts can drain all deposited ETH |
| Operator selection risk | LRT chooses operators; poor selection → slashing |
| Liquidity risk | LRT token may trade below NAV during crises |
| Withdrawal delay risk | EigenLayer delay + LRT's own queue can stack |
| Governance risk | LRT DAO can change operator set or fee params |
| Rehypothecation | LRT token used as DeFi collateral creates cascading liquidation risk |

### LRT Architecture (Generic)

```solidity
interface ILRTProtocol {
    // User entry point
    function deposit(address token, uint256 amount)
        external returns (uint256 lrtMinted);

    function depositETH() external payable returns (uint256 lrtMinted);

    // Redemption (queued)
    function requestWithdrawal(uint256 lrtAmount)
        external returns (uint256 requestId);

    function claimWithdrawal(uint256 requestId) external;

    // Operator management (governance)
    function addOperator(address operator, OperatorConfig calldata config) external;
    function removeOperator(address operator) external;

    // AVS management
    function optIntoAVS(address operator, address avs) external;
    function optOutOfAVS(address operator, address avs) external;

    // Price
    function getExchangeRate() external view returns (uint256 ethPerLRT);
}
```

### weETH (Wrapped EtherFi ETH) as DeFi Collateral

weETH became the dominant LRT collateral in DeFi. Integration points:
- Aave: weETH listed as collateral (LTV ~72%)
- MorphoBlue: weETH/USDC markets
- Pendle: split yield into PT (fixed) + YT (variable) for weETH

This creates a leverage loop:
```
Deposit ETH → get weETH → borrow USDC against weETH
→ buy ETH → deposit ETH → get more weETH → borrow more...
```
Systemic risk: large ETH price drop → mass liquidations of LRT collateral positions → LRT sellers overwhelm exit liquidity → LRT depegs → further liquidations (death spiral).

---

## 11. Security Considerations

### Rehypothecation Risk

```
ETH staked on beacon chain:
  Security layer 1: Ethereum consensus

Same ETH restaked via EigenLayer:
  Security layer 2: AVS-A
  Security layer 3: AVS-B
  Security layer 4: AVS-C

Same ETH as LRT collateral in DeFi:
  Liquidation risk: if ETH price drops 30%, LRT depegs,
                    borrowers get liquidated, LRT sells
```

The security promise of each layer relies on the assumption that ETH price stays high enough that slashing is economically irrational. Under correlated stress, this breaks.

**Vitalik's original concern:** if restaked ETH is used to make social consensus commitments (e.g., "the Ethereum community will hard fork to protect this AVS"), it corrupts Ethereum's base layer neutrality. EigenLayer explicitly prohibits AVSs from requiring such commitments.

### Operator Centralization

```
Risk: A few large operators (e.g., P2P, Figment, Chorus One) run >50% of
restaked ETH.

Consequence:
  - Single operator compromise → large simultaneous slash across many AVSs
  - Regulatory pressure on 3 operators can censor 50%+ of AVS messages
  - "Operator cartel" can extract rents from AVSs

Mitigations:
  - Operator diversity requirements in AVS registry
  - Max stake cap per operator per quorum
  - LRT protocols distributing across >20 operators
```

### Withdrawal Delays

Stacked delays create liquidity risk:

```
Beacon chain exit queue:
  Varies by validator queue length; can be 1-30+ days

EigenLayer withdrawal delay:
  Currently ~7 days (withdrawalDelayBlocks)

LRT protocol queue:
  EtherFi: depends on liquidity pool depth (can be instant if pool has ETH)
  Renzo: separate request/claim flow

Total worst case:
  Beacon exit (30 days) + EigenLayer (7 days) + LRT queue (varies)
  = potentially 40+ days from "I want to exit" to ETH in hand
```

**Smart contract risk vector**: StrategyManager holds all restaked LSTs. A bug there could compromise the entire restaking ecosystem. EigenLayer mitigates via pausing mechanisms and a guardian multisig.

### M2 vs ELIP-002 Security Model Change

Pre-ELIP-002 (M2): Slasher only "froze" operators; no real burn. Security was social/reputational.
Post-ELIP-002: Actual stake destruction. This changes the risk profile significantly — now restakers have real economic skin in the game, and slashing bugs can cause permanent loss.

---

## 12. Integration Patterns

### Full AVS Integration — Solidity Interfaces

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// ─── Step 1: Inherit ServiceManagerBase ───────────────────────────────────────
import {ServiceManagerBase} from "@eigenlayer-middleware/ServiceManagerBase.sol";
import {BLSSignatureChecker} from "@eigenlayer-middleware/BLSSignatureChecker.sol";
import {RegistryCoordinator} from "@eigenlayer-middleware/RegistryCoordinator.sol";

contract MyAVSServiceManager is ServiceManagerBase, BLSSignatureChecker {
    IAllocationManager public immutable allocationManager;
    uint32 public constant OPERATOR_SET_ID = 0;

    constructor(
        IAVSDirectory _avsDirectory,
        IAllocationManager _allocationManager,
        IRegistryCoordinator _registryCoordinator,
        IStakeRegistry _stakeRegistry
    )
        ServiceManagerBase(_avsDirectory, _registryCoordinator, _stakeRegistry)
        BLSSignatureChecker(_registryCoordinator)
    {
        allocationManager = _allocationManager;
    }

    // ─── Step 2: Initialize slashable operator set ──────────────────────────
    function createOperatorSet() external onlyOwner {
        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = BEACONCHAIN_ETH_STRATEGY; // or stETH strategy

        allocationManager.createOperatorSets(
            address(this),
            CreateSetParams(OPERATOR_SET_ID, strategies)
        );
    }

    // ─── Step 3: Task flow ──────────────────────────────────────────────────
    event TaskCreated(uint32 indexed taskId, Task task);
    event TaskResponded(uint32 indexed taskId, bytes32 responseHash);

    struct Task {
        bytes32 inputHash;
        uint32  createdBlock;
        bytes   quorumNumbers;
        uint32  quorumThresholdPct;
    }

    Task[] public tasks;

    function createTask(bytes32 inputHash) external returns (uint32 taskId) {
        taskId = uint32(tasks.length);
        Task memory t = Task({
            inputHash: inputHash,
            createdBlock: uint32(block.number),
            quorumNumbers: abi.encodePacked(uint8(0)),
            quorumThresholdPct: 66
        });
        tasks.push(t);
        emit TaskCreated(taskId, t);
    }

    mapping(uint32 => bytes32) public taskResponses;

    function respondToTask(
        uint32 taskId,
        bytes32 resultHash,
        NonSignerStakesAndSignature memory nssas
    ) external {
        Task memory task = tasks[taskId];
        require(taskResponses[taskId] == bytes32(0), "already responded");

        bytes32 msgHash = keccak256(abi.encode(taskId, resultHash));

        (QuorumStakeTotals memory totals, ) = checkSignatures(
            msgHash,
            task.quorumNumbers,
            task.createdBlock,
            nssas
        );

        // Verify threshold
        for (uint256 i = 0; i < task.quorumNumbers.length; i++) {
            require(
                totals.signedStakeForQuorum[i] * 100
                >= totals.totalStakeForQuorum[i] * task.quorumThresholdPct,
                "insufficient stake"
            );
        }

        taskResponses[taskId] = resultHash;
        emit TaskResponded(taskId, resultHash);
    }

    // ─── Step 4: Slashing ───────────────────────────────────────────────────
    function slashOperatorForMaliciousResponse(
        address operator,
        uint32 taskId,
        bytes32 fraudulentResult,
        bytes calldata fraudProof
    ) external {
        // 1. Verify the fraud proof (task-specific logic)
        require(_verifyFraud(taskId, fraudulentResult, fraudProof), "invalid proof");

        // 2. Slash via AllocationManager
        IStrategy[] memory strats = new IStrategy[](1);
        strats[0] = BEACONCHAIN_ETH_STRATEGY;
        uint256[] memory wads = new uint256[](1);
        wads[0] = 0.05e18; // 5% slash

        allocationManager.slashOperator(
            address(this),
            IAllocationManager.SlashingParams({
                operator: operator,
                operatorSetId: OPERATOR_SET_ID,
                strategies: strats,
                wadsToSlash: wads,
                description: "fraudulent task response"
            })
        );
    }

    function _verifyFraud(
        uint32 taskId,
        bytes32 fraudulentResult,
        bytes calldata proof
    ) internal view returns (bool) {
        // AVS-specific fraud proof verification logic
        // e.g., interactive fraud proof, ZK proof, etc.
        return true; // placeholder
    }
}
```

### Operator Registration Script (Off-chain / Foundry)

```solidity
// Script to register as operator and opt into an AVS
contract RegisterOperatorScript is Script {
    function run() external {
        uint256 operatorKey = vm.envUint("OPERATOR_PRIVATE_KEY");
        address operator = vm.addr(operatorKey);

        IDelegationManager delegationManager =
            IDelegationManager(DELEGATION_MANAGER_ADDRESS);
        IAllocationManager allocationManager =
            IAllocationManager(ALLOCATION_MANAGER_ADDRESS);

        vm.startBroadcast(operatorKey);

        // 1. Register as operator
        delegationManager.registerAsOperator(
            IDelegationManager.OperatorDetails({
                earningsReceiver: operator,
                delegationApprover: address(0),  // permissionless
                stakerOptOutWindowBlocks: 50400  // ~7 days
            }),
            "https://my-operator-metadata.json"
        );

        // 2. Opt into AVS's operator set for slashing
        IAllocationManager.RegisterParams memory regParams =
            IAllocationManager.RegisterParams({
                avs: AVS_SERVICE_MANAGER_ADDRESS,
                operatorSetIds: [uint32(0)],
                data: ""
            });
        allocationManager.registerForOperatorSets(regParams);

        // 3. Allocate magnitude (30% of stake slashable by this AVS)
        IAllocationManager.MagnitudeAllocation[] memory allocs =
            new IAllocationManager.MagnitudeAllocation[](1);
        allocs[0] = IAllocationManager.MagnitudeAllocation({
            strategy: BEACONCHAIN_ETH_STRATEGY,
            expectedMaxMagnitude: 1e18,
            operatorSets: [OperatorSet(AVS_SERVICE_MANAGER_ADDRESS, 0)],
            magnitudes: [uint64(0.3e18)]  // 30%
        });
        allocationManager.modifyAllocations(allocs);

        vm.stopBroadcast();
    }
}
```

### Monitoring Integration

```solidity
// Events to monitor for operator dashboards
interface IMonitoringEvents {
    // EigenLayer core
    event OperatorSlashed(
        address indexed operator,
        OperatorSet operatorSet,
        IStrategy[] strategies,
        uint256[] wadSlashed,
        string description
    );

    event AllocationUpdated(
        address indexed operator,
        OperatorSet operatorSet,
        IStrategy strategy,
        uint64 magnitude,
        uint32 effectBlock
    );

    event OperatorFrozen(address indexed operatorAddress, address indexed slashingContract);

    // AVS-level
    event TaskCreated(uint32 indexed taskId, Task task);
    event TaskResponded(uint32 indexed taskId, bytes32 responseHash);
    event SlashProposed(bytes32 indexed proposalId, address operator, uint256 amount);
}
```

---

## Economic Models Summary

### AVS Security Budget Calculation

```
Target security level: $X (cost to corrupt AVS)

Required slashable stake: $X / average_slash_percentage

At current market:
  ETH price: $3,000
  Average operator allocation: 25%
  Required restaked ETH: ($X / 0.25) / 3000

Example: AVS wants $100M security
  Required slashable: $100M / 0.25 = $400M in restaked ETH
  ETH needed: $400M / $3,000 = 133,333 ETH delegated to AVS operators
```

### Operator Yield Stack

```
Base yield (beacon chain):           ~3.5% APR
LST premium (stETH vs ETH):          ~0.1% (liquidity premium)
EigenLayer AVS payments:             ~1-3% APR (current market, sparse)
MEV (MEV-boost):                     ~0.5-1.5% APR (variable)
LRT incentive tokens:                ~0-5% APR (dilutive, market-dependent)

Total range:                         5-13% APR
Expected for professional operator:  ~5-7% APR sustainable

Risk-adjusted: subtract expected_loss = E[slash] * slash_pct
For well-managed operator: expected_loss < 0.1% APR
```

### Security Efficiency Ratio

A metric for comparing restaking protocols:

```
Security Efficiency = (Total AVS security provided) / (Total TVL)

EigenLayer (current): ~2-4x (each ETH covers 2-4 AVSs on average)
Theoretical max: limited by correlated slash risk tolerance
Theoretical upper bound: 10-20x before systemic risk becomes prohibitive
```

---

## Quick Reference: Key Addresses (Mainnet)

| Contract | Address |
|---|---|
| StrategyManager | `0x858646372CC42E1A627fcE94aa7A7033e7CF075A` |
| DelegationManager | `0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37b` |
| EigenPodManager | `0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338` |
| AllocationManager | `0x947aab7e9a5f76bb4e3b0d7c23e7c1ee80a99b6A` |
| AVSDirectory | `0x135DDa560e946695d6f155dACaFC6f1F25C1F5AF` |
| RewardsCoordinator | `0x7750d328b314EfFa365A0402CcfD489B80B0adda` |

*Always verify current addresses via EigenLayer docs — contracts are upgradeable via ProxyAdmin.*

---

## Gotchas and Edge Cases

1. **Withdrawal credential re-pointing**: Once set to EigenPod, beacon validator withdrawal credentials cannot be changed without full exit. No escape hatch.

2. **Share price manipulation**: If an LST strategy's `sharesToUnderlying()` is manipulated (e.g., donation attack), it could inflate virtual shares. Mitigated by EigenLayer's min deposit requirements.

3. **BLS key aggregation**: If an operator registers with a BLS key they don't control (front-run registration), they cannot participate. BLS key must be signed by the corresponding private key.

4. **Quorum threshold games**: If operators know a task is about to expire unresponded, they can withhold signatures to prevent slash accountability. Design tasks with proper incentives for honest non-signing.

5. **Beacon chain fork**: An Ethereum hard fork that reorgs EigenPod proofs could create phantom withdrawals. EigenPod uses finalized beacon roots (EIP-4788) to mitigate.

6. **Stale magnitude**: `ALLOCATION_CONFIGURATION_DELAY` means operators cannot instantly increase allocations. But they CAN instantly decrease (with pending unbonding). This creates a window where an operator could slash-and-run.

7. **AVS insolvency**: If an AVS cannot pay operators (treasury drained), operators will deregister. Security collapses. AVSs should maintain 6-12 month payment runway.
