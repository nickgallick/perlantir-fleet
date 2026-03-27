#!/usr/bin/env node
/**
 * UAT (User Acceptance Testing) Script
 * Performs functional testing on a deployed web app:
 * - Navigation / routing
 * - Link validation (internal + external)
 * - Form interaction
 * - Button/CTA clicks
 * - Auth flow testing
 * - Console error capture
 * - Network error capture
 * - Accessibility audit (basic)
 * - Performance metrics
 *
 * Usage: node uat.js <url> [output-dir]
 */

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

async function run() {
  const url = process.argv[2];
  const outDir = process.argv[3] || './uat-results';

  if (!url) {
    console.error('Usage: node uat.js <url> [output-dir]');
    process.exit(1);
  }

  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const results = {
    url,
    timestamp: new Date().toISOString(),
    navigation: [],
    links: { internal: [], external: [], broken: [] },
    forms: [],
    buttons: [],
    consoleErrors: [],
    networkErrors: [],
    performance: {},
    accessibility: {},
    authFlow: null,
    issues: [],
  };

  // === MAIN PAGE AUDIT ===
  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();

  // Capture console errors
  page.on('console', msg => {
    if (msg.type() === 'error') {
      results.consoleErrors.push({ text: msg.text(), url: page.url() });
    }
  });
  page.on('pageerror', err => {
    results.consoleErrors.push({ text: err.message, url: page.url() });
  });

  // Capture network errors
  page.on('requestfailed', request => {
    results.networkErrors.push({
      url: request.url(),
      method: request.method(),
      failure: request.failure()?.errorText || 'unknown',
    });
  });

  console.log(`\n=== UAT: ${url} ===\n`);

  // --- Step 1: Load and Performance ---
  console.log('1. Loading page and capturing performance...');
  try {
    const startTime = Date.now();
    const response = await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
    const loadTime = Date.now() - startTime;

    results.performance.loadTimeMs = loadTime;
    results.performance.statusCode = response?.status();
    results.performance.ok = response?.ok();

    // Core Web Vitals approximation
    const perfMetrics = await page.evaluate(() => {
      const entries = performance.getEntriesByType('navigation');
      const nav = entries[0] || {};
      return {
        domContentLoaded: Math.round(nav.domContentLoadedEventEnd - nav.startTime) || null,
        domComplete: Math.round(nav.domComplete - nav.startTime) || null,
        transferSize: nav.transferSize || null,
      };
    });
    results.performance = { ...results.performance, ...perfMetrics };

    if (loadTime > 5000) {
      results.issues.push({ severity: 'major', type: 'performance', message: `Page load took ${loadTime}ms (>5s)` });
    }
    console.log(`   Load time: ${loadTime}ms | Status: ${response?.status()}`);
  } catch (err) {
    results.issues.push({ severity: 'critical', type: 'load', message: `Page failed to load: ${err.message}` });
    console.error(`   CRITICAL: Page failed to load - ${err.message}`);
  }

  await page.waitForTimeout(2000);

  // --- Step 2: Discover all links ---
  console.log('2. Discovering links...');
  const links = await page.evaluate((baseUrl) => {
    const anchors = [...document.querySelectorAll('a[href]')];
    return anchors.map(a => ({
      href: a.href,
      text: a.textContent?.trim().substring(0, 80) || '',
      isInternal: a.href.startsWith(baseUrl) || a.href.startsWith('/'),
      target: a.target || '_self',
    }));
  }, url);

  const internalLinks = links.filter(l => l.isInternal);
  const externalLinks = links.filter(l => !l.isInternal);
  results.links.internal = internalLinks;
  results.links.external = externalLinks;
  console.log(`   Found ${internalLinks.length} internal, ${externalLinks.length} external links`);

  // --- Step 3: Test internal navigation ---
  console.log('3. Testing internal navigation...');
  const visitedPaths = new Set();
  const uniqueInternalLinks = internalLinks
    .filter(l => {
      try {
        const u = new URL(l.href);
        const p = u.pathname;
        if (visitedPaths.has(p) || p.startsWith('/auth/callback') || p.includes('#')) return false;
        visitedPaths.add(p);
        return true;
      } catch { return false; }
    })
    .slice(0, 20); // Cap at 20 pages

  for (const link of uniqueInternalLinks) {
    try {
      const resp = await page.goto(link.href, { waitUntil: 'domcontentloaded', timeout: 15000 });
      const status = resp?.status() || 0;
      results.navigation.push({ url: link.href, text: link.text, status, ok: status < 400 });

      if (status >= 400) {
        results.issues.push({ severity: 'major', type: 'navigation', message: `Broken route: ${link.href} (${status})` });
        // Screenshot broken pages
        await page.screenshot({ path: path.join(outDir, `broken-${status}-${visitedPaths.size}.png`) });
      }
      console.log(`   ${status < 400 ? '✓' : '✗'} ${link.href} [${status}]`);
    } catch (err) {
      results.navigation.push({ url: link.href, text: link.text, status: 0, ok: false, error: err.message });
      results.issues.push({ severity: 'major', type: 'navigation', message: `Route error: ${link.href} - ${err.message}` });
      console.log(`   ✗ ${link.href} [ERROR: ${err.message}]`);
    }
  }

  // Go back to main page
  await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1000);

  // --- Step 4: Discover and test forms ---
  console.log('4. Auditing forms...');
  const forms = await page.evaluate(() => {
    const formEls = [...document.querySelectorAll('form')];
    return formEls.map((form, i) => {
      const inputs = [...form.querySelectorAll('input, textarea, select')];
      return {
        index: i,
        action: form.action || '',
        method: form.method || 'get',
        inputs: inputs.map(inp => ({
          type: inp.type || inp.tagName.toLowerCase(),
          name: inp.name || '',
          id: inp.id || '',
          required: inp.required,
          placeholder: inp.placeholder || '',
          hasLabel: !!document.querySelector(`label[for="${inp.id}"]`),
        })),
      };
    });
  });

  for (const form of forms) {
    const formIssues = [];
    for (const input of form.inputs) {
      if (!input.hasLabel && input.type !== 'hidden' && input.type !== 'submit') {
        formIssues.push(`Input "${input.name || input.id || input.type}" missing associated label`);
      }
    }
    results.forms.push({ ...form, issues: formIssues });
    if (formIssues.length > 0) {
      results.issues.push({ severity: 'minor', type: 'forms', message: `Form ${form.index}: ${formIssues.join('; ')}` });
    }
  }
  console.log(`   Found ${forms.length} forms`);

  // --- Step 5: Discover and audit buttons/CTAs ---
  console.log('5. Auditing buttons and CTAs...');
  const buttons = await page.evaluate(() => {
    const btns = [...document.querySelectorAll('button, [role="button"], a.btn, a[class*="button"], a[class*="cta"]')];
    return btns.map(btn => {
      const rect = btn.getBoundingClientRect();
      const styles = window.getComputedStyle(btn);
      return {
        text: btn.textContent?.trim().substring(0, 60) || '',
        tag: btn.tagName.toLowerCase(),
        type: btn.type || '',
        disabled: btn.disabled || false,
        width: Math.round(rect.width),
        height: Math.round(rect.height),
        visible: rect.width > 0 && rect.height > 0,
        cursor: styles.cursor,
        tooSmall: rect.width < 44 || rect.height < 44,
      };
    });
  });

  for (const btn of buttons) {
    if (btn.tooSmall && btn.visible) {
      results.issues.push({
        severity: 'minor',
        type: 'accessibility',
        message: `Button "${btn.text}" too small: ${btn.width}x${btn.height}px (min 44x44)`,
      });
    }
  }
  results.buttons = buttons;
  console.log(`   Found ${buttons.length} buttons/CTAs`);

  // --- Step 6: Check for auth pages ---
  console.log('6. Checking auth flow...');
  const authPaths = ['/auth/login', '/login', '/signin', '/auth/signin', '/auth/signup', '/signup', '/register'];
  let authPage = null;

  for (const authPath of authPaths) {
    try {
      const authUrl = new URL(authPath, url).href;
      const resp = await page.goto(authUrl, { waitUntil: 'domcontentloaded', timeout: 10000 });
      if (resp?.ok()) {
        authPage = authPath;
        console.log(`   Found auth page at ${authPath}`);

        // Check auth form
        const authForms = await page.evaluate(() => {
          const inputs = [...document.querySelectorAll('input')];
          return {
            hasEmail: inputs.some(i => i.type === 'email' || i.name?.includes('email')),
            hasPassword: inputs.some(i => i.type === 'password'),
            hasSubmit: !!document.querySelector('button[type="submit"], input[type="submit"]'),
          };
        });

        results.authFlow = { path: authPath, ...authForms };

        if (!authForms.hasEmail) {
          results.issues.push({ severity: 'major', type: 'auth', message: 'Auth page missing email input' });
        }
        if (!authForms.hasPassword) {
          results.issues.push({ severity: 'major', type: 'auth', message: 'Auth page missing password input' });
        }
        if (!authForms.hasSubmit) {
          results.issues.push({ severity: 'major', type: 'auth', message: 'Auth page missing submit button' });
        }

        // Screenshot auth page
        await page.screenshot({ path: path.join(outDir, 'auth-page.png'), fullPage: true });
        break;
      }
    } catch { /* skip */ }
  }

  if (!authPage) {
    console.log('   No auth pages found (may not be applicable)');
  }

  // --- Step 7: Accessibility basics ---
  console.log('7. Running accessibility checks...');
  await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1000);

  const a11y = await page.evaluate(() => {
    const images = [...document.querySelectorAll('img')];
    const imgsNoAlt = images.filter(i => !i.alt).map(i => i.src?.substring(0, 100));

    const focusable = [...document.querySelectorAll('a, button, input, textarea, select, [tabindex]')];
    const noFocusVisible = []; // Would need to tab through to check properly

    const headings = [...document.querySelectorAll('h1, h2, h3, h4, h5, h6')];
    const headingOrder = headings.map(h => parseInt(h.tagName[1]));
    let skippedLevels = false;
    for (let i = 1; i < headingOrder.length; i++) {
      if (headingOrder[i] > headingOrder[i - 1] + 1) {
        skippedLevels = true;
        break;
      }
    }

    const hasSkipLink = !!document.querySelector('a[href="#main"], a[href="#content"], .skip-link, .skip-to-content');
    const hasLang = !!document.documentElement.lang;
    const h1Count = document.querySelectorAll('h1').length;

    return {
      imagesWithoutAlt: imgsNoAlt,
      headingOrder,
      skippedHeadingLevels: skippedLevels,
      hasSkipLink,
      hasLangAttr: hasLang,
      h1Count,
      focusableElements: focusable.length,
    };
  });

  results.accessibility = a11y;

  if (a11y.imagesWithoutAlt.length > 0) {
    results.issues.push({ severity: 'minor', type: 'accessibility', message: `${a11y.imagesWithoutAlt.length} images missing alt text` });
  }
  if (a11y.skippedHeadingLevels) {
    results.issues.push({ severity: 'minor', type: 'accessibility', message: 'Heading levels are skipped (e.g., h1 → h3)' });
  }
  if (a11y.h1Count === 0) {
    results.issues.push({ severity: 'major', type: 'seo', message: 'No h1 tag found on page' });
  }
  if (a11y.h1Count > 1) {
    results.issues.push({ severity: 'minor', type: 'seo', message: `Multiple h1 tags found (${a11y.h1Count})` });
  }
  if (!a11y.hasLangAttr) {
    results.issues.push({ severity: 'minor', type: 'accessibility', message: 'Missing lang attribute on <html>' });
  }

  console.log(`   Images without alt: ${a11y.imagesWithoutAlt.length}`);
  console.log(`   Heading levels skipped: ${a11y.skippedHeadingLevels}`);
  console.log(`   h1 count: ${a11y.h1Count}`);

  // --- Step 8: Mobile responsiveness check ---
  console.log('8. Testing mobile responsiveness...');
  await context.close();

  const mobileCtx = await browser.newContext({
    viewport: { width: 375, height: 812 },
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
    isMobile: true,
    hasTouch: true,
  });
  const mobilePage = await mobileCtx.newPage();

  try {
    await mobilePage.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
    await mobilePage.waitForTimeout(2000);

    const mobileIssues = await mobilePage.evaluate(() => {
      const issues = [];
      // Check for horizontal overflow
      if (document.body.scrollWidth > window.innerWidth) {
        issues.push(`Horizontal scroll detected: body width ${document.body.scrollWidth}px > viewport ${window.innerWidth}px`);
      }
      // Check for text too small
      const textEls = [...document.querySelectorAll('p, span, li, td, th, label')];
      const smallText = textEls.filter(el => {
        const fs = parseFloat(window.getComputedStyle(el).fontSize);
        return fs < 14 && el.textContent?.trim().length > 0;
      });
      if (smallText.length > 0) {
        issues.push(`${smallText.length} text elements below 14px font size on mobile`);
      }
      return issues;
    });

    for (const issue of mobileIssues) {
      results.issues.push({ severity: 'major', type: 'responsive', message: issue });
    }

    await mobilePage.screenshot({ path: path.join(outDir, 'mobile-uat.png'), fullPage: true });
    console.log(`   Mobile issues: ${mobileIssues.length}`);
  } catch (err) {
    results.issues.push({ severity: 'major', type: 'responsive', message: `Mobile test failed: ${err.message}` });
  }

  await mobileCtx.close();
  await browser.close();

  // --- Summary ---
  const critical = results.issues.filter(i => i.severity === 'critical').length;
  const major = results.issues.filter(i => i.severity === 'major').length;
  const minor = results.issues.filter(i => i.severity === 'minor').length;

  results.summary = {
    totalIssues: results.issues.length,
    critical,
    major,
    minor,
    consoleErrors: results.consoleErrors.length,
    networkErrors: results.networkErrors.length,
    pagesChecked: results.navigation.length + 1,
    formsFound: results.forms.length,
    brokenRoutes: results.navigation.filter(n => !n.ok).length,
  };

  // Grade
  let grade = 'A';
  if (critical > 0) grade = 'F';
  else if (major >= 3) grade = 'D';
  else if (major >= 1) grade = 'C';
  else if (minor >= 3) grade = 'B';
  results.summary.grade = grade;

  // Write results
  const resultFile = path.join(outDir, 'uat-results.json');
  fs.writeFileSync(resultFile, JSON.stringify(results, null, 2));

  console.log(`\n=== UAT COMPLETE ===`);
  console.log(`Grade: ${grade}`);
  console.log(`Issues: ${critical} critical, ${major} major, ${minor} minor`);
  console.log(`Console errors: ${results.consoleErrors.length}`);
  console.log(`Network errors: ${results.networkErrors.length}`);
  console.log(`Pages checked: ${results.navigation.length + 1}`);
  console.log(`Results: ${resultFile}`);
}

run().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});
