# Inscription & Metaprotocol Design

## The Metaprotocol Paradigm

A metaprotocol runs ON TOP of a blockchain without being enforced BY the blockchain's consensus. Bitcoin nodes don't validate BRC-20 transfers — indexers do.

```
Blockchain layer:   Stores data permanently (immutable, censorship-resistant)
Metaprotocol layer: Interprets that data according to off-chain rules
Indexer:            Software that reads the chain and maintains metaprotocol state
Client:             Wallet/app that constructs metaprotocol transactions

The blockchain doesn't know or care about the metaprotocol.
All enforcement is social consensus around the indexer rules.
```

## Designing a Metaprotocol

### 1. Data Encoding

Where and how to embed protocol data in transactions:

```
Bitcoin options:
  OP_RETURN: 80 bytes, unspendable, cheap, standard
  Taproot witness: unlimited size, slightly cheaper per byte, more complex
  Inscription envelope: Taproot script path, arbitrary data

Ethereum options:
  Transaction calldata: cheap (4 gas/zero, 16 gas/nonzero), permanent, indexable
  Event logs: slightly more expensive, but typed/indexed by Ethereum nodes natively
  SSTORE: expensive, but readable by other contracts

Best choice for most metaprotocols: calldata (Ethereum) or OP_RETURN (Bitcoin)
```

### 2. Protocol Format (JSON example)

```json
{
  "p": "sparta",
  "op": "enter",
  "challenge": "0xabc123...",
  "agent": "0xMyAgent",
  "commitment": "0xHashOfSubmission"
}
```

```json
{"p":"sparta","op":"resolve","challenge":"0xabc123","winner":"0xAgent","score":"847"}
```

### 3. Indexer Implementation

```typescript
// Indexer: reads every block, maintains metaprotocol state
import { createPublicClient, http } from "viem";

interface SpartaEntry {
  challengeId: string;
  agent: string;
  commitment: string;
  blockNumber: bigint;
  txHash: string;
}

const state = {
  entries: new Map<string, SpartaEntry[]>(),  // challengeId → entries
  results: new Map<string, string>(),           // challengeId → winner
};

async function indexBlock(blockNumber: bigint) {
  const block = await client.getBlock({ blockNumber, includeTransactions: true });

  for (const tx of block.transactions) {
    if (!tx.input || tx.input === "0x") continue;

    // Try to decode as Sparta metaprotocol operation
    try {
      const text = Buffer.from(tx.input.slice(2), "hex").toString("utf8");
      const op = JSON.parse(text);

      if (op.p !== "sparta") continue;

      // Validate sender (must be KYC-verified — checked against separate registry)
      const isVerified = await checkKYC(tx.from);

      if (op.op === "enter" && isVerified) {
        const entries = state.entries.get(op.challenge) ?? [];
        entries.push({
          challengeId: op.challenge,
          agent: tx.from,        // Sender IS the agent (authenticated by signing the tx)
          commitment: op.commitment,
          blockNumber,
          txHash: tx.hash,
        });
        state.entries.set(op.challenge, entries);
      }

      if (op.op === "resolve") {
        // Only accept from authorized oracle addresses
        if (ORACLE_ADDRESSES.includes(tx.from.toLowerCase())) {
          state.results.set(op.challenge, op.winner);
        }
      }

    } catch (e) {
      // Not valid JSON or not sparta protocol — ignore
    }
  }
}
```

### 4. Consensus Problem — The Core Challenge

```
What happens when indexers disagree?

BRC-20 real incident (2023):
  - A transfer inscription was interpreted differently by different indexers
  - Some indexers counted it as valid, others didn't
  - Two different "canonical" states of BRC-20 token balances existed simultaneously
  - Chaos: exchanges that integrated different indexers had different balances

Solutions:
  1. Commit to a single canonical indexer (centralized, fast, fragile)
  2. Require N/M indexer consensus to accept a state (decentralized, slower)
  3. Move validation on-chain (defeats the purpose for Bitcoin, but works on EVM)
  4. Formal spec: write an unambiguous specification document; index to it strictly

For Ethereum metaprotocols: consider just using smart contracts.
The calldata savings rarely justify the indexer complexity.

For Bitcoin: metaprotocols are the ONLY option for tokens/NFTs.
Accept the indexer risk; use multiple indexers and monitor for divergence.
```

### 5. Ethscriptions — EVM Metaprotocol

```typescript
// Create an Ethscription (store content permanently in Ethereum calldata)
const tx = await signer.sendTransaction({
    to: recipientAddress,
    data: ethers.toUtf8Bytes(
        `data:text/plain;rule=esip6,${JSON.stringify({
            protocol: "sparta",
            content: "Hello from Sparta!",
            timestamp: Date.now()
        })}`
    )
});
// This data is now permanently on Ethereum, interpretable by Ethscriptions indexer
// Cost: 16 gas/byte × 100 bytes ≈ 1,600 gas ≈ $0.0001 on Base
```

## When to Build Metaprotocol vs Smart Contract

| Use metaprotocol | Use smart contract |
|-----------------|-------------------|
| Target chain has no smart contracts (Bitcoin) | EVM chain, trust required |
| Need extreme data cost efficiency | Need on-chain enforcement |
| Purely informational protocol | Financial transactions |
| Willing to accept indexer risk | Need composability with other contracts |
| Global permanent data record | Real-time state changes |
