# Seaport & NFT Exchange Architecture

## Seaport Order Structure

```solidity
struct Order {
    OrderParameters parameters;
    bytes signature;
}

struct OrderParameters {
    address offerer;           // Who is offering
    address zone;              // Optional validation contract (address(0) = none)
    OfferItem[] offer;         // What the offerer is offering
    ConsiderationItem[] consideration; // What the offerer wants in return
    OrderType orderType;       // FULL_OPEN, PARTIAL_OPEN, FULL_RESTRICTED, PARTIAL_RESTRICTED, CONTRACT
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;          // Arbitrary data passed to zone
    uint256 salt;              // Entropy for unique order hash
    bytes32 conduitKey;        // Which conduit to use for token transfers
    uint256 totalOriginalConsiderationItems;
}

struct OfferItem {
    ItemType itemType;        // NATIVE, ERC20, ERC721, ERC1155, ERC721_WITH_CRITERIA, ERC1155_WITH_CRITERIA
    address token;
    uint256 identifierOrCriteria;  // Token ID, or merkle root for criteria orders
    uint256 startAmount;
    uint256 endAmount;        // For Dutch auctions: startAmount > endAmount (declining price)
}
```

## Item Types Explained
```
NATIVE (0):              ETH or native token
ERC20 (1):               Any ERC-20 token
ERC721 (2):              Specific NFT by token ID
ERC1155 (3):             ERC-1155 with amount
ERC721_WITH_CRITERIA(4): Any NFT matching merkle criteria (any in collection, or any with trait)
ERC1155_WITH_CRITERIA(5): Same but ERC-1155
```

## Order Types
```
FULL_OPEN (0):          Anyone can fill, must fill fully
PARTIAL_OPEN (1):       Anyone can fill partial amounts (ERC-1155 lots)
FULL_RESTRICTED (2):    Zone validates fulfillment, must fill fully
PARTIAL_RESTRICTED (3): Zone validates + partial fill allowed
CONTRACT (4):           Offerer is a contract that validates in callback
```

## Fulfillment Functions

```solidity
interface ISeaport {
    // Fill a single order
    function fulfillOrder(Order calldata order, bytes32 fulfillerConduitKey)
        external payable returns (bool fulfilled);

    // Fill an advanced order (partial, criteria)
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    // Fill multiple orders, skip unavailable
    function fulfillAvailableOrders(
        Order[] calldata orders,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    ) external payable returns (bool[] memory availableOrders, Execution[] memory executions);

    // Match complementary orders (no msg.sender involvement)
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);
}
```

## Zones (Validation Contracts)

```solidity
interface IZone {
    // Called during order validation
    function validateOrder(ZoneParameters calldata zoneParameters)
        external returns (bytes4 validOrderMagicValue);
}

// Example: Trait-based zone (only Bored Apes with Gold Fur)
contract TraitZone is IZone {
    ITraitOracle public immutable traitOracle;

    function validateOrder(ZoneParameters calldata params) external returns (bytes4) {
        // Extract NFT token ID from the fulfilled items
        uint256 tokenId = extractTokenId(params.consideration);

        // Verify trait via oracle or merkle proof
        require(traitOracle.hasTrait(tokenId, "Gold Fur"), "Wrong trait");

        return IZone.validateOrder.selector;
    }
}

// Example: Time-locked auction zone
contract AuctionZone is IZone {
    mapping(bytes32 => uint256) public auctionEndTimes;

    function validateOrder(ZoneParameters calldata params) external returns (bytes4) {
        require(block.timestamp >= auctionEndTimes[params.orderHash], "Auction not ended");
        return IZone.validateOrder.selector;
    }
}
```

## Conduit System

```solidity
// Users approve the conduit ONCE → multiple marketplaces can use it
// Conduit Controller manages which contracts can use each conduit

interface IConduit {
    function execute(ConduitTransfer[] calldata transfers) external returns (bytes4);
}

// User approves: IERC721(nft).setApprovalForAll(conduitAddress, true)
// Seaport calls: conduit.execute([transfer1, transfer2, ...])
// All marketplaces sharing this conduit can now move approved tokens
```

## Criteria-Based Orders (Collection Offers)

```solidity
// Offer on ANY Bored Ape
OfferItem memory collectionOffer = OfferItem({
    itemType: ItemType.ERC721_WITH_CRITERIA,
    token: BAYC_ADDRESS,
    identifierOrCriteria: 0,  // 0 = any token ID
    startAmount: 1,
    endAmount: 1
});

// Offer on Bored Apes with specific traits (merkle tree of valid IDs)
bytes32 merkleRoot = computeMerkleRoot(validTokenIds);
OfferItem memory traitOffer = OfferItem({
    itemType: ItemType.ERC721_WITH_CRITERIA,
    token: BAYC_ADDRESS,
    identifierOrCriteria: uint256(merkleRoot),  // merkle root of valid IDs
    startAmount: 1,
    endAmount: 1
});

// Fulfiller provides CriteriaResolver with proof
CriteriaResolver memory resolver = CriteriaResolver({
    orderIndex: 0,
    side: Side.OFFER,
    index: 0,
    identifier: specificTokenId,
    criteriaProof: merkleProof  // Proves tokenId is in the tree
});
```

## Dutch Auctions via Seaport

```solidity
// Price decreases linearly from startAmount to endAmount over time window
ConsiderationItem memory payment = ConsiderationItem({
    itemType: ItemType.NATIVE,
    token: address(0),
    identifier: 0,
    startAmount: 10 ether,    // Starting price
    endAmount: 1 ether,       // Ending price
    recipient: payable(seller)
});

// At any moment: price = startAmount + (endAmount - startAmount) * elapsed / duration
// Buyer waits for price they like and fills
```

## Blur's Innovations vs OpenSea

| Feature | OpenSea/Seaport | Blur |
|---------|-----------------|------|
| Royalties | Creator-set (0-10%) | Optional (0.5% min) |
| Listings | Off-chain orders | Off-chain orders |
| Bids | Collection/trait offers | Bid pool (ETH deposited once) |
| Settlement | On-chain via Seaport | On-chain via Blur Exchange |
| Points | None | BLUR token incentives |
| Pro features | None | Portfolio analytics, depth charts |

## Blur Blend (NFT Perpetual Lending)

```solidity
// Revolutionary: NFT-backed loans with NO expiry
// Lender can trigger "Dutch auction refinancing" at any time

struct Lien {
    address borrower;
    address lender;
    address collection;
    uint256 tokenId;
    uint256 principal;       // Loan amount
    uint256 rate;            // Interest rate per second
    uint256 startTime;       // When loan started
    uint256 auctionDuration; // How long refinancing auction runs
}

function startAuction(uint256 lienId) external {
    // Lender can trigger this at any time — no expiry needed
    Lien memory lien = liens[lienId];
    require(msg.sender == lien.lender, "Not lender");
    auctionStartTime[lienId] = block.timestamp;
}

function refinance(uint256 lienId, uint256 newRate) external {
    // During auction: new lender can take over at lower rate
    // Dutch auction: rate starts high and decreases
    // If nobody refinances within auctionDuration → lender seizes NFT
    require(block.timestamp < auctionStartTime[lienId] + lien.auctionDuration);
    require(newRate <= getCurrentAuctionRate(lienId), "Rate too high");

    // Transfer principal from new lender to old lender
    // Update lien with new lender and rate
}

function seize(uint256 lienId) external {
    // If auction expires with no refinancing
    require(block.timestamp > auctionStartTime[lienId] + lien.auctionDuration);
    // Lender receives the NFT
    IERC721(lien.collection).transferFrom(address(this), lien.lender, lien.tokenId);
}
```

## Royalty Enforcement vs Bypass
- **Pre-2023**: OpenSea enforced royalties via "operator filter registry" — blacklist trading contracts that don't pay royalties
- **Blur's response**: Deployed contracts outside the filter → optional royalties
- **Current state**: Royalties are socially enforced, not technically enforced. ERC-2981 signals royalties, marketplaces can ignore.
- **On-chain enforcement**: Transfer hooks (ERC-721C by Limit Break) — blocks transfers that don't include royalty payment. Very restrictive.
- **Best practice**: Use ERC-2981, announce royalty policy, let market decide. Don't rely on enforceable royalties for business model.
