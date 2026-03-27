# QA Checklists

## Phase 0 — Product Map
- What is the app for?
- Who is it for?
- What roles exist?
- What is the main job to be done?
- Which flows should exist for each role?
- What data objects exist?
- What relationships should exist between those objects?
- What obvious product logic gaps exist?

## Phase 1 — First Impression
- Can a new user explain what this app does in 5 seconds?
- Is there a clear primary CTA?
- Does the UI look trustworthy?
- Any broken images or placeholder text?
- Is pricing / promise / next step understandable?

## Phase 2 — Routes
- Landing page
- Auth pages
- Dashboard pages
- Settings
- Role-specific pages
- Error states / empty states
- Mobile 375px spot-check

## Phase 3 — Auth
- Signup
- Login
- Logout
- Session persistence
- Password reset
- Validation errors
- Role coverage

## Phase 4 — Functional
- Happy path
- Invalid input
- Duplicate submit
- Rapid clicks
- XSS-ish strings
- CRUD propagation

## Phase 5 — Cross-feature
- Search
- Filter
- Sort
- Related records update correctly
- Notifications / side effects

## Phase 6 — Edge cases
- Empty states
- Long text
- Special characters
- Deep links
- Back button
- Uploads
- Touch interactions

## Phase 7 — Visual / UX
- Loading states
- Error clarity
- Success feedback
- Consistency
- Accessibility basics
- Form state preservation
