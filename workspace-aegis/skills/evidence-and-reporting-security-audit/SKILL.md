# Evidence & Reporting — Aegis Standards

## Evidence Requirements

### P0 Finding — Required Evidence
1. Exact HTTP request (curl command reproducible by another person)
2. Exact HTTP response (status code + relevant response body)
3. Screenshot if UI-visible
4. Confirmation that the issue is reproducible (tested ≥2 times)

### P1 Finding — Required Evidence
1. Reproduction steps (detailed enough to reproduce without the auditor present)
2. HTTP request/response for API findings
3. Screenshot for UI findings

### P2/P3 — Recommended
- Description sufficient for P3
- Reproduction steps for P2

## Evidence Capture Commands

```bash
# Full request + response capture
curl -sv https://agent-arena-roan.vercel.app/api/admin/challenges 2>&1

# Just status code
curl -s -o /dev/null -w "%{http_code}" https://agent-arena-roan.vercel.app/api/admin/challenges

# Response body
curl -s https://agent-arena-roan.vercel.app/api/admin/challenges | python3 -m json.tool

# Check for sensitive strings in response
curl -s https://agent-arena-roan.vercel.app/api/challenges?limit=5 \
  | grep -i "service_role\|postgres\|secret\|hidden_test"
```

## Finding ID Format
- P0: AEG-P0-001, AEG-P0-002, etc.
- P1: AEG-P1-001, AEG-P1-002, etc.
- P2: AEG-P2-001, etc.
- P3: AEG-P3-001, etc.

## Severity Assignment Checklist

Before filing P0, confirm all:
- [ ] You have an HTTP request that reproduces it
- [ ] The response confirms unauthorized access OR data exposure
- [ ] You tested it at least twice
- [ ] It's not in FALSE_POSITIVE_GUARDRAILS.md

Before filing P1, confirm:
- [ ] You have reproduction steps
- [ ] The issue is confirmed (not theoretical)
- [ ] Severity reasoning is documented

## Escalation Protocol
P0 findings: escalate immediately to Forge (@ForgeVPSBot) AND log in audit report.
Do not wait until report is complete to notify Forge of a P0.

Message format:
"🚨 AEGIS P0: [title] — [route/endpoint] — [one-line description] — [curl command]"
