# Points Systems — Pre-Token to Airdrop

## Complete Pipeline: DB → Snapshot → Merkle → Claim → Frontend

### Database Schema (Postgres/Supabase)

```sql
-- User totals (write-ahead, update in real time)
CREATE TABLE user_points (
  wallet_address TEXT PRIMARY KEY,     -- lowercase, checksummed
  points         BIGINT  NOT NULL DEFAULT 0,
  updated_at     TIMESTAMPTZ DEFAULT now()
);

-- Immutable audit log of every points event
CREATE TABLE point_events (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_address TEXT    NOT NULL,
  action         TEXT    NOT NULL,   -- 'deposit', 'referral', 'hold_duration', 'social'
  points_earned  BIGINT  NOT NULL,
  metadata       JSONB,              -- e.g. {depositUSD: 1000, daysHeld: 7}
  tx_hash        TEXT,               -- on-chain tx that triggered this
  epoch          INT     NOT NULL DEFAULT 1,
  created_at     TIMESTAMPTZ DEFAULT now()
);

-- Published snapshots (immutable after creation)
CREATE TABLE snapshots (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  epoch          INT     NOT NULL,
  merkle_root    TEXT    NOT NULL,
  total_points   BIGINT  NOT NULL,
  total_users    INT     NOT NULL,
  snapshot_block BIGINT  NOT NULL,
  ipfs_cid       TEXT,               -- full tree data on IPFS
  created_at     TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_point_events_wallet  ON point_events(wallet_address);
CREATE INDEX idx_point_events_action  ON point_events(action);
CREATE INDEX idx_point_events_epoch   ON point_events(epoch);
CREATE INDEX idx_user_points_points   ON user_points(points DESC);
```

### Point Accrual Service

```typescript
// services/points.ts
import { createClient } from "@supabase/supabase-js";
import { getAddress } from "viem";

const db = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!);

export const POINT_RULES = {
  deposit: {
    // 1 point per $1 deposited per day held
    calculate: (depositUSD: number, daysHeld: number) =>
      Math.floor(depositUSD * daysHeld),
    maxPerDay: 10_000,
  },
  referral: {
    // 10% of referred user's total points (paid daily)
    calculate: (referredPoints: number) =>
      Math.floor(referredPoints * 0.10),
    maxPerReferral: 50_000,
  },
  holdBonus: {
    // 2x multiplier for wallets that staked in first 30 days
    multiplier: 2.0,
    eligibilityWindow: 30 * 24 * 60 * 60, // 30 days
  },
  social: {
    twitter_follow:  100,
    discord_join:    200,
    tweet_about:     500,
  },
} as const;

export async function awardPoints(
  walletAddress: string,
  action: string,
  pointsEarned: number,
  metadata?: Record<string, unknown>,
  txHash?: string
) {
  const address = getAddress(walletAddress).toLowerCase();

  // Sybil check: wallet must be >24h old with >0.01 ETH
  // (check this upstream before calling awardPoints)

  // Insert event record
  await db.from("point_events").insert({
    wallet_address: address,
    action,
    points_earned: pointsEarned,
    metadata,
    tx_hash: txHash,
  });

  // Upsert running total
  await db.rpc("increment_points", {
    p_wallet: address,
    p_amount: pointsEarned,
  });
  // SQL: INSERT INTO user_points (wallet_address, points) VALUES (p_wallet, p_amount)
  //      ON CONFLICT (wallet_address) DO UPDATE SET points = user_points.points + p_amount, updated_at = now()
}
```

### Anti-Gaming Rules

```typescript
// middleware/sybil.ts
import { createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";

const client = createPublicClient({ chain: mainnet, transport: http() });

export async function isSybilSuspect(address: `0x${string}`): Promise<boolean> {
  // Rule 1: Wallet age (first tx must be >7 days ago)
  const firstTxBlock = await getFirstTxBlock(address);
  const currentBlock = await client.getBlockNumber();
  const blocksOld    = Number(currentBlock) - firstTxBlock;
  if (blocksOld < 7 * 7200) return true; // 7 days * ~7200 blocks/day on mainnet

  // Rule 2: Minimum ETH balance
  const balance = await client.getBalance({ address });
  if (balance < 10_000_000_000_000_000n) return true; // <0.01 ETH

  // Rule 3: Check if funded from known Sybil cluster source
  const funder = await getFirstFundingSource(address);
  if (funder && await isFlaggedFunder(funder)) return true;

  return false;
}

// Rule 4: Referral loop detection
export async function detectReferralLoop(
  referrer: string, referred: string
): Promise<boolean> {
  // Check if referred user has previously referred the referrer
  const { data } = await db
    .from("referrals")
    .select("referrer")
    .eq("referred", referrer)
    .single();
  return data?.referrer === referred; // If yes, it's a loop
}
```

### Snapshot and Merkle Tree Generation

```typescript
// scripts/generate-snapshot.ts
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { parseEther, getAddress } from "viem";
import { create } from "kubo-rpc-client"; // IPFS client

const TOTAL_AIRDROP_TOKENS = parseEther("100000000"); // 100M tokens
const IPFS = create({ url: process.env.IPFS_API_URL! });

export async function generateSnapshot(epoch: number) {
  console.log(`Generating snapshot for epoch ${epoch}...`);

  // Fetch all users with points
  const { data: users } = await db
    .from("user_points")
    .select("wallet_address, points")
    .gt("points", 0)
    .order("points", { ascending: false });

  if (!users?.length) throw new Error("No users found");

  // Calculate total points
  const totalPoints = users.reduce((sum, u) => sum + BigInt(u.points), 0n);
  console.log(`Total users: ${users.length}, Total points: ${totalPoints}`);

  // Compute each user's token allocation
  const leaves: [string, string][] = users.map((user) => {
    const tokenAmount = (BigInt(user.points) * TOTAL_AIRDROP_TOKENS) / totalPoints;
    return [getAddress(user.wallet_address), tokenAmount.toString()];
  });

  // Build Merkle tree
  const tree = StandardMerkleTree.of(leaves, ["address", "uint256"]);
  const merkleRoot = tree.root;
  console.log("Merkle root:", merkleRoot);

  // Upload full tree to IPFS (users need proofs to claim)
  const treeJson = JSON.stringify(tree.dump());
  const { cid } = await IPFS.add(treeJson);
  const ipfsCid = cid.toString();
  console.log("IPFS CID:", ipfsCid);

  // Save snapshot to DB
  const snapshotBlock = await provider.getBlockNumber();
  await db.from("snapshots").insert({
    epoch,
    merkle_root:    merkleRoot,
    total_points:   totalPoints.toString(),
    total_users:    users.length,
    snapshot_block: snapshotBlock,
    ipfs_cid:       ipfsCid,
  });

  // Return data needed to deploy claim contract
  return { merkleRoot, ipfsCid, tree, leaves };
}

// Get proof for a specific user (called by frontend API)
export function getUserProof(tree: ReturnType<typeof StandardMerkleTree.of>, address: string) {
  for (const [i, [addr, amount]] of tree.entries()) {
    if (addr.toLowerCase() === address.toLowerCase()) {
      return { proof: tree.getProof(i), amount };
    }
  }
  return null; // User not in airdrop
}
```

### On-Chain Claim Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SpartaAirdropClaim is Ownable {
    using SafeERC20 for IERC20;

    IERC20  public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public immutable claimDeadline;

    mapping(address => bool) public hasClaimed;

    uint256 public totalClaimed;
    uint256 public claimCount;

    event Claimed(address indexed account, uint256 amount);

    constructor(
        address _token,
        bytes32 _merkleRoot,
        uint256 _claimDurationDays
    ) Ownable(msg.sender) {
        token         = IERC20(_token);
        merkleRoot    = _merkleRoot;
        claimDeadline = block.timestamp + (_claimDurationDays * 1 days);
    }

    /// @notice Claim your airdrop allocation
    /// @param amount   Your allocated amount (from the merkle tree)
    /// @param proof    Your merkle proof (from the API or IPFS tree)
    function claim(uint256 amount, bytes32[] calldata proof) external {
        require(block.timestamp <= claimDeadline, "Claim period ended");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(amount > 0, "Nothing to claim");

        // Verify: the leaf is (address, amount) as encoded in the tree
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        hasClaimed[msg.sender] = true;
        totalClaimed += amount;
        claimCount++;

        token.safeTransfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    /// @notice Recover unclaimed tokens after deadline → return to treasury
    function recoverUnclaimed() external onlyOwner {
        require(block.timestamp > claimDeadline, "Claim period active");
        uint256 remaining = token.balanceOf(address(this));
        token.safeTransfer(owner(), remaining);
    }
}
```

### Frontend Claim Flow

```typescript
// app/claim/page.tsx
"use client";
import { useAccount, useWriteContract, useReadContract } from "wagmi";
import { useState, useEffect } from "react";

const CLAIM_ABI = [
  { name: "claim",      type: "function", stateMutability: "nonpayable",
    inputs: [{ name: "amount", type: "uint256" }, { name: "proof", type: "bytes32[]" }], outputs: [] },
  { name: "hasClaimed", type: "function", stateMutability: "view",
    inputs: [{ name: "", type: "address" }], outputs: [{ type: "bool" }] },
  { name: "claimDeadline", type: "function", stateMutability: "view",
    inputs: [], outputs: [{ type: "uint256" }] },
] as const;

export default function ClaimPage() {
  const { address } = useAccount();
  const { writeContractAsync } = useWriteContract();
  const [allocation, setAllocation] = useState<{ amount: string; proof: string[] } | null>(null);

  // Fetch user's allocation from API
  useEffect(() => {
    if (!address) return;
    fetch(`/api/airdrop/proof?address=${address}`)
      .then(r => r.json())
      .then(data => setAllocation(data.allocation ?? null));
  }, [address]);

  const { data: alreadyClaimed } = useReadContract({
    address: CLAIM_CONTRACT_ADDRESS,
    abi: CLAIM_ABI,
    functionName: "hasClaimed",
    args: [address!],
    query: { enabled: !!address },
  });

  const handleClaim = async () => {
    if (!allocation) return;
    await writeContractAsync({
      address: CLAIM_CONTRACT_ADDRESS,
      abi: CLAIM_ABI,
      functionName: "claim",
      args: [BigInt(allocation.amount), allocation.proof as `0x${string}`[]],
    });
  };

  if (!allocation) return <p>Not eligible — no points in this epoch</p>;
  if (alreadyClaimed) return <p>✅ Already claimed {formatTokenAmount(allocation.amount)} SPARTA</p>;

  return (
    <div>
      <h1>Claim Your SPARTA Tokens</h1>
      <p>Your allocation: {formatTokenAmount(allocation.amount)} SPARTA</p>
      <button onClick={handleClaim}>Claim Now</button>
    </div>
  );
}
```

### TGE Sequence Checklist

```
□ Final snapshot: freeze points database (no more writes)
□ Run generate-snapshot.ts → get merkleRoot + ipfsCid
□ Deploy token contract (if not already)
□ Deploy SpartaAirdropClaim with merkleRoot + 90 day claim window
□ Transfer airdrop tokens to claim contract
□ Verify: claim contract balance == total allocation
□ Publish IPFS CID publicly so anyone can verify the tree
□ Open claim UI
□ Simultaneously: add liquidity to DEX (so claimed tokens have value)
□ Announce: tweet, Discord, Telegram with claim URL
□ Monitor: check claim volume in first 24h, confirm no errors
□ After deadline: call recoverUnclaimed() to return unclaimed tokens to treasury
```
