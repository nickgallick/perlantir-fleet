---
name: web3-frontend-and-integration
description: Web3 frontend development — wagmi hooks, viem client, wallet connection, contract interaction, The Graph, IPFS, account abstraction, hybrid Web2+Web3 architecture.
---

# Web3 Frontend & Integration

## Review Checklist

- [ ] Private keys NEVER in frontend or git (P0)
- [ ] Contract addresses verified against deployment records (P0)
- [ ] ABI matches deployed contract version (P1)
- [ ] Transaction parameters validated before signing (P1)
- [ ] Token approvals show amount and spender clearly (P1)
- [ ] Error handling for: wallet not connected, wrong network, tx rejected, insufficient gas, revert (P1)
- [ ] RPC provider URL in env var (not hardcoded) (P2)
- [ ] Loading states for all blockchain operations (P2)

---

## The Web3 Frontend Stack

```
wagmi       — React hooks for Ethereum (connect, read, write, watch)
viem        — Low-level TypeScript Ethereum client (wagmi is built on it)
RainbowKit  — Wallet connection UI (MetaMask, Coinbase, WalletConnect)
Alchemy     — RPC provider (don't run your own node)
```

## Wallet Connection

```tsx
import { createConfig, http } from 'wagmi'
import { base } from 'wagmi/chains'

const config = createConfig({
  chains: [base],
  transports: {
    [base.id]: http(`https://base-mainnet.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_KEY}`),
  },
})

// In component:
import { useAccount, useConnect, useDisconnect } from 'wagmi'

function WalletButton() {
  const { address, isConnected } = useAccount()
  const { connect, connectors } = useConnect()
  const { disconnect } = useDisconnect()
  
  if (isConnected) return (
    <button onClick={() => disconnect()}>
      {address?.slice(0, 6)}...{address?.slice(-4)}
    </button>
  )
  
  return <button onClick={() => connect({ connector: connectors[0] })}>Connect</button>
}
```

## Reading and Writing Contracts

```tsx
// READ: get balance (no transaction, no gas)
import { useReadContract } from 'wagmi'

function Balance({ address }: { address: string }) {
  const { data: balance } = useReadContract({
    address: ARENA_COINS_ADDRESS,
    abi: arenaCoinsABI,
    functionName: 'balanceOf',
    args: [address],
  })
  return <p>{formatUnits(balance ?? 0n, 18)} ARENA</p>
}

// WRITE: claim reward (sends transaction, costs gas)
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi'

function ClaimReward({ challengeId }: { challengeId: string }) {
  const { writeContract, data: hash, error } = useWriteContract()
  const { isLoading, isSuccess } = useWaitForTransactionReceipt({ hash })
  
  return (
    <button
      disabled={isLoading}
      onClick={() => writeContract({
        address: ARENA_COINS_ADDRESS,
        abi: arenaCoinsABI,
        functionName: 'claimReward',
        args: [challengeId],
      })}
    >
      {isLoading ? 'Confirming...' : isSuccess ? '✅ Claimed!' : 'Claim Reward'}
    </button>
  )
}
```

## Real-Time Event Listening

```tsx
import { useWatchContractEvent } from 'wagmi'

useWatchContractEvent({
  address: ARENA_COINS_ADDRESS,
  abi: arenaCoinsABI,
  eventName: 'RewardClaimed',
  onLogs(logs) {
    // Update leaderboard when someone claims
    invalidateLeaderboard()
  },
})
```

## Hybrid Architecture (Arena Web2 + Web3)

| Component | Where | Why |
|-----------|-------|-----|
| User accounts | **Supabase** | Fast auth, familiar UX |
| Challenge logic | **Supabase + Edge Functions** | Complex business logic, real-time |
| Leaderboards | **Supabase** | Fast reads, materialized views |
| Arena Coins balance | **On-chain (ERC-20)** | Transparent, tradeable, verifiable |
| Badge ownership | **On-chain (ERC-721)** | Ownable, displayable in wallets |
| Challenge results hash | **On-chain** | Immutable proof of results |
| Session transcripts | **Supabase Storage** | Large data, cheap |
| Real-time spectator | **Supabase Realtime** | WebSocket, fast |

**Pattern:** Supabase is the source of truth for speed. Blockchain is the source of truth for verification. Sync key data to chain after challenge completion.

## Account Abstraction (ERC-4337 — Invisible Web3 UX)

User signs up with email → platform creates a smart contract wallet behind the scenes → user interacts with blockchain without knowing it.

```ts
// Using Alchemy Account Kit
import { createModularAccountAlchemyClient } from '@alchemy/aa-alchemy'

const client = await createModularAccountAlchemyClient({
  apiKey: process.env.ALCHEMY_API_KEY,
  chain: base,
  signer: localAccountSigner, // derived from user's Supabase session
})

// Send gasless transaction (platform sponsors gas)
const result = await client.sendUserOperation({
  uo: {
    target: ARENA_COINS_ADDRESS,
    data: encodeFunctionData({
      abi: arenaCoinsABI,
      functionName: 'claimReward',
      args: [challengeId],
    }),
  },
})
```

**Benefits:** No MetaMask install, no ETH purchase, no gas understanding. Users interact with blockchain like a normal web app.

## The Graph (Indexing Blockchain Data)

```graphql
# Subgraph query: top earners this week
{
  rewardClaimeds(
    first: 10
    orderBy: amount
    orderDirection: desc
    where: { blockTimestamp_gt: "1711036800" }
  ) {
    winner
    amount
    challengeId
    blockTimestamp
  }
}
```

**Why:** Querying blockchain directly is slow and limited. The Graph indexes events into a fast GraphQL API.

## IPFS (Decentralized Storage)

```ts
// Store CID on-chain (cheap pointer), content on IPFS (cheap storage)
const cid = await pinata.upload(submissionData) // returns: QmXyz...
await contract.commitResult(challengeId, cid) // store CID on-chain
// Anyone can verify: fetch from IPFS using CID, compare to on-chain hash
```

## Testing Web3

```bash
# Local blockchain
anvil                           # Foundry's local Ethereum node
anvil --fork-url $ALCHEMY_URL   # Fork mainnet state

# Deploy test contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545

# E2E: Playwright + anvil
# Set up: start anvil, deploy contracts, run Playwright tests
```

## Sources
- wagmi documentation (hooks reference)
- viem documentation (TypeScript client)
- scaffold-eth-2 (full-stack Web3 reference)
- Alchemy Account Kit (account abstraction)
- The Graph documentation

## Changelog
- 2026-03-21: Initial skill — Web3 frontend and integration
