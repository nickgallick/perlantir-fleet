# SKILL 61: Market Resolution — Legal Standard of Care

## Purpose
Resolution is the most legally sensitive operation on a prediction market. Wrong resolution = lawsuits. Ambiguous resolution = disputes. Design resolution methodology that is bulletproof before any market launches.

## Pre-Launch Resolution Specification (Required for Every Market)

Every market MUST specify BEFORE launch:
1. The exact primary resolution source (URL, API endpoint, named authority)
2. The exact data point that determines resolution
3. The exact time window (resolves at 11:59 PM ET on [date], or within 48 hours of event)
4. How ambiguous outcomes are handled
5. What happens if the source is unavailable, disputed, or changes its determination
6. Fallback source hierarchy (primary → secondary → tertiary → void)

**This specification is a legal document.** Courts and arbitrators will evaluate whether you followed it exactly. Deviation = breach of contract.

## Resolution Source Hierarchy (Every Market Must Have All Four)
1. **Primary source**: the definitive authority (Fed Reserve press release, AP election call, official benchmark publication)
2. **Secondary source**: backup if primary unavailable (Bloomberg, Reuters, multiple corroborating sources)
3. **Tertiary source**: last resort — resolution committee vote with documented methodology
4. **Fallback**: if no source can determine the outcome within the specified time window → market voids, all positions refunded at entry price

## Legal Standard of Care
- Platform has a fiduciary-like duty to resolve markets accurately and in good faith
- Even without formal fiduciary status: users paid to participate in reliance on fair resolution → duty of good faith and fair dealing
- **Breach**: resolving incorrectly, prematurely, based on wrong source, or when outcome is ambiguous
- **Defense**: if resolution followed the pre-specified source and methodology exactly → strong breach of contract defense
- **Critical**: deviating from pre-specified source → breach of contract + negligence + potential fraud

## Edge Cases That WILL Happen — Pre-Define All of Them

### Event Cancelled or Postponed
- Market voids; all positions refunded at entry price
- State this explicitly: "If the underlying event is cancelled, postponed, or does not occur by [date], the market voids and all positions are refunded."
- Time limit: "Market voids if event does not occur by [X days after scheduled date]."

### Result Contested After Resolution
- **Pre-specify**: "This market resolves based on the initial [AP call / Fed announcement / official publication] at the time of resolution, regardless of subsequent appeals, recounts, or revisions, UNLESS a correction is published by the primary source within [24 hours / 48 hours]."
- OR: "This market resolves based on the final certified result after all legal challenges are exhausted." (Choose one; state it explicitly.)
- **The choice has legal consequences**: "initial result" → faster resolution, but risk of reversal; "final result" → slower, but more accurate. Specify in the market terms.

### Multiple Valid Sources Disagree
- Pre-specify which source controls: "In the event of conflicting data from multiple sources, [primary source] controls."
- If primary source is ambiguous: invoke dispute process.

### Source Publishes Incorrect Data, Then Corrects
- Pre-specify: "Resolves based on data published by [source] as of [exact time]." OR "Resolves based on corrected data if correction published within [time window]."
- State clearly in market terms — don't leave this to discretion.

### Gradual/Non-Binary Outcome
- Define the exact threshold: "Resolves YES if CPI exceeds 3.5% (not equal to 3.5%), NO if CPI is 3.5% or below."
- Avoid: "Resolves YES if CPI is high" — "high" is not a legally defensible resolution criterion.

### Resolution Source Permanently Unavailable
- Invoke fallback sources in order, then void if all unavailable within time window.

## Disputed Resolution Process
- **Tier 1 — Automated Verification (0–24 hours)**: re-check the resolution source. If source confirms → resolution stands. Log the verification.
- **Tier 2 — Dispute Bond (24–72 hours)**: user posts bond (5% of position or $50 minimum) to formally dispute. If dispute succeeds: bond returned + resolution corrected + affected users refunded. If fails: bond forfeited to protocol treasury.
- **Tier 3 — Resolution Committee (72 hours–7 days)**: 3–5 independent reviewers who hold NO positions in the disputed market. Majority vote. Decision is final within the platform.
- **Tier 4 — Binding Arbitration**: per TOS. Individual, remote, AAA rules.
- **Dispute filing window**: must be filed within [48 hours / 7 days] of resolution. After that → resolution is final, no disputes accepted.

## UMA Optimistic Oracle Model (Study This)
- Anyone proposes a resolution. If unchallenged within the challenge period → accepted as final.
- If challenged: disputer stakes UMA tokens. Dispute escalated to UMA token holder vote.
- Economic security: cost of corrupting the resolution > profit from wrong resolution
- Most battle-tested decentralized resolution mechanism in production

## Resolver Independence Requirements
- Persons who resolve markets CANNOT hold positions in those markets (or correlated markets)
- Resolution team has an information barrier from trading operations
- Resolution decisions are logged with the specific data point used and the reasoning
- Audit trail: resolution logs kept for 5 years

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
