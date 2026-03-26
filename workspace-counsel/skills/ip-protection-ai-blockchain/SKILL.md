# SKILL: Intellectual Property for AI Models & Blockchain Protocols
**Version:** 1.0.0 | **Domain:** IP Law, Patents, Trademarks, Trade Secrets

---

## AI Model IP

### Model Weights
- **Not patentable** (mathematical algorithms generally not patent-eligible under *Alice Corp. v. CLS Bank*, 573 U.S. 208 (2014))
- **Not copyrightable** (weights are numerical values, not "expression")
- **Best protection: Trade secret** under Defend Trade Secrets Act (DTSA), 18 U.S.C. §§ 1836-1839
- Requirements for trade secret protection: (1) information has economic value from secrecy, (2) reasonable measures to maintain secrecy (NDAs, access controls, encryption)

### AI-Generated Output
- **No copyright protection in the US** (Copyright Office ruling 2023 — AI-generated works without human authorship are not copyrightable)
- **Key case:** *Thaler v. Perlmutter* (D.D.C. 2023) — confirmed no copyright for purely AI-generated works
- **Hybrid works:** If a human makes "sufficient creative choices" in prompting/editing AI output → may be copyrightable
- **Practical implication for Agent Sparta:** AI predictions published on the platform are NOT copyrightable; the prediction database structure, curation, and analysis layer built on top may be

### Training Data Risks
- Using copyrighted data to train AI: active litigation, no settled law
- *NYT v. OpenAI* (S.D.N.Y. 2023): New York Times sued OpenAI for copyright infringement via training data
- *Getty Images v. Stability AI* (D. Del. 2023): Getty sued for unauthorized use of images in training
- **For Nick's platforms:** If training prediction models on scraped data → consult counsel on data sourcing. Publicly available data (government data, public forecasts) is safer. Licensed data is safest.

### The Prediction Database as Trade Secret
- **High-value asset:** Database of AI predictions + accuracy records over time = calibration data with commercial value
- Protect as trade secret: limit access, NDA for employees/contractors with access, technical access controls
- **Do NOT publish** the full prediction history publicly without legal structure in place

---

## Smart Contract IP

### Source Code Copyright
- Smart contract source code is copyrightable as a literary work
- BUT: once verified on Etherscan → publicly available → copyright exists but practical protection is near zero
- **Consider:** Don't verify on Etherscan immediately; give yourself time to establish market position first

### ABI/Interface
- Solidity interfaces are NOT copyrightable (functional/merger doctrine — only one way to express the function)
- ABI is functional, not expressive → no copyright

### Patent Protection for Novel Mechanisms
- **Uniswap V3 concentrated liquidity:** Uniswap obtained US patent (US Patent No. 11,475,524)
- Business method patents ARE granted in DeFi — controversial but real
- **For Agent Sparta:** Novel mechanisms for AI prediction scoring, AI model selection, or calibration methodology → potentially patentable
- **Cost:** $15-25K for provisional patent application; $50-100K for full prosecution
- **Timeline:** 18-24+ months to granted patent
- **File BEFORE publishing:** Public disclosure before filing can destroy patent rights (US has 1-year grace period, but international rights are lost immediately upon public disclosure)

---

## Brand Protection

### Trademark Registration
- **File with USPTO** before launch: https://www.uspto.gov/trademarks
- Fee: $250-$350 per class (TEAS Plus application)
- **Relevant classes for Agent Sparta/AI prediction:**
  - Class 36: Financial services, online wagering, prediction market services
  - Class 42: Software as a service, AI services, online platform services
  - Class 41: Entertainment, competition organization services
- **International:** File PCT or WIPO Madrid Protocol application for global protection (~$3-5K for key markets)
- **Timeline:** 8-12 months to registration (assuming no opposition)

### Critical: Search Before Launch
- USPTO TESS search: https://tess2.uspto.gov/
- Search: "Agent Sparta," "Agent Arena," "Bouts," any product name
- Common law trademark rights exist even without registration — a prior user can force you to rebrand
- Cost of rebrand after launch >> cost of trademark search before

### Domain & Handle Strategy
**Register BEFORE announcing:**
- .com (primary)
- .ai (increasingly important for AI products)
- .io (crypto/tech standard)
- .xyz (popular in crypto)
- Social handles: Twitter/X, Discord, Telegram, TikTok, Instagram, LinkedIn, YouTube
- Username squatting is common in crypto — lock everything down on announcement day

### Brand Monitoring
- Google Alerts for product names
- USPTO trademark watch service (through filing agent)
- Namecheap, GoDaddy alerts for domain variants

---

## Open Source Compliance

### Common License Types in DeFi/AI Stacks:
| License | Can Use? | Must Open Source? | Must Attribute? |
|---|---|---|---|
| MIT | ✅ Yes | ❌ No | ✅ Yes |
| Apache 2.0 | ✅ Yes | ❌ No | ✅ Yes |
| GPL v3 | ⚠️ Conditionally | ✅ Yes (if distributed) | ✅ Yes |
| AGPL v3 | ⚠️ Careful | ✅ Yes (including SaaS) | ✅ Yes |
| BSL (Buiness Source License) | ⚠️ Time-limited | Converts to open source after delay | ✅ Yes |

**Uniswap BSL:** Used BSL 1.1 for V3 — proprietary for 4 years, then converts to GPL 2.0. This is how they protected their concentrated liquidity innovation commercially while planning to eventually open source.

**For Nick's platforms:** Build on MIT/Apache-licensed code; avoid GPL if you want to keep your code proprietary.

---

## Practical IP Priorities for Launch Sequence

| Priority | Action | Timeline | Cost |
|---|---|---|---|
| 1 | Trademark search (before naming anything publicly) | Before announcement | $500-2K |
| 2 | File trademark application | Before launch | $500-1K |
| 3 | Register all domains and social handles | Before announcement | $100-500 |
| 4 | Employee/contractor NDAs covering trade secrets | Before any hiring | $500-2K legal |
| 5 | Trade secret policy for prediction database | Before launch | $1-3K legal |
| 6 | Provisional patent application (if novel mechanism) | Before public disclosure | $5-15K |
| 7 | Source code copyright notice + license file | Before any OSS release | Free |

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
