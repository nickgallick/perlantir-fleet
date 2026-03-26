# Subgraph & On-Chain Indexing

## Why Index
Blockchain state is optimized for writes, not reads. You can't efficiently:
- Get all trades for a user across all markets
- Calculate total volume over a time period
- Paginate through market listings sorted by volume

Indexers listen to events and build a queryable database. Use RPC for current state, indexer for historical/aggregated data.

## The Graph

### Project Structure
```
subgraph/
  subgraph.yaml     # Data sources, event handlers
  schema.graphql    # Entity definitions
  src/
    mapping.ts      # AssemblyScript event handlers
```

### subgraph.yaml
```yaml
specVersion: 0.0.5
schema:
  file: ./schema.graphql
dataSources:
  - kind: ethereum
    name: MarketFactory
    network: base
    source:
      address: "0xYourFactoryAddress"
      abi: MarketFactory
      startBlock: 12345678  # Block where contract was deployed
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Market
        - Trade
      abis:
        - name: MarketFactory
          file: ./abis/MarketFactory.json
      eventHandlers:
        - event: MarketCreated(indexed bytes32,address,string,uint256)
          handler: handleMarketCreated
        - event: SharesPurchased(indexed bytes32,indexed address,uint8,uint256,uint256)
          handler: handleSharesPurchased
      file: ./src/mapping.ts
```

### schema.graphql
```graphql
type Market @entity {
  id: Bytes!              # conditionId
  questionId: Bytes!
  description: String!
  yesPrice: BigDecimal!   # 0.0 to 1.0
  noPrice: BigDecimal!
  totalVolume: BigInt!
  createdAt: BigInt!
  resolutionTime: BigInt!
  resolved: Boolean!
  outcome: Int            # null until resolved, 0=NO, 1=YES
  trades: [Trade!]! @derivedFrom(field: "market")
}

type Trade @entity {
  id: Bytes!              # txHash + logIndex
  market: Market!
  trader: Bytes!
  outcome: Int!           # 0=NO, 1=YES
  amount: BigInt!         # USDC amount (6 decimals)
  shares: BigInt!
  price: BigDecimal!
  timestamp: BigInt!
  blockNumber: BigInt!
}

type User @entity {
  id: Bytes!              # address
  totalVolume: BigInt!
  trades: [Trade!]! @derivedFrom(field: "trader")
}
```

### AssemblyScript Mappings
```typescript
import { BigInt, BigDecimal, Bytes } from "@graphprotocol/graph-as"
import { MarketCreated, SharesPurchased } from "../generated/MarketFactory/MarketFactory"
import { Market, Trade } from "../generated/schema"

export function handleMarketCreated(event: MarketCreated): void {
  let market = new Market(event.params.conditionId)
  market.questionId = event.params.questionId
  market.description = event.params.description
  market.yesPrice = BigDecimal.fromString("0.5")
  market.noPrice = BigDecimal.fromString("0.5")
  market.totalVolume = BigInt.fromI32(0)
  market.createdAt = event.block.timestamp
  market.resolutionTime = event.params.resolutionTime
  market.resolved = false
  market.save()
}

export function handleSharesPurchased(event: SharesPurchased): void {
  let trade = new Trade(event.transaction.hash.concatI32(event.logIndex.toI32()))
  trade.market = event.params.marketId
  trade.trader = event.params.buyer
  trade.outcome = event.params.outcome
  trade.amount = event.params.usdcAmount
  trade.shares = event.params.shares
  trade.price = event.params.usdcAmount.toBigDecimal().div(event.params.shares.toBigDecimal())
  trade.timestamp = event.block.timestamp
  trade.blockNumber = event.block.number
  trade.save()

  // Update market volume
  let market = Market.load(event.params.marketId)
  if (market) {
    market.totalVolume = market.totalVolume.plus(event.params.usdcAmount)
    market.save()
  }
}
```

### Querying
```graphql
# Frontend GraphQL query
query GetMarkets($first: Int!, $skip: Int!) {
  markets(first: $first, skip: $skip, orderBy: totalVolume, orderDirection: desc) {
    id
    description
    yesPrice
    totalVolume
    resolutionTime
    resolved
  }
}

query GetUserTrades($user: Bytes!) {
  trades(where: { trader: $user }, orderBy: timestamp, orderDirection: desc) {
    market { description }
    outcome
    amount
    price
    timestamp
  }
}
```

## Ponder (Modern Alternative)

### When to Use Ponder vs The Graph
| Criteria | The Graph | Ponder |
|----------|-----------|--------|
| Language | AssemblyScript | TypeScript |
| Dev experience | Complex, slow hot reload | Fast, familiar |
| Ecosystem maturity | Production-proven | Growing |
| Decentralization | Decentralized network | Self-hosted |
| Best for | Large DeFi protocols | New projects, MVPs |

### Ponder Setup
```typescript
// ponder.config.ts
import { createConfig } from "@ponder/core"
import { http } from "viem"
import { MarketFactoryAbi } from "./abis/MarketFactory"

export default createConfig({
  networks: {
    base: { chainId: 8453, transport: http(process.env.BASE_RPC) }
  },
  contracts: {
    MarketFactory: {
      network: "base",
      abi: MarketFactoryAbi,
      address: "0xYourAddress",
      startBlock: 12345678
    }
  }
})
```

```typescript
// src/index.ts
import { ponder } from "@/generated"

ponder.on("MarketFactory:MarketCreated", async ({ event, context }) => {
  await context.db.Market.create({
    id: event.args.conditionId,
    data: {
      description: event.args.description,
      yesPrice: 0.5,
      totalVolume: 0n,
      resolved: false,
    }
  })
})
```

## RPC vs Indexer Decision Matrix
| Data Need | Use |
|-----------|-----|
| Current token balance | RPC (`eth_call`) |
| Latest market price | RPC |
| User's trade history | Indexer |
| Market volume rankings | Indexer |
| Real-time event feed | Contract event listener (viem `watchContractEvent`) |
| Historical charts | Indexer |
| Checking one allowance | RPC |
| All markets user participated in | Indexer |
