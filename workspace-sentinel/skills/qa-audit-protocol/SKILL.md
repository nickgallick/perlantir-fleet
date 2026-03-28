# QA Audit Protocol — Sentinel Standard

## Audit Mindset
You are testing as a serious evaluator. Not a developer who knows the code. Not a friend who wants the product to succeed. A credible user who will lose trust the moment something doesn't work.

Ask at every step:
- Would a paying user accept this?
- Would a serious operator trust this?
- Would a developer who just connected their agent feel confident?

## Pre-Audit Checklist
Before starting any audit:
1. Confirm live URL is accessible and returning 200
2. Confirm QA credentials work (qa-bouts-001@mailinator.com / BoutsQA2026!)
3. Note current date/time (for time-sensitive tests)
4. Check /api/health first
5. Document your starting environment (desktop/mobile, viewport, browser)

## Role-Based Test Matrix

### Unauthenticated User
- All public routes load correctly (200, no errors)
- No authenticated content visible
- Dashboard/admin routes redirect to /login
- /qa-login returns 404
- Login/signup flows work
- Legal pages have real content
- Mobile responsive (390px — no horizontal scroll)

### Authenticated Competitor
- Login flow works end-to-end
- Onboarding: DOB + state + 6 checkboxes all required
- State restriction enforcement (test WA/AZ/LA/MT/ID)
- Dashboard loads with real data (not empty states with no explanation)
- Agent creation form validates properly
- Wallet shows correct balance
- Results page shows real data

### Admin/Operator
- /admin loads (not blocked for admin role)
- /admin/challenges loads
- Challenge pipeline actions work
- Forge review queue accessible
- Inventory decisions work

### Connector/Integration User
- /docs/connector shows real, accurate setup instructions
- /docs/api shows real API documentation
- Connector CLI instructions are accurate and complete
- Example code works

## Severity Decision Guide

### P0 (launch blocker)
Any of these = immediate escalation to Forge:
- Security: unauthed access to authed routes, data exposed to wrong role
- Payment: billing broken, coin balance wrong, prize pool wrong
- Judging: scores not delivered, lane breakdown missing/wrong
- State corruption: DB errors visible, 500 on critical path
- Legal compliance: onboarding missing DOB/state/checkboxes, /qa-login accessible
- Auth: login broken, signup broken, sessions not persisting

### P1 (major broken)
- Core feature completely non-functional
- Admin/operator dead end (can't complete workflow)
- Trust-destroying UX (empty state with no explanation, wrong data shown)
- Connector setup docs lead to failure

### P2 (important non-blocking)
- Feature partially broken or degraded
- UX significantly misleading
- Mobile layout broken on secondary pages
- Error messages unhelpful

### P3 (polish)
- Minor visual inconsistency
- Copy that could be clearer
- Non-critical empty state
- Minor responsive issue

## Playwright Test Pattern
Write scripts to /tmp/playwright-test-*.js

```javascript
exports.config = {
  headed: false,
  slowMo: 0,
};

exports.run = async ({ browser, context, page, result, helpers }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  
  // Navigate and test
  await page.goto(BASE + '/route', { waitUntil: 'domcontentloaded', timeout: 15000 });
  
  // Check for DB errors
  const body = await page.content();
  if (body.includes('PostgresError') || body.includes('syntax error')) {
    result.errors.push('DB error visible on page');
  }
  
  // Take screenshot
  await page.screenshot({ path: '/tmp/sentinel-screenshots/route.png' });
  
  result.ok = true;
};
```

Run with: `node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js /tmp/playwright-test-FILE.js`

## Defect Log Template

```
## [SEVERITY] Issue Title

**Severity**: P0/P1/P2/P3
**Environment**: https://agent-arena-roan.vercel.app
**Affected role**: public / authenticated / admin
**Route**: /route-path

**Steps to reproduce**:
1. 
2. 
3. 

**Expected**: What should happen
**Actual**: What actually happens
**Evidence**: Screenshot / console error / network response
**Reproducible**: Yes / No / Intermittent
**Suspected root cause**: (if known)
```

## Report Structure

### Executive Summary
- Overall verdict: PASS / CONDITIONAL PASS / FAIL
- P0 count: X
- P1 count: X  
- P2 count: X
- P3 count: X
- Launch readiness: BLOCKED / CONDITIONAL / READY

### Coverage Summary
| Domain | Tested | Method | Result |
|--------|--------|--------|--------|
| Public routes | ✅ | Playwright | N issues |
| Auth flows | ✅ | Manual + Playwright | N issues |
| ... | | | |

### Defect Log
(All issues in P0→P3 order)

### Visual/UX Issues
(Layout, responsive, copy, empty states)

### Risk Register
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| | | | |

### Recommended Fix Order
1. [P0] Fix X — assigned to Forge
2. [P0] Fix Y — assigned to Forge
3. [P1] Fix Z...
