# Airdrop & Distribution

## Merkle Airdrop — Production Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleAirdrop is Ownable {
    using SafeERC20 for IERC20;

    IERC20  public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public immutable expiryTime;     // Unclaimed tokens recoverable after expiry

    // Bitmap for gas-efficient claim tracking
    // 256 claims per uint256 slot → 10K claims = 40 slots (vs 10K mapping entries)
    mapping(uint256 => uint256) private _claimedBitmap;

    event Claimed(address indexed claimant, uint256 amount);
    event Expired(uint256 unclaimed);

    constructor(address _token, bytes32 _root, uint256 _expiryDays) {
        token      = IERC20(_token);
        merkleRoot = _root;
        expiryTime = block.timestamp + (_expiryDays * 1 days);
    }

    function claim(
        uint256 index,      // position in the merkle list (for bitmap)
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        require(block.timestamp < expiryTime, "Airdrop expired");
        require(!isClaimed(index), "Already claimed");

        // Verify merkle proof: leaf = hash(index, address, amount)
        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        _setClaimed(index);
        token.safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex  = index % 256;
        return (_claimedBitmap[wordIndex] >> bitIndex) & 1 == 1;
    }

    function _setClaimed(uint256 index) internal {
        uint256 wordIndex = index / 256;
        uint256 bitIndex  = index % 256;
        _claimedBitmap[wordIndex] |= (1 << bitIndex);
    }

    // Recover unclaimed tokens after expiry
    function recoverUnclaimed() external onlyOwner {
        require(block.timestamp >= expiryTime, "Not expired");
        uint256 bal = token.balanceOf(address(this));
        token.safeTransfer(owner(), bal);
        emit Expired(bal);
    }
}
```

## Merkle Tree Generation (Off-Chain)

```typescript
import { MerkleTree } from "merkletreejs";
import { keccak256, solidityPacked } from "ethers";

interface Recipient {
    address: string;
    amount: bigint;
}

function buildMerkleTree(recipients: Recipient[]) {
    // Sort for determinism
    recipients.sort((a, b) => a.address.localeCompare(b.address));

    const leaves = recipients.map((r, index) =>
        keccak256(solidityPacked(
            ["uint256", "address", "uint256"],
            [index, r.address, r.amount]
        ))
    );

    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

    // Generate claim data for each recipient
    const claims = recipients.map((r, index) => ({
        index,
        address: r.address,
        amount:  r.amount.toString(),
        proof:   tree.getHexProof(leaves[index])
    }));

    return {
        root:   tree.getHexRoot(),
        claims
    };
}

// Usage
const { root, claims } = buildMerkleTree([
    { address: "0xAlice", amount: 1000n * 10n**18n },
    { address: "0xBob",   amount: 500n  * 10n**18n },
]);

// Deploy airdrop contract with root
// Upload claims JSON to IPFS for users to fetch their proofs
```

## Airdrop Strategy Comparison

| Strategy | Gas Cost | Sybil Risk | Best For |
|----------|----------|-----------|---------|
| Merkle claim | Low (user pays) | Medium | Most airdrops |
| Direct send | High (deployer pays) | Medium | Small lists <1K |
| Snapshot + claim | Low | High | Token holder rewards |
| Activity-based | Medium | Low | Protocol users |
| Vested stream | Medium | Low | Team/investor allocations |

## Sybil Detection Algorithm

```python
import pandas as pd
import networkx as nx

def detect_sybils(transactions_df, airdrop_candidates):
    """
    Cluster wallets that were likely created by the same person.
    Common signals: funded from same source, identical behavior patterns.
    """
    G = nx.DiGraph()

    # Build graph: edge = wallet funded another wallet
    for _, tx in transactions_df.iterrows():
        if tx['value'] < 0.01e18:  # Small ETH transfers = likely wallet funding
            G.add_edge(tx['from'], tx['to'])

    # Find clusters (weakly connected components)
    clusters = list(nx.weakly_connected_components(G))

    sybil_addresses = set()
    for cluster in clusters:
        cluster_candidates = cluster & set(airdrop_candidates)
        if len(cluster_candidates) > 5:  # >5 wallets from same source = likely Sybil
            # Keep the 1 most active, flag the rest
            most_active = max(cluster_candidates, key=lambda a: get_tx_count(a))
            sybil_addresses |= (cluster_candidates - {most_active})

    return sybil_addresses

# Apply Gitcoin Passport score gate (API)
async def filter_by_passport_score(addresses, min_score=15):
    eligible = []
    for addr in addresses:
        score = await fetch_passport_score(addr)
        if score >= min_score:
            eligible.append(addr)
    return eligible
```

## Vesting Contract for Airdrop Recipients

```solidity
contract VestedAirdrop {
    // Tokens vest over 12 months with 3-month cliff
    uint256 public constant CLIFF    = 90  days;
    uint256 public constant DURATION = 365 days;
    uint256 public startTime;

    mapping(address => uint256) public totalAllocation;
    mapping(address => uint256) public claimed;

    function claimVested() external {
        uint256 elapsed = block.timestamp - startTime;
        if (elapsed < CLIFF) revert("Still in cliff");

        uint256 vested = totalAllocation[msg.sender] * min(elapsed, DURATION) / DURATION;
        uint256 claimable = vested - claimed[msg.sender];
        require(claimable > 0, "Nothing to claim");

        claimed[msg.sender] += claimable;
        token.safeTransfer(msg.sender, claimable);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```
