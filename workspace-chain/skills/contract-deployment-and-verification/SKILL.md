# Contract Deployment & Verification

## Pre-Deployment Checklist
- [ ] All tests passing: `forge test`
- [ ] Coverage adequate: `forge coverage`
- [ ] Slither passing: `slither . --filter-paths "test|script|lib"`
- [ ] Gas snapshot taken: `forge snapshot`
- [ ] Constructor arguments documented
- [ ] Environment variables set (private key, RPC URL, API keys)
- [ ] Testnet deployment verified and tested
- [ ] Multisig ready (never deploy mainnet from an EOA for production)

## Foundry Deployment Scripts

### Basic Script
```solidity
// script/Deploy.s.sol
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {MarketFactory} from "../src/MarketFactory.sol";

contract DeployMarketFactory is Script {
    function run() external returns (MarketFactory factory) {
        // Load config from env
        address usdc = vm.envAddress("USDC_ADDRESS");
        address oracle = vm.envAddress("ORACLE_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        console2.log("Deploying from:", deployer);
        console2.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerKey);

        factory = new MarketFactory(usdc, oracle, treasury);
        console2.log("MarketFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
```

### Deployment Commands
```bash
# Dry run (no broadcast)
forge script script/Deploy.s.sol:DeployMarketFactory \
    --rpc-url $BASE_RPC_URL \
    --private-key $PRIVATE_KEY

# Actual deployment + verification
forge script script/Deploy.s.sol:DeployMarketFactory \
    --rpc-url $BASE_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY \
    -vvvv

# Multi-chain deployment
for CHAIN in base arbitrum optimism; do
    forge script script/Deploy.s.sol \
        --rpc-url $(eval echo \$${CHAIN^^}_RPC) \
        --broadcast --verify ...
done
```

## Proxy Deployment (UUPS)
```solidity
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployProxy is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // Deploy implementation
        MarketV1 impl = new MarketV1();

        // Deploy proxy pointing to implementation
        bytes memory initData = abi.encodeCall(MarketV1.initialize, (owner, usdc));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        console2.log("Implementation:", address(impl));
        console2.log("Proxy:", address(proxy));

        // Verify both on Etherscan
        vm.stopBroadcast();
    }
}
```

## Deterministic Deployment (CREATE2)
Same address across all chains:
```bash
# Using Foundry's deterministic deployer
forge script script/DeployDeterministic.s.sol \
    --rpc-url $BASE_RPC \
    --broadcast \
    --sender 0x4e59b44847b379578588920cA78FbF26c0B4956C  # Canonical CREATE2 factory
```

```solidity
bytes32 salt = keccak256(abi.encode("MarketFactory", "v1.0.0"));
address factory = address(new MarketFactory{salt: salt}(params));
// Address depends on: deployer, salt, init bytecode
```

## Verification

### Via Foundry (Recommended)
```bash
forge verify-contract \
    0xYourContractAddress \
    src/MarketFactory.sol:MarketFactory \
    --chain-id 8453 \  # Base
    --etherscan-api-key $BASESCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address,address,address)" $USDC $ORACLE $TREASURY)
```

### Proxy Verification
Verify implementation + proxy separately. Block explorers auto-detect proxies if using EIP-1967 slots.

### Multiple Chains
Each chain has its own block explorer and API key:
- Ethereum: Etherscan — `ETHERSCAN_API_KEY`
- Base: Basescan — `BASESCAN_API_KEY`
- Arbitrum: Arbiscan — `ARBISCAN_API_KEY`
- Polygon: Polygonscan — `POLYGONSCAN_API_KEY`

### Sourcify (Alternative)
Open source, no API key needed: `forge verify-contract ... --verifier sourcify`

## Deployments Manifest
Track every deployment:
```json
{
  "base": {
    "chainId": 8453,
    "MarketFactory": {
      "address": "0x...",
      "txHash": "0x...",
      "blockNumber": 12345678,
      "deployedAt": "2024-01-15T10:30:00Z",
      "constructorArgs": { "usdc": "0x..." }
    }
  }
}
```

## Production Deployment Security

### Never Deploy from a Personal EOA
Use a Safe multisig:
1. Deploy from Safe (2/3 or 3/5 threshold)
2. Safe is the initial owner of all contracts
3. Upgrade keys held by multiple team members
4. Hardware wallets for all signers

### Timelock on Admin Actions
```solidity
// OpenZeppelin TimelockController
// 48-hour delay on all governance actions
TimelockController timelock = new TimelockController(
    172800,      // 48 hours in seconds
    proposers,   // Who can propose
    executors,   // Who can execute after delay
    admin        // Admin (set to address(0) to remove admin after setup)
);
```

### Post-Deployment Steps
1. Verify source code on block explorer
2. Run smoke tests against deployed contract
3. Transfer ownership to multisig
4. Set up monitoring (Forta, Defender Sentinels)
5. Register with bug bounty (Immunefi)
6. Update deployments manifest
7. Notify frontend team of contract addresses
