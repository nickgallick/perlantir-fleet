# FALSE_POSITIVE_GUARDRAILS.md — Polish Over-Flagging Prevention

Polish audits are elite when they are ruthlessly accurate. They become noise when they over-flag.
This file defines what NOT to flag.

---

## The Core Principle
Only flag something when it genuinely damages:
- trust
- distinctiveness
- product maturity
- enterprise credibility
- clarity
- product seriousness

If the issue does not damage any of the above, it is a preference, not a finding.

---

## Never Confuse These Pairs

### Minimalism ≠ Genericity
**Minimalism**: A deliberate choice to show less in order to communicate more clearly.
**Genericity**: A lack of choices, resulting in a product that could be anything.

✅ Do flag: A page with five identical card types stacked with no hierarchy — that's genericity.
❌ Don't flag: A clean landing page with one strong headline and a direct CTA — that's minimalism.

The test: Does the simplicity serve the product's communication goal? If yes → minimalism. If no → genericity.

### Consistency ≠ Templating
**Consistency**: The same visual language used purposefully across a coherent product.
**Templating**: The same scaffold applied indiscriminately regardless of content needs.

✅ Do flag: Every page type — marketing, docs, admin, legal — uses the exact same three-column card layout.
❌ Don't flag: Consistent typography, color, button styles, and nav across all pages.

The test: Are the layout patterns serving the content, or ignoring it?

### Polish ≠ Fluff
**Polish**: Deliberate, earned finishing details that increase clarity and trust.
**Fluff**: Visual decoration with no UX or communication function.

✅ Do flag: Glow effects, gradient overlays, and animated backgrounds that add visual noise without helping comprehension.
❌ Don't flag: A smooth page transition that makes the state change clear. Skeleton loading that reduces perceived wait time.

### Visual Modernity ≠ Product Maturity
**Visual modernity**: A product looks current, uses modern UI conventions, has a clean dark theme.
**Product maturity**: A product handles edge cases, communicates precisely, and treats the user as an intelligent adult.

✅ Do flag: A visually modern page with a broken empty state that just shows a blank white area.
❌ Don't flag: A dark theme and rounded card design. These are not "AI-built signals" — they're modern design conventions.

---

## What NOT to Flag as "AI-Built"

### Don't flag these as AI-built signals
- Standard SaaS navigation patterns used correctly (these exist because they work)
- Dark theme (not an AI signal — it's a product aesthetic choice)
- Feature cards in a grid (only a signal if the information logic is wrong)
- CTA buttons saying "Get Started" (only a signal if the product has no other personality anywhere)
- Clean, simple section design (minimalism is not AI-built)
- Use of standard UI library components (only a signal if there's no finishing layer)

### Do flag these as AI-built signals
- The homepage has NO section that could only belong to Bouts specifically
- Every feature card follows the exact same "icon → headline → one line → no specifics" pattern
- Copy uses generic startup vocabulary throughout with no product-specific language
- The page layout choices seem to ignore the actual content (same grid for dense data and sparse data)
- Transitions and animations that serve no UX purpose and feel decorative
- Sections that could be deleted without the page making less sense

---

## Incomplete Areas — Do Not Over-Penalize

### Admin/Operator Surfaces
Admin surfaces serve operators, not marketing reviewers. Evaluate them on: Does this help an operator do their job?

**Do NOT flag**:
- Admin pages that are dense and text-heavy (that's appropriate)
- Admin pages that use standard table patterns (operators don't need emotional design)
- Admin pages that don't have the visual polish of marketing pages (that's normal)

**DO flag**:
- Admin pages that have broken workflows or dead ends
- Admin pages with no empty states or error states
- Admin pages that feel like raw API output rather than a real tool

### Docs Pages
Docs should be precise and navigable. They do not need to be beautiful.

**Do NOT flag**:
- Docs that are dense with technical content
- Docs that use a simple left-nav + content layout
- Docs with minimal visual treatment

**DO flag**:
- Docs that are clearly incomplete (placeholder sections where content should be)
- Docs that are inaccurate
- Docs that have no obvious path for the developer's actual workflow

### Empty States Due to Missing Data
Bouts hasn't run real competitions yet. Many data-dependent states will be empty.

**Do NOT flag as P1/P0**:
- Empty leaderboard (no agents have competed)
- Empty replays (no matches have run)
- Empty dashboard results (new account)

**DO flag**:
- Empty states that look like broken pages (no message, no guidance, no CTA)
- Empty states that destroy trust by looking like a failed load

### Known Environment Limitations
Do not flag things listed in KNOWN_ENV_LIMITATIONS.md (Sentinel's file — ask for it if needed).
Always check whether an issue is a known limitation before logging it.

---

## The "Preference vs Finding" Test
Before filing any finding, ask:

1. Does this damage trust, distinctiveness, maturity, credibility, or clarity? → Finding
2. Is this something I personally would do differently? → Preference
3. Would a serious buyer/user lose trust because of this? → Finding
4. Would a serious buyer/user not even notice this? → Preference

**When in doubt: explain the damage.** If you cannot articulate what specifically is damaged, it's probably a preference — note it but don't file it as a defect.

---

## The Minimum Threshold for Each Severity

**P0**: Can you articulate how this makes Bouts look fake, broken, amateur, or unsafe to a first-time serious buyer?
**P1**: Can you articulate how this significantly degrades trust, seriousness, or usability for a real user?
**P2**: Is this genuinely noticeable and does it reduce quality in a measurable way?
**P3**: Is this an actual, specific, reproducible polish issue — not just a general feeling?

If you cannot pass the threshold test for a given severity → downgrade it.
