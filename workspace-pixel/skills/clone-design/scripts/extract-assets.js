#!/usr/bin/env node
// Extract all visual assets, fonts, colors, and structure from a URL
// Usage: NODE_PATH=/data/.npm-global/lib/node_modules node extract-assets.js <url> <output-dir>

const { chromium, devices } = require('playwright');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const url = process.argv[2];
const outputDir = process.argv[3] || '/tmp/clone-extract';

if (!url) { console.error('Usage: node extract-assets.js <url> <output-dir>'); process.exit(1); }

fs.mkdirSync(path.join(outputDir, 'assets', 'images'), { recursive: true });
fs.mkdirSync(path.join(outputDir, 'assets', 'svgs'), { recursive: true });
fs.mkdirSync(path.join(outputDir, 'assets', 'fonts'), { recursive: true });
fs.mkdirSync(path.join(outputDir, 'screenshots'), { recursive: true });

function download(fileUrl, dest) {
  return new Promise((resolve, reject) => {
    const proto = fileUrl.startsWith('https') ? https : http;
    const file = fs.createWriteStream(dest);
    proto.get(fileUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        download(res.headers.location, dest).then(resolve).catch(reject);
        return;
      }
      res.pipe(file);
      file.on('finish', () => { file.close(); resolve(dest); });
    }).on('error', (e) => { fs.unlink(dest, () => {}); reject(e); });
  });
}

(async () => {
  const iPhone = devices['iPhone 13'];
  const browser = await chromium.launch();
  const context = await browser.newContext({ ...iPhone });
  const page = await context.newPage();

  console.log(`[1/7] Loading ${url}...`);
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(5000);

  // Screenshot: full page + viewport
  console.log('[2/7] Taking screenshots...');
  await page.screenshot({ path: path.join(outputDir, 'screenshots', 'full-page.png'), fullPage: true });
  await page.screenshot({ path: path.join(outputDir, 'screenshots', 'viewport.png'), fullPage: false });

  // Sectioned screenshots (scroll-based)
  const fullHeight = await page.evaluate(() => document.body.scrollHeight);
  const viewHeight = 844;
  let sectionIdx = 0;
  for (let y = 0; y < fullHeight; y += viewHeight) {
    await page.evaluate((scrollY) => window.scrollTo(0, scrollY), y);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outputDir, 'screenshots', `section-${sectionIdx}.png`), fullPage: false });
    sectionIdx++;
  }
  await page.evaluate(() => window.scrollTo(0, 0));

  // Extract all data in one evaluate call
  console.log('[3/7] Extracting design tokens...');
  const extraction = await page.evaluate(() => {
    const result = { images: [], svgs: [], fonts: new Set(), colors: new Set(), sections: [], typography: [] };

    // Images
    document.querySelectorAll('img').forEach(img => {
      if (img.src && img.naturalWidth > 10) {
        const rect = img.getBoundingClientRect();
        result.images.push({
          src: img.src, alt: img.alt || '',
          width: rect.width, height: rect.height,
          x: rect.x, y: rect.y + window.scrollY
        });
      }
    });

    // SVGs (inline)
    document.querySelectorAll('svg').forEach((svg, i) => {
      const rect = svg.getBoundingClientRect();
      if (rect.width > 5 && rect.height > 5) {
        result.svgs.push({
          html: svg.outerHTML, index: i,
          width: rect.width, height: rect.height,
          x: rect.x, y: rect.y + window.scrollY
        });
      }
    });

    // Background images
    document.querySelectorAll('*').forEach(el => {
      const bg = getComputedStyle(el).backgroundImage;
      if (bg && bg !== 'none' && bg.startsWith('url(')) {
        const match = bg.match(/url\(["']?(.*?)["']?\)/);
        if (match) {
          const rect = el.getBoundingClientRect();
          result.images.push({
            src: match[1], alt: 'bg-image',
            width: rect.width, height: rect.height,
            x: rect.x, y: rect.y + window.scrollY
          });
        }
      }
    });

    // Colors and typography from visible elements
    const visited = new Set();
    document.querySelectorAll('*').forEach(el => {
      const style = getComputedStyle(el);
      const text = el.innerText?.trim();

      // Colors
      [style.color, style.backgroundColor, style.borderColor].forEach(c => {
        if (c && c !== 'rgba(0, 0, 0, 0)' && c !== 'transparent') result.colors.add(c);
      });

      // Fonts
      if (style.fontFamily) result.fonts.add(style.fontFamily.split(',')[0].replace(/['"]/g, '').trim());

      // Typography samples
      if (text && text.length > 0 && text.length < 200 && !visited.has(text)) {
        visited.add(text);
        const rect = el.getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0) {
          result.typography.push({
            text: text.substring(0, 100),
            fontFamily: style.fontFamily.split(',')[0].replace(/['"]/g, '').trim(),
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            color: style.color,
            lineHeight: style.lineHeight,
            letterSpacing: style.letterSpacing,
            y: rect.y + window.scrollY
          });
        }
      }
    });

    // Sections (top-level semantic blocks)
    document.querySelectorAll('header, nav, section, main, footer, [class*="hero"], [class*="section"], [class*="container"]').forEach(el => {
      const rect = el.getBoundingClientRect();
      if (rect.height > 50) {
        result.sections.push({
          tag: el.tagName.toLowerCase(),
          className: el.className?.toString().substring(0, 200) || '',
          y: rect.y + window.scrollY,
          height: rect.height,
          bgColor: getComputedStyle(el).backgroundColor
        });
      }
    });

    result.fonts = [...result.fonts];
    result.colors = [...result.colors];
    result.typography.sort((a, b) => a.y - b.y);
    result.sections.sort((a, b) => a.y - b.y);
    return result;
  });

  // Extract font URLs from stylesheets
  console.log('[4/7] Extracting font URLs...');
  const fontUrls = await page.evaluate(() => {
    const urls = [];
    for (const sheet of document.styleSheets) {
      try {
        for (const rule of sheet.cssRules) {
          if (rule.cssText?.includes('@font-face')) {
            const match = rule.cssText.match(/url\(["']?(.*?)["']?\)/g);
            if (match) match.forEach(u => urls.push(u.replace(/url\(["']?|["']?\)/g, '')));
          }
        }
      } catch (e) {} // cross-origin
    }
    return urls;
  });

  // Get raw HTML
  console.log('[5/7] Extracting source HTML...');
  const html = await page.content();
  fs.writeFileSync(path.join(outputDir, 'source.html'), html);

  // Download images
  console.log('[6/7] Downloading assets...');
  const imageManifest = [];
  for (let i = 0; i < Math.min(extraction.images.length, 30); i++) {
    const img = extraction.images[i];
    try {
      const ext = img.src.match(/\.(png|jpg|jpeg|gif|webp|svg|avif)/i)?.[1] || 'png';
      const filename = `img-${i}.${ext}`;
      await download(img.src, path.join(outputDir, 'assets', 'images', filename));
      imageManifest.push({ ...img, localFile: `assets/images/${filename}` });
    } catch (e) {
      imageManifest.push({ ...img, localFile: null, error: e.message });
    }
  }

  // Save inline SVGs
  extraction.svgs.forEach((svg, i) => {
    fs.writeFileSync(path.join(outputDir, 'assets', 'svgs', `svg-${i}.svg`), svg.html);
  });

  // Download fonts
  for (let i = 0; i < Math.min(fontUrls.length, 10); i++) {
    try {
      const ext = fontUrls[i].match(/\.(woff2?|ttf|otf|eot)/i)?.[1] || 'woff2';
      await download(fontUrls[i], path.join(outputDir, 'assets', 'fonts', `font-${i}.${ext}`));
    } catch (e) {}
  }

  // RGB to hex helper
  function rgbToHex(rgb) {
    const match = rgb.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (!match) return rgb;
    return '#' + [match[1], match[2], match[3]].map(x => parseInt(x).toString(16).padStart(2, '0')).join('');
  }

  // Build design tokens
  console.log('[7/7] Building design token report...');
  const colorHexes = [...new Set(extraction.colors.map(rgbToHex))].filter(c => c.startsWith('#'));
  
  const report = {
    url,
    extractedAt: new Date().toISOString(),
    viewport: { width: 390, height: 844, deviceScaleFactor: 2 },
    fullPageHeight: fullHeight,
    sectionCount: sectionIdx,
    fonts: extraction.fonts,
    colors: colorHexes.slice(0, 40),
    typography: extraction.typography.slice(0, 50),
    sections: extraction.sections.slice(0, 30),
    images: imageManifest,
    svgCount: extraction.svgs.length,
    fontUrlCount: fontUrls.length
  };

  fs.writeFileSync(path.join(outputDir, 'design-tokens.json'), JSON.stringify(report, null, 2));
  
  // Human-readable summary
  let summary = `# Clone Extraction Report\n\n`;
  summary += `**Source:** ${url}\n**Extracted:** ${report.extractedAt}\n**Full page height:** ${fullHeight}px (${sectionIdx} viewport sections)\n\n`;
  summary += `## Fonts Used\n${extraction.fonts.map(f => `- ${f}`).join('\n')}\n\n`;
  summary += `## Color Palette\n${colorHexes.slice(0, 20).map(c => `- \`${c}\``).join('\n')}\n\n`;
  summary += `## Page Sections (${extraction.sections.length})\n`;
  extraction.sections.slice(0, 20).forEach((s, i) => {
    summary += `${i + 1}. \`<${s.tag}>\` at y=${Math.round(s.y)}px, h=${Math.round(s.height)}px, bg=${rgbToHex(s.bgColor)}\n`;
  });
  summary += `\n## Typography Samples (top ${Math.min(extraction.typography.length, 30)})\n`;
  extraction.typography.slice(0, 30).forEach(t => {
    summary += `- "${t.text.substring(0, 60)}" — ${t.fontFamily} ${t.fontWeight} ${t.fontSize} ${rgbToHex(t.color)}\n`;
  });
  summary += `\n## Assets Downloaded\n- Images: ${imageManifest.filter(i => i.localFile).length}/${extraction.images.length}\n`;
  summary += `- SVGs: ${extraction.svgs.length} inline\n- Font files: ${fontUrls.length} URLs found\n`;
  
  fs.writeFileSync(path.join(outputDir, 'extraction-report.md'), summary);

  await browser.close();
  console.log(`\nExtraction complete → ${outputDir}`);
  console.log(`  Screenshots: ${sectionIdx + 2} files`);
  console.log(`  Images: ${imageManifest.filter(i => i.localFile).length} downloaded`);
  console.log(`  SVGs: ${extraction.svgs.length} saved`);
  console.log(`  Colors: ${colorHexes.length} unique`);
  console.log(`  Fonts: ${extraction.fonts.length} families`);
})().catch(e => { console.error(e); process.exit(1); });
