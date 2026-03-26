# EigenLayer AVS Development

## Architecture Overview

```
EigenLayer Stack:
  Restakers → stake ETH/LSTs → delegate to Operators
  Operators → opt into AVSes → run off-chain software → earn fees
  AVS → defines: tasks, validation, slashing → gets economic security from EigenLayer

Security model:
  AVS inherits ETH security proportional to operator stake
  Misbehaving operators lose their staked ETH (slashing)
  This lets ANY service bootstrap trust without its own token/validator set
```

## Core Contracts

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@eigenlayer/contracts/interfaces/IServiceManager.sol";
import "@eigenlayer/contracts/interfaces/IBLSRegistryCoordinatorWithIndices.sol";
import "@eigenlayer/middleware/BLSSignatureChecker.sol";

/**
 * @title SpartaJudgingServiceManager
 * @notice AVS for decentralized AI judging of Agent Sparta challenges
 *
 * Flow:
 *  1. New challenge created on Sparta → emits NewTask event
 *  2. EigenLayer operators run judging software off-chain
 *  3. Operators sign their scores with BLS keys
 *  4. Aggregator collects BLS signatures, forms quorum signature
 *  5. Aggregated score posted on-chain with quorum proof
 *  6. Slashing: if operator score deviates >20% from quorum → slash
 */
contract SpartaJudgingServiceManager is IServiceManager, BLSSignatureChecker {

    // Quorum requirements
    uint8  public constant QUORUM_NUMBER = 0;     // Which quorum (operators opted in to this AVS)
    uint96 public constant QUORUM_THRESHOLD = 6_600; // 66% of stake must agree (BPS)

    struct JudgingTask {
        bytes32 challengeId;
        bytes32 submissionsHash;  // Hash of all submissions to judge
        uint32  taskCreatedBlock;
        bytes   quorumNumbers;    // Which quorums must respond
    }

    struct JudgingResponse {
        uint32  referenceBlockNumber;
        bytes32 challengeId;
        uint256[] scores;     // Score per submission
        bytes32 scoresHash;   // keccak256(abi.encode(scores))
    }

    mapping(uint32 => JudgingTask) public tasks;
    mapping(uint32 => bytes32) public taskResponses; // taskId → aggregated scores hash
    uint32 public latestTaskNum;

    event NewJudgingTask(uint32 indexed taskIndex, JudgingTask task);
    event TaskResponded(uint32 indexed taskIndex, JudgingResponse response, address aggregator);

    // ─── Create Task (called when a challenge needs judging) ───────────────────

    function createNewTask(
        bytes32 challengeId,
        bytes32 submissionsHash,
        bytes calldata quorumNumbers
    ) external onlySpartaArena returns (uint32 taskIndex) {
        taskIndex = latestTaskNum++;
        tasks[taskIndex] = JudgingTask({
            challengeId:      challengeId,
            submissionsHash:  submissionsHash,
            taskCreatedBlock: uint32(block.number),
            quorumNumbers:    quorumNumbers
        });
        emit NewJudgingTask(taskIndex, tasks[taskIndex]);
    }

    // ─── Submit Aggregated Response ─────────────────────────────────────────────

    function respondToTask(
        JudgingTask calldata task,
        JudgingResponse calldata response,
        NonSignerStakesAndSignature memory nonSignerStakesAndSignature
    ) external {
        uint32 taskIndex = getTaskIndex(task);
        require(taskResponses[taskIndex] == bytes32(0), "Already responded");

        // Verify BLS signature from quorum of operators
        (QuorumStakeTotals memory quorumStakeTotals, bytes32 hashOfNonSigners) =
            checkSignatures(
                response.scoresHash,
                task.quorumNumbers,
                response.referenceBlockNumber,
                nonSignerStakesAndSignature
            );

        // Verify quorum threshold met
        for (uint i = 0; i < task.quorumNumbers.length; i++) {
            require(
                quorumStakeTotals.signedStakeForQuorum[i] * 10_000
                    >= quorumStakeTotals.totalStakeForQuorum[i] * QUORUM_THRESHOLD,
                "Insufficient quorum"
            );
        }

        taskResponses[taskIndex] = response.scoresHash;

        // Finalize scores in Sparta contract
        ISpartaArena(SPARTA_ARENA).finalizeJudging(
            task.challengeId,
            response.scores
        );

        emit TaskResponded(taskIndex, response, msg.sender);
    }

    // ─── Slashing (for operators who deviate significantly from quorum) ─────────

    function raiseAndResolveChallenge(
        JudgingTask calldata task,
        JudgingResponse calldata response,
        address challengedOperator,
        uint256[] calldata operatorScores
    ) external {
        // Challenger proves: operator's scores deviate >20% from accepted quorum scores
        uint256[] memory quorumScores = abi.decode(
            abi.encode(taskResponses[getTaskIndex(task)]),
            (uint256[])
        );

        uint256 totalDeviation;
        for (uint i = 0; i < quorumScores.length; i++) {
            uint256 deviation = quorumScores[i] > operatorScores[i]
                ? quorumScores[i] - operatorScores[i]
                : operatorScores[i] - quorumScores[i];
            totalDeviation += deviation * 10_000 / quorumScores[i];
        }

        if (totalDeviation / quorumScores.length > 2_000) { // >20% average deviation
            // Slash the operator
            slasher.freezeOperator(challengedOperator);
        }
    }
}
```

## Operator Software (Off-Chain)

```typescript
// The software operators run to participate in the AVS
import { ethers } from "ethers";
import { ScoringModel } from "./scoring-model";

class SpartaJudgingOperator {
    private wallet: ethers.Wallet;
    private model: ScoringModel;
    private serviceManager: ethers.Contract;

    async run() {
        // Listen for new judging tasks
        this.serviceManager.on("NewJudgingTask", async (taskIndex, task) => {
            console.log(`New task: ${task.challengeId}`);

            // Fetch submissions from IPFS/calldata
            const submissions = await this.fetchSubmissions(task.submissionsHash);

            // Score each submission using the agreed-upon model
            const scores = await Promise.all(
                submissions.map(s => this.model.score(s))
            );

            // Sign the scores with BLS key (for quorum aggregation)
            const scoresHash = ethers.keccak256(
                ethers.AbiCoder.defaultAbiCoder().encode(["uint256[]"], [scores])
            );
            const signature = await this.wallet.signMessage(scoresHash);

            // Submit to aggregator
            await this.submitToAggregator(taskIndex, scores, scoresHash, signature);
        });
    }
}
```

## Agent Sparta AVS Economics

```
Operators stake: 32 ETH minimum (typical EigenLayer requirement)
Slashing risk: operator loses up to 50% of stake for provable misbehavior
Operator reward: 0.5% of challenge prize pool per challenge judged

Example:
  - 1000 challenges/month × $1000 average prize × 0.5% = $5,000/month per operator
  - 32 ETH staked at $3000 = $96,000 stake
  - Annual yield: $60,000 / $96,000 = 62.5% APY
  - This is attractive for operators → many operators opt in → strong security

Security: if a cartel of operators tries to corrupt scores:
  - They need to control 67% of quorum stake
  - Cost: 67% × total staked ETH (could be billions)
  - Expected gain: fraction of challenge prizes
  - Attack is not profitable → honest participation is dominant strategy
```
