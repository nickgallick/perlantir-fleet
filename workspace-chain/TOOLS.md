# TOOLS.md — Chain Workspace Resources

## Blockchain Tools & References

### Deployment
- Foundry: `forge`, `cast`, `anvil`, `chisel`
- OpenZeppelin Defender: https://defender.openzeppelin.com
- Hardhat (when needed): https://hardhat.org
- CreateX factory: `repos/createx`

### Security Analysis
- Slither (static): `repos/slither` — `slither . --print human-summary`
- Echidna (fuzz): `repos/echidna`
- Certora Prover: https://www.certora.com
- Halmos (symbolic): https://github.com/a16z/halmos
- Mythril: `myth analyze`

### Verification & Explorers
- Etherscan: https://etherscan.io
- Basescan: https://basescan.org
- Arbiscan: https://arbiscan.io
- Optimistic Etherscan: https://optimistic.etherscan.io

### Chain RPC (Alchemy recommended)
- Ethereum Mainnet: https://eth-mainnet.g.alchemy.com/v2/{KEY}
- Base: https://base-mainnet.g.alchemy.com/v2/{KEY}
- Arbitrum: https://arb-mainnet.g.alchemy.com/v2/{KEY}
- Optimism: https://opt-mainnet.g.alchemy.com/v2/{KEY}

### Key Contract Addresses (Production)
- EntryPoint v0.7 (ERC-4337): `0x0000000071727De22E5E9d8BAf0edAc6f37da032`
- Base CCIP Router: `0x881e3A65B4d4a04dD529061dd0071cf975F58bCD`
- Uniswap Universal Router (Base): `0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD`
- Safe Singleton: `0x41675C099F32341bf84BFc5382aF534df5C7461a`

### Oracles
- Chainlink Data Feeds: https://data.chain.link
- Pyth Network: https://pyth.network
- UMA Optimistic Oracle: https://oracle.uma.xyz

### Indexing
- The Graph Studio: https://thegraph.com/studio
- Ponder: https://ponder.sh
- Dune Analytics: https://dune.com

### Security Monitoring
- Forta: https://app.forta.network
- OpenZeppelin Defender Sentinel: https://defender.openzeppelin.com
- Seal 911 (emergency): https://t.me/seal_911_bot

### Bug Bounties
- Immunefi: https://immunefi.com
- Code4rena: https://code4rena.com
- Sherlock: https://audits.sherlock.xyz

### Reference Repos Location
All repos cloned at: `/data/.openclaw/workspace-chain/repos/`
Key repos: openzeppelin-contracts, v3-core, aave-v3-core, morpho-blue, safe-smart-account,
           DeFiHackLabs, slither, echidna, conditional-tokens-contracts, eigenlayer-contracts

### Whitepapers Location
`/data/.openclaw/workspace-chain/whitepapers/`
- eigenlayer-deep.md
- mev-share.md
- op-stack.md
- uniswap-v4-hooks.md

## Nick's Blockchain Stack (Current)
- Primary chain: **Base** (low gas, Coinbase-backed, EVM-compatible)
- Token standard: **USDC** for payment/prize pools
- Wallet infra: **Safe** multisig for treasury
- Frontend: Next.js + wagmi + viem
- Indexing: The Graph (subgraphs)

## Active Projects
- **Bouts (Agent Arena)**: AI agent coding competition. Blockchain phases:
  - Phase 1: USDC prize pool escrow on Base
  - Phase 2: Soulbound agent identity + on-chain ELO
  - Phase 3: $BT token (after demand driver exists)
