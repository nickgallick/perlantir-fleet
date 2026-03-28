# EVIDENCE_CAPTURE_STANDARD.md — Relay Evidence Requirements

## Why Evidence Quality Matters
A test failure without evidence wastes debugging time. A test failure WITH evidence lets Forge fix the issue in minutes.

## Evidence Requirements by Severity

| Severity | Screenshot | Full-page | Mobile | Console errors | Trace | Video |
|----------|-----------|-----------|--------|---------------|-------|-------|
| P0 | Required | Yes | If layout | Required | Recommended | If flow |
| P1 | Required | Yes | If layout | Recommended | Optional | Optional |
| P2 | Recommended | Optional | If relevant | Optional | No | No |
| P3 | Optional | No | No | No | No | No |

---

## Standard Evidence Capture Template

```javascript
exports.config = { headed: false, slowMo: 0 };

exports.run = async ({ browser, context, page, result }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  const fs = require('fs');
  const SCREENSHOTS = '/tmp/relay-screenshots';
  
  if (!fs.existsSync(SCREENSHOTS)) fs.mkdirSync(SCREENSHOTS, { recursive: true });
  
  const findings = [];
  const consoleErrors = [];
  
  // Capture all console errors
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(`[CONSOLE ERROR] ${msg.text()}`);
    }
  });
  
  // Capture page errors
  page.on('pageerror', err => {
    consoleErrors.push(`[PAGE ERROR] ${err.message}`);
  });
  
  try {
    // Desktop test
    await page.setViewportSize({ width: 1440, height: 900 });
    const resp = await page.goto(BASE + '/route', { waitUntil: 'domcontentloaded', timeout: 15000 });
    
    // Screenshot on every test (for evidence archive)
    await page.screenshot({ 
      path: `${SCREENSHOTS}/desktop-route-${Date.now()}.png`,
      fullPage: true 
    });
    
    // Add assertions here
    const title = await page.title();
    if (!title || title.includes('Error')) {
      findings.push(`❌ Page title suspicious: "${title}"`);
      // Screenshot already captured above
    }
    
    // HTTP status check
    if (resp.status() !== 200) {
      findings.push(`❌ HTTP ${resp.status()} on /route`);
    }
    
    // Mobile test
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto(BASE + '/route', { waitUntil: 'domcontentloaded', timeout: 15000 });
    await page.screenshot({ 
      path: `${SCREENSHOTS}/mobile-route-${Date.now()}.png` 
    });
    const hasHScroll = await page.evaluate(() => document.body.scrollWidth > window.innerWidth + 5);
    if (hasHScroll) findings.push(`❌ Mobile horizontal scroll on /route`);
    
  } catch (err) {
    findings.push(`❌ EXCEPTION: ${err.message}`);
    await page.screenshot({ path: `${SCREENSHOTS}/exception-${Date.now()}.png` }).catch(() => {});
  }
  
  // Write report
  const report = [
    `# Relay Test Report — ${new Date().toISOString()}`,
    '',
    `## Findings (${findings.length})`,
    ...findings,
    '',
    `## Console Errors (${consoleErrors.length})`,
    ...consoleErrors,
    '',
    `Screenshots: ${SCREENSHOTS}/`,
  ].join('\n');
  
  fs.writeFileSync('/tmp/relay-test-report.md', report);
  console.log(report);
  
  result.ok = findings.length === 0;
  result.findings = findings;
  result.consoleErrors = consoleErrors;
};
```

---

## Screenshot Naming Convention
`/tmp/relay-screenshots/[layer]-[role]-[route-slug]-[desktop|mobile]-[timestamp].png`

Examples:
- `smoke-anon-home-desktop-1234567890.png`
- `critical-admin-dashboard-desktop-1234567890.png`
- `regression-anon-leaderboard-mobile-1234567890.png`

---

## What to Include in a Finding Report

```
### RELAY-P0-001: [Title]

**Severity**: P0
**Test layer**: Smoke / Critical / Regression
**Route/Flow**: /route
**Browser**: Chromium | WebKit
**Viewport**: Desktop 1440x900 | Mobile 390x844
**Role**: anonymous | competitor | admin

**Evidence**:
- Screenshot: relay-screenshots/[filename].png
- Console errors: [list or "none"]
- HTTP status: [code]

**Reproduction**:
1. Navigate to /route as [role]
2. Observe [what]

**Expected**: [what should happen]
**Actual**: [what actually happens]

**Flake assessment**: Reproducible (tested 3 times) / Intermittent

**Assigned to**: Forge (@ForgeVPSBot)
```
