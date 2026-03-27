# Design Review: PayPulse Home Screen

**Brand:** UberKiwi  
**Screen:** Main / Home  
**Date:** 2026-03-20  
**Stitch Project:** 11589345584077126409  
**Screen ID:** cd912a1a036c49adb7cdb6547bad1214  
**Iteration:** 1  

---

## 1. Visual Hierarchy ✅
Strong. The summary card's $284.00 (green) and $127.50 (red) are the undeniable focal points — the user immediately sees their financial position. Reading order flows naturally: header → summary → active splits → tab bar. The FAB is visible without dominating.

**One concern:** All three split cards compete at the same visual weight. "Pending" items that need action don't stand out more than "Settled" ones.

## 2. Layout & Spacing ⚠️
Mostly solid. Horizontal margins are consistent (~24px). Card padding is consistent (~16px). Gap between split cards is consistent (~12px).

**Issues:**
- Summary card internal columns are not equal width — left ("You owe") appears narrower than right ("Owed to you")
- The vertical divider in the summary card is barely visible
- Subtext ("3 people", "5 people") was specified but is **missing** from the summary card

## 3. Typography ❌
**Font substitution:** Stitch used **Spline Sans** instead of the specified **Satoshi** for headings. Spline Sans is more neutral and generic — it lacks Satoshi's geometric sharpness that gives UberKiwi its fintech-forward feel. Both heading and body appear to use the same family, losing the intentional Satoshi/Outfit typographic contrast.

**Size issues:**
- "YOU OWE" / "OWED TO YOU" labels: ~10-11px uppercase — below the 12px minimum for labels
- Badge text (PENDING, YOU OWE, SETTLED): ~10px — too small for comfortable reading
- Card subtitles ("Oct 24 · 4 people"): ~13px — acceptable for secondary text but tight

## 4. Color ✅ (with notes)
Semantics are correct: green for positive amounts, red for negative. The settled amount (+$28.33) is correctly muted to gray — smart design decision that I did NOT specify but actually improves the design.

**Contrast concerns:**
- Gray secondary text (~#888) on #1A1A1A ≈ 3.5:1 — **fails WCAG AA** for normal text
- Badge text at 10px on tinted backgrounds — borderline contrast
- Green (#39FF14) on dark backgrounds passes AAA easily ✅
- Red on dark passes AA ✅

## 5. Components ✅
Cards, badges, avatar, and tab bar are all consistent within themselves. Badge pill styling is correct with semantic color tinting. FAB is properly sized (56px) with green glow shadow.

## 6. Interaction Design ⚠️
**Touch target issues:**
- "NG" avatar: ~40px — below 44px minimum
- "See all" link: text-only, insufficient vertical touch area
- Emoji circles on split cards: ~48px — acceptable ✅
- FAB: 56px ✅
- Tab bar items: adequate ✅

## 7. Edge States ⚠️
Not testable from a single static screen, but noted concerns:
- Long split names could overflow the card title area
- Large dollar amounts ($10,000+) could collide with the title column
- Summary card with $0/$0 — empty state not defined
- No loading state visible
- No error state visible

## 8. Accessibility ⚠️
- Secondary text gray fails WCAG AA (3.5:1 vs required 4.5:1)
- Badge text is extremely small (~10px) — readability risk
- No color-only indicators — amounts have both color AND +/- sign ✅
- Active tab uses color + filled icon (not color-only) ✅

## 9. Confusion Testing
- **Distracted User:** Would understand the screen — summary is clear, splits are scannable ✅
- **First-Time User:** Might not know what "splits" means without onboarding, but the card layout is self-explanatory ✅
- **Anxious User:** Red debt amount might cause anxiety, but the net positive (owed > owe) is clear ✅
- **Elderly User:** Small badge text and secondary text would be difficult to read ⚠️
- **Non-Native Speaker:** "+$62.00" and "-$34.75" are universal ✅

## 10. Brand Consistency ⚠️
The electric green accent is correctly applied throughout. Dark theme is correct (#0D0D0D). The overall feel is bold and modern. **However:**
- Wrong heading font (Spline Sans instead of Satoshi)
- Missing Outfit for body text
- Dates show "Oct" instead of "Mar" (content accuracy)
- The electric green border on the avatar is a nice touch but wasn't specified — acceptable addition

---

## Issues Found

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| 1 | **P1** | Font substitution: Spline Sans instead of Satoshi/Outfit | Regenerate with explicit Satoshi (headings) + Outfit (body) font loading |
| 2 | **P1** | Secondary text fails WCAG AA contrast (gray ~#888 on #1A1A1A) | Use #A3A3A3 minimum for secondary text (4.6:1 ratio) |
| 3 | **P2** | Summary card missing "3 people" / "5 people" subtexts | Add subtext below each amount in 12px #A3A3A3 |
| 4 | **P2** | Badge text too small (~10px) | Increase to 11px minimum with 500 weight |
| 5 | **P2** | "YOU OWE" / "OWED TO YOU" labels too small (~10px) | Increase to 13px |
| 6 | **P2** | "See all" touch target insufficient | Add 44px minimum tappable area with padding |
| 7 | **P2** | Avatar touch target ~40px, below 44px minimum | Increase to 44px diameter |
| 8 | **P2** | Dates show "Oct" instead of "Mar" | Correct to Mar 18, Mar 17, Mar 15 |
| 9 | **P3** | Summary card vertical divider barely visible | Increase opacity to rgba(255,255,255,0.1) |
| 10 | **P3** | Summary card columns not equal width | Balance 50/50 with equal flex |

## What's Done Well
- ✅ Electric green accent is bold and ownable — peak UberKiwi energy
- ✅ Settled amount muted to gray — smart design decision (better than my spec)
- ✅ FAB with green glow shadow — premium touch
- ✅ Green-tinted border on avatar — cohesive brand detail
- ✅ Overall composition breathes — generous spacing, no cramping
- ✅ Card structure is clean and scannable
- ✅ Tab bar active state uses both color + fill (accessible)
- ✅ Dark theme execution is premium — not just "dark gray", genuinely dark

---

## Verdict (Iteration 1): APPROVED WITH REVISIONS

The design is fundamentally strong — the layout, hierarchy, and brand energy are excellent. The UberKiwi DNA comes through clearly. However, the font substitution (P1) and contrast issues (P1) must be addressed before handoff. The remaining P2s are straightforward fixes.

---

# Iteration 2 + 3 (Code Fixes Applied)

## Changes Applied
1. ✅ Satoshi font loaded via CDN, applied to all headings (font-display class)
2. ✅ Outfit applied to all body text (font-body class)
3. ✅ Secondary text set to #A3A3A3, muted text to #737373
4. ✅ Summary card subtexts added ("3 people", "5 people")
5. ✅ Labels increased to 13px with tracking
6. ✅ Badge text increased to 11px
7. ✅ Summary card columns set to 50/50 (w-1/2)
8. ✅ Dollar amounts increased to 32px
9. ✅ Avatar set to 44px
10. ✅ Emoji icons set to 44px circles
11. ✅ Dates corrected to Mar 18/17/15
12. ✅ "See all" given min-h-touch (44px) class
13. ✅ Outer card border increased to white/10
14. ✅ Emoji rendering fixed (Noto Color Emoji installed)

## Remaining P3 (non-blocking)
- Emoji circles could be bumped to 48px for more breathing room
- Summary card could benefit from a subtle gradient to differentiate further

## Verdict (Final): APPROVED ✅

All P1 and P2 issues resolved. Design is ready for handoff to Maks.

**Files:**
- HTML: `/data/.openclaw/workspace-pixel/stitch-pulls/paypulse/home-screen-v3.html`
- Screenshot: `/data/.openclaw/workspace-pixel/stitch-pulls/paypulse/paypulse-v3-final.png`
- Stitch Project: `11589345584077126409`
