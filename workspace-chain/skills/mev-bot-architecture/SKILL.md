# MEV Bot Architecture

## Why Chain Needs This Knowledge
Not to profit from MEV. To design protocols that RESIST it. Every attack vector here is a defense requirement.

## Sandwich Bot (Full Architecture)

```typescript
import { WebSocketProvider, parseUnits, formatUnits } from 'viem'
import { FlashbotsBundleProvider } from '@flashbots/ethers-provider-bundle'

class SandwichBot {
    private provider: WebSocketProvider
    private flashbots: FlashbotsBundleProvider

    async monitor() {
        // Subscribe to pending transactions
        this.provider.watchPendingTransactions(async (hash) => {
            const tx = await this.provider.getTransaction({ hash })
            if (!tx) return

            // Step 1: Is this a DEX swap?
            const swap = this.decodeSwap(tx)
            if (!swap) return

            // Step 2: Is it profitable to sandwich?
            const analysis = await this.analyzeOpportunity(swap)
            if (!analysis.profitable) return

            // Step 3: Build the sandwich bundle
            const bundle = await this.buildBundle(tx, analysis)

            // Step 4: Submit to Flashbots
            await this.submitBundle(bundle)
        })
    }

    decodeSwap(tx: Transaction): SwapData | null {
        // Check if calldata matches known DEX router selectors
        const selector = tx.input.slice(0, 10)

        if (selector === '0x38ed1739') {
            // swapExactTokensForTokens(uint,uint,address[],address,uint)
            return this.decodeUniV2Swap(tx)
        }
        if (selector === '0x414bf389') {
            // exactInputSingle(ExactInputSingleParams)
            return this.decodeUniV3Swap(tx)
        }
        return null
    }

    async analyzeOpportunity(swap: SwapData) {
        // Simulate: what's the price impact of the victim's swap?
        const poolState = await this.getPoolState(swap.pool)
        const victimOutput = simulateSwap(poolState, swap.amountIn)
        const priceImpact = calculatePriceImpact(poolState, swap.amountIn)

        // Our frontrun: buy the same token BEFORE victim
        // This pushes price further up → victim gets worse rate
        // Our backrun: sell the token AFTER victim at elevated price
        const frontrunAmount = this.calculateOptimalFrontrun(poolState, swap.amountIn)
        const frontrunOutput = simulateSwap(poolState, frontrunAmount)

        // After frontrun, simulate victim (at worse price)
        const poolAfterFrontrun = applySwap(poolState, frontrunAmount)
        const victimOutputWorst = simulateSwap(poolAfterFrontrun, swap.amountIn)

        // After victim, simulate our backrun
        const poolAfterVictim = applySwap(poolAfterFrontrun, swap.amountIn)
        const backrunOutput = simulateReverse(poolAfterVictim, frontrunOutput)

        const profit = backrunOutput - frontrunAmount
        const gasCost = estimateGas() * gasPrice

        return {
            profitable: profit > gasCost * 2n, // Need 2x gas as minimum profit
            frontrunAmount,
            expectedProfit: profit - gasCost
        }
    }

    async buildBundle(victimTx: Transaction, analysis: Analysis) {
        // Transaction 1: Our frontrun (buy token before victim)
        const frontrunTx = {
            to: UNISWAP_ROUTER,
            data: encodeFrontrun(analysis),
            gasPrice: victimTx.gasPrice + parseUnits('1', 'gwei'), // Beat victim
            nonce: await this.getNonce()
        }

        // Transaction 2: Victim's transaction (unmodified)
        // Transaction 3: Our backrun (sell token after victim)
        const backrunTx = {
            to: UNISWAP_ROUTER,
            data: encodeBackrun(analysis),
            gasPrice: victimTx.gasPrice - parseUnits('1', 'gwei'), // Right after
            nonce: frontrunTx.nonce + 1
        }

        return [
            { signedTransaction: await this.sign(frontrunTx) },
            { signedTransaction: victimTx.raw },
            { signedTransaction: await this.sign(backrunTx) }
        ]
    }
}
```

## Liquidation Bot Architecture

```typescript
class LiquidationBot {
    // Track ALL positions across ALL lending protocols
    private positions: Map<string, Position> = new Map()

    async indexPositions() {
        // Subscribe to Deposit/Borrow events to build position database
        // Update on every Borrow, Repay, Withdraw, LiquidationCall event
        watchContractEvent({
            address: AAVE_POOL,
            abi: AaveABI,
            eventName: 'Borrow',
            onLogs: (logs) => {
                for (const log of logs) {
                    this.updatePosition(log.args.onBehalfOf)
                }
            }
        })
    }

    async monitor() {
        // Every block: check all positions for liquidatability
        watchBlocks(async (block) => {
            const prices = await this.getOraclePrices()

            for (const [user, position] of this.positions) {
                const hf = calculateHealthFactor(position, prices)

                if (hf < 1.0) {
                    await this.liquidate(user, position)
                } else if (hf < 1.05) {
                    // Watch closely — might liquidate next block
                    this.addToWatchList(user)
                }
            }
        })
    }

    async liquidate(user: string, position: Position) {
        // Find most profitable collateral/debt pair
        const { collateral, debt, profit } = this.findBestLiquidation(position)
        if (profit < MIN_PROFIT) return

        // Can we do this with a flash loan? (no capital required)
        if (debt > this.ownCapital) {
            await this.flashLoanLiquidation(user, collateral, debt)
        } else {
            await this.directLiquidation(user, collateral, debt)
        }
    }

    async flashLoanLiquidation(user: string, collateral: string, debtAsset: string) {
        // 1. Flash loan the debt amount from Aave
        // 2. Repay user's debt → receive collateral + 5-10% bonus
        // 3. Swap received collateral → debt asset
        // 4. Repay flash loan + 0.09% fee
        // 5. Keep the difference as profit

        const contract = new FlashLoanLiquidator()
        await contract.liquidateWithFlashLoan(user, collateral, debtAsset, {
            gasPrice: getCurrentGasPrice() * 1.2n // Outbid competitors
        })
    }
}
```

## Arbitrage Bot Architecture

```typescript
class ArbitrageBot {
    // Graph of all DEX pools
    private graph: Map<string, Edge[]> = new Map()

    async findArbitrage(): Promise<Path | null> {
        // Bellman-Ford for negative cycles (profit opportunities)
        // Price A→B on Uniswap: 1 ETH = 2000 USDC
        // Price B→A on Curve: 2005 USDC = 1 ETH
        // Cycle: ETH → USDC (Uniswap) → ETH (Curve) = +5 USDC profit

        const prices = await this.getSpotPrices()
        const cycles = findNegativeCycles(this.graph, prices)

        return cycles
            .map(cycle => this.estimateProfit(cycle))
            .filter(p => p.profit > p.gasCost)
            .sort((a, b) => b.profit - a.profit)[0] ?? null
    }

    async executeArbitrage(path: Path) {
        // Atomic execution: flash loan → swap sequence → repay
        const tx = await this.atomicArb.execute({
            flashLoanAmount: path.optimalAmount,
            flashLoanToken: path.startToken,
            swaps: path.swaps,
            minProfit: path.profit * 9n / 10n // 10% slippage tolerance
        })
    }
}
```

## JIT (Just-In-Time) Liquidity

```typescript
class JITBot {
    async monitor() {
        this.provider.watchPendingTransactions(async (hash) => {
            const tx = await this.getTransaction(hash)
            const swap = this.decodeUniV3Swap(tx)
            if (!swap || swap.amountIn < MIN_SWAP_SIZE) return

            // Is there profit in providing JIT liquidity for this swap?
            const fee = swap.amountIn * pool.feeTier / 1_000_000n
            const gasToMint = estimateGas('mint') + estimateGas('burn')

            if (fee > gasToMint * gasPrice) {
                await this.executeJIT(swap, tx)
            }
        })
    }

    async executeJIT(swap: SwapData, victimTx: Transaction) {
        // Bundle: [mint_liquidity, victim_swap, burn_liquidity]
        const tick = getCurrentTick(swap.pool)
        const tickRange = { lower: tick - 10, upper: tick + 10 } // Tight range

        const bundle = [
            this.buildMintTx(swap.pool, tickRange, swap.amountIn),
            { signedTransaction: victimTx.raw },
            this.buildBurnTx(swap.pool, tickRange)
        ]

        await this.flashbots.sendBundle(bundle, targetBlock)
        // After: our liquidity earned the fee from the victim's swap
        // Net gain: swap fee - gas cost for mint + burn
    }
}
```

## Defense Design Patterns (Why You Need This)

| Attack | How It Works | How to Stop It |
|--------|-------------|----------------|
| Sandwich | Buy before + sell after victim swap | `minAmountOut` param, private mempool |
| Liquidation race | First liquidator wins bonus | Irrelevant — competition = healthy. Design: make liquidation bots profitable at small margins |
| Arbitrage | Exploit price gaps between your protocol and others | Expected behavior — but if your protocol IS the lagging one, you're subsidizing arb bots. Use tighter oracles. |
| JIT liquidity | Steal fees from LPs | Uniswap V4 hooks can detect + block JIT |
| Oracle frontrun | Buy before oracle price update | Use TWAP, not spot price |

The goal isn't to eliminate MEV — it's to ensure MEV doesn't come at your users' expense.
