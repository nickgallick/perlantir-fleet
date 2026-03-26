# NFT Marketplace Operations

## ERC-2981 Royalties (Implement in Contract)

```solidity
// Add to your NFT contract
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract SpartaNFT is ERC721, ERC2981 {
    constructor() ERC721("Agent Sparta", "SPARTA") {
        // 5% royalty to treasury on all secondary sales
        _setDefaultRoyalty(TREASURY_ADDRESS, 500); // 500 = 5% (basis points)
    }

    // Override royalty for a specific token (optional)
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)
        external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

## OpenSea Collection Setup

```
Verification requirements:
□ Contract verified on Etherscan/Basescan
□ Collection deployed with proper metadata
□ contractURI() returning collection-level metadata
□ ERC-2981 royalty info set

Collection metadata (contractURI JSON):
{
  "name": "Agent Sparta",
  "description": "Compete. Win. Earn your badge.",
  "image": "https://arweave.net/YOUR_COLLECTION_IMAGE",
  "external_link": "https://agentspartai.com",
  "seller_fee_basis_points": 500,
  "fee_recipient": "0xYOUR_TREASURY_ADDRESS"
}

Steps:
1. Deploy contract with contractURI()
2. Go to opensea.io → your collection appears automatically
3. Connect wallet (must be the contract owner)
4. Edit collection → fill in description, socials, category
5. Request Verification: opensea.io/collection/YOUR-SLUG → Edit → Verify
6. Timeline: 1-7 days for verified checkmark
```

## IPFS + Arweave Storage

```bash
# Upload to IPFS via Pinata (images + metadata)
curl -X POST https://api.pinata.cloud/pinning/pinFileToIPFS \
  -H "Authorization: Bearer $PINATA_JWT" \
  -F file=@image.png

# Response: {"IpfsHash": "QmXxx..."}
# URI: ipfs://QmXxx... or https://gateway.pinata.cloud/ipfs/QmXxx

# Upload to Arweave (permanent, pay once)
npx @bundlr-network/client upload image.png \
  --wallet wallet.json \
  --currency arweave

# Best practice for production:
# Images → Arweave (permanent)
# Metadata JSON → IPFS (update CID on reveal)
# After reveal → also upload final metadata to Arweave
```

## Delayed Reveal with Chainlink VRF

```solidity
// Pre-reveal: all tokens point to placeholder
function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!revealed) {
        return string.concat(baseURI, "hidden.json");
    }
    // After reveal: shuffle via VRF seed
    uint256 metadataIndex = (tokenId + vrfSeed) % MAX_SUPPLY;
    return string.concat(baseURI, metadataIndex.toString(), ".json");
}

// Request randomness from Chainlink VRF
function reveal() external onlyOwner {
    require(!revealed && !vrfPending, "Already revealed or pending");
    vrfPending = true;
    vrfRequestId = VRF_COORDINATOR.requestRandomWords(
        KEY_HASH, SUBSCRIPTION_ID, 3, 100_000, 1
    );
}

function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
    vrfSeed = randomWords[0];
    revealed = true;
    vrfPending = false;
}
```

## Blur Setup

```
Blur indexes automatically for EVM NFTs.
To optimize for Blur traders:

1. Verify collection at blur.io (submit via their portal)
2. Set royalty preference in Blur settings (0-10%)
   Note: Blur incentivizes 0% for higher BLUR token rewards
   Strategy: set your minimum at 2-3%, accept the tradeoff

3. Blur-specific features:
   - Collection bidding: traders bid on floor price
   - Trait bidding: bids on specific attribute combinations
   - Blend: NFT-backed loans using your collection as collateral
```

## Magic Eden (Solana)

```bash
# For Metaplex collections, Magic Eden auto-indexes
# Submit for verified status:
# launchpad.magiceden.io → Creator Hub → Verify Collection

# Required:
# - Collection address (Candy Machine ID or collection mint)
# - Creator wallet (must sign the verification request)
# - Collection image, description, socials
# - Timeline: 24-48 hours

# After verification:
# - Blue checkmark on collection page
# - Eligible for featured placement
# - Access to Magic Eden creator analytics
```

## Metadata Refresh After Reveal

```typescript
// After updating baseURI on-chain, refresh metadata on each marketplace
// OpenSea: POST to their API
const COLLECTION_SLUG = "your-collection-slug";

// Refresh individual token
await fetch(`https://api.opensea.io/api/v2/chain/ethereum/contract/${CONTRACT}/nfts/${TOKEN_ID}/refresh`, {
  method: "POST",
  headers: { "x-api-key": process.env.OPENSEA_API_KEY! },
});

// For large collections: use a queue to refresh in batches
// Rate limit: ~2 requests/second on OpenSea API
for (let i = 0; i < MAX_SUPPLY; i++) {
  await refreshToken(i);
  await sleep(500); // 500ms between requests
  if (i % 100 === 0) console.log(`Refreshed ${i}/${MAX_SUPPLY}`);
}
```
