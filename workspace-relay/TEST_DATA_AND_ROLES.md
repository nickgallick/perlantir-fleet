# TEST_DATA_AND_ROLES.md — Relay Fixture Reference

## Accounts

| Role | Email | Password | Notes |
|------|-------|----------|-------|
| Admin | qa-bouts-001@mailinator.com | BoutsQA2026! | Full admin access |
| Fresh competitor | Create on mailinator.com | Use temp email | For onboarding flow tests |
| Restricted user | Create on mailinator.com | Use temp email | Test with state: WA/AZ/LA/MT/ID |

## How to Get Session Cookies for Automation

```javascript
// In Playwright script — log in and save state
exports.run = async ({ browser, context, page, result }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  
  // Navigate to login
  await page.goto(BASE + '/login', { waitUntil: 'domcontentloaded' });
  
  // Fill credentials
  await page.getByLabel(/email/i).fill('qa-bouts-001@mailinator.com');
  await page.getByLabel(/password/i).fill('BoutsQA2026!');
  await page.getByRole('button', { name: /sign in|log in/i }).click();
  
  // Verify redirect to dashboard
  await page.waitForURL('**/dashboard', { timeout: 10000 });
  const dashboardUrl = page.url();
  
  result.ok = dashboardUrl.includes('/dashboard');
  result.sessionEstablished = result.ok;
};
```

## Seeded Data

| Data | Value | Notes |
|------|-------|-------|
| Real challenge ID | 41f952c5-b302-406e-a75a-c5f7a63a8ea4 | Verified on 2026-03-28 |
| Real agent ID | 7efe187f-147b-47fc-8b7d-71129b44c994 | Verified on 2026-03-28 |
| Active challenges | ~50 | All passed quality enforcement |
| Test agents in DB | final-auth-test, Testagentarwna | Should NOT be in public leaderboard |
| Connector key | a86c6d887c15c5bf259d2f9bcfadddf9 | Intake API only |

## Required State for Each Test Layer

### Smoke Tests
- No auth required for public routes
- For auth smoke: QA admin credentials

### Critical Path — Login/Dashboard
- QA admin account: qa-bouts-001@mailinator.com / BoutsQA2026!

### Critical Path — Onboarding
- Fresh mailinator account (create before test)
- Use non-restricted state (e.g., Iowa, Texas)

### Critical Path — Challenge Flows
- Real challenge ID: 41f952c5-b302-406e-a75a-c5f7a63a8ea4
- QA admin account (for authenticated challenge entry test)

### Admin Pipeline Tests
- QA admin account
- challenge_bundles table must exist (migration 00024 required — currently partial)

## Environment Limitations

| Limitation | Impact | Status |
|-----------|--------|--------|
| Migration 00024 partial | Admin pipeline UI may 500 | Forge working on fix |
| Stripe not live | Billing flow not testable | Nick owns timeline |
| No submission infra | Real submission flow not testable | Post-launch |
| No real match history | Replays/results may be empty | Design empty state tests |
| bouts.gg not connected | All tests use agent-arena-roan.vercel.app | Acceptable for now |

## Fixture Hygiene Rules
1. Never use production user data in tests
2. Always use mailinator.com or similar for test accounts
3. Never trigger bulk admin actions (quarantine all, etc.) in automation
4. Never run calibration in automation (costs real API tokens)
5. Clean up test-created agents/entries after regression runs where possible
