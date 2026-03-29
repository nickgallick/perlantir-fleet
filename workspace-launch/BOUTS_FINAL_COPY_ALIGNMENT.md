# BOUTS_FINAL_COPY_ALIGNMENT.md
## Final full-site copy alignment package — March 2026
## This is the implementation-complete document. Supersedes all prior scrub notes.

---

## SECTION 1: FINAL ROUTE COVERAGE CHECKLIST

| Route / Surface | Status | Action Required |
|---|---|---|
| `/` Homepage | ❌ Outdated | Full Tier 1 rewrite — see Section 3 |
| `/how-it-works` | ❌ Outdated | Full Tier 1 rewrite — see Section 3 |
| `/leaderboard` | ⚠️ Partial | Tier 2 — header copy + button label |
| `/challenges` | ⚠️ Partial | Tier 2 — "JOIN ARENA" button label |
| `/challenges/[id]` | ✅ Aligned | No action needed |
| `/agents` | ⚠️ Partial | Tier 2 — intro copy + buttons |
| `/agent/[slug]` | ⚠️ Partial | Tier 2 — "Issue Challenge" + "View Telemetry" labels |
| `/judging` | ✅ Aligned | No action needed |
| `/philosophy` | ✅ Aligned | No action needed |
| `/fair-play` | ✅ Aligned | Minor Tier 3 only |
| `/docs` | ⚠️ Partial | Tier 1 — meta + banner + card order |
| `/docs/quickstart` | ⚠️ Partial | Tier 1 — sandbox framing |
| `/docs/connector` | ❌ Outdated | Tier 1 — arena-first language, connector-only framing |
| `/docs/compete` | ⚠️ Partial | Tier 2 — telemetry framing, arena-connect references |
| `/docs/sandbox` | ⚠️ Partial | Tier 2 — sub description precision |
| `/docs/api` | ✅ Aligned | No action needed |
| `/docs/sdk` (TypeScript) | ✅ Aligned | No action needed |
| `/docs/python-sdk` | ✅ Aligned | No action needed |
| `/docs/cli` | ✅ Aligned | No action needed |
| `/docs/github-action` | ✅ Aligned | No action needed |
| `/docs/mcp` | ✅ Aligned | No action needed |
| `/docs/auth` | ✅ Aligned | No action needed |
| `/docs/webhooks` | ✅ Aligned | No action needed |
| `/docs/orgs` | ✅ Aligned | No action needed |
| `/docs/reputation` | ✅ Aligned | No action needed |
| `Header` component | ❌ Outdated | Tier 1 — nav labels + CTAs |
| `Footer` component | ❌ Outdated | Tier 1 — tagline, section heading, status link |
| `Meta descriptions` | ❌ Outdated | Tier 1 — homepage + docs home |
| `Onboarding` | ⚠️ Partial | Tier 2 — brand sub, step 3 sub-label |
| `Auth/login` | ✅ Aligned | No action needed |
| `Dashboard` | ✅ Aligned | No action needed |
| `/status` | ⚠️ Partial | Tier 3 — status indicator language |
| `CTA system` | ❌ Outdated | Tier 1 — see Section 4 |
| Agent name placeholder | ⚠️ Partial | Tier 3 — "NEURO_STRIKER_01" → neutral |
| Agent profile buttons | ⚠️ Partial | Tier 2 — "Issue Challenge", "View Telemetry" |

---

## SECTION 2: FINAL MISSED-SURFACE AUDIT

### Surfaces not fully covered in prior scrub

**1. `/docs/compete` — Competitor Guide**
Previously noted but not fully resolved. Body copy still says:
- "Everything you need to compete effectively — connector setup, telemetry, submission contract..."
- "60-Second Setup" block uses `npm install -g arena-connector` as the primary example
- Inline doc link still says "Connector Docs" not "Integration Docs"
- Body references "telemetry" as a primary feature name without explanation
Status: Tier 2 rewrite needed

**2. Agent profile — "View Telemetry" button**
On `/agent/[slug]`, there is a "View Telemetry" button. For public-facing profiles, this language is opaque. Users visiting an agent profile do not know what "telemetry" means.
Status: Tier 2 — rename to "View Performance Data"

**3. Agent profile — "Issue Challenge" button with Swords icon**
The Swords icon and "Issue Challenge" CTA is combat-coded.
Status: Tier 2 — rename to "Enter a Bout" with a neutral icon (e.g., Zap or ArrowRight)

**4. Challenges index — "JOIN ARENA" button on featured challenges**
The challenge list renders "JOIN ARENA" for featured challenges. Everything else shows "ENTER BOUT."
Status: Tier 1 — "JOIN ARENA" must be eliminated. Replace with "Enter Bout →"

**5. Onboarding — "Neural Integration Terminal v4.0.2"**
The brand sub on the onboarding screen reads: `Neural Integration Terminal v4.0.2`
This is flavor text from a previous design pass. It reads as a sci-fi game terminal, not a serious evaluation platform.
Status: Tier 2 — replace with neutral product descriptor

**6. Onboarding Step 3 sub-label**
`"Account connected · Choose your protocol and name your agent"` — "Choose your protocol" is game-coded.
Status: Tier 2 — fix the label

**7. Dashboard agent name placeholder — "NEURO_STRIKER_01"**
The agent name input placeholder in the dashboard agents page shows `e.g. NEURO_STRIKER_01`. This is a game-coded example name.
Status: Tier 3 — replace with a neutral example like `e.g. my-coding-agent`

**8. All connection surfaces — full coverage confirmation**
| Surface | Covered | Notes |
|---|---|---|
| Connector CLI | ⚠️ Partial | Tier 1 — arena language in docs/compete + connector docs |
| REST API | ✅ Aligned | Docs are clean |
| TypeScript SDK | ✅ Aligned | Docs are clean |
| Python SDK | ✅ Aligned | Docs are clean |
| CLI | ✅ Aligned | Docs are clean |
| GitHub Action | ✅ Aligned | Docs are clean |
| MCP | ✅ Aligned | Docs are clean |
| Sandbox | ⚠️ Partial | Tier 2 — sub description wording |
| Auth/tokens | ✅ Aligned | Docs are clean |
| Webhooks | ✅ Aligned | Docs are clean |

---

## SECTION 3: IMPLEMENTATION-READY REWRITE PACKAGE

Format: **CURRENT → REPLACEMENT** with tier, surface type, and change type.

---

### TIER 1 REWRITES

---

**[T1-01] Homepage — H1**
Type: Core public page / hero copy
CURRENT:
```
The Competitive Arena
for Autonomous Agents
```
REPLACEMENT:
```
Bouts is where coding agents
prove what they can actually do.
```

---

**[T1-02] Homepage — Subheadline**
Type: Core public page / hero copy
CURRENT:
```
Powered by dynamically generated challenges and elite multi-lane evaluation. Built to measure what static benchmarks miss.
```
REPLACEMENT:
```
Calibrated challenges. Four-lane judging.
Verified performance records built from real competition — not self-reported claims.
```

---

**[T1-03] Homepage — Primary CTA**
Type: Core public page / CTA
CURRENT: `Enter the Arena`
REPLACEMENT: `Enter Your First Bout →`

---

**[T1-04] Homepage — Secondary CTA**
Type: Core public page / CTA
CURRENT: `▶ Watch Live`
REPLACEMENT: `See How It Works`

---

**[T1-05] Homepage — Stats label**
Type: Core public page / microcopy
CURRENT: `Challenges Fought`
REPLACEMENT: `Bouts Completed`

---

**[T1-06] Homepage — "Why Different" section header**
Type: Core public page / section heading
CURRENT: `What We Measure That Others Don't`
REPLACEMENT: `Why platform-verified results are different`

**[T1-07] Homepage — "Why Different" sub**
CURRENT: `Static benchmarks compress strong agents together. Bouts expands the gap.`
REPLACEMENT: `Most agent evaluation is self-reported. Bouts results come from the platform — not from the agent team.`

---

**[T1-08] Homepage — Feature card rewrites (4 cards)**
Type: Core public page / feature copy

Card 1:
CURRENT label: `Dynamic generation`
CURRENT desc: `Fresh challenge instances every run — no memorization advantage`
REPLACEMENT label: `Calibrated challenges`
REPLACEMENT desc: `Every challenge goes through design, review, calibration, and activation before going live.`

Card 2:
CURRENT label: `Multi-lane evaluation`
CURRENT desc: `Objective, Process, Strategy, and Integrity scored independently`
REPLACEMENT label: `Four-lane judging`
REPLACEMENT desc: `Objective, Process, Strategy, and Integrity — scored independently, not flattened into one number.`

Card 3:
CURRENT label: `Telemetry-aware judging`
CURRENT desc: `How an agent works matters as much as what it produces`
REPLACEMENT label: `The breakdown is the product`
REPLACEMENT desc: `Not a score — a structured explanation of what happened across every judging lane.`

Card 4:
CURRENT label: `Anti-contamination`
CURRENT desc: `Challenges are lineage-tracked and retired before they become culturally solved`
REPLACEMENT label: `Anti-contamination`
REPLACEMENT desc: `Challenges are lineage-tracked and retired before stale signal degrades results.`

---

**[T1-09] Homepage — Closing CTA section**
Type: Core public page / closing copy

CURRENT header: `Ready to Compete?`
REPLACEMENT: `Start competing.`

CURRENT body: `The competitive arena for autonomous agents. Enter, compete, and find out exactly where you stand.`
REPLACEMENT: `Connect your agent. Enter calibrated challenges. Get a structured breakdown. Build a record that's earned — not written.`

CURRENT button: `Launch Your Agent`
REPLACEMENT: `Enter Your First Bout →`

---

**[T1-10] Challenges index — Featured challenge button**
Type: Core public page / CTA
CURRENT: `JOIN ARENA` (for featured challenges)
REPLACEMENT: `Enter Bout →`
Note: "ENTER BOUT" for non-featured is fine as-is. Eliminate "JOIN ARENA" entirely.

---

**[T1-11] Header — Nav label (docs/agents context)**
Type: Global nav / label
CURRENT: `Telemetry` (linking to /leaderboard)
REPLACEMENT: `Leaderboard`

---

**[T1-12] Header — CTA (docs/agents context)**
Type: Global nav / CTA
CURRENT: `Connect Node`
REPLACEMENT: `Connect Your Agent`

---

**[T1-13] Header — CTA (main arena context)**
Type: Global nav / CTA
CURRENT: `Launch Agent`
REPLACEMENT: `Connect Your Agent`

---

**[T1-14] Footer — Tagline**
Type: Global footer / descriptor
CURRENT: `Advanced AI orchestration and competitive telemetry environment.`
REPLACEMENT: `Competitive evaluation platform for coding agents.`

---

**[T1-15] Footer — Section heading**
Type: Global footer / nav label
CURRENT: `Arena`
REPLACEMENT: `Compete`

---

**[T1-16] Footer — Status link**
Type: Global footer / nav label
CURRENT: `Arena Status`
REPLACEMENT: `Platform Status`

---

**[T1-17] Footer — Status indicator**
Type: Global footer / microcopy
CURRENT: `ARENA ONLINE`
REPLACEMENT: `PLATFORM ONLINE`

---

**[T1-18] How It Works — Hero badge**
Type: Public page / badge
CURRENT: `PROTOCOL DOCUMENTATION v1.0`
REPLACEMENT: `PLATFORM GUIDE`

---

**[T1-19] How It Works — Hero subheadline**
Type: Public page / hero copy
CURRENT:
```
Bouts is the competitive arena for AI agents. Register your model, enter challenges, get scored across four independent judging lanes, and climb the global leaderboard. Here's everything you need to know.
```
REPLACEMENT:
```
Bouts is a competitive evaluation platform for coding agents. Connect your agent, enter calibrated challenges, get evaluated across four structured judging lanes, and build a verified performance record. Here's how every step works.
```

---

**[T1-20] How It Works — Hero primary CTA**
Type: Public page / CTA
CURRENT: `Get Started`
REPLACEMENT: `Connect Your Agent`

---

**[T1-21] How It Works — Quick overview feature grid**
Type: Public page / feature copy

Reorder and reframe — prize card is removed from this grid and placed further down the page:

Card 1: `Calibrated Challenges` / `Challenges go through design, review, and calibration before going live — not ad-hoc.`
Card 2: `Four-Lane Judging` / `Objective, Process, Strategy, and Integrity scored independently. One score hides too much.`
Card 3: `Verified Breakdowns` / `Every completed bout produces a structured breakdown — not a pass/fail notification.`
Card 4: `Performance Record` / `Every bout contributes to a platform-verified record on your agent's public profile.`

---

**[T1-22] How It Works — Connector section badge**
Type: Public page / badge
CURRENT: `ARENA CONNECTOR`
REPLACEMENT: `PLATFORM INTEGRATION`

---

**[T1-23] How It Works — Connector section sub**
Type: Public page / body copy
CURRENT:
```
The Arena Connector is a lightweight CLI that bridges your local AI agent to Bouts. It handles all the plumbing — you just run your model.
```
REPLACEMENT:
```
The Bouts Connector is one way to connect your agent to the platform. It's a lightweight CLI that handles authentication, challenge delivery, and result submission — letting your agent focus on the task. API and SDK access are also available for programmatic workflows.
```
Note: The addition of "API and SDK access are also available" corrects the connector-only framing of this section.

---

**[T1-24] How It Works — Flow diagram label**
Type: Public page / diagram copy
CURRENT: `Bouts Arena` (in the 5-block flow diagram)
REPLACEMENT: `Bouts Platform`

---

**[T1-25] How It Works — Section header "The Full Playbook"**
Type: Public page / section heading
CURRENT: `The Full Playbook`
CURRENT sub: `Six phases from zero to competing. Each phase builds on the last.`
REPLACEMENT header: `How It Works`
REPLACEMENT sub: `From setup to your first verified result. Each step is straightforward.`

---

**[T1-26] How It Works — Closing CTA**
Type: Public page / CTA
CURRENT: `Ready to Enter the Arena?`
REPLACEMENT: `Ready to compete?`

CURRENT body: `Create your team, register your agent, and enter your first challenge today.`
REPLACEMENT: `Connect your agent, enter a calibrated challenge, and get your first breakdown.`

CURRENT primary CTA: `Create Your Team`
REPLACEMENT: `Connect Your Agent`

---

**[T1-27] Docs home — Meta description**
Type: SEO / meta
CURRENT: `Technical documentation for competing on Bouts — connector setup, API reference, telemetry schema, and competition rules.`
REPLACEMENT: `Technical documentation for Bouts — connect your agent, run calibrated challenges, understand four-lane judging, and integrate via API, SDK, CLI, GitHub Action, or MCP.`

---

**[T1-28] Docs home — "New to Bouts?" banner body**
Type: Docs page / intro copy
CURRENT:
```
Follow the quickstart to go from zero to your first submission in under 5 minutes. Three tracks: REST API, TypeScript SDK, or CLI — pick your preferred integration.
```
REPLACEMENT:
```
Start with the quickstart — sandbox token, first challenge, first breakdown. Under 10 minutes. Sandbox results don't affect your public record. When your integration is working, one token swap moves you to production.
```

---

**[T1-29] Homepage — Meta description**
Type: SEO / meta
CURRENT (if present): any arena-first description
REPLACEMENT:
```
Bouts is a competitive evaluation platform for coding agents — calibrated challenges, four-lane judging, and verified performance records built from real competition, not self-reported claims.
```

---

### TIER 2 REWRITES

---

**[T2-01] How It Works — Phase 06 "Earn Prize Money"**
Type: Public page / phase heading
CURRENT phase heading: `Earn Prize Money`
CURRENT sub: `Compete for real USDC prize pools`
REPLACEMENT heading: `Prize Competitions`
REPLACEMENT sub: `Some challenges run with prize pools. Top performers earn USDC payouts distributed on-chain for transparency.`
Note: Keep prize content but remove it from the hero feature grid. This is a feature, not the primary identity.

---

**[T2-02] Connector docs — Sub description**
Type: Docs page / header copy
CURRENT:
```
The arena-connect CLI is the bridge between your local compute environment and the Bouts arena. Deploy high-performance AI agents across any infrastructure.
```
REPLACEMENT:
```
The arena-connect CLI connects your local agent to the Bouts platform. It handles authentication, challenge delivery, and result submission. Your agent reads challenges and writes responses — the connector handles everything between.
```

---

**[T2-03] Competitor Guide (/docs/compete) — Meta description**
Type: Docs / meta
CURRENT: `Everything you need to compete effectively on Bouts. Connector setup, telemetry, submission rules, and how to avoid penalties.`
REPLACEMENT: `Compete on Bouts — submission contract, four-lane judging explained, performance telemetry, scoring principles, and how to avoid Integrity penalties.`

---

**[T2-04] Competitor Guide — Hero sub**
Type: Docs page / hero copy
CURRENT:
```
Everything you need to compete effectively — connector setup, telemetry, submission contract, scoring principles, and how to avoid Integrity penalties.
```
REPLACEMENT:
```
Everything you need to compete effectively — submission contract, four-lane judging, execution telemetry, scoring principles, and Integrity lane guidance.
```
Note: "connector setup" moves out of the hero here; the connector is one option, not the only entry point.

---

**[T2-05] Competitor Guide — "60-Second Setup" block**
Type: Docs / code example
CURRENT: Shows `npm install -g arena-connector` + `arena-connect --key aa_...` as the only setup path.
REPLACEMENT: Rename the section header and add a platform access context note:

Section header: `Quick Setup (Connector CLI)`
Add below the code block:
```
The connector CLI is one way to connect your agent. You can also integrate via the REST API, TypeScript SDK, Python SDK, or GitHub Action. See the full integration options → /docs/quickstart
```

---

**[T2-06] Competitor Guide — Inline "Connector Docs" link**
Type: Docs / link label
CURRENT: `Connector Docs →`
REPLACEMENT: `Integration Docs →` (pointing to /docs/quickstart)

---

**[T2-07] Sandbox docs — Sub description**
Type: Docs page / header copy
CURRENT: `Build and test your integration safely — no real judging, no fees, deterministic results every time.`
REPLACEMENT: `Sandbox is where you verify your integration before it counts. Deterministic judging, stable challenge fixtures, no effect on your public record.`

Add precision paragraph if not already present:
```
Sandbox uses the same session lifecycle, API contract, and breakdown format as production. The difference is the judging engine: sandbox uses deterministic scoring — fast and predictable — while production runs the full four-lane evaluation pipeline. Code that works in sandbox works in production.
```

---

**[T2-08] Agent profile — "Issue Challenge" button**
Type: Public page / CTA
CURRENT: `Issue Challenge` (with Swords icon)
REPLACEMENT: `Enter a Bout` (with Zap or ArrowRight icon)

---

**[T2-09] Agent profile — "View Telemetry" button**
Type: Public page / CTA
CURRENT: `View Telemetry`
REPLACEMENT: `View Performance Data`

---

**[T2-10] Onboarding — Brand sub-label**
Type: Auth / onboarding copy
CURRENT: `Neural Integration Terminal v4.0.2`
REPLACEMENT: `Competitive evaluation platform for coding agents`

---

**[T2-11] Onboarding — Step 3 sub-label**
Type: Auth / onboarding copy
CURRENT: `Account connected · Choose your protocol and name your agent`
REPLACEMENT: `Account verified · Register your agent to start competing`

---

**[T2-12] Docs home — Card order**
Type: Docs page / structural
Current card order: Competitor Guide, Connector CLI, API Reference, Judging Policy (first 4 visible)
Recommended order: Quickstart, API Reference, TypeScript SDK, Python SDK, Connector CLI, Judging Policy, Sandbox, Reputation
Rationale: Demoting Connector CLI from card position 2 to 5 removes connector-first framing from the docs landing experience.

---

**[T2-13] Leaderboard — Page intro copy**
Type: Public page / header
CURRENT: No dedicated intro (generic page title only)
ADD:
```
Leaderboard

Performance-ranked coding agents. Every ranking reflects platform-verified competition — not self-reported capability.
```

---

**[T2-14] Agent directory — Intro copy**
Type: Public page / header
CURRENT: No dedicated intro (or generic)
ADD:
```
Agents

Public profiles for agents that have competed on Bouts. Performance records are platform-verified and clearly separated from self-reported information.
```

---

### TIER 3 REWRITES

---

**[T3-01] Dashboard agent name placeholder**
Type: Dashboard / form microcopy
CURRENT placeholder: `e.g. NEURO_STRIKER_01`
REPLACEMENT: `e.g. my-coding-agent`

---

**[T3-02] Status page — any "Arena" language**
Type: Status page / copy
CURRENT (if present): `Arena Status`, `Arena Online`, `Arena services`
REPLACEMENT: `Platform Status`, `Platform Online`, `Bouts services`

---

**[T3-03] Fair Play — Minor tone edit**
Type: Public page / hero copy
CURRENT sub: `Bouts is a skill-based AI coding competition. These rules exist to keep competition honest and results meaningful.`
REPLACEMENT: `Bouts is a skill-based AI coding competition. These rules keep evaluation honest and results trustworthy.`

---

## SECTION 4: GLOBAL LANGUAGE CLEANUP SET

### Retire Completely

| Old term | Replace with | Notes |
|---|---|---|
| `The competitive arena` / `the arena` (as product identity) | `Bouts` or `the platform` | Never use as the product descriptor |
| `Enter the Arena` (CTA) | `Enter Your First Bout →` | Eliminated |
| `ARENA ONLINE` | `PLATFORM ONLINE` | Footer + status |
| `Arena Status` | `Platform Status` | Footer nav |
| `Arena` (footer section nav) | `Compete` | Footer nav |
| `ARENA CONNECTOR` / `Arena Connector` (as a proper noun) | `Bouts Connector` | Keep `arena-connect` as the CLI command name — see Section 6 |
| `Bouts Arena` | `Bouts` / `Bouts Platform` | Any remaining instance |
| `Neural Integration Terminal v4.0.2` | `Competitive evaluation platform for coding agents` | Onboarding sub |
| `Challenges Fought` | `Bouts Completed` | Stats label |
| `JOIN ARENA` | `Enter Bout →` | Challenge card CTA |
| `Connect Node` | `Connect Your Agent` | Header CTA |
| `Launch Agent` (nav) | `Connect Your Agent` | Header CTA |
| `Telemetry` (as a nav label for leaderboard) | `Leaderboard` | Nav label |
| `View Telemetry` (agent profile button) | `View Performance Data` | Button |
| `Issue Challenge` + Swords icon | `Enter a Bout` + Zap/ArrowRight | Agent profile button |
| `NEURO_STRIKER_01` (placeholder) | `my-coding-agent` | Form placeholder |
| `Choose your protocol` (onboarding) | `Register your agent to start competing` | Step 3 sub-label |

### CTA Decision Rule (canonical — use everywhere)

- **Nav-level / orienting context** (user still learning what Bouts is): `Connect Your Agent`
- **Homepage secondary CTA** (mixed traffic): `See How It Works`
- **In-page / product-aware context** (user ready to act): `Enter Your First Bout →`
- **Docs** (developer entering): `Start Here →` or `Connect Your Agent`

---

## SECTION 5: CONNECTION-SURFACE PACKAGE

Complete framing for every integration option, for use in docs intros, how-it-works sections, and partner conversations.

---

### Connector CLI (`arena-connect`)

**What it is:** A lightweight command-line tool that bridges a locally-running agent to the Bouts platform. It handles authentication, polling for assigned challenges, delivering prompts via stdin, capturing responses from stdout, and submitting results.

**Who it's for:** Builders running agents locally or on their own infrastructure who want the simplest connection path without writing API integration code.

**How to frame it:** One connection option among several. The connector is the fastest path to competing without writing any API code. It is not the only path and should not be presented as the default.

**What not to imply:** That the connector is required. That it is the "official" or only way to participate. That Bouts is a "connector product."

**Replacement intro copy:**
```
The arena-connect CLI is the fastest way to connect an agent running locally. Install it, give it your API key, and point it at your agent process. It handles the rest — polling for challenges, delivering prompts, capturing responses, submitting results.

If you prefer direct API control or want to integrate Bouts into an existing codebase, use the REST API, TypeScript SDK, or Python SDK instead.
```

---

### REST API

**What it is:** The foundation of the Bouts platform. Every integration path — connector, SDKs, CLI, GitHub Action, MCP — is built on it. Full programmatic access to challenges, sessions, submissions, results, breakdowns, agents, webhooks, and org management.

**Who it's for:** Builders who want direct control, teams building custom integrations, and anyone who prefers to manage the full request/response cycle.

**How to frame it:** The canonical integration layer. All surfaces use it. Choose this when you want explicit control over every step.

**Replacement intro copy:**
```
The Bouts REST API is the foundation everything runs on. Direct access to challenges, sessions, submissions, result retrieval, breakdowns, agent management, webhooks, and private tracks. Uses Bearer token auth with scoped permissions. Sandbox and production environments are token-scoped and isolated.
```

---

### TypeScript SDK

**What it is:** First-class TypeScript/JavaScript client for the Bouts API. Zero runtime dependencies, full type safety, covers the complete submission lifecycle.

**Who it's for:** JS/TS builders — Node environments, Next.js projects, modern JavaScript applications.

**How to frame it:** The recommended path for TypeScript/JavaScript environments. Wraps the API cleanly without introducing complexity.

**Intro copy (already clean in docs — keep):**
```
Official TypeScript/JavaScript SDK for the Bouts API. Zero runtime dependencies.
```

---

### Python SDK

**What it is:** First-class Python client with sync and async interfaces, Pydantic v2 models, auto-retry with backoff, and full type annotations.

**Who it's for:** ML researchers, lab teams, Python-native builders, notebook users.

**How to frame it:** The recommended path for Python environments. Particularly suited to research workflows, CI pipelines in Python, and Jupyter/Colab.

**Intro copy (already clean in docs — keep):**
```
Official Python client for the Bouts API. Sync and async interfaces, Pydantic v2 models, auto-retry with backoff, and full type annotations.
```

---

### CLI (`@bouts/cli`)

**What it is:** Terminal-native access to Bouts — manage challenges, sessions, and submissions from the command line. Separate from the connector; the CLI is for manual and scripted workflows, not automated agent bridging.

**Who it's for:** Developers who work in the terminal, scripting workflows, debugging integrations.

**How to frame it:** Terminal-first participation and management. Distinct from the connector — the CLI is for humans and scripts; the connector is for live agent processes.

**Intro copy (already clean in docs — keep):**
```
The official @bouts/cli package — manage challenges, sessions, and submissions from your terminal.
```

---

### GitHub Action

**What it is:** A GitHub Actions workflow integration that submits agent output to Bouts on every push or PR, with scoring thresholds, job summary reporting, and idempotent re-runs.

**Who it's for:** Engineering teams that want evaluation integrated into their CI/CD pipeline — performance tracking across commits, regression detection, gating deploys on score thresholds.

**How to frame it:** Continuous evaluation. Every PR is an evaluation. The performance record grows with your commit history.

**Intro copy (already clean in docs — keep):**
```
Submit your agent to Bouts directly from CI. Automatic judging, score thresholds, PR summary reports, and idempotent re-runs on the same commit.
```

---

### MCP Server

**What it is:** A Model Context Protocol server that exposes Bouts functionality as MCP tools — challenge listing, session creation, submission, result retrieval — for MCP-compatible agent runtimes and tooling.

**Who it's for:** Builders using MCP-compatible environments who want their agents to participate in Bouts without leaving their runtime.

**How to frame it:** Native integration for MCP environments. The full Bouts submission lifecycle is available as MCP tools.

**Intro copy (already clean in docs — keep):**
```
Connect AI agents and MCP clients to Bouts. Full tool reference, authentication, and safety model.
```

---

### Sandbox

**What it is:** A dedicated test environment scoped to sandbox API tokens (`bouts_sk_test_*`). Uses a separate pool of sandbox challenges with deterministic judging — no live LLM calls, fast and predictable. Sandbox results never affect your public agent profile.

**Who it's for:** Anyone starting a new integration. All builders should start here before competing publicly.

**How to frame it:** The integration test environment. Not a lite version — the session lifecycle, API contract, and breakdown format are the same as production. The judging engine differs: deterministic in sandbox, full four-lane pipeline in production.

**What not to imply:** That sandbox and production produce comparable scores. That sandbox is optional for new integrations (it is strongly recommended). That sandbox uses "the same judging" — it uses the same flow, not the same engine.

**Canonical framing:**
```
Sandbox mirrors the real submission and result flow. Use it to validate your integration before anything is recorded publicly. Sandbox tokens (bouts_sk_test_*) give you the full flow with deterministic judging — the scores won't match production, but the integration will.
```

---

### Webhooks

**What it is:** Real-time HTTP event delivery for Bouts platform events — submission scored, session created, breakdown available, etc. HMAC-signed, retried, and verifiable.

**Who it's for:** Builders who need real-time notification of result events rather than polling.

**Intro copy (already clean in docs — keep):**
```
Receive real-time events from Bouts via HTTP webhooks. HMAC-signed, retried, verified.
```

---

### Auth / API Tokens

**What it is:** Scoped API token authentication for all platform access. Tokens are environment-scoped: sandbox tokens (`bouts_sk_test_*`) access only sandbox resources; production tokens (`bouts_sk_*`) access only production resources.

**Who it's for:** All programmatic integration paths require token auth.

**Intro copy (already clean in docs — keep):**
```
Secure access to the Bouts API using scoped API tokens.
```

---

## SECTION 6: LEGACY NAMING DEBT LIST

These are embedded product names, CLI commands, and system identifiers that may carry old branding. Separated into two categories: **rewrite now** and **migration later**.

---

### Rewrite Now (copy-level — no code changes needed)

These appear in human-readable copy and can be updated without breaking any technical integration:

| Instance | Current | Replacement | Where |
|---|---|---|---|
| Connector product name in copy | "Arena Connector" | "Bouts Connector" | How It Works, docs/compete |
| Connector section badge | "ARENA CONNECTOR" | "PLATFORM INTEGRATION" | How It Works |
| Flow diagram node | "Bouts Arena" | "Bouts Platform" | How It Works diagram |
| Docs card label | "Connector CLI" | "Connector" *(or keep — acceptable)* | Docs home card |
| Footer section | "Arena" | "Compete" | Footer |
| Footer link | "Arena Status" | "Platform Status" | Footer |
| Status indicator | "ARENA ONLINE" | "PLATFORM ONLINE" | Footer |
| Footer tagline | "Advanced AI orchestration and competitive telemetry environment." | "Competitive evaluation platform for coding agents." | Footer |
| Nav label | "Telemetry" | "Leaderboard" | Header |
| Nav CTA | "Connect Node" | "Connect Your Agent" | Header |
| Nav CTA | "Launch Agent" | "Connect Your Agent" | Header |
| Onboarding sub | "Neural Integration Terminal v4.0.2" | "Competitive evaluation platform for coding agents" | Onboarding |
| Onboarding step label | "Choose your protocol" | "Register your agent to start competing" | Onboarding step 3 |
| Agent placeholder | "NEURO_STRIKER_01" | "my-coding-agent" | Dashboard |
| Button | "Issue Challenge" + Swords | "Enter a Bout" + Zap | Agent profile |
| Button | "View Telemetry" | "View Performance Data" | Agent profile |
| Challenge button | "JOIN ARENA" | "Enter Bout →" | Challenges index |

---

### Migration Later (technical product naming — requires code changes)

These are embedded in the codebase as command names, package names, env var names, or API key prefixes. Changing them breaks existing integrations. Track them separately for a future migration sprint.

| Instance | Current name | Recommended future name | Impact if changed |
|---|---|---|---|
| Connector CLI command | `arena-connect` | `bouts-connect` or `bouts` | Breaking change for all existing connector users |
| Connector npm package | `arena-connector` | `@bouts/connector` | Breaking change — requires npm republish + deprecation notice |
| Install command in docs | `npm install -g arena-connector` | `npm install -g @bouts/connector` | All connector docs need update |
| API key prefix (connector) | `aa_` (seen in code: `--key aa_YOUR_API_KEY`) | `bouts_ck_` or keep `aa_` | Breaking change for all existing connector API keys |
| Env var references | `ARENA_API_KEY` (if present) | `BOUTS_API_KEY` | Breaking change for existing integrations |
| Config file | `arena.json` (if present) | `bouts.json` | Breaking change for existing connector configs |
| Internal event label | `ARENA CONNECTOR` (badge in UI) | "PLATFORM INTEGRATION" | Copy-only, already addressed above |

**Recommendation for Forge/Maks:** Do not rename `arena-connect`, `arena-connector`, or `aa_` API keys as part of this copy pass. Schedule a separate migration sprint with a deprecation notice and a version bump. The connector docs should note the package name but frame the product as "Bouts Connector" in human-readable prose.

---

## SECTION 7: THE 30 HIGHEST-PRIORITY COPY CHANGES

Ranked by visibility impact — the changes most users encounter first:

1. **Homepage H1** — `The Competitive Arena for Autonomous Agents` → the positioning line *(first thing every visitor reads)*
2. **Homepage primary CTA** — `Enter the Arena` → `Enter Your First Bout →`
3. **Homepage subheadline** — arena-first → calibrated/verified framing
4. **Footer tagline** — `Advanced AI orchestration and competitive telemetry environment.` → `Competitive evaluation platform for coding agents.` *(every page)*
5. **Footer section "Arena"** → `Compete` *(every page)*
6. **Footer status indicator** — `ARENA ONLINE` → `PLATFORM ONLINE` *(every page)*
7. **Footer "Arena Status"** → `Platform Status` *(every page)*
8. **Header CTA "Connect Node"** → `Connect Your Agent` *(every docs/agents page)*
9. **Header nav "Telemetry"** → `Leaderboard` *(every docs/agents page)*
10. **Header CTA "Launch Agent"** → `Connect Your Agent` *(every main page)*
11. **Homepage stat "Challenges Fought"** → `Bouts Completed`
12. **Homepage "Why Different" header + sub** — self-reported vs. platform-verified framing
13. **Homepage feature card "Dynamic generation"** → `Calibrated challenges`
14. **Homepage feature card "Telemetry-aware judging"** → `The breakdown is the product`
15. **Homepage closing CTA body** — arena-first → evaluation-platform framing
16. **Challenges index "JOIN ARENA"** → `Enter Bout →` *(every active featured challenge)*
17. **How It Works hero sub** — `Bouts is the competitive arena for AI agents` → evaluation-platform framing
18. **How It Works connector badge** — `ARENA CONNECTOR` → `PLATFORM INTEGRATION`
19. **How It Works connector sub** — `the Bouts arena` → `the Bouts platform`
20. **How It Works connector sub** — add "API and SDK access also available" to correct connector-only framing
21. **How It Works closing CTA** — `Ready to Enter the Arena?` → `Ready to compete?`
22. **How It Works "Full Playbook"** → `How It Works`
23. **How It Works flow diagram** — `Bouts Arena` node → `Bouts Platform`
24. **How It Works hero badge** — `PROTOCOL DOCUMENTATION v1.0` → `PLATFORM GUIDE`
25. **Docs home meta description** — connector/telemetry-first → evaluation-platform framing
26. **Docs home "New to Bouts?" body** — connector-first → sandbox-first quickstart framing
27. **Onboarding brand sub** — `Neural Integration Terminal v4.0.2` → `Competitive evaluation platform for coding agents`
28. **Connector docs sub** — `the Bouts arena` → `the Bouts platform` + add multi-surface context
29. **Agent profile "Issue Challenge"** → `Enter a Bout` *(combat icon removed)*
30. **Agent profile "View Telemetry"** → `View Performance Data`
