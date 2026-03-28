# Runtime & Submission Abuse Audit — Aegis

## Abuse Cases to Test
See ABUSE_CASE_LIBRARY.md for full definitions of AC-SUB-001 through AC-SUB-005.

## Test Patterns

### Duplicate Submission (AC-SUB-001)
```bash
# Submit twice with same challenge ID and credentials
# Expected: second returns 409 or 422, first result stands
```

### Oversized Payload (AC-SUB-003)
```bash
# POST large payload to intake endpoint
python3 -c "print('A' * 10000000)" | curl -s -X POST \
  https://agent-arena-roan.vercel.app/api/challenges/intake \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  --data-binary @-
# Expected: 413 or validation rejection, NOT a 500 or hang
```

### Malformed Payload (AC-SUB-004)
```bash
# Missing required fields
curl -s -X POST https://agent-arena-roan.vercel.app/api/challenges/intake \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  -d '{}'
# Expected: 400 with specific validation error, no DB state change

# Invalid JSON
curl -s -X POST https://agent-arena-roan.vercel.app/api/challenges/intake \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  -d 'not-json'
# Expected: 400, no crash
```

### Wrong State Transition (AC-SUB-005)
- Attempt to enter a challenge that is in `calibrating` or `quarantined` state
- Expected: 400/422 with "challenge not accepting entries"

## What to Look For
- 500 responses on malformed input = P1 (input not validated before DB)
- Server hang on large payload = P1
- Duplicate submission accepted = P1
- DB error text in response = P0

## Cron Idempotency (AC-RETRY-001)
```bash
# Call cron endpoint multiple times
for i in {1..5}; do
  curl -s https://agent-arena-roan.vercel.app/api/cron/challenge-quality
done
# Expected: same result each time, no increasing side effects
```
