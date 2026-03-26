# Yield Optimization & Vaults (Yearn Architecture)

## ERC-4626 Vault Foundation

```solidity
contract YieldVault is ERC4626 {
    // ERC-4626: deposit → shares, withdraw → assets
    // Share price = totalAssets / totalSupply
    // As vault earns yield, totalAssets grows → shares appreciate

    constructor(IERC20 _asset, string memory _name, string memory _symbol)
        ERC4626(_asset)
        ERC20(_name, _symbol)
    {}

    // Override to account for strategy deployments
    function totalAssets() public view override returns (uint256) {
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        uint256 deployed = _totalStrategyAssets();
        return idle + deployed;
    }

    function _totalStrategyAssets() internal view returns (uint256 total) {
        for (uint i = 0; i < strategies.length; i++) {
            total += IStrategy(strategies[i]).estimatedTotalAssets();
        }
    }
}
```

## Strategy Pattern

```solidity
interface IStrategy {
    function vault() external view returns (address);
    function estimatedTotalAssets() external view returns (uint256);
    function harvest() external returns (uint256 profit, uint256 loss);
    function withdraw(uint256 amount) external returns (uint256 loss);
    function migrate(address newStrategy) external;
}

contract AaveV3Strategy is IStrategy {
    address public immutable vault;
    IPool public immutable aavePool;
    IERC20 public immutable want;    // e.g., USDC
    IERC20 public immutable aToken;  // e.g., aUSDC

    // Deploy vault funds to Aave
    function invest(uint256 amount) external onlyVault {
        want.approve(address(aavePool), amount);
        aavePool.supply(address(want), amount, address(this), 0);
    }

    // Report yield and reinvest
    function harvest() external onlyKeeper returns (uint256 profit, uint256 loss) {
        uint256 before = want.balanceOf(address(this));

        // Claim any additional rewards (AAVE token emissions)
        _claimRewards();

        // Sell reward tokens for want token
        _swapRewardsToWant();

        uint256 after = want.balanceOf(address(this));
        profit = after > before ? after - before : 0;
        loss = before > after ? before - after : 0;

        // Reinvest profit
        if (profit > 0) {
            aavePool.supply(address(want), profit, address(this), 0);
        }
    }

    function estimatedTotalAssets() external view returns (uint256) {
        return aToken.balanceOf(address(this)); // aToken balance grows with interest
    }

    function withdraw(uint256 amount) external onlyVault returns (uint256 loss) {
        uint256 before = want.balanceOf(address(this));
        aavePool.withdraw(address(want), amount, address(this));
        uint256 withdrawn = want.balanceOf(address(this)) - before;
        loss = amount > withdrawn ? amount - withdrawn : 0;
        want.safeTransfer(vault, withdrawn);
    }
}
```

## Multi-Strategy Vault with Allocation

```solidity
contract MultiStrategyVault is ERC4626 {
    struct StrategyParams {
        uint256 allocationBps;   // % of funds allocated (e.g., 3000 = 30%)
        uint256 debtRatio;       // Current actual allocation
        uint256 lastHarvest;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalLoss;
        bool active;
    }

    address[] public withdrawalQueue; // Priority order for withdrawals
    mapping(address => StrategyParams) public strategies;
    uint256 public totalAllocationBps; // Must not exceed 10000

    // Allocate funds to strategies after deposit
    function _afterDeposit(uint256 assets) internal {
        for (uint i = 0; i < withdrawalQueue.length; i++) {
            address strategy = withdrawalQueue[i];
            StrategyParams memory params = strategies[strategy];
            if (!params.active) continue;

            uint256 targetDebt = (totalAssets() * params.allocationBps) / 10_000;
            if (targetDebt > params.totalDebt) {
                uint256 credit = targetDebt - params.totalDebt;
                IERC20(asset()).safeTransfer(strategy, credit);
                IStrategy(strategy).invest(credit);
                strategies[strategy].totalDebt += credit;
            }
        }
    }

    // Harvest all strategies
    function harvest(address strategy) external onlyKeeper {
        (uint256 profit, uint256 loss) = IStrategy(strategy).harvest();
        StrategyParams storage params = strategies[strategy];
        params.totalGain += profit;
        params.totalLoss += loss;
        params.lastHarvest = block.timestamp;
    }
}
```

## Auto-Compounding Math

```
Without compounding:
  10% APY on $1000 = $100/year

With daily compounding:
  APY = (1 + 0.10/365)^365 - 1 ≈ 10.52%
  
Optimal harvest frequency:
  profit_per_harvest = P × r × t  (P=principal, r=rate, t=time)
  gas_cost = constant (e.g., $5 on Base)
  
  Harvest when: profit_per_harvest > gas_cost
  t_optimal = gas_cost / (P × r)
  
  Example: $100K vault, 10% APY = $27.40/day
  Gas cost = $5 → harvest every 0.18 days ≈ every 4.4 hours
  But: frequent harvesting causes gas waste at scale → keeper bots optimize dynamically
```

## Vault Security Patterns

```solidity
contract SecureVault is MultiStrategyVault {
    uint256 public emergencyShutdown; // If set, stop all new deposits
    uint256 public maxSlippage = 50;  // 0.5% max slippage on harvest swaps
    uint256 public lossLimit = 100;   // 1% loss limit before pausing strategy

    // Withdrawal limit: max X% of TVL per period (prevents bank run exploitation)
    uint256 public withdrawalLimit = 1000; // 10% per period
    mapping(uint256 => uint256) public withdrawalsThisPeriod;

    function _beforeWithdraw(uint256 assets) internal {
        uint256 period = block.timestamp / 1 days;
        withdrawalsThisPeriod[period] += assets;
        uint256 limit = totalAssets() * withdrawalLimit / 10_000;
        require(withdrawalsThisPeriod[period] <= limit, "Daily withdrawal limit");
    }

    // Strategy health check
    function _assessStrategy(address strategy) internal {
        StrategyParams storage params = strategies[strategy];
        uint256 lossRatio = (params.totalLoss * 10_000) / (params.totalDebt + 1);
        if (lossRatio > lossLimit) {
            // Revoke and withdraw
            params.active = false;
            IStrategy(strategy).withdraw(params.totalDebt);
        }
    }
}
```

## Convex/Yearn Composability

```
Yearn's CRV strategy:
1. User deposits USDC into Yearn vault
2. Vault deposits USDC into Curve 3pool → receives 3CRV LP tokens
3. Strategy stakes 3CRV into Convex → receives cvx3CRV
4. Convex stakes in Curve gauge → earns CRV + CVX rewards
5. Convex aggregates CRV → boosts APY via veCRV holdings
6. Harvest: sell CRV + CVX → buy more USDC → compound
7. User earns: Curve trading fees + boosted CRV rewards + CVX rewards
   (All auto-compounded, all in one deposit)
```

## APY vs APR
```
APR = annual return without compounding (simple interest)
APY = annual return WITH compounding

APY = (1 + APR/n)^n - 1  where n = compounding periods per year

For harvest every 8 hours (3 times/day, 1095 times/year):
  10% APR → APY = (1 + 0.10/1095)^1095 - 1 ≈ 10.52%
  
Always show APY to users — it's the actual return.
Always show APR to regulators — APY can look misleadingly high.
```
