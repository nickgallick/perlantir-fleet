# Common Attack Scenarios — Quick Reference

## Authentication Attacks
- Brute force login (no rate limiting)
- Credential stuffing (reused passwords from breaches)
- Session fixation (predictable session IDs)
- JWT algorithm confusion (none algorithm accepted)
- Token theft via XSS → stored cookie access
- OAuth redirect manipulation

## Authorization Attacks
- IDOR (Insecure Direct Object Reference) — change ?id=123 to ?id=456
- Privilege escalation — change role field in request
- Missing function-level access control — admin endpoints without admin check
- Parameter pollution — send role=admin in the request body

## Data Attacks
- SQL injection (even through ORMs — check raw queries)
- NoSQL injection (MongoDB operator injection)
- XSS (reflected, stored, DOM-based)
- CSRF (state-changing requests without CSRF token)
- SSRF (server makes requests to attacker-controlled URLs)
- File upload attacks (webshell, polyglot files, path traversal)

## Business Logic Attacks
- Race conditions (double spend, double vote, double redeem)
- Negative quantity/amount (buy -1 items = get money)
- Integer overflow (max_int + 1 = negative)
- Floating point precision (0.1 + 0.2 ≠ 0.3)
- State machine bypass (skip steps in a workflow)
- Time manipulation (expired coupon still works due to timezone)

## Infrastructure Attacks
- DNS rebinding
- Host header injection
- Cache poisoning
- Dependency confusion (npm package name squatting)
- Environment variable leakage in error pages
- Debug endpoints left enabled in production

## Competitive Platform Attacks

### Score Manipulation
- **Judge prompt injection:** Embedding instructions in submissions to manipulate AI judge scores. Likelihood: High. Impact: Critical. Detection: Pre-judge injection scanner + cross-judge divergence detection. Prevention: Submission as document attachment, structured output, injection-aware system prompt.
- **Vote fraud (Sybil):** Creating multiple accounts to vote for own submission. Likelihood: High. Impact: Medium. Detection: Temporal clustering, account age analysis, vote pattern correlation. Prevention: GitHub OAuth, account age requirement, activity threshold for voting.
- **ELO manipulation (sandbagging):** Intentionally losing to lower ELO, then farming easy wins. Likelihood: Medium. Impact: Medium. Detection: Win/loss streak analysis, bimodal performance distribution. Prevention: Minimum ELO floor by model class.
- **Win trading:** Two accounts colluding to boost one's ELO. Likelihood: Low. Impact: Medium. Detection: Pair frequency analysis, shared IP detection. Prevention: Random matchmaking, pair limits.

### Identity Fraud
- **Smurfing:** Champion creates new account to dominate lower tiers. Likelihood: Medium. Impact: Low. Detection: New account with Diamond-level performance immediately. Prevention: Placement matches, config similarity detection.
- **Multi-accounting:** One person running multiple agents to manipulate brackets. Likelihood: Medium. Impact: High. Detection: Shared gateway URL, IP correlation, config similarity. Prevention: Gateway URL limits, GitHub OAuth.
- **Weight class misrepresentation:** Declaring Llama 8B but routing to Opus. Likelihood: High. Impact: Critical. Detection: Output-weighted MPS, response timing, transcript model verification. Prevention: Per-call model logging, MPS calculated post-challenge.

### Economic Attacks
- **Coin duplication:** Exploiting race conditions in coin transactions. Likelihood: Low. Impact: Critical. Detection: Transaction audit, balance reconciliation. Prevention: Balance changes only via Postgres function with proper locking.
- **Negative balance exploitation:** Spending more coins than available via concurrent requests. Likelihood: Low. Impact: High. Detection: Balance check failures in logs. Prevention: `CHECK (balance >= 0)` constraint, function-level validation.
- **Entry fee refund abuse:** Entering challenges, withdrawing after seeing competition, requesting refund. Likelihood: Medium. Impact: Medium. Detection: Refund frequency tracking. Prevention: No refunds after challenge starts, rate limit refund requests.

### Content Attacks
- **Malicious submissions:** Code that attacks the judge, the platform, or other users. Likelihood: Medium. Impact: High. Detection: Static analysis, sandbox monitoring. Prevention: Sandboxed execution, network isolation for code eval.
- **NSFW content in challenges:** Inappropriate content in user-created challenges or submissions. Likelihood: Medium. Impact: Medium. Detection: Content moderation AI scan. Prevention: Pre-publish review for community challenges, automated content filtering.
- **IP theft from replays:** Copying innovative agent configurations visible in public transcripts. Likelihood: High. Impact: Low. Detection: Not easily detectable. Prevention: Accept as inherent to open competition. Allow agents to mark reasoning as private (excluded from public replay).

### Infrastructure Attacks
- **DoS on challenge start:** Overwhelming the orchestrator at challenge launch. Likelihood: Medium. Impact: High. Detection: Connection rate spikes, orchestrator health monitoring. Prevention: Staggered connection starts, circuit breakers, connection queuing.
- **Connection flooding:** Opening hundreds of WebSocket connections to exhaust resources. Likelihood: Medium. Impact: High. Detection: Per-IP/per-user connection count monitoring. Prevention: Connection limits, rate limiting.
- **Spectator feed abuse:** Injecting messages into spectator channels. Likelihood: Low. Impact: Medium. Detection: Unauthorized write attempts in logs. Prevention: Read-only Realtime channels with RLS, private channel mode.

### Social Attacks
- **Harassment via challenge names:** Offensive or targeted challenge titles. Likelihood: Medium. Impact: Medium. Detection: Content moderation, community reports. Prevention: Pre-publish content filtering, report system.
- **Targeted win-trading against specific users:** Collusion to ensure a specific user always loses. Likelihood: Low. Impact: Medium. Detection: Pattern analysis of who loses to whom. Prevention: Random matchmaking.
- **Community manipulation:** Organizing off-platform groups to mass-vote or mass-report. Likelihood: Medium. Impact: High. Detection: Coordinated action patterns (same timing, same targets). Prevention: Vote weight based on participation history, rate-limited reporting.
