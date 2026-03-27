# Core Web Vitals for Next.js

## Targets

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5-4.0s | > 4.0s |
| INP (Interaction to Next Paint) | < 200ms | 200-500ms | > 500ms |
| CLS (Cumulative Layout Shift) | < 0.1 | 0.1-0.25 | > 0.25 |

## LCP Optimization

### Font Loading
```tsx
// next/font eliminates FOIT/FOUT — always use it
import { Space_Grotesk, Inter } from 'next/font/google'
const heading = Space_Grotesk({ subsets: ['latin'], display: 'swap', variable: '--font-heading' })
```
- `display: 'swap'` prevents invisible text during load
- next/font self-hosts fonts — no Google Fonts request

### Image Optimization
```tsx
// Hero images — use priority to preload
<Image src="/hero.png" alt="..." priority width={1200} height={600} />

// Use next/image for all images — automatic WebP/AVIF, lazy loading, srcset
// Never use <img> tags for important images
```

### Reduce Server Response Time
- Use ISR or SSG for public pages (sub-100ms TTFB on Vercel)
- Minimize database calls in server components — cache aggressively
- Use `unstable_cache` or React `cache()` for expensive queries

### Avoid Render-Blocking Resources
- next/font handles fonts automatically
- Critical CSS is inlined by Next.js
- Defer non-critical scripts:
```tsx
<Script src="analytics.js" strategy="lazyOnload" />
```

## INP Optimization

### Keep Main Thread Free
- Heavy client-side computation → move to Web Workers
- Large lists → virtualize with react-window or @tanstack/virtual
- Animations → use CSS transforms/opacity only (GPU-accelerated)
- Use `startTransition` for non-urgent state updates

### Arena-Specific
- Leaderboard with 1000+ rows → virtualize
- Real-time updates → use optimistic UI + background sync
- Replay viewer → requestAnimationFrame, not setInterval
- Filter changes → debounce, don't re-render on every keystroke

## CLS Optimization

### Reserve Space for Dynamic Content
```tsx
// ✅ Always set explicit dimensions on images
<Image width={800} height={400} ... />

// ✅ Use aspect-ratio for responsive containers
<div className="aspect-video">
  <Image fill ... />
</div>

// ❌ Don't inject content above existing content after load
// ❌ Don't use top banners that load late
```

### Font Loading CLS Prevention
- next/font with `display: 'swap'` and `adjustFontFallback: true`
- Size-adjusted fallback font minimizes layout shift during swap

### Skeleton Loading
```tsx
// Show skeleton matching final content dimensions
<div className="h-12 w-full bg-arena-surface animate-pulse rounded-lg" />
```
Same dimensions as final content = zero CLS.

## Testing Tools

1. **Vercel Analytics** — Real User Monitoring (RUM), automatic CWV tracking
2. **Lighthouse** — `npx lighthouse https://agentarena.com --output html`
3. **PageSpeed Insights** — Lab + field data: https://pagespeed.web.dev/
4. **Chrome DevTools Performance tab** — Detailed trace for INP debugging
5. **web.dev/measure** — Quick CWV check

## Arena Performance Budget

| Resource | Budget |
|----------|--------|
| Total JS (gzipped) | < 200KB |
| Total CSS (gzipped) | < 50KB |
| Hero image | < 100KB (WebP/AVIF) |
| Web fonts | < 100KB total |
| TTFB | < 200ms (Vercel Edge) |
| LCP | < 1.5s (target, not just "good") |
| First Input Delay | < 100ms |
