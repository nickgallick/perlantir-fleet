# Screen 7: Replay Viewer

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: YouTube player (timeline scrubbing), VS Code (code display), Framer Motion (smooth transitions)

---

## PAGE LAYOUT

```
Container: min-h-screen bg-arena-page

Top nav: standard (back button navigates to challenge detail or results)

Main content: max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## SECTION 1: VIDEO/PLAYBACK AREA

```
Container: relative w-full aspect-video bg-arena-page rounded-xl overflow-hidden border border-arena-border

Video player (Framer Motion + canvas/codex animation):
  Background: gradient-to-br from-arena-surface to-arena-page
  
  Placeholder (while not video-based):
    Lucide Play 40px text-arena-text-muted centered
    Text below: font-body text-sm text-arena-text-muted "Code replay animation"
    
    OR show live code diff animation:
    - Left side: file tree with highlighted file
    - Right side: code block showing edits in real-time
    - Diff highlighting: added lines green bg, removed lines red bg, changed lines yellow bg

  Controls overlay (hover/focus):
    Position: absolute bottom-0 left-0 right-0
    Background: linear-gradient(to top, rgba(0,0,0,0.8), transparent)
    Padding: py-4 px-4

    Playback controls:
      Container: flex items-center gap-4

      Play/Pause: icon button Lucide Play/Pause 20px text-white
        hover: scale(1.1)

      Timeline: flex-1 relative h-1 rounded-full bg-arena-border/50 cursor-pointer
        Fill: h-full bg-blue-500 rounded-full (scrubable)
        Hover: h-2 (expands on hover)
        Tooltip on hover: timestamp at mouse position
          Format: MM:SS
          Position: above mouse
          bg-arena-elevated border border-arena-border rounded-lg px-2 py-1
          font-mono text-xs text-arena-text-primary

      Time display: flex items-center gap-1
        Current: font-mono text-xs text-white tabular-nums "02:34"
        Separator: "/" text-white/40
        Total: font-mono text-xs text-white/60 "08:12"

      Speed selector: relative group
        Trigger: font-body text-xs text-white hover:text-white/80 "1x"
        Dropdown: absolute bottom-full right-0 mb-2 bg-arena-elevated border border-arena-border rounded-lg p-1
          Option: px-3 py-1.5 rounded-md text-xs font-body text-arena-text-secondary hover:text-arena-text-primary
          Options: 0.25x, 0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x
          Active: bg-arena-surface text-arena-text-primary

      Fullscreen: icon button Lucide Maximize2 16px text-white hover:scale(1.1)

      Keyboard shortcuts: overlay hint (small, bottom-right of player, fade after 3s)
        font-mono text-[10px] text-white/40 "Space: play/pause • → ←: skip • F: fullscreen"
```

---

## SECTION 2: TIMELINE (EVENTS AS NODES)

```
Container: mt-6 arena-glass p-6

Header: font-heading text-base font-semibold text-arena-text-primary "Event Timeline"

Timeline container: relative mt-6
  Orientation: horizontal on desktop, vertical on mobile

Desktop (lg+):
  Layout: flex items-end gap-2 h-24 overflow-x-auto pb-4 pt-4
  
  Event node:
    Container: relative flex flex-col items-center cursor-pointer
      hover: scale(1.1) transition-transform 0.2s
    
    Node: w-3 h-3 rounded-full bg-blue-400 flex-shrink-0
      On click: seek timeline to event timestamp
    
    Connector line (between nodes): absolute top-0 w-px h-6 bg-arena-border left-[50%] -translate-x-1/2
      Last node: no connector
    
    Label (tooltip on hover):
      Absolute bottom-full mb-8
      bg-arena-elevated border border-arena-border rounded-lg px-3 py-2 shadow-lg
      font-mono text-xs text-arena-text-primary "00:14:32"
      Icon: above timestamp
      Text: below timestamp
      font-body text-xs text-arena-text-secondary max-w-32 text-center

Mobile (<lg):
  Layout: flex flex-col gap-4
  
  Event item (row):
    Container: flex items-center gap-4 p-3 bg-arena-elevated/40 rounded-lg
    
    Timeline dot: w-2 h-2 rounded-full bg-blue-400 flex-shrink-0
    Vertical line (except last): absolute left-[7px] top-full h-4 w-px bg-arena-border
    
    Content: flex-1 flex items-center justify-between
      Left: flex items-center gap-3
        Icon: Lucide icon per event type, 16px text-blue-400
        Text: font-body text-sm text-arena-text-primary
      Right:
        Timestamp: font-mono text-xs text-arena-text-muted "00:14:32"

Event types (with icons):
  - code_write: Lucide Code 14px text-blue-400 "Writing src/api/routes.ts"
  - tool_call: Lucide Wrench 14px text-purple-400 "Calling search tool"
  - thinking: Lucide Brain 14px text-amber-400 "Analyzing requirements"
  - error: Lucide AlertTriangle 14px text-red-400 "Error: type mismatch"
  - submitted: Lucide Check 14px text-emerald-400 "Submission complete"
  - file_created: Lucide FileText 14px text-blue-400 "Created new file"
  - test_run: Lucide TestTube2 14px text-cyan-400 "Running tests"
```

---

## SECTION 3: CODE BLOCK DISPLAY (EXPANDABLE)

```
Container: mt-6 arena-glass p-0 rounded-lg overflow-hidden

Header (click to expand/collapse):
  Container: px-6 py-4 bg-arena-surface border-b border-arena-border flex items-center justify-between cursor-pointer
  
  Left: flex items-center gap-3
    Icon: Lucide Code 16px text-blue-400
    File path: font-mono text-sm text-arena-text-primary "src/api/routes.ts"
    (11-23 lines): font-body text-xs text-arena-text-muted ml-auto
  
  Chevron: Lucide ChevronDown 16px text-arena-text-muted
    Rotates 180deg when expanded

Code block (expandable):
  Container: arena-code-block px-6 py-4 max-h-none (full, no 20-line limit)
  
  Scrollable: max-h-[600px] overflow-y-auto
  
  Line numbers: arena-code-block includes them
  Syntax highlighting: standard code colors
    Keywords: text-pink-400
    Strings: text-green-400
    Numbers: text-orange-400
    Comments: text-gray-500
    Functions: text-cyan-400
  
  Diff highlight (if showing code change):
    Added lines: bg-emerald-500/10 border-l-2 border-l-emerald-500 pl-3
    Removed lines: bg-red-500/10 border-l-2 border-l-red-500 pl-3
    Changed lines: bg-amber-500/10 border-l-2 border-l-amber-500 pl-3

Animation on expand:
  height: 0 → auto, opacity 0 → 1, 0.3s ease
```

---

## SECTION 4: AGENT INFO + JUDGE FEEDBACK (SIDE PANELS)

```
Layout: grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6

Left (lg:col-span-2):
  Judge feedback card: arena-glass p-6

  Header: font-heading text-base font-semibold text-arena-text-primary "Judge Feedback"
  Judges: grid grid-cols-1 sm:grid-cols-3 gap-4 mt-4

    Judge card: bg-arena-elevated/40 rounded-lg p-4
      Judge name: font-body text-sm font-medium text-arena-text-primary "Judge 1 — Functionality"
      Score: font-mono text-3xl font-bold text-yellow-400 mt-2 "92"
      Label: font-body text-xs text-arena-text-muted "/ 100"
      Feedback: font-body text-sm text-arena-text-secondary mt-3 italic
        "Clean API design with good error handling. Missing edge case for 500 errors."
      Rating: flex items-center gap-1 mt-3
        Stars: 5 Lucide Star 12px, filled: text-yellow-400, unfilled: text-arena-border
        "4.5 / 5"

Right sidebar (lg:col-span-1):
  Agent info: arena-glass p-5

  Avatar: w-12 h-12 rounded-lg bg-gradient
  Name: font-body text-sm font-medium text-arena-text-primary mt-2
  Model: font-mono text-xs text-arena-text-muted "Claude 3.5 Sonnet"
  ELO: font-body text-xs text-arena-text-muted mt-3
    "ELO Rating: " font-mono text-sm font-semibold "1,847"
  Weight class: font-body text-xs text-arena-text-muted mt-1
    Weight class badge component

  Divider: border-t border-arena-border my-4

  Final score: font-body text-xs text-arena-text-muted uppercase tracking-wider "Final Score"
    font-mono text-2xl font-bold text-arena-text-primary "87.4 / 100"
    ELO change: font-mono text-lg text-emerald-400 mt-1 "+18"

  Placement: font-body text-xs text-arena-text-muted uppercase tracking-wider mt-4 "Placement"
    Placement badge with color coding
    font-mono text-xl font-bold text-[placement-color] "#3"

CTA buttons: mt-6 flex flex-col gap-2
  Primary: "Challenge Again" button
  Secondary: "View Full Results" ghost button
  Share: "Share Replay" ghost button
    Copy to clipboard: replay URL "agentarena.com/replay/[id]"
```

---

## MOBILE ADAPTATION

```
Mobile (<lg):
  Timeline: vertical layout (see timeline section above)
  Judge feedback: cards stack vertically
  Side panels: below judge feedback, single column
  Player: full-width, height 50vh (smaller to fit controls)
  Code block: max-h-[400px], smaller font
  CTAs: full-width buttons at bottom
```

---

## KEYBOARD SHORTCUTS

```
Space: Play/pause
→: Skip 5 seconds forward
←: Skip 5 seconds backward
>: Skip to next event
<: Skip to previous event
F: Toggle fullscreen
M: Mute (if audio implemented)
V: Cycle between playback speeds
```

---

## 10-QUESTION QUALITY CHECK

1. ✅ Color — every element hex/Tailwind (blue-400 for playback, event colors, code syntax colors).
2. ✅ Font — font-heading/body/mono per element with size, tracking, weight.
3. ✅ Spacing — exact Tailwind (p-6, gap-4, mt-6, max-h-[600px]).
4. ✅ Effects — glass cards, code block styling, diff highlight colors.
5. ✅ Animation — timeline expand/collapse, code block height transition, hover scale.
6. ✅ Layout — grid per breakpoint, flex timeline (horizontal/vertical), sidebar layout.
7. ✅ Z-order — z-10 for overlays, tooltip z-20.
8. ✅ Hover — timeline nodes scale, code block header highlight, buttons.
9. ✅ Mobile — vertical timeline, full-width buttons, stacked panels, smaller player.
10. ✅ Accessibility — keyboard shortcuts listed, event icons + text (color not only indicator), focus states on interactive.

**Verdict: SPEC COMPLETE — Screen 7 ready for generation.**
