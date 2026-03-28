# Polish Audit Domains — Reference Guide

## Domain 1 — Visual Hierarchy Audit

### What to evaluate
- First impression clarity — what does a user see and understand in 3 seconds?
- Primary/secondary hierarchy — is the most important content visually dominant?
- Section order logic — does the page tell a coherent story?
- Layout pacing — does the page breathe? Is it too dense or too sparse?
- Content density choices — are dense sections earnable and structured, not chaotic?
- Scanability — can a user skim and understand the product?
- Page rhythm — is there variation in section types, or is it "cards all the way down"?

### What to look for
- Equally weighted sections (everything feels equally important = nothing is important)
- No clear focal point on key pages
- Bloated sections with no information logic
- Too many cards of equal importance
- Design that looks clean but does not help comprehension
- Sections that could be removed without the page making less sense

---

## Domain 2 — Copy Maturity Audit

### What to evaluate
- Clarity: does the copy say something specific?
- Specificity: does it describe the actual product, or just a category?
- Conviction: does it have a point of view?
- Audience fit: does it speak to the actual buyer/user?
- Brand consistency: same voice across all pages?
- Anti-genericity: could this copy belong to any AI startup?
- Trustworthiness: do claims have any backing?

### Red-flag phrases
- "revolutionize" / "unlock" / "streamline" / "supercharge"
- "powerful platform" / "seamless experience" / "intelligent system"
- "next-generation" / "cutting-edge" / "state-of-the-art"
- Any sentence that could describe 100 different products
- "The future of X" without defining what that future actually is

### What great copy looks like
- Describes what Bouts actually does: "AI agents compete in structured coding challenges judged by a 4-lane system"
- Has product-specific language: Blacksite Debug, Fog of War, CDI, Objective Judge
- Sounds like it was written by someone who actually built the product
- Has a point of view: "We don't use LLM judges who can be prompted. We use reproducible test-based scoring."

---

## Domain 3 — Enterprise Readiness Audit

### What enterprise-capable looks like
- Navigation that never gets lost or broken
- Clear docs with accurate content
- Proper states: loading, empty, error, success — all handled gracefully
- Readable data displays: tables that work, numbers that are legible
- Serious admin/operator surfaces: not a dashboard that looks like a toy
- Role clarity: users always know what they can and cannot do
- Calm, mature visual treatment: no playful or "beta startup" feel in serious flows

### What to look for
- Admin pages that look like prototypes
- Tables with no sorting, filtering, or interaction logic
- Empty states that look like bugs
- Error messages that expose implementation details
- Navigation that feels incomplete or inconsistent
- Operator flows where the next action is unclear

---

## Domain 4 — Anti-Template / Anti-AI-Built Audit

### The core question
Does this look like a human with taste and product conviction built it, or does it look like an AI assembled it from components?

### Signs of template/AI assembly
- Every page uses the same section scaffold
- No distinctive information architecture on any page
- Visual rhythm is mathematically even but has no meaning
- Sections that feel like they were pulled from "best landing page practices" without being applied to this specific product
- Copy that follows a pattern: headline → subheadline → three bullet points → CTA
- Same card type used across marketing, features, docs, and product indiscriminately
- "Feature grid" applied where real depth would serve better
- Transitions and animations that feel decorative, not purposeful

### Signs of human-led product design
- Sections designed around the specific content they hold
- Visual hierarchy that reflects actual product priorities
- Copy that uses product-specific language and real examples
- Pages where the layout choice makes the content clearer
- Details that only someone who deeply understands the product would think to include

---

## Domain 5 — Interaction Quality Audit

### States to check on every interactive component
- Default state: does it look right?
- Hover state: is there meaningful feedback?
- Active/pressed state: is there confirmation of the action?
- Disabled state: is it clearly disabled, not just grayed out?
- Focus state: is it keyboard-accessible and visible?
- Loading state: is it informative, not just a spinner?
- Error state: is the error message specific and actionable?
- Empty state: is the empty state helpful, not just blank?
- Success state: is completion confirmed clearly?

### Table interaction checklist
- Can headers be sorted?
- Is there row hover state?
- Is pagination clear?
- Are loading states handled (skeleton rows)?
- Do long strings truncate gracefully?
- Is mobile overflow handled?

### Form interaction checklist
- Are validation errors shown inline or after submit?
- Are required fields marked?
- Is the submit button disabled until valid?
- Is submission feedback immediate?
- Are errors specific ("Email is invalid") not generic ("Please check your input")?

---

## Domain 6 — Mobile and Responsive Audit

### Test viewports
- 390px (iPhone 14 — primary mobile bar)
- 768px (tablet)
- 1440px (desktop standard)

### What to check at 390px
- No horizontal scroll on any page
- Navigation collapses and works correctly
- All CTAs are tappable (minimum 44px tap target)
- Tables scroll horizontally or reformat gracefully
- Forms are usable with mobile keyboard
- Modals don't overflow viewport
- Sticky headers don't consume too much screen real estate
- Long copy is readable (line length, font size, contrast)
- Loading states don't cause layout shift

### Common mobile failures
- Text too small to read without pinching
- Buttons too close together (tap target collision)
- Fixed sidebar that collapses badly
- Hero text that overflows at small viewport
- Cards that stack awkwardly
- Tables that become unusable (no horizontal scroll)

---

## Domain 7 — Trust Signal Audit

### What builds trust
- Real legal pages (not boilerplate)
- Real contact information
- Real company name (Perlantir AI Studio LLC)
- Real Iowa legal compliance language
- Credible pricing/costs (when live)
- Results/breakdown that feel consequential and permanent
- Admin surfaces that look operationally serious
- Docs that are accurate and complete
- Error states that acknowledge the problem without panic

### What destroys trust
- Placeholder content anywhere public-facing
- "Coming soon" in important sections
- Hardcoded fake stats
- Generic support@company.com email
- Stale branding (Agent Arena, BOUTS ELITE)
- Legal pages that feel copy-pasted from a template
- Admin surfaces that look like a prototype
- Error messages that expose DB errors or stack traces

### Trust signal checklist
- [ ] Real company name: Perlantir AI Studio LLC
- [ ] Iowa Code § 99B disclaimer where required
- [ ] All 4 legal pages with real content
- [ ] Real helpline numbers in responsible gaming
- [ ] 18+ notice prominent in footer
- [ ] Restricted states listed (WA, AZ, LA, MT, ID)
- [ ] Copyright year correct: 2026
- [ ] Support contact is real
- [ ] No placeholder Iowa address in contest rules
- [ ] No "BOUTS ELITE" in footer/copyright
- [ ] No "Agent Arena" references

---

## Domain 8 — Product/Marketing Consistency Audit

### The mismatch test
Premium marketing + rough product = credibility collapse.
Rough marketing + polished product = missed opportunity.
Both rough = not ready.
Both premium = ready to ship.

### What to score
| Surface | Expected quality level |
|---------|----------------------|
| Homepage | Premium marketing |
| Challenge pages | Product-grade |
| Results/breakdowns | Enterprise-grade |
| Admin surfaces | Operator-grade (serious, not pretty) |
| Docs | Technical-grade |
| Auth/onboarding | Professional-grade |

### The consistency test
- Does the homepage promise match what the product delivers?
- Does the visual language stay consistent across marketing, product, and admin?
- Is the tone consistent (serious technical platform throughout)?
- Are the quality levels roughly matched?
