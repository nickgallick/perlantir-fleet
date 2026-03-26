# Solidity Mastery

## Language Fundamentals (0.8.x+)

### Data Types
- **Value types**: uint8-uint256, int8-int256, address (20 bytes), bool, bytes1-bytes32, enums
- **Reference types**: arrays (fixed/dynamic), structs, mappings, strings
- **Special**: address payable (can receive ETH), function types

### Storage Locations
- **storage**: Persistent on-chain. SSTORE = 20,000 gas (cold zero→nonzero), SLOAD = 2,100 gas (cold). Use sparingly.
- **memory**: Temporary, exists during function execution. Cheap reads/writes but costs gas to expand.
- **calldata**: Read-only input data. Cheapest for external function parameters — no copy needed.
- **stack**: EVM native. 256-bit words, 1024 depth limit. Free to use but limited.

### Function Visibility & Security Implications
- `public`: Callable internally + externally. Generates getter for state vars. ABI-exposed.
- `external`: Only callable from outside. Cheaper than public for large calldata (no memory copy).
- `internal`: Only this contract + derived contracts. Not ABI-exposed.
- `private`: Only this contract. NOT truly private — storage is readable by anyone on-chain.

### Function Modifiers
- `view`: Reads state, no modifications. Free when called externally (no transaction needed).
- `pure`: No state access at all. Free externally.
- `payable`: Can receive ETH with the call. Without payable, sending ETH reverts.
- Custom modifiers: Reusable precondition checks. Use `_;` for function body insertion point.

### Events
```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
```
- `indexed` parameters: searchable in logs (max 3 per event)
- Events are stored in transaction logs, NOT in contract storage — much cheaper than SSTORE
- Essential for frontend: listen to events for real-time updates
- Cost: LOG0 = 375 gas + 8 gas/byte of data + 375 gas per indexed topic

### Error Handling
```solidity
// Custom errors (cheapest — no string storage)
error InsufficientBalance(uint256 available, uint256 required);
revert InsufficientBalance(balance, amount);

// require (readable but costs more due to string)
require(balance >= amount, "Insufficient balance");

// assert (for invariants — consumes all remaining gas on failure pre-0.8.0, now same as revert)
assert(totalSupply == sumOfBalances);
```

### Inheritance
- C3 linearization for multiple inheritance resolution
- `virtual` on base function, `override` on derived
- `super.functionName()` calls the next contract in linearization
- Abstract contracts: at least one unimplemented function
- Interfaces: all functions external, no state, no implementation

### Libraries
```solidity
using SafeERC20 for IERC20; // Attach library functions to a type
```
- **Embedded** (internal functions): Inlined at compile time, no DELEGATECALL overhead
- **Deployed** (external functions): Separate contract, called via DELEGATECALL. Saves deployment gas for large libraries.

### Assembly / Yul
```solidity
assembly {
    let slot := sload(0)           // Read storage slot 0
    sstore(0, add(slot, 1))        // Write storage slot 0
    let ptr := mload(0x40)         // Free memory pointer
    mstore(ptr, value)             // Write to memory
}
```
- Use for: gas-critical paths, operations Solidity can't express, custom memory management
- Avoid for: anything security-critical unless you're extremely confident
- Common pattern: abi.decode in assembly to skip Solidity's checks when you've already validated

### ABI Encoding
- `abi.encode(...)`: Standard encoding, padded to 32 bytes. Safe for hashing.
- `abi.encodePacked(...)`: Tight packing, no padding. DANGEROUS for hashing variable-length types (collision risk).
- `abi.encodeWithSelector(bytes4, ...)`: Prepends function selector.
- `abi.encodeCall(IContract.function, (args))`: Type-safe encoding (compile-time checks).

### Low-Level Calls
```solidity
(bool success, bytes memory data) = target.call{value: 1 ether, gas: 50000}(
    abi.encodeWithSelector(ITarget.doSomething.selector, arg1)
);
require(success, "Call failed");
```
- `call`: Execute function on target. Returns success bool. ALWAYS CHECK RETURN VALUE.
- `delegatecall`: Execute target code in caller's storage context. Core of proxy patterns. DANGEROUS.
- `staticcall`: Read-only call. Reverts if target modifies state.

### Receive & Fallback
```solidity
receive() external payable { } // Called when ETH sent with empty calldata
fallback() external payable { } // Called when no function matches selector
```

## Design Patterns

### Checks-Effects-Interactions (CEI)
The MOST IMPORTANT pattern. Prevents reentrancy.
1. **Checks**: Validate all conditions (require/revert)
2. **Effects**: Update all state variables
3. **Interactions**: External calls LAST
```solidity
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount);  // Check
    balances[msg.sender] -= amount;            // Effect
    (bool ok,) = msg.sender.call{value: amount}(""); // Interaction
    require(ok);
}
```

### Pull Over Push
Don't send ETH/tokens to recipients directly. Let them withdraw.
- Prevents DoS from reverting recipients
- Users pay their own gas for claiming
- Use for: prize distributions, refunds, payment splitting

### Factory Pattern
```solidity
contract MarketFactory {
    function createMarket(bytes32 questionId) external returns (address) {
        Market market = new Market(questionId);
        return address(market);
    }
}
```
- Use CREATE2 for deterministic addresses: `new Market{salt: salt}(args)`

### Minimal Proxy (EIP-1167)
```solidity
address clone = Clones.clone(implementation);
```
- Deploy identical contracts for ~$45k gas instead of ~$500k+
- All clones delegate to one implementation
- Use for: factory-deployed markets, user vaults, per-user contracts

## Gas Optimization Essentials

### Storage
- Pack variables: `uint128 a; uint128 b;` = 1 slot. `uint256 a; uint128 b;` = 2 slots.
- Cache storage reads: `uint256 cached = storageVar;` then use `cached` multiple times
- Use `immutable` for values set in constructor (stored in bytecode, not storage)
- Use `constant` for compile-time constants (replaced inline, zero gas)
- Delete storage for gas refund: `delete mapping[key]` refunds ~4,800 gas

### Functions
- `external` over `public` when only called externally (saves calldata copy to memory)
- `unchecked { i++; }` in loops when overflow is impossible (saves ~60 gas per iteration)
- Custom errors save ~50 gas per revert vs require strings
- Short-circuit: `require(cheapCheck && expensiveCheck)` — cheap check first

### Memory
- Don't return large arrays — use pagination or events
- Use `calldata` for read-only array/struct parameters
- Avoid unnecessary memory copies of storage arrays

## NatSpec Documentation
```solidity
/// @title Market Factory
/// @author Chain
/// @notice Creates and manages prediction markets
/// @dev Uses CREATE2 for deterministic addresses
/// @param questionId The unique identifier for the market question
/// @return market The address of the newly created market
/// @custom:security-contact security@example.com
```
Every public/external function must have NatSpec. Every contract must have @title and @notice.
