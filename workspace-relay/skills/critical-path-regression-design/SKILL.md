# Critical Path Regression Design — Relay

## The 5 Most Important Flows to Protect

### 1. Auth Login → Dashboard
```javascript
await page.goto(BASE + '/login');
// Fill email + password
await page.getByLabel(/email/i).fill('qa-bouts-001@mailinator.com');
await page.getByLabel(/password/i).fill('BoutsQA2026!');
await page.getByRole('button', { name: /sign in|log in/i }).click();
// Verify redirect
await page.waitForURL('**/dashboard', { timeout: 10000 });
if (!page.url().includes('/dashboard')) findings.push('❌ Login failed to redirect to dashboard');
await page.screenshot({ path: '/tmp/relay-screenshots/critical-login-dashboard.png' });
```

### 2. Challenge Discovery → Detail
```javascript
// From API, get a real challenge ID
const apiResp = await page.request.get(BASE + '/api/challenges?limit=1');
const data = await apiResp.json();
const challengeId = data.challenges?.[0]?.id;
if (!challengeId) { findings.push('⚠️ No real challenge ID available'); return; }

await page.goto(BASE + '/challenges');
// Find first challenge card and click it
await page.getByRole('link', { name: /challenge|debug|fog|summit/i }).first().click();
await page.waitForURL(`**/challenges/**`, { timeout: 10000 });
// Verify key content present
const hasTitle = await page.getByRole('heading', { level: 1 }).isVisible();
if (!hasTitle) findings.push('❌ Challenge detail missing heading');
```

### 3. Leaderboard → Sub-Ratings Visible
```javascript
await page.goto(BASE + '/leaderboard');
await page.waitForSelector('table', { timeout: 10000 });
// Check sub-ratings column in table header
const tableHtml = await page.innerHTML('table');
const hasSubRatings = tableHtml.toLowerCase().includes('sub-rating') || 
                       tableHtml.toLowerCase().includes('process') ||
                       tableHtml.toLowerCase().includes('strategy');
if (!hasSubRatings) findings.push('❌ Leaderboard missing sub-ratings column');
```

### 4. Agent Profile → Radar Chart
```javascript
// Get real agent ID
const agentsResp = await page.request.get(BASE + '/api/agents?limit=1');
const agentsData = await agentsResp.json();
const agentId = agentsData.agents?.[0]?.id || agentsData[0]?.id;
if (!agentId) { findings.push('⚠️ No real agent ID available'); return; }

await page.goto(BASE + `/agents/${agentId}`);
const hasSvg = await page.locator('svg').first().isVisible().catch(() => false);
if (!hasSvg) findings.push('❌ Agent profile missing radar chart SVG');
```

### 5. Security Regressions (always run)
```javascript
// /qa-login must be 404
const qaResp = await page.goto(BASE + '/qa-login');
if (qaResp.status() !== 404) findings.push(`🔴 REGRESSION: /qa-login returned ${qaResp.status()}`);

// /admin unauthed redirects
await page.goto(BASE + '/admin');
if (!page.url().includes('/login')) findings.push(`🔴 REGRESSION: /admin accessible without auth`);

// /api/me returns 401 unauthenticated
const meResp = await page.request.get(BASE + '/api/me');
if (meResp.status() !== 401) findings.push(`🔴 REGRESSION: /api/me returned ${meResp.status()} (expected 401)`);
```

---

## Coverage Priority Matrix

| Flow | Risk if broken | Automation priority |
|------|---------------|-------------------|
| Login → dashboard | High — users can't access product | P0 — always |
| /qa-login = 404 | High — security backdoor | P0 — always |
| Admin redirect unauthed | High — security | P0 — always |
| Challenge list loads | High — product unusable | P0 |
| Legal pages 200 | High — compliance | P0 |
| Mobile no-scroll | Medium — regression risk | P1 |
| Sub-ratings column | Medium — feature | P1 |
| Result breakdown | Medium — core value prop | P1 |
| Admin shell load | Medium — operator tool | P1 |
