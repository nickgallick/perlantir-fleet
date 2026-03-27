# Bouts — Smart Contract Architecture Spec
**Author:** Chain  
**Date:** 2026-03-27  
**Status:** Design complete — awaiting Nick decisions on key choices  
**Counsel review required:** YES (flagged below)

---

## What's Already Deployed

| Contract | Address | Purpose |
|----------|---------|---------|
| `BoutsJudgeCommit` | `0x267837dEB1ae92Eb4F321De99F893802B20AAD9a` | Commit-reveal for judge scores |
| Oracle wallet | `0x7eb41C96A11FAa55887188a6eD2538968D521722` | Signs all on-chain actions |

Everything below builds on top of this foundation.

---

## Contract Suite Overview

```
BoutsJudgeCommit (deployed ✅)
    ↓ feeds scores into
BoutsScoreAggregator (new)
    ↓ feeds final score into
BoutsEscrow (new) — releases USDC prizes
    ↓ agent identity anchored by
BoutsAgentSBT (new) — soulbound NFT carrying ELO
    ↓ performance data anchored by
BoutsDataRegistry (new) — IPFS hash commitments
```

---

## 1. Scoring Commitment Contract — BoutsScoreAggregator

### What it does
Takes the 3 committed + revealed scores from `BoutsJudgeCommit`, applies the disagreement logic, and produces a single canonical final score that triggers prize release.

### Already handled
`BoutsJudgeCommit` already does commit-reveal — scores are tamper-proof on-chain before aggregation. No redesign needed there.

### Disagreement logic (on-chain)

```
Given scores: [claude, gpt4o, gemini] — range 10-100

Rule 1 — All within 10pts of each other:
  finalScore = median(all three)
  
Rule 2 — One outlier >15pts from median:
  identify outlier
  finalScore = average(remaining two)
  emit OutlierDiscarded(entryId, provider, outlierScore)
  
Rule 3 — All three disagree (max spread >15pts, no single outlier):
  emit DisputeFlagged(entryId, scores)
  finalScore = 0  ← blocks prize release
  oracle must resolve manually
```

**Gas cost on Base:** ~25k gas per aggregation call. At current Base prices: ~$0.00003 per entry. Negligible.

**Implementation note:** Integer arithmetic only — no floating point on-chain. All scores stored as uint8 (10-100). Median of 3 = sort array, take middle value.

### Interface

```solidity
function aggregateScores(
    bytes32 entryId,
    bytes32 challengeId
) external onlyOracle returns (uint8 finalScore, AggregationResult result)

enum AggregationResult { Consensus, OutlierDiscarded, Disputed }

event ScoreFinalized(bytes32 indexed entryId, bytes32 indexed challengeId, uint8 finalScore, AggregationResult result)
event OutlierDiscarded(bytes32 indexed entryId, string provider, uint8 outlierScore)
event DisputeFlagged(bytes32 indexed entryId, uint8 claude, uint8 gpt4o, uint8 gemini)
```

---

## 2. ELO Contract — Decision Required

### The core question: on-chain ELO vs off-chain + commitment

**Option A — Fully on-chain ELO**

ELO formula runs in Solidity. Every match updates both agents' ratings in the contract.

```
K = 32
expectedScore = 1 / (1 + 10^((ratingB - ratingA) / 400))
newRating = oldRating + K * (actualScore - expectedScore)
```

Pros:
- Fully trustless — nobody can manipulate ratings
- Users can verify any rating change

Cons:
- Fixed-point arithmetic required (Solidity has no floats) — adds ~150 lines of library code
- Every challenge resolution costs ~40k gas per agent updated
- Can't retroactively fix a bug without redeploying

**Option B — Off-chain ELO + on-chain commitment (recommended)**

ELO calculated in Supabase (already exists in `src/lib/elo.ts`). After each calculation, post a commitment:

```
commit: keccak256(agentId, newEloRating, challengeId, timestamp)
```

Pros:
- Cheap — one small tx per challenge resolution
- Can fix ELO calculation bugs without contract changes
- Existing `calculate_elo` RPC function works as-is

Cons:
- ELO calculation itself not trustless (you run it)
- Users trust you computed it correctly (mitigated by open-sourcing the formula)

**My recommendation: Option B.** Fully on-chain ELO is a complexity/cost trap for V1. The commitment proves the rating existed at a point in time. Open-source the formula. Move to on-chain if the product demands it later.

### Soulbound NFT — BoutsAgentSBT

**Purpose:** Each registered agent gets a non-transferable NFT that serves as its permanent on-chain identity. The ELO rating, win/loss record, and weight class are attributes on this token.

```solidity
// ERC-5192 (minimal soulbound) — no transfer, no approval
contract BoutsAgentSBT is ERC5192 {
    struct AgentProfile {
        string agentId;         // UUID from Supabase
        string weightClass;     // frontier/contender/scrapper/etc.
        uint16 eloRating;       // committed ELO
        uint32 challengesPlayed;
        uint32 wins;
        address owner;
        uint256 mintedAt;
    }
    
    mapping(uint256 => AgentProfile) public profiles;
    mapping(string => uint256) public agentIdToTokenId; // UUID → tokenId
    
    function mint(address to, string calldata agentId, string calldata weightClass) external onlyOracle
    function updateRating(uint256 tokenId, uint16 newElo, uint32 wins, uint32 played) external onlyOracle
    function locked(uint256 tokenId) external pure returns (bool) { return true; } // always locked
}
```

**Token URI:** Points to IPFS JSON with agent name, description, stats. Metadata updates when ELO updates via `updateRating()`.

**Model version handling:** The NFT tracks `weightClass` not model version. If an agent switches from GPT-4o to Claude, the owner updates via the web app — the NFT reflects the current weight class. Historical model data lives in Supabase, not on-chain.

**Gas:** Mint ~80k. Update ~30k. Both trivial on Base.

---

## 3. Prize Escrow Contract — BoutsEscrow

### Flow

```
1. Challenge created on-chain: challengeId, entryFeeUSDC, startTime, endTime
2. Agents pay entry fee → USDC locked in contract
3. Challenge closes → scores aggregated → BoutsScoreAggregator calls finalizeChallenge()
4. Contract sorts agents by finalScore → pays out:
   - 1st: 50% of pool
   - 2nd: 30% of pool  
   - 3rd: 20% of pool
   (configurable per challenge)
5. Platform fee (5%) taken before payout
```

### USDC handling

**Always use USDC.** Not ETH. Reasons:
- No price volatility risk for prize pools
- Users know exactly what they're winning
- USDC on Base: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`

Entry fees are in USDC. Prizes paid in USDC. Platform fee collected in USDC.

### Edge cases

```
Ties: split the prize tier equally between tied agents
Disqualified agents: their entry fee stays in pool (redistributed to other winners)
Cancelled challenges: all entry fees refunded in full
Disputed scores (Rule 3 above): prize frozen until oracle resolves
Min entries: if < 2 agents enter, challenge auto-cancels and refunds
```

### Interface

```solidity
function createChallenge(
    bytes32 challengeId,
    uint256 entryFeeUSDC,    // 6 decimals — 5 USDC = 5_000_000
    uint256 endTime,
    uint8[3] calldata payoutBps  // e.g. [5000, 3000, 2000] = 50/30/20%
) external onlyOracle

function enterChallenge(bytes32 challengeId) external
    // caller must have approved USDC transfer first

function finalizeChallenge(
    bytes32 challengeId,
    bytes32[] calldata entryIds,  // ordered by rank (1st to last)
    uint8[] calldata finalScores
) external onlyOracle

function cancelChallenge(bytes32 challengeId) external onlyOracle
    // triggers full refund to all entrants

function withdrawPlatformFees(address to) external onlyOwner
```

### Security notes

- Re-entrancy guard on all USDC transfer functions
- Pull pattern for withdrawals (agents claim their prize, not pushed)
- Challenge state machine: `Open → Active → Scoring → Complete | Cancelled`
- Emergency pause function (owner only)

---

## 4. Data Licensing Architecture — BoutsDataRegistry

### The asset

Longitudinal agent performance data is the most valuable thing Bouts will own long-term. Every score, every challenge, every judge breakdown — indexed by agent, model, challenge type, time. This is what companies will pay to license for AI benchmarking.

### On-chain vs IPFS

**Don't put raw data on-chain.** Too expensive, unnecessary.

**Architecture:**
1. Raw data lives in Supabase (already there)
2. Periodically (weekly/monthly), export a dataset snapshot as JSON
3. Upload to IPFS → get CID
4. Commit `keccak256(CID + timestamp + datasetVersion)` on-chain

```solidity
contract BoutsDataRegistry {
    struct DatasetCommitment {
        string ipfsCID;
        bytes32 contentHash;
        uint256 timestamp;
        string datasetVersion;  // e.g. "2026-Q1"
        string description;
    }
    
    DatasetCommitment[] public commitments;
    
    function commitDataset(
        string calldata ipfsCID,
        bytes32 contentHash,
        string calldata version,
        string calldata description
    ) external onlyOwner
}
```

**Licensing model (off-chain):** Buyers purchase a license via Stripe/crypto. They receive the IPFS CID + access credentials. They can verify the data hasn't been tampered with by checking the on-chain hash. You control access via an API gateway — not on-chain.

**Why this works:** The on-chain hash proves data integrity. You don't need to put the actual data on-chain to sell it.

---

## 5. Key Decisions for Nick

### Decision 1: Chain ✅ Already decided
**Base mainnet.** Low gas, EVM-compatible, Coinbase-backed. `BoutsJudgeCommit` is already deployed here. Everything else goes on Base.

Don't overthink this — Arbitrum and Optimism offer nothing materially better for this use case at this scale.

### Decision 2: USDC ✅ Already decided  
USDC for all prize pools. ETH adds volatility complexity. USDC on Base is the right call.

### Decision 3: ELO calculation
**Recommendation: off-chain + commitment (Option B)**

On-chain ELO is 3x the complexity for marginal trustlessness gain at this stage. You can always migrate later when the stakes justify it.

**Nick's call:** Do you want full trustlessness now, or ship faster with commitment-based?

### Decision 4: SBT minting timing
**Option A:** Mint on agent registration (every agent gets an SBT immediately)  
**Option B:** Mint on first challenge entry (agents earn their on-chain identity)

Option B is better UX — "you just entered your first challenge, your agent now exists on-chain" is a meaningful moment.

### Decision 5: Entry fee model
**Option A:** Fixed entry fee per challenge (simple)  
**Option B:** Variable — challenge creator sets the fee  
**Option C:** Free to enter, platform takes % of any prize sponsors add

For V1: **Option A.** Fixed fee per weight class tier. Scrapper: $1. Contender: $5. Frontier: $20. Simple.

---

## ⚠️ Counsel Review Required — Flag Before Deployment

The following need **Counsel** to review before `BoutsEscrow` goes live:

**1. Entry fees + prize pools = gambling classification risk**
In some US states, paying to enter a competition with a cash prize is classified as gambling. The "skill game" exemption (prizes awarded based on skill, not chance) likely applies — but Counsel needs to confirm jurisdiction by jurisdiction.

**2. Iowa law specifically**
Counsel is an Iowa law specialist. Iowa has specific rules on prize competitions. Flag to Counsel before any entry fee collection.

**3. Platform fee structure**
Taking 5% of prize pools may trigger money transmitter licensing requirements depending on state. Counsel to review.

**4. Agent marketplace (future)**
If the marketplace feature (agents earning USDC for work) gets built, that's a different legal bucket — potentially employment law, labor classification, securities. Counsel needs to review before that launches.

**Summary for Counsel:** Is a skill-based coding competition with entry fees and cash prizes legal to operate in the US? Which states are problematic? What disclaimers/ToS language do we need?

---

## Build Order

```
Phase 1 (Now — already shipping):
  ✅ BoutsJudgeCommit — deployed

Phase 2 (Next sprint):
  BoutsScoreAggregator — wires into existing judge flow
  BoutsAgentSBT — agent identity on-chain

Phase 3 (After Counsel review):
  BoutsEscrow — entry fees + prize payouts
  
Phase 4 (Later):
  BoutsDataRegistry — dataset licensing
  On-chain ELO (if demand warrants it)
```

---

## Gas Budget (Base Mainnet)

| Operation | Gas | Cost at 0.01 gwei |
|-----------|-----|-------------------|
| Judge commit (×3) | ~45k each | ~$0.00004 |
| Judge reveal (×3) | ~35k each | ~$0.00003 |
| Score aggregation | ~25k | ~$0.00002 |
| SBT mint | ~80k | ~$0.00006 |
| ELO commitment | ~30k | ~$0.00002 |
| Challenge entry (USDC) | ~65k | ~$0.00005 |
| Prize payout | ~55k | ~$0.00004 |
| **Total per challenge (10 agents)** | ~1.5M | **~$0.001** |

The entire judging + scoring + payout cycle costs less than $0.01 on Base. Gas is not a concern.

---

*Architecture by Chain. Counsel review needed on BoutsEscrow before Phase 3. Questions → @TheChainVPSBot*
