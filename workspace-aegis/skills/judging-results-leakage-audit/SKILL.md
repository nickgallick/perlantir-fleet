# Judging & Results Leakage Audit — Aegis

## Why This Is P0 Territory
Hidden test cases and judge configuration are the core competitive integrity of Bouts. If a competitor can access hidden tests before or during a match, the platform's credibility is destroyed. Test this first in every security audit.

---

## Hidden Test Case Protection

### API Response Inspection
```bash
BASE="https://agent-arena-roan.vercel.app"
CHALLENGE_ID="41f952c5-b302-406e-a75a-c5f7a63a8ea4"

# Check challenge detail API — as anonymous
curl -s "$BASE/api/challenges/$CHALLENGE_ID" | python3 -c "
import sys, json
data = json.load(sys.stdin)
# Look for any field that could contain test data
dangerous_fields = ['hidden_tests', 'test_cases', 'hidden', 'judge_config', 
                    'scoring_rubric', 'judge_weights', 'thresholds', 
                    'calibration', 'cdi', 'activation_snapshot']
found = []
def check(obj, path=''):
    if isinstance(obj, dict):
        for k, v in obj.items():
            full = path + '.' + k if path else k
            if any(f in k.lower() for f in dangerous_fields):
                found.append(f'SENSITIVE FIELD: {full} = {str(v)[:100]}')
            check(v, full)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            check(v, f'{path}[{i}]')
check(data)
if found:
    print('🚨 P0 POTENTIAL LEAKAGE:')
    for f in found: print(f)
else:
    print('✅ No sensitive fields found in challenge detail response')
"
```

### Compete as Authenticated Competitor
```bash
# Log in, get session, check challenge detail with auth
curl -s -H "Cookie: COMPETITOR_COOKIE" \
  "$BASE/api/challenges/$CHALLENGE_ID" | python3 -c "
import sys, json
data = json.load(sys.stdin)
# Same check but as authenticated user — should also have no hidden test data
print(json.dumps({k: v for k, v in data.items() if 'hidden' in k.lower() or 'test' in k.lower()}, indent=2))
"
```

---

## Judge Configuration Protection

### Check for Judge Weights in Response
```bash
curl -s "$BASE/api/challenges/$CHALLENGE_ID" | python3 -c "
import sys, json, re
response_text = sys.stdin.read()
# Check for judge weight patterns
patterns = [
    r'judge_weight', r'judge_config', r'threshold', r'scoring_weight',
    r'objective.*weight', r'process.*weight', r'strategy.*weight', r'integrity.*weight',
    r'0\.5[0-9]',  # 50% weight pattern
]
for p in patterns:
    if re.search(p, response_text, re.I):
        print(f'🚨 POTENTIAL JUDGE CONFIG: pattern \"{p}\" found')
print('Check complete')
"
```

### Activation Snapshot Accessibility
```bash
# Activation snapshot should be admin-only
# Check it's not in the public challenge API response
curl -s "$BASE/api/challenges/$CHALLENGE_ID" | grep -i "activation_snapshot\|frozen\|snapshot_id"
# Expected: no results
```

---

## Result Immutability

### Score Mutation Test
```bash
# After a challenge is active, attempt to modify a score
# Try PATCH/PUT on result endpoints
curl -s -X PATCH "$BASE/api/results/[RESULT_ID]" \
  -H "Cookie: ADMIN_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"objective_score": 100}'
# Expected: 403 or 405 — scores are immutable post-activation
```

### Activation Snapshot Immutability
```bash
# Verify the activation_snapshot table/record cannot be modified after creation
# Admin attempt to update snapshot
curl -s -X PATCH "$BASE/api/admin/challenges/$CHALLENGE_ID/snapshot" \
  -H "Cookie: ADMIN_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"judge_weights": {"objective": 0.9}}'
# Expected: 403 or 404 — no mutation endpoint exists
```

---

## Cross-Competitor Result Isolation

### Competitor A Cannot See Competitor B's Raw Output
```bash
# Log in as Competitor A (create fresh account for testing)
# Get Competitor B's result/replay ID (from /api/replays or leaderboard)
# Attempt to access detailed breakdown as Competitor A

curl -s -H "Cookie: COMPETITOR_A_COOKIE" \
  "$BASE/api/replays/[COMPETITOR_B_REPLAY_ID]/detail"
# Expected: 403 or only public summary data
# FAIL: Full raw judge output returned for another competitor's match
```

### Public Replay API — Field Inspection
```bash
# Check what public replay detail contains
curl -s "$BASE/api/replays?limit=1" | python3 -c "
import sys, json
data = json.load(sys.stdin)
replays = data.get('replays', data.get('data', data if isinstance(data, list) else []))
if replays:
    print('Public replay fields:', list(replays[0].keys()))
    # Should NOT include: raw_judge_output, hidden_test_results, internal_scores
"
```

---

## Leakage via Error States

### Probe with Malformed UUIDs
```bash
# Send malformed IDs and check if error reveals DB structure
curl -s "$BASE/api/challenges/not-a-uuid-at-all"
# Expected: 400 or 404 with generic message
# FAIL: PostgresError or SQL visible in response

curl -s "$BASE/api/challenges/'; DROP TABLE challenges; --"
# Expected: 400 with generic validation error
# FAIL: SQL error or any unexpected behavior
```

---

## P0 Findings (immediate escalation)
- hidden_tests field present in ANY response to competitor or anonymous role
- Judge weights or activation snapshot accessible to competitor
- Scores mutable after challenge activation
- Competitor can access another competitor's raw judge output
- SQL injection attempt causes a Postgres error (confirms unsanitized input reaching DB)

## P1 Findings
- Calibration data (CDI, calibration_results) accessible to competitors
- pipeline_status internal field exposed to public API consumers
- Replay detail exposes fields that should be admin-only
- Error on malformed UUID reveals internal schema names
