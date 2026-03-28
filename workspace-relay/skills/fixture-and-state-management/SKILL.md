# Fixture & State Management — Relay

## Core Principle
Tests must declare their fixture requirements explicitly. A test that silently depends on magic seed data is a flake waiting to happen.

## Fixture Requirements by Test Type

### Smoke Tests
- No fixtures required — public routes only
- Pre-check: confirm BASE URL responds (api/health = 200)

### Auth Tests
- Required: qa-bouts-001@mailinator.com account with BoutsQA2026! password
- Pre-check: login succeeds, dashboard loads

### Challenge Tests
- Required: at least 1 active challenge in DB
- How to get: GET /api/challenges?limit=1 → extract ID
- Pre-check: API returns challenges array with at least 1 item

### Admin Tests
- Required: admin session (qa-bouts-001 has admin role)
- Required: /admin route accessible for admin
- Pre-check: /admin loads after login with admin credentials

### Onboarding Tests
- Required: fresh account (no existing profile)
- How to create: register new mailinator account just before test
- Cleanup: not required (mailinator accounts are throwaway)

## State Checks Before Critical Tests

```javascript
// Pre-flight check for challenge tests
async function verifyFixtures(page, BASE) {
  const issues = [];
  
  // 1. App is up
  const health = await page.request.get(BASE + '/api/health');
  if (health.status() !== 200) issues.push('FIXTURE FAIL: /api/health not 200');
  
  // 2. Active challenges exist
  const challenges = await page.request.get(BASE + '/api/challenges?limit=1');
  const challengeData = await challenges.json();
  const challengeList = challengeData.challenges || challengeData.data || challengeData;
  if (!Array.isArray(challengeList) || challengeList.length === 0) {
    issues.push('FIXTURE WARN: No active challenges found — challenge tests may be empty state only');
  }
  
  // 3. Active agents exist
  const agents = await page.request.get(BASE + '/api/agents?limit=1');
  const agentData = await agents.json();
  const agentList = agentData.agents || agentData.data || agentData;
  if (!Array.isArray(agentList) || agentList.length === 0) {
    issues.push('FIXTURE WARN: No registered agents found — agent tests will test empty state');
  }
  
  return { issues, challengeId: challengeList?.[0]?.id, agentId: agentList?.[0]?.id };
}
```

## Known Environment Limitations (Do Not Test)

| Limitation | Impact on tests | How to handle |
|-----------|----------------|--------------|
| Migration 00024 partial | /api/challenges/intake may 500 | Skip intake tests, note in coverage gaps |
| Stripe not live | Billing flows not testable | Mark as N/A in coverage matrix |
| No real match history | Replays may be empty | Test empty state is handled correctly |
| bouts.gg not connected | All tests use vercel URL | Acceptable for automation |
| challenge_bundles may not exist | Admin pipeline UI may 500 | Note in fixtures, skip pipeline tests |

## Fixture Hygiene Rules
1. Never assume seed data exists — verify it with an API call first
2. Never create challenges or results in automation (too much state to manage)
3. Never run calibration or bulk admin actions
4. Use real API responses to get real IDs — never hardcode unless as known-good fallback
5. Document when a test degrades gracefully (empty state) vs when it fails hard
