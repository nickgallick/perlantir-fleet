# Advanced Foundry Tooling

## Multi-Chain Deployment Script

```solidity
// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SpartaChallenge.sol";

contract DeployScript is Script {
    // Deterministic address via CREATE2 — same address on every chain
    bytes32 constant SALT = keccak256("sparta-challenge-v1-2026");

    struct ChainConfig {
        uint256 chainId;
        string  rpcAlias;   // matches [rpc_endpoints] in foundry.toml
        address usdc;
        address aave;
        address kyc;
    }

    ChainConfig[] chains;

    function setUp() public {
        chains.push(ChainConfig(8453,  "base",     0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, address(0), address(0)));
        chains.push(ChainConfig(42161, "arbitrum", 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, address(0), address(0)));
        chains.push(ChainConfig(10,    "optimism", 0x7F5c764cBc14f9669B88837ca1490cCa17c31607, address(0), address(0)));
    }

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        for (uint i = 0; i < chains.length; i++) {
            ChainConfig memory config = chains[i];

            // Switch to each chain
            vm.createSelectFork(config.rpcAlias);

            vm.startBroadcast(deployerKey);

            // Deploy with CREATE2 for same address everywhere
            SpartaChallenge sparta = new SpartaChallenge{salt: SALT}(
                config.usdc,
                config.aave,
                config.kyc
            );

            vm.stopBroadcast();

            console.log("Chain %d: %s", config.chainId, address(sparta));

            // Write deployment manifest
            _writeDeployment(config.chainId, address(sparta));
        }
    }

    function _writeDeployment(uint256 chainId, address contractAddr) internal {
        string memory path = string(abi.encodePacked(
            "deployments/", vm.toString(chainId), ".json"
        ));
        string memory json = string(abi.encodePacked(
            '{"address":"', vm.toString(contractAddr), '",',
            '"chainId":', vm.toString(chainId), ',',
            '"block":', vm.toString(block.number), ',',
            '"timestamp":', vm.toString(block.timestamp), '}'
        ));
        vm.writeFile(path, json);
    }
}
```

## Cast Power Usage

```bash
# Read any contract state
cast call 0xContract "totalSupply()(uint256)" --rpc-url $BASE_RPC

# Read private storage slot (nothing is truly private on-chain)
cast storage 0xContract 0  # Slot 0
# Mapping: keccak256(abi.encode(key, slot))
cast storage 0xContract $(cast keccak256 $(cast abi-encode "f(address,uint256)" 0xAlice 1))

# Decode calldata
cast calldata-decode "transfer(address,uint256)" 0xa9059cbb000000...
# Returns: (address: 0xBob, uint256: 1000000000000000000)

# Decode function selector
cast 4byte 0xa9059cbb
# Returns: transfer(address,uint256)

# Send transaction
cast send 0xToken "approve(address,uint256)" 0xRouter 1000000 \
    --private-key $PRIVATE_KEY --rpc-url $BASE_RPC

# Simulate transaction (no gas, no broadcast)
cast call 0xToken "approve(address,uint256)" 0xRouter 1000000 \
    --from 0xMySender --rpc-url $BASE_RPC

# Get logs with filters
cast logs \
    --address 0xContract \
    --topic0 $(cast keccak256 "Transfer(address,address,uint256)") \
    --from-block 20000000 \
    --rpc-url $MAINNET_RPC

# Replay a transaction locally for debugging
cast run 0xTxHash --rpc-url $MAINNET_RPC --debug

# Estimate gas
cast estimate 0xContract "transfer(address,uint256)" 0xBob 1000000 --rpc-url $BASE_RPC
```

## Custom Invariant Testing

```solidity
contract SpartaInvariantTest is Test {
    SpartaChallenge sparta;
    IERC20 usdc;

    // Called before each invariant check
    function setUp() public {
        usdc  = IERC20(deployMock());
        sparta = new SpartaChallenge(address(usdc), address(0), address(0));
    }

    // Invariant 1: Protocol never owes more than it holds
    function invariant_solvency() public view {
        uint256 totalLocked   = sparta.totalPrizesLocked();
        uint256 contractBalance = usdc.balanceOf(address(sparta));
        assertGe(contractBalance, totalLocked, "INVARIANT: Protocol insolvent");
    }

    // Invariant 2: No challenge can have 0 prize and remain open
    function invariant_noZeroPrizeChallenges() public view {
        bytes32[] memory openChallenges = sparta.getOpenChallenges();
        for (uint i = 0; i < openChallenges.length; i++) {
            assertGt(sparta.prizes(openChallenges[i]), 0, "INVARIANT: Open challenge with zero prize");
        }
    }
}
```

## Writing Custom Slither Detectors

```python
# detectors/sparta_missing_access_control.py
from slither.detectors.abstract_detector import AbstractDetector, DetectorClassification
from slither.core.declarations import Function

class SpartaMissingAccessControl(AbstractDetector):
    """
    Detect functions that modify prize state without onlyRole check.
    Custom detector for Agent Sparta's specific security model.
    """
    ARGUMENT = "sparta-access-control"
    HELP = "Prize-modifying functions missing access control"
    IMPACT = DetectorClassification.HIGH
    CONFIDENCE = DetectorClassification.MEDIUM

    PRIZE_MODIFYING_PATTERNS = ["finalize", "resolve", "setPrize", "distribute"]

    def _detect(self):
        results = []
        for contract in self.contracts:
            for function in contract.functions:
                # Check if function name suggests it modifies prizes
                if any(p in function.name.lower() for p in self.PRIZE_MODIFYING_PATTERNS):
                    # Check if it has access control modifier
                    has_access_control = any(
                        "onlyRole" in m.name or "onlyOwner" in m.name
                        for m in function.modifiers
                    )
                    if not has_access_control and function.visibility == "public":
                        results.append(self.generate_result([
                            f"Function {function.name} modifies prize state without access control",
                            function
                        ]))
        return results
```

## Chisel Quick Patterns

```bash
# Launch Chisel (Solidity REPL)
chisel

# Test storage layout
➜ bytes32 slot = keccak256(abi.encode(address(0xABC), uint256(1)));
➜ slot
Type: bytes32
└ Data: 0x1f4f...

# Verify selector calculations
➜ bytes4 sig = bytes4(keccak256("transfer(address,uint256)"));
➜ sig
Type: bytes4
└ Data: 0xa9059cbb

# Test math (before implementing in contract)
➜ uint256 a = 1000e18;
➜ uint256 b = 3;
➜ uint256 result = a * b / 100;
➜ result
Type: uint256
└ Data: 30000000000000000000 ✓
```
