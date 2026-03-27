// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BoutsJudgeCommit
 * @author Chain — Perlantir AI Studio
 * @notice Commit-reveal integrity layer for the Bouts multi-provider judge system.
 *
 * @dev Flow:
 *   1. After each AI judge scores a submission, the backend commits a hash of
 *      (entryId, provider, score, salt) on-chain BEFORE storing the plaintext score.
 *   2. After all 3 providers have committed, the backend reveals each score.
 *   3. The contract verifies the reveal matches the original commitment.
 *   4. All scores are permanently on-chain — nobody can change them after commitment.
 *
 * This proves to users that scores were locked before being revealed,
 * preventing any post-hoc manipulation.
 *
 * Providers: "claude" | "gpt4o" | "gemini"
 * Score range: 10–100 (maps 1.0–10.0 × 10, integer)
 */
contract BoutsJudgeCommit {
    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted when a judge commits a score hash
    event Committed(
        bytes32 indexed entryId,
        string provider,
        bytes32 commitment,
        uint256 timestamp
    );

    /// @notice Emitted when a judge reveals a score
    event Revealed(
        bytes32 indexed entryId,
        string provider,
        uint8 score,
        uint256 timestamp
    );

    /// @notice Emitted when oracle address is transferred
    event OracleTransferred(address indexed previousOracle, address indexed newOracle);

    // =========================================================================
    // Errors
    // =========================================================================

    error OnlyOracle();
    error InvalidProvider();
    error AlreadyCommitted();
    error NotCommitted();
    error AlreadyRevealed();
    error InvalidReveal();
    error InvalidScore();
    error ZeroAddress();

    // =========================================================================
    // State
    // =========================================================================

    /// @notice The oracle address — only this address can commit and reveal
    address public oracle;

    /// @notice Valid providers — enforced on commit/reveal
    mapping(string => bool) private _validProviders;

    /// @notice commitments[entryId][provider] = keccak256(entryId, provider, score, salt)
    mapping(bytes32 => mapping(string => bytes32)) public commitments;

    /// @notice revealed scores — 0 means not yet revealed
    mapping(bytes32 => mapping(string => uint8)) public reveals;

    /// @notice whether a provider has revealed for a given entry
    mapping(bytes32 => mapping(string => bool)) public isRevealed;

    /// @notice commit timestamps for auditability
    mapping(bytes32 => mapping(string => uint256)) public commitTimestamps;

    /// @notice reveal timestamps for auditability
    mapping(bytes32 => mapping(string => uint256)) public revealTimestamps;

    // =========================================================================
    // Constructor
    // =========================================================================

    /**
     * @param _oracle The address permitted to commit and reveal scores.
     *                Should be the backend deployer wallet — fund with ~0.05 ETH.
     */
    constructor(address _oracle) {
        if (_oracle == address(0)) revert ZeroAddress();
        oracle = _oracle;

        // Register valid providers
        _validProviders["claude"] = true;
        _validProviders["gpt4o"] = true;
        _validProviders["gemini"] = true;

        emit OracleTransferred(address(0), _oracle);
    }

    // =========================================================================
    // Modifiers
    // =========================================================================

    modifier onlyOracle() {
        if (msg.sender != oracle) revert OnlyOracle();
        _;
    }

    modifier validProvider(string calldata provider) {
        if (!_validProviders[provider]) revert InvalidProvider();
        _;
    }

    // =========================================================================
    // Core: Commit
    // =========================================================================

    /**
     * @notice Commit a judge score hash before the score is revealed.
     *
     * @param entryId    The submission entry ID (UUID as bytes32)
     * @param provider   The judge provider: "claude", "gpt4o", or "gemini"
     * @param commitment keccak256(abi.encodePacked(entryId, provider, score, salt))
     *
     * @dev The backend generates a random salt per judge per entry,
     *      computes the commitment off-chain, then calls this function.
     *      The score remains unknown on-chain until reveal().
     */
    function commit(
        bytes32 entryId,
        string calldata provider,
        bytes32 commitment
    ) external onlyOracle validProvider(provider) {
        if (commitments[entryId][provider] != bytes32(0)) revert AlreadyCommitted();

        commitments[entryId][provider] = commitment;
        commitTimestamps[entryId][provider] = block.timestamp;

        emit Committed(entryId, provider, commitment, block.timestamp);
    }

    // =========================================================================
    // Core: Reveal
    // =========================================================================

    /**
     * @notice Reveal a judge score, verifying it matches the commitment.
     *
     * @param entryId  The submission entry ID (UUID as bytes32)
     * @param provider The judge provider: "claude", "gpt4o", or "gemini"
     * @param score    The judge's overall score × 10 (range: 10–100)
     * @param salt     The random salt used when generating the commitment
     *
     * @dev Reverts if the reconstructed commitment doesn't match.
     *      Score 10 = 1.0/10, score 100 = 10.0/10.
     */
    function reveal(
        bytes32 entryId,
        string calldata provider,
        uint8 score,
        bytes32 salt
    ) external onlyOracle validProvider(provider) {
        if (commitments[entryId][provider] == bytes32(0)) revert NotCommitted();
        if (isRevealed[entryId][provider]) revert AlreadyRevealed();
        if (score < 10 || score > 100) revert InvalidScore();

        bytes32 expected = keccak256(abi.encodePacked(entryId, provider, score, salt));
        if (expected != commitments[entryId][provider]) revert InvalidReveal();

        reveals[entryId][provider] = score;
        isRevealed[entryId][provider] = true;
        revealTimestamps[entryId][provider] = block.timestamp;

        emit Revealed(entryId, provider, score, block.timestamp);
    }

    // =========================================================================
    // View: Get all reveals for an entry
    // =========================================================================

    /**
     * @notice Read all three provider scores for a submission entry.
     *
     * @param entryId The submission entry ID
     * @return claude  Claude's score (0 if not yet revealed)
     * @return gpt4o   GPT-4o's score (0 if not yet revealed)
     * @return gemini  Gemini's score (0 if not yet revealed)
     * @return allRevealed True only when all 3 providers have revealed
     */
    function getReveals(bytes32 entryId)
        external
        view
        returns (
            uint8 claude,
            uint8 gpt4o,
            uint8 gemini,
            bool allRevealed
        )
    {
        claude = reveals[entryId]["claude"];
        gpt4o  = reveals[entryId]["gpt4o"];
        gemini = reveals[entryId]["gemini"];
        allRevealed =
            isRevealed[entryId]["claude"] &&
            isRevealed[entryId]["gpt4o"]  &&
            isRevealed[entryId]["gemini"];
    }

    /**
     * @notice Check commitment status for a single provider.
     *
     * @param entryId  The submission entry ID
     * @param provider The judge provider
     * @return committed  Whether a commitment exists
     * @return revealed   Whether the score has been revealed
     * @return score      The revealed score (0 if not revealed)
     * @return committedAt Block timestamp of commitment (0 if not committed)
     * @return revealedAt  Block timestamp of reveal (0 if not revealed)
     */
    function getProviderStatus(bytes32 entryId, string calldata provider)
        external
        view
        returns (
            bool committed,
            bool revealed,
            uint8 score,
            uint256 committedAt,
            uint256 revealedAt
        )
    {
        committed   = commitments[entryId][provider] != bytes32(0);
        revealed    = isRevealed[entryId][provider];
        score       = reveals[entryId][provider];
        committedAt = commitTimestamps[entryId][provider];
        revealedAt  = revealTimestamps[entryId][provider];
    }

    /**
     * @notice Reconstruct a commitment hash for verification purposes.
     *         Useful for off-chain testing and debugging.
     *
     * @param entryId  The submission entry ID
     * @param provider The judge provider string
     * @param score    The score (10–100)
     * @param salt     The random salt
     * @return The keccak256 commitment hash
     */
    function computeCommitment(
        bytes32 entryId,
        string calldata provider,
        uint8 score,
        bytes32 salt
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(entryId, provider, score, salt));
    }

    // =========================================================================
    // Admin: Oracle management
    // =========================================================================

    /**
     * @notice Transfer oracle role to a new address.
     *         Use to rotate the backend wallet without redeploying.
     *
     * @param newOracle The new oracle address
     */
    function transferOracle(address newOracle) external onlyOracle {
        if (newOracle == address(0)) revert ZeroAddress();
        emit OracleTransferred(oracle, newOracle);
        oracle = newOracle;
    }
}
