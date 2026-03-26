# MEMORY.md — Chain Long-Term Memory

## Identity
- Name: Chain — Blockchain & Smart Contract Architect
- Role: Blockchain specialist in Nick's 9-agent fleet
- COO: ClawExpert (reports to)
- Workspace: /data/.openclaw/workspace-chain
- Channel: Telegram (@TheChainVPSBot)
- Model: anthropic/claude-sonnet-4-6

## Training Status (Complete — 2026-03-25/26)
- **116 skills** covering: Solidity, EVM, Foundry, DeFi, security, MEV, ZK, cross-chain, L2, account abstraction, NFTs, DAOs, tokenomics, bridges, Solana, Cairo, Cosmos, Move, Vyper, Huff, Yul, and more
- **94 repos cloned** in `/repos/` including: OpenZeppelin, Uniswap v2/v3/v4, Aave v3, Morpho, GMX, EigenLayer, zkSync, Optimism, Reth, Compound, Curve, Lido, Synthetix, Seaport, Azuro, DeFiHackLabs, Slither, Echidna
- **4 whitepapers** in `/whitepapers/`: EigenLayer, MEV-Share, OP Stack, Uniswap v4 hooks
- **20 languages** tracked

## Active Projects

### Bouts (Agent Arena) — Blockchain Integration
Nick's AI agent coding competition platform. 3 AI judges score submissions. ELO leaderboard.
- **Phase 1 (Now→3mo)**: USDC prize pool escrow on Base
- **Phase 2 (3-6mo)**: Soulbound agent identity + on-chain ELO
- **Phase 3 (6-12mo)**: $BT token (after demand driver — entry fees in $BT, staking, burns)
- **Phase 4 (12mo+)**: Commit-reveal judging, multi-provider (Claude + GPT-4o + Gemini)
- **Phase 5**: ZKML (only when open-source model replaces Claude API)

Key decision: Option 2 judging (commit-reveal, 3 providers) = ~$0.03/submission

Nick needs: Google Gemini API key, Alchemy Base RPC, Basescan API key, deployer wallet (~0.05 ETH on Base)

## Key Technical Decisions Made
- Base is primary chain (low gas, EVM-compatible, Coinbase-backed)
- USDC for prize pools in V1 (not $BT — avoid token dump risk)
- Safe multisig for treasury
- The Graph for indexing
- EntryPoint v0.7 for ERC-4337 account abstraction

## Important Contacts
- Seal 911: t.me/seal_911_bot (emergency exploit response)
- Immunefi: immunefi.com (bug bounties)
- Safe: app.safe.global

## Fleet Context
9-agent fleet: Maks, MaksPM, Scout, ClawExpert (COO), Forge, Pixel, Launch, Chain, Counsel
- Work with Maks on web3/web2 interface
- Work with Counsel on smart contract legal compliance (before deployment)
- Work with Forge on non-blockchain code review
