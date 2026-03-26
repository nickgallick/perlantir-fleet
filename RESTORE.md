# How to Restore the Fleet on a New Machine
# Written for: anyone, no technical experience needed

---

## What you need before starting
- A computer or VPS with internet access
- Your GitHub token (the `ghp_...` token — save this somewhere safe)
- About 30 minutes

---

## Step 1 — Install the software OpenClaw needs

Open a terminal and run this one command:

```bash
npm install -g openclaw
```

> **Don't have npm?** Install Node.js first from https://nodejs.org (click "Download Node.js LTS", install it like any app). Then come back and run the command above.

---

## Step 2 — Download the fleet

Run this command (replace `YOUR_TOKEN` with your GitHub token):

```bash
git clone https://YOUR_TOKEN@github.com/nickgallick/perlantir-fleet.git /data/.openclaw
```

This downloads everything — all 9 agents, their skills, memory, and config.

> **On a Mac**, you might want a different folder. Replace `/data/.openclaw` with `~/openclaw` and it'll go in your home folder.

---

## Step 3 — Start OpenClaw

```bash
openclaw gateway start
```

That's it. All 9 agents are now running.

---

## Step 4 — Test it

Open Telegram and message any of your bots. They should respond immediately.

---

## Step 5 (optional) — Re-authenticate Claude Code

Only needed if you use Claude Code directly. Run:

```bash
claude
```

Pick option 1, open the link it gives you in your browser, paste the code back. Done.

---

## Step 6 (optional) — Restore the reference repos

The agents work fine without these. They're just reference codebases the agents use to look things up. Only restore them if an agent asks for them.

To restore all of them at once, run the script for each agent:

**Chain's repos** (blockchain reference code):
```bash
mkdir -p /data/.openclaw/workspace-chain/repos && cd /data/.openclaw/workspace-chain/repos
git clone --depth 1 https://github.com/OpenZeppelin/openzeppelin-contracts
git clone --depth 1 https://github.com/Uniswap/v3-core
git clone --depth 1 https://github.com/aave/aave-v3-core
git clone --depth 1 https://github.com/morpho-org/morpho-blue
git clone --depth 1 https://github.com/safe-global/safe-smart-account
git clone --depth 1 https://github.com/foundry-rs/forge-std
git clone --depth 1 https://github.com/transmissions11/solmate
git clone --depth 1 https://github.com/Vectorized/solady
git clone --depth 1 https://github.com/crytic/slither
git clone --depth 1 https://github.com/SunWeb3Sec/DeFiHackLabs
git clone --depth 1 https://github.com/eth-infinitism/account-abstraction
git clone --depth 1 https://github.com/Uniswap/v4-core
git clone --depth 1 https://github.com/Uniswap/v2-core
git clone --depth 1 https://github.com/Uniswap/v2-periphery
git clone --depth 1 https://github.com/Uniswap/v3-periphery
git clone --depth 1 https://github.com/Uniswap/permit2
git clone --depth 1 https://github.com/Uniswap/universal-router
git clone --depth 1 https://github.com/compound-finance/comet
git clone --depth 1 https://github.com/gnosis/conditional-tokens-contracts
git clone --depth 1 https://github.com/Polymarket/ctf-exchange
git clone --depth 1 https://github.com/Layr-Labs/eigenlayer-contracts
git clone --depth 1 https://github.com/matter-labs/zksync-era
git clone --depth 1 https://github.com/ethereum-optimism/optimism
git clone --depth 1 https://github.com/paradigmxyz/reth
git clone --depth 1 https://github.com/coinbase/onchainkit
git clone --depth 1 https://github.com/smartcontractkit/chainlink
git clone --depth 1 https://github.com/smartcontractkit/ccip
git clone --depth 1 https://github.com/lidofinance/lido-dao
git clone --depth 1 https://github.com/rocket-pool/rocketpool
git clone --depth 1 https://github.com/yearn/yearn-vaults-v3 yearn-vaults
git clone --depth 1 https://github.com/Synthetixio/synthetix-v3 synthetix
git clone --depth 1 https://github.com/curvefi/curve-stablecoin
git clone --depth 1 https://github.com/makerdao/dss
git clone --depth 1 https://github.com/makerdao/dss-psm
git clone --depth 1 https://github.com/ProjectOpenSea/seaport
git clone --depth 1 https://github.com/safe-global/safe-core-sdk
git clone --depth 1 https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable
git clone --depth 1 https://github.com/OpenZeppelin/openzeppelin-foundry-upgrades
git clone --depth 1 https://github.com/crytic/echidna
git clone --depth 1 https://github.com/Layr-Labs/incredible-squaring-avs
git clone --depth 1 https://github.com/zerodevapp/kernel
git clone --depth 1 https://github.com/flashbots/mev-boost
git clone --depth 1 https://github.com/flashbots/mev-share-client-ts
git clone --depth 1 https://github.com/paradigmxyz/artemis
git clone --depth 1 https://github.com/flashbots/suave-geth
git clone --depth 1 https://github.com/gmx-io/gmx-contracts gmx
git clone --depth 1 https://github.com/azuro-protocol/Azuro-v2-public azuro
git clone --depth 1 https://github.com/euler-xyz/euler-vault-kit
git clone --depth 1 https://github.com/pcaversaccio/createx
git clone --depth 1 https://github.com/pcaversaccio/reentrancy-attacks
git clone --depth 1 https://github.com/pcaversaccio/snekmate
git clone --depth 1 https://github.com/huff-language/huff-rs
git clone --depth 1 https://github.com/huff-language/huffmate
git clone --depth 1 https://github.com/vyperlang/vyper
git clone --depth 1 https://github.com/starkware-libs/cairo
git clone --depth 1 https://github.com/OpenZeppelin/cairo-contracts
git clone --depth 1 https://github.com/zama-ai/fhevm
git clone --depth 1 https://github.com/MystenLabs/sui
git clone --depth 1 https://github.com/metaplex-foundation/mpl-bubblegum
git clone --depth 1 https://github.com/metaplex-foundation/sugar
git clone --depth 1 https://github.com/metaplex-foundation/umi
git clone --depth 1 https://github.com/forta-network/forta-bot-sdk
git clone --depth 1 https://github.com/graphprotocol/graph-node
git clone --depth 1 https://github.com/messari/subgraphs
git clone --depth 1 https://github.com/duneanalytics/spellbook
git clone --depth 1 https://github.com/Cyfrin/foundry-full-course-cu
git clone --depth 1 https://github.com/framesjs/frames.js
git clone --depth 1 https://github.com/wevm/frog
git clone --depth 1 https://github.com/pimlicolabs/permissionless.js
git clone --depth 1 https://github.com/chiru-labs/ERC721A
git clone --depth 1 https://github.com/artblocks/artblocks-contracts
git clone --depth 1 https://github.com/NexusMutual/smart-contracts NexusMutual
git clone --depth 1 https://github.com/immunefi-team/Web3-Security-Library
git clone --depth 1 https://github.com/thirdweb-dev/contracts
git clone --depth 1 https://github.com/cowprotocol/contracts cowprotocol
git clone --depth 1 https://github.com/compound-finance/compound-protocol compound-v2
git clone --depth 1 https://github.com/ensdomains/ens-contracts
git clone --depth 1 https://github.com/OpenZeppelin/compound-monitoring
git clone --depth 1 https://github.com/OffchainLabs/nitro
git clone --depth 1 https://github.com/taikoxyz/taiko-mono
git clone --depth 1 https://github.com/convex-eth/platform
git clone --depth 1 https://github.com/superfluid-finance/protocol-monorepo
git clone --depth 1 https://github.com/0xProject/protocol
git clone --depth 1 https://github.com/liquity/dev liquity
git clone --depth 1 https://github.com/Uniswap/merkle-distributor
git clone --depth 1 https://github.com/OpenZeppelin/merkle-tree
git clone --depth 1 https://github.com/cadCAD-org/cadCAD
git clone --depth 1 https://github.com/yearn/tokenized-strategy
git clone --depth 1 https://github.com/smartcontractkit/ccip-starter-kit-foundry
git clone --depth 1 https://github.com/ordinals/ord
```

**Counsel's repos** (legal reference code):
```bash
mkdir -p /data/.openclaw/workspace-counsel/repos && cd /data/.openclaw/workspace-counsel/repos
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

**Forge's repos** (web dev reference code):
```bash
mkdir -p /data/.openclaw/workspace-forge/repos && cd /data/.openclaw/workspace-forge/repos
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

**ClawExpert's repos** (OpenClaw internals):
```bash
cd /data/.openclaw/workspace-clawexpert
git clone --depth 1 https://github.com/anthropics/anthropic-sdk-python
git clone --depth 1 https://github.com/NVIDIA/NemoClaw nemoclaw
git clone https://github.com/openclaw/openclaw
```

---

## That's it. You're done.

The fleet is running. All 9 agents are ready to go.
