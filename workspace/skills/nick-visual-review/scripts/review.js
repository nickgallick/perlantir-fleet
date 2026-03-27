#!/usr/bin/env node
/**
 * Visual Review Script
 * Takes screenshots of a URL at multiple viewport sizes.
 * Usage: node review.js <url> [output-dir]
 */

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const viewports = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'laptop', width: 1280, height: 800 },
  { name: 'desktop', width: 1920, height: 1080 },
];

async function run() {
  const url = process.argv[2];
  const outDir = process.argv[3] || './review-screenshots';

  if (!url) {
    console.error('Usage: node review.js <url> [output-dir]');
    process.exit(1);
  }

  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const results = [];

  for (const vp of viewports) {
    const context = await browser.newContext({
      viewport: { width: vp.width, height: vp.height },
      deviceScaleFactor: 2,
    });
    const page = await context.newPage();

    console.log(`Capturing ${vp.name} (${vp.width}x${vp.height})...`);

    try {
      await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(2000); // let animations settle

      // Full page screenshot
      const filename = `${vp.name}-${vp.width}x${vp.height}-full.png`;
      const filepath = path.join(outDir, filename);
      await page.screenshot({ path: filepath, fullPage: true });
      results.push({ viewport: vp.name, width: vp.width, height: vp.height, file: filepath, status: 'ok' });

      // Above-the-fold screenshot
      const foldFile = `${vp.name}-${vp.width}x${vp.height}-fold.png`;
      const foldPath = path.join(outDir, foldFile);
      await page.screenshot({ path: foldPath, fullPage: false });
      results.push({ viewport: `${vp.name}-fold`, width: vp.width, height: vp.height, file: foldPath, status: 'ok' });

      // Collect page metadata
      const meta = await page.evaluate(() => {
        const h1 = document.querySelector('h1');
        const title = document.title;
        const metaDesc = document.querySelector('meta[name="description"]')?.content || '';
        const ogImage = document.querySelector('meta[property="og:image"]')?.content || '';
        const links = document.querySelectorAll('a');
        const images = document.querySelectorAll('img');
        const imgsWithoutAlt = [...images].filter(i => !i.alt).length;
        const h1Count = document.querySelectorAll('h1').length;
        const fontSizes = new Set();
        document.querySelectorAll('*').forEach(el => {
          const fs = window.getComputedStyle(el).fontSize;
          fontSizes.add(fs);
        });
        return {
          title,
          h1Text: h1?.textContent?.trim() || null,
          h1Count,
          metaDescription: metaDesc,
          ogImage,
          linkCount: links.length,
          imageCount: images.length,
          imagesWithoutAlt: imgsWithoutAlt,
          uniqueFontSizes: [...fontSizes].sort(),
        };
      });

      if (vp.name === 'desktop') {
        const metaFile = path.join(outDir, 'page-meta.json');
        fs.writeFileSync(metaFile, JSON.stringify(meta, null, 2));
        console.log(`Page metadata saved to ${metaFile}`);
      }

    } catch (err) {
      console.error(`Error on ${vp.name}: ${err.message}`);
      results.push({ viewport: vp.name, width: vp.width, height: vp.height, status: 'error', error: err.message });
    }

    await context.close();
  }

  // Check for console errors on desktop
  const errContext = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const errPage = await errContext.newPage();
  const consoleErrors = [];
  errPage.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  errPage.on('pageerror', err => consoleErrors.push(err.message));

  try {
    await errPage.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
    await errPage.waitForTimeout(3000);
  } catch (e) { /* ignore nav errors */ }

  await errContext.close();
  await browser.close();

  // Write summary
  const summary = {
    url,
    timestamp: new Date().toISOString(),
    screenshots: results,
    consoleErrors,
  };
  const summaryFile = path.join(outDir, 'review-summary.json');
  fs.writeFileSync(summaryFile, JSON.stringify(summary, null, 2));
  console.log(`\nReview complete. Summary: ${summaryFile}`);
  console.log(`Screenshots: ${outDir}/`);
  console.log(`Console errors found: ${consoleErrors.length}`);
}

run().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});
