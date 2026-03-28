# Playwright & Evidence Capture — Polish Reference

## Polish's Use of Playwright
Polish uses Playwright differently than Sentinel.

Sentinel = functional testing (does it work?)
Polish = visual and behavioral evidence capture (does it feel right?)

For Polish, Playwright is primarily used for:
1. **Screenshots for P0/P1 evidence** — required for all major polish findings
2. **Mobile layout verification** — 390px viewport checks
3. **Visual state capture** — loading states, empty states, error states
4. **Copy verification** — capturing actual text on page for copy audit
5. **Consistency checks** — capturing the same component across multiple pages

## Playwright Skill
- **Skill**: /data/.openclaw/skills/playwright-skill-safe/SKILL.md
- **Runner**: `node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js /tmp/playwright-test-FILE.js`
- **Scripts**: Must go to `/tmp/playwright-test-*.js`
- **Screenshots**: Save to `/tmp/polish-screenshots/`

## Script Template for Polish Audits

```javascript
exports.config = {
  headed: false,
  slowMo: 0,
};

exports.run = async ({ browser, context, page, result }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  const fs = require('fs');
  
  if (!fs.existsSync('/tmp/polish-screenshots')) {
    fs.mkdirSync('/tmp/polish-screenshots', { recursive: true });
  }
  
  const findings = [];
  const screenshots = [];
  
  // Desktop screenshot
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(BASE + '/route', { waitUntil: 'domcontentloaded', timeout: 15000 });
  await page.screenshot({ 
    path: '/tmp/polish-screenshots/desktop-route.png',
    fullPage: true 
  });
  
  // Mobile screenshot
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(BASE + '/route', { waitUntil: 'domcontentloaded', timeout: 15000 });
  await page.screenshot({ 
    path: '/tmp/polish-screenshots/mobile-route.png',
    fullPage: true 
  });
  
  // Capture page text for copy audit
  const bodyText = await page.evaluate(() => document.body.innerText);
  
  // Check for banned phrases
  const bannedPhrases = ['Agent Arena', 'BOUTS ELITE', '3-Judge Panel', 'Three independent judges'];
  for (const phrase of bannedPhrases) {
    if (bodyText.includes(phrase)) {
      findings.push(`BANNED PHRASE: "${phrase}" found on /route`);
    }
  }
  
  result.ok = findings.length === 0;
  result.findings = findings;
  result.screenshots = screenshots;
};
```

## Evidence Requirements by Severity

| Severity | Desktop screenshot | Mobile screenshot | Full-page | Annotated |
|----------|-------------------|-------------------|-----------|-----------|
| P0 | Required | Required if layout issue | Yes | Recommended |
| P1 | Required | Required if layout issue | Yes | Optional |
| P2 | Recommended | Optional | Optional | No |
| P3 | Optional | No | No | No |

## Annotation Guidelines
For P0/P1 findings, where possible annotate screenshots:
- Red box around the problematic element
- Arrow pointing to the specific issue
- Caption: "What this is" / "Why it's a problem" / "What it should look like"

If annotation tools aren't available, describe position precisely:
"Top navigation bar, right side — the 'Console' button label conflicts with..."

## Screenshot Naming Convention
`/tmp/polish-screenshots/[severity]-[page-slug]-[desktop|mobile]-[YYYYMMDD].png`

Examples:
- `p0-homepage-desktop-20260329.png`
- `p1-leaderboard-mobile-20260329.png`
- `p2-footer-desktop-20260329.png`

## Copy Audit Pattern
```javascript
// Capture all text on a page and search for patterns
const bodyText = await page.evaluate(() => document.body.innerText);

// Check banned phrases
const bannedPhrases = [
  'Agent Arena', 'BOUTS ELITE', '3-Judge Panel',
  'Three independent judges', 'Claude+GPT', 'revolutionize',
  'streamline', 'lorem ipsum', 'coming soon', 'TBD'
];

// Check required phrases
const requiredPhrases = [
  'Perlantir AI Studio',
  'Iowa Code',
  '18+'
];
```

## What Polish Does NOT Use Playwright For
- Testing auth flows (Sentinel handles this)
- API endpoint testing (Sentinel handles this)
- Functional regression (Sentinel handles this)
- Testing if features work (Sentinel handles this)

Polish uses Playwright for evidence, not verification.
