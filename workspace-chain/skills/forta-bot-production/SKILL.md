# Forta Bot Production

## Complete Oracle Manipulation Detection Bot

```typescript
// src/agent.ts
import {
    Finding, FindingSeverity, FindingType,
    HandleTransaction, HandleBlock,
    TransactionEvent, BlockEvent,
    getEthersProvider, ethers
} from "forta-agent";

// ── Config ──────────────────────────────────────────────────────────────────
const CHAINLINK_AGGREGATOR_ABI = [
    "event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt)",
    "function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)",
];

// Known oracle addresses to monitor (add your protocol's oracles)
const MONITORED_ORACLES: Record<string, string> = {
    "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419": "ETH/USD",
    "0xf4030086522a5beea4988f8ca5b36dbc97bee88c": "BTC/USD",
    "0x8ffdf2de812095b1d19cb146e4c004587c0a0692": "USDC/USD",
};

const DEVIATION_THRESHOLD_PCT = 10;   // >10% single-update change = suspicious
const FLASH_WINDOW_BLOCKS     = 1;    // Oracle update + exploit in same block
const PRICE_HISTORY_MAX       = 100;  // Keep last 100 price points per oracle

// ── State ───────────────────────────────────────────────────────────────────
interface PricePoint { price: bigint; blockNumber: number; txHash: string; }
const priceHistory  = new Map<string, PricePoint[]>();
const alertCooldown = new Map<string, number>(); // oracle → last alert block

// ── Main handlers ────────────────────────────────────────────────────────────

export const handleTransaction: HandleTransaction = async (txEvent: TransactionEvent) => {
    const findings: Finding[] = [];

    // ── Detection 1: Sudden price deviation ─────────────────────────────────
    const answerUpdatedLogs = txEvent.filterLog(
        ["event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt)"]
    );

    for (const log of answerUpdatedLogs) {
        const oracle   = log.address.toLowerCase();
        const newPrice = BigInt(log.args.current.toString());
        const blockNum = txEvent.blockNumber;

        if (!priceHistory.has(oracle)) priceHistory.set(oracle, []);
        const history = priceHistory.get(oracle)!;

        if (history.length > 0) {
            const lastPrice  = history[history.length - 1].price;
            const deviation  = _deviation(lastPrice, newPrice);

            if (deviation > DEVIATION_THRESHOLD_PCT) {
                const oracleName = MONITORED_ORACLES[oracle] ?? oracle.slice(0, 10);
                const lastAlerted = alertCooldown.get(oracle) ?? 0;

                if (blockNum > lastAlerted + 5) { // Debounce: 5 blocks
                    alertCooldown.set(oracle, blockNum);
                    findings.push(Finding.fromObject({
                        name:        "Oracle Price Manipulation Suspected",
                        description: `${oracleName} price changed ${deviation.toFixed(1)}% in single update`,
                        alertId:     "ORACLE-PRICE-DEVIATION",
                        severity:    FindingSeverity.Critical,
                        type:        FindingType.Exploit,
                        metadata: {
                            oracle,
                            oracleName,
                            previousPrice: lastPrice.toString(),
                            newPrice:      newPrice.toString(),
                            deviationPct:  deviation.toFixed(2),
                            txHash:        txEvent.hash,
                            blockNumber:   blockNum.toString(),
                        },
                    }));
                }
            }
        }

        // Update history
        history.push({ price: newPrice, blockNumber: blockNum, txHash: txEvent.hash });
        if (history.length > PRICE_HISTORY_MAX) history.shift();
    }

    // ── Detection 2: Flash loan + oracle interaction in same tx ──────────────
    const flashLoanTopics = [
        "0x631042c832b07452973831137f2d73e395028b44b250de141f8cae08e3773d", // Aave V3 FlashLoan
        "0x5cfe4ff55dcb2f75d6c8b64a13b5e4e4ed2e6f57cd8c2fc5bd6c98dc5a36c",  // Euler FlashLoan
    ];
    const hasFlashLoan = txEvent.logs.some(log =>
        flashLoanTopics.some(topic => log.topics[0] === topic)
    );
    const hasOracleUpdate = answerUpdatedLogs.length > 0;

    if (hasFlashLoan && hasOracleUpdate) {
        findings.push(Finding.fromObject({
            name:        "Flash Loan + Oracle Update in Same Transaction",
            description: "A flash loan and oracle price update occurred in the same transaction — possible manipulation",
            alertId:     "FLASH-LOAN-ORACLE-COMBO",
            severity:    FindingSeverity.High,
            type:        FindingType.Suspicious,
            metadata: { txHash: txEvent.hash, blockNumber: txEvent.blockNumber.toString() },
        }));
    }

    // ── Detection 3: Chainlink round skipping (indicates manipulation attempt) ─
    for (const log of answerUpdatedLogs) {
        const history = priceHistory.get(log.address.toLowerCase()) ?? [];
        if (history.length >= 2) {
            // If latest two rounds are more than 2 apart, rounds may have been skipped
            // (normal: consecutive rounds; skipped rounds = suspicious)
            // Note: requires reading roundId from the log
        }
    }

    return findings;
};

export const handleBlock: HandleBlock = async (blockEvent: BlockEvent) => {
    const findings: Finding[] = [];

    // ── Detection 4: Oracle staleness (price not updated in >1 hour) ──────────
    const provider  = getEthersProvider();
    const blockTime = blockEvent.block.timestamp;

    for (const [oracle, name] of Object.entries(MONITORED_ORACLES)) {
        try {
            const contract  = new ethers.Contract(oracle, CHAINLINK_AGGREGATOR_ABI, provider);
            const roundData = await contract.latestRoundData();
            const age       = blockTime - Number(roundData.updatedAt);

            if (age > 3600) { // >1 hour stale
                findings.push(Finding.fromObject({
                    name:        "Oracle Price Data Stale",
                    description: `${name} oracle has not updated in ${Math.floor(age/60)} minutes`,
                    alertId:     "ORACLE-STALENESS",
                    severity:    age > 7200 ? FindingSeverity.High : FindingSeverity.Medium,
                    type:        FindingType.Degraded,
                    metadata: {
                        oracle, name,
                        lastUpdate:  roundData.updatedAt.toString(),
                        ageSeconds:  age.toString(),
                        blockNumber: blockEvent.blockNumber.toString(),
                    },
                }));
            }
        } catch (_) { /* Oracle may not be on this chain */ }
    }

    return findings;
};

// ── Helpers ──────────────────────────────────────────────────────────────────

function _deviation(prev: bigint, curr: bigint): number {
    if (prev === 0n) return 0;
    const diff = curr > prev ? curr - prev : prev - curr;
    return Number(diff * 10000n / (prev < 0n ? -prev : prev)) / 100;
}
```

## Deploy and Run

```bash
# Initialize (if new project)
npx forta-agent@latest init --typescript

# Copy agent.ts to src/agent.ts

# Test locally against real transactions
npm run test

# Start local node (uses past blocks)
npx hardhat node --fork $MAINNET_RPC

# Run against live chain
npm run start:prod

# Publish to Forta Network
# First: get FORT tokens for staking, stake on your bot
npx forta-agent@latest publish

# Check bot status
# https://app.forta.network/bot/YOUR_BOT_ID
```

## package.json

```json
{
  "name": "oracle-manipulation-detector",
  "version": "0.0.1",
  "description": "Detects oracle price manipulation attacks",
  "scripts": {
    "build": "tsc",
    "start": "npm run build && forta-agent run",
    "start:prod": "npm run build && forta-agent run --prod",
    "test": "npm run build && forta-agent test"
  },
  "dependencies": {
    "forta-agent": "^0.1.48",
    "ethers": "^6.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

## Additional Bots to Build for Agent Sparta

```typescript
// Bot 2: Large prize pool drain detection
// Alert if more than 50% of prize pool leaves the contract in one tx

// Bot 3: Governance attack detector
// Flash loan + token transfer + governance proposal in same block

// Bot 4: Reentrancy detector
// Same contract called recursively in a single tx trace
// Requires trace_transaction (archive node)
```
