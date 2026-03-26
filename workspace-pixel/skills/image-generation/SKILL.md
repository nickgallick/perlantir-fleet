---
name: image-generation
description: Generate high-quality images via Midjourney, DALL-E 3, Flux, and Ideogram through Apiframe API. Use when designs need hero images, card thumbnails, realistic photos, background textures, illustrations, user avatars, product mockups, or any visual asset that isn't a UI component or icon. Triggers on phrases like "generate an image", "need a hero image", "create a photo", "stock image", "illustration for", "background for", or when a V0 design has gray placeholder images that need replacing.
---

# Image Generation — Apiframe Multi-Model Pipeline

## When to Generate Images

### Auto-generate (don't wait to be asked)
- **Landing page hero** — every landing page needs a hero image
- **Card thumbnails** — listing UIs, business cards, article cards
- **Empty state illustrations** — onboarding, no-data screens
- **Clone designs** — replacing placeholder rectangles with real photos
- **User avatars** — realistic placeholder people for mockups

### On request only
- Background textures and abstract patterns
- Product/device mockups (phone, laptop with screen)
- Blog/article featured images
- Social media assets
- Marketing materials

### Never generate (use other tools)
- Icons → Lucide (1703 icons in repos/lucide/)
- Logos → needs human designer
- UI components → V0
- Screenshots → Playwright
- Charts → Recharts

## Quick Start

```bash
# Basic Midjourney generation
NODE_PATH=/data/.npm-global/lib/node_modules \
  node skills/image-generation/scripts/generate-image.js \
  "your prompt here"

# With options
ASPECT_RATIO=1:1 MODEL=midjourney \
  NODE_PATH=/data/.npm-global/lib/node_modules \
  node skills/image-generation/scripts/generate-image.js \
  "your prompt here"
```

Returns: 4 image variants (Midjourney) or 1 image (DALL-E/Flux/Ideogram), downloaded locally + CDN URLs.

## Models — When to Use Each

| Model | Quality | Speed | Best For | Cost |
|---|---|---|---|---|
| **Midjourney v7** | 10/10 | 30-60s | Hero images, cinematic, premium brand, emotional | ~$0.04/img |
| **DALL-E 3** | 7/10 | 15-20s | Accurate prompt following, text in images, quick prototypes | ~$0.04/img |
| **Flux 1.1** | 9/10 | 10-15s | High volume, modern aesthetic, speed-critical | ~$0.03/img |
| **Ideogram** | 8/10 | 15-25s | Text rendering in images, logos mockups, social graphics | ~$0.025/img |

### Decision Tree
```
Need text IN the image? → Ideogram
Need 10+ images fast? → Flux
Need maximum quality? → Midjourney
Need accurate prompt following? → DALL-E 3
Default → Midjourney
```

## Prompt Engineering by Use Case

### Hero Images (Landing Pages)
```
Model: Midjourney
Aspect: 16:9
Template: "[scene description], [mood], [lighting], premium quality, editorial photography, 8k --ar 16:9 --v 7"

Example — Fintech:
"abstract flowing data streams and geometric shapes floating in deep navy space, cyan and blue glow accents, premium tech aesthetic, dark background, volumetric lighting, cinematic, 8k --ar 16:9 --v 7"

Example — SaaS:
"modern minimalist workspace with floating holographic UI elements, soft warm lighting, clean white desk, shallow depth of field, editorial photography --ar 16:9 --v 7"
```

### Card Thumbnails (Business/Product Cards)
```
Model: Midjourney
Aspect: 4:3 or 3:2
Template: "[subject in setting], warm ambient lighting, shallow depth of field, [mood] --ar 4:3 --v 7"

Example — Salon/Barbershop:
"interior of a premium modern barbershop, warm amber lighting, leather chairs, mirrors, dark wood accents, inviting atmosphere --ar 4:3 --v 7"

Example — Restaurant:
"elegant dinner table setting in upscale restaurant, candlelight, fine dining, moody ambiance, bokeh background --ar 4:3 --v 7"
```

### User Avatars (Realistic People)
```
Model: Midjourney
Aspect: 1:1
Template: "professional headshot portrait of [description], natural lighting, neutral background, friendly expression, high quality --ar 1:1 --v 7"

Example:
"professional headshot portrait of a young woman with dark curly hair, warm smile, soft natural lighting, light gray background, corporate casual --ar 1:1 --v 7"
```

### Background Textures (Dark Theme)
```
Model: Midjourney
Aspect: 16:9
Template: "abstract [pattern type], [brand colors], subtle, dark background, seamless, 8k --ar 16:9 --v 7 --style raw"

Example — Perlantir:
"abstract geometric mesh pattern, deep navy #0A1628, subtle blue gradient lines, minimal, dark luxurious, seamless texture --ar 16:9 --v 7 --style raw"

Example — NERVE:
"abstract neural network visualization, deep black #080C18, cyan #00D4FF node connections, dark sci-fi, subtle glow --ar 16:9 --v 7 --style raw"
```

### Empty State Illustrations
```
Model: DALL-E 3 or Midjourney
Aspect: 1:1
Template: "minimalist flat illustration of [concept], [brand accent color] accent, simple clean lines, white or dark background, modern vector style"

Example:
"minimalist flat illustration of an empty inbox with a small paper airplane, electric green #39FF14 accent details, dark charcoal background, clean modern vector style --ar 1:1 --v 7"
```

### Product/Device Mockups
```
Model: Midjourney
Aspect: 16:9 or 4:3
Template: "[device] mockup floating at angle, [screen content description], dark background, studio lighting, premium product photography --ar 16:9 --v 7"

Example:
"iPhone 15 Pro mockup floating at slight angle, dark fintech app on screen, deep navy background, subtle reflection, studio lighting, premium product photography --ar 16:9 --v 7"
```

## Brand-Specific Prompt Additions

When generating for a specific brand, append these to any prompt:

### Perlantir
```
, deep navy blue #0A1628 tones, professional, data-driven aesthetic, Bloomberg meets Apple feel, cool blue lighting
```

### UberKiwi
```
, dark background with electric green #39FF14 accent glow, bold modern energy, high contrast, neon on black
```

### NERVE
```
, deep black #080C18 with cyan #00D4FF accents, cinematic sci-fi atmosphere, mission control aesthetic, intense focused
```

## Aspect Ratios Guide

| Ratio | Pixels | Use For |
|---|---|---|
| 16:9 | 1920×1080 | Hero banners, backgrounds, headers |
| 4:3 | 1600×1200 | Card thumbnails, business photos |
| 3:2 | 1500×1000 | Blog featured images, portfolio items |
| 1:1 | 1024×1024 | Avatars, profile photos, app icons |
| 9:16 | 1080×1920 | Mobile hero, stories, app store screenshots |
| 2:3 | 1000×1500 | Portrait photos, tall cards |
| 3:4 | 1200×1600 | Product photos, Pinterest-style |

## Actions After Generation

Midjourney returns 4 variants. After reviewing:

### Upscale (get high-res version of best variant)
```bash
UPSCALE=2 NODE_PATH=/data/.npm-global/lib/node_modules \
  node skills/image-generation/scripts/generate-image.js "original prompt"
```
Or call the API directly:
```javascript
client.midjourney.action({ task_id: "TASK_ID", action: "upscale2" })
```

### Variation (get more like a specific variant)
```javascript
client.midjourney.action({ task_id: "TASK_ID", action: "variation3" })
```

### Reroll (completely new set)
```javascript
client.midjourney.action({ task_id: "TASK_ID", action: "reroll" })
```

## Integration with V0 Design Pipeline

### During V0 Generation
1. Generate images BEFORE or DURING V0 design creation
2. Get CDN URLs from Apiframe
3. Pass image URLs to V0 via attachments or in the prompt:
```
"Use this image as the hero: https://cdn.apiframe.pro/images/xxxxx.png"
```

### After V0 Generation (replacing placeholders)
1. Identify gray/gradient placeholder areas in V0 output
2. Generate appropriate images for each placeholder
3. Send V0 a follow-up message with chatId:
```
"Replace the hero placeholder with this image: [URL]
Replace the card thumbnails with these: [URL1], [URL2], [URL3]"
```

### For Clone Designs
1. Extract real images from the source site (clone-design skill Phase 1)
2. If images can't be extracted (lazy-loaded, protected), generate similar ones:
   - Analyze the source screenshot to understand what the image should be
   - Craft a Midjourney prompt to recreate a similar image
   - Use the generated image in the clone

## File Organization
```
/tmp/generated-images/              # Default output
  midjourney-{timestamp}-1.png      # Variant 1
  midjourney-{timestamp}-2.png      # Variant 2
  midjourney-{timestamp}-3.png      # Variant 3
  midjourney-{timestamp}-4.png      # Variant 4
  midjourney-upscaled-{timestamp}.png  # Upscaled version
  manifest-{timestamp}.json         # Generation metadata

stitch-pulls/{project}/images/      # Project-specific generated images
```

## Environment
```
APIFRAME_KEY=9c0e5954-eca0-4001-8f35-e462ae0544a0
```

## Changelog
- 2026-03-20: Initial skill — Apiframe integration with Midjourney, DALL-E 3, Flux, Ideogram support
