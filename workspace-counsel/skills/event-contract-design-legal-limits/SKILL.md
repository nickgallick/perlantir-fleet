# SKILL 57: Event Contract Design & Legal Limits

## Purpose
Know what events CAN and CANNOT be the subject of a prediction market. Design markets that stay within CFTC limits, avoid public interest prohibitions, and serve legitimate informational purposes.

## CFTC Event Contract Framework (17 CFR Part 40)

### Prohibited Categories — CFTC Can Block Under CEA §5c(c)(5)(C)
- **Terrorism**: "Will a terrorist attack occur in [location]?" → ALWAYS prohibited. Creates incentive to commit terrorism. Also: criminal material support (18 U.S.C. § 2339A).
- **Assassination**: any market on whether a specific person will be harmed/killed → prohibited and criminal
- **War**: "Will the US invade [country]?" → CFTC authority to block as "contrary to the public interest"
- **Election integrity**: markets that could be used to INFLUENCE elections (buying votes via market positions). Distinguished from markets that PREDICT elections (legal post-Kalshi). Test: does the market incentivize manipulation of the underlying event?
- **CFTC Final Rule on Event Contracts (2024)**: attempted broad codification. Kalshi successfully challenged election contract ban in *Kalshi v. CFTC* (D.D.C. 2024).

### Permitted Categories (Established Precedent)
- **Weather**: temperature, rainfall, hurricane landfall — well-established commodity derivative
- **Economic indicators**: GDP, unemployment rate, CPI, Fed decisions — Kalshi actively offers these on DCM
- **Political elections**: permitted on registered DCMs post-Kalshi ruling
- **Corporate events**: earnings, merger completion, product launches — developing precedent
- **Crypto prices**: already traded as derivatives on CME; event contract form developing
- **AI model performance**: NOVEL — no precedent. This is your whitespace. Strong legality arguments (see below).

### Gray Areas (Legal Opinion Required Before Launch)
- **Celebrity events**: "Will [celebrity] get divorced?" → distasteful, reputational risk, but not clearly prohibited
- **Health/pandemic events**: "Will a pandemic be declared?" → public interest concerns, but informational value
- **Legal outcomes**: "Will [defendant] be convicted?" → could be seen as interfering with judicial process
- **Regulatory outcomes**: "Will SEC approve X?" → meta-regulatory; Polymarket ran these
- **Natural disasters**: "Will an earthquake hit [region]?" → disaster markets raise insurance characterization risk (see SKILL 56)

## The "Public Interest" Test
- CFTC can block contracts "contrary to the public interest" under CEA §5c(c)(5)(C)
- **Key question**: does the market CREATE harmful incentives?
- If someone can profit from a bad outcome AND influence that outcome → contrary to public interest
- **AI prediction accuracy markets**: nobody can INFLUENCE whether an AI model scores correctly on a benchmark. The underlying event is independent of the market. This is the STRONGEST legality argument for your whitespace.
- Document the informational purpose of every market you create.

## Market Design Principles (Legal Risk Minimization)
1. Never create markets on events someone could influence through violence or crime
2. Never create markets on individual people's health, safety, or personal life without consent
3. Prefer measurable, publicly verifiable, objective outcomes
4. Resolution sources must be publicly available and independently verifiable
5. Markets must serve a legitimate informational or hedging purpose
6. Document the informational purpose of every market at creation time

## Market Creation Governance
- **Who creates markets?**: Platform-only (you're responsible for each market's legality) vs. user-created (requires robust review process)
- **Automated screening**: keyword filters for terrorism, assassination, specific individuals' health/safety
- **Human review**: required for gray-area markets before they go live
- **Decision log**: document EVERY market creation decision and the legal reasoning — this is your defense in regulatory proceedings
- **Appeal**: rejected markets can be appealed to a review panel; document the decision

## AI Benchmark Market Specific Analysis
- No one can influence whether GPT-5 scores above a threshold on MMLU
- Resolution source is publicly published (MMLU leaderboard, official paper)
- Informational purpose: price discovery for AI capability expectations
- No public interest concern
- **Classification risk**: could be a security (unlikely — no equity interest), commodity contract (possible), or unregulated skill contest
- **Strongest path**: operate as a non-custodial skill competition platform (CFTC jurisdiction avoided; state skill-game exemption applies)

---
*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*

## AI Benchmark Markets — Full Legal Analysis (Post-Kalshi)

### Why AI Benchmark Markets Are the Strongest Legal Whitespace

**Kalshi v. CFTC (ForecastEx LLC v. CFTC, No. 23-cv-3112, D.D.C. 2024) applied:**

The CFTC argued election contracts were "contrary to the public interest" because:
1. They could incentivize election interference
2. They could be used for money laundering
3. They were "gaming" (gambling)

The court rejected all three arguments. Key holding: the CFTC's "public interest" authority is narrow — it cannot block a contract merely because it's unusual or could theoretically be misused.

**Applied to AI benchmark markets:**
- Argument 1 (incentivize harmful behavior): ❌ Fails. Nobody can influence whether GPT-5 scores above 90% on MMLU. The underlying event is completely independent of market positions.
- Argument 2 (money laundering): ❌ Same risk as any other financial instrument — not specific to AI markets.
- Argument 3 (gaming): ❌ Post-Kalshi, the CFTC cannot block event contracts merely by labeling them "gaming."

**Conclusion**: AI benchmark markets have BETTER legal footing than election markets (which Kalshi won). The CFTC has no coherent "contrary to public interest" argument against markets on publicly-published AI benchmark scores.

### Resolution Source Requirements (Critical for Legal Certainty)
- Must be publicly verifiable: MMLU leaderboard, Epoch AI benchmark database, official model cards
- Must be objective: numeric threshold (GPT-5 > 90% on MMLU) not subjective assessment
- Must be published by independent third party: the AI lab's own claims are insufficient — use independent benchmark organizations
- Must have a clear dispute resolution path: what happens if the benchmark methodology changes?

### Strongest Market Designs for AI Events
✅ "Will GPT-5 score above X% on [public benchmark] by [date]?" — objective, verifiable, third-party source
✅ "Will Claude 4 achieve top-3 ranking on [public leaderboard] by [date]?" — same
✅ "How many MMLU points will the leading model score in Q3 2026?" — range markets work too
❌ "Will OpenAI's next model be 'better' than Google's?" — subjective, no objective resolution source
❌ "Will [AI company] release a model by [date]?" — company announcement = potentially inside information
