# Reverse Engineering Contracts

## Full Workflow: Bytecode → Understanding

```bash
# Step 1: Get bytecode
cast code 0xUnverifiedContract --rpc-url $BASE_RPC

# Step 2: Get function selectors from bytecode
# Extract 4-byte selectors from the dispatcher
cast 4byte-decode $(cast code 0xUnverifiedContract | head -c 10)

# Step 3: Match selectors to known signatures
# Query 4byte.directory database
cast 4byte 0xa9059cbb  # → transfer(address,uint256)
cast 4byte 0x70a08231  # → balanceOf(address)

# If not in database, the function is custom/obscured
# Step 4: Decompile with external tool
# Use: https://app.dedaub.com/decompile  (best for EVM)
#      https://ethervm.io/decompile
#      heimdall-rs (local CLI)
```

## Reading Raw Storage

```bash
# Read every storage slot (slots 0-20 for most contracts)
for slot in $(seq 0 20); do
    value=$(cast storage 0xContract $slot --rpc-url $BASE_RPC)
    if [ "$value" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        echo "Slot $slot: $value"
    fi
done

# Compute mapping slot: keccak256(abi.encode(key, baseSlot))
# Example: balanceOf[0xAlice] where balances is at slot 1
python3 -c "
from eth_abi import encode
from eth_utils import keccak
slot = keccak(encode(['address','uint256'], ['0xAlice', 1]))
print('0x' + slot.hex())
"

# Read the mapping value
cast storage 0xContract 0xComputedSlot --rpc-url $BASE_RPC
```

## Decompiled Output Interpretation

```
// Raw decompiler output (Dedaub style):
function 0xa9059cbb(address varg0, uint256 varg1) public {
    require(msg.data.length - 4 >= 64);
    // ← ABI decoding two 32-byte args = transfer(address,uint256) ✓

    require(stor_0 == msg.sender || stor_3[msg.sender] != 0);
    // ← stor_0 is likely owner. stor_3 is likely allowances/roles mapping.

    require(stor_2[msg.sender] >= varg1);
    // ← stor_2 is balances mapping. Checks sender has enough.

    stor_2[msg.sender] -= varg1;
    stor_2[varg0] += varg1;
    // ← Transfer: deduct from sender, add to recipient.

    emit 0xddf252...(msg.sender, varg0, varg1);
    // ← Topic 0 = Transfer(address,address,uint256) keccak. This IS ERC-20 Transfer event.
}

// CONCLUSION: This is a standard ERC-20 transfer with an access control gate.
// stor_0 = owner address (slot 0)
// stor_2 = balances mapping (slot 2)
// stor_3 = operators/allowances (slot 3)
```

## Reproducing Exploits from Bytecode

```solidity
// When an exploit happens and the attacker contract is unverified:
// 1. Get the attack transaction
// 2. Use cast run to trace it
// 3. Reverse engineer the attacker contract
// 4. Reproduce in Foundry

// cast run <TX_HASH> --rpc-url $MAINNET_RPC --verbose --label 0xAttacker=Attacker

// From the trace, you can see:
// - Every call the attacker made
// - Every storage read/write
// - Every event emitted
// - The exact sequence of operations

// Then reproduce in Foundry:
contract ExploitReproduction is Test {
    function test_reproduced_exploit() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC"), EXPLOIT_BLOCK - 1);

        // Set up attacker
        address attacker = makeAddr("attacker");
        vm.deal(attacker, 1 ether);

        vm.startPrank(attacker);

        // Replicate the exact call sequence from the trace
        IVulnerableProtocol(VICTIM).deposit{value: 1 ether}();
        IVulnerableProtocol(VICTIM).withdraw(1 ether);  // Re-enter here
        // etc.

        vm.stopPrank();

        // Verify exploit succeeded
        assertGt(IERC20(TOKEN).balanceOf(attacker), 1_000_000e18);
    }
}
```

## Verifying Deployed Bytecode Matches Source

```bash
# Build locally with same compiler settings
forge build --optimize --optimizer-runs 200

# Get local bytecode (runtime code, not init code)
cat out/Contract.sol/Contract.json | jq '.deployedBytecode.object'

# Get on-chain bytecode
cast code 0xDeployedAddress --rpc-url $BASE_RPC

# Compare (should match exactly, minus any immutables/constructor args embedded)
# Differences = contract was tampered with OR different compiler settings used

# Etherscan does this automatically on contract verification
# But for manual verification: diff the two bytecodes
```

## Storage Collision Analysis

```bash
# For proxies: verify implementation doesn't clash with proxy admin slot (EIP-1967)
EIP_1967_IMPL_SLOT="0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
EIP_1967_ADMIN_SLOT="0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"

cast storage 0xProxy $EIP_1967_IMPL_SLOT --rpc-url $BASE_RPC
# Returns implementation address

cast storage 0xProxy $EIP_1967_ADMIN_SLOT --rpc-url $BASE_RPC
# Returns admin address

# Then: read implementation's source, verify slot 0 of implementation
# doesn't conflict with slot 0 of proxy's own storage
```
