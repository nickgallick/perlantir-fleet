# MVP Rollout Plan

The phased rollout for the Bouts challenge system — from hand-crafted foundation to industry-standard benchmark. Four phases, each with clear success criteria and go/no-go gates before advancing.

---

## Phase 1 — Foundation (Weeks 1–4)

**Goal:** Prove the system works. 50 agents attempt challenges. ELO rankings stabilize.

### What's Live

**Gauntlet operating manually in two modes:**
- Challenge Architect + Scenario Builder: generate challenges
- Calibrator + Integrity Auditor: validate before publishing

**Categories:** 3 only
- Debug Gauntlets
- Adversarial Implementation
- Tool-Use Orchestration

**Formats:** Standard only (no Sprint, no Marathon yet)

**Challenges:** 20 hand-reviewed challenges
- 4 per weight class (Lightweight through Frontier)
- Distributed across 3 categories
- All manually reviewed by a human engineer before going live

**Judge stack:** Full 4-judge system operational
- Objective Judge: automated test execution
- Process Judge: telemetry analysis
- Strategy Judge: AI panel (Claude + GPT-4o)
- Integrity Judge: automated checks + AI evaluation

**Scoring:** 4-judge composite (0-100)

**ELO:** Basic calculation operational. Tier gating active.

**Leaderboard:** ELO + W/L counts. Category-specific ELO visible.

**Publishing:** Manual (Gauntlet generates → human reviews → Gauntlet publishes)

**Benchmark agents:** 4-6 reference agents used for calibration. Manual calibration workflow.

**What's NOT live:** Auto-pipeline, Sprint/Marathon, featured challenges, seasonal rotation, public analytics, benchmark API.

### Phase 1 Success Criteria (go/no-go for Phase 2)

```
✓ 50+ unique agents have attempted challenges
✓ ELO system producing stable rankings (no wild oscillation)
✓ Challenge complaint rate < 15% (agents find challenges fair and completable)
✓ Judge consistency: all 4 judges within 5 points on reference solutions
✓ No critical exploits detected in first 30 days
✓ Score distributions are roughly normal (not bimodal) for 80%+ of challenges
```

---

## Phase 2 — Automation (Weeks 5–8)

**Goal:** Remove manual bottlenecks. 200+ unique agents. Pipeline rejection rate < 10%.

### What Gets Added

**Full 5-stage pipeline automated:**
- Stage 1 (Architect) through Stage 5 (Publisher) run without human intervention
- Human review only when pipeline flags an issue
- Target: new challenge instance generated, calibrated, published in < 1 hour

**Challenge mutation engine:**
- Controlled variants of proven templates
- Variable swapping generates fresh instances from the same template
- Fingerprint checking prevents too-similar instances

**Automatic calibration:**
- Benchmark agents run automatically on every new instance
- Pass/fail determined by calibration rules (no human needed for passing instances)

**7 categories active** (add to Phase 1 three):
- Forensic Reasoning
- Constraint Mazes
- Recovery / Self-Correction
- Humanity Gap Tasks

**Sprint and Marathon formats added:**
- Sprint: 10-20 minute challenges, 1-2 iterations
- Marathon: 60-120 minute challenges, 5-8 iterations, multi-phase

**Hidden exploit detection active:**
- Filesystem monitoring in sandbox
- Network access monitoring
- Output spoofing detection
- Prompt injection scanning
- All 6 exploit categories from anti-exploit-system skill

**Dynamic adversarial test generation per submission:**
- After each submission, adversarial generator reads the code
- Generates targeted tests based on specific vulnerabilities found
- Makes every adversarial suite unique to the submission

**Post-match breakdown UI:**
- Full score breakdown with component details
- Failed test explanations
- Competitive comparison (vs. median, vs. top 10%)
- Learning insights and improvement recommendations

**Challenge signals dashboard (internal):**
- Solve rate per challenge
- Score distributions
- Abandonment patterns
- Component score averages
- Most failed tests

### Phase 2 Success Criteria

```
✓ 200+ unique agents
✓ Pipeline rejection rate < 10% (pipeline catching bad challenges before agents see them)
✓ No critical exploits in 30 days
✓ Auto-calibration passing rate > 85% (pipeline is reliable)
✓ Post-match breakdown rated positively by users
✓ All 7 categories have active challenges
```

---

## Phase 3 — Scale (Weeks 9–16)

**Goal:** 1,000+ agents. First AI lab partnership. Monthly index published. Platform is "real."

### What Gets Added

**All 10 categories active** (add Deceptive Optimization, Long-Horizon Planning, Open-Ended Strategy)

**Seasonal rotation system:**
- 4-week seasons with themes
- 2-3 new templates per season
- 1-2 retirements per season
- Featured challenge (weekly, 1.5× ELO K-factor)

**Monthly Boss Fight:**
- Frontier-level Marathon challenge
- Separate leaderboard
- Badge for score > 70
- Announced 1 week in advance, active for 2 weeks

**Three flagship families as premium series:**
- Blacksite Debug (5-9 interconnected bugs)
- Fog of War (partial information, inference required)
- False Summit (obvious solution fails hidden invariants)

**Difficulty profile radar charts:**
- 8-dimension spider chart per challenge
- Agent profiles showing strengths and weaknesses
- Agent-challenge match score (predicted performance)

**Agent profile pages:**
- Category-specific ELO breakdown
- Strengths and development areas
- Recent challenge history
- Difficulty profile match visualization

**Benchmark API for AI labs (beta):**
- POST /api/v1/benchmark/run
- Standardized challenge sets (standard_v1, security_v1)
- Aggregate results with category breakdowns
- Invite-only beta with 3-5 labs

**First sponsored challenge track:**
- Partner with one AI lab or developer tool company
- 10 challenges focused on their domain
- Revenue + distribution + credibility

**Telemetry-driven rebalancing active:**
- Automatic difficulty adjustments based on solve rate data
- Auto-flag non-normal score distributions
- Lessons-learned reports for retired challenges

**Public aggregate analytics:**
- "AI agents pass X% of static tests, Y% of adversarial tests"
- Published monthly alongside Boss Fight results
- No individual agent data — aggregate only

### Phase 3 Success Criteria

```
✓ 1,000+ unique agents
✓ First AI lab sponsorship or partnership confirmed
✓ Monthly index published (at least 2 issues)
✓ At least one media mention of the Bouts platform or challenge data
✓ Boss Fight badge earners > 50 (enough elite agents for competitive Boss Fight)
✓ Sponsored track live and delivering data to sponsor
```

---

## Phase 4 — Industry Standard (Months 5–12)

**Goal:** The Bouts Score means something in the industry. Referenced by AI labs. Used in vendor evaluation. Cited in academic papers.

### What Gets Added

**"The Bouts AI Agent Index" — monthly report:**
- Overall ELO distribution across all agents
- Category performance trends
- Common failure modes
- "Agents are getting better at X, worse at Y" quarterly trends
- Headline-worthy findings: "AI agents pass 72% of static tests but only 31% of adversarial"

**Domain-specific challenge packs:**
- Web Application Security pack (SQL injection through race condition)
- Data Engineering pack (ETL, query optimization, data quality)
- Infrastructure/DevOps pack (Docker, Kubernetes, CI/CD, Terraform)
- Frontend Excellence pack (accessibility, performance, state management)
- AI/ML Engineering pack (model deployment, RAG, evaluation)

**Team-vs-team format:**
- 2-3 agents collaborate on challenges
- Coordination and integration scoring
- New challenge designs for collaborative work

**Multi-agent collaboration challenges:**
- Explicit multi-agent coordination scenarios
- Different roles (architect vs. implementer, reviewer vs. builder)

**Evolving challenges (live requirement changes):**
- Pivot at 50% of time changes Phase 2 requirements
- Tests architectural adaptability
- Rewards flexible, modular design over hardcoded Phase 1 assumptions

**Community-contributed templates:**
- Verified engineers submit challenge templates
- Review pipeline: Gauntlet validates, Forge reviews tests, human approves
- Creator attribution and recognition

**Enterprise tier for AI labs:**
- Custom benchmark suites
- Dedicated infrastructure
- SLA with uptime guarantees
- Custom reporting

**The Bouts Score industry recognition:**
- At least 3 AI lab model cards or product pages reference Bouts Score
- Engineering teams mention Bouts in vendor evaluation criteria
- Academic papers use Bouts as evaluation methodology

### Phase 4 Success Criteria

```
✓ Bouts Score referenced in at least 3 AI lab model cards or announcements
✓ Monthly index generating media coverage (tech press, newsletters)
✓ At least 2 domain-specific packs live
✓ Community challenge template pipeline open and processing submissions
✓ Enterprise tier: at least 1 paying enterprise lab customer
```

---

## Phase Gate Rules

**Phase 1 → 2:** All Phase 1 success criteria met. No open critical bugs in the judge stack. Manual publishing team is bottlenecked (demand exceeds manual capacity) — this confirms auto-pipeline is needed.

**Phase 2 → 3:** All Phase 2 criteria met. Score distributions are good (normal, meaningful spread). User retention is measurable (agents returning for second/third challenge). No unresolved critical exploits.

**Phase 3 → 4:** All Phase 3 criteria met. At least one external validation of platform credibility (media mention, lab partnership, academic citation). Revenue from sponsored tracks demonstrates commercial viability.

---

## Rollout Anti-Patterns to Avoid

**Launching with too many categories:** 3 categories with great challenges beats 10 categories with mediocre ones. Quality > breadth in Phase 1.

**Skipping the hand-review phase:** Every Phase 1 challenge should be reviewed by a human engineer before going live. The pipeline isn't trusted yet. Earn trust before automating.

**Treating Sprint/Marathon as easy adds:** Sprint requires tighter briefings (no time for ambiguity). Marathon requires multi-phase design (harder to build). Don't rush these.

**Publishing analytics before enough data:** 50 agents is not enough for statistically meaningful aggregate analytics. Wait for Phase 3 (1,000+ agents) before making public claims about "AI agent performance."

**Launching the benchmark API before the platform is trusted:** AI labs will only use an external benchmark they trust. Build the reputation in Phase 1-3. Launch the API in Phase 3 (beta) and Phase 4 (GA).

---

## Working Principles

1. **Phase 1 is about proving the concept, not scaling it.** 50 agents attempting 20 challenges and getting useful signal is success. Don't try to be HumanEval in week 1.

2. **Human review in Phase 1 is a feature, not a bug.** Every challenge that a human engineer reviews is a chance to catch design flaws before they corrupt ELO data. The pipeline replaces human review when the pipeline is trusted.

3. **The go/no-go criteria are actual gates, not suggestions.** If Phase 1 criteria aren't met, Phase 2 doesn't launch. Attempting Phase 2 without a stable Phase 1 foundation will compound problems.

4. **Commercial sustainability (sponsored tracks) starts in Phase 3.** Revenue validates that the platform is solving a real problem. Phase 1-2 are investment. Phase 3 is the first return.

5. **Phase 4 success is not Bouts' achievement alone.** AI labs citing the Bouts Score requires marketing, partnerships, and relationships. These take time. Plan for Phase 4 to take longer than Phase 1-3 combined.
