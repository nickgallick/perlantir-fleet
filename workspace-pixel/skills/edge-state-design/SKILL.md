# SKILL — Edge State Design

Pixel's edge state knowledge. A design that only works with perfect data is not a design — it's a mockup. Real designs handle every state.

---

## The 8 Edge States

### 1. Empty State
**When**: No data exists yet. First-time user, no results, empty list.

**Rules**:
- Never show a blank screen or just "No data"
- Include an illustration or icon (relevant, not generic)
- Explain what would be here ("No transactions yet")
- Provide a clear action ("Create your first transaction")
- The action should be the primary CTA — large, obvious
- If the emptiness is due to filters, say so ("No results match your filters") with a "Clear filters" action

**Examples**:
- Empty inbox: Illustration + "No messages yet. Start a conversation."
- Empty dashboard: Placeholder cards + "Add your first widget"
- No search results: "No results for '[query]'. Try different keywords."

### 2. Loading State
**When**: Data is being fetched, an action is processing, content is rendering.

**Rules**:
- Use skeleton screens for content that has a known structure (preferred over spinners)
- Use spinners for actions with unknown duration (submit buttons, global loading)
- Match skeleton shapes to the actual content layout
- Never show a blank screen while loading
- Show loading within 100ms if data isn't ready
- For operations > 2 seconds, add a text indicator ("Loading transactions...")
- For operations > 5 seconds, add a progress bar or percentage if possible
- Loading state should not cause layout shift when content arrives

**Skeleton Design**:
- Rounded rectangles matching text lines
- Circle/square for avatars
- Subtle pulse animation (respecting prefers-reduced-motion)
- Same padding and spacing as loaded state

### 3. Error State
**When**: Something went wrong. Network failure, server error, invalid data, timeout.

**Rules**:
- Clear message: What happened (not technical jargon)
- Actionable: What the user can do about it ("Try again", "Contact support")
- Scoped: Error affects only the relevant component, not the entire page
- Recoverable: Retry button that actually works
- Preserved: Don't lose user input on error — preserve form data
- Styled: Use semantic error colors (red/destructive) but don't alarm
- Never show raw error messages, stack traces, or error codes to users

**Error Levels**:
- **Inline**: Field-level validation errors
- **Component**: A single card/widget fails to load
- **Section**: Part of the page is unavailable
- **Page**: The entire page can't be loaded
- **Global**: The application can't connect at all

### 4. Single Item State
**When**: A list, table, or grid has exactly one item.

**Rules**:
- The layout should still look intentional with one item
- Grid: Single item shouldn't stretch full width (maintain card size)
- Table: One row shouldn't look broken
- List: One item should still have proper padding and structure
- May want to prompt for adding more ("Add another")

### 5. Many Items State
**When**: Hundreds or thousands of items.

**Rules**:
- Pagination or infinite scroll (with clear end indicator)
- Virtualized rendering for large lists (mention in spec for Maks)
- Show total count ("Showing 1-25 of 1,432")
- Provide filtering and search to narrow results
- Table columns should handle the volume (no layout break)
- Consider "load more" vs pagination vs infinite scroll based on context

### 6. Long Text Overflow
**When**: User-generated content, long names, long descriptions, URLs.

**Rules**:
- Truncate with ellipsis for single-line content (max-width + overflow: hidden + text-overflow: ellipsis)
- Line clamp for multi-line content (2-3 lines with "Read more")
- Test with extremely long strings (50+ character words, no spaces)
- Test with multiple languages (German words are long, CJK characters have different widths)
- URLs should not break layouts (word-break: break-all for URLs)
- Never let text overflow its container and overlap other elements
- Tables: Define min/max column widths

### 7. Offline State
**When**: Network connection is lost.

**Rules**:
- Show a subtle, persistent banner (not a blocking modal)
- Display cached content where possible
- Disable actions that require network (with clear disabled state)
- Queue actions for when connectivity returns (if applicable)
- Auto-reconnect and remove the banner when connectivity returns
- Don't show a full-screen error — the user may be browsing cached data

### 8. Permission Denied
**When**: User doesn't have access to this content or feature.

**Rules**:
- Don't show a raw 403 page
- Explain what they can't access and why ("You don't have admin access")
- Provide a path forward ("Request access" or "Contact your admin")
- If the page has mixed permissions, hide/disable inaccessible parts rather than blocking the entire page
- Don't reveal the existence of content they can't access (security)

---

## Edge State Checklist

For every screen design, verify:

```
## Edge State Checklist: [Screen Name]

- [ ] Empty state: Designed with illustration, message, and CTA
- [ ] Loading state: Skeleton or spinner, no layout shift
- [ ] Error state: Clear message, retry action, scoped impact
- [ ] Single item: Layout works with exactly one item
- [ ] Many items: Pagination/scroll, count shown, filter available
- [ ] Long text: Truncation defined, tested with long strings
- [ ] Offline: Banner shown, cached content displayed, actions disabled
- [ ] Permission denied: Clear message, action to request access
```

Every checkbox must be addressed. If a state doesn't apply (e.g., a settings page doesn't have a "many items" state), note it as N/A with reasoning.
