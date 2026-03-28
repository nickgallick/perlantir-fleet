# Browser Evidence Capture — Relay

## The Standard
Evidence is only useful if it answers: what failed, where, when, and why.

## Full Evidence Template
See EVIDENCE_CAPTURE_STANDARD.md for the complete template.

## Key Patterns

### Screenshot with context
```javascript
// Full page with context
await page.screenshot({ 
  path: `/tmp/relay-screenshots/${layer}-${role}-${slug}-${Date.now()}.png`,
  fullPage: true 
});
```

### Console + network error capture
```javascript
const consoleErrors = [];
const networkErrors = [];
const httpErrors = [];

page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push(msg.text()); });
page.on('pageerror', err => consoleErrors.push(`[PAGE ERROR] ${err.message}`));
page.on('requestfailed', req => networkErrors.push(`[NET FAIL] ${req.url()}: ${req.failure()?.errorText}`));
page.on('response', resp => { if (resp.status() >= 400) httpErrors.push(`[HTTP ${resp.status()}] ${resp.url()}`); });
```

### DB error detection
```javascript
const bodyText = await page.content();
const dbErrorPatterns = ['PostgresError', 'relation "', 'syntax error', 'ERROR: ', 'supabase error'];
for (const pattern of dbErrorPatterns) {
  if (bodyText.includes(pattern)) {
    findings.push(`🔴 DB ERROR VISIBLE: "${pattern}" on ${page.url()}`);
    await page.screenshot({ path: `/tmp/relay-screenshots/p0-db-error-${Date.now()}.png`, fullPage: true });
  }
}
```

### API response capture for P0 evidence
```javascript
// Capture full API response for evidence
const resp = await page.request.get(BASE + '/api/admin/challenges');
const status = resp.status();
let body = '';
try { body = JSON.stringify(await resp.json(), null, 2).substring(0, 500); } catch(e) {}
findings.push(`API /api/admin/challenges: HTTP ${status} | Body: ${body}`);
```

## Report Writing
```javascript
const report = [
  `# Relay Test Report`,
  `Date: ${new Date().toISOString()}`,
  `App: ${BASE}`,
  '',
  `## Summary`,
  `✅ Passed: ${passes.length} | ❌ Failed: ${findings.length}`,
  '',
  '## Findings',
  ...findings,
  '',
  '## Console Errors',
  ...consoleErrors,
  '',
  '## Network Errors',
  ...networkErrors,
  '',
  `Screenshots: /tmp/relay-screenshots/`,
].join('\n');

require('fs').writeFileSync(`/tmp/relay-report-${Date.now()}.md`, report);
```
