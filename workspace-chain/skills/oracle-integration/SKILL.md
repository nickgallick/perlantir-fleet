# Oracle Integration

## Why Oracles
Smart contracts cannot access off-chain data natively. Oracles are trusted data bridges bringing real-world information (prices, events, randomness) on-chain.

## Chainlink (Industry Standard)

### Price Feeds
```solidity
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        // ETH/USD on Base mainnet
        priceFeed = AggregatorV3Interface(0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70);
    }

    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // ALWAYS validate
        require(answer > 0, "Invalid price");
        require(updatedAt > 0, "Round not complete");
        require(block.timestamp - updatedAt < 1 hours, "Stale price");
        require(answeredInRound >= roundId, "Stale round");

        return answer;
    }
}
```

**Price feed decimals**: 8 for USD pairs, 18 for ETH pairs. Check `priceFeed.decimals()`.

### Chainlink VRF (Randomness)
```solidity
contract RandomConsumer is VRFConsumerBaseV2Plus {
    uint256 public constant CALLBACK_GAS = 100_000;
    bytes32 public keyHash; // Gas lane
    uint256 public subId;   // Subscription ID

    function requestRandom() external returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subId,
                requestConfirmations: 3,        // Wait 3 blocks for security
                callbackGasLimit: CALLBACK_GAS,
                numWords: 1,
                extraArgs: ""
            })
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 result = randomWords[0] % 100; // 0-99
        // Use result
    }
}
```
- VRF = Verifiable Random Function. Cryptographically provable random number.
- Requires LINK subscription. Callback arrives 1-3 blocks later.

### Chainlink Automation
Trigger functions based on time or conditions:
```solidity
function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory) {
    upkeepNeeded = block.timestamp > nextResolutionTime;
}

function performUpkeep(bytes calldata) external {
    if (block.timestamp > nextResolutionTime) {
        resolveMarket();
    }
}
```

### Chainlink CCIP
Cross-chain token transfers + messaging. See bridge-and-crosschain-development skill.

## UMA Optimistic Oracle (Used by Polymarket)
UMA's design: assume the result is correct unless challenged. Cheaper than Chainlink for infrequent custom data.

### Integration Flow
```solidity
// 1. Request a price assertion
bytes32 identifier = "YES_OR_NO_QUERY";
uint256 timestamp = block.timestamp;
bytes memory ancillaryData = abi.encodePacked("q: Will ETH > 4000 by Dec 31?");

OptimisticOracleV3Interface oracle = OptimisticOracleV3Interface(UMA_OO_ADDRESS);

bytes32 assertionId = oracle.assertTruth(
    abi.encodePacked("YES"),    // Proposer asserts YES
    proposer,                    // Proposer address
    address(this),               // CallbackRecipient
    address(0),                  // Escalation manager
    disputeWindow,               // e.g., 7200 seconds (2 hours)
    IERC20(bondCurrency),
    bondAmount,
    identifier,
    bytes32(0)
);
```

### Dispute Resolution
- Proposer submits result + bond during `disputeWindow`
- If no dispute → result accepted, proposer gets bond back
- If disputed → DVM (Data Verification Mechanism) votes → winner gets loser's bond
- DVM = UMA tokenholders vote on the correct answer

### When to Use UMA
- Custom/novel data requests (prediction market outcomes)
- Infrequent, high-value assertions
- When the data can be verified by humans reading a news source
- **NOT for**: High-frequency price data (use Chainlink), real-time feeds

## Pyth Network
Pull-based price feeds with sub-second latency.
```solidity
IPyth pyth = IPyth(0xff1a0f4744e8582DF1aE09D5611b887B6a12925C);

function getPrice(bytes32 priceId, bytes[] calldata priceUpdateData) external payable returns (int64) {
    uint fee = pyth.getUpdateFee(priceUpdateData);
    pyth.updatePriceFeeds{value: fee}(priceUpdateData);  // User provides fresh price data

    PythStructs.Price memory price = pyth.getPrice(priceId);
    require(block.timestamp - price.publishTime < 60, "Stale price");
    return price.price;
}
```
- Consumer passes price update calldata (fetched off-chain) with each transaction
- Good for: perpetuals, high-frequency trading, fast-moving prices
- Used by: Synthetix, Drift Protocol

## Oracle Selection Guide
| Use Case | Oracle | Reason |
|----------|--------|--------|
| ETH/BTC/asset price | Chainlink Price Feeds | Most battle-tested, push model |
| On-chain randomness | Chainlink VRF | Cryptographically verifiable |
| Prediction market outcome | UMA Optimistic Oracle | Custom assertions, dispute mechanism |
| High-frequency trading | Pyth | Sub-second latency |
| Automated triggers | Chainlink Automation or Gelato | Decentralized keepers |
| Cross-chain data | CCIP | Native Chainlink messaging |

## Oracle Security
- **TWAP**: Use time-weighted average price, not spot price. Harder to manipulate via flash loans.
- **Freshness check**: Always validate `updatedAt` timestamp. Stale prices are dangerous.
- **Circuit breakers**: If price moves >X% in one block, pause protocol.
- **Multiple sources**: Cross-reference multiple oracles for critical operations.
- **Fallback**: Have a fallback oracle if primary fails.
- **Never trust single source for high-value decisions.**
