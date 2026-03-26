# SKILL — Confusion Testing

Pixel's confusion testing methodology. Every design must be tested against 5 confused user personas to ensure clarity.

---

## The 5 Confused User Personas

### 1. The First-Timer
**Who**: Someone using this application for the very first time. No prior context, no tutorial, no onboarding completed.

**Their mindset**: "I just opened this app. I have no idea what it does or how it works. I need to figure out what's going on."

**Questions they ask**:
- What is this screen for? Can I tell within 5 seconds?
- Where do I start? Is there a clear first action?
- What do the icons mean? Would I understand them without labels?
- Is there help available if I'm lost?
- Do I understand the navigation? Can I find other sections?
- If I make a mistake, can I undo it? Is that obvious?
- Are there any terms or jargon I wouldn't understand?

### 2. The Rusher
**Who**: Someone in a hurry who wants to complete their task as fast as possible. Impatient. Scanning, not reading.

**Their mindset**: "I need to do [thing] right now. Don't make me think. Don't make me wait."

**Questions they ask**:
- Can I find the primary action without reading any text?
- How many taps/clicks to complete my task? Can it be fewer?
- Is there anything loading that doesn't show progress?
- Can I skip optional fields and steps?
- Are error messages clear enough to fix instantly?
- Is the CTA button visible without scrolling?
- Does the interface let me tab through a form quickly?

### 3. The Non-Technical User
**Who**: Someone who is not comfortable with technology. Uses their phone for calls and messages, maybe Facebook. Not familiar with app conventions.

**Their mindset**: "I don't really understand this technology stuff. Please don't make me feel stupid."

**Questions they ask**:
- Are there any icons without labels? Would I know what they mean?
- Is the language simple and jargon-free?
- Are interactive elements obviously tappable/clickable?
- Is the text big enough to read comfortably?
- Would I know what a "toggle" or "dropdown" does?
- Are confirmations clear? ("Are you sure?" doesn't tell me what happens.)
- Would I accidentally trigger something I don't understand?

### 4. The Anxious User
**Who**: Someone worried about making mistakes, losing data, or doing something irreversible. Cautious and careful.

**Their mindset**: "What if I tap the wrong thing? What if I lose my work? What if I can't go back?"

**Questions they ask**:
- Can I tell which actions are reversible and which are permanent?
- Is there a confirmation step before destructive actions (delete, send, submit)?
- Can I save my progress and come back later?
- Is my data being saved? Is that communicated?
- What happens if I navigate away — will I lose what I entered?
- Are there clear back/cancel options on every screen?
- Does the design communicate safety and trust?

### 5. The Accessibility User
**Who**: Someone using assistive technology — screen reader, keyboard-only navigation, high contrast mode, or with visual/motor impairments.

**Their mindset**: "I need this interface to work with my tools and accommodate my needs."

**Questions they ask**:
- Can I navigate this entire screen with only a keyboard?
- Does every interactive element have a text label (visible or aria)?
- Is the focus order logical? Can I tell where focus is?
- Do images have alt text? Do icons have labels?
- Is there sufficient color contrast for all text?
- Are form errors announced by screen readers?
- Can I zoom to 200% without breaking the layout?
- Is information conveyed by color also conveyed by text/icon?

---

## How to Run a Confusion Test

For each screen:
1. Look at the rendered design (screenshot — never from code)
2. Assume the perspective of each persona, one at a time
3. Ask their specific questions against the design
4. Flag any question where the answer is "no" or "unclear" as an issue
5. Classify issues by severity (P0–P3)

---

## Confusion Test Output Format

```
## Confusion Testing: [Screen Name]

### First-Timer
- ✅ Purpose is clear within 5 seconds
- ✅ Clear starting point / primary action
- ⚠️ [Issue] — [description] → [fix]
- ❌ [Issue] — [description] → [fix]

### Rusher
- ✅ Primary action is immediately visible
- ✅ Minimal steps to complete task
- ⚠️ [Issue] — [description] → [fix]

### Non-Technical
- ✅ All icons have labels
- ✅ Language is simple
- ⚠️ [Issue] — [description] → [fix]

### Anxious
- ✅ Destructive actions have confirmation
- ✅ Clear back/cancel options
- ⚠️ [Issue] — [description] → [fix]

### Accessibility
- ✅ Keyboard navigable
- ✅ Contrast ratios pass
- ⚠️ [Issue] — [description] → [fix]

### Summary
- Total issues: [N]
- P0: [count] | P1: [count] | P2: [count] | P3: [count]
- Blocking: [Yes/No]
```

A confusion test that finds 0 issues is suspicious — look harder. Real designs almost always have at least a few P2-P3 findings.
