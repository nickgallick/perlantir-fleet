# Examples

## Run a generated script

```bash
node "$SKILL_DIR/scripts/run_playwright_task.js" /tmp/playwright-test-homepage.js
```

## Minimal generated script pattern

```javascript
const { chromium } = require('playwright');

(async () => {
  const result = {
    ok: false,
    screenshots: [],
    consoleErrors: [],
    pageErrors: [],
    requestFailures: [],
    steps: [],
  };

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  page.on('console', msg => {
    if (msg.type() === 'error') result.consoleErrors.push(msg.text());
  });
  page.on('pageerror', err => result.pageErrors.push(String(err)));
  page.on('requestfailed', req => {
    result.requestFailures.push({
      url: req.url(),
      method: req.method(),
      failure: req.failure()?.errorText || 'unknown',
    });
  });

  try {
    result.steps.push('Opening target URL');
    await page.goto('https://example.com', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.screenshot({ path: '/tmp/playwright-test-homepage.png', fullPage: true });
    result.screenshots.push('/tmp/playwright-test-homepage.png');
    result.ok = true;
  } catch (err) {
    const failShot = '/tmp/playwright-test-homepage-fail.png';
    await page.screenshot({ path: failShot, fullPage: true }).catch(() => {});
    result.screenshots.push(failShot);
    result.error = String(err);
  } finally {
    await context.close().catch(() => {});
    await browser.close().catch(() => {});
    console.log(JSON.stringify(result, null, 2));
  }
})();
```
