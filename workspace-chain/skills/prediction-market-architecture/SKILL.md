# Prediction Market Architecture

## System Overview (Polymarket-Style)

### End-to-End Flow
```
User deposits USDC
       ↓
ConditionalTokens.splitPosition() → mints YES + NO tokens (ERC-1155)
       ↓
OrderBook / AMM → trade YES/NO tokens against other users
       ↓
Deadline passes → Oracle reports outcome
       ↓
ConditionalTokens.redeemPositions() → winners claim $1 per winning token
```

## Contract Architecture

### MarketFactory
```solidity
contract MarketFactory {
    IConditionalTokens public immutable ctf;
    IERC20 public immutable collateral; // USDC
    address public oracle;

    event MarketCreated(bytes32 indexed questionId, address indexed market, bytes32 conditionId);

    function createMarket(
        bytes32 questionId,
        string calldata description,
        uint256 resolutionTime
    ) external returns (address market, bytes32 conditionId) {
        // Prepare condition in CTF
        ctf.prepareCondition(oracle, questionId, 2); // 2 outcomes: YES/NO
        conditionId = ctf.getConditionId(oracle, questionId, 2);

        // Deploy market via BeaconProxy for upgradability + cheap deployment
        market = address(new BeaconProxy(beacon, abi.encodeCall(
            Market.initialize, (questionId, conditionId, resolutionTime)
        )));
    }
}
```

### ConditionalTokens (CTF — Gnosis Standard)
```solidity
// Core CTF interface
interface IConditionalTokens {
    // Create the condition (done by market creator)
    function prepareCondition(address oracle, bytes32 questionId, uint outcomeSlotCount) external;

    // Deposit USDC, receive YES + NO tokens
    function splitPosition(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata partition,
        uint amount
    ) external;

    // Burn YES + NO tokens, receive USDC back (before resolution)
    function mergePositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata partition,
        uint amount
    ) external;

    // After resolution: burn winning tokens, receive USDC
    function redeemPositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata indexSets
    ) external;

    // Oracle reports outcome (1 = YES wins, 2 = NO wins)
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
}
```

### Order Book (CLOB Model)
```solidity
struct Order {
    bytes32 marketId;
    address maker;
    uint256 outcomeIndex;  // 0 = NO, 1 = YES
    uint256 price;         // Price in USDC (6 decimals), e.g., 600000 = $0.60
    uint256 size;          // Amount of outcome tokens
    uint256 nonce;
    uint256 expiry;
    bytes signature;       // EIP-712 signature
}

contract OrderBook {
    // Off-chain matching engine calls this with matched orders
    function matchOrders(
        Order calldata takerOrder,
        Order[] calldata makerOrders,
        uint256[] calldata fillAmounts
    ) external onlyOperator {
        // Validate signatures
        // Transfer outcome tokens between parties
        // Collect platform fees
    }
}
```

### Oracle / Resolution Module
```solidity
contract OptimisticResolution {
    IOptimisticOracleV3 public immutable uma;
    mapping(bytes32 => bytes32) public assertionIdByMarket;

    function initializeResolution(bytes32 questionId, bytes memory claim) external {
        // e.g., claim = "YES" or "NO"
        bytes32 assertionId = uma.assertTruth(
            claim,
            msg.sender,  // asserter
            address(this),
            address(0),
            LIVENESS,    // challenge window (e.g., 2 hours for Polymarket)
            bondCurrency,
            bondAmount,
            IDENTIFIER,
            bytes32(0)
        );
        assertionIdByMarket[questionId] = assertionId;
    }

    function assertionResolvedCallback(
        bytes32 assertionId,
        bool assertedTruthfully
    ) external {
        // UMA calls this after dispute window
        if (assertedTruthfully) {
            // Report payout to CTF
            uint[] memory payouts = _buildPayouts(assertionId);
            ctf.reportPayouts(questionId, payouts);
        }
    }
}
```

### Fee Module
```solidity
contract FeeModule {
    uint256 public constant PLATFORM_FEE_BPS = 20; // 0.2% (2bps on notional = 20bps on trade value)
    address public treasury;

    function collectTradeFee(address token, uint256 tradeValue) internal returns (uint256 fee) {
        fee = (tradeValue * PLATFORM_FEE_BPS) / 10_000;
        IERC20(token).safeTransfer(treasury, fee);
    }
}
```

## LMSR AMM (Alternative to CLOB)
```solidity
// Logarithmic Market Scoring Rule
// C(q) = b * ln(exp(q_yes/b) + exp(q_no/b))
// Cost to move from q1 to q2 = C(q2) - C(q1)

contract LMSR {
    uint256 public b;       // Liquidity parameter
    uint256 public qYes;    // Outstanding YES shares
    uint256 public qNo;     // Outstanding NO shares

    function cost(uint256 _qYes, uint256 _qNo) public view returns (uint256) {
        // b * ln(e^(qYes/b) + e^(qNo/b))
        // Implemented with fixed-point math
        return FixedPointMathLib.lnWad(
            FixedPointMathLib.expWad(int256(_qYes * WAD / b)) +
            FixedPointMathLib.expWad(int256(_qNo * WAD / b))
        ) * b / WAD;
    }

    function buyYes(uint256 sharesOut) external returns (uint256 costIn) {
        uint256 costBefore = cost(qYes, qNo);
        uint256 costAfter = cost(qYes + sharesOut, qNo);
        costIn = costAfter - costBefore;

        qYes += sharesOut;
        usdc.safeTransferFrom(msg.sender, address(this), costIn);
        ctf.splitPosition(usdc, bytes32(0), conditionId, _partition(), costIn);
        // Send YES tokens to buyer
    }
}
```

## Security Considerations Specific to Prediction Markets

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Oracle manipulation | CRITICAL | UMA dispute mechanism, long liveness periods, multiple asserters |
| Front-running resolution | HIGH | Commit-reveal for oracle reports, CLOB private matching |
| Wash trading | MEDIUM | On-chain volume transparent; flag outliers off-chain |
| Invalid market resolution | HIGH | Clear resolution criteria in market description, governance escalation |
| Flash loan LMSR attacks | HIGH | Use CLOB not AMM, or TWAP-protected AMM prices |
| Market maker insolvency | MEDIUM | LMSR bounded loss = b*ln(n), size liquidity parameter appropriately |
| Reentrancy in redemption | CRITICAL | CEI pattern, ReentrancyGuard on redeem functions |
| Signature replay | CRITICAL | EIP-712 domain separator includes chainId + contract address |

## Production Checklist
- [ ] CTF contract audited (use Gnosis CTF v1 — already audited)
- [ ] Off-chain CLOB operator has NO access to user funds
- [ ] Oracle dispute window appropriate for market type (hours for news, days for slow events)
- [ ] Fee collector is a multisig, not an EOA
- [ ] Emergency pause mechanism exists
- [ ] Invalid market protocol defined (full refunds or 50/50 split)
- [ ] Maximum market cap per contract to limit exploit exposure
