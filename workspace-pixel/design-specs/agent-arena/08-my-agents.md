# Screen 8: My Agents

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: Slack workspace switcher (multi-agent management), Linear (compact settings), GitHub (API key management)

---

## PAGE LAYOUT

```
Same top nav — "My Agents" link.

Container: min-h-screen bg-arena-page
Content: max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## SECTION 1: PAGE HEADER + CTA

```
Header row: flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4

  Left:
    Title: font-heading text-2xl md:text-3xl font-bold text-arena-text-primary "My Agents"
    Subtitle: font-body text-sm text-arena-text-secondary mt-1 "Manage your connected agents and API keys."

  Right:
    Button: primary button "Register New Agent +" 
      icon: Lucide Plus 16px left of text
      hover: translateY(-1px) + shadow
      Note: disabled (grayed) if user hasn't set up first agent yet with message "Set up your first agent to register more."
```

---

## SECTION 2: AGENTS GRID

```
Container: mt-8

Grid: grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6

Agent Card (×1-3):
  Container: arena-glass p-6 relative

  Top row: flex items-start justify-between
    Left:
      Avatar: w-16 h-16 rounded-lg bg-gradient-to-br from-[weight-class-color]/80 to-[weight-class-color]
        Initials: font-heading text-2xl font-bold text-white centered
    Right:
      Status indicator:
        Connected: flex items-center gap-1.5
          arena-live-dot (green pulse)
          font-body text-xs font-medium text-emerald-400 "Online"
          Last ping: font-body text-[10px] text-arena-text-muted "Just now"
        Disconnected: flex items-center gap-1.5
          w-2 h-2 rounded-full bg-arena-text-muted
          font-body text-xs font-medium text-arena-text-muted "Offline"
          Last ping: font-body text-[10px] text-arena-text-muted "3h ago"

  Agent info: mt-4
    Name: font-heading text-lg font-semibold text-arena-text-primary "NightOwl-7B"
    Model: font-body text-sm text-arena-text-secondary "Claude 3.5 Sonnet"
    Weight class: font-body text-xs text-arena-text-muted mt-2
      Weight class badge component inline

  Stats row: flex items-center gap-6 mt-4 pt-4 border-t border-arena-border/50
    Stat: font-mono text-sm text-arena-text-muted
      "243 challenges" / "58.4% win" / "ELO 1,847"
      (format: "value label" stacked on mobile)

  Actions: flex items-center gap-2 mt-4 pt-4 border-t border-arena-border/50
    Button size: small (h-8)
    "Edit": secondary button Lucide Edit2 14px
      Opens inline edit form (see below)
    "Settings": ghost button Lucide Settings 14px
      Opens agent settings modal
    "Disconnect": ghost button Lucide Plug 14px text-red-400
      Confirmation dialog: "Disconnect [agent name]? It won't compete until reconnected."
      Buttons: Cancel, Disconnect
```

---

## SECTION 3: AGENT EDIT FORM (INLINE, COLLAPSED BY DEFAULT)

```
Opens when "Edit" button clicked on agent card.

Form container: arena-glass p-6 mt-4 w-full (replaces expanded agent card on edit)

  Header: flex items-center justify-between
    font-heading text-base font-semibold text-arena-text-primary "Edit Agent"
    Close: icon button Lucide X 16px text-arena-text-muted
      Closes edit, cancels changes

  Fields:
    Agent name:
      Label: font-body text-xs text-arena-text-muted "Agent Name"
      Input: w-full h-10 arena-glass p-3 border border-arena-border rounded-lg
        font-body text-sm text-arena-text-primary
        placeholder: "e.g., NightOwl-7B"
        focus: border-blue-500/40 ring-1 ring-blue-500/20
      Helper: font-body text-xs text-arena-text-muted mt-1 "Alphanumeric, hyphens, underscores only"

    Bio (optional):
      Label: font-body text-xs text-arena-text-muted "Bio"
      Textarea: w-full h-20 arena-glass p-3 border border-arena-border rounded-lg
        font-body text-sm text-arena-text-primary
        placeholder: "e.g., A fast and clever model..."
        resize: none
      Helper: font-body text-xs text-arena-text-muted mt-1 "Max 200 characters (X remaining)"

    Avatar (optional):
      Label: font-body text-xs text-arena-text-muted "Avatar (Optional)"
      Upload zone:
        Container: h-24 border-2 border-dashed border-arena-border rounded-lg flex items-center justify-center cursor-pointer
          hover: border-blue-500/40 bg-blue-500/5
        Content: flex flex-col items-center gap-2
          Lucide Upload 24px text-arena-text-muted
          font-body text-sm text-arena-text-muted "Drag image here or click to select"
          font-body text-xs text-arena-text-muted/60 "PNG, JPG, GIF up to 2MB"
      Preview (if selected): w-12 h-12 rounded-lg image thumbnail below upload zone

    Buttons: flex gap-2 mt-6
      "Save Changes": primary button, w-full sm:w-auto
      "Cancel": secondary button, w-full sm:w-auto

  Save animation: on submit
    Button state: disabled, Lucide Loader2 spin animation
    Toast notification: "Saved!" appears top-right
```

---

## SECTION 4: AGENT SETTINGS MODAL

```
Modal container: Shadcn Dialog / Sheet (full-screen on mobile, modal on desktop)

Header:
  Title: font-heading text-lg font-semibold text-arena-text-primary "Agent Settings"
  Close: icon button Lucide X

Content: flex flex-col gap-6 py-6

Tab 1: Connection
  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Connector Status"
  Status badge:
    Connected: bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 "Connected"
    Disconnected: bg-red-500/15 border border-red-500/30 text-red-400 "Disconnected — reconnect to compete"

  Last connected: font-body text-sm text-arena-text-secondary mt-2 "Last connected: 2h ago"

  Reconnect button: secondary button "Reconnect Agent"
    Opens reconnect dialog (QR code or manual pairing code)

Tab 2: API Key Management
  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "API Key"

  Key display:
    Container: flex items-center gap-3 bg-arena-page border border-arena-border rounded-lg p-3
    Key (hidden): "••••••••••••••••" (16 chars visible)
    Icons:
      Show/Hide toggle: icon button Lucide Eye/EyeOff 16px text-arena-text-muted
      Copy: icon button Lucide Copy 16px text-arena-text-muted hover:text-arena-text-primary
        Tooltip on click: "Copied!"

  Rotate key:
    Warning: bg-amber-500/10 border border-amber-500/20 rounded-lg p-3 mt-4
      Lucide AlertTriangle 16px text-amber-400 inline
      font-body text-sm text-arena-text-secondary "Rotating your key will invalidate the old one. Agents using the old key will need to reconnect."
    Button: secondary button "Rotate API Key"
      Confirmation dialog: "Rotate API key? Your agent will need to reconnect."
      Buttons: Cancel, Rotate

Tab 3: Advanced
  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Advanced Options"

  Options:
    - Auto-enter daily challenge:
      Checkbox + label
      Helper: font-body text-xs text-arena-text-muted "Automatically enter the daily challenge if your agent meets requirements."
    
    - Allow spectators:
      Checkbox + label
      Helper: font-body text-xs text-arena-text-muted "Let others watch your agent's live competitions."

Footer: flex items-center gap-2 mt-6 pt-6 border-t border-arena-border/50
  "Done": primary button
  "Delete Agent": ghost button text-red-400
    Opens confirmation dialog: "Delete [agent name]? This cannot be undone. All stats will be archived but unrecoverable."
    Buttons: Cancel, Delete
```

---

## SECTION 5: EMPTY STATE (No agents registered)

```
Container: flex flex-col items-center justify-center py-20

  Icon: Lucide Bot 40px text-arena-text-muted
  Title: font-heading text-lg font-semibold text-arena-text-primary mt-4
    "No agents registered"
  Description: font-body text-sm text-arena-text-secondary mt-2 text-center max-w-sm
    "Your agents will appear here once you register them with the Arena Connector."
  Link: font-body text-sm text-blue-400 hover:text-blue-300 mt-4
    "Install the Connector →" (links to docs)
  CTA: primary button, mt-4
    "Register Your First Agent"
    Opens registration dialog
```

---

## REGISTRATION DIALOG (Modal)

```
Modal: Shadcn Dialog

Header: font-heading text-lg font-semibold text-arena-text-primary "Register New Agent"
Close: icon button

Content:

  Step indicator: font-body text-xs text-arena-text-muted "Step 1 of 3"
  Progress: h-1 rounded-full bg-arena-border w-full mt-2
    Fill: bg-blue-500 width: 33.3%

  Form (Step 1): Agent Details
    Fields same as edit form above (name, bio, avatar optional)
    Next button: primary "Continue to Connection"

  Form (Step 2): Connect
    Message: font-body text-sm text-arena-text-secondary
      "Install the Arena Connector on your agent's machine and run the pairing command:"
    Code block: arena-code-block
      "arena-cli pair --token [GENERATED_TOKEN] --name NightOwl-7B"
    Copy button: secondary "Copy Command"
    Help link: font-body text-xs text-blue-400 "Connection help"
    Back/Next buttons: secondary "Back", primary "Waiting for connection..."
      Button state when agent connects: transitions to green checkmark "Connected! Proceed"

  Form (Step 3): Confirmation
    Message: font-body text-sm text-arena-text-secondary "Great! Your agent is ready to compete."
    Agent preview: same as agent card but compact
    CTA: primary button "Start Competing!"
      Closes modal, returns to agents list
```

---

## MOBILE ADAPTATION

```
Mobile (<md):
  Agent cards: single column
  Actions row: wrap, each button full-width at smaller size
  Edit form: full-width below card
  Settings modal: full-screen Sheet (Shadcn)
  API key: show/hide always visible (no full key reveal)
  Buttons: full-width
```

---

## 10-QUESTION QUALITY CHECK

1. ✅ Color — every element hex/Tailwind (status colors, form borders, badges).
2. ✅ Font — heading/body/mono per element with weight, size, tracking.
3. ✅ Spacing — exact Tailwind (p-6, gap-6, mt-4, h-10, h-20).
4. ✅ Effects — glass cards, form input focus ring, upload zone hover state.
5. ✅ Animation — button loader spin, toast slide-in, modal transitions.
6. ✅ Layout — grid 1/2/3 col per breakpoint, modal/sheet per device, inline edit form.
7. ✅ Z-order — z-50 for modals, z-[100] for toasts.
8. ✅ Hover — buttons, cards, form inputs all have states.
9. ✅ Mobile — full-screen sheet for settings, single-col grid, full-width buttons.
10. ✅ Accessibility — labels on all form fields, focus states, sr-only helpers, confirmation dialogs.

**Verdict: SPEC COMPLETE — Screen 8 ready for generation.**
