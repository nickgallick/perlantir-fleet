# Advanced Gas Optimization

## Storage Optimization

### Slot Packing
Pack variables that share a 32-byte slot. Order matters.
```solidity
// BAD — 3 slots (96 bytes)
uint256 amount;    // slot 0 (32 bytes)
address owner;     // slot 1 (32 bytes, wasting 12 bytes)
bool active;       // slot 2 (32 bytes, wasting 31 bytes)

// GOOD — 1 slot (32 bytes) — pack address(20) + bool(1) + uint72(9) = 30 bytes
address owner;     // slot 0: bytes 0-19
bool active;       // slot 0: byte 20
uint72 amount;     // slot 0: bytes 21-29 (max ~4.7 * 10^21 — enough for most use cases)
```

### Bit Packing (Advanced)
```solidity
// Store multiple small values in one uint256
uint256 packed; // bits 0-7: status, bits 8-15: tier, bits 16-255: timestamp

function setStatus(uint8 status) internal {
    packed = (packed & ~uint256(0xFF)) | uint256(status);
}

function getStatus() internal view returns (uint8) {
    return uint8(packed & 0xFF);
}
```

### Cache Storage Reads
```solidity
// BAD — 3 SLOAD operations (6,300 gas warm × 3 = ~18,900 gas)
function badLoop() external {
    for (uint i = 0; i < length; i++) {
        if (values[i] > threshold) { /* threshold = 3 SLOADs */ }
    }
}

// GOOD — 1 SLOAD (2,100 gas cold, 100 gas warm after)
function goodLoop() external {
    uint256 _threshold = threshold;  // Cache once
    uint256 _length = length;        // Cache once
    for (uint i = 0; i < _length; i++) {
        if (values[i] > _threshold) { }
    }
}
```

### Immutables & Constants
```solidity
// constant: replaced at compile time (free to read)
uint256 public constant MAX_SUPPLY = 1_000_000e18;

// immutable: stored in bytecode, set in constructor (2.1K gas to read, not SLOAD)
address public immutable factory;
constructor(address _factory) { factory = _factory; }
```

## Computation Optimization

### Unchecked Math
```solidity
// Save ~60 gas per operation when overflow is impossible
function sum(uint256[] calldata arr) external pure returns (uint256 total) {
    for (uint256 i; i < arr.length;) {
        total += arr[i];
        unchecked { ++i; }  // ++i cheaper than i++ (no temporary variable)
    }
}
```

### Short-Circuit Ordering
```solidity
// Put cheapest checks first
require(amount > 0, "Zero amount");           // 3 gas comparison
require(balances[msg.sender] >= amount, "...");  // 2100 gas SLOAD
require(externalCheck(amount), "...");          // External call (costly)
```

### Custom Errors vs Require Strings
```solidity
// BAD: string stored in bytecode, decoded on revert (~200+ gas + deployment cost)
require(amount > 0, "Amount must be greater than zero");

// GOOD: error selector is 4 bytes (selector dispatch cost only)
error AmountIsZero();
if (amount == 0) revert AmountIsZero();
// Saves ~50 gas per revert + deployment gas
```

### Calldata vs Memory Parameters
```solidity
// BAD: copies calldata to memory
function process(uint256[] memory data) external { }

// GOOD: reads directly from calldata (no copy)
function process(uint256[] calldata data) external { }
// Savings: ~3 gas per 32-byte word, significant for large arrays
```

## Transient Storage (EIP-1153, post-Dencun)
Ultra-cheap storage that resets after the transaction. Perfect for reentrancy guards.
```solidity
// Replaces ReentrancyGuard's SSTORE/SLOAD with TSTORE/TLOAD
// TSTORE: 100 gas (vs 20,000 for cold SSTORE)
// TLOAD: 100 gas (vs 2,100 for cold SLOAD)

contract TransientReentrancyGuard {
    uint256 private constant LOCK_SLOT = 0x1;

    modifier nonReentrant() {
        assembly { if tload(LOCK_SLOT) { revert(0, 0) } }
        assembly { tstore(LOCK_SLOT, 1) }
        _;
        assembly { tstore(LOCK_SLOT, 0) }
    }
}
```

## Function Optimization

### Function Selector Optimization
Lower 4-byte selectors are marginally cheaper (EVM checks in order).
Not worth engineering around but good to know.

### Optimal Loop Patterns
```solidity
// Most gas-efficient loop pattern
uint256 length = arr.length; // Cache length
for (uint256 i; i != length;) { // != cheaper than <, start from 0 (default)
    // body
    unchecked { ++i; }
}
```

### Using Assembly for Tight Paths
```solidity
function efficientTransfer(address token, address to, uint256 amount) internal {
    assembly {
        // Load free memory pointer
        let ptr := mload(0x40)
        // Encode transfer(address,uint256)
        mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
        mstore(add(ptr, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
        mstore(add(ptr, 36), amount)
        // Call token contract
        let success := call(gas(), token, 0, ptr, 68, ptr, 32)
        // Check success and return value
        if iszero(and(success, or(iszero(returndatasize()), and(gt(returndatasize(), 31), eq(mload(ptr), 1))))) {
            revert(0, 0)
        }
    }
}
```
Only use assembly if profiling proves the savings justify the complexity and audit cost.

## Deployment Optimization

### Solmate vs OpenZeppelin
Solmate is ~30-50% more gas efficient than OZ for ERC-20/721/1155.
Use Solmate or Solady for gas-critical contracts (not for upgradeable — no initializer support).

### Minimal Proxy (EIP-1167)
For factory-deployed contracts, use clones:
```solidity
address clone = Clones.clone(implementation);
// ~$3-5 gas to deploy vs ~$50+ for full deployment
```

## Gas Profiling Workflow
```bash
# Per-function gas report
forge test --gas-report

# Track changes over commits
forge snapshot
git commit ...
forge snapshot --diff  # Shows gas delta per test

# Specific function gas profiling
forge test --match-test test_buyShares -vvvv 2>&1 | grep "gas:"
```

## Key Gas Numbers to Remember
| Operation | Gas |
|-----------|-----|
| Cold SSTORE (0→nonzero) | 20,000 |
| Cold SLOAD | 2,100 |
| Warm SLOAD | 100 |
| TSTORE (transient) | 100 |
| CALL (cold address) | 2,600 |
| ERC-20 transfer | ~30,000-65,000 |
| ETH transfer | 21,000 |
| Contract deployment (base) | 32,000 |
| LOG2 (2 topics, 32 bytes data) | ~1,500 |
