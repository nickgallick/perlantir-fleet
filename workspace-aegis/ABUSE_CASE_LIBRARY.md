# ABUSE_CASE_LIBRARY.md — Aegis Predefined Abuse Scenarios

Predefine and systematically test these before every major audit.
Each abuse case has: scenario, test method, expected defense, failure signal.

---

## Category 1 — Submission Abuse

### AC-SUB-001: Duplicate Submission
**Scenario**: Competitor submits a solution twice to the same challenge
**Test**: Submit via API twice with the same credentials and challenge ID
**Expected defense**: Second submission rejected (HTTP 409 or equivalent), first stands
**Failure signal**: Both accepted, score overwritten, or undefined behavior

### AC-SUB-002: Solution Replay After Match Close
**Scenario**: Match has ended but competitor tries to submit retroactively
**Test**: POST to submission endpoint after challenge deadline
**Expected defense**: 400/422 — challenge not in accepting state
**Failure signal**: Late submission accepted or silently queued

### AC-SUB-003: Oversized Payload
**Scenario**: Competitor sends extremely large submission (10MB+ payload)
**Test**: POST to submission endpoint with large body
**Expected defense**: 413 Payload Too Large or validation rejection
**Failure signal**: Server hangs, crashes, or returns 500

### AC-SUB-004: Malformed Payload State Corruption
**Scenario**: Competitor sends malformed JSON or missing required fields
**Test**: POST with missing `solution_code`, empty strings, null values
**Expected defense**: 400 with specific validation error, no state change
**Failure signal**: 500 error, partial DB write, or undefined behavior

### AC-SUB-005: Wrong Challenge State Transition
**Scenario**: Competitor enters a challenge that is in `calibrating` or `quarantined` state
**Test**: Attempt entry/submission when challenge is not in `active` state
**Expected defense**: 400/422 — challenge not accepting entries
**Failure signal**: Entry accepted despite wrong pipeline state

---

## Category 2 — Session / Auth Abuse

### AC-AUTH-001: Stale Session Replay
**Scenario**: User uses an expired JWT/session cookie
**Test**: Save a valid session token, wait for expiry (or modify expiry claim), replay
**Expected defense**: 401 — session expired, redirect to login
**Failure signal**: Expired token accepted as valid

### AC-AUTH-002: JWT Manipulation
**Scenario**: User modifies JWT payload to escalate role (e.g., role: "admin")
**Test**: Decode JWT, modify role claim, re-encode with same signature, send
**Expected defense**: Signature validation fails → 401
**Failure signal**: Modified JWT accepted

### AC-AUTH-003: Session Fixation
**Scenario**: Attacker sets a known session ID before auth to take over after login
**Test**: Set a session cookie before login, see if same session is used post-login
**Expected defense**: New session created on login (session rotation)
**Failure signal**: Pre-login session persists after authentication

### AC-AUTH-004: Brute Force Login
**Scenario**: Rapid repeated login attempts
**Test**: POST /login endpoint 20+ times rapidly with wrong credentials
**Expected defense**: Rate limiting kicks in (429), lockout, or CAPTCHA
**Failure signal**: All attempts accepted without throttling

### AC-AUTH-005: Cross-Competitor Session Bleed
**Scenario**: Competitor A can access Competitor B's results or agent data
**Test**: Log in as Competitor A, attempt to access Competitor B's private routes
**Expected defense**: 403 or data scoped to authenticated user
**Failure signal**: Competitor B's data returned

---

## Category 3 — Role Escalation Abuse

### AC-ROLE-001: Competitor Accessing Admin Routes
**Scenario**: Authenticated competitor directly requests admin API
**Test**: Authenticated as competitor → GET/POST /api/admin/*
**Expected defense**: 403 Forbidden
**Failure signal**: 200 with admin data

### AC-ROLE-002: Anonymous User Accessing Competitor Routes
**Scenario**: Unauthenticated user directly requests authenticated API
**Test**: No auth headers → GET /api/me, POST /api/agents
**Expected defense**: 401 Unauthorized
**Failure signal**: 200 or partial data returned

### AC-ROLE-003: Competitor Modifying Another Competitor's Agent
**Scenario**: Competitor A tries to modify Competitor B's registered agent
**Test**: PATCH /api/agents/[COMPETITOR_B_AGENT_ID] while logged in as Competitor A
**Expected defense**: 403 Forbidden or 404
**Failure signal**: Modification succeeds

### AC-ROLE-004: Connector Token Privilege Escalation
**Scenario**: GAUNTLET_INTAKE_API_KEY used to access non-intake admin endpoints
**Test**: Use API key as Bearer token → GET /api/admin/inventory
**Expected defense**: 401 or 403 (key only valid for intake endpoint)
**Failure signal**: Admin data returned with intake API key

---

## Category 4 — Judging / Result Manipulation

### AC-JUDGE-001: Score Modification After Activation
**Scenario**: Attempt to modify a score after challenge is in `active` state
**Test**: PATCH to challenge score endpoint after activation
**Expected defense**: 403 — score is immutable post-activation
**Failure signal**: Score updated

### AC-JUDGE-002: Hidden Test Case Extraction
**Scenario**: Competitor attempts to retrieve hidden test cases before match
**Test**: GET challenge detail with authenticated competitor token, check all response fields
**Expected defense**: Hidden tests not present in any API response to competitor role
**Failure signal**: hidden_tests or test_cases field present in response

### AC-JUDGE-003: Pre-Match Judge Configuration Leakage
**Scenario**: Competitor retrieves judge weight configuration before match
**Test**: Get challenge detail, check for judge_weights, scoring_rubric, thresholds
**Expected defense**: Judge configuration not in competitor-facing API response
**Failure signal**: Judge weights or thresholds returned to competitor

### AC-JUDGE-004: Replay Result Manipulation
**Scenario**: Attempt to modify a replay result after match conclusion
**Test**: PATCH or PUT to replay/result endpoint post-match
**Expected defense**: 403 — results immutable, or endpoint doesn't accept mutation
**Failure signal**: Result changed

---

## Category 5 — Admin Abuse

### AC-ADMIN-001: Mass Quarantine Without Confirmation
**Scenario**: Admin script attempts to quarantine all challenges in one request
**Test**: POST /api/admin/inventory with bulk quarantine action
**Expected defense**: Either bulk action not supported, or requires explicit confirmation per item
**Failure signal**: All challenges quarantined in one unauthenticated/unconfirmed request

### AC-ADMIN-002: Admin Action Without Reason Capture
**Scenario**: Admin quarantines or rejects a challenge without providing a reason
**Test**: POST /api/admin/inventory with no `reason` field
**Expected defense**: 400 — reason required for destructive state transitions
**Failure signal**: Action accepted with no reason recorded

### AC-ADMIN-003: Unauthorized Pipeline Trigger
**Scenario**: Automated system or unauthorized actor triggers calibration
**Test**: POST /api/admin/calibration without admin session
**Expected defense**: 401 or 403
**Failure signal**: Calibration triggered, costing real API tokens

---

## Category 6 — Information Disclosure

### AC-INFO-001: DB Error Leakage
**Scenario**: Malformed request causes raw DB error to be returned
**Test**: Send malformed UUIDs, special characters, SQL-like strings as query params
**Expected defense**: Generic error response, no PostgresError or relation name exposed
**Failure signal**: "PostgresError: relation X does not exist" in response

### AC-INFO-002: Environment Variable Disclosure
**Scenario**: API response or error includes env var names/values
**Test**: Trigger various error states, inspect responses for NEXT_PUBLIC_, process.env patterns
**Expected defense**: No env var references in any response body
**Failure signal**: Any env var string in response

### AC-INFO-003: Internal Path Disclosure
**Scenario**: Error messages reveal server file paths or internal structure
**Test**: Trigger 500 errors, inspect for /data/, /var/, or other server paths
**Expected defense**: Generic "internal server error" message
**Failure signal**: File system paths in error response

### AC-INFO-004: User Data Exposure in Public API
**Scenario**: Public API response includes fields intended only for the authenticated user
**Test**: GET /api/agents?limit=10 as anonymous — inspect response for email, private fields
**Expected defense**: Only public fields returned (name, profile, public stats)
**Failure signal**: Email addresses, tokens, or private fields in public response

---

## Category 7 — Dead-Letter / Retry Abuse

### AC-RETRY-001: Replay Webhook / Cron Trigger
**Scenario**: Attacker replays a cron trigger to run quality enforcement repeatedly
**Test**: GET /api/cron/challenge-quality multiple times rapidly
**Expected defense**: Idempotent — same result each call, no side effects from repeat calls
**Failure signal**: Repeat calls cause double-processing or state corruption

### AC-RETRY-002: Migration Endpoint Replay
**Scenario**: /api/internal/run-migration-024 replayed after migration is complete
**Test**: POST to migration endpoint after it's been run
**Expected defense**: Idempotent or endpoint returns 404/disabled post-migration
**Failure signal**: Migration re-runs, corrupting applied state
