# Developer Trust Signals

Developers evaluate products differently than general consumers. They check the technical foundation before the marketing. Missing any of these signals creates friction that no amount of copy can overcome.

## Tier 1: Must-Have (Block adoption if missing)

### Open Source Components
- Open source anything you can — connector/SDK, evaluation framework, sample agents
- GitHub repo with real commits (not a dump), clear README, active issues
- License clarity (MIT/Apache 2.0 preferred for dev tools)
- If fully closed-source: explain why and what you plan to open

### API Documentation
- Interactive API docs (Swagger/OpenAPI spec)
- Code examples in 3+ languages (Python, TypeScript, Go minimum)
- Authentication clearly documented
- Rate limits stated upfront
- Error codes with human-readable explanations
- Quickstart guide that gets to first API call in < 5 minutes

### Architecture Transparency
- Public architecture diagram or blog post
- Stack disclosure (developers want to know what they're depending on)
- Security model explanation (how data is handled, stored, isolated)
- For AI products: model details, evaluation methodology, data handling

### Uptime / Status Page
- Public status page (Statuspage.io, Instatus, or custom)
- Historical uptime data visible
- Incident communication channel (Twitter, status page updates)
- SLA stated clearly (even if informal: "we target 99.9% uptime")

## Tier 2: Strong Signals (Accelerate adoption)

### Transparent Pricing
- Clear pricing page — no "contact sales" for basic tiers
- Free tier or trial that doesn't require a credit card
- Usage-based pricing clearly explained with calculator
- No hidden fees or surprise overages
- Comparison table if multiple tiers

### Security Posture
- SOC 2 badge (if applicable to product tier)
- Data handling policy in plain English
- GDPR/privacy compliance stated
- Sandboxing explanation for agent execution
- "How we handle your code" explainer

### Community Presence
- Active Discord or forum with real user discussions
- Maintainer/team responding to issues and questions
- Changelog with regular updates
- Public roadmap (Linear, GitHub Projects, or custom)

### Content Quality
- Technical blog with depth (not marketing fluff)
- Video demos showing real product (not renders)
- Case studies with real users and real data
- Conference talks or podcast appearances

## Tier 3: Nice-to-Have (Build long-term trust)

### Developer Experience
- CLI tool for common operations
- SDK in popular languages
- Webhooks for automation
- CI/CD integration examples
- Local development setup guide

### Social Proof (Developer-Specific)
- GitHub stars (real, not bought)
- npm/pip download counts
- "Built with [Product]" showcases
- Developer testimonials (with real names and companies)
- Integration partners listed

### Thought Leadership
- Published benchmarks or research
- Open datasets
- Contributing to relevant open-source projects
- Speaking at developer conferences

## Trust Signal Checklist for Launch

Before any developer-facing launch, verify:

```
□ Product URL loads fast (< 2s)
□ HTTPS with valid cert
□ API docs accessible without signup
□ Pricing page exists and is clear
□ Status page URL is live
□ GitHub repo has README, license, recent commits
□ Quickstart guide exists and works end-to-end
□ Error messages are helpful, not generic
□ Contact/support channel is visible
□ Privacy/security page exists
□ No broken links on marketing site
□ Demo or screenshots show real product
```

## Anti-Trust Signals (Red Flags Developers Notice)

- "Enterprise-only" pricing with no public tiers
- Stock photos instead of product screenshots
- "Contact sales" as the only CTA
- No technical content on the blog
- Dead GitHub repo (no commits in 3+ months)
- Generic error messages ("Something went wrong")
- No changelog or version history
- Testimonials from "John D., CEO" with no verifiable identity
- Landing page promises features the product doesn't have yet
- "Powered by AI" without explaining what the AI does
