# Real-World Scenario Research

Finding and converting real engineering incidents, vulnerabilities, and problems into Bouts challenge templates. Real-world grounding is what gives challenges face validity — and face validity is what makes the Bouts Score credible.

---

## Why Real-World Sources

A challenge based on "I made up a bug" is recognizable. It feels academic. It doesn't create the same urgency as "this exact class of bug took down Cloudflare for 27 minutes."

Real-world scenarios provide:
- **Authenticity:** The narrative feels real because it is real (adapted)
- **Validation:** If a real engineer was defeated by this, it's a legitimate challenge
- **Surprise:** Real incidents often involve unexpected interactions between systems
- **Calibration:** Real incident resolution approaches validate our reference solutions
- **Content:** The backstory enriches the narrative

---

## Primary Research Sources

### Tier 1: Postmortem Databases

High-quality engineering postmortems with root cause analysis:

| Source | What's there | URL |
|---|---|---|
| danluu/post-mortems | Curated list of 200+ public postmortems | github.com/danluu/post-mortems |
| Google SRE Book | Chapter-length incident analyses | sre.google/sre-book/example-postmortem |
| Cloudflare Blog | Detailed technical outage analyses | blog.cloudflare.com (tag: outage) |
| GitHub Engineering | GitHub's own incident analyses | github.blog/tag/incident |
| Stripe Blog | Payment infrastructure incidents | stripe.com/blog/tag/engineering |
| Discord Engineering | High-scale systems incidents | discord.com/blog (tag: engineering) |
| PagerDuty Blog | SRE postmortem examples | pagerduty.com/blog/tag/postmortem |

**Best postmortems for challenges:** Those with clear root cause, observable symptoms, and non-obvious fix. Avoid: incidents where the fix was "upgrade the software" — too trivial.

### Tier 2: Vulnerability Databases

Real security vulnerabilities → security challenge templates:

| Source | What's there |
|---|---|
| CVE database (cve.mitre.org) | All published vulnerabilities |
| HackerOne Hacktivity | Disclosed bug bounty reports |
| OWASP Top 10 | Categorized web vulnerabilities |
| Snyk Vulnerability DB | Package-level vulnerabilities |
| NVD (nvd.nist.gov) | National vulnerability database with CVSS scores |

**Best vulnerability sources for challenges:** HackerOne disclosed reports are gold — they include the exact reproduction steps, which becomes the adversarial test case.

### Tier 3: Developer Q&A

Real bugs real developers faced:

| Source | What's there |
|---|---|
| Stack Overflow | Most-voted debugging questions |
| GitHub Issues | Real bugs on major open-source projects |
| Reddit /r/programming | Incident discussions with community analysis |
| Hacker News | Technical postmortems in comments |
| Dev.to | Engineering blogs with debugging stories |

---

## The Conversion Pipeline

### Step 1: Read the Incident

Read the full postmortem or bug report. Focus on:
- What were the observable symptoms?
- What was the root cause?
- What made it hard to find?
- What red herrings were investigated before finding the real cause?
- What prevented it from being caught earlier?

### Step 2: Extract the Core Engineering Problem

Strip away company-specific details. What remains is the transferable problem:

**Example — Cloudflare 2019 Regex Outage:**
- Actual: Cloudflare's WAF used a regex with catastrophic backtracking on certain payloads → CPU hit 100% → traffic dropped 82% globally
- Core problem: Regex with polynomial/exponential backtracking behavior, not caught in performance testing

**Example — GitHub 2012 MySQL Replication Issue:**
- Actual: GitHub's primary MySQL server had schema drift from replica → replication broke → read queries hitting primary → cascade
- Core problem: Schema drift between primary and replica not detected until failure

### Step 3: Generate Synthetic Codebase

Create a codebase that has the analogous problem without being the actual company's code:

```python
def generate_from_incident(incident):
    codebase = generate_working_codebase(
        framework=select_appropriate_framework(incident.tech_stack),
        domain=select_different_domain(incident.company_domain),  # Different domain, same problem
        scale=incident.scale_tier
    )
    
    # Introduce the analogous bug (not the exact code, the same category of bug)
    bug = translate_incident_to_bug(incident.root_cause)
    codebase = plant_bug(codebase, bug)
    
    # Briefing uses the SYMPTOMS from the real incident
    briefing = write_briefing(
        hook=incident.observable_symptoms,  # What was visible
        context=generated_system_context,
        already_tried=incident.red_herrings  # What was investigated first
    )
    
    return codebase, briefing
```

**The key translation rule:** The briefing describes symptoms, not causes. The symptoms can be drawn directly from the real incident. The cause must be discovered by the agent.

### Step 4: Add Red Herrings from the Real Incident

Real incidents almost always involved investigating red herrings before finding the root cause. These become the planted red herrings in the challenge:

**Cloudflare regex example:**
- Real investigation: engineers first looked at traffic patterns, then at rule triggers, then at individual rules — before finding the CPU-exhausting regex
- Challenge red herrings: high-traffic route handler (suspicious but fine), overly complex middleware chain (slow but not the problem), a database query that looked expensive (it is slow, but not catastrophically so)

### Step 5: Validate Reference Solution

The real-world resolution approach validates our reference solution. If the real engineers fixed it with approach X, and our reference solution uses approach Y, something is wrong — either our bug isn't quite right, or our reference solution is suboptimal.

---

## High-Value Incident Classes for Challenges

### Class 1: Timezone/DST Disasters

Perfect for "The Time Traveler" template. Endlessly variable, always surprising, frequently catastrophic in production.

**Real examples:**
- Services that billed users twice when clocks fell back
- Scheduled jobs that ran twice or not at all at DST transitions
- "End of month" logic that broke on February 29th
- Log correlation failures because frontend and backend in different timezones

**Challenge conversion:** Payment systems, scheduling systems, audit logs — any domain with time-sensitive logic.

### Class 2: Race Conditions in High-Traffic Systems

Perfect for concurrency challenges. The symptom is intermittent. The cause is invisible in single-threaded tests.

**Real examples:**
- Double-charge bugs: payment processed twice because checkout submitted twice within 100ms
- Inventory oversell: last item purchased by two users simultaneously
- Duplicate account creation: same email registered twice in parallel

**Challenge conversion:** Any transactional system with shared state.

### Class 3: Regex Catastrophic Backtracking

Perfect for "The Performance Cliff" template. Works fine in dev. Falls apart under specific production inputs.

**Real examples:**
- Cloudflare 2019 (the canonical example)
- Input validation using ReDoS-vulnerable patterns
- Email validation regexes that hang on malformed addresses

**Challenge conversion:** Any input validation middleware, any search/filter feature.

### Class 4: N+1 Query Problems

Perfect for performance challenges. Common in every ORM. Often not caught until production scale.

**Real examples:**
- GraphQL resolvers making 1 query per item in a list
- REST endpoints that load related records one-by-one
- Admin dashboards that become unusable at 10k+ records

**Challenge conversion:** Any list endpoint, any admin view, any GraphQL resolver.

### Class 5: Cache Invalidation Failures

Perfect for stale data challenges. "There are only two hard things in CS..."

**Real examples:**
- Users seeing other users' cached data after profile updates
- Price caches not invalidated after admin price changes
- Session caches returning stale permissions after role changes

**Challenge conversion:** Any cached resource that can be modified.

---

## The 7 Research Repos to Clone

These repos provide deep technical knowledge for challenge generation:

```bash
# 1. Testing patterns — for generating quality test suites
git clone https://github.com/goldbergyoni/javascript-testing-best-practices

# 2. Integration test design — for generating integration tests
git clone https://github.com/testjavascript/nodejs-integration-tests-best-practices

# 3. Fuzzing techniques — for adversarial test generation
git clone https://github.com/google/fuzzing

# 4. Security scanning rules — for security challenge test suites
git clone https://github.com/semgrep/semgrep-rules

# 5. Security vulnerability patterns — for adversarial challenges
git clone https://github.com/OWASP/CheatSheetSeries

# 6. Real-world sysadmin problems — for scenario inspiration
git clone https://github.com/trimstray/the-book-of-secret-knowledge

# 7. System design patterns — for architecture/design challenges
git clone https://github.com/donnemartin/system-design-primer
```

**How to use each repo:**
- `javascript-testing-best-practices`: reference for test structure and edge case coverage in static test suites
- `nodejs-integration-tests-best-practices`: patterns for integration test design in challenge test suites
- `fuzzing`: techniques for the adversarial test generation pipeline (what to fuzz, how to structure fuzzing campaigns)
- `semgrep-rules`: ready-made security scanning rules for the security scoring component
- `CheatSheetSeries`: OWASP vulnerability patterns → adversarial test cases for security challenges
- `the-book-of-secret-knowledge`: real-world operational problems for scenario inspiration
- `system-design-primer`: architecture patterns and tradeoffs for design challenge templates

---

## Research Logging Protocol

After each research session, log:

```markdown
## Research Log: [DATE]

**Source:** [URL or document title]
**Incident/topic:** [Brief description]

**Core engineering problem extracted:**
[The transferable, company-agnostic problem statement]

**Observable symptoms (for briefing hook):**
[What would an engineer see when this occurs]

**Red herrings from real investigation:**
[What was investigated before finding root cause]

**Root cause:**
[The actual cause — becomes the planted bug]

**Reference solution approach:**
[How it was actually fixed]

**Challenge template concept:**
- Template type: [Debugging/Greenfield/Refactoring/etc.]
- Target tier: [1/2/3/4]
- Framework variables: [what frameworks this applies to]
- Failure modes targeted: [from the 15 failure modes]

**Status:** [Concept / In-development / Ready for QA / Live]
```

---

## Working Principles

1. **Symptoms go in the briefing. Causes stay hidden.** The entire value of a real-world scenario is that the agent has to discover the root cause, just like the real engineers did.

2. **Red herrings from the real incident are pure gold.** Real engineers investigated the wrong things before finding the real problem. Those wrong paths become the challenge's red herrings. They're realistic because they were real.

3. **Change the domain, keep the problem.** A Cloudflare regex incident becomes an API gateway challenge for a fictional e-commerce company. The problem class is the same. The specifics are fresh.

4. **Validate reference solutions against the real fix.** If the real engineers fixed it with approach X and our reference solution uses approach Y, question why. The real engineers had full context we don't.

5. **Build the research habit.** One good postmortem per week generates 52 potential challenge concepts per year. Some will be gold, most will be good, a few will be unusable. That's a fine ratio.
