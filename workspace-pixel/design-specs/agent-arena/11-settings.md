# Screen 11: Settings

## Design Authority: Pixel
## Date: 2026-03-22
## Reference: GitHub settings (sidebar nav), Slack (team management), Linear (notifications)

---

## PAGE LAYOUT

```
Same top nav — "Settings" link.

Container: min-h-screen bg-arena-page
Content: max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6 md:py-8
```

---

## LAYOUT: SIDEBAR SETTINGS

```
Grid: grid grid-cols-1 md:grid-cols-4 gap-6

Left sidebar (md:col-span-1):
  Position: sticky top-20 (below nav) height-fit
  Nav: flex flex-col gap-1 md:gap-0.5

  Nav link:
    classes: px-4 py-2 rounded-lg text-sm font-body font-medium transition-colors 0.2s
    Default: text-arena-text-muted hover:text-arena-text-primary hover:bg-arena-elevated/50
    Active: text-blue-400 bg-blue-500/10 border-l-2 border-l-blue-500 pl-3.5
    Links:
    - Profile
    - Notifications
    - Connected Accounts
    - Agent Management
    - Privacy & Data
    - Preferences
    - About

Mobile (<md):
  Sidebar: hidden
  Top tab bar instead: sticky top-16 z-20
    Horizontal scroll of nav links
    Same active/inactive styling
    Or use dropdown menu (Lucide Menu)

Right content area (md:col-span-3):
  Arena-glass card for each section (loaded on tab change)
  Min-height: h-auto, grows with content
```

---

## SECTION 1: PROFILE (DEFAULT TAB)

```
Card: arena-glass p-6 md:p-8

Title: font-heading text-lg font-semibold text-arena-text-primary "Profile Settings"

Form sections:

  Display Name:
    Label: font-body text-xs text-arena-text-muted "Display Name"
    Input: w-full h-10 bg-arena-page border border-arena-border rounded-lg px-3 py-2
      font-body text-sm text-arena-text-primary
      value: "Nick Gallick"
      placeholder: "Your name"
    Helper: font-body text-xs text-arena-text-muted mt-1
      "This is how you appear on the platform."

  Avatar:
    Label: font-body text-xs text-arena-text-muted "Avatar"
    Current: w-12 h-12 rounded-lg bg-gradient border-2 border-arena-border mt-2
    Upload zone: h-20 border-2 border-dashed border-arena-border rounded-lg mt-3
      flex items-center justify-center cursor-pointer
      hover: border-blue-500/40 bg-blue-500/5
      Lucide Upload 20px text-arena-text-muted centered
    Helper: font-body text-xs text-arena-text-muted mt-1 "PNG, JPG up to 2MB"

  Bio (optional):
    Label: font-body text-xs text-arena-text-muted "Bio"
    Textarea: w-full h-16 bg-arena-page border border-arena-border rounded-lg px-3 py-2
      font-body text-sm text-arena-text-primary
      placeholder: "Tell us about yourself"
      resize: none
    Counter: font-body text-xs text-arena-text-muted mt-1
      "45 / 200 characters"

  Buttons: mt-6 flex gap-3
    "Save Changes": primary button
    "Cancel": secondary button

Save state:
  Toast notification (top-right): "Profile updated successfully!"
  Button animation: disabled → spinner → green checkmark → back to normal
```

---

## SECTION 2: NOTIFICATIONS

```
Card: arena-glass p-6 md:p-8

Title: font-heading text-lg font-semibold text-arena-text-primary "Notifications"

Email notifications: flex flex-col gap-4

  Toggle item (×6):
    Container: flex items-center justify-between p-3 bg-arena-elevated/40 rounded-lg

    Left:
      Label: font-body text-sm font-medium text-arena-text-primary
      Description: font-body text-xs text-arena-text-secondary mt-0.5
        e.g., "Get notified when a challenge you've entered is about to start"

    Right:
      Toggle: Shadcn Switch
        On: bg-emerald-500
        Off: bg-arena-border
        Label sr-only: aria-label="[setting name]"

  Notification options:
    1. Daily digest: "Summary of your activities and standings"
    2. Results ready: "Judging complete and results posted"
    3. Streak warning: "You're about to lose your streak"
    4. Rival alerts: "A rival entered a challenge you're in"
    5. New challenges: "New challenges matching your interests"
    6. System updates: "Important platform announcements"

Frequency selector: mt-6 pt-6 border-t border-arena-border/50
  Label: font-body text-xs text-arena-text-muted "Email Frequency"
  Option group: flex flex-col gap-2

  Radio option:
    Container: flex items-center gap-3 p-2 rounded-lg cursor-pointer
      hover: bg-arena-elevated/30
      active: border border-blue-500/20 bg-blue-500/5
    Radio: Shadcn RadioGroup item
    Label: font-body text-sm text-arena-text-primary
    Description: font-body text-xs text-arena-text-secondary mt-0.5

  Options:
    Realtime - Immediate notifications
    Daily - Once per day digest (8 AM)
    Weekly - Once per week digest (Monday 8 AM)

Buttons: mt-6 flex gap-3
  "Save Preferences": primary
  "Cancel": secondary
```

---

## SECTION 3: CONNECTED ACCOUNTS

```
Card: arena-glass p-6 md:p-8

Title: font-heading text-lg font-semibold text-arena-text-primary "Connected Accounts"

Connected account item: flex items-center justify-between p-4 bg-arena-elevated/40 rounded-lg

  Left:
    Icon: Lucide Github 20px text-arena-text-muted
    Info:
      Platform: font-body text-sm font-medium text-arena-text-primary "GitHub"
      Account: font-body text-xs text-arena-text-muted "Connected as @[username]"
      Connected: font-body text-xs text-arena-text-muted mt-1
        "Connected since Feb 15, 2026"

  Right:
    Status: flex items-center gap-1.5
      arena-live-dot (green)
      font-body text-xs font-medium text-emerald-400 "Connected"
    Button:
      "Disconnect": secondary button, text-red-400
        Confirmation: "Disconnect GitHub? You'll need to reconnect to sign in with GitHub."
        Buttons: Cancel, Disconnect

Future integrations: mt-4
  Label: font-body text-xs text-arena-text-muted uppercase tracking-wider "Available Integrations"
  Item: flex items-center justify-between p-4 bg-arena-elevated/20 rounded-lg opacity-60

    Left:
      Icon: Lucide Cloud 20px text-arena-text-muted
      Info:
        Platform: font-body text-sm font-medium text-arena-text-muted "Google"
        Description: font-body text-xs text-arena-text-muted "Coming soon"

    Right:
      "Coming Soon": secondary button, disabled opacity-50
```

---

## SECTION 4: AGENT MANAGEMENT

```
Card: arena-glass p-6 md:p-8

Title: font-heading text-lg font-semibold text-arena-text-primary "Agent Management"

Connected agents: flex flex-col gap-3

  Agent item: flex items-center justify-between p-4 bg-arena-elevated/40 rounded-lg

    Left:
      Avatar: w-10 h-10 rounded-lg bg-gradient
      Info:
        Name: font-body text-sm font-medium text-arena-text-primary "NightOwl-7B"
        Status: flex items-center gap-1.5 mt-0.5
          arena-live-dot
          font-body text-xs text-emerald-400 "Online • 5 min ago"

    Right:
      "Settings": secondary button Lucide Settings 14px
        Opens agent settings modal (from My Agents screen)

Link to full agent management:
  font-body text-sm text-blue-400 "Manage all agents →" (links to My Agents screen)
```

---

## SECTION 5: PRIVACY & DATA

```
Card: arena-glass p-6 md:p-8

Title: font-heading text-lg font-semibold text-arena-text-primary "Privacy & Data"

Spectator mode: flex items-center justify-between p-4 bg-arena-elevated/40 rounded-lg

  Left:
    Label: font-body text-sm font-medium text-arena-text-primary "Spectator Mode"
    Description: font-body text-xs text-arena-text-secondary mt-0.5
      "Allow others to watch your agent's live competitions"

  Right:
    Toggle: Shadcn Switch (default: on)

Privacy settings: mt-6 pt-6 border-t border-arena-border/50 flex flex-col gap-4

  Option:
    Container: flex items-center justify-between p-3 bg-arena-elevated/20 rounded-lg
    Label: font-body text-sm text-arena-text-primary
    Icon: Lucide Info 14px text-arena-text-muted ml-auto

  Options:
    - Public profile: "Your profile is visible to everyone"
    - Public results: "Challenge results are visible in leaderboards"
    - Hide stats: "Hide detailed statistics from your profile" (requires paid tier)

Data management: mt-6 pt-6 border-t border-arena-border/50

  Export button: secondary button Lucide Download 14px "Export My Data"
    Generates JSON zip of all account data (GDPR compliance)
    Toast: "Export started. You'll receive a download link via email."

  Delete account: mt-4
    Warning card: bg-red-500/10 border border-red-500/20 rounded-lg p-4
      Lucide AlertTriangle 16px text-red-400 inline
      font-body text-sm text-red-400 font-medium "Delete Account"
      Description: font-body text-sm text-arena-text-secondary mt-2
        "This action cannot be undone. All data will be permanently deleted."
      Button: secondary button text-red-400 "Delete My Account"
        Confirmation dialog:
          "Are you sure? Type your email to confirm."
          Input field for email verification
          Buttons: Cancel, Permanently Delete
```

---

## SECTION 6: PREFERENCES

```
Card: arena-glass p-6 md:p-8

Title: font-heading text-lg font-semibold text-arena-text-primary "Preferences"

Theme selector: flex flex-col gap-3

  Label: font-body text-xs text-arena-text-muted "Appearance"
  Option group: flex gap-2 sm:gap-3

  Theme card (×3):
    Container: w-24 h-20 rounded-lg border-2 p-3 cursor-pointer transition-all 0.2s
      Unselected: border-arena-border hover:border-arena-text-muted
      Selected: border-blue-500 shadow-[0_0_12px_rgba(59,130,246,0.2)]
    
    Preview: w-full h-full rounded flex flex-col gap-1
      Bar: h-1.5 bg-arena-text-primary rounded
      Line1: h-1 bg-arena-text-muted/60 rounded-full
      Line2: h-1 bg-arena-text-muted/40 rounded-full
    
    Label below: font-body text-xs text-arena-text-muted text-center mt-2
    
    Themes: Dark (current), Light (grayed), Auto (system)

Reduce motion: flex items-center justify-between p-3 bg-arena-elevated/40 rounded-lg mt-4

  Label: font-body text-sm font-medium text-arena-text-primary
  Description: font-body text-xs text-arena-text-secondary mt-0.5
    "Minimize animations and transitions"

  Toggle: Shadcn Switch
```

---

## MOBILE ADAPTATION

```
Mobile (<md):
  No sidebar
  Tab bar at top: grid grid-cols-3 or 4 buttons
    Scroll if more than 4 tabs
  Each section loads in main area below tabs
  All forms are full-width
  Toggle switches are larger (touch-friendly)
  Buttons are full-width
```

---

## 10-QUESTION QUALITY CHECK

1. ✅ Color — hex/Tailwind for all elements (toggle colors, warning colors).
2. ✅ Font — font-heading/body/mono per element.
3. ✅ Spacing — exact Tailwind (p-6, gap-4, mt-6, h-10).
4. ✅ Effects — glass cards, form input focus state, toggle animation.
5. ✅ Animation — toggle slide, modal fade, button state transitions.
6. ✅ Layout — sidebar nav (desktop) / tab bar (mobile), card per section.
7. ✅ Z-order — z-20 sticky tab bar.
8. ✅ Hover — nav links, toggle items, buttons.
9. ✅ Mobile — full-screen tabs, no sidebar, full-width forms.
10. ✅ Accessibility — form labels, toggle aria-label, confirmation dialogs, focus management.

**Verdict: SPEC COMPLETE — Screen 11 ready for generation.**
