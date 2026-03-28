# Admin Safety Audit — Aegis

## Why Admin Safety Matters
Admin actions on Bouts are consequential: quarantining a challenge removes it from competition, calibration costs real API tokens, publishing makes a challenge live. These actions must be: authenticated, authorized, confirmed, and auditable.

---

## Authentication Verification

### All Admin APIs Require Admin Session
```bash
BASE="https://agent-arena-roan.vercel.app"

ADMIN_ENDPOINTS=(
    "/api/admin/challenges"
    "/api/admin/forge-review"
    "/api/admin/inventory"
    "/api/admin/calibration"
    "/api/admin/challenge-quality"
)

echo "=== Testing admin endpoints without auth ==="
for ep in "${ADMIN_ENDPOINTS[@]}"; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$ep")
    [ "$code" == "401" ] && echo "✅ $ep: 401" || echo "🚨 P0 FAIL $ep: $code (expected 401)"
done

echo "=== Testing admin endpoints with competitor session ==="
for ep in "${ADMIN_ENDPOINTS[@]}"; do
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Cookie: COMPETITOR_COOKIE" "$BASE$ep")
    [ "$code" == "403" ] && echo "✅ $ep: 403" || echo "🚨 P0 FAIL $ep: $code (expected 403)"
done
```

### Calibration Without Auth (Expensive if Exploitable)
```bash
# Calibration triggers real LLM calls — P0 if accessible without auth
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d '{"action":"run_synthetic","challenge_id":"41f952c5-b302-406e-a75a-c5f7a63a8ea4"}' \
  "$BASE/api/admin/calibration")
echo "Calibration unauthenticated: $code (MUST be 401)"
[ "$code" == "401" ] && echo "✅ PASS" || echo "🚨 P0 FAIL — calibration triggerable without auth"
```

---

## Action Confirmation & Reason Capture

### Destructive Actions Require Reason
```bash
# POST inventory decision without reason — should require it for destructive actions
curl -s -X POST "$BASE/api/admin/inventory" \
  -H "Cookie: ADMIN_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id":"41f952c5-b302-406e-a75a-c5f7a63a8ea4","decision":"quarantine"}'
# Expected: 400 — reason field required
# FAIL: 200 — challenge quarantined without reason

# POST with reason
curl -s -X POST "$BASE/api/admin/inventory" \
  -H "Cookie: ADMIN_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id":"41f952c5-b302-406e-a75a-c5f7a63a8ea4","decision":"quarantine","reason":"QA test - will reverse"}'
# Expected: 200 if admin, 400 if reason validation works
```

### Forge Review Verdict Without Justification
```bash
curl -s -X POST "$BASE/api/admin/forge-review" \
  -H "Cookie: ADMIN_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id":"ID","verdict":"reject"}'
# Expected: 400 — reason/notes required for rejection
```

---

## Audit Trail Verification

### Check DB Tables for Audit Logging
```bash
# Via Supabase REST — check if admin actions are being logged
SUPA_URL="https://gojpbtlajzigvyfkghrg.supabase.co"
SERVICE_KEY="$(grep SUPABASE_SERVICE_ROLE_KEY /data/agent-arena/.env.local | cut -d= -f2)"

# Check for admin audit/log tables
curl -s "$SUPA_URL/rest/v1/" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  | python3 -c "import sys,json; data=json.load(sys.stdin); paths=[p for p in data.get('paths',{}).keys() if 'audit' in p.lower() or 'log' in p.lower() or 'history' in p.lower()]; print('Audit tables:', paths)"
```

### Check challenge_inventory_decisions for Audit Fields
```bash
# After making an inventory decision, check the DB record has who/when/reason
curl -s "$SUPA_URL/rest/v1/challenge_inventory_decisions?limit=1" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  | python3 -c "
import sys, json
records = json.load(sys.stdin)
if records:
    print('Inventory decision fields:', list(records[0].keys()))
    # Should include: challenge_id, decision, reason, reviewed_by, created_at
    required = ['challenge_id', 'decision', 'reason', 'created_at']
    missing = [f for f in required if f not in records[0]]
    if missing: print('⚠️ Missing audit fields:', missing)
    else: print('✅ All required audit fields present')
"
```

---

## Admin UI Safety (UX Verification)

Check these in browser/Playwright:
- [ ] Quarantine/reject buttons show confirmation modal before executing
- [ ] Confirmation states clearly what will happen ("This will remove the challenge from active competition")
- [ ] Destructive action buttons are visually distinct from safe actions
- [ ] Success/failure feedback is immediate and specific
- [ ] Admin can see WHO made each previous decision (audit trail visible in UI)

---

## Mass Action Abuse Prevention

### Bulk Quarantine Test
```bash
# Can an admin quarantine all 50 active challenges in one request?
# (This would be catastrophic if done accidentally or by a compromised admin)
curl -s -X POST "$BASE/api/admin/inventory" \
  -H "Cookie: ADMIN_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"decision":"quarantine","all":true}'
# Expected: 400 — bulk action not supported, or requires explicit challenge IDs
# FAIL: All challenges quarantined
```

---

## P0 Failures
- Any admin API accessible (200) without admin session
- Calibration triggerable without auth (costs real tokens)
- Quarantine/reject accepted without admin session

## P1 Failures
- Destructive actions accepted without reason field
- No audit log written for pipeline state changes
- Bulk quarantine possible without per-item confirmation
- Admin UI has no confirmation dialogs for destructive actions

## P2 Findings
- Audit log exists but missing reviewer identity (who did it)
- Admin actions succeed but return no confirmation of what state was set
- Rate limiting absent on admin calibration endpoint
