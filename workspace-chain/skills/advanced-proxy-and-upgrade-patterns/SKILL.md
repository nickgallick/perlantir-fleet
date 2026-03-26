# Advanced Proxy & Upgrade Patterns

## Overview

Upgradeability in EVM smart contracts is not a single pattern but a spectrum of architectural choices with distinct tradeoffs in gas cost, security surface, governance complexity, and storage safety. This document covers the full landscape from minimal clones to multi-facet diamonds, with complete implementations and deployment tooling.

---

## 1. Diamond Pattern (EIP-2535)

The Diamond pattern solves two hard problems simultaneously: the 24KB contract size limit and the need for a single proxy address to serve multiple logical modules (facets).

### Core Concepts

- **Diamond**: The proxy contract at a single address. Stores a mapping from function selector to facet address.
- **Facet**: An implementation contract. Any number of facets can be attached to one diamond.
- **diamondCut**: The single function that adds, replaces, or removes facets atomically.
- **Loupe functions**: Introspection — enumerate facets, selectors, and facet addresses.
- **Diamond Storage**: Each facet uses a struct stored at a deterministic slot via `keccak256("diamond.storage.namespace") - 1` to avoid collisions.

### Diamond Storage Pattern

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library DiamondStorageLib {
    // Each facet defines its own storage struct at a unique slot.
    // Slot formula: keccak256(abi.encode(uint256(keccak256("myapp.storage.token")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant TOKEN_STORAGE_SLOT =
        0x1234000000000000000000000000000000000000000000000000000000000000; // Replace with real hash

    struct TokenStorage {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function tokenStorage() internal pure returns (TokenStorage storage ts) {
        bytes32 slot = TOKEN_STORAGE_SLOT;
        assembly {
            ts.slot := slot
        }
    }
}
```

### DiamondCut Interface and Storage

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IDiamondCut {
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_SLOT =
        keccak256(abi.encode(uint256(keccak256("eip2535.diamond.storage")) - 1)) & ~bytes32(uint256(0xff));

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector => facet address and selector position
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 slot = DIAMOND_STORAGE_SLOT;
        assembly {
            ds.slot := slot
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamond: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamond: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamond: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamond: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamond: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress == address(0), "LibDiamond: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamond: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamond: Can't remove function that doesn't exist");
        require(_facetAddress != address(this), "LibDiamond: Can't remove immutable function");
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];
        if (lastSelectorPosition == 0) {
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamond: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert("LibDiamond: _init function reverted");
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
```

### Diamond Proxy Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "./LibDiamond.sol";
import { IDiamondCut } from "./IDiamondCut.sol";
import { IDiamondLoupe } from "./IDiamondLoupe.sol";

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet.
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the function
    // if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
```

### Loupe Facet

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "./LibDiamond.sol";
import { IDiamondLoupe } from "./IDiamondLoupe.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}
```

---

## 2. Metamorphic Contracts (Pre-Dencun)

Metamorphic contracts exploit CREATE2's deterministic addressing combined with selfdestruct to deploy different bytecode at the same address. **Post-EIP-6780 (Dencun, March 2024)**, selfdestruct only sends ETH; it no longer deletes code unless the contract was created in the same transaction. This pattern is now effectively deprecated for new designs on mainnet.

### Pre-Dencun Pattern (Historical Reference)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // Pre-Dencun semantics

// The factory deploys a transient "deployer" at a fixed salt,
// which immediately deploys the real implementation and selfdestructs.
// Net effect: implementation bytecode at the CREATE2 address can change.

contract MetamorphicFactory {
    // Immutable: the address where the metamorphic contract lives
    address public immutable metamorphicAddress;
    // Temporary storage for the initcode to be deployed
    bytes private _initCode;

    bytes32 constant SALT = bytes32(0);

    // The creation code of the "metamorphic" contract:
    // reads initcode from factory and deploys it via CREATE
    bytes constant METAMORPHIC_INIT =
        hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3";

    constructor() {
        metamorphicAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                address(this),
                SALT,
                keccak256(METAMORPHIC_INIT)
            ))))
        );
    }

    function deploy(bytes memory initCode) external returns (address deployed) {
        _initCode = initCode;
        bytes memory metamorphicInit = METAMORPHIC_INIT;
        assembly {
            deployed := create2(0, add(metamorphicInit, 32), mload(metamorphicInit), 0) // SALT = 0
        }
        require(deployed == metamorphicAddress, "MetamorphicFactory: wrong address");
        delete _initCode;
    }

    // Called by the transient deployer to retrieve initcode
    function getInitCode() external view returns (bytes memory) {
        return _initCode;
    }
}
```

### Post-Dencun Alternative: Just Use UUPS or Beacon

For any use case that previously relied on metamorphic contracts, prefer:
- UUPS proxy (single contract, self-upgradeable)
- Beacon proxy (upgrade many instances simultaneously)
- CREATE3 (deterministic address without redeployment)

---

## 3. Namespaced Storage (EIP-7201)

EIP-7201 standardizes where each logical module stores its state to prevent slot collisions across proxies and inherited contracts.

### Formula

```
storage_slot = keccak256(abi.encode(uint256(keccak256(id)) - 1)) & ~bytes32(uint256(0xff))
```

The `& ~0xff` operation zeros the last byte, reserving 256 slots for struct members starting at the computed slot (struct layout proceeds linearly from slot N).

### Reference Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// EIP-7201: Namespaced Storage
// @custom:storage-location erc7201:myapp.storage.v1
contract NamespacedStorageExample {
    /// @custom:storage-location erc7201:myapp.storage.token
    struct TokenStorage {
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        string name;
        string symbol;
    }

    // keccak256(abi.encode(uint256(keccak256("myapp.storage.token")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TOKEN_STORAGE_LOCATION =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getTokenStorage() private pure returns (TokenStorage storage $) {
        assembly {
            $.slot := TOKEN_STORAGE_LOCATION
        }
    }

    function totalSupply() public view returns (uint256) {
        return _getTokenStorage().totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _getTokenStorage().balances[account];
    }
}
```

### OpenZeppelin v5 Pattern

OZ v5 uses this exact pattern in all upgradeable contracts. Example from `OwnableUpgradeable`:

```solidity
// From OpenZeppelin Contracts v5
abstract contract OwnableUpgradeable is Initializable, OwnableStorage {
    // @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    bytes32 private constant OwnableStorageLocation =
        0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }
}
```

### Migration from Unstructured Storage

When migrating from unstructured (append-at-fixed-slot) to namespaced storage:
1. Deploy a new implementation with EIP-7201 slots.
2. Write a migration initializer that copies values from old slots to new struct.
3. Use `reinitializer(2)` to guard it.
4. After migration, drop the old slot variables from layout (leave gaps or use `uint256[N] __gap`).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TokenV2 is Initializable {
    // Old unstructured slot (slot 0 in original layout) — must keep for migration
    // DO NOT remove until after migration is complete across all proxies
    uint256 private _legacyTotalSupply; // slot 0

    /// @custom:storage-location erc7201:myapp.storage.token
    struct TokenStorage {
        uint256 totalSupply;
        mapping(address => uint256) balances;
    }

    bytes32 private constant TOKEN_STORAGE_LOCATION =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getTokenStorage() private pure returns (TokenStorage storage $) {
        assembly {
            $.slot := TOKEN_STORAGE_LOCATION
        }
    }

    function initializeV2() external reinitializer(2) {
        TokenStorage storage $ = _getTokenStorage();
        // Migrate from legacy slot 0
        $.totalSupply = _legacyTotalSupply;
        _legacyTotalSupply = 0; // Clear old slot
    }
}
```

---

## 4. Beacon Proxy Pattern

The Beacon pattern decouples the implementation address from individual proxies. All proxies point to a beacon; changing the beacon's implementation pointer upgrades all proxies in a single transaction.

### When to Use Beacon vs UUPS vs Transparent

| Criterion | Beacon | UUPS | Transparent |
|---|---|---|---|
| Mass upgrade (N instances) | Best — 1 tx | N txs | N txs |
| Upgrade authorization gas | Low (beacon storage) | In implementation | Admin slot |
| Individual upgrade possible | No (by design) | Yes | Yes |
| Logic separation | Clean | Mixed | Mixed |
| Deployment cost | Higher (beacon contract) | Lower | Higher (admin logic) |

### UpgradeableBeacon

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

// Deploy sequence:
// 1. Deploy implementation
// 2. Deploy UpgradeableBeacon(implementation, owner)
// 3. For each instance: deploy BeaconProxy(beacon, initData)

contract VaultImplementation {
    address private _beacon; // not used in impl, only in proxy context

    /// @custom:storage-location erc7201:myapp.storage.vault
    struct VaultStorage {
        address owner;
        uint256 balance;
        bool initialized;
    }

    bytes32 private constant VAULT_STORAGE_LOCATION =
        0xabcd000000000000000000000000000000000000000000000000000000000000; // use real hash

    function _getVaultStorage() private pure returns (VaultStorage storage $) {
        assembly {
            $.slot := VAULT_STORAGE_LOCATION
        }
    }

    function initialize(address owner) external {
        VaultStorage storage $ = _getVaultStorage();
        require(!$.initialized, "Already initialized");
        $.initialized = true;
        $.owner = owner;
    }

    function deposit() external payable {
        _getVaultStorage().balance += msg.value;
    }
}
```

### Deployment Script (Foundry)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./VaultImplementation.sol";

contract DeployBeaconSystem is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // 1. Deploy implementation
        VaultImplementation impl = new VaultImplementation();

        // 2. Deploy beacon (owner = deployer, can be transferred to multisig)
        UpgradeableBeacon beacon = new UpgradeableBeacon(address(impl), deployer);

        // 3. Deploy proxy instances
        for (uint256 i = 0; i < 3; i++) {
            bytes memory initData = abi.encodeCall(VaultImplementation.initialize, (deployer));
            BeaconProxy proxy = new BeaconProxy(address(beacon), initData);
            console.log("Vault proxy", i, ":", address(proxy));
        }

        vm.stopBroadcast();

        console.log("Implementation:", address(impl));
        console.log("Beacon:", address(beacon));
    }

    function upgrade(address beacon, address newImpl) external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        VaultImplementation newImplContract = new VaultImplementation();
        UpgradeableBeacon(beacon).upgradeTo(address(newImplContract));

        vm.stopBroadcast();
        console.log("Upgraded beacon to:", address(newImplContract));
    }
}
```

---

## 5. UUPS vs Transparent Proxy

### Transparent Proxy

The admin address is stored in a dedicated EIP-1967 slot (`keccak256("eip1967.proxy.admin") - 1`). The proxy intercepts all admin calls (upgrade, changeAdmin) and forwards all other calls to the implementation. The admin can never call implementation functions directly.

**Storage layout**: Implementation is stored at `keccak256("eip1967.proxy.implementation") - 1`.

```
EIP-1967 slots:
  implementation: 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  admin:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  beacon:         0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50
```

### UUPS Proxy

The upgrade logic lives in the implementation, not the proxy. The proxy is minimal — just a delegatecall forwarder. `UUPSUpgradeable` in OpenZeppelin provides the `upgradeTo` / `upgradeToAndCall` functions with an `_authorizeUpgrade` hook.

**Security risk**: If the implementation is bricked (broken `_authorizeUpgrade`), the proxy is permanently locked. Never deploy UUPS without a multisig or timelock holding upgrade authority.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyProtocolV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:storage-location erc7201:myprotocol.storage.v1
    struct ProtocolStorage {
        uint256 version;
        mapping(address => uint256) stakes;
        uint256 totalStaked;
    }

    bytes32 private constant PROTOCOL_STORAGE_LOCATION =
        0xf00d000000000000000000000000000000000000000000000000000000000000; // real hash required

    function _getProtocolStorage() private pure returns (ProtocolStorage storage $) {
        assembly {
            $.slot := PROTOCOL_STORAGE_LOCATION
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        _getProtocolStorage().version = 1;
    }

    // Only owner can authorize upgrades. In production: owner = timelock.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function stake() external payable {
        ProtocolStorage storage $ = _getProtocolStorage();
        $.stakes[msg.sender] += msg.value;
        $.totalStaked += msg.value;
    }

    function version() external view returns (uint256) {
        return _getProtocolStorage().version;
    }
}
```

### Storage Collision Risk

The classic collision: if an implementation uses slot 0 for a variable AND the proxy stores the implementation address at slot 0, delegatecall will corrupt both. EIP-1967 solves this with pseudo-random slots. With namespaced storage (EIP-7201), collision risk is negligible — each module hashes a unique string.

**Never** inherit from non-upgradeable contracts in an upgradeable implementation. `Ownable` vs `OwnableUpgradeable` is a classic footgun: `Ownable` uses slot 0 for `_owner`, which will collide with implementation storage in a pre-7201 layout.

---

## 6. Minimal Proxy (EIP-1167)

EIP-1167 defines a 45-byte bytecode template that delegatecalls to a fixed implementation. Used for cheap "clone" deployments — ~10x cheaper than full deployment.

### Clone Bytecode (45 bytes)

```
363d3d373d3d3d363d73<20-byte-address>5af43d82803e903d91602b57fd5bf3
```

### OpenZeppelin Clones

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract CloneFactory {
    using Clones for address;

    address public immutable implementation;
    address[] public clones;

    event CloneDeployed(address indexed clone, address indexed owner);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    // Standard clone: cheapest, same address pattern each time
    function createClone(address owner) external returns (address clone) {
        clone = implementation.clone();
        IInitializable(clone).initialize(owner);
        clones.push(clone);
        emit CloneDeployed(clone, owner);
    }

    // Deterministic clone: same address for same salt across any chain
    function createDeterministicClone(address owner, bytes32 salt) external returns (address clone) {
        clone = implementation.cloneDeterministic(salt);
        IInitializable(clone).initialize(owner);
        clones.push(clone);
        emit CloneDeployed(clone, owner);
    }

    // Predict address before deployment
    function predictCloneAddress(bytes32 salt) external view returns (address) {
        return implementation.predictDeterministicAddress(salt);
    }
}

interface IInitializable {
    function initialize(address owner) external;
}
```

### Clones With Immutable Args (CWIA)

CWIA appends immutable arguments to the clone bytecode. These are read via `calldata` slicing in the implementation, avoiding storage costs.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Using wightstufff/clones-with-immutable-args
import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";

contract VaultCWIA is Clone {
    // Read immutable args baked into bytecode at deploy time
    function owner() public pure returns (address) {
        return _getArgAddress(0); // first 20 bytes of appended args
    }

    function maxDeposit() public pure returns (uint256) {
        return _getArgUint256(20); // next 32 bytes
    }

    function deposit() external payable {
        require(msg.value <= maxDeposit(), "Exceeds max");
    }
}

contract VaultCWIAFactory {
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createVault(address vaultOwner, uint256 maxDep) external returns (address vault) {
        bytes memory data = abi.encodePacked(vaultOwner, maxDep);
        vault = implementation.clone(data);
        // No initialize() needed — owner and maxDeposit are in bytecode
    }
}
```

---

## 7. Storage Layout Compatibility

### The Append-Only Rule

When upgrading an implementation:
- **Never remove** storage variables.
- **Never reorder** storage variables.
- **Never change the type** of a variable (even same-size types like `uint256` → `int256` can change semantics).
- **Always append** new variables at the end.
- **Mappings are safe** to "expand" conceptually — mapping slots are computed by key hash, not sequential.

### Gap Pattern

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract StorageV1 {
    uint256 public value;
    address public admin;
    // Reserve 48 slots for future use without breaking layout
    uint256[48] private __gap;
}

// Safe upgrade: use gap slots
abstract contract StorageV2 is StorageV1 {
    // "Consume" one gap slot by adding a new variable
    // __gap shrinks by 1 implicitly — but this ONLY works if we
    // explicitly override __gap to length 47 in the child
    uint256 public newValue;
    uint256[47] private __gap; // Was 48, now 47 — net slot count unchanged
}
```

**Preferred modern alternative**: Use EIP-7201 namespaced storage structs. Adding fields to the end of a struct is safe (struct members are laid out sequentially from the struct's base slot). Gap patterns become unnecessary.

### Layout Verification with Foundry

```bash
# Check storage layout of a contract
forge inspect MyContractV2 storage-layout

# Compare layouts between versions (pipe to jq for diff)
forge inspect MyContractV1 storage-layout --json > v1.json
forge inspect MyContractV2 storage-layout --json > v2.json
diff v1.json v2.json
```

---

## 8. Upgrade Safety Checks

### OpenZeppelin Upgrades Plugin (Hardhat / Foundry)

The plugin statically analyzes storage layout and flags incompatible changes before deployment.

```typescript
// hardhat.config.ts
import "@openzeppelin/hardhat-upgrades";

// deploy/001_deploy_proxy.ts
import { ethers, upgrades } from "hardhat";

async function main() {
    const MyProtocol = await ethers.getContractFactory("MyProtocolV1");

    // deployProxy validates the contract is upgrade-safe
    const proxy = await upgrades.deployProxy(MyProtocol, [await ethers.getSigners()[0].getAddress()], {
        kind: "uups",
        initializer: "initialize",
    });
    await proxy.waitForDeployment();
    console.log("Proxy:", await proxy.getAddress());

    // Upgrade (validates storage layout compatibility)
    const MyProtocolV2 = await ethers.getContractFactory("MyProtocolV2");
    const upgraded = await upgrades.upgradeProxy(await proxy.getAddress(), MyProtocolV2, {
        kind: "uups",
        call: { fn: "initializeV2", args: [] }, // optional reinitializer call
    });
    console.log("Upgraded to V2");
}
```

### Foundry with OZ Upgrades

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract UpgradeTest is Test {
    address proxy;

    function setUp() public {
        proxy = Upgrades.deployUUPSProxy(
            "MyProtocolV1.sol",
            abi.encodeCall(MyProtocolV1.initialize, (address(this)))
        );
    }

    function testUpgrade() public {
        // This validates storage layout compatibility at test time
        Upgrades.upgradeProxy(
            proxy,
            "MyProtocolV2.sol",
            abi.encodeCall(MyProtocolV2.initializeV2, ())
        );
        MyProtocolV2 v2 = MyProtocolV2(proxy);
        assertEq(v2.version(), 2);
    }
}
```

### Annotation-Based Safety

```solidity
// Mark constructor as safe to skip initializer check
/// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
    _disableInitializers();
}

// Mark a state variable as intentionally uninitialized
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable
address private immutable _factory;

// Allow delegatecall in a specific function
/// @custom:oz-upgrades-unsafe-allow delegatecall
function exec(address target, bytes calldata data) external {
    (bool ok,) = target.delegatecall(data);
    require(ok);
}
```

---

## 9. Multi-Implementation Proxies (Routing Proxies)

A routing proxy dispatches calls to different implementations based on a registry. Unlike Diamond (function-selector routing), routing proxies can route by caller, version tag, or feature flag.

### Version Registry Proxy

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VersionRegistry {
    address public owner;
    mapping(bytes32 => address) public implementations;
    bytes32 public currentVersion;

    event VersionRegistered(bytes32 indexed version, address implementation);
    event VersionActivated(bytes32 indexed version);

    constructor(address _owner) {
        owner = _owner;
    }

    function registerVersion(bytes32 versionTag, address implementation) external {
        require(msg.sender == owner, "Not owner");
        require(implementation.code.length > 0, "No code");
        implementations[versionTag] = implementation;
        emit VersionRegistered(versionTag, implementation);
    }

    function activateVersion(bytes32 versionTag) external {
        require(msg.sender == owner, "Not owner");
        require(implementations[versionTag] != address(0), "Version not registered");
        currentVersion = versionTag;
        emit VersionActivated(versionTag);
    }

    function currentImplementation() external view returns (address) {
        return implementations[currentVersion];
    }
}

contract RoutingProxy {
    VersionRegistry public immutable registry;

    constructor(address _registry) {
        registry = VersionRegistry(_registry);
    }

    fallback() external payable {
        address impl = registry.currentImplementation();
        require(impl != address(0), "No active implementation");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
```

### Per-Caller Implementation Routing

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Useful for gradual rollouts: some callers get V2, others stay on V1
contract GradualRolloutProxy {
    address public admin;
    address public defaultImpl;
    mapping(address => address) public callerOverrides;

    constructor(address _admin, address _defaultImpl) {
        admin = _admin;
        defaultImpl = _defaultImpl;
    }

    function setCallerOverride(address caller, address impl) external {
        require(msg.sender == admin);
        callerOverrides[caller] = impl;
    }

    function setDefaultImpl(address impl) external {
        require(msg.sender == admin);
        defaultImpl = impl;
    }

    fallback() external payable {
        address impl = callerOverrides[msg.sender];
        if (impl == address(0)) impl = defaultImpl;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
```

---

## 10. Initializer Patterns

### `initializer` vs `reinitializer`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MultiVersionContract is Initializable {
    uint256 public x;
    uint256 public y;
    uint256 public z;

    // Called once at V1 deployment
    function initialize(uint256 _x) external initializer {
        x = _x;
    }

    // Called once at V2 upgrade — guards against re-execution
    // reinitializer(N) allows calling if _initialized < N
    function initializeV2(uint256 _y) external reinitializer(2) {
        y = _y;
    }

    // V3 upgrade
    function initializeV3(uint256 _z) external reinitializer(3) {
        z = _z;
    }
}
```

### `_disableInitializers`

Call this in the implementation constructor to prevent direct calls to `initialize` on the bare implementation (not through a proxy). Without it, an attacker can initialize the implementation and potentially exploit it via `delegatecall` tricks.

```solidity
/// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
    _disableInitializers();
}
```

### Initializer Reentrancy Guard

`Initializable` uses a flag (`_initializing`) to block reentrant calls during initialization. This prevents an attacker from calling `initialize` again from within an initializer callback.

```solidity
// WRONG — vulnerable to reentrancy during init if externalContract is attacker-controlled
function initialize(address externalContract) external initializer {
    IExternal(externalContract).setup(); // Could re-enter initialize()
    _owner = msg.sender;
}

// SAFE — set state before external calls
function initialize(address externalContract) external initializer {
    _owner = msg.sender; // state first
    IExternal(externalContract).setup(); // external call after
}
```

### Chained Initializers in Inheritance

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MyToken is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol, address owner) external initializer {
        // Each __X_init() sets up its own namespaced storage
        __ERC20_init(name, symbol);
        __Ownable_init(owner);
        __UUPSUpgradeable_init();
        // Note: __X_init_unchained() skips calling parent initializers,
        // use when you're managing the chain manually
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
```

---

## 11. CREATE3 Pattern

CREATE2 gives a deterministic address based on `(deployer, salt, initcodeHash)`. The initcode hash means the same salt produces different addresses for different bytecode. **CREATE3** breaks the initcode dependency: the address depends only on `(deployer, salt)`.

CREATE3 is implemented by deploying a tiny proxy via CREATE2 with fixed bytecode, then having that proxy deploy the real contract via CREATE. The proxy's address is deterministic (fixed bytecode hash), and the real contract's address is the proxy's CREATE address at nonce 1.

### CreateX (Production Library)

[CreateX](https://github.com/pcaversaccio/createx) is the canonical production implementation, deployed at `0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed` on 40+ chains.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICreateX {
    function deployCreate3(bytes32 salt, bytes memory initCode) external payable returns (address newContract);
    function computeCreate3Address(bytes32 salt) external view returns (address);
    function computeCreate3Address(bytes32 salt, address deployer) external view returns (address);
}

contract CrossChainDeployer {
    ICreateX constant CREATEX = ICreateX(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

    // Deploy same contract at same address on any chain
    function deploy(bytes32 salt, bytes memory initCode) external payable returns (address deployed) {
        deployed = CREATEX.deployCreate3{value: msg.value}(salt, initCode);
    }

    // Predict address before deployment
    function predictAddress(bytes32 salt) external view returns (address) {
        return CREATEX.computeCreate3Address(salt, address(this));
    }
}
```

### Foundry Deployment Script with CREATE3

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ICreateX} from "./interfaces/ICreateX.sol";

contract DeployViaCreate3 is Script {
    ICreateX constant CREATEX = ICreateX(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

    // Encode salt with deployer prefix to prevent front-running
    // CreateX uses first 20 bytes of salt as optional deployer guard
    function buildSalt(bytes12 uniqueId) internal view returns (bytes32) {
        return bytes32(abi.encodePacked(msg.sender, uniqueId));
    }

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        bytes32 salt = buildSalt(bytes12(keccak256("myprotocol.v1")));
        bytes memory initCode = type(MyProtocol).creationCode;
        // If constructor takes args, append abi.encode(args) to initCode

        address predicted = CREATEX.computeCreate3Address(salt, vm.addr(pk));
        console.log("Predicted address:", predicted);

        address deployed = CREATEX.deployCreate3(salt, initCode);
        console.log("Deployed address:", deployed);
        require(deployed == predicted, "Address mismatch");

        vm.stopBroadcast();
    }
}
```

### Minimal CREATE3 Implementation (No Dependencies)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CREATE3 {
    // Minimal proxy bytecode: deploys whatever initcode is passed to it via CREATE
    bytes internal constant PROXY_INITCODE =
        hex"67363d3d37363d34f03d5260086018f3";

    bytes32 internal constant PROXY_INITCODE_HASH = keccak256(PROXY_INITCODE);

    function deploy(bytes32 salt, bytes memory initCode, uint256 value) internal returns (address deployed) {
        // Deploy the proxy via CREATE2
        bytes memory proxyInitcode = PROXY_INITCODE;
        address proxy;
        assembly {
            proxy := create2(0, add(proxyInitcode, 32), mload(proxyInitcode), salt)
        }
        require(proxy != address(0), "CREATE3: proxy deployment failed");

        // The proxy deploys initCode via CREATE, giving a deterministic address
        (bool success,) = proxy.call{value: value}(initCode);
        require(success, "CREATE3: initCode deployment failed");

        // Compute the deployed address: it's the CREATE address of the proxy at nonce 1
        deployed = address(uint160(uint256(keccak256(abi.encodePacked(
            hex"d694",
            proxy,
            hex"01"
        )))));

        require(deployed.code.length > 0, "CREATE3: deployment produced no code");
    }

    function getDeployed(bytes32 salt, address deployer) internal pure returns (address) {
        address proxy = address(uint160(uint256(keccak256(abi.encodePacked(
            hex"ff",
            deployer,
            salt,
            PROXY_INITCODE_HASH
        )))));

        return address(uint160(uint256(keccak256(abi.encodePacked(
            hex"d694",
            proxy,
            hex"01"
        )))));
    }
}
```

---

## 12. Upgrade Governance

### Timelock-Gated UUPS

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract GovernedProtocol is Initializable, UUPSUpgradeable {
    address public timelock;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _timelock) external initializer {
        __UUPSUpgradeable_init();
        timelock = _timelock;
    }

    // Only the timelock can upgrade — enforces a mandatory delay
    function _authorizeUpgrade(address newImplementation) internal override {
        require(msg.sender == timelock, "GovernedProtocol: only timelock");
    }
}
```

### Upgrade Flow with TimelockController

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract ProposeUpgrade is Script {
    // Step 1: Proposer schedules the upgrade call on the timelock
    function propose(
        address timelock,
        address proxy,
        address newImpl,
        bytes32 predecessor,  // 0x0 for no dependency
        bytes32 salt,
        uint256 delay         // must be >= timelock.getMinDelay()
    ) external {
        uint256 pk = vm.envUint("PROPOSER_KEY");
        vm.startBroadcast(pk);

        bytes memory upgradeCalldata = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)",
            newImpl,
            "" // empty if no reinitializer
        );

        TimelockController(payable(timelock)).schedule(
            proxy,           // target
            0,               // value
            upgradeCalldata, // data
            predecessor,
            salt,
            delay
        );

        bytes32 opId = TimelockController(payable(timelock)).hashOperation(
            proxy, 0, upgradeCalldata, predecessor, salt
        );
        console.log("Operation ID:");
        console.logBytes32(opId);

        vm.stopBroadcast();
    }

    // Step 2: After delay, executor executes
    function execute(
        address timelock,
        address proxy,
        address newImpl,
        bytes32 predecessor,
        bytes32 salt
    ) external {
        uint256 pk = vm.envUint("EXECUTOR_KEY");
        vm.startBroadcast(pk);

        bytes memory upgradeCalldata = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)",
            newImpl,
            ""
        );

        TimelockController(payable(timelock)).execute(
            proxy,
            0,
            upgradeCalldata,
            predecessor,
            salt
        );

        vm.stopBroadcast();
        console.log("Upgrade executed. New implementation:", newImpl);
    }
}
```

### Emergency Upgrade Pattern

For true emergencies (critical exploit in progress), a multisig with emergency role can bypass the timelock's delay. This requires careful role management:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/governance/TimelockController.sol";

// In your TimelockController deployment:
// - Proposer role: governance contract (Governor Bravo / OZ Governor)
// - Executor role: zero address (anyone can execute after delay) OR specific executor
// - Canceller role: multisig (to cancel malicious proposals)
// - Emergency role: guardian multisig with BYPASSER_ROLE on a custom timelock

contract EmergencyTimelock is TimelockController {
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address[] memory emergencyGuardians,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {
        for (uint256 i = 0; i < emergencyGuardians.length; i++) {
            _grantRole(EMERGENCY_ROLE, emergencyGuardians[i]);
        }
    }

    // Emergency execute: bypass delay, requires EMERGENCY_ROLE
    function emergencyExecute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external onlyRole(EMERGENCY_ROLE) {
        // Schedule immediately (delay=0 requires TIMELOCK_ADMIN_ROLE or override)
        _execute(target, value, data);
    }
}
```

### Multisig Upgrade Script (Safe)

```typescript
// scripts/proposeUpgrade.ts
// Uses Safe SDK to propose a transaction to a multisig

import { ethers } from "hardhat";
import Safe from "@safe-global/protocol-kit";
import SafeApiKit from "@safe-global/api-kit";

async function main() {
    const SAFE_ADDRESS = process.env.SAFE_ADDRESS!;
    const PROXY_ADDRESS = process.env.PROXY_ADDRESS!;
    const NEW_IMPL_ADDRESS = process.env.NEW_IMPL_ADDRESS!;
    const CHAIN_ID = BigInt(process.env.CHAIN_ID || "1");

    const [signer] = await ethers.getSigners();

    const protocolKit = await Safe.init({
        provider: process.env.RPC_URL!,
        signer: process.env.PRIVATE_KEY!,
        safeAddress: SAFE_ADDRESS,
    });

    const apiKit = new SafeApiKit({ chainId: CHAIN_ID });

    const iface = new ethers.Interface(["function upgradeToAndCall(address,bytes)"]);
    const data = iface.encodeFunctionData("upgradeToAndCall", [NEW_IMPL_ADDRESS, "0x"]);

    const safeTransaction = await protocolKit.createTransaction({
        transactions: [{
            to: PROXY_ADDRESS,
            value: "0",
            data,
        }],
    });

    const safeTxHash = await protocolKit.getTransactionHash(safeTransaction);
    const signature = await protocolKit.signHash(safeTxHash);

    await apiKit.proposeTransaction({
        safeAddress: SAFE_ADDRESS,
        safeTransactionData: safeTransaction.data,
        safeTxHash,
        senderAddress: await signer.getAddress(),
        senderSignature: signature.data,
    });

    console.log("Proposed upgrade transaction:", safeTxHash);
    console.log("Safe UI:", `https://app.safe.global/transactions/tx?safe=eth:${SAFE_ADDRESS}&id=multisig_${SAFE_ADDRESS}_${safeTxHash}`);
}

main().catch(console.error);
```

---

## Checklist: Choosing the Right Pattern

| Scenario | Recommended Pattern |
|---|---|
| Single contract, needs upgrade | UUPS |
| Many identical instances, bulk upgrade | Beacon proxy |
| Large protocol with many modules | Diamond (EIP-2535) |
| Cheap factory for non-upgradeable instances | EIP-1167 clone |
| Cheap factory with per-instance config | CWIA |
| Cross-chain deterministic address | CREATE3 via CreateX |
| Gradual migration / canary deployment | Routing proxy with version registry |
| Emergency pause only, no logic change | Access control + pause, not upgrade |

## Security Non-Negotiables

1. Always call `_disableInitializers()` in implementation constructors.
2. Never leave `_authorizeUpgrade` open to `msg.sender == owner` where owner is an EOA. Use a timelock minimum.
3. Validate storage layout before every upgrade — automated via OZ Upgrades plugin or Foundry `openzeppelin-foundry-upgrades`.
4. Test upgrade sequences in fork tests: deploy V1, populate state, upgrade to V2, assert state is preserved.
5. For Diamond proxies: every facet's `diamondCut` call should go through the same governance/timelock as UUPS upgrades.
6. With Beacon proxies: the beacon owner IS the upgrade authority for all instances — treat it with the same weight as a protocol multisig.
7. EIP-1967 slots are not magic protection — always use EIP-7201 namespaced storage in implementations to avoid slot collisions with proxy admin/implementation slots.
8. On chains post-Dencun: do not design new systems around selfdestruct for mutability. Selfdestruct only clears code if called in the same transaction as creation.
