# SKILL: Enforcement Defense Playbook
**Version:** 1.0.0 | **Domain:** CFTC Defense, SEC Defense, State AG Defense, Criminal Defense

---

## The Framework: Every Defense Has a Pattern

**Before reading this skill:** Understand that the best enforcement defense is a thick compliance file built BEFORE the enforcement action. Everything below assumes you're in a fight — but the goal is to never be in one.

---

## Defense 1: "We're Not Operating an Exchange or DCM"

**When to use:** CFTC alleges you're operating an unregistered designated contract market under CEA §5(a), 7 U.S.C. § 7

**The legal theory:**
- You provide SOFTWARE TOOLS that let users interact with autonomous smart contracts
- You do NOT match orders, execute trades, or settle transactions
- The smart contract's automated market maker (AMM) or order book operates autonomously
- You have no ability to control, pause, or modify transactions once submitted

**Arguments in order of strength:**

1. **Uniswap Protocol defense:** Uniswap Labs (a company) deployed the Uniswap Protocol (autonomous code). SEC investigated and dropped the case. The distinction is real and the SEC accepted it.
   - *Apply to prediction market:* "Perlantir Labs (the company) deployed the AI Prediction Protocol (autonomous smart contracts). The Protocol operates autonomously. Perlantir Labs provides an interface that allows users to interact with the Protocol."

2. **First Amendment / software-as-speech:** Source code is protected speech under the First Amendment. *Bernstein v. DOJ*, 176 F.3d 1132 (9th Cir. 1999). Publishing software that facilitates user activity is not "operating" the activity.

3. **CEA statutory text:** CEA §5(a) prohibits operating a "facility for the trading of futures contracts." Your smart contracts facilitate user-to-pool trading; there is no "facility" that the company "operates" if the contracts are autonomous and admin-renounced.

4. **Post-Loper Bright:** CFTC's interpretation of "facility" and "operate" under CEA §5(a) gets no deference. The court independently interprets whether a smart contract author is "operating a facility." This is the strongest post-2024 argument.

**Evidence to preserve from Day 1:**
- Documentation that smart contract admin keys are in a multisig (not solely controlled by Nick)
- Any timelock on admin functions (shows users can exit before changes take effect)
- Source code publication and verification on Etherscan/Sourcify (proves openness)
- Documentation that the company earns revenue from INTERFACE services, not from the protocol's trading volume

**Precedent:** SEC dropped Uniswap investigation (2024). CFTC has not prosecuted any protocol whose developer genuinely gave up admin control. CFTC v. Ooki DAO succeeded because identified humans made governance decisions — Ooki DAO was not truly decentralized.

---

## Defense 2: "Our Contest Is Skill-Based, Not Gambling"

**When to use:** Iowa AG or other state AG alleges contest is illegal gambling under state gambling statute

**The legal theory:**
- Skill predominates over chance in determining contest outcomes (predominance test)
- Experienced participants win at statistically higher rates than novices
- Every outcome metric traces to a participant's skill decision

**Arguments in order of strength:**

1. **Statistical evidence (most powerful):** Hire a statistician to analyze your contest results. Demonstrate: (a) top-decile participants win at significantly higher rates than bottom-decile, (b) experienced participants (10+ contests) win at higher rates than new participants, (c) the skill gap compounds over time. This is exactly what DraftKings submitted to defeat NY AG Schneiderman's challenge.

2. **Scoring rubric transparency:** Your rubric was published BEFORE the contest. Participants can study and optimize. The ability to study, practice, and improve = skill. This is how poker was classified as skill in multiple states.

3. **Agent configuration as demonstrated skill:** The participant chose: which AI model (skill: knowledge of model capabilities), which prompt architecture (skill: prompt engineering), which task decomposition strategy (skill: domain knowledge). Each choice is a skill decision with an objectively better and worse option.

4. **Iowa Code §99B.5 explicit authorization:** Iowa law EXPLICITLY authorizes "contests of skill" with entry fees and prizes. The burden is on the AG to prove chance predominates, not on you to prove skill predominates.

5. **DraftKings/FanDuel precedent:** DFS companies established skill-based classification in 40+ states through the same arguments. The legal framework is established; you're applying it to a new domain.

**Evidence to preserve from Day 1:**
- Complete contest result database from first contest forward
- Scoring rubric versions and publication dates
- User outcome data (anonymized for privacy) showing skill progression
- Any academic analysis of your contest format (commission one if challenged)

**Note on Iowa specifically:** Iowa Code §99B.5 is explicit that skill contests are legal. You have home-field legal advantage. An Iowa AG action would be challenging settled Iowa law.

---

## Defense 3: "Our Token Is Not a Security"

**When to use:** SEC sends Wells notice alleging unregistered securities offering under Securities Act §5

**Arguments in order of strength:**

1. **Howey Prong 1 failure — no investment of money:** If the token was distributed via airdrop (no payment required) or usage rewards (earned by platform activity) → users didn't "invest money" in the traditional sense. The SEC has struggled with this argument in pure airdrop cases.

2. **Howey Prong 3 failure — no expectation of profits:** If the team NEVER communicated token price appreciation, market the token ONLY as a governance tool, and never discuss secondary market performance → profit expectation is harder to establish. Audit EVERY communication: tweets, Discord messages, investor presentations.

3. **Howey Prong 4 failure — sufficient decentralization:** If the platform is genuinely decentralized by token launch time → "efforts of others" prong fails. The SEC's Hinman speech (June 14, 2018) established this framework even though Hinman is not binding law post-Loper Bright. The underlying logic is sound.

4. **Ripple programmatic sales defense:** *SEC v. Ripple Labs*, No. 20-cv-10832 (S.D.N.Y. 2023) — Judge Torres: XRP sold on secondary markets to users who didn't know they were buying from Ripple = NOT securities. If your token distribution is similarly "blind" (users receive tokens from a smart contract, not directly from the company) → stronger programmatic sales argument.

5. **Post-Loper Bright challenge to SEC's Howey application:** The SEC's interpretation of Howey's "investment contract" as applied to digital assets gets NO deference. Courts independently assess whether a particular token distribution meets Howey. This creates room to challenge the SEC's aggressive reading.

**What kills this defense:**
- Any team member ever saying in any channel: "Our token will go up in value" or "Early holders will benefit" or "We're going to the moon"
- The company selling tokens for cash (even to a small number of investors) before establishing non-security status
- A secondary market that the company actively promotes and benefits from

---

## Defense 4: "We're Not a Money Transmitter"

**When to use:** FinCEN or state regulator alleges operating an unlicensed money transmitting business under 31 U.S.C. § 5330 or Iowa Code §533C.201

**Arguments in order of strength:**

1. **Non-custodial architecture:** Your platform never "accepts" funds. Users approve a smart contract to pull USDC from their wallet. The smart contract, not the platform, holds funds. FinCEN FIN-2019-G001 (May 9, 2019) defines money transmission as accepting and transmitting value. If you never accept → you don't transmit.

2. **Software provider exemption (Roman Storm defense):** Writing and deploying software is not "operating" a money transmitting business. A developer who writes a non-custodial smart contract is a software author, not a money transmitter. *United States v. Storm* (pending): the outcome of Roman Storm's trial on this exact issue will be the defining precedent.

3. **Agent analogy to licensed entity:** If you've structured as a technology platform serving a licensed partner (Zero Hash, Circle), YOU are their authorized agent. Iowa Code §533C.301(3): agents of licensed transmitters are exempt from Iowa MTL requirements.

4. **Iowa Code §533C.301(7):** "A person that provides clearance or settlement services pursuant to a registration or exemption under federal securities law" — potentially applicable if the smart contract settlement qualifies.

**What kills this defense:**
- Any admin function allowing the platform to withdraw user funds from the smart contract
- Any period where the platform actually held user funds (even briefly)
- Internal communications describing the platform as "holding" or "custodying" funds

---

## Defense 5: "Post-Loper Bright — The Agency's Interpretation Is Wrong"

**When to use:** ANY federal agency enforcement based on aggressive or novel statutory interpretation

**The doctrine:** *Loper Bright Enterprises v. Raimondo*, 603 U.S. ___ (2024) — Courts must independently interpret statutes. Agencies receive NO deference. The court asks: "Is this the BEST reading of the statute?" not "Is this a reasonable reading?"

**Combined with Major Questions Doctrine:** *West Virginia v. EPA*, 597 U.S. 697 (2022) — Agencies cannot claim authority over "questions of vast economic and political significance" without clear congressional authorization.

**Application to CFTC prediction market enforcement:**
- Is the CFTC's interpretation that "AI prediction accuracy contracts" are "swaps" under CEA §1a(18) the BEST reading of the text? Congress defined swaps in 2010, before AI prediction markets existed. Courts must determine whether the statutory text covers this novel category — and the answer is genuinely uncertain.
- The Major Questions angle: regulating all AI-based information markets as commodity swaps is a question of vast economic significance; Congress never specifically authorized this extension.

**This is the highest-value legal argument available in 2025-2026.** Use it in every regulatory challenge, every Wells notice response, every comment letter.

---

## Defense 6: "Advice of Counsel" (Criminal Shield)

**When to use:** ANY criminal prosecution; defeats "willfulness" element required for most white-collar crimes

**Requirements (all must be met):**
1. **Qualified counsel:** Must be an attorney experienced in the relevant area (gaming attorney for gambling charges, CFTC defense attorney for CEA charges, securities attorney for securities fraud)
2. **Complete information provided:** You gave the attorney the complete facts — nothing hidden, nothing minimized. If you gave incomplete facts → advice of counsel doesn't protect you for facts you omitted.
3. **Written opinion:** Oral advice is very difficult to prove in court. The opinion must be in writing, dated, and signed.
4. **Actual reliance:** You actually followed the advice. If you got an opinion saying X is okay and then did Y → no protection.
5. **Pre-conduct timing:** The opinion must have been obtained BEFORE the allegedly illegal conduct, not after the fact.

**Why this is your most important investment:**
- Wire fraud (18 U.S.C. § 1343): "willfully" not in the statute but "scheme to defraud" requires intent → good faith reliance destroys the scheme element
- Operating unlicensed MSB (18 U.S.C. § 1960): "knowingly" required → advice of counsel defeats knowledge element
- CEA violations: "willfully and knowingly" required for criminal charges → advice of counsel is a complete defense

**Build your advice of counsel file before every product launch:**
- Gaming attorney opinion (skill-based classification) → criminal defense for Iowa §99F charges
- AML/BSA attorney opinion (non-custodial exemption) → criminal defense for §1960 charges
- Securities attorney opinion (token is not a security) → criminal defense for securities fraud charges

---

*This is legal research and intelligence, not legal advice. Consult qualified legal counsel before taking action.*
