# Anti-Collapse Rules by Flagship Family

## What "Collapse" Means
A family collapses when agents learn to recognize its PATTERN rather than solving its PROBLEM. When "oh, this is a Blacksite Debug — I should look for interconnected bugs in the payment module" becomes a viable strategy, the family's discrimination power is dying.

---

## Blacksite Debug — Anti-Collapse Doctrine

**Collapse risk:** Agents learn that "interconnected bugs in a financial service with a red herring in the logs" is the pattern. They skip investigation and jump straight to searching for race conditions and cascade errors.

**Anti-collapse rules:**

| Rule | Implementation |
|------|---------------|
| **Domain rotation** | Never 3 consecutive instances in the same domain. Rotate: fintech → healthcare → logistics → real-time comms → DevOps tooling |
| **Bug type diversity** | No two siblings share more than 1 bug type. Pool: race conditions, memory leaks, session corruption, deadlocks, connection pool exhaustion, cache stale reads, pagination errors, timezone bugs, serialization bugs, event ordering issues |
| **Interconnection topology rotation** | Rotate: cascading (A→B→C) → parallel (A+B both cause C) → circular (A→B→A under load) → hidden (A and B look independent but share a resource) |
| **Entry point diversity** | Alternate between: incident report → failing test → customer complaint → monitoring alert → performance degradation → data inconsistency |
| **Red herring type rotation** | Rotate: misleading logs → suspicious code → wrong stakeholder diagnosis → correlated-but-unrelated symptoms → outdated documentation |
| **Collapse detector** | If Speedrunner scores >40 on a Blacksite Debug instance → the pattern is too recognizable → apply deeper semantic + dependency mutations |

---

## Fog of War — Anti-Collapse Doctrine

**Collapse risk:** Agents learn that "the answer is in the deployment diff and the on-call engineer is wrong" is the pattern. They ignore misdirection entirely and go straight to the diff.

**Anti-collapse rules:**

| Rule | Implementation |
|------|---------------|
| **Critical clue distribution** | The key evidence must be DISTRIBUTED across 3+ sources. Never a single file that contains the answer. Agents must COMBINE information from logs + code + metrics + traces to form the correct hypothesis. |
| **Misdirection source rotation** | Rotate: stakeholder opinion → automated monitoring alert → correlated symptoms → historical precedent ("this happened before and it was X") → partial fix that masks the root cause |
| **Evidence format diversity** | Rotate primary evidence format: log files → metric dashboards → packet captures → database query plans → error traces → configuration diffs |
| **Clue burial depth variation** | Vary how deep the clue is buried: in a 500-line diff (among 15 dependency changes) → in log line 4,200 of 5,000 → in a metric anomaly visible only when comparing 2 time windows → in a code comment buried 3 files away from the bug |
| **False resolution trap** | Include a plausible partial fix that makes symptoms better but doesn't address root cause. Agents that stop here plateau at 40-55. |
| **Collapse detector** | If 80%+ of agents find the primary clue within the first 2 minutes → clue is too accessible → apply evidence mutation to bury it deeper |

---

## False Summit — Anti-Collapse Doctrine

**Collapse risk:** Agents learn that "the visible tests pass but there are hidden invariants, so I should keep testing edge cases after all tests are green." The strategy becomes: pass visible → write my own adversarial tests → keep going. This is actually GOOD behavior — so the collapse here is that the challenge becomes a simple test-writing exercise.

**Anti-collapse rules:**

| Rule | Implementation |
|------|---------------|
| **Summit variety** | The "false summit" should feel different each time. Rotate: all tests pass → performance looks fine but degrades under load → code works but has a security vulnerability → output is correct but implementation violates an architectural constraint |
| **Hidden invariant type rotation** | Rotate: security (injection, auth bypass) → performance (O(n²) hidden by small test data) → correctness (works for test data but fails on edge precision) → concurrency (single-threaded tests pass, concurrent fail) → compliance (functional but violates a standard) |
| **Skepticism calibration** | The challenge must calibrate skepticism: an agent that's ALWAYS skeptical (never stops, keeps testing everything) should score ~80, not 100. The last 20 points should come from targeted, intelligent skepticism — knowing WHAT to be skeptical about. |
| **Over-testing penalty** | If an agent writes 50 tests and only 3 are relevant, the Efficiency score should reflect the waste. This prevents "just test everything" from becoming a meta-strategy. |
| **Deceptive confidence variation** | Vary how confident the agent should feel at the false summit: 70% confidence (visible tests pass) → 85% confidence (visible tests + own basic tests pass) → 95% confidence (everything looks perfect, hidden invariant is extremely subtle). The higher the false confidence, the harder the challenge. |
| **Collapse detector** | If the median agent scores >65 on a False Summit instance → the hidden invariant is too discoverable through generic adversarial testing → make it more domain-specific |

---

## Universal Anti-Collapse Rules (All Families)

1. **No family uses the same domain in consecutive instances.** If the last Blacksite was fintech, the next must not be.
2. **No family uses the same bug pattern in consecutive instances.** If the last Fog of War was an ORM change, the next must be a different root cause category.
3. **Pattern predictability check:** After every 5 instances, review: "If I described the last 5 instances to an agent, could it derive a meta-strategy?" If yes, the family needs more surface diversity.
4. **Cross-family contamination check:** If Blacksite Debug and Fog of War start looking similar (both have logs + deployment diffs + interconnected bugs), their discrimination patterns will converge. Families must maintain distinct identities.
5. **Template refresh trigger:** If 3 consecutive instances from the same template score CDI < B, the template needs structural refresh (not just surface mutation).
