# RESTORE.md — Fleet Restore & Migration Guide
# Use this to clone the fleet to a new VPS, Mac, or any environment.
# Last updated: 2026-03-26

---

## Step 1: Clone the fleet workspace

```bash
git clone https://ghp_TOKEN@github.com/nickgallick/perlantir-fleet.git /data/.openclaw
cd /data/.openclaw
```

Replace `ghp_TOKEN` with a valid GitHub personal access token (scope: `repo`).

---

## Step 2: Install OpenClaw

On a Hostinger VPS (Docker):
```bash
docker pull ghcr.io/hostinger/hvps-openclaw:latest
```

On Mac or other VPS:
```bash
npm install -g openclaw
```

---

## Step 3: Restore secrets (not in git)

`openclaw.json` is in the repo with tokens included (private repo).
If tokens have been rotated since last commit, update them manually:

```bash
nano /data/.openclaw/openclaw.json
# Update botToken for each agent channel
# Update auth.anthropic.apiKey if rotated
```

---

## Step 4: Start OpenClaw

```bash
openclaw gateway start
# or via Docker as per your setup
```

---

## Step 5: Re-authenticate Claude Code (if using it)

```bash
claude  # follow interactive OAuth flow
# Select option 1 (Claude subscription)
# Open URL in browser, paste code back
```

---

## Step 6: Re-clone reference repos (optional but recommended)

These were excluded from git due to size. Each agent can re-clone on first use,
or run these scripts to restore everything at once.

### Chain (94 repos → /data/.openclaw/workspace-chain/repos/)

```bash
mkdir -p /data/.openclaw/workspace-chain/repos
cd /data/.openclaw/workspace-chain/repos

git clone --depth 1 https://github.com/SunWeb3Sec/DeFiHackLabs
git clone --depth 1 https://github.com/chiru-labs/ERC721A
git clone --depth 1 https://github.com/NexusMutual/smart-contracts NexusMutual
git clone --depth 1 https://github.com/immunefi-team/Web3-Security-Library
git clone --depth 1 https://github.com/aave/aave-v3-core
git clone --depth 1 https://github.com/eth-infinitism/account-abstraction
git clone --depth 1 https://github.com/artblocks/artblocks-contracts
git clone --depth 1 https://github.com/paradigmxyz/artemis
git clone --depth 1 https://github.com/azuro-protocol/Azuro-v2-public azuro
git clone --depth 1 https://github.com/cadCAD-org/cadCAD
git clone --depth 1 https://github.com/starkware-libs/cairo
git clone --depth 1 https://github.com/OpenZeppelin/cairo-contracts
git clone --depth 1 https://github.com/smartcontractkit/ccip
git clone --depth 1 https://github.com/smartcontractkit/ccip-starter-kit-foundry
git clone --depth 1 https://github.com/smartcontractkit/chainlink
git clone --depth 1 https://github.com/compound-finance/comet
git clone --depth 1 https://github.com/OpenZeppelin/compound-monitoring
git clone --depth 1 https://github.com/compound-finance/compound-protocol compound-v2
git clone --depth 1 https://github.com/gnosis/conditional-tokens-contracts
git clone --depth 1 https://github.com/thirdweb-dev/contracts
git clone --depth 1 https://github.com/cowprotocol/contracts cowprotocol
git clone --depth 1 https://github.com/pcaversaccio/createx
git clone --depth 1 https://github.com/curvefi/curve-stablecoin
git clone --depth 1 https://github.com/makerdao/dss
git clone --depth 1 https://github.com/makerdao/dss-psm
git clone --depth 1 https://github.com/crytic/echidna
git clone --depth 1 https://github.com/Layr-Labs/eigenlayer-contracts
git clone --depth 1 https://github.com/ensdomains/ens-contracts
git clone --depth 1 https://github.com/matter-labs/era-contracts
git clone --depth 1 https://github.com/euler-xyz/euler-vault-kit
git clone --depth 1 https://github.com/zama-ai/fhevm
git clone --depth 1 https://github.com/foundry-rs/forge-std
git clone --depth 1 https://github.com/forta-network/forta-bot-sdk
git clone --depth 1 https://github.com/Cyfrin/foundry-full-course-cu
git clone --depth 1 https://github.com/framesjs/frames.js
git clone --depth 1 https://github.com/wevm/frog
git clone --depth 1 https://github.com/gmx-io/gmx-contracts gmx
git clone --depth 1 https://github.com/graphprotocol/graph-node
git clone --depth 1 https://github.com/huff-language/huff-rs
git clone --depth 1 https://github.com/huff-language/huffmate
git clone --depth 1 https://github.com/Layr-Labs/incredible-squaring-avs
git clone --depth 1 https://github.com/zerodevapp/kernel
git clone --depth 1 https://github.com/lidofinance/lido-dao
git clone --depth 1 https://github.com/liquity/dev liquity
git clone --depth 1 https://github.com/Uniswap/merkle-distributor
git clone --depth 1 https://github.com/OpenZeppelin/merkle-tree
git clone --depth 1 https://github.com/flashbots/mev-boost
git clone --depth 1 https://github.com/flashbots/mev-share-client-ts
git clone --depth 1 https://github.com/morpho-org/morpho-blue
git clone --depth 1 https://github.com/metaplex-foundation/mpl-bubblegum
git clone --depth 1 https://github.com/OffchainLabs/nitro
git clone --depth 1 https://github.com/coinbase/onchainkit
git clone --depth 1 https://github.com/OpenZeppelin/openzeppelin-contracts
git clone --depth 1 https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable
git clone --depth 1 https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades
git clone --depth 1 https://github.com/ethereum-optimism/optimism
git clone --depth 1 https://github.com/ordinals/ord
git clone --depth 1 https://github.com/pimlicolabs/permissionless.js
git clone --depth 1 https://github.com/Uniswap/permit2
git clone --depth 1 https://github.com/convex-eth/platform
git clone --depth 1 https://github.com/superfluid-finance/protocol-monorepo
git clone --depth 1 https://github.com/0xProject/protocol
git clone --depth 1 https://github.com/pcaversaccio/reentrancy-attacks
git clone --depth 1 https://github.com/paradigmxyz/reth
git clone --depth 1 https://github.com/rocket-pool/rocketpool
git clone --depth 1 https://github.com/safe-global/safe-core-sdk
git clone --depth 1 https://github.com/safe-global/safe-smart-account
git clone --depth 1 https://github.com/ProjectOpenSea/seaport
git clone --depth 1 https://github.com/crytic/slither
git clone --depth 1 https://github.com/pcaversaccio/snekmate
git clone --depth 1 https://github.com/Vectorized/solady
git clone --depth 1 https://github.com/LayerZero-Labs/solidity-examples
git clone --depth 1 https://github.com/transmissions11/solmate
git clone --depth 1 https://github.com/duneanalytics/spellbook
git clone --depth 1 https://github.com/flashbots/suave-geth
git clone --depth 1 https://github.com/messari/subgraphs
git clone --depth 1 https://github.com/metaplex-foundation/sugar
git clone --depth 1 https://github.com/MystenLabs/sui
git clone --depth 1 https://github.com/Synthetixio/synthetix-v3 synthetix
git clone --depth 1 https://github.com/taikoxyz/taiko-mono
git clone --depth 1 https://github.com/yearn/tokenized-strategy
git clone --depth 1 https://github.com/metaplex-foundation/umi
git clone --depth 1 https://github.com/Uniswap/universal-router
git clone --depth 1 https://github.com/Uniswap/v2-core
git clone --depth 1 https://github.com/Uniswap/v2-periphery
git clone --depth 1 https://github.com/Uniswap/v3-core
git clone --depth 1 https://github.com/Uniswap/v3-periphery
git clone --depth 1 https://github.com/Uniswap/v4-core
git clone --depth 1 https://github.com/vyperlang/vyper
git clone --depth 1 https://github.com/yearn/yearn-vaults-v3 yearn-vaults
git clone --depth 1 https://github.com/matter-labs/zksync-era
```

### Counsel (12 repos → /data/.openclaw/workspace-counsel/repos/)

```bash
mkdir -p /data/.openclaw/workspace-counsel/repos
cd /data/.openclaw/workspace-counsel/repos

git clone --depth 1 https://github.com/lexDAO/LexCorpus
git clone --depth 1 https://github.com/compound-finance/compound-governance
git clone --depth 1 https://github.com/gnosis/conditional-tokens-contracts
git clone --depth 1 https://github.com/Polymarket/ctf-exchange
git clone --depth 1 https://github.com/aragon/govern
git clone --depth 1 https://github.com/kleros/kleros
git clone --depth 1 https://github.com/kleros/kleros-v2
git clone --depth 1 https://github.com/OpenZeppelin/openzeppelin-contracts
git clone --depth 1 https://github.com/oss-review-toolkit/ort
git clone --depth 1 https://github.com/UMAprotocol/protocol
git clone --depth 1 https://github.com/safe-global/safe-smart-account
git clone --depth 1 https://github.com/Polymarket/uma-ctf-adapter
```

### Forge (70 repos → /data/.openclaw/workspace-forge/repos/)

```bash
mkdir -p /data/.openclaw/workspace-forge/repos
cd /data/.openclaw/workspace-forge/repos

git clone --depth 1 https://github.com/anthropics/anthropic-sdk-typescript anthropic-sdk-js
git clone --depth 1 https://github.com/anthropics/anthropic-sdk-python anthropic-sdk
git clone --depth 1 https://github.com/alan2207/bulletproof-react
git clone --depth 1 https://github.com/natemoo-re/clack
git clone --depth 1 https://github.com/ryanmcdermott/clean-code-javascript
git clone --depth 1 https://github.com/tj/commander.js commander
git clone --depth 1 https://github.com/stitionai/devika
git clone --depth 1 https://github.com/drizzle-team/drizzle-orm
git clone --depth 1 https://github.com/fastify/fastify
git clone --depth 1 https://github.com/formatjs/formatjs
git clone --depth 1 https://github.com/mmai/glicko2js
git clone --depth 1 https://github.com/tailwindlabs/heroicons
git clone --depth 1 https://github.com/hoppscotch/hoppscotch
git clone --depth 1 https://github.com/inngest/inngest
git clone --depth 1 https://github.com/airbnb/javascript
git clone --depth 1 https://github.com/goldbergyoni/javascript-testing-best-practices js-testing-best-practices
git clone --depth 1 https://github.com/judge0/judge0
git clone --depth 1 https://github.com/grafana/k6
git clone --depth 1 https://github.com/langchain-ai/langchainjs langchain-js
git clone --depth 1 https://github.com/lichess-org/lila lichess
git clone --depth 1 https://github.com/liveblocks/liveblocks
git clone --depth 1 https://github.com/lucia-auth/lucia
git clone --depth 1 https://github.com/meilisearch/meilisearch
git clone --depth 1 https://github.com/mswjs/msw
git clone --depth 1 https://github.com/nativewind/nativewind
git clone --depth 1 https://github.com/amannn/next-intl
git clone --depth 1 https://github.com/vercel/nextjs-subscription-payments
git clone --depth 1 https://github.com/nodejs/node nodejs
git clone --depth 1 https://github.com/All-Hands-AI/OpenHands openhands
git clone --depth 1 https://github.com/open-telemetry/opentelemetry-js
git clone --depth 1 https://github.com/OWASP/CheatSheetSeries owasp-cheatsheets
git clone --depth 1 https://github.com/partykit/partykit
git clone --depth 1 https://github.com/pgvector/pgvector
git clone --depth 1 https://github.com/pinojs/pino
git clone --depth 1 https://github.com/microsoft/playwright
git clone --depth 1 https://github.com/porsager/postgres postgres-js
git clone --depth 1 https://github.com/facebook/react
git clone --depth 1 https://github.com/resend/react-email
git clone --depth 1 https://github.com/react-hook-form/react-hook-form
git clone --depth 1 https://github.com/testing-library/react-testing-library
git clone --depth 1 https://github.com/resend/resend-node resend
git clone --depth 1 https://github.com/getsentry/sentry-javascript sentry-js
git clone --depth 1 https://github.com/shadcn-ui/ui shadcn-ui
git clone --depth 1 https://github.com/socketio/socket.io
git clone --depth 1 https://github.com/stripe/stripe-node
git clone --depth 1 https://github.com/supabase/supabase-js
git clone --depth 1 https://github.com/princeton-nlp/SWE-agent swe-agent
git clone --depth 1 https://github.com/donnemartin/system-design-primer
git clone --depth 1 https://github.com/t3-oss/create-t3-app t3-app
git clone --depth 1 https://github.com/tailwindlabs/tailwindcss
git clone --depth 1 https://github.com/shadcn-ui/taxonomy
git clone --depth 1 https://github.com/triggerdotdev/trigger.dev trigger-dev
git clone --depth 1 https://github.com/trpc/trpc
git clone --depth 1 https://github.com/total-typescript/ts-reset
git clone --depth 1 https://github.com/vercel/turborepo
git clone --depth 1 https://github.com/type-challenges/type-challenges
git clone --depth 1 https://github.com/microsoft/TypeScript typescript
git clone --depth 1 https://github.com/vercel/ai vercel-ai
git clone --depth 1 https://github.com/vitest-dev/vitest
git clone --depth 1 https://github.com/GoogleChrome/web-vitals
git clone --depth 1 https://github.com/statelyai/xstate
git clone --depth 1 https://github.com/colinhacks/zod
git clone --depth 1 https://github.com/pmndrs/zustand
```

### ClawExpert (3 repos → /data/.openclaw/workspace-clawexpert/)

```bash
cd /data/.openclaw/workspace-clawexpert
git clone --depth 1 https://github.com/anthropics/anthropic-sdk-python
git clone --depth 1 https://github.com/NVIDIA/NemoClaw nemoclaw
git clone https://github.com/openclaw/openclaw  # full clone, no depth
```

---

## Summary

| What | How to restore |
|------|---------------|
| All workspace files, skills, config | `git clone` (Step 1) |
| OpenClaw software | npm install or Docker pull (Step 2) |
| Bot tokens / API keys | Already in `openclaw.json` from git clone |
| Claude Code auth | Re-auth interactively (Step 5) |
| Chain repos (94) | Run Chain clone script above |
| Counsel repos (12) | Run Counsel clone script above |
| Forge repos (70) | Run Forge clone script above |
| ClawExpert repos (3) | Run ClawExpert clone script above |

**Total restore time estimate**: ~20-30 min (mostly repo cloning speed)
**Fleet is operational** after Steps 1-4. Repos are optional for immediate use.
