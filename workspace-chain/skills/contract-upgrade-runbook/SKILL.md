# Contract Upgrade Runbook

## Pre-Upgrade: Storage Layout Validation

```bash
# Step 1: Get current implementation storage layout
cast call $PROXY_ADDRESS "implementation()(address)" --rpc-url $RPC
# Returns: 0xCurrentImpl

forge inspect CurrentImpl storage-layout --json > old-layout.json

# Step 2: Get new implementation storage layout
forge inspect NewImpl storage-layout --json > new-layout.json

# Step 3: Compare — rules:
# ✅ OK: New variables APPENDED at end
# ✅ OK: Gap slots reduced by number of new variables
# ❌ FATAL: Variable REMOVED
# ❌ FATAL: Variable TYPE changed
# ❌ FATAL: Variable ORDER changed
# ❌ FATAL: Inheritance order changed (reorders all slots)

# Step 4: Use OpenZeppelin's validator
npx @openzeppelin/upgrades-core validate old-layout.json new-layout.json
```

## The Gap Pattern

```solidity
// V1 contract — always include gap
contract SpartaChallengeV1 is Initializable, UUPSUpgradeable {
    mapping(bytes32 => Challenge) public challenges;  // slot 0
    address public owner;                              // slot 1
    uint256 public totalPrizePool;                    // slot 2
    // ... other variables ...

    // Reserve 47 slots for future variables
    uint256[47] private __gap;
}

// V2 contract — add new variable, reduce gap by 1
contract SpartaChallengeV2 is Initializable, UUPSUpgradeable {
    mapping(bytes32 => Challenge) public challenges;  // slot 0 — unchanged
    address public owner;                              // slot 1 — unchanged
    uint256 public totalPrizePool;                    // slot 2 — unchanged
    uint256 public feeRate;                           // slot 3 — NEW variable

    // Gap reduced from 47 to 46 (used 1 new slot)
    uint256[46] private __gap;
}
```

## Upgrade Execution via Safe + Timelock

```bash
# Step 1: Deploy new implementation
forge create src/SpartaChallengeV2.sol:SpartaChallengeV2 \
  --rpc-url $BASE_RPC --private-key $DEPLOYER_KEY
# Note the NEW_IMPL address

# Step 2: Verify new implementation on Basescan
forge verify-contract $NEW_IMPL SpartaChallengeV2 \
  --etherscan-api-key $BASESCAN_KEY --chain base --watch

# Step 3: Check timelock delay
cast call $TIMELOCK "getMinDelay()(uint256)" --rpc-url $BASE_RPC
# e.g., 172800 = 2 days
```

```typescript
// Step 4: Schedule upgrade via Safe → Timelock
import { ethers } from "ethers";

const TIMELOCK_ABI = [
    "function schedule(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt, uint256 delay) external",
    "function execute(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) external",
    "function getMinDelay() external view returns (uint256)",
];

async function scheduleUpgrade(newImpl: string) {
    const proxyAdminIface = new ethers.Interface(["function upgrade(address proxy, address implementation)"]);
    const upgradeData = proxyAdminIface.encodeFunctionData("upgrade", [PROXY_ADDRESS, newImpl]);

    const salt = ethers.randomBytes(32);
    const predecessor = ethers.ZeroHash;

    // This gets proposed to Safe, which then calls Timelock.schedule
    return {
        target:      PROXY_ADMIN_ADDRESS,
        value:       0,
        data:        upgradeData,
        predecessor,
        salt,
        delay:       await getMinDelay(),
    };
}
```

## Post-Upgrade Verification

```bash
# Verify implementation slot updated
cast storage $PROXY_ADDRESS \
  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc \
  --rpc-url $BASE_RPC
# Must equal $NEW_IMPL address

# Verify critical state intact
cast call $PROXY_ADDRESS "owner()(address)" --rpc-url $BASE_RPC
cast call $PROXY_ADDRESS "totalPrizePool()(uint256)" --rpc-url $BASE_RPC

# Run integration test on fork AFTER upgrade
forge test --fork-url $BASE_RPC \
  --fork-block-number $(cast block-number --rpc-url $BASE_RPC) \
  --match-contract PostUpgradeTest -vvv

# Check new function exists
cast call $PROXY_ADDRESS "feeRate()(uint256)" --rpc-url $BASE_RPC
```

## Emergency Rollback

```bash
# For UUPS: deploy OLD implementation again and upgrade back
# (only works if new impl didn't brick the upgrade function)
forge create src/SpartaChallengeV1.sol:SpartaChallengeV1 \
  --rpc-url $BASE_RPC --private-key $DEPLOYER_KEY
# Propose upgrade back to old impl via Safe

# For Transparent proxy: ProxyAdmin always retains upgrade ability
# ProxyAdmin.upgrade(proxy, oldImplAddress)
# This works even if new implementation is broken
# Reason to prefer Transparent proxy for high-value, long-lived contracts
```
