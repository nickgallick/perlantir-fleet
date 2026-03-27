#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const outDir = process.argv[2] || '/tmp/qa-bug-artifacts';
const title = process.argv[3] || 'Untitled bug';
fs.mkdirSync(outDir, { recursive: true });
const safe = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const file = path.join(outDir, `${safe || 'bug'}.md`);
const content = `# ${title}\n\n- Severity: \n- URL/Route: \n- Steps to reproduce: \n- Expected: \n- Actual: \n- Console errors: \n- Request failures: \n- Screenshot: \n- Notes: \n`;
fs.writeFileSync(file, content, 'utf8');
console.log(file);
