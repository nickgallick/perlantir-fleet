# SKILL 48: Antitrust & Competition Law

## Purpose
Understand when platform growth triggers antitrust risk, what practices are per se illegal, and how to defend against competitor antitrust complaints.

## When Antitrust Applies
- 30%+ market share: starts raising questions
- 50%+ market share: creates presumption of market power
- Even without dominance: certain PRACTICES trigger antitrust regardless of market share

## Sherman Act §1 — Agreements in Restraint of Trade

### Per Se Illegal (No Business Justification Defense)
- **Price fixing**: coordinating with competitors on fees
- **Market allocation**: agreeing with another platform "you take sports, we take politics"
- **Group boycott**: coordinating with other platforms to exclude a competitor
- **Tying**: "you can only use Agent Sparta if you also use our prediction market" — illegal if you have market power in one product

### Rule of Reason (Justification Defense Available)
- Exclusive dealing arrangements
- Vertical restraints (between platform and participants)
- Most partnership agreements with non-compete provisions
- Defense: demonstrate pro-competitive justification + limited anticompetitive effect

## Sherman Act §2 — Monopolization

### What IS Legal
- Having a monopoly through superior product, business acumen, or historical accident

### What is NOT Legal
- **Maintaining** a monopoly through exclusionary conduct
- Examples of exclusionary conduct:
  - Exclusive contracts with all major AI labs (preventing competitors from accessing models)
  - Below-cost pricing to drive out competitors (predatory pricing — must be below marginal cost AND with reasonable prospect of recoupment)
  - Refusing to interoperate with competing platforms
  - Self-preferencing: your own agents receive favorable scoring/visibility on your platform
  - Denial of access to essential facilities

## Platform-Specific Antitrust (Post-Epic v. Apple)

### If Agent Sparta Controls a Market
- If Agent Sparta becomes the dominant/only AI competition platform: platform antitrust applies
- Self-preferencing risk: if Perlantir agents compete on Agent Sparta with better scoring algorithms → antitrust concern
- Fee structure: if excessive fees create competitive foreclosure → potential issue at scale
- Data advantages: if your platform gives you data competitors can't access → potentially exclusionary (see *FTC v. Facebook*)

### Connector/API Standard
- Keep the connector/API open and non-discriminatory
- Document: any AI agent framework that meets the public spec can participate
- Do NOT make exclusive deals with AI providers to prevent competitors from using those models
- Open standards = antitrust protection (you're NOT restricting access)

## Relevant Case Law
- *United States v. Google* (2024): Google liable for monopolization of search through exclusive distribution agreements with Apple, Mozilla, etc.
- *Epic Games v. Apple* (9th Cir. 2023): Apple's App Store restrictions analyzed under rule of reason; mostly upheld but anti-steering injunction issued
- *FTC v. Meta* (ongoing): attempted monopolization through acquisition of Instagram/WhatsApp
- *Aspen Skiing Co. v. Aspen Highlands Skiing Corp.* (1985): essential facilities / refusal to deal doctrine
- *Verizon Communications v. Law Offices of Curtis V. Trinko* (2004): limits on essential facilities doctrine — generally, no duty to deal with competitors

## Antitrust Compliance Practices
1. Keep Agent Sparta connector/API open and documented — any compliant framework participates
2. No exclusive deals with AI providers that prevent competitor platforms from using those providers
3. No predatory pricing (don't price below cost to kill competitors)
4. No self-preferencing: Perlantir agents compete under the same rules as all others
5. Document all pricing decisions with legitimate business justifications
6. No coordination with competitors on fees, market allocation, or participant targeting
7. If competitors request API access / interoperability → don't refuse without legitimate technical justification

## Defense Framework (Competitor Antitrust Complaint)
1. **Challenge market definition**: "AI agent competition" is too narrow — the relevant market includes all AI benchmarks, developer competitions, hackathons, and competitive programming platforms
2. **Deny market power**: even if the defined market is accepted, market share + barriers to entry analysis
3. **Demonstrate open access**: connector spec is public, any agent can participate, no exclusionary agreements
4. **Pro-competitive justification**: all design decisions serve product quality, not exclusion
5. **No harm**: competitor hasn't suffered actual antitrust injury (they can still operate)

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
