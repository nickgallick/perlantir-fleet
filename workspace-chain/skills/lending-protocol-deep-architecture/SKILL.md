# Lending Protocol Deep Architecture

## Interest Rate Model (Kink/Two-Slope)

```
Rate
|                                    /
|                                   /  slope2 (steep)
|                                  /
|──────────────────────────────── kink
|                         /
|                        / slope1 (gentle)
|                       /
|──────────────────────
|  base rate
|_________________________ utilization
0%              U_optimal         100%
```

### Exact Formulas
```solidity
contract InterestRateModel {
    uint256 constant SECONDS_PER_YEAR = 365 days;
    
    // Parameters (set per asset by governance)
    uint256 public baseRatePerSecond;
    uint256 public slope1PerSecond;
    uint256 public slope2PerSecond;
    uint256 public optimalUtilization; // e.g., 80% = 0.8e18

    function calculateRates(
        uint256 totalDebt,
        uint256 totalLiquidity
    ) external view returns (uint256 supplyRate, uint256 borrowRate) {
        if (totalDebt == 0) return (0, baseRatePerSecond);

        uint256 utilization = (totalDebt * 1e18) / (totalDebt + totalLiquidity);

        if (utilization <= optimalUtilization) {
            // Below kink: linear from base to base+slope1
            borrowRate = baseRatePerSecond +
                (utilization * slope1PerSecond) / optimalUtilization;
        } else {
            // Above kink: base + slope1 + steep slope2
            uint256 excessUtilization = utilization - optimalUtilization;
            uint256 maxExcess = 1e18 - optimalUtilization;
            borrowRate = baseRatePerSecond +
                slope1PerSecond +
                (excessUtilization * slope2PerSecond) / maxExcess;
        }

        // Supply rate = borrow rate × utilization × (1 - reserve factor)
        uint256 reserveFactor = 0.1e18; // 10% to protocol treasury
        supplyRate = (borrowRate * utilization / 1e18) * (1e18 - reserveFactor) / 1e18;
    }
}
```

### Example Parameters (Aave V3 USDC)
- Base: 0%
- Slope1: 4% (below 80%)
- Slope2: 60% (above 80%)
- Optimal: 80%
- At 90% utilization: borrow rate = 0 + 4% + (10%/20%) × 60% = 34% APY

## aToken Mechanics (Rebasing)

```solidity
contract AToken is ERC20 {
    // Key insight: user's SCALED balance stays constant
    // but actual balance grows as liquidity index increases

    mapping(address => uint256) internal _scaledBalances;
    uint256 public liquidityIndex; // Cumulative interest factor, starts at 1e27

    // Balance grows automatically without any transactions
    function balanceOf(address user) public view override returns (uint256) {
        return (_scaledBalances[user] * liquidityIndex) / 1e27;
    }

    function totalSupply() public view override returns (uint256) {
        return (_totalScaledSupply * liquidityIndex) / 1e27;
    }

    // When user deposits, they receive scaled amount
    function _mintScaled(address user, uint256 amount) internal {
        uint256 scaledAmount = (amount * 1e27) / liquidityIndex;
        _scaledBalances[user] += scaledAmount;
    }

    // Update index (called periodically or on each interaction)
    function updateIndex(uint256 supplyRatePerSecond) external {
        uint256 timeDelta = block.timestamp - lastUpdateTimestamp;
        // Compound: newIndex = oldIndex × (1 + rate × time)
        // Simplified linear for low rates:
        liquidityIndex = liquidityIndex + (liquidityIndex * supplyRatePerSecond * timeDelta) / 1e27;
        lastUpdateTimestamp = block.timestamp;
    }
}
```

## Variable Debt Token

```solidity
contract VariableDebtToken {
    mapping(address => uint256) internal _scaledBalances;
    uint256 public variableBorrowIndex; // Tracks cumulative borrow rate

    // Debt grows automatically
    function balanceOf(address user) public view returns (uint256) {
        return (_scaledBalances[user] * variableBorrowIndex) / 1e27;
    }

    // On borrow: store scaled debt (normalized to current index)
    function mint(address user, uint256 amount) external {
        uint256 scaledAmount = (amount * 1e27) / variableBorrowIndex;
        _scaledBalances[user] += scaledAmount;
    }

    // On repay: reduce scaled debt
    function burn(address user, uint256 amount) external {
        uint256 scaledAmount = (amount * 1e27) / variableBorrowIndex;
        _scaledBalances[user] -= scaledAmount;
    }
}
```

## Health Factor & Liquidation

```solidity
function calculateHealthFactor(address user) public view returns (uint256) {
    UserData memory data = getUserData(user);

    // HF = Σ(collateral_i × price_i × liquidationThreshold_i) / Σ(debt_j × price_j)
    uint256 collateralValue = 0;
    for (uint i = 0; i < data.collateralAssets.length; i++) {
        address asset = data.collateralAssets[i];
        uint256 price = oracle.getPrice(asset);
        uint256 threshold = riskParams[asset].liquidationThreshold; // e.g., 0.85e18
        collateralValue += data.collateralAmounts[i] * price / 1e18 * threshold / 1e18;
    }

    if (data.totalDebtValue == 0) return type(uint256).max;
    return (collateralValue * 1e18) / data.totalDebtValue;
}

function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover  // capped at close factor (50%)
) external {
    uint256 hf = calculateHealthFactor(user);
    require(hf < 1e18, "Not liquidatable");

    // Max debt that can be covered
    uint256 maxDebt = getUserDebt(user, debtAsset) * CLOSE_FACTOR / 1e18;
    debtToCover = Math.min(debtToCover, maxDebt);

    // Calculate collateral to seize
    uint256 debtPrice = oracle.getPrice(debtAsset);
    uint256 collateralPrice = oracle.getPrice(collateralAsset);
    uint256 liquidationBonus = riskParams[collateralAsset].liquidationBonus; // e.g., 1.05e18

    uint256 collateralToSeize = debtToCover * debtPrice * liquidationBonus
        / (collateralPrice * 1e18);

    // Transfer: liquidator pays debt, receives collateral
    IERC20(debtAsset).safeTransferFrom(msg.sender, address(this), debtToCover);
    _repayDebt(user, debtAsset, debtToCover);
    _withdrawCollateral(user, collateralAsset, collateralToSeize, msg.sender);

    emit LiquidationCall(user, debtAsset, collateralAsset, debtToCover, collateralToSeize);
}
```

## eMode (Efficiency Mode)

```solidity
// eMode allows higher LTV for correlated assets
// e.g., ETH eMode: ETH, wstETH, rETH → 97% LTV instead of 80%

struct EModeCategory {
    uint16 ltv;                    // e.g., 9700 = 97%
    uint16 liquidationThreshold;   // e.g., 9800 = 98%
    uint16 liquidationBonus;       // e.g., 10100 = 1% bonus
    address priceSource;           // Single oracle for all assets in category
    string label;                  // "ETH correlated"
}

mapping(uint8 => EModeCategory) public eModeCategories;
mapping(address => uint8) public userEModeCategory; // 0 = none

function setUserEMode(uint8 categoryId) external {
    // Validate: all user's collateral must be in this category
    // Validate: resulting HF >= 1 after applying new parameters
    userEModeCategory[msg.sender] = categoryId;
}

// When computing HF for eMode user:
// - Use category's higher LTV/threshold instead of per-asset params
// - Use category's price source (prevents oracle divergence attacks)
```

## Isolation Mode

```solidity
// New/risky assets: can only borrow stablecoins up to a debt ceiling
mapping(address => bool) public isIsolated;
mapping(address => uint256) public isolationDebtCeiling; // in USD terms

function validateBorrow(address borrower, address asset, uint256 amount) internal {
    // If borrower has isolated collateral, can only borrow stablecoins
    address isolatedCollateral = getIsolatedCollateral(borrower);
    if (isolatedCollateral != address(0)) {
        require(isStablecoin[asset], "Isolated: stablecoins only");

        // Check debt ceiling
        uint256 currentDebt = isolationDebtTracker[isolatedCollateral];
        uint256 newDebt = currentDebt + (amount * oracle.getPrice(asset) / 1e18);
        require(newDebt <= isolationDebtCeiling[isolatedCollateral], "Debt ceiling reached");

        isolationDebtTracker[isolatedCollateral] = newDebt;
    }
}
```

## Flash Loans

```solidity
function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes, // 0 = no debt, 1 = stable, 2 = variable
    bytes calldata params
) external {
    // Transfer assets to receiver
    for (uint i = 0; i < assets.length; i++) {
        IERC20(assets[i]).safeTransfer(receiverAddress, amounts[i]);
    }

    // Execute receiver's logic
    IFlashLoanReceiver(receiverAddress).executeOperation(
        assets, amounts, premiums, msg.sender, params
    );

    // Verify repayment
    for (uint i = 0; i < assets.length; i++) {
        if (interestRateModes[i] == 0) {
            // Must repay + premium
            uint256 repayment = amounts[i] + (amounts[i] * FLASH_LOAN_FEE / 10_000);
            IERC20(assets[i]).safeTransferFrom(receiverAddress, address(this), repayment);
        }
        // If mode != 0, opens a debt position instead of requiring repayment
    }
}
```

## Pool Architecture (Aave V3)

```
PoolAddressesProvider  ← Registry of all contract addresses
       │
       ├── Pool  ← Main entry point (supply, borrow, repay, withdraw, liquidate, flashloan)
       │    │
       │    ├── PoolLogic library
       │    ├── SupplyLogic library
       │    ├── BorrowLogic library
       │    └── LiquidationLogic library
       │
       ├── PoolConfigurator  ← Admin functions (add assets, set params, eMode)
       ├── AaveOracle  ← Price aggregator (Chainlink feeds)
       └── Per-asset contracts:
            ├── aToken (ERC-20, rebasing)
            ├── StableDebtToken
            └── VariableDebtToken
```

## Risk Parameters Per Asset
| Asset | LTV | Liq Threshold | Liq Bonus | Reserve Factor | Optimal Util |
|-------|-----|---------------|-----------|----------------|--------------|
| ETH | 80% | 82.5% | 5% | 15% | 80% |
| WBTC | 70% | 75% | 6.25% | 20% | 45% |
| USDC | 77% | 80% | 4.5% | 10% | 90% |
| stETH | 69% | 79% | 7.5% | 15% | 45% |
| ETH (eMode) | 90% | 93% | 1% | 15% | 80% |
