# Auth, Session & Access Control Audit — Aegis

## What to Test

### Login Flow
```bash
# Normal login
curl -s -X POST https://agent-arena-roan.vercel.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"qa-bouts-001@mailinator.com","password":"BoutsQA2026!"}'

# Wrong credentials — check error message doesn't reveal email existence
curl -s -X POST https://agent-arena-roan.vercel.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"notreal@example.com","password":"wrong"}'
# Expected: same error message as wrong password on real email
```

### Session / JWT Tests
- Decode the JWT returned after login
- Verify: does it contain role claim? Is role verified server-side or just trusted from token?
- Verify: what is the token expiry (exp claim)?
- Test: use expired token → should get 401

### Route Gating Tests
```bash
# Test admin route unauthenticated
curl -s -o /dev/null -w "%{http_code}" \
  https://agent-arena-roan.vercel.app/api/admin/challenges
# Expected: 401

# Test /qa-login (MUST be 404)
curl -s -o /dev/null -w "%{http_code}" \
  https://agent-arena-roan.vercel.app/qa-login
# Expected: 404
```

### RBAC Tests
```bash
# With competitor session cookie (not admin)
curl -s -H "Cookie: COMPETITOR_COOKIE" \
  https://agent-arena-roan.vercel.app/api/admin/challenges
# Expected: 403

# With admin session cookie
curl -s -H "Cookie: ADMIN_COOKIE" \
  https://agent-arena-roan.vercel.app/api/admin/challenges
# Expected: 200
```

## What Good Looks Like
- Admin APIs: 401 unauthenticated, 403 non-admin, 200 admin
- Dashboard: redirects unauthenticated to /login
- JWT manipulation (changed role claim): signature validation fails → 401
- Expired session: 401 with redirect to login, not a blank page

## P0 Failures
- Admin API returns 200 to unauthenticated request
- Competitor can access admin API with 200
- JWT role claim changed to "admin" is accepted
- /qa-login returns 200

## Supabase RLS Verification
Check that RLS is active on key tables:
```sql
-- Run via Supabase dashboard or service role
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('challenges', 'profiles', 'agents', 'challenge_bundles', 'challenge_forge_reviews');
-- All should have rowsecurity = true
```
