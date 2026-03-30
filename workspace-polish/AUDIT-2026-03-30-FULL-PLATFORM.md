# Polish Full-Platform Audit — Bouts
**Date:** 2026-03-30  
**Auditor:** Polish ✨  
**Coverage:** 30+ routes across public, docs, auth, dashboard, legal, mobile  
**Method:** Playwright browser passes (2) + codebase inspection  
**Standard:** Enterprise SaaS / premium technical platform (Vercel, Linear, Notion tier)

---

## 1. OVERALL POLISH VERDICT

### 🟡 LAUNCH-SAFE BUT NOT FINISHED

Bouts has made real progress. The homepage reads with genuine product point of view. The footer is legally credible. The docs suite is substantive. The four-lane judging framing is genuinely distinctive.

But there are meaningful finish-line issues that will read as "not done" to any serious operator or developer who pokes around: auth routes are 404ing, terminology leaks internal schema language, the challenges page still says "Arena Challenges," key routes like `/about`, `/pricing`, `/docs/web-submission`, `/profile`, `/submissions`, and `/settings/tokens` are all 404s, and the leaderboard is showing cryptic sub-rating abbreviations (P17 / S10 / I50 / E50) that mean nothing to an outside user.

The platform is not embarrassing. But it is not finished. The gap between "the homepage feels premium" and "the rest of the platform lives up to that" is still real.

**Grade: B−**  
**Letter rating: 7.1 / 10 overall**  
**Launch recommendation: Hold — fix P0s and P1s before any operator/press exposure. Soft launch with known users is acceptable now. Public-first launch requires the fix list below.**

---

## 2. SCORECARD

| Dimension | Score | Notes |
|---|---|---|
| Visual Maturity | 7.5 | Homepage strong. Challenges list unfinished. Challenge detail feels sparse. |
| Copy Maturity | 6.5 | Homepage copy is sharp. Internal pages leak schema language. "Arena Challenges," "neural combatants," "SECTOR NOT FOUND / current iteration" are off-brand. |
| Information Hierarchy | 6.0 | Leaderboard sub-rating row is opaque. Challenge detail metadata is raw DB values. Workspace state machine is invisible to users. |
| Interaction Quality | 6.5 | Login/signup 404 is a hard blocker. Dashboard agent registration is functional but copy is gamey. Workspace flow untestable due to auth failure. |
| Mobile / Responsive Quality | 7.0 | Responsive sweep passed. No hamburger menu on desktop nav — mobile nav exists but pattern is acceptable. |
| Enterprise Readiness | 5.5 | Hardcoded API URLs in docs (`agent-arena-roan.vercel.app`). No `/about` or `/pricing`. Auth routes 404. Profile 404. Key linked routes are dead. |
| Trust Signal Quality | 6.5 | Footer legal block is strong. Legal pages are substantive. But auth 404s destroy operator trust on first contact. |
| Marketing/Product Consistency | 6.0 | Homepage and challenge detail tell different stories. "Arena Challenges" on challenges page contradicts the Bouts brand. How-it-works links to `/onboarding` which doesn't exist. |
| Anti-AI-Built Quality | 7.0 | Homepage avoids AI-smell words. Docs are substantive. But "orchestrate your autonomous neural combatants" and the 404 page's "current iteration" language feel generated. |
| Overall Product Polish | 6.5 | Strong foundation, real product POV, but too many broken links and raw-schema leaks to call it finished. |

---

## 3. TOP STRENGTHS

**1. Homepage copy has a genuine point of view.**  
"Bouts is where coding agents prove what they can actually do." — This is real. It's not a template headline. The sub-framing ("not self-reported capability," "four-lane judging") is distinctive and earns trust.

**2. Footer is legally credible.**  
The responsible gaming strip, Iowa arbitration, NCPG hotline, state exclusions — this signals a real company with real legal counsel. It anchors trust for any operator who reads to the bottom.

**3. Docs suite is substantive.**  
Quickstart, Connector CLI, API Reference, SDK, CLI, GitHub Action, MCP — every path exists and has real content. This is enterprise-grade docs breadth for a product at this stage.

**4. Legal pages are real.**  
Terms of Service, Privacy Policy, Contest Rules — these are actual documents, not placeholders. Perlantir AI Studio LLC is consistently named as the legal entity.

**5. Four-lane judging framing is genuinely differentiated.**  
Objective / Process / Strategy / Integrity — this is not a generic benchmark. It's a real product concept that stands apart from "score = correct or not."

**6. 404 page has character.**  
"Sector Not Found" with the bold typographic treatment is the right idea — it fits the aesthetic. (The copy inside it needs work — see P2 issues.)

---

## 4. TOP WEAKNESSES

**1. Auth routes are completely broken.**  
`/auth/login`, `/auth/signup`, `/auth/forgot-password` all return 404. The actual login page is at `/login`. This means any link in the codebase pointing to `/auth/login` — including nav CTAs, docs links, challenge detail "Sign in to Enter" redirects — may silently send users to a 404 wall. This is a P0.

**2. "Arena Challenges" is still the H1 on the challenges listing page.**  
This is one of the most visible on-brand failures in the entire product. It directly contradicts the Bouts brand. (Code: `src/app/(public)/challenges/page.tsx:102`)

**3. Raw DB values are surfaced as user-facing labels.**  
- Challenge detail shows `category: Speed_build` (snake_case from the DB, not formatted)
- Leaderboard shows `P17 / S10 / I50 / E50` — opaque abbreviations that mean nothing to an outside viewer
- Workspace shows `Weight Class: contender` (raw DB value)

**4. Critical routes are 404.**  
`/about`, `/pricing`, `/docs/web-submission`, `/profile`, `/profile/settings`, `/submissions`, `/settings/tokens`, `/legal/responsible-gaming` — all 404. Some of these are linked from live pages and docs.

**5. Docs hardcode the dev URL.**  
`agent-arena-roan.vercel.app` appears in API examples in Quickstart, API Reference, and Sandbox docs. These should be `bouts.gg` or at minimum `your-domain.com`.

**6. Dashboard copy is over-gamified.**  
"Orchestrate your autonomous neural combatants" — this is trying too hard. It reads like a game, not a serious evaluation platform. The Bouts tone is competitive and serious, not sci-fi.

**7. How-it-works page links to `/onboarding` which doesn't exist.**  
Phase 1 CTA: "Create Your Team" → `/onboarding` → 404. This is the discovery path for new users.

---

## 5. ISSUE LIST BY SEVERITY

### P0 — Trust-destroying / brand-damaging

**P0-01: Auth routes return 404**  
- `/auth/login`, `/auth/signup`, `/auth/forgot-password` all 404
- The real route is `/(auth)/login` which renders at `/login`
- Anything linking to `/auth/login` sends users to a 404 page
- Fix: Audit every link in the codebase pointing to `/auth/*` and update to `/login` OR add redirects from `/auth/login` → `/login`, `/auth/signup` → `/signup` (or wherever registration lives)

**P0-02: "Arena Challenges" as the challenges list H1**  
- File: `src/app/(public)/challenges/page.tsx:102`
- Change to: "Challenges" or "Open Challenges"
- Takes 30 seconds to fix, destroys brand coherence until it is

**P0-03: `docs/web-submission` is a 404**  
- The docs nav and multiple internal links reference this page
- It's the primary path for browser-based submission — the core demo flow
- A 404 here tells any evaluating developer the product is unfinished

---

### P1 — Major product polish failure

**P1-01: Raw DB values as user-facing labels on challenge detail**  
- `category: Speed_build` should be "Speed Build"
- `format: sprint` should be "Sprint" (capitalized)
- `weight_class_id: contender` should have a display mapping
- All three are surfaced raw in the challenge detail metadata strip and workspace header
- Fix: Add display mapping in the component — not a DB change

**P1-02: Leaderboard sub-rating abbreviations (P17 / S10 / I50 / E50) are unexplained**  
- Source: `spectate-client.tsx:309-312` — P = Process, S = Strategy, I = Integrity, E = (Execution/Objective?)
- No legend, no tooltip, no label — completely opaque to a first-time viewer
- Fix: Add a tooltip on hover or a small legend row below the column header: "P = Process · S = Strategy · I = Integrity · E = Objective"

**P1-03: `/about` and `/pricing` return 404, yet these are implied by the footer and navigation**  
- If these pages genuinely don't exist yet, remove links to them
- If they should exist, build stubs — even a 2-section about page is better than a 404
- The footer and nav create expectation; the 404 destroys it

**P1-04: `/profile`, `/profile/settings`, `/submissions`, `/settings/tokens` all 404**  
- These are expected post-login destinations
- After successful auth, a user who navigates to profile or submissions hits a 404
- Fix: Either build the routes or ensure the nav doesn't expose these links to logged-in users yet

**P1-05: Docs hardcode `agent-arena-roan.vercel.app` in curl examples**  
- Files: `docs/quickstart/page.tsx:231`, `docs/api/page.tsx:494`, `docs/sandbox/page.tsx:268`
- This is the Vercel preview domain, not a real product domain
- Tells any developer reading the docs that the product is in development
- Fix: Replace with `api.bouts.gg` or `{{BASE_URL}}` placeholder syntax

**P1-06: How-it-works Phase 1 CTA links to `/onboarding` which doesn't exist**  
- "Create Your Team" → `/onboarding` → 404
- This is the primary entry point for new users reading the how-it-works page
- Fix: Point to `/login` or `/dashboard/agents` or wherever account creation actually lives

**P1-07: "Orchestrate your autonomous neural combatants" — agents dashboard headline**  
- File: `src/app/(dashboard)/agents/page.tsx:255`
- Current: "Orchestrate your autonomous neural combatants."
- Reads like an AI-written sci-fi game, not a serious evaluation platform
- Fix: "Register and manage the agents you're fielding in competition." or similar

**P1-08: Challenge detail shows "Sign in to Enter" but auth routes 404**  
- The "Sign in to Enter" CTA presumably redirects to `/auth/login` or `/login`
- If it's pointing to `/auth/login`, the user hits a 404 instead of a login form
- This is the single most important conversion path on the platform
- Fix: Ensure CTA redirects to `/login?redirect=/challenges/[id]`

---

### P2 — Meaningful but non-blocking

**P2-01: 404 page copy — "current iteration" is off-brand**  
- "The path you are seeking does not exist in the current iteration."
- "Current iteration" is AI/agile jargon. It sounds synthetic.
- Fix: "The page you're looking for doesn't exist." or keep "Sector Not Found" as the headline but drop the body copy gamification

**P2-02: "THE EVALUATION PLATFORM FOR AUTONOMOUS AGENTS" on the login page**  
- This is the subtitle below "Sign in to Bouts"
- "For autonomous agents" implies the agents themselves sign in, not the operators
- Fix: "The competitive evaluation platform for coding agents." — matches footer and is more accurate

**P2-03: "END-TO-END SECURE" / "LOW LATENCY AUTH" badges on login page**  
- These feel like AI-generated trust badges with no substance
- "LOW LATENCY AUTH" is not a meaningful trust signal — it's a technical implementation detail
- Fix: Remove both. The clean login form is more trustworthy without them.

**P2-04: Challenge detail `ENDS: Mar 29, 10:18 AM` — expired session on active challenge**  
- The sandbox challenge `[Sandbox] Hello Bouts` shows ACTIVE status but ENDS date has already passed (Mar 29)
- This looks broken to any user who checks the date
- Fix: Either extend the session or correct the display logic

**P2-05: Challenges list shows raw challenge cards without category display formatting**  
- Category tag shows `speed_build` raw snake_case
- Fix: Format display values consistently across all challenge surfaces

**P2-06: "PLATFORM ONLINE" in the footer**  
- The pulsing dot + "PLATFORM ONLINE" in mono text looks more like a debug status badge than a trust signal
- It's not adding confidence — it's adding clutter
- Fix: Either remove it or replace with something meaningful like a link to `/status`

**P2-07: Dashboard `FLEET STATUS: 0 ACTIVE / 0 IDLE` with `AVG ELO: —`**  
- For a new user, this empty state with dashes and zeroes feels broken
- Fix: Replace with a more welcoming empty state: "No agents registered yet — register your first agent to start competing"

**P2-08: Leaderboard H2 "final-auth-test" is the #1 ranked agent**  
- This is a test agent name that reads as debug content on the public leaderboard
- "final-auth-test" as the top entry tells any visitor the leaderboard is filled with test data
- Fix: Either seed real agent names or (before launch) don't surface the leaderboard publicly until there are real entries

**P2-09: `openclaw skill install agent-arena-connector` in the onboarding flow**  
- `src/components/onboarding/step-connector.tsx:14`
- "openclaw" is an internal tool reference — it will confuse any external user
- Fix: Use the actual CLI command users should run

**P2-10: `bouts.gg/legal/contest-rules` referenced in contest rules page but domain may not be live**  
- The contest rules page mentions `bouts.gg/legal/contest-rules` — if `bouts.gg` isn't the live domain, this is a dead reference

---

### P3 — Minor polish issues

**P3-01: Agent registration form label "AGENT IDENTIFIER"**  
- "Identifier" is technical jargon. Call it "Agent Name" or "Agent Handle."

**P3-02: "BIO (OPTIONAL) 0/200" on agent registration**  
- The character counter is fine. The label "BIO" feels too casual for a serious platform. Consider "Agent description" or just "Description (optional)."

**P3-03: Dashboard uses "CONSOLE" as the nav label for the logged-in area**  
- Visible in the results page body: "CONSOLE" as the section label
- "Console" is a developer term that implies debugging, not competing
- Consider: "Dashboard" or "Command Center" if you want the competitive framing

**P3-04: "Live Session" badge on challenge detail is inconsistently placed**  
- The challenge detail shows both `ACTIVE` badge and a separate `Live Session` label
- Redundant — pick one

**P3-05: `VIEW FULL STANDINGS` in challenge detail spectate section**  
- Appears to be a CTA but was rendering without a visible button border in test — confirm it's styled as a link, not a label

**P3-06: Footer GitHub link goes to `github.com/bouts-elite`**  
- Verify this is the correct and live GitHub org — if not, this is a dead external link

**P3-07: Font preload warning in console**  
- `0c89a48fa5027cee-s.p.0rd3rjvnnhw7n.woff2` is preloaded but not used within the page load window
- Minor performance / console noise issue

---

## 6. REMAINING TRUST / PERCEPTION RISKS

**Risk 1: Any serious operator who clicks "Sign In" from the challenges page will hit a 404 if the CTA points to `/auth/login`.**  
This is the single highest-stakes trust failure. Auth is the gateway to everything — if a developer clicks "Sign in to Enter" and hits a 404, they do not come back.

**Risk 2: The leaderboard is surfacing test agent names as real competition.**  
`final-auth-test`, `forge-loop-final`, `ForgeE2E-001`, `QA-BOT-001` — these are QA/testing artifacts. A first-time visitor seeing this as the competitive leaderboard will assume the platform has no real users.

**Risk 3: API examples reference a Vercel preview URL, not a product domain.**  
Any technical evaluator who opens the docs and sees `agent-arena-roan.vercel.app` in curl examples knows immediately this product does not have its own domain yet. This signals pre-launch, not launch-ready.

**Risk 4: Multiple critical nav paths are dead.**  
Profile, submissions, settings/tokens, about, pricing — these are the pages a curious buyer or investor clicks. Dead pages tell the same story: not done.

**Risk 5: The browser submission flow cannot be fully evaluated end-to-end.**  
The workspace page for the sandbox challenge couldn't be fully exercised due to auth session issues in the test runner. The core product flow — submit → judge → result → breakdown — couldn't be traced in a single session. This is both a QA concern and a trust concern.

---

## 7. EXACT IMPROVEMENTS BEFORE LAUNCH

### Immediate / P0 (fix today)

1. **Fix auth routing.** Audit every link to `/auth/login`, `/auth/signup`, `/auth/forgot-password` and either redirect them to the working `/login` route or add Next.js redirects in `next.config.js`. *(30 min)*

2. **Fix "Arena Challenges" H1.** Change to "Challenges" in `src/app/(public)/challenges/page.tsx:102`. *(2 min)*

3. **Build or stub `/docs/web-submission`.** This is the primary browser-submission explainer and it's a hard 404. *(2-4 hours)*

### High Priority / P1 (fix before public launch)

4. **Format all raw DB values in challenge display.** Add a display mapping for `category` (snake_case → Title Case), `format`, and `weight_class_id` → friendly label. Apply in challenge list, challenge detail, and workspace header.

5. **Add leaderboard sub-rating legend.** A single tooltip or one-line legend row explaining P / S / I / E. Or replace abbreviations with full lane names.

6. **Replace `agent-arena-roan.vercel.app` in all docs with `api.bouts.gg` or `{{BASE_URL}}`.**

7. **Fix how-it-works Phase 1 CTA** — update `/onboarding` link to the actual account creation path.

8. **Rewrite dashboard agents page H2.** Replace "Orchestrate your autonomous neural combatants" with something human and serious.

9. **Fix or stub `/profile`, `/profile/settings`, `/submissions`.** Either build minimal pages or remove nav links to routes that don't exist.

### Before Any Operator Exposure

10. **Clean up the leaderboard.** Either seed believable agent names or hide the leaderboard from the public navigation until real competition data is in it. Test artifacts as top-ranked agents is a significant trust failure.

11. **Remove `openclaw skill install agent-arena-connector` from onboarding.** Replace with the actual public install command.

12. **Remove "END-TO-END SECURE" and "LOW LATENCY AUTH" badges from login.** They read as AI-generated placeholders.

13. **Fix the sandbox challenge "ENDS: Mar 29" date.** Either extend it or fix the display logic for expired sessions that still show ACTIVE status.

14. **Fix the "Sign in to Enter" CTA redirect on challenge detail pages.** Confirm it points to `/login?redirect=...`, not `/auth/login`.

---

## 8. COVERAGE REPORT

| Surface | Status | Notes |
|---|---|---|
| Homepage | ✅ Audited | Strong |
| Challenges list | ✅ Audited | "Arena Challenges" P0, raw category P1 |
| Challenge detail | ✅ Audited | Raw metadata, expired session |
| Workspace (submission) | ⚠️ Partial | Auth timeout prevented full flow |
| Results dashboard | ✅ Audited | Empty state acceptable |
| Result detail | ❌ No live data | No results accessible with test session |
| Replay/breakdown | ❌ Not reached | Depends on result detail |
| Leaderboard | ✅ Audited | Sub-rating opacity P1, test agents P2 |
| Agent profiles | ⚠️ Partial | Registration form audited; individual profile pages not reached |
| Docs home | ✅ Audited | |
| Docs quickstart | ✅ Audited | Dev URL P1, Iowa placeholder P2 |
| Docs compete | ✅ Audited | |
| Docs connector | ✅ Audited | |
| Docs sandbox | ✅ Audited | Dev URL in examples |
| Docs API | ✅ Audited | Dev URL in examples |
| Docs SDK / CLI / GitHub Action / MCP | ✅ Audited | All present and substantive |
| Docs web-submission | ❌ 404 | P0 |
| Auth (login/signup/forgot) | ❌ All 404 | P0 |
| Dashboard (agents) | ✅ Audited | Empty state, gamey copy |
| Profile | ❌ 404 | P1 |
| Submissions | ❌ 404 | P1 |
| Settings/tokens | ❌ 404 | P1 |
| Admin | ✅ Partially audited | Redirects to login correctly |
| Legal (terms/privacy/contest-rules) | ✅ Audited | Substantive and credible |
| 404 page | ✅ Audited | Copy issue P2 |
| Mobile (home/challenges/docs/login/leaderboard) | ✅ Audited | Acceptable |
| Footer | ✅ Audited | Legally credible, minor PLATFORM ONLINE note |

---

*Report generated by Polish ✨ — 2026-03-30. Findings to be routed to Forge for P0/P1 fixes.*
