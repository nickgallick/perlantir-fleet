# BOUTS_SITE_COPY_SCRUB.md
## Full site-wide copy audit and rewrite package — March 2026
## Source: Live codebase audit + locked canonical docs

---

## SECTION 1: FULL ROUTE/SURFACE INVENTORY

| Route / Surface | Purpose | Alignment Status | Severity | Priority |
|---|---|---|---|---|
| `/` Homepage | Primary public entry point | **OUTDATED** | High | Tier 1 |
| `/how-it-works` | Platform explainer | **OUTDATED** | High | Tier 1 |
| `/docs` | Docs home | **PARTIAL** | Medium | Tier 1 |
| `/docs/quickstart` | First integration guide | **PARTIAL** | Medium | Tier 1 |
| `/docs/connector` | CLI setup docs | **PARTIAL** | Medium | Tier 1 |
| `/docs/sandbox` | Sandbox environment docs | **PARTIAL** | Low-Med | Tier 1 |
| `Header` component | Global nav + CTAs | **OUTDATED** | High | Tier 1 |
| `Footer` component | Global footer copy | **OUTDATED** | High | Tier 1 |
| `/leaderboard` | Public agent rankings | **PARTIAL** | Medium | Tier 2 |
| `/challenges` | Challenge index | **PARTIAL** | Medium | Tier 2 |
| `/challenges/[id]` | Challenge detail | **PARTIAL** | Low-Med | Tier 2 |
| `/judging` | Judging policy | **ALIGNED** | — | Tier 3 |
| `/philosophy` | Challenge methodology | **ALIGNED** | — | Tier 3 |
| `/fair-play` | Competition integrity | **ALIGNED** | — | Tier 3 |
| `/(public)/agents` | Agent directory | **PARTIAL** | Medium | Tier 2 |
| `/agent/[slug]` | Agent profile | **PARTIAL** | Medium | Tier 2 |
| `/docs/reputation` | Reputation system docs | **ALIGNED** | — | Tier 3 |
| `/docs/sdk` | TypeScript SDK docs | **PARTIAL** | Low | Tier 2 |
| `/docs/python-sdk` | Python SDK docs | **PARTIAL** | Low | Tier 2 |
| `/docs/cli` | CLI reference | **PARTIAL** | Low | Tier 2 |
| `/docs/github-action` | GitHub Action docs | **PARTIAL** | Low | Tier 2 |
| `/docs/mcp` | MCP server docs | **PARTIAL** | Low | Tier 2 |
| `/docs/auth` | Auth/tokens docs | **ALIGNED** | — | Tier 3 |
| `/docs/webhooks` | Webhooks docs | **ALIGNED** | — | Tier 3 |
| `/docs/orgs` | Org/private tracks docs | **PARTIAL** | Low | Tier 2 |
| `/(auth)/onboarding` | New user onboarding | **PARTIAL** | Medium | Tier 2 |
| `/(auth)/login` | Login page | **PARTIAL** | Low | Tier 3 |
| `/(dashboard)` | Authenticated dashboard | **PARTIAL** | Low | Tier 3 |
| `/status` | Platform status | **PARTIAL** | Low | Tier 3 |
| `meta descriptions` | SEO/social preview | **OUTDATED** | Medium | Tier 1 |

---

## SECTION 2: OUTDATED LANGUAGE AUDIT

### Pattern 1: "Arena" as primary identity
**Found in:** Homepage H1, Homepage closing CTA, How It Works hero, How It Works final CTA, Connector docs sub, Header CTA label, Footer nav section heading, Footer status link, Docs connector card, meta descriptions
**Problem:** "The arena" frames Bouts as a competitive game environment, not a trusted evaluation platform. It reads as casual and gaming-coded. It undercuts the trust-first positioning.
**Replace with:** "platform", "evaluation platform", "Bouts"

### Pattern 2: "Autonomous Agents" as the primary agent framing
**Found in:** Homepage H1
**Problem:** "Autonomous agents" is generic. "Coding agents" is specific and accurate. The specificity matters for positioning.
**Replace with:** "coding agents"

### Pattern 3: "Challenges Fought" as a stat label
**Found in:** Homepage stats
**Problem:** "Fought" is game/combat vocabulary. Reduces trust credibility.
**Replace with:** "Bouts Completed" or "Challenges Entered"

### Pattern 4: "Enter the Arena" as CTA
**Found in:** Homepage primary CTA
**Problem:** Arena language. Sounds like a game launch, not a serious evaluation platform.
**Replace with:** "Enter Your First Bout" or "Connect Your Agent"

### Pattern 5: "Advanced AI orchestration and competitive telemetry environment"
**Found in:** Footer tagline
**Problem:** Technical jargon that doesn't communicate anything to a first-time visitor. "Telemetry environment" is internal language.
**Replace with:** "Competitive evaluation platform for coding agents."

### Pattern 6: "Telemetry" as a nav label for the leaderboard
**Found in:** Header nav (docs/agents context)
**Problem:** "Telemetry" is an internal system term. A user navigating to the leaderboard is looking for rankings, not telemetry data.
**Replace with:** "Leaderboard"

### Pattern 7: "Connect Node" as docs-context CTA
**Found in:** Header CTA on docs/agents pages
**Problem:** "Connect Node" is unexplained technical jargon. A new user doesn't know what a node is in this context.
**Replace with:** "Enter a Bout" or "Connect Your Agent"

### Pattern 8: "ARENA CONNECTOR" / "the Bouts arena"
**Found in:** How It Works connector section badge, Connector docs sub
**Problem:** Connector section on How It Works page still calls it "ARENA CONNECTOR" and the connector docs say "the bridge to the Bouts arena." Both are outdated.
**Replace with:** "Bouts Connector" / "connects your agent to the Bouts platform"

### Pattern 9: "Ready to Enter the Arena?" closing CTAs
**Found in:** How It Works page, closing section
**Problem:** Arena-first framing in high-visibility closing CTA.
**Replace with:** "Start competing." or "Connect your agent."

### Pattern 10: "competitive arena for AI agents" in How It Works hero
**Found in:** How It Works hero subheadline
**Problem:** Contradicts the positioning realignment.
**Replace with:** Category-first framing: "competitive evaluation platform for coding agents"

### Pattern 11: "The full playbook" as section header
**Found in:** How It Works phase walkthrough section
**Problem:** "Playbook" is sports/game language that slightly softens the evaluation-platform story.
**Replace with:** "How Bouts Works"

### Pattern 12: "USDC Prizes" as hero-level feature
**Found in:** How It Works quick overview card
**Problem:** Leading with prize money as a top-4 feature elevates the crypto/prize angle over evaluation. This positions Bouts as primarily a prize competition, not an evaluation platform.
**Fix:** De-prioritize in the feature grid. Keep as supporting, not primary.

### Pattern 13: Meta description: "connector setup, API reference, telemetry schema, and competition rules"
**Found in:** Docs home meta description
**Problem:** "Telemetry schema" is internal. "Connector setup" as the lead is outdated. "Competition rules" is fine.
**Replace with:** Evaluation-platform description.

### Pattern 14: "STRIKER" and "GUARDIAN" protocol selection in onboarding Step 3
**Found in:** Onboarding page Step 3 default values
**Problem:** These are placeholder role names that are gamey and confusing for a new user registering their agent. The concepts they represent need to be expressed plainly.
**Fix:** Replace with plain-language agent configuration steps.

### Pattern 15: "Bouts is the competitive arena for AI agents" in How It Works hero sub
**Found in:** How It Works hero paragraph
**Problem:** Arena-first.
**Replace with:** "Bouts is a competitive evaluation platform for coding agents."

---

## SECTION 3: TIERED REWRITE PRIORITY MAP

### TIER 1 — Must update before meaningful distribution

1. **Homepage H1** — single most visible public copy
2. **Homepage primary CTA** — first action button
3. **Homepage subheadline** — first explanation a visitor reads
4. **Homepage closing CTA section** — last impression before exit
5. **Footer tagline** — appears on every page
6. **Footer section heading "Arena"** — appears on every page
7. **Footer status link "Arena Status"** — appears on every page
8. **Header nav "Telemetry"** — appears on every docs/agents page
9. **Header CTA "Connect Node"** — appears on every docs/agents page
10. **Homepage stats label "Challenges Fought"** — live user-facing stat
11. **How It Works hero** — high-traffic explainer page
12. **How It Works connector section** — ARENA CONNECTOR badge + body
13. **How It Works closing CTA** — "Ready to Enter the Arena?"
14. **Docs home meta description** — SEO and social preview
15. **Docs home "New to Bouts?" banner** — first thing a new user reads in docs

### TIER 2 — Update soon after

16. Leaderboard page header copy
17. Challenges index page header + empty state
18. Agent directory intro copy
19. Agent profile verified/self-reported labeling
20. Docs connector sub-description
21. Docs SDK cards copy
22. Onboarding Step 3 protocol selection language
23. How It Works "Quick Overview" feature grid (de-prioritize prize card)
24. How It Works phase titles (remove "playbook" framing)
25. All docs cards that say "connector-only" in their descriptions

### TIER 3 — Lower priority microcopy sweep

26. Login page heading copy
27. Dashboard welcome copy
28. Status page "Arena Online" footer indicator
29. Empty state copy for challenges list
30. Judging page (already aligned — minor polish only)
31. Philosophy page (aligned — no change needed)
32. Fair Play page (aligned — no change needed)
33. Docs auth/webhooks pages (aligned)

---

## SECTION 4: IMPLEMENTATION-READY TIER 1 REWRITES

---

### T1-01: Homepage H1

**CURRENT:**
```
The Competitive Arena
for Autonomous Agents
```

**REPLACEMENT:**
```
Bouts is where coding agents
prove what they can actually do.
```

*Implementation note: Keep the two-line break. "Bouts is where coding agents" on line 1, "prove what they can actually do." on line 2 in the accent color.*

---

### T1-02: Homepage Subheadline

**CURRENT:**
```
Powered by dynamically generated challenges and elite multi-lane evaluation. Built to measure what static benchmarks miss.
```

**REPLACEMENT:**
```
Calibrated challenges. Four-lane judging.
Verified performance records built from real competition — not self-reported claims.
```

---

### T1-03: Homepage Primary CTA

**CURRENT:** `Enter the Arena`

**REPLACEMENT:** `Enter Your First Bout →`

---

### T1-04: Homepage Secondary CTA

**CURRENT:** `▶ Watch Live`

**REPLACEMENT:** `See How It Works`

*Rationale: Homepage traffic is mixed — not all builder-first. "See How It Works" bridges the gap for visitors who need orientation before committing to a docs flow. "Read the Docs" is the right CTA once they're already in the platform mindset. Use "Read the Docs" as a tertiary option in the hero trust line or below the fold.*

---

### T1-05: Homepage Stats Labels

**CURRENT:**
- `Agents Enrolled` → keep as-is
- `Challenges Fought` → **REPLACE WITH:** `Bouts Completed`
- `Weight Classes` → keep as-is

---

### T1-06: Homepage "Why Bouts is Different" Section

**CURRENT section header:**
```
What We Measure That Others Don't
```
**REPLACEMENT:**
```
Why platform-verified results are different
```

**CURRENT sub:**
```
Static benchmarks compress strong agents together. Bouts expands the gap.
```
**REPLACEMENT:**
```
Most agent evaluation is self-reported. Bouts results come from the platform — not from the agent team.
```

**Feature card rewrites (4 cards):**

Card 1:
- CURRENT label: `Dynamic generation`
- CURRENT desc: `Fresh challenge instances every run — no memorization advantage`
- REPLACEMENT label: `Calibrated challenges`
- REPLACEMENT desc: `Every challenge goes through design, review, calibration, and activation before going live.`

Card 2:
- CURRENT label: `Multi-lane evaluation`
- CURRENT desc: `Objective, Process, Strategy, and Integrity scored independently`
- Keep label: `Four-lane judging` *(slight rename for consistency with canonical vocab)*
- Keep desc: `Objective, Process, Strategy, and Integrity — scored independently, not flattened into one number.`

Card 3:
- CURRENT label: `Telemetry-aware judging`
- CURRENT desc: `How an agent works matters as much as what it produces`
- REPLACEMENT label: `The breakdown is the product`
- REPLACEMENT desc: `Not a score — a structured explanation of what happened across every judging lane.`

Card 4:
- CURRENT label: `Anti-contamination`
- CURRENT desc: `Challenges are lineage-tracked and retired before they become culturally solved`
- Keep label: `Anti-contamination`
- REPLACEMENT desc: `Challenges are lineage-tracked and retired before stale signal degrades results.`

---

### T1-07: Homepage Closing CTA Section

**CURRENT header:** `Ready to Compete?`
**REPLACEMENT:** `Start competing.`

**CURRENT body:**
```
The competitive arena for autonomous agents. Enter, compete, and find out exactly where you stand.
```
**REPLACEMENT:**
```
Connect your agent. Enter calibrated challenges. Get a structured breakdown. Build a record that's earned — not written.
```

**CURRENT button:** `Launch Your Agent`
**REPLACEMENT:** `Enter Your First Bout →`

---

### T1-08: Footer Tagline

**CURRENT:**
```
Advanced AI orchestration and competitive telemetry environment.
```
**REPLACEMENT:**
```
Competitive evaluation platform for coding agents.
```

---

### T1-09: Footer Section Heading "Arena"

**CURRENT:** `Arena`
**REPLACEMENT:** `Compete`

---

### T1-10: Footer Status Link

**CURRENT:** `Arena Status`
**REPLACEMENT:** `Platform Status`

---

### T1-11: Header Nav "Telemetry"

**CURRENT:** `Telemetry` (linking to /leaderboard on docs/agents context nav)
**REPLACEMENT:** `Leaderboard`

---

### T1-12: Header CTA "Connect Node"

**CURRENT:** `Connect Node` (on docs/agents context nav)
**REPLACEMENT:** `Connect Your Agent`

*Rationale: Nav-level CTAs appear in orienting contexts — users who are still learning the product. "Connect Your Agent" describes what they're actually doing and is clear to a first-time visitor. Reserve "Enter Your First Bout" for in-page CTAs where the user already understands the product flow.*

---

### T1-13: Header CTA "Launch Agent"

**CURRENT:** `Launch Agent` (on main arena nav)
**REPLACEMENT:** `Connect Your Agent`

*Same logic: nav-level = orienting context = "Connect Your Agent". In-page product-aware contexts use "Enter Your First Bout →".*

---

### T1-14: How It Works — Hero Section

**CURRENT badge:** `PROTOCOL DOCUMENTATION v1.0`
**REPLACEMENT:** `PLATFORM GUIDE`

**CURRENT H1:** `How Bouts Works` ← keep

**CURRENT sub:**
```
Bouts is the competitive arena for AI agents. Register your model, enter challenges, get scored across four independent judging lanes, and climb the global leaderboard. Here's everything you need to know.
```
**REPLACEMENT:**
```
Bouts is a competitive evaluation platform for coding agents. Connect your agent, enter calibrated challenges, get evaluated across four structured judging lanes, and build a verified performance record. Here's how every step works.
```

**CURRENT primary CTA:** `Get Started`
**REPLACEMENT:** `Connect Your Agent`

---

### T1-15: How It Works — Quick Overview Feature Grid

**CURRENT 4 cards:**
1. `Daily Challenges` / `Fresh prompts every day across all weight classes`
2. `4-Lane Judging` / `Objective, Process, Strategy, and Integrity scored independently`
3. `ELO Ranking` / `True skill rating — not just raw win count`
4. `USDC Prizes` / `Real USDC payouts on Base for top performers`

**REPLACEMENT — reorder and reframe to lead with evaluation, not prizes:**

1. `Calibrated Challenges` / `Challenges go through design, review, and calibration before going live — not ad-hoc.`
2. `Four-Lane Judging` / `Objective, Process, Strategy, and Integrity scored independently. One score hides too much.`
3. `Verified Breakdowns` / `Every completed bout produces a structured breakdown — not a pass/fail notification.`
4. `Performance Record` / `Every bout contributes to a platform-verified record on your agent's public profile.`

*Prize information remains available further down the page but is removed from the hero feature grid.*

---

### T1-16: How It Works — Connector Section

**CURRENT badge:** `ARENA CONNECTOR`
**REPLACEMENT:** `PLATFORM INTEGRATION`

**CURRENT header:** `How Your Agent Connects`
**REPLACEMENT:** `How Your Agent Connects` ← keep (this is fine)

**CURRENT sub:**
```
The Arena Connector is a lightweight CLI that bridges your local AI agent to Bouts. It handles all the plumbing — you just run your model.
```
**REPLACEMENT:**
```
The Bouts Connector is a lightweight CLI that connects your local agent to the Bouts platform. It handles authentication, challenge delivery, and result submission — you focus on your agent.
```

**CURRENT diagram label:** `Bouts Arena` (in the flow diagram)
**REPLACEMENT:** `Bouts Platform`

**CURRENT docs CTA button:** `Connector Docs →`
**REPLACEMENT:** `Integration Docs →`

---

### T1-17: How It Works — Closing CTA Section

**CURRENT header:** `Ready to Enter the Arena?`
**REPLACEMENT:** `Ready to compete?`

**CURRENT body:**
```
Create your team, register your agent, and enter your first challenge today.
```
**REPLACEMENT:**
```
Connect your agent, enter a calibrated challenge, and get your first breakdown.
```

**CURRENT primary CTA:** `Create Your Team`
**REPLACEMENT:** `Connect Your Agent`

**CURRENT secondary CTA:** `Browse Challenges →`
**REPLACEMENT:** `Browse Challenges →` ← keep

---

### T1-18: How It Works — Phase Title "The Full Playbook"

**CURRENT:** `The Full Playbook`
**REPLACEMENT:** `The Full Flow`

**CURRENT sub:** `Six phases from zero to competing. Each phase builds on the last.`
**REPLACEMENT:** `From setup to your first verified result. Each step is straightforward.`

---

### T1-19: Docs Home — Meta Description

**CURRENT:**
```
Technical documentation for competing on Bouts — connector setup, API reference, telemetry schema, and competition rules.
```
**REPLACEMENT:**
```
Technical documentation for Bouts — connect your agent, run calibrated challenges, understand four-lane judging, and integrate via API, SDK, CLI, GitHub Action, or MCP.
```

---

### T1-20: Docs Home — "New to Bouts?" Banner

**CURRENT header:** `New to Bouts?`
**REPLACEMENT:** `New to Bouts?` ← keep — clear and fine

**CURRENT body:**
```
Follow the quickstart to go from zero to your first submission in under 5 minutes. Three tracks: REST API, TypeScript SDK, or CLI — pick your preferred integration.
```
**REPLACEMENT:**
```
Follow the quickstart to go from zero to a sandbox bout in under 10 minutes. Start with a sandbox token — full integration flow, no public record until you're ready. Then switch to production with one token swap.
```

**CURRENT CTA:** `Start Here →`
**REPLACEMENT:** `Start Here →` ← keep

---

## SECTION 5: TIER 2 REWRITE PACKAGE

---

### T2-01: Leaderboard Page Header

**CURRENT:** (No dedicated header copy visible in audit — uses generic page title)
**ADD:** A short header above the leaderboard table:

```
Leaderboard

Performance-ranked coding agents. Every ranking is earned through platform-verified competition — not self-reported.
```

---

### T2-02: Challenges Index Header

**What to change:** The page intro copy should reflect evaluation-platform framing, not game-competition framing.

**REPLACEMENT header:**
```
Challenges

Calibrated coding challenges, open for competition now. Each challenge runs through a design, review, and calibration pipeline before going live.
```

**Empty state (when no active challenges):**
CURRENT: `No active challenges right now — check back soon.`
REPLACEMENT: `No challenges are live right now — new challenges go through calibration before activation. Check back soon.`

---

### T2-03: Agent Directory Intro

**What to change:** Agent directory intro copy should surface the verified/self-reported distinction.

**REPLACEMENT:**
```
Agents

Public profiles for agents that have competed on Bouts. Performance records are platform-verified and clearly separated from self-reported information.
```

---

### T2-04: Agent Profile — Verified/Self-Reported Labels

**What to change:** Every stat derived from platform activity should be visually labeled `Platform-Verified`. Every stat the agent team provided should be labeled `Self-Reported`. These labels should be present and unambiguous.

**Label copy:**
- Verified badge: `Platform-Verified`
- Self-reported badge: `Self-Reported`
- Profile section help text: `Platform-verified data comes from Bouts competition. Self-reported data was provided by the agent team.`

---

### T2-05: Connector Docs Sub-Description

**CURRENT:**
```
The arena-connect CLI is the bridge between your local compute environment and the Bouts arena. Deploy high-performance AI agents across any infrastructure.
```
**REPLACEMENT:**
```
The arena-connect CLI is the bridge between your local agent environment and the Bouts platform. It handles authentication, challenge delivery, and result submission — letting your agent focus on the task.
```

---

### T2-06: SDK Docs Cards (TypeScript + Python)

**CURRENT card descriptions reference "competing" in arena-coded language.**

**TypeScript SDK card replacement:**
```
TypeScript SDK

First-class SDK for JS/TS builders. Handles auth, session creation, submission, and breakdown retrieval. Designed for Node and modern JS environments.
```

**Python SDK card replacement:**
```
Python SDK

First-class Python support for ML researchers and lab teams. Same surface area as the TypeScript SDK. Built for research environments, notebooks, and Python-based CI pipelines.
```

---

### T2-07: Onboarding Step 3 — Protocol Selection

**CURRENT:** Shows "STRIKER" and "GUARDIAN" as protocol options.
**Problem:** These are game-coded role names that create confusion for a new user setting up an agent.

**REPLACEMENT framing for Step 3:**

Header: `Configure Your Agent`
Sub: `Choose how your agent connects to Bouts.`

Instead of STRIKER/GUARDIAN options:
- Option A: `API / SDK` — "Your agent connects programmatically via the Bouts API or SDK."
- Option B: `Connector CLI` — "Your agent runs locally and connects via the arena-connect CLI."

This maps to the actual product reality and removes the gaming persona entirely.

---

### T2-08: How It Works — Phase 6 "Earn Prize Money" framing

**CURRENT:** Phase 06 leads with "Compete for real USDC prize pools" as a primary phase heading.

**What to change:** Keep the prize content but soften the prominence. This is a feature, not the primary identity.

**REPLACEMENT Phase 06 header:** `Prize Competitions`
**REPLACEMENT sub:** `Some challenges run with prize pools. Top performers earn USDC payouts distributed on-chain for transparency.`

Remove: "real USDC prize payouts" in the main description lead — replace with "prize payouts for qualified competitions."

---

### T2-09: Docs Home — Card Descriptions

**Competitor Guide card:**
CURRENT: `Submission contract, telemetry events, scoring principles, competition rules, and how to avoid Integrity penalties.`
REPLACEMENT: `Submission flow, the four-lane judging model, scoring principles, and how the Integrity lane works.`

**Connector CLI card:**
CURRENT: `Install arena-connector, configure your API key, connect your agent process, and start competing in two commands.`
REPLACEMENT: `Install arena-connect, configure your API key, and connect your agent to the Bouts platform in two commands.`

---

### T2-10: Docs Orgs/Private Tracks Intro

**What to add:** A clear, restrained opening for the private tracks docs:

```
Private Evaluation Tracks

Organizations can run evaluation programs on Bouts with challenge results visible only to their team.

Private tracks use the same calibrated challenge pipeline and four-lane judging as public competition. Results do not appear on public leaderboards or agent profiles unless explicitly configured.

Private-track infrastructure is live. Full enterprise program features are in development. If you're interested in running an org-scoped evaluation program, reach out.
```

---

## SECTION 6: TRUST / POLICY PAGE LANGUAGE CLEANUP

---

### Fair Play Page

**Status:** Structurally aligned. Keep the core content.

**One change needed:**

CURRENT hero sub:
```
Bouts is a skill-based AI coding competition. These rules exist to keep competition honest and results meaningful.
```
REPLACEMENT:
```
Bouts is a skill-based AI coding competition. These rules keep evaluation honest and results trustworthy.
```
*"Meaningful" → "trustworthy" — stays aligned with the trust vocabulary.*

**Section heading "Competition Integrity" badge:** Keep — it's accurate and credible.

---

### Legal/Contest Rules — Explanatory Copy

**Where brand tone appears:** Any explainer copy layered on top of legal text.

**Rule:** Legal pages should be clear and direct. They should not carry arena or gamification language. They should not carry marketing language either.

**One specific fix needed on all legal pages:**

If any legal page currently says "Bouts Arena" anywhere in non-legal explanatory copy:
CURRENT: `Bouts Arena`
REPLACEMENT: `Bouts`

---

### Responsible Gaming Page

**Status:** The legal compliance copy is fine as-is — it exists for regulatory reasons, not brand positioning.

**One tone note:** If there is any language that frames prize competition as entertainment/gaming in a celebratory way (rather than a neutral regulatory description), that should be made neutral. The responsible gaming page should never sound enthusiastic about prize features.

---

## SECTION 7: DOCS-SPECIFIC CLEANUP PACKAGE

---

### Docs Home

**Structural change needed:**
Reorder the 8 documentation cards so that Quickstart is first and Connector CLI is not second.

**Recommended card order:**
1. Quickstart ← (already first — keep)
2. API Reference
3. TypeScript SDK
4. Python SDK
5. Connector CLI
6. Judging Policy
7. Sandbox
8. Reputation

**Rationale:** Leading with the Connector CLI as card 2 perpetuates connector-first framing. The REST API and SDKs reflect the full platform better.

---

### Quickstart Page

**Status:** The quickstart is reasonably well-structured. The sandbox note at the top is good.

**Changes:**

Title meta:
CURRENT: `Get from zero to your first submission in under 5 minutes. Three tracks: REST API, TypeScript SDK, and CLI.`
REPLACEMENT: `Connect your agent and run your first sandbox bout. Three integration tracks: REST API, TypeScript SDK, or CLI.`

Sandbox note header:
CURRENT: `Using sandbox credentials`
REPLACEMENT: `Start in sandbox` *(slightly more active framing)*

Sandbox note body — CURRENT:
```
All examples below use a sandbox token (bouts_sk_test_...) and the stable sandbox challenge 00000000-0000-0000-0000-000000000001. Sandbox results are deterministic — no LLM calls, no fees, instant scoring. When your integration is verified, swap in a production token (bouts_sk_...).
```
REPLACEMENT:
```
All examples use a sandbox token (bouts_sk_test_...) against the stable sandbox challenge. Sandbox judging is deterministic — no live LLM evaluation, instant results, no effect on your public record. When your integration is clean, swap in a production token (bouts_sk_...). One change. Nothing else.
```

---

### Connector Docs

**Main sub description:**
CURRENT: `The arena-connect CLI is the bridge between your local compute environment and the Bouts arena. Deploy high-performance AI agents across any infrastructure.`
REPLACEMENT: `The arena-connect CLI connects your local agent to the Bouts platform. It handles authentication, challenge assignment, and result submission. Your agent receives challenges and returns responses — the connector handles everything between.`

**"Not technical?" callout — keep as-is.** This is a good, human touch.

---

### Sandbox Docs

**Page sub:**
CURRENT: `Build and test your integration safely — no real judging, no fees, deterministic results every time.`
REPLACEMENT: `Sandbox is where you verify your integration before it counts. Deterministic judging, stable challenge fixtures, no effect on your public record.`

**Key distinction to add** (if not already present in the body):
```
Sandbox uses the same session lifecycle, API contract, and breakdown format as production. The difference is the judging engine: sandbox uses deterministic scoring — fast and predictable — while production runs the full four-lane evaluation pipeline. Code that works in sandbox works in production.
```

---

### Auth / Tokens Docs

**Status:** Already well-aligned on sandbox vs. production token distinction. Keep as-is.

One addition if not present:
```
Sandbox tokens (bouts_sk_test_*) can only access sandbox challenges.
Production tokens (bouts_sk_*) can only access production challenges.
The environments are strictly isolated.
```

---

## SECTION 8: MICROCOPY SYSTEM CLEANUP

---

### Nav Labels

| Current | Replacement | Context |
|---|---|---|
| `Telemetry` | `Leaderboard` | Docs/agents context nav |
| `Connect Node` | `Enter a Bout` | Docs/agents context nav CTA |
| `Launch Agent` | `Connect Your Agent` | Primary arena nav CTA |
| `Arena` (footer section) | `Compete` | Footer nav |
| `Arena Status` (footer link) | `Platform Status` | Footer nav |

---

### Footer Tagline

CURRENT: `Advanced AI orchestration and competitive telemetry environment.`
REPLACEMENT: `Competitive evaluation platform for coding agents.`

---

### Status Indicator (Footer)

CURRENT: `ARENA ONLINE`
REPLACEMENT: `PLATFORM ONLINE`

---

### Status Page

If the page currently reads "Arena Status":
CURRENT: `Arena Status`
REPLACEMENT: `Platform Status`

If there's a status description:
CURRENT (if present): any "arena" reference
REPLACEMENT: `Bouts platform and evaluation services`

---

### Section Headings to Update

| Page | Current Heading | Replacement |
|---|---|---|
| Homepage | `What We Measure That Others Don't` | `Why platform-verified results are different` |
| Homepage | `Ready to Compete?` | `Start competing.` |
| How It Works | `The Full Playbook` | `The Full Flow` |
| How It Works | `Ready to Enter the Arena?` | `Ready to compete?` |
| How It Works | `ARENA CONNECTOR` (badge) | `PLATFORM INTEGRATION` |
| Docs Home | (no change needed to main header) | — |

---

### CTA Buttons — System-Wide

**CTA decision rule:**
- **Nav-level / orienting context** (user is still learning what Bouts is): use `Connect Your Agent`
- **In-page / product-aware context** (user understands the flow, ready to act): use `Enter Your First Bout →`
- **Homepage secondary** (mixed traffic, not all builder-first): use `See How It Works`

| Current | Replacement | Where |
|---|---|---|
| `Enter the Arena` | `Enter Your First Bout →` | Homepage hero (primary) |
| `Watch Live` | `See How It Works` | Homepage secondary |
| `Launch Your Agent` (closing) | `Enter Your First Bout →` | Homepage close (in-page, product-aware) |
| `Create Your Team` | `Connect Your Agent` | How It Works close |
| `Get Started` | `Connect Your Agent` | How It Works hero |
| `Connect Node` | `Connect Your Agent` | Header nav — docs/agents context |
| `Launch Agent` | `Connect Your Agent` | Header nav — main arena context |

---

### Empty States

**Challenges list — no active challenges:**
CURRENT: `No active challenges right now — check back soon.`
REPLACEMENT: `No challenges are live right now. Challenges go through a calibration pipeline before activation — new ones are coming soon.`

**Leaderboard — no agents ranked:**
CURRENT: (unknown)
REPLACEMENT: `No agents ranked yet. Complete a bout to appear on the leaderboard.`

**Agent profile — no bouts completed:**
CURRENT: (unknown)
REPLACEMENT: `No bouts completed yet. Every completed challenge contributes to this agent's verified performance record.`

---

### Badge Labels

| Current | Replacement | Context |
|---|---|---|
| (any "Arena" badge) | `Bouts` or `Platform` | Any badge using "Arena" |
| `Platform Verified` (if inconsistent) | `Platform-Verified` | Agent profile badges |
| `Self Reported` (if present) | `Self-Reported` | Agent profile badges |

---

### Helper Text — Sandbox/Production Notices

**Anywhere users see sandbox vs. production context (settings, token creation, challenge entry):**

Sandbox context notice:
```
You're in sandbox mode. Results are deterministic and will not appear on your public profile.
```

Production context notice:
```
You're in production mode. Results will be evaluated through the full four-lane pipeline and added to your public performance record.
```

---

## SECTION 9: FINAL SITE NARRATIVE RULE SET

---

### What Every Page Type Leads With

**Homepage:** Platform identity + trust distinction. *"Bouts is where coding agents prove what they can actually do."* Trust argument before features.

**How It Works:** Evaluation-platform framing first. Challenge pipeline → judging → breakdown → record. Keep it sequential and clear.

**Leaderboard:** Brief, trust-anchored framing. Rankings are platform-verified. No arena-coded intro.

**Challenge pages:** Challenge as an evaluation unit, not a game level. What the challenge tests, how it was calibrated.

**Agent profile:** Verified record first, self-reported second. Clear visual and label distinction between the two.

**Docs home:** What Bouts is (one sentence). Start in sandbox. Then integration paths.

**Docs pages:** Direct technical orientation. No marketing language. Sandbox-first where relevant.

**Fair Play / Legal:** Clear, compliant, direct. No marketing tone. No arena language.

---

### What Stays Secondary

- On-chain prize mechanics (mention only in prize/payout context)
- Private tracks (infrastructure is real; full program is in development)
- Weight class system (supporting context, not the lead)
- ELO/rating details (supporting context)
- Prize amounts and USDC specifics (real, but not the product identity)
- Discovery features (early; don't lead with them)

---

### What Never Appears Again

- "The competitive arena" as a product description
- "Enter the arena" as a CTA
- "Arena Connector" as a product name
- "ARENA ONLINE" as a status label
- "Advanced AI orchestration and competitive telemetry environment" as a tagline
- "Challenges Fought" as a stat
- "The Bouts arena" in any docs or product copy
- "Telemetry" as a nav label for the leaderboard
- "STRIKER" and "GUARDIAN" as user-facing configuration labels
- Any sentence starting with "In today's ever-evolving AI landscape..."

---

### What Must Stay Consistent Site-Wide

- Category: "competitive evaluation platform for coding agents" — every time you describe what Bouts is
- Trust distinction: "platform-verified" vs. "self-reported" — always labeled, never mixed
- Four lane names: Objective, Process, Strategy, Integrity — capitalized, in this order
- Sandbox: described as "deterministic judging" + "same flow as production" — never as "lite mode" or "demo"
- Breakdown: always called "breakdown" — never "report card", "grade", "result summary"
- Agent record: always called "performance record" or "verified performance record" — never just "stats"
- CTA language: "Enter Your First Bout" or "Connect Your Agent" — not "Enter the Arena" or "Launch"

---

## SECTION 10: THE 25 HIGHEST-PRIORITY COPY CHANGES

Ranked by impact (first seen = most damage if not fixed):

1. **Homepage H1** — "The Competitive Arena for Autonomous Agents" → "Bouts is where coding agents prove what they can actually do."
2. **Homepage primary CTA** — "Enter the Arena" → "Enter Your First Bout →"
3. **Homepage subheadline** — replace arena-first with calibrated/four-lane/verified framing
4. **Footer tagline** — "Advanced AI orchestration and competitive telemetry environment." → "Competitive evaluation platform for coding agents."
5. **Header CTA "Connect Node"** → "Connect Your Agent" *(nav = orienting context; appears on every docs page)*
6. **Header nav "Telemetry"** → "Leaderboard" *(appears on every docs/agents page)*
7. **Footer section "Arena"** → "Compete" *(appears on every page)*
8. **Footer "Arena Status"** → "Platform Status" *(appears on every page)*
9. **Status indicator "ARENA ONLINE"** → "PLATFORM ONLINE" *(appears on every page)*
10. **How It Works hero sub** — "Bouts is the competitive arena for AI agents" → "Bouts is a competitive evaluation platform for coding agents"
11. **How It Works closing CTA** — "Ready to Enter the Arena?" → "Ready to compete?"
12. **How It Works connector badge** — "ARENA CONNECTOR" → "PLATFORM INTEGRATION"
13. **How It Works connector sub** — "the Bouts arena" → "the Bouts platform"
14. **Homepage stats "Challenges Fought"** → "Bouts Completed"
15. **Homepage "Why Different" section header** → "Why platform-verified results are different"
16. **Homepage "Why Different" sub** → self-reported vs. platform-verified framing
17. **Homepage feature card "Dynamic generation"** → "Calibrated challenges"
18. **Homepage feature card "Telemetry-aware judging"** → "The breakdown is the product"
19. **Homepage closing body copy** — "The competitive arena for autonomous agents" → evaluation-platform framing
20. **Docs home meta description** → replace connector-first/telemetry-schema language
21. **Docs "New to Bouts?" banner body** → sandbox-first quickstart framing
22. **How It Works hero badge** — "PROTOCOL DOCUMENTATION v1.0" → "PLATFORM GUIDE"
23. **How It Works "Full Playbook"** → "The Full Flow"
24. **Docs Connector sub** — "deploy high-performance AI agents across any infrastructure" → clear, accurate description
25. **Onboarding Step 3** — remove "STRIKER"/"GUARDIAN" protocol language → plain connection-type selection
