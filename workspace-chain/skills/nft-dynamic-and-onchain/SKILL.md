# Dynamic & On-Chain NFTs

## On-Chain SVG NFT — Full Pattern

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicAgentNFT is ERC721 {
    using Strings for uint256;

    struct Agent {
        string  name;
        uint256 elo;
        uint8   tier;       // 0=Bronze 1=Silver 2=Gold 3=Diamond
        uint256 wins;
        uint256 losses;
        uint256 badges;     // Bitmask of earned badge IDs
    }

    mapping(uint256 => Agent) public agents;
    uint256 private _nextId;
    address public immutable arena; // Only arena contract can update stats

    string[4] private TIER_NAMES  = ["Bronze", "Silver", "Gold",    "Diamond"];
    string[4] private TIER_COLORS = ["CD7F32", "C0C0C0", "FFD700",  "B9F2FF"];
    string[4] private TIER_EMOJI  = ["\xF0\x9F\xA5\x89", "\xF0\x9F\xA5\x88", "\xF0\x9F\x8F\x86", "\xF0\x9F\x92\x8E"];

    event AgentEvolved(uint256 indexed tokenId, uint8 newTier);

    constructor(address _arena) ERC721("SpartaAgent", "AGENT") {
        arena = _arena;
    }

    function mint(address to, string calldata name) external returns (uint256) {
        uint256 id = _nextId++;
        agents[id] = Agent(name, 1000, 0, 0, 0, 0);
        _mint(to, id);
        return id;
    }

    // Called by arena contract after each challenge
    function updateStats(uint256 tokenId, bool won, uint256 eloChange) external {
        require(msg.sender == arena, "Only arena");
        Agent storage a = agents[tokenId];

        if (won) {
            a.wins++;
            a.elo += eloChange;
        } else {
            a.losses++;
            a.elo = a.elo > eloChange ? a.elo - eloChange : 0;
        }

        // Check tier upgrade
        uint8 newTier = _calculateTier(a.elo);
        if (newTier > a.tier) {
            a.tier = newTier;
            emit AgentEvolved(tokenId, newTier);
        }
    }

    function _calculateTier(uint256 elo) internal pure returns (uint8) {
        if (elo >= 2200) return 3; // Diamond
        if (elo >= 1800) return 2; // Gold
        if (elo >= 1400) return 1; // Silver
        return 0;                   // Bronze
    }

    // ─── Full on-chain metadata generation ───

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Nonexistent");
        Agent memory a = agents[tokenId];

        string memory svg     = _buildSVG(a, tokenId);
        string memory attrs   = _buildAttributes(a);
        string memory jsonRaw = string(abi.encodePacked(
            '{"name":"', a.name, ' #', tokenId.toString(), '",',
            '"description":"A Sparta Arena competitor.",',
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
            '"attributes":', attrs, '}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(jsonRaw))
        ));
    }

    function _buildSVG(Agent memory a, uint256 tokenId) internal view returns (string memory) {
        string memory bg    = TIER_COLORS[a.tier];
        string memory tier  = TIER_NAMES[a.tier];
        string memory emoji = TIER_EMOJI[a.tier];

        // Win rate bar width
        uint256 totalGames = a.wins + a.losses;
        uint256 winPct     = totalGames > 0 ? (a.wins * 100 / totalGames) : 50;
        uint256 barWidth   = winPct * 3; // max 300px

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400">',
            // Background gradient
            '<defs><linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:#', bg, ';stop-opacity:1"/>',
            '<stop offset="100%" style="stop-color:#111111;stop-opacity:1"/>',
            '</linearGradient></defs>',
            '<rect width="400" height="400" fill="url(#bg)" rx="20"/>',

            // Agent name
            '<text x="200" y="60" text-anchor="middle" fill="white" ',
            'font-family="Arial" font-size="22" font-weight="bold">', a.name, '</text>',

            // Token ID
            '<text x="200" y="90" text-anchor="middle" fill="rgba(255,255,255,0.6)" ',
            'font-size="14">#', tokenId.toString(), '</text>',

            // ELO (big center number)
            '<text x="200" y="200" text-anchor="middle" fill="white" ',
            'font-size="72" font-weight="bold">', a.elo.toString(), '</text>',
            '<text x="200" y="230" text-anchor="middle" fill="rgba(255,255,255,0.7)" ',
            'font-size="16">ELO RATING</text>',

            // Tier badge
            '<rect x="140" y="250" width="120" height="36" rx="18" fill="rgba(255,255,255,0.2)"/>',
            '<text x="200" y="273" text-anchor="middle" fill="white" font-size="16">',
            emoji, ' ', tier, '</text>',

            // Win rate bar
            '<text x="50" y="320" fill="rgba(255,255,255,0.7)" font-size="12">WIN RATE</text>',
            '<rect x="50" y="330" width="300" height="8" rx="4" fill="rgba(255,255,255,0.2)"/>',
            '<rect x="50" y="330" width="', barWidth.toString(), '" height="8" rx="4" fill="white"/>',

            // Stats
            '<text x="50"  y="370" fill="rgba(255,255,255,0.9)" font-size="13">',
            'W: ', a.wins.toString(), '</text>',
            '<text x="200" y="370" text-anchor="middle" fill="rgba(255,255,255,0.9)" font-size="13">',
            'L: ', a.losses.toString(), '</text>',

            '</svg>'
        ));
    }

    function _buildAttributes(Agent memory a) internal view returns (string memory) {
        return string(abi.encodePacked(
            '[',
            '{"trait_type":"Tier","value":"',      TIER_NAMES[a.tier], '"},',
            '{"trait_type":"ELO","display_type":"number","value":', a.elo.toString(), '},',
            '{"trait_type":"Wins","display_type":"number","value":', a.wins.toString(), '},',
            '{"trait_type":"Losses","display_type":"number","value":', a.losses.toString(), '}',
            ']'
        ));
    }
}
```

## Soulbound Tokens (ERC-5192)

```solidity
// ERC-5192: Minimal Soulbound Token
interface IERC5192 {
    function locked(uint256 tokenId) external view returns (bool);
    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId); // Not emitted for pure SBTs
}

contract SpartaBadge is ERC721, IERC5192 {
    // All tokens are soulbound — cannot be transferred
    function locked(uint256) external pure returns (bool) { return true; }

    function _beforeTokenTransfer(
        address from, address to, uint256 tokenId, uint256 batchSize
    ) internal override {
        // Allow minting (from == 0) but block all transfers
        require(from == address(0), "Soulbound: non-transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
```

## Composable NFTs (ERC-6059)

```solidity
// Parent NFT owns child NFTs
// Transfer parent → all children move with it
contract ComposableAgent is ERC721 {
    // tokenId → array of child NFT references
    mapping(uint256 => ChildNFT[]) public childAssets;

    struct ChildNFT {
        address contractAddress;
        uint256 tokenId;
    }

    // Attach a badge/item to an agent
    function attachChild(
        uint256 parentId,
        address childContract,
        uint256 childTokenId
    ) external {
        require(ownerOf(parentId) == msg.sender, "Not owner");
        // Transfer child NFT from sender to THIS contract (parent holds children)
        IERC721(childContract).transferFrom(msg.sender, address(this), childTokenId);
        childAssets[parentId].push(ChildNFT(childContract, childTokenId));
    }

    // When parent is transferred, children must go with it
    function _afterTokenTransfer(address, address to, uint256 tokenId, uint256) internal override {
        // Children are held by THIS contract — the new owner controls them via parent
        // (Full ERC-6059 implementation tracks owner via parent chain)
    }
}
```
