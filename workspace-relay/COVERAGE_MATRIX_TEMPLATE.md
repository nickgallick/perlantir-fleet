# COVERAGE_MATRIX_TEMPLATE.md — Relay Coverage Tracking

Use this to track what flows are covered, at what depth, with what role/viewport/browser.

**Coverage codes**: ✅ covered | ⚠️ partial | ❌ not covered | N/A not applicable | ~ partial confidence

---

## Layer 1 — Smoke Tests

| Route/Flow | Desktop Chromium | Mobile 390px | WebKit | Role | Status | Notes |
|-----------|-----------------|-------------|--------|------|--------|-------|
| `/` loads | | | | anon | | |
| `/challenges` loads | | | | anon | | |
| `/challenges/[id]` loads | | | | anon | | |
| `/leaderboard` loads | | | | anon | | |
| `/login` loads | | | | anon | | |
| `/legal/terms` loads | | | | anon | | |
| `/legal/responsible-gaming` loads | | | | anon | | |
| `/docs/connector` loads | | | | anon | | |
| `/api/health` 200 | | | | n/a | | |
| `/api/challenges` 200 | | | | n/a | | |
| `/qa-login` is 404 | | | | anon | | |
| Dashboard redirects unauthed | | | | anon | | |
| Admin redirects unauthed | | | | anon | | |

---

## Layer 2 — Critical Path Workflows

| Flow | Desktop | Mobile | Role | Test Layer | Status | Notes |
|------|---------|--------|------|-----------|--------|-------|
| Login → dashboard redirect | | | competitor | critical | | |
| Login → /admin accessible | | | admin | critical | | |
| Browse challenges → open detail | | | anon | critical | | |
| Challenge detail → entry/registration | | | competitor | critical | | |
| Submit solution → status display | | | competitor | critical | | |
| View result → breakdown visible | | | competitor | critical | | |
| Admin: view forge review queue | | | admin | critical | | |
| Admin: submit inventory decision | | | admin | critical | | |
| View leaderboard → agent profile | | | anon | critical | | |
| Onboarding: compliance fields present | | | new user | critical | | |

---

## Layer 3 — Regression Protection

| Flow | What it protects | Status | Added after |
|------|----------------|--------|------------|
| /qa-login = 404 | Security — backdoor route | | Initial setup |
| Auth redirect on /dashboard unauthed | Role gating | | Initial setup |
| Mobile no horizontal scroll (4 pages) | Responsive regression | | 2026-03-28 E2E |
| Sub-ratings column in leaderboard | Feature regression | | 2026-03-28 E2E |
| Agent radar chart present | Feature regression | | 2026-03-28 E2E |
| /api/me = 401 unauthed | Auth regression | | Initial setup |
| /api/admin = 401 unauthed | Security regression | | Initial setup |
| Legal pages 200 with content | Compliance regression | | Initial setup |

---

## Layer 4 — Diagnostic / Ad Hoc

| Flow | Purpose | Automatable | Notes |
|------|---------|------------|-------|
| Challenge intake bundle POST | Test intake pipeline | Yes (when migration 00024 fixed) | Blocked |
| Forge review queue UI | Admin workflow | Yes (when pipeline data exists) | |
| Billing entry/success | Payment flow | No — Stripe not live | |

---

## Coverage Gap Register

| Gap | Severity | Reason | Planned |
|-----|----------|--------|---------|
| Submission flow E2E | P1 | No real submission infra testable yet | Post-launch |
| Billing smoke | P1 | Stripe not live | When live |
| Admin pipeline UI | P1 | challenge_bundles migration pending | When migration fixed |
| WebKit/Safari smoke | P2 | Playwright WebKit not confirmed installed | Check |
| Competitor registration flow | P1 | Need fresh test account seeding | |
