- Nick preference: Before adding or installing any new skill, first check whether it overlaps with an existing installed/custom skill. If there is overlap, do not install/create it immediately. Compare the options, identify which one is better for Nick's workflow, and come back with a recommendation so he can choose which version to keep.
- Nick preference: For any skill Nick sends, if a stronger custom version would be better than the repo/ClawHub version, say so proactively and recommend/build the better version instead of blindly installing the generic one.
- Nick preference: Be direct about whether work is actually in progress. If I say I’m going to do something, I need to follow through and proactively report real progress instead of losing the thread.
- ✅ COMPLETED (2026-03-19): All skills upgraded — nick-product-strategist, nick-design-director, nick-visual-design-review, nick-fullstack, nick-schema-designer, nick-supabase-reference, nick-project-orchestrator all complete and in workspace/skills/.
- CREATED: nick-design-system skill (2026-03-16) — "Enterprise Confidence with Clean Authority". Reference sites: Accenture, Atlassian, Adobe, NVIDIA, Rocket Companies. Key traits: strong sans-serif typography (Inter), dark heroes, generous whitespace, mega-menu nav, no generic AI design, no stock photos, no cookie-cutter templates.
- CREATED: nick-product-strategist skill (2026-03-16) — Strategic evaluation before building. 5-phase framework: Problem Validation → Market Analysis → Business Model → Build Assessment → Go/No-Go verdict. Factors in Nick's fintech domain expertise as competitive moat.
- CREATED: nick-fullstack skill (2026-03-16) — Enterprise-grade build standards. Covers project structure, Supabase patterns (client/server/admin), auth flow, error handling, security checklist, performance, SEO, accessibility, code quality, pre-deploy checklist.
- CREATED: nick-project-orchestrator skill (2026-03-16) — Top-level skill chaining: Strategy → Design → Build → Deploy → Verify. Four paths: new idea (runs strategy first), build request, iteration, quick build. Post-deploy verification included.
- App-builder skill updated to always load design system + fullstack standards before builds.
- CREATED: nick-visual-review skill (2026-03-16) — Full QA suite: visual review (screenshots at 4 viewports, vision analysis against design system) + UAT functional testing (route navigation, link audit, form validation, button touch targets, auth flow detection, accessibility checks, mobile responsiveness, console/network errors, performance metrics, auto-grading A-F). Both scripts run after every deploy. Grade C or below = auto-fix before reporting to Nick.
- Nick's design vibe: Enterprise, polished, structured, intentional. Dark heroes OK, light sections OK if spacious and deliberate. Headlines are short declarative mission statements. Navigation signals ecosystem depth. No gradients, no blobs, no pill buttons, no SaaS-purple.
- CRITICAL DESIGN LESSON (2026-03-17): First build of BarberBook was graded C — plain, flat, empty sections, no imagery, looked like a template. Nick was not happy. Rebuilt to B+ after major overhaul. KEY TAKEAWAYS FOR ALL FUTURE BUILDS:
  1. NEVER ship a sparse/minimal homepage. Every landing page needs 12-15 rich sections minimum.
  2. ALWAYS include device mockups (phone frames, dashboard previews) built with CSS — they prove the product is real.
  3. ALWAYS include trust signals (press logos bar, stats with large numbers, testimonials with ratings).
  4. ALWAYS use alternating section backgrounds (gradients, dark, light gray, white) — never flat same-color.
  5. ALWAYS include pricing section, FAQ accordion, and dual-audience feature showcases.
  6. Feature sections must alternate layout (text-left/visual-right, then visual-left/text-right).
  7. Cards need shadows, borders, hover elevation, gradient headers — never flat/plain.
  8. Use static demo data so homepage looks great without database dependency.
  9. Compare against the competitor BEFORE building, not after. Screenshot their site and match/exceed their visual density.
  10. Run the visual review skill DURING development, not just after deploy. Catch issues early.
  11. Design standard is Booksy/Accenture/NVIDIA level — not MVP/template level. Nick expects the FIRST deploy to look polished.
- Nick preference: Design is highest priority. Never compromise on visual quality. Every project must look like it was built by a top-tier agency, not a template or AI.
- Nick has an Apple Developer Account for App Store submissions.
- iOS app conversion for BookDSM is on hold. Nick wants to explore other app ideas first. When ready: use Capacitor + Tailscale to Mac for remote Xcode builds.
- Expo account: username uberkiwi.com, email nick@uberkiwi.com
- Apple Developer ID: nick@maksdigital.com (pending approval as of 2026-03-19)
- Nick preference: Always run full UAT automatically after every phase/build/deploy. Never wait for Nick to ask. Flow: Build → Deploy → UAT → Fix failures → Redeploy → Report final results.
- Nick preference: Quality over cost. No sub-agent concurrency limits. Don't restrict capabilities to save money.
- CONFIG CHANGE (2026-03-17): Switched primary model from Opus → Sonnet 4.6. Opus is first fallback. Nick manually switches to Opus for builds with /model Opus.
- PROJECT: Perlantir Mission Control (2026-03-17) — 18+ page admin dashboard at https://perlantir-mission-control.vercel.app. Supabase project zjcgoeivuwkrpqezyhqg (dedicated). Auth: nick@perlantir.com. Built from Lovable frontend + full Supabase backend. Live integrations with OpenClaw gateway, Vercel API, spend tracking. Located at ~/Projects/perlantir-mission-control.
- INFRASTRUCTURE: Caddy reverse proxy on VPS (2026-03-17) — openclaw.perlantir.com → localhost:18789 with auto-TLS. Port 18789 blocked externally. Traefik removed.
- AGENT: MaksPM (2026-03-17) — PM agent on Haiku 4.5, separate Telegram bot. Workspace at /data/.openclaw/workspace-pm/. Silent project manager — heartbeats, tracking, follow-ups. Only messages Nick when something needs attention.
- CREDENTIALS: All Supabase + Vercel credentials stored permanently in TOOLS.md. Use existing credentials for all projects. Only ask Nick for updated credentials if existing ones stop working or return auth errors.
- Nick uses Claude via OAuth subscription (Claude Max), NOT API billing. No per-token costs. Track token usage only, never show dollar amounts or cost estimates.
- Nick preference: Never use seed/fake data in dashboards. Only show real data or clean empty states.
- VPS OpenClaw gateway runs inside Docker on port 45133 (host-mapped), NOT 18789. Caddy proxies openclaw.perlantir.com → 127.0.0.1:45133.
- Docker container name: openclaw-okny-openclaw-1 (container ID: a8e3013d4da3). Restart command: `docker restart openclaw-okny-openclaw-1`
- CRITICAL: openclaw.json Telegram groupPolicy valid values are ONLY: "open", "disabled", "allowlist". NEVER use "deny" — it crashes the ENTIRE OpenClaw instance (all bots, not just the misconfigured one). Same valid values for dmPolicy plus "pairing".
- CRITICAL: Config file path on VPS is /data/.openclaw/openclaw.json, NOT /app/.openclaw/openclaw.json. Data volume mounts at /data/.
- CRITICAL: Always validate openclaw.json before asking Nick to restart. One bad field kills all 3 bots.
- RULE: Before making ANY changes to openclaw.json, installing plugins, or modifying config, MUST first consult ClawExpert via agent-to-agent messaging to verify the change is safe and keys are valid for version 2026.3.13. No exceptions.
- Nick preference: When giving commands to run, send them in a standalone message (no mixed text) so he can copy the whole message and paste directly.
- INTEGRATION: v0.dev API (2026-03-17) — v0 SDK installed, API key stored in TOOLS.md. Skill at skills/nick-v0-design/. Script at skills/nick-v0-design/scripts/v0-generate.js. DEMOTED to backup — replaced by Google Stitch.
- INTEGRATION: Google Stitch MCP (2026-03-19) — Primary design tool. Configured via mcporter (NOT openclaw.json — that crashes the gateway). Config at ~/.mcporter/mcporter.json. Use `mcporter call stitch <tool> '<json>'` to call. 8 tools available. 350 screens/month free. Skill at skills/stitch-design/.
- CRITICAL (2026-03-19): Claude Code flag is `--permission-mode bypassPermissions --print` — NEVER `--dangerously-skip-permissions` (exits after confirmation dialog).
- BUILD PIPELINE (2026-03-19): New order — Step 0: Screenshot competitor + aspiration → Design Director → Stitch (2+ iterations, named refs, specific prompts) → Design Brief (50-100 words) → Schema Designer → Fullstack → Claude Code with --image flags (Stitch + competitor + aspiration screenshots) → Deploy → vercel-qa + visual-design-review + deep-uat.
- DESIGN QUALITY (2026-03-19): Never accept first Stitch output. Always 2+ refinement prompts. Pass screenshots to Claude Code via --image for pixel-matching. Spec minimum 800+ words. Include competitor + aspirational screenshots as visual benchmarks.
- UAT UPGRADED (2026-03-19): nick-deep-uat now does Phase 0 scope gap detection (reads spec, finds missing features), Phase 1 vision analysis (screenshots + image tool), tests 50 buttons/page (was 20). Every failure needs screenshot evidence.
- TOOLS (2026-03-19): Stitch MCP is configured via mcporter, NOT openclaw.json. TOOLS.md corrected. v0-design is deprecated — use stitch-design skill.
- KNOWLEDGE UPGRADE (2026-03-20): Maks upgraded with 7 deep framework reference skills (4,899 lines total):
  - supabase-deep: Auth flows, RLS patterns, Edge Functions, Realtime, Storage. Covers email/password, magic link, OAuth, @supabase/ssr for Next.js App Router, session management, middleware auth (getClaims vs getSession), RLS policies, edge function deployment, realtime subscriptions, storage bucket policies.
  - stripe-payments: Checkout sessions, subscriptions, webhooks, customer portal, billing. Covers session creation, pricing tiers, webhook signature verification, subscription lifecycle, server-side-only Stripe SDK, Supabase integration via customer_id in profiles, RLS-based tier access.
  - tanstack-query: useQuery, useMutation, optimistic updates, infinite queries, prefetching. Covers queryKey conventions, enabled flag, select transform, onSuccess/onError, invalidateQueries, setQueryData for optimistic updates, cursor pagination, SSR dehydrate/hydrate, Supabase integration patterns.
  - auth-patterns: Supabase Auth primary (Next.js App Router), Auth.js reference, JWT, session management, protected routes. Covers createServerClient vs createBrowserClient, middleware token refresh, getClaims() security (NOT getSession), httpOnly cookies, CSRF protection, rate limiting, auth state listener.
  - drizzle-orm: Type-safe SQL, schema definition, migrations, relations, joins. Covers table definitions, column types, references, indexes, select/insert/update/delete, one-to-one/one-to-many/many-to-many relations, drizzle-kit migration pipeline, when to use Drizzle vs Supabase JS.
  - react-email: Transactional email templates with React components, Resend integration. Covers Html/Head/Body/Container/Section/Row/Column/Text/Link/Img/Button/Hr/Preview, template patterns (welcome, password reset, invoice, notification), inline styles for email clients, table-based layout for Outlook, react-email dev server testing.
  - framework-reference: Index of 6 cloned repos (66MB total) with paths, contents, grep examples, web fetch fallbacks.
  - Repos cloned: supabase-docs (13M), next-auth (31M), tanstack-query (5.7M), stripe-sdk (11M), react-email (1.6M), drizzle-orm (4.9M). Available in /data/.openclaw/workspace/repos/ for reference during builds.
