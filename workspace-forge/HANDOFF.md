# Forge Handoff

## Last Updated
2026-03-31 ~01:35 KL

## Latest Deploy
Git: cafad55 | https://agent-arena-roan.vercel.app

## Copy Alignment Pass — COMPLETE (2026-03-31 ~01:55 KL)
All Tier 1 + Tier 2 changes from BOUTS_FINAL_COPY_ALIGNMENT.md executed.
Part 2 RAI surface alignment also complete. See summary below.

## RAI — FULLY COMPLETE (2026-03-31 ~01:35 KL)
All 6 polish items browser-verified by QA. P1 bug found and fixed. Zero open RAI items.

### P1 Bug Fixed (02d24d4)
workspace/route.ts: three early returns (already_submitted, expired x2) were missing
`remote_invocation_supported` in their JSON payloads. Client checks this field BEFORE
checking workspace_state, so `undefined` → falsy → rendered "Connector Required"
instead of "Session Expired" / "Already Submitted" for RI-enabled challenges.
Fix: extracted `riSupported` const, added to all three early return payloads.

1. Validate shortcut — now points to /settings?tab=agent&subtab=remote-invocation&validate=1
   - AgentManagement accepts defaultSubtab + autoValidate props from URL params
   - RemoteInvocation fires handleValidate() automatically when autoValidate=true + endpoint loaded
   - Label updated: "Validate Contract" (consistent everywhere)

2. Deep-link subtab — all /settings?tab=agent links now include &subtab=remote-invocation
   - Workspace Validate, Configure Endpoint, Check Endpoint, InvocationFailure links
   - Challenge detail nudge "Configure →" link
   - All docs quick links

3. Trust note link — "How we verify this →" added to workspace trust note
   - Points to /docs/remote-invocation#trust-model
   - #trust-model anchor added to docs page

4. Redundant env microcopy removed — "Env: production" replaced with "Zero retries"
   - Badge remains the authoritative signal

5. /docs/web-submission — now renders an explanatory page (not a silent redirect)
   - Shows what changed, CTA to new docs, "Update your bookmark" message

6. Copy consistency — all surfaces now use:
   - "Remote Agent Invocation" (full name, feature badge, section headers, Track 0 title)
   - "Remote Invocation" only in short-form inline/link contexts in compete docs
   - "Validate Contract" everywhere
   - "Settings → Agent → Remote Invocation" in all docs references
   - "View Breakdown →" (consistent, both challenge detail and workspace)

## Migration 00039
Written at supabase/migrations/00039_rai_tightening.sql
Needs to be run in Supabase SQL editor (ALTER column default, zero max_retries).

## Key Files
- src/app/api/challenges/[id]/invoke/route.ts — RAI trigger
- src/app/api/v1/agents/[id]/endpoint/ — CRUD + ping + validate + rotate-secret
- src/app/(public)/challenges/[id]/workspace/page.tsx — workspace UI
- src/app/(public)/challenges/[id]/page.tsx — challenge detail (nudge, badges)
- src/components/settings/remote-invocation.tsx — settings component
- src/app/docs/remote-invocation/page.tsx — docs
- src/lib/rai/ — full RAI library
- supabase/migrations/00038_remote_invocation.sql — main migration (applied)
- supabase/migrations/00039_rai_tightening.sql — tightening migration (needs Supabase run)
