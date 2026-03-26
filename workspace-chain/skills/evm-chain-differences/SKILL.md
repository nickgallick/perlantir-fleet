# EVM Chain Differences

## The Bug-Causing Quirks

```solidity
// ❌ BREAKS ON ARBITRUM: block.number returns L2 block, NOT Ethereum L1 block
// but Arbitrum has a different function for L1 block number
function getL1Block() external view returns (uint256) {
    // On Arbitrum: ArbSys precompile (0x0000000000000000000000000000000000000064)
    (bool ok, bytes memory data) = address(0x64).staticcall(
        abi.encodeWithSignature("arbBlockNumber()")
    );
    return abi.decode(data, (uint256));
}

// ❌ BREAKS ON OPTIMISM/BASE: block.timestamp is L2 sequencer time, not L1
// L2 block time ≈ 2 seconds (vs L1's 12 seconds)
// Time-dependent logic works but block-number-dependent logic may differ

// ❌ BREAKS ON ZKSYNC: some opcodes missing or behave differently
// PUSH0 (0x5F): added in Shanghai, not supported on zkSync until recent upgrade
// pragma solidity >=0.8.20 uses PUSH0 → compilation fails on older zkSync
// Fix: pragma solidity 0.8.19 or configure evmVersion: "paris" in foundry.toml

// ❌ BREAKS ON POLYGON: reorgs are common (2-3 blocks)
// Never consider a transaction final after 1 confirmation on Polygon
// Use at least 30+ confirmations for irreversibility

// ❌ BREAKS ON BLAST: ETH is rebasing (yields ~4% APY natively)
// address(this).balance changes WITHOUT any transfers happening
// Any logic that compares balance[t1] vs balance[t2] expecting no change = bug
```

## Foundry Config Per Chain

```toml
# foundry.toml
[profile.default]
evm_version = "paris"   # Safe for all chains including zkSync

[profile.ethereum]
evm_version = "cancun"  # Latest, L1 only

[profile.base]
evm_version = "ecotone"  # OP Stack + EIP-4844

[profile.zksync]
# Use foundry-zksync fork
zksync = true
```

## Chain-Specific Fork Tests

```solidity
// Test your contract on EVERY target chain
contract MultiChainTest is Test {
    function test_arbitrum() public {
        vm.createSelectFork(vm.envString("ARB_RPC"));
        // Deploy and test — real Arbitrum behavior
        assertEq(block.chainid, 42161);
        // Verify block.number behavior is correct for your use case
    }

    function test_base() public {
        vm.createSelectFork(vm.envString("BASE_RPC"));
        assertEq(block.chainid, 8453);
    }

    function test_zksync() public {
        // Use foundry-zksync
        vm.createSelectFork(vm.envString("ZKSYNC_RPC"));
        // zkSync-specific: factory deployments behave differently
    }
}
```

## Gas Cost Differences

```
Chain             | Calldata cost | Storage cost | Execution cost
Ethereum (L1)     | 16 gas/byte   | 20,000/slot  | Normal
Arbitrum          | 16 gas/byte   | 20,000/slot  | ~10-50x cheaper
Base/Optimism     | Calldata goes to L1 blobs (EIP-4844) | Very cheap
zkSync            | Pubdata cost separate from execution gas
Polygon PoS       | ~10x cheaper than L1 on average

For L2s: gas cost = execution gas + data availability cost
EIP-4844 blobs: cheap DA → Base/Optimism/Arbitrum all much cheaper after EIP-4844 upgrade
```

## Sequencer Failure — Design For It

```solidity
// OP Stack: if sequencer is down, users can force-include transactions via L1
// But there's a delay (7 days for finality on optimistic rollups)

contract SequencerAwareProtocol {
    // Check if sequencer is live (Chainlink Sequencer Uptime Feed on Arbitrum)
    AggregatorV2V3Interface internal sequencerUptimeFeed;

    modifier sequencerOnline() {
        (, int256 answer, uint256 startedAt,,) = sequencerUptimeFeed.latestRoundData();
        bool isSequencerUp = answer == 0;
        require(isSequencerUp, "Sequencer offline");
        require(block.timestamp - startedAt > 1 hours, "Grace period not passed");
        _;
    }

    // For liquidations: don't allow liquidations during sequencer downtime
    // (users couldn't top up collateral if sequencer was down)
    function liquidate(address user) external sequencerOnline {
        // ...
    }
}
```

## Full Chain Compatibility Checklist

Before deploying to any new chain:
- [ ] `block.number` semantics match your assumptions
- [ ] `block.timestamp` granularity acceptable
- [ ] All Solidity opcodes supported (check EVM version compatibility)
- [ ] CREATE2 behavior matches (differs on zkSync)
- [ ] `address(this).balance` static assumption (Blast!)
- [ ] Reorg depth acceptable for your confirmation requirements
- [ ] Chainlink oracle available on this chain
- [ ] Uniswap V3 deployed and liquid on this chain
- [ ] Gas estimation tested (some L2s have different pricing models)
