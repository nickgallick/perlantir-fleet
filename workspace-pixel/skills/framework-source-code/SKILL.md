---
name: framework-source-code
description: Index of cloned design framework repos and how to reference them.
---

# Design Framework Source Code Index

## Repos
| Framework | Path | Use For |
|-----------|------|---------|
| Shadcn UI | repos/shadcn-ui | Component patterns, variants, styling |
| Radix Primitives | repos/radix-primitives | Accessible component architecture |
| Tailwind CSS | repos/tailwindcss | Utility classes, config, theme |
| Lucide Icons | repos/lucide | Available icons, naming conventions |
| Nativewind | repos/nativewind | Tailwind-to-RN translation |
| Recharts | repos/recharts | Chart component APIs and patterns |
| Stitch MCP | repos/stitch-mcp | Design tool CLI integration |

## Repos Using Web Fetch Fallback
- **React Native Paper** (rn-paper) — removed due to size (457MB). Fetch on demand from raw.githubusercontent.com/callstack/react-native-paper/main/...

## When to Reference Source
- Checking available Shadcn component variants: grep through the registry
- Verifying Radix accessibility props: read the primitive source
- Finding Tailwind default values: check the default config
- Checking Lucide icon availability: search the icons directory

## How to Search
```bash
# Find a Shadcn component
find repos/shadcn-ui -name "*.tsx" | xargs grep -l "ComponentName"

# Find Radix accessibility props
grep -r "aria-" repos/radix-primitives/packages/ --include="*.tsx" | head -20

# Find Tailwind defaults
cat repos/tailwindcss/stubs/config.full.js

# Find available Lucide icons
ls repos/lucide/icons/ | head -50
```

## Web Fetch Fallback
- Shadcn: raw.githubusercontent.com/shadcn-ui/ui/main/...
- Radix: raw.githubusercontent.com/radix-ui/primitives/main/...
- Tailwind: raw.githubusercontent.com/tailwindlabs/tailwindcss/master/...
- RN Paper: raw.githubusercontent.com/callstack/react-native-paper/main/...

## Changelog
- 2026-03-20: Initial index with 7 local repos + 1 web fetch fallback (rn-paper removed, 457MB)
