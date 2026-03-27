#!/usr/bin/env node
// Create side-by-side comparison strip of reference vs clone screenshots
// Usage: NODE_PATH=/data/.npm-global/lib/node_modules node visual-diff.js <reference-dir> <clone.html> <output-dir>
// Takes section-by-section screenshots of the clone and pairs them with reference sections

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const referenceDir = process.argv[2];
const cloneHtml = process.argv[3];
const outputDir = process.argv[4] || '/tmp/visual-diff';

if (!referenceDir || !cloneHtml) {
  console.error('Usage: node visual-diff.js <reference-extract-dir> <clone.html> <output-dir>');
  process.exit(1);
}

fs.mkdirSync(outputDir, { recursive: true });

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 390, height: 844, deviceScaleFactor: 2 } });

  // Screenshot clone in sections
  await page.goto(`file://${path.resolve(cloneHtml)}`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(4000);

  // Full page
  await page.screenshot({ path: path.join(outputDir, 'clone-full.png'), fullPage: true });

  // Sections
  const fullHeight = await page.evaluate(() => document.body.scrollHeight);
  const viewHeight = 844;
  let sectionIdx = 0;
  for (let y = 0; y < fullHeight; y += viewHeight) {
    await page.evaluate((scrollY) => window.scrollTo(0, scrollY), y);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outputDir, `clone-section-${sectionIdx}.png`), fullPage: false });
    sectionIdx++;
  }

  await browser.close();

  // Report
  const refScreenshots = fs.readdirSync(path.join(referenceDir, 'screenshots')).filter(f => f.startsWith('section-')).sort();
  const cloneScreenshots = fs.readdirSync(outputDir).filter(f => f.startsWith('clone-section-')).sort();

  let report = `# Visual Diff Report\n\n`;
  report += `| Section | Reference | Clone |\n|---|---|---|\n`;
  const maxSections = Math.max(refScreenshots.length, cloneScreenshots.length);
  for (let i = 0; i < maxSections; i++) {
    const ref = i < refScreenshots.length ? path.join(referenceDir, 'screenshots', refScreenshots[i]) : 'N/A';
    const clone = i < cloneScreenshots.length ? path.join(outputDir, cloneScreenshots[i]) : 'N/A';
    report += `| ${i} | ${ref} | ${clone} |\n`;
  }
  report += `\n## Comparison Files\n`;
  report += `- Reference full: ${path.join(referenceDir, 'screenshots', 'full-page.png')}\n`;
  report += `- Clone full: ${path.join(outputDir, 'clone-full.png')}\n`;
  report += `- Reference sections: ${refScreenshots.length}\n`;
  report += `- Clone sections: ${cloneScreenshots.length}\n`;

  fs.writeFileSync(path.join(outputDir, 'diff-report.md'), report);
  console.log(`Visual diff complete → ${outputDir}`);
  console.log(`  Reference sections: ${refScreenshots.length}`);
  console.log(`  Clone sections: ${cloneScreenshots.length}`);
  console.log(`  Use image analysis to compare section-by-section`);
})().catch(e => { console.error(e); process.exit(1); });
