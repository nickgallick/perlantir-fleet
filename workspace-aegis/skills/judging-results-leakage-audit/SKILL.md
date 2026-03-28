# Judging & Results Leakage Audit — Aegis

## What to Verify

### Hidden Test Case Protection (P0 if failed)
```bash
# Get challenge detail as competitor — verify no hidden tests
curl -s https://agent-arena-roan.vercel.app/api/challenges/41f952c5-b302-406e-a75a-c5f7a63a8ea4 \
  | python3 -m json.tool | grep -i "hidden\|test_case\|hidden_test"
# Expected: zero matches
```

### Judge Configuration Protection (P0 if failed)
```bash
# Get challenge — verify no judge weights/config in response
curl -s https://agent-arena-roan.vercel.app/api/challenges/41f952c5-b302-406e-a75a-c5f7a63a8ea4 \
  | python3 -m json.tool | grep -i "weight\|threshold\|rubric\|judge_config"
# Expected: zero matches for admin-only fields
```

### Result Immutability (P0 if failed)
- Activation snapshot must be frozen at activation time
- POST/PATCH to score endpoint after challenge is active → must return 403 or 405
- Verify: can admin modify a score post-activation? If yes, is it logged?

### Cross-Competitor Result Isolation
```bash
# As Competitor A, try to access Competitor B's detailed breakdown
# Expected: 403 or own data only returned
curl -s -H "Cookie: COMPETITOR_A_COOKIE" \
  https://agent-arena-roan.vercel.app/api/results/[COMPETITOR_B_RESULT_ID]
```

### Leakage Check on Public Result APIs
```bash
# Check public replay/result for admin-only fields
curl -s https://agent-arena-roan.vercel.app/api/replays?limit=1 \
  | python3 -m json.tool | grep -i "hidden\|service_role\|judge_weight\|calibration"
# Expected: zero matches for admin-only fields
```

## What Good Looks Like
- Challenge detail API: no hidden_tests, no judge_weights, no judge_config for competitor/anonymous
- Result API: competitor sees own lane scores, not raw judge output or other competitor data
- Activation snapshot: exists and frozen — no mutation endpoint for live challenges
- Admin APIs: return full detail — hidden tests, judge config accessible to admin only

## P0 Failures
- hidden_tests field present in any public or competitor-facing API response
- Judge weights or thresholds visible to competitor
- Score modification accepted after activation
- Competitor can see another competitor's raw judge output
