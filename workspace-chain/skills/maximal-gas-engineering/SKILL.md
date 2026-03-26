# Maximal Gas Engineering

## EIP-1153 Transient Storage — The Game Changer

Transient storage: 100 gas write, 100 gas read. Cleared at end of transaction. Perfect for:

```solidity
// Before EIP-1153: reentrancy guard costs ~20,000 gas (SSTORE 0→1) + 5,000 (SSTORE 1→0)
// After EIP-1153: reentrancy guard costs 200 gas total (TSTORE + TLOAD)

contract TransientReentrancyGuard {
    uint256 private constant REENTRANCY_SLOT = 0x01;

    modifier nonReentrant() {
        assembly {
            if tload(REENTRANCY_SLOT) { revert(0, 0) }  // Check
            tstore(REENTRANCY_SLOT, 1)                    // Lock
        }
        _;
        assembly {
            tstore(REENTRANCY_SLOT, 0)                    // Unlock
        }
    }

    // Savings: ~24,800 gas → ~200 gas per guarded function call
    // For a function called 1M times: saves 24.6B gas ≈ $50K at 10 gwei
}
```

```solidity
// Flash loan accounting via transient storage (no persistent state needed)
contract FlashLoanWithTransient {
    uint256 private constant FLASH_AMOUNT_SLOT = 0x02;

    function flashLoan(uint256 amount) external {
        assembly { tstore(FLASH_AMOUNT_SLOT, amount) }

        // Send funds and call recipient
        IERC20(TOKEN).transfer(msg.sender, amount);
        IFlashLoanReceiver(msg.sender).onFlashLoan(amount);

        // Verify repayment using transient storage (no persistent slot)
        assembly {
            let borrowed := tload(FLASH_AMOUNT_SLOT)
            if lt(IERC20.balanceOf(address(this)), add(borrowed, FEE)) {
                revert(0, 0)  // Not repaid
            }
            tstore(FLASH_AMOUNT_SLOT, 0)
        }
    }
}
```

## Sub-Opcode Optimization Patterns

```solidity
// TECHNIQUE 1: Optimal function selector ordering
// Most-called function = lowest selector value = checked first in dispatcher
// Sort functions by call frequency, not alphabetically

// Before (alphabetical): approve (0x..5f), balanceOf (0x70a0), transfer (0xa905), ...
// After (optimal): put transfer first if it's 90% of calls
// Saves 22 gas per JUMPI instruction skipped for the common path

// TECHNIQUE 2: Pack hot variables together in first storage slot
contract GasOptimizedState {
    // SLOT 0 — pack into one 32-byte slot (all hot path variables):
    uint128 public price;       // 16 bytes
    uint64  public lastUpdate;  // 8 bytes
    uint32  public flags;       // 4 bytes
    uint32  public version;     // 4 bytes
    // Total: 32 bytes = 1 SLOAD reads ALL of these together

    // SLOT 1 — cold data (infrequently accessed):
    address public owner;       // 20 bytes (+ 12 wasted)

    // SLOT 2+ — mappings:
    mapping(address => uint256) public balances; // Each entry = separate SLOAD
}

// TECHNIQUE 3: Avoid redundant zero checks in Yul
function transferOptimized(address to, uint256 amount) external {
    assembly {
        // Load balance (single SLOAD)
        let balanceSlot := add(keccak256(0, 64), caller())  // simplified
        let senderBal := sload(balanceSlot)

        // Check and update in one block (no intermediate zeros)
        if lt(senderBal, amount) { revert(0, 0) }
        sstore(balanceSlot, sub(senderBal, amount))

        // Recipient balance
        let recipientSlot := add(keccak256(0, 64), to)
        sstore(recipientSlot, add(sload(recipientSlot), amount))

        // Emit Transfer event
        mstore(0x00, amount)
        log3(0x00, 0x20,
            0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
            caller(), to)
    }
}
```

## Bytecode Size — Hit the 24KB Ceiling

```solidity
// TECHNIQUE 1: Custom errors (not strings)
// error InsufficientBalance(uint256 have, uint256 need); → 4 bytes on-chain
// require(bal >= amount, "Insufficient balance, cannot complete transfer"); → 52 bytes

// TECHNIQUE 2: Extract repeated logic to internal function
// BAD: modifier used 10 times = modifier code inlined 10 times
modifier checkRole() {
    require(hasRole(MINTER_ROLE, msg.sender), "Not authorized");
    _;
}

// GOOD: call internal function (single copy in bytecode, minimal overhead)
function _requireRole() internal view {
    require(hasRole(MINTER_ROLE, msg.sender), "Not authorized");
}

// TECHNIQUE 3: Library linking
// Deploy shared logic as external library → multiple contracts share one deployment
library SafeMath {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;  // Not inlined — single deployed copy
    }
}

// TECHNIQUE 4: Split large contracts
// If a contract is near 24KB: split into core + extension
// Core contract: primary user-facing functions
// Extension contract: admin functions called rarely (via DELEGATECALL)
```

## ERC-7201 Namespaced Storage

```solidity
// The modern proxy storage pattern — no collision risk
contract NamespacedStorage {
    // Derive a storage slot that's virtually impossible to collide with
    // Convention: keccak256(fully_qualified_name) - 1
    bytes32 private constant STORAGE_SLOT =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;
        // = keccak256("protocol.storage.SpartaChallenge.v1") - 1

    struct Storage {
        mapping(bytes32 => Challenge) challenges;
        mapping(address => uint256) balances;
        address owner;
        bool paused;
        uint256 version;
    }

    function _getStorage() private pure returns (Storage storage s) {
        assembly { s.slot := STORAGE_SLOT }
    }

    function getChallengeCount() public view returns (uint256) {
        return _getStorage().challengeCount;
    }
}

// Why "-1": prevents the hash preimage from matching the slot
// Someone can't craft calldata that accidentally hits your storage namespace
```

## Gas Measurement Automation

```bash
# Baseline snapshot
forge snapshot

# After changes: compare
forge snapshot --diff

# Example output:
# SpartaTest::test_enterChallenge  gas: 185,432 (-3,200) ← saved 3.2K gas
# SpartaTest::test_finalizeResult  gas: 92,100  (+150)   ← small regression, investigate

# In CI: fail if any function regresses by >1% gas
forge snapshot --check --tolerance 1
```
