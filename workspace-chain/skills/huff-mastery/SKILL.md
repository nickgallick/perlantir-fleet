# Huff Language — EVM Bytecode Mastery

## 1. Huff Philosophy

### Why Huff Exists

Huff is a low-level assembly macro language for the EVM. It gives developers direct control over every opcode in the deployed bytecode, eliminating all overhead from Solidity's safety checks, ABI encoding, memory management, and free memory pointer maintenance.

Core motivations: **maximum gas optimization** (you decide exactly which opcodes execute), **direct bytecode control** (no optimizer rearranging your code), and **minimal abstraction** (macros and constants are the only abstractions — no types, inheritance, or visibility modifiers).

### When to Use Huff vs Solidity vs Yul

| Criteria              | Solidity   | Yul          | Huff       |
|-----------------------|------------|--------------|------------|
| Developer productivity| High       | Medium       | Low        |
| Gas efficiency        | Good       | Very Good    | Maximum    |
| Auditability          | High       | Medium       | Low        |
| Bytecode control      | None       | Partial      | Total      |
| Safety guarantees     | Strong     | Moderate     | None       |

Use Huff for: DEX routers, MEV bots, precompile-like contracts with tiny ABI surfaces, or deep EVM education. Avoid Huff for complex business logic or when gas savings over optimized Solidity are negligible.

### The Macro Assembler Concept

Huff is a macro assembler — you write EVM opcode sequences, and macros let you compose reusable sequences. At compile time, macros expand inline (no JUMP overhead unless you choose it).

```huff
#define macro ADD_TWO() = takes(2) returns(1) {
    add    // Stack: [a, b] -> [a+b]
}
```

The `takes`/`returns` annotations are documentation only — Huff does not enforce them at compile time.

---

## 2. EVM Stack Machine Review

### Stack Operations

```
PUSH1..PUSH32  — Push 1-32 bytes onto the stack
POP            — Remove top element
DUP1..DUP16   — Copy nth element (1-indexed from top) to top
SWAP1..SWAP16  — Swap top with (n+1)th element
```

### Memory Model

Memory is byte-addressable, grows in 32-byte chunks with quadratic expansion cost.

```
MSTORE(offset, value)  — Store 32-byte word at offset
MSTORE8(offset, value) — Store single byte
MLOAD(offset)          — Load 32-byte word from offset
MSIZE                  — Current memory size (always multiple of 32)
```

In Huff, you manage memory manually with fixed offsets. There is no free memory pointer.

### Storage

Persistent key-value store: 256-bit keys to 256-bit values.

```
SSTORE(slot, value)  — Write (cold: 20000 gas for zero->nonzero)
SLOAD(slot)          — Read (cold: 2100 gas, warm: 100 gas)
```

### Calldata

```
CALLDATALOAD(offset)           — Load 32 bytes from calldata at offset
CALLDATASIZE                   — Push calldata length
CALLDATACOPY(dest, offset, sz) — Copy calldata region to memory
```

First 4 bytes = function selector. Arguments start at offset 4.

### Return Data and Control Flow

```
RETURN(offset, size)    — Halt, return memory[offset..offset+size]
REVERT(offset, size)    — Halt, revert with error data
RETURNDATASIZE          — Size of last call's return data (0 before any call — cheap zero push)
JUMP(dest)              — Unconditional jump
JUMPI(dest, condition)  — Jump if condition != 0
JUMPDEST                — Valid jump target marker
```

Gas trick: `RETURNDATASIZE` costs 2 gas vs `PUSH1 0x00` at 3 gas — use it as a free zero before any external call.

---

## 3. Huff Syntax

### Macros and Functions

```huff
#define macro TRANSFER() = takes(0) returns(0) { /* opcodes */ }

// fn creates JUMP-based subroutines (rarely used — inline macros are cheaper)
#define fn SAFE_ADD() = takes(2) returns(1) {
    dup2 dup2 add dup1 swap2 gt overflow jumpi
    swap1 pop back jump
    overflow: 0x00 0x00 revert
    back:
}
```

### Constants

```huff
#define constant OWNER_SLOT = 0x00
#define constant MAX_SUPPLY = 0xDE0B6B3A7640000  // 1e18

#define macro GET_OWNER() = takes(0) returns(1) {
    [OWNER_SLOT] sload    // [CONSTANT_NAME] syntax inlines as PUSH
}
```

### Errors, Events, and ABI Functions

```huff
#define error InsufficientBalance()
#define event Transfer(address indexed from, address indexed to, uint256 amount)
#define function balanceOf(address) view returns (uint256)
#define function transfer(address, uint256) nonpayable returns (bool)
```

### Built-in Functions

```huff
__FUNC_SIG(transfer)      // 4-byte function selector
__EVENT_HASH(Transfer)    // 32-byte keccak256 event topic
__ERROR(InsufficientBalance) // 4-byte error selector
__RIGHTPAD(0x48656c6c6f)  // Right-pad literal to 32 bytes
__codesize(MACRO_NAME)    // Byte size of macro's compiled output
__tablestart(TABLE_NAME)  // Jump table start offset
__tablesize(TABLE_NAME)   // Jump table byte size
```

### Template Arguments and Jump Labels

```huff
#define macro LOAD_SLOT(slot) = takes(0) returns(1) {
    [slot] sload
}

#define macro CONDITIONAL() = takes(1) returns(0) {
    is_true jumpi          // Labels are local to each macro expansion
    0x00 0x00 revert
    is_true:               // JUMPDEST — auto-disambiguated across expansions
}
```

### Include

```huff
#include "./utils/SafeMath.huff"
#include "huffmate/tokens/ERC20.huff"
```

---

## 4. MAIN() Macro — Entry Point and Dispatch

Every Huff contract needs a `MAIN()` macro. You build function dispatch manually:

```huff
#define macro MAIN() = takes(0) returns(0) {
    // Extract selector: first 4 bytes of calldata
    0x00 calldataload 0xE0 shr         // [selector]

    // Linear dispatch — order by call frequency for gas savings
    dup1 __FUNC_SIG(transfer)       eq transfer_jump     jumpi
    dup1 __FUNC_SIG(balanceOf)      eq balanceOf_jump    jumpi
    dup1 __FUNC_SIG(approve)        eq approve_jump      jumpi
    dup1 __FUNC_SIG(transferFrom)   eq transferFrom_jump jumpi
    dup1 __FUNC_SIG(totalSupply)    eq totalSupply_jump  jumpi
    dup1 __FUNC_SIG(allowance)      eq allowance_jump    jumpi

    // No match — revert
    0x00 0x00 revert

    transfer_jump:      TRANSFER()
    balanceOf_jump:     BALANCE_OF()
    approve_jump:       APPROVE()
    transferFrom_jump:  TRANSFER_FROM()
    totalSupply_jump:   TOTAL_SUPPLY()
    allowance_jump:     ALLOWANCE()
}
```

For many functions, binary search dispatch halves worst-case comparisons:

```huff
dup1 0x70a08231 lt low_selectors jumpi
// high selectors here...
low_selectors:
// low selectors here...
```

Handle receive/fallback by checking `calldatasize` at the top of MAIN():

```huff
calldatasize iszero receive_jump jumpi
// ... dispatch ...
receive_jump: stop   // Accept ETH
```

---

## 5. Manual ABI Encoding/Decoding

### Reading Arguments

```huff
// transfer(address to, uint256 amount)
// Calldata: [0x00-0x04) selector, [0x04-0x24) to, [0x24-0x44) amount
#define macro TRANSFER() = takes(0) returns(0) {
    0x04 calldataload                    // [to_raw]
    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
    and                                   // [to_clean] — mask address to 20 bytes
    0x24 calldataload                    // [amount, to_clean]
    // ... transfer logic ...
}
```

### Encoding Return Values

```huff
#define macro RETURN_UINT() = takes(1) returns(0) {
    0x00 mstore  0x20 0x00 return    // Return 32-byte word
}
#define macro RETURN_TRUE() = takes(0) returns(0) {
    0x01 0x00 mstore  0x20 0x00 return
}
```

### Dynamic Types (bytes, string)

Dynamic types use an offset indirection layer:

```huff
// Return string "Hello": offset(0x20) + length(5) + padded data
#define macro RETURN_HELLO() = takes(0) returns(0) {
    0x20 0x00 mstore                     // offset
    0x05 0x20 mstore                     // length
    __RIGHTPAD(0x48656c6c6f) 0x40 mstore // "Hello" padded
    0x60 0x00 return
}
```

### Error Encoding

```huff
#define error InsufficientBalance(uint256 available, uint256 required)

#define macro REVERT_INSUFFICIENT() = takes(2) returns(0) {
    // Stack: [available, required]
    __ERROR(InsufficientBalance) 0xE0 shl 0x00 mstore
    0x24 mstore  0x04 mstore             // encode args after selector
    0x44 0x00 revert
}
```

---

## 6. Huffmate Library

[Huffmate](https://github.com/huff-language/huffmate) provides prebuilt Huff modules analogous to OpenZeppelin.

| Module                   | Description                    |
|--------------------------|--------------------------------|
| `auth/Owned`             | Single-owner access control    |
| `tokens/ERC20`           | Full ERC-20 implementation     |
| `tokens/ERC721`          | Full ERC-721 implementation    |
| `tokens/ERC1155`         | Multi-token standard           |
| `utils/SafeTransferLib`  | Safe ERC-20 transfer wrappers  |
| `utils/ReentrancyGuard`  | Reentrancy mutex               |
| `utils/Multicallable`    | Batch call support             |

### Usage

```bash
forge install huff-language/huffmate
```

```huff
#include "huffmate/tokens/ERC20.huff"
#include "huffmate/auth/Owned.huff"

// Wire Huffmate macros into dispatch:
// balanceOf_dest: BALANCE_OF()
// transfer_dest:  TRANSFER()
```

### Reentrancy Guard Pattern

```huff
#define constant REENTRANCY_SLOT = FREE_STORAGE_POINTER()

#define macro NON_REENTRANT_START() = takes(0) returns(0) {
    [REENTRANCY_SLOT] sload 0x02 eq iszero not_locked jumpi
    0x00 0x00 revert
    not_locked:
    0x02 [REENTRANCY_SLOT] sstore
}
#define macro NON_REENTRANT_END() = takes(0) returns(0) {
    0x01 [REENTRANCY_SLOT] sstore
}
```

---

## 7. Gas Golf Techniques

### Huff vs Solidity Cost Comparison

Simple `add(uint256,uint256)` — Solidity: ~150-200 gas (ABI decode + overflow check + encode), ~70+ bytes. Huff: ~50 gas (calldataload + calldataload + add + mstore + return), ~30 bytes.

### Key Techniques

**RETURNDATASIZE as free zero:** 2 gas vs PUSH1's 3 gas. `returndatasize returndatasize revert` saves 2 gas over `0x00 0x00 revert`.

**Memory over storage:** MSTORE/MLOAD = 3 gas each. SSTORE = 2900-20000 gas. Keep transaction-scoped intermediates in memory.

**Bitpacking:** Pack multiple values into one 256-bit storage slot:

```huff
// Pack owner(160 bits) + balance(96 bits) into one slot
#define macro PACK() = takes(2) returns(1) {
    swap1 0x60 shl or    // [owner << 96 | balance]
}
#define macro UNPACK_OWNER() = takes(1) returns(1) { 0x60 shr }
#define macro UNPACK_BALANCE() = takes(1) returns(1) {
    0xFFFFFFFFFFFFFFFFFFFFFFFF and
}
```

**Custom errors vs require strings:** Custom error = ~20 gas, 4 bytes return data. Solidity require string = 200+ gas, 68+ bytes.

**Efficient hashing for mapping slots:**

```huff
#define macro BALANCE_SLOT_OF() = takes(1) returns(1) {
    0x00 mstore  [BALANCE_SLOT] 0x20 mstore  0x40 0x00 sha3
}
```

---

## 8. Real Huff Contract Examples

### Complete ERC-20

```huff
#define function totalSupply() view returns (uint256)
#define function balanceOf(address) view returns (uint256)
#define function transfer(address, uint256) nonpayable returns (bool)
#define function approve(address, uint256) nonpayable returns (bool)
#define function allowance(address, address) view returns (uint256)
#define function transferFrom(address, address, uint256) nonpayable returns (bool)

#define event Transfer(address indexed, address indexed, uint256)
#define event Approval(address indexed, address indexed, uint256)

#define constant TOTAL_SUPPLY_SLOT = 0x00
#define constant BALANCE_SLOT = 0x01
#define constant ALLOWANCE_SLOT = 0x02
#define constant ADDR_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff

#define macro BAL_SLOT() = takes(1) returns(1) {
    0x00 mstore [BALANCE_SLOT] 0x20 mstore 0x40 0x00 sha3
}

#define macro ALLOW_SLOT() = takes(2) returns(1) {
    // Stack: [owner, spender]
    swap1 0x00 mstore [ALLOWANCE_SLOT] 0x20 mstore 0x40 0x00 sha3
    0x20 mstore 0x00 mstore 0x40 0x00 sha3
}

#define macro TOTAL_SUPPLY() = takes(0) returns(0) {
    [TOTAL_SUPPLY_SLOT] sload 0x00 mstore 0x20 0x00 return
}

#define macro BALANCE_OF() = takes(0) returns(0) {
    0x04 calldataload [ADDR_MASK] and BAL_SLOT() sload
    0x00 mstore 0x20 0x00 return
}

#define macro TRANSFER() = takes(0) returns(0) {
    0x04 calldataload [ADDR_MASK] and    // [to]
    0x24 calldataload                     // [amount, to]

    // Deduct from sender
    caller BAL_SLOT() dup1 sload          // [senderBal, senderSlot, amount, to]
    dup3 dup2 lt iszero ok1 jumpi
    0x00 0x00 revert
    ok1:
    dup3 swap1 sub swap1 sstore           // [amount, to]

    // Credit recipient
    dup2 BAL_SLOT() dup1 sload            // [toBal, toSlot, amount, to]
    dup3 add swap1 sstore                 // [amount, to]

    // Emit Transfer(caller, to, amount)
    0x00 mstore caller __EVENT_HASH(Transfer) 0x20 0x00 log3
    pop  // clean stack

    0x01 0x00 mstore 0x20 0x00 return
}

#define macro APPROVE() = takes(0) returns(0) {
    0x04 calldataload [ADDR_MASK] and    // [spender]
    0x24 calldataload                     // [amount, spender]
    swap1 caller ALLOW_SLOT()             // [slot, amount]
    sstore

    // Emit Approval
    0x24 calldataload 0x00 mstore
    0x04 calldataload caller __EVENT_HASH(Approval) 0x20 0x00 log3

    0x01 0x00 mstore 0x20 0x00 return
}

#define macro TRANSFER_FROM() = takes(0) returns(0) {
    0x04 calldataload [ADDR_MASK] and    // [from]
    0x24 calldataload [ADDR_MASK] and    // [to, from]
    0x44 calldataload                     // [amount, to, from]

    // Check and deduct allowance (skip if max uint256)
    dup3 caller ALLOW_SLOT()              // [allowSlot, amount, to, from]
    dup1 sload dup1                       // [allow, allow, allowSlot, amount, to, from]
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF eq
    skip_allow jumpi
    dup3 dup2 lt iszero allow_ok jumpi
    0x00 0x00 revert
    allow_ok:
    dup3 swap1 sub dup2 sstore pop        // [amount, to, from]
    cont jump
    skip_allow: pop pop                   // [amount, to, from]

    cont:
    // Deduct from sender, credit recipient (same pattern as TRANSFER)
    dup3 BAL_SLOT() dup1 sload dup3 dup2 lt iszero ok2 jumpi
    0x00 0x00 revert
    ok2:
    dup3 swap1 sub swap1 sstore
    dup2 BAL_SLOT() dup1 sload dup3 add swap1 sstore

    // Emit Transfer(from, to, amount)
    0x00 mstore swap1 __EVENT_HASH(Transfer) 0x20 0x00 log3

    0x01 0x00 mstore 0x20 0x00 return
}

#define macro ALLOWANCE() = takes(0) returns(0) {
    0x04 calldataload [ADDR_MASK] and
    0x24 calldataload [ADDR_MASK] and
    swap1 ALLOW_SLOT() sload
    0x00 mstore 0x20 0x00 return
}

#define macro MAIN() = takes(0) returns(0) {
    0x00 calldataload 0xE0 shr
    dup1 __FUNC_SIG(transfer)       eq t1 jumpi
    dup1 __FUNC_SIG(transferFrom)   eq t2 jumpi
    dup1 __FUNC_SIG(approve)        eq t3 jumpi
    dup1 __FUNC_SIG(balanceOf)      eq t4 jumpi
    dup1 __FUNC_SIG(allowance)      eq t5 jumpi
    dup1 __FUNC_SIG(totalSupply)    eq t6 jumpi
    0x00 0x00 revert
    t1: TRANSFER()
    t2: TRANSFER_FROM()
    t3: APPROVE()
    t4: BALANCE_OF()
    t5: ALLOWANCE()
    t6: TOTAL_SUPPLY()
}
```

### Simple ETH Vault

```huff
#define function deposit() payable returns ()
#define function withdraw(uint256) nonpayable returns ()
#define function balanceOf(address) view returns (uint256)
#define event Deposit(address indexed, uint256)
#define event Withdrawal(address indexed, uint256)
#define constant BAL_SLOT = 0x00

#define macro BAL_KEY() = takes(1) returns(1) {
    0x00 mstore [BAL_SLOT] 0x20 mstore 0x40 0x00 sha3
}

#define macro DEPOSIT() = takes(0) returns(0) {
    callvalue iszero no_val jumpi
    caller BAL_KEY() dup1 sload callvalue add swap1 sstore
    callvalue 0x00 mstore caller __EVENT_HASH(Deposit) 0x20 0x00 log2
    stop
    no_val: 0x00 0x00 revert
}

#define macro WITHDRAW() = takes(0) returns(0) {
    0x04 calldataload                     // [amount]
    caller BAL_KEY() dup1 sload           // [bal, slot, amount]
    dup3 dup2 lt iszero wd_ok jumpi
    0x00 0x00 revert
    wd_ok:
    dup3 swap1 sub swap1 sstore           // [amount]
    0x00 0x00 0x00 0x00 swap4 caller gas call
    iszero send_fail jumpi
    0x04 calldataload 0x00 mstore
    caller __EVENT_HASH(Withdrawal) 0x20 0x00 log2
    stop
    send_fail: 0x00 0x00 revert
}

#define macro MAIN() = takes(0) returns(0) {
    calldatasize iszero recv jumpi
    0x00 calldataload 0xE0 shr
    dup1 __FUNC_SIG(deposit)   eq d1 jumpi
    dup1 __FUNC_SIG(withdraw)  eq d2 jumpi
    dup1 __FUNC_SIG(balanceOf) eq d3 jumpi
    0x00 0x00 revert
    recv: DEPOSIT()
    d1:   DEPOSIT()
    d2:   WITHDRAW()
    d3:   0x04 calldataload BAL_KEY() sload 0x00 mstore 0x20 0x00 return
}
```

### Minimal WETH Wrapper

A WETH contract wraps the vault pattern with ERC-20 minting/burning. On `deposit()` (or plain ETH receive), mint WETH 1:1 by incrementing `totalSupply` and `balances[caller]`, then emit both `Deposit` and `Transfer(address(0), caller, amount)`. On `withdraw(amount)`, verify balance, deduct, decrement totalSupply, send ETH via `CALL`, and emit `Withdrawal` and `Transfer(caller, address(0), amount)`. The dispatch MAIN() routes `deposit`, `withdraw`, `totalSupply`, and `balanceOf` using the same selector pattern shown above, with the fallback case routing to `WETH_DEPOSIT()` for plain ETH transfers.

---

## 9. Testing Huff

### Compilation with huffc

```bash
cargo install huffc
huffc src/Token.huff --bytecode    # Runtime bytecode
huffc src/Token.huff --abi         # ABI JSON
huffc src/Token.huff -b            # Deployment (constructor + runtime)
huffc src/Token.huff -d            # Disassemble with offsets
```

### Foundry Integration with foundry-huff

```bash
forge install huff-language/foundry-huff
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract HuffERC20Test is Test {
    IERC20 public token;

    function setUp() public {
        token = IERC20(HuffDeployer.deploy("Token"));
    }

    function testTransfer() public {
        address to = address(0xBEEF);
        assertTrue(token.transfer(to, 1000e18));
        assertEq(token.balanceOf(to), 1000e18);
    }

    function testTransferInsufficientBalance() public {
        vm.expectRevert();
        token.transfer(address(0xBEEF), type(uint256).max);
    }

    function testApproveAndTransferFrom() public {
        address spender = address(0xCAFE);
        token.approve(spender, 500e18);
        vm.prank(spender);
        token.transferFrom(address(this), address(0xDEAD), 500e18);
        assertEq(token.balanceOf(address(0xDEAD)), 500e18);
    }
}
```

### FFI-Based Compilation

```solidity
function deployHuff(string memory file) internal returns (address) {
    string[] memory cmds = new string[](3);
    cmds[0] = "huffc";
    cmds[1] = string.concat("src/", file, ".huff");
    cmds[2] = "-b";
    bytes memory bc = vm.ffi(cmds);
    address a;
    assembly { a := create(0, add(bc, 0x20), mload(bc)) }
    require(a != address(0));
    return a;
}
```

Enable in `foundry.toml`: `ffi = true`.

### Debugging Strategies

1. **`forge test -vvvv`** — Full EVM trace; cross-reference opcodes with your Huff source.
2. **Debug events** — Insert temporary `LOG0` to emit stack values:
   ```huff
   dup1 0x00 mstore 0x20 0x00 log0   // Emits top-of-stack value
   ```
3. **`cast run <txHash> --debug`** — Step through on-chain transactions.
4. **`huffc -d`** — Disassemble to map JUMP offsets back to source labels.
5. **evm.codes / Remix debugger** — Step through raw bytecode instruction by instruction.

---

## 10. Security Checklist

### Stack Underflow/Overflow

The EVM does not revert on stack underflow — it produces undefined behavior. Trace every code path through every macro and verify stack depth at each instruction. After a `jumpi`, both taken and not-taken paths must leave consistent stack state.

### Missing Arithmetic Checks

Huff has no overflow protection. Every `add`, `sub`, `mul` involving user input needs manual checks:

```huff
#define macro SAFE_ADD() = takes(2) returns(1) {
    dup2 dup2 add           // [sum, a, b]
    dup1 swap2 gt           // [a > sum, sum, b]
    overflow jumpi
    swap1 pop done jump     // [sum]
    overflow: 0x00 0x00 revert
    done:
}
```

### Incorrect Jump Destinations

Labels are scoped per macro expansion — you cannot jump between macros. Test every branch to catch wrong-destination bugs.

### Calldata Validation

Solidity validates calldata length automatically; Huff does not. Short calldata zero-pads silently. Validate with `calldatasize 0x44 lt bad jumpi` and always mask addresses to 20 bytes.

### Reentrancy

Any `CALL`/`STATICCALL`/`DELEGATECALL` can re-enter. Apply checks-effects-interactions or use a reentrancy guard. Never rely on gas limits for security.

### Storage Slot Collisions

Document every slot. Verify mapping base slots are unique. When using `FREE_STORAGE_POINTER()`, order matters — verify no overlap with Huffmate's expected layout.

### Missing Termination

Every function path must end with `return`, `revert`, or `stop`. Without termination, execution falls through to the next function's jump destination:

```huff
// BUG: BALANCE_OF() doesn't return — falls through to TRANSFER()
balanceOf_dest: BALANCE_OF()
transfer_dest:  TRANSFER()
```

### Callvalue Checks

Non-payable functions must explicitly reject ETH:

```huff
callvalue iszero ok jumpi  0x00 0x00 revert  ok:
```

### The Huff Audit Workflow

1. Map and document every storage slot; verify no collisions.
2. Trace stack depth through every code path in every macro.
3. Verify overflow/underflow checks on all arithmetic with user input.
4. Validate calldata length and mask all address arguments.
5. Confirm every function path terminates with `return`/`revert`/`stop`.
6. Verify `caller` checks on all privileged operations.
7. Audit all external calls for reentrancy vectors.
8. Fuzz test with Foundry (minimum 10,000 runs per test).
9. Compare gas profiles (`forge test --gas-report`) to confirm Huff savings justify the risk.
10. Engage at least two auditors with Huff-specific experience.
