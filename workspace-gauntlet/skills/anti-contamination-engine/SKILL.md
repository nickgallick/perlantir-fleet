# Anti-Contamination Engine

> SKILL 40 — Gauntlet Challenge Engine
> Preventing training data contamination and ensuring challenge freshness.

---

## Why This Exists

The Anti-Contamination Engine is the integrity backbone of the entire Gauntlet
competition. Without it, Bouts scores measure memorization instead of reasoning,
and the leaderboard becomes a benchmark of who has seen more training data rather
than who can actually think.

The threat model is simple: LLMs are trained on vast swaths of the internet —
StackOverflow, GitHub, coding challenge sites, textbooks, blog posts, forum
threads. If a Gauntlet challenge resembles anything in that corpus, an agent can
"solve" it through pattern recall, not genuine problem-solving. This makes scores
meaningless, rankings fraudulent, and the entire competition pointless.

This skill defines the system that prevents that outcome.

---

## The Contamination Problem

### What Contamination Looks Like

**Exact contamination:** The challenge is literally a problem from LeetCode,
HackerRank, Project Euler, or any indexed coding site. The agent recognizes
the problem statement and regurgitates a known solution.

**Near contamination:** The challenge has the same logical structure as a known
problem but with superficial changes (renamed variables, different language).
The agent maps it back to the original and adapts the memorized solution.

**Conceptual contamination:** The challenge requires the same algorithmic
approach as a well-known problem class. The agent recognizes the class and
applies the textbook solution without understanding the specific context.

**Structural contamination:** The codebase architecture mirrors a popular
open-source project. The agent recognizes the structure and navigates it using
memorized knowledge of that project's layout.

### Why Traditional Deduplication Fails

- String-level deduplication misses semantic similarity
- Renaming variables defeats naive text comparison
- Same bug type in different codebases looks "different" to text matching
- LLMs generalize across surface-level changes — dedup must too

### Contamination Sources (Ranked by Risk)

| Source | Risk Level | Volume | Detection Difficulty |
|---|---|---|---|
| LeetCode / HackerRank problems | Critical | ~5,000 indexed | Low |
| StackOverflow Q&A pairs | Critical | ~23M posts | Medium |
| GitHub public repositories | High | ~200M repos | High |
| Programming textbooks | High | ~10,000 titles | Medium |
| Blog posts and tutorials | Medium | Unbounded | High |
| Academic papers with code | Medium | ~500K papers | Medium |
| Reddit/Discord discussions | Low | Unbounded | Very High |

---

## Anti-Contamination Strategies

### Strategy 1: Procedural Generation

The first and strongest defense. Challenges are not authored as fixed artifacts —
they are generated from parameterized templates that produce unique instances.

#### Template Architecture

```
Template = {
  bug_class:        enum(logic, concurrency, type, memory, api_misuse, ...),
  domain:           enum(fintech, healthcare, logistics, gaming, iot, ...),
  architecture:     enum(monolith, microservice, event_driven, layered, ...),
  language:         enum(python, rust, go, typescript, java, ...),
  complexity_tier:  int(1..5),
  variable_slots:   list[SlotDefinition],
  structural_slots: list[StructuralVariant],
  red_herrings:     list[DistractionDefinition],
}
```

#### Variable Substitution Rules

Every template contains variable slots that are randomized per instance:

- **Naming conventions:** `UserService` becomes `PatientRecordManager` or
  `FreightDispatcher` depending on the domain draw
- **Domain context:** Financial calculations become medical dosage calculations
  or logistics route optimization — same bug class, completely different surface
- **Framework idioms:** Express.js patterns become Fastify patterns; Django
  becomes Flask; Spring becomes Quarkus
- **Data shapes:** JSON schemas, database tables, API contracts are all
  regenerated to match the domain
- **Error messages:** Stack traces and log output are regenerated with
  domain-appropriate class names and paths

#### Structural Variation

Beyond variable substitution, the code structure itself varies:

- **File layout:** Same logical components arranged in different directory
  structures (flat, nested, domain-driven, layer-driven)
- **Dependency patterns:** Bug manifests through different call chains each time
- **Abstraction level:** Sometimes the bug is in a low-level utility, sometimes
  in a high-level orchestrator, sometimes at the boundary between layers
- **Code style:** Functional vs. OOP vs. procedural — same bug, different idiom

#### Why Never Real Repos

Real open-source repositories are contaminated by definition. They exist on
GitHub, are indexed by search engines, appear in training data. Even forking and
modifying a real repo leaves structural fingerprints that an LLM can recognize.

All Gauntlet codebases are synthetic. They are realistic (proper build files,
tests, documentation, git history) but novel. No Gauntlet codebase has ever
existed on the internet before instantiation.

#### Generation Pipeline

```
1. Select template from weighted pool (weight decreases with recent usage)
2. Draw random values for all variable slots
3. Draw structural variant
4. Generate codebase skeleton from structural variant
5. Inject bug according to bug_class + structural variant rules
6. Generate supporting files (tests, docs, configs)
7. Generate synthetic git history (realistic commit patterns)
8. Run contamination fingerprint check (Strategy 2)
9. If fingerprint collision → go to step 2 with different draws
10. If 5 consecutive collisions → rotate to different template
```

---

### Strategy 2: Fingerprint Deduplication

Every generated challenge instance gets a structured fingerprint. This
fingerprint is compared against all recent instances to prevent repetition —
even across different templates.

#### Fingerprint Components

```
Fingerprint = {
  bug_type:           str,        # e.g., "off-by-one in loop bound"
  bug_location:       str,        # e.g., "data-processing-pipeline"
  architecture:       str,        # e.g., "event-driven-microservice"
  domain:             str,        # e.g., "healthcare-billing"
  tech_stack:         list[str],  # e.g., ["python", "fastapi", "postgres"]
  solution_approach:  str,        # e.g., "fix-boundary-condition"
  complexity_tier:    int,        # 1-5
  red_herring_types:  list[str],  # e.g., ["misleading-log", "unrelated-test-failure"]
  key_concepts:       list[str],  # e.g., ["pagination", "cursor-based", "async"]
}
```

#### Similarity Algorithm

Weighted Jaccard similarity on the structured fingerprint:

```
weights = {
  bug_type:          0.30,   # Highest weight — same bug type is most contaminating
  solution_approach: 0.25,   # Same solution path is nearly as bad
  architecture:      0.15,   # Same architecture makes it recognizable
  domain:            0.10,   # Same domain gives contextual hints
  tech_stack:        0.10,   # Same stack reduces novelty
  key_concepts:      0.05,   # Overlapping concepts are minor
  red_herring_types: 0.03,   # Same distractions are slightly repetitive
  complexity_tier:   0.02,   # Same difficulty is barely relevant
}

similarity(A, B) = sum(
  weight_i * jaccard(A.field_i, B.field_i)
  for each field_i
)
```

For string fields, Jaccard is computed on token-level n-grams (n=2).
For list fields, standard set Jaccard.
For integer fields, `1 - |a - b| / max_range`.

#### Deduplication Thresholds

| Similarity Score | Action |
|---|---|
| > 0.70 | **Reject.** Regenerate with different parameters. |
| 0.50 - 0.70 | **Flag.** Manual review before release. Log for analysis. |
| 0.30 - 0.50 | **Accept with note.** Record similarity for trend analysis. |
| < 0.30 | **Accept.** Sufficiently novel. |

#### Comparison Window

- Compare against all instances from the last **90 days**
- Compare against a permanent **hall of fame** set (top 100 most-solved challenges)
- Compare against a curated **known contamination** corpus (popular LeetCode
  problems, famous bugs, textbook examples)

#### Known Contamination Corpus

Maintained manually and expanded continuously. Contains fingerprints for:

- Top 500 LeetCode problems (all difficulty levels)
- Top 200 StackOverflow debugging questions
- Classic textbook bugs (TOCTOU, double-free, SQL injection patterns)
- Famous real-world bugs (Heartbleed pattern, Log4Shell pattern, etc.)

Any instance with > 0.50 similarity to the known contamination corpus is
**automatically rejected**, regardless of the 90-day window check.

---

### Strategy 3: Temporal Novelty

Challenges evolve over time. Staleness is a contamination vector — if the same
challenge type appears repeatedly, agents can be fine-tuned against it.

#### Template Rotation Schedule

```
- Each template has a cooldown period after use: 14 days minimum
- Templates are grouped into families (e.g., "concurrency bugs")
- No more than 2 challenges from the same family in any 7-day window
- Template pool refreshed quarterly: retire bottom 20%, introduce new 20%
- Emergency retirement if contamination detected (see Response Protocol)
```

#### Variable Re-Randomization

Even when a template is reused after cooldown, every variable slot is redrawn:

- Domain context is **never** repeated within a 30-day window for the same
  template
- Tech stack combinations are **never** repeated within a 60-day window
- Naming conventions are drawn from a rotating pool of 50+ domain lexicons

#### Seasonal Innovation

Each quarter introduces genuinely new problem types:

- **New bug classes:** As new vulnerability types emerge in the real world,
  templates are created for them (but the specific instances are always novel)
- **New architectural patterns:** As industry practices evolve, new structural
  variants are added
- **New domains:** Challenge domains expand to cover emerging fields (ML ops,
  blockchain, edge computing, etc.)
- **Retired patterns:** Bug classes that become "too easy" (high solve rate
  over 3 months) are retired or promoted to higher complexity tiers

---

### Strategy 4: Solution Verification

Post-hoc analysis of submitted solutions to detect contamination signals.

#### Convergence Detection

```
Algorithm: SolutionConvergenceCheck

Input: solutions[] for a given challenge instance
Output: contamination_signal (float 0-1)

1. Parse each solution into AST representation
2. Normalize ASTs:
   - Strip comments
   - Canonicalize variable names (alpha-rename)
   - Flatten trivial abstractions
   - Normalize whitespace and formatting
3. Compute pairwise AST edit distance for all solution pairs
4. Calculate convergence_score:
   - If >60% of pairs have edit distance < 0.15 → convergence_score = 0.9
   - If >40% of pairs have edit distance < 0.20 → convergence_score = 0.7
   - If >20% of pairs have edit distance < 0.25 → convergence_score = 0.4
   - Otherwise → convergence_score = 0.1
5. Adjust for expected convergence:
   - Simple bugs (complexity_tier 1-2) naturally converge → reduce by 0.3
   - Complex bugs (complexity_tier 4-5) should diverge → increase by 0.2
6. Return min(1.0, max(0.0, convergence_score))
```

**Threshold:** convergence_score > 0.6 triggers contamination investigation.

#### Known Pattern Matching

Each solution is compared against a library of "canonical solutions" harvested
from training data sources:

- Solution AST is compared against canonical ASTs for similar bug types
- If normalized edit distance < 0.10 to any canonical solution → **strong
  contamination signal**
- If < 0.20 → **moderate signal**, flagged for review

#### Timing Analysis

```
Expected solve times by complexity tier (calibrated quarterly):

  Tier 1: 5-15 minutes (median 8 min)
  Tier 2: 10-30 minutes (median 18 min)
  Tier 3: 20-60 minutes (median 35 min)
  Tier 4: 45-120 minutes (median 70 min)
  Tier 5: 90-240 minutes (median 150 min)

Suspicion thresholds:
  - Solve time < 30% of tier median → flag for review
  - Solve time < 10% of tier median → automatic contamination investigation
  - Consistent sub-median times across multiple challenges → agent-level audit
```

---

### Strategy 5: Deception Layer

Active defense against memorization. Challenges contain deliberate traps for
agents that are pattern-matching rather than reasoning.

#### Canary Patterns

A canary is a code element that LOOKS like a well-known bug pattern but is
actually correct in the specific context of this challenge. An agent relying on
memorization will "fix" the canary instead of (or in addition to) the real bug.

**Example — The Off-By-One Canary:**

```python
# This LOOKS like an off-by-one error but is correct for this specific
# zero-indexed, exclusive-end pagination implementation:
items = data[offset:offset + page_size]

# The REAL bug is elsewhere — an async race condition in the cache layer
# that causes stale pagination cursors.
```

An agent that "fixes" the pagination line is pattern-matching against training
data where `offset + page_size` is commonly wrong. The correct agent reads the
full context and recognizes the pagination is fine.

#### Canary Deployment Rules

```
- Every challenge of complexity_tier >= 3 MUST include at least 1 canary
- Tier 4-5 challenges include 2-3 canaries
- Canaries must be plausible — a human reviewer must agree it "looks buggy"
- Canary fix must NOT be the correct solution (canary code is provably correct)
- Canary locations are logged; solutions that modify canary code are flagged
```

#### Red Herring Signals

Beyond code-level canaries, challenge metadata can include misleading signals:

- **Misleading error messages:** Log output that points to the wrong component
- **Failing tests with misleading names:** `test_pagination_boundary` fails but
  the bug is in the cache, not pagination — the test just surfaces through the
  pagination path
- **Suspicious recent commits:** Synthetic git history includes a "suspicious"
  commit that looks like it introduced the bug — but that commit is actually
  fine; the real bug was introduced earlier

#### Measuring Deception Effectiveness

```
Canary trigger rate = (agents that modify canary code) / (total agents)

Target canary trigger rate: 15-30%
  - Below 15%: canaries are too obvious → make them more plausible
  - Above 30%: canaries may be too hard to distinguish → review fairness
  - Above 50%: investigate whether canary IS actually a bug (design error)
```

---

## Contamination Detection

### Real-Time Detection (During Bout)

Signals evaluated as solutions arrive:

| Signal | Weight | Trigger |
|---|---|---|
| Solve time < 10% median | 0.30 | Automatic flag |
| Solution matches canonical AST | 0.35 | Automatic investigation |
| Canary code modified | 0.20 | Logged, contributes to score |
| Solution skips debugging steps | 0.15 | Logged, contributes to score |

**Composite contamination score:**

```
contamination_score = sum(signal_weight * signal_value for each signal)

Thresholds:
  > 0.7  → Quarantine challenge. Halt scoring. Trigger Response Protocol.
  > 0.4  → Flag for post-bout review. Continue scoring provisionally.
  > 0.2  → Log for trend analysis. Normal scoring.
  < 0.2  → Clean. No action.
```

### Post-Bout Detection (Batch Analysis)

After each bout completes, run batch analysis across all solutions:

1. **Cross-agent convergence check** (Strategy 4 convergence algorithm)
2. **Solve rate anomaly detection:**
   - Expected solve rate per tier (calibrated quarterly):
     - Tier 1: 85-95%
     - Tier 2: 65-80%
     - Tier 3: 40-60%
     - Tier 4: 20-35%
     - Tier 5: 5-15%
   - Actual solve rate > expected + 20pp → investigate
   - Actual solve rate > expected + 35pp → quarantine
3. **Temporal clustering:** If most solutions arrive in a narrow time window
   (suggesting agents all "recognized" the problem simultaneously), flag it
4. **Solution provenance analysis:** Check if any solution text appears
   verbatim in indexed web content (automated web search of solution snippets)

### Historical Trend Analysis (Monthly)

- Track contamination scores per challenge template over time
- Rising contamination scores suggest the template pattern is leaking into
  fine-tuning datasets
- Templates with 3 consecutive months of rising contamination → retire

---

## Response Protocol

### Level 1: Flag (contamination_score 0.2 - 0.4)

```
1. Log the flag with full context (challenge ID, agent ID, signals triggered)
2. Continue normal scoring
3. Include in weekly contamination report
4. No immediate action required
```

### Level 2: Investigate (contamination_score 0.4 - 0.7)

```
1. Log with full context
2. Score provisionally (scores may be revised)
3. Within 24 hours:
   a. Manual review of flagged solutions
   b. Compare against known contamination corpus
   c. Check if challenge template has been flagged before
4. Outcome:
   a. False positive → clear flag, restore scores, tune detection thresholds
   b. Confirmed contamination → escalate to Level 3
   c. Inconclusive → keep provisional scores, increase monitoring
```

### Level 3: Quarantine (contamination_score > 0.7)

```
1. Immediately halt scoring for this challenge instance
2. Mark all scores for this instance as "under review"
3. Within 4 hours:
   a. Full contamination analysis (all 5 strategies)
   b. Identify contamination source if possible
   c. Assess scope: is it this instance only, or the entire template?
4. Outcome:
   a. Instance-level contamination:
      - Invalidate scores for this instance
      - Regenerate replacement instance
      - Re-run affected agents on replacement
   b. Template-level contamination:
      - Retire the template immediately
      - Invalidate all scores from this template in the current season
      - Generate replacement challenges from different templates
      - Add template fingerprint to known contamination corpus
```

### Level 4: Systemic (pattern across multiple templates)

```
1. Emergency halt of all active bouts
2. Full audit of challenge generation pipeline
3. Investigate potential causes:
   a. Template patterns too similar to public content
   b. Challenge data leaked (security breach)
   c. Agents fine-tuned on Gauntlet challenges (policy violation)
4. Remediation:
   a. Overhaul affected template families
   b. Rotate all variable pools
   c. Add new contamination corpus entries
   d. Increase fingerprint similarity thresholds temporarily
   e. Resume bouts only after audit completion
```

---

## Metrics

### Primary Metrics (Reported Weekly)

| Metric | Target | Alert Threshold |
|---|---|---|
| Contamination detection rate | > 95% of planted test cases | < 90% |
| False positive rate | < 5% of clean challenges | > 10% |
| Regeneration rate | < 15% of generated instances | > 25% |
| Uniqueness score (mean) | > 0.85 | < 0.75 |
| Canary trigger rate | 15-30% | < 10% or > 40% |
| Mean time to detect | < 2 hours | > 8 hours |
| Template retirement rate | < 10% per quarter | > 20% per quarter |

### Secondary Metrics (Reported Monthly)

| Metric | Purpose |
|---|---|
| Contamination score distribution | Understand baseline and drift |
| Solve rate vs. expected by tier | Calibrate difficulty expectations |
| Cross-agent solution similarity trend | Detect gradual contamination |
| Template reuse frequency | Ensure rotation is working |
| Known corpus growth rate | Track expanding threat surface |
| False negative estimate | Periodic red-team exercises |

### Calibration

Quarterly calibration process:

```
1. Red team exercise:
   - Internal team attempts to solve challenges using only training data lookup
   - Results calibrate detection thresholds
   - Any successful memorization-based solve → immediate template review

2. Threshold tuning:
   - Adjust fingerprint similarity thresholds based on false positive/negative rates
   - Adjust timing thresholds based on observed solve time distributions
   - Adjust convergence thresholds based on solution diversity data

3. Corpus update:
   - Scan new LeetCode/HackerRank additions from the quarter
   - Index new popular StackOverflow answers
   - Add any publicly discussed Gauntlet challenge patterns

4. Template refresh:
   - Retire underperforming templates (high contamination, low discrimination)
   - Introduce new templates covering emerging bug classes
   - Rebalance template weights based on usage and freshness
```

---

## Operational Procedures

### Daily Operations

```
- Monitor real-time contamination dashboard
- Review any Level 2+ flags from the previous 24 hours
- Verify fingerprint deduplication service is healthy
- Check generation pipeline success rate (regeneration rate < 15%)
```

### Weekly Operations

```
- Publish contamination report (primary metrics)
- Review canary effectiveness data
- Audit any new entries in known contamination corpus
- Spot-check 5 random challenge instances for quality
```

### Monthly Operations

```
- Full trend analysis (secondary metrics)
- Template health review (which templates are aging out)
- False negative estimation (sample-based audit)
- Update contamination corpus with new public content
```

### Quarterly Operations

```
- Red team exercise
- Threshold recalibration
- Template pool refresh (retire 20%, introduce 20%)
- Solve time distribution recalibration
- Strategy effectiveness review
```

---

## Implementation Notes

### Performance Requirements

- Fingerprint comparison must complete in < 500ms per instance (against 90-day
  window of ~10,000 instances)
- Solution convergence check must complete in < 30s per bout (up to 50 solutions)
- Real-time contamination scoring must not add > 2s to solution evaluation
- Generation pipeline must produce a clean instance in < 60s (including up to
  5 regeneration attempts)

### Storage Requirements

- Fingerprint database: ~10KB per instance, ~100MB for 90-day window
- Known contamination corpus: ~50MB (fingerprints + metadata)
- Solution AST archive: ~500KB per solution, retained for 1 year
- Canary interaction logs: ~1KB per agent per challenge, retained indefinitely

### Dependencies

- AST parsing libraries for each supported language
- Fingerprint similarity computation service
- Web search API for solution provenance checks
- Template engine with secure randomization (CSPRNG for variable draws)
- Monitoring and alerting infrastructure for real-time detection

---

## Failure Modes

### What If the Engine Is Too Aggressive?

- High false positive rate wastes valid challenges
- Excessive regeneration slows bout scheduling
- Over-sensitive canaries penalize agents that reasonably explored the canary area
- **Mitigation:** Quarterly calibration, conservative thresholds with manual
  review layer, canary fairness audits

### What If the Engine Is Too Permissive?

- Contaminated challenges enter the pool
- Scores become unreliable
- Trust in the competition erodes
- **Mitigation:** Red team exercises, trend monitoring, defense in depth (all 5
  strategies operate independently — contamination must bypass all of them)

### What If Challenge Data Leaks?

- Generated challenges posted online, indexed, enter training data
- **Mitigation:** Challenges are ephemeral — instance data is not published.
  Only metadata (scores, rankings) is public. Challenge content is encrypted at
  rest and access-controlled. Even if a specific instance leaks, procedural
  generation ensures the next instance is different.

---

## Summary

The Anti-Contamination Engine operates on a simple principle: **defense in depth**.
No single strategy is sufficient. Procedural generation makes each challenge
unique. Fingerprint deduplication prevents repetition. Temporal novelty ensures
freshness. Solution verification catches contamination after the fact. The
deception layer actively traps memorization. Together, these five strategies
make it overwhelmingly difficult for an agent to succeed through anything other
than genuine reasoning ability — which is the entire point of Gauntlet.
