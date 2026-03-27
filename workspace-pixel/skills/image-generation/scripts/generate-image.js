#!/usr/bin/env node
// Generate images via Apiframe (Midjourney, DALL-E, Flux, Ideogram)
// Usage: NODE_PATH=/data/.npm-global/lib/node_modules node generate-image.js <prompt> [options]
//
// Options (via env vars):
//   APIFRAME_KEY     - API key (required)
//   MODEL            - midjourney|dalle|flux|ideogram (default: midjourney)
//   ASPECT_RATIO     - 1:1|16:9|9:16|4:3|3:4|2:3|3:2 (default: 16:9)
//   OUTPUT_DIR       - where to save downloaded images (default: /tmp/generated-images)
//   STYLE            - raw|cute|scenic|expressive (midjourney only)
//   QUALITY          - 1|2 (midjourney only, 2=highest)
//   UPSCALE          - 1|2|3|4 to auto-upscale a specific variant

const { Apiframe } = require('@apiframe-ai/sdk');
const https = require('https');
const fs = require('fs');
const path = require('path');

const prompt = process.argv.slice(2).join(' ');
if (!prompt) {
  console.error('Usage: node generate-image.js "<prompt>"');
  console.error('Env: APIFRAME_KEY, MODEL, ASPECT_RATIO, OUTPUT_DIR, STYLE, QUALITY, UPSCALE');
  process.exit(1);
}

const apiKey = process.env.APIFRAME_KEY || '9c0e5954-eca0-4001-8f35-e462ae0544a0';
const model = (process.env.MODEL || 'midjourney').toLowerCase();
const aspectRatio = process.env.ASPECT_RATIO || '16:9';
const outputDir = process.env.OUTPUT_DIR || '/tmp/generated-images';
const style = process.env.STYLE || '';
const quality = process.env.QUALITY || '';
const upscaleVariant = process.env.UPSCALE || '';

fs.mkdirSync(outputDir, { recursive: true });

const client = new Apiframe({ apiKey });

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        download(res.headers.location, dest).then(resolve).catch(reject);
        return;
      }
      res.pipe(file);
      file.on('finish', () => { file.close(); resolve(dest); });
    }).on('error', reject);
  });
}

async function waitForTask(taskId, maxWait = 180000) {
  const start = Date.now();
  while (Date.now() - start < maxWait) {
    const result = await client.tasks.get(taskId);
    const progress = result.progress || result.percentage || 0;
    process.stderr.write(`\r  Progress: ${progress}% [${result.status}]`);
    
    if (result.status === 'completed' || result.status === 'finished') {
      process.stderr.write('\n');
      return result;
    }
    if (result.status === 'failed' || result.status === 'error') {
      throw new Error(`Task failed: ${JSON.stringify(result)}`);
    }
    await new Promise(r => setTimeout(r, 4000));
  }
  throw new Error('Task timed out after ' + (maxWait / 1000) + 's');
}

async function main() {
  console.log(`[image-gen] Model: ${model}`);
  console.log(`[image-gen] Aspect: ${aspectRatio}`);
  console.log(`[image-gen] Prompt: ${prompt.substring(0, 100)}...`);

  let task;
  
  if (model === 'midjourney') {
    const params = { prompt, aspect_ratio: aspectRatio };
    if (style) params.style = style;
    if (quality) params.quality = parseInt(quality);
    task = await client.midjourney.imagine(params);
  } else if (model === 'dalle') {
    task = await client.dalle.generate({ prompt, size: aspectRatio === '1:1' ? '1024x1024' : '1792x1024' });
  } else if (model === 'flux') {
    task = await client.flux.generate({ prompt, aspect_ratio: aspectRatio });
  } else if (model === 'ideogram') {
    task = await client.ideogram.generate({ prompt, aspect_ratio: aspectRatio });
  } else {
    throw new Error(`Unknown model: ${model}. Use: midjourney, dalle, flux, ideogram`);
  }

  console.log(`[image-gen] Task created: ${task.id || task.task_id}`);
  
  // Wait for completion
  const result = await waitForTask(task.id || task.task_id);
  
  // Download images
  const imageUrls = result.image_urls || [result.image_url].filter(Boolean);
  console.log(`[image-gen] ${imageUrls.length} image(s) generated`);
  
  const downloaded = [];
  for (let i = 0; i < imageUrls.length; i++) {
    const url = imageUrls[i];
    const ext = url.match(/\.(png|jpg|jpeg|webp)/i)?.[1] || 'png';
    const filename = `${model}-${Date.now()}-${i + 1}.${ext}`;
    const filepath = path.join(outputDir, filename);
    
    try {
      await download(url, filepath);
      downloaded.push({ url, localPath: filepath, variant: i + 1 });
      console.log(`[image-gen] Downloaded: ${filepath}`);
    } catch (e) {
      console.error(`[image-gen] Download failed for variant ${i + 1}: ${e.message}`);
      downloaded.push({ url, localPath: null, variant: i + 1 });
    }
  }
  
  // Auto-upscale if requested
  if (upscaleVariant && model === 'midjourney' && result.actions?.includes(`upscale${upscaleVariant}`)) {
    console.log(`[image-gen] Upscaling variant ${upscaleVariant}...`);
    const upscaleTask = await client.midjourney.action({
      task_id: result.task_id || result.id,
      action: `upscale${upscaleVariant}`
    });
    const upscaleResult = await waitForTask(upscaleTask.id || upscaleTask.task_id);
    const upscaleUrls = upscaleResult.image_urls || [upscaleResult.image_url].filter(Boolean);
    
    for (const url of upscaleUrls) {
      const ext = url.match(/\.(png|jpg|jpeg|webp)/i)?.[1] || 'png';
      const filename = `${model}-upscaled-${Date.now()}.${ext}`;
      const filepath = path.join(outputDir, filename);
      await download(url, filepath);
      downloaded.push({ url, localPath: filepath, variant: 'upscaled' });
      console.log(`[image-gen] Upscaled: ${filepath}`);
    }
  }
  
  // Output manifest
  const manifest = {
    prompt,
    model,
    aspectRatio,
    taskId: result.task_id || result.id,
    originalUrl: result.original_image_url || null,
    images: downloaded,
    actions: result.actions || [],
    generatedAt: new Date().toISOString()
  };
  
  const manifestPath = path.join(outputDir, `manifest-${Date.now()}.json`);
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
  
  // Print summary to stdout as JSON for programmatic use
  console.log('\n' + JSON.stringify(manifest, null, 2));
}

main().catch(e => {
  console.error(`[image-gen] Fatal: ${e.message}`);
  process.exit(1);
});
