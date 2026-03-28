# Cross-Role Browser Testing — Relay

## Role Isolation Principle
Each role must be tested in its own isolated browser context. Never share sessions between role tests.

## Role Test Setup Patterns

### Anonymous (no auth)
```javascript
// Just navigate without any auth — default browser state
await page.goto(BASE + '/dashboard');
const finalUrl = page.url();
if (!finalUrl.includes('/login')) findings.push('❌ /dashboard accessible without auth');
```

### Authenticated Competitor
```javascript
const compContext = await browser.newContext();
const compPage = await compContext.newPage();

await compPage.goto(BASE + '/login');
await compPage.getByLabel(/email/i).fill('qa-bouts-001@mailinator.com');
await compPage.getByLabel(/password/i).fill('BoutsQA2026!');
await compPage.getByRole('button', { name: /sign in|log in|continue/i }).click();
await compPage.waitForURL('**/dashboard', { timeout: 10000 });

// Now test competitor flows with compPage
await compPage.goto(BASE + '/dashboard/agents');
const loaded = await compPage.getByRole('heading').isVisible();
if (!loaded) findings.push('❌ Dashboard/agents did not load for competitor');

await compContext.close();
```

### Admin User
```javascript
const adminContext = await browser.newContext();
const adminPage = await adminContext.newPage();

await adminPage.goto(BASE + '/login');
await adminPage.getByLabel(/email/i).fill('qa-bouts-001@mailinator.com'); // Admin account
await adminPage.getByLabel(/password/i).fill('BoutsQA2026!');
await adminPage.getByRole('button', { name: /sign in|log in|continue/i }).click();
await adminPage.waitForURL('**/dashboard', { timeout: 10000 });

// Test admin routes accessible
await adminPage.goto(BASE + '/admin');
const adminLoaded = !adminPage.url().includes('/login');
if (!adminLoaded) findings.push('❌ Admin redirected to login despite admin credentials');

await adminContext.close();
```

## Role Boundary Tests

### Competitor Cannot Access Admin Routes
```javascript
// After logging in as competitor:
await compPage.goto(BASE + '/admin');
// Should redirect to login OR show 403
const isBlocked = compPage.url().includes('/login') || 
                  await compPage.getByText(/forbidden|not authorized|403/i).isVisible().catch(() => false);
if (!isBlocked) findings.push('❌ ROLE BOUNDARY: Competitor can access /admin');
```

### Spectator (Anonymous) Cannot Access Dashboard
```javascript
await page.goto(BASE + '/dashboard/wallet');
const redirected = page.url().includes('/login');
if (!redirected) findings.push('❌ ROLE BOUNDARY: /dashboard/wallet accessible without auth');
```

## QA Agent Coordination for Role Tests
When Aegis finds a role-boundary issue:
1. Aegis files: "AEG-P0-001: Competitor accesses /admin with 200"
2. Relay creates: `relay-regression-AEG-P0-001-admin-role-boundary.js`
3. Test uses competitor context above
4. Regression test added to Layer 3 pack
