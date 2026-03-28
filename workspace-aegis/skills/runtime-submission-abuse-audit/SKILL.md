# Runtime & Submission Abuse Audit — Aegis

## Why This Matters
Submission abuse could let competitors gain unfair advantages, waste operator resources, or corrupt platform state. Test all categories systematically.

---

## Abuse Case Tests (from ABUSE_CASE_LIBRARY.md)

### AC-SUB-001: Duplicate Submission Prevention
A competitor should not be able to submit to the same challenge twice.

```bash
BASE="https://agent-arena-roan.vercel.app"
CHALLENGE_ID="41f952c5-b302-406e-a75a-c5f7a63a8ea4"

# First submission
curl -s -X POST "$BASE/api/challenges/$CHALLENGE_ID/submit" \
  -H "Cookie: COMPETITOR_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"solution_code": "print(\"hello\")", "language": "python"}'
# Note the HTTP status code

# Second submission (same challenge)
curl -s -X POST "$BASE/api/challenges/$CHALLENGE_ID/submit" \
  -H "Cookie: COMPETITOR_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"solution_code": "print(\"different solution\")", "language": "python"}'
# Expected: 409 Conflict or 422 Unprocessable Entity
# FAIL: 200 (submission accepted) — competitor can resubmit
```

### AC-SUB-002: Late Submission Rejection
```bash
# If a challenge has ended (status: retired/archived), submission should be rejected
curl -s -X POST "$BASE/api/challenges/[CLOSED_CHALLENGE_ID]/submit" \
  -H "Cookie: COMPETITOR_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"solution_code": "test"}'
# Expected: 400/422 — challenge not accepting submissions
# FAIL: 200 — late submission accepted
```

### AC-SUB-003: Oversized Payload Protection
```bash
# Generate a large payload and test the intake endpoint
python3 -c "
import json, sys
large_payload = {
    'family': 'blacksite_debug',
    'weight_class': 'lightweight',
    'format': 'sprint',
    'prompt': 'A' * 5000000,  # 5MB string
    'name': 'Test'
}
print(json.dumps(large_payload))
" | curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  --data-binary @- \
  "$BASE/api/challenges/intake"
# Expected: 413 (Payload Too Large) or 400 (Validation Error)
# FAIL: 200 or 500 (large payload processed or crashes server)
```

### AC-SUB-004: Malformed JSON Payload
```bash
# Invalid JSON
curl -s -X POST "$BASE/api/challenges/intake" \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  --data-raw 'this is not json at all' \
  -w "\nHTTP %{http_code}"
# Expected: 400 Bad Request with validation error
# Response should NOT contain: stack trace, internal path, PostgresError

# Missing required fields
curl -s -X POST "$BASE/api/challenges/intake" \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  -d '{}'
# Expected: 400 with specific validation error listing missing fields
# FAIL: 500 or vague error

# SQL-like injection in string field
curl -s -X POST "$BASE/api/challenges/intake" \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  -d '{"name": "'"'"'; DROP TABLE challenges; --", "family": "blacksite_debug"}' \
  | python3 -c "import sys; r=sys.stdin.read(); print('SQL in response' if 'syntax error' in r or 'PostgresError' in r else 'Clean response')"
```

### AC-SUB-005: Wrong Challenge State Entry
```bash
# Try entering a challenge that is in calibrating state (not active)
# Need a challenge_id that is in a non-active state
# If no such challenge exists in test data, note as "untestable — no seed data"
curl -s -X POST "$BASE/api/challenges/[CALIBRATING_CHALLENGE_ID]/enter" \
  -H "Cookie: COMPETITOR_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{}'
# Expected: 400/422 — challenge not in active state
```

---

## Cron and Internal Route Idempotency

### AC-RETRY-001: Quality Enforcement Idempotency
```bash
# Call the quality cron multiple times — verify no side effects from repeat calls
echo "First call:"
curl -s "$BASE/api/cron/challenge-quality" | python3 -c "import sys,json; d=json.load(sys.stdin); print('newly_quarantined:', d.get('result',{}).get('newly_quarantined',0), '| processed:', d.get('result',{}).get('processed',0))"

echo "Second call:"
curl -s "$BASE/api/cron/challenge-quality" | python3 -c "import sys,json; d=json.load(sys.stdin); print('newly_quarantined:', d.get('result',{}).get('newly_quarantined',0), '| processed:', d.get('result',{}).get('processed',0))"

echo "Third call:"
curl -s "$BASE/api/cron/challenge-quality" | python3 -c "import sys,json; d=json.load(sys.stdin); print('newly_quarantined:', d.get('result',{}).get('newly_quarantined',0), '| processed:', d.get('result',{}).get('processed',0))"

# Expected: same result each call, no increasing quarantine count
# FAIL: Each call quarantines more challenges (not idempotent)
```

### AC-RETRY-002: Migration Endpoint Post-Migration
```bash
# /api/internal/run-migration-024 should not exist post-migration
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/internal/run-migration-024")
echo "Migration endpoint: $code (should be 404 if deleted, or at minimum require auth)"
[ "$code" == "404" ] && echo "✅ PASS — endpoint removed" || echo "⚠️ WARN — endpoint still exists ($code)"
```

---

## Rate Limiting Assessment

### Login Brute Force
```bash
# Send 10 rapid login attempts
for i in {1..10}; do
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/..." \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"wrong'$i'"}')
  echo "Attempt $i: $code"
done
# Expected: eventually get 429 (Too Many Requests)
# FAIL: All 10 return 200 or 401 with no throttling (brute force possible)
# NOTE: Rate limiting on auth is P1, not P0, for this product category
```

---

## P0 Findings
- Duplicate submissions accepted (competitor can resubmit to change result)
- Oversized payload causes server crash (DoS vector)
- Malformed JSON causes visible PostgresError or stack trace
- Cron endpoint not idempotent (each call causes additional quarantines)

## P1 Findings
- Late submission to closed challenge accepted
- Entry to non-active challenge state accepted
- No validation on required fields (fails silently or with 500)
- Migration endpoint still accessible post-migration

## P2 Findings
- No rate limiting on login (brute force possible but not trivially practical)
- Oversized payload returns 500 instead of 413
- Error messages on invalid intake are generic rather than specific
