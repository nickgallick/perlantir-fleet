# Account Abstraction (ERC-4337)

## What It Solves
EOAs require ETH for gas, MetaMask for signing, one-click-per-tx. AA fixes all three:
- **Gasless**: Paymasters sponsor gas (user pays in USDC or nothing)
- **Social login**: Smart wallet derived from email/passkey, no seed phrase
- **Batch tx**: Multiple operations in single UserOperation
- **Session keys**: Temporary approval for specific actions (agent can act without per-tx user approval)
- **Custom logic**: Spend limits, multi-sig, social recovery built into the wallet

## ERC-4337 Architecture

```
User signs UserOperation
       ↓
Bundler picks up UserOp from alt mempool
       ↓
Bundler calls EntryPoint.handleOps()
       ↓
EntryPoint calls wallet.validateUserOp()  ← wallet validates signature
       ↓
EntryPoint calls Paymaster.validatePaymasterUserOp() (if paymaster used)
       ↓
EntryPoint calls wallet.execute() ← actual transaction
       ↓
Paymaster.postOp() ← for post-execution logic
```

## UserOperation Structure
```solidity
struct UserOperation {
    address sender;              // The smart wallet address
    uint256 nonce;               // Replay protection
    bytes initCode;              // Deploy wallet if not yet deployed
    bytes callData;              // What to execute (encoded function call)
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;      // Optional paymaster address + data
    bytes signature;             // User's signature
}
```

## Minimal Smart Wallet Implementation
```solidity
contract SimpleWallet is IAccount {
    address public owner;
    IEntryPoint public immutable entryPoint;

    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "Not EntryPoint");
        _;
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256 validationData) {
        // Verify signature
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        require(owner == hash.recover(userOp.signature), "Invalid sig");

        // Pay EntryPoint if needed
        if (missingAccountFunds > 0) {
            (bool ok,) = payable(address(entryPoint)).call{value: missingAccountFunds}("");
            require(ok);
        }

        return 0; // 0 = valid, 1 = invalid
    }

    function execute(address target, uint256 value, bytes calldata data) external onlyEntryPoint {
        (bool ok, bytes memory result) = target.call{value: value}(data);
        if (!ok) {
            assembly { revert(add(result, 32), mload(result)) }
        }
    }
}
```

## Paymaster (Sponsor Gas)
```solidity
contract SponsoringPaymaster is IPaymaster {
    IEntryPoint public immutable entryPoint;
    address public owner;

    // Sponsor all valid userOps from our app
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external onlyEntryPoint returns (bytes memory context, uint256 validationData) {
        // Verify this userOp is for our app
        bytes4 selector = bytes4(userOp.callData[0:4]);
        require(allowedSelectors[selector], "Not allowed");

        // Fund from paymaster deposit
        return ("", 0);
    }

    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external onlyEntryPoint {}

    // Owner deposits ETH for gas sponsorship
    receive() external payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }
}
```

## Session Keys
User approves "enter challenges" once → agent submits entries without per-tx approval:
```solidity
struct SessionKey {
    address key;            // Temporary key address
    uint256 expiry;         // When permission expires
    bytes4[] allowedFuncs;  // Which functions can be called
    address[] allowedTo;    // Which contracts can be called
    uint256 maxValue;       // Max ETH per call
}

mapping(bytes32 => SessionKey) public sessions;

function addSessionKey(SessionKey calldata session) external onlyOwner {
    sessions[keccak256(abi.encode(session.key))] = session;
}

function validateUserOp(...) external returns (uint256) {
    address signer = recoverSigner(userOp.signature, userOpHash);

    if (signer == owner) return 0; // Full access

    // Check session key permissions
    SessionKey storage session = sessions[keccak256(abi.encode(signer))];
    require(block.timestamp < session.expiry, "Session expired");
    require(isAllowed(session, userOp.callData, userOp.callGasLimit), "Not permitted");
    return 0;
}
```

## SDKs & Providers

| Provider | Best For | Notes |
|----------|----------|-------|
| **Privy** | Consumer apps, social login | Email/Google/Apple → embedded wallet. Best onboarding UX. |
| **ZeroDev** | ERC-4337 SDK | Great session key support, modular kernel |
| **Biconomy** | Gasless + paymaster infra | Multi-chain paymaster dashboard |
| **Alchemy Account Kit** | Full-stack AA | Account, bundler, paymaster in one SDK |
| **Safe** | Multi-sig, institutional | Most battle-tested, highest security |

## Relevance for Agent Sparta
1. **No ETH needed**: Paymaster pays gas in ETH, user pays nothing or in USDC
2. **One-click onboarding**: Privy social login → embedded smart wallet, no MetaMask
3. **Session keys**: User approves "enter challenges for me up to $50/day, expire in 7 days" → AI can submit entries automatically
4. **Batch entries**: Enter 3 challenges in one transaction instead of three separate ones
