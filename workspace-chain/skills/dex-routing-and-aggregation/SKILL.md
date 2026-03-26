# DEX Routing & Aggregation

## The Aggregator Problem
A DEX aggregator doesn't hold liquidity — it finds the best path through existing pools. The optimization problem: given token A → token B, find the path (or combination of paths) that maximizes output while accounting for price impact, fees, and gas costs.

## Graph Model
Model all DEX pools as a weighted directed graph:
- **Nodes**: tokens (USDC, ETH, WBTC, etc.)
- **Edges**: liquidity pools (each pool creates two directed edges: A→B and B→A)
- **Edge weight**: effective exchange rate including price impact and fee

```
USDC ──[Uniswap V3 0.05%]──> ETH ──[Curve]──> stETH
  └──[Uniswap V2]──────────────────────────────> WBTC
  └──[Balancer]────> DAI ──[Curve 3pool]──> USDC (circular, for arbitrage)
```

## Routing Algorithms

### Bellman-Ford / Dijkstra Adapted
```typescript
interface Pool {
  tokenIn: string
  tokenOut: string
  getAmountOut(amountIn: bigint): bigint  // accounts for price impact
  gasEstimate: number
}

function findBestPath(
  tokenIn: string,
  tokenOut: string,
  amountIn: bigint,
  pools: Pool[],
  maxHops: number = 3
): Path {
  // Build graph
  const graph = buildGraph(pools)

  // BFS/DFS with pruning
  const paths = findAllPaths(graph, tokenIn, tokenOut, maxHops)

  // Simulate each path
  return paths
    .map(path => ({
      path,
      amountOut: simulatePath(path, amountIn),
      gasEstimate: estimateGas(path)
    }))
    .sort((a, b) => {
      // Net value = amountOut - gasCost (in token terms)
      const netA = a.amountOut - BigInt(a.gasEstimate) * gasPrice
      const netB = b.amountOut - BigInt(b.gasEstimate) * gasPrice
      return netB > netA ? 1 : -1
    })[0].path
}
```

### Split Routing
Split large orders across multiple paths to minimize total price impact.
```
Order: Sell 1,000,000 USDC for ETH

Naive: Route all through Uniswap V3 USDC/ETH 0.05% pool
→ $15,000 price impact (moves pool significantly)

Split: 
  40% → Uniswap V3 USDC/ETH 0.05% ($3,000 impact)
  35% → Uniswap V3 USDC/ETH 0.3% ($2,800 impact)
  25% → Curve USDC/ETH ($1,200 impact)
  Total: $7,000 impact — 53% improvement
```

Optimization: binary search on split ratios until marginal output per dollar is equal across all routes (at optimum, no path offers better marginal rate than another).

```typescript
function optimizeSplit(
  paths: Path[],
  totalAmount: bigint,
  precision: number = 100  // 1% increments
): { path: Path; amount: bigint }[] {
  // Convex optimization — at optimum:
  // dOutput/dAmount is equal across all selected paths
  
  // Discrete approximation: try all splits in `precision` increments
  // Returns allocation that maximizes total output
  
  let best = { output: 0n, allocation: [] }
  
  // Dynamic programming over path selections
  // O(paths^2 * precision) — manageable for 3-4 paths
  for (const allocation of generateAllocations(paths.length, precision)) {
    const amounts = allocation.map(pct => totalAmount * BigInt(pct) / BigInt(precision))
    const output = paths.reduce((sum, path, i) => sum + path.getOutput(amounts[i]), 0n)
    if (output > best.output) best = { output, allocation }
  }
  
  return best.allocation.map((pct, i) => ({
    path: paths[i],
    amount: totalAmount * BigInt(pct) / BigInt(precision)
  }))
}
```

## Multi-Hop Routes
```
BONK → SOL → USDC (2 hops)
vs
BONK → USDC (1 hop, if pool exists)

Rule: Multi-hop wins when:
  output(A→B→C) - extraGas > output(A→C)
  
Reality: For long-tail tokens, 2-hop through major pairs
(USDC, ETH, BTC, SOL) is almost always better than direct
because the direct pool is too thin.
```

## Limit Orders
Off-chain signed orders executed when price hits target.

```solidity
struct LimitOrder {
    address maker;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 minAmountOut;    // The "limit" — minimum acceptable output
    uint256 expiry;
    uint256 nonce;
    bytes signature;
}

contract LimitOrderExecutor {
    mapping(bytes32 => bool) public filledOrders;

    // Keeper calls this when price is favorable
    function executeOrder(
        LimitOrder calldata order,
        bytes calldata routeData  // Optimal route at execution time
    ) external {
        bytes32 orderId = hashOrder(order);
        require(!filledOrders[orderId], "Filled");
        require(block.timestamp < order.expiry, "Expired");
        require(verifySignature(order), "Bad sig");

        filledOrders[orderId] = true;

        // Pull tokens from maker
        IERC20(order.tokenIn).safeTransferFrom(order.maker, address(this), order.amountIn);

        // Execute swap via router
        uint256 amountOut = _executeSwap(order.tokenIn, order.tokenOut, order.amountIn, routeData);

        // Enforce minimum output (the limit)
        require(amountOut >= order.minAmountOut, "Below limit");

        // Send to maker
        IERC20(order.tokenOut).safeTransfer(order.maker, amountOut);

        // Keeper reward from surplus
        // amountOut - order.minAmountOut = keeper's incentive
    }
}
```

## DCA (Dollar Cost Averaging)
```solidity
struct DCAOrder {
    address user;
    address tokenIn;
    address tokenOut;
    uint256 totalAmountIn;
    uint256 swapAmount;      // Amount per interval
    uint256 intervalSeconds; // How often to swap
    uint256 nextExecutionTime;
    uint256 remainingAmount;
}

function executeDCA(uint256 orderId) external {
    DCAOrder storage order = orders[orderId];
    require(block.timestamp >= order.nextExecutionTime, "Too soon");
    require(order.remainingAmount >= order.swapAmount, "Exhausted");

    uint256 swapAmt = Math.min(order.swapAmount, order.remainingAmount);
    order.remainingAmount -= swapAmt;
    order.nextExecutionTime = block.timestamp + order.intervalSeconds;

    // Execute swap (no price limit — that's the point of DCA)
    uint256 received = _swap(order.tokenIn, order.tokenOut, swapAmt, 0);
    IERC20(order.tokenOut).safeTransfer(order.user, received);
}
```

## Universal Router Pattern (Uniswap V4 style)
Single entry point for all protocol interactions:
```solidity
// Commands: SWAP_V2, SWAP_V3, SWEEP, WRAP_ETH, UNWRAP_ETH, etc.
function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable {
    require(block.timestamp <= deadline, "Expired");

    uint256 numCommands = commands.length;
    for (uint256 i = 0; i < numCommands; ) {
        bytes1 command = commands[i];
        bytes calldata input = inputs[i];

        if (command == Commands.SWAP_V3_EXACT_IN) {
            (address recipient, uint256 amountIn, uint256 amountOutMin, bytes memory path, bool payerIsUser) =
                abi.decode(input, (address, uint256, uint256, bytes, bool));
            _v3SwapExactInput(recipient, amountIn, amountOutMin, path, payerIsUser);
        }
        // ... other commands
        unchecked { ++i; }
    }
}
```

## Jupiter-Specific (Solana)
- Routes across: Raydium, Orca, Serum (legacy), Phoenix, OpenBook
- Uses Versioned Transactions with Address Lookup Tables to fit complex multi-hop routes
- Quote API: off-chain route computation → on-chain execution
- Exact-out routing: "I want exactly 1 SOL, how much USDC do I need?" (reverse routing)
