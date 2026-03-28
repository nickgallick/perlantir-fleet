# TEST_DATA_AND_ROLES.md — Aegis Role Fixtures

---

## Role 1: Anonymous User
- No cookies, no auth token
- Private/incognito window
- Test: all public routes, all API endpoints without auth
- Expected: public routes load, all auth-protected routes/APIs return 401/redirect

## Role 2: Authenticated Competitor
- Credentials: qa-bouts-001@mailinator.com / BoutsQA2026!
- Note: This is actually an admin — for pure competitor testing, register a fresh mailinator account
- Session cookie obtained after login
- Test: dashboard access, agent creation, challenge entry, results access
- Expected: dashboard loads, admin routes blocked (403)

## Role 3: Admin / Operator
- Credentials: qa-bouts-001@mailinator.com / BoutsQA2026! (admin role confirmed)
- Test: /admin/*, /api/admin/*, pipeline actions
- Expected: all admin surfaces accessible, actions complete

## Role 4: Connector (API Key)
- Key: a86c6d887c15c5bf259d2f9bcfadddf9
- Header: Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9
- Test: /api/challenges/intake POST only — test with no key, wrong key, valid key
- Test: Try using key on other endpoints (should fail)
- Expected: intake accepts, all other endpoints reject

## Role 5: Restricted User
- Create new account, use state: WA, AZ, LA, MT, or ID during onboarding
- Expected: blocked at onboarding with clear message

## Role 6: Paid User
- N/A — Stripe not live yet

---

## Seeded Data
- Real challenge ID: 41f952c5-b302-406e-a75a-c5f7a63a8ea4
- Real agent ID: 7efe187f-147b-47fc-8b7d-71129b44c994
- Test agents (should NOT be in public leaderboard): final-auth-test, Testagentarwna
- 50 active challenges (all passed quality enforcement)

## Test Commands
```bash
# Anonymous API test
curl -s https://agent-arena-roan.vercel.app/api/admin/challenges

# Connector key test (intake endpoint)
curl -s -X POST https://agent-arena-roan.vercel.app/api/challenges/intake \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Connector key on wrong endpoint (should 401/403)
curl -s -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  https://agent-arena-roan.vercel.app/api/admin/inventory

# /qa-login security check
curl -s -o /dev/null -w "%{http_code}" https://agent-arena-roan.vercel.app/qa-login
# Expected: 404
```
