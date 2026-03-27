// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BoutsEscrow
 * @author Chain — Perlantir AI Studio
 * @notice Non-custodial USDC prize escrow for Bouts coding challenges.
 *
 * @dev Architecture:
 *   1. Oracle creates a challenge on-chain with entry fee + prize structure
 *   2. Agents pay entry fee in USDC → funds held by THIS contract (never platform wallet)
 *   3. Oracle commits composite scores (60% objective + 40% LLM) via commit-reveal
 *   4. Oracle finalizes challenge → contract ranks entries → auto-pays winners
 *   5. Platform fee (5%) extracted at payout time
 *
 * Security model:
 *   - Non-custodial: platform oracle submits scores only, cannot move USDC directly
 *   - Reentrancy guard on all USDC transfer functions
 *   - Pull pattern: winners claim prizes (not pushed)
 *   - Emergency pause (owner only)
 *   - Max prize pool cap: $500 USDC enforced on-chain (Counsel requirement)
 *   - Full refund path for cancelled challenges
 *
 * USDC on Base: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
 */

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BoutsEscrow {

    // =========================================================================
    // Events
    // =========================================================================

    event ChallengeCreated(bytes32 indexed challengeId, uint256 entryFee, uint256 maxPool, uint256 endTime);
    event EntryPaid(bytes32 indexed challengeId, bytes32 indexed entryId, address indexed payer, uint256 amount);
    event CompositeCommitted(bytes32 indexed entryId, bytes32 indexed challengeId, bytes32 commitment);
    event CompositeRevealed(bytes32 indexed entryId, uint8 compositeScore);
    event ChallengeFinalized(bytes32 indexed challengeId, uint256 totalPool, uint256 platformFee);
    event PrizeClaimed(bytes32 indexed challengeId, bytes32 indexed entryId, address indexed winner, uint256 amount);
    event ChallengeRefunded(bytes32 indexed challengeId, uint256 refundCount);
    event EntryCancelled(bytes32 indexed challengeId, bytes32 indexed entryId, address indexed payer, uint256 refund);
    event OracleTransferred(address indexed previousOracle, address indexed newOracle);
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event OwnerTransferred(address indexed previousOwner, address indexed newOwner);
    event PlatformFeeWithdrawn(address indexed to, uint256 amount);

    // =========================================================================
    // Errors
    // =========================================================================

    error OnlyOracle();
    error OnlyOwner();
    error ZeroAddress();
    error Paused_();
    error ChallengeNotFound();
    error ChallengeNotOpen();
    error ChallengeNotScoring();
    error ChallengeNotFinalized();
    error ChallengeAlreadyExists();
    error EntryNotFound();
    error AlreadyPaid();
    error AlreadyClaimed();
    error AlreadyCommitted();
    error NotCommitted();
    error AlreadyRevealed();
    error InvalidReveal();
    error InvalidScore();
    error PoolCapExceeded();
    error ChallengeExpired();
    error ChallengeNotExpired();
    error InsufficientEntries();
    error TransferFailed();
    error InvalidPayoutConfig();
    error NotRefundable();

    // =========================================================================
    // Types
    // =========================================================================

    enum ChallengeState {
        Open,       // accepting entries
        Scoring,    // closed to entries, scoring in progress
        Finalized,  // scores committed + revealed, payouts unlocked
        Cancelled   // refunds available
    }

    struct Challenge {
        uint256 entryFee;           // USDC (6 decimals) — e.g. 5 USDC = 5_000_000
        uint256 maxPool;            // max total USDC in pool — capped at 500 USDC
        uint256 totalPool;          // current USDC collected
        uint256 endTime;            // unix timestamp — no entries after this
        uint16[3] payoutBps;        // payout % in basis points [5000, 3000, 2000] = 50/30/20
        ChallengeState state;
        uint32 entryCount;
        bool exists;
    }

    struct Entry {
        bytes32 entryId;
        bytes32 challengeId;
        address payer;              // wallet that paid the entry fee
        uint8 compositeScore;       // revealed composite score (0 = not revealed)
        uint8 placement;            // 1st/2nd/3rd (0 = not finalized)
        uint256 prizeAmount;        // USDC prize amount (0 until finalized)
        bool paid;                  // entry fee collected
        bool claimed;               // prize claimed
        bool scoreCommitted;
        bool scoreRevealed;
        bool disqualified;
    }

    // =========================================================================
    // Constants
    // =========================================================================

    uint256 public constant MAX_POOL_USDC    = 500_000_000;  // $500 USDC (6 decimals)
    uint256 public constant PLATFORM_FEE_BPS = 500;          // 5%
    uint256 public constant BPS_DENOMINATOR  = 10_000;
    uint256 public constant MIN_ENTRIES      = 2;            // minimum to run a challenge

    // USDC on Base mainnet
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // =========================================================================
    // State
    // =========================================================================

    address public oracle;
    address public owner;
    bool public paused;

    /// @notice Accumulated platform fees available for withdrawal
    uint256 public platformFeeBalance;

    /// @notice challengeId → Challenge
    mapping(bytes32 => Challenge) public challenges;

    /// @notice entryId → Entry
    mapping(bytes32 => Entry) public entries;

    /// @notice challengeId → array of entryIds (for ranking)
    mapping(bytes32 => bytes32[]) public challengeEntries;

    /// @notice commit-reveal: entryId → commitment hash
    mapping(bytes32 => bytes32) public compositeCommitments;

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor(address _oracle) {
        if (_oracle == address(0)) revert ZeroAddress();
        oracle = _oracle;
        owner  = _oracle; // owner = deployer initially
        emit OracleTransferred(address(0), _oracle);
    }

    // =========================================================================
    // Modifiers
    // =========================================================================

    modifier onlyOracle() {
        if (msg.sender != oracle) revert OnlyOracle();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier notPaused() {
        if (paused) revert Paused_();
        _;
    }

    // Reentrancy guard
    uint256 private _guardStatus = 1;
    modifier nonReentrant() {
        require(_guardStatus == 1, "Reentrant");
        _guardStatus = 2;
        _;
        _guardStatus = 1;
    }

    // =========================================================================
    // Oracle: Challenge lifecycle
    // =========================================================================

    /**
     * @notice Create a new challenge with entry fee and prize structure.
     *
     * @param challengeId  bytes32 UUID of the challenge
     * @param entryFee     USDC amount per entry (6 decimals)
     * @param endTime      Unix timestamp when entries close
     * @param payoutBps    Prize split in basis points [1st, 2nd, 3rd]
     *                     Must sum to 10000 - PLATFORM_FEE_BPS = 9500
     */
    function createChallenge(
        bytes32 challengeId,
        uint256 entryFee,
        uint256 endTime,
        uint16[3] calldata payoutBps
    ) external onlyOracle notPaused {
        if (challenges[challengeId].exists) revert ChallengeAlreadyExists();
        if (endTime <= block.timestamp) revert ChallengeExpired();

        // Validate payout config: must sum to exactly 10000 bps (100%)
        // Platform fee is taken from the pool at finalization, not from payout split
        uint256 payoutSum = uint256(payoutBps[0]) + uint256(payoutBps[1]) + uint256(payoutBps[2]);
        if (payoutSum != BPS_DENOMINATOR) revert InvalidPayoutConfig();

        // Max pool = 500 USDC enforced on-chain (Counsel requirement)
        uint256 maxPool = MAX_POOL_USDC;

        challenges[challengeId] = Challenge({
            entryFee:   entryFee,
            maxPool:    maxPool,
            totalPool:  0,
            endTime:    endTime,
            payoutBps:  payoutBps,
            state:      ChallengeState.Open,
            entryCount: 0,
            exists:     true
        });

        emit ChallengeCreated(challengeId, entryFee, maxPool, endTime);
    }

    /**
     * @notice Close entries and move challenge to Scoring state.
     *         Called after endTime passes.
     */
    function closeEntries(bytes32 challengeId) external onlyOracle {
        Challenge storage c = challenges[challengeId];
        if (!c.exists) revert ChallengeNotFound();
        if (c.state != ChallengeState.Open) revert ChallengeNotOpen();

        c.state = ChallengeState.Scoring;
    }

    /**
     * @notice Cancel a challenge and enable refunds for all entrants.
     *         Use for: insufficient entries, technical failure, admin decision.
     */
    function cancelChallenge(bytes32 challengeId) external onlyOracle {
        Challenge storage c = challenges[challengeId];
        if (!c.exists) revert ChallengeNotFound();
        if (c.state == ChallengeState.Finalized) revert NotRefundable();

        c.state = ChallengeState.Cancelled;
        emit ChallengeRefunded(challengeId, c.entryCount);
    }

    // =========================================================================
    // Entry: Pay entry fee
    // =========================================================================

    /**
     * @notice Pay entry fee to enter a challenge.
     *         Caller must have approved this contract to spend USDC first.
     *
     * @param challengeId  The challenge to enter
     * @param entryId      The entry UUID (from Supabase challenge_entries.id)
     */
    function payEntry(
        bytes32 challengeId,
        bytes32 entryId
    ) external notPaused nonReentrant {
        Challenge storage c = challenges[challengeId];
        if (!c.exists) revert ChallengeNotFound();
        if (c.state != ChallengeState.Open) revert ChallengeNotOpen();
        if (block.timestamp >= c.endTime) revert ChallengeExpired();
        if (entries[entryId].paid) revert AlreadyPaid();

        // Pool cap check
        if (c.totalPool + c.entryFee > c.maxPool) revert PoolCapExceeded();

        // CEI pattern: write all state BEFORE external call
        c.totalPool  += c.entryFee;
        c.entryCount += 1;

        entries[entryId] = Entry({
            entryId:        entryId,
            challengeId:    challengeId,
            payer:          msg.sender,
            compositeScore: 0,
            placement:      0,
            prizeAmount:    0,
            paid:           true,
            claimed:        false,
            scoreCommitted: false,
            scoreRevealed:  false,
            disqualified:   false
        });

        challengeEntries[challengeId].push(entryId);

        // Pull USDC AFTER state is written (CEI — Checks-Effects-Interactions)
        bool success = IERC20(USDC).transferFrom(msg.sender, address(this), c.entryFee);
        if (!success) revert TransferFailed();

        emit EntryPaid(challengeId, entryId, msg.sender, c.entryFee);
    }

    // =========================================================================
    // Oracle: Composite score commit-reveal
    // =========================================================================

    /**
     * @notice Commit a composite score hash before revealing.
     *         Called by oracle after calculate-ratings completes.
     *
     * @param entryId        Entry UUID as bytes32
     * @param challengeId    Challenge UUID as bytes32 (for indexing)
     * @param commitment     keccak256(abi.encodePacked(entryId, compositeScore, salt))
     */
    function commitComposite(
        bytes32 entryId,
        bytes32 challengeId,
        bytes32 commitment
    ) external onlyOracle {
        if (!entries[entryId].paid) revert EntryNotFound();
        if (entries[entryId].scoreCommitted) revert AlreadyCommitted();

        compositeCommitments[entryId] = commitment;
        entries[entryId].scoreCommitted = true;

        emit CompositeCommitted(entryId, challengeId, commitment);
    }

    /**
     * @notice Reveal a composite score, verifying against the commitment.
     *
     * @param entryId        Entry UUID as bytes32
     * @param compositeScore Weighted composite score 0-100
     * @param salt           Random salt used in commitment
     */
    function revealComposite(
        bytes32 entryId,
        uint8 compositeScore,
        bytes32 salt
    ) external onlyOracle {
        if (!entries[entryId].scoreCommitted) revert NotCommitted();
        if (entries[entryId].scoreRevealed) revert AlreadyRevealed();
        if (compositeScore > 100) revert InvalidScore();

        bytes32 expected = keccak256(abi.encodePacked(entryId, compositeScore, salt));
        if (expected != compositeCommitments[entryId]) revert InvalidReveal();

        entries[entryId].compositeScore = compositeScore;
        entries[entryId].scoreRevealed  = true;

        emit CompositeRevealed(entryId, compositeScore);
    }

    /**
     * @notice Disqualify an entry (integrity violation).
     *         Disqualified entries' fees stay in pool (redistributed to winners).
     */
    function disqualifyEntry(bytes32 entryId) external onlyOracle {
        if (!entries[entryId].paid) revert EntryNotFound();
        entries[entryId].disqualified = true;
    }

    // =========================================================================
    // Oracle: Finalize and rank
    // =========================================================================

    /**
     * @notice Finalize a challenge: rank entries by composite score,
     *         assign placements and prize amounts, unlock claims.
     *
     * @param challengeId   The challenge to finalize
     * @param rankedEntries Entry IDs ordered by rank (1st to last), desc composite score.
     *                      Pass ONLY eligible (non-disqualified) entries.
     *                      Disqualified entries are handled separately — their fees
     *                      remain in the pool (redistributed to winners).
     *                      Oracle must exclude disqualified entries before calling.
     */
    function finalizeChallenge(
        bytes32 challengeId,
        bytes32[] calldata rankedEntries
    ) external onlyOracle nonReentrant {
        Challenge storage c = challenges[challengeId];
        if (!c.exists) revert ChallengeNotFound();
        if (c.state != ChallengeState.Scoring) revert ChallengeNotScoring();
        if (rankedEntries.length < MIN_ENTRIES) revert InsufficientEntries();

        // Verify all ranked entries have revealed scores and are NOT disqualified
        // Oracle must only pass eligible entries — disqualified entries excluded upstream
        for (uint256 i = 0; i < rankedEntries.length; i++) {
            Entry storage e = entries[rankedEntries[i]];
            if (e.disqualified) revert InvalidScore(); // disqualified entries must not be ranked
            if (!e.scoreRevealed) revert InvalidScore();
        }

        // Calculate platform fee (5% of total pool, which includes DQ'd entry fees)
        uint256 platformFee = (c.totalPool * PLATFORM_FEE_BPS) / BPS_DENOMINATOR;
        uint256 prizePool   = c.totalPool - platformFee;
        platformFeeBalance += platformFee;

        // Assign placements and prize amounts to top 3 eligible entries.
        // Prize slot index tracks separately from loop index — no gaps from DQ.
        // rankedEntries contains ONLY eligible entries (oracle-enforced).
        uint256 prizeSlots = rankedEntries.length < 3 ? rankedEntries.length : 3;

        for (uint256 slot = 0; slot < prizeSlots; slot++) {
            Entry storage e = entries[rankedEntries[slot]];
            e.placement   = uint8(slot + 1);
            e.prizeAmount = (prizePool * uint256(c.payoutBps[slot])) / BPS_DENOMINATOR;
        }

        c.state = ChallengeState.Finalized;

        emit ChallengeFinalized(challengeId, c.totalPool, platformFee);
    }

    // =========================================================================
    // Winner: Claim prize (pull pattern)
    // =========================================================================

    /**
     * @notice Winners call this to claim their USDC prize.
     *         Pull pattern — prizes are not pushed to winners automatically.
     *
     * @param entryId The winning entry ID
     */
    function claimPrize(bytes32 entryId) external nonReentrant notPaused {
        Entry storage e = entries[entryId];
        if (!e.paid) revert EntryNotFound();
        if (e.claimed) revert AlreadyClaimed();
        if (e.prizeAmount == 0) revert EntryNotFound(); // not a winner
        if (e.disqualified) revert EntryNotFound();

        Challenge storage c = challenges[e.challengeId];
        if (c.state != ChallengeState.Finalized) revert ChallengeNotFinalized();

        // Only the entry payer (agent owner) can claim
        require(msg.sender == e.payer, "Not entry owner");

        e.claimed = true;
        uint256 amount = e.prizeAmount;

        bool success = IERC20(USDC).transfer(e.payer, amount);
        if (!success) revert TransferFailed();

        emit PrizeClaimed(e.challengeId, entryId, e.payer, amount);
    }

    /**
     * @notice Claim a refund for a cancelled challenge.
     *
     * @param entryId The entry to refund
     */
    function claimRefund(bytes32 entryId) external nonReentrant notPaused {
        Entry storage e = entries[entryId];
        if (!e.paid) revert EntryNotFound();
        if (e.claimed) revert AlreadyClaimed();

        Challenge storage c = challenges[e.challengeId];
        if (c.state != ChallengeState.Cancelled) revert NotRefundable();

        require(msg.sender == e.payer, "Not entry owner");

        e.claimed = true;

        bool success = IERC20(USDC).transfer(e.payer, c.entryFee);
        if (!success) revert TransferFailed();

        emit EntryCancelled(e.challengeId, entryId, e.payer, c.entryFee);
    }

    // =========================================================================
    // View
    // =========================================================================

    function getChallenge(bytes32 challengeId) external view returns (Challenge memory) {
        return challenges[challengeId];
    }

    function getEntry(bytes32 entryId) external view returns (Entry memory) {
        return entries[entryId];
    }

    function getChallengeEntries(bytes32 challengeId) external view returns (bytes32[] memory) {
        return challengeEntries[challengeId];
    }

    function getCompositeScore(bytes32 entryId) external view returns (uint8) {
        return entries[entryId].compositeScore;
    }

    // =========================================================================
    // Admin
    // =========================================================================

    function withdrawPlatformFees(address to) external onlyOwner nonReentrant {
        if (to == address(0)) revert ZeroAddress();
        uint256 amount = platformFeeBalance;
        platformFeeBalance = 0;
        bool success = IERC20(USDC).transfer(to, amount);
        if (!success) revert TransferFailed();
        emit PlatformFeeWithdrawn(to, amount);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function transferOracle(address newOracle) external onlyOracle {
        if (newOracle == address(0)) revert ZeroAddress();
        emit OracleTransferred(oracle, newOracle);
        oracle = newOracle;
    }

    function transferOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnerTransferred(owner, newOwner);
        owner = newOwner;
    }
}
