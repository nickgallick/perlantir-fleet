# CHAIN Platform Mastery Upgrade — Skills 41-50, Repos 26-45, Whitepapers

## Workspace
/data/.openclaw/workspace-chain/

## Skills to Build (41-50)
Each SKILL.md: 300-600 lines, expert-level, production code examples included.

41. skills/dex-routing-and-aggregation/SKILL.md — Routing algorithms, split routing, multi-hop, limit orders, DCA
42. skills/lending-protocol-deep-architecture/SKILL.md — Aave/Compound internals: interest models, aTokens, health factor, liquidation engine, eMode, isolation, PSM concepts
43. skills/seaport-and-nft-exchange/SKILL.md — Seaport order structure, zones, conduits, criteria orders, Blur innovations, Blend NFT lending, Reservoir
44. skills/perpetual-futures-engine/SKILL.md — Full perps architecture: funding rate, margin engine, mark price, liquidation, insurance fund, ADL, order matching
45. skills/liquid-staking-architecture/SKILL.md — stETH rebasing, wstETH, withdrawal queue, node operator registry, oracle committee, DVT, Rocket Pool differences
46. skills/cdp-and-stablecoin-systems/SKILL.md — MakerDAO Vat/Jug/Dog/Clipper, Liquidation 2.0, PSM, DSR, OSM, emergency shutdown, spell system
47. skills/sports-betting-on-chain/SKILL.md — Azuro architecture: LP as bookmaker, odds calculation, condition/outcome model, bet tokens, parlays, live betting, B2B2C model
48. skills/decentralized-dispute-resolution/SKILL.md — Kleros, Augur fork, Reality.eth, UMA deep, Agent Sparta dispute design
49. skills/cosmos-and-app-chains/SKILL.md — Cosmos SDK, CometBFT, IBC, dYdX V4 architecture, when app-chain vs L2
50. skills/yield-optimization-and-vaults/SKILL.md — ERC-4626 vaults, strategy pattern, auto-compounding, Yearn model, risk layers, Convex/Curve

## Repos to Clone (26-45) into repos/
Use --depth 1. Log failures, continue:

26. https://github.com/Uniswap/v2-core
27. https://github.com/Uniswap/universal-router
28. https://github.com/cowprotocol/contracts
29. https://github.com/compound-finance/comet
30. https://github.com/ProjectOpenSea/seaport
31. https://github.com/reservoirprotocol/indexer
32. https://github.com/blur-io/blend
33. https://github.com/dydxprotocol/v4-chain
34. https://github.com/gmx-io/gmx-contracts
35. https://github.com/Synthetixio/synthetix-v3
36. https://github.com/lidofinance/lido-dao
37. https://github.com/rocket-pool/rocketpool
38. https://github.com/azuro-protocol/Azuro-v2-public
39. https://github.com/kleros/kleros
40. https://github.com/makerdao/dss
41. https://github.com/makerdao/dss-psm
42. https://github.com/liquity/dev
43. https://github.com/yearn/yearn-vaults-v3
44. https://github.com/Uniswap/v2-periphery
45. https://github.com/compound-finance/compound-protocol

## Whitepapers — Fetch and Summarize
Fetch each URL, extract key formulas/architecture points, save to whitepapers/<name>.md:

1. Uniswap V3: https://uniswap.org/whitepaper-v3.pdf
2. Curve StableSwap: https://curve.fi/files/stableswap-paper.pdf
3. Liquity: https://docsend.com/view/bwiczmy - instead fetch https://docs.liquity.org/documentation/technical-overview
4. Kleros: https://kleros.io/whitepaper.pdf
5. For others: fetch from docs pages and save summaries:
   - Aave V3: https://docs.aave.com/developers/getting-started/readme
   - Lido: https://docs.lido.fi/contracts/lido
   - dYdX V4: https://dydx.exchange/blog/dydx-chain
   - Seaport: https://docs.opensea.io/docs/seaport-overview
   - Polymarket CTF: https://docs.polymarket.com/
   - GMX: https://gmxio.gitbook.io/gmx/
   - Azuro: https://gem.azuro.org/concepts/protocol/architecture
   - EigenLayer: https://docs.eigenlayer.xyz/
   - MakerDAO: https://docs.makerdao.com/

Save each as whitepapers/<name>.md with: overview, key mechanism, key formulas, architecture notes, security considerations.

## After Build
1. Update README.md: 50 skills, 45 repos, 13 whitepapers
2. Update .build_complete_platform with timestamp

When completely finished, run:
openclaw system event --text "CHAIN platform mastery complete: 50 skills, 45 repos, 13 whitepapers — can build any DeFi protocol" --mode now
