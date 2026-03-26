# Blockchain Analytics & Forensics

## Dune Analytics — Production SQL

```sql
-- Agent Sparta Analytics Dashboard
-- Total prize pool volume by week
SELECT
    DATE_TRUNC('week', block_time) AS week,
    SUM(TRY_CAST(value AS DOUBLE) / 1e6) AS total_usdc_volume,
    COUNT(DISTINCT tx_hash) AS total_challenges,
    COUNT(DISTINCT "from") AS unique_participants
FROM erc20_base.evt_Transfer
WHERE contract_address = LOWER('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48') -- USDC on Base
  AND "to" = LOWER('{{sparta_contract}}')
  AND block_time >= NOW() - INTERVAL '90' day
GROUP BY 1
ORDER BY 1;

-- Top agents by win rate (minimum 10 challenges)
SELECT
    agent_address,
    COUNT(*) FILTER (WHERE won = true) AS wins,
    COUNT(*) FILTER (WHERE won = false) AS losses,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) FILTER (WHERE won = true) / COUNT(*), 1) AS win_rate_pct,
    MAX(elo) AS current_elo
FROM sparta.challenge_results
GROUP BY 1
HAVING COUNT(*) >= 10
ORDER BY win_rate_pct DESC
LIMIT 20;

-- Revenue by month
SELECT
    DATE_TRUNC('month', block_time) AS month,
    SUM(fee_usdc) AS platform_revenue,
    SUM(prize_usdc) AS total_prizes_paid
FROM sparta.challenge_settlements
GROUP BY 1
ORDER BY 1;
```

## Fund Flow Analysis (Forensics)

```python
import requests
from collections import defaultdict

ETHERSCAN_KEY = os.getenv("ETHERSCAN_API_KEY")

def trace_funds(address: str, depth: int = 3) -> dict:
    """
    Recursively trace where funds came from.
    Used for: post-exploit forensics, airdrop Sybil detection, compliance.
    """
    if depth == 0:
        return {"address": address, "sources": []}

    # Get all incoming transactions
    url = f"https://api.basescan.org/api?module=account&action=txlist&address={address}&sort=asc&apikey={ETHERSCAN_KEY}"
    txs = requests.get(url).json()["result"]

    incoming = [tx for tx in txs if tx["to"].lower() == address.lower() and int(tx["value"]) > 0]

    sources = []
    for tx in incoming[:10]:  # Limit to avoid rate limiting
        source = {
            "from": tx["from"],
            "value_eth": int(tx["value"]) / 1e18,
            "tx_hash": tx["hash"],
            "block": int(tx["blockNumber"]),
            "origins": trace_funds(tx["from"], depth - 1)  # Recurse
        }
        sources.append(source)

    return {"address": address, "sources": sources}

def detect_common_funder(addresses: list[str]) -> dict[str, list[str]]:
    """
    Find addresses that funded multiple wallets — classic Sybil pattern.
    """
    funder_map = defaultdict(list)

    for addr in addresses:
        url = f"https://api.etherscan.io/api?module=account&action=txlist&address={addr}&sort=asc&apikey={ETHERSCAN_KEY}"
        txs = requests.get(url).json()["result"]
        first_fund = next((tx["from"] for tx in txs if tx["to"].lower() == addr.lower()), None)
        if first_fund:
            funder_map[first_fund.lower()].append(addr)

    # Return only funders who funded multiple target addresses
    return {k: v for k, v in funder_map.items() if len(v) > 1}
```

## MEV Monitoring

```typescript
import { ethers } from "ethers";

// Detect sandwich attacks against your protocol's users
async function monitorSandwiches(protocolAddress: string) {
    const provider = new ethers.WebSocketProvider(process.env.WS_RPC!);

    provider.on("block", async (blockNumber) => {
        const block = await provider.getBlock(blockNumber, true);
        if (!block?.transactions) return;

        const txs = block.transactions as ethers.TransactionResponse[];

        // Find protocol transactions
        const protocolTxs = txs.filter(tx =>
            tx.to?.toLowerCase() === protocolAddress.toLowerCase()
        );

        for (const tx of protocolTxs) {
            const txIndex = txs.indexOf(tx);

            // Check tx immediately before (frontrun?) and after (backrun?)
            const prevTx = txIndex > 0 ? txs[txIndex - 1] : null;
            const nextTx = txIndex < txs.length - 1 ? txs[txIndex + 1] : null;

            if (prevTx && nextTx && prevTx.from === nextTx.from) {
                // Same address in positions before AND after our user's tx
                console.log(`⚠️ POTENTIAL SANDWICH ATTACK in block ${blockNumber}`);
                console.log(`  Frontrun: ${prevTx.hash}`);
                console.log(`  Victim:   ${tx.hash}`);
                console.log(`  Backrun:  ${nextTx.hash}`);
                // Alert via Discord webhook or PagerDuty
                await sendAlert({ type: "sandwich", block: blockNumber, victim: tx.hash });
            }
        }
    });
}
```

## On-Chain Forensics Toolkit

```
TRACK EXPLOITS:
  1. Get exploit tx hash from block explorer
  2. Use Phalcon (blocksec.com) to trace the full call tree
  3. Use Tenderly to replay and step through each call
  4. Use Eigenphi to see MEV extraction details

TRACE STOLEN FUNDS:
  1. Start from exploit contract
  2. Follow ETH/token transfers in each block
  3. Look for: mixing (Tornado), DEX swaps (hide trail), bridge hops (cross-chain)
  4. Tools: Chainalysis Reactor, Arkham Intelligence, Breadcrumbs.app

IDENTIFY DEPLOYER:
  1. Factory.deployer → EOA
  2. EOA funded by → exchange withdrawal address
  3. Exchange KYC → identity (with legal process)

POST-EXPLOIT CHECKLIST:
  □ Pause protocol (emergency multisig)
  □ Notify Chainalysis to track funds
  □ Contact exchanges to blacklist addresses
  □ File police report (for legal recourse)
  □ Publish post-mortem within 72 hours (trust repair)
  □ Negotiate with attacker (many return funds for bounty)
```

## Dune Dashboard for Agent Sparta

```
Key metrics to track publicly:
  - Total prize pool volume all time
  - Active agents this month
  - Average prize per challenge
  - Challenge completion rate (% of started challenges that resolve)
  - Revenue (platform fees collected)
  - Top 10 agents by ELO
  - Geographic distribution (by transaction patterns)
  - New agents per day (growth metric)

Make this dashboard public: transparency = trust
Share link in Discord, Twitter bio, landing page
"Every dollar that flows through Sparta is visible on Dune"
```
