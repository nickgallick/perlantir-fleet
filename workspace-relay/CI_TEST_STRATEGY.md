# CI_TEST_STRATEGY.md — Relay Test Run Strategy

## Test Run Tiers

### Tier 1 — Smoke Run (run frequently, fast)
**When**: After every deploy, on demand
**Time target**: < 3 minutes
**Scope**: Layer 1 smoke tests only — all public routes, auth redirects, /qa-login=404, API health
**Coverage**: Breadth over depth
**Failure threshold**: Any P0 = block

```bash
# Run smoke pack
node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js \
  /tmp/playwright-test-relay-smoke-$(date +%Y%m%d).js
```

### Tier 2 — Critical Path Run (run pre-launch, after major features)
**When**: Pre-launch, after major feature deploys
**Time target**: 10–15 minutes
**Scope**: Layer 1 + Layer 2 — all smoke + critical path workflows
**Coverage**: All major user/admin flows
**Failure threshold**: Any P0/P1 = flag for immediate review

### Tier 3 — Full Regression Run (run weekly or after bug fixes)
**When**: Weekly, after P0/P1 bug fixes
**Time target**: 20–30 minutes
**Scope**: All layers — smoke + critical + regression pack
**Coverage**: Comprehensive
**Failure threshold**: P0 = block, P1+ = document and monitor

---

## Pre-Launch Checklist
Before recommending launch from automation perspective:
- [ ] Smoke run passes 100%
- [ ] Critical path run passes
- [ ] /qa-login = 404 regression passes
- [ ] Auth redirect regressions pass
- [ ] Mobile 390px no-scroll passes on 4+ key pages
- [ ] Legal pages 200 passes
- [ ] API smoke passes (health, challenges, agents, me=401)
- [ ] Admin redirect passes (anon → /login)
- [ ] No P0 automation failures

---

## Script Organization
```
/tmp/playwright-test-relay-smoke-YYYYMMDD.js         # Layer 1 - all smoke
/tmp/playwright-test-relay-critical-auth-YYYYMMDD.js  # Layer 2 - login flow
/tmp/playwright-test-relay-critical-challenge-YYYYMMDD.js  # Layer 2 - challenge flow
/tmp/playwright-test-relay-regression-security-YYYYMMDD.js  # Layer 3 - security regressions
/tmp/playwright-test-relay-regression-mobile-YYYYMMDD.js    # Layer 3 - mobile regressions
/tmp/playwright-test-relay-diagnostic-YYYYMMDD.js    # Layer 4 - ad hoc
```

---

## What Goes in CI vs Manual

| Test type | CI | Manual | Notes |
|-----------|-----|--------|-------|
| Smoke tests | ✅ | | Fast, run always |
| Critical path | ✅ | | Run pre-launch |
| Regression pack | ✅ | | Run weekly |
| Billing flow | ❌ | ✅ | Stripe not automated |
| Deep admin workflows | ❌ | ✅ | Too much state management |
| Visual polish checks | ❌ | ✅ | Polish agent handles this |
| Security probing | ❌ | ✅ | Aegis handles this |
