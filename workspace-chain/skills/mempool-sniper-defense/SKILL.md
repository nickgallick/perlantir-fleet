# Mempool Sniper Defense

## Production Bot Defense Script

```typescript
// scripts/sniper-defense.ts
// Run immediately after enableTrading() — monitors first 30 blocks

import { ethers, WebSocketProvider, Contract, Wallet } from "ethers";
import axios from "axios";

const CONFIG = {
    TOKEN_ADDRESS:     process.env.TOKEN_ADDRESS!,
    PAIR_ADDRESS:      process.env.PAIR_ADDRESS!,
    DEPLOYER_KEY:      process.env.PRIVATE_KEY!,
    WS_RPC:            process.env.WS_RPC!,          // Alchemy/Infura WebSocket
    RPC_URL:           process.env.BASE_RPC!,
    ETHERSCAN_KEY:     process.env.BASESCAN_KEY!,
    TRADING_BLOCK:     parseInt(process.env.TRADING_BLOCK!),
    BLACKLIST_BLOCKS:  30,   // Monitor for 30 blocks (~60s on Base)
    PRIORITY_GAS:      2,    // Multiplier over base fee for blacklist tx
};

const TOKEN_ABI = [
    "function blacklistBot(address account, bool status) external",
    "event Transfer(address indexed from, address indexed to, uint256 value)",
];

const PAIR_ABI = [
    "event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to)",
];

// Track funding sources for multi-wallet detection
const fundingCache = new Map<string, string>(); // address → funder
const blacklisted   = new Set<string>();
const flaggedForReview = new Set<string>();

async function main() {
    const provider = new WebSocketProvider(CONFIG.WS_RPC);
    const wallet   = new Wallet(CONFIG.DEPLOYER_KEY, provider);
    const token    = new Contract(CONFIG.TOKEN_ADDRESS, TOKEN_ABI, wallet);
    const pair     = new Contract(CONFIG.PAIR_ADDRESS, PAIR_ABI, provider);

    let currentBlock = await provider.getBlockNumber();
    const stopBlock  = CONFIG.TRADING_BLOCK + CONFIG.BLACKLIST_BLOCKS;

    console.log(`[DEFENSE] Active. Trading block: ${CONFIG.TRADING_BLOCK}, Stop: ${stopBlock}`);

    // ── PATTERN 1: Block 0/1 auto-blacklist ─────────────────────────────
    pair.on("Swap", async (sender, a0In, a1In, a0Out, a1Out, to, event) => {
        currentBlock = event.log.blockNumber;

        if (currentBlock > stopBlock) {
            console.log("[DEFENSE] Monitoring window closed.");
            pair.removeAllListeners();
            return;
        }

        const buyer = to.toLowerCase();

        // Already handled
        if (blacklisted.has(buyer)) return;

        // Block 0 or 1 — almost certainly a bot
        const isFirstBlocks = currentBlock <= CONFIG.TRADING_BLOCK + 1;
        if (isFirstBlocks && buyer !== wallet.address.toLowerCase()) {
            console.log(`[SNIPER] Block ${currentBlock} buyer: ${buyer} — AUTO BLACKLIST`);
            await _blacklist(token, buyer, "Block 0/1 sniper");
            return;
        }

        // ── PATTERN 3: Multi-wallet check ────────────────────────────────
        const funder = await _getFunder(buyer, provider);
        if (funder) {
            fundingCache.set(buyer, funder);

            // Check if another buyer shares the same funder
            for (const [otherAddr, otherFunder] of fundingCache) {
                if (otherAddr !== buyer && otherFunder === funder && blacklisted.has(otherAddr)) {
                    console.log(`[COORDINATED] ${buyer} funded by same source as blacklisted ${otherAddr}`);
                    await _blacklist(token, buyer, "Coordinated wallet");
                    return;
                }
            }
        }

        // ── PATTERN 4: Large buy (>1% of supply in single tx) ─────────────
        // a1Out = token amount out (if token is token1 in the pair)
        const largeThreshold = ethers.parseEther("10000000"); // 1% of 1B
        if (a1Out > largeThreshold || a0Out > largeThreshold) {
            console.log(`[WHALE] Large buy detected: ${buyer}`);
            flaggedForReview.add(buyer);
            await _alert(`WHALE BUY: ${buyer} | Block: ${currentBlock}`);
        }

        console.log(`[SWAP] Block ${currentBlock} | Buyer: ${buyer.slice(0,8)}... | OK`);
    });

    // ── PATTERN 2: Sandwich detection (same address, buy+sell same block) ─
    const blockBuyers = new Map<number, Map<string, number>>(); // block → address → txCount

    provider.on("block", async (blockNum) => {
        if (blockNum > stopBlock) return;

        const block = await provider.getBlock(blockNum, true);
        if (!block?.transactions) return;

        const txMap = new Map<string, number>();
        for (const tx of block.transactions as ethers.TransactionResponse[]) {
            if (!tx.to) continue;
            const count = (txMap.get(tx.from.toLowerCase()) ?? 0) + 1;
            txMap.set(tx.from.toLowerCase(), count);
        }

        // Multiple txs from same address in same block = potential sandwich
        for (const [addr, count] of txMap) {
            if (count >= 2 && !blacklisted.has(addr)) {
                console.log(`[SANDWICH] ${addr} had ${count} txs in block ${blockNum}`);
                await _blacklist(token, addr, "Sandwich pattern");
            }
        }
    });

    // Keep alive
    await new Promise(() => {});
}

async function _blacklist(token: Contract, address: string, reason: string) {
    if (blacklisted.has(address)) return;
    blacklisted.add(address);

    try {
        const feeData = await token.runner!.provider!.getFeeData();
        const maxFee  = feeData.maxFeePerGas! * BigInt(CONFIG.PRIORITY_GAS);

        const tx = await token.blacklistBot(address, true, {
            maxFeePerGas: maxFee,
            maxPriorityFeePerGas: maxFee,
        });

        console.log(`[BLACKLISTED] ${address} | Reason: ${reason} | TX: ${tx.hash}`);
        await _alert(`BLACKLISTED: ${address}\nReason: ${reason}\nTx: ${tx.hash}`);
    } catch (e: any) {
        console.error(`[ERROR] Failed to blacklist ${address}: ${e.message}`);
    }
}

async function _getFunder(address: string, provider: WebSocketProvider): Promise<string | null> {
    if (fundingCache.has(address)) return fundingCache.get(address)!;
    try {
        const r = await axios.get(`https://api.basescan.org/api`, {
            params: { module: "account", action: "txlist", address, sort: "asc",
                      page: 1, offset: 5, apikey: CONFIG.ETHERSCAN_KEY }
        });
        const txs = r.data.result;
        if (!Array.isArray(txs) || txs.length === 0) return null;
        const firstFund = txs.find((t: any) => t.to.toLowerCase() === address.toLowerCase());
        return firstFund?.from?.toLowerCase() ?? null;
    } catch { return null; }
}

async function _alert(message: string) {
    console.log(`[ALERT] ${message}`);
    // In production: POST to Telegram bot, Discord webhook, PagerDuty
    // const tgToken = process.env.TG_BOT_TOKEN;
    // const tgChat  = process.env.TG_CHAT_ID;
    // await axios.post(`https://api.telegram.org/bot${tgToken}/sendMessage`, { chat_id: tgChat, text: message });
}

main().catch(console.error);
```

## Graduated Tax (Contract-Level Defense)

```solidity
// In MemeCoin._getCurrentTaxRate()
// Blocks 0-5:  99% — snipers lose everything
// Blocks 6-10: 50%
// Blocks 11-20: 25%
// Block 21+:   Normal (5%)

function _getCurrentTaxRate(bool isBuy) internal view returns (uint256) {
    if (!tradingEnabled) return 0;
    uint256 elapsed = block.number - launchBlock;
    if (elapsed <= 5)  return 99;
    if (elapsed <= 10) return 50;
    if (elapsed <= 20) return 25;
    return isBuy ? buyTaxBps / 100 : sellTaxBps / 100;
}
```

## Running Instructions

```bash
# Set env vars
export TOKEN_ADDRESS=0x...
export PAIR_ADDRESS=0x...
export PRIVATE_KEY=0x...
export WS_RPC=wss://base-mainnet.g.alchemy.com/v2/YOUR_KEY
export BASE_RPC=https://mainnet.base.org
export BASESCAN_KEY=YOUR_KEY
export TRADING_BLOCK=12345678  # Block where you called enableTrading()

# Start defense immediately after enableTrading() tx confirms
npx ts-node scripts/sniper-defense.ts
```
