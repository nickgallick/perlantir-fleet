# MANUAL_TO_AUTOMATION_HANDOFF.md — Relay Conversion Protocol

When Sentinel, Polish, or Aegis find a real issue, Relay evaluates whether it should become a regression test.

## Handoff Triggers

### From Sentinel (functional QA)
When Sentinel files a P0 or P1 finding:
1. Is the failure browser-visible? (not just API-level)
2. Is it reproducible with Playwright?
3. Would it silently regress in the future without automation?
If yes to all 3 → Relay creates a regression test.

### From Polish (product quality)
When Polish finds a browser-visible state issue, layout regression, or broken interaction:
1. Is it detectable by Playwright? (element present, visible, no scroll overflow)
2. Is it likely to regress?
If yes → Relay creates a visual regression or state assertion test.

### From Aegis (security)
When Aegis finds a role-boundary or access control issue:
1. Is the issue browser-testable (route redirect, element visibility by role)?
2. Would a role-based Playwright test catch it?
If yes → Relay creates a role-based regression test.

---

## Conversion Decision Framework

| Finding type | Convert to automation? | Why |
|-------------|----------------------|-----|
| /qa-login accessible | ✅ Yes — already done | P0 security regression |
| Admin redirects unauthed | ✅ Yes — already done | P0 security regression |
| Mobile horizontal scroll | ✅ Yes — already done | Regression protection |
| Sub-ratings column missing | ✅ Yes | Feature regression |
| DB error visible on page | ✅ Yes | P0 regression check |
| Copy says "3-Judge Panel" | ✅ Yes (copy check) | Compliance regression |
| Visual design choice | ❌ No | Polish judgment call, not deterministic |
| JWT manipulation works | ❌ No | API-level, not browser-level |
| Admin UI looks like prototype | ❌ No | Judgment call, not automatable |

---

## Regression Test Template

When converting a finding to a regression test:

```javascript
// Name format: relay-regression-[finding-id]-[description].js
// Example: relay-regression-AEG-P0-001-qa-login-must-404.js

exports.config = { headed: false, slowMo: 0 };
exports.run = async ({ page, result }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  const findings = [];

  // Regression: [Original finding ID and description]
  // Added: [Date]
  // Original finding: [Sentinel/Polish/Aegis finding reference]
  
  const resp = await page.goto(BASE + '/qa-login', { waitUntil: 'domcontentloaded' });
  if (resp.status() !== 404) {
    findings.push(`🔴 REGRESSION: /qa-login returned ${resp.status()} (must be 404). Finding: AEG-security-001`);
    await page.screenshot({ path: '/tmp/relay-screenshots/regression-qa-login.png' });
  }
  
  result.ok = findings.length === 0;
  result.regressionTestName = 'qa-login-must-404';
  result.findings = findings;
};
```

---

## Current Regression Tests Built
| Test | Source finding | Date added |
|------|---------------|-----------|
| /qa-login = 404 | Security baseline | 2026-03-28 |
| Auth redirects on /dashboard | Security baseline | 2026-03-28 |
| Mobile no-scroll (4 pages) | 2026-03-28 E2E | 2026-03-28 |
| Leaderboard sub-ratings present | 2026-03-28 E2E | 2026-03-28 |

## Pipeline for New Regressions
1. Another QA agent files finding
2. Relay evaluates: automatable? worth protecting?
3. If yes: write regression test, add to COVERAGE_MATRIX_TEMPLATE.md, add to this table
4. Run it once to confirm it catches the issue
5. Add to regression pack (Layer 3)
6. Update MEMORY.md regression history
