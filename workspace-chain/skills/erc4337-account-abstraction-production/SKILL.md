# ERC-4337 Account Abstraction — Production Stack

## Architecture

```
User → Frontend → Bundler (Pimlico/Alchemy/Stackup)
                      ↓
              EntryPoint (0x000...7032)
                      ↓
              Smart Account (ZeroDev Kernel / Safe AA)
                      ↓
              Paymaster (optional: sponsor gas)
```

## Deploy a Smart Account (ZeroDev Kernel)

```typescript
import { createKernelAccount, createKernelAccountClient, createZeroDevPaymasterClient } from "@zerodev/sdk";
import { signerToEcdsaValidator } from "@zerodev/ecdsa-validator";
import { ENTRYPOINT_ADDRESS_V07 } from "permissionless";
import { createPublicClient, http } from "viem";
import { base } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const ENTRYPOINT = "0x0000000071727De22E5E9d8BAf0edAc6f37da032"; // v0.7
const ZERODEV_PROJECT_ID = process.env.ZERODEV_PROJECT_ID!;

const publicClient = createPublicClient({ chain: base, transport: http() });

// Signer — in production: Ledger, WalletConnect, Passkey
const signer = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);

// Build smart account
const ecdsaValidator = await signerToEcdsaValidator(publicClient, {
  signer,
  entryPoint: ENTRYPOINT,
});

const account = await createKernelAccount(publicClient, {
  plugins: { sudo: ecdsaValidator },
  entryPoint: ENTRYPOINT,
});

console.log("Smart Account:", account.address);
// Address is deterministic — same signer = same address across all chains

// Create account client (with paymaster = gasless)
const paymasterClient = createZeroDevPaymasterClient({
  chain: base,
  transport: http(`https://rpc.zerodev.app/api/v2/paymaster/${ZERODEV_PROJECT_ID}`),
});

const kernelClient = createKernelAccountClient({
  account,
  chain: base,
  entryPoint: ENTRYPOINT,
  bundlerTransport: http(`https://rpc.zerodev.app/api/v2/bundler/${ZERODEV_PROJECT_ID}`),
  middleware: {
    sponsorUserOperation: paymasterClient.sponsorUserOperation, // gasless txs
  },
});

// Send gasless transaction
const txHash = await kernelClient.sendTransaction({
  to: "0xRecipient",
  value: 0n,
  data: "0x",
});
console.log("Tx:", txHash);
```

## Session Keys (No Popup UX)

```typescript
import { toPermissionValidator } from "@zerodev/permissions";
import { toECDSASigner } from "@zerodev/permissions/signers";
import { toCallPolicy, toTimestampPolicy, toRateLimitPolicy } from "@zerodev/permissions/policies";

// Generate one-time session key (lives in browser storage)
const sessionPrivateKey = generatePrivateKey();
const sessionKeySigner = privateKeyToAccount(sessionPrivateKey);

// Define what the session key is allowed to do
const callPolicy = toCallPolicy({
  permissions: [{
    target: SPARTA_CONTRACT_ADDRESS,       // Only this contract
    valueLimit: 0n,                        // No ETH transfers
    functionName: "submitAnswer",          // Only this function
  }],
});

const timePolicy = toTimestampPolicy({
  validUntil: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60, // 7 days
});

const rateLimitPolicy = toRateLimitPolicy({
  count: 10,           // Max 10 submissions
  interval: 86400,     // Per 24 hours
});

// Approve session key (one user signature required)
const sessionKeyValidator = await toPermissionValidator(publicClient, {
  entryPoint: ENTRYPOINT,
  signer: toECDSASigner({ signer: sessionKeySigner }),
  policies: [callPolicy, timePolicy, rateLimitPolicy],
});

const sessionKeyAccount = await createKernelAccount(publicClient, {
  plugins: {
    sudo:    ecdsaValidator,   // Master key
    regular: sessionKeyValidator, // Session key
  },
  entryPoint: ENTRYPOINT,
});

// After approval: dapp can submit txs without user signature
const sessionClient = createKernelAccountClient({
  account: sessionKeyAccount,
  // ...bundler config
});

await sessionClient.sendTransaction({
  to: SPARTA_CONTRACT_ADDRESS,
  data: encodeFunctionData({ abi, functionName: "submitAnswer", args: [challengeId, answerHash] }),
});
// User is NOT prompted — session key signs automatically
```

## Paymaster (Sponsor User Gas)

```solidity
// VerifyingPaymaster.sol — only sponsors approved dapp calls
contract SpartaPaymaster is BasePaymaster {
    mapping(address => bool) public approvedContracts;
    mapping(address => uint256) public dailySpend;
    uint256 public constant MAX_DAILY_SPEND = 0.01 ether; // per user

    constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32,
        uint256 maxCost
    ) internal view override returns (bytes memory context, uint256 validationData) {
        // Decode the calldata to check which contract is being called
        (address target,) = abi.decode(userOp.callData[4:], (address, bytes));

        require(approvedContracts[target], "Contract not approved for sponsorship");
        require(dailySpend[userOp.sender] + maxCost <= MAX_DAILY_SPEND, "Daily limit exceeded");

        return (abi.encode(userOp.sender, maxCost), 0); // 0 = valid
    }

    function _postOp(PostOpMode, bytes calldata context, uint256 actualGasCost, uint256) internal override {
        (address user, ) = abi.decode(context, (address, uint256));
        dailySpend[user] += actualGasCost;
    }
}
```

```bash
# Fund the paymaster at EntryPoint
cast send $ENTRYPOINT "depositTo(address)" $PAYMASTER_ADDRESS \
  --value 0.1ether --rpc-url $BASE_RPC --private-key $KEY
```

## Production Bundler Config (Self-Hosted)

```bash
# Using Rundler (Alchemy's Rust bundler — most performant)
docker run -p 3000:3000 alchemyplatform/rundler:latest \
  --network base \
  --node-http $BASE_RPC \
  --entry-points 0x0000000071727De22E5E9d8BAf0edAc6f37da032 \
  --max-verification-gas 5000000 \
  --max-bundle-size 10
```

## EntryPoint Addresses

```
EntryPoint v0.6: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
EntryPoint v0.7: 0x0000000071727De22E5E9d8BAf0edAc6f37da032 ← use this
```
