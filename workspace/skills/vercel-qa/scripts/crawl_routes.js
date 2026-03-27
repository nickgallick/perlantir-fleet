#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

function loadPlaywright() {
  const candidates = ['playwright', '/data/.npm-global/lib/node_modules/playwright', '/usr/local/lib/node_modules/playwright'];
  for (const c of candidates) {
    try { return require(c); } catch (_) {}
  }
  throw new Error('Playwright not found');
}
const { chromium } = loadPlaywright();

const target = process.argv[2];
const outFile = process.argv[3] || '/tmp/qa-routes.json';
if (!target) {
  console.error('Usage: node crawl_routes.js <url> [outFile]');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const routes = new Set();
  try {
    await page.goto(target, { waitUntil: 'domcontentloaded', timeout: 30000 });
    const links = await page.locator('a[href]').evaluateAll(nodes => nodes.map(n => n.getAttribute('href')).filter(Boolean));
    for (const href of links) {
      try {
        const u = new URL(href, target);
        if (u.origin === new URL(target).origin) routes.add(u.pathname + u.search);
      } catch (_) {}
    }
    const data = { target, discovered: Array.from(routes).sort() };
    fs.writeFileSync(outFile, JSON.stringify(data, null, 2));
    console.log(outFile);
  } finally {
    await browser.close().catch(() => {});
  }
})();
