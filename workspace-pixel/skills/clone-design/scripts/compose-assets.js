#!/usr/bin/env node
// Compose extracted assets into a Stitch-generated HTML file
// Usage: NODE_PATH=/data/.npm-global/lib/node_modules node compose-assets.js <generated.html> <extract-dir> <output.html>
// Replaces placeholder images with real extracted assets using position/size matching

const fs = require('fs');
const path = require('path');

const generatedHtml = process.argv[2];
const extractDir = process.argv[3];
const outputFile = process.argv[4];

if (!generatedHtml || !extractDir || !outputFile) {
  console.error('Usage: node compose-assets.js <generated.html> <extract-dir> <output.html>');
  process.exit(1);
}

let html = fs.readFileSync(generatedHtml, 'utf-8');
const tokensPath = path.join(extractDir, 'design-tokens.json');

if (!fs.existsSync(tokensPath)) {
  console.error('No design-tokens.json found in extract dir');
  process.exit(1);
}

const tokens = JSON.parse(fs.readFileSync(tokensPath, 'utf-8'));

// 1. Replace placeholder/gradient images with real extracted images
// Convert extracted images to data URIs or file:// paths
const imageDir = path.join(extractDir, 'assets', 'images');
if (fs.existsSync(imageDir)) {
  const imageFiles = fs.readdirSync(imageDir).filter(f => /\.(png|jpg|jpeg|webp|gif|avif)$/i.test(f));
  
  // Find img tags with placeholder/gradient sources and replace with real images
  let imgIndex = 0;
  html = html.replace(/<img([^>]*?)src=["'](data:image\/svg\+xml[^"']*|https?:\/\/(?:via\.placeholder|placehold|picsum|unsplash|images\.unsplash)[^"']*|[^"']*gradient[^"']*)["']/gi, (match, attrs, src) => {
    if (imgIndex < imageFiles.length) {
      const realPath = path.resolve(imageDir, imageFiles[imgIndex]);
      imgIndex++;
      return `<img${attrs}src="file://${realPath}"`;
    }
    return match;
  });

  // Also replace background-image placeholders
  imgIndex = 0;
  html = html.replace(/background-image:\s*url\(["']?(data:image\/svg\+xml[^"')]*|https?:\/\/(?:via\.placeholder|placehold|picsum|unsplash)[^"')]*|[^"')]*gradient)["']?\)/gi, (match, src) => {
    if (imgIndex < imageFiles.length) {
      const realPath = path.resolve(imageDir, imageFiles[imgIndex]);
      imgIndex++;
      return `background-image: url('file://${realPath}')`;
    }
    return match;
  });
}

// 2. Inject inline SVGs where possible
const svgDir = path.join(extractDir, 'assets', 'svgs');
if (fs.existsSync(svgDir)) {
  const svgFiles = fs.readdirSync(svgDir).filter(f => f.endsWith('.svg'));
  // Make SVGs available as a lookup — don't auto-replace, but note them
  console.log(`  ${svgFiles.length} SVGs available for manual injection`);
}

// 3. Fix font references to use extracted fonts or CDN
const fontDir = path.join(extractDir, 'assets', 'fonts');
if (fs.existsSync(fontDir)) {
  const fontFiles = fs.readdirSync(fontDir).filter(f => /\.(woff2?|ttf|otf)$/i.test(f));
  if (fontFiles.length > 0) {
    // Add @font-face declarations at the top of <style>
    let fontFaces = '';
    tokens.fonts.forEach((fontName, i) => {
      if (i < fontFiles.length) {
        const fontPath = path.resolve(fontDir, fontFiles[i]);
        const ext = path.extname(fontFiles[i]).slice(1);
        const format = ext === 'woff2' ? 'woff2' : ext === 'woff' ? 'woff' : ext === 'ttf' ? 'truetype' : 'opentype';
        fontFaces += `@font-face { font-family: '${fontName}'; src: url('file://${fontPath}') format('${format}'); }\n`;
      }
    });
    if (fontFaces) {
      html = html.replace(/<style>/, `<style>\n${fontFaces}`);
      console.log(`  Injected ${tokens.fonts.length} @font-face declarations`);
    }
  }
}

// 4. Write composed output
fs.writeFileSync(outputFile, html);
console.log(`Composed output → ${outputFile}`);
console.log(`  Source HTML: ${generatedHtml}`);
console.log(`  Assets from: ${extractDir}`);
