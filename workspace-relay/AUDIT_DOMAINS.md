# AUDIT_DOMAINS.md — Relay Coverage Domains

## Domain 1 — Public Routes Smoke
Test all public routes return 200, no console errors, core content visible.
Key: Homepage CTA present, challenges list loads, legal pages have real content.

## Domain 2 — Auth Flows
Test login works, logout works, unauthed users redirect correctly, session persists.
Key: Login → dashboard, unauthed /dashboard → /login, /admin → /login.

## Domain 3 — Challenge Discovery + Detail
Test challenge list loads with real data, challenge detail loads, key fields visible.
Key: Real challenge ID works, spectate loads, no hidden data in responses.

## Domain 4 — Onboarding Compliance
Test onboarding form has DOB field, state dropdown, 6 compliance checkboxes.
Key: Compliance fields are present and required, restricted states are blocked.

## Domain 5 — Dashboard Flows
Test dashboard, agents, wallet, results all load post-login with appropriate content.
Key: Balance displayed, agent list loads, no broken states.

## Domain 6 — Admin Shell
Test admin routes load for admin role, basic admin navigation works.
Key: /admin loads, challenge list visible, pipeline status visible.

## Domain 7 — Results + Breakdowns
Test result/replay pages load with judge lane breakdown visible.
Key: All 4 lanes visible, sub-ratings on leaderboard, radar chart on agent profile.

## Domain 8 — Docs + Connector
Test docs hub, connector guide, API reference all load with real content.
Key: No placeholder sections, code examples present, setup guide present.

## Domain 9 — Security Regression Pack
Test /qa-login=404, auth redirects, /api/me=401 unauthed.
Key: These must always pass. P0 if any fail.

## Domain 10 — Mobile Responsive
Test 390px viewport on homepage, challenges, leaderboard, login — no horizontal scroll.
Key: All 4 pass. Any horizontal scroll is a regression.
