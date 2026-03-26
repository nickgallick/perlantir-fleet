# Cosmos & App-Chains

## App-Chain Thesis

Building your own blockchain optimized for your use case:
- **Custom block time**: dYdX uses 1-2 second blocks (vs Ethereum's 12 seconds)
- **Custom mempool ordering**: dYdX orders trades by price-time priority, not gas price
- **No gas competition**: Users pay trading fees, not competing for block space
- **Vertical integration**: Consensus-level logic (order matching in validator memory)
- **Sovereignty**: Govern your own upgrades, parameters, and validator set

**When to build app-chain vs L2 smart contracts**:
- App-chain: need custom consensus logic, order book in-memory on validators, sovereign governance, no gas model
- L2 smart contracts: composability with other DeFi, existing ecosystem, faster time-to-market

## Cosmos SDK Architecture

```
Application (your chain logic)
     │
     ├── Modules (each module = one domain of functionality)
     │    ├── x/bank      → token transfers
     │    ├── x/staking   → validator staking
     │    ├── x/gov       → governance
     │    ├── x/clob      → dYdX's order book module
     │    └── x/subaccounts → dYdX's margin accounting
     │
     ├── ABCI Interface (Application BlockChain Interface)
     │    ├── InitChain   → genesis setup
     │    ├── BeginBlock  → start of each block
     │    ├── DeliverTx   → process each transaction
     │    ├── EndBlock    → end of block processing
     │    └── Commit      → finalize state
     │
     └── CometBFT (consensus engine)
          ├── P2P networking
          ├── Mempool
          └── BFT consensus (Tendermint)
```

## Module Structure

```go
// Each Cosmos module follows this pattern
type Module struct {
    name    string
    keeper  Keeper  // State management
    handler sdk.Handler  // Message processing
    querier sdk.Querier  // Query handling
}

// Message handler
func handleMsgPlaceOrder(ctx sdk.Context, keeper Keeper, msg MsgPlaceOrder) (*sdk.Result, error) {
    // Validate
    if err := msg.ValidateBasic(); err != nil {
        return nil, err
    }

    // Execute
    orderId, err := keeper.PlaceOrder(ctx, msg.Order)
    if err != nil {
        return nil, err
    }

    // Emit event
    ctx.EventManager().EmitEvent(sdk.NewEvent(
        EventTypePlaceOrder,
        sdk.NewAttribute(AttributeKeyOrderId, fmt.Sprintf("%d", orderId)),
    ))

    return &sdk.Result{Events: ctx.EventManager().Events().ToABCIEvents()}, nil
}
```

## CometBFT (Tendermint BFT)

### Consensus Process
```
Propose → Prevote → Precommit → Commit

Round N:
1. Proposer broadcasts block proposal
2. All validators: if valid → prevote(block), else prevote(nil)
3. If 2/3+ prevotes for same block → validators send precommit
4. If 2/3+ precommits → COMMIT (finality!)
5. Next proposer is selected round-robin

Properties:
- Finality in 1-2 rounds (1-2 seconds on dYdX)
- No reorganizations (unlike PoW)
- Safety: never commit conflicting blocks
- Liveness: progresses as long as 2/3+ validators are honest
```

## IBC (Inter-Blockchain Communication)

```
Chain A ←──── IBC ────→ Chain B

1. Chain A creates IBC packet (message + proof)
2. Relayer observes Chain A → submits packet to Chain B
3. Chain B verifies proof against Chain A's light client
4. Chain B executes the packet (token transfer, message, etc.)
5. Relayer submits acknowledgment back to Chain A

Security: Light client verification — Chain B has Chain A's block headers
If Chain A forks, IBC pauses until fork is resolved
```

## dYdX V4 Architecture

```go
// Order placement via gRPC/REST → validator mempool
type MsgPlaceOrder struct {
    Order Order
}

type Order struct {
    OrderId     OrderId
    Side        Order_Side  // BUY or SELL
    Quantums    uint64      // Position size in base units
    Subticks    uint64      // Price in subtick units
    TimeInForce Order_TimeInForce  // GTT, IOC, FOK, POST_ONLY
    GoodTilBlock uint32
}

// Matching happens in PrepareProposal (before block is committed)
func (app *App) PrepareProposal(ctx sdk.Context, req abci.RequestPrepareProposal) abci.ResponsePrepareProposal {
    // Process all pending orders from mempool
    // Match compatible orders
    // Generate match transactions to include in block
    matches := app.ClobKeeper.RunMatchingLogic(ctx)
    // Include matches in block
}
```

### Key Design Decisions in dYdX V4
1. **Order book is NOT in storage** — it's in-memory on each validator node. Orders don't need to be on-chain until matched.
2. **Matches are on-chain** — when orders match, the match is submitted as a transaction and included in a block.
3. **Gas is free for order placement** — placing/canceling orders doesn't cost gas (validators run them as mempool operations). Only matches cost "gas" (paid as trading fees).
4. **Composability tradeoff** — dYdX V4 can't natively interact with Ethereum DeFi without IBC bridging.

## When to Use App-Chain

**Use app-chain when**:
- Need sub-second finality with guaranteed ordering
- Want sovereign governance of the chain
- Business model requires custom gas model (trading fees not ETH gas)
- Need consensus-level logic (order matching, specific sequencing)
- Don't need Ethereum composability

**Don't use app-chain when**:
- Need to interact with ETH/ERC-20 ecosystems natively
- Team doesn't have blockchain infrastructure expertise
- Want to iterate quickly (app-chains need validator set management)
- MVP stage — start on L2 smart contracts, migrate to app-chain at scale
