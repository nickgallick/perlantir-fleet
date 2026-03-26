---
name: video-and-media-integration
description: "Video backgrounds, HLS streaming, overlays, image optimization. Complete React implementations. Use when integrating video backgrounds, HLS streaming, video fades, responsive video, or media-heavy designs."
---

# Video & Media Integration

Reference this skill for video backgrounds, streaming, overlays, and media optimization.

## HLS Video Background

Full-screen video background with HLS streaming:

```tsx
import { useRef, useEffect } from "react"
import Hls from "hls.js"

const VideoBackground = ({ src, className = "" }) => {
  const videoRef = useRef<HTMLVideoElement>(null)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return

    if (video.canPlayType("application/vnd.apple.mpegurl")) {
      video.src = src // Safari native HLS
    } else if (Hls.isSupported()) {
      const hls = new Hls({ enableWorker: true, lowLatencyMode: true })
      hls.loadSource(src)
      hls.attachMedia(video)
      return () => hls.destroy()
    }
  }, [src])

  return (
    <video
      ref={videoRef}
      autoPlay
      muted
      loop
      playsInline
      className={`absolute inset-0 w-full h-full object-cover ${className}`}
    />
  )
}
```

**Required attributes:** `autoPlay muted loop playsInline` (all four for autoplay to work).

---

## Video Overlays & Fades

**Standard overlay structure:**
```html
<div className="relative h-[1000px] overflow-hidden">
  {/* z-0: Video */}
  <VideoBackground src="..." className="z-0" />
  
  {/* z-[1]: Color overlay */}
  <div className="absolute inset-0 bg-black/20 z-[1]" />
  
  {/* z-[1]: Top fade */}
  <div className="absolute top-0 left-0 right-0 h-[200px] bg-gradient-to-b from-black to-transparent z-[1]" />
  
  {/* z-[1]: Bottom fade */}
  <div className="absolute bottom-0 left-0 right-0 h-[200px] bg-gradient-to-t from-black to-transparent z-[1]" />
  
  {/* z-[2]: Content */}
  <div className="relative z-[2]">
    {/* Headings, CTAs, etc. */}
  </div>
</div>
```

**Desaturated video (stats/testimonial sections):**
```css
video { filter: saturate(0); }
```
Tailwind: `saturate-0`

---

## Responsive Video

**Desktop: partial width, positioned right:**
```html
<video className="hidden md:block absolute right-0 top-0 bottom-0 w-[55%] object-cover object-top" />
```

**Mobile: full width, lower opacity:**
```html
<video className="md:hidden absolute inset-0 w-full h-full object-cover opacity-30" />
```

**Aspect-ratio video container:**
```html
<div className="aspect-video rounded-2xl overflow-hidden">
  <video className="w-full h-full object-cover" />
</div>
```

---

## Video-by-Breakpoint Pattern

Different video behavior at different screen sizes:
```tsx
const ResponsiveVideo = ({ src }) => (
  <div className="absolute inset-0">
    {/* Mobile: full width, dimmed */}
    <video
      src={src} autoPlay muted loop playsInline
      className="md:hidden absolute inset-0 w-full h-full object-cover opacity-30"
    />
    {/* Desktop: right-aligned, full opacity */}
    <video
      src={src} autoPlay muted loop playsInline
      className="hidden md:block absolute right-0 top-0 bottom-0 w-[55%] h-full object-cover object-top"
      style={{ mixBlendMode: "normal" }}
    />
  </div>
)
```

---

## GIF in Glass Card

For feature showcases:
```html
<div className="liquid-glass rounded-2xl overflow-hidden">
  <img
    src="/features/demo.gif"
    alt="Feature demo"
    className="w-full h-auto"
    loading="lazy"
  />
</div>
```

---

## Image Optimization

**Next.js Image component:**
```tsx
import Image from "next/image"

<Image
  src="/hero.jpg"
  alt="Hero"
  fill
  className="object-cover"
  priority // Above-the-fold images
  sizes="(max-width: 768px) 100vw, (max-width: 1280px) 50vw, 33vw"
/>
```

**Rules:**
- `priority` on hero/above-fold images only
- `loading="lazy"` on everything else (default in Next.js)
- Always specify `sizes` for responsive images
- Use `fill` + `object-cover` for container-filling images
- Serve WebP/AVIF via Next.js Image optimization

---

## Vignette Overlays for Video

**Desktop (radial vignette):**
```css
.vignette-desktop {
  position: absolute; inset: 0;
  background: radial-gradient(ellipse, transparent 70%, rgba(0,0,0,0.7) 100%);
  pointer-events: none;
}
```

**Mobile (bottom gradient for text readability):**
```css
.vignette-mobile {
  position: absolute; inset: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.8), transparent 60%);
  pointer-events: none;
}
```

---

## Z-Layer Stack for Video Sections

```
z-0:  Solid background color (fallback)
z-[1]: Video element
z-[1]: Overlays (gradients, vignettes, desaturation)
z-[2]: Content (text, buttons, cards)
z-[3]: Section dividers (SVG polygons)
z-50:  Navigation (always above)
```

---

## Performance Rules

1. **Never autoplay video with sound.** Always `muted`.
2. **Use HLS for large videos.** MP4 fallback for short clips only.
3. **Lazy-load below-fold videos.** Use IntersectionObserver to load/play only when visible.
4. **Prefer CSS animations over video** for simple backgrounds (grid patterns, particle effects).
5. **First load matters.** Hero video should be ≤2MB for fast LCP. Use poster image as placeholder.
6. **Reduce motion:** Replace video with static poster when `prefers-reduced-motion: reduce`.

```tsx
const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
if (prefersReducedMotion) {
  // Show poster image instead of video
}
```
