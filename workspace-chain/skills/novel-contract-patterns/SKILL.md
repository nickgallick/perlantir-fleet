# Novel Contract Patterns

Expert-level reference for modern Solidity contract patterns. Each section covers the canonical implementation, subtle correctness constraints, and security pitfalls that appear in audit findings.

---

## 1. ERC-6909 — Minimal Multi-Token Standard

### Overview

ERC-6909 is a minimal multi-token interface designed as a leaner alternative to ERC-1155. It eliminates mandatory batch operations, removes the `onERC6909Received` callback requirement (no safeTransfer hook), and separates operator permissions from per-ID approvals.

### Core Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC6909 {
    event Transfer(address caller, address indexed from, address indexed to, uint256 indexed id, uint256 amount);
    event OperatorSet(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);

    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function allowance(address owner, address spender, uint256 id) external view returns (uint256);
    function isOperator(address owner, address operator) external view returns (bool);
    function transfer(address to, uint256 id, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 id, uint256 amount) external returns (bool);
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);
    function setOperator(address operator, bool approved) external returns (bool);
}
```

### Minimal Implementation

```solidity
abstract contract ERC6909 is IERC6909 {
    mapping(address owner => mapping(uint256 id => uint256)) public balanceOf;
    mapping(address owner => mapping(address spender => mapping(uint256 id => uint256))) public allowance;
    mapping(address owner => mapping(address operator => bool)) public isOperator;

    function transfer(address to, uint256 id, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender][id] -= amount;
        balanceOf[to][id] += amount;
        emit Transfer(msg.sender, msg.sender, to, id, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 id, uint256 amount) public virtual returns (bool) {
        if (from != msg.sender && !isOperator[from][msg.sender]) {
            uint256 allowed = allowance[from][msg.sender][id];
            if (allowed != type(uint256).max) {
                allowance[from][msg.sender][id] = allowed - amount; // underflows on insufficient
            }
        }
        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;
        emit Transfer(msg.sender, from, to, id, amount);
        return true;
    }

    function approve(address spender, uint256 id, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender][id] = amount;
        emit Approval(msg.sender, spender, id, amount);
        return true;
    }

    function setOperator(address operator, bool approved) public virtual returns (bool) {
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        return true;
    }

    function _mint(address to, uint256 id, uint256 amount) internal {
        balanceOf[to][id] += amount;
        emit Transfer(msg.sender, address(0), to, id, amount);
    }

    function _burn(address from, uint256 id, uint256 amount) internal {
        balanceOf[from][id] -= amount;
        emit Transfer(msg.sender, from, address(0), id, amount);
    }
}
```

### ERC-6909 vs ERC-1155

| Feature | ERC-1155 | ERC-6909 |
|---|---|---|
| Safe transfer callbacks | Mandatory (`onERC1155Received`) | None |
| Batch transfer in spec | Yes (`safeBatchTransferFrom`) | No (implementor choice) |
| Per-ID approvals | No (operator-only) | Yes |
| Operator model | Global | Global + per-ID |
| Gas overhead | Higher (callbacks) | Lower |
| Re-entrancy surface | High (callback) | Low |

### Security Considerations

- No `onERC6909Received` callback removes the main ERC-1155 reentrancy vector, but also means no defense against sending tokens to contracts that cannot handle them.
- `type(uint256).max` allowance as infinite approval is a convention, not a spec requirement — verify consuming contracts handle it.
- The `caller` field in `Transfer` events (the msg.sender, not necessarily `from`) is a break from ERC-20/1155 indexing conventions.
- Operators have unlimited power across all IDs — privilege escalation if an operator key is compromised.

---

## 2. Uniswap V4 Hooks

### Hook Lifecycle

Uniswap V4 introduces hooks: external contracts called at specific points in pool operations. The `PoolManager` calls hooks before and after each action.

```
Hook call points:
  beforeInitialize / afterInitialize
  beforeAddLiquidity / afterAddLiquidity
  beforeRemoveLiquidity / afterRemoveLiquidity
  beforeSwap / afterSwap
  beforeDonate / afterDonate
```

### Hook Flags via Address

The hook contract's address encodes which callbacks it expects. The last 14 bits of the address are inspected:

```solidity
// From Uniswap V4 source
library Hooks {
    uint160 constant BEFORE_INITIALIZE_FLAG      = 1 << 13;
    uint160 constant AFTER_INITIALIZE_FLAG       = 1 << 12;
    uint160 constant BEFORE_ADD_LIQUIDITY_FLAG   = 1 << 11;
    uint160 constant AFTER_ADD_LIQUIDITY_FLAG    = 1 << 10;
    uint160 constant BEFORE_REMOVE_LIQUIDITY_FLAG = 1 << 9;
    uint160 constant AFTER_REMOVE_LIQUIDITY_FLAG  = 1 << 8;
    uint160 constant BEFORE_SWAP_FLAG            = 1 << 7;
    uint160 constant AFTER_SWAP_FLAG             = 1 << 6;
    uint160 constant BEFORE_DONATE_FLAG          = 1 << 5;
    uint160 constant AFTER_DONATE_FLAG           = 1 << 4;
    uint160 constant BEFORE_SWAP_RETURNS_DELTA_FLAG = 1 << 3;
    uint160 constant AFTER_SWAP_RETURNS_DELTA_FLAG  = 1 << 2;
    uint160 constant AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG    = 1 << 1;
    uint160 constant AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 0;
}
```

The hook address must be mined (CREATE2) to have the correct bits set. The PoolManager validates this on pool initialization.

### Hook Interface

```solidity
interface IHooks {
    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96)
        external returns (bytes4);
    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external returns (bytes4);

    function beforeAddLiquidity(address sender, PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params, bytes calldata hookData)
        external returns (bytes4);
    function afterAddLiquidity(address sender, PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params, BalanceDelta delta,
        BalanceDelta feesAccrued, bytes calldata hookData)
        external returns (bytes4, BalanceDelta);

    function beforeSwap(address sender, PoolKey calldata key,
        IPoolManager.SwapParams calldata params, bytes calldata hookData)
        external returns (bytes4, BeforeSwapDelta, uint24);
    function afterSwap(address sender, PoolKey calldata key,
        IPoolManager.SwapParams calldata params, BalanceDelta delta, bytes calldata hookData)
        external returns (bytes4, int128);
}
```

### PoolManager Singleton

All V4 pools live in one `PoolManager` contract. Liquidity providers and traders interact through the manager. This enables:

- Flash accounting: net token movements settle at the end of a transaction
- Shared flash loan liquidity across all pools
- Atomic multi-hop swaps with deferred settlement

```solidity
// PoolKey uniquely identifies a pool
struct PoolKey {
    Currency currency0;
    Currency currency1;
    uint24 fee;
    int24 tickSpacing;
    IHooks hooks;
}

// Interaction pattern via unlock callback
interface IUnlockCallback {
    function unlockCallback(bytes calldata data) external returns (bytes memory);
}

// Caller must implement unlockCallback
contract MyRouter is IUnlockCallback {
    IPoolManager immutable manager;

    function swap(PoolKey calldata key, IPoolManager.SwapParams calldata params) external {
        manager.unlock(abi.encode(key, params, msg.sender));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(manager));
        (PoolKey memory key, IPoolManager.SwapParams memory params, address user) =
            abi.decode(data, (PoolKey, IPoolManager.SwapParams, address));

        BalanceDelta delta = manager.swap(key, params, "");

        // Settle debts: positive delta = PoolManager owes us, negative = we owe PoolManager
        if (delta.amount0() < 0) {
            manager.sync(key.currency0);
            IERC20(Currency.unwrap(key.currency0)).transferFrom(user, address(manager), uint128(-delta.amount0()));
            manager.settle();
        }
        if (delta.amount1() > 0) {
            manager.take(key.currency1, user, uint128(delta.amount1()));
        }
        return "";
    }
}
```

### Flash Accounting with Transient Storage

The PoolManager uses transient storage (EIP-1153) to track per-currency deltas during an `unlock` session. At the end of `unlock`, all deltas must net to zero.

```solidity
// Conceptual internal accounting (simplified)
// Real implementation uses Currency => int256 in transient storage
mapping(address currency => int256 delta) transient currencyDelta;

function _accountDelta(Currency currency, int128 delta) internal {
    // tload/tstore via assembly
    int256 current = _tload(currency);
    int256 next = current + delta;
    _tstore(currency, next);
}
```

### Writing a Hook: TWAMM Example Pattern

```solidity
contract TWAMMHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // Long-term order state per pool
    mapping(PoolId => OrderState) public orderState;

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external override onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        // Execute any outstanding long-term orders before the swap
        _executeLongTermOrders(key.toId());
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}
```

### Security Considerations

- Hook addresses must be mined: use CREATE2 with a factory, verify the address flags match the implementation.
- `onlyPoolManager` modifier is critical — any hook function callable by arbitrary callers is a critical vulnerability.
- Hooks that manipulate deltas (RETURNS_DELTA flags) can cause pool insolvency if math is wrong.
- The `hookData` parameter is untrusted user input passed through from the swap caller.
- Reentrancy: hooks can call back into the PoolManager (which allows it), but must not leave inconsistent state.

---

## 3. Transient Storage Patterns (EIP-1153)

### Overview

EIP-1153 introduces two new opcodes: `TSTORE(key, value)` and `TLOAD(key)`. Transient storage is per-transaction, automatically cleared at transaction end. Cost is 100 gas per `TSTORE`/`TLOAD` (much cheaper than `SSTORE`/`SLOAD` for cold slots).

Available from Cancun hard fork (January 2024).

### Pattern 1: Reentrancy Guard

```solidity
contract TransientReentrancyGuard {
    // Slot for the reentrancy lock
    uint256 private constant REENTRANCY_SLOT = uint256(keccak256("reentrancy.guard.slot"));

    modifier nonReentrant() {
        assembly {
            if tload(REENTRANCY_SLOT) { revert(0, 0) }
            tstore(REENTRANCY_SLOT, 1)
        }
        _;
        assembly {
            tstore(REENTRANCY_SLOT, 0)
        }
    }
}
```

This is strictly cheaper than SSTORE-based guards for the common case (100 gas vs 2900+ gas for warm write).

### Pattern 2: Callback Data Passing

Pass context from an initiating call to a callback without storage:

```solidity
contract FlashLoanReceiver {
    uint256 private constant CALLBACK_DATA_SLOT = uint256(keccak256("flash.callback.data"));

    function initiateFlash(address token, uint256 amount, bytes calldata data) external {
        // Store callback context transiently
        bytes32 dataHash = keccak256(data);
        assembly { tstore(CALLBACK_DATA_SLOT, dataHash) }

        IFlashLender(lender).flash(token, amount, data);
    }

    function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata data) external {
        // Verify the callback data matches what we set
        bytes32 stored;
        assembly { stored := tload(CALLBACK_DATA_SLOT) }
        require(stored == keccak256(data), "invalid callback");
        require(msg.sender == lender, "invalid caller");

        // Execute flash loan logic...
        IERC20(token).approve(lender, amount + fee);
    }
}
```

### Pattern 3: Temporary Approvals (ERC-7674 concept)

```solidity
contract TemporaryApprovalToken is ERC20 {
    // Maps keccak256(owner, spender) => transient slot number
    // In practice, use a mapping stored transiently via custom slot derivation

    function temporaryApprove(address spender, uint256 amount) external {
        uint256 slot = _transientAllowanceSlot(msg.sender, spender);
        assembly { tstore(slot, amount) }
    }

    function _transientAllowance(address owner, address spender) internal view returns (uint256 amount) {
        uint256 slot = _transientAllowanceSlot(owner, spender);
        assembly { amount := tload(slot) }
    }

    function _transientAllowanceSlot(address owner, address spender) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked("transient.allowance", owner, spender)));
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 transientAllowed = _transientAllowance(from, msg.sender);
        if (transientAllowed >= amount) {
            uint256 slot = _transientAllowanceSlot(from, msg.sender);
            assembly { tstore(slot, sub(transientAllowed, amount)) }
        } else {
            // Fall back to persistent allowance
            super.transferFrom(from, to, amount);
            return true;
        }
        _transfer(from, to, amount);
        return true;
    }
}
```

### Pattern 4: Flash Accounting (Uniswap V4 style)

```solidity
contract FlashAccountingManager {
    uint256 private constant UNLOCKED_SLOT = uint256(keccak256("flash.accounting.unlocked"));

    modifier onlyUnlocked() {
        uint256 unlocked;
        assembly { unlocked := tload(UNLOCKED_SLOT) }
        require(unlocked == 1, "not unlocked");
        _;
    }

    function unlock(bytes calldata data) external returns (bytes memory result) {
        assembly { tstore(UNLOCKED_SLOT, 1) }
        result = IUnlockCallback(msg.sender).unlockCallback(data);
        // Verify all deltas are settled (check per-currency transient slots)
        _requireAllSettled();
        assembly { tstore(UNLOCKED_SLOT, 0) }
    }

    function _currencyDeltaSlot(address currency) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked("currency.delta", currency)));
    }

    function _accountDelta(address currency, int256 delta) internal onlyUnlocked {
        uint256 slot = _currencyDeltaSlot(currency);
        int256 current;
        assembly { current := tload(slot) }
        int256 next = current + delta;
        assembly { tstore(slot, next) }
    }
}
```

### Security Considerations

- Transient storage is NOT cleared between internal calls within the same transaction — only between transactions. This means re-entrancy guards based on transient storage work correctly.
- Transient storage values do NOT persist across `CALL` boundaries to different contracts — each contract has its own transient storage namespace.
- In Solidity 0.8.24+, the `transient` keyword can be used: `uint256 transient _lock;`
- Never use transient storage as a substitute for events or logs — it is invisible off-chain.
- Static analysis tools may not yet fully model transient storage; manual audit is required.

---

## 4. Permit2

### Overview

Permit2 (Uniswap) is a canonical shared allowance and signature-based transfer contract. It enables: (1) SignatureTransfer — one-time transfers authorized by signature, (2) AllowanceTransfer — persistent allowances set by signature.

Deployed at `0x000000000022D473030F116dDEE9F6B43aC78BA3` on all major networks.

### SignatureTransfer

```solidity
interface ISignatureTransfer {
    struct TokenPermissions {
        address token;
        uint256 amount;
    }
    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;       // unique per signature
        uint256 deadline;
    }
    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}
```

Integration pattern in a protocol contract:

```solidity
contract MyProtocol {
    IPermit2 immutable permit2;

    function depositWithPermit(
        ISignatureTransfer.PermitTransferFrom calldata permit,
        ISignatureTransfer.SignatureTransferDetails calldata details,
        bytes calldata sig
    ) external {
        // Permit2 verifies sig, checks deadline, marks nonce used, transfers tokens
        permit2.permitTransferFrom(permit, details, msg.sender, sig);
        // tokens are now in address(this), proceed with deposit logic
        _deposit(permit.permitted.token, details.requestedAmount);
    }
}
```

### AllowanceTransfer

```solidity
interface IAllowanceTransfer {
    struct PermitDetails {
        address token;
        uint160 amount;
        uint48 expiration;
        uint48 nonce;
    }
    struct PermitSingle {
        PermitDetails details;
        address spender;
        uint256 sigDeadline;
    }

    function permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature) external;
    function transferFrom(address from, address to, uint160 amount, address token) external;
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}
```

### Batch Operations

```solidity
// Batch permit + transfer in one call
struct PermitBatch {
    PermitDetails[] details;
    address spender;
    uint256 sigDeadline;
}

// Sign a PermitBatch, then:
permit2.permit(owner, permitBatch, signature);

// Then transfer multiple tokens atomically
IAllowanceTransfer.AllowanceTransferDetails[] memory transfers = new IAllowanceTransfer.AllowanceTransferDetails[](2);
transfers[0] = IAllowanceTransfer.AllowanceTransferDetails(from, to, amount0, token0);
transfers[1] = IAllowanceTransfer.AllowanceTransferDetails(from, to, amount1, token1);
permit2.transferFrom(transfers);
```

### Security Considerations

- **Witness data**: `permitWitnessTransferFrom` allows binding a permit to arbitrary data (e.g., order parameters). Always use witness when the permit should be tied to specific protocol-level intent; without it, a signed permit can be replayed for any compliant transfer.
- **Nonce bitfields**: Nonces in SignatureTransfer are word + bit positions (unordered). A nonce can only be used once but nonces within a word can be used in any order.
- **Spender is msg.sender**: In `permitTransferFrom`, the spender is always `msg.sender`. A malicious router could steal funds — users must trust the router contract.
- **Allowance expiration**: AllowanceTransfer allowances expire by timestamp. Set tight expirations (e.g., 30 days) to limit exposure.
- **Front-running**: Permit signatures are public once broadcast. Use `requestedAmount` to allow partial fills but ensure the protocol handles this correctly.
- **Token compatibility**: Permit2 uses `safeTransferFrom` internally but relies on standard ERC-20 behavior — fee-on-transfer tokens will produce unexpected received amounts.

---

## 5. ERC-4626 Tokenized Vaults

### Interface

```solidity
interface IERC4626 is IERC20 {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function maxDeposit(address receiver) external view returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function maxMint(address receiver) external view returns (uint256);
    function previewMint(uint256 shares) external view returns (uint256);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function maxWithdraw(address owner) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);
    function withdraw(uint256 assets, address owner, address receiver) external returns (uint256 shares);
    function maxRedeem(address owner) external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function redeem(uint256 shares, address owner, address receiver) external returns (uint256 assets);
}
```

### Share/Asset Math — Virtual Shares (Inflation Attack Prevention)

```solidity
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _decimals;

    // Virtual shares/assets prevent inflation attacks
    // OpenZeppelin approach: add 10^(decimalsOffset) virtual shares
    uint256 private constant _VIRTUAL_SHARES = 1;
    uint256 private constant _VIRTUAL_ASSETS = 1;

    constructor(IERC20 asset_, string memory name_, string memory symbol_)
        ERC20(name_, symbol_) {
        _asset = asset_;
    }

    function totalAssets() public view virtual returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view returns (uint256) {
        return assets.mulDiv(
            totalSupply() + _VIRTUAL_SHARES,
            totalAssets() + _VIRTUAL_ASSETS,
            rounding
        );
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view returns (uint256) {
        return shares.mulDiv(
            totalAssets() + _VIRTUAL_ASSETS,
            totalSupply() + _VIRTUAL_SHARES,
            rounding
        );
    }

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        shares = _convertToShares(assets, Math.Rounding.Floor);
        require(shares > 0, "zero shares");
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
        if (msg.sender != owner) _spendAllowance(owner, msg.sender, shares);
        assets = _convertToAssets(shares, Math.Rounding.Floor);
        _burn(owner, shares);
        _asset.transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}
```

### Inflation Attack — Deep Dive

The classic attack:
1. Attacker is first depositor, deposits 1 wei, receives 1 share.
2. Attacker donates a large amount directly to the vault (inflates `totalAssets`).
3. Next depositor deposits `X` assets. Due to rounding: `shares = X * 1 / (1 + donated)` → rounds to 0.
4. Depositor receives 0 shares, attacker redeems 1 share for all assets.

Mitigations:
- **Virtual shares/assets**: Add a constant offset to both numerator and denominator (OpenZeppelin v5 approach). An attacker must now control an astronomically large donation to cause rounding to 0.
- **Decimal offset**: Mint shares at 1e18 ratio by default, even before any deposits.
- **Dead shares**: Protocol mints a small amount of shares to address(0) on initialization.
- **Min deposit**: Require a minimum first deposit.

### Integration with Yield Sources

```solidity
contract CompoundV3Vault is ERC4626 {
    IComet immutable comet;

    function totalAssets() public view override returns (uint256) {
        // comet tracks principal + accrued interest
        return comet.balanceOf(address(this));
    }

    function _deposit(uint256 assets) internal override {
        // Forward assets to Compound
        IERC20(asset()).approve(address(comet), assets);
        comet.supply(asset(), assets);
    }

    function _withdraw(uint256 assets) internal override {
        comet.withdraw(asset(), assets);
    }
}
```

### Security Considerations

- **Fee-on-transfer assets**: `deposit` should measure received assets after transfer, not trust the `assets` parameter.
- **Slippage**: Always allow callers to specify `minShares` / `minAssets`. The preview functions are not guaranteed to match actual execution in the same block.
- **Rebasing tokens as assets**: Shares math will break if `totalAssets()` changes spontaneously (rebasing). Use a wrapper.
- **Loss of funds scenario**: If `totalAssets()` decreases (e.g., strategy loss), late redeemers receive less. This is by design but must be documented.
- **Reentrancy**: Hooks in the underlying asset can reenter. Use CEI (checks-effects-interactions) or reentrancy guards.

---

## 6. Account Abstraction — ERC-4337 and ERC-7579

### ERC-4337 UserOperation Flow

```
User signs UserOperation
    → Bundler validates (simulateValidation)
    → Bundler submits batch to EntryPoint
    → EntryPoint calls account.validateUserOp()
    → EntryPoint calls paymaster.validatePaymasterUserOp() (if paymaster set)
    → EntryPoint executes account.execute()
    → EntryPoint calls paymaster.postOp() (if paymaster set)
```

### UserOperation Structure

```solidity
struct UserOperation {
    address sender;           // smart account address
    uint256 nonce;
    bytes initCode;           // empty if account already deployed
    bytes callData;           // encoded call to execute
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;   // paymaster address + data, or empty
    bytes signature;
}
```

### Minimal Smart Account

```solidity
contract SimpleAccount is IAccount, ERC1271 {
    IEntryPoint public immutable entryPoint;
    address public owner;

    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint));
        _;
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256 validationData) {
        // Validate signature
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address recovered = ECDSA.recover(hash, userOp.signature);

        // Return packed validation data:
        // sigFailed (1 bit) | validUntil (48 bits) | validAfter (48 bits)
        if (recovered != owner) {
            return SIG_VALIDATION_FAILED; // = 1
        }

        // Pay the entrypoint if needed
        if (missingAccountFunds > 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds}("");
            success;
        }
        return 0; // success
    }

    function execute(address target, uint256 value, bytes calldata data)
        external onlyEntryPoint {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly { revert(add(result, 32), mload(result)) }
        }
    }

    function isValidSignature(bytes32 hash, bytes memory sig)
        public view override returns (bytes4) {
        address recovered = ECDSA.recover(hash, sig);
        return recovered == owner ? IERC1271.isValidSignature.selector : bytes4(0xffffffff);
    }
}
```

### Paymaster Pattern

```solidity
contract GaslessPaymaster is IPaymaster {
    IEntryPoint public immutable entryPoint;
    mapping(address => bool) public sponsored;

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external view returns (bytes memory context, uint256 validationData) {
        require(msg.sender == address(entryPoint));
        // Check if this sender is sponsored
        require(sponsored[userOp.sender], "not sponsored");
        // Return empty context, immediate validity
        return ("", 0);
    }

    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external {
        require(msg.sender == address(entryPoint));
        // mode: opSucceeded, opReverted, postOpReverted
        // Track spending if needed
    }
}
```

### Session Keys

Session keys allow delegated execution with constraints:

```solidity
struct SessionKey {
    address key;
    address allowedTarget;
    bytes4 allowedSelector;
    uint256 spendingLimit;   // per-transaction
    uint256 validUntil;
    uint256 validAfter;
}

contract SessionKeyAccount is SimpleAccount {
    mapping(bytes32 sessionId => SessionKey) public sessions;

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingFunds)
        external override onlyEntryPoint returns (uint256 validationData) {
        // Try owner signature first
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(hash, userOp.signature[:65]);

        if (signer == owner) return _packValidationData(false, 0, 0);

        // Try session key
        bytes32 sessionId = bytes32(userOp.signature[65:97]);
        SessionKey memory session = sessions[sessionId];

        if (session.key != signer) return SIG_VALIDATION_FAILED;
        if (block.timestamp > session.validUntil) return SIG_VALIDATION_FAILED;

        // Validate the call matches session constraints
        (address target,, bytes memory calldata_) = abi.decode(userOp.callData[4:], (address, uint256, bytes));
        bytes4 selector = bytes4(calldata_);
        require(target == session.allowedTarget && selector == session.allowedSelector);

        return _packValidationData(false, uint48(session.validUntil), uint48(session.validAfter));
    }
}
```

### ERC-7579 — Smart Account Modules

ERC-7579 standardizes modular smart account interfaces. Modules are categorized:

```solidity
// Module types
uint256 constant MODULE_TYPE_VALIDATOR = 1;
uint256 constant MODULE_TYPE_EXECUTOR  = 2;
uint256 constant MODULE_TYPE_FALLBACK  = 3;
uint256 constant MODULE_TYPE_HOOK      = 4;

interface IModule {
    function onInstall(bytes calldata data) external;
    function onUninstall(bytes calldata data) external;
    function isModuleType(uint256 moduleTypeId) external view returns (bool);
    function isInitialized(address smartAccount) external view returns (bool);
}

interface IValidator is IModule {
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        external returns (uint256);
    function isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata data)
        external view returns (bytes4);
}

interface IExecutor is IModule { /* no required functions beyond IModule */ }

interface IHook is IModule {
    function preCheck(address msgSender, uint256 value, bytes calldata msgData)
        external returns (bytes memory hookData);
    function postCheck(bytes calldata hookData) external;
}
```

### Security Considerations

- **Simulation vs execution**: `simulateValidation` is not atomic with execution. Bundlers must revalidate at submission time.
- **Griefing**: Malicious accounts can exhaust bundler gas in simulation. Bundlers impose stake requirements on factory/paymaster.
- **Storage restrictions**: `validateUserOp` may only access the account's own storage (and associated staked entities' storage) per ERC-4337 spec. Violations are caught by the bundler's validation rules.
- **Replay across chains**: `userOpHash` includes `chainId` — signatures are chain-specific by default.
- **Module trust**: In ERC-7579, executor modules can call `execute` with full permissions. Installing untrusted modules is equivalent to adding an owner.

---

## 7. Singleton Pattern — Uniswap V4 Style

### Motivation

Pre-V4: each pool is a separate deployed contract. Creating a pool costs ~2M gas for deployment. Liquidity is siloed.

V4: one `PoolManager` contract holds all pool state. Pool creation is a storage write (~50k gas). Flash loans and arbitrage can span pools atomically.

### State Layout

```solidity
contract PoolManager {
    // All pool state keyed by PoolId (keccak256 of PoolKey)
    mapping(PoolId id => Pool.State) internal _pools;

    // Per-currency, per-address claim balances (ERC-6909)
    mapping(address owner => mapping(uint256 id => uint256)) public balanceOf;

    // Locker stack (who currently holds the lock)
    // In V4, replaced by transient storage for the current locker
}
```

### The Unlock/Lock Pattern

```solidity
// Only one unlock can be active at a time (enforced via transient storage)
function unlock(bytes calldata data) external returns (bytes memory) {
    // Revert if already unlocked
    if (Lock.isUnlocked()) revert AlreadyUnlocked();
    Lock.unlock();

    bytes memory result = IUnlockCallback(msg.sender).unlockCallback(data);

    // Require all currency deltas are zero
    if (CurrencyReserves.getSyncedCurrency() != CurrencyLibrary.ADDRESS_ZERO) {
        revert CurrencyNotSettled();
    }
    Lock.lock();
    return result;
}
```

### Flash Loan via Singleton

```solidity
contract SingletonFlashLoan is IUnlockCallback {
    IPoolManager immutable manager;

    function flashLoan(address token, uint256 amount, bytes calldata data) external {
        manager.unlock(abi.encode(token, amount, data, msg.sender));
    }

    function unlockCallback(bytes calldata encoded) external returns (bytes memory) {
        (address token, uint256 amount, bytes memory data, address borrower) =
            abi.decode(encoded, (address, uint256, bytes, address));

        // Take tokens from PoolManager (creates a negative delta for us)
        manager.take(Currency.wrap(token), borrower, amount);

        // Let borrower use the funds
        IFlashBorrower(borrower).onFlashLoan(token, amount, data);

        // Borrower must have approved us to repay
        IERC20(token).transferFrom(borrower, address(manager), amount);
        manager.settle();

        return "";
    }
}
```

### Security Considerations

- The singleton holds all pool assets — a critical bug affects all pools simultaneously.
- Flash accounting means tokens are not transferred until settlement — the manager must verify settlement before returning from `unlock`.
- ERC-6909 claim balances inside the PoolManager are trust-equivalent to the underlying tokens — protect `mint` paths.

---

## 8. ERC-7702 — EOA Code Delegation

### Overview

ERC-7702 (introduced in Pectra, live 2025) allows an EOA to designate a contract whose code will be executed when the EOA is called. The EOA retains its private key and nonce but can now have contract code temporarily associated.

### Set Code Transaction

A new transaction type (type 4) includes an authorization list:

```
Authorization = (chain_id, contract_address, nonce, y_parity, r, s)
```

The EOA signs an authorization tuple. When the transaction is processed, the EVM stores `contract_address` as the code of the EOA (stored in a special delegation designator format). After the transaction, calls to the EOA execute the bytecode of `contract_address` in the EOA's context (like a `DELEGATECALL`).

### Implications

```solidity
// After ERC-7702: an EOA can behave like this smart account
// The EOA's storage is used, the EOA's balance is used
// But the logic comes from the delegated contract

contract DelegatedAccount {
    // Storage at slot 0 in the EOA after delegation
    address public owner;  // This IS the EOA address itself (self-referential)

    function initialize() external {
        require(owner == address(0));
        owner = msg.sender; // msg.sender is EOA in the delegation tx
    }

    function execute(address target, uint256 value, bytes calldata data) external {
        require(msg.sender == owner);
        (bool success,) = target.call{value: value}(data);
        require(success);
    }
}
```

### Key Behaviors

- The EOA can revoke delegation by sending another type-4 transaction pointing to `address(0)`.
- Multiple EOAs can delegate to the same implementation contract.
- The EOA's nonce is still used for transactions — no separate smart account nonce needed.
- `tx.origin` remains the EOA for transactions sent by the EOA.
- Contracts can check if an address has a delegation: the code stored starts with the delegation designator `0xef0100`.

### Smart Wallet Migration

```solidity
// A user with an existing EOA can adopt smart wallet features without migrating assets:
// 1. Sign authorization for a smart account implementation
// 2. Include in a type-4 tx (can be bundled by a bundler with a paymaster)
// 3. EOA now has smart account logic: social recovery, session keys, batching
// 4. User can revert at any time by re-signing with address(0)
```

### Security Considerations

- **Signature replay**: Authorization signatures include `chain_id` and `nonce`. Cross-chain replay is prevented if chain_id is set. Use `chain_id = 0` at your own risk.
- **Delegating to malicious code**: The authorized contract runs in the EOA's full context — it can drain the EOA's ETH and tokens.
- **Storage collisions**: If the user has delegated to contract A and re-delegates to contract B, storage written by A may be misinterpreted by B.
- **`SELFDESTRUCT` in delegated code**: Would destroy the EOA account permanently.
- **Phishing**: dApps could trick users into signing authorization tuples that appear to be normal messages.

---

## 9. ERC-7683 — Cross-Chain Orders

### Overview

ERC-7683 standardizes interfaces for cross-chain intent-based swaps. It separates the concept of an order (the user's intent) from the filler (the entity that executes it on the destination chain) and the settlement (the mechanism that pays the filler and delivers assets to the user).

### Core Structs

```solidity
struct CrossChainOrder {
    address settlementContract;  // origin chain settlement contract
    address swapper;             // user initiating the order
    uint256 nonce;
    uint32  originChainId;
    uint32  initiateDeadline;    // must be opened by this time
    uint32  fillDeadline;        // must be filled by this time
    bytes   orderData;           // implementation-specific
}

struct ResolvedCrossChainOrder {
    address settlementContract;
    address swapper;
    uint256 nonce;
    uint32  originChainId;
    uint32  initiateDeadline;
    uint32  fillDeadline;
    Input[] minReceived;         // minimum assets received by filler on origin
    Output[] maxSpent;           // maximum assets filler must provide on destination
}

struct Input {
    bytes32 token;     // ERC-7528 token identifier (chain-agnostic)
    uint256 amount;
}

struct Output {
    bytes32 token;
    uint256 amount;
    bytes32 recipient;
    uint32  chainId;
}
```

### Settlement Interface

```solidity
interface IOriginSettler {
    event Open(bytes32 indexed orderId, ResolvedCrossChainOrder resolvedOrder);

    function open(CrossChainOrder calldata order, bytes calldata signature) external;
    function resolve(CrossChainOrder calldata order, bytes calldata fillerData)
        external view returns (ResolvedCrossChainOrder memory);
}

interface IDestinationSettler {
    function fill(bytes32 orderId, bytes calldata originData, bytes calldata fillerData) external;
}
```

### Filler Pattern

```solidity
contract CrossChainFiller {
    IDestinationSettler immutable settler;

    // Filler monitors origin chain for Open events
    // Then calls fill on destination chain
    function fillOrder(
        bytes32 orderId,
        bytes calldata originData,    // encoded ResolvedCrossChainOrder from origin event
        address outputToken,
        uint256 outputAmount,
        address recipient
    ) external {
        // Deliver output to recipient
        IERC20(outputToken).transferFrom(msg.sender, recipient, outputAmount);

        // Notify settler (settler will verify and record fill)
        settler.fill(orderId, originData, abi.encode(msg.sender));
    }

    // Filler then claims from origin chain once fill is proven
}
```

### Security Considerations

- **Proof mechanism**: The spec does not mandate a specific cross-chain proof system. Implementations use optimistic (7-day challenge period), ZK proof, or oracle-based approaches.
- **Fill deadline**: If a filler commits assets on the destination but proof fails, they may lose funds. Always verify proof mechanism latency vs fill deadline.
- **Output token mismatch**: Fillers must verify `originData` matches the actual `ResolvedCrossChainOrder` — do not trust the caller-supplied `originData` without verification.
- **Griefing**: An attacker can submit orders with unfavorable rates, wasting filler simulation costs.
- **Partial fills**: The spec does not mandate atomic fills — check whether the settlement contract supports partial fill scenarios.

---

## 10. Gasless Transactions

### ERC-2771 Meta-Transactions

```solidity
// Trusted forwarder contract
contract MinimalForwarder {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes   data;
    }

    mapping(address => uint256) private _nonces;

    function getNonce(address from) public view returns (uint256) { return _nonces[from]; }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"),
            req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)
        ))).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public payable returns (bool, bytes memory) {
        require(verify(req, signature), "invalid signature");
        _nonces[req.from]++;

        // Append original sender to calldata (ERC-2771 convention)
        (bool success, bytes memory result) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );
        return (success, result);
    }
}

// Recipient contract that understands ERC-2771
contract ERC2771Context {
    address private immutable _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    // Override _msgSender to unwrap meta-transaction sender
    function _msgSender() internal view virtual returns (address) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            return address(bytes20(msg.data[msg.data.length - 20:]));
        }
        return msg.sender;
    }
}
```

### Security Considerations for ERC-2771

- **Immutable trusted forwarder**: If the trusted forwarder is ever compromised or has a bug, all contracts trusting it are vulnerable. Do not use upgradeable forwarders.
- **Context confusion**: A contract that uses `_msgSender()` but is called directly by an EOA (not via forwarder) and the EOA's address ends in the trusted forwarder address — edge case but real. The standard requires `msg.sender == trustedForwarder` check before unwrapping.
- **Function selector clashing**: `executeWithForwarder` patterns where the target's function accepts arbitrary calldata can be abused if the relayer can choose calldata.
- **Gas griefing**: The `gas` field in ForwardRequest must be validated — set too low to intentionally revert, set too high to waste forwarder ETH. Add a gas buffer check: `gasleft() >= req.gas + 2300`.

### Native Gas Sponsorship (ERC-4337 Alternative)

Using ERC-4337 paymasters is strictly superior to ERC-2771 for new contracts because:
- No trusted forwarder security assumption
- Standard nonce management via EntryPoint
- Paymaster can apply arbitrary sponsorship logic
- Works with existing ERC-20 approvals for gas payment

---

## 11. Multicall Patterns

### Basic Multicall

```solidity
contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }

    function multicall(Call[] calldata calls)
        external returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.call(calls[i].callData);
            require(success, "call failed");
            results[i] = result;
        }
    }
}
```

### Delegatecall Multicall (same contract context)

```solidity
abstract contract MulticallBase {
    // Executes calls in the context of this contract (delegatecall)
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                // Bubble up the revert reason
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
            results[i] = result;
        }
    }
}
```

### Payable Multicall — The Safety Problem

```solidity
// DANGEROUS: msg.value is shared across all delegatecalls
// Each subcall sees the full msg.value
contract DangerousPayableMulticall {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        // If deposit() uses msg.value, calling it twice in the same multicall
        // would credit the user 2x the actual ETH sent
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
    }
}

// SAFE: Only allow payable multicall if exactly one call uses msg.value
// OR: track ETH usage across calls
contract SafePayableMulticall {
    bool private _inMulticall;

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        _inMulticall = true;
        uint256 remainingValue = msg.value;
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // Each subcall must specify its ETH usage explicitly
            // Use a separate encoded value per call rather than msg.value
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        require(address(this).balance >= 0); // verify no excess
        _inMulticall = false;
    }
}
```

### Multicall3 (Standard)

The deployed Multicall3 at `0xcA11bde05977b3631167028862bE2a173976CA11` on all major chains:

```solidity
struct Call3 {
    address target;
    bool allowFailure;
    bytes callData;
}
struct Result {
    bool success;
    bytes returnData;
}

function aggregate3(Call3[] calldata calls) external payable returns (Result[] memory results) {
    results = new Result[](calls.length);
    for (uint256 i = 0; i < calls.length; i++) {
        (results[i].success, results[i].returnData) = calls[i].target.call(calls[i].callData);
        if (!calls[i].allowFailure && !results[i].success) {
            assembly { revert(add(results[i].returnData, 0x20), mload(results[i].returnData)) }
        }
    }
}
```

### Security Considerations

- **Delegatecall multicall + self-referencing**: If `address(this)` is a proxy, delegatecall goes through the proxy's fallback — verify the call chain.
- **Reentrancy via multicall**: A delegatecall to a function that emits state changes, followed by another delegatecall, can create inconsistent state windows.
- **`msg.sender` in delegatecall**: The delegatecalled function sees `msg.sender` as the original EOA, not the contract — this is intentional but can cause access control issues if callers assume `msg.sender` is the contract.
- **Gas estimation**: Multicall gas estimation is unreliable; always add a buffer.

---

## 12. Modern Token Patterns

### ERC-20 with Hooks (ERC-777 Lessons)

ERC-777 introduced send/receive hooks that caused reentrancy vulnerabilities (e.g., the imBTC/Uniswap V1 attack). Modern patterns avoid arbitrary hooks, but some tokens implement targeted callbacks:

```solidity
// Safer: callback only to trusted recipients registered by the token holder
contract HookedToken is ERC20 {
    mapping(address => address) public hooks; // owner => hook contract

    function registerHook(address hook) external {
        hooks[msg.sender] = hook;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        address hook = hooks[to];
        if (hook != address(0)) {
            // CEI: state already updated before callback
            try ITokenHook(hook).onReceive(from, to, amount) {} catch {}
        }
    }
}
```

### Fee-on-Transfer Token Handling

Fee-on-transfer tokens (e.g., USDT on some chains, PAXG) reduce the received amount. Protocols must measure actual received amounts:

```solidity
library SafeTransferLib {
    function safeTransferFromWithReturn(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256 received) {
        uint256 balanceBefore = token.balanceOf(to);
        token.transferFrom(from, to, amount);
        received = token.balanceOf(to) - balanceBefore;
    }
}

contract FeeOnTransferAwareDEX {
    function addLiquidity(address token, uint256 amount) external {
        uint256 received = SafeTransferLib.safeTransferFromWithReturn(
            IERC20(token), msg.sender, address(this), amount
        );
        // Use `received`, not `amount`, for all subsequent accounting
        _mintShares(msg.sender, received);
    }
}
```

### Rebasing Token Integration

Rebasing tokens (e.g., stETH, aTokens) change holders' balances without transfers. Two approaches:

```solidity
// Approach 1: Wrapper (shares-based)
// Convert to a fixed-supply token representing underlying shares
// stETH → wstETH pattern

contract RebasingWrapper is ERC20 {
    IRebasingToken immutable underlying;

    function wrap(uint256 amount) external returns (uint256 shares) {
        shares = underlying.getSharesByPooledEth(amount); // or equivalent
        underlying.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, shares);
    }

    function unwrap(uint256 shares) external returns (uint256 amount) {
        amount = underlying.getPooledEthByShares(shares);
        _burn(msg.sender, shares);
        underlying.transfer(msg.sender, amount);
    }
}

// Approach 2: Use share balances directly
// Many protocols that support stETH store shares internally
// and only convert to/from rebasing amounts at entry/exit points
contract StethVault {
    IStETH constant steth = IStETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    mapping(address => uint256) public sharesOf;

    function deposit(uint256 stethAmount) external {
        steth.transferFrom(msg.sender, address(this), stethAmount);
        // Store shares, not rebasing amount
        sharesOf[msg.sender] += steth.getSharesByPooledEth(stethAmount);
    }

    function withdraw(uint256 shares) external {
        sharesOf[msg.sender] -= shares;
        uint256 stethAmount = steth.getPooledEthByShares(shares);
        steth.transfer(msg.sender, stethAmount);
    }
}
```

### Permit (ERC-2612)

```solidity
// EIP-2612 permit: approve via signature (no separate approve tx)
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v, bytes32 r, bytes32 s
) external {
    require(block.timestamp <= deadline, "expired");
    bytes32 structHash = keccak256(abi.encode(
        PERMIT_TYPEHASH,
        owner, spender, value,
        _useNonce(owner), // increment nonce
        deadline
    ));
    address signer = ECDSA.recover(_hashTypedDataV4(structHash), v, r, s);
    require(signer == owner, "invalid signer");
    _approve(owner, spender, value);
}
```

### Security Considerations

- **Fee-on-transfer + Permit2**: Permit2 pulls `amount` but the vault receives `amount - fee`. Always measure post-transfer balance, not the permit amount.
- **Rebasing in AMMs**: Standard AMM math breaks if reserves change without trades. AMMs that accept rebasing tokens (like Balancer's boosted pools) require special pool math.
- **ERC-2612 permit front-running**: A permit signature broadcast in the mempool can be front-run and used to set an allowance before the intended transaction. The intended call should be atomic with the permit (e.g., in the same contract call). If front-run and the intended call still succeeds (now using the allowance path), no harm done — design for idempotency.
- **Nonce invalidation**: `nonces[owner]++` happens on any successful `permit` call. If the owner calls `permit` twice, the second becomes invalid. Use this deliberately to cancel outstanding permit signatures.
- **DOMAIN_SEPARATOR caching**: If the contract is deployed via a proxy that changes address, or if `chainId` changes (e.g., L2 reorg), cached domain separators become invalid. Recompute if `block.chainid != _CACHED_CHAIN_ID`.

---

## Cross-Pattern Integration: Complete DeFi Stack Example

```solidity
// A vault that accepts gasless deposits via Permit2, issues ERC-4626 shares,
// and uses ERC-6909 internally for sub-strategy accounting

contract ModernVault is ERC4626, ERC6909, ERC2771Context {
    IPermit2 immutable permit2;

    constructor(
        IERC20 asset,
        address trustedForwarder,
        address _permit2
    ) ERC4626(asset) ERC2771Context(trustedForwarder) {
        permit2 = IPermit2(_permit2);
    }

    // Gasless deposit: user signs both a Permit2 transfer and a deposit intent
    // Relayer submits, paying gas
    function permitDeposit(
        ISignatureTransfer.PermitTransferFrom calldata permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        bytes calldata sig
    ) external returns (uint256 shares) {
        address user = _msgSender(); // unwraps forwarder if present
        // Permit2 pulls tokens from user to this vault
        permit2.permitTransferFrom(permit, transferDetails, user, sig);
        // Issue ERC-4626 shares to user (tokens already in vault)
        shares = _convertToShares(transferDetails.requestedAmount, Math.Rounding.Floor);
        _mint(user, shares);
        emit Deposit(user, user, transferDetails.requestedAmount, shares);
    }

    // Allocate to a sub-strategy tracked by ERC-6909 ID
    function allocateToStrategy(uint256 strategyId, uint256 shareAmount) external {
        _burn(msg.sender, shareAmount);       // burn ERC-4626 shares
        _mint(msg.sender, strategyId, shareAmount); // mint ERC-6909 strategy tokens
        // Route underlying assets to strategy
    }
}
```

---

## Quick Reference: Deployment Addresses

| Contract | Network | Address |
|---|---|---|
| Permit2 | All major | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| Multicall3 | All major | `0xcA11bde05977b3631167028862bE2a173976CA11` |
| ERC-4337 EntryPoint v0.7 | All major | `0x0000000071727De22E5E9d8BAf0edAc6f37da032` |
| Uniswap V4 PoolManager | Mainnet | `0x000000000004444c5dc75cB358380D2e3dE08A90` |

---

## Audit Checklist for Novel Patterns

### ERC-6909
- [ ] Infinite allowance (max uint256) handled correctly
- [ ] Operator vs per-ID allowance precedence is correct
- [ ] Transfer to address(0) behavior is defined

### V4 Hooks
- [ ] Hook address bits match implementation flags
- [ ] All hook functions guarded by `onlyPoolManager`
- [ ] Delta-returning hooks implement correct math
- [ ] `hookData` treated as untrusted

### Transient Storage
- [ ] Slots are uniquely derived (no collision between modules)
- [ ] Transient state is never depended upon across transactions
- [ ] Solidity version >= 0.8.24 or assembly is correct

### Permit2
- [ ] `msg.sender` is the spender in `permitTransferFrom`
- [ ] Witness data used when permit should be order-specific
- [ ] Fee-on-transfer tokens measured post-transfer

### ERC-4626
- [ ] Virtual shares/assets prevent inflation attack
- [ ] Rounding direction: deposit/mint round down shares, withdraw/redeem round up shares
- [ ] Fee-on-transfer assets measured via balance delta

### ERC-4337
- [ ] `validateUserOp` only accessed account-associated storage
- [ ] Paymaster validates all fields that affect gas cost
- [ ] Session key time bounds enforced via validationData packing

### ERC-7702
- [ ] Authorization includes chain_id
- [ ] Delegated contract does not use SELFDESTRUCT
- [ ] Storage layout is compatible across delegation changes

### ERC-2771
- [ ] Trusted forwarder is immutable
- [ ] `_msgSender()` unwrapping only occurs when `msg.sender == trustedForwarder`
- [ ] Gas forwarding buffer (2300) is added

### Multicall
- [ ] Payable multicall does not allow msg.value double-spend
- [ ] Delegatecall targets are whitelisted or self-only
- [ ] Reentrancy guards are not bypassed by delegatecall
