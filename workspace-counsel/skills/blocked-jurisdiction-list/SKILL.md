# SKILL: Blocked Jurisdiction List

## Purpose
Definitive operational list of US states and territories that must be geo-blocked for prediction market, skill-game competition, and wagering-adjacent platforms. Includes the legal basis for each block and the tier system for product design decisions.

## Risk Level
🔴 High — Serving users in prohibited jurisdictions is a criminal violation in some states. Washington State is a Class C felony. This list must be hardcoded into geo-blocking infrastructure on day one, not added after launch.

---

## Tier 1: HARD BLOCK — Zero Tolerance (Criminal Risk)

These jurisdictions must be blocked at the IP level AND confirmed via user registration address. No exceptions without jurisdiction-specific licensing.

### Washington State
**Block level**: ⚫ Existential
**Legal basis**: RCW 9.46.010 — Washington's gambling statute is among the broadest in the US
- Broadly defines gambling to include any "contest of chance" for consideration
- RCW 9.46.240: **Class C felony** (up to 5 years) for operators of unlicensed gambling activities
- Washington AG has been aggressive against online gaming companies
- Skill-game exception is narrow and contested in WA
- **Block regardless of product framing**: Washington has pursued DFS operators, crypto platforms, and skill-game sites
- **Additional**: WA state constitution Article II § 24 prohibits lotteries except state-run

### Arizona (Unlicensed Real-Money Skill Games)
**Block level**: 🔴 High
**Legal basis**: ARS § 13-3301 et seq. — Arizona gambling statutes
- ARS § 13-3302: Exempts certain skill-game tournaments but narrowly
- DFS: Legalized via ARS § 5-1301 et seq. (2022) — DFS operators must be licensed
- Non-DFS skill games: Gray area; AG has taken aggressive positions
- **Block until licensed or legal opinion obtained for specific product**

### Louisiana
**Block level**: 🔴 High
**Legal basis**: Louisiana Constitution Article XII § 6; LSA-RS 14:90
- Broadly prohibits gambling not authorized by legislature
- DFS: Legalized only in specific parishes; not statewide
- Online gaming: Permitted only through licensed casinos
- **Block unless DFS-licensed and product fits DFS definition**

### Montana
**Block level**: 🔴 High
**Legal basis**: MCA § 23-5-112 et seq.
- Montana prohibits most forms of online gambling
- DFS: Not specifically legalized; AG position is restrictive
- Skill games: Narrow exception for licensed amusement devices only
- **Block for real-money products**

### Idaho
**Block level**: 🔴 High
**Legal basis**: Idaho Code § 18-3801 et seq.
- Broad gambling prohibition with limited exceptions
- No DFS-specific legislation
- Idaho courts have been unfavorable to skill-game arguments
- **Block for real-money products**

---

## Tier 2: CONDITIONAL BLOCK — Block Until Licensed or Product Confirmed Legal

### Nevada
**Block level**: 🟡 Medium
**Legal basis**: NRS Chapter 463
- Counterintuitively, Nevada has strict gaming licensing requirements
- All real-money online gaming requires Nevada Gaming Control Board license
- DFS: Legal but requires license (NAC 463A)
- Skill competitions with prizes: Gray area; Nevada GCB has historically interpreted broadly
- **Block until Nevada gaming counsel confirms product classification**

### Tennessee
**Block level**: 🟡 Medium
**Legal basis**: TCA § 39-17-501 et seq.
- Tennessee legalized DFS (TCA § 47-18-2001) but NOT general skill-game competitions
- Sports betting: Legal since 2019 but requires license
- AI coding competitions with prize pools: Uncategorized; AG position unclear
- **Block pending Tennessee-specific legal analysis**

### Connecticut
**Block level**: 🟡 Medium
**Legal basis**: CGS § 12-557b et seq.
- Online gaming legal only through licensed operators (Foxwoods, Mohegan Sun partnerships)
- DFS: Legal under CGS § 12-852 but operators must register
- **Block until registered or confirmed exempt**

### Delaware
**Block level**: 🟡 Medium (for wagering layer only)
**Legal basis**: Delaware Code Title 29, Ch. 48
- Delaware has a comprehensive online gaming framework
- Skill competitions: Generally permissible
- If any element of chance: must be licensed gaming
- **Skill competition layer: likely OK. Wagering layer: block until analyzed.**

### Hawaii
**Block level**: 🟡 Medium
**Legal basis**: HRS § 712-1220 et seq.
- Broad gambling prohibition; one of only two states with no commercial gaming
- DFS: Not legalized; AG has been restrictive
- Skill competitions with prizes: Gray area
- **Block for wagering layer; skill competition likely OK with legal opinion**

### Alaska
**Block level**: 🟡 Medium
**Legal basis**: AS 11.66.200 et seq.
- Limited gaming; no DFS-specific law
- Skill game exceptions exist but narrow
- **Block for wagering layer; analyze skill competition separately**

---

## Tier 3: PROCEED WITH STANDARD COMPLIANCE (Generally Permissible)

These states generally permit skill-game competitions and/or DFS with standard compliance:

**Clear**: California, Colorado, Florida, Georgia, Illinois, Indiana, Kansas, Maryland, Massachusetts, Michigan (DFS licensed), Minnesota, Missouri, Nebraska, New Jersey, New York (DFS licensed), North Carolina, Ohio, Oklahoma, Oregon, Pennsylvania, South Carolina, South Dakota, Texas, Utah (skill games OK, gambling not), Virginia, West Virginia, Wisconsin, Wyoming

**Iowa**: Permissible under Iowa Code § 99B (skill games) — but register with Iowa DIA if prize >$500; see `iowa-state-law-complete` skill

**Important note for all Tier 3 states**: Standard compliance still required:
- Age verification (18+)
- Responsible gaming disclosures
- Tax information collection
- Terms of Service with governing law clause

---

## US Territories

### Puerto Rico
**Block level**: 🟡 Medium
- Puerto Rico has its own gaming regulatory framework
- Online gambling permitted only through licensed operators
- **Block until Puerto Rico-specific analysis completed**

### US Virgin Islands, Guam, American Samoa
**Block level**: 🟡 Medium
- Limited regulatory frameworks; default to block for wagering layer

---

## International Jurisdictions (If Serving International Users)

### Hard Block (Never Serve)
- **OFAC Sanctioned Countries**: Cuba, Iran, North Korea, Syria, Russia (certain activities), Belarus — see `ofac-sanctions-screening` skill
- **China**: Complete prohibition on online gambling; enforcement risk
- **United Kingdom**: Requires UK Gambling Commission license for real-money products
- **Australia**: Interactive Gambling Act 2001 prohibits unlicensed online gambling to Australians
- **France**: Requires ARJEL license for prediction markets

### Generally Permissible (Standard Compliance)
- Canada (provincial analysis required), EU countries (GDPR compliance required), Australia (for skill competitions only)

---

## Implementation Requirements

### Technical Geo-Blocking
1. **IP geolocation**: Use MaxMind GeoIP2 or IPinfo database — block Tier 1 states at IP level
2. **Registration address**: Collect state at signup; block Tier 1 states from completing registration
3. **VPN detection**: Flag known VPN/proxy IPs; require additional verification or deny service
4. **Periodic re-verification**: For long-term users, re-verify location annually
5. **Terms of Service**: "Service not available in [list prohibited states]" — explicit TOS provision

### Legal Coverage
- Terms of Service must explicitly list blocked jurisdictions
- "Void where prohibited by law" language is minimum; list of blocked states is stronger
- Users must attest to jurisdiction at registration
- Screenshots / logs of geo-block implementation retained for potential regulatory defense

### Geo-Block Technology Stack
- **Cloudflare**: Built-in geo-blocking by country/state (Workers or WAF rules)
- **MaxMind GeoIP2**: $20/month for state-level US precision
- **IPQualityScore**: VPN/proxy detection + geolocation combo
- **Persona / Stripe Identity**: KYC address verification as secondary layer

---

## State-Specific DIA / Contest Registration (Iowa-Focused)

Iowa Code § 99B.5(2): Register with Iowa DIA if **any single contest** offers prize value >$500:
- **Where**: Iowa Department of Inspections and Appeals, Lucas State Office Building, Des Moines, IA 50319
- **When**: Before first paid contest
- **Cost**: Minimal (filing fee ~$25–100 range; confirm current fee with DIA)
- **What to file**: Contest rules, prize description, entry fee structure, skill-determination methodology

---

## Quick Reference Card (For Engineering)

```
HARD BLOCK (⚫🔴):
- WA, AZ, LA, MT, ID

CONDITIONAL BLOCK (🟡):
- NV, TN, CT, DE (wagering layer), HI, AK
- All US territories

INTERNATIONAL HARD BLOCK:
- OFAC list + UK + Australia + China

PROCEED WITH COMPLIANCE:
- All other US states + Iowa (register with DIA if prize >$500)
```

---

## Disclaimer
This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.
