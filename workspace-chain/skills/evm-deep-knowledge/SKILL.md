# EVM Deep Knowledge

## Architecture
- Stack-based VM: 256-bit word size, 1024 stack depth max
- Memory model: storage (persistent/expensive), memory (temporary/cheap), stack (cheapest), calldata (read-only input)
- Account types: EOA (externally owned, has private key) vs Contract (has code + storage)

## Transaction Lifecycle
1. Creation: construct tx object (to, value, data, gasLimit, maxFeePerGas, maxPriorityFeePerGas)
2. Signing: ECDSA signature with private key → v, r, s
3. Broadcasting: submit to mempool via RPC node
4. Mempool: pending transactions ordered by gas price (priority fee)
5. Inclusion: validator selects tx for block, executes EVM bytecode
6. Execution: opcodes run sequentially, gas consumed per operation
7. Receipt: status (0=fail, 1=success), gasUsed, logs (events)

## Gas Mechanics (EIP-1559)
- **Base fee**: protocol-set, burned. Adjusts per block based on utilization.
- **Priority fee (tip)**: goes to validator. Incentivizes inclusion.
- **Max fee**: ceiling the sender will pay. `actualFee = min(maxFee, baseFee + priorityFee)`
- **Gas limit**: max gas units for the tx. Unused gas refunded.
- **Block gas limit**: ~30M gas on Ethereum mainnet

## Key Opcode Costs
| Opcode | Gas | Notes |
|--------|-----|-------|
| ADD/SUB/MUL | 3 | Arithmetic |
| DIV/MOD | 5 | Division |
| SLOAD (cold) | 2,100 | First read of a storage slot in tx |
| SLOAD (warm) | 100 | Subsequent reads of same slot |
| SSTORE (cold, 0→nonzero) | 20,000 | Most expensive common operation |
| SSTORE (cold, nonzero→nonzero) | 2,900 | Modifying existing value |
| SSTORE (warm) | 100 | Already accessed this tx |
| SSTORE refund (nonzero→0) | 4,800 | Refund for clearing storage |
| CALL (cold) | 2,600 | First call to an address |
| CALL (warm) | 100 | Subsequent calls |
| CREATE | 32,000 | Deploy new contract |
| CREATE2 | 32,000 | Deterministic deploy |
| LOG0 | 375 | Base event cost |
| LOG topic | +375 each | Per indexed parameter |
| LOG data | +8/byte | Event data |
| MLOAD/MSTORE | 3 | Memory read/write |
| CALLDATALOAD | 3 | Read calldata |
| PUSH0 | 2 | EIP-3855, push zero |

## EVM Execution Context
```
msg.sender    — immediate caller (contract or EOA)
msg.value     — ETH sent with call (in wei)
msg.data      — full calldata (selector + encoded args)
msg.sig       — first 4 bytes of calldata (function selector)
block.timestamp — current block timestamp (seconds since epoch)
block.number  — current block number
block.basefee — current base fee (EIP-1559)
block.chainid — chain ID (1=mainnet, 8453=Base, 42161=Arbitrum)
gasleft()     — remaining gas
tx.origin     — original EOA sender (NEVER use for auth)
```

## Storage Layout
- Each contract has 2^256 storage slots, each 32 bytes
- State variables assigned sequentially starting at slot 0
- Multiple variables packed into one slot if they fit (e.g., two uint128s)
- Mappings: `slot(mapping[key]) = keccak256(key . mappingSlot)`
- Dynamic arrays: length at `slot`, elements at `keccak256(slot) + index`
- Nested mappings: `keccak256(key2 . keccak256(key1 . slot))`

## Memory Layout
- `0x00-0x3f`: Scratch space (used by Solidity for hashing)
- `0x40-0x5f`: Free memory pointer (points to next available memory)
- `0x60-0x7f`: Zero slot (used as initial value for dynamic memory arrays)
- `0x80+`: Usable memory starts here
- Memory expands in 32-byte words; expansion cost is quadratic: `cost = 3*words + words²/512`

## Contract Creation
- **Constructor**: Runs once at deployment, not stored in runtime bytecode
- **Bytecode**: `creationCode + runtimeCode`. Creation code runs constructor and returns runtime code.
- **CREATE**: `address = keccak256(deployer, nonce)` — nonce-dependent, non-deterministic
- **CREATE2**: `address = keccak256(0xff, deployer, salt, keccak256(initCode))` — deterministic, same address on any chain with same deployer + salt + code

## Important EVM Changes
- **Shanghai (2023)**: PUSH0 opcode, beacon chain withdrawals
- **Dencun (2024)**: EIP-4844 blob transactions (cheap L2 data), transient storage (EIP-1153), SELFDESTRUCT deprecated
- **Pectra (2025)**: EIP-7702 (EOA code setting), increased blob throughput

## ABI Encoding
- Function selector: `bytes4(keccak256("functionName(type1,type2)"))` — first 4 bytes of calldata
- Arguments: ABI-encoded after the selector (32-byte aligned, dynamic types have offset + length)
- `abi.encode()` — standard encoding, includes length prefixes
- `abi.encodePacked()` — tight packing, no length prefixes, cheaper but collision-prone for hashing
- `abi.encodeWithSelector()` — prepends selector, use for low-level calls
- `abi.encodeWithSignature("transfer(address,uint256)", to, amt)` — human-readable

## DELEGATECALL
Executes callee's code in the CALLER's context (storage, msg.sender, msg.value unchanged).
```
Contract A delegatecalls Contract B:
  - Code: Contract B's
  - Storage: Contract A's (slot 0 in B maps to slot 0 in A)
  - msg.sender: original caller (not A)
  - msg.value: original value
```
Critical: storage layout between proxy and implementation MUST match exactly. Mismatched layouts = storage corruption.

## SELFDESTRUCT (Post-Dencun)
- EIP-6780 (Dencun 2024): SELFDESTRUCT only works as originally designed if called in the SAME TRANSACTION as contract creation
- Existing contracts: SELFDESTRUCT still sends ETH but does NOT delete code or storage anymore
- Do NOT design systems that rely on SELFDESTRUCT for cleanup — it's effectively deprecated

## Transient Storage (EIP-1153 — Dencun 2024)
- New opcodes: `TSTORE` / `TLOAD` — storage that resets to 0 after every transaction
- Cost: ~100 gas (like warm SLOAD) vs 20,000 gas for cold SSTORE
- Use cases: reentrancy locks (replace storage-based mutex), temporary state within complex tx, cross-contract flags
```solidity
// Reentrancy guard using transient storage (much cheaper)
modifier nonReentrant() {
    assembly { if tload(0) { revert(0, 0) } tstore(0, 1) }
    _;
    assembly { tstore(0, 0) }
}
```

## Common Assembly Patterns
```solidity
// Read storage slot directly
assembly { value := sload(slot) }

// Write storage slot
assembly { sstore(slot, value) }

// Get contract balance
assembly { bal := selfbalance() }

// Revert with custom error (gas efficient)
assembly {
    mstore(0x00, 0xe0e54ced) // error selector
    revert(0x1c, 0x04)
}

// Efficient address masking
assembly { addr := and(addr, 0xffffffffffffffffffffffffffffffffffffffff) }
```
