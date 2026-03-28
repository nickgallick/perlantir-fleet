# Playwright Handoff — Sentinel ↔ Automation Agents

This document defines what Sentinel automates vs what stays manual, and how to hand off automation work to Relay (or any future automation-focused QA agent).

---

## Automation Philosophy
Playwright is a tool for evidence capture and regression coverage — not a replacement for judgment. Sentinel writes scripts when:
1. A test needs to run repeatedly (regression)
2. A test requires browser rendering to verify (JS-rendered content)
3. A test is too slow or tedious to do manually every audit
4. Evidence capture is critical (screenshots of P0/P1 issues)

Sentinel does NOT write Playwright scripts for:
- Tests that require real payment processing
- Tests that would modify production data at scale
- Tests better handled by reading the codebase

---

## Playwright Skill
- **Skill location**: /data/.openclaw/skills/playwright-skill-safe/SKILL.md
- **Runner**: `node /data/.openclaw/skills/playwright-skill-safe/scripts/run_playwright_task.js /tmp/playwright-test-FILE.js`
- **Script location**: Must be `/tmp/playwright-test-*.js` (required by runner)
- **Screenshots**: Save to `/tmp/sentinel-screenshots/`
- **Reports**: Save to `/tmp/sentinel-audit-report-DATE.md`

---

## What Should Be Automated (Priority Order)

### Tier 1 — Always automate (run every audit)
| Test | Why |
|------|-----|
| All public routes return 200 | Fast regression, catches deploy failures |
| Dashboard/admin routes redirect to /login unauthed | Security regression |
| /qa-login returns 404 | Security compliance |
| /api/health, /api/challenges, /api/agents, /api/leaderboard return 200 | API smoke test |
| /api/me returns 401 unauthed | Auth regression |
| Mobile viewport (390px): /, /challenges, /leaderboard, /login — no horizontal scroll | Responsive regression |
| All legal pages return 200 with content | Legal compliance |
| No DB errors (PostgresError) in any page response | Data safety |

### Tier 2 — Automate for full audits
| Test | Why |
|------|-----|
| Login flow with QA credentials | Auth regression |
| Dashboard loads post-login | Core UX |
| Leaderboard sub-ratings column present | Feature regression |
| Agent profile radar chart present | Feature regression |
| Challenge detail page loads for real ID | Feature regression |
| Challenge spectate loads | Feature regression |
| Screenshots of all primary pages (desktop + mobile) | Visual evidence |
| Console error capture on all pages | JS error detection |

### Tier 3 — Automate for deep audits
| Test | Why |
|------|-----|
| Onboarding flow compliance fields | Legal regression |
| Admin routes load for admin user | Role regression |
| /api/challenges/intake with test bundle | Pipeline regression |
| /api/admin/forge-review returns queue | Pipeline regression |
| Error page (404) looks correct | UX regression |

---

## What Must Stay Manual

| Test | Why manual |
|------|------------|
| Visual design quality judgment | Automation can't assess "does this look credible" |
| Copy quality and trust signals | Requires human evaluation |
| Empty state UX quality | Requires judgment |
| Admin workflow completeness | Complex multi-step flows requiring judgment |
| Connector docs accuracy | Requires reading comprehension |
| "Would a serious user trust this?" overall assessment | Fundamental judgment call |
| Payment flows (when live) | Requires real payment method, destructive |
| Exploratory testing for edge cases | By definition unpredictable |

---

## Handoff to Relay (or future automation agent)

When handing off automation work:
1. Provide this file
2. Provide ROUTE_MAP.md
3. Provide TEST_DATA_AND_ACCOUNTS.md (credentials)
4. Provide KNOWN_ENV_LIMITATIONS.md (to avoid false positives)
5. Specify: which Tier to run (1, 2, or 3)
6. Specify: output location for screenshots and report

### Handoff message template
```
Relay — run a Tier [1/2/3] Playwright audit on Bouts.

App: https://agent-arena-roan.vercel.app
Credentials: qa-bouts-001@mailinator.com / BoutsQA2026! (admin)
Reference docs: /data/.openclaw/workspace-sentinel/

Save screenshots: /tmp/relay-screenshots-[DATE]/
Save report: /tmp/relay-audit-[DATE].md

Known limitations to skip: see KNOWN_ENV_LIMITATIONS.md
Report format: see REPORT_TEMPLATE.md
```

---

## Script Naming Convention
`/tmp/playwright-test-sentinel-[domain]-[YYYYMMDD].js`

Examples:
- `/tmp/playwright-test-sentinel-public-routes-20260329.js`
- `/tmp/playwright-test-sentinel-auth-flows-20260329.js`
- `/tmp/playwright-test-sentinel-mobile-20260329.js`
- `/tmp/playwright-test-sentinel-pipeline-20260329.js`

---

## Screenshot Naming Convention
`/tmp/sentinel-screenshots/[role]-[route-slug]-[desktop|mobile].png`

Examples:
- `public-home-desktop.png`
- `public-leaderboard-mobile.png`
- `admin-challenges-desktop.png`
- `auth-login-desktop.png`
