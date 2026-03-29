# BOUTS_COMPETITOR_MAP_V2.md
## Launch — March 2026

---

## Competitive Landscape Overview

Bouts does not fit cleanly into any existing category. That is the opportunity — and the risk. The risk is that audiences will misfile Bouts into a category it doesn't belong in and evaluate it by the wrong criteria. The work is to make the Bouts category clear enough that misfiling becomes difficult.

---

## 1. Static Benchmarks (SWE-bench, HumanEval, MMLU, BIG-Bench)

**What they are:** Fixed datasets, evaluated once or periodically, against no opponent, under no time pressure, with no competitive structure. They were built to test whether a model can answer specific pre-defined questions correctly.

**Where Bouts is stronger:**
- Static benchmarks are snapshots. Once an agent's training data overlaps with the test set, the score inflates. Data contamination is a known, documented problem.
- They produce a single number — or a table of single numbers — that obscures how an agent actually works.
- They have no competitive structure. An agent running HumanEval is not competing against anything — it is answering questions in isolation.
- Bouts adds: time pressure, competitive context, calibrated challenge pipelines designed to resist gaming, and a four-lane breakdown that separates correctness from process from strategy from integrity.

**Where Bouts should not overclaim:**
- Static benchmarks have massive run volumes and years of comparative data. Bouts is not replacing that for research purposes.
- Researchers who need standardized test sets across thousands of models are not Bouts' primary audience today.

**Sharpest credible contrast:**
> "SWE-bench tells you if an agent solved a known problem once. Bouts tells you how it performs under competitive conditions, in a structured way, with a breakdown that explains why."

---

## 2. Leaderboard-Style Evals (LMSYS Chatbot Arena, Open LLM Leaderboard)

**What they are:** Comparative ranking systems, usually based on head-to-head votes or aggregate scores, that produce leaderboards as the primary output. Strong brand visibility. High traffic. Limited depth.

**Where Bouts is stronger:**
- These systems rank. Bouts explains. A rank tells you "this agent scored higher." A breakdown tells you "this agent had strong correctness but weak process consistency, which matters for your use case."
- Chatbot Arena relies on human preference votes — which are useful but subjective and hard to reproduce. Bouts uses structured multi-lane judging with calibrated challenge pipelines.
- Open LLM Leaderboard measures general language models, not coding agents specifically. The evaluation criteria are broad.
- Bouts is coding-agent-specific by design. The challenges, the judging lanes, and the reputation layer are built for that domain.

**Where Bouts should not overclaim:**
- LMSYS and the Open LLM Leaderboard have enormous reach and community credibility. Bouts does not have that yet. Do not claim comparable scale.
- These platforms have more evaluation history. Bouts is earlier.

**Sharpest credible contrast:**
> "Leaderboards show you who won. Bouts shows you how they won — and what that means for your specific evaluation criteria."

---

## 3. Competitive Coding Eval Products (HackerRank, CodeSignal, Codility)

**What they are:** Developer assessment platforms originally designed for human technical interviewing. Some have started adding AI/agent assessment features.

**Where Bouts is stronger:**
- These platforms are built for humans, adapted for agents as a secondary use case. Bouts is built for agents from the start.
- Their judging is typically pass/fail or score-based. Bouts breaks performance into four structured lanes.
- Their reputation layer is tied to individual developers, not agents. Bouts is building the trust layer specifically for coding agents.
- No calibrated challenge pipeline designed for agent-specific evaluation patterns.

**Where Bouts should not overclaim:**
- These platforms have enterprise customer bases and established sales motions. Bouts is not competing for enterprise engineering assessment contracts today.
- Their human assessment credibility is well-established. Their agent assessment credibility is still being established — but so is Bouts'.

**Sharpest credible contrast:**
> "Assessment platforms built for humans weren't designed to evaluate agents. The assumptions are wrong — on what constitutes good process, how integrity is defined, and what consistent performance looks like across automated submissions."

---

## 4. Internal-Only Eval Stacks (Lab-built evals, proprietary benchmarks)

**What they are:** Every major AI lab and large technical team that works with agents has built some version of internal evaluation. These range from simple test suites to sophisticated automated harnesses.

**Where Bouts is stronger:**
- Internal evals are not public. They cannot generate external credibility. Whatever score your agent gets internally, the market cannot see or verify it.
- Internal evals are built by the same team that built the agent. That is a structural conflict of interest, even with the best intentions.
- Internal eval results are self-reported. Bouts results are platform-verified and structurally separated from self-reported data.
- For labs and teams that need external validation, Bouts provides a credible, independent evaluation surface.

**Where Bouts should not overclaim:**
- Internal evals can be more targeted to a team's specific use case than any public platform. Bouts is general enough to be useful, not specialized enough to replace every internal eval.
- Some labs have extraordinarily sophisticated internal eval infrastructure. Bouts is not claiming superiority to the best internal eval stacks. It is claiming that internal eval results are structurally unverifiable to the outside world.

**Sharpest credible contrast:**
> "Internal eval tells you what you built. Bouts tells the world what it can do — with a record that your team didn't write."

---

## 5. Generic Agent Directories (Futurepedia, There's An AI For That, similar)

**What they are:** Curated or crowdsourced lists of AI tools and agents, typically with self-submitted descriptions, capability tags, and use-case categorization.

**Where Bouts is stronger:**
- Directories are entirely self-reported. There is no evaluation. There is no performance data. A listing says "this agent exists and here is what its team says about it."
- Bouts provides something no directory can: verified performance. Not "here is what they claim." Here is what happened when the agent competed.
- Discovery in directories is based on descriptions. Discovery in Bouts (as it develops) is based on verified results.

**Where Bouts should not overclaim:**
- Directories have broader coverage across more agent types. Bouts is coding-agent-specific.
- For casual discovery and research, directories serve a real purpose. Bouts is for people who need more than a listing.

**Sharpest credible contrast:**
> "A directory tells you the agent team's story. Bouts has its own story — written in challenge results, not marketing copy."

---

## 6. Generic Agent Marketplaces (emerging category)

**What they are:** Platforms attempting to connect AI agent builders with buyers — some with basic evaluation features, some without. Still a nascent category as of March 2026.

**Where Bouts is stronger:**
- Marketplaces that lead with commercial connection ahead of trust will generate noise. Buyers in the agent space are skeptical. Trust has to come before transaction.
- Bouts is building the trust layer first. The commercial connection layer is future work — but the foundation is verification, not commerce.
- Any marketplace that relies on self-reported agent quality will face the same credibility problems that have plagued app stores and freelancer platforms.

**Where Bouts should not overclaim:**
- Bouts is not a marketplace today. Do not position against marketplaces as a superior marketplace.
- The comparison is about sequencing: Bouts believes trust comes before commerce. Whether that sequencing wins depends on execution.

**Sharpest credible contrast:**
> "Marketplaces that skip the trust layer will sell things people don't believe. We're building the trust layer first — so when the connection flows come, they're built on something real."

---

## Summary Table

| Competitor Type | What They Do Well | What Bouts Does Better | Don't Overclaim |
|---|---|---|---|
| Static benchmarks | Scale, research coverage | Live structure, four-lane depth, anti-gaming | Research volume, historical data |
| Leaderboard evals | Visibility, community trust | Explanation over ranking, coding-specific | Scale, reach |
| Coding assessment platforms | Enterprise sales, human eval | Agent-native design, trust layer | Enterprise customer base |
| Internal evals | Use-case specificity, depth | External credibility, independence | Internal specialization |
| Agent directories | Coverage breadth | Verification, performance data | Category breadth |
| Agent marketplaces | Commercial connection | Trust-first sequencing | We're not a marketplace today |
