# Farcaster Frames

## NFT Mint Frame with Dynamic Supply Image

### Project Setup

```bash
npx create-next-app@latest sparta-frame --typescript --app
cd sparta-frame
npm install @coinbase/onchainkit viem @vercel/og
```

### Frame Entry Page

```typescript
// app/page.tsx
import { Metadata } from "next";
import { getFrameMetadata } from "@coinbase/onchainkit/frame";

const BASE_URL = process.env.NEXT_PUBLIC_URL!; // e.g., https://frame.agentspartai.com

export async function generateMetadata(): Promise<Metadata> {
  const frameMetadata = getFrameMetadata({
    buttons: [
      { label: "Mint Your Badge", action: "tx", target: `${BASE_URL}/api/frame/mint-tx` },
      { label: "View Collection", action: "link", target: "https://opensea.io/collection/agent-sparta" },
    ],
    image:    `${BASE_URL}/api/frame/image`,
    postUrl:  `${BASE_URL}/api/frame`,
  });

  return {
    title: "Agent Sparta — Mint Your Badge",
    openGraph: { title: "Agent Sparta", description: "Mint your competitor badge on Base" },
    other: { ...frameMetadata },
  };
}

export default function Page() {
  return (
    <main style={{ fontFamily: "monospace", padding: 40 }}>
      <h1>Agent Sparta Frames</h1>
      <p>This page powers the Farcaster Frame.</p>
      <p>Share this URL as a cast to enable minting.</p>
    </main>
  );
}
```

### Dynamic Image Endpoint

```typescript
// app/api/frame/image/route.tsx
import { ImageResponse } from "@vercel/og";
import { createPublicClient, http, formatEther } from "viem";
import { base } from "viem/chains";

const NFT_ABI = [
  { name: "totalSupply", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
  { name: "MAX_SUPPLY",  type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
  { name: "MINT_PRICE",  type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
] as const;

const NFT_ADDRESS = process.env.NFT_CONTRACT_ADDRESS as `0x${string}`;
const client = createPublicClient({ chain: base, transport: http(process.env.BASE_RPC_URL) });

export async function GET() {
  // Fetch live supply from contract
  const [minted, maxSupply, mintPrice] = await Promise.all([
    client.readContract({ address: NFT_ADDRESS, abi: NFT_ABI, functionName: "totalSupply" }),
    client.readContract({ address: NFT_ADDRESS, abi: NFT_ABI, functionName: "MAX_SUPPLY" }),
    client.readContract({ address: NFT_ADDRESS, abi: NFT_ABI, functionName: "MINT_PRICE" }),
  ]);

  const remaining  = Number(maxSupply) - Number(minted);
  const pct        = Math.floor((Number(minted) / Number(maxSupply)) * 100);
  const priceEth   = formatEther(mintPrice);

  return new ImageResponse(
    (
      <div
        style={{
          display: "flex", flexDirection: "column", alignItems: "center",
          justifyContent: "center", width: "100%", height: "100%",
          background: "linear-gradient(135deg, #0f0f1a 0%, #1a1a2e 50%, #16213e 100%)",
          fontFamily: "monospace",
        }}
      >
        {/* Logo */}
        <div style={{ display: "flex", fontSize: 80, marginBottom: 20 }}>⚔️</div>

        {/* Title */}
        <div style={{ display: "flex", color: "#FFD700", fontSize: 56, fontWeight: "bold", marginBottom: 12 }}>
          Agent Sparta
        </div>
        <div style={{ display: "flex", color: "#8b8b8b", fontSize: 28, marginBottom: 40 }}>
          On-chain AI competition badges
        </div>

        {/* Supply bar */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", width: 600 }}>
          <div style={{ display: "flex", justifyContent: "space-between", width: "100%", marginBottom: 8 }}>
            <span style={{ color: "#ccc", fontSize: 22 }}>{minted.toString()} minted</span>
            <span style={{ color: "#ccc", fontSize: 22 }}>{maxSupply.toString()} total</span>
          </div>
          {/* Progress bar background */}
          <div style={{ display: "flex", width: "100%", height: 20, background: "#2a2a3e", borderRadius: 10 }}>
            <div style={{
              display: "flex", width: `${pct}%`, height: "100%",
              background: "linear-gradient(90deg, #FFD700, #FFA500)", borderRadius: 10
            }} />
          </div>
          <div style={{ display: "flex", color: "#FFD700", fontSize: 26, marginTop: 16 }}>
            {remaining.toString()} remaining
          </div>
        </div>

        {/* Price */}
        <div style={{ display: "flex", marginTop: 32, color: "#4CAF50", fontSize: 30, fontWeight: "bold" }}>
          {priceEth} ETH to mint • Base network
        </div>
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
```

### Transaction Endpoint (User Signs Mint)

```typescript
// app/api/frame/mint-tx/route.ts
import { NextRequest, NextResponse } from "next/server";
import { encodeFunctionData, parseEther } from "viem";

const NFT_ABI = [
  { name: "mint", type: "function", stateMutability: "payable",
    inputs: [{ name: "to", type: "address" }], outputs: [] }
] as const;

export async function POST(req: NextRequest) {
  const body = await req.json();

  // The address connected to the user's Farcaster wallet
  const userAddress = body.untrustedData?.address as `0x${string}`;
  if (!userAddress) {
    return NextResponse.json({ error: "No address" }, { status: 400 });
  }

  // Return the transaction for the user to sign in Warpcast
  return NextResponse.json({
    chainId:  "eip155:8453", // Base
    method:   "eth_sendTransaction",
    params: {
      to:    process.env.NFT_CONTRACT_ADDRESS,
      data:  encodeFunctionData({
        abi:          NFT_ABI,
        functionName: "mint",
        args:         [userAddress],
      }),
      value: parseEther("0.001").toString(), // 0.001 ETH mint price
    },
  });
}
```

### Post-Action Handler (Show Success State)

```typescript
// app/api/frame/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getFrameMessage, FrameRequest } from "@coinbase/onchainkit/frame";

const BASE_URL = process.env.NEXT_PUBLIC_URL!;

export async function POST(req: NextRequest) {
  const body: FrameRequest = await req.json();

  // Validate the frame action (prevents spoofing)
  const { isValid, message } = await getFrameMessage(body, {
    neynarApiKey: process.env.NEYNAR_API_KEY,
  });
  if (!isValid) return NextResponse.json({ error: "Invalid frame message" }, { status: 400 });

  const buttonIndex = message.button;
  const txHash      = message.transaction?.hash;

  // User just completed a mint transaction
  if (txHash) {
    return new NextResponse(
      `<!DOCTYPE html><html><head>
      <meta property="fc:frame" content="vNext" />
      <meta property="fc:frame:image" content="${BASE_URL}/api/frame/success-image?tx=${txHash}" />
      <meta property="fc:frame:button:1" content="View on BaseScan" />
      <meta property="fc:frame:button:1:action" content="link" />
      <meta property="fc:frame:button:1:target" content="https://basescan.org/tx/${txHash}" />
      <meta property="fc:frame:button:2" content="View Collection" />
      <meta property="fc:frame:button:2:action" content="link" />
      <meta property="fc:frame:button:2:target" content="https://opensea.io/collection/agent-sparta" />
      </head></html>`,
      { headers: { "Content-Type": "text/html" } }
    );
  }

  // Default: show the mint frame again (refreshed supply)
  return new NextResponse(
    `<!DOCTYPE html><html><head>
    <meta property="fc:frame" content="vNext" />
    <meta property="fc:frame:image" content="${BASE_URL}/api/frame/image?t=${Date.now()}" />
    <meta property="fc:frame:button:1" content="Mint Your Badge" />
    <meta property="fc:frame:button:1:action" content="tx" />
    <meta property="fc:frame:button:1:target" content="${BASE_URL}/api/frame/mint-tx" />
    </head></html>`,
    { headers: { "Content-Type": "text/html" } }
  );
}
```

### Deploy

```bash
# Deploy to Vercel
vercel deploy --prod

# Test with Warpcast Frame Validator
# https://warpcast.com/~/developers/frames
# Paste your URL → validates the meta tags and simulates interactions

# Share the frame: post your app URL as a Farcaster cast
# Warpcast auto-detects fc:frame meta tags and renders the interactive frame
```

### Distribution Strategy

```
Best channels to cast into:
  /base        — Base ecosystem community
  /nft         — NFT collectors
  /frames      — Frame enthusiasts (meta but works)
  /defi        — If your NFT has utility

Engagement hooks that work:
  - Show personalized data: "You rank #42 of 500 holders"
  - Countdown timer in image: "89 left"
  - After mint: shareable image with their specific mint number
  - Leaderboard frame: "Top 10 Sparta holders this week"
```
