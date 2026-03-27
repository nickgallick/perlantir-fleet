---
name: nick-fullstack
description: Production-grade product building skill for Nick's standard stack: Next.js App Router, Tailwind CSS, shadcn/ui, Supabase, Vercel, Lucide icons, and Recharts. Use when building any web app, scaffolding a new project, making architecture decisions, implementing features, reviewing code quality, or deciding how to structure a production SaaS/app in Nick's workflow. Bias toward MVP discipline, core-workflow-first execution, strong trust/activation flows, and avoiding premature complexity.
---

# Nick Fullstack

Use this as the default full-stack build skill for Nick.

## Core job

Turn product strategy into a production-grade MVP or shipped product without wasting build effort.

Do not just build clean code. Build the right scope, in the right order, with the right constraints.

Default bias:
- core workflow first
- MVP discipline
- fast path to user value
- trust-critical polish where it matters
- no premature platform complexity
- production quality where the user touches risk, money, auth, or critical actions

## Default stack
- Next.js App Router
- TypeScript
- Tailwind CSS
- shadcn/ui
- Supabase for database and auth
- Vercel for deployment
- Lucide React for icons
- Recharts for charts

## Non-negotiables

- Default to this stack unless Nick explicitly says otherwise.
- Build for production, not tutorials.
- Let product strategy constrain what gets built.
- Build the smallest credible version that proves the workflow.
- Include proper error handling, loading states, empty states, and validation.
- Keep security in mind from the start.
- Use server-side patterns for secrets and privileged operations.
- Never expose secrets in client code.
- Prefer clean architecture over hacks, but avoid architecture theater.
- Do not build speculative complexity before demand is proven.
- Deploy after meaningful changes.
- Share the live URL after deployment.

## Inputs to clarify before major build work

When available, anchor implementation to:
- ICP / buyer
- end user vs economic buyer
- core workflow
- product wedge
- activation moment
- monetization moment
- trust sensitivity
- MVP boundaries

If those are unclear, state assumptions and keep the build narrow.

## Product-led build rules

### Build around the core workflow
Identify:
- the one thing the product must do well first
- the shortest path to first value
- the actions that decide trust, retention, or willingness to pay

Shape the app around that flow. Everything else is secondary.

### Protect MVP discipline
For v1, prefer:
- one strong user journey
- one clear data model for the core workflow
- one clear success metric
- one authentication story
- one credible dashboard / work surface

Push out unless justified:
- broad settings surfaces
- multi-role systems that are not yet needed
- advanced notification systems
- heavy permission matrices
- background job systems without a real trigger
- realtime features without clear user value
- generic admin infrastructure before operations actually require it

### Engineer for trust where it matters
Put extra care into:
- auth flows
- onboarding/setup
- money or sensitive data screens
- approvals/confirmations
- irreversible actions
- core data entry and validation

Not every screen needs the same depth. Put polish where it affects trust and value.

## Standard build workflow

1. Define the product objective and core workflow.
2. Lock MVP scope before feature sprawl starts.
3. Define data model and auth model first.
4. Write an app plan / feature plan when the scope is non-trivial.
5. Record architecture decisions when real tradeoffs exist.
6. Scaffold the app structure.
7. Build the core happy path first.
8. Add validation, empty states, edge cases, and error handling.
9. Add trust-critical polish, responsiveness, accessibility, and SEO where relevant.
10. QA the live app against the core workflow.
11. Deploy and capture durable project memory.
12. Suggest the next logical improvements, separated into now vs later.

## Architecture defaults

- App Router route groups when useful
- Server Components by default
- Client Components only when needed for interactivity
- Server Actions or API routes based on fit
- Supabase schema and auth designed before feature sprawl
- Reusable UI components in a clear component hierarchy
- Shared lib utilities for validation, formatting, and integrations
- Event tracking where activation, conversion, or operational visibility matters

## Preferred project structure

- `app/` for routes
- `components/` for reusable UI
- `lib/` for helpers, integrations, validation, and server utilities
- `types/` for shared types when needed
- `supabase/` or `lib/supabase/` for client/server setup
- `public/` for static assets

## What good looks like

- clear IA and navigation
- forms with strong validation
- auth flows that feel complete
- stable loading/success/error states
- responsive layouts
- clean visual hierarchy
- useful dashboards, not decorative dashboards
- fast first-run experience
- core user value reachable without confusion
- no obvious dead weight in v1

## Decision defaults

- Auth: Supabase Auth
- Database: Supabase Postgres
- File storage: Supabase Storage unless strong reason otherwise
- Charts: Recharts
- Icons: Lucide React
- UI primitives: shadcn/ui
- Deployment: Vercel

## What not to build too early

Do not add these by default unless the product clearly needs them now:
- complex role hierarchies
- abstract plugin systems
- generalized workflow engines
- extensive settings pages
- deep notification frameworks
- overbuilt analytics dashboards
- premature microservices / job orchestration
- broad admin panels disconnected from real operator needs

## Feature implementation standard

For each major feature, define:
- user
- goal
- trigger
- success state
- empty state
- error state
- validation rules
- permissions
- server/client boundary
- analytics or event hooks if relevant

If a feature does not clearly support the MVP or product wedge, challenge it before building.

## QA and launch discipline

Before deploy, confirm:
- core flow works end-to-end
- auth path works
- validation and error states work
- no secret exposure
- env vars are correct
- mobile is usable
- console is clean enough
- metadata/title are sane where relevant

After deploy, capture:
- live URL
- what was shipped
- main technical decisions
- known limits
- next logical improvements

## Output style

When planning or guiding a build, structure responses around:

### Product frame
- user / buyer
- core workflow
- MVP boundary

### Build plan
- phases in implementation order
- what must exist in v1
- what should wait

### Architecture decisions
- auth, data, routing, server/client boundaries, integrations

### Risk areas
- trust-sensitive flows
- likely breakpoints
- security concerns
- complexity traps

### Ship criteria
- what must be true before deploy

## Quality bar

A strong fullstack response should:
- reduce wasted build effort
- keep the product narrow enough to ship
- make the core workflow strong
- apply engineering effort where trust and value are won
- avoid premature complexity while still shipping production-grade work

## References

Read these as needed:
- `references/architecture.md` for architecture defaults
- `references/build-checklist.md` before shipping
- `references/component-patterns.md` when building UI
- `references/supabase-patterns.md` for auth/data patterns
- `references/deployment-memory.md` for deploy and memory capture rules
- `references/feature-design-template.md` for feature planning structure
- `references/admin-and-ops.md` for internal-tool and operator defaults
- `references/qa-handoff.md` for final handoff quality

## Bundled scripts

- `scripts/init_project_notes.sh` — create a project notes stub
- `scripts/generate-feature-checklist.sh` — create a feature delivery checklist
- `scripts/generate-app-plan.sh` — create a higher-level app plan
- `scripts/generate-architecture-decision.sh` — create an ADR-style decision stub
- `scripts/post_deploy_checklist.sh` — create a post-deploy verification checklist
