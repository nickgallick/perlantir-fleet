# SKILL: Litigation Preparation for Crypto Platforms
**Version:** 1.0.0 | **Domain:** Class Action Defense, Securities Litigation, Discovery, Expert Witnesses

---

## Class Action Defense

### The Arbitration Clause — First Line of Defense
**Authority:** Federal Arbitration Act, 9 U.S.C. §§ 1-16

**Governing precedent:**
- *Epic Systems Corp. v. Lewis*, 584 U.S. 497 (2018): Supreme Court (5-4) upheld class action waivers in mandatory arbitration agreements. Employer may require individual arbitration, waiving class action rights.
- *AT&T Mobility LLC v. Concepcion*, 563 U.S. 333 (2011): States cannot invalidate class action waivers in arbitration agreements via consumer protection laws.
- *American Express Co. v. Italian Colors Restaurant*, 570 U.S. 228 (2013): Even when individual arbitration is economically irrational (cost exceeds potential recovery), arbitration clause is enforceable.

**Requirements for an enforceable class action waiver:**
1. **Conspicuous disclosure:** User must have actual or constructive notice. Buried clauses fail. (*Nguyen v. Barnes & Noble*, 763 F.3d 1171 (9th Cir. 2014); *Berkson v. Gogo LLC*, 97 F. Supp. 3d 359 (E.D.N.Y. 2015))
2. **Affirmative acceptance:** Clickwrap (user clicks "I Agree") is enforceable; browsewrap (passive) is NOT reliably enforceable
3. **Mutual waiver:** Both platform and user waive class action rights — one-sided waivers face more scrutiny
4. **Small claims carve-out:** Include a small claims court exception (FTC guidance; some courts require this)

**Model waiver language:**
> ARBITRATION AND CLASS ACTION WAIVER: ALL DISPUTES ARISING OUT OF OR RELATED TO THIS AGREEMENT OR YOUR USE OF THE PLATFORM SHALL BE RESOLVED BY FINAL AND BINDING INDIVIDUAL ARBITRATION ADMINISTERED BY JAMS PURSUANT TO ITS CONSUMER ARBITRATION RULES. **YOU AND [COMPANY] EACH WAIVE THE RIGHT TO A JURY TRIAL AND TO PARTICIPATE IN ANY CLASS ACTION, CLASS ARBITRATION, OR REPRESENTATIVE PROCEEDING.** This Section does not prevent either party from seeking relief in a small claims court for disputes within that court's jurisdiction.

**Implementation:**
- Use JAMS or AAA as the arbitration administrator (well-respected; their rules are balanced)
- Venue: Delaware or neutral major city
- Governing law: Delaware (most developed corporate law; no class action carve-out issues)
- Version: timestamp every TOS version; log which version each user agreed to

**California exception:**
- California courts are more likely to invalidate arbitration clauses that are unconscionable
- If significant California user base: have California-specific legal review of your arbitration clause
- California Private Attorneys General Act (PAGA) claims cannot be waived in arbitration — PAGA is its own problem

---

## Securities Class Action Defense

**Trigger:** Your token is ruled a security → anyone who bought it has a potential Section 12(a)(1) claim.

**Section 12(a)(1) of the Securities Act of 1933, 15 U.S.C. § 77l(a)(1):**
- Strict liability for selling unregistered securities
- Does NOT require proof of fraud — just that the security was unregistered
- Seller must repay the purchase price (rescission) if the buyer still holds, OR damages if already sold
- Defense: seller can reduce damages by proving the decline in value was caused by something other than the registration violation

**Section 11, Securities Act of 1933, 15 U.S.C. § 77k:**
- Liability for material misstatements or omissions in a registration statement
- Less relevant if you never filed a registration statement (i.e., you were unregistered)

**Statute of limitations:**
- Section 12(a)(1): 1 year from when the plaintiff knew or should have known about the violation, but no more than 3 years from the date of the sale
- *Lampf, Pleva, Lipkind, Prupis & Petigrow v. Gilbertson*, 501 U.S. 350 (1991): established this limitations period for federal securities claims

**Primary defense:** The token was NOT a security (Howey analysis). Secondary defense: the sale qualified for an exemption (Reg D, Reg S). Both defenses require pre-launch legal work.

---

## Discovery in Crypto Litigation

### What Opposing Counsel WILL Do:
1. **Hire Chainalysis or TRM Labs:** Every on-chain transaction involving your protocol will be mapped. Wallet addresses will be linked to identities using exchange KYC data (obtained via subpoena). All financial flows will be reconstructed.
2. **Subpoena your cloud providers:** AWS, Google Cloud, Azure — all your logs, all your databases, all your backups.
3. **Subpoena your communication platforms:** Slack, Discord, Telegram, Signal (though Signal messages may be harder to get), email.
4. **Subpoena your key employees:** Testimony depositions. They WILL be asked about every internal discussion about regulatory strategy.
5. **Obtain your smart contract deployment records:** Every deployment transaction, every admin action, every parameter change is on-chain and immutable.

### The Golden Rule of Business Communications
**NEVER put anything in writing that you wouldn't want read aloud in a courtroom.**

This means:
- ❌ "We geo-block but let's not use KYC so US users can still get in via VPN"
- ❌ "The token is definitely going to 10x when we launch Phase 2"
- ❌ "Don't worry about the CFTC, they can't touch us"
- ❌ "We're calling it a skill competition but it's basically a betting app"
- ❌ "Let's not register with Iowa, it'll take too long"

**Everything you type in Slack, Discord, Telegram, or email is discoverable in litigation.** Train your team on this from Day 1.

### Agent Communications as Discovery
- Your AI agents' transcripts and logs are discoverable
- If Agent Maks (builder agent) generated code with comments about regulatory avoidance → discoverable
- If MaksPM's task logs include notes about avoiding state licensing → discoverable
- **Implication:** Internal agent logs should be treated as confidential business records subject to the same communication standards as human emails

---

## Litigation Hold Implementation

### When to Implement
A litigation hold is required when litigation is "**reasonably anticipated**" — even before a lawsuit is filed. This includes:
- Receipt of a regulatory subpoena or CID (Civil Investigative Demand)
- Receipt of a demand letter from a plaintiff's attorney
- News coverage suggesting regulatory investigation
- Internal knowledge that you may have violated a law

**Failure to implement a litigation hold after litigation becomes reasonably anticipated = SPOLIATION.**
Sanctions for spoliation: adverse inference instructions to the jury ("assume the destroyed evidence was bad for you"), monetary sanctions, case-dispositive sanctions, referral for criminal obstruction charges.

### Litigation Hold Implementation Steps:
1. **Issue a hold notice immediately** to all custodians (employees, contractors, agents with relevant information)
2. **Suspend all auto-deletion policies** (Slack retention policies, email auto-delete, cloud storage lifecycle policies)
3. **Identify relevant custodians:** Who touched this product? Who made regulatory decisions? Who knew what and when?
4. **Preserve:** All email, all Slack/Discord/Telegram messages, all code repositories (git history), all smart contract deployment records, all financial records, all legal opinions
5. **Legal team involvement:** All preservation decisions should be made with counsel (attorney-client privilege applies to hold instructions)

---

## Expert Witnesses in Crypto Cases

**Courts are still learning crypto.** Expert witnesses are not optional — they're essential.

### Types of Experts You Need:
| Type | Role | Approximate Cost |
|---|---|---|
| Blockchain forensics | Trace on-chain flows, identify wallet ownership, reconstruct transactions | $500-$1,000/hour (Chainalysis analysts, former DOJ blockchain analysts) |
| Smart contract security | Explain whether code is custodial or non-custodial, whether admin controls exist, security audits | $400-$800/hour (Trail of Bits, OpenZeppelin engineers) |
| Financial economics | Token valuation, market manipulation analysis, damages calculation | $600-$1,500/hour (academic economists, former Fed or SEC economists) |
| Regulatory | How the CFTC/SEC actually applies these rules in practice | $800-$2,000/hour (former CFTC/SEC commissioners or senior staff) |
| Gambling/gaming law | Skill vs. chance analysis, state gambling law | $400-$700/hour (former state gaming commission officials) |

**Advisory board value:** Having a former CFTC Commissioner, SEC Commissioner, or senior gaming regulator on your advisory board serves dual purposes — legitimacy and a potential expert witness who already understands your product.

---

## Document Preservation Strategy (Pre-Litigation, Ongoing)

| Document Type | Retention Period | Storage |
|---|---|---|
| User agreements (TOS, each version) | Permanent | Immutable storage (IPFS or equivalent + local) |
| User acceptance records (who agreed to which TOS, timestamp, IP) | 5 years minimum | Encrypted database |
| KYC records | 5 years minimum (BSA requirement) | Encrypted, access-controlled |
| Legal opinions | Permanent | Privileged document management system |
| Financial records | 7 years (IRS standard) | Accounting software + secure backup |
| Communications | 3 years operational / indefinite once litigation anticipated | Archiving platform (Vanta, Drata) |
| Smart contract deployment records | Permanent (they're on-chain anyway) | Document the off-chain decisions that led to each deployment |
| State registrations | Permanent | Entity management software |

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
