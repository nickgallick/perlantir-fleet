// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BoutsAgentSBT
 * @author Chain — Perlantir AI Studio
 * @notice Soulbound (non-transferable) NFT representing an AI agent's
 *         permanent on-chain identity in the Bouts competition platform.
 *
 * @dev Implements ERC-5192 minimal soulbound token standard.
 *      One token per agent. Minted on first challenge entry.
 *      Carries ELO rating, win/loss record, and weight class.
 *      ELO and stats are committed off-chain, anchored here.
 *
 *      Token ID = sequential uint256
 *      Agent identity = agentId (UUID string from Supabase)
 */
contract BoutsAgentSBT {

    // =========================================================================
    // Events
    // =========================================================================

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Locked(uint256 tokenId);
    event AgentMinted(uint256 indexed tokenId, string agentId, address indexed owner, string weightClass);
    event RatingUpdated(uint256 indexed tokenId, uint16 previousElo, uint16 newElo, bytes32 commitmentHash);
    event OracleTransferred(address indexed previousOracle, address indexed newOracle);

    // =========================================================================
    // Errors
    // =========================================================================

    error OnlyOracle();
    error ZeroAddress();
    error Soulbound();
    error AgentAlreadyMinted();
    error TokenNotFound();
    error InvalidElo();
    error EmptyAgentId();

    // =========================================================================
    // Types
    // =========================================================================

    struct AgentProfile {
        string agentId;           // UUID from Supabase — permanent identifier
        string weightClass;       // frontier/contender/scrapper/underdog/homebrew/open
        address owner;            // wallet address of agent owner
        uint16 eloRating;         // current ELO rating (default 1200)
        uint16 eloPeak;           // all-time peak ELO
        uint32 challengesPlayed;  // total challenges entered
        uint32 wins;              // total wins
        uint32 losses;            // total losses
        uint256 mintedAt;         // block.timestamp of first challenge entry
        bytes32 lastEloCommit;    // keccak256(agentId, newElo, challengeId, timestamp)
    }

    // =========================================================================
    // State
    // =========================================================================

    string public constant name   = "Bouts Agent";
    string public constant symbol = "BOUTS";

    address public oracle;

    uint256 private _tokenIdCounter;

    /// @notice tokenId → AgentProfile
    mapping(uint256 => AgentProfile) private _profiles;

    /// @notice agentId (UUID) → tokenId — for fast lookup
    mapping(string => uint256) public agentIdToTokenId;

    /// @notice tokenId → owner address (ERC-721 compatible)
    mapping(uint256 => address) private _owners;

    /// @notice owner → token count
    mapping(address => uint256) private _balances;

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor(address _oracle) {
        if (_oracle == address(0)) revert ZeroAddress();
        oracle = _oracle;
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
    // ERC-5192: Soulbound
    // =========================================================================

    /// @notice All tokens are permanently locked — non-transferable
    function locked(uint256 tokenId) external view returns (bool) {
        if (_owners[tokenId] == address(0)) revert TokenNotFound();
        return true;
    }

    // =========================================================================
    // ERC-721: Read-only interface (no transfers)
    // =========================================================================

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenNotFound();
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /// @dev Soulbound — all transfer/approval functions revert
    function transferFrom(address, address, uint256) external pure {
        revert Soulbound();
    }

    function safeTransferFrom(address, address, uint256) external pure {
        revert Soulbound();
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure {
        revert Soulbound();
    }

    function approve(address, uint256) external pure {
        revert Soulbound();
    }

    function setApprovalForAll(address, bool) external pure {
        revert Soulbound();
    }

    // =========================================================================
    // Core: Mint
    // =========================================================================

    /**
     * @notice Mint a soulbound agent identity NFT.
     *         Called on an agent's FIRST challenge entry — never before.
     *
     * @param to          The agent owner's wallet address
     * @param agentId     The agent's UUID from Supabase (permanent)
     * @param weightClass The agent's weight class at time of minting
     *
     * @dev Each agentId can only be minted once.
     *      tokenId is sequential starting from 1.
     */
    function mint(
        address to,
        string calldata agentId,
        string calldata weightClass
    ) external onlyOracle returns (uint256 tokenId) {
        if (to == address(0)) revert ZeroAddress();
        if (bytes(agentId).length == 0) revert EmptyAgentId();
        if (agentIdToTokenId[agentId] != 0) revert AgentAlreadyMinted();

        _tokenIdCounter++;
        tokenId = _tokenIdCounter;

        _owners[tokenId] = to;
        _balances[to]++;
        agentIdToTokenId[agentId] = tokenId;

        _profiles[tokenId] = AgentProfile({
            agentId:          agentId,
            weightClass:      weightClass,
            owner:            to,
            eloRating:        1200,
            eloPeak:          1200,
            challengesPlayed: 1,      // first challenge entry triggered the mint
            wins:             0,
            losses:           0,
            mintedAt:         block.timestamp,
            lastEloCommit:    bytes32(0)
        });

        emit Transfer(address(0), to, tokenId);
        emit Locked(tokenId);
        emit AgentMinted(tokenId, agentId, to, weightClass);
    }

    // =========================================================================
    // Core: Update rating
    // =========================================================================

    /**
     * @notice Commit an updated ELO rating and stats after a challenge resolves.
     *
     * @param tokenId        The agent's token ID
     * @param newElo         New ELO rating (must be 400-4000)
     * @param wins           Updated total wins
     * @param losses         Updated total losses
     * @param played         Updated total challenges played
     * @param commitmentHash keccak256(agentId, newElo, challengeId, timestamp)
     *                       Allows off-chain verification of rating history
     *
     * @dev ELO is computed off-chain and committed here.
     *      The commitment hash anchors the calculation to a specific challenge.
     */
    function updateRating(
        uint256 tokenId,
        uint16 newElo,
        uint32 wins,
        uint32 losses,
        uint32 played,
        bytes32 commitmentHash
    ) external onlyOracle {
        if (_owners[tokenId] == address(0)) revert TokenNotFound();
        if (newElo < 400 || newElo > 4000) revert InvalidElo();

        AgentProfile storage profile = _profiles[tokenId];
        uint16 previousElo = profile.eloRating;

        profile.eloRating        = newElo;
        profile.wins             = wins;
        profile.losses           = losses;
        profile.challengesPlayed = played;
        profile.lastEloCommit    = commitmentHash;

        if (newElo > profile.eloPeak) {
            profile.eloPeak = newElo;
        }

        emit RatingUpdated(tokenId, previousElo, newElo, commitmentHash);
    }

    /**
     * @notice Update weight class (e.g. agent switches model tier)
     */
    function updateWeightClass(
        uint256 tokenId,
        string calldata newWeightClass
    ) external onlyOracle {
        if (_owners[tokenId] == address(0)) revert TokenNotFound();
        _profiles[tokenId].weightClass = newWeightClass;
    }

    // =========================================================================
    // View: Read profile
    // =========================================================================

    function getProfile(uint256 tokenId) external view returns (AgentProfile memory) {
        if (_owners[tokenId] == address(0)) revert TokenNotFound();
        return _profiles[tokenId];
    }

    function getProfileByAgentId(string calldata agentId) external view returns (AgentProfile memory, uint256 tokenId) {
        tokenId = agentIdToTokenId[agentId];
        if (tokenId == 0) revert TokenNotFound();
        return (_profiles[tokenId], tokenId);
    }

    function isMinted(string calldata agentId) external view returns (bool) {
        return agentIdToTokenId[agentId] != 0;
    }

    // =========================================================================
    // ERC-165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC-165
            interfaceId == 0x80ac58cd || // ERC-721
            interfaceId == 0xb45a3c0e;   // ERC-5192
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
