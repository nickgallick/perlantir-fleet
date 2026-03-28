# Manual to Automation Conversion — Relay

## See MANUAL_TO_AUTOMATION_HANDOFF.md for the full protocol.

## Quick Decision Guide

Ask 3 questions:
1. Is it browser-visible/testable?
2. Is it likely to regress?
3. Would automation catch it reliably without being flaky?

All 3 yes → automate it.

## Conversion Template

When another QA agent files a finding that should become a regression test:

```javascript
// File: /tmp/playwright-test-relay-regression-[SOURCE-AGENT]-[FINDING-ID]-YYYYMMDD.js
// Source: [AGENT finding ID and description]
// Added: YYYY-MM-DD

exports.config = { headed: false, slowMo: 0 };
exports.run = async ({ page, result }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  const fs = require('fs');
  if (!fs.existsSync('/tmp/relay-screenshots')) fs.mkdirSync('/tmp/relay-screenshots', { recursive: true });
  
  const findings = [];
  
  // Test description: [what this protects]
  // Original source: [Sentinel/Polish/Aegis finding]
  
  // ... test code ...
  
  if (findings.length > 0) {
    console.log('REGRESSION DETECTED:', findings);
    await page.screenshot({ path: '/tmp/relay-screenshots/regression-[name].png', fullPage: true });
  }
  
  result.ok = findings.length === 0;
  result.regressionName = '[finding-id-description]';
  result.findings = findings;
};
```

## Current Regression Pack
See MANUAL_TO_AUTOMATION_HANDOFF.md for the current table of regression tests and their source findings.
