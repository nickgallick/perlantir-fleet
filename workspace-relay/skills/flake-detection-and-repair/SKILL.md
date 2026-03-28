# Flake Detection & Repair — Relay

## See FLAKE_POLICY.md for classification and escalation rules.

## Detecting Flakes
Run any suspected test 5 times and count failures:
- 5/5 fail: real failure
- 3-4/5 fail: likely real failure with some stability issue
- 1-2/5 fail: flake — investigate
- 0/5 fail: likely one-off environment issue

## Common Fixes

### Timing Flake → Proper Wait
```javascript
// WRONG
await page.waitForTimeout(2000);

// RIGHT — wait for URL change
await page.waitForURL('**/dashboard', { timeout: 10000 });

// RIGHT — wait for element
await page.waitForSelector('[data-testid="challenge-list"]', { timeout: 10000 });

// RIGHT — wait for network response
await page.waitForResponse(
  resp => resp.url().includes('/api/challenges') && resp.status() === 200,
  { timeout: 10000 }
);
```

### Selector Fragility → Semantic Selectors
```javascript
// FRAGILE
page.locator('div.card-container > div:nth-child(2) > button.primary')

// STABLE
page.getByRole('button', { name: 'Register Agent' })
page.getByLabel('Email address')
page.getByText('Global Rankings')
```

### State Pollution → Context Isolation
```javascript
// Create fresh context for each role
const freshContext = await browser.newContext();
const freshPage = await freshContext.newPage();
// ... test ...
await freshContext.close(); // Clean up
```

### Seed Data Flake → Pre-flight Check
```javascript
// Always verify seed data before using it
const resp = await page.request.get(BASE + '/api/challenges?limit=1');
const data = await resp.json();
const challenges = data.challenges || data.data || data;
if (!challenges?.length) {
  result.skipped = true;
  result.skipReason = 'No active challenges — cannot test challenge flow';
  result.ok = true; // Don't fail — just note the gap
  return;
}
```

## Quarantine Protocol
When a test is too flaky to trust and can't be fixed immediately:
1. Add to MEMORY.md flake tracker with status: "Quarantined"
2. Remove from Layer 1/2 packs (don't let it block CI)
3. Keep in Layer 4 diagnostic pack
4. Set a reminder to fix or remove within 1 week
