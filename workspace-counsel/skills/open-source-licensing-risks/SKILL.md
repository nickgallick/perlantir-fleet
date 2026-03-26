# SKILL 40: Open Source Licensing Risks

## Purpose
Identify and mitigate open source license risks for commercial platforms — especially copyleft traps that can force your entire codebase open-source.

## License Categories

### Permissive (Safe for Commercial Use)
- **MIT**: Do anything, include license text. Most Solidity libraries.
- **Apache 2.0**: Like MIT + patent grant + requires stating changes. OpenZeppelin.
- **BSD (2-clause, 3-clause)**: Similar to MIT. Many crypto tools.
- **ISC**: Functionally identical to MIT.

### Copyleft (DANGEROUS for Commercial Platforms)
- **GPL v2/v3**: Using GPL code in your product → entire product must be GPL (open source). "Using" includes linking, importing, incorporating, derivative works.
- **AGPL v3**: GPL + network use trigger. SaaS platforms must release source code even if users only interact over network. MOST DANGEROUS for web platforms.
- **LGPL**: Weaker — only the library stays open source. Safe if dynamic linking only; dangerous if you modify the LGPL code itself.

### Smart Contract Specific
- **BSL (Business Source License)**: Source available but NOT open source. Commercial use prohibited for 2 years (Uniswap v3). Then converts to GPL. Do NOT fork Uniswap v3 during restricted period.
- **OpenZeppelin contracts**: MIT licensed — safe for commercial use.
- **Foundry/Forge**: MIT/Apache — safe.

## Banned Licenses for Commercial Use
GPL, AGPL, SSPL (MongoDB's Server Side Public License)

## Allowed Licenses
MIT, Apache 2.0, BSD, ISC, LGPL (with careful use), MPL 2.0 (with care)

## Audit Tools
- **Node.js**: `npx license-checker`
- **Python**: `pip-licenses`
- **Automated**: FOSSA, Snyk, ORT (Open Source Review Toolkit)

## Practical Compliance Steps
1. Before any library/dependency: check the license at npmjs.com, pypi, GitHub
2. Maintain license inventory (FOSSA recommended for production platforms)
3. For smart contracts: verify license of EVERY imported contract before deployment (on-chain = permanent)
4. Run license audit before every major deployment

## Risk Levels
- AGPL anywhere in dependency tree: ⚫ Existential (forces entire platform open source)
- GPL in production code: 🔴 High
- LGPL without dynamic linking: 🟡 Medium
- BSL during restricted period: 🔴 High
- MIT/Apache/BSD: 🟢 Low

## Iowa/Perlantir Context
- Agent Sparta, prediction market: audit ALL npm dependencies before launch
- Smart contract imports: 100% of OpenZeppelin is MIT — use only OZ for baseline contracts
- No Uniswap v3 forks until BSL restriction expires for target contracts

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
