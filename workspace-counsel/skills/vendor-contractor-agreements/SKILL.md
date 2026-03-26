# SKILL 76: Vendor & Contractor Agreements

## Purpose
Legal protection for every external relationship that touches your product — developers, vendors, SaaS providers, subcontractors. The right agreements prevent IP disputes, tax disasters, and security breaches.

## Independent Contractor Agreement — Required Elements

### Scope of Work
- Specific deliverables (not "help with development" — list exact outputs)
- Timeline and milestones
- Acceptance criteria for each milestone
- Revision rounds included vs. charged separately

### Payment
- Fixed fee per milestone preferred over hourly (clearer budget, aligned incentives)
- Payment terms: net 30 after milestone acceptance
- Late payment: 1.5%/month interest on overdue amounts
- Expenses: reimbursed only with pre-approval and receipts

### IP Assignment (CRITICAL)
> "All work product, including but not limited to source code, designs, documentation, inventions, and improvements, created by Contractor in connection with this Agreement shall be the sole and exclusive property of the Company. Contractor hereby assigns all right, title, and interest in such work product to the Company, including all intellectual property rights."

- Includes: everything made using company resources, time, or information
- Work made for hire doctrine: where applicable, work is "work made for hire" under 17 U.S.C. § 101
- Prior IP: list any pre-existing IP the contractor retains (they must carve it out explicitly)

### Confidentiality
- NDA embedded in the agreement (no separate NDA needed)
- Covers: all company information, user data, technical systems, business plans
- Survives termination for [2–5 years] or until information is publicly known

### Non-Solicitation
- Contractor won't solicit your employees for [12–24 months] after engagement
- Note: not a non-compete — just a non-solicitation (more enforceable, less restrictive)

### Independent Contractor Status
> "Contractor is an independent contractor, not an employee. Nothing in this Agreement creates an employment relationship, partnership, or joint venture."
- **Why critical**: misclassification as employee → back payroll taxes, benefits, workers comp liability
- Tax: collect W-9 (US) before first payment; W-8BEN for non-US contractors
- Issue 1099-NEC if US contractor is paid >$600/year

### Termination
- Either party: [14/30] days written notice
- For cause: immediate termination if contractor violates IP assignment, confidentiality, or prohibited conduct provisions
- On termination: contractor delivers all work product, deletes company data

### Indemnification
- Contractor indemnifies company for: IP infringement in their work product, their own tax obligations, their compliance with applicable law
- Company indemnifies contractor for: company's use of the work product as directed

## Software Development Agreement (External Dev Shops)
Everything in the contractor agreement PLUS:

- **Source code ownership**: company owns ALL source code. No license-back to the developer.
- **Escrow**: if dev shop goes bankrupt, source code held in escrow is accessible to company
- **Warranty**: code is free from known material defects, substantially conforms to specifications, does not infringe third-party IP
- **Acceptance testing**: define acceptance criteria for each milestone. Payment contingent on acceptance.
- **Security requirements**: follow OWASP guidelines, no hardcoded credentials, no known vulnerabilities, no GPL/AGPL without prior approval
- **Bug fix support**: [90-day] post-delivery support for defects, included in contract price
- **Source control**: all code committed to company-controlled repository (GitHub org, not contractor's account)

## SaaS Vendor Agreement Review Checklist
Before signing any vendor TOS, verify:

| Issue | What to Verify | Red Flag |
|-------|---------------|---------|
| Data ownership | You own YOUR data | "Vendor owns all data" |
| Data portability | You can export all data | No export capability |
| SLA | 99.9%+ uptime guarantee | No uptime commitment |
| Data security | Encryption at rest and transit, access controls | No security specifications |
| Breach notification | 72-hour notice | No breach notification obligation |
| Termination and data return | Data returned within 30 days after termination | Data deleted immediately |
| Sub-processors | List of sub-processors provided | No sub-processor transparency |
| DPA availability | Standard DPA available (for GDPR compliance) | No DPA |

### Key Vendors to Negotiate Enterprise Terms With
- **Supabase**: database hosting, data processing agreement
- **Vercel**: frontend hosting, DPA
- **Anthropic**: AI API, enterprise agreement covering your use case (CRITICAL — see SKILL 45)
- **OpenAI**: backup AI API, enterprise agreement

## Subprocessor Agreements (GDPR)
If serving EU users:
- Vendors that process EU user data are "subprocessors"
- Data Processing Agreement (DPA) required with each subprocessor
- Maintain a subprocessor list: vendors, data processed, purpose, location, safeguards
- Most major vendors have standard DPAs: Supabase (dpa.supabase.com), Vercel (vercel.com/legal/dpa), Anthropic

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
