# Formal Verification & Advanced Analysis

## The Security Stack (in order of application)

```
1. Slither (CI) ─────────── Every PR, catches common patterns fast
2. Mythril ──────────────── Symbolic execution, deeper bug finding
3. Fuzz Testing (Echidna) ── Property-based, finds edge cases
4. Invariant Tests (Forge) ─ Foundry-native invariant testing
5. Manual Audit ─────────── Pre-launch, expert human review
6. Formal Verification ───── Certora/Halmos for high-value contracts
7. Bug Bounty ───────────── Post-launch, ongoing (Immunefi)
```

## Slither (Static Analysis)

### Setup & Usage
```bash
pip install slither-analyzer
slither . --filter-paths "test,script,lib" --triage-mode

# CI integration (fail on high findings)
slither . --json slither-output.json || exit 1

# Specific detector
slither . --detect reentrancy-eth,unprotected-upgrade
```

### Key Detectors
- `reentrancy-eth` / `reentrancy-no-eth`: CEI violations
- `unprotected-upgrade`: UUPS without access control
- `suicidal`: `selfdestruct` callable by anyone
- `arbitrary-send-eth`: ETH sent to user-controlled address
- `controlled-delegatecall`: delegatecall target from user input
- `incorrect-equality`: `==` on block.timestamp (should be `>=`)
- `divide-before-multiply`: precision loss pattern

## Echidna (Property-Based Fuzzing)

```solidity
// echidna.config.yaml
testMode: assertion  # or: property, exploration
testLimit: 100000    # Number of sequences to try
seqLen: 100          # Max calls per sequence
workers: 4

contract MarketEchidna is Market {
    // Properties that must ALWAYS hold
    function echidna_totalAlwaysPositive() external view returns (bool) {
        return totalPool >= 0;  // Trivially true, but test it anyway
    }

    function echidna_noFreeShares() external view returns (bool) {
        // Total outstanding shares ≤ total collateral deposited
        return totalShares <= totalCollateral;
    }

    function echidna_pricesSumToOne() external view returns (bool) {
        if (totalShares == 0) return true;
        // YES price + NO price should equal 1 (within precision)
        uint256 yes = getYesPrice();
        uint256 no = getNoPrice();
        return yes + no == 1e18;
    }
}
```

```bash
echidna . --contract MarketEchidna --config echidna.config.yaml
```

## Halmos (Symbolic Execution for Foundry)

Halmos runs your Foundry tests symbolically — tests every possible input simultaneously.

```solidity
// Works with regular Foundry tests
// `forge test` runs concrete tests; `halmos` runs symbolically

function testWithdrawCorrectness(uint256 amount) external {
    vm.assume(amount > 0 && amount <= totalDeposits);
    uint256 balBefore = token.balanceOf(address(this));
    market.withdraw(amount);
    uint256 balAfter = token.balanceOf(address(this));
    assert(balAfter == balBefore + amount);  // Halmos proves this for ALL amounts
}
```

```bash
pip install halmos
halmos --contract MarketTest --function testWithdrawCorrectness
```

## Certora Prover (Formal Verification)

For high-value contracts (>$1M TVL). Proves mathematical properties hold for ALL possible inputs.

### CVL (Certora Verification Language) Spec
```
// Market.spec

methods {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external returns uint256 envfree;
    function totalDeposits() external returns uint256 envfree;
}

// RULE: withdrawing reduces your balance by exactly the amount
rule withdrawReducesBalance(uint256 amount) {
    address user;
    require balanceOf(user) >= amount;

    uint256 balBefore = balanceOf(user);
    withdraw(amount);
    uint256 balAfter = balanceOf(user);

    assert balAfter == balBefore - amount,
        "Withdraw did not reduce balance correctly";
}

// INVARIANT: sum of all balances equals total deposits
invariant totalIsConsistent()
    totalDeposits() == sum_of_all_balances
    {
        preserved deposit(uint256 amount) with (env e) {
            require e.msg.sender != 0;
        }
    }
```

### When Certora is Worth the Cost
- Token contracts holding user funds
- Lending pools / collateral management
- Bridge contracts
- Any contract where mathematical invariants = solvency

## Mythril (Symbolic Execution)

```bash
pip install mythril
myth analyze src/Market.sol --solc-json remappings.json
myth analyze --address 0xDeployedAddress --rpc https://mainnet.base.org
```

Finds: reentrancy, integer overflow, transaction order dependence, unchecked return values.

## Formal Verification Decision Matrix

| Contract TVL | Minimum Required | Recommended |
|-------------|-----------------|-------------|
| < $100K | Slither + Foundry fuzz | + Manual review |
| $100K - $1M | Above + External audit | + Echidna |
| $1M - $10M | Above + Formal verification | + Certora |
| > $10M | All of the above | + Multiple auditors + Bug bounty |

## Bug Bounty Setup (Immunefi)

After launch, run a bug bounty program:
- Define scope (which contracts, which chains)
- Set severity/payout matrix (Critical: up to $500K, High: $50K, etc.)
- Clearly define what's in scope vs out of scope
- Have funds available in a bug bounty wallet before announcing
- Respond within 24 hours to critical findings

Critical bounties must be funded. Protocols that have bounties but can't pay get drained and ignored.
