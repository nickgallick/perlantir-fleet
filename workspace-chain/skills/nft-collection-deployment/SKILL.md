# NFT Collection Deployment

## ERC-721A Production Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract AgentCollection is ERC721A, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant MAX_PER_WALLET = 5;

    // Pricing
    uint256 public allowlistPrice = 0.03 ether;
    uint256 public publicPrice   = 0.05 ether;

    // Phases
    bool public allowlistActive;
    bool public publicActive;
    bytes32 public merkleRoot;

    // Metadata
    string private _baseTokenURI;
    string public unrevealedURI = "ipfs://QmPlaceholder/unrevealed.json";
    bool public revealed;

    // Chainlink VRF for randomized reveal
    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint256 public randomOffset; // Applied to token→metadata mapping
    bool public offsetRequested;

    // Royalties (ERC-2981)
    address public royaltyReceiver;
    uint96  public royaltyBps = 500; // 5%

    // Events
    event Revealed(uint256 randomOffset);
    event PhaseChanged(string phase, bool active);

    constructor(
        string memory name_,
        string memory symbol_,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    )
        ERC721A(name_, symbol_)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        royaltyReceiver = msg.sender;
    }

    // ──────────────── MINTING ────────────────

    function allowlistMint(
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(allowlistActive, "Allowlist not active");
        require(msg.value >= allowlistPrice * quantity, "Insufficient ETH");
        require(
            MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Not on allowlist"
        );
        require(_numberMinted(msg.sender) + quantity <= MAX_PER_WALLET, "Wallet limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply");

        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable nonReentrant {
        require(publicActive, "Public mint not active");
        require(msg.value >= publicPrice * quantity, "Insufficient ETH");
        require(_numberMinted(msg.sender) + quantity <= MAX_PER_WALLET, "Wallet limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply");

        _mint(msg.sender, quantity);
    }

    // ──────────────── REVEAL ────────────────

    // Step 1: request randomness (before reveal)
    function requestRevealRandom() external onlyOwner {
        require(!offsetRequested, "Already requested");
        offsetRequested = true;
        vrfCoordinator.requestRandomWords(
            keyHash, subscriptionId, 3, 200_000, 1
        );
    }

    // Step 2: VRF callback sets offset
    function fulfillRandomWords(uint256, uint256[] memory words) internal override {
        randomOffset = words[0] % MAX_SUPPLY;
    }

    // Step 3: owner sets real base URI and enables reveal
    function reveal(string calldata newBaseURI) external onlyOwner {
        require(offsetRequested && randomOffset > 0, "Randomness not set");
        _baseTokenURI = newBaseURI;
        revealed = true;
        emit Revealed(randomOffset);
    }

    // ──────────────── METADATA ────────────────

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        if (!revealed) return unrevealedURI;

        // Apply random offset: token #5 might show metadata #(5 + offset) % MAX_SUPPLY
        uint256 metadataId = (tokenId + randomOffset) % MAX_SUPPLY;
        return string(abi.encodePacked(_baseTokenURI, _toString(metadataId), ".json"));
    }

    // ERC-2981 royalties
    function royaltyInfo(uint256, uint256 salePrice)
        external view
        returns (address, uint256)
    {
        return (royaltyReceiver, salePrice * royaltyBps / 10_000);
    }

    // ──────────────── ADMIN ────────────────

    function setPhase(bool _allowlist, bool _public) external onlyOwner {
        allowlistActive = _allowlist;
        publicActive    = _public;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
```

## Generative Art Pipeline

```python
from PIL import Image
import random, json, os

LAYERS = {
    "Background": [("Ocean",0.40),("Forest",0.35),("Gold",0.20),("Void",0.05)],
    "Body":       [("Bronze",0.50),("Silver",0.30),("Gold",0.15),("Diamond",0.05)],
    "Eyes":       [("Normal",0.60),("Laser",0.25),("Closed",0.10),("Rainbow",0.05)],
}

def weighted_choice(options):
    names, weights = zip(*options)
    return random.choices(names, weights=weights)[0]

def generate_one(token_id, used_combos):
    while True:
        traits = {layer: weighted_choice(opts) for layer, opts in LAYERS.items()}
        key = tuple(sorted(traits.items()))
        if key not in used_combos:
            used_combos.add(key)
            return traits

def compose_image(traits, token_id):
    layers_path = "layers/"
    base = None
    for layer_name in ["Background", "Body", "Eyes"]:
        img = Image.open(f"{layers_path}{layer_name}/{traits[layer_name]}.png").convert("RGBA")
        base = img if base is None else Image.alpha_composite(base, img)
    base.save(f"output/images/{token_id}.png")

used = set()
metadata_list = []
for i in range(10000):
    traits = generate_one(i, used)
    compose_image(traits, i)
    metadata_list.append({
        "name": f"Agent #{i}",
        "description": "A warrior of the Sparta Arena.",
        "image": f"ipfs://PLACEHOLDER/{i}.png",
        "attributes": [{"trait_type": k, "value": v} for k, v in traits.items()]
    })
    with open(f"output/metadata/{i}.json","w") as f:
        json.dump(metadata_list[-1], f)

print("Generated 10,000 unique agents")
```

## Pinata Upload Script

```typescript
import PinataClient from "@pinata/sdk";
import fs from "fs";

const pinata = new PinataClient({ pinataJWTKey: process.env.PINATA_JWT! });

// 1. Upload images folder
const imagesCID = await pinata.pinFromFS("./output/images", {
    pinataMetadata: { name: "AgentCollection-Images" }
});
console.log("Images CID:", imagesCID.IpfsHash);

// 2. Update metadata with real image CIDs
for (let i = 0; i < 10000; i++) {
    const meta = JSON.parse(fs.readFileSync(`./output/metadata/${i}.json`, "utf8"));
    meta.image = `ipfs://${imagesCID.IpfsHash}/${i}.png`;
    fs.writeFileSync(`./output/metadata-final/${i}.json`, JSON.stringify(meta));
}

// 3. Upload metadata folder
const metaCID = await pinata.pinFromFS("./output/metadata-final", {
    pinataMetadata: { name: "AgentCollection-Metadata" }
});
console.log("Metadata CID:", metaCID.IpfsHash);
console.log(`Base URI: ipfs://${metaCID.IpfsHash}/`);
```

## Key Decisions

| Choice | Recommendation | Why |
|--------|---------------|-----|
| ERC-721 vs ERC-721A | ERC-721A always | Batch mint gas savings |
| IPFS vs Arweave | IPFS pinned on Pinata + Arweave for top 1% | Cost vs permanence |
| Reveal method | Chainlink VRF offset | Proves team didn't cherry-pick rare tokens |
| Royalties | ERC-2981 + operator filter | Standard, marketplaces will enforce |
| Allowlist | Merkle tree | No on-chain storage, scalable |
