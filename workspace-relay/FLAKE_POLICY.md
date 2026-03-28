# FLAKE_POLICY.md — Relay Flake Management

## Zero Tolerance for Hidden Flakiness
A flaky test is worse than no test. It trains the team to ignore failures.

**Rule**: When a test fails intermittently, it must be: fixed, quarantined, or removed. Never silently ignored.

---

## Flake Classification

### Type 1 — Timing Flake
Test fails because of race conditions or slow network responses.
**Fix**: Use proper Playwright waits (`waitForURL`, `waitForSelector`, `waitForResponse`) — never `page.waitForTimeout()`.

### Type 2 — Selector Fragility
Test fails because DOM structure changed but test didn't update.
**Fix**: Use semantic selectors (`getByRole`, `getByLabel`, `getByText`) over brittle CSS selectors.

### Type 3 — State Pollution
Test fails because previous test left unexpected state.
**Fix**: Make tests independently resettable. Use fresh context/browser per test group.

### Type 4 — Environment Flake
Test fails because of network timeout, Vercel cold start, or external service issue.
**Fix**: Add retry logic for network requests. Mark environment-sensitive tests separately.

### Type 5 — Seed Data Flake
Test fails because required seeded data doesn't exist or changed.
**Fix**: Document fixture requirements explicitly. Add pre-test assertions on seed state.

---

## Flake Detection Protocol

When a test fails:
1. Run it 3 more times immediately
2. If fails 2+ of 3: it's a real failure
3. If fails 0 of 3: it's environment flake — quarantine and investigate
4. If fails 1 of 3: it's a flake — investigate Type 1–5 above

---

## Flake Tracker Format
Add to MEMORY.md flake tracker:

```
## Flake: [Test name]
- Type: [1-5]
- Failure rate: X/10 runs
- Symptoms: [what the failure looks like]
- Status: Investigating / Fixed / Quarantined / Removed
- Fix applied: [what was done]
```

---

## Flake Escalation
- Type 1/2/3 flakes in critical path tests: P1 — fix immediately
- Type 4 environment flakes: P2 — add retry, mark as environment-sensitive
- Type 5 seed flakes: P1 — fix fixture or document limitation

---

## Good Wait Patterns (use these)
```javascript
// Wait for navigation to complete
await page.waitForURL('**/dashboard', { timeout: 10000 });

// Wait for specific element to appear
await page.waitForSelector('[data-testid="challenge-list"]', { timeout: 10000 });

// Wait for response to complete
await page.waitForResponse(resp => resp.url().includes('/api/challenges'));

// Use role-based locators (more stable)
await page.getByRole('button', { name: 'Register Agent' }).click();
await page.getByLabel('Email').fill('test@example.com');
await page.getByText('Submit Solution').click();
```

## Bad Patterns (avoid these)
```javascript
// NEVER use arbitrary sleeps
await page.waitForTimeout(2000); // WRONG

// NEVER use brittle nth-child selectors
await page.locator('div.card:nth-child(3) > button').click(); // FRAGILE

// NEVER assert on exact text that might change
expect(await page.textContent('h1')).toBe('The Competitive Arena for Autonomous Agents'); // BRITTLE

// INSTEAD — assert structure
await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
```
