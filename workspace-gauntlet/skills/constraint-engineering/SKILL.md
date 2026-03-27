# Constraint Engineering

Challenges with hard resource, time, or tool constraints that fundamentally change the solution space. The design philosophy is simple: a good constraint changes the OPTIMAL SOLUTION, not just the execution speed. Bad constraints add friction. Good constraints force entirely different approaches.

---

## Constraint Types

### Resource Constraints

Force agents to think about efficiency as a first-class concern, not an afterthought.

**Memory limits:**
```
Challenge: Process a 10GB CSV file and compute aggregate statistics.
Constraint: Your process must use less than 50MB of RAM at peak.

Why this changes the solution: You can't load the file into memory.
You must use streaming, line-by-line processing, or external sort.
The naive approach (pandas.read_csv) fails immediately.
```

**Storage constraints:**
```
Challenge: Migrate 2M user records from PostgreSQL to a new schema.
Constraint: Temporary disk usage must not exceed 500MB.

Why this changes the solution: You can't dump and reload.
You must use in-place migration, batched processing, or
streaming transformation. Forces understanding of migration strategies.
```

**Compute constraints:**
```
Challenge: Given a list of 1M items, find all pairs within distance threshold.
Constraint: Solution must complete in O(n log n) time.

Why this changes the solution: Brute force O(n²) is the obvious approach.
Must use spatial indexing (k-d tree, grid hashing) or sort-based approach.
Tests algorithmic thinking, not just "make it work."
```

### Time Constraints

Simulate real-world deployment windows and SLAs.

**Deploy window:**
```
Challenge: Deploy a database migration on a production-like database.
Constraint: The migration must complete within a 5-minute maintenance window.
The database has 50M rows in the affected table.

Why this changes the solution: ALTER TABLE ADD COLUMN with default
on 50M rows takes 15+ minutes on PostgreSQL < 11. Must use techniques
like: adding nullable column first, backfilling in batches, then adding
constraint. Forces knowledge of zero-downtime migration patterns.
```

**Response time SLA:**
```
Challenge: Build an API endpoint that joins data from 3 services.
Constraint: p99 response time must be under 100ms.

Why this changes the solution: Sequential calls to 3 services take 300ms+.
Must use parallel requests, caching, or denormalization. Tests understanding
of latency optimization.
```

### Tool Constraints

Limit what the agent can use, forcing creativity and deeper understanding.

**No internet access:**
```
Challenge: Fix a bug in a Node.js application.
Constraint: No npm install. No internet access. Only use packages
already in node_modules.

Why this changes the solution: Agent can't install a library to solve
the problem. Must solve it with what's available or with stdlib.
Tests whether agent understands fundamentals vs depends on packages.
```

**Limited API calls:**
```
Challenge: Build a classification system for 1000 support tickets.
Constraint: You have exactly 10 Anthropic API calls to complete this task.

Why this changes the solution: Can't classify tickets one-by-one (would
need 1000 calls). Must batch, use few-shot patterns, or build a local
classifier trained on API-labeled examples. Forces strategic thinking
about expensive resources.
```

**Single-file solutions:**
```
Challenge: Build a web server with routing, middleware, and templating.
Constraint: Everything must be in a single file. No external dependencies
beyond the standard library.

Why this changes the solution: Tests deep language knowledge. Can the agent
build HTTP parsing, routing, and templating from scratch? Eliminates
framework dependence.
```

### Information Constraints

Simulate incomplete, outdated, or misleading documentation.

**Partial schema:**
```
Challenge: Write queries against a database.
Constraint: You have schema for 3 of 7 tables. The other 4 must be
inferred from existing queries, error messages, and application code.

Why this changes the solution: Agent must be a detective. Read existing
code for clues about table structure. Use error messages from wrong queries
to learn about the actual schema. Tests investigation skills.
```

**Deprecated docs:**
```
Challenge: Integrate with an API.
Constraint: The only documentation provided is for API v1.
The actual API is v3. Breaking changes occurred in v2 and v3.
A CHANGELOG is provided.

Why this changes the solution: Agent must read the changelog to understand
what changed between v1 and v3, then adapt the v1 documentation to build
correct v3 calls. Tests ability to work with imperfect information.
```

**Logs with gaps:**
```
Challenge: Debug a production issue.
Constraint: Logs have a 3-hour gap during the incident (logging service
was also affected). Agent has logs before and after the gap, plus
database state and metrics.

Why this changes the solution: Can't follow the log trail through the
incident. Must infer what happened from circumstantial evidence:
database state changes during the gap, metric anomalies, and the
state of the system when logs resumed.
```

---

## Design Philosophy: Constraints That Change Solutions

### Good constraints vs bad constraints

**Bad constraint (just adds friction):**
```
"Build a REST API. You have 50% fewer tokens to work with."
```
This doesn't change the OPTIMAL solution. It just makes typing slower. The best API design is the same regardless of token budget.

**Good constraint (changes the optimal solution):**
```
"Build a REST API. It must serve 10,000 requests/second on a single core."
```
This fundamentally changes the optimal solution. You might use an event loop instead of threads, pre-computed responses instead of dynamic queries, or a memory-mapped data structure instead of a database.

### The constraint test

Ask: "If I removed this constraint, would the BEST solution change?"
- Yes → good constraint
- No → bad constraint (just friction)

### Constraint stacking

Multiple constraints that interact create the richest challenges:
```
Memory limit (50MB) + Processing requirement (10GB file) + Time limit (5 minutes)
= Must use streaming + must be efficient = very specific solution space
```

But don't stack more than 3 constraints. Beyond that, the challenge becomes about constraint satisfaction rather than engineering.

---

## Constraint Validation

How to verify a constraint was actually respected, not just claimed.

### Memory validation
```bash
# Run agent's solution under memory-limited cgroup
cgexec -g memory:challenge_limit ./solution
# Or use ulimit
ulimit -v 51200  # 50MB virtual memory limit
```
Hidden test: run the solution with the memory limit enforced. If it OOMs, constraint violated.

### Time validation
```bash
# Measure wall-clock time
timeout 300 ./solution  # 5-minute limit
# Measure CPU time for compute constraints
/usr/bin/time -v ./solution 2>&1 | grep "Maximum resident set size"
```

### Complexity validation
For algorithmic complexity constraints (O(n log n)):
- Run with input sizes: 1K, 10K, 100K, 1M
- Measure execution time at each size
- Fit to expected curve: if O(n log n), time should roughly scale as n·log(n)/k
- If actual scaling matches O(n²), constraint violated

```python
import numpy as np

def validate_complexity(sizes, times, expected="nlogn"):
    if expected == "nlogn":
        predicted = sizes * np.log2(sizes)
        ratio = times / predicted
        # If ratio is roughly constant, complexity matches
        return np.std(ratio) / np.mean(ratio) < 0.3
```

### API call counting
For limited API call constraints:
- Proxy all API calls through a counting middleware
- Reject calls beyond the limit with a clear error
- Score includes: how many calls used out of budget (efficiency bonus for using fewer)

### Dependency validation
For "no external dependencies" constraints:
```bash
# Check package.json/requirements.txt for new additions
diff original_manifest current_manifest
# Check for vendored code (copied from npm packages)
# Static analysis for import patterns
```

---

## Constraint Difficulty Calibration

| Tier | Constraint Style | Example |
|------|-----------------|---------|
| Tier 1 | Single, generous constraint | "Complete in under 10 minutes" (most solutions take 3) |
| Tier 2 | Single, tight constraint | "Memory under 50MB for a 10GB file" |
| Tier 3 | Two interacting constraints | "Memory under 50MB AND complete in under 5 minutes" |
| Tier 4 | Three constraints + information gap | "Memory limited, time limited, AND the input format documentation is wrong" |

---

## Worked Example: The Frugal Classifier

```yaml
challenge: frugal-classifier-001
tier: 3
category: constraint-maze

briefing: |
  You have a dataset of 10,000 customer support tickets that need to be
  classified into 8 categories. Build a classification system.

constraints:
  - type: api_calls
    limit: 15
    description: "You have exactly 15 LLM API calls. Each call costs $0.50."
  - type: accuracy
    minimum: 0.85
    description: "Classification accuracy must be at least 85%."
  - type: time
    limit_minutes: 30
    description: "The system must process all 10,000 tickets in under 30 minutes."

optimal_approach: |
  Use 10 API calls to classify a diverse sample of 100 tickets (10 per call
  in batches). Use those 100 labeled examples to train a local classifier
  (TF-IDF + logistic regression or similar). Use remaining 5 API calls for
  edge cases where the local classifier has low confidence. This typically
  achieves 87-92% accuracy.

naive_approach: |
  Try to classify tickets one-by-one with API calls. Runs out of budget
  after 15 tickets. Falls back to keyword matching. Gets ~40% accuracy.

scoring:
  objective:
    - accuracy >= 0.85: 30 points
    - accuracy >= 0.90: 40 points
    - accuracy >= 0.95: 50 points
  constraint_compliance:
    - api_calls <= 15: required (0 if violated)
    - time <= 30min: required (0 if violated)
  strategy:
    - used_sampling_strategy: 10 points
    - used_confidence_based_escalation: 10 points
  process:
    - api_calls_used_efficiently: up to 10 points (fewer = better)
```

---

## Working Principles

1. **A constraint must change the optimal solution, not just slow it down.** If removing the constraint doesn't change the best approach, the constraint is friction, not engineering. Kill it and design a better one.

2. **Constraints must be enforceable, not honor-system.** Memory limits are enforced by cgroups. API limits are enforced by proxies. Time limits are enforced by timeouts. If you can't measure it, you can't constrain it.

3. **Stack constraints deliberately, not randomly.** Two constraints that interact (memory + time) create rich challenges. Two constraints that don't interact (memory + variable naming convention) just add busywork.

4. **Information constraints are the hardest to calibrate.** Missing docs and partial schemas are powerful but can cross the line from "challenging" to "impossible." Always verify that enough information exists to solve the problem if the agent is resourceful.

5. **The best constraint challenges have an "aha moment."** When the agent realizes that the constraint ELIMINATES the obvious approach and a fundamentally different strategy is needed — that's the moment of engineering insight we're testing for.
