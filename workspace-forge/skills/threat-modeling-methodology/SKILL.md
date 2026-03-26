---
name: threat-modeling-methodology
description: Systematic threat modeling using STRIDE, attack trees, and data flow analysis — applied BEFORE code is written to catch security flaws at design time. Use when designing new features, reviewing architecture specs, evaluating system designs, creating security requirements for new projects, or performing pre-development security review. This is the proactive counterpart to reactive code review — find the vulnerability in the design before anyone writes a line of code. Covers STRIDE threat categorization, data flow diagramming, trust boundary identification, attack tree construction, risk scoring, and threat-to-mitigation mapping specific to our Next.js + Supabase + Vercel stack.
---

# Threat Modeling Methodology

## Why This Changes Everything

Code review finds bugs in code. Threat modeling finds bugs in **design**. A vulnerability caught at design time costs 10 minutes to fix. The same vulnerability caught in production costs days and potentially millions.

**The 0.01% mindset**: Before any code is written, the architecture is reviewed against every attack category. The code reviewer's job becomes verification ("did they implement the mitigations we designed?") instead of discovery ("is there a vulnerability hiding somewhere?").

## When to Threat Model

- **New product/feature**: Before Maks writes a single line
- **Architecture change**: New API, new data flow, new third-party integration
- **Security-sensitive feature**: Auth, payments, admin, data export, AI inference
- **External attack surface change**: New domain, new API endpoint, new WebSocket

## The Process (4 Steps)

### Step 1: Decompose the System

#### Draw the Data Flow Diagram (DFD)
Map every:
- **External entity**: Users, third-party APIs, payment providers
- **Process**: Next.js server, API routes, Server Actions, Edge Functions, cron jobs
- **Data store**: Supabase DB, Redis cache, Supabase Storage, file system
- **Data flow**: HTTP requests, WebSocket messages, database queries, API calls
- **Trust boundary**: Client ↔ Server, Server ↔ Database, Server ↔ Third-party

```
┌─────────────────────────────────────────────────────────────┐
│                    TRUST BOUNDARY: Internet                   │
│                                                               │
│  [Browser]  ←──HTTP/WS──→  [Next.js Server]                 │
│  [Mobile App]              │                                  │
│                            │                                  │
│        ┌───────────────────┼──────────────────┐              │
│        │   TRUST BOUNDARY: Internal            │              │
│        │                   │                   │              │
│        │  [Supabase DB] ←──SQL──→ [Server]     │              │
│        │  [Redis Cache] ←──Redis──→ [Server]   │              │
│        │  [Storage]     ←──S3──→ [Server]      │              │
│        │                                       │              │
│        └───────────────────────────────────────┘              │
│                            │                                  │
│        ┌───────────────────┼──────────────────┐              │
│        │   TRUST BOUNDARY: Third-party         │              │
│        │                                       │              │
│        │  [Stripe API] ←──HTTPS──→ [Server]    │              │
│        │  [Claude API] ←──HTTPS──→ [Server]    │              │
│        │  [GitHub API] ←──HTTPS──→ [Server]    │              │
│        └───────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

#### Identify Trust Boundaries
Every arrow that crosses a trust boundary is an **attack surface**. Each must be analyzed:
- What data crosses this boundary?
- Is it authenticated?
- Is it encrypted?
- Is input validated?
- Can it be intercepted or forged?

### Step 2: Apply STRIDE to Every Component

STRIDE categorizes threats. For each component and data flow in the DFD, systematically ask:

| Threat | Question | Example in Our Stack |
|--------|----------|---------------------|
| **S**poofing | Can an attacker pretend to be someone else? | Forge JWT, bypass auth, impersonate user via IDOR |
| **T**ampering | Can an attacker modify data in transit or at rest? | Modify request body, tamper with cached data, SQL injection |
| **R**epudiation | Can an actor deny performing an action? | Delete logs, no audit trail on admin actions |
| **I**nformation Disclosure | Can an attacker access data they shouldn't? | Cross-tenant data leak, verbose errors, missing RLS |
| **D**enial of Service | Can an attacker make the system unavailable? | ReDoS, resource exhaustion, cost attack on AI endpoints |
| **E**levation of Privilege | Can an attacker gain unauthorized capabilities? | Become admin, access service_role, bypass feature gates |

#### STRIDE Applied to Common Components

**API Route (POST /api/challenges)**:
| Threat | Applicable? | Mitigation |
|--------|------------|------------|
| Spoofing | Yes — can unauthenticated user call it? | Require auth (getUser()) |
| Tampering | Yes — can input be manipulated? | Zod validation, parameterized queries |
| Repudiation | Maybe — are challenge creations logged? | Audit log with user_id and timestamp |
| Info Disclosure | Yes — do errors leak schema? | Generic error responses |
| DoS | Yes — can it be called unlimited times? | Rate limiting |
| EoP | Yes — can regular user create admin-only challenges? | Role check before creation |

**Supabase Database Table**:
| Threat | Applicable? | Mitigation |
|--------|------------|------------|
| Spoofing | N/A at DB level | Auth handled at API layer |
| Tampering | Yes — can wrong user modify rows? | RLS with USING + WITH CHECK |
| Info Disclosure | Yes — can wrong user read rows? | RLS SELECT policies |
| EoP | Yes — can user modify their own role? | RLS prevents user_role column updates |

### Step 3: Build Attack Trees for Critical Paths

For the most critical assets (user accounts, payment data, admin access), build attack trees:

```
GOAL: Steal User's Payment Information
├── Via Database Access
│   ├── Missing RLS on payment_methods table
│   ├── SQL injection in search endpoint
│   └── Service role key leaked to frontend
├── Via API Response
│   ├── IDOR on /api/payment-methods?userId=X
│   ├── Verbose error includes payment data
│   └── Cross-tenant data leak in multi-tenant query
├── Via Client-Side
│   ├── XSS steals session → accesses payment API
│   ├── Payment data stored in localStorage
│   └── Payment form on HTTP (not HTTPS)
├── Via Third-Party
│   ├── Stripe webhook forgery → manipulate payment records
│   ├── Compromised dependency reads payment data
│   └── SSRF → internal API → payment service
└── Via Physical/Social
    ├── Session token in URL → shared/logged
    ├── Admin password brute force
    └── Social engineering support staff
```

Each leaf is a potential attack. Each requires a specific mitigation.

### Step 4: Create Threat-Mitigation Map

For each identified threat, specify the mitigation:

| ID | Threat | Component | STRIDE | Severity | Mitigation | Status |
|----|--------|-----------|--------|----------|------------|--------|
| T1 | Unauthenticated API access | /api/challenges | S | HIGH | getUser() check | Required |
| T2 | Input injection | /api/challenges | T | HIGH | Zod schema validation | Required |
| T3 | Cross-tenant data leak | challenges table | I | CRITICAL | RLS with org_id scoping | Required |
| T4 | Admin bypass | /api/admin/* | E | CRITICAL | Role verification middleware | Required |
| T5 | Brute force login | /api/auth/login | S,D | HIGH | Rate limiting + CAPTCHA | Required |

This becomes the **security requirements document** for the feature.

## Threat Model Template

```markdown
# Threat Model: [Feature Name]
Date: [Date]
Author: Forge
Status: [Draft/Review/Approved]

## 1. System Description
[1-2 paragraphs describing what the feature does]

## 2. Data Flow Diagram
[DFD with trust boundaries marked]

## 3. Assets
| Asset | Sensitivity | Storage | Access Control |
|-------|------------|---------|---------------|
| [e.g., User credentials] | CRITICAL | Supabase auth | Auth service only |

## 4. Trust Boundaries
| Boundary | Data Crossing | Protection |
|----------|--------------|------------|
| Client ↔ Server | Auth tokens, user input | HTTPS, JWT verification |

## 5. STRIDE Analysis
[Table per component as shown above]

## 6. Attack Trees
[For top 3 critical assets]

## 7. Threat-Mitigation Map
[Full table with mitigations and status]

## 8. Residual Risks
[Threats that can't be fully mitigated — accepted with justification]

## 9. Review Verification Points
[What to check during code review to verify mitigations are implemented]
```

## Integration with Forge Workflow

### Before Maks Builds (Architecture Phase)
1. Forge receives architecture spec
2. Forge creates threat model for the feature
3. Threat model reviewed with Nick/MaksPM
4. Mitigations become security requirements in the spec
5. Maks implements with requirements built in

### During Code Review (Review Phase)
1. Load the threat model for the feature being reviewed
2. For each mitigation in the threat map: verify it's implemented
3. Findings reference specific threat IDs: "T3 not mitigated — missing RLS on new table"

This closes the loop: **design-time threat identification → implementation-time verification**.

## References

For STRIDE details and examples, see `references/stride-reference.md`.
For attack tree construction patterns, see `references/attack-trees.md`.
