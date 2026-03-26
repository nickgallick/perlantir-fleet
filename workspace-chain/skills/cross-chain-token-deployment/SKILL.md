# Cross-Chain Token Deployment

## LayerZero OFT (Omnichain Fungible Token)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Deploy THIS contract on every chain
// Same source code, same salt → same address everywhere (via CREATE2)
contract SpartaToken is OFT, Ownable {
    uint256 public constant TOTAL_SUPPLY = 100_000_000 * 1e18; // 100M

    // Minted ONLY on the "home chain" (e.g., Ethereum mainnet)
    // Other chains: mint 0, supply comes from cross-chain transfers
    constructor(
        address lzEndpoint,  // LayerZero endpoint for this chain
        address delegate,
        bool isHomeChain
    )
        OFT("Sparta Token", "SPARTA", lzEndpoint, delegate)
        Ownable(delegate)
    {
        if (isHomeChain) {
            _mint(msg.sender, TOTAL_SUPPLY);
        }
        // Non-home chains: no mint — supply bridged from home chain
    }
}

// Cross-chain transfer: burn on source, mint on destination
// User calls: oft.send(SendParam({dstEid, to, amountLD, ...}), fee, refundAddress)
```

## OFT Bridge Frontend

```typescript
import { Options } from "@layerzerolabs/lz-v2-utilities";
import { ethers } from "ethers";

const OFT_ABI = [/* ... */];

async function bridgeTokens(
    oftAddress: string,
    dstChainId: number,  // LayerZero Endpoint ID (e.g., 30184 = Base)
    recipient: string,
    amount: bigint,
    signer: ethers.Signer
) {
    const oft = new ethers.Contract(oftAddress, OFT_ABI, signer);

    // Encode recipient as bytes32
    const toBytes32 = ethers.zeroPadValue(recipient, 32);

    // Estimate fee
    const options = Options.newOptions().addExecutorLzReceiveOption(200_000, 0).toHex();
    const sendParam = {
        dstEid:     dstChainId,
        to:         toBytes32,
        amountLD:   amount,
        minAmountLD: amount * 99n / 100n, // 1% slippage tolerance
        extraOptions: options,
        composeMsg:  "0x",
        oftCmd:      "0x"
    };

    const [nativeFee] = await oft.quoteSend(sendParam, false);

    // Execute bridge
    const tx = await oft.send(
        sendParam,
        { nativeFee, lzTokenFee: 0n },
        signer.address,
        { value: nativeFee }
    );

    return tx;
}
```

## Deterministic Deployment (Same Address Everywhere)

```typescript
import { create2Deploy } from "./create2";

// Deploy SpartaToken at THE SAME ADDRESS on all chains
const DEPLOYMENT_SALT = ethers.keccak256(ethers.toUtf8Bytes("sparta-token-v1"));

const CHAINS = [
    { name: "Ethereum",  rpc: process.env.ETH_RPC!,  lzEndpoint: "0x1a44076050125825900e736c501f859c50fE728c", isHome: true  },
    { name: "Base",      rpc: process.env.BASE_RPC!,  lzEndpoint: "0x1a44076050125825900e736c501f859c50fE728c", isHome: false },
    { name: "Arbitrum",  rpc: process.env.ARB_RPC!,   lzEndpoint: "0x3c2269811836af69497E5F486A85D7316753cf62", isHome: false },
    { name: "Optimism",  rpc: process.env.OPT_RPC!,   lzEndpoint: "0x3c2269811836af69497E5F486A85D7316753cf62", isHome: false },
];

for (const chain of CHAINS) {
    const provider = new ethers.JsonRpcProvider(chain.rpc);
    const signer   = new ethers.Wallet(process.env.DEPLOYER_KEY!, provider);

    const constructorArgs = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "address", "bool"],
        [chain.lzEndpoint, signer.address, chain.isHome]
    );

    const address = await create2Deploy(
        signer,
        SpartaToken.bytecode + constructorArgs.slice(2),
        DEPLOYMENT_SALT
    );

    console.log(`${chain.name}: ${address}`);
}
// All chains: same address ✅ — users can verify across explorers
```

## Supply Accounting Verification

```typescript
// Run periodically to verify total supply is conserved across all chains
async function verifyCrossChainSupply(oftAddresses: Record<string, string>) {
    let totalSupply = 0n;

    for (const [chainName, address] of Object.entries(oftAddresses)) {
        const provider = getProvider(chainName);
        const oft = new ethers.Contract(address, OFT_ABI, provider);
        const supply = await oft.totalSupply();
        console.log(`${chainName}: ${ethers.formatEther(supply)} SPARTA`);
        totalSupply += supply;
    }

    const EXPECTED = ethers.parseEther("100000000"); // 100M
    if (totalSupply !== EXPECTED) {
        console.error(`SUPPLY MISMATCH: ${ethers.formatEther(totalSupply)} != ${ethers.formatEther(EXPECTED)}`);
        // Alert: Forta bot, PagerDuty, Telegram notification
    } else {
        console.log("✅ Supply verified: 100M SPARTA across all chains");
    }
}
```

## Rate-Limiting Bridge for Security

```solidity
contract RateLimitedOFT is OFT {
    uint256 public constant MAX_BRIDGE_PER_DAY = 1_000_000 * 1e18; // 1M tokens/day
    uint256 public dailyBridged;
    uint256 public lastResetDay;

    function _debitView(uint256 amountLD, ...) internal override view returns (...) {
        // Rate limit check
        uint256 today = block.timestamp / 1 days;
        uint256 bridgedToday = today == lastResetDay ? dailyBridged : 0;
        require(bridgedToday + amountLD <= MAX_BRIDGE_PER_DAY, "Bridge rate limit");
        return super._debitView(amountLD, ...);
    }

    function _debit(uint256 amountLD, ...) internal override returns (...) {
        uint256 today = block.timestamp / 1 days;
        if (today != lastResetDay) { dailyBridged = 0; lastResetDay = today; }
        dailyBridged += amountLD;
        return super._debit(amountLD, ...);
    }
}
```
