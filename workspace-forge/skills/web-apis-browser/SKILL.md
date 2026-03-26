---
name: web-apis-browser
description: Modern browser APIs for Arena — IntersectionObserver, Web Workers, Clipboard, Web Share, Performance APIs, Service Workers.
---

# Web APIs & Browser Patterns

## IntersectionObserver (Lazy Loading & Animations)

```ts
// Lazy load images, trigger animations on scroll, infinite scroll
function useIntersectionObserver(options?: IntersectionObserverInit) {
  const ref = useRef<HTMLElement>(null)
  const [isVisible, setIsVisible] = useState(false)
  
  useEffect(() => {
    const el = ref.current
    if (!el) return
    
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setIsVisible(true)
        observer.unobserve(el) // one-shot
      }
    }, { threshold: 0.1, ...options })
    
    observer.observe(el)
    return () => observer.disconnect()
  }, [])
  
  return { ref, isVisible }
}
```

**Review check:** Always `disconnect()` in cleanup. Always unobserve after trigger for one-shot animations.

## Web Workers (Heavy Computation Off Main Thread)

```ts
// Arena: parse large transcripts without blocking UI
const worker = new Worker(new URL('./transcript-parser.worker.ts', import.meta.url))

worker.postMessage({ transcript: largeTranscriptData })
worker.onmessage = (e) => {
  setEvents(e.data.events) // parsed on worker thread, no jank
}

// transcript-parser.worker.ts
self.onmessage = (e) => {
  const events = parseTranscript(e.data.transcript) // CPU-intensive
  self.postMessage({ events })
}
```

**When to use:** Transcript parsing, ELO batch calculation display, submission diff generation. **When NOT:** Simple state updates, DOM manipulation (workers can't access DOM).

## Clipboard API

```tsx
async function copyToClipboard(text: string) {
  try {
    await navigator.clipboard.writeText(text) // requires HTTPS + user gesture
    toast('Copied!')
  } catch {
    // Fallback for older browsers
    const textarea = document.createElement('textarea')
    textarea.value = text
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand('copy')
    document.body.removeChild(textarea)
    toast('Copied!')
  }
}

// Arena: "Share result" button copies challenge result URL
<button onClick={() => copyToClipboard(`https://agentarena.com/results/${id}`)}>
  Copy Link
</button>
```

## Web Share API

```tsx
async function shareResult(challenge: Challenge, placement: number) {
  const shareData = {
    title: `Agent Arena — ${challenge.title}`,
    text: `My agent placed #${placement}! 🏆`,
    url: `https://agentarena.com/results/${challenge.id}`,
  }
  
  if (navigator.share && navigator.canShare?.(shareData)) {
    await navigator.share(shareData) // native share sheet (mobile)
  } else {
    await copyToClipboard(shareData.url) // fallback: copy to clipboard
  }
}
```

## Performance APIs

```ts
// Measure specific operations
performance.mark('judge-start')
await judgeSubmissions()
performance.mark('judge-end')
performance.measure('judging', 'judge-start', 'judge-end')

// Detect long tasks (>50ms = potential jank)
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.duration > 100) {
      console.warn(`Long task: ${entry.duration}ms`, entry)
    }
  }
})
observer.observe({ type: 'longtask', buffered: true })

// Adaptive behavior based on connection
const conn = (navigator as any).connection
if (conn?.effectiveType === '2g' || conn?.saveData) {
  // Reduce data: skip spectator feed, lower image quality
}
```

## Service Workers (Offline Support)

Caching strategies:
| Strategy | When | Use For |
|----------|------|---------|
| Cache First | Offline support | Static assets, fonts, icons |
| Network First | Freshness critical | API data, leaderboards |
| Stale While Revalidate | Speed + eventual freshness | Challenge list, agent profiles |

**Note:** Not applicable in React Native. Use expo-updates and AsyncStorage for mobile offline support.

## Sources
- MDN Web APIs documentation
- web-vitals library (Performance APIs)
- Workbox (Google's Service Worker toolkit)

## Changelog
- 2026-03-21: Initial skill — web APIs and browser patterns
