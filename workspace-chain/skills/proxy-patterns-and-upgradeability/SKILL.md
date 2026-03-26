# Proxy Patterns & Upgradeability

## Why Proxies
Smart contracts are immutable once deployed. Proxies delegate calls to an implementation contract that can be swapped, effectively making logic "upgradeable" while preserving the same address and storage.

**The core mechanism**: DELEGATECALL runs the implementation's code in the proxy's storage context. Same storage, different logic.

## Transparent Proxy (EIP-1967)
```
User → [TransparentProxy] → delegatecall → [Implementation]
         ProxyAdmin ↑ (can upgrade)
```
- Storage slots at fixed EIP-1967 locations (e.g., `implementation` at `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`)
- ProxyAdmin can upgrade but CANNOT call implementation functions
- Users interact with implementation functions only
- **Limitation**: Admin can't use the protocol they administer

**When to use**: Simple upgradeable contracts, established pattern, high compatibility.

## UUPS Proxy (EIP-1822)
```
User → [ERC1967Proxy] → delegatecall → [Implementation with upgradeTo()]
```
- Upgrade logic lives IN the implementation contract
- Lighter proxy bytecode (cheaper deployment, cheaper calls — saves ~2.3K gas per call vs Transparent)
- **Critical risk**: If you deploy a new implementation WITHOUT the `upgradeTo()` function, the proxy is permanently bricked. Always verify upgrade function exists in new implementation before upgrading.
- Use `UUPSUpgradeable` from OpenZeppelin — includes upgrade authorization hook.

**When to use**: New projects, gas-sensitive applications. Preferred pattern.

```solidity
contract MyContract is UUPSUpgradeable, OwnableUpgradeable {
    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
```

## Beacon Proxy
```
[Proxy1] ──┐
[Proxy2] ──┼── reads implementation address from → [Beacon] → [Implementation]
[Proxy3] ──┘
```
- Multiple proxies all point to one Beacon contract
- Upgrade the Beacon → all proxies upgrade simultaneously
- One transaction upgrades unlimited proxies
- **When to use**: Factory-deployed contracts (prediction markets, user vaults) that all need the same upgrade

```solidity
// Deploy beacon with initial implementation
UpgradeableBeacon beacon = new UpgradeableBeacon(implementationAddress, owner);

// Each factory-deployed market uses BeaconProxy
BeaconProxy proxy = new BeaconProxy(
    address(beacon),
    abi.encodeCall(Market.initialize, (params))
);
```

## Diamond Pattern (EIP-2535)
```
User → [Diamond] → function selector lookup → [FacetA | FacetB | FacetC]
```
- One proxy, multiple implementation contracts (facets)
- `DiamondStorage`: shared storage layout across all facets
- `DiamondCut`: add/replace/remove function → facet mappings
- **When to use**: Very large systems (>24KB bytecode limit), modular upgrades, complex protocols
- **Avoid**: Unless you specifically need modularity. High complexity = high audit cost.

## Storage Safety Rules (CRITICAL)

### The Cardinal Rule: Only Append, Never Remove or Reorder
```solidity
// V1
contract MyContract {
    uint256 public value;    // slot 0
    address public owner;    // slot 1
}

// V2 CORRECT — append only
contract MyContract {
    uint256 public value;    // slot 0 — unchanged
    address public owner;    // slot 1 — unchanged
    uint256 public newVar;   // slot 2 — appended
}

// V2 WRONG — storage collision!
contract MyContract {
    address public owner;    // now slot 0 — COLLIDES with old slot 0 (value)!
    uint256 public value;    // now slot 1
}
```

### Storage Gaps
Reserve slots for future variables in base contracts:
```solidity
contract BaseUpgradeable {
    uint256 private _someVar;
    // Reserve 49 slots for future use
    uint256[49] private __gap;
}
```

### Initializers vs Constructors
Proxies don't run constructors. Use initializers:
```solidity
contract Market is Initializable {
    function initialize(address _token) public initializer {
        // Called once via proxy
        token = _token;
    }
}

// In the implementation contract constructor (prevent direct init):
constructor() {
    _disableInitializers(); // Prevents attacker from initializing implementation directly
}
```

## Upgrade Safety Checklist
- [ ] Storage layout validated with `@openzeppelin/upgrades-core` or `forge` storage layout diff
- [ ] No storage variable reordering or removal
- [ ] New implementation has `upgradeTo()` function (UUPS)
- [ ] `_disableInitializers()` in implementation constructor
- [ ] Tested upgrade on forked mainnet before deploying
- [ ] Timelock on upgrade operation (governance delay)
- [ ] Multisig controls upgrade authority
- [ ] New implementation verified on block explorer
- [ ] Rollback plan documented
