# SKILL — Component Architecture

Pixel's component design knowledge. Components are the building blocks of every interface — they must be well-defined, consistent, and account for all states.

---

## Atomic Design Levels

### Tokens (Sub-atomic)
Design tokens: colors, spacing, typography, radii, shadows. These are the raw values that feed into everything else. Defined in the design-system skill.

### Atoms
The smallest UI elements that can't be broken down further:
- Button
- Input field
- Label
- Icon
- Badge
- Avatar
- Checkbox
- Radio button
- Toggle
- Tooltip
- Divider
- Skeleton loader

### Molecules
Combinations of atoms that form a functional unit:
- Search bar (input + icon + button)
- Form field (label + input + error message)
- Menu item (icon + text + badge)
- Stat card (label + value + trend icon)
- Breadcrumb (links + separators)
- Pagination (buttons + page numbers)

### Organisms
Complex components made of molecules and atoms:
- Navigation bar (logo + menu items + actions)
- Form (multiple form fields + submit)
- Data table (header + rows + pagination)
- Card with header, content, and actions
- Modal dialog (header + content + actions)
- Sidebar navigation (logo + menu groups + footer)

### Templates
Page-level layouts that define structure:
- Dashboard layout (sidebar + header + content area)
- Auth layout (centered card + background)
- Settings layout (sidebar nav + content panel)
- Detail layout (header + content + sidebar)

### Pages
Templates populated with real content and data, representing actual screens in the application.

---

## Every Component Needs These States

No component design is complete without defining ALL of these states:

### Default
The resting, neutral state. This is what the user sees when nothing is happening.
- Must be clearly identifiable as interactive (if interactive)
- Must communicate the component's purpose

### Hover
Visual feedback when the cursor is over the component (desktop only).
- Subtle change: slight background shift, underline, shadow
- Must not significantly change the component's size or layout
- Cursor should change to pointer for clickable elements

### Active / Pressed
Visual feedback during the click/tap interaction.
- Deeper change than hover: darker background, scale down slightly
- Provides physical feel of pressing
- Duration: as long as the user holds down

### Focus
Keyboard/accessibility focus indicator.
- **Required for ALL interactive elements**
- 2px outline with 2px offset in brand color (or high-contrast color)
- Must be visible against any background
- Never use `outline: none` without a replacement

### Disabled
The component cannot be interacted with.
- Reduced opacity (0.5) or muted colors
- `cursor: not-allowed` on desktop
- No hover/active effects
- Must still be visible (not hidden)
- Should convey WHY it's disabled (tooltip or adjacent text)

### Loading
The component is processing or waiting for data.
- Spinner icon replaces content (maintain component dimensions)
- Or skeleton placeholder for content-heavy components
- Disable interaction during loading
- Must not cause layout shift

### Error
The component has an error state (especially inputs).
- Red/destructive border color
- Error icon (optional)
- Error message below component
- Must clearly communicate what's wrong and how to fix it

---

## Component Specification Format

When specifying a component for handoff:

```
## Component: [Name]

### Purpose
What this component is for and when to use it.

### Anatomy
- [Part 1]: [description]
- [Part 2]: [description]
- [Part N]: [description]

### Variants
| Variant | Usage |
|---------|-------|
| [name] | [when to use] |

### Sizes
| Size | Dimensions | Font | Padding |
|------|-----------|------|---------|
| [name] | [h × w] | [size] | [values] |

### States
| State | Visual Changes |
|-------|---------------|
| Default | [description] |
| Hover | [description] |
| Active | [description] |
| Focus | [description] |
| Disabled | [description] |
| Loading | [description] |
| Error | [description] |

### Design Tokens Used
- Background: [token]
- Text: [token]
- Border: [token]
- Spacing: [token]

### Accessibility
- Role: [ARIA role]
- Label: [how it's labeled]
- Keyboard: [keyboard interactions]

### Usage Rules
- [Rule 1]
- [Rule 2]
```

---

## Shadcn UI Reference Components

Our web stack uses shadcn/ui. These components are available and should be used consistently:

### Layout
- `Card` — Container with header, content, footer
- `Separator` — Visual divider
- `Sheet` — Slide-out panel
- `ScrollArea` — Custom scrollbar container

### Forms
- `Button` — All button variants
- `Input` — Text input
- `Textarea` — Multi-line input
- `Select` — Dropdown selection
- `Checkbox` — Boolean toggle
- `RadioGroup` — Single selection from options
- `Switch` — Toggle
- `Slider` — Range input
- `Form` — Form validation wrapper (react-hook-form)

### Data Display
- `Table` — Data tables
- `Badge` — Status/category indicators
- `Avatar` — User/entity images
- `Calendar` — Date selection
- `Chart` — Data visualization (via Recharts)

### Feedback
- `Alert` — Inline messages
- `AlertDialog` — Confirmation dialogs
- `Toast` / `Sonner` — Notification toasts
- `Progress` — Progress bars
- `Skeleton` — Loading placeholders
- `Tooltip` — Hover information

### Navigation
- `NavigationMenu` — Top navigation
- `Tabs` — Tab switching
- `Breadcrumb` — Path navigation
- `Pagination` — Page navigation
- `Command` — Command palette
- `DropdownMenu` — Action menus
- `ContextMenu` — Right-click menus
- `Menubar` — Menu bar

### Overlay
- `Dialog` — Modal dialogs
- `Popover` — Floating content
- `HoverCard` — Rich hover preview

---

## Mobile Component Patterns

For React Native with React Native Paper:

### Available Components
- `Appbar` — Top app bar with actions
- `BottomNavigation` — Tab bar
- `Button` — All button modes
- `Card` — Content container
- `Chip` — Filter/selection chips
- `Dialog` — Modal dialogs
- `Divider` — Separator
- `FAB` — Floating action button
- `List` — List items with icons, descriptions
- `Menu` — Popup menu
- `Searchbar` — Search input
- `Snackbar` — Toast messages
- `Surface` — Elevated surface
- `TextInput` — Form inputs with modes (flat, outlined)

### Mobile-Specific Rules
- Bottom sheets for contextual actions (not modals)
- FAB for single primary action on a screen
- Swipe actions on list items (with caution — discoverable?)
- Pull-to-refresh for refreshable content
- Haptic feedback for significant actions
