# SKILL 49: Tort Liability for AI Decisions

## Purpose
Understand every legal theory a user can deploy when an AI judge or AI prediction system costs them money, and the defenses that protect against each theory.

## The Core Scenario
Agent Sparta: AI judge scores submission incorrectly → user loses prize money
Prediction market: AI model makes a prediction → market resolves incorrectly → users lose money

## Legal Theory 1: Negligence

### Elements User Must Prove
1. **Duty**: Did you owe a duty of care to the user?
   - If they paid entry fees and relied on your judging → yes, duty exists
   - Heightened duty for financial services providers (fiduciary-like)
2. **Breach**: Did your AI judge fail to meet the standard of care?
   - What IS the standard of care for an AI judge? → UNSETTLED LAW
   - Analogies courts may use: medical AI (FDA-regulated), self-driving cars (product liability), financial robo-advisors (fiduciary duty)
   - Defense: standard of care for AI judges has not been established; we used reasonable engineering practices
3. **Causation**: Did the breach cause the user's loss?
   - User must prove: they WOULD have won but for the scoring error
   - Difficult to prove in competitive context (other submissions may have been better)
4. **Damages**: Quantifiable financial loss — the prize money not received

### Negligence Defense
- **No breach**: AI judge performed within disclosed parameters; used reasonable engineering practices
- **Causation**: user cannot prove they would have won; scoring was close and other factors were determinative
- **Assumption of risk**: user accepted TOS acknowledging AI scoring limitations
- **Contributory negligence**: user's submission had other defects independent of the alleged scoring error
- **Limitation of liability clause**: TOS limits liability to entry fee paid
- **Arbitration clause**: dispute must go to arbitration, not court

## Legal Theory 2: Breach of Contract

### Elements User Must Prove
1. Valid contract exists (yes — TOS accepted at signup)
2. Specific contractual obligation: TOS promised "fair" or "accurate" judging
3. Breach: AI judge failed to provide what was promised
4. Damages: quantifiable loss

### Breach of Contract Defense
**CRITICAL**: Your TOS must NOT promise accuracy or fairness in absolute terms.

**TOS Language That Protects You:**
> "AI judging is provided on an 'as-is' basis. The Platform makes no warranty, express or implied, regarding the accuracy, completeness, or fitness for any particular purpose of the AI judging system. AI scoring decisions are final except through the platform's dispute resolution process described in Section X."

> "The Platform's maximum liability for any claim arising from judging errors is limited to the entry fee paid by the user for the affected contest."

- **Disclaimer**: no warranty of accuracy → no contractual obligation for perfect scoring
- **Limitation of liability**: cap liability at entry fees paid
- **Dispute resolution**: user must exhaust internal process first
- **Exclusive remedy**: dispute resolution process IS the remedy; no separate breach of contract action

## Legal Theory 3: Product Liability (Strict Liability)

### The Risk
- If AI judge is classified as a "product": strict liability for defects — no need to prove negligence
- Traditional rule: software = service, not product. Courts have been inconsistent.
- EU AI Act (effective 2025): treats certain AI systems as products → EU product liability
- US trend: moving toward product liability for AI systems in high-stakes contexts

### Product Liability Defense
- **Service classification**: AI judging is a service, not a product (Restatement (Second) of Torts §402A doesn't apply)
- **No manufacturing defect**: AI judge performed as designed; scoring reflects inherent AI variability, not a defect
- **Assumption of risk**: user knew AI judging involved inherent variability; TOS discloses this
- **Economic loss rule**: purely economic losses (missed prize money) are not recoverable under product liability in most states

## Legal Theory 4: Fraud / Misrepresentation

### Elements User Must Prove
1. False statement of material fact
2. Plaintiff's justifiable reliance
3. Damages

### Fraud Exposure Points
- Claiming AI judge is "99% accurate" when it's not → fraudulent misrepresentation
- Knowing the AI judge has a known bug and not disclosing it → fraud by omission
- Overstating AI capabilities in marketing materials → FTC deception + fraud

### Fraud Defense
- **Accurate marketing**: all AI accuracy claims are substantiated by documented testing data
- **No known defects undisclosed**: no hidden bugs at time of user's contest
- **Opinion vs. fact**: marketing statements are puffery (opinions), not actionable as fraud
- **TOS disclaimers**: "AI scoring is provided without warranty; results may vary" negates reliance
- **No reliance**: user participated despite knowing AI scoring is not guaranteed

## Required TOS Provisions (Build These In NOW)

```
AI Judging Disclaimer:
"The Platform uses artificial intelligence (AI) systems for contest judging and 
evaluation. AI systems may produce variable results and are not infallible. The 
Platform makes no representation or warranty regarding the accuracy of any AI 
judging decision. AI judging is provided 'as is' without warranty of any kind.

Limitation of Liability:
To the maximum extent permitted by applicable law, the Platform's total liability 
to you for any claim arising from or related to the judging of your submission 
shall not exceed the entry fee you paid for the affected contest.

Assumption of Risk:
By entering a contest, you acknowledge and accept that: (a) AI judging involves 
inherent variability and uncertainty; (b) no AI system is perfectly accurate; 
(c) you have reviewed the scoring rubric and contest rules; (d) the dispute 
resolution process described in Section X is your sole remedy for judging disputes.

Dispute Resolution:
All disputes regarding AI judging must be submitted through the Platform's internal 
dispute resolution process within 30 days of the contest result. Internal dispute 
resolution must be exhausted before initiating external arbitration."
```

## Risk Mitigation Architecture
1. **Multi-judge system**: 3 AI judges, median score (reduces individual error impact)
2. **Human appeal**: Tier 2 human review available for all disputes
3. **Immutable logging**: store all inputs, prompts, and outputs for every scoring decision
4. **Published methodology**: transparency strengthens assumption of risk defense
5. **Insurance**: E&O (Errors & Omissions) policy covering AI decision-making errors
6. **Track record**: maintain and publish historical accuracy metrics

## Risk Levels
- AI judge error on $10K prize without proper TOS: 🔴 High
- AI judge error on $10K prize WITH proper TOS + dispute process: 🟡 Medium
- Fraud claim if AI claims substantiated: 🟢 Low
- Product liability in EU without AI Act compliance: 🔴 High

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
