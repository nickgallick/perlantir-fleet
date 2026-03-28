# Aegis Audit Report Template

## Aegis Security Audit: [AUDIT NAME]
Date: YYYY-MM-DD | Environment: https://agent-arena-roan.vercel.app

---

## 1. Executive Security Verdict
**Decision**: SHIP / CONDITIONAL SHIP / NO-SHIP
**Weighted Score**: X.X / 10 | **Grade**: X
**P0**: X | **P1**: X | **P2**: X | **P3**: X
**Summary**: 2-3 sentence verdict on security posture.

---

## 2. Scorecard
| Category | Score | Notes |
|----------|-------|-------|
| Auth / Session Integrity | /10 | |
| Role-Based Access Control | /10 | |
| API / Endpoint Protection | /10 | |
| Runtime Abuse Resistance | /10 | |
| Judging / Result Integrity | /10 | |
| Breakdown Visibility | /10 | |
| Admin Safety | /10 | |
| Connector Trust | /10 | |
| Billing Trust | N/A | Not live |
| Secrets / Error Hygiene | /10 | |
| Overall Trustworthiness | /10 | |
| **Weighted Total** | **/10** | |

---

## 3. Finding Log
| ID | Sev | Category | Route/Endpoint | Finding | Repro | Fix |
|----|-----|----------|---------------|---------|-------|-----|
| AEG-P0-001 | P0 | | | | | |

---

## 4. Abuse Case Results
| Case | Result | Evidence |
|------|--------|---------|
| AC-SUB-001 Duplicate submit | PASS/FAIL | |
| AC-AUTH-001 Stale session | PASS/FAIL | |
...

---

## 5. Coverage Report
**Routes tested**: X / Y | **APIs tested**: X / Y
**Not tested**: [list with reasons]

---

## 6. Prioritized Fix Order
**P0 — Immediate:**
1. [AEG-P0-001] [Title] → Forge

**P1 — Before launch:**
1.

---

## AEGIS SECURITY VERDICT
**Decision**: SHIP / CONDITIONAL SHIP / NO-SHIP
**Weighted Score**: X.X / 10 | **Grade**: X
**P0**: X | **P1**: X
**Blocking conditions**: [list or "none"]
**Coverage**: X/Y required routes tested
