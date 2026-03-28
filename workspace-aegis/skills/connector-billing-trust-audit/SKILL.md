# Connector & Billing Trust Audit — Aegis

## Connector Security (Intake API)

### The Security Model
- GAUNTLET_INTAKE_API_KEY = `a86c6d887c15c5bf259d2f9bcfadddf9`
- Valid ONLY for: `POST /api/challenges/intake`
- All other endpoints must reject this key

### Test Matrix

```bash
BASE="https://agent-arena-roan.vercel.app"
KEY="a86c6d887c15c5bf259d2f9bcfadddf9"

echo "=== Connector Key Tests ==="

# 1. No key on intake — should 401
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/challenges/intake" -H "Content-Type: application/json" -d '{}')
echo "Intake (no key): $code (expected 401)"

# 2. Wrong key on intake — should 401
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/challenges/intake" -H "Authorization: Bearer wrongkey" -H "Content-Type: application/json" -d '{}')
echo "Intake (wrong key): $code (expected 401)"

# 3. Valid key on intake — should 200/400/422 (not 401)
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/challenges/intake" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -d '{}')
echo "Intake (valid key, empty payload): $code (expected 400/422, NOT 401)"

# 4. Valid key on admin endpoints — should 401/403 (P0 if 200)
for ep in /api/admin/inventory /api/admin/forge-review /api/admin/challenges /api/admin/calibration; do
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $KEY" "$BASE$ep")
    [ "$code" == "401" ] || [ "$code" == "403" ] && status="✅" || status="🚨 P0"
    echo "$status Intake key on $ep: $code (expected 401/403)"
done

# 5. Key in URL param (should not work — keys only via header)
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/challenges/intake?api_key=$KEY" -H "Content-Type: application/json" -d '{}')
echo "Intake (key in URL param): $code (expected 401 — key only via Authorization header)"
```

### Error Response Safety
```bash
# Verify error response on wrong key doesn't hint at the correct key
curl -s -X POST "$BASE/api/challenges/intake" \
  -H "Authorization: Bearer wrongkey123" \
  -H "Content-Type: application/json" \
  -d '{}'
# Response should say "Unauthorized" or similar
# Must NOT say: "Invalid key format", "Expected 32 hex chars", or echo any part of the real key
```

### Docs Security Check
```bash
# Verify connector setup docs don't include real API key in examples
curl -s "$BASE/docs/connector/setup" | grep -i "GAUNTLET_INTAKE\|a86c6d88"
# Expected: no matches
# The docs should use placeholder values like YOUR_API_KEY, not the real key
```

---

## Intake Validation Security

### Bundle Schema Validation
```bash
# Family must be a valid enum value
curl -s -X POST "$BASE/api/challenges/intake" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"family": "invalid_family", "weight_class": "lightweight", "format": "sprint"}' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('Status:', d.get('error', d.get('message', 'check response')))"
# Expected: 400 with "invalid family" validation error
# FAIL: 200 or generic 500

# Script injection in text fields
curl -s -X POST "$BASE/api/challenges/intake" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "<script>alert(1)</script>", "family": "blacksite_debug"}' \
  | python3 -c "import sys; r=sys.stdin.read(); print('XSS not sanitized' if '<script>' in r else 'Sanitized or rejected')"
# Expected: rejected (validation) or script tag escaped in response
```

---

## Billing Security (when Stripe goes live)

### Stripe Webhook Authentication
When Stripe is configured, verify:
```bash
# Webhook without Stripe signature should be rejected
curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/webhooks/stripe" \
  -H "Content-Type: application/json" \
  -d '{"type":"payment_intent.succeeded","data":{"object":{"amount":1000}}}'
# Expected: 400 — signature missing/invalid
# FAIL: 200 — webhook processed without signature verification

# Replay old Stripe event (timestamp too old)
curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/webhooks/stripe" \
  -H "Stripe-Signature: t=1000000000,v1=fakesig" \
  -H "Content-Type: application/json" \
  -d '{"type":"payment_intent.succeeded"}' 
# Expected: 400 — timestamp too old (replay prevention)
```

### Coin Balance Manipulation
```bash
# Can a user directly set their own coin balance?
curl -s -X PATCH "$BASE/api/me" \
  -H "Cookie: COMPETITOR_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"coins": 999999}'
# Expected: 400 (field not allowed) or the field is ignored
# FAIL: 200 — coin balance updated directly by user

# Verify coin balance is server-side only
curl -s -H "Cookie: COMPETITOR_COOKIE" "$BASE/api/me" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('Profile fields:', list(d.keys()))
# coins/balance should be present but read-only via this endpoint
"
```

---

## P0 Findings
- Intake API key works on admin endpoints (lateral movement)
- Stripe webhook processed without signature verification (payment injection)
- User can directly modify their own coin balance
- API key accepted via URL parameter (key logged in server logs)

## P1 Findings
- Error response on wrong key reveals key format or expected pattern
- Intake docs include real API key in examples
- No validation on bundle family/format/weight_class enum values
- Script injection in bundle name fields not sanitized

## P2 Findings
- Error messages on intake don't specify which fields are missing
- No rate limiting on intake endpoint (spam possible but low impact pre-launch)
