# SKILL 54: Multi-State Compliance Matrix

## Purpose
Track the compliance posture across all 50 states for an online competition/prediction market platform operating from Iowa. Know where you can launch, where you need registration, and where to geo-block.

## Compliance Dimensions per State

For each state, track:
1. Skill-based competition legality (legal / requires registration / restricted / prohibited)
2. Money transmitter license requirement (if custodial funds)
3. Privacy law obligations (threshold, rights, enforcement mechanism)
4. Age verification requirements
5. Tax nexus implications
6. Consumer protection registration requirements
7. Data breach notification requirements

## Launch Tier Framework

### Tier 1 — Launch Freely (~25–30 States)
No specific skill-game restrictions, standard privacy laws, no special licensing required beyond federal compliance.

Likely includes: Iowa, Nebraska, South Dakota, North Dakota, Wyoming, Montana, Idaho, Nevada (DFS legal), Oklahoma, Missouri, Mississippi, Alabama, Georgia, South Carolina, North Carolina (except specific categories), Virginia (has VCDPA but no gaming restriction), Maryland (some DFS issues — check), Minnesota, Wisconsin, Ohio, Indiana (has UCPA-equivalent, check), Kansas, Arkansas

**Action**: Launch in these states at Day 1. Build to CCPA standard for privacy, cover all.

### Tier 2 — Launch With Registration (~10–15 States)
States requiring registration for skill-based competitions, or with specific DFS laws requiring state registration.

**Likely Tier 2**: Colorado, Tennessee, New Hampshire, Maine, Massachusetts (check gambling definition carefully), Connecticut, New Jersey (DFS licensed — check if your product falls under DFS definition), Illinois (check — BIPA compliance also required), Michigan, Pennsylvania, West Virginia (legal sports betting/DFS framework)

**Action**: Budget $1–5K per state for registration. Complete within 6 months of launch.

### Tier 3 — Legal Opinion Required Before Launch (~5–8 States)
Ambiguous state laws where skill-based competition legality with AI agents is unclear.

**Likely Tier 3**: California (complex — AG aggressive, but skill games generally legal), Texas (TDPSA applies broadly; gaming law analysis needed), New York (NY AG aggressive; Martin Act risk; DFS legal with DFS license), Florida (DFS was banned/reinstated — current status check required), Arizona (has had restrictions on DFS — check current law)

**Action**: Get gaming attorney opinion specific to each state before launching. Budget $3–8K per state.

### Tier 4 — Geo-Block Permanently (Until Law Changes)
**Washington State**: 🚫 Class C felony for internet gambling (RCW 9.46.240). Extremely broadly interpreted by WA AG. Always geo-block. Risk: criminal prosecution.

**Louisiana**: historically restrictive on online gaming. Verify current status before reconsidering.

**Montana**: state lottery monopoly, very restrictive on other gaming. Verify.

**Note**: Tier 4 list should be reviewed annually as laws change. Washington is the one permanent geo-block.

## Key State-Specific Issues

### California
- CCPA/CPRA: most restrictive privacy law in the US — build to this standard
- Skill games: generally legal (California Penal Code §330 exempts games of skill from gambling prohibition)
- AG: most aggressive AG in the US on consumer protection and tech
- No DFS-specific licensing requirement

### New York
- DFS: requires DFS operator license from NY Gaming Commission
- Martin Act: NY AG can pursue fraud without proving intent — very low bar
- Privacy: no comprehensive privacy law yet (as of 2025) but aggressive AG enforcement
- Action: NYC is a huge market; worth pursuing NY DFS license if product qualifies

### Texas
- TDPSA: applies to virtually any commercial entity collecting personal data — effective July 2024
- Skill games: legal under Texas law (Texas Penal Code §47.02(c))
- No DFS-specific license required
- Large market: prioritize Tier 3 analysis to get to launch

### Illinois
- BIPA: applies to any biometric data collection from Illinois residents — $1,000 per negligent violation, $5,000 intentional
- If KYC uses facial recognition: BIPA compliance required for IL users or use a BIPA-compliant KYC vendor
- DFS: legal with registration

### Washington
- Geo-block. Always. Do not reconsider until RCW 9.46 is amended.

## Money Transmission State Matrix

| Approach | States Requiring License |
|----------|------------------------|
| Custodial (you hold user funds) | All 50 states (federal FinCEN + state MTL) |
| Non-custodial smart contract | May avoid MTL in most states — get legal opinion |
| Crypto-only non-custodial | Best MTL risk profile; OFAC screening still required |

**Best architecture for MTL avoidance**: smart contract escrow where users send directly to contract; platform never holds funds in omnibus account.

## Maintaining the Compliance Database
- Living document: update when new legislation passes, court decisions shift landscape, AG takes action
- Monitoring: set Google Alerts for "[state] skill game legislation" and "[state] prediction market bill"
- Annual review: review all state statuses each January before the legislative session begins
- Counsel role: proactively flag state law changes that affect the compliance posture

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
