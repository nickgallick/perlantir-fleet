# Bug Severity & Triage — Sentinel Standard

---

## Severity Definitions

### P0 — Launch Blocker
**Ship-blocking. Platform cannot launch until resolved.**

A P0 exists when:
- Security: unauthed access to authed routes, data exposure to wrong role, /qa-login accessible
- Payments: billing broken, coin balance wrong, prize pool miscalculated (when live)
- Judging: scores not delivered, lane breakdown missing or wrong, judging results corrupted
- Auth: login completely broken, signup broken, sessions not persisting
- Legal/Compliance: onboarding missing DOB/state/compliance checkboxes, restricted states not blocked, legal pages returning 404 or empty
- State corruption: DB errors visible in page content, raw Postgres errors in API responses
- Data integrity: wrong user seeing another user's data, admin data visible to non-admin
- Critical runtime failure: core page returns 500 with no fallback

**Required evidence**: Screenshot or video required. Repro steps required. Cannot close without verified fix.

**SLA**: Report to Forge within the same audit session. Do not wait for report.

---

### P1 — Major Broken
**Should be fixed before launch. Seriously degrades trust or functionality.**

A P1 exists when:
- Core feature is completely non-functional (not just degraded)
- Admin/operator cannot complete a critical workflow
- Trust-destroying UX (example: empty admin queue with no explanation, wrong data shown to user)
- Connector setup docs lead to an integration failure
- Mobile layout fundamentally broken on a primary page (horizontal scroll, unusable form)
- Legal page has placeholder content (Iowa address placeholder = P1)
- Stale branding that contradicts current product (3-Judge Panel, Agent Arena, BOUTS ELITE)
- Error messages expose internal system details (stack traces, SQL, environment variables)

**Required evidence**: Screenshot strongly recommended. Repro steps required.

**SLA**: Include in audit report with clear fix assignment.

---

### P2 — Important, Non-Blocking
**Fix this sprint. Noticeable but does not prevent launch.**

A P2 exists when:
- Feature partially broken or degraded (still usable but imperfect)
- UX is misleading but not trust-destroying
- Mobile layout issues on secondary pages
- Hardcoded/fake stats on landing page
- Empty states with no helpful messaging
- Connector docs with a stale version number
- Test data visible in production (test agents in leaderboard)
- Non-critical copy errors

**Required evidence**: Screenshot if visual. Repro steps recommended.

---

### P3 — Polish
**Backlog. Does not affect launch decision.**

A P3 exists when:
- Minor visual inconsistency (pixel alignment, color mismatch)
- Copy that could be clearer but is not wrong
- Non-critical empty state that works but could be better
- Responsive issues on edge case viewports
- Minor animation/transition issues

**Required evidence**: Screenshot optional.

---

## Ship-Blocking Checklist

Before recommending GO:
- [ ] Zero P0s open
- [ ] All P1s either fixed or explicitly accepted by Nick with documented reasoning
- [ ] /qa-login returns 404
- [ ] Auth gate confirmed (dashboard/admin redirect to login)
- [ ] Legal pages confirmed (all 4 return 200 with real content)
- [ ] Onboarding compliance confirmed (DOB + state + 6 checkboxes)
- [ ] Restricted states blocked (WA/AZ/LA/MT/ID)
- [ ] No raw DB errors visible anywhere
- [ ] No unauthed access to admin routes

---

## Evidence Requirements by Severity

| Severity | Screenshot | Video | Console log | Network tab | Repro steps |
|----------|-----------|-------|-------------|-------------|-------------|
| P0 | Required | If auth/flow | If JS error | If API failure | Required |
| P1 | Strongly recommended | Optional | If relevant | If relevant | Required |
| P2 | Recommended | No | If relevant | No | Recommended |
| P3 | Optional | No | No | No | Optional |

---

## Reproducibility Standards

**Reproducible**: Issue occurs on at least 2 attempts with same steps
**Intermittent**: Issue occurs on some attempts but not all — note frequency (e.g., "3/5 attempts")
**Not reproducible**: Issue occurred once and cannot be replicated — downgrade severity, note as "observed once"

---

## Escalation Rules

**Escalate immediately (same session, don't wait for report)**:
- Any P0 security issue (unauthed access, data exposure)
- Any P0 that blocks a just-shipped feature
- Any issue that suggests production data may be corrupted

**Escalation path**: Forge (build fixes) → ClawExpert (COO) → Nick (owner decisions)

**How to escalate**: Send message to @ForgeVPSBot with:
- Issue title
- Severity
- Route
- One-line description
- Screenshot if available

---

## Triage Decision Tree

```
Found an issue?
  │
  ├─ Is it in KNOWN_ENV_LIMITATIONS.md? → Not a bug (document as risk item)
  │
  ├─ Does it expose data to wrong role? → P0 (security)
  │
  ├─ Does it break auth, judging, or payments? → P0
  │
  ├─ Does it violate legal/compliance requirements? → P0
  │
  ├─ Is core functionality completely broken? → P1
  │
  ├─ Does it seriously damage trust? → P1
  │
  ├─ Is it broken but not unusable? → P2
  │
  └─ Is it a polish/minor issue? → P3
```
