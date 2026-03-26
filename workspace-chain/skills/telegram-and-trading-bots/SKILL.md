# Telegram & Trading Bots

## Architecture Overview

```
User (Telegram) → Bot API → Backend Server → Blockchain
                                  ↓
                         Embedded Wallet (per-user)
                         Encrypted in DB
                                  ↓
                         Uniswap Router → DEX → Token
```

## Wallet Generation & Security

```typescript
import { ethers, HDNodeWallet } from "ethers";
import CryptoJS from "crypto-js";

class WalletManager {
    // Master HD wallet (never exposed) — derives user wallets
    private masterMnemonic: string = process.env.MASTER_MNEMONIC!;
    private masterKey: string = process.env.ENCRYPTION_KEY!;

    // Derive deterministic wallet from user's Telegram ID
    getUserWallet(telegramUserId: number): HDNodeWallet {
        const masterNode = ethers.HDNodeWallet.fromPhrase(this.masterMnemonic);
        // Derive path: m/44'/60'/0'/0/{userId}
        return masterNode.derivePath(`m/44'/60'/0'/0/${telegramUserId}`);
    }

    // Encrypt private key for DB storage (never store plaintext)
    encryptPrivateKey(privateKey: string): string {
        return CryptoJS.AES.encrypt(privateKey, this.masterKey).toString();
    }

    decryptPrivateKey(encrypted: string): string {
        return CryptoJS.AES.decrypt(encrypted, this.masterKey).toString(CryptoJS.enc.Utf8);
    }

    // CRITICAL: master mnemonic stored in HSM or AWS KMS, never on server disk
}
```

## Token Swap Execution

```typescript
import { ethers } from "ethers";

const UNISWAP_V2_ROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const ROUTER_ABI = [/* ... */];

async function swapExactETHForTokens(
    tokenAddress: string,
    ethAmount: string,
    slippagePct: number,
    wallet: ethers.Wallet
) {
    const router = new ethers.Contract(UNISWAP_V2_ROUTER, ROUTER_ABI, wallet);
    const provider = wallet.provider!;

    // Get expected output
    const amountIn = ethers.parseEther(ethAmount);
    const path = [await router.WETH(), tokenAddress];
    const amounts = await router.getAmountsOut(amountIn, path);
    const amountOutMin = amounts[1] * BigInt(100 - slippagePct) / 100n;

    // Gas estimate with buffer
    const gasEstimate = await router.swapExactETHForTokens.estimateGas(
        amountOutMin, path, wallet.address, Date.now() + 60_000,
        { value: amountIn }
    );

    // Get fast gas price
    const feeData   = await provider.getFeeData();
    const gasPrice  = feeData.maxFeePerGas! * 120n / 100n; // 20% buffer

    const tx = await router.swapExactETHForTokens(
        amountOutMin,
        path,
        wallet.address,
        Date.now() + 60_000,
        {
            value:       amountIn,
            gasLimit:    gasEstimate * 120n / 100n,
            maxFeePerGas: gasPrice,
        }
    );

    return tx;
}
```

## Telegram Bot Handler

```typescript
import TelegramBot from "node-telegram-bot-api";

const bot = new TelegramBot(process.env.BOT_TOKEN!, { polling: true });

// /buy 0xTokenAddress 0.1
bot.onText(/\/buy (.+) (.+)/, async (msg, match) => {
    const userId  = msg.from!.id;
    const token   = match![1];
    const ethAmt  = match![2];

    // Validate token address
    if (!ethers.isAddress(token)) {
        return bot.sendMessage(msg.chat.id, "❌ Invalid token address");
    }

    const keyboard = {
        inline_keyboard: [[
            { text: "✅ Confirm Buy", callback_data: `confirm_buy:${token}:${ethAmt}` },
            { text: "❌ Cancel",      callback_data: "cancel" }
        ]]
    };

    // Show token info before confirming
    const info = await getTokenInfo(token);
    bot.sendMessage(msg.chat.id,
        `*Buy Confirmation*\n\n` +
        `Token: ${info.name} (${info.symbol})\n` +
        `Amount: ${ethAmt} ETH\n` +
        `Expected: ~${info.expectedOut} tokens\n` +
        `Slippage: 1%\n\n` +
        `⚠️ You are about to execute a trade. Confirm?`,
        { parse_mode: "Markdown", reply_markup: keyboard }
    );
});

bot.on("callback_query", async (query) => {
    const [action, ...params] = query.data!.split(":");

    if (action === "confirm_buy") {
        const [token, ethAmt] = params;
        const wallet = walletManager.getUserWallet(query.from.id);

        try {
            const tx = await swapExactETHForTokens(token, ethAmt, 1, wallet);
            await bot.sendMessage(query.message!.chat.id,
                `✅ Swap submitted!\nTx: [View on BaseScan](https://basescan.org/tx/${tx.hash})`,
                { parse_mode: "Markdown" }
            );
            // Wait for confirmation
            const receipt = await tx.wait();
            await bot.sendMessage(query.message!.chat.id,
                `🎉 Swap confirmed in block ${receipt!.blockNumber}`
            );
        } catch (e: any) {
            bot.sendMessage(query.message!.chat.id, `❌ Failed: ${e.message}`);
        }
    }
});
```

## Sniper Bot Logic

```typescript
class SniperBot {
    provider: ethers.WebSocketProvider;

    constructor() {
        // WebSocket for real-time pending tx monitoring
        this.provider = new ethers.WebSocketProvider(process.env.WS_RPC!);
    }

    async monitor() {
        const uniFactory = new ethers.Contract(UNISWAP_V2_FACTORY, FACTORY_ABI, this.provider);

        // Listen for new pair creation events
        uniFactory.on("PairCreated", async (token0, token1, pair) => {
            const newToken = token0 === WETH ? token1 : token0;

            // Quick checks (run in < 1 second)
            const isHoneypot = await this.checkHoneypot(newToken);
            if (isHoneypot) return console.log(`Honeypot detected: ${newToken}`);

            const taxRate = await this.getTaxRate(newToken);
            if (taxRate > 10) return console.log(`Tax too high: ${taxRate}%`);

            // Execute snipe
            console.log(`Sniping ${newToken}...`);
            const tx = await swapExactETHForTokens(newToken, "0.1", 20, sniperWallet);
            console.log(`Snipe submitted: ${tx.hash}`);
        });
    }

    async checkHoneypot(token: string): Promise<boolean> {
        // Simulate a buy + sell using eth_call
        // If sell fails → honeypot
        try {
            await simulateSell(token);
            return false;
        } catch {
            return true;
        }
    }
}
```

## Revenue Model & Security

```
Revenue: 1% fee on each swap → $100K daily volume → $1K/day
         Competes with: Maestro (1%), BananaGun (0.5%), Unibot (1%)

CRITICAL Security:
- All private keys encrypted with AES-256 using master key
- Master key in AWS KMS (never on disk)
- Rate limiting: max 10 txs/hour per user
- Withdrawal 2FA: require confirmation for transfers > $100
- Audit log: every transaction signed and stored
- NO LOGGING of private keys, mnemonics, or sensitive data
- Emergency pause: if unusual activity detected, pause all trades
```
