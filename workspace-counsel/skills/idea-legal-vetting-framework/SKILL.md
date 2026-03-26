# SKILL 69: Idea Legal Vetting Framework

## Purpose
Produce a complete Legal Vetting Report for ANY new product idea. Apply this framework every time Nick brings a new product concept — before a single line of code is written.

## The Legal Vetting Report — 7 Sections

### Section 1 — Regulatory Classification
For the proposed product, answer each question with YES / NO / GRAY AREA + statutory citation:

| Question | Analysis Required | Key Statutes |
|----------|-----------------|-------------|
| Is it a security? | Howey test: investment of money + common enterprise + expectation of profits + efforts of others | 15 U.S.C. §77b(a)(1); SEC v. W.J. Howey Co. |
| Is it a commodity/derivative/swap? | Does it involve a commodity (Bitcoin, ETH, oil) or a contract for future delivery? | 7 U.S.C. §2 (CEA); CFTC jurisdiction |
| Is it gambling? | Three-element test: consideration + chance + prize. Any one element removable? | State-by-state; Iowa Code §99B |
| Is it money transmission? | Does platform custody user funds? Does it exchange value? | 31 C.F.R. §1010.100(ff); state MTL statutes |
| Is it insurance? | Does it indemnify a loss? Does it require insurable interest? | State insurance codes; see SKILL 56 |
| Is it a consumer financial product? | Does it offer credit, payment processing, or financial services to consumers? | 12 U.S.C. §5481 (CFPB) |
| Does it involve personal data? | Does it collect, process, or share personal information? | CCPA, ICDPA, GDPR |
| Does it involve AI decisions? | Does AI make consequential decisions about users? | EU AI Act; Colorado AI Act SB 24-205 |
| Does it involve advertising claims? | Will it make claims about performance, returns, or capabilities? | 15 U.S.C. §45 (FTC Act) |

### Section 2 — Jurisdiction Scan
- Federal agencies with potential jurisdiction (for each: explain WHY and the specific authority)
- State agencies: Iowa-first analysis, then CA/NY/TX/WA as key states
- International: GDPR applicability, major market restrictions
- Favorable jurisdictions (where would this product be most welcome legally?)
- Hostile jurisdictions (where should you geo-block from day one?)

### Section 3 — Comparable Products Analysis
- What existing products are most similar?
- How are they structured legally? (regulatory classification, entity structure)
- Enforcement actions against them? (CFTC, SEC, state AG, FTC)
- What did they get right?
- What did they get wrong — and how do we avoid it?

### Section 4 — Risk Matrix
| Risk Category | Likelihood | Severity | Mitigation |
|--------------|-----------|---------|-----------|
| CFTC enforcement | H/M/L | Fine/Injunction/Criminal | [specific] |
| SEC enforcement | H/M/L | Fine/Injunction/Criminal | [specific] |
| State AG action | H/M/L | Fine/Injunction | [specific] |
| Class action lawsuit | H/M/L | $$$$ exposure | [specific] |
| Patent troll | H/M/L | Settlement cost | [specific] |
| Bank/payment deplatforming | H/M/L | Operational disruption | [specific] |
| AI provider termination | H/M/L | Platform outage | [specific] |
| Insurance characterization | H/M/L | State regulator action | [specific] |

### Section 5 — Recommended Structure
- Entity type and jurisdiction
- Regulatory registrations needed (each with: cost, timeline, difficulty)
- Legal opinions needed (each with: estimated cost, who can provide it)
- Compliance infrastructure needed (AML, KYC, surveillance, etc.)
- Total estimated legal budget Year 1
- Estimated time from "go" to legal launch readiness

### Section 6 — Kill Criteria
- Under what circumstances should we NOT build this?
- What regulatory development would make this unviable?
- What is the worst realistic downside (worst-case scenario)?
- What's the "point of no return" — the scale at which regulatory risk becomes unavoidable?

### Section 7 — Go/No-Go Recommendation
- 🟢 **GREEN**: Build it. Regulatory path is clear, risks are manageable, comparable products operate successfully.
- 🟡 **YELLOW**: Build with modifications. Specific changes required. List them. Proceed after changes are implemented.
- 🔴 **RED**: Do NOT build until [specific precondition — regulatory change, legal opinion, license obtained, co-founder with relevant license].
- For YELLOW and RED: exactly what needs to change for it to become GREEN.

## Delivery Format
This is a written document, not a verbal briefing. Produce in full before Nick invests significant development time. Update it when: regulatory landscape changes, product scope changes materially, enforcement actions hit comparable products.

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
