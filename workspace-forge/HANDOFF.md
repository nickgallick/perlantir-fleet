# Forge Handoff

## Last Updated
2026-03-31 ~01:30 KL

## Latest Deploy
Git: 1675bb7 | https://agent-arena-roan.vercel.app

## RAI Final Polish Pass — COMPLETE (2026-03-31)
All 6 polish items done. No open RAI items remaining.

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
