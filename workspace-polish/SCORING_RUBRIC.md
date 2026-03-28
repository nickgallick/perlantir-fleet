# SCORING_RUBRIC.md — Polish Canonical Scoring Framework

Every Polish audit must use this exact rubric. No exceptions. No drifting into impressionism.

---

## The 8 Scored Categories

### Category 1 — Visual Maturity (weight: 15%)
Does the visual design feel deliberate, premium, and disciplined?

| Score | Meaning |
|-------|---------|
| 1–3 | Amateur: broken layout, inconsistent styling, visually untrustworthy |
| 4–5 | Below launch: technically functional but no premium feel, obvious template residue |
| 6–7 | Decent: clean and consistent but not distinctive or premium |
| 8 | Strong: premium feel, clear hierarchy, intentional design choices |
| 9 | Excellent: design feels hand-crafted, visually mature, reflects product seriousness |
| 10 | Elite: best-in-class visual discipline for this product category |

**Evaluate**: First impression, hierarchy, visual rhythm, restraint, consistency across page types, density decisions

---

### Category 2 — Copy Maturity (weight: 15%)
Does the copy sound like a sharp team that built a real product?

| Score | Meaning |
|-------|---------|
| 1–3 | Damaging: generic AI buzzwords, obvious filler, copy says nothing specific |
| 4–5 | Weak: functional but forgettable, could describe any SaaS product |
| 6–7 | Decent: mostly clear and accurate, some filler or weak sections |
| 8 | Strong: specific, conviction-led, product-native language throughout |
| 9 | Excellent: every line earns its place, point of view is clear, copy is a trust signal |
| 10 | Elite: copy as sharp and specific as the product itself |

**Evaluate**: Specificity, product-native language, absence of filler, tone consistency, strongest vs weakest pages

---

### Category 3 — Enterprise Readiness (weight: 15%)
Would a serious technical buyer, operator, or partner trust this as an enterprise-grade platform?

| Score | Meaning |
|-------|---------|
| 1–3 | Prototype-level: admin/operator surfaces look unfinished, system language immature |
| 4–5 | Startup-level: works but would not be trusted by a serious buyer |
| 6–7 | Decent: mostly professional, some gaps in operator surfaces or system language |
| 8 | Strong: feels operationally serious, data displays are readable, system language precise |
| 9 | Excellent: enterprise-capable across all surfaces, would hold up in a serious evaluation |
| 10 | Elite: indistinguishable from premium enterprise infrastructure products |

**Evaluate**: Admin surface quality, system language precision, data display maturity, operator workflow completeness, error quality

---

### Category 4 — Product Consistency (weight: 12%)
Does the experience feel like one coherent product, or a collection of pages?

| Score | Meaning |
|-------|---------|
| 1–3 | Incoherent: major disconnects between marketing, product, and admin surfaces |
| 4–5 | Inconsistent: tone, quality, or visual language shifts noticeably across surfaces |
| 6–7 | Mostly consistent: minor gaps, overall reasonably coherent |
| 8 | Strong: consistent voice, visual language, and quality level throughout |
| 9 | Excellent: marketing → product → admin feels like one purposeful system |
| 10 | Elite: complete product coherence, every surface reinforces the brand |

**Evaluate**: Homepage promise vs actual product, marketing vs admin quality gap, tone consistency, visual language consistency

---

### Category 5 — Anti-AI-Built Quality (weight: 15%)
Does the product feel intentional and human-led, or assembled from patterns?

| Score | Meaning |
|-------|---------|
| 1–3 | Obviously AI-assembled: generic structure, template-generated feel, no product point of view |
| 4–5 | Heavy template residue: some personality but pattern-use dominates |
| 6–7 | Mostly intentional: a few generic signals but overall feels real |
| 8 | Strong: clearly product-specific design decisions, no obvious AI-built signals |
| 9 | Excellent: every page feels designed for its specific content, not assembled |
| 10 | Elite: distinctively human-led, impossible to mistake for a template |

**Evaluate**: Section uniqueness, copy specificity, layout decisions, interaction distinctiveness, visual point of view

---

### Category 6 — Trust Signal Quality (weight: 12%)
Do users feel safe, confident, and credibly informed?

| Score | Meaning |
|-------|---------|
| 1–3 | Trust-destroying: placeholder legal content, fake stats, broken error states |
| 4–5 | Weak: trust signals present but unconvincing or inconsistently placed |
| 6–7 | Adequate: most trust signals present, minor gaps |
| 8 | Strong: clear legal compliance, real company identity, precise system language |
| 9 | Excellent: trust signals reinforce credibility at every decision point |
| 10 | Elite: trust is embedded in the product experience itself |

**Evaluate**: Legal page quality, Iowa compliance language, company identity, error message quality, real vs fake data, status labeling

---

### Category 7 — Mobile Quality (weight: 8%)
Does the mobile experience feel as intentional as desktop?

| Score | Meaning |
|-------|---------|
| 1–3 | Broken: horizontal scroll, unusable forms, broken navigation |
| 4–5 | Functional but rough: works but clearly desktop-first thinking |
| 6–7 | Decent: mostly usable, minor overflow or layout awkwardness |
| 8 | Strong: clean collapse, all tap targets correct, navigation works well |
| 9 | Excellent: mobile experience feels designed, not adapted |
| 10 | Elite: mobile-first quality throughout |

**Evaluate**: 390px viewport: no horizontal scroll, navigation, tap targets, form usability, table handling, loading states

---

### Category 8 — Interaction Maturity (weight: 8%)
Do interactions feel considered, or default-library?

| Score | Meaning |
|-------|---------|
| 1–3 | Amateur: no hover states, broken focus states, loading with no feedback |
| 4–5 | Default library: functional but no finishing layer |
| 6–7 | Decent: most interactions polished, minor rough spots |
| 8 | Strong: hover/focus/active/disabled states all feel deliberate |
| 9 | Excellent: interactions feel tuned for this specific product |
| 10 | Elite: interaction quality as a trust signal in itself |

**Evaluate**: Hover states, focus states, loading states, empty states, error states, table interaction, form interaction

---

## Weighted Score Calculation

```
Weighted Score = 
  (Visual Maturity × 0.15) +
  (Copy Maturity × 0.15) +
  (Enterprise Readiness × 0.15) +
  (Product Consistency × 0.12) +
  (Anti-AI-Built Quality × 0.15) +
  (Trust Signal Quality × 0.12) +
  (Mobile Quality × 0.08) +
  (Interaction Maturity × 0.08)
```

---

## Letter Grade Conversion

| Weighted Score | Letter Grade | Interpretation |
|---------------|-------------|----------------|
| 9.0 – 10.0 | A+ | Elite — exceeds the bar |
| 8.5 – 8.9 | A | Excellent — ship confidently |
| 8.0 – 8.4 | A- | Strong — ship with minor polish |
| 7.5 – 7.9 | B+ | Good — ship with targeted fixes |
| 7.0 – 7.4 | B | Decent — conditional ship |
| 6.5 – 6.9 | B- | Below target — conditional ship with conditions |
| 6.0 – 6.4 | C+ | Weak — do not ship without P1 resolution |
| 5.0 – 5.9 | C | Failing — major work needed |
| 4.0 – 4.9 | D | Serious quality failure |
| Below 4.0 | F | Not launch-ready |

---

## Ship / Ship-With-Conditions / No-Ship Thresholds

### NO-SHIP (automatic)
Any of the following triggers a no-ship recommendation regardless of score:
- Any P0 finding unresolved
- Trust Signal Quality score ≤ 4
- Anti-AI-Built Quality score ≤ 3 (platform is embarrassing at its launch quality)
- Weighted overall score < 6.0

### CONDITIONAL SHIP
All of the following must be true:
- Zero P0 findings
- All P1 findings documented with fix plan and owner
- Weighted score ≥ 6.5
- No individual category score < 5
- Trust Signal Quality ≥ 6
- Anti-AI-Built Quality ≥ 6

**Conditions must be explicit**: List exactly what must be fixed before going live.

### SHIP
All of the following:
- Zero P0 findings
- P1 findings are minor or have accepted workarounds
- Weighted score ≥ 7.5
- No individual category score < 6
- Trust Signal Quality ≥ 7
- Anti-AI-Built Quality ≥ 7

---

## Scoring Discipline Rules
1. **Score what you tested, not what you assume.** If you didn't test mobile, don't score it 8.
2. **Explain every score.** A score without reasoning is worthless.
3. **Anchor to the rubric.** Not to your current mood or the last product you reviewed.
4. **Don't round up out of generosity.** A 6.8 is a 6.8, not a 7.
5. **Re-score after fixes.** A new deploy should trigger a re-score of affected categories.
