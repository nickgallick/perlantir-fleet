# Advanced Testing & Verification

## Invariant Testing (Foundry)

### Financial Invariants for Prediction Markets
```solidity
contract MarketInvariantTest is Test {
    MarketFactory factory;
    Market market;
    Handler handler;

    function setUp() public {
        factory = new MarketFactory(usdc, oracle);
        (address m,) = factory.createMarket(questionId, "Test", block.timestamp + 1 days);
        market = Market(m);
        handler = new Handler(market, usdc);

        // Target the handler — Foundry calls its functions randomly
        targetContract(address(handler));

        // Fund handler actors
        deal(address(usdc), address(handler), 1_000_000e6);
    }

    // INVARIANT: Total collateral = sum of all outcome token supplies
    function invariant_collateralBacksAllTokens() public view {
        uint256 totalCollateral = usdc.balanceOf(address(market));
        uint256 totalYes = market.totalYesShares();
        uint256 totalNo = market.totalNoShares();
        // Every YES+NO pair is backed by 1 USDC
        assertEq(totalCollateral, Math.max(totalYes, totalNo));
    }

    // INVARIANT: YES price + NO price = 1.0 (within precision)
    function invariant_pricesSumToOne() public view {
        uint256 yesPrice = market.getYesPrice();
        uint256 noPrice = market.getNoPrice();
        assertApproxEqAbs(yesPrice + noPrice, 1e18, 1e12); // 0.0001% tolerance
    }

    // INVARIANT: No user can have negative balance
    function invariant_noNegativeBalances() public view {
        address[] memory actors = handler.getActors();
        for (uint i = 0; i < actors.length; i++) {
            assertGe(market.yesShares(actors[i]), 0);
            assertGe(market.noShares(actors[i]), 0);
        }
    }

    // INVARIANT: Resolved market total payouts ≤ total collateral
    function invariant_payoutsNeverExceedCollateral() public view {
        if (!market.resolved()) return;
        uint256 totalCollateral = usdc.balanceOf(address(market));
        uint256 totalPayable = market.totalPayableAmount();
        assertLe(totalPayable, totalCollateral);
    }
}

// Handler: simulates realistic user behavior
contract Handler is Test {
    Market market;
    IERC20 usdc;
    address[] public actors;

    constructor(Market _market, IERC20 _usdc) {
        market = _market;
        usdc = _usdc;
        for (uint i = 0; i < 10; i++) {
            actors.push(makeAddr(string(abi.encodePacked("actor", i))));
            deal(address(usdc), actors[i], 100_000e6);
        }
    }

    function buyYes(uint256 actorSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        amount = bound(amount, 1e6, 10_000e6); // $1 to $10,000

        vm.startPrank(actor);
        usdc.approve(address(market), amount);
        market.buyShares(1, amount); // 1 = YES
        vm.stopPrank();
    }

    function buyNo(uint256 actorSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        amount = bound(amount, 1e6, 10_000e6);

        vm.startPrank(actor);
        usdc.approve(address(market), amount);
        market.buyShares(0, amount); // 0 = NO
        vm.stopPrank();
    }

    function getActors() external view returns (address[] memory) {
        return actors;
    }
}
```

### Running Invariant Tests
```bash
# Default: 256 sequences, each up to 16 calls
forge test --match-contract InvariantTest

# Deep run: more sequences and longer call chains
forge test --match-contract InvariantTest \
    --fuzz-runs 10000 \
    --fuzz-depth 100
```

## Stateful Fuzz Testing (Actor-Based)

```solidity
contract StatefulFuzzTest is Test {
    // Multiple actors interact simultaneously
    function testFuzz_multiActorScenario(
        uint256 aliceAmount,
        uint256 bobAmount,
        uint8 aliceOutcome,
        uint8 bobOutcome,
        uint256 timeDelta
    ) public {
        aliceAmount = bound(aliceAmount, 1e6, 100_000e6);
        bobAmount = bound(bobAmount, 1e6, 100_000e6);
        aliceOutcome = aliceOutcome % 2;
        bobOutcome = bobOutcome % 2;
        timeDelta = bound(timeDelta, 0, 30 days);

        // Alice buys
        vm.prank(alice);
        usdc.approve(address(market), aliceAmount);
        vm.prank(alice);
        market.buyShares(aliceOutcome, aliceAmount);

        // Time passes
        skip(timeDelta);

        // Bob buys
        vm.prank(bob);
        usdc.approve(address(market), bobAmount);
        vm.prank(bob);
        market.buyShares(bobOutcome, bobAmount);

        // Verify invariants still hold
        assertEq(
            usdc.balanceOf(address(market)),
            aliceAmount + bobAmount
        );
    }
}
```

## Symbolic Execution with Halmos

```solidity
// Halmos runs Foundry tests symbolically — proves for ALL inputs
// Install: pip install halmos
// Run: halmos --contract MarketSymbolicTest

contract MarketSymbolicTest is Test {
    Market market;

    function setUp() public {
        market = new Market();
        market.initialize(questionId, conditionId, block.timestamp + 365 days);
    }

    // Halmos proves: withdrawal amount always equals deposit amount (minus fees)
    function check_withdrawCorrectness(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);

        uint256 balBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        market.buyShares(1, amount);

        // If market resolves YES...
        vm.prank(oracle);
        market.resolveMarket(1);

        vm.prank(alice);
        market.redeemShares();

        uint256 balAfter = usdc.balanceOf(alice);
        // Halmos proves this holds for ALL valid amounts:
        assert(balAfter == balBefore); // Full refund for winning shares
    }
}
```

## Mutation Testing (Gambit/Certora)

```bash
# Install Gambit
pip install gambit-sol

# Generate mutants
gambit mutate --solc-remappings "forge-std/=lib/forge-std/src/" src/Market.sol

# Run tests against each mutant
for mutant in gambit_out/mutants/*/; do
    cp "$mutant/Market.sol" src/Market.sol
    forge test --no-match-contract Invariant 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "SURVIVED: $mutant"  # Your tests are WEAK here
    else
        echo "KILLED: $mutant"    # Tests caught the mutation
    fi
    git checkout src/Market.sol
done
```

Mutation types:
- Change `<` to `<=` (boundary condition)
- Remove `require` statements (access control)
- Flip boolean conditions
- Change arithmetic operators (`+` to `-`)
- Replace constants with 0 or max values

Target: >90% mutation kill rate.

## Differential Testing

```solidity
// Compare Yul-optimized vs reference Solidity implementation
contract DifferentialTest is Test {
    MarketReference ref;    // Pure Solidity
    MarketOptimized opt;    // Yul-optimized

    function testFuzz_buySharesMatch(uint8 outcome, uint256 amount) public {
        outcome = outcome % 2;
        amount = bound(amount, 1e6, 1_000_000e6);

        // Execute on both
        uint256 refCost = ref.buyShares(outcome, amount);
        uint256 optCost = opt.buyShares(outcome, amount);

        // Results must be identical
        assertEq(refCost, optCost, "Mismatch between reference and optimized");
    }
}
```

## Formal Specification (Certora CVL)

```cvl
// Market.spec — formal properties

methods {
    function buyShares(uint8, uint256) external;
    function redeemShares() external;
    function totalYesShares() external returns uint256 envfree;
    function totalNoShares() external returns uint256 envfree;
    function resolved() external returns bool envfree;
}

// RULE: buying increases share count
rule buyIncreasesShares(uint8 outcome, uint256 amount) {
    env e;
    require amount > 0;
    require outcome <= 1;

    uint256 yesBefore = totalYesShares();
    uint256 noBefore = totalNoShares();

    buyShares(e, outcome, amount);

    if (outcome == 1) {
        assert totalYesShares() == yesBefore + amount;
        assert totalNoShares() == noBefore;
    } else {
        assert totalNoShares() == noBefore + amount;
        assert totalYesShares() == yesBefore;
    }
}

// INVARIANT: resolved market payouts never exceed collateral
invariant solvency()
    !resolved() || totalPayable() <= totalCollateral()
```

## Testing Pyramid for Production Contracts

```
                    ┌──────────┐
                    │  Formal  │ ← Certora/Halmos for critical paths
                   ┌┤Verification├┐
                  │ └──────────┘ │
                 ┌┤  Invariant   ├┐ ← Financial invariants
                │ │   Testing    │ │
               ┌┤ └──────────────┘├┐
              │ │   Fuzz Testing   │ │ ← Random inputs, 10K+ runs
             ┌┤ └──────────────────┘├┐
            │ │  Integration Tests   │ │ ← Multi-contract interactions
           ┌┤ └──────────────────────┘├┐
          │ │      Unit Tests          │ │ ← Every function, every path
          └────────────────────────────┘
```
