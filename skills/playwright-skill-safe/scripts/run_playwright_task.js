#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

function loadPlaywright() {
  const candidates = [
    'playwright',
    '/data/.npm-global/lib/node_modules/playwright',
    '/usr/local/lib/node_modules/playwright',
  ];
  for (const candidate of candidates) {
    try {
      return require(candidate);
    } catch (_) {}
  }
  throw new Error('Unable to load Playwright from local or known global install paths');
}

const { chromium, devices } = loadPlaywright();
const helpers = require('./helpers');

function fail(msg) {
  console.error(msg);
  process.exit(1);
}

const scriptPath = process.argv[2];
if (!scriptPath) fail('Usage: node run_playwright_task.js /tmp/playwright-test-*.js');

const resolved = path.resolve(scriptPath);
const base = path.basename(resolved);
if (!resolved.startsWith('/tmp/') || !base.startsWith('playwright-test-') || !base.endsWith('.js')) {
  fail('Refusing to run script outside /tmp/playwright-test-*.js');
}
if (!fs.existsSync(resolved)) fail(`Script not found: ${resolved}`);

(async () => {
  const result = helpers.buildResult(base.replace(/\.js$/, ''));
  let browser;
  let context;
  let page;

  try {
    const taskModule = require(resolved);
    const config = typeof taskModule.config === 'object' && taskModule.config ? taskModule.config : {};
    const headed = !!config.headed;
    const deviceProfile = config.device && devices[config.device] ? devices[config.device] : null;

    browser = await chromium.launch({ headless: !headed, slowMo: config.slowMo || 0 });
    context = await browser.newContext(deviceProfile ? { ...deviceProfile } : {});
    await helpers.startTracing(context);
    page = await context.newPage();
    await helpers.attachObservers(page, result);

    if (!taskModule || typeof taskModule.run !== 'function') {
      throw new Error('Generated script must export async function run({ browser, context, page, result, helpers, chromium })');
    }

    await taskModule.run({ browser, context, page, result, helpers, chromium });
    result.ok = result.ok !== false;

    if (result.ok) {
      await helpers.stopTracing(context, result, `${base.replace(/\.js$/, '')}-trace`);
    }
  } catch (err) {
    result.ok = false;
    result.error = String(err && err.stack ? err.stack : err);
    if (page && context) {
      await helpers.failureArtifacts(page, context, result, `${base.replace(/\.js$/, '')}-failure`);
    }
  } finally {
    await context?.close().catch(() => {});
    await browser?.close().catch(() => {});
    console.log(JSON.stringify(result, null, 2));
  }
})();
