# Web3 Frontend Integration

## Core Libraries

### viem — Low-Level Ethereum Client
```typescript
import { createPublicClient, createWalletClient, http, parseEther } from 'viem'
import { base } from 'viem/chains'

// Read-only client
const publicClient = createPublicClient({
  chain: base,
  transport: http('https://mainnet.base.org')
})

// Read contract
const balance = await publicClient.readContract({
  address: '0xMarketAddress',
  abi: MarketABI,
  functionName: 'getMarketInfo',
  args: [marketId]
})

// Wallet client (for writes)
const walletClient = createWalletClient({
  chain: base,
  transport: custom(window.ethereum)
})

// Write contract
const hash = await walletClient.writeContract({
  address: '0xMarketAddress',
  abi: MarketABI,
  functionName: 'buyShares',
  args: [marketId, outcome, amount]
})

// Wait for receipt
const receipt = await publicClient.waitForTransactionReceipt({ hash })
```

### wagmi — React Hooks for Ethereum
```typescript
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'

function MarketCard({ marketId }) {
  const { address, isConnected } = useAccount()

  // Read contract state
  const { data: marketInfo } = useReadContract({
    address: MARKET_CONTRACT,
    abi: MarketABI,
    functionName: 'getMarketInfo',
    args: [marketId],
    query: { refetchInterval: 5000 }  // Poll every 5s
  })

  // Write transaction
  const { writeContract, data: hash, isPending } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash })

  const buyShares = () => writeContract({
    address: MARKET_CONTRACT,
    abi: MarketABI,
    functionName: 'buyShares',
    args: [marketId, OUTCOME_YES, parseUnits('10', 6)]
  })

  return (
    <button onClick={buyShares} disabled={isPending || isConfirming}>
      {isPending ? 'Confirm in wallet...' : isConfirming ? 'Processing...' : 'Buy YES'}
    </button>
  )
}
```

### Wallet Connection
```typescript
// RainbowKit setup
import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit'
import { WagmiProvider } from 'wagmi'
import { base, baseSepolia } from 'wagmi/chains'

const config = getDefaultConfig({
  appName: 'My dApp',
  projectId: 'WALLETCONNECT_PROJECT_ID',
  chains: [base, baseSepolia],
  transports: {
    [base.id]: http('https://mainnet.base.org'),
    [baseSepolia.id]: http('https://sepolia.base.org')
  }
})

// In component
import { ConnectButton } from '@rainbow-me/rainbowkit'
<ConnectButton />
```

## Transaction Lifecycle UI

Every transaction has states — show them all:
```typescript
type TxState = 'idle' | 'signing' | 'pending' | 'confirming' | 'success' | 'error'

// idle → user clicks button
// signing → wallet popup open, waiting for user to sign
// pending → tx submitted, waiting in mempool
// confirming → tx included, waiting for enough confirmations
// success → confirmed + successful
// error → rejected, reverted, or timed out

function TxButton() {
  const [state, setState] = useState<TxState>('idle')

  return (
    <button disabled={state !== 'idle'}>
      {state === 'idle' && 'Buy Shares'}
      {state === 'signing' && 'Confirm in wallet...'}
      {state === 'pending' && 'Submitting...'}
      {state === 'confirming' && 'Confirming (1/3)...'}
      {state === 'success' && '✓ Done'}
      {state === 'error' && 'Failed — retry'}
    </button>
  )
}
```

## Contract Events for Real-Time Updates
```typescript
// Watch for events
publicClient.watchContractEvent({
  address: MARKET_CONTRACT,
  abi: MarketABI,
  eventName: 'SharesPurchased',
  args: { marketId: targetId },
  onLogs: (logs) => {
    logs.forEach(log => {
      console.log('New purchase:', log.args)
      // Update UI
    })
  }
})

// Historical events
const logs = await publicClient.getLogs({
  address: MARKET_CONTRACT,
  event: parseAbiItem('event SharesPurchased(bytes32 indexed marketId, address buyer, uint256 amount)'),
  fromBlock: deployBlock,
  toBlock: 'latest'
})
```

## Approval Flows (ERC-20)
```typescript
// Standard 2-step: check allowance → approve if needed → execute

async function buyWithUSDC(amount: bigint) {
  const allowance = await publicClient.readContract({
    address: USDC_ADDRESS,
    abi: erc20Abi,
    functionName: 'allowance',
    args: [userAddress, MARKET_CONTRACT]
  })

  if (allowance < amount) {
    // Step 1: Approve
    const approveHash = await walletClient.writeContract({
      address: USDC_ADDRESS,
      abi: erc20Abi,
      functionName: 'approve',
      args: [MARKET_CONTRACT, amount]
    })
    await publicClient.waitForTransactionReceipt({ hash: approveHash })
  }

  // Step 2: Execute
  const buyHash = await walletClient.writeContract({ /* buy */ })
}

// Better UX: Use ERC-20 Permit (EIP-2612) — single tx
// Sign permit off-chain, submit with buy tx
```

## Multicall — Batch Read Requests
```typescript
import { multicall } from 'viem/actions'

// Instead of 3 separate RPC calls, do 1
const [marketInfo, userBalance, totalVolume] = await publicClient.multicall({
  contracts: [
    { address: MARKET, abi: MarketABI, functionName: 'getMarketInfo', args: [id] },
    { address: USDC, abi: erc20Abi, functionName: 'balanceOf', args: [user] },
    { address: MARKET, abi: MarketABI, functionName: 'totalVolume', args: [id] }
  ]
})
```

## RPC Provider Strategy
```typescript
import { fallback, http } from 'viem'

// Never use a single RPC in production
const transport = fallback([
  http('https://base-mainnet.g.alchemy.com/v2/KEY'),  // Primary
  http('https://base.llamarpc.com'),                   // Fallback 1
  http('https://mainnet.base.org')                     // Fallback 2
])
```

## Indexing: The Graph vs Ponder
**The Graph**: Mature, decentralized, AssemblyScript mappings, GraphQL queries.
**Ponder**: TypeScript-native, faster DX, hot reloading, better for new projects.

```typescript
// Ponder schema
export const schema = createSchema((p) => ({
  Market: p.createTable({
    id: p.hex(),
    question: p.string(),
    yesPrice: p.bigint(),
    totalVolume: p.bigint(),
    resolved: p.boolean(),
  })
}))

// Ponder event handler
ponder.on("MarketFactory:MarketCreated", async ({ event, context }) => {
  await context.db.Market.create({
    id: event.args.marketId,
    data: {
      question: event.args.question,
      yesPrice: 500000n, // 50 cents
      totalVolume: 0n,
      resolved: false,
    }
  })
})
```

## ENS Resolution
```typescript
const ensName = await publicClient.getEnsName({ address: '0x...' })
const display = ensName ?? `${address.slice(0,6)}...${address.slice(-4)}`
```
