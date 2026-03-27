// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BoutsScoreAggregator
 * @author Chain — Perlantir AI Studio
 * @notice Aggregates 3 revealed judge scores into a single canonical final score.
 *         Reads from BoutsJudgeCommit, applies disagreement logic, emits result.
 *
 * @dev Disagreement rules:
 *   Rule 1 — All 3 scores within 10pts of each other → median
 *   Rule 2 — One outlier >15pts from median → discard + average remaining 2
 *   Rule 3 — All disagree (max spread >15, no single outlier) → flag for manual resolution
 *
 * Scores are uint8 in range 10-100 (1.0×10 to 10.0×10).
 * Final score stored as uint8 (same range) or 0 if disputed.
 */

interface IBoutsJudgeCommit {
    function getReveals(bytes32 entryId) external view returns (
        uint8 claude,
        uint8 gpt4o,
        uint8 gemini,
        bool allRevealed
    );
}

contract BoutsScoreAggregator {

    // =========================================================================
    // Events
    // =========================================================================

    event ScoreFinalized(
        bytes32 indexed entryId,
        bytes32 indexed challengeId,
        uint8 finalScore,
        AggregationResult result,
        uint8 claude,
        uint8 gpt4o,
        uint8 gemini
    );

    event OutlierDiscarded(
        bytes32 indexed entryId,
        string provider,
        uint8 outlierScore,
        uint8 finalScore
    );

    event DisputeFlagged(
        bytes32 indexed entryId,
        bytes32 indexed challengeId,
        uint8 claude,
        uint8 gpt4o,
        uint8 gemini
    );

    event DisputeResolved(
        bytes32 indexed entryId,
        uint8 finalScore,
        string resolution
    );

    event OracleTransferred(address indexed previousOracle, address indexed newOracle);

    // =========================================================================
    // Errors
    // =========================================================================

    error OnlyOracle();
    error ZeroAddress();
    error ScoresNotAllRevealed();
    error AlreadyAggregated();
    error NotDisputed();
    error InvalidScore();

    // =========================================================================
    // Types
    // =========================================================================

    enum AggregationResult {
        Consensus,        // All within 10pts — used median
        OutlierDiscarded, // One outlier >15pts discarded — used average of 2
        Disputed          // All disagree >15pts — flagged, prize frozen
    }

    struct AggregationRecord {
        uint8 finalScore;
        AggregationResult result;
        uint8 claude;
        uint8 gpt4o;
        uint8 gemini;
        uint256 aggregatedAt;
        bool exists;
    }

    // =========================================================================
    // Constants
    // =========================================================================

    uint8 public constant CONSENSUS_THRESHOLD = 10;  // all within 10pts → consensus
    uint8 public constant OUTLIER_THRESHOLD   = 15;  // one >15pts off → discard

    // =========================================================================
    // State
    // =========================================================================

    address public oracle;
    IBoutsJudgeCommit public judgeCommit;

    /// @notice entryId → AggregationRecord
    mapping(bytes32 => AggregationRecord) public records;

    /// @notice disputed entryIds pending manual resolution
    mapping(bytes32 => bool) public disputed;

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor(address _oracle, address _judgeCommit) {
        if (_oracle == address(0)) revert ZeroAddress();
        if (_judgeCommit == address(0)) revert ZeroAddress();
        oracle = _oracle;
        judgeCommit = IBoutsJudgeCommit(_judgeCommit);
        emit OracleTransferred(address(0), _oracle);
    }

    // =========================================================================
    // Modifiers
    // =========================================================================

    modifier onlyOracle() {
        if (msg.sender != oracle) revert OnlyOracle();
        _;
    }

    // =========================================================================
    // Core: Aggregate
    // =========================================================================

    /**
     * @notice Read the 3 revealed scores from BoutsJudgeCommit and produce
     *         a single canonical final score for this entry.
     *
     * @param entryId     The submission entry ID (bytes32 UUID)
     * @param challengeId The challenge ID (bytes32 UUID) — for event indexing
     *
     * @return finalScore  The canonical score (0 if disputed)
     * @return result      Consensus / OutlierDiscarded / Disputed
     */
    function aggregateScores(
        bytes32 entryId,
        bytes32 challengeId
    ) external onlyOracle returns (uint8 finalScore, AggregationResult result) {
        if (records[entryId].exists) revert AlreadyAggregated();

        // Read from BoutsJudgeCommit — all 3 must be revealed
        (uint8 claude, uint8 gpt4o, uint8 gemini, bool allRevealed) =
            judgeCommit.getReveals(entryId);

        if (!allRevealed) revert ScoresNotAllRevealed();

        // Apply disagreement logic
        (finalScore, result) = _applyDisagreementLogic(claude, gpt4o, gemini);

        // Store record
        records[entryId] = AggregationRecord({
            finalScore:    finalScore,
            result:        result,
            claude:        claude,
            gpt4o:         gpt4o,
            gemini:        gemini,
            aggregatedAt:  block.timestamp,
            exists:        true
        });

        if (result == AggregationResult.Disputed) {
            disputed[entryId] = true;
            emit DisputeFlagged(entryId, challengeId, claude, gpt4o, gemini);
        } else if (result == AggregationResult.OutlierDiscarded) {
            // Identify and emit which provider was the outlier
            string memory outlierProvider;
            uint8 outlierScore;
            uint8 med = _median3(claude, gpt4o, gemini);

            if (_absDiff(claude, med) > OUTLIER_THRESHOLD) {
                outlierProvider = "claude";
                outlierScore = claude;
            } else if (_absDiff(gpt4o, med) > OUTLIER_THRESHOLD) {
                outlierProvider = "gpt4o";
                outlierScore = gpt4o;
            } else {
                outlierProvider = "gemini";
                outlierScore = gemini;
            }

            emit OutlierDiscarded(entryId, outlierProvider, outlierScore, finalScore);
        }

        emit ScoreFinalized(entryId, challengeId, finalScore, result, claude, gpt4o, gemini);
    }

    /**
     * @notice Manually resolve a disputed entry.
     *         Oracle sets the final score after human review.
     *
     * @param entryId    The disputed entry
     * @param finalScore The resolved score (10-100)
     * @param resolution Human-readable explanation (stored in event)
     */
    function resolveDispute(
        bytes32 entryId,
        uint8 finalScore,
        string calldata resolution
    ) external onlyOracle {
        if (!disputed[entryId]) revert NotDisputed();
        if (finalScore < 10 || finalScore > 100) revert InvalidScore();

        disputed[entryId] = false;
        records[entryId].finalScore = finalScore;

        emit DisputeResolved(entryId, finalScore, resolution);
    }

    // =========================================================================
    // View
    // =========================================================================

    function getRecord(bytes32 entryId) external view returns (AggregationRecord memory) {
        return records[entryId];
    }

    function getFinalScore(bytes32 entryId) external view returns (uint8) {
        return records[entryId].finalScore;
    }

    function isDisputed(bytes32 entryId) external view returns (bool) {
        return disputed[entryId];
    }

    // =========================================================================
    // Internal: Disagreement logic
    // =========================================================================

    function _applyDisagreementLogic(
        uint8 a,
        uint8 b,
        uint8 c
    ) internal pure returns (uint8 finalScore, AggregationResult result) {
        uint8 med = _median3(a, b, c);
        uint8 maxSpread = _maxSpread(a, b, c);

        // Rule 1: All within 10pts → consensus, use median
        if (maxSpread <= CONSENSUS_THRESHOLD) {
            return (med, AggregationResult.Consensus);
        }

        // Check for a single outlier >15pts from median
        bool aOutlier = _absDiff(a, med) > OUTLIER_THRESHOLD;
        bool bOutlier = _absDiff(b, med) > OUTLIER_THRESHOLD;
        bool cOutlier = _absDiff(c, med) > OUTLIER_THRESHOLD;

        uint8 outlierCount = (aOutlier ? 1 : 0) + (bOutlier ? 1 : 0) + (cOutlier ? 1 : 0);

        // Rule 2: Exactly one outlier → discard it, average the other two
        if (outlierCount == 1) {
            uint8 avg;
            if (aOutlier) {
                avg = uint8((uint16(b) + uint16(c)) / 2);
            } else if (bOutlier) {
                avg = uint8((uint16(a) + uint16(c)) / 2);
            } else {
                avg = uint8((uint16(a) + uint16(b)) / 2);
            }
            return (avg, AggregationResult.OutlierDiscarded);
        }

        // Rule 3: All disagree → dispute, return 0 (blocks prize release)
        return (0, AggregationResult.Disputed);
    }

    // =========================================================================
    // Internal: Math helpers
    // =========================================================================

    /// @dev Median of 3 uint8 values — sort and take middle
    function _median3(uint8 a, uint8 b, uint8 c) internal pure returns (uint8) {
        if (a > b) (a, b) = (b, a);
        if (b > c) (b, c) = (c, b);
        if (a > b) (a, b) = (b, a);
        return b; // middle value after sort
    }

    /// @dev Maximum spread between any two of three values
    function _maxSpread(uint8 a, uint8 b, uint8 c) internal pure returns (uint8) {
        uint8 mn = a < b ? (a < c ? a : c) : (b < c ? b : c);
        uint8 mx = a > b ? (a > c ? a : c) : (b > c ? b : c);
        return mx - mn;
    }

    /// @dev Absolute difference between two uint8 values
    function _absDiff(uint8 a, uint8 b) internal pure returns (uint8) {
        return a > b ? a - b : b - a;
    }

    // =========================================================================
    // Admin
    // =========================================================================

    function transferOracle(address newOracle) external onlyOracle {
        if (newOracle == address(0)) revert ZeroAddress();
        emit OracleTransferred(oracle, newOracle);
        oracle = newOracle;
    }
}
