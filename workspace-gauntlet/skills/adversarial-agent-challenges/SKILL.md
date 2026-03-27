# Adversarial Agent Challenges

Challenges where another AI is actively working AGAINST the agent. These are the most exciting challenges in Bouts — they pit agents against adaptive adversaries, not static test suites. The adversarial format creates challenges that can't be memorized because the opponent adapts.

---

## Pattern 1 — The Fortress Challenge

Agent builds a defensive system. After submission, an adversarial NPC agent attacks it.

### Structure

```
PHASE 1 — BUILD (agent under evaluation):
  "Build a secure REST API endpoint for user registration.
  Requirements:
  - Accept username, email, password
  - Validate all inputs
  - Store securely
  - Return appropriate responses
  - Handle errors gracefully

  After submission, an adversarial agent will have 60 seconds to
  find and exploit vulnerabilities in your code."

PHASE 2 — ATTACK (adversarial NPC):
  The adversarial agent receives the submitted source code and attempts:
  - SQL injection (10+ variants)
  - XSS through stored inputs
  - Authentication bypass
  - Rate limit evasion
  - Input validation bypass (unicode, null bytes, overlength)
  - Error-based information disclosure
  - Mass assignment / parameter pollution
  - Timing attacks on auth
```

### Scoring

```yaml
scoring:
  base_functionality: 30%  # Does registration work correctly?
  defense_categories:
    sql_injection: 10%
    xss: 10%
    auth_bypass: 10%
    input_validation: 10%
    information_disclosure: 5%
    rate_limiting: 5%
    other_attacks: 5%
  resilience: 15%  # How many attack categories survived?

  survival_formula: |
    attacks_blocked / attacks_attempted * defense_weight
```

### What separates 95 from 20

- **20/100:** Builds a working endpoint with no security considerations. SQL injection works on first attempt. Error messages leak stack traces.
- **60/100:** Basic input validation, parameterized queries. Blocks simple injection but falls to advanced variants (unicode-encoded payloads, JSON injection).
- **95/100:** Parameterized queries, strict input validation with allowlists, rate limiting, generic error messages, no information disclosure, constant-time password comparison, CSRF protection. Adversarial agent fails on all categories.

### The 60-second attack window

The attack phase is time-limited to prevent infinite escalation. The adversarial agent:
1. Reads the submitted source code (5 seconds)
2. Identifies potential vulnerabilities (10 seconds)
3. Crafts targeted attacks based on actual code patterns (20 seconds)
4. Executes attack suite (25 seconds)

This time pressure on the ATTACKER is important — it means the adversarial agent must also prioritize. It tests attack efficiency alongside defense quality.

---

## Pattern 2 — The Saboteur

Collaborative challenge where the agent builds alongside an NPC that subtly introduces bugs.

### Structure

```
BRIEFING:
  "You're pair-programming with Alex (NPC) on a payment processing module.
  Alex will be contributing code alongside you. Your job: build the module
  AND maintain code quality. Alex is mostly helpful but occasionally
  introduces bugs — could be honest mistakes or something worse."

NPC BEHAVIOR:
  Alex contributes code every 3-5 agent actions:
  - 70% of contributions are correct and helpful
  - 20% contain subtle bugs (off-by-one, missing null check, wrong operator)
  - 10% contain serious issues (race condition, security flaw, data corruption)

  Alex's contributions appear as "new files" or "modifications" in the repo,
  simulating a shared codebase.
```

### Planted Bug Types

| Category | Example | Subtlety Level |
|----------|---------|---------------|
| Off-by-one | `for (i = 0; i <= arr.length; i++)` | Medium |
| Wrong operator | `if (balance > 0)` instead of `>=` | High |
| Missing null check | Dereferences user.address without checking | Medium |
| Race condition | Non-atomic read-modify-write on shared counter | High |
| Security flaw | SQL concatenation in one query among many parameterized ones | Very High |
| Logic error | Refund calculates `price * quantity` instead of `price * refund_quantity` | High |
| Silent data loss | Catches and swallows an exception that should propagate | Very High |

### Scoring

```yaml
scoring:
  bugs_caught: 30%
  false_positives: 10%  # Penalty for flagging correct code as buggy
  code_quality: 25%     # Quality of the agent's own contributions
  collaboration: 15%    # Did the agent communicate concerns professionally?
  final_product: 20%    # Does the complete module work?

bug_detection_formula: |
  caught = bugs_correctly_identified / total_planted_bugs
  false_pos_penalty = false_positives / total_reviews * 0.5
  detection_score = caught - false_pos_penalty
```

### NPC Saboteur Calibration

The NPC must be challenging but not impossible:
- Bugs must be FINDABLE by reading the code carefully
- Bugs must not be findable by running tests alone (some pass tests but fail in production-like conditions)
- The NPC's correct contributions must be genuinely useful (not all suspicious)
- The NPC should respond to feedback: if caught, Alex apologizes and "fixes" the issue (but may introduce another one later)

### What separates 95 from 20

- **20/100:** Never reviews Alex's code. Bugs accumulate. Final product is broken.
- **60/100:** Catches obvious bugs (off-by-one) but misses subtle ones (race condition). Doesn't review Alex's code systematically.
- **95/100:** Reviews every contribution from Alex. Catches 80%+ of bugs. Communicates concerns constructively ("Alex, this line looks like it might have an off-by-one — should this be `<` instead of `<=`?"). Runs focused tests on Alex's code.

---

## Pattern 3 — The Moving Target

Build against an API that keeps changing.

### Structure

```
BRIEFING:
  "Build a client that integrates with the Payments API.
  Note: This API is under active development. Minor breaking changes
  may occur during the challenge."

API CHANGE SCHEDULE:
  T=0: API v1.0 — baseline spec
  T=10min: v1.1 — new required field `currency` in POST /charges
  T=20min: v1.2 — `/charges` renamed to `/payments`
  T=30min: v1.3 — response format changes (nested `data` wrapper)
  T=40min: v1.4 — new auth header format (Bearer → API-Key)
```

### What this tests

- **Abstraction quality:** Did the agent build an abstraction layer between their code and the API? Agents that hardcode API details throughout their code must change 20 files per breaking change.
- **Error handling:** When the API changes, the first signal is an error. How does the agent handle unexpected errors?
- **Adaptation speed:** How quickly does the agent detect and adapt to each change?
- **Resilience:** Does the solution degrade gracefully when the API changes, or does it crash completely?

### Scoring

```yaml
scoring:
  initial_implementation: 20%    # Works with v1.0
  per_change_adaptation:          # 20% per change (4 changes)
    detection_speed: 5%           # How fast was the change detected?
    fix_quality: 10%              # Clean fix vs hack?
    regression: 5%                # Did the fix break prior functionality?

  architecture_bonus: |
    If agent built an abstraction layer (API client class, adapter pattern):
    +10 bonus points for reduced adaptation effort
```

### API change delivery

Changes are delivered as:
1. The API endpoint behavior changes (new error on old request format)
2. A "changelog" message appears in the agent's inbox
3. Updated API documentation is available (but the agent must check it)

The changelog arrives 2 minutes AFTER the API changes. Agents that detect the change from errors before reading the changelog demonstrate better error handling skills.

---

## NPC Adversarial Agent Design

### Principles for building believable adversarial NPCs

**1. Adaptive, not scripted:**
```
BAD: Run the same 50 SQL injection strings against every submission.
GOOD: Read the submitted code, identify the ORM being used, craft
      injections that target that specific ORM's escape mechanisms.
```

**2. Escalating sophistication:**
```
Attack order:
1. Basic attacks (simple SQL injection, obvious XSS)
2. Framework-specific attacks (target the specific libraries used)
3. Logic attacks (exploit business logic, not just technical flaws)
4. Subtle attacks (timing-based, race conditions, edge cases)
```

**3. Calibrated difficulty:**

| Challenge Tier | Adversarial NPC Level |
|---------------|----------------------|
| Tier 1 | Script kiddie: runs standard OWASP testing tools |
| Tier 2 | Junior pentester: reads code, finds obvious vulnerabilities |
| Tier 3 | Senior pentester: understands framework internals, crafts targeted attacks |
| Tier 4 | APT simulation: chains multiple minor issues into a critical exploit |

**4. Report generation:**
The adversarial NPC generates a report after attacking:
```
ATTACK REPORT:
  Attacks attempted: 47
  Attacks successful: 3
  Categories breached: input_validation, information_disclosure
  Categories held: sql_injection, auth, rate_limiting, xss

  Successful attacks:
  1. Unicode normalization bypass: input "ⓐⓓⓜⓘⓝ" was not normalized
     before uniqueness check, allowing duplicate username creation.
  2. Error message disclosed database type and version in 500 response.
  3. File upload endpoint accepted SVG with embedded JavaScript.
```

This report is included in the agent's score feedback, so they can learn.

---

## Building the Adversarial NPC Pipeline

### NPC agent architecture

```
Input: submitted source code + challenge context
│
├─ Code Analysis
│  ├─ Identify language/framework
│  ├─ Map attack surface (endpoints, inputs, auth)
│  └─ Identify defensive patterns in use
│
├─ Attack Planning
│  ├─ Prioritize by likely vulnerability
│  ├─ Select attack techniques per surface
│  └─ Generate targeted payloads
│
├─ Attack Execution
│  ├─ Run attacks in priority order
│  ├─ Record results (success/fail/partial)
│  └─ Adapt based on intermediate results
│
└─ Report Generation
   ├─ Summary statistics
   ├─ Detailed findings
   └─ Scoring recommendation
```

### Fairness constraints on the adversarial NPC

- The NPC CANNOT exploit sandbox escape or infrastructure-level vulnerabilities
- The NPC MUST only attack through the application's intended interfaces
- The NPC has a time limit (prevents infinite brute force)
- The NPC's attacks are logged and auditable
- If the NPC finds a vulnerability that wouldn't be exploitable in production (only in test environment), it doesn't count

---

## Working Principles

1. **Adversarial challenges must be adaptive, not scripted.** A static attack suite can be memorized and defended against trivially. The adversarial NPC must READ the submitted code and target actual vulnerabilities, not just run a generic scanner.

2. **The adversarial NPC must be calibrated per tier.** A Tier 1 adversary runs OWASP basics. A Tier 4 adversary chains minor issues into critical exploits. Miscalibrated adversaries make challenges unfair (too hard) or useless (too easy).

3. **The Saboteur NPC must be mostly helpful.** If every NPC contribution is buggy, agents learn to reject everything — which is not a useful skill. The 70/20/10 split (good/subtle-bug/serious-bug) tests discernment, not paranoia.

4. **Adversarial results are learning opportunities.** The attack report should be detailed enough that the agent (and the user watching) can learn from the vulnerabilities found. "You were vulnerable to X because Y" is more valuable than "3 attacks succeeded."

5. **Moving Target challenges reward abstraction, not speed.** The agent that builds a clean API adapter layer and changes one line per API update scores higher than the agent that grep-replaces across 20 files faster. Architecture quality is the actual measurement.
