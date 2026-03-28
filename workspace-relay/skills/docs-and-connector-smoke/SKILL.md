# Docs & Connector Smoke Testing — Relay

## Why Docs Matter for Automation
If a developer can't follow the connector docs, they can't compete. Docs routes must always load with real content. This is a regression risk — docs can silently go stale.

## Docs Smoke Tests

```javascript
const docsRoutes = [
  { path: '/docs', required: ['connector', 'API', 'compete'] },
  { path: '/docs/connector', required: ['connector', 'setup', 'install'] },
  { path: '/docs/connector/setup', required: ['step', 'install', 'configure'] },
  { path: '/docs/api', required: ['API', 'endpoint', 'curl'] },
  { path: '/docs/compete', required: ['submit', 'judge', 'score'] },
];

for (const doc of docsRoutes) {
  const resp = await page.goto(BASE + doc.path, { waitUntil: 'domcontentloaded', timeout: 15000 });
  
  if (resp.status() !== 200) {
    findings.push(`❌ Docs ${doc.path}: HTTP ${resp.status()}`);
    continue;
  }
  
  const text = await page.evaluate(() => document.body.innerText);
  
  // Check for placeholder content
  const placeholders = ['coming soon', 'lorem ipsum', 'TBD', 'TODO'];
  for (const p of placeholders) {
    if (text.toLowerCase().includes(p.toLowerCase())) {
      findings.push(`⚠️ Docs ${doc.path}: placeholder content "${p}" found`);
    }
  }
  
  // Check at least some required terms appear
  const found = doc.required.filter(term => text.toLowerCase().includes(term.toLowerCase()));
  if (found.length === 0) {
    findings.push(`⚠️ Docs ${doc.path}: no expected content terms found (expected: ${doc.required.join(', ')})`);
  }
  
  await page.screenshot({ path: `/tmp/relay-screenshots/docs${doc.path.replace(/\//g, '_')}.png` });
}
```

## Connector Integration Smoke

Test the intake API endpoint behavior (no auth → 401):
```javascript
// Connector API smoke — verify intake endpoint responds correctly
const intakeResp = await page.request.post(BASE + '/api/challenges/intake', {
  data: {},
  headers: {}  // No auth
});
if (intakeResp.status() !== 401) {
  findings.push(`❌ Intake API: Expected 401 unauthenticated, got ${intakeResp.status()}`);
}

// With valid key but empty payload — expect 400/422 (key accepted, payload invalid)
const intakeWithKey = await page.request.post(BASE + '/api/challenges/intake', {
  data: {},
  headers: { 'Authorization': 'Bearer a86c6d887c15c5bf259d2f9bcfadddf9', 'Content-Type': 'application/json' }
});
if (intakeWithKey.status() === 401) {
  findings.push(`❌ Intake API: Valid key rejected with 401 — key may have changed`);
}
```

## Banned Content in Docs
```javascript
const bannedInDocs = ['coming soon', 'TODO', 'TBD', 'lorem ipsum', 'Agent Arena', 'BOUTS ELITE'];
for (const term of bannedInDocs) {
  if (text.toLowerCase().includes(term.toLowerCase())) {
    findings.push(`⚠️ Docs ${doc.path}: banned content "${term}" found`);
  }
}
```
