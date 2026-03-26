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

## GPL v2 vs v3 — Key Differences
- **GPL v2**: "distribution" triggers copyleft. SaaS that never distributes code = NOT triggered. Loophole: offer the software as a service, never distribute binaries.
- **GPL v3**: Adds: anti-tivoization (hardware restrictions), patent retaliation, explicit international scope. Still requires distribution to trigger. SaaS still not triggered.
- **AGPL v3**: Closes the SaaS loophole. "Interaction over a network" counts as distribution. Running AGPL code as a web service → must release ALL source. This is the dangerous one.

## How AGPL Actually Gets Triggered
You run a web app. Users interact with it over the internet. If ANY dependency is AGPL-licensed:
- You are "conveying" the work to users (by network interaction)
- You must offer users access to the complete corresponding source code
- "Complete" = everything needed to rebuild the running application
- Failure to comply = copyright infringement → statutory damages up to $150,000 per work per infringement

## Real Enforcement Cases
- **Hancom v. FSF (2017)**: Hancom (Korean office suite) settled with FSF for using GPL code in commercial product without compliance. Terms undisclosed.
- **SFC v. Vizio (2021)**: Software Freedom Conservancy sued Vizio for GPL violations in smart TV software. First case to allow HOME OWNERS to sue — not just the copyright holder. Settled 2023.
- **VMware Corp. v. Hellwig (Germany, 2015)**: Linux kernel contributor sued VMware for GPL violation in ESXi hypervisor. Case ongoing years, eventually VMware removed the code.

## Dependency Tree Audit Commands
```bash
# Node.js — check every package
npx license-checker --onlyAllow 'MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;CC0-1.0;Unlicense;0BSD' --excludePrivatePackages

# Find any GPL/AGPL
npx license-checker | grep -E 'GPL|AGPL|LGPL'

# Python
pip-licenses --allow-only='MIT;Apache Software License;BSD License;ISC License'
```

## SaaS Hosting Decision Tree
```
Is the license AGPL? → YES → DO NOT USE (SaaS = triggered)
Is the license GPL? → YES → Do you distribute binaries? → YES → triggered / NO → safe (for now)
Is the license LGPL? → YES → Do you modify the library? → YES → risky / NO → safe if dynamic linking
Is the license MIT/Apache/BSD/ISC? → YES → safe, just keep license notice
```
