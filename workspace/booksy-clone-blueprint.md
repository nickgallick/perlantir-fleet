# Booksy Clone — Execution Blueprint

## Product summary
Build an enterprise-grade beauty and wellness booking platform with two major sides:
- client marketplace + booking experience
- provider operating system for running a service business

The raw requested scope spans:
- marketplace discovery
- booking engine
- provider onboarding and calendar ops
- CRM/client management
- staff permissions
- waitlist
- gift cards
- loyalty
- promotions
- intake forms
- recurring appointments
- audit logging
- email summaries
- accessibility/performance/GDPR hardening

This is too large for one uninterrupted build pass. It should be executed in controlled milestones.

## Recommended implementation sequence

### Milestone 1 — Booking MVP foundation
Ship first:
- Next.js app shell, design system, auth scaffold
- Supabase schema + RLS for core tables
- landing page
- search results page
- provider profile page
- client booking flow
- client account basics
- seed data
- initial Vercel deploy

### Milestone 2 — Provider operations MVP
Ship next:
- provider onboarding wizard
- dashboard home
- appointments management
- services management
- business settings
- provider calendar (day/week/month)

### Milestone 3 — Advanced operations
Ship next:
- staff management
- waitlist
- intake forms
- recurring appointments
- audit log
- daily summary emails

### Milestone 4 — Monetization/growth systems
Ship next:
- gift cards
- loyalty
- promotions

### Milestone 5 — Enterprise hardening and polish
Ship next:
- skeleton states
- optimistic UI improvements
- animation layer
- accessibility hardening
- performance optimization
- GDPR export/delete flows
- custom error pages and consistent API errors
- command palette / keyboard shortcuts
- final polish assets

## Milestone 1 goal
Prove the product with a fully usable booking marketplace and booking flow.

## Milestone 1 exact scope

### Core schema
Include in M1:
- users
- businesses
- services
- service_variants
- service_addons
- staff
- staff_services
- appointments
- appointment_addons
- appointment_holds
- reviews
- notifications

Defer from later phases:
- audit_log
- loyalty-specific tables
- gift-card-specific tables
- promotions tables
- waitlist tables
- intake-form structures beyond forward-compatible placeholder strategy
- recurring-series support tables unless needed immediately

### Auth
Include in M1:
- Supabase email/password auth
- email verification gate before booking confirmation
- login/signup pages with Zod validation
- protected routes
- role-based post-login redirects
- auth provider/context

Notes:
- password complexity can be enforced at validation layer
- lockout/cooldown likely needs app-side tracking + auth wrapper behavior rather than assuming Supabase natively handles it exactly as requested

### Public/client UI
Include in M1:
- landing page
- search results
- provider profile
- 5-step booking flow
- success page
- client account overview/upcoming/past/profile/review

### Booking engine rules for M1
Support in M1:
- service + variant + add-ons selection
- staff selection or any available
- date/time slot generation for next 30 days
- business hours + staff schedule + existing appointments + buffer handling
- 5-minute appointment hold
- cancellation/reschedule subject to business rules

### Design/system
Include in M1:
- light mode default
- dark mode toggle saved in preferences
- specified color system
- Inter + Space Grotesk
- responsive layout
- mobile bottom nav for core client flows
- toast notifications

### Security/SEO baseline for M1
Include in M1:
- Zod validation everywhere
- security headers baseline
- no secret leakage
- metadata/OG/twitter basics
- JSON-LD on provider profile
- sitemap/robots/canonical

### Seed data
Include in M1:
- 5 Chicago providers
- realistic services/variants/add-ons
- 2–3 staff each
- 15–20 reviews each
- 30+ past/upcoming appointments each

## Highest-risk technical areas
1. Availability engine correctness
2. Hold expiration and booking race conditions
3. RLS separation for clients vs providers vs staff
4. Business owner vs staff relationship model
5. Email verification gate before booking
6. Seed data realism while preserving policy compatibility
7. Cancellation/reschedule policy enforcement

## Recommended sub-agent usage

### Planning phase
- Main agent: product/architecture orchestration
- Optional sub-agent 1: schema/RLS review
- Optional sub-agent 2: route/component architecture review

### Build phase
- Main agent: own implementation plan and synthesis
- Optional sub-agent: isolated review/audit or QA after milestone deploy

Recommendation: do not parallelize actual coding too aggressively in M1. Too many dependencies touch auth, schema, and booking logic.

## Definition of done for Milestone 1
- seeded app runs locally
- Supabase schema + RLS applied cleanly
- client can discover providers
- client can complete booking flow with verified account
- holds prevent collisions during checkout window
- client account shows upcoming/past appointments
- review submission works for completed appointments
- responsive UI works on mobile and desktop
- Vercel deployment live

## Immediate next action
Start implementation planning for Milestone 1, then scaffold the project and build foundation before feature layering.
