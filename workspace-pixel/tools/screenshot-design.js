/**
 * Pixel Design Screenshot Tool
 * Uses Playwright (confirmed installed) instead of Puppeteer
 * Usage: node screenshot-design.js <htmlPath> <outputPath> [width] [height]
 */
const { chromium } = require('/data/.openclaw/workspace/node_modules/playwright');
const fs = require('fs');

(async () => {
  const htmlPath = process.argv[2] || '/tmp/stitch-screen.html';
  const outputPath = process.argv[3] || '/tmp/design-screenshot.png';
  const width = parseInt(process.argv[4]) || 390;
  const height = parseInt(process.argv[5]) || 844;

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu']
  });

  const context = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: 2
  });

  const page = await context.newPage();
  const htmlContent = fs.readFileSync(htmlPath, 'utf8');
  await page.setContent(htmlContent, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(1000);

  // Full page screenshot
  await page.screenshot({ path: outputPath, fullPage: true });

  // Viewport only (above the fold)
  const viewportPath = outputPath.replace('.png', '-viewport.png');
  await page.screenshot({ path: viewportPath, fullPage: false });

  console.log('Screenshots saved:', outputPath, viewportPath);

  // Extract design tokens
  const tokens = await page.evaluate(() => {
    const fontSizes = new Set();
    const colors = new Set();
    const fontFamilies = new Set();
    const borderRadii = new Set();
    const gaps = new Set();

    document.querySelectorAll('*').forEach(el => {
      const s = getComputedStyle(el);
      if (s.fontSize) fontSizes.add(s.fontSize);
      if (s.color && s.color !== 'rgba(0, 0, 0, 0)') colors.add(s.color);
      if (s.backgroundColor && s.backgroundColor !== 'rgba(0, 0, 0, 0)') colors.add(s.backgroundColor);
      if (s.fontFamily) fontFamilies.add(s.fontFamily.split(',')[0].trim().replace(/['"]/g, ''));
      if (s.borderRadius && s.borderRadius !== '0px') borderRadii.add(s.borderRadius);
      if (s.gap && s.gap !== 'normal') gaps.add(s.gap);
    });

    return {
      fontSizes: [...fontSizes].sort(),
      colors: [...colors],
      fontFamilies: [...fontFamilies],
      borderRadii: [...borderRadii],
      gaps: [...gaps]
    };
  });

  const tokensPath = outputPath.replace('.png', '-tokens.json');
  fs.writeFileSync(tokensPath, JSON.stringify(tokens, null, 2));
  console.log('Tokens saved:', tokensPath);

  await browser.close();
})().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
