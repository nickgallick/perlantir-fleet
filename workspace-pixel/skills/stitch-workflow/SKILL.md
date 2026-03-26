---
name: stitch-workflow
description: Google Stitch MCP workflow for generating, editing, and managing design screens. Use for all Stitch operations — creating projects, generating screens, editing screens, verifying outputs. Documents known API quirks and the full generation pipeline.
---

# Stitch MCP Workflow

## Tool
All Stitch operations use `mcporter call stitch.<method>`. Stitch is a Google design tool accessed via MCP (Model Context Protocol).

## Known API Quirks

### ⚠️ list_screens Returns Empty
`stitch.list_screens` frequently returns `{}` even when screens exist in a project. This is a known bug.

**Workaround:** Always verify screens using `stitch.get_screen` with the specific `screenId` returned from generation. Never rely on `list_screens` to confirm screen existence.

### ⚠️ Timeout Risk
Screen generation can take 60-300 seconds. Always set:
```bash
MCPORTER_CALL_TIMEOUT=300000  # 5 minutes
```

### ⚠️ Design System Drift
Each `generate_screen_from_text` call may auto-generate a new `designMd` document with a different creative name and slightly different tokens. The visual output stays consistent (same base colors, fonts), but the embedded documentation drifts.

**Mitigation:** Include your canonical design system name and key tokens in every prompt. Verify the `displayName` field in the response matches.

## Available Models

| Model ID | Speed | Quality | Use When |
|----------|-------|---------|----------|
| `GEMINI_3_PRO` | Slow (~4min) | Highest | Hero screens, landing pages, complex layouts |
| `GEMINI_3_1_PRO` | Slow (~4min) | Highest (latest) | Same as above, newer model |
| `GEMINI_3_FLASH` | Fast (~2min) | Good | Secondary screens, iteration, avoiding timeouts |

**Default recommendation:** Use `GEMINI_3_FLASH` for most screens. Use `GEMINI_3_PRO` or `GEMINI_3_1_PRO` for landing pages and hero screens where visual quality is paramount.

## Device Types

| Device Type | Resolution | Use |
|-------------|-----------|-----|
| `DESKTOP` | 2560px wide | Primary — generate this first for every screen |
| `MOBILE` | 390px wide | Secondary — generate after desktop is approved |
| `TABLET` | 1024px wide | Optional — only if tablet-specific layout exists |

## Full Workflow

### Step 1: Create Project
```bash
mcporter call stitch.create_project \
  title="[Project Name]" \
  --output json
```
Response includes `projectId` — save this. One project per product.

### Step 2: Generate Design System Screen (Batch 0)
Generate a foundational screen that establishes the design system:
```bash
MCPORTER_CALL_TIMEOUT=300000 mcporter call stitch.generate_screen_from_text \
  projectId="[PROJECT_ID]" \
  modelId=GEMINI_3_FLASH \
  deviceType=DESKTOP \
  prompt='[Design system foundation prompt with exact colors, fonts, spacing, effects]' \
  --output json
```

### Step 3: Generate Each Screen
For each screen in the project:
```bash
MCPORTER_CALL_TIMEOUT=300000 mcporter call stitch.generate_screen_from_text \
  projectId="[PROJECT_ID]" \
  modelId=GEMINI_3_FLASH \
  deviceType=DESKTOP \
  prompt='Screen: [Project] — [Screen Name]

Design system: [CANONICAL NAME]. [Key tokens: bg color, fonts, border treatment].

[Detailed layout description with exact content, hierarchy, and styling.]' \
  --output json
```

**Response contains:**
- `id` — the screen ID (SAVE THIS)
- `screenshot.downloadUrl` — preview image URL
- `htmlCode.downloadUrl` — HTML/CSS download URL
- `title` — screen title
- `width`, `height` — dimensions
- `theme` — applied design system tokens

### Step 4: Verify Each Screen
After generation, verify the screen persists:
```bash
MCPORTER_CALL_TIMEOUT=60000 mcporter call stitch.get_screen \
  projectId="[PROJECT_ID]" \
  screenId="[SCREEN_ID]" \
  --output json
```
Check: `title`, `width`, `height`, `screenshot.downloadUrl` all present. If this returns data, the screen exists.

**Do NOT rely on `list_screens` for verification.** Use `get_screen` with the specific ID.

### Step 5: Visual Review
Download and review the screenshot:
```bash
# Use the image tool to review the screenshot URL
image(url=screenshot.downloadUrl, prompt="Review against design spec...")
```

Check against the 10-point review protocol:
1. Visual hierarchy clear?
2. Layout/spacing correct?
3. Typography matches spec?
4. Colors correct?
5. Components consistent?
6. Interactive elements obvious?
7. Edge states handled?
8. Accessibility baseline met?
9. Would confused users understand it?
10. Brand consistency maintained?

### Step 6: Iterate with edit_screens
If changes are needed:
```bash
MCPORTER_CALL_TIMEOUT=300000 mcporter call stitch.edit_screens \
  projectId="[PROJECT_ID]" \
  screenId="[SCREEN_ID]" \
  prompt='[Specific changes: "Move the CTA button above the fold. Change the nav background to #141B2D. Increase heading size to 4xl."]' \
  --output json
```

Be specific. Vague edits ("make it better") produce unpredictable results. State exactly what to change and what the target values are.

### Step 7: Pull Final Assets
For each approved screen, the handoff assets are:
- **Screenshot:** `screenshot.downloadUrl` (PNG preview)
- **HTML/CSS:** `htmlCode.downloadUrl` (full HTML file with inline CSS)
- **Screen metadata:** title, dimensions, device type

## Prompt Engineering for Stitch

### What Works
- Exact hex colors: `#0A1628` not "dark navy"
- Specific font sizes: `Space Grotesk 3xl bold` not "large heading"
- Layout structure: `3-column grid, left 8 cols, right 4 cols`
- Content text: Include actual copy, not "lorem ipsum"
- Reference patterns: "chess.com density", "F1 live timing feel"
- Component descriptions: "glass card with 15% opacity ghost border"

### What Doesn't Work
- Vague descriptions: "make it look premium" (too subjective)
- Animation descriptions: Stitch generates static screens — describe the resting state
- Overly long prompts: Keep under ~2000 chars for best results. Stitch has its own interpretation layer.
- Expecting pixel-perfect spec matching: Stitch interprets creatively. Use `edit_screens` to refine.

### Prompt Template
```
Screen: [Project] — [Screen Name]

[CANONICAL DESIGN SYSTEM NAME]: [1-line summary of aesthetic].
Colors: bg [hex], surface [hex], accent [hex].
Fonts: [heading font] headings, [body font] body, [mono font] data.
Borders: [treatment, e.g., "ghost only, 15% opacity"].

LAYOUT ([constraint, e.g., "max-w-6xl centered"]):

1. [SECTION NAME] ([container type]):
   - [Element]: [exact description with values]
   - [Element]: [exact description with values]

2. [SECTION NAME] ([container type]):
   - [Element]: [exact description]

[Overall feel reference]: "[Reference site] meets [reference site]".
```

## Project Management Integration

After each screen generation:
1. Save the screen ID to the progress tracker (see design-project-management skill)
2. Verify with `get_screen`
3. Review screenshot
4. Update tracker status
5. Every 3 screens: send progress update to Nick

## Stitch Budget
- Standard: 350 generations/month
- Experimental: 50 generations/month
- Track usage in `research-logs/stitch-usage.md`
- Each `generate_screen_from_text` = 1 generation
- Each `edit_screens` = 1 generation
- Plan iterations accordingly — budget ~2 generations per screen (initial + 1 edit)
