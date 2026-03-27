// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SpartaBadges — Soulbound ERC-1155 Achievement System
 * @notice Non-transferable achievement badges with fully on-chain SVG metadata
 * @dev ERC-5192 soulbound, ERC-1155 multi-badge per address
 *
 * BADGE IDs:
 *   0 = Founding Agent    (first 1,000 agents — historical, not skill-based)
 *   1 = Bronze Champion   (Achieve Bronze tier)
 *   2 = Silver Champion   (Achieve Silver tier)
 *   3 = Gold Champion     (Achieve Gold tier)
 *   4 = Diamond Champion  (Achieve Diamond tier — <1% of agents)
 *   5 = First Blood       (Win your first challenge)
 *   6 = Centurion         (Win 100 challenges)
 *   7 = Perfect Season    (10-0 in any season)
 *   8 = Slayer            (Beat a Diamond-tier agent)
 *   9 = Unbroken          (Win 10 consecutive challenges)
 *  10 = Oracle            (Correctly predict 20+ market outcomes)
 *  11 = Season 1 Legend   (Top 10 on Season 1 leaderboard)
 *
 * SOULBOUND: Badges CANNOT be transferred. They are permanent on-chain achievements.
 * This prevents badge markets, which would undermine the achievement system.
 */

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract SpartaBadges is ERC1155, AccessControl {
    using Strings for uint256;

    // ─── Roles ────────────────────────────────────────────────────────────────
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");  // Arena contract
    bytes32 public constant ADMIN_ROLE  = keccak256("ADMIN");   // Multisig

    // ─── Badge definitions ───────────────────────────────────────────────────
    struct BadgeDef {
        string  name;
        string  description;
        string  emoji;
        string  color;    // Hex bg color
        string  accent;   // Hex accent color
        uint256 maxSupply; // 0 = unlimited
        uint256 minted;
        bool    active;
    }

    mapping(uint256 => BadgeDef) public badges;
    uint256 public constant BADGE_COUNT = 12;

    // ─── Claim guard ──────────────────────────────────────────────────────────
    // Bitmap: address → which badges they hold (256 possible badges)
    mapping(address => uint256) public badgeBitmap;

    // ─── Events ───────────────────────────────────────────────────────────────
    event BadgeAwarded(address indexed recipient, uint256 indexed badgeId, string badgeName);

    // ─── Constructor ──────────────────────────────────────────────────────────
    constructor(address admin, address arena) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE,  admin);
        _grantRole(MINTER_ROLE, arena);
        _initBadges();
    }

    function _initBadges() internal {
        badges[0]  = BadgeDef("Founding Agent",   "One of the first 1,000 agents.",          "\xF0\x9F\x8F\x9B",  "1A1A2E", "E94560", 1000, 0, true);
        badges[1]  = BadgeDef("Bronze Champion",  "Reached Bronze tier (1000+ ELO).",        "\xF0\x9F\xA5\x89",  "4A2C00", "CD7F32", 0,    0, true);
        badges[2]  = BadgeDef("Silver Champion",  "Reached Silver tier (1400+ ELO).",        "\xF0\x9F\xA5\x88",  "1A1A1A", "C0C0C0", 0,    0, true);
        badges[3]  = BadgeDef("Gold Champion",    "Reached Gold tier (1800+ ELO).",          "\xF0\x9F\x8F\x86",  "2D2000", "FFD700", 0,    0, true);
        badges[4]  = BadgeDef("Diamond Champion", "Reached Diamond tier (2200+ ELO).",       "\xF0\x9F\x92\x8E",  "0D1B2A", "B9F2FF", 0,    0, true);
        badges[5]  = BadgeDef("First Blood",      "Won your first challenge.",               "\xE2\x9A\x94",      "1A0000", "FF4444", 0,    0, true);
        badges[6]  = BadgeDef("Centurion",        "Won 100 challenges.",                     "\xF0\x9F\x9B\xA1",  "0D0D0D", "FF8C00", 0,    0, true);
        badges[7]  = BadgeDef("Perfect Season",   "10-0 in a single season.",               "\xE2\xAD\x90",      "000D1A", "00D4FF", 0,    0, true);
        badges[8]  = BadgeDef("Giant Slayer",     "Defeated a Diamond-tier agent.",         "\xE2\x9A\xA1",      "0A0A1A", "8B00FF", 0,    0, true);
        badges[9]  = BadgeDef("Unbroken",         "Won 10 consecutive challenges.",          "\xF0\x9F\x94\xA5",  "1A0D00", "FF6B00", 0,    0, true);
        badges[10] = BadgeDef("Oracle",           "Correctly predicted 20+ market outcomes.","\xF0\x9F\x94\xAE", "001A0D", "00FF88", 0,    0, true);
        badges[11] = BadgeDef("Season 1 Legend",  "Top 10 on Season 1 leaderboard.",        "\xF0\x9F\x91\x91",  "1A1000", "FFD700", 10,   0, true);
    }

    // ─── Minting ──────────────────────────────────────────────────────────────

    /// @notice Award a badge to an agent. Called by Arena contract.
    function awardBadge(address recipient, uint256 badgeId) external onlyRole(MINTER_ROLE) {
        require(badgeId < BADGE_COUNT, "Invalid badge ID");
        BadgeDef storage badge = badges[badgeId];
        require(badge.active, "Badge not active");
        require(!hasBadge(recipient, badgeId), "Already awarded");
        if (badge.maxSupply > 0) {
            require(badge.minted < badge.maxSupply, "Max supply reached");
        }

        badge.minted++;
        _setBadgeBit(recipient, badgeId);
        _mint(recipient, badgeId, 1, "");

        emit BadgeAwarded(recipient, badgeId, badge.name);
    }

    /// @notice Batch award multiple badges to one recipient
    function awardBadges(address recipient, uint256[] calldata badgeIds) external onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < badgeIds.length; i++) {
            uint256 id = badgeIds[i];
            if (!hasBadge(recipient, id) && id < BADGE_COUNT && badges[id].active) {
                if (badges[id].maxSupply == 0 || badges[id].minted < badges[id].maxSupply) {
                    badges[id].minted++;
                    _setBadgeBit(recipient, id);
                    _mint(recipient, id, 1, "");
                    emit BadgeAwarded(recipient, id, badges[id].name);
                }
            }
        }
    }

    // ─── Soulbound: block ALL transfers ──────────────────────────────────────

    /// @dev Override to block safeTransferFrom
    function safeTransferFrom(
        address, address, uint256, uint256, bytes memory
    ) public pure override {
        revert("Soulbound: non-transferable");
    }

    /// @dev Override to block safeBatchTransferFrom
    function safeBatchTransferFrom(
        address, address, uint256[] memory, uint256[] memory, bytes memory
    ) public pure override {
        revert("Soulbound: non-transferable");
    }

    /// @dev ERC-5192: returns true = permanently locked
    function locked(uint256) external pure returns (bool) { return true; }

    // ─── Fully On-Chain Metadata ──────────────────────────────────────────────

    function uri(uint256 badgeId) public view override returns (string memory) {
        require(badgeId < BADGE_COUNT, "Invalid badge ID");
        BadgeDef storage badge = badges[badgeId];

        string memory svg  = _buildSVG(badgeId, badge);
        string memory meta = string(abi.encodePacked(
            '{"name":"',        badge.name,
            '","description":"', badge.description,
            '","image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '","attributes":[',
            '{"trait_type":"Type","value":"Achievement Badge"},',
            '{"trait_type":"Soulbound","value":"Yes"},',
            '{"trait_type":"Max Supply","value":"', badge.maxSupply == 0 ? "Unlimited" : badge.maxSupply.toString(), '"},',
            '{"trait_type":"Total Awarded","display_type":"number","value":', badge.minted.toString(), '}',
            ']}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(meta))
        ));
    }

    function _buildSVG(uint256 badgeId, BadgeDef storage badge) internal view returns (string memory) {
        // Unique visual for each badge tier: hexagonal badge shape + glow effect
        string memory supplyLine = badge.maxSupply > 0
            ? string(abi.encodePacked(badge.minted.toString(), " / ", badge.maxSupply.toString()))
            : string(abi.encodePacked(badge.minted.toString(), " awarded"));

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">',

            // Defs: gradient + glow filter
            '<defs>',
            '<radialGradient id="bg" cx="50%" cy="50%" r="50%">',
            '<stop offset="0%" style="stop-color:#', badge.accent, ';stop-opacity:0.15"/>',
            '<stop offset="100%" style="stop-color:#', badge.color, ';stop-opacity:1"/>',
            '</radialGradient>',
            '<filter id="glow"><feGaussianBlur stdDeviation="4" result="blur"/>',
            '<feComposite in="SourceGraphic" in2="blur" operator="over"/></filter>',
            '</defs>',

            // Background
            '<rect width="400" height="400" rx="24" fill="url(#bg)"/>',

            // Hexagonal badge border (SVG polygon)
            '<polygon points="200,30 350,110 350,290 200,370 50,290 50,110" ',
            'fill="none" stroke="#', badge.accent, '" stroke-width="3" ',
            'opacity="0.6" filter="url(#glow)"/>',

            // Inner hex
            '<polygon points="200,60 320,125 320,275 200,340 80,275 80,125" ',
            'fill="rgba(255,255,255,0.05)" stroke="#', badge.accent, '" stroke-width="1.5" opacity="0.4"/>',

            // Emoji (large center)
            '<text x="200" y="200" text-anchor="middle" dominant-baseline="middle" ',
            'font-size="80">', badge.emoji, '</text>',

            // Badge name
            '<text x="200" y="285" text-anchor="middle" ',
            'font-family="Georgia,serif" font-size="20" font-weight="bold" ',
            'fill="white" filter="url(#glow)">', badge.name, '</text>',

            // SPARTA ARENA label (top)
            '<text x="200" y="50" text-anchor="middle" ',
            'font-family="Arial,sans-serif" font-size="11" letter-spacing="4" ',
            'fill="#', badge.accent, '" opacity="0.9">SPARTA ARENA</text>',

            // SOULBOUND label (bottom)
            '<text x="200" y="365" text-anchor="middle" ',
            'font-family="Arial,sans-serif" font-size="10" letter-spacing="2" ',
            'fill="rgba(255,255,255,0.4)">SOULBOUND \xE2\x80\xA2 NON-TRANSFERABLE</text>',

            // Supply indicator
            '<text x="200" y="345" text-anchor="middle" ',
            'font-family="Arial,sans-serif" font-size="11" ',
            'fill="rgba(255,255,255,0.5)">', supplyLine, '</text>',

            // Badge ID (subtle top-right)
            '<text x="370" y="30" text-anchor="end" ',
            'font-family="monospace" font-size="10" fill="rgba(255,255,255,0.3)">',
            '#', badgeId.toString(), '</text>',

            '</svg>'
        ));
    }

    // ─── View Helpers ─────────────────────────────────────────────────────────

    function hasBadge(address account, uint256 badgeId) public view returns (bool) {
        return (badgeBitmap[account] >> badgeId) & 1 == 1;
    }

    /// @notice Returns array of badge IDs held by account
    function getBadges(address account) external view returns (uint256[] memory) {
        uint256 bitmap = badgeBitmap[account];
        uint256 count;
        for (uint i = 0; i < BADGE_COUNT; i++) {
            if ((bitmap >> i) & 1 == 1) count++;
        }
        uint256[] memory result = new uint256[](count);
        uint256 idx;
        for (uint i = 0; i < BADGE_COUNT; i++) {
            if ((bitmap >> i) & 1 == 1) result[idx++] = i;
        }
        return result;
    }

    /// @notice Total unique badges an account holds
    function badgeCount(address account) external view returns (uint256) {
        uint256 bitmap = badgeBitmap[account];
        uint256 count;
        while (bitmap > 0) { count += bitmap & 1; bitmap >>= 1; }
        return count;
    }

    function _setBadgeBit(address account, uint256 badgeId) internal {
        badgeBitmap[account] |= (1 << badgeId);
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    function setArena(address arena) external onlyRole(ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, arena);
    }

    function revokeArena(address arena) external onlyRole(ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, arena);
    }

    function deactivateBadge(uint256 badgeId) external onlyRole(ADMIN_ROLE) {
        badges[badgeId].active = false;
    }

    // ─── Interface support ────────────────────────────────────────────────────
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC1155, AccessControl)
        returns (bool)
    {
        return interfaceId == 0xb45a3c0e // ERC-5192
            || super.supportsInterface(interfaceId);
    }
}
