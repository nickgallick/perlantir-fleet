# Foundry Testing & Toolchain

## Toolchain Overview
- **forge**: Build, test, deploy, verify contracts
- **cast**: Interact with deployed contracts from CLI
- **anvil**: Local Ethereum node for testing (fork-capable)
- **chisel**: Solidity REPL for quick experiments

## Project Setup
```bash
forge init my-project          # New project
forge install OpenZeppelin/openzeppelin-contracts  # Install deps
forge build                     # Compile
forge test                      # Run all tests
forge test -vvvv               # Max verbosity (trace calls)
forge test --match-test testFuzz_  # Run specific tests
```

## Test Structure
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Market} from "../src/Market.sol";

contract MarketTest is Test {
    Market market;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        market = new Market();
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function test_deposit() public {
        vm.prank(alice);
        market.deposit{value: 1 ether}();
        assertEq(market.balances(alice), 1 ether);
    }

    function testFail_withdrawTooMuch() public {
        vm.prank(alice);
        market.withdraw(1 ether); // Should revert
    }
}
```

## Essential Cheatcodes
```solidity
// Identity & ETH
vm.prank(address)              // Next call from this address
vm.startPrank(address)         // All subsequent calls from this address
vm.stopPrank()                 // Stop pranking
vm.deal(address, amount)       // Set ETH balance
makeAddr("label")              // Deterministic address from label

// Time & Blocks
vm.warp(timestamp)             // Set block.timestamp
vm.roll(blockNumber)           // Set block.number
skip(seconds)                  // Advance timestamp by N seconds

// Expectations
vm.expectRevert()              // Next call must revert
vm.expectRevert(CustomError.selector)  // Specific error
vm.expectRevert(abi.encodeWithSelector(CustomError.selector, arg1))
vm.expectEmit(true, true, false, true)  // Check indexed params + data
emit ExpectedEvent(arg1, arg2);         // The expected event
contract.functionThatEmits();            // The actual call

// Storage & State
vm.store(address, slot, value) // Write storage directly
vm.load(address, slot)         // Read storage directly

// Token Mocking
deal(address(token), user, amount)  // Set ERC-20 balance
```

## Fuzz Testing
```solidity
function testFuzz_deposit(uint256 amount) public {
    amount = bound(amount, 1, 100 ether);  // Constrain input
    vm.deal(alice, amount);
    vm.prank(alice);
    market.deposit{value: amount}();
    assertEq(market.balances(alice), amount);
}
```
- Foundry generates random inputs automatically (256 runs default, configurable)
- Use `bound()` to constrain to valid ranges
- Use `vm.assume()` sparingly (skips invalid inputs, can slow tests)
- Config: `[fuzz] runs = 1000` in foundry.toml for more coverage

## Invariant Testing
```solidity
contract MarketInvariantTest is Test {
    Market market;
    Handler handler;

    function setUp() public {
        market = new Market();
        handler = new Handler(market);
        targetContract(address(handler));
    }

    function invariant_totalDepositsMatchBalance() public view {
        assertEq(market.totalDeposits(), address(market).balance);
    }

    function invariant_noNegativeBalances() public view {
        // Check critical financial invariants
        assertGe(address(market).balance, 0);
    }
}

contract Handler is Test {
    Market market;
    constructor(Market _market) { market = _market; }

    function deposit(uint256 amount) public {
        amount = bound(amount, 0.01 ether, 10 ether);
        vm.deal(msg.sender, amount);
        market.deposit{value: amount}();
    }
}
```
- Define properties that must ALWAYS hold regardless of call sequence
- Handler contracts constrain random function calls to valid ranges
- Foundry calls handler functions randomly, checks invariants after each call sequence

## Fork Testing
```solidity
function test_swapOnUniswap() public {
    uint256 forkId = vm.createFork("https://mainnet.infura.io/v3/KEY");
    vm.selectFork(forkId);

    // Now running against real mainnet state
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    // Test against real contracts...
}
```
- Test against actual mainnet state (tokens, oracles, pools)
- `vm.rollFork(blockNumber)` to pin to a specific block
- Essential for testing oracle integrations, DEX interactions

## Gas Profiling
```bash
forge test --gas-report                    # Gas per function
forge snapshot                              # Save gas snapshot
forge snapshot --diff                       # Compare to last snapshot
```
- `forge snapshot` in CI: alert on gas regressions
- Set gas budgets: if function exceeds N gas, test fails

## Coverage
```bash
forge coverage                              # Line/branch coverage report
forge coverage --report lcov                # For CI integration
```
- Target: 100% line coverage minimum for production contracts
- Branch coverage: ensure all conditional paths tested

## Deployment Scripts
```solidity
contract DeployMarket is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        Market market = new Market();
        console2.log("Market deployed at:", address(market));

        vm.stopBroadcast();
    }
}
```
```bash
forge script script/Deploy.s.sol:DeployMarket \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_KEY
```

## Production Testing Standards
1. ✅ 100% line coverage
2. ✅ Fuzz testing on ALL functions accepting user input
3. ✅ Invariant testing for ALL financial invariants
4. ✅ Fork tests for ALL external integrations (oracles, DEXes, tokens)
5. ✅ Gas snapshot in CI — alert on regressions >5%
6. ✅ Slither static analysis passing with zero highs
7. ✅ Edge case tests: zero amounts, max values, empty arrays, self-transfers
