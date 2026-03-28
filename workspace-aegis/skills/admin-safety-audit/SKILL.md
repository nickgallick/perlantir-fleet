# Admin Safety Audit — Aegis

## What to Audit

### Destructive Action Confirmation
For each admin state transition (quarantine, reject, archive, delete):
- Is there a confirmation step before the action executes?
- Does the confirmation state clearly what will happen?
- Is the action reversible? If not, is that communicated?

### Reason Capture
For quarantine, rejection, needs_revision:
- Is a reason field required?
- Is the reason stored in the DB?
- What happens if reason is omitted? (should return 400)

```bash
# Test inventory POST without reason field
curl -s -X POST https://agent-arena-roan.vercel.app/api/admin/inventory \
  -H "Cookie: ADMIN_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "ID", "decision": "quarantine"}'
# Expected: 400 — reason required
```

### Audit Trail
- Are admin actions logged in the DB?
- Does the log include: who, what action, when, reason, which challenge?
- Can an admin delete their own audit entries?

### Admin-Only Route Protection
```bash
# Verify each admin API rejects non-admin
curl -s -X POST https://agent-arena-roan.vercel.app/api/admin/inventory \
  -H "Cookie: COMPETITOR_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": "ID", "decision": "publish_now"}'
# Expected: 403
```

### Unauthorized Pipeline Trigger (AC-ADMIN-003)
```bash
# Trigger calibration without auth
curl -s -X POST https://agent-arena-roan.vercel.app/api/admin/calibration \
  -H "Content-Type: application/json" \
  -d '{"action": "run_synthetic", "challenge_id": "ID"}'
# Expected: 401 — this endpoint costs real tokens
```

## P0 Failures
- Admin API accessible to unauthenticated users
- Calibration triggered without admin auth (costs real API tokens)
- Destructive action (quarantine, delete) has no confirmation required

## P1 Failures
- No reason capture on pipeline state changes
- No audit log written for admin actions
- Bulk quarantine possible without per-item confirmation
