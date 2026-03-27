# Bouts — Multi-Provider Judge System Spec
**Version:** 1.1 (OpenRouter replaces 3 separate APIs)
**Author:** Chain (Blockchain & Smart Contract Architect)  
**Date:** 2026-03-27  
**Assigned to:** Forge  
**Status:** Ready for implementation

---

## Overview

Replace the current single-provider (Claude-only) judge system with a **3-provider parallel judging system** (Claude + GPT-4o + Gemini) with **on-chain commit-reveal integrity**. Each judge runs independently and simultaneously. The on-chain commitment proves results were locked before being revealed — preventing score manipulation.

**API Strategy:** All 3 providers routed through **OpenRouter** — one API key, one client file, one endpoint. No separate Anthropic/OpenAI/Google API keys needed for judging.

**No sandbox code execution in V1.** Skip it. Add later.

---

## What Exists Today

| File | What it does |
|------|-------------|
| `supabase/functions/judge-entry/index.ts` | Core judge runner — Claude only, via `callJudge()` |
| `supabase/functions/_shared/anthropic-client.ts` | Claude API client — **will be replaced** |
| `src/app/api/internal/process-jobs/route.ts` | Job queue processor — calls `judge-entry` 3x (alpha/beta/gamma) |
| `src/app/api/webhooks/judge/route.ts` | Receives final results, updates DB, triggers ELO |
| `src/types/judge.ts` | `JudgeScore` type — has `judge_type: 'alpha' \| 'beta' \| 'gamma' \| 'tiebreaker'` |
| `supabase/migrations/` | DB schema — `judge_scores` table, `challenge_entries` table |

**Key insight:** The current system already calls 3 "judges" (alpha/beta/gamma) but they're all Claude. The rename to provider-based (claude/gpt4o/gemini) is the cleanest change — one judge per provider, parallel, same scoring schema.

---

## Architecture: What Changes

```
BEFORE:
  job queue → judge-entry (alpha/Claude) ─┐
  job queue → judge-entry (beta/Claude)  ─┤→ median → final_score
  job queue → judge-entry (gamma/Claude) ─┘

AFTER:
  job queue → judge-entry (claude)  ─┐
  job queue → judge-entry (gpt4o)   ─┤→ all 3 commit on-chain → reveal → median → final_score
  job queue → judge-entry (gemini)  ─┘
  
  All 3 routed through OpenRouter (single API key/client)
```

---

## Part 1 — Smart Contract (Chain delivers this)

### Contract: `BoutsJudgeCommit.sol`

**Chain:** Base  
**Standard:** Solidity 0.8.24  
**Pattern:** Commit-reveal with event emission  
**Deployment:** ~0.002 ETH gas on Base

#### Core Logic

```
commit(bytes32 entryId, bytes32 commitment)
  → stores: commitments[entryId][provider] = commitment
  → emits: Committed(entryId, provider, commitment, block.timestamp)

reveal(bytes32 entryId, string provider, uint8 score, bytes32 salt)
  → verifies: keccak256(abi.encodePacked(entryId, provider, score, salt)) == commitment
  → stores: reveals[entryId][provider] = score
  → emits: Revealed(entryId, provider, score, block.timestamp)

getReveals(bytes32 entryId) → (uint8 claude, uint8 gpt4o, uint8 gemini, bool allRevealed)
```

**Access control:** Only the designated `judgeOracle` address (deployer wallet) can call `commit` and `reveal`.

**Score range:** 0-100 (mapped from provider's 1-10 scale × 10, integer).

#### What the contract proves
- Score was locked (committed) before being revealed
- The revealed score matches exactly what was committed
- All three provider scores are on-chain, immutable, timestamped
- Nobody can change the scores after commitment, even us

**Chain delivers:** Production-ready Solidity, Foundry tests, deployment script, ABI JSON, `DEPLOYMENT.md` with contract addresses for Base Sepolia + Base Mainnet.

---

## Part 2 — Backend Changes (Forge implements)

### ⚠️ Key Architecture Decision: Single OpenRouter Client

**Use OpenRouter instead of calling Anthropic, OpenAI, and Google APIs separately.**

| | 3 Separate APIs (old plan) | OpenRouter (new plan) |
|---|---|---|
| API keys | 3 keys | 1 key |
| Client files | 3 files | 1 file |
| Cost | Provider rate | Provider rate + ~0-5% markup |
| Single point of failure | No | Yes — if OR is down, all 3 fail |
| Anthropic document content type | ✅ | ❌ (use separate user message instead) |

**Single point of failure:** Acceptable — jobs retry via existing job queue.  
**Injection protection:** Submission passed as a **separate user message**, never interpolated into system prompt. Same safety level in practice.

---

### 2a. New Shared Client: `openrouter-client.ts` (replaces `anthropic-client.ts`)

**Location:** `supabase/functions/_shared/openrouter-client.ts`

**Delete:** `supabase/functions/_shared/anthropic-client.ts` — fully replaced. Check if `ANTHROPIC_API_KEY` is used anywhere else before removing from env.

```typescript
const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1/chat/completions'

const MODEL_MAP = {
  claude: 'anthropic/claude-sonnet-4-6',
  gpt4o:  'openai/gpt-4o',
  gemini: 'google/gemini-1.5-pro',
}

interface JudgeResponse {
  scores: {
    quality: number      // 1-10 integer
    creativity: number   // 1-10 integer
    completeness: number // 1-10 integer
    practicality: number // 1-10 integer
  }
  overall: number        // 1.0-10.0
  feedback: string
  red_flags: string[]
}

export async function callJudgeViaOpenRouter(
  provider: 'claude' | 'gpt4o' | 'gemini',
  systemPrompt: string,
  submissionText: string,
): Promise<JudgeResponse>
```

**Request format:**
```json
{
  "model": "anthropic/claude-sonnet-4-6",
  "response_format": { "type": "json_object" },
  "messages": [
    { "role": "system", "content": "<judge system prompt — instructs to return JSON matching schema>" },
    { "role": "user", "content": "Evaluate the following submission. Return only valid JSON matching the schema." },
    { "role": "user", "content": "<submission text>" }
  ]
}
```

**Required headers:**
```
Authorization: Bearer <OPENROUTER_API_KEY>
HTTP-Referer: https://bouts.gg
X-Title: Bouts Judge System
Content-Type: application/json
```

**System prompt addition:** Append to each judge's existing system prompt:
```
Return your evaluation as valid JSON with this exact schema:
{
  "scores": { "quality": <1-10>, "creativity": <1-10>, "completeness": <1-10>, "practicality": <1-10> },
  "overall": <1.0-10.0>,
  "feedback": "<2-4 sentences>",
  "red_flags": ["<string>", ...]
}
```

**Validation:** After parsing JSON response, validate all score fields are integers 1-10, overall is float 1.0-10.0. Throw on invalid.

---

### 2b. Updated `judge-entry/index.ts`

**Changes:**
1. Replace `judge_type` parameter with `provider: 'claude' | 'gpt4o' | 'gemini'`
2. Replace `callJudge()` with `callJudgeViaOpenRouter(provider, systemPrompt, submission)`
3. Add commit-reveal chain logic after scoring

**Updated flow:**
```
1. Receive: { entry_id, provider, challenge_id }
2. Fetch entry.submission_text from DB
3. Run injection detection (keep existing detectInjection())
4. Call callJudgeViaOpenRouter(provider, systemPrompt, submission)
5. Generate salt: crypto.randomUUID() → bytes32 hex
6. score_int = Math.round(evaluation.overall * 10)  → 10-100
7. commitment = keccak256(abi.encodePacked(entryId_bytes32, provider, score_int, salt))
8. Submit commitment to chain: chain-client.commitScore(entryId, provider, score_int, salt)
9. Store in DB: judge_scores row with commitment_hash, commitment_tx, salt_encrypted
10. Check if all 3 providers done for this entry_id
11. If yes → reveal all 3 on-chain → update entry final_score → trigger ratings job
```

**Keep unchanged:** Tiebreaker logic (`judge_type = 'tiebreaker'`), outlier/divergence detection (>3 point spread), ELO trigger, notification insert.

---

### 2c. New Helper: `chain-client.ts`

**Location:** `supabase/functions/_shared/chain-client.ts`

Uses **viem** (lighter than ethers, better for Deno/edge). Chain delivers ABI before this is needed.

```typescript
// commitScore — call after judge scores
commitScore(entryId: string, provider: string, scoreInt: number, salt: string): Promise<string> // → txHash

// revealScore — call after all 3 committed
revealScore(entryId: string, provider: string, scoreInt: number, salt: string): Promise<string> // → txHash

// getAllReveals — read-only verification
getAllReveals(entryId: string): Promise<{ claude: number, gpt4o: number, gemini: number, allRevealed: boolean }>
```

**Config from env:**
```
JUDGE_CONTRACT_ADDRESS
JUDGE_ORACLE_PRIVATE_KEY
BASE_RPC_URL
```

---

### 2d. DB Migration: `00010_multi_provider_judges.sql`

```sql
-- Add provider + on-chain columns to judge_scores
ALTER TABLE judge_scores 
  ADD COLUMN IF NOT EXISTS provider TEXT CHECK (provider IN ('claude', 'gpt4o', 'gemini', 'tiebreaker')),
  ADD COLUMN IF NOT EXISTS commitment_hash TEXT,
  ADD COLUMN IF NOT EXISTS commitment_tx TEXT,
  ADD COLUMN IF NOT EXISTS reveal_tx TEXT,
  ADD COLUMN IF NOT EXISTS salt_encrypted TEXT;

-- Backfill existing rows: alpha/beta/gamma were all Claude
UPDATE judge_scores 
SET provider = 'claude'
WHERE provider IS NULL;

-- Add on-chain summary fields to challenge_entries
ALTER TABLE challenge_entries
  ADD COLUMN IF NOT EXISTS onchain_entry_id TEXT,
  ADD COLUMN IF NOT EXISTS all_revealed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reveal_summary JSONB;
-- reveal_summary shape: { claude: 84, gpt4o: 79, gemini: 81, reveal_tx: "0x..." }
```

---

### 2e. Updated `process-jobs/route.ts`

**Change:** Replace `judgeTypes = ['alpha', 'beta', 'gamma']` → `providers = ['claude', 'gpt4o', 'gemini']`

```typescript
const providers = ['claude', 'gpt4o', 'gemini']
const results = await Promise.all(
  entries.flatMap(entry =>
    providers.map(provider =>
      fetch(`${SUPABASE_URL}/functions/v1/judge-entry`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${SERVICE_KEY}` },
        body: JSON.stringify({ entry_id: entry.id, provider, challenge_id: payload.challenge_id }),
      }).then(r => r.ok).catch(() => false)
    )
  )
)
```

All 3 fired in parallel — no sequential calls.

---

## Part 3 — Frontend Changes (Forge implements after backend)

### 3a. Challenge Results Page — Judge Breakdown

**Location:** Challenge Detail + Results pages (wherever scores currently display)

**Current:** Shows single score  
**New:** Show 3 provider scores + final median + on-chain link

```
┌─────────────────────────────────────────────┐
│  JUDGE PANEL                                │
├──────────────┬──────────────┬───────────────┤
│  Claude      │  GPT-4o      │  Gemini       │
│  8.4 / 10    │  7.9 / 10    │  8.1 / 10     │
│  "Strong..." │  "Good..."   │  "Clean..."   │
├──────────────┴──────────────┴───────────────┤
│  FINAL SCORE: 8.1    [View on Base ↗]       │
│  ✓ Scores committed on-chain before reveal  │
└─────────────────────────────────────────────┘
```

### 3b. Types Update

`src/types/judge.ts` — add `provider: 'claude' | 'gpt4o' | 'gemini'` field alongside existing `judge_type`.

### 3c. On-Chain Link Component

```tsx
<a href={`https://basescan.org/tx/${revealTx}`} target="_blank" rel="noopener">
  View on Base ↗
</a>
```

Trust signal — users can independently verify scores.

### 3d. Admin Judge Panel (low priority, add if time allows)

Table in admin showing per-provider scores + commitment/reveal tx links per entry.

---

## Part 4 — Environment Variables

### Supabase Edge Function Secrets

```bash
OPENROUTER_API_KEY=sk-or-...          # Get from openrouter.ai
JUDGE_CONTRACT_ADDRESS=0x...          # Chain provides after deployment
JUDGE_ORACLE_PRIVATE_KEY=0x...        # Deployer wallet — treat as hot wallet, min ETH only
BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/YOUR_KEY
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY
```

### Remove (after confirming not used elsewhere)
```bash
ANTHROPIC_API_KEY  # Was only for judging — check before deleting
```

### Vercel (unchanged)
No changes needed.

---

## Keys Nick Needs to Provide

| Key | Where to get |
|-----|-------------|
| `OPENROUTER_API_KEY` | openrouter.ai → Keys |
| `BASE_RPC_URL` | dashboard.alchemy.com → Base mainnet |
| Deployer wallet + ~0.05 ETH on Base | Any wallet, bridge from Coinbase |

**That's it — one API key instead of three.**

---

## Implementation Order

```
Day 1-2:  Chain — BoutsJudgeCommit.sol + tests + Base Sepolia deploy
Day 1:    Forge — openrouter-client.ts (can start immediately, no dependency)
Day 2:    Forge — chain-client.ts (needs Chain's ABI — Chain delivers Day 1-2)
Day 2:    Forge — DB migration 00010
Day 3:    Forge — judge-entry/index.ts (wire OpenRouter + commit/reveal)
Day 3:    Forge — process-jobs/route.ts (providers array)
Day 4:    Forge — Frontend: judge breakdown component
Day 4:    Forge — End-to-end test on Base Sepolia
Day 5:    Chain — Deploy to Base mainnet + Basescan verify
Day 5:    Forge — Swap to mainnet RPC, final smoke test
```

---

## What Chain Delivers

1. **`BoutsJudgeCommit.sol`** — Production Solidity, NatSpec documented
2. **`test/BoutsJudgeCommit.t.sol`** — Foundry test suite (commit, reveal, bad reveal, replay protection, access control)
3. **`script/Deploy.s.sol`** — Foundry deployment script
4. **`abi/BoutsJudgeCommit.json`** — ABI for chain-client.ts
5. **`DEPLOYMENT.md`** — Addresses, verification commands
6. **Deployed addresses** — Base Sepolia + Base Mainnet

---

## What Forge Implements

1. `supabase/functions/_shared/openrouter-client.ts` — new, replaces anthropic-client.ts
2. `supabase/functions/_shared/chain-client.ts` — new, uses Chain's ABI
3. `supabase/functions/judge-entry/index.ts` — updated
4. `src/app/api/internal/process-jobs/route.ts` — updated
5. `supabase/migrations/00010_multi_provider_judges.sql`
6. Frontend: judge breakdown + on-chain link
7. `src/types/judge.ts` — updated

---

## Risk Flags

**MEDIUM** — OpenRouter is a single point of failure for all 3 judges. Mitigation: jobs retry via existing queue. Monitor OpenRouter status.

**MEDIUM** — `JUDGE_ORACLE_PRIVATE_KEY` in Supabase secrets is a hot wallet. Fund with only ~0.05 ETH (enough for ~1000 commit+reveal pairs on Base). Rotate if exposed.

**LOW** — On-chain commit/reveal adds ~2-3 seconds latency per judge. Acceptable for async judging system.

**LOW** — Tiebreaker still runs Claude via OpenRouter (`anthropic/claude-sonnet-4-6`). No change needed there.

---

## Definition of Done

- [ ] All 3 providers scoring independently in parallel via OpenRouter
- [ ] Each score committed on-chain before reveal
- [ ] Reveal verifiable on Basescan
- [ ] Frontend shows 3 judge scores + provider labels + on-chain link
- [ ] DB migration applied cleanly
- [ ] End-to-end test on Base Sepolia passes
- [ ] Deployed to Base mainnet

---

*Spec v1.1 by Chain. Questions → Chain via @TheChainVPSBot*
