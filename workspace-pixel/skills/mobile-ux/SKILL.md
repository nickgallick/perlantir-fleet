# SKILL — Mobile UX

Pixel's mobile design knowledge. Mobile is not a shrunk-down desktop — it's a fundamentally different context with different constraints and behaviors.

---

## iOS Human Interface Guidelines — Key Rules

### Navigation
- Use **UINavigationController** patterns (stack-based navigation with back buttons)
- **Tab Bar** at the bottom for top-level destinations (3-5 items)
- Large titles that shrink on scroll for primary views
- Swipe-from-left-edge for back navigation (never override this)
- Modals for focused, interruptive tasks (with clear dismiss)

### Visual Design
- System fonts (SF Pro) or high-quality custom fonts
- Vibrancy and materials (translucent backgrounds for depth)
- Safe area compliance (notch, Dynamic Island, home indicator)
- Rounded corners matching device hardware radius

### Interaction
- 44pt minimum touch targets
- Standard gestures (tap, long press, swipe, pinch)
- Haptic feedback for meaningful interactions
- Pull-to-refresh for refreshable lists
- Swipe actions on list items (delete, archive, etc.)

### Layout
- Full-width on phones
- Sidebar + content on iPad (UISplitViewController pattern)
- Sheet presentations (detents: medium, large) for supplementary content

---

## Navigation Patterns

### Tab Bar (Bottom Navigation)
**When**: Primary navigation between top-level sections
- 3–5 items maximum
- Icon + label for each tab
- Active tab: filled icon + brand color
- Inactive tab: outline icon + muted color
- Maintains state per tab (each tab has its own navigation stack)
- **This is the default navigation pattern.** Use it unless you have a specific reason not to.

### Stack Navigation
**When**: Drilling into detail from a list or category
- Back button in top-left
- Title centered (iOS) or left-aligned (Android/Material)
- Right side for contextual actions (edit, share, more)
- Swipe-from-left-edge to go back (iOS)
- Deep stacks (4+ levels) suggest the information architecture needs rethinking

### Modal
**When**: Focused tasks that interrupt the main flow
- Appears from bottom (iOS sheet) or center (dialog)
- Clear dismiss action (X button top-left, or swipe down)
- Should be completable without navigating away
- Use sparingly — modals are interruptive
- Full-screen modals for complex tasks (forms, editors)

### Bottom Sheet
**When**: Contextual actions or supplementary content
- Slides up from bottom
- Detents: peek (compact), half, full
- Swipe down to dismiss
- Great for filters, options, detail previews
- Should not contain complex navigation (that's a modal)

### NEVER: Hamburger Menu
**Do not use hamburger menus (☰).** They hide navigation, reduce discoverability, and create extra taps. Research consistently shows lower engagement with hamburger menus. Use a tab bar instead.

If you have more than 5 top-level sections, reconsider your information architecture. Most apps don't actually need more than 5.

---

## Gesture Design

### Standard Gestures (Never Override)
| Gesture | Standard Behavior |
|---------|-------------------|
| Tap | Select, activate |
| Long press | Context menu, reorder |
| Swipe left/right | List actions (delete, archive) |
| Swipe from left edge | Navigate back (iOS) |
| Pull down | Refresh content |
| Pinch | Zoom (maps, images) |
| Two-finger scroll | Scroll within scroll (avoid this scenario) |

### Gesture Design Rules
1. **Gestures must be discoverable** — Never make gesture the ONLY way to perform an action. Always provide a visible button alternative.
2. **Gestures must be forgiving** — Accidental swipes should be reversible (undo).
3. **Gestures should feel physical** — The UI should follow the finger, not jump.
4. **Standard gestures first** — Only invent custom gestures if standard ones don't fit.
5. **Provide feedback** — Haptic, visual, or both when a gesture triggers an action.

---

## Mobile-Specific Concerns

### Performance Perception
- Skeleton screens > spinners (feels faster)
- Optimistic updates for actions (show success immediately, rollback on failure)
- Lazy load content below the fold
- Cache previously loaded data
- Progressive loading for images

### Thumb-Friendly Design
```
┌─────────────────────┐
│  ❌ Hard to reach   │
│                     │
│  ⚠️ OK zone        │
│                     │
│  ✅ Easy zone       │
│  ┌─────────────┐   │
│  │  Primary CTA │   │
│  └─────────────┘   │
│  [Tab] [Tab] [Tab]  │
└─────────────────────┘
```
- Primary actions at the bottom
- Navigation at the bottom
- Settings, less-used actions at the top
- Bottom sheets for actions, not top dropdowns

### Keyboard Handling
- Inputs should not be obscured by keyboard
- Scroll content up when keyboard appears
- Appropriate keyboard type per input (email, number, phone, URL)
- Return key action matches form flow (Next → Next → Done)
- Dismiss keyboard on tap outside

### Offline Behavior
- Show cached content when offline
- Queue actions for when connectivity returns
- Clear offline indicator (subtle banner, not blocking modal)
- Never show an error screen for expected offline use

---

## Common Mobile Mistakes

1. **Desktop patterns on mobile** — Hover states, right-click menus, tooltips don't work on touch.
2. **Too much content per screen** — Mobile is sequential. Show less, let users drill in.
3. **Small touch targets** — Anything under 44px will cause tap errors and frustration.
4. **Hamburger menus** — Hidden navigation = unused navigation. Use tab bars.
5. **No loading states** — Mobile networks are slow. Every async operation needs a loading state.
6. **Fixed position everything** — Fixed headers + fixed tab bars + fixed CTAs = no room for content.
7. **Ignoring safe areas** — Content behind notches and home indicators looks broken.
8. **Horizontal scrolling** — Almost never appropriate on mobile (except carousels with clear affordance).
9. **Complex forms on one screen** — Break long forms into steps/pages. One concept per screen.
10. **No empty states** — First-time users see empty screens with no guidance. Always design the empty state.
