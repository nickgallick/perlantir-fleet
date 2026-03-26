# Smart Contract Security

## The Top 20 Vulnerabilities

### 1. Reentrancy
**Impact**: CRITICAL — direct loss of funds
**How**: External call before state update allows recursive calls back into the contract.
```solidity
// VULNERABLE
function withdraw() external {
    uint256 bal = balances[msg.sender];
    (bool ok,) = msg.sender.call{value: bal}(""); // Attacker re-enters here
    balances[msg.sender] = 0; // Too late — already re-entered
}
```
**Prevention**: CEI pattern, OpenZeppelin ReentrancyGuard (`nonReentrant` modifier), pull payments.
**Note**: Read-only reentrancy also exists — re-entering a `view` function that reads stale state.

### 2. Integer Overflow/Underflow
**Impact**: HIGH
Solidity 0.8+ has built-in checks. But `unchecked {}` blocks reintroduce the risk.
Always validate inputs before unchecked math. Never use unchecked on user-supplied values without bounds checking.

### 3. Access Control Failures
**Impact**: CRITICAL
- Missing modifiers on sensitive functions (mint, pause, upgrade, withdraw)
- Unprotected `initialize()` on proxy implementations
- Default `public` visibility when `internal` was intended
**Prevention**: OpenZeppelin AccessControl, explicit visibility on every function, `initializer` modifier.

### 4. Front-Running / MEV
**Impact**: HIGH
Miners/validators see pending transactions and reorder for profit.
**Prevention**: Commit-reveal schemes, private mempools (Flashbots Protect), batch auctions, slippage limits, deadline parameters.

### 5. Oracle Manipulation
**Impact**: CRITICAL
Spot price from a DEX can be manipulated within a single transaction via flash loans.
**Prevention**: TWAP oracles (time-weighted), Chainlink price feeds, multi-oracle systems, circuit breakers on extreme price moves.

### 6. Flash Loan Attacks
**Impact**: CRITICAL
Borrow millions with zero collateral, manipulate prices, profit, repay — all in one tx.
**Prevention**: Time-weighted prices, multi-block validation (check price over N blocks), disallow same-block price changes for critical operations.

### 7. Delegatecall Vulnerabilities
**Impact**: CRITICAL
Storage collision when delegating to a contract with different storage layout.
**Prevention**: Strict storage layout matching, use established proxy patterns (UUPS/Transparent), OpenZeppelin's storage gap pattern.

### 8. Uninitialized Proxy
**Impact**: CRITICAL
Attacker calls `initialize()` on the implementation contract directly, becoming owner.
**Prevention**: Call `_disableInitializers()` in the implementation constructor. Always initialize immediately after proxy deployment.

### 9. Signature Replay
**Impact**: HIGH
Reusing signed messages across chains or contexts.
**Prevention**: Include nonce, chain ID, contract address, and deadline in signed data. Use EIP-712 domain separator.
```solidity
bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
    TYPE_HASH, name, version, block.chainid, address(this)
));
```

### 10. Denial of Service
**Impact**: MEDIUM-HIGH
- Unbounded loops hitting block gas limit
- Reverting recipient in a push-payment loop blocks all subsequent payments
- Griefing via dust deposits to bloat arrays
**Prevention**: Pull payments, pagination, bounded iterations, allow skipping failed transfers.

### 11. Timestamp Dependence
**Impact**: MEDIUM
`block.timestamp` manipulable by validators (~15 seconds on Ethereum).
**Prevention**: Don't use for randomness. Acceptable for deadlines with >15 min granularity. Use Chainlink VRF for randomness.

### 12. tx.origin Authentication
**Impact**: CRITICAL
`tx.origin` returns the original sender of the transaction, not the immediate caller. A malicious contract can trick a user into calling it, then call your contract with the user's `tx.origin`.
**Prevention**: ALWAYS use `msg.sender`. Never `tx.origin` for auth.

### 13. Unchecked Return Values
**Impact**: HIGH
Low-level `call` returns false on failure but doesn't revert. Silently failing transfers.
**Prevention**: Always check: `(bool success,) = addr.call{value: x}(""); require(success);`
Use SafeERC20 for token transfers (handles non-standard tokens that don't return bool).

### 14. Storage Collision in Proxies
**Impact**: CRITICAL
Upgrading a proxy with a new implementation that has different storage variable order.
**Prevention**: Only append new variables, never reorder/remove. Use OpenZeppelin's `@openzeppelin/upgrades-core` for storage layout validation. Use storage gaps: `uint256[50] private __gap;`

### 15. Precision Loss
**Impact**: MEDIUM-HIGH
Integer division truncates in Solidity. `1/3 = 0`.
**Prevention**: Multiply before divide. Use fixed-point math (e.g., WAD = 1e18). Round in protocol's favor.
```solidity
// BAD: (amount * rate) / PRECISION — loses precision if amount*rate < PRECISION
// GOOD: amount.mulDivDown(rate, PRECISION) — using Solmate's FixedPointMathLib
```

### 16. Centralization Risks
**Impact**: MEDIUM-HIGH
Owner keys that can drain funds, pause indefinitely, change rules, upgrade to malicious code.
**Prevention**: Multisig (Safe), timelock on admin actions, governance for critical changes, renounce ownership when possible, transparent admin powers in docs.

### 17. Cross-Chain Replay
**Impact**: HIGH
After chain forks, transactions valid on one chain can be replayed on the other.
**Prevention**: Include `block.chainid` in signed messages and domain separators.

### 18. ERC-20 Approval Race Condition
**Impact**: LOW-MEDIUM
Changing allowance from N to M: spender can spend N + M by front-running the approval change.
**Prevention**: `approve(0)` then `approve(M)`, or use `increaseAllowance`/`decreaseAllowance`.

### 19. Forced ETH via selfdestruct
**Impact**: LOW-MEDIUM
`selfdestruct(payable(target))` forces ETH into a contract, bypassing `receive()` and `fallback()`.
**Prevention**: Never rely on `address(this).balance` for logic. Track balances with internal accounting.
**Note**: `selfdestruct` is deprecated post-Dencun but the ETH-forcing vector still applies on some chains.

### 20. Logic Errors in State Machines
**Impact**: VARIES
Incorrect state transitions allowing operations in wrong states.
**Prevention**: Explicit state enums, require current state in every transition function, emit events on every transition.

## Audit Methodology

### Step-by-Step Contract Review
1. **Read docs** — Understand intended behavior before reading code
2. **Map the attack surface** — All external/public functions, their access controls
3. **Trace state changes** — Every SSTORE, every condition that guards it
4. **Find external calls** — Check for reentrancy (CEI compliance)
5. **Check math** — Overflow, underflow, precision loss, division by zero
6. **Review token interactions** — SafeERC20? Handle fee-on-transfer? Handle non-standard returns?
7. **Check upgrade safety** — Storage layout, initialization, upgrade access control
8. **Assess economic attacks** — Flash loans, oracle manipulation, MEV exposure
9. **Review events** — All state changes logged? Indexed properly?
10. **Centralization assessment** — Admin powers, timelock, multisig, emergency functions
11. **Gas analysis** — Unbounded loops? Block gas limit DoS?
12. **Edge cases** — Zero amounts, max uint256, empty arrays, self-referential calls

### Severity Classification
| Severity | Definition | Examples |
|----------|-----------|---------|
| **CRITICAL** | Direct loss of funds, unauthorized fund access, permanent DoS | Reentrancy draining pools, unprotected withdraw |
| **HIGH** | Conditional loss of funds, privilege escalation, significant economic damage | Oracle manipulation under specific conditions |
| **MEDIUM** | Unexpected behavior, griefing, suboptimal outcomes | DoS on non-critical functions, incorrect event emission |
| **LOW** | Code quality, best practice violations, minor issues | Missing zero-address checks, suboptimal naming |
| **GAS** | Gas optimization opportunities | Cacheable storage reads, unchecked increments |

### Reporting Template
```markdown
## [SEVERITY] Title

**Location**: `Contract.sol#L42`
**Impact**: What can go wrong
**Likelihood**: How likely is exploitation
**Description**: Technical explanation
**Proof of Concept**: Foundry test or attack scenario
**Recommendation**: How to fix
```
