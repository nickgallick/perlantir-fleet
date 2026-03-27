const path = require('path');

const VIEWPORTS = {
  desktop: { width: 1440, height: 900 },
  laptop: { width: 1280, height: 800 },
  tablet: { width: 768, height: 1024 },
  mobile: { width: 390, height: 844 },
};

function buildResult(name = 'playwright-task') {
  return {
    ok: false,
    task: name,
    screenshots: [],
    consoleErrors: [],
    consoleWarnings: [],
    pageErrors: [],
    requestFailures: [],
    httpErrors: [],
    accessibilityWarnings: [],
    steps: [],
    metrics: {},
    traces: [],
    error: null,
  };
}

async function attachObservers(page, result) {
  page.on('console', msg => {
    const type = msg.type();
    if (type === 'error') result.consoleErrors.push(msg.text());
    if (type === 'warning') result.consoleWarnings.push(msg.text());
  });
  page.on('pageerror', err => result.pageErrors.push(String(err)));
  page.on('requestfailed', req => {
    result.requestFailures.push({
      url: req.url(),
      method: req.method(),
      failure: req.failure()?.errorText || 'unknown',
    });
  });
  page.on('response', async res => {
    const status = res.status();
    if (status >= 400) {
      result.httpErrors.push({ url: res.url(), status });
    }
  });
}

async function screenshot(page, result, name, options = {}) {
  const safe = name.replace(/[^a-zA-Z0-9-_]/g, '-');
  const file = path.join('/tmp', `${safe}.png`);
  await page.screenshot({ path: file, fullPage: options.fullPage !== false, ...options });
  result.screenshots.push(file);
  return file;
}

async function failureArtifacts(page, context, result, baseName = 'playwright-test-failure') {
  try {
    const shot = path.join('/tmp', `${baseName}.png`);
    await page.screenshot({ path: shot, fullPage: true });
    result.screenshots.push(shot);
  } catch (_) {}
  try {
    if (context && context.tracing) {
      const traceFile = path.join('/tmp', `${baseName}.zip`);
      await context.tracing.stop({ path: traceFile });
      result.traces.push(traceFile);
    }
  } catch (_) {}
}

async function startTracing(context) {
  if (context && context.tracing) {
    await context.tracing.start({ screenshots: true, snapshots: true });
  }
}

async function stopTracing(context, result, baseName = 'playwright-trace') {
  if (context && context.tracing) {
    const traceFile = path.join('/tmp', `${baseName}.zip`);
    await context.tracing.stop({ path: traceFile });
    result.traces.push(traceFile);
  }
}

async function gotoStable(page, url, result, options = {}) {
  result.steps.push(`Navigate: ${url}`);
  await page.goto(url, { waitUntil: options.waitUntil || 'domcontentloaded', timeout: options.timeout || 30000 });
  await page.waitForLoadState('networkidle', { timeout: options.networkIdleTimeout || 10000 }).catch(() => {});
}

async function waitForAppReady(page, checks = {}) {
  if (checks.selector) {
    await page.locator(checks.selector).first().waitFor({ state: 'visible', timeout: checks.timeout || 10000 });
  }
  if (checks.role) {
    await page.getByRole(checks.role, checks.roleOptions || {}).first().waitFor({ state: 'visible', timeout: checks.timeout || 10000 });
  }
  if (checks.text) {
    await page.getByText(checks.text, { exact: !!checks.exact }).first().waitFor({ state: 'visible', timeout: checks.timeout || 10000 });
  }
}

async function setViewportPreset(page, preset, result) {
  const vp = VIEWPORTS[preset] || VIEWPORTS.desktop;
  await page.setViewportSize(vp);
  result.metrics.viewport = { name: preset, ...vp };
}

async function runResponsiveSweep(page, url, result, presets = ['desktop', 'tablet', 'mobile']) {
  for (const preset of presets) {
    await setViewportPreset(page, preset, result);
    await gotoStable(page, url, result);
    await screenshot(page, result, `playwright-${preset}`);
  }
}

async function findFirst(page, spec) {
  if (spec.role) return page.getByRole(spec.role, spec.options || {}).first();
  if (spec.label) return page.getByLabel(spec.label, spec.options || {}).first();
  if (spec.placeholder) return page.getByPlaceholder(spec.placeholder, spec.options || {}).first();
  if (spec.text) return page.getByText(spec.text, spec.options || {}).first();
  if (spec.testId) return page.getByTestId(spec.testId).first();
  if (spec.selector) return page.locator(spec.selector).first();
  throw new Error('No valid locator spec provided');
}

async function clickFirst(page, spec) {
  const loc = await findFirst(page, spec);
  await loc.click();
}

async function fillFirst(page, spec, value) {
  const loc = await findFirst(page, spec);
  await loc.fill(value);
}

async function basicA11ySmoke(page, result) {
  const missingLabels = await page.locator('input:not([type="hidden"]):not([aria-label]):not([aria-labelledby])').count().catch(() => 0);
  const unnamedButtons = await page.locator('button').evaluateAll(btns => btns.filter(b => !(b.innerText || '').trim() && !b.getAttribute('aria-label') && !b.getAttribute('aria-labelledby')).length).catch(() => 0);
  if (missingLabels > 0) result.accessibilityWarnings.push(`${missingLabels} input(s) may be missing accessible labels`);
  if (unnamedButtons > 0) result.accessibilityWarnings.push(`${unnamedButtons} button(s) may be missing accessible names`);
}

module.exports = {
  VIEWPORTS,
  buildResult,
  attachObservers,
  screenshot,
  failureArtifacts,
  startTracing,
  stopTracing,
  gotoStable,
  waitForAppReady,
  setViewportPreset,
  runResponsiveSweep,
  findFirst,
  clickFirst,
  fillFirst,
  basicA11ySmoke,
};
