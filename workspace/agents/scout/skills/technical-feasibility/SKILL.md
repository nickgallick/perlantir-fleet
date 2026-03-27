---
name: technical-feasibility
description: Scout research skill — Technical Feasibility
---

# Skill: Technical Feasibility Assessment

Evaluate whether Perlantir can actually build this. Be realistic about complexity.

## Perlantir Stack Capabilities
- Frontend: Next.js, React, TypeScript, Tailwind CSS, shadcn/ui
- Backend: Supabase (Postgres, Auth, Storage, Edge Functions, Realtime)
- Deployment: Vercel (auto-deploy from GitHub)
- AI: Claude API (Anthropic), OpenAI API, Ollama (local)
- Payments: Stripe (when configured)
- Mobile: Expo + EAS (iOS apps) — available but adds complexity
- Build tool: OpenClaw (autonomous AI agent that builds and deploys end-to-end)

## Build Time Estimates
- Landing page with waitlist: 1 day
- Simple CRUD SaaS (dashboard, forms, data tables): 1-2 weeks
- Marketplace (listings, search, user profiles, messaging): 2-4 weeks
- Complex platform (multiple user types, workflows, integrations): 4-8 weeks
- API product: 1-2 weeks for core, ongoing for documentation/SDKs
- Chrome extension: 1-2 weeks
- Mobile app (via Expo): add 1-2 weeks to any web estimate

## Easily Buildable Product Types (green light)
- Dashboards and analytics tools
- CRUD SaaS apps (CRM, project tracker, inventory, booking)
- AI-powered content/writing tools
- Workflow automation tools
- API wrappers and integrations
- Internal tools and admin panels
- Landing pages and marketing sites
- Calculators and planning tools
- Marketplace MVPs
- Browser extensions
- Notification/monitoring tools

## Harder / Avoid for MVP (yellow/red flag)
- Real-time video/audio (WebRTC complexity)
- Native mobile app required on day 1 (web-first is always faster)
- Heavy ML model training (inference via API is fine, training is not)
- Hardware integration (IoT, Bluetooth, sensors)
- Regulated industries requiring certifications before launch (HIPAA, SOC2, PCI on day 1)
- Products requiring massive seed data to be useful (cold start problem)
- Products requiring network effects to deliver value (chicken-and-egg problem)
- Desktop native apps (Electron is possible but adds complexity)

## Assessment Checklist
For every idea, answer:
1. Can the core feature be built with Supabase + Next.js + Vercel? YES/NO
2. Does it need any external APIs? Which ones? Are they affordable at low scale?
3. Does it need real-time? Supabase Realtime handles most cases.
4. Does it need file storage/uploads? Supabase Storage handles this.
5. Does it need auth/user management? Supabase Auth handles this.
6. Does it need payments? Stripe handles this.
7. Does it need AI/LLM features? Claude/OpenAI APIs handle this.
8. Does it need email sending? Resend or SendGrid handles this.
9. What's the estimated monthly infrastructure cost at 100 users? At 1000 users?
10. What's the single hardest technical challenge and can it be solved in under a week?

## Output
- Build complexity: SIMPLE (1-2 weeks) / MODERATE (2-4 weeks) / COMPLEX (4-8 weeks) / TOO COMPLEX (skip)
- Tech stack recommendation (specific libraries, APIs, services)
- MVP scope: the absolute minimum feature set to test the idea (usually 3-5 core features)
- What to explicitly SKIP in the MVP (nice-to-haves that can come later)
- Estimated monthly infrastructure cost
