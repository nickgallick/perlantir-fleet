# CHAIN Wizard Upgrade — Skills 26-40 + Repos 16-25

## Workspace
/data/.openclaw/workspace-chain/

## Skills to Build (26-40)
Write each as a dense, expert-level SKILL.md with code examples, formulas, and production patterns.

26. skills/yul-and-assembly-mastery/SKILL.md — Full Yul/assembly mastery, bytecode reading, Huff
27. skills/exploit-reproduction-and-analysis/SKILL.md — 30 major exploits, Foundry reproductions, attack taxonomy
28. skills/advanced-cryptography-for-blockchain/SKILL.md — ECDSA, EIP-712, ZK deep, VRFs, Merkle
29. skills/mechanism-design-and-game-theory/SKILL.md — Incentive compatibility, tokenomics, LMSR math
30. skills/advanced-testing-and-verification/SKILL.md — Invariant testing, symbolic execution, mutation testing
31. skills/mempool-and-transaction-engineering/SKILL.md — Mempool mechanics, private submission, searcher knowledge
32. skills/advanced-proxy-and-upgrade-patterns/SKILL.md — Diamond deep dive, metamorphic, namespaced storage
33. skills/cross-chain-security-and-bridges/SKILL.md — Bridge architectures ranked, light clients, build patterns
34. skills/restaking-and-shared-security/SKILL.md — EigenLayer, AVS, Symbiotic, Karak
35. skills/intent-based-architecture/SKILL.md — Intents vs transactions, UniswapX, CoW, ERC-7683
36. skills/evm-precompiles-and-edge-cases/SKILL.md — All precompiles, EVM edge cases, chain-specific quirks
37. skills/production-monitoring-and-war-room/SKILL.md — Security checklist, Forta, Defender, incident response
38. skills/advanced-amm-mathematics/SKILL.md — UniV2/V3 math, Curve StableSwap, IL formulas, tick math
39. skills/novel-contract-patterns/SKILL.md — ERC-6909, Uniswap V4 hooks, transient storage, Permit2
40. skills/blockchain-economics-and-mev-theory/SKILL.md — Block space market, MEV supply chain, economic security

## Additional Repos to Clone (into repos/)
Use --depth 1:

16. https://github.com/Uniswap/v4-core
17. https://github.com/SunWeb3Sec/DeFiHackLabs
18. https://github.com/pcaversaccio/createx
19. https://github.com/Cyfrin/foundry-full-course-cu
20. https://github.com/smartcontractkit/chainlink
21. https://github.com/0xProject/protocol
22. https://github.com/euler-xyz/euler-vault-kit
23. https://github.com/morpho-org/morpho-blue
24. https://github.com/paradigmxyz/reth
25. https://github.com/Uniswap/permit2

## Exploit Reproductions
In repos/exploit-reproductions/, create Foundry test files reproducing at least 15 of these:
1. The DAO (reentrancy)
2. bZx flash loan oracle manipulation
3. Harvest Finance flash loan
4. Parity Multisig initWallet
5. Compound governance distribution bug
6. Mango Markets oracle manipulation
7. Euler Finance donation attack
8. Wormhole signature verification bypass (conceptual — Solana side)
9. Nomad Bridge copy-paste drain
10. Audius uninitialized proxy
11. Fei/Rari cross-contract reentrancy
12. Curve/Vyper reentrancy (compiler bug — demonstrate the pattern)
13. Wintermute Profanity weak key (demonstrate key generation weakness)
14. Ronin validator key compromise (demonstrate multisig threshold risk)
15. Cream Finance flash loan + oracle

Each test file: explain the vulnerability, show the attack, show the fix.

## After Build
1. Update README.md with all 40 skills + 25 repos
2. Create EXPLOIT_PATTERNS.md — taxonomy of all attack patterns studied
3. Write .build_complete_wizard with timestamp

When completely finished, run:
openclaw system event --text "CHAIN wizard upgrade complete: 40 skills, 25 repos, 15+ exploit reproductions" --mode now
