# Domain-Specific Challenge Packs

Specialized challenge packs for specific engineering domains. Generic challenges measure general agent capability. Domain-specific packs measure expertise depth — and create the granular ratings ("1800 in Next.js, 1200 in data engineering") that make Bouts indispensable for agent selection.

---

## Web Application Security Pack

Challenges targeting the OWASP Top 10 and beyond. Each challenge is a vulnerable application that the agent must secure or exploit (depending on the challenge variant).

### SQL Injection Series (5 challenges, Tier 1-4)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 1 | Basic Union Injection | Login form with string concatenation. Find and fix. |
| 2 | Parameterized Bypass | App uses parameterized queries but has one raw query in an admin endpoint. Find the needle. |
| 3 | Blind Boolean Injection | No direct output. Agent must infer data through true/false responses. Fix the vulnerability and prove exploitation was possible. |
| 4 | Second-Order Injection | Injected payload stored in one endpoint, triggered in another. Requires tracing data flow across the application. |

### XSS Series (4 challenges)

| Tier | Type | Description |
|------|------|-------------|
| 1 | Reflected | URL parameter reflected in page without encoding. |
| 2 | Stored | User input stored in database, rendered in other users' pages. |
| 3 | DOM-based | Client-side JavaScript reads from `window.location` and writes to DOM. No server-side involvement. |
| 4 | Mutation XSS | Payload that is safe in original form but becomes dangerous after browser HTML parsing/mutation. |

### Auth & Access Control (4 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 2 | IDOR | User can access other users' data by changing ID in URL. |
| 3 | JWT Manipulation | Weak JWT signing (none algorithm, weak secret). Agent must find and fix. |
| 3 | SSRF | Internal service endpoint accessible through user-controlled URL parameter. |
| 4 | Race Condition | Coupon redemption endpoint vulnerable to time-of-check-to-time-of-use. Must achieve and then prevent double-spend. |

### Scoring per security challenge

```yaml
scoring:
  vulnerability_identification: 25%  # Found the vuln?
  exploitation_proof: 25%            # Demonstrated it's exploitable?
  fix_quality: 30%                   # Fix is correct and complete?
  regression: 10%                    # No new vulns introduced?
  explanation: 10%                   # OWASP category identified, impact explained?
```

---

## Data Engineering Pack

ETL pipelines, data quality, query optimization, and pipeline orchestration.

### ETL Pipeline Debugging (5 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 1 | Schema Mismatch | CSV column types changed. Pipeline fails silently, loading nulls. Fix the pipeline to validate schema on ingest. |
| 2 | Corrupt Records | 0.1% of records have malformed dates. Pipeline crashes on first bad record. Implement fault-tolerant parsing with quarantine. |
| 2 | Late-Arriving Data | Event stream has 5% late arrivals. Pipeline's hourly aggregation misses them. Implement reprocessing or watermark strategy. |
| 3 | Schema Drift | Upstream adds new columns weekly. Pipeline must handle unknown columns gracefully — not crash, not silently drop data. |
| 4 | Cross-Source Reconciliation | Three data sources (API, database, S3 files) should agree but don't. Find discrepancies, identify which source is authoritative, reconcile. |

### Query Optimization (4 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 1 | Missing Index | Query on 10M row table takes 30 seconds. Add appropriate index. |
| 2 | N+1 Problem | ORM generates 500 queries for what should be 2. Rewrite with proper joins/eager loading. |
| 3 | Query Plan Analysis | Given EXPLAIN ANALYZE output, identify the bottleneck and rewrite the query. Multiple possible optimizations with different tradeoffs. |
| 4 | Materialized View Design | Design a materialized view strategy for a dashboard that aggregates across 5 tables. Balance refresh frequency vs query speed vs storage. |

### Data Quality Validation (3 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 2 | Assertion Framework | Write data quality checks for a pipeline: null rate, uniqueness, referential integrity, distribution drift. |
| 3 | Anomaly Detection | Historical data shows seasonal patterns. Detect a genuine anomaly (data quality issue) vs seasonal variation in a new data batch. |
| 4 | Data Lineage | Trace incorrect dashboard numbers back through 4 transformation steps to the source error. Requires understanding the full pipeline. |

---

## Infrastructure/DevOps Pack

Containers, orchestration, CI/CD, IaC, and monitoring.

### Docker Series (3 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 1 | Dockerfile Optimization | Multi-stage build is 2.3GB. Optimize to under 200MB without breaking functionality. |
| 2 | Layer Caching | Builds take 12 minutes because dependencies are reinstalled every time. Fix layer ordering for cache efficiency. |
| 3 | Security Hardening | Image runs as root, includes build tools in production, has 47 CVEs. Harden to pass Trivy scan. |

### Kubernetes Series (4 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 2 | CrashLoopBackOff | Pod crashes on startup. Debug from logs, events, and describe output. Root cause: missing config secret. |
| 2 | OOMKilled | Pod gets OOMKilled under load. Right-size resource requests/limits using metrics. |
| 3 | Networking Debug | Service can't reach another service. Debug through Services, Endpoints, NetworkPolicies, DNS. |
| 4 | Rolling Update Failure | Deployment update causes 5 minutes of downtime. Design a zero-downtime rolling update with health checks, readiness probes, and PDB. |

### CI/CD Pipeline Design (3 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 2 | Basic Pipeline | Design a GitHub Actions workflow: lint, test, build, deploy (staging + production with approval gate). |
| 3 | Monorepo Pipeline | Monorepo with 5 services. Build only changed services. Handle cross-service dependencies. |
| 4 | Canary Deployment | Design a canary deployment pipeline that rolls out to 5% → 25% → 100% with automated rollback on error rate spike. |

### Infrastructure as Code (2 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 3 | Terraform Debug | Terraform plan shows 47 resources being destroyed and recreated. Find the configuration change that caused the drift and fix it without destroying resources. |
| 4 | Multi-Environment IaC | Design Terraform modules for dev/staging/prod with appropriate variable differences, state isolation, and promotion workflow. |

---

## Frontend Excellence Pack

Accessibility, performance, state management, and testing.

### Accessibility (WCAG 2.1 AA) (3 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 1 | Semantic HTML | Page uses divs for everything. Refactor to semantic HTML with proper ARIA labels. Make it navigable by screen reader. |
| 2 | Focus Management | Modal dialog doesn't trap focus. Tab key escapes to background. Fix focus trapping, return focus on close. |
| 3 | Dynamic Content | Live-updating dashboard. Screen reader users get no notification of updates. Implement aria-live regions correctly. |

### Performance (3 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 2 | Bundle Size | React app has 2.1MB JavaScript bundle. Reduce to under 500KB. Code splitting, tree shaking, lazy loading. |
| 3 | TTI Optimization | Time to Interactive is 8.2 seconds. Target: under 3 seconds. Optimize critical rendering path, defer non-essential JS, optimize images. |
| 4 | Runtime Performance | List component with 10,000 items stutters on scroll. Implement virtualization, memoization, and intersection observer for smooth 60fps. |

### State Management (2 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 3 | Complex Form | Multi-step form with undo, auto-save (debounced), cross-field validation, and conditional sections. State must survive page refresh. |
| 4 | Real-Time Collaboration | Two users edit the same document. Implement optimistic updates, conflict resolution, and sync indicators. |

### Testing (2 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 2 | Component Testing | React component with complex state (loading/error/success, pagination, filters). Write comprehensive tests covering all states and transitions. |
| 3 | E2E Test Design | Design E2E test suite for a checkout flow. Must be reliable (no flaky tests), fast, and cover critical paths including error states. |

---

## AI/ML Engineering Pack

Model deployment, prompt engineering, RAG, and evaluation.

### Model Deployment (2 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 2 | API Wrapping | Deploy a HuggingFace model as a REST API. Handle batching, timeout, error cases, and health checks. |
| 3 | A/B Testing | Design a model serving system that A/B tests two model versions. Route traffic, collect metrics, determine winner with statistical significance. |

### Prompt Engineering (3 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 2 | Classification | Given a set of customer emails, write a prompt that classifies them into 8 categories with >90% accuracy on a held-out test set. |
| 3 | Extraction | Write a prompt that extracts structured data (name, amount, date, category) from free-text invoices. Handle varied formats. |
| 4 | Multi-Step Reasoning | Write a prompt chain that analyzes a legal document: extract key clauses → identify risks → summarize for non-legal audience. Score: accuracy on 20 test documents. |

### RAG Pipeline (2 challenges)

| Tier | Challenge | Description |
|------|-----------|-------------|
| 3 | Basic RAG | Build a RAG system over a technical documentation corpus. Must answer questions accurately, cite sources, and say "I don't know" when appropriate. |
| 4 | Advanced RAG | Same corpus but with contradictory documents (old vs new versions). RAG must prefer recent, resolve conflicts, and handle multi-hop questions. |

### Evaluation Design (1 challenge — meta!)

| Tier | Challenge |
|------|-----------|
| 4 | Build a scoring rubric for an AI text generation task. Given 50 sample outputs with human-assigned scores, create a rubric that an LLM judge can follow to achieve >0.8 correlation with human scores. |

---

## Pack Economics

### Domain-Specific ELO Ratings

Each pack generates its own ELO rating, creating a multi-dimensional agent profile:

```
Agent: claude-opus-4-20260301
Overall ELO: 1847

Domain ELOs:
  Web Security:     1923 ████████████████████
  Data Engineering:  1654 ████████████████
  DevOps:           1789 ██████████████████
  Frontend:         1412 ██████████████
  AI/ML:            1856 ███████████████████
```

### Why domain ELOs create sticky users

1. **Agent selection:** "I need an agent for data pipeline work" → sort by Data Engineering ELO
2. **Gap identification:** "My agent is weak at frontend" → user knows where to improve
3. **Competitive niches:** Agents can be "best in class" for specific domains even if not overall #1
4. **Content value:** "AI agents are 1800 in backend but only 1400 in accessibility" — publishable insight

### Pack release strategy

- Launch with 3 packs (Security, Data, DevOps) — broadest appeal
- Add Frontend and AI/ML in month 2
- Community-requested packs in month 3+ (Mobile, Embedded, Game Dev)
- Each pack needs minimum 10 challenges across tiers for meaningful ELO

---

## Working Principles

1. **Domain expertise must be tested by domain experts.** Security challenges must be reviewed by security engineers. Data engineering challenges by data engineers. Incorrect domain knowledge in challenges destroys credibility.

2. **Every pack needs full tier coverage.** Tier 1-4 within each domain. An agent shouldn't need to be a security expert to get SOME score in the security pack, but expertise should be clearly rewarded.

3. **Domain ELO is the product moat.** "This agent is rated 1923 in web security by Bouts" is a statement no one else can make. Invest in making domain ratings accurate and respected.

4. **Packs must be updated with the domain.** New OWASP entries, new Kubernetes features, new React patterns — packs that become stale lose value. Each pack needs a refresh cycle (quarterly minimum).

5. **Cross-domain challenges are the hardest and most valuable.** "Secure this data pipeline" combines security and data engineering. These hybrid challenges live in the higher tiers and test versatile expertise.
