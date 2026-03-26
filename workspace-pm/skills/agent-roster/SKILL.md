# Agent Roster

Complete reference for all 6 agents in the Perlantir studio. Use this to understand capabilities, constraints, and how to invoke each agent correctly.

---

## Scout

- **Bot name:** Scout
- **Model:** Opus
- **Heartbeat:** Active
- **Skills:** 13 skills
  - Key skills: market-research, competitor-analysis, icp-profiling, brand-audit, trend-analysis, industry-report, user-persona, positioning-strategy, swot-analysis, feature-benchmarking, audience-segmentation, keyword-research, content-gap-analysis
- **Capabilities:** Deep market and competitor research, ICP definition, brand positioning analysis, industry trend identification, strategic recommendations. Produces comprehensive written reports with data-backed insights.
- **Output format:** Long-form written report (800+ words), structured with sections for each research area. Includes citations and specific examples where relevant.
- **Limitations:** Does not design, build, or write marketing copy. Research only. Cannot access private/paywalled data sources. Output quality depends on brief specificity.
- **Response time:** 3–8 minutes
- **When to invoke:** At the start of every project, after intake. Also invoke mid-project if new research questions arise (e.g., pivot in direction, new competitor discovered).
- **How to invoke:** Send via `sessions_send` with a research brief containing project description, target audience, specific research questions, and brand context.
- **Important notes:** Always review Scout's output for completeness before passing to Pixel. If the report is under 800 words or misses key areas, send a follow-up request specifying gaps.

---

## Pixel

- **Bot name:** Pixel
- **Model:** Opus
- **Heartbeat:** Active
- **Skills:** 21 skills
  - Key skills: v0-design, component-spec, design-tokens, ui-review, screen-layout, responsive-design, accessibility-check, stitch-fallback, prototype-generation, style-guide, color-system, typography-spec, icon-system, spacing-system, animation-spec, dark-mode, mobile-first, interaction-design, edge-state-design, handoff-notes, visual-qa
- **Repos:** 15 design reference repositories
- **Capabilities:** Full UI/UX design pipeline using V0. Generates screen designs, extracts design tokens, creates component specifications, handles responsive layouts, covers edge states (empty, loading, error, overflow), checks accessibility, and produces detailed handoff documentation for the build phase.
- **Output format:** Per-screen output includes: V0 chat ID, preview URL, design tokens (colors, typography, spacing), component specs, edge state designs, accessibility notes, and handoff notes for Maks.
- **Limitations:** Depends on V0 API availability. Cannot build or deploy — design only. Cannot do backend architecture. If V0 is down, falls back to Stitch or text-based specs (reduced fidelity).
- **Response time:** 5–15 minutes per screen
- **When to invoke:** After Scout's research is reviewed and saved. Send all screens at once — Pixel handles the full design batch.
- **How to invoke:** Send via `sessions_send` with a design brief containing project description, brand guidelines, Scout's research summary, and the full screen list with descriptions.
- **Important notes:** Pixel runs the V0 pipeline autonomously — do not micromanage individual design iterations. Wait for Pixel's complete output. Verify that every screen has a V0 chat ID and preview URL before proceeding to build.

---

## Maks

- **Bot name:** Maks
- **Model:** Sonnet
- **Heartbeat:** Active
- **Skills:** 33 skills
  - Key skills: nextjs-build, react-components, tailwind-styling, api-routes, database-setup, prisma-orm, auth-implementation, vercel-deploy, preview-deploy, prod-deploy, file-structure, state-management, form-handling, data-fetching, error-boundaries, image-optimization, seo-meta, responsive-implementation, animation-implementation, testing-setup, env-config, git-workflow, dependency-management, performance-optimization, accessibility-implementation, dark-mode-implementation, search-implementation, pagination, filtering, crud-operations, webhook-integration, email-integration, payment-integration
- **Capabilities:** Full-stack development. Builds Next.js applications from Pixel's design specs. Implements components, pages, API routes, database schemas, authentication, and integrations. Deploys to Vercel (preview and production). Handles bug fixes and code changes from Forge's review.
- **Output format:** Working deployed application with preview URL. Reports back with deployment status, URL, and any issues encountered.
- **Limitations:** Follows specs — does not make design decisions. Does not review his own code (that's Forge's job). Should not deploy to production until explicitly told to after QA passes. Quality depends on the specificity of the design specs provided.
- **Response time:** 15–60 minutes (depends on scope — simple screen: 15 min, full app: 60 min)
- **When to invoke:** After Pixel's designs are reviewed and all screens pass the design gate. Also invoke during fix loops (Forge feedback) and for production deployment after QA.
- **How to invoke:** Send via `sessions_send` with a build brief containing project description, Pixel's complete design specs, V0 chat IDs, design tokens, technical requirements, and handoff notes.
- **Important notes:** Always specify preview vs. production deployment explicitly. Never assume Maks will deploy to production — he deploys to preview by default. During fix loops, include Forge's exact feedback with file references.

---

## Forge

- **Bot name:** Forge
- **Model:** Opus
- **Heartbeat:** Active
- **Skills:** 19 skills
  - Key skills: code-review, security-audit, performance-review, best-practices-check, type-safety-check, error-handling-review, api-review, database-review, auth-review, dependency-audit, accessibility-audit, seo-review, responsive-review, testing-review, code-style, architecture-review, bundle-analysis, memory-leak-check, race-condition-check
- **Repos:** 16 code reference repositories
- **Capabilities:** Comprehensive code review covering quality, security, performance, best practices, type safety, error handling, and architecture. Returns a clear verdict with specific issues, file references, and recommended fixes.
- **Output format:** Verdict (Approved / Approved with notes / Changes requested / Blocked) followed by categorized issue list with severity (P0/P1/P2), file paths, line numbers, and suggested fixes.
- **Limitations:** Reviews only — does not write or fix code. Cannot deploy. Does not do design review. Focuses on code quality, not business logic correctness (that's QA's job).
- **Response time:** 3–10 minutes
- **When to invoke:** After Maks deploys to preview and the build gate passes. Also invoke during fix loops to re-review after Maks applies fixes.
- **How to invoke:** Send via `sessions_send` with the repository/project reference, description of what was built, areas of concern, and preview URL.
- **Important notes:** Forge's verdict is final for code quality. If Forge blocks, do not bypass — enter the fix loop. After 3 failed loops, escalate to Nick via the circuit breaker protocol. Log every Forge verdict in the project file.

---

## ClawExpert

- **Bot name:** ClawExpert
- **Model:** Sonnet
- **Heartbeat:** Active
- **Skills:** 21 skills
  - Key skills: dns-management, domain-config, ssl-setup, vercel-config, env-variables, infra-troubleshoot, deployment-debug, log-analysis, uptime-check, performance-monitoring, cdn-config, redirect-rules, header-config, cors-setup, rate-limiting, backup-config, rollback-procedure, incident-response, status-page, monitoring-setup, alert-config
- **Repos:** 4 infrastructure repositories
- **Capabilities:** Infrastructure and operations. Manages DNS, domains, SSL, environment variables, Vercel configuration, and deployment troubleshooting. The go-to agent for any infrastructure issue that blocks build or deployment.
- **Output format:** Diagnostic report with root cause, fix applied (or fix instructions), and verification steps.
- **Limitations:** Ops only — does not build features, design, research, or review code. Should not be involved in the main build pipeline unless there's an infrastructure blocker.
- **Response time:** 2–5 minutes
- **When to invoke:** When Maks encounters a deployment or infrastructure error. When DNS/domain/SSL issues arise. When environment configuration is needed. NOT part of the standard pipeline — invoke only when needed.
- **How to invoke:** Send via `sessions_send` with the specific error message, context (what was being attempted), and any relevant configuration details.
- **Important notes:** ClawExpert is a support agent, not a pipeline agent. Do not route standard project work through ClawExpert. Use only for infrastructure issues, troubleshooting, and ops tasks.

---

## Launch

- **Bot name:** Launch
- **Model:** Opus
- **Heartbeat:** Active
- **Skills:** 10 skills
  - Key skills: launch-strategy, marketing-copy, social-media-plan, seo-strategy, analytics-setup, press-release, email-campaign, landing-page-copy, brand-messaging, competitive-positioning
- **Capabilities:** Go-to-market strategy and execution. Creates launch plans, marketing copy, social media content, SEO strategy, and analytics setup recommendations. Produces comprehensive launch packages aligned with brand and ICP.
- **Output format:** Structured launch plan with sections for strategy, messaging, channel plan, content calendar, and metrics/KPIs.
- **Limitations:** Marketing and strategy only — does not build, design, or deploy. Cannot implement analytics (Maks does that). Should only be invoked after QA passes — never before the product is verified.
- **Response time:** 5–15 minutes
- **When to invoke:** After QA passes and Maks has deployed to production. Send the go-to-market brief with product description, URL, ICP, and brand context.
- **How to invoke:** Send via `sessions_send` with a go-to-market brief containing product description, value proposition, production URL, ICP from Scout's research, brand guidelines, key features, and differentiators.
- **Important notes:** Only invoke Launch after QA has passed. Launching an unverified product is never acceptable. Launch's output is the final deliverable alongside the production URL in the project complete report to Nick.
