#!/usr/bin/env node
const fs = require('fs');

const input = process.argv[2];
const outFile = process.argv[3] || '/tmp/uat-report-final.md';
if (!input) {
  console.error('Usage: node write_uat_report.js <report.json> [outFile]');
  process.exit(1);
}
const data = JSON.parse(fs.readFileSync(input, 'utf8'));
const list = (arr, fmt) => (arr && arr.length ? arr.map(fmt).join('\n') : '- None');
const md = `## 🧪 UAT REPORT: ${data.appName || '[App Name]'} — ${data.url || '[URL]'}\n\n## 📋 PRODUCT MAP\n- Purpose: ${data.productMap?.purpose || ''}\n- Users: ${(data.productMap?.users || []).join(', ')}\n- Roles: ${(data.productMap?.roles || []).join(', ')}\n- Core flows: ${(data.productMap?.coreFlows || []).join('; ')}\n- Main entities: ${(data.productMap?.entities || []).join(', ')}\n- Expected vs actual: ${data.productMap?.expectedVsActual || ''}\n\n## 🚨 PRODUCT GAPS\n${list(data.productGaps, g => `- [${g.severity || 'Major'}] ${g.title}: ${g.why || ''}`)}\n\n## ❌ BUGS\n${list(data.bugs, b => `- [${b.severity || 'Major'}] ${b.title} — Expected: ${b.expected || ''} | Actual: ${b.actual || ''} | Steps: ${b.steps || ''} | Screenshot: ${b.screenshot || ''}`)}\n\n## ⚠️ UX ISSUES\n${list(data.uxIssues, u => `- [${u.severity || 'Minor'}] ${u.title}: ${u.why || ''} | Fix: ${u.fix || ''}`)}\n\n## ✅ PASSED\n${list(data.passed, p => `- ${p}`)}\n\n## 📊 SUMMARY\n- Total tests: ${data.summary?.totalTests || 0}\n- Passed: ${data.summary?.passed || 0}\n- Failed: ${data.summary?.failed || 0}\n- Product gaps: ${(data.productGaps || []).length}\n- UX issues: ${(data.uxIssues || []).length}\n\n## 🏁 VERDICT\n- ${data.verdict || 'NEEDS WORK'}\n\n## 📎 SCREENSHOTS\n${list(data.screenshots, s => `- ${s.path} — ${s.description || ''}`)}\n`;
fs.writeFileSync(outFile, md, 'utf8');
console.log(outFile);
