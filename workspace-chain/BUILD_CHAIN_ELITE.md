# CHAIN 0.01% Elite Upgrade — Skills 51-67, Repos 46-60

## Workspace
/data/.openclaw/workspace-chain/

## Skills to Build (51-67)
Each SKILL.md: 400-700 lines, expert-level, production code + formulas + real examples.
NO SHORTCUTS. Every section must be complete and detailed.

51. skills/vyper-mastery/SKILL.md — Full Vyper language, decorators, Titanoboa, compiler version security, Snekmate, real Curve contract analysis
52. skills/cairo-and-starknet/SKILL.md — Cairo language, Sierra/CASM, felt252, storage model, account abstraction native, StarkNet architecture
53. skills/move-language/SKILL.md — Resource types, Move vs Solidity safety guarantees, Sui object model, owned vs shared objects, Aptos architecture
54. skills/huff-mastery/SKILL.md — Stack-based EVM bytecode, MAIN() macro, manual ABI dispatch, Huffmate, gas golf, real Huff contract examples
55. skills/rollup-architecture/SKILL.md — Optimistic internals (sequencer, batches, fraud proofs, bisection), ZK internals (prover, verifier, SNARK vs STARK), EIP-4844, DA layers, OP Stack, Arbitrum Orbit, ZK Stack
56. skills/sequencer-and-block-building/SKILL.md — Sequencer responsibilities, MEV extraction, shared sequencing (Espresso), based rollups, Flashbots MEV-Boost, builder API, bundle construction
57. skills/mev-bot-architecture/SKILL.md — Sandwich bot (mempool monitoring, bundle construction), liquidation bot (health factor polling, flash loan liquidation), arbitrage bot (graph-based cycles), JIT liquidity, defense patterns for each
58. skills/advanced-exploit-patterns/SKILL.md — Governance attacks, cross-protocol composability attacks, read-only reentrancy, donation attacks on vaults, proxy storage collision, supply chain attacks, compiler bugs
59. skills/rwa-tokenization/SKILL.md — T-bill tokenization, private credit, ERC-3643 T-REX standard, SPV structure, compliance module, NAV oracle, Centrifuge, Ondo, MakerDAO RWA vaults
60. skills/on-chain-insurance/SKILL.md — Nexus Mutual model (capital pool, cover pricing, claims voting), Sherlock (audit + coverage alignment), parametric insurance, oracle-triggered payouts
61. skills/on-chain-options-and-structured-products/SKILL.md — Options fundamentals (calls, puts, Greeks), Black-Scholes on-chain, Lyra architecture, Premia concentrated liquidity options, covered call vaults, put selling vaults, Panoptic perpetual options
62. skills/privacy-protocols/SKILL.md — Stealth addresses (EIP-5564), Aztec network architecture, Railgun proof of innocence, ZK mixer mechanics (Tornado Cash academic study), nullifiers, Merkle trees for privacy
63. skills/fhe-and-encrypted-computation/SKILL.md — FHE fundamentals, TFHE scheme, fhEVM (Zama), euint/ebool types, sealed bid auctions on encrypted data, private voting, current limitations and roadmap
64. skills/smart-contract-devops/SKILL.md — CI/CD pipeline (lint→compile→test→fuzz→coverage→gas→deploy→verify), Slither in CI, deployment manifests, HSMs, AWS KMS, key hierarchy, Forta/Tenderly monitoring, runbooks
65. skills/smart-contract-legal-compliance/SKILL.md — ERC-3643 transfer restrictions, KYC integration (Chainalysis, Elliptic), OFAC screening, Travel Rule, AML monitoring, responsible gaming limits, 1099 reporting triggers, Agent Sparta compliance design
66. skills/whitepaper-reading-and-implementation/SKILL.md — How to read a whitepaper, key papers analyzed (Uniswap V3, Curve StableSwap, EIP-4626, MEV-Share, EigenLayer), implementation from formulas, mechanism design process, red-teaming
67. skills/economic-simulation/SKILL.md — Agent-based simulation (Python + NumPy), CadCAD framework, parameter tuning via simulation (liquidation bonus, AMM fee, LMSR b), stress testing (flash crash, bank run, oracle failure, whale attack), pre-deployment validation

## Repos to Clone (46-60) into repos/
Use --depth 1. Log failures and continue.

46. https://github.com/vyperlang/vyper
47. https://github.com/pcaversaccio/snekmate
48. https://github.com/starkware-libs/cairo
49. https://github.com/MystenLabs/sui
50. https://github.com/huff-language/huff-rs
51. https://github.com/huff-language/huffmate
52. https://github.com/ethereum-optimism/optimism
53. https://github.com/OffchainLabs/nitro
54. https://github.com/matter-labs/zksync-era
55. https://github.com/flashbots/mev-boost
56. https://github.com/flashbots/suave-geth
57. https://github.com/NexusMutual/smart-contracts
58. https://github.com/lyra-finance/v2-core
59. https://github.com/zama-ai/fhevm
60. https://github.com/cadCAD-org/cadCAD

## Research Papers
Fetch and summarize into whitepapers/:
- whitepapers/mev-share.md: https://collective.flashbots.net/t/mev-share-programmably-private-orderflow-to-share-mev-with-users/1264
- whitepapers/eigenlayer-deep.md: https://docs.eigenlayer.xyz/eigenlayer/overview/whitepaper
- whitepapers/uniswap-v4-hooks.md: https://blog.uniswap.org/uniswap-v4
- whitepapers/op-stack.md: https://stack.optimism.io/

## Quality Standard
- Every skill must have working code examples in Solidity, Vyper, Cairo, Huff, or Python as appropriate
- Every skill must have a security checklist at the end
- Every skill must be exhaustive — if a section is listed above, it must be covered in full

## After Build
1. Update README.md: 67 skills, 60 repos, 20 whitepapers
2. Create .build_complete_elite with timestamp

When completely finished, run:
openclaw system event --text "CHAIN elite upgrade complete: 67 skills, 60 repos — 0.01% blockchain engineer training done" --mode now
