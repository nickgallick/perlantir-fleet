# Metaplex Candy Machine — Solana NFT Launch

## Install Sugar CLI

```bash
bash <(curl -sSf https://sugar.metaplex.com/install.sh)
sugar --version
```

## Asset Preparation

```
assets/
  0.png       # NFT image
  0.json      # NFT metadata
  1.png
  1.json
  ...
  collection.png
  collection.json
```

```json
// 0.json — per-NFT metadata
{
  "name": "Agent Sparta #0",
  "symbol": "SPARTA",
  "description": "An Agent Sparta competitor badge",
  "image": "0.png",
  "attributes": [
    { "trait_type": "Tier", "value": "Gold" },
    { "trait_type": "ELO", "value": "1850" }
  ],
  "properties": {
    "files": [{ "uri": "0.png", "type": "image/png" }],
    "creators": [{ "address": "YOUR_WALLET", "share": 100 }]
  }
}
```

## Configure Candy Machine

```bash
sugar config create
# Interactive — sets:
# - price (SOL)
# - number of items
# - go-live date
# - creator splits
# - guards (allowlist, mint limit, etc.)
```

```json
// config.json output
{
  "price": 0.1,
  "number": 1000,
  "symbol": "SPARTA",
  "sellerFeeBasisPoints": 500,
  "isMutable": true,
  "isSequential": false,
  "creators": [
    { "address": "YOUR_WALLET", "share": 100 }
  ],
  "uploadMethod": "bundlr",
  "awsConfig": null,
  "nftStorageAuthToken": null,
  "shdwStorageAccount": null,
  "pinataConfig": null
}
```

## Deploy Flow

```bash
# 1. Upload assets to Arweave via Bundlr
sugar upload

# 2. Deploy Candy Machine on-chain
sugar deploy

# 3. Verify everything uploaded correctly
sugar verify

# 4. Test mint
sugar mint

# 5. Show Candy Machine state
sugar show
```

## Candy Machine Guards (Mint Conditions)

```typescript
// Using UMI SDK — add guards during deployment or after
import { createUmi } from "@metaplex-foundation/umi-bundle-defaults";
import { mplCandyMachine, create, addConfigLines } from "@metaplex-foundation/mpl-candy-machine";
import { generateSigner, percentAmount, some, none, dateTime } from "@metaplex-foundation/umi";

const umi = createUmi("https://api.devnet.solana.com").use(mplCandyMachine());

// Update candy machine guards
await updateCandyGuard(umi, {
  candyMachine: candyMachinePublicKey,
  guards: {
    // SOL payment
    solPayment: some({ lamports: { basisPoints: 100_000_000n, identifier: "SOL" }, destination: treasuryPublicKey }),
    // Time-gated mint
    startDate: some({ date: dateTime("2024-06-01T00:00:00Z") }),
    endDate:   some({ date: dateTime("2024-06-30T23:59:59Z") }),
    // Max per wallet
    mintLimit: some({ id: 1, limit: 3 }),
    // Allowlist (WL phase)
    allowList: some({ merkleRoot: YOUR_MERKLE_ROOT }),
  },
});
```

## Frontend Minting

```typescript
import { createUmi } from "@metaplex-foundation/umi-bundle-defaults";
import { walletAdapterIdentity } from "@metaplex-foundation/umi-signer-wallet-adapters";
import { mplCandyMachine, fetchCandyMachine, mintV2 } from "@metaplex-foundation/mpl-candy-machine";
import { generateSigner, transactionBuilder } from "@metaplex-foundation/umi";
import { useWallet } from "@solana/wallet-adapter-react";

const CANDY_MACHINE_ID = "YOUR_CM_ID";

export function MintButton() {
  const wallet = useWallet();

  const handleMint = async () => {
    const umi = createUmi("https://api.mainnet-beta.solana.com")
      .use(mplCandyMachine())
      .use(walletAdapterIdentity(wallet));

    const cm = await fetchCandyMachine(umi, CANDY_MACHINE_ID);
    const nftMint = generateSigner(umi);

    const tx = await transactionBuilder()
      .add(mintV2(umi, {
        candyMachine: cm.publicKey,
        nftMint,
        collectionMint: cm.collectionMint,
        collectionUpdateAuthority: cm.authority,
      }))
      .sendAndConfirm(umi);

    console.log("Minted:", nftMint.publicKey.toString());
  };

  return <button onClick={handleMint}>Mint NFT</button>;
}
```

## Compressed NFTs (10K+ collections)

```typescript
// 1000x cheaper — uses Merkle tree state compression
import { mplBubblegum, createTree, mintToCollectionV1 } from "@metaplex-foundation/mpl-bubblegum";

// Create Merkle tree (do once)
const treeConfig = await createTree(umi, {
  maxDepth: 14,        // 2^14 = 16,384 max NFTs
  maxBufferSize: 64,
  canopyDepth: 0,
});

// Mint compressed NFT
await mintToCollectionV1(umi, {
  leafOwner: recipientPublicKey,
  merkleTree: treeConfig.publicKey,
  collectionMint: collectionMint.publicKey,
  metadata: {
    name: "Agent Sparta #1",
    uri: "https://arweave.net/YOUR_METADATA_URI",
    sellerFeeBasisPoints: 500,
    collection: { key: collectionMint.publicKey, verified: false },
    creators: [{ address: umi.identity.publicKey, verified: true, share: 100 }],
  },
}).sendAndConfirm(umi);
```

## Post-Deploy Marketplace

```bash
# Magic Eden — submit via creator portal
# https://magiceden.io/launchpad — contact their team for launchpad partnership
# After verification: collection shows up with verified checkmark

# Tensor — auto-indexed for Metaplex collections
# Submit for verified status at tensor.trade

# Set royalties via seller_fee_basis_points in collection metadata (500 = 5%)
```
