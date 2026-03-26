# SKILL: Privacy Law — Complete US & EU Framework
**Version:** 1.0.0 | **Domain:** CCPA, GDPR, COPPA, ICDPA, BIPA, Breach Notification

---

## Federal Privacy Laws

### COPPA — Children's Online Privacy Protection Act
**Authority:** 15 U.S.C. §§ 6501-6506; 16 C.F.R. Part 312
**Applies to:** Websites/apps directed at children under 13, OR that knowingly collect data from children under 13
**Penalty:** Up to $51,744 per violation (FTC enforces; adjusted annually)
**FTC enforcement examples:**
- Epic Games (Fortnite): $275M fine (2023) — largest COPPA penalty ever
- Google/YouTube: $170M fine (2019) — collecting data on child viewers

**Compliance requirements:**
- Verifiable parental consent BEFORE collecting ANY data from known under-13 users
- Clear, prominent privacy notice on any page where data is collected
- Data minimization: collect only what's necessary for the child-directed activity
- No behavioral advertising to children
- Data deletion on parental request

**For Agent Sparta/prediction market:**
- TOS must state: "Platform is for users 18 and older only"
- Age gate at signup: collect birth year or date of birth
- If you discover a user is under 13: immediately delete ALL their data, no exceptions
- If platform has ANY educational angle (AI tutoring, learning features): heightened COPPA risk → consult counsel

---

### FTC Act Section 5 — Unfair or Deceptive Practices
**Authority:** 15 U.S.C. § 45
**The catch-all:** FTC's broadest privacy enforcement tool

**"Deceptive":** Your privacy policy says X; you do Y → deceptive
**"Unfair":** You collect data without adequate security → unfair

**Key FTC privacy enforcement actions:**
- Facebook: $5B penalty (2019) — violated FTC consent decree on user privacy
- Zoom: consent decree (2021) — misrepresented security practices ("end-to-end encrypted" when it wasn't)
- Twitter: $150M penalty (2022) — collected phone numbers for security, used them for advertising

**Practical rules:**
- Your privacy policy must EXACTLY describe what you actually do — no overcommitting
- Never say "we never share your data" unless you actually never share it with anyone
- Never claim security practices you don't have ("bank-level encryption," "military-grade security" → you'd better be able to prove it)
- FTC consent decrees: 20-year compliance obligations + independent biennial audits → devastating for a startup

---

### GLBA — Gramm-Leach-Bliley Act
**Authority:** 15 U.S.C. §§ 6801-6827; 16 C.F.R. Part 314 (Safeguards Rule)
**Applies to:** "Financial institutions" — broadly includes any business "significantly engaged" in providing financial services

**Does it apply to Agent Sparta?** Possibly — if classified as providing "financial services" (processing payments, holding prize pools even briefly). Get legal opinion.

**If it applies:**
- Annual privacy notice to customers: what data you collect, how you use it, how you share it
- Opt-out for sharing with non-affiliated third parties
- **Safeguards Rule** (updated 2023): written information security plan, designated security coordinator, risk assessment, employee training, monitoring, incident response plan
- Sanctions: FTC enforcement + state AG enforcement; no private right of action

---

## State Privacy Laws — The Complete Patchwork

### California CCPA/CPRA
**Authority:** Cal. Civ. Code §§ 1798.100-1798.199 (CCPA); Prop. 24 amendments (CPRA, effective Jan. 1, 2023)

**Thresholds (any ONE triggers compliance):**
- Annual gross revenues > $25 million, OR
- Annually buys, sells, or shares personal information of 100,000+ California consumers/households, OR
- Derives 50%+ of annual revenues from selling/sharing personal information

**Consumer rights (CCPA/CPRA):**
- Right to know what data is collected
- Right to delete personal information
- Right to correct inaccurate information (CPRA added)
- Right to opt out of SALE or SHARING of personal information
- Right to limit use of sensitive personal information
- Right to non-discrimination for exercising rights
- Right to portability

**Sensitive personal information (opt-in consent required for certain uses):**
- SSN, financial account numbers, health information, biometrics, geolocation, race/ethnicity, sexual orientation, private communications

**Private right of action:** ONLY for data breaches ($100-$750/consumer/incident, or actual damages, whichever is greater)
**AG enforcement:** All other violations; $2,500 per violation, $7,500 per intentional violation
**Enforcement:** California Privacy Protection Agency (CPPA) + California AG

**"No cure period" as of 2023:** CPPA can sue immediately without 30-day cure notice

---

### Iowa ICDPA — Iowa Consumer Data Protection Act
**Authority:** Iowa Code Chapter 715D (effective January 1, 2025)

**Thresholds (either triggers compliance):**
- Controls or processes personal data of 100,000+ Iowa consumers during a calendar year, OR
- Controls or processes personal data of 25,000+ Iowa consumers AND derives >50% of gross revenue from the sale of personal data

**Consumer rights under ICDPA:**
- Right to access personal data collected
- Right to deletion
- Right to portability (data in machine-readable format)
- Opt out of: targeted advertising, sale of personal data, profiling that produces legal or similarly significant effects

**NOT in ICDPA (narrower than CCPA):**
- No right to correct inaccurate data
- No data minimization requirement
- No right to opt out of AI decision-making (unless "similarly significant effects")

**Sensitive data:** REQUIRES opt-in consent to process (race/ethnicity, religious beliefs, mental/physical health, sexual orientation, citizenship/immigration status, biometric data, geolocation, known children's data)

**NO private right of action:** Iowa AG enforcement only
**90-day cure period:** Through January 1, 2026 (then discretionary — AG may or may not give cure time)
**Penalties:** Iowa AG civil action; actual damages + injunctive relief

---

### Other State Privacy Laws (2025-2026)

| State | Law | Effective | Key Threshold |
|---|---|---|---|
| Virginia | VCDPA | Jan 1, 2023 | 100K consumers or 25K + >50% revenue from data |
| Colorado | CPA | Jul 1, 2023 | 100K consumers or 25K + >50% revenue from data |
| Connecticut | CTDPA | Jul 1, 2023 | 100K consumers or 25K + >50% revenue from data |
| Utah | UCPA | Dec 31, 2023 | 100K consumers OR 25K + >50% revenue from data |
| Texas | TDPSA | Jul 1, 2024 | 100K consumers (no revenue threshold alternative) |
| Oregon | OCPA | Jul 1, 2024 | 100K consumers or 25K + >25% revenue from data |
| Montana | MCDPA | Oct 1, 2024 | 50K consumers or 25K + >25% revenue from data |
| New Hampshire | NHPA | Jan 1, 2025 | 35K consumers or 10K + >25% revenue from data |
| New Jersey | NJDPA | Jan 15, 2025 | 100K consumers or 25K + >50% revenue from data |
| Delaware | DPDPA | Jan 1, 2025 | 35K consumers or 10K + >20% revenue from data |
| Iowa | ICDPA | Jan 1, 2025 | 100K consumers or 25K + >50% revenue from data |
| Tennessee | TIPA | Jul 1, 2025 | 175K consumers or 25K + >50% revenue from data |
| Indiana | IDCPA | Jan 1, 2026 | 100K consumers or 25K + >50% revenue from data |

**The CCPA standard covers all of them.** Build to CCPA compliance → compliant with all other state laws.

---

### GDPR — General Data Protection Regulation
**Authority:** EU Regulation 2016/679 (effective May 25, 2018)
**Applies to:** Processing personal data of EU residents, regardless of company location

**Fines:** Up to €20M or 4% of global annual turnover, whichever is higher

**Key requirements:**
- **Lawful basis for processing:** Consent, contract, legal obligation, vital interests, public task, or legitimate interests
- **Data minimization:** Collect only what's necessary for the specified purpose
- **Purpose limitation:** Use data only for stated purpose
- **Right to erasure ("right to be forgotten"):** Delete personal data on request (within 30 days)
- **Right to portability:** Provide data in machine-readable format
- **Data Protection Impact Assessment (DPIA):** Required for high-risk processing (profiling, large-scale systematic monitoring)
- **Data Protection Officer (DPO):** Required for large-scale systematic monitoring; optional for smaller operations but good practice
- **72-hour breach notification:** To supervisory authority (and affected individuals if high risk)
- **Cross-border transfers:** Standard Contractual Clauses (SCCs) or adequacy decision required for transfers outside EU

**Blockchain + GDPR tension:**
- Right to erasure vs. blockchain immutability: you cannot delete on-chain data
- Solution: store ALL personally identifiable information (PII) OFF-CHAIN; store only cryptographic hashes on-chain
- A hash of personal data (without the key) is not personal data — cannot be reversed to identify the person
- Smart contract logs: ensure no PII is emitted in events

**Practical for Nick:** Geo-block EU users until GDPR compliance is implemented. The fine risk ($20M+) exceeds the revenue opportunity at early stage.

---

### BIPA — Illinois Biometric Information Privacy Act
**Authority:** 740 ILCS 14/1 et seq.
**Unique feature:** PRIVATE RIGHT OF ACTION per biometric data point

**Damages:** $1,000/negligent violation, $5,000/intentional violation (per person, per biometric scan)
**Class action risk:** If your KYC uses facial recognition → every Illinois user is a class member

**If your KYC uses facial recognition (Jumio, Onfido):**
- Before collecting: written notice of purpose and retention schedule, written release of consent
- Cannot profit from biometric data
- Must have destruction policy (destroy when no longer needed or within 3 years)

**Workaround:** Use a KYC provider that handles BIPA compliance within their own system (Jumio, Persona). Their user agreement covers BIPA consent. You receive only the verification result (pass/fail), not the biometric data itself. You are NOT the data controller for the biometric data → BIPA doesn't apply to you directly.

---

### Iowa Breach Notification
**Authority:** Iowa Code §715C.2

**Triggers:** Unauthorized acquisition of personal information of Iowa residents
**Definition of "personal information":** Name + SSN, driver's license, financial account number + security code, medical information, health insurance account number, passport number, OR electronic signature

**Notice requirements:**
- To affected Iowa residents: "in the most expedient time possible and without unreasonable delay"
- To Iowa AG: if >500 Iowa residents affected
- Method: written, electronic (if prior consent), or "substitute notice" (website posting + major statewide media) if cost exceeds $250K or >500K residents affected

**Iowa AG contact for breach notification:** Office of the Attorney General, Consumer Protection Division, 1305 E. Walnut St., Des Moines, IA 50319

---

## Minimum Viable Privacy Compliance Stack

**Document 1:** Privacy Policy (current, accurately reflecting all data practices)
**Document 2:** Cookie Policy + consent banner (for GDPR if EU users; for CCPA opt-out)
**Document 3:** Iowa ICDPA notice (once you approach 100K Iowa users)
**Document 4:** COPPA compliance documentation (age gate, parental consent process if any under-13 risk)
**Document 5:** Data Processing Agreement template (for any vendor handling personal data)
**Document 6:** Breach Response Plan (pre-drafted notification letter, contact list, 72-hour checklist)
**Document 7:** Data Retention Schedule (how long you keep each category of data, and deletion process)
**Tool:** OneTrust or Osano (privacy management platforms, $2K-$10K/year) — manages consent, DSARs (data subject access requests), and compliance documentation

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
