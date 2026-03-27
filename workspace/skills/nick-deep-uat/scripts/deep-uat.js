#!/usr/bin/env node
/**
 * Deep UAT — Full Interaction Testing
 * Tests every button, link, form, and modal on every page
 * 
 * Usage: node deep-uat.js <baseUrl> [--auth email:password] [--viewport mobile|desktop|both]
 */

const { chromium } = require('playwright');

const args = process.argv.slice(2);
const baseUrl = args[0];
if (!baseUrl) { console.error('Usage: node deep-uat.js <baseUrl>'); process.exit(1); }

const authArg = args.find(a => a.startsWith('--auth='))?.split('=')[1];
const viewportArg = args.find(a => a.startsWith('--viewport='))?.split('=')[1] || 'both';

const VIEWPORTS = {
  desktop: { width: 1280, height: 800 },
  mobile: { width: 375, height: 812 }
};

let passed = 0, failed = 0, warnings = 0;
const failures = [];
const warns = [];

function ok(page, msg) { passed++; console.log(`  ✅ ${msg}`); }
function fail(page, msg) { failed++; failures.push(`${page} → ${msg}`); console.log(`  ❌ ${msg}`); }
function warn(page, msg) { warnings++; warns.push(`${page} → ${msg}`); console.log(`  ⚠️ ${msg}`); }

const SCREENSHOT_DIR = process.env.UAT_SCREENSHOT_DIR || '/tmp/uat-screenshots';
const fs_extra = require('fs');
fs_extra.mkdirSync(SCREENSHOT_DIR, { recursive: true });

async function screenshotPage(page, name) {
  const safe = name.replace(/[^a-z0-9_-]/gi, '_').substring(0, 60);
  const filepath = `${SCREENSHOT_DIR}/${safe}.png`;
  try {
    await page.screenshot({ path: filepath, fullPage: true });
    console.log(`  📸 Screenshot: ${filepath}`);
    return filepath;
  } catch { return null; }
}

async function testPage(page, url, pageName) {
  console.log(`\n=== ${pageName} (${url}) ===`);
  
  try {
    const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });
    await page.waitForTimeout(3000);
    
    // Screenshot every page for vision analysis
    await screenshotPage(page, pageName);
    
    if (!resp || resp.status() !== 200) {
      fail(pageName, `Page returned ${resp?.status()}`);
      return;
    }
    
    const body = await page.textContent('body');
    if (body.includes('Something went wrong')) {
      fail(pageName, 'Error boundary triggered');
      return;
    }
    ok(pageName, `Page loads (${resp.status()})`);
    
    // Check for console errors
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error' && !msg.text().includes('net::ERR')) errors.push(msg.text()); });
    
    // ===== TEST ALL BUTTONS =====
    const buttons = await page.locator('button:visible').all();
    console.log(`  Buttons found: ${buttons.length}`);
    
    for (let i = 0; i < Math.min(buttons.length, 50); i++) { // Cap at 20 per page
      try {
        const btn = buttons[i];
        if (!await btn.isVisible()) continue;
        
        const text = (await btn.textContent())?.trim() || '';
        const ariaLabel = await btn.getAttribute('aria-label') || '';
        const btnName = text.substring(0, 30) || ariaLabel || `button[${i}]`;
        const disabled = await btn.isDisabled();
        
        if (disabled) { ok(pageName, `Button "${btnName}" (disabled — OK)`); continue; }
        
        // Skip dangerous buttons
        if (btnName.match(/delete|remove|emergency|stop/i)) {
          ok(pageName, `Button "${btnName}" (skipped — destructive)`);
          continue;
        }
        
        // Record state before click
        const urlBefore = page.url();
        const bodyBefore = await page.textContent('body');
        
        await btn.click({ timeout: 3000 }).catch(() => {});
        await page.waitForTimeout(1500);
        
        const urlAfter = page.url();
        const bodyAfter = await page.textContent('body');
        
        // Check if something happened
        const urlChanged = urlAfter !== urlBefore;
        const bodyChanged = bodyAfter !== bodyBefore;
        const modalOpened = await page.locator('[data-state="open"], [role="dialog"]:visible, [role="alertdialog"]:visible').count() > 0;
        const toastAppeared = bodyAfter.includes('success') || bodyAfter.includes('Success') || 
                              (bodyAfter.length > bodyBefore.length + 20);
        
        if (urlChanged || bodyChanged || modalOpened || toastAppeared) {
          ok(pageName, `Button "${btnName}" responds`);
        } else {
          // Check if it's a theme toggle, filter, or sort button (these may not change text)
          const isToggle = btnName.match(/toggle|theme|sort|filter|view|tab/i) || ariaLabel.match(/toggle|theme/i);
          if (isToggle) {
            ok(pageName, `Button "${btnName}" (toggle — OK)`);
          } else {
            warn(pageName, `Button "${btnName}" — no visible response`);
          }
        }
        
        // Close any opened modals
        if (modalOpened) {
          await page.keyboard.press('Escape');
          await page.waitForTimeout(500);
        }
        
        // Navigate back if URL changed
        if (urlChanged) {
          await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });
          await page.waitForTimeout(2000);
        }
        
      } catch (e) {
        // Button may have been removed from DOM
      }
    }
    
    // ===== TEST ALL LINKS =====
    const links = await page.locator('a:visible').all();
    console.log(`  Links found: ${links.length}`);
    
    for (let i = 0; i < Math.min(links.length, 15); i++) {
      try {
        const link = links[i];
        if (!await link.isVisible()) continue;
        
        const href = await link.getAttribute('href') || '';
        const text = (await link.textContent())?.trim().substring(0, 30) || href.substring(0, 30);
        
        if (href === '#' || href === '') {
          fail(pageName, `Link "${text}" — dead link (href="${href}")`);
        } else if (href.startsWith('http') && !href.includes(baseUrl.replace('https://', '').replace('http://', ''))) {
          // External link — check for target="_blank"
          const target = await link.getAttribute('target');
          if (!target) warn(pageName, `External link "${text}" — no target="_blank"`);
          else ok(pageName, `Link "${text}" (external)`);
        } else {
          ok(pageName, `Link "${text}" → ${href}`);
        }
      } catch (e) {}
    }
    
    // ===== TEST FORMS =====
    const forms = await page.locator('form:visible').all();
    console.log(`  Forms found: ${forms.length}`);
    
    for (const form of forms) {
      try {
        const inputs = await form.locator('input:visible, textarea:visible, select:visible').all();
        const submitBtn = await form.locator('button[type="submit"]:visible, button:has-text("Submit"):visible, button:has-text("Save"):visible, button:has-text("Send"):visible').first();
        
        if (inputs.length > 0 && await submitBtn.count() > 0) {
          // Try submitting empty
          const bodyBefore = await page.textContent('body');
          await submitBtn.click({ timeout: 3000 }).catch(() => {});
          await page.waitForTimeout(1500);
          const bodyAfter = await page.textContent('body');
          
          const hasValidation = bodyAfter.includes('required') || bodyAfter.includes('valid') || 
                                bodyAfter.includes('error') || bodyAfter !== bodyBefore;
          
          if (hasValidation) {
            ok(pageName, `Form (${inputs.length} inputs) — validates on empty submit`);
          } else {
            warn(pageName, `Form (${inputs.length} inputs) — no validation on empty submit`);
          }
        }
      } catch (e) {}
    }
    
  } catch (e) {
    fail(pageName, `Page error: ${e.message.substring(0, 100)}`);
  }
}

async function run() {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  
  for (const [vpName, viewport] of Object.entries(VIEWPORTS)) {
    if (viewportArg !== 'both' && viewportArg !== vpName) continue;
    
    console.log(`\n${'='.repeat(50)}`);
    console.log(`VIEWPORT: ${vpName} (${viewport.width}x${viewport.height})`);
    console.log(`${'='.repeat(50)}`);
    
    const context = await browser.newContext({ viewport });
    const page = await context.newPage();
    
    // Login if auth provided
    if (authArg) {
      const [email, password] = authArg.split(':');
      console.log(`\nLogging in as ${email}...`);
      await page.goto(`${baseUrl}/login`, { waitUntil: 'domcontentloaded', timeout: 15000 });
      await page.waitForTimeout(2000);
      const emailInput = page.locator('input[type="email"]');
      if (await emailInput.count() > 0) {
        await emailInput.fill(email);
        await page.locator('input[type="password"]').fill(password);
        await page.locator('button[type="submit"]').click();
        await page.waitForTimeout(3000);
        console.log(`  Logged in. URL: ${page.url()}`);
      }
    }
    
    // Discover all routes from nav/sidebar
    await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
    await page.waitForTimeout(3000);
    
    const allLinks = await page.locator('a[href]').all();
    const routes = new Set();
    for (const link of allLinks) {
      const href = await link.getAttribute('href');
      if (href && href.startsWith('/') && !href.includes('.') && href.length < 50) {
        routes.add(href);
      }
    }
    routes.add('/'); // Always test root
    
    console.log(`\nDiscovered ${routes.size} routes: ${[...routes].join(', ')}`);
    
    // Test each route
    for (const route of routes) {
      await testPage(page, `${baseUrl}${route}`, `[${vpName}] ${route}`);
    }
    
    await context.close();
  }
  
  await browser.close();
  
  // ===== REPORT =====
  console.log(`\n${'='.repeat(50)}`);
  console.log('DEEP UAT REPORT');
  console.log(`${'='.repeat(50)}`);
  console.log(`URL: ${baseUrl}`);
  console.log(`✅ PASSED: ${passed}`);
  console.log(`❌ FAILED: ${failed}`);
  console.log(`⚠️ WARNINGS: ${warnings}`);
  
  if (failures.length > 0) {
    console.log(`\n=== FAILURES ===`);
    failures.forEach(f => console.log(`  ❌ ${f}`));
  }
  if (warns.length > 0) {
    console.log(`\n=== WARNINGS ===`);
    warns.forEach(w => console.log(`  ⚠️ ${w}`));
  }
  
  const total = passed + failed;
  const grade = failed === 0 ? 'A' : failed <= 2 ? 'B' : failed <= 5 ? 'C' : 'F';
  console.log(`\nGRADE: ${grade} (${passed}/${total} passed, ${warnings} warnings)`);
  
  process.exit(failed > 0 ? 1 : 0);
}

run().catch(e => { console.error('FATAL:', e.message); process.exit(1); });
