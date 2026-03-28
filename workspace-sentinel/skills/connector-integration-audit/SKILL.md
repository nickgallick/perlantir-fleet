# Connector & Integration Audit — Sentinel Standard

## What the Connector Is
The Bouts Connector is the CLI/SDK that AI agents (or their developers) use to submit solutions to Bouts challenges. It is the primary integration point for competitors.

If this doesn't work, developers can't compete.

## Routes to Audit
- `/docs/connector` — connector overview
- `/docs/connector/setup` — setup guide
- `/docs/api` — API reference
- `/docs/compete` — competitor guide
- `/docs` — docs hub (should have 4 clear cards)

## What to Verify

### Documentation Completeness
- Are setup instructions present and complete?
- Is the API reference accurate? (check against actual endpoints)
- Does the connector CLI guide show the correct version? (should show v0.1.1 badge or current version)
- Are example code snippets present and syntactically correct?
- Is the submission flow explained end-to-end?

### Documentation Accuracy (P1 if wrong)
- Do the docs reference the correct API endpoints?
- Are auth requirements correctly documented?
- Is the telemetry schema documented?
- Are the output format requirements documented?
- Does the "getting started" path actually work?

### Trust Signals in Docs
- Do docs feel like a real product (not an MVP with TBD sections)?
- Is there a clear FAQ or troubleshooting section?
- Is the error handling documented?

## Known Issues (as of 2026-03-29)
- Connector docs don't show v0.1.1 badge — stale version display (P2)

## Integration API Checks
Test these endpoints work correctly for a connector implementation:

```
GET /api/health → 200 { "status": "ok" }
GET /api/challenges?limit=5 → 200 { challenges: [...] }
GET /api/challenges/[id] → 200 challenge detail
POST /api/challenges/[id]/submit → requires auth (401 unauthed)
GET /api/me → 401 unauthed, 200 authed with user data
```

## Competitor Experience Audit
Walk through the competitor journey:
1. Finds Bouts
2. Reads how it works
3. Browses challenges
4. Reads connector docs
5. Installs CLI
6. Connects their agent
7. Submits a challenge
8. Views results

At each step: is there friction? Is anything unclear? Is anything broken?

## Test Checklist
- [ ] /docs loads with real content (not 404 or empty)
- [ ] /docs/connector shows complete setup guide
- [ ] /docs/connector/setup has step-by-step instructions
- [ ] /docs/api shows accurate API reference
- [ ] /docs/compete shows submission contract and scoring principles
- [ ] All code examples are syntactically correct
- [ ] API endpoints listed in docs actually exist and return expected responses
- [ ] No "Coming soon" placeholders in critical docs sections
- [ ] Connector version shown is current (check for v0.1.1 or later)
