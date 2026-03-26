# Atomic Token Launch Automation

## Production Launch Script (Foundry)

```solidity
// script/Launch.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MemeCoin.sol";

interface IUniswapV2Router02 {
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IUniswapV2Factory {
    function getPair(address, address) external view returns (address);
}

interface ILPLocker {
    function lockTokens(address token, uint256 amount, uint256 unlockDate, address beneficiary) external returns (uint256 lockId);
}

contract LaunchScript is Script {
    // ── Config (set via .env) ─────────────────────────────────────────────
    MemeCoin      public token;
    IUniswapV2Router02 public router;
    ILPLocker     public locker;

    address constant ROUTER   = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24; // Base Uniswap V2
    address constant LOCKER   = 0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf; // Unicrypt on Base
    address constant DEAD     = 0x000000000000000000000000000000000000dEaD;

    uint256 constant ETH_FOR_LIQ   = 1 ether;       // ETH to pair as initial liquidity
    uint256 constant TOKEN_FOR_LIQ = 700_000_000 * 1e18; // 70% of supply to LP
    uint256 constant LOCK_DURATION = 365 days;       // Lock LP 1 year
    uint256 constant MAX_GAS_PRICE = 50 gwei;        // Abort if gas > 50 gwei

    // State captured during script
    address public lpTokenAddress;
    uint256 public lpTokenAmount;
    uint256 public lockId;

    function run() public {
        uint256 deployerKey  = vm.envUint("PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerKey);
        bool    dryRun       = vm.envOr("DRY_RUN", false);

        if (dryRun) {
            console.log("=== DRY RUN MODE — Simulating on fork ===");
            vm.createSelectFork(vm.envString("BASE_RPC"));
        }

        console.log("Deployer:", deployerAddr);
        console.log("ETH balance:", deployerAddr.balance / 1e18, "ETH");

        // ── STEP 0: Pre-flight checks ──────────────────────────────────────
        _preflight(deployerAddr);

        vm.startBroadcast(deployerKey);

        // ── STEP 1: Deploy token ───────────────────────────────────────────
        token  = _deployToken(deployerAddr);
        router = IUniswapV2Router02(ROUTER);
        locker = ILPLocker(LOCKER);

        // ── STEP 2: Add liquidity ──────────────────────────────────────────
        _addLiquidity();

        // ── STEP 3: Enable trading ─────────────────────────────────────────
        token.enableTrading();
        console.log("Trading enabled at block:", block.number);

        // ── STEP 4: Lock LP ────────────────────────────────────────────────
        _lockLP(deployerAddr);

        // ── STEP 5: Set final taxes ────────────────────────────────────────
        // (Wait is simulated here; in production, run step 5 separately after ~10 min)
        // token.setTaxes(300, 300); // 3%/3% final

        // ── STEP 6: Renounce ownership ─────────────────────────────────────
        // ⚠️  ONLY call after EVERYTHING is set correctly
        // token.renounceOwnership();
        // console.log("Ownership renounced. Owner:", token.owner());

        vm.stopBroadcast();

        _printSummary();
    }

    // ── HELPERS ──────────────────────────────────────────────────────────────

    function _preflight(address deployer) internal view {
        console.log("--- Pre-flight checks ---");
        require(tx.gasprice <= MAX_GAS_PRICE,
            string(abi.encodePacked("Gas too high: ", vm.toString(tx.gasprice / 1e9), " gwei")));
        require(deployer.balance >= ETH_FOR_LIQ + 0.1 ether, "Insufficient ETH (need liq + gas)");
        console.log("[OK] Gas price:", tx.gasprice / 1e9, "gwei");
        console.log("[OK] ETH balance sufficient");
    }

    function _deployToken(address deployer) internal returns (MemeCoin t) {
        console.log("--- Deploying token ---");
        t = new MemeCoin(ROUTER, deployer); // marketingWallet = deployer for launch
        require(t.totalSupply() == 1_000_000_000 * 1e18, "Supply mismatch");
        require(t.owner() == deployer, "Owner mismatch");
        console.log("[OK] Token deployed:", address(t));
        console.log("[OK] Total supply:", t.totalSupply() / 1e18);
    }

    function _addLiquidity() internal {
        console.log("--- Adding liquidity ---");
        token.approve(ROUTER, TOKEN_FOR_LIQ);
        (uint amtToken, uint amtETH, uint liq) = router.addLiquidityETH{value: ETH_FOR_LIQ}(
            address(token), TOKEN_FOR_LIQ, TOKEN_FOR_LIQ * 98 / 100, ETH_FOR_LIQ * 98 / 100,
            address(this), block.timestamp + 300
        );
        lpTokenAddress = IUniswapV2Factory(router.factory()).getPair(address(token), router.WETH());
        lpTokenAmount  = liq;
        require(lpTokenAddress != address(0), "Pair not created");
        require(liq > 0, "Zero LP tokens");
        console.log("[OK] Pair:", lpTokenAddress);
        console.log("[OK] LP tokens received:", liq);
        console.log("[OK] Token in LP:", amtToken / 1e18);
        console.log("[OK] ETH in LP:", amtETH / 1e18);
    }

    function _lockLP(address deployer) internal {
        console.log("--- Locking LP ---");
        IERC20(lpTokenAddress).approve(LOCKER, lpTokenAmount);
        lockId = locker.lockTokens(lpTokenAddress, lpTokenAmount, block.timestamp + LOCK_DURATION, deployer);
        require(IERC20(lpTokenAddress).balanceOf(address(this)) == 0, "LP not fully locked");
        console.log("[OK] LP locked. Lock ID:", lockId);
        console.log("[OK] Unlock date:", block.timestamp + LOCK_DURATION);
    }

    function _printSummary() internal view {
        console.log("=== LAUNCH COMPLETE ===");
        console.log("Token:    ", address(token));
        console.log("Pair:     ", lpTokenAddress);
        console.log("LP Locked:", lpTokenAmount);
        console.log("Lock ID:  ", lockId);
        console.log("");
        console.log("NEXT STEPS:");
        console.log("1. Monitor first 30 blocks (run sniper-defense.ts)");
        console.log("2. After 10 min: setTaxes(300, 300)");
        console.log("3. After 1 hr:   removeLimits()");
        console.log("4. After stable: renounceOwnership()");
        console.log("5. Verify on Etherscan: forge verify-contract", address(token));
    }
}
```

## Etherscan Verification

```bash
# After deployment
forge verify-contract \
  $TOKEN_ADDRESS \
  src/MemeCoin.sol:MemeCoin \
  --constructor-args $(cast abi-encode "constructor(address,address)" $ROUTER $MARKETING) \
  --etherscan-api-key $BASESCAN_API_KEY \
  --chain base \
  --watch
```

## Failure Handling Reference

| Failure Point | Symptom | Recovery |
|---------------|---------|---------|
| Add liquidity reverts | Slippage exceeded | Adjust minAmounts, retry |
| LP lock fails | Approve not set | Re-approve then lock immediately |
| Stuck tx | Nonce blocked | Replace same nonce, higher gas |
| Trading enabled, LP not locked | Deployer can rug | Lock LP immediately with priority gas |
| Renounce too early | Can't change anything | You're fine if everything was set |

## Dry-Run Mode

```bash
# Always simulate first on a Base fork
DRY_RUN=true BASE_RPC=$BASE_RPC forge script script/Launch.s.sol \
  --fork-url $BASE_RPC --private-key $PRIVATE_KEY -vvv

# When ready for real
forge script script/Launch.s.sol \
  --rpc-url $BASE_RPC --private-key $PRIVATE_KEY \
  --broadcast --verify -vvv
```
