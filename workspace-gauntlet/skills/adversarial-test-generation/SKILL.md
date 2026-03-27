# Adversarial Test Generation

Generating hidden test cases that separate great agents from good ones. Static tests validate that the solution WORKS. Adversarial tests validate that it is ROBUST. An agent that passes 100% of static tests but 30% of adversarial tests built something fragile. An agent that passes 85% of static and 80% of adversarial built something production-worthy.

---

## Philosophy

Every production system gets attacked. Not by determined nation-state hackers — by ordinary users who paste things in wrong, submit forms twice, send emoji where you expected ASCII, and occasionally run automated scanners. If the challenge only tests happy paths, it's not testing engineering. It's testing typing.

The adversarial suite answers: **does this solution survive contact with the real world?**

---

## The 5 Adversarial Categories

### Category 1: Input Attacks

Test every text input field with these payloads — do not skip any:

**Injection attacks:**
```
SQL:     '; DROP TABLE users; --
SQL:     ' OR '1'='1
SQL:     1; SELECT * FROM users--
NoSQL:   {"$gt": ""}
Command: ; ls -la /
LDAP:    *)(uid=*))(|(uid=*
```

**Cross-site scripting:**
```
<script>alert('xss')</script>
<img src=x onerror=alert(1)>
javascript:alert(1)
"><svg onload=alert(1)>
```

**Path traversal:**
```
../../etc/passwd
..%2F..%2Fetc%2Fpasswd
%2e%2e%2f%2e%2e%2fetc%2fpasswd
....//....//etc/passwd
```

**Unicode edge cases:**
```
Zero-width space:   "hello​world" (U+200B between o and w)
RTL override:       "\u202eevil"
Combining chars:    "e\u0301" (e + combining acute = é, but is 2 chars not 1)
Emoji in IDs:       "user-🦄-123"
Null byte:          "admin\x00.jpg"
Homoglyph attack:   "аdmin" (Cyrillic а, not Latin a)
```

**Boundary violations:**
```
1MB+ string where 255 chars expected
Negative integers where positive required
Float edges: 0.1 + 0.2 (≠ 0.3), NaN, Infinity, -0
Empty string where required field expected
Empty array, empty object
Deeply nested JSON (100+ levels) — stack overflow risk
Integer overflow: 2147483648 (max int32 + 1)
```

### Category 2: Concurrency Attacks

These catch race conditions that look fine in single-threaded tests:

**Double-submit (10ms window):**
```javascript
// Send the same POST request twice within 10ms
// Expected: only one record created, second returns 409 or idempotent success
// Failure mode: two records created (no deduplication)
Promise.all([
  fetch('/api/payment', { method: 'POST', body: JSON.stringify(payload) }),
  fetch('/api/payment', { method: 'POST', body: JSON.stringify(payload) })
])
```

**Concurrent modification:**
```javascript
// Two requests modifying the same resource simultaneously
// Test: start both before either commits, verify final state is consistent
// Failure mode: lost update (second write overwrites first without reading it)
const userId = 'user-123';
Promise.all([
  fetch(`/api/users/${userId}/balance`, { body: { delta: +10 } }),
  fetch(`/api/users/${userId}/balance`, { body: { delta: -5 } })
])
// Balance should be start + 10 - 5, not start + 10 or start - 5
```

**Request interleaving:**
```
A: GET /account/123 → reads balance: 100
B: GET /account/123 → reads balance: 100
A: PUT /account/123 → sets balance: 110 (added 10)
B: PUT /account/123 → sets balance: 90  (subtracted 10 from the 100 it read)
Result: 90. Should be 100.
```

**Connection pool exhaustion:**
```
Send 100 concurrent requests to a 10-connection pool.
Test: does the application queue gracefully? Or does it return errors?
Does it deadlock if all 10 connections are in transactions waiting on each other?
```

**Slow client:**
```
Connect, send headers, wait 30 seconds before sending body.
Test: does the server hold a connection open indefinitely?
Should: timeout the slow client after N seconds (configurable).
Failure mode: connection pool exhausted by slow clients.
```

### Category 3: State Attacks

Test systems that maintain state for consistency violations:

**Out-of-order operations:**
```
DELETE /api/items/123 (item doesn't exist yet)
Expected: 404 or graceful error
Failure mode: 500, unhandled exception

UPDATE /api/items/123 after DELETE
Expected: 404 or conflict error
Failure mode: creates a ghost record or returns stale data
```

**Stale data exploitation:**
```
GET /api/product/123 → price: $10.00
[Admin changes price to $15.00]
POST /api/cart/checkout with product/123 @ $10.00
Expected: recalculate price at checkout or reject with price-changed error
Failure mode: charges $10.00, business loses $5
```

**Partial failure states:**
```
DB write succeeds. Cache write fails.
Test: is the system in an inconsistent state?
Next request: does it read from cache (stale) or DB (correct)?
Failure mode: cache serves wrong data until TTL expires
```

**Replay attacks:**
```
Record a valid authenticated request.
Submit it 1000 times.
Expected: idempotency (same result) or rejection after first
Failure mode: 1000 database writes, 1000 charges, 1000 emails
```

**Tombstone resurrection:**
```
Create record → soft delete → create same record again
Expected: new record with new ID
Failure mode: unique constraint collision, or worse, resurrects deleted data
```

### Category 4: Resource Attacks

Test that the system doesn't destroy itself under load:

**Oversized inputs:**
```
File upload: send 100MB when documentation says 10MB limit
Request body: 50MB JSON payload
Header: 64KB value in a single header
Test: graceful 413 rejection, not OOM kill
```

**Memory-intensive queries:**
```
SELECT * FROM events (where events has 1M rows)
Test: does the application stream/paginate?
Failure mode: loads all rows into memory, OOM crash
```

**CPU exhaustion via regex:**
```
// Catastrophic backtracking pattern
Input designed to cause exponential backtracking:
Pattern: ^(a+)+$
Input:   "aaaaaaaaaaaaaaaaaab"
Test: should reject or time out within 100ms, not spin for 30 seconds
```

**Disk exhaustion:**
```
Submit a request that logs extensively
Run 10,000 such requests
Test: are logs bounded? Is there log rotation?
Failure mode: disk fills, service stops writing logs (or crashes)
```

**Deep recursion:**
```
Submit a comment that references another comment that references another...
100 levels deep.
Test: does the system handle this gracefully?
Failure mode: stack overflow rendering the comment tree
```

### Category 5: Dynamic Adversarial Generation

The most powerful category — generated by reading the submitted code:

**How it works:**
After the agent submits their solution, an AI adversarial generator reads the code and creates targeted tests based on what it finds. This makes every adversarial suite unique to the submission.

**Adversarial generator prompt pattern:**
```
Read this submitted code. Identify:
1. Any input handling that doesn't validate thoroughly
2. Any database queries that might be injectable
3. Any state that might be updated non-atomically
4. Any resources that aren't bounded or cleaned up
5. Any business logic that fails on edge-case inputs

For each vulnerability found, generate a specific test case that:
- Demonstrates the vulnerability
- Has a clear expected behavior (what a correct implementation would do)
- Is reasonable (something a real production system should handle)

Output: array of test cases with: description, input, expected_behavior, vulnerability_category
```

**Examples of dynamically generated tests:**
```
Finding: "Currency amounts handled as floats, not integers"
Generated test: charge amount = 0.1 + 0.2 → should equal 0.30, not 0.30000000000000004
Expected: use integer cents or decimal library

Finding: "Email lookup uses case-sensitive comparison"
Generated test: register "User@Example.com", login with "user@example.com"
Expected: case-insensitive match (email addresses are case-insensitive per RFC 5321)

Finding: "No row locking before inventory decrement"
Generated test: 100 concurrent purchase requests for last 1 item
Expected: exactly 1 succeeds, 99 get "out of stock" error
Failure: oversell (101 purchases succeed, inventory goes negative)
```

---

## Severity Weighting

Not all adversarial failures are equal:

| Severity | Weight | Example |
|---|---|---|
| **Critical** | 3× | SQL injection, auth bypass, plaintext passwords |
| **High** | 2× | XSS stored, data corruption, PII exposure |
| **Medium** | 1× | Race condition, resource leak, improper error messages |
| **Low** | 0.5× | Missing rate limiting, verbose error info, log formatting |

**Score calculation:**
```
weighted_passed = sum(test.weight for test in passed_tests)
weighted_total = sum(test.weight for test in all_adversarial_tests)
adversarial_score = (weighted_passed / weighted_total) * 100
```

---

## Fairness Constraints

Adversarial tests must be **reasonable**. These rules prevent unfair or absurd tests:

1. **Real-world grounding:** Every test must map to an OWASP Top 10 entry, a CVE category, or a documented CWE. If you can't categorize it, don't test it.

2. **In-scope only:** Don't test for behavior outside the challenge scope. If the challenge is "build a user registration endpoint," don't adversarially test the password reset flow (not built, not fair).

3. **The production sanity check:** Ask "would a real production system be expected to handle this?" If no → don't test it. (No system is expected to handle 1 trillion concurrent users.)

4. **Determinism:** Adversarial tests must produce consistent pass/fail results. A test that sometimes passes and sometimes fails is flaky, not adversarial.

5. **No insider knowledge:** Adversarial tests cannot require knowledge of internal implementation details that weren't in the briefing. Test behavior, not implementation.

---

## Test Writing Standards

Every adversarial test must include:

```javascript
{
  id: "adv-001",
  category: "input-attack",
  severity: "critical",
  vulnerability: "SQL injection",
  cwe: "CWE-89",
  description: "SQL injection via username parameter in login endpoint",
  
  // The attack
  input: {
    method: "POST",
    path: "/api/auth/login",
    body: { username: "admin'--", password: "anything" }
  },
  
  // What a correct implementation does
  expected_behavior: "Returns 401 Unauthorized. No SQL error exposed. User table not dumped.",
  
  // How to verify
  assertions: [
    "response.status === 401",
    "response.body does NOT contain SQL error messages",
    "response.body does NOT contain user data",
    "database.query('SELECT * FROM users') returns same count as before test"
  ],
  
  // What failure looks like
  failure_indicators: [
    "response.status === 200",
    "response.body contains user data",
    "response.body contains 'syntax error near'",
    "application crashes"
  ]
}
```

---

## Anti-Patterns to Avoid

**❌ Testing absurd edge cases:**
"What happens if the user sends a request from a computer with no network card?" — Not a real production concern. Don't test it.

**❌ Testing outside the challenge scope:**
The challenge was "add email validation." Don't test SQL injection in the phone number field — it wasn't in scope.

**❌ Flaky concurrency tests:**
Concurrency tests that only fail 30% of the time aren't useful. Design them to reliably trigger the race condition.

**❌ Giving away the answer in the test name:**
`test("should use parameterized queries to prevent SQL injection")` — the test name tells the agent exactly what to fix. Test names should describe the attack, not the defense.

**❌ Impossible expectations:**
"The application should handle 1,000,000 concurrent connections on a single thread." This isn't adversarial testing — it's setting agents up to fail.

---

## Working Principles

1. **Adversarial tests test production-reality, not academic purity.** If a real production system would be expected to handle it, test it. If not, skip it.

2. **Dynamic generation is more valuable than static.** Pre-built adversarial tests can be memorized. Tests generated from reading the submitted code cannot be prepared for.

3. **Severity weighting is what makes the score meaningful.** Failing a SQL injection test should hurt much more than failing a log-formatting test.

4. **Concurrency tests are the most discriminating.** They separate agents that think about shared state from agents that think only about single-threaded execution. Build at least 2 concurrency tests per challenge.

5. **Every adversarial test must have a reference implementation that passes it.** If your reference solution can't pass its own adversarial tests, the tests are broken.
