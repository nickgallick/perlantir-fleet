# Connector & Billing Trust Audit — Aegis

## Connector (Intake API) Security Tests

### No Key (AC-ROLE-004 related)
```bash
curl -s -o /dev/null -w "%{http_code}" -X POST \
  https://agent-arena-roan.vercel.app/api/challenges/intake
# Expected: 401
```

### Wrong Key
```bash
curl -s -o /dev/null -w "%{http_code}" -X POST \
  https://agent-arena-roan.vercel.app/api/challenges/intake \
  -H "Authorization: Bearer wrongkey123"
# Expected: 401
```

### Valid Key on Wrong Endpoint (P0 if fails)
```bash
# Intake key should NOT work on admin endpoints
curl -s -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  https://agent-arena-roan.vercel.app/api/admin/inventory
# Expected: 401 or 403 — key not valid here
```

### Key in Error Response
```bash
# Trigger an error on intake — verify key not echoed back
curl -s -X POST https://agent-arena-roan.vercel.app/api/challenges/intake \
  -H "Authorization: Bearer a86c6d887c15c5bf259d2f9bcfadddf9" \
  -H "Content-Type: application/json" \
  -d '{}' | grep -i "key\|token\|secret\|GAUNTLET"
# Expected: zero matches
```

### Error Response Safety
- 401 response should say "Unauthorized" — not "Invalid API key: a86c6..."
- Error should not reveal the expected key format or hint at the correct key

## Billing (when Stripe goes live)

### Stripe Webhook Security
- Webhook endpoint must verify Stripe signature (stripe-signature header)
- Replay of old webhook events must be rejected (timestamp check)
- Webhook endpoint must be POST-only

### Coin Purchase Security
- No way to purchase coins without completing Stripe checkout
- Coin credit only applied after payment confirmed (not optimistic)
- Amount validation server-side — client-submitted amount not trusted

### Entitlement Mismatch
- Cannot enter paid challenge without sufficient coin balance
- Balance checked server-side at entry time, not just UI
- Refund on match cancellation is server-side triggered, not client-triggered

## Docs Security Review
- Connector setup docs should not mention GAUNTLET_INTAKE_API_KEY value
- API reference should not include any real tokens/keys in examples
- Docs should use placeholder values in code examples
