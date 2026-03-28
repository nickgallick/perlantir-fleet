# Playwright Foundations — Relay Reference

## Playwright Skill Setup
- **Skill location**: /data/.openclaw/skills/playwright-skill-safe/SKILL.md
- **Runner**: `node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js /tmp/playwright-test-FILE.js`
- **Scripts must go to**: `/tmp/playwright-test-*.js`
- **Screenshots**: `/tmp/relay-screenshots/`

## Script Contract
```javascript
exports.config = {
  headed: false,
  slowMo: 0,
};

exports.run = async ({ browser, context, page, result, helpers, chromium }) => {
  // Your test code here
  result.ok = true;
};
```

## Core Playwright Patterns

### Navigate and check status
```javascript
const resp = await page.goto(BASE + '/route', { waitUntil: 'domcontentloaded', timeout: 15000 });
const status = resp ? resp.status() : 0;
```

### Wait for navigation
```javascript
await page.waitForURL('**/dashboard', { timeout: 10000 });
```

### Role-based selectors (prefer these)
```javascript
await page.getByRole('button', { name: 'Sign In' }).click();
await page.getByLabel('Email').fill('test@example.com');
await page.getByPlaceholder('Enter your email').fill('test@example.com');
await page.getByText('Challenges').click();
await page.getByRole('heading', { name: 'Global Rankings' }).isVisible();
```

### Screenshots
```javascript
await page.screenshot({ path: '/tmp/relay-screenshots/page-desktop.png', fullPage: true });
// Mobile
await page.setViewportSize({ width: 390, height: 844 });
await page.screenshot({ path: '/tmp/relay-screenshots/page-mobile.png' });
```

### Console error capture
```javascript
const errors = [];
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
page.on('pageerror', err => errors.push(err.message));
```

### Mobile horizontal scroll check
```javascript
const hasHScroll = await page.evaluate(() => document.body.scrollWidth > window.innerWidth + 5);
```

### New page/context for role isolation
```javascript
const adminContext = await browser.newContext();
const adminPage = await adminContext.newPage();
// Log in as admin
await adminPage.goto(BASE + '/login');
// ... fill credentials
await adminContext.close();
```

### API request from browser context
```javascript
const apiResp = await page.request.get(BASE + '/api/challenges?limit=1');
const data = await apiResp.json();
const challengeId = data.challenges?.[0]?.id;
```

## Viewports
```javascript
const DESKTOP = { width: 1440, height: 900 };
const MOBILE = { width: 390, height: 844 };
const TABLET = { width: 768, height: 1024 };

await page.setViewportSize(DESKTOP);
```

## Anti-Patterns — Never Do These
```javascript
// NEVER arbitrary sleep
await page.waitForTimeout(2000); // WRONG

// NEVER brittle nth-child
await page.locator('div:nth-child(3) > button').click(); // FRAGILE

// NEVER skip error capture
// Always attach console listener before navigation
```
