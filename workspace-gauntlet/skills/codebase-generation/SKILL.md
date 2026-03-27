# Codebase Generation

> Gauntlet Foundation Skill 4 of 15

The complete pipeline for generating realistic, contamination-free codebases that serve as the foundation for every Bouts challenge.

---

## Why Generated Codebases (Not Open Source)

Open-source repositories are poisoned for evaluation purposes:

1. **Memorization risk:** LLMs have seen popular GitHub repos during training. An agent that "solves" a Next.js bug it memorized from the React repo isn't demonstrating skill.
2. **Planted bugs:** We need precise control over what's broken and how. Real repos have unknown bugs that interfere with scoring.
3. **Version control:** Real repos evolve. A challenge based on commit `abc123` might not work after the next merge.
4. **Copyright:** Generated code has no licensing issues. We own it fully.
5. **Difficulty control:** We can tune exactly how hard the codebase is to understand, navigate, and modify.

**The tradeoff:** Generated code must feel REAL. If it feels synthetic ("FooService", "doThing"), agents may behave differently than they would on production code. Realism is non-negotiable.

---

## The 5-Step Generation Pipeline

### Step 1: Architecture Template Selection

Select three dimensions:

**Framework stack** (what technologies):
```
Node.js ecosystem:
  - Express + PostgreSQL + Redis
  - Fastify + MongoDB + Redis
  - Next.js (App Router) + Prisma + PostgreSQL
  - Hono + SQLite + Redis
  - NestJS + TypeORM + PostgreSQL

Python ecosystem:
  - FastAPI + SQLAlchemy + PostgreSQL
  - Flask + SQLite + Redis
  - Django + PostgreSQL + Celery

TypeScript ecosystem:
  - All Node.js stacks with TypeScript
  - Deno + Oak + PostgreSQL

Go ecosystem:
  - Gin + GORM + PostgreSQL
  - Chi + sqlx + PostgreSQL

Rust ecosystem:
  - Actix-web + Diesel + PostgreSQL
  - Axum + SQLx + PostgreSQL
```

**Application domain** (what it does):
```
E-commerce:        Products, carts, orders, payments, inventory
Social platform:   Users, posts, comments, likes, follows, feed
Project management: Projects, tasks, sprints, assignments, status
Fintech:           Accounts, transactions, balances, transfers, audit
Logistics:         Shipments, routes, tracking, warehouses, inventory
Healthcare-adjacent: Appointments, records, notifications, scheduling
SaaS analytics:    Events, dashboards, reports, exports, alerts
Notification system: Templates, channels, preferences, delivery, retry
Auth service:      Users, roles, permissions, sessions, tokens, MFA
Inventory system:  Products, locations, movements, counts, alerts
```

**Scale** (how big):
```
Tier 0-1: Small (5-15 files, 1-3 models, simple routes)
Tier 2:   Medium (15-30 files, 4-8 models, middleware, services)
Tier 3:   Large (30-50 files, 8-15 models, multi-layer architecture)
Tier 4:   XL (50-100+ files, 15+ models, multi-service)
```

### Step 2: Generate Working Codebase

The codebase must be WORKING before any challenge elements are planted. This means:

**Functional requirements:**
- Application starts without errors
- All routes/endpoints respond correctly
- Database schema is valid and seeded with realistic data
- Tests pass (the pre-challenge test suite)
- Dependencies install cleanly

**Realism requirements:**

The code must look like it was written by a real team over time:

```
Intentional imperfections (REQUIRED):
- Inconsistent naming (camelCase in some files, snake_case in others)
- 3-5 TODO comments ("TODO: refactor this", "FIXME: handle edge case")
- 1-2 commented-out code blocks (previous implementation attempts)
- Varying comment density (some files well-documented, some sparse)
- 1-2 unused imports or variables
- Mixed async patterns (callbacks in old code, async/await in new code)
- Slightly outdated dependency versions (not latest, not ancient)
```

**Project artifacts (REQUIRED):**
```
README.md          — Project description, setup instructions, API docs
package.json       — Realistic scripts (dev, build, test, lint)
.env.example       — Environment variable template
.gitignore         — Standard gitignore for the stack
tsconfig.json      — If TypeScript (realistic compiler options)
docker-compose.yml — If database required
.eslintrc          — Linting config (with some rules disabled)
```

**Realistic git history (OPTIONAL, Tier 2+):**
```
Initial commit with scaffolding
Feature commits (1-2 per major feature)
A "fix typo" commit
A merge commit
A "refactor: clean up X" commit
The most recent commit is the one that "introduced" the challenge element
```

### Step 3: Plant Challenge Element

Depending on challenge type:

**For debugging challenges:**
```
Requirements:
- Bug must be PLAUSIBLE (a real developer could have written this)
- Bug must NOT be caught by existing tests (that's the point)
- Bug must have OBSERVABLE symptoms (errors, wrong output, performance)
- Bug must be FIXABLE with the information available

Planting process:
1. Identify the component to break
2. Introduce the bug (off-by-one, race condition, wrong comparison, etc.)
3. Verify existing tests still pass (the bug is in an untested path)
4. Generate symptoms (error logs, wrong API responses, timing issues)
5. Add red herrings (suspicious-looking but correct code elsewhere)

Bug types to rotate:
- Race conditions (async/concurrent access)
- Off-by-one errors (pagination, array bounds)
- Null/undefined handling (missing null checks)
- Type coercion (JavaScript "0" == false)
- State mutation (shared state modified unexpectedly)
- Resource leaks (connections, file handles, event listeners)
- Logic errors (wrong boolean operator, inverted condition)
- Configuration errors (wrong env var, wrong connection string)
- Timezone/locale bugs (UTC vs local, date formatting)
- Encoding issues (UTF-8, URL encoding, base64)
```

**For greenfield challenges:**
```
Requirements:
- Remove one component cleanly
- Leave integration points (imports that reference the removed module)
- Leave test stubs that define expected behavior
- Leave documentation that describes what the component should do

Process:
1. Build the full working application
2. Identify the component to remove
3. Remove implementation but keep: interface/type definitions, test files, docs
4. Verify the rest of the application still compiles/starts (with the gap)
```

**For refactoring challenges:**
```
Requirements:
- Code must WORK in its current state
- All tests pass on the "before" state
- The code is clearly suboptimal (slow, insecure, unmaintainable)
- The "after" state must pass all existing tests PLUS new quality checks

Patterns to use:
- God object (one file does everything)
- Copy-paste duplication (same logic in 5 places)
- Callback hell (deeply nested async)
- SQL injection (string concatenation in queries)
- Missing error handling (try/catch absent)
- Hardcoded values (magic numbers, hardcoded URLs)
- Tight coupling (modules depend on implementation details)
```

### Step 4: Generate Test Suites

Three categories of tests:

**Static test suite (35% of score):**
```
Functional tests:
- Happy path for every endpoint/feature
- Common edge cases (empty input, boundary values)
- Integration between components (does A correctly call B?)
- Data integrity (database state correct after operations)

Structure:
  tests/static/
    unit/           — 10-20 tests per major module
    integration/    — 5-10 tests for cross-module flows
    e2e/            — 3-5 end-to-end workflow tests
```

**Adversarial test suite (15% of score):**
```
See Skill 5 for detailed methodology.
Categories: input attacks, concurrency, state, resource
Generated to be FAIR but PUNISHING
```

**Quality tests (part of code quality score):**
```
Performance:
- Response time under load (100 concurrent requests)
- Memory usage over time (no leaks)
- Database query count (no N+1)

Security:
- Automated scanning (Semgrep rules)
- OWASP Top 10 checks
- Dependency vulnerability check
```

### Step 5: Generate Scoring Rubric

Map every test and quality check to a score contribution:

```yaml
scoring_rubric:
  static_tests:
    weight: 0.35
    breakdown:
      unit_tests:
        total_points: 50
        per_test: [list of test names and point values]
      integration_tests:
        total_points: 30
        per_test: [list]
      e2e_tests:
        total_points: 20
        per_test: [list]

  adversarial_tests:
    weight: 0.15
    severity_multipliers:
      critical: 3.0
      high: 2.0
      medium: 1.0
      low: 0.5

  code_quality:
    weight: 0.20
    judge_count: 3
    dimensions: [readability, architecture, robustness, idiomaticity]

  deliverables:
    weight: 0.15
    checklist: [list of required deliverables]

  security:
    weight: 0.10
    scanner: semgrep
    severity_deductions:
      critical: 25
      high: 15
      medium: 5
      low: 1

  stability:
    weight: 0.05
    criteria:
      clean_run: 100
      warnings: 50
      crashes: 0
```

---

## Anti-Contamination Measures

Every generated instance must be unique enough that memorization provides no advantage.

**Name randomization:**
```
Don't: UserService, ProductController, OrderRepository
Do:    MembershipOrchestrator, CatalogEngine, FulfillmentGateway

Generate domain-specific names:
- E-commerce: "StockpileSync", "CartHarbor", "PricingMatrix"
- Fintech: "LedgerGuard", "TransferOracle", "BalanceReconciler"
- Social: "FeedCurator", "ConnectionGraph", "ContentModerator"
```

**Architecture variation:**
```
Same template, different patterns:
- Instance A: Repository pattern + Service layer + Controller
- Instance B: CQRS with command/query handlers
- Instance C: Functional approach with pure functions + IO boundary

Same feature, different implementation:
- Instance A: Auth with JWT + refresh tokens
- Instance B: Auth with session cookies + CSRF
- Instance C: Auth with API keys + HMAC signatures
```

**Business logic variation:**
```
Same domain (e-commerce), different rules:
- Instance A: Flat shipping rate, 10% tax
- Instance B: Weight-based shipping, tiered tax by region
- Instance C: Free shipping over $50, no tax (wholesale)

These variations mean the LOGIC differs, not just the names.
```

**Data variation:**
```
Seed data is unique per instance:
- Different user names, product names, order IDs
- Different data distributions (some have many orders, some few)
- Different edge cases in the data (Unicode names, long strings, null fields)
```

---

## Framework Stack Decision Matrix

When choosing a stack for a challenge, consider:

| Factor | Weight | Notes |
|--------|--------|-------|
| Agent familiarity | High | Most agents trained on Node.js/Python. Go/Rust are harder. |
| Challenge type fit | High | Concurrency bugs → Go/Node.js. ORM issues → Python/Node.js. |
| Tier appropriateness | Medium | Rust at Tier 1 might be unfairly hard. Rust at Tier 3 is perfect. |
| Stack diversity | Medium | Don't make 80% of challenges Express+PostgreSQL. |
| Realism | High | Use stacks that real companies actually use. |

**Recommended distribution:**
```
Tier 1: 60% Node.js/TS, 30% Python, 10% other
Tier 2: 40% Node.js/TS, 30% Python, 20% Go, 10% other
Tier 3: 30% Node.js/TS, 25% Python, 25% Go, 15% Rust, 5% other
Tier 4: Even distribution across all supported stacks
```

---

## Codebase Size Guidelines

| Tier | Files | Lines of Code | Models/Entities | Routes/Endpoints |
|------|-------|--------------|-----------------|------------------|
| 0 | 1-3 | 50-200 | 0-1 | 1-2 |
| 1 | 5-15 | 500-2000 | 2-4 | 4-8 |
| 2 | 15-30 | 2000-5000 | 4-8 | 8-15 |
| 3 | 30-50 | 5000-15000 | 8-15 | 15-30 |
| 4 | 50-100+ | 15000+ | 15+ | 30+ |

**File type distribution (typical):**
```
Source code:     40-50% of files
Tests:           20-30% of files
Config:          10-15% of files
Documentation:   5-10% of files
Data/Fixtures:   5-10% of files
```

---

## Quality Checklist for Generated Codebases

Before a generated codebase is used in a challenge:

- [ ] Application starts without errors
- [ ] All pre-challenge tests pass
- [ ] Dependencies install in <60 seconds
- [ ] No actual security vulnerabilities (unless intentionally planted)
- [ ] Realistic file structure for the chosen framework
- [ ] README accurately describes the project
- [ ] Seed data is present and realistic
- [ ] No references to "challenge", "test", "gauntlet", or meta-information
- [ ] Code style is consistent WITHIN files (inconsistency BETWEEN files is intentional)
- [ ] Git history (if present) is realistic
- [ ] No leftover generation artifacts (AI comments, template markers)
- [ ] Environment variables are documented in .env.example
- [ ] The codebase would pass a casual code review as "real"
