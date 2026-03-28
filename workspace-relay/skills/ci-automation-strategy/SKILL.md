# CI Automation Strategy — Relay

## See CI_TEST_STRATEGY.md for full run tier definitions.

## Quick Reference

### Run Smoke Pack (< 3 min)
```bash
node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js \
  /tmp/playwright-test-relay-smoke-$(date +%Y%m%d).js
```

### Run Critical Path Pack (10-15 min)
Run smoke + all critical path scripts in sequence.

### Pre-Launch Checklist
Before recommending launch:
- [ ] Smoke 100% pass
- [ ] /qa-login = 404 regression passes
- [ ] Auth redirects pass
- [ ] Mobile 390px no-scroll (4 pages) passes
- [ ] Legal pages 200 passes
- [ ] API smoke (health, challenges, me=401) passes
- [ ] Admin redirect passes

## What Breaks CI
- Any test in Layer 1 (smoke) failing
- Any Layer 3 regression test failing
- P0 findings in any layer

## What Doesn't Break CI
- Layer 4 diagnostic tests (ad hoc)
- Tests marked as skipped due to missing seed data
- Environment flakes (quarantined tests)
