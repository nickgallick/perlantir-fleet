# CHAIN Agent Build Task

## Mission
Build 25 blockchain/smart contract skills and clone 15 reference repos for the CHAIN agent.

## Workspace
/data/.openclaw/workspace-chain/

## Skill Files to Create
Create each skill as a complete, expert-level SKILL.md reference document at the path specified.
Each skill should be 200-500 lines of dense, practical, production-ready reference content.

### Skills to Build:
1. skills/solidity-mastery/SKILL.md — Full Solidity 0.8.x+ language reference
2. skills/smart-contract-security/SKILL.md — Top 20 vulnerabilities + audit methodology  
3. skills/evm-deep-knowledge/SKILL.md — EVM architecture, opcodes, memory model
4. skills/foundry-testing/SKILL.md — Foundry toolchain, test patterns, cheatcodes
5. skills/token-standards/SKILL.md — ERC-20/721/1155/4626 + EIPs
6. skills/defi-primitives/SKILL.md — AMMs, lending, prediction markets, staking, governance
7. skills/proxy-patterns-and-upgradeability/SKILL.md — Transparent, UUPS, Beacon, Diamond
8. skills/oracle-integration/SKILL.md — Chainlink, UMA, Pyth, API3
9. skills/l2-and-multichain/SKILL.md — L2 rollups, cross-chain, chain selection
10. skills/web3-frontend/SKILL.md — viem, wagmi, RainbowKit, The Graph, Ponder
11. skills/prediction-market-architecture/SKILL.md — Full Polymarket-style architecture
12. skills/escrow-and-payment-patterns/SKILL.md — Prize pools, payment splitting
13. skills/account-abstraction/SKILL.md — ERC-4337, session keys, paymasters
14. skills/mev-and-transaction-ordering/SKILL.md — MEV types + protection strategies
15. skills/gas-optimization-advanced/SKILL.md — Opcode-level gas engineering
16. skills/contract-deployment-and-verification/SKILL.md — Deployment scripts, verification
17. skills/subgraph-and-indexing/SKILL.md — The Graph, Ponder, indexing patterns
18. skills/formal-verification/SKILL.md — Certora, Halmos, Slither, Echidna
19. skills/dao-and-governance/SKILL.md — Governor, timelocks, attack vectors
20. skills/token-launch-and-tokenomics/SKILL.md — Supply design, launch patterns, vesting
21. skills/bridge-and-crosschain-development/SKILL.md — LayerZero, CCIP, Wormhole
22. skills/solana-and-anchor/SKILL.md — Rust/Anchor, PDAs, CPI, SPL tokens
23. skills/zk-proofs-fundamentals/SKILL.md — SNARKs, STARKs, Circom, on-chain verification
24. skills/nft-and-digital-asset-systems/SKILL.md — Royalties, dynamic NFTs, marketplace integration
25. skills/defi-security-monitoring/SKILL.md — Forta, Defender, incident response

## Reference Repos to Clone
Clone into /data/.openclaw/workspace-chain/repos/ — use --depth 1 for speed:

1. https://github.com/OpenZeppelin/openzeppelin-contracts
2. https://github.com/Uniswap/v3-core
3. https://github.com/Uniswap/v3-periphery
4. https://github.com/aave/aave-v3-core
5. https://github.com/gnosis/conditional-tokens-contracts
6. https://github.com/foundry-rs/forge-std
7. https://github.com/transmissions11/solmate
8. https://github.com/Vectorized/solady
9. https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable
10. https://github.com/safe-global/safe-smart-account
11. https://github.com/LayerZero-Labs/solidity-examples
12. https://github.com/crytic/slither
13. https://github.com/crytic/echidna
14. https://github.com/pcaversaccio/sniper
15. https://github.com/SunWeb3Sec/DeFiHackLabs

## After All Skills + Repos
1. Create SOUL.md in /data/.openclaw/workspace-chain/ (copy from prompt)
2. Create IDENTITY.md for Chain agent
3. Create README.md listing all 25 skills and 15 repos with status
4. Write completion marker: /data/.openclaw/workspace-chain/.build_complete

## Instructions
- Write every skill file as dense, expert-level content — not summaries, real reference docs
- Include code examples in Solidity, TypeScript, bash as appropriate
- Repos: clone with --depth 1 to save space, log any failures but continue
- Do not stop if a single repo clone fails — continue with the rest
- When done, create the .build_complete file with a timestamp

When completely finished, run:
openclaw system event --text "CHAIN agent training complete: 25 skills built, 15 repos cloned" --mode now
