# Evidence & Reporting — Aegis Standards

## The Evidence Standard
A security finding without reproducible evidence is a concern, not a finding. Aegis only files findings it can prove.

**P0**: Exact HTTP request + exact HTTP response that demonstrates the issue. Tested ≥ 2 times.
**P1**: Reproduction steps + response evidence. Tested at least once, reasoning for severity documented.
**P2**: Description + enough detail for another auditor to reproduce.
**P3**: Description sufficient.

---

## Evidence Capture Patterns

### Full Request + Response (use for all P0/P1 API findings)
```bash
# Full verbose output including headers
curl -sv -X GET \
  https://agent-arena-roan.vercel.app/api/admin/challenges \
  2>&1 | head -50

# Just status code
curl -s -o /dev/null -w "Status: %{http_code}\nURL: %{url_effective}\n" \
  https://agent-arena-roan.vercel.app/api/admin/challenges

# Status + response body
curl -s -w "\n---HTTP STATUS: %{http_code}---\n" \
  https://agent-arena-roan.vercel.app/api/admin/challenges | python3 -m json.tool
```

### Check for Sensitive Strings in Response
```bash
# One-liner to check response for dangerous content
curl -s https://agent-arena-roan.vercel.app/api/challenges?limit=1 | \
  python3 -c "
import sys
content = sys.stdin.read()
checks = {
    'Postgres error': 'PostgresError' in content or 'relation \"' in content,
    'Stack trace': 'at Object.' in content or 'at Function.' in content,
    'File path': '/data/' in content or '/var/' in content,
    'Service role': 'service_role' in content,
    'Env var pattern': 'SUPABASE_' in content or 'VERCEL_' in content,
    'Hidden tests': 'hidden_test' in content.lower(),
    'Judge config': 'judge_weight' in content.lower(),
}
for check, result in checks.items():
    status = '🚨 FOUND' if result else '✅ clean'
    print(f'{status}: {check}')
"
```

### Playwright Evidence for UI Findings
```javascript
// Save to /tmp/playwright-test-aegis-DOMAIN-DATE.js
exports.config = { headed: false, slowMo: 0 };
exports.run = async ({ page, result }) => {
  const BASE = 'https://agent-arena-roan.vercel.app';
  const fs = require('fs');
  if (!fs.existsSync('/tmp/aegis-screenshots')) fs.mkdirSync('/tmp/aegis-screenshots');
  
  const findings = [];
  
  // Test: /qa-login must be 404
  const qaLogin = await page.goto(BASE + '/qa-login', { timeout: 10000 });
  if (qaLogin.status() !== 404) {
    findings.push(`🚨 P0: /qa-login returns ${qaLogin.status()} (must be 404)`);
    await page.screenshot({ path: '/tmp/aegis-screenshots/p0-qa-login.png' });
  }
  
  // Test: /admin redirects unauthed
  const admin = await page.goto(BASE + '/admin');
  const adminUrl = page.url();
  if (!adminUrl.includes('/login')) {
    findings.push(`🚨 P0: /admin accessible without auth (final URL: ${adminUrl})`);
    await page.screenshot({ path: '/tmp/aegis-screenshots/p0-admin-unauthed.png' });
  }
  
  // Test: no DB errors in page content
  await page.goto(BASE + '/');
  const content = await page.content();
  if (content.includes('PostgresError') || content.includes('relation "')) {
    findings.push('🚨 P0: DB error visible on homepage');
    await page.screenshot({ path: '/tmp/aegis-screenshots/p0-db-error-home.png' });
  }
  
  findings.forEach(f => console.log(f));
  result.ok = findings.filter(f => f.includes('P0')).length === 0;
  result.findings = findings;
};
```

---

## Finding ID and Format

### ID Format
- P0: `AEG-P0-001`, `AEG-P0-002`
- P1: `AEG-P1-001`, `AEG-P1-002`
- P2: `AEG-P2-001`
- P3: `AEG-P3-001`

### Complete Finding Template
```
### AEG-P0-001: [Title]

**Severity**: P0
**Category**: access-control / abuse / leakage / admin-safety / integration / secrets
**Environment**: https://agent-arena-roan.vercel.app
**Affected role**: anonymous / competitor / admin
**Route/Endpoint**: /route or /api/endpoint

**Evidence**:
\`\`\`bash
curl -s -o /dev/null -w "%{http_code}" https://agent-arena-roan.vercel.app/api/admin/challenges
# Output: 200 (FAIL — expected 401)
\`\`\`

**Response body** (if relevant):
\`\`\`json
{ "data": [...] }
\`\`\`

**Reproduction steps**:
1. Send HTTP GET to /api/admin/challenges without any auth headers
2. Observe HTTP 200 response with admin challenge data

**Expected**: HTTP 401 Unauthorized
**Actual**: HTTP 200 with full challenge admin data

**Reproducible**: Yes — tested 3 times
**Suspected root cause**: Missing auth middleware on admin route, or middleware bypassed

**Recommended fix**: Add server-side admin role check at the beginning of the route handler. Verify Supabase RLS also enforces admin-only on challenge_bundles table.

**Assigned to**: Forge
```

---

## Escalation Protocol

### P0 Escalation — Immediate (Don't Wait for Report)
```
Message to Forge (@ForgeVPSBot):

🚨 AEGIS P0: [Title]

Route: [route/endpoint]
Finding: [one sentence]
Evidence: curl -s -o /dev/null -w "%{http_code}" [URL] → [actual result]
Expected: [expected result]
Severity reasoning: [why this is P0]
```

### Report Completion
After escalating P0s, complete the full report using REPORT_TEMPLATE.md.
Include all findings P0→P3, coverage report, and AEGIS SECURITY VERDICT block.

---

## False Positive Check Before Filing

Before filing any P0 or P1:
1. Have you confirmed it in FALSE_POSITIVE_GUARDRAILS.md? If listed as acceptable → don't file.
2. Is this an observed issue or a theoretical concern? Theoretical → risk register, not finding.
3. Can you provide the exact HTTP evidence? No evidence = not ready to file.
4. Is this a missing feature or a security gap? Missing feature → note it, don't rate it P0.

---

## Coverage Tracking
After every audit, update ROUTE_AND_ENDPOINT_INVENTORY.md with:
- ✅ for routes tested with no issues
- ⚠️ for routes tested with issues found
- ❌ for routes not tested (document why)
