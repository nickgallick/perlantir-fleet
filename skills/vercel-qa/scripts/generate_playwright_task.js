#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const targetUrl = process.argv[2];
const mode = process.argv[3] || 'smoke';
const outFile = process.argv[4] || `/tmp/playwright-test-${mode}.js`;
const shotsDir = process.argv[5] || '/tmp/qa-screenshots';

if (!targetUrl) {
  console.error('Usage: node generate_playwright_task.js <url> [mode] [outFile] [shotsDir]');
  process.exit(1);
}

fs.mkdirSync(shotsDir, { recursive: true });

const common = `
exports.config = { headed: false };
exports.run = async ({ page, result, helpers }) => {
  const SHOTS_DIR = ${JSON.stringify(shotsDir)};
  const saveShot = async (name) => {
    const file = require('path').join(SHOTS_DIR, name);
    await page.screenshot({ path: file, fullPage: true });
    result.screenshots.push(file);
  };
  await helpers.gotoStable(page, ${JSON.stringify(targetUrl)}, result);
`;

const modes = {
  smoke: `${common}
  result.steps.push('Homepage smoke test');
  await saveShot('01-home.png');
  await helpers.basicA11ySmoke(page, result);
  result.title = await page.title();
  result.ok = true;
};
`,
  responsive: `${common}
  result.steps.push('Responsive QA');
  for (const preset of ['desktop', 'tablet', 'mobile']) {
    await helpers.setViewportPreset(page, preset, result);
    await helpers.gotoStable(page, ${JSON.stringify(targetUrl)}, result);
    await saveShot(
      preset === 'desktop' ? '01-desktop.png' : preset === 'tablet' ? '02-tablet.png' : '03-mobile.png'
    );
  }
  await helpers.basicA11ySmoke(page, result);
  result.ok = true;
};
`,
  auth: `${common}
  result.steps.push('Auth surface smoke test');
  await saveShot('01-entry.png');
  const authLinks = page.getByRole('link', { name: /sign up|signup|log in|login|get started/i });
  const count = await authLinks.count().catch(() => 0);
  result.authEntryPoints = count;
  result.ok = true;
};
`,
};

if (!modes[mode]) {
  console.error('Unknown mode. Use one of: smoke, responsive, auth');
  process.exit(1);
}

fs.writeFileSync(outFile, modes[mode], 'utf8');
console.log(outFile);
