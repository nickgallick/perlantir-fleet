# SCORING_RUBRIC.md — Relay Automation Coverage Scoring

Every major Relay audit produces scores for all 10 categories.

---

## The 10 Scored Categories

| # | Category | Weight | What it measures |
|---|----------|--------|-----------------|
| 1 | Smoke Coverage Quality | 12% | Are all critical routes covered with fast smoke checks? |
| 2 | Critical Path Coverage Quality | 15% | Are the highest-value end-to-end flows covered? |
| 3 | Regression Protection Quality | 12% | Are known failure modes protected against re-introduction? |
| 4 | Evidence Capture Quality | 12% | Do failures produce useful, actionable diagnostic output? |
| 5 | Cross-Role Coverage Quality | 12% | Are all user/admin/competitor/spectator paths tested by role? |
| 6 | Mobile/Responsive Coverage | 8% | Is 390px viewport tested for key flows? |
| 7 | Cross-Browser Coverage | 7% | Is coverage beyond Chromium-only? |
| 8 | Test Reliability / Flake Resistance | 10% | Can the suite be trusted, or is it noisy? |
| 9 | Fixture / State Management | 7% | Are test prerequisites clean, deterministic, documented? |
| 10 | Overall Automation Readiness | 5% | Holistic: is the suite ready to protect a launch? |

---

## Score Scale
- **1–3**: Weak/untrustworthy — cannot rely on this for launch protection
- **4–5**: Below launch-quality — gaps create real risk
- **6–7**: Decent but incomplete — useful but not fully trusted
- **8**: Strong — trustworthy for this area
- **9**: Excellent — comprehensive, reliable, well-evidenced
- **10**: Elite — best-in-class for this product type

---

## Weighted Score Formula
```
Score = (Smoke × 0.12) + (CritPath × 0.15) + (Regression × 0.12) +
        (Evidence × 0.12) + (CrossRole × 0.12) + (Mobile × 0.08) +
        (CrossBrowser × 0.07) + (Reliability × 0.10) +
        (Fixtures × 0.07) + (Overall × 0.05)
```

---

## Letter Grade + Recommendation

| Score | Grade | Recommendation |
|-------|-------|----------------|
| 9.0–10.0 | A+ | Automation-ready: elite coverage |
| 8.5–8.9 | A | Automation-ready: ship with confidence |
| 8.0–8.4 | A- | Automation-ready with minor gaps |
| 7.5–7.9 | B+ | Automation-usable: targeted gaps documented |
| 7.0–7.4 | B | Automation-usable with gaps: P1s documented |
| 6.5–6.9 | B- | Automation-usable with conditions |
| 6.0–6.4 | C+ | Not trustworthy enough: major gaps |
| 5.0–5.9 | C | Not trustworthy: significant rebuild needed |
| Below 5.0 | D/F | Not trustworthy: critical work required |

---

## Ship Thresholds

### AUTOMATION-READY
- Weighted score ≥ 7.5
- No P0 automation failures
- Critical Path Coverage ≥ 7
- Evidence Capture ≥ 7
- Reliability ≥ 7

### AUTOMATION-USABLE WITH GAPS
- Zero P0 automation failures
- Weighted score ≥ 6.5
- All P1 gaps documented with owners
- Critical Path Coverage ≥ 6

### NOT TRUSTWORTHY ENOUGH
- Any P0 unresolved
- Critical Path Coverage < 5
- Reliability < 5 (suite is too flaky to trust)
- Weighted score < 6.0
