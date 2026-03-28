# Auth, Session & Access Control Audit — Aegis

## What to Test and Why
Access control is the highest-priority security domain for Bouts. Every protected resource must be gated at the API level — not just the UI. Supabase RLS provides a second layer of defense. Both must be verified.

---

## Auth Flow Tests

### Login Endpoint
```bash
# Normal login — get session cookie
curl -sv -X POST https://agent-arena-roan.vercel.app/api/auth/... 2>&1 | grep "set-cookie\|200\|401"

# Wrong credentials — verify error message doesn't reveal email existence
curl -s -X POST https://agent-arena-roan.vercel.app/... \
  -H "Content-Type: application/json" \
  -d '{"email":"notreal-xyz@example.com","password":"wrong"}'
# And with a real email but wrong password
curl -s -X POST https://agent-arena-roan.vercel.app/... \
  -H "Content-Type: application/json" \
  -d '{"email":"qa-bouts-001@mailinator.com","password":"wrongpassword"}'
# Both responses should be identical — don't reveal whether email exists
```

### Session JWT Analysis
After login, decode the JWT token:
```python
import base64, json

def decode_jwt(token):
    parts = token.split('.')
    payload = parts[1] + '=' * (4 - len(parts[1]) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))

# Check: what claims are in the token?
# - role claim (should be verified server-side, not trusted client-side)
# - exp claim (when does it expire?)
# - sub claim (user ID)
```

### JWT Manipulation Test
```bash
# 1. Get valid JWT from login
# 2. Decode the payload
# 3. Modify role claim to "service_role" or "admin"  
# 4. Re-encode WITHOUT updating signature
# 5. Send to admin endpoint
# Expected: 401 — signature invalid
# FAIL: 200 returned (role claim trusted without signature verification)
```

### Session Expiry Test
```bash
# Get a valid session
# Wait for expiry OR manually create a token with past exp claim
# Send to authenticated endpoint
# Expected: 401 — token expired, redirect to login
# FAIL: Expired token accepted
```

### Logout Test
```bash
# Log in, get session cookie
# Make authenticated request — verify it works
# Log out
# Replay the same session cookie
# Expected: 401 — server-side session invalidated
# FAIL: Session still valid after logout (client-side only invalidation)
```

---

## Route Gating Tests

### Admin Routes — Test All 3 Roles
```bash
BASE="https://agent-arena-roan.vercel.app"

# 1. Unauthenticated
echo "=== UNAUTHENTICATED ==="
curl -s -o /dev/null -w "%{http_code}" $BASE/api/admin/challenges
# Expected: 401

# 2. Authenticated competitor (not admin) — need competitor session cookie
echo "=== COMPETITOR ==="
curl -s -o /dev/null -w "%{http_code}" \
  -H "Cookie: COMPETITOR_SESSION_COOKIE" \
  $BASE/api/admin/challenges
# Expected: 403

# 3. Admin
echo "=== ADMIN ==="
curl -s -o /dev/null -w "%{http_code}" \
  -H "Cookie: ADMIN_SESSION_COOKIE" \
  $BASE/api/admin/challenges
# Expected: 200
```

### Dashboard Routes — Unauthed Redirect
```bash
# These should redirect to /login, not return 200 or 403
for route in /dashboard /dashboard/agents /dashboard/wallet /dashboard/results; do
    response=$(curl -s -o /dev/null -w "%{http_code}" $BASE$route)
    final_url=$(curl -sL -o /dev/null -w "%{url_effective}" $BASE$route)
    echo "$route: HTTP $response → $final_url"
    # Expected: redirects to /login (302 or 200 at /login)
done
```

### Security Critical Routes
```bash
# /qa-login MUST be 404
result=$(curl -s -o /dev/null -w "%{http_code}" $BASE/qa-login)
echo "/qa-login: $result (MUST be 404)"
[ "$result" == "404" ] && echo "✅ PASS" || echo "🚨 P0 FAIL — /qa-login accessible"
```

---

## RBAC Tests

### Cross-Competitor Data Access
```bash
# Log in as Competitor A
# Get agent ID of Competitor B
# Attempt to access Competitor B's private data
curl -s -H "Cookie: COMPETITOR_A_COOKIE" \
  $BASE/api/agents/[COMPETITOR_B_AGENT_ID]
# Verify: only public fields returned, no private competitor data
```

### Connector Key Privilege Boundary
```bash
# Valid connector key should ONLY work on intake
INTAKE_KEY="a86c6d887c15c5bf259d2f9bcfadddf9"

# Should work:
curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Authorization: Bearer $INTAKE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' \
  $BASE/api/challenges/intake
# Expected: 400 (bad payload) or 422 — not 401 (key valid, payload invalid)

# Should NOT work:
for endpoint in /api/admin/inventory /api/admin/forge-review /api/me /api/admin/challenges; do
    result=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $INTAKE_KEY" $BASE$endpoint)
    echo "Intake key on $endpoint: $result (should be 401/403)"
done
```

---

## Supabase RLS Verification

### Check RLS is Enabled
If you have DB access (via service role or Supabase dashboard):
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'challenges', 'profiles', 'agents', 
    'challenge_bundles', 'challenge_forge_reviews', 
    'challenge_inventory_decisions', 'arena_wallets'
);
-- All should have rowsecurity = true
```

### Verify Anon Key Doesn't Bypass
```bash
SUPA_URL="https://gojpbtlajzigvyfkghrg.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvanBidGxhanppZ3Z5ZmtnaHJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMjA4NzcsImV4cCI6MjA4OTY5Njg3N30.TtCCr-_6_NBgUAxN66Cct2yjC2h_UhoS-RGtvWhQq4I"

# Attempt to read admin-only tables with anon key
curl -s "$SUPA_URL/rest/v1/challenge_bundles?limit=1" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY"
# Expected: 403 or empty array (RLS blocks it)
# FAIL: Returns challenge bundle data (RLS not enforcing)
```

---

## P0 Failure Signals
- Admin API returns 200 to unauthenticated request
- Competitor can access admin API with 200
- /qa-login returns anything other than 404
- JWT role claim manipulation accepted (signature not verified)
- Expired session token accepted as valid
- Logout doesn't invalidate server-side session

## P1 Failure Signals
- Different error messages for "email not found" vs "wrong password" (user enumeration)
- Connector API key works on non-intake endpoints
- RLS not enabled on any protected table
- Dashboard accessible without auth (no redirect)
