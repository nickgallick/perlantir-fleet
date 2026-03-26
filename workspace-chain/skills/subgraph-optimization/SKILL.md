# Subgraph Optimization

## Diagnosing Production Issues

```bash
# Check indexing status via Graph Node admin API
curl -X POST http://localhost:8030/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ indexingStatuses { subgraph health synced fatalError { message block { number } } chains { latestBlock { number } chainHeadBlock { number } } } }"}'

# Key metric: latestBlock vs chainHeadBlock
# If chainHeadBlock - latestBlock > 1000: subgraph is falling behind
# fatalError: null = healthy; fatalError: {...} = subgraph crashed
```

## Schema Anti-Patterns and Fixes

```graphql
# ❌ BAD: Storing array of IDs — grows unbounded, slow to query
type Pool @entity {
  id: ID!
  swapIds: [String!]!  # This array has 1M items after a month
}

# ✅ GOOD: Reverse lookup via @derivedFrom — virtual, no storage
type Pool @entity {
  id: ID!
  swaps: [Swap!]! @derivedFrom(field: "pool")  # Computed at query time
}

type Swap @entity {
  id: ID!
  pool: Pool!  # Store the forward reference only
  amount: BigInt!
}

# ❌ BAD: New entity every block for metrics
type DailyVolume @entity {
  id: ID!  # "2024-01-15-00:01:23" — millions of records
  volume: BigDecimal!
}

# ✅ GOOD: Hourly snapshots using truncated timestamp as ID
type HourlySnapshot @entity {
  id: ID!  # "2024011500" = floor(timestamp / 3600) → at most 8760/year
  timestamp: BigInt!
  volume: BigDecimal!
  txCount: BigInt!
}
```

## Handler Optimization

```typescript
// ❌ BAD: Multiple store.load() calls scattered throughout handler
export function handleSwap(event: SwapEvent): void {
  let pool = Pool.load(event.address.toHex())!;
  let token0 = Token.load(pool.token0)!;       // Extra load
  let token1 = Token.load(pool.token1)!;       // Extra load
  let factory = Factory.load("mainFactory")!;   // Extra load

  // ... lots of code ...

  let pool2 = Pool.load(event.address.toHex())!; // DUPLICATE load — wasted
  pool2.save();
}

// ✅ GOOD: Load everything at top, save once at bottom
export function handleSwap(event: SwapEvent): void {
  // Load all entities at once
  let poolId   = event.address.toHex();
  let pool     = Pool.load(poolId);
  if (!pool) return; // Early exit on missing data

  let token0   = Token.load(pool.token0)!;
  let token1   = Token.load(pool.token1)!;
  let factory  = Factory.load("mainFactory")!;

  // ... processing ...

  // Save all modified entities at the end
  pool.save();
  token0.save();
  token1.save();
  factory.save();
}
```

## Efficient Entity IDs

```typescript
// ❌ BAD: Counter-based IDs — requires loading counter entity on every event
let counter = Counter.load("main")!;
counter.count = counter.count.plus(ONE);
counter.save();
let swap = new Swap(counter.count.toString());

// ✅ GOOD: Deterministic ID from event data — no extra load needed
let swap = new Swap(
  event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
);
// This ID is globally unique, derived from the event itself, requires zero store reads
```

## Time-Series Data Pattern

```typescript
// Efficient hourly/daily snapshot pattern
function getOrCreateHourlySnapshot(timestamp: BigInt): HourlySnapshot {
  let hourId = timestamp.div(BigInt.fromI32(3600));
  let id     = hourId.toString();

  let snapshot = HourlySnapshot.load(id);
  if (!snapshot) {
    snapshot           = new HourlySnapshot(id);
    snapshot.timestamp = hourId.times(BigInt.fromI32(3600));
    snapshot.volume    = ZERO_BD;
    snapshot.txCount   = ZERO_BI;
  }
  return snapshot;
}
```

## Grafting (Skip Re-indexing)

```yaml
# subgraph.yaml — start from a known-good block using existing subgraph state
features:
  - grafting
graft:
  base: QmExistingSubgraphIPFSHash  # Previous deployment's IPFS hash
  block: 19000000                    # Start indexing from this block forward
# Saves hours/days of re-indexing for large subgraphs
```

## Query Optimization

```graphql
# ✅ Always paginate with cursor pattern
query GetSwaps($lastId: ID!) {
  swaps(first: 1000, where: { id_gt: $lastId }, orderBy: id, orderDirection: asc) {
    id
    amount0
    amount1
    timestamp
  }
}
# Start with lastId: "" then use last result's ID as next cursor
```
