#!/usr/bin/env node
const fs = require('fs');

const outFile = process.argv[2] || '/tmp/qa-role-plan.md';
const rolesArg = process.argv[3] || 'guest,member,admin';
const roles = rolesArg.split(',').map(s => s.trim()).filter(Boolean);

const sections = roles.map(role => `## ${role}\n- Signup flow\n- Login flow\n- Core happy path\n- Invalid-input path\n- Permission boundary checks\n- Logout/session check\n`).join('\n');
const content = `# Role-Based QA Plan\n\n${sections}\n## Cross-role checks\n- Data visibility boundaries\n- Navigation differences\n- Feature access differences\n- Shared entity consistency\n`;
fs.writeFileSync(outFile, content, 'utf8');
console.log(outFile);
