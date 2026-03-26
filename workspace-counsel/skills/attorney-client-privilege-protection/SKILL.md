# SKILL 46: Attorney-Client Privilege Protection

## Purpose
Maintain legal privilege in a crypto/AI company that communicates through Slack, Telegram, Discord, and AI agents. One waiver can expose your entire legal strategy to regulators and opposing counsel.

## What Privilege Protects
- Confidential communications between client and attorney for the purpose of obtaining legal advice
- Work product doctrine: documents prepared in anticipation of litigation by or for an attorney
- If privileged: regulators and opposing counsel CANNOT compel production in discovery

## How Privilege is WAIVED (The Danger Zone)

### Waiver by Disclosure to Third Parties
- Sharing a legal memo with ANYONE outside attorney-client relationship → privilege waived for that communication
- Forwarding a lawyer's email to an advisor, investor, or contractor → waived
- Discussing legal advice in a Slack channel with non-privileged parties → waived
- Posting legal analysis in Discord → waived (public disclosure)
- **AI agent accessing a legal memo** → potentially waived (unsettled law — treat as waived)
- Rule: if someone outside the attorney-client relationship sees it → it's waived

### Subject Matter Waiver (The Cascade Risk)
- Voluntarily disclose privileged information on one topic → courts can compel ALL related privileged communications on that topic
- Example: testify "our lawyer said this structure is legal" → you've waived privilege on the lawyer's ENTIRE analysis of that structure

## AI Agents and Privilege (CRITICAL)
**Unsettled law.** No court has definitively ruled on whether sharing privileged communications with an AI agent waives privilege.

**Conservative approach (required for Perlantir):**
- Treat ALL AI agent communications as NON-PRIVILEGED
- NEVER share actual attorney opinions, memos, or privileged analysis with any AI agent
- Counsel (the AI agent) role: independent legal RESEARCH and INTELLIGENCE only
- Counsel is NOT a conduit for actual attorney communications
- NEVER paste a lawyer's memo into Counsel and ask it to summarize → potentially waives privilege on the memo

**The Two-Stream Rule:**
- Stream 1: Outside counsel provides PRIVILEGED legal opinions → Nick reads them, acts on them, stores them securely
- Stream 2: Counsel (AI agent) does INDEPENDENT research → supplements, does not receive, privileged counsel work
- These streams NEVER cross. Nick synthesizes both. AI agents never see Stream 1.

## Privilege Protection Protocols by Platform

### Slack
- Create a dedicated `#legal-privileged` channel: ONLY Nick + attorneys + named legal team members
- All legal strategy discussions: `#legal-privileged` ONLY
- Never discuss legal analysis in: `#general`, `#product`, `#engineering`, or any agent-accessible channels
- Label all messages: "[PRIVILEGED AND CONFIDENTIAL]" in legal strategy messages

### Email
- Subject line: "PRIVILEGED AND CONFIDENTIAL — ATTORNEY-CLIENT COMMUNICATION"
- Body header: "This communication is protected by the attorney-client privilege. Do not forward."
- Never CC: employees who don't need to know, investors, advisors unless they're part of the legal team
- BCC: never (creates undisclosed third-party recipients)

### Telegram / Signal
- Do NOT use for legal strategy discussions
- Use for: operational coordination only
- If a legal question comes up in Telegram: "Let's take this offline — I'll email you"

### Document Storage
- Privileged documents: separate folder/vault with access controls
- Label every document: "PRIVILEGED AND CONFIDENTIAL" in filename and header
- Access log: know who has accessed privileged documents
- Cloud storage: encrypted, access-controlled (not public Google Drive, not Notion)

## Document Retention and Privilege Log
- Maintain a privilege log: list of all documents withheld from production as privileged
- Required in litigation: log must include document date, author, recipient, subject matter (not substance), privilege basis
- Pre-litigation: maintain the log anyway — it demonstrates good faith when litigation arrives
- Litigation hold: when litigation is anticipated, preserve ALL documents including privileged ones (you still assert privilege; you just don't destroy them)

## The Crime-Fraud Exception
- Privilege does NOT protect communications made to further a crime or fraud
- If you consulted your lawyer to help you break the law (not understand it) → privilege is pierced
- "Advice of counsel" defense requires: you gave your lawyer COMPLETE AND ACCURATE facts
- If you lied to your lawyer to get a favorable opinion → crime-fraud exception applies, privilege gone

## Practical Privilege Checklist
- [ ] `#legal-privileged` Slack channel created with restricted access
- [ ] Email template with privilege header configured
- [ ] Outside counsel agreement specifying privilege protections
- [ ] No attorney memos or opinions shared with AI agents (ever)
- [ ] Privileged document storage separate from operational documents
- [ ] All employees briefed: "legal strategy stays in #legal-privileged"
- [ ] Litigation hold template ready to deploy within 1 hour

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
