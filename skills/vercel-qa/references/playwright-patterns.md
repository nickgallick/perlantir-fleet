# Playwright Patterns For Vercel QA

Use `playwright-skill-safe` as the execution layer.

## Rules
- Save screenshots to `/tmp/qa-screenshots/`
- Take screenshots at each meaningful step
- Capture console errors, page errors, request failures, and traces
- Prefer role/label/text locators first
- Use realistic test data

## Suggested screenshot naming
- `/tmp/qa-screenshots/01-home.png`
- `/tmp/qa-screenshots/02-signup.png`
- `/tmp/qa-screenshots/03-dashboard.png`
- `/tmp/qa-screenshots/04-error-state.png`

## Minimum automation coverage
- homepage smoke
- auth flow
- one happy path per role
- one invalid-input path per role
- one mobile viewport pass

## Route discovery ideas
- nav links
- sitemap if available
- obvious CTA destinations
- footer links
- auth redirects
- dashboard sidebar items

## Product-gap examples
- Booking app with no provider/vendor onboarding
- Marketplace with buyer flow but no seller listing flow
- CRM with contact list but no contact creation or editing
- Team app with invite UI absent
- Auth present but no post-signup onboarding path
