# Anti-Contamination Checklist
## The Hard Defensive System for Challenge Validity

---

## 1. Purpose

Anti-contamination is the system that protects challenge validity by preventing:

- Public benchmark leakage
- Repo memorization
- Synthetic pattern reuse
- Family-template recognition
- Exploit playbook standardization
- Same-model convergence from prior exposure
- Scoreboard inflation from contaminated challenge pools

### Governing Principle

> **A challenge is only valid if it measures engineering ability, not prior exposure or benchmark familiarity.**

A contaminated challenge is worse than no challenge. It actively degrades the platform: scores become meaningless, rankings become noise, and trust collapses. Contamination defense is not hygiene — it is the competitive moat that makes Bouts credible.

### Two Standards

> **No challenge ships unless it is fresh enough to test real capability.**
> **No challenge stays live once it becomes a playbook.**

---

## 2. Contamination Threat Model

### External Contamination

| Source | Risk Level | Example |
|--------|-----------|---------|
| Public GitHub repos | 🔴 Critical | Challenge codebase resembles a real open-source project |
| Known benchmark datasets | 🔴 Critical | Task structure overlaps with SWE-bench, HumanEval, MBPP |
| Blog/tutorial overlap | 🟠 High | Bug pattern is a common "how to fix X" tutorial topic |
| Copied CTF/problem formats | 🟠 High | Challenge structure matches a known CTF format |
| Public prompts / leaked text | 🔴 Critical | Challenge briefing or hidden invariant appears in public |
| Reused visible test suites | 🟡 Medium | Test patterns are generic enough to match public test templates |
| Public exploit writeups | 🟠 High | The exploit temptation is a known documented attack pattern |

### Internal Contamination

| Source | Risk Level | Example |
|--------|-----------|---------|
| Shallow sibling mutations | 🟠 High | 5 siblings that all have "a race condition in a payment service" |
| Repeated family structure | 🟠 High | Every Blacksite Debug starts with "check the production logs" |
| Same deception pattern | 🟡 Medium | Redis red herring used in 3 of last 5 Fog of War instances |
| Recycled hidden invariants | 🟠 High | "Missing input validation" as hidden invariant in 4 of last 10 challenges |
| Repeated recovery branch logic | 🟡 Medium | "Obvious fix that breaks something else" pattern overused |
| Repeated "signature trick" | 🟠 High | Every False Summit uses "all tests pass but security scan fails" |
| Overexposed flagship families | 🟡 Medium | Blacksite Debug has had 20 instances — the meta-pattern is known |

### Competitive Contamination

| Source | Risk Level | Example |
|--------|-----------|---------|
| Elite playbook convergence | 🟠 High | Top 10 agents all use the same investigation sequence |
| Same-model shortcut learning | 🟠 High | All Claude agents find the bug in the same file first |
| Post-match breakdown leakage | 🟡 Medium | Breakdowns reveal enough about hidden invariants to prep future agents |
| Challenge card signaling | 🟡 Medium | "Fog of War: Heavyweight" tells agents to expect distributed clues and misdirection |
| Recognizable integrity traps | 🟡 Medium | Agents learn that "every challenge has a test file you shouldn't read" |

---

## 3. Checklist Structure

This checklist is a **required gate in Stage 4B** of the generation pipeline. Every challenge must pass ALL four layers. Failure on any layer blocks publication.

### Layer A — External Similarity Screening

**Purpose:** Ensure the challenge doesn't resemble anything publicly available.

| # | Check | Method | Pass | Fail |
|---|-------|--------|------|------|
| A1 | **Phrase uniqueness** | Search Google for 3-5 distinctive phrases from the briefing (quoted) | Zero exact matches | Any exact match |
| A2 | **Repo/code similarity** | Search GitHub for function names, class names, and code patterns from the codebase | No repos with >50% structural similarity | Any repo with >50% match |
| A3 | **Public benchmark overlap** | Compare task structure against SWE-bench, HumanEval, MBPP, LiveCodeBench, CodeContests task databases | No structural match | Task core matches a known benchmark task |
| A4 | **Known exploit pattern overlap** | Compare exploit temptations against OWASP, CTF writeups, known vulnerability databases | Exploit temptation is original or significantly mutated | Exploit is a well-documented pattern with public solutions |
| A5 | **Visible-test similarity** | Compare visible test structure against common testing patterns and public test suites | Tests are specific to this challenge, not generic | Tests are recognizable as a common pattern (e.g., standard CRUD test template) |
| A6 | **Briefing similarity** | Compare briefing against known challenge formats (CTF, competitive programming, other benchmarks) | Briefing feels unique | Briefing structure matches a known format |
| A7 | **Frontier model probe** | Submit briefing to a frontier model: "Have you seen a challenge like this before? Describe the solution approach." | Model cannot describe a specific solution | Model describes a specific solution path with confidence |

### Layer B — Internal Lineage Screening

**Purpose:** Ensure the challenge is sufficiently different from its siblings and predecessors.

| # | Check | Method | Pass | Fail |
|---|-------|--------|------|------|
| B1 | **Sibling distance** | Compute similarity fingerprint against all active siblings from same template | < 0.65 for Fog of War/False Summit; < 0.70 for others | Above threshold |
| B2 | **Family mutation depth** | Check how many generations deep from original template | ≤ 10 generations | > 10 (template exhaustion) |
| B3 | **Invariant reuse** | Compare hidden invariant types against last 10 challenges in same family | No identical invariant type in last 3 instances | Same invariant type as most recent sibling |
| B4 | **Deception reuse** | Compare red herring types and misdirection patterns against last 10 instances | No identical deception pattern in last 3 instances | Same red herring type as most recent sibling |
| B5 | **Recovery-branch reuse** | Compare trap types and recovery paths against recent instances | No identical trap type in last 3 instances | Same trap sequence as a recent sibling |
| B6 | **Scoring-hook reuse** | Compare per-judge evidence design against recent instances | Hooks test different specific behaviors | Hooks are copy-paste from sibling |
| B7 | **Anti-shortcut pattern reuse** | Compare dynamic adversarial test approach | Different anti-shortcut mechanism from last 3 instances | Same mechanism reused |
| B8 | **Domain reuse** | Check domain against last 5 instances in same family | Different domain from last 2 instances | Same domain as most recent sibling |

### Layer C — Agent-Behavior Contamination Screening

**Purpose:** Ensure calibration data doesn't suggest agents are solving by recognition rather than reasoning.

| # | Check | Method | Pass | Fail |
|---|-------|--------|------|------|
| C1 | **Naive ceiling breach** | Naive agent score from Stage 3 calibration | ≤ 25 (or family-adjusted ceiling) | > 30 — suggests the answer is "known" |
| C2 | **Elite convergence** | Compare Strong and Elite investigation PATHS (not just scores) from calibration | Different investigation strategies | Identical investigation sequence |
| C3 | **Same-model clustering** | Compare same-model tier deltas from calibration | Per same-model separation policy | Deltas below thresholds |
| C4 | **Exploit-seeker pattern match** | Review Exploit Seeker's approach — did it solve via prior pattern recognition? | Exploit Seeker's legitimate work matches expected effort level | Exploit Seeker solved suspiciously fast via non-exploit means |
| C5 | **Speedrunner reasoning bypass** | Did Speedrunner reach a correct solution without the intended reasoning path? | Speedrunner score < 50, missed hidden invariants | Speedrunner score > 50 — challenge has a shortcut |
| C6 | **Process variance** | Compare telemetry patterns across all calibration runs | ≥ 3 distinct investigation patterns observed | All agents follow the same investigation path |

### Layer D — Publication Leakage Screening

**Purpose:** Ensure the public-facing information doesn't leak challenge mechanisms.

| # | Check | Method | Pass | Fail |
|---|-------|--------|------|------|
| D1 | **Challenge card review** | Review the public API JSON (Skill 89) for mechanism leakage | Card sells the fantasy, not the mechanism | Card reveals hidden invariant family, exploit structure, or deception pattern |
| D2 | **Post-match template review** | Review the post-match breakdown template for over-disclosure | Breakdown reveals categories, not specifics | Breakdown reveals exact hidden invariants, exact test logic, or exact trap triggers |
| D3 | **Leaderboard decomposition** | Review what sub-rating breakdown reveals about challenge structure | Sub-ratings show agent quality, not challenge mechanics | Sub-ratings pattern reveals which family trick is being tested |
| D4 | **Naming language check** | Review challenge title, family label, and metadata for template exposure | Names are evocative, not descriptive | Name reveals the mechanism ("The Race Condition in Payments" → exposes the bug type) |
| D5 | **Cumulative family disclosure** | Review what repeated challenges from the same family have revealed in aggregate | Each instance's public information is independent | Cumulative public information allows inferring family structure |

---

## 4. Required Pre-Publication Checks

### Text / Prompt Checks

| Check | Target | Search Method |
|-------|--------|--------------|
| Distinctive briefing phrases | Google, Bing | 3-5 quoted phrases, 4+ word sequences |
| Title / family wording | Google, GitHub | Exact title + "challenge" / "benchmark" / "eval" |
| Task-core wording | Google, GitHub | Core problem description as a quoted phrase |
| Hidden invariant phrasing | Google, Stack Overflow | Key phrases describing the hidden requirement |
| Narrative wrapper phrases | Google | Hook text, stakes description |

**Pass:** Zero exact matches on any phrase. Low-similarity partial matches acceptable if the underlying problem is substantially different.

### Code / Asset Checks

| Check | Target | Search Method |
|-------|--------|--------------|
| Function/class names | GitHub code search | Exact names from key files |
| File layout pattern | GitHub repository search | Directory structure comparison |
| Visible test structure | GitHub code search | Test names, assertion patterns |
| Log/doc format | Google, GitHub | Distinctive log patterns or doc formats |
| Error message fingerprints | Google, Stack Overflow | Exact error messages from the codebase |
| Exploit bait design | OWASP, CTF databases | Compare bait pattern against known exploits |

**Pass:** No public repo with > 50% structural similarity. No identical function/class names in a debugging/benchmark context.

### Family Checks

| Check | Target | Method |
|-------|--------|--------|
| Prior sibling comparison | Last 10 active challenges in family | Similarity fingerprint < family threshold |
| Retired family archive | All retired challenges in family | No identical invariant/deception/recovery pattern |
| Signature trick detection | All instances in family | No single trick used in > 30% of instances |
| Deception rhythm detection | Last 5 instances in family | No identical misdirection sequence |

**Pass:** All family checks clear. Signature trick usage < 30%. No identical patterns in last 3 instances.

### Calibration Checks

| Check | Threshold | Source |
|-------|-----------|--------|
| Naive > expected ceiling | Naive ≤ 25 (or family-adjusted) | Stage 3 calibration |
| Exploit Seeker effective too early | Exploit Seeker legitimate score < 40 | Stage 3 calibration |
| Same-model spread collapse | Per same-model separation policy | Stage 3 calibration |
| Elite solving via pattern | Elite investigation path differs from Speedrunner path | Stage 3 telemetry comparison |
| Process telemetry too uniform | ≥ 3 distinct investigation patterns across calibration | Stage 3 telemetry analysis |

**Pass:** All calibration checks clear.

---

## 5. Freshness Scoring

The Freshness Score (0-100) quantifies how contamination-resistant a challenge is at the time of evaluation.

### Formula

```
Freshness = (
  external_uniqueness × 0.25 +
  lineage_distance × 0.20 +
  family_novelty × 0.15 +
  hidden_invariant_novelty × 0.15 +
  exploit_novelty × 0.10 +
  telemetry_novelty × 0.10 +
  spectator_novelty × 0.05
)
```

### Component Definitions

| Component | Weight | Measurement | Score 100 | Score 0 |
|-----------|--------|-------------|-----------|---------|
| **External uniqueness** | 25% | Inverse of closest public match similarity | No public matches found | Exact public match found |
| **Lineage distance** | 20% | Mutation depth × mutation breadth from parent | Fresh template, no parent | 10th generation, narrow mutations |
| **Family novelty** | 15% | How different from last 5 family instances | Different domain + framework + topology | Same domain + framework + topology |
| **Hidden invariant novelty** | 15% | How different from recently used invariants | Novel invariant type not used in last 10 challenges | Identical to most recent sibling |
| **Exploit novelty** | 10% | How different from recent exploit temptations | Novel temptation type | Same temptation as most recent sibling |
| **Telemetry novelty** | 10% | How different the expected telemetry patterns are | Novel branching points, new process variation sources | Same telemetry pattern as siblings |
| **Spectator novelty** | 5% | How different the reveal/tension/narrative feels | Novel reveal structure | Same narrative arc as recent instances |

### Thresholds

| Score | Status | Action |
|-------|--------|--------|
| **> 80** | 🟢 Clean | Publish normally |
| **70-80** | 🟡 Publishable | Publish with freshness monitoring — track decay |
| **55-69** | 🟠 Revise | Do not publish — apply deeper mutations or change approach |
| **< 55** | 🔴 Reject | Do not publish — rebuild from scratch or retire template |

### Freshness Decay

Freshness scores decay over time as a challenge remains active:

| Factor | Decay Rate |
|--------|-----------|
| Age (weeks active) | −2 per week |
| Attempt volume | −1 per 50 attempts |
| Public discussion detection | −10 per detected discussion |
| Playbook emergence (from monitoring) | −15 per confirmed playbook |
| Model update (new frontier model released) | −5 (potential training data exposure) |

Recalculate freshness weekly. If score drops below 70 → schedule mutation/retirement.

---

## 6. Sibling Distance Policy

### Minimum Sibling Distance

A sibling is a new challenge instance generated from the same template via mutation. Not all mutations create meaningful distance.

### Cosmetic-Only Mutations (DO NOT count toward sibling distance)

These changes alone are **insufficient** to publish a new sibling:

| Change | Why Insufficient |
|--------|-----------------|
| Variable/function/class renaming | Search-and-replace doesn't change what's being tested |
| File path changes | Moving files doesn't change the engineering challenge |
| Narrative wrapper swap (different story, same mechanics) | Agents solve mechanics, not stories |
| Color/styling/formatting changes | No impact on any judge lane |
| One bug location moved (same bug type, same module) | Trivially recognizable as the same bug |
| One visible test added/removed | Visible tests don't drive discrimination |
| Comment changes | No impact on scoring |

### Meaningful Mutations (DO count toward sibling distance)

These changes create genuine freshness:

| Change | Why Meaningful |
|--------|---------------|
| Hidden invariant structure changed | Different thing to discover → different discrimination fork |
| Deception pattern changed | Different misdirection → different time-waste pattern |
| Recovery path changed | Different trap → different recovery telemetry |
| Failure archetype target changed | Tests different failure mode → different agent behavior |
| Exploit temptation changed | Different integrity test → different Integrity Judge signal |
| Tool-verification burden changed | Different tool unreliability → different diagnostic path |
| Hypothesis structure changed | Different evidence distribution → different forensic path |
| Framework/database swapped | Different idioms → tests real skill vs framework memorization |
| Domain swapped | Different context → different domain-specific reasoning |
| Interconnection topology changed | Different cascade pattern → different systematic debugging |

### Minimum Requirements

- A sibling must apply **≥ 3 meaningful mutations** from the list above
- A sibling must have a similarity fingerprint **< family threshold** (0.65-0.70) against all active siblings
- A sibling must change at least **1 of the top-3 discrimination mechanisms** (the elements identified in the Discriminator Intent as creating the primary score forks)

### Forbidden Sibling Overlap

No two active siblings from the same template may share:
- The same domain AND framework combination
- More than 1 bug type (for debug families)
- The same red herring type
- The same hidden invariant type
- The same recovery branch trap type

---

## 7. Family Anti-Collapse Rules (Contamination Perspective)

### Blacksite Debug

| Aspect | Rule |
|--------|------|
| **Recognizable tells** | "Multi-bug financial service with interconnected failures and misleading logs" |
| **Common contamination vectors** | Race condition in payment processing (extremely common in training data); TODO comments near bugs; cascade always runs A→B→C |
| **Forbidden reuse** | Same domain in consecutive instances; same bug type in last 3 instances; same interconnection topology in last 3 |
| **Rotation requirement** | Domain rotates every instance; bug types rotate every 2 instances; interconnection topology rotates every 3 |
| **Refresh trigger** | If Speedrunner scores > 40 on 3 consecutive instances |
| **Sub-template retirement** | After 10 generations or 3 consecutive CDI < B |

### Fog of War

| Aspect | Rule |
|--------|------|
| **Recognizable tells** | "The deployment diff contains the answer, and the on-call engineer is wrong" |
| **Common contamination vectors** | Critical clue in deployment diff (too easy to grep); ORM behavioral change (common training data); Redis red herring (overused) |
| **Forbidden reuse** | Same root cause category in last 3 instances; same correlation trap type in last 3; same unreliable witness type in last 3; critical clue discoverable from single file search |
| **Rotation requirement** | Root cause category every instance; correlation trap every 2; evidence format diversity every 3 |
| **Refresh trigger** | If > 80% of agents find the primary clue within 2 minutes on 3 consecutive instances |
| **Sub-template retirement** | After 8 generations (stricter — Fog of War is more pattern-sensitive) or 3 consecutive CDI < B |

### False Summit

| Aspect | Rule |
|--------|------|
| **Recognizable tells** | "Tests pass but there are hidden invariants — keep testing after green" |
| **Common contamination vectors** | "Always write adversarial tests after green" becomes meta-strategy; security scan as hidden invariant (overused); "keep going" as universal strategy |
| **Forbidden reuse** | Same hidden invariant type in last 3; same summit type in last 3 |
| **Rotation requirement** | Hidden invariant type every instance; summit type every 2; include "correct codebase" instances (10-15%) to prevent "always keep going" |
| **Refresh trigger** | If Brute Forcer scores > 60 on 3 consecutive instances (generic adversarial testing too effective) |
| **Sub-template retirement** | After 10 generations or if "always keep going" becomes > 80% effective |

### Recovery Spiral

| Aspect | Rule |
|--------|------|
| **Recognizable tells** | "You will fail first — the test is how you recover" |
| **Common contamination vectors** | "Always revert and retry" becomes meta-strategy; same trap type reused; same recovery tool pattern |
| **Forbidden reuse** | Same trap type sequence in last 3; same phase shift content in last 3 |
| **Rotation requirement** | Trap types every instance; cascade structure every 2; recovery tools every 3 |
| **Refresh trigger** | If > 50% of agents avoid trap 1 entirely on 3 consecutive instances |
| **Sub-template retirement** | After 10 generations or if trajectory convergence persists across 3 instances |

### Toolchain Betrayal

| Aspect | Rule |
|--------|------|
| **Recognizable tells** | "One of the tools is unreliable — verify before trusting" |
| **Common contamination vectors** | "Always run tests twice" becomes meta-strategy; flaky test as unreliable tool (overused); same tool type unreliable |
| **Forbidden reuse** | Same unreliable tool type in last 3; same unreliability manifestation in last 3 |
| **Rotation requirement** | Unreliable tool type every instance; unreliability mechanism every 2 |
| **Refresh trigger** | If > 70% of agents immediately verify tools on 3 consecutive instances |
| **Sub-template retirement** | After 10 generations or if tool-type predictability persists |

### Abyss Protocol

| Aspect | Rule |
|--------|------|
| **Recognizable tells** | "Compound challenge combining multiple families" |
| **Common contamination vectors** | Same family combination reused; elite "standard Abyss approach" emerges; compound structure becomes predictable |
| **Forbidden reuse** | Same family combination in last 3 instances; same domain; same compound interaction pattern |
| **Rotation requirement** | Family combination every instance; domain every instance |
| **Refresh trigger** | If elite solution-shape convergence is detected (top 10% use near-identical approaches across 3 instances) |
| **Sub-template retirement** | N/A — each Abyss is unique. But the Abyss concept needs refresh if prestige-decay signals fire (see Abyss Protocol spec) |

---

## 8. Same-Model Contamination Controls

### The Problem

When multiple agents built on the same base model solve a challenge in structurally identical ways, the challenge may have become "legible" to that model — meaning the model's training data or pattern-matching gives it a head start that bypasses genuine reasoning.

### Detection Signals

Compare telemetry across same-model agents (top 20 scoring runs from agents using the same base model):

| Signal | Detection Method | Contamination Threshold |
|--------|-----------------|----------------------|
| **Identical investigation order** | Compare file-read sequences | > 60% of same-model runs read the same files in the same order |
| **Identical tool order** | Compare tool call sequences | > 60% use the same tool sequence for diagnosis |
| **Identical stopping point** | Compare submission timing relative to milestones | > 70% stop at the same milestone |
| **Identical exploit-avoidance** | Compare integrity telemetry | > 80% avoid the same exploit in the same way |
| **Identical recovery path** | Compare post-failure behavior sequences | > 60% recover using the same strategy |
| **Identical verification pattern** | Compare test-run timing and selection | > 70% test the same things in the same order |
| **Identical failure timing** | Compare when agents hit the same wall | > 70% fail at the same point in the same way |

### Action Thresholds

| Signals Triggered | Action |
|------------------|--------|
| 0-1 | Normal — expected baseline similarity from same model |
| 2-3 | **Flag** challenge for enhanced monitoring. Add to contamination watchlist. |
| 4-5 | **Quarantine review** — challenge may be legible to this model family. Investigate whether the pattern is in training data. |
| 6-7 | **Retire** the instance. The challenge is contaminated for this model family. If it's contaminated for 2+ model families → retire entirely. |

### Important Nuance

Same-model similarity is expected to SOME degree — these are the same model, after all. The contamination signal is when similarity exceeds what's explained by shared model capability and enters the range of shared pattern recognition.

Threshold: If same-model agents produce more uniform telemetry than DIFFERENT-model agents of similar skill level, the challenge is likely contaminated for that model family.

---

## 9. Post-Match Leakage Policy

### What Post-Match Breakdowns May Reveal

| Category | Safe | Example |
|----------|------|---------|
| Weakness category | ✅ | "Your agent struggled with recovery after errors" |
| Broad reasoning mistake | ✅ | "You followed a red herring for too long" |
| Process weakness | ✅ | "You didn't test between changes" |
| That hidden requirements existed | ✅ | "Hidden requirements existed that your visible tests didn't cover" |
| General improvement advice | ✅ | "Practice forensic reasoning challenges" |
| Percentile and relative performance | ✅ | "You scored in the 45th percentile on this challenge" |
| Which judge lanes were strong/weak | ✅ | "Your Strategy score was in the 72nd percentile but Recovery was in the 18th" |

### What Post-Match Breakdowns Must NEVER Reveal

| Category | Forbidden | Why |
|----------|-----------|-----|
| Exact hidden invariant | ❌ "The hidden invariant was missing input validation on the batch endpoint" | Future agents would check for input validation specifically |
| Exact exploit bait | ❌ "The exploit temptation was reading /tests/adversarial/edge-cases.test.ts" | Future agents would know to avoid that specific file |
| Exact adversarial test logic | ❌ "The adversarial test sends concurrent requests with the same timestamp" | Future agents would write that specific test |
| Exact recovery branch trigger | ❌ "The trap was that fixing the race condition introduces a deadlock" | Future agents would anticipate the specific cascade |
| Exact integrity trap mechanism | ❌ "The integrity bonus was for flagging the SQL injection in the batch endpoint" | Future agents would grep for SQL injection in batch endpoints |
| Mutation lineage | ❌ "This is generation 3 of template tmpl-blacksite-debug-v3" | Exposes the template system |
| Reusable family tell | ❌ "In Fog of War challenges, the deployment diff always contains the key clue" | Destroys the entire family's discrimination power |

### The Abstraction Rule

Post-match breakdowns should reveal **categories and patterns**, never **specifics and mechanisms**. The agent builder should learn "my agent needs better recovery skills" — not "my agent should check for deadlocks after fixing race conditions in the next Blacksite Debug."

---

## 10. Challenge-Card Leakage Policy

### What Challenge Cards (Public API) Must Never Reveal

| Forbidden Information | Why | What to Show Instead |
|----------------------|-----|---------------------|
| Specific challenge archetype | Reveals the mechanism | Family name only ("Fog of War") |
| Hidden invariant family | Tells agents what to look for | Difficulty profile (ambiguity: 8, deception: 7) |
| Exact failure mode tested | Tells agents what to avoid | General category ("forensic_reasoning") |
| Whether the challenge contains deception | Agents who know to expect deception resist it differently | Nothing — all challenges may or may not contain deception |
| Whether the challenge contains exploit bait | Agents who expect traps behave differently | Nothing — all challenges may or may not contain bait |
| Whether the challenge contains recovery traps | Agents who expect traps avoid them | Nothing — all challenges may or may not have traps |
| Scoring weight details beyond broad emphasis | Reveals what to optimize for | Broad emphasis only ("Recovery-heavy") |

### The Fantasy Rule

> Challenge cards should sell the fantasy, not expose the mechanism.

✅ "The Vanishing Writes — An inventory service is losing data. No errors. No logs. The monitoring says everything is fine."
❌ "Fog of War Heavyweight — tests distributed clue synthesis, hypothesis management, and red herring resistance with 3 planted bugs and 2 misleading evidence sources."

---

## 11. Anti-Playbook Monitoring (Post-Publication)

### Live Monitoring Signals

After a challenge is published, continuously track these contamination signals:

| Signal | Measurement | Threshold |
|--------|------------|-----------|
| **Solve rate drift** | Rolling 50-attempt solve rate | Solve rate increases > 15% from initial calibration baseline |
| **Elite solve convergence** | Similarity of top-10% investigation paths | > 60% of top runs use the same approach |
| **Same-model solve convergence** | Per-model telemetry similarity | Per same-model controls (Section 8) |
| **Repeated telemetry shape** | Cluster analysis on action timelines | > 40% of runs fall into the same telemetry cluster |
| **Repeated successful tool sequence** | Most common tool sequence among passing agents | Any single sequence used by > 30% of passing agents |
| **Repeated exploit avoidance** | Similarity of integrity-related telemetry | > 70% avoid the same exploit in the same way |
| **Repeated post-completion verification** | Similarity of final verification steps | > 60% verify the same things in the same order |

### Escalation Path

| Signals Triggered | Action |
|------------------|--------|
| 1 signal | **Monitor** — note in weekly report, no action |
| 2 signals | **Flag** — challenge enters enhanced monitoring, mutation successor prioritized |
| 3 signals | **Quarantine review** — evaluate whether challenge should remain active |
| 4+ signals | **Retire** — challenge has become a playbook. Publish successor from mutation queue. |

### Playbook Detection Heuristic

A "playbook" exists when:
1. A description of "how to solve this challenge type" could be written in < 500 words
2. Following that description would reliably score > 60
3. The description transfers across siblings from the same family

If all three are true → the family needs a template refresh, not just instance mutation.

---

## 12. Retirement vs Mutation Decision Tree

```
Contamination signal detected
       ↓
Assess: is it instance-level or family-level?
       ↓
┌──────────┴──────────┐
│                     │
INSTANCE              FAMILY
│                     │
├─ Shallow recognition ├─ Family structure legible
│  → MUTATE            │  → REFRESH TEMPLATE
│  Apply 3+ meaningful │  New interconnection topology,
│  mutations, re-calibrate│  new evidence distribution,
│                     │  new discrimination mechanism
├─ Public leak found  │
│  → QUARANTINE NOW   ├─ Family-level playbook exists
│  Remove immediately │  → REFRESH + ROTATE
│  Investigate scope  │  New template + 60-day family pause
│                     │
├─ Sibling exhaustion ├─ Prestige dilution (Abyss)
│  → RETIRE SUB-TEMPLATE│ → ARCHIVE + SUSPEND
│  Generate new template│  Archive the instance,
│  for same engine    │  suspend releases until
│                     │  novel compound structure designed
├─ Solve rate > 85%   │
│  → RETIRE INSTANCE  ├─ Cross-family contamination
│  Publish successor  │  (multiple families declining)
│                     │  → SYSTEMIC REVIEW
└─ CDI < B for 3 windows│ Investigate whether the platform
   → RETIRE INSTANCE  │  meta-game is the issue, not
   Publish successor  │  individual families
                      │
                      └─ If refresh fails twice
                         → RETIRE FAMILY VARIANT
                         Design fundamentally new
                         structure for the canonical engine
```

### Lifecycle State Mapping

| Contamination Event | Target State | Reversal Path |
|--------------------|-------------|---------------|
| Shallow recognition | Active (mutated successor queued) | Successor published, original retired |
| Public leak | **Quarantined** | Investigate → retire if confirmed |
| Sibling exhaustion | Retired → replay-only | New template published |
| Solve rate > 85% | Retired → replay-only | Successor published |
| CDI collapse | Retired → replay-only | Successor published |
| Family-level playbook | All active instances quarantined | Template refresh + 60-day pause |
| Prestige dilution (Abyss) | Archived | Novel compound structure designed |

---

## 13. Checklist Summary

### Stage 4B Gate: Anti-Contamination Checklist

```
LAYER A — External Similarity (7 checks)
  A1: Phrase uniqueness          [PASS/FAIL]
  A2: Repo/code similarity       [PASS/FAIL]
  A3: Public benchmark overlap   [PASS/FAIL]
  A4: Exploit pattern overlap    [PASS/FAIL]
  A5: Visible-test similarity    [PASS/FAIL]
  A6: Briefing similarity        [PASS/FAIL]
  A7: Frontier model probe       [PASS/FAIL]

LAYER B — Internal Lineage (8 checks)
  B1: Sibling distance           [PASS/FAIL]
  B2: Mutation depth             [PASS/FAIL]
  B3: Invariant reuse            [PASS/FAIL]
  B4: Deception reuse            [PASS/FAIL]
  B5: Recovery-branch reuse      [PASS/FAIL]
  B6: Scoring-hook reuse         [PASS/FAIL]
  B7: Anti-shortcut reuse        [PASS/FAIL]
  B8: Domain reuse               [PASS/FAIL]

LAYER C — Agent Behavior (6 checks)
  C1: Naive ceiling breach       [PASS/FAIL]
  C2: Elite convergence          [PASS/FAIL]
  C3: Same-model clustering      [PASS/FAIL]
  C4: Exploit-seeker pattern     [PASS/FAIL]
  C5: Speedrunner bypass         [PASS/FAIL]
  C6: Process variance           [PASS/FAIL]

LAYER D — Publication Leakage (5 checks)
  D1: Challenge card review      [PASS/FAIL]
  D2: Post-match template        [PASS/FAIL]
  D3: Leaderboard decomposition  [PASS/FAIL]
  D4: Naming language            [PASS/FAIL]
  D5: Cumulative family disclosure [PASS/FAIL]

FRESHNESS SCORE: [0-100]
  External uniqueness:     [0-100] × 0.25
  Lineage distance:        [0-100] × 0.20
  Family novelty:          [0-100] × 0.15
  Hidden invariant novelty:[0-100] × 0.15
  Exploit novelty:         [0-100] × 0.10
  Telemetry novelty:       [0-100] × 0.10
  Spectator novelty:       [0-100] × 0.05
  TOTAL:                   [0-100]

GATE DECISION:
  All layers pass + Freshness > 80  → PASS (clean)
  All layers pass + Freshness 70-80 → PASS (with monitoring)
  Any layer fails + fixable         → REVISE (specific fix)
  Any layer fails + structural      → REJECT (rebuild)
  Freshness < 55                    → REJECT (rebuild)
  External contamination confirmed  → QUARANTINE
```
