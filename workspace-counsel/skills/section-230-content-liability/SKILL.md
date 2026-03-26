# SKILL: Section 230 & Content Liability
**Version:** 1.0.0 | **Domain:** Section 230, DMCA Safe Harbor, Platform Moderation

---

## Section 230 — The Shield

**Authority:** 47 U.S.C. § 230 (Communications Decency Act, 1996)

### The Core Protection
**§230(c)(1):** "No provider or user of an interactive computer service shall be treated as the publisher or speaker of any information provided by another information content provider."

**Plain English:** Your platform is NOT liable for content that USERS create and post.

### What This Protects You From
- Defamation claims from third parties suing over user comments
- Liability for user-posted predictions that turn out to be wrong (and users claim they relied on them)
- Liability for user-submitted AI agent code that causes harm
- Liability for discussion forums, community posts, user-submitted content

### What Section 230 Does NOT Cover

**1. Content YOU create or "develop"**
- If your platform creates the market descriptions → YOUR content → your liability
- If your AI judge generates an incorrect score that defames someone → potentially your liability (you created and deployed the AI judge)
- If you materially contribute to making illegal content → you become a "developer" and lose protection

**2. Federal Criminal Law**
- Section 230 explicitly does NOT shield criminal liability under federal law
- CSAM (child sexual abuse material): NO protection; mandatory reporting under 18 U.S.C. § 2258A
- Federal trafficking crimes: FOSTA-SESTA (18 U.S.C. § 1591) carved out from Section 230
- Criminal prosecution of any kind: Section 230 is a civil liability shield only

**3. Intellectual Property (Partially)**
- Copyright: Section 230 does NOT override DMCA — use DMCA safe harbor separately
- Trademark: courts are split; Section 230 may or may not protect against trademark infringement by users

**4. Federal Agency Enforcement**
- Section 230 does NOT protect against FTC enforcement actions
- Does NOT protect against CFTC/SEC enforcement for platform's own regulatory violations

### The "Development" Problem — Where You Lose 230 Protection
*Fair Housing Council of San Fernando Valley v. Roommates.com*, 521 F.3d 1157 (9th Cir. 2008):

- Roommates.com required users to select from dropdown menus that asked about race/national origin → platform CREATED the discriminatory choice → lost §230 protection
- If you provide the STRUCTURE that determines what illegal content gets posted → you're a developer, not just a platform

**Agent Sparta application:**
- AI judge scores contests: the AI judge IS your content → you're the content creator for scoring decisions → potential liability for scoring errors
- Solution: design appeal process + Ricardian contract provisions specifying judge's limitations
- User-submitted agent code: that's user content → §230 protects you from liability for what users' agents do

---

## Good Faith Moderation — §230(c)(2)

**§230(c)(2):** Platforms are NOT liable for good-faith moderation decisions — restricting, blocking, or removing "objectionable" content.

**What you can do without liability:**
- Remove content you believe is false, misleading, or violates your terms
- Ban users who violate community standards
- Restrict certain types of content from your platform
- Curate and editorialize

**What kills good faith protection:**
- Selective enforcement based on viewpoint rather than stated policies
- Discriminatory moderation (targeting specific groups)
- Moderation in bad faith (to harm competitors, not to protect platform quality)

---

## DMCA Safe Harbor
**Authority:** 17 U.S.C. § 512 (Digital Millennium Copyright Act)

**Why you need it:** If users can upload content (agent code, competition submissions, profile content, any files) → they may upload copyrighted material → DMCA safe harbor protects you if you comply.

### Four Safe Harbor Requirements (§512)

**1. Designated Agent (§512(c)(2)):**
- Register a DMCA designated agent with the Copyright Office
- Register at: copyright.gov/dmca-directory/ ($6/year)
- Publish agent's name, address, phone, email on your website
- Your website must have a page: "Copyright Policy" with the agent's contact info

**2. Takedown Procedure:**
When you receive a valid DMCA takedown notice:
- Act "expeditiously" to remove or disable access to the allegedly infringing content
- No specific timeframe in statute — industry standard is 24-72 hours for straightforward notices
- Notify the user whose content was removed

**3. Counter-Notification Process:**
If a user believes their content was wrongly removed:
- They send a counter-notification with: identification of removed content, statement under penalty of perjury that removal was a mistake, consent to jurisdiction of federal court
- You: wait 10-14 business days; then restore the content (unless the copyright holder has filed suit)

**4. No Financial Benefit from Infringement:**
- If you financially benefit from infringing activity AND had the right and ability to control it → you lose safe harbor
- Don't create incentives specifically for users to upload copyrighted content

### Valid Takedown Notice Requirements (§512(c)(3))
A notice must include:
1. Signature (physical or electronic) of copyright owner or authorized agent
2. Identification of the copyrighted work
3. Identification of the infringing material and information to locate it
4. Copyright owner's contact information
5. Statement of good faith belief that use is unauthorized
6. Statement under penalty of perjury that information is accurate

**What to do with an INVALID notice:** Send a letter explaining why the notice is deficient. Do NOT remove content based on an invalid notice.

---

## Specific Liability Issues for Agent Sparta / Prediction Market

### AI Judge Scoring Content
- AI judge scores are generated by YOUR platform's AI → YOUR content
- §230 does NOT protect you from liability for your own AI-generated content
- If AI judge incorrectly scores and someone claims the score was defamatory or caused financial loss → potential E&O liability
- **Protection:** TOS limitation of liability clause; Ricardian contract; appeal process; E&O insurance

### User-Submitted AI Agent Code
- Users submit their agent code → USER content → §230 protects you if the agent's code causes harm (to other users, to the platform)
- **Caveat:** If you EXECUTE the user's code on your infrastructure → you may be more than just a host; you're running the code
- **Protection:** Sandboxing and execution limits; TOS requiring users to warrant their code doesn't contain malware; IP indemnification by users

### Prediction Market Discussions and Forums
- Users post: "I think GPT-4o will get the Fed prediction wrong" → user content → §230 protects you
- Platform posts: "According to our analysis, Claude outperforms GPT-4o in financial predictions" → YOUR content → §230 doesn't help

### Community Forums / Discord
- If you operate a Discord server: you're a "provider or user of an interactive computer service" → §230 applies
- Moderate proactively (under §230(c)(2)) for: spam, scams, pump-and-dump coordination
- Don't moderate discriminatorily

---

## CSAM — Mandatory Reporting
**Authority:** 18 U.S.C. § 2258A (PROTECT Our Children Act)

If ANY electronic service provider (which includes online platforms) discovers apparent CSAM on their platform → MANDATORY report to the National Center for Missing and Exploited Children (NCMEC) within 24 hours.

Report at: cybertipline.org or call 1-800-THECYBERTIP

**This is not optional. This is federal law. Criminal penalties apply for failure to report.**

**Practical:** Prediction markets and AI competition platforms are unlikely targets for CSAM. But if users can communicate or share files → implement reporting protocols.

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
