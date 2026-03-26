# Decentralized Storage & Data

## IPFS Integration

```typescript
import { PinataSDK } from "pinata";
import fs from "fs";

const pinata = new PinataSDK({ pinataJwt: process.env.PINATA_JWT! });

// Upload single file
async function uploadFile(filePath: string): Promise<string> {
    const file = new File([fs.readFileSync(filePath)], path.basename(filePath));
    const result = await pinata.upload.file(file);
    console.log(`CID: ${result.IpfsHash}`);
    return result.IpfsHash;
}

// Upload directory (NFT metadata folder)
async function uploadDirectory(dirPath: string): Promise<string> {
    const files = fs.readdirSync(dirPath).map(name => {
        const content = fs.readFileSync(path.join(dirPath, name));
        return new File([content], name, { type: "application/json" });
    });

    const result = await pinata.upload.fileArray(files);
    return result.IpfsHash; // Access individual files: ipfs://{CID}/0.json
}

// Upload JSON directly
async function uploadJSON(data: object): Promise<string> {
    const result = await pinata.upload.json(data);
    return result.IpfsHash;
}

// Multiple gateway fallbacks for resilience
const GATEWAYS = [
    "https://ipfs.io/ipfs/",
    "https://cloudflare-ipfs.com/ipfs/",
    "https://gateway.pinata.cloud/ipfs/",
    "https://nftstorage.link/ipfs/"
];

async function fetchFromIPFS(cid: string): Promise<Response> {
    for (const gateway of GATEWAYS) {
        try {
            const response = await fetch(`${gateway}${cid}`, { signal: AbortSignal.timeout(5000) });
            if (response.ok) return response;
        } catch {}
    }
    throw new Error("All IPFS gateways failed");
}
```

## Arweave for Permanent NFT Metadata

```typescript
import Irys from "@irys/sdk";

async function uploadToArweave(filePath: string): Promise<string> {
    const irys = new Irys({
        network: "mainnet",
        token:   "ethereum",
        key:     process.env.PRIVATE_KEY!,
    });

    // Check upload cost
    const price = await irys.getPrice(fs.statSync(filePath).size);
    console.log(`Cost: ${irys.utils.fromAtomic(price)} ETH`);

    // Fund if needed (one-time cost, stored permanently)
    await irys.fund(price);

    const result = await irys.uploadFile(filePath, {
        tags: [
            { name: "Content-Type",      value: "application/json" },
            { name: "App-Name",          value: "SpartaNFT" },
            { name: "Type",              value: "NFT-Metadata" }
        ]
    });

    return `https://arweave.net/${result.id}`;
}

// For high-value collections: use Arweave for metadata, IPFS for images
// Or: use Arweave for both (expensive but most permanent)
```

## On-Chain Data Storage Patterns

```solidity
// Pattern 1: Events as permanent log (cheapest)
event MetadataUpdate(uint256 indexed tokenId, string uri);

function updateTokenURI(uint256 tokenId, string calldata uri) external onlyOwner {
    emit MetadataUpdate(tokenId, uri); // 375 gas + 8 gas/byte
    // The Graph can index this — no storage needed on-chain
}

// Pattern 2: Calldata for cheaper input (not readable by contracts)
function recordBatch(bytes calldata data) external {
    // Data stored in transaction calldata — cheapest persistent storage
    // 16 gas/non-zero byte vs 20,000 gas/slot SSTORE
    // Can be read by off-chain indexers from the transaction trace
    emit DataRecorded(keccak256(data));
}

// Pattern 3: EIP-4844 Blob (cheapest, but pruned after ~18 days)
// Used by rollups for temporary data availability
// blobs are available via beacon node API for 4096 epochs (~18 days)

// Pattern 4: SSTORE (most expensive, most readable)
mapping(uint256 => string) public tokenURIs; // Full on-chain storage
// Only justified for data that OTHER contracts need to read
```

## NFT Metadata Best Practices

```
Storage Tier Decision Tree:
  Is this a 1-of-1 fine art NFT worth $10K+?
    → Yes → Arweave (pay ~$1-5 for permanent storage)
    → No  → IPFS pinned on Pinata + NFT.Storage (redundancy)

  Will the metadata EVER change?
    → No  → Upload final metadata, done
    → Yes → Use contract-side tokenURI that reads from upgradeable source
           → Migrate IPFS folder when metadata changes (new CID)

  Do you need the metadata in contract storage?
    → No (99% of cases) → IPFS or Arweave
    → Yes (on-chain SVG, data availability) → Encode as base64 in tokenURI

Redundancy strategy:
  1. Pin on Pinata (primary)
  2. Pin on NFT.Storage (secondary, free)
  3. Mirror on Arweave for top-tier collections
  4. Never use http:// centralized URLs
```

## IPFS vs Arweave vs Filecoin

| Factor | IPFS | Arweave | Filecoin |
|--------|------|---------|---------|
| Cost | Free (with pinning service ~$20/mo) | ~$5-15/GB one-time | Cheapest bulk storage |
| Permanence | Depends on pinning | 200+ years guaranteed | Contract duration |
| Retrieval speed | Fast (CDN gateways) | Moderate | Slow |
| Best for | NFT metadata, images | High-value permanent data | Large archives |
| Main risk | Pinning service goes offline | None | Storage provider failure |
