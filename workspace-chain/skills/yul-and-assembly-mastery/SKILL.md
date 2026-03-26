# Yul & Assembly Mastery

## Complete Contract in Yul

### Object Structure
```yul
object "PredictionMarket" {
    // Constructor code — runs once at deployment
    code {
        // Store deployer as owner in slot 0
        sstore(0, caller())

        // Copy runtime code to memory and return it
        let size := datasize("runtime")
        let offset := dataoffset("runtime")
        datacopy(0, offset, size)
        return(0, size)
    }

    // Runtime code — executes on every call
    object "runtime" {
        code {
            // Revert if ETH sent to non-payable
            // if callvalue() { revert(0, 0) }

            // Function dispatcher
            switch shr(224, calldataload(0))
            case 0x6a627842 /* mint(address) */ {
                _mint(decodeAsAddress(0))
            }
            case 0xa9059cbb /* transfer(address,uint256) */ {
                _transfer(caller(), decodeAsAddress(0), decodeAsUint(1))
            }
            case 0x70a08231 /* balanceOf(address) */ {
                let bal := _balanceOf(decodeAsAddress(0))
                mstore(0x00, bal)
                return(0x00, 0x20)
            }
            default {
                revert(0, 0)
            }

            // --- Internal Functions ---

            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) { revert(0, 0) }
                v := calldataload(pos)
            }

            // Storage layout:
            // slot 0: owner
            // slot keccak256(address, 1): balances mapping (base slot 1)
            // slot 2: totalSupply

            function _balanceSlot(account) -> slot {
                mstore(0x00, account)
                mstore(0x20, 1) // mapping base slot
                slot := keccak256(0x00, 0x40)
            }

            function _balanceOf(account) -> bal {
                bal := sload(_balanceSlot(account))
            }

            function _mint(to) {
                require(eq(caller(), sload(0))) // onlyOwner
                let amount := 1000000000000000000 // 1e18
                let slot := _balanceSlot(to)
                sstore(slot, add(sload(slot), amount))
                sstore(2, add(sload(2), amount)) // totalSupply

                // Emit Transfer(address(0), to, amount)
                mstore(0x00, amount)
                log3(0x00, 0x20,
                    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, // Transfer topic
                    0, // from = address(0)
                    to)
            }

            function _transfer(from, to, amount) {
                let fromSlot := _balanceSlot(from)
                let fromBal := sload(fromSlot)
                require(iszero(lt(fromBal, amount))) // balance >= amount

                sstore(fromSlot, sub(fromBal, amount))
                let toSlot := _balanceSlot(to)
                sstore(toSlot, add(sload(toSlot), amount))

                mstore(0x00, amount)
                log3(0x00, 0x20,
                    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                    from, to)
            }

            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
        }
    }
}
```

## Memory Management Without Solidity
```yul
// Solidity manages free memory pointer at 0x40
// In Yul, YOU manage memory manually

// Scratch space: 0x00-0x3f (use for hashing, temporary values)
// Free memory starts at 0x80 (or wherever you decide)

// Manual memory allocator
function allocate(size) -> ptr {
    ptr := mload(0x40)
    mstore(0x40, add(ptr, size))
}

// Or skip the allocator entirely — just use fixed offsets
// 0x00: scratch
// 0x20: scratch
// 0x40: return data buffer
// 0x60: hash buffer
```

## ABI Encoding/Decoding by Hand
```yul
// Decode: first 4 bytes = selector, then 32-byte chunks
// calldataload(0) → full 32 bytes starting at position 0
// shr(224, calldataload(0)) → first 4 bytes (function selector)
// calldataload(4) → first parameter (32 bytes at offset 4)
// calldataload(36) → second parameter

// Encode return data
function returnUint(v) {
    mstore(0x00, v)
    return(0x00, 0x20)
}

function returnTrue() {
    mstore(0x00, 1)
    return(0x00, 0x20)
}

// Encode custom error
function revertWithError(selector, arg1) {
    mstore(0x00, shl(224, selector))
    mstore(0x04, arg1)
    revert(0x00, 0x24)
}
```

## Mapping Slot Computation
```yul
// Solidity mapping: mapping(address => uint256) balances; at slot N
// slot(balances[key]) = keccak256(abi.encode(key, N))

function mappingSlot(key, baseSlot) -> slot {
    mstore(0x00, key)
    mstore(0x20, baseSlot)
    slot := keccak256(0x00, 0x40)
}

// Nested mapping: mapping(address => mapping(address => uint256)) at slot N
// slot(allowance[owner][spender]) = keccak256(spender . keccak256(owner . N))
function nestedMappingSlot(key1, key2, baseSlot) -> slot {
    mstore(0x00, key1)
    mstore(0x20, baseSlot)
    let innerSlot := keccak256(0x00, 0x40)
    mstore(0x00, key2)
    mstore(0x20, innerSlot)
    slot := keccak256(0x00, 0x40)
}
```

## Event Emission in Yul
```yul
// log0(offset, size) — no topics
// log1(offset, size, topic0) — 1 topic (event signature)
// log2(offset, size, topic0, topic1)
// log3(offset, size, topic0, topic1, topic2)
// log4(offset, size, topic0, topic1, topic2, topic3)

// Transfer(address indexed from, address indexed to, uint256 value)
// topic0 = keccak256("Transfer(address,address,uint256)")
// topic1 = from (indexed)
// topic2 = to (indexed)
// data = value (non-indexed, in memory)

function emitTransfer(from, to, amount) {
    mstore(0x00, amount)
    log3(0x00, 0x20,
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
        from,
        to
    )
}
```

## CREATE2 in Assembly
```yul
// Deterministic address deployment
function deployWithCreate2(bytecode_ptr, bytecode_len, salt) -> addr {
    addr := create2(0, bytecode_ptr, bytecode_len, salt)
    if iszero(addr) { revert(0, 0) }
}

// Predict CREATE2 address
// address = keccak256(0xff ++ deployer ++ salt ++ keccak256(initCode))[12:]
```

## Proxy Pattern in Pure Yul
```yul
object "MinimalProxy" {
    code {
        sstore(0, caller()) // owner
        sstore(
            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
            calldataload(0) // implementation address from constructor arg
        )
        let s := datasize("runtime")
        datacopy(0, dataoffset("runtime"), s)
        return(0, s)
    }
    object "runtime" {
        code {
            let impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
```

## When to Use Yul vs Solidity
| Scenario | Use | Reason |
|----------|-----|--------|
| Factory-deployed contract (1000s of instances) | Yul | Every gas unit × 1000 deploys |
| DEX router (millions of daily calls) | Yul hot paths | Aggregate savings are massive |
| Standard business logic | Solidity | Readability, auditability, maintainability |
| Token contract (ERC-20) | Solmate/Solady | Already Yul-optimized, battle-tested |
| One-off admin contract | Solidity | Gas doesn't matter, correctness does |
| Precompile interaction | Yul | Solidity can't access some precompiles directly |

## Huff (Know It, Read It)
```huff
// Stack-based, compiles to raw bytecode
#define macro MAIN() = takes(0) returns(0) {
    0x00 calldataload       // [calldata[0:32]]
    0xe0 shr                // [selector]

    __FUNC_SIG(balanceOf)   // [balanceOf_sig, selector]
    eq                      // [selector == balanceOf_sig]
    balanceOf jumpi          // jump if match

    0x00 0x00 revert        // no match → revert

    balanceOf:
        BALANCE_OF()
}
```

## Bytecode Reading
Common opcodes:
```
00: STOP          60: PUSH1         80: DUP1
01: ADD           61: PUSH2         90: SWAP1
02: MUL           63: PUSH4         a0: LOG0
04: DIV           35: CALLDATALOAD  f3: RETURN
10: LT            36: CALLDATASIZE  fd: REVERT
14: EQ            37: CALLDATACOPY  ff: SELFDESTRUCT
1c: SHR           39: CODECOPY
20: SHA3          3d: RETURNDATASIZE
51: MLOAD         3e: RETURNDATACOPY
52: MSTORE        54: SLOAD
55: SSTORE        f1: CALL
f4: DELEGATECALL  fa: STATICCALL
```

Tools: `cast disassemble <bytecode>`, Dedaub decompiler, Heimdall-rs, ethervm.io
