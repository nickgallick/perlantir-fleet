# GameFi & On-Chain Gaming

## Dual-Token Economy Design

```
GOVERNANCE TOKEN (SPARTA) — capped supply, value accrual
  - Max supply: 100M (never mints more)
  - Earns: stake to earn protocol fees, governance rights, staking rewards
  - Sinks: buy premium features, create challenges, unlock exclusive content
  - Distribution: team 15% (vested 2yr), investors 20% (vested 1yr), community 65%

UTILITY TOKEN (GLORY) — inflationary, earned through gameplay
  - Minted: when players win challenges, complete quests, achieve milestones
  - Burned: entry fees (50% burned), crafting upgrades, tournament registration
  - Design constraint: burn rate MUST >= mint rate at equilibrium, or price collapses
  - Circuit breaker: if GLORY price drops >50% in 7 days, halve emission rate automatically
```

## Loot Drop Contract with Chainlink VRF

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract LootSystem is ERC1155, VRFConsumerBaseV2 {
    // Item IDs
    uint256 constant COMMON    = 0;
    uint256 constant UNCOMMON  = 1;
    uint256 constant RARE      = 2;
    uint256 constant LEGENDARY = 3;
    uint256 constant MYTHIC    = 4;

    // Rarity thresholds (out of 10000)
    uint16[5] THRESHOLDS = [6000, 8500, 9500, 9900, 10000]; // 60/25/10/4/1%

    VRFCoordinatorV2Interface immutable vrf;
    uint64  subscriptionId;
    bytes32 keyHash;

    mapping(uint256 => address) public pendingRequests; // requestId → player

    event LootDropped(address player, uint256 itemId, string rarity);

    constructor(address _vrf, uint64 _subId, bytes32 _keyHash)
        ERC1155("https://sparta.game/api/items/{id}.json")
        VRFConsumerBaseV2(_vrf)
    {
        vrf = VRFCoordinatorV2Interface(_vrf);
        subscriptionId = _subId;
        keyHash = _keyHash;
    }

    // Called when player wins a challenge
    function requestLootDrop(address player) external onlyArena {
        uint256 requestId = vrf.requestRandomWords(keyHash, subscriptionId, 3, 100_000, 1);
        pendingRequests[requestId] = player;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory words) internal override {
        address player = pendingRequests[requestId];
        delete pendingRequests[requestId];

        uint256 roll = words[0] % 10_000;
        uint256 itemId;

        for (uint i = 0; i < 5; i++) {
            if (roll < THRESHOLDS[i]) {
                itemId = i;
                break;
            }
        }

        _mint(player, itemId, 1, "");

        string[5] memory rarityNames = ["Common","Uncommon","Rare","Legendary","Mythic"];
        emit LootDropped(player, itemId, rarityNames[itemId]);
    }
}
```

## Session Keys for Gaming UX

```solidity
// ERC-4337 + Session Keys = no MetaMask popup per action
contract SessionKeyModule {
    struct SessionKey {
        address key;
        uint256 validUntil;    // Expiry timestamp
        uint256 spendLimit;    // Max USDC spendable per session
        uint256 spent;
        bytes4[] allowedSelectors; // Which functions the session key can call
    }

    mapping(address => mapping(address => SessionKey)) public sessions; // account → key → session

    // Player approves session key for 1 hour
    function createSession(
        address sessionKey,
        bytes4[] calldata allowedSelectors
    ) external {
        sessions[msg.sender][sessionKey] = SessionKey({
            key:               sessionKey,
            validUntil:        block.timestamp + 1 hours,
            spendLimit:        10e6, // $10 USDC per session
            spent:             0,
            allowedSelectors:  allowedSelectors
        });
    }

    // Validate session key transaction (called by ERC-4337 account)
    function validateSessionKeyOp(
        address account,
        address sessionKey,
        bytes4 selector,
        uint256 value
    ) external view returns (bool) {
        SessionKey storage sk = sessions[account][sessionKey];
        if (block.timestamp > sk.validUntil) return false;
        if (sk.spent + value > sk.spendLimit) return false;

        for (uint i = 0; i < sk.allowedSelectors.length; i++) {
            if (sk.allowedSelectors[i] == selector) return true;
        }
        return false;
    }
}
```

## Axie Inflation Post-Mortem

The key lesson from Axie Infinity's SLP (Smooth Love Potion) collapse:

```
Peak: SLP = $0.40 (May 2021)
Bottom: SLP = $0.001 (2022) — 99.75% collapse

Root cause: Emission >> Burn
  - Millions of players earning SLP daily by playing
  - SLP only needed for breeding Axies
  - When NFT market slowed, breeding demand fell
  - SLP flooded the market with no buyers
  - Price dropped → less incentive to play → less breeding demand → more sell pressure

Prevention model (Agent Sparta):
  - GLORY earned for wins only (not for participating)
  - Multiple burn sinks: entry fees, upgrades, cosmetics, tournament buy-ins
  - Emission rate automatically adjusts based on GLORY price vs 30-day EMA
  - If emission/burn ratio > 1.2x, halve emission rate for next period
  - Token buyback from protocol revenue when price < target
```

## Anti-Cheat Architecture

```
Layer 1: Server-authoritative game logic
  - All game outcomes computed server-side
  - Server signs results before submitting to chain
  - Client never directly calls game-state-changing functions

Layer 2: Verifiable randomness
  - Chainlink VRF for all loot drops, stat rolls, tournament seeds
  - Players can verify each random outcome on-chain

Layer 3: Rate limiting
  - Max X challenges per day per address (prevents botting)
  - Cooldown between consecutive submissions

Layer 4: Reputation system
  - Behavioral analysis (play patterns, submission timing, win rates)
  - Anomaly detection flags accounts for review
  - Proven bots: burn all in-game assets, ban address
```
