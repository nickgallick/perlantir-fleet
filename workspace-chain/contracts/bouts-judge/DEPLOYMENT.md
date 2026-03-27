# BoutsJudgeCommit — Deployment Guide

## Prerequisites

1. **Foundry installed** — `curl -L https://foundry.paradigm.xyz | bash && foundryup`
2. **Deployer wallet** with ~0.05 ETH on Base (and ~0.01 ETH on Base Sepolia for testing)
3. **Environment variables set:**

```bash
export DEPLOYER_PRIVATE_KEY=0x...        # Private key of oracle/deployer wallet
export BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY
export BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/YOUR_KEY
export BASESCAN_API_KEY=YOUR_BASESCAN_KEY   # From basescan.org → API Keys
```

---

## Step 1: Install dependencies

```bash
cd /data/.openclaw/workspace-chain/contracts/bouts-judge
forge install foundry-rs/forge-std
```

---

## Step 2: Run tests (must pass before deploying)

```bash
forge test -vvv
```

Expected: All tests pass including fuzz tests (1000 runs each).

```bash
forge test --gas-report
```

Review gas costs — commit and reveal should each be under 60k gas on Base.

---

## Step 3: Deploy to Base Sepolia (test first)

```bash
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvvv
```

**Save the output address.** Add to Supabase secrets as `JUDGE_CONTRACT_ADDRESS` for testing.

Verify on Basescan Sepolia: https://sepolia.basescan.org/address/YOUR_ADDRESS

---

## Step 4: Smoke test on Sepolia

Use `cast` to verify the deployment:

```bash
# Read oracle address
cast call YOUR_CONTRACT_ADDRESS "oracle()" --rpc-url $BASE_SEPOLIA_RPC_URL

# Compute a commitment (off-chain helper)
cast call YOUR_CONTRACT_ADDRESS \
  "computeCommitment(bytes32,string,uint8,bytes32)" \
  0x000000000000000000000000000000000000000000000000000000000000abcd \
  "claude" \
  84 \
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef \
  --rpc-url $BASE_SEPOLIA_RPC_URL
```

---

## Step 5: Deploy to Base Mainnet

Only after Sepolia smoke test passes and Forge's end-to-end test passes.

```bash
forge script script/Deploy.s.sol \
  --rpc-url $BASE_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvvv
```

---

## Deployed Addresses

| Network       | Address | Basescan |
|---------------|---------|----------|
| Base Mainnet  | `0x267837dEB1ae92Eb4F321De99F893802B20AAD9a` | https://basescan.org/address/0x267837dEB1ae92Eb4F321De99F893802B20AAD9a |
| Oracle Wallet | `0x7eb41C96A11FAa55887188a6eD2538968D521722` | — |

---

## Supabase Secrets to Add After Deployment

```bash
# Add via Supabase Dashboard → Project Settings → Edge Functions → Secrets

JUDGE_CONTRACT_ADDRESS=0x...       # Deployed contract address
JUDGE_ORACLE_PRIVATE_KEY=0x...     # Same as DEPLOYER_PRIVATE_KEY — this is the hot wallet
BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/YOUR_KEY
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY
OPENROUTER_API_KEY=sk-or-...
SALT_ENCRYPTION_KEY=<32-byte hex>  # Generate: openssl rand -hex 32
```

---

## Rotating the Oracle Wallet

If `JUDGE_ORACLE_PRIVATE_KEY` is ever exposed, rotate immediately:

```bash
# Call transferOracle from the current oracle wallet
cast send YOUR_CONTRACT_ADDRESS \
  "transferOracle(address)" \
  NEW_ORACLE_ADDRESS \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --rpc-url $BASE_RPC_URL
```

Then update `JUDGE_ORACLE_PRIVATE_KEY` in Supabase secrets to the new wallet's private key.

---

## Oracle Wallet Funding

The oracle wallet needs ETH on Base for gas to call `commit()` and `reveal()`.

**Estimated gas per judging round (1 entry, 3 providers):**
- 3x `commit()` calls: ~45k gas each = ~135k total
- 3x `reveal()` calls: ~35k gas each = ~105k total
- Total per entry: ~240k gas
- At 0.001 gwei Base gas price: ~0.00000024 ETH per entry (effectively free)

**Keep ~0.05 ETH in the oracle wallet.** This covers thousands of judging rounds.

---

## Files Delivered

```
contracts/bouts-judge/
├── src/
│   └── BoutsJudgeCommit.sol      ← The contract
├── test/
│   └── BoutsJudgeCommit.t.sol    ← Full test suite
├── script/
│   └── Deploy.s.sol              ← Deployment script
├── abi/
│   └── BoutsJudgeCommit.json     ← ABI for chain-client.ts
├── foundry.toml                  ← Foundry config
└── DEPLOYMENT.md                 ← This file
```
