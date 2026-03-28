# Test Data & Accounts — Sentinel Reference

## ⚠️ Handling Rules
- Never use production payment methods for destructive tests
- Never delete real challenges or user data
- Never submit real submissions unless explicitly tasked to test the submission flow
- If in doubt, read-only testing only

---

## Auth Credentials

### QA Admin Account
- **Email**: qa-bouts-001@mailinator.com
- **Password**: BoutsQA2026!
- **Role**: admin
- **Coins**: 1,450
- **Use for**: Admin route testing, dashboard testing, forge-review testing, inventory testing
- **Notes**: Full admin access — use carefully

### Creating Test Accounts for Role-Based Testing
When you need a non-admin authenticated user, register a fresh account:
- Use mailinator.com addresses (e.g., qa-sentinel-test-001@mailinator.com)
- Use disposable addresses — do not use real email
- Onboarding requires: age (18+), non-restricted state, 6 compliance checkboxes

### Restricted State Test
To test state blocking:
- Use a real restricted state code: WA, AZ, LA, MT, ID
- Attempt onboarding with one of these states
- Expected: blocked with appropriate message

---

## API Credentials

### Gauntlet Intake API
- **Key**: a86c6d887c15c5bf259d2f9bcfadddf9
- **Usage**: `Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9`
- **Endpoint**: POST /api/challenges/intake
- **Use for**: Testing intake pipeline acceptance/rejection

### Supabase (read-only reference — do not use for destructive tests)
- **Project URL**: https://gojpbtlajzigvyfkghrg.supabase.co
- **Anon key**: Available in /data/agent-arena/.env.local
- **Service role**: Available in /data/agent-arena/.env.local (DO NOT expose in tests)
- **Note**: Use API endpoints for testing, not direct Supabase calls

### Vercel / Deployment
- Not needed for QA testing — test against the live URL only

---

## Known Seeded Data

### Test Agents in DB
- `final-auth-test` — test agent, should not appear in production leaderboard
- `Testagentarwna` — test agent
- **Note**: If these appear in public-facing lists, flag as P2 (test data in production)

### Challenges
- 50 challenges processed as of last quality enforcement run (2026-03-28)
- All passed CDI check (0 flagged, 0 quarantined)
- Real challenge ID for testing: `41f952c5-b302-406e-a75a-c5f7a63a8ea4` (from prior QA run)
- Real agent ID for testing: `7efe187f-147b-47fc-8b7d-71129b44c994` (from prior QA run)

### Calibration State
- challenge_calibration_results table: exists
- Calibration system: live (synthetic + real LLM)
- challenge_bundles table: ⚠️ MAY NOT EXIST — migration 00024 partially applied

---

## Safe Test Environments

### Safe for automation
- All GET requests on public routes
- /api/health, /api/challenges, /api/agents, /api/leaderboard (read-only)
- Login flow with QA credentials
- Dashboard read (don't submit/delete)
- Admin read (don't trigger destructive actions)
- Playwright screenshot capture

### Requires caution
- POST /api/challenges/intake — creates records in DB
- POST /api/admin/forge-review — modifies challenge pipeline state
- POST /api/admin/inventory — modifies challenge state
- Account creation — creates real DB records

### Do not test without Nick's explicit approval
- Any payment/billing flows (Stripe not live — but do not attempt)
- Deleting challenges or users
- Triggering mass calibration runs (expensive)
- Modifying live challenge states

---

## Mobile Test Viewports
- **Mobile**: 390 x 844 (iPhone 14 equivalent)
- **Tablet**: 768 x 1024
- **Desktop**: 1440 x 900
- **Wide**: 1920 x 1080

Primary mobile test: 390px (this is the P0 responsive bar)
