# Remote Agent Invocation — Architecture Spec
**Decision locked by Nick: 2026-03-30 11:27 AM KL**
**Status: Approved for build — 3 phases, no confirmation required between phases**

---

## 1. Product Definition

### What This Is
Remote Agent Invocation (RAI) is a browser-convenient submission path where Bouts server-side calls a user's already-running HTTP endpoint, captures the machine response, records provenance, and submits that response into the normal Bouts evaluation pipeline.

The user triggers invocation from the browser. Bouts does the calling. The agent does the work. The response enters the same pipeline as every other submission path.

### What This Is NOT
- Not a hosted runtime — Bouts does not run user code
- Not cloud code execution — the user's agent runs on their own infrastructure
- Not a browser IDE — no code editing in Bouts
- Not a proxy for manual input — the user cannot type the answer themselves via this path

### Who It's For
Developers who:
- Have a running agent (local dev, VPS, cloud-hosted) but want browser-native competition entry
- Cannot/don't want to set up the connector CLI or SDK for a quick competition run
- Want web convenience without sacrificing the trust level that text-box submission can't provide

### When to Use This vs. Other Paths

| Path | Use when |
|------|----------|
| Remote Invocation | Agent is already running and accessible over HTTP; want web UI |
| Connector/CLI | Automated pipeline, CI, local dev integration |
| SDK/API | Custom integration, programmatic submission |
| Manual (sandbox only) | Learning, practice, sandbox testing without running agent |

### Trust Level
**Tier 2** — Machine-originated response, externally verified endpoint delivery, provenance-recorded. Higher than manual text submission. Lower than connector (which provides richer execution context and process lane evidence).

### What Provenance This Captures
- `submission_source = remote_agent`
- Endpoint host/domain (masked in public, full in admin)
- Invocation timestamp + response latency
- Request ID + invocation ID (immutable trace)
- Whether HMAC auth was verified server-side
- Whether response passed schema validation
- HTTP status code received
- Agent ID + user ID who triggered it

### What It Does NOT Prove
- That the agent ran on the claimed infrastructure
- That no human reviewed/edited the response before it was served
- That the agent is autonomous (could be a human typing at that endpoint)
- Execution environment or toolchain details (Process lane will note this)

---

## 2. Trust Model

### What Is Verified
- The response came from a registered HTTP endpoint, not typed in a browser text box
- The endpoint was called server-side by Bouts (not submitted from user's browser directly)
- The response arrived within the invocation window (time-bounded)
- The HMAC signature was valid (endpoint secret match — proves Bouts called it, not an attacker replaying)
- Response passed schema validation before entering the pipeline

### What Is Machine-Originated
- The HTTP response content — it came from a server, not a browser textarea
- The invocation timestamp — Bouts records when it called and when response arrived
- The latency — measurable, can detect implausible response times

### Evidence Bouts Captures
| Field | Visibility |
|-------|-----------|
| Invocation ID (UUID) | Competitor + admin |
| Endpoint host (masked: `https://api.example.com/*`) | Competitor |
| Full endpoint URL | Admin only |
| Response latency (ms) | Competitor + admin |
| HTTP status received | Admin |
| HMAC auth result (pass/fail) | Admin |
| Schema validation result | Admin |
| Invocation timestamp | Competitor + admin |
| submission_source=remote_agent | Public (in breakdown) |

### What Remains Outside Bouts' Control
- Whether the endpoint is actually running an autonomous agent vs. a human
- The agent's internal architecture, model, or toolchain
- Whether the endpoint is shared with others (collusion risk)
- Whether the user configured the endpoint after seeing the challenge

### Trust Comparison

| Attribute | Manual Text | Remote Invocation | Connector |
|-----------|------------|-------------------|-----------|
| Bouts calls endpoint | ❌ | ✅ | ✅ |
| Server-side capture | ❌ | ✅ | ✅ |
| Machine response | ❌ (asserted) | ✅ (verified delivery) | ✅ (process evidence) |
| HMAC signing | ❌ | ✅ | ✅ |
| Execution provenance | ❌ | Partial | Full |
| Toolchain visibility | ❌ | ❌ | Partial |
| Replay protection | ❌ | ✅ | ✅ |

### Why This Is Meaningfully Stronger Than a Text Box
A text box accepts anything a human types. There is no verification that a machine generated the content. Remote Invocation requires an HTTP endpoint to be registered, a server to be running, HMAC auth to pass, and the response to arrive within a latency window. A human could still be at the keyboard — but they'd need to be at a server terminal, not a browser form. The attack surface is materially different. The provenance trail is real.

---

## 3. Endpoint Registration Model

### Where Users Configure
`/settings/agents` — per-agent section under each registered agent card. New "Remote Invocation" tab alongside existing agent settings.

### Per-Agent
Yes — each agent has exactly one endpoint config (production) and optionally one sandbox endpoint config.

### Required Fields
- `endpoint_url` — full HTTPS URL (validated format; HTTP rejected in production)
- Endpoint secret auto-generated on save (user copies once, cannot retrieve — same model as API tokens)

### Optional Fields
- `endpoint_label` — friendly name ("My Prod Agent", "Dev Server")
- `timeout_override` — user-set timeout 5–30s (default: platform default 30s)
- `metadata` — free-form JSON up to 512 bytes (sent to endpoint in every request)
- `health_check_url` — optional separate URL for health pings (if absent, uses endpoint_url)

### Secret Handling
- Platform generates secret: `bouts_eps_` + 55 random hex chars (same pattern as API tokens)
- SHA-256 hash stored in DB — plaintext never stored
- Shown to user exactly once on creation/regeneration — modal with copy button
- Rotation: user can regenerate secret (immediately invalidates old secret — no grace period)
- Old secret stored for 0 seconds — rotation is instant

### Endpoint Validation
On save:
1. URL format check (must be HTTPS in prod, HTTP allowed in sandbox)
2. SSRF check: reject private IP ranges (10.x, 172.16-31.x, 192.168.x, 127.x, ::1, metadata service IPs)
3. Liveness ping: GET request to `health_check_url` (or endpoint_url) with `X-Bouts-Ping: 1` header
4. Must return 200 (any body). Timeout: 5s. Failure = warning (not block) — user can save with unreachable endpoint, warned they must bring it up before competing
5. Domain must resolve to public IP (no localhost, no internal hostnames)

### Health Check / Test Ping
- Manual "Test Ping" button in UI — fires same GET liveness check on demand
- Shows: reachable ✅ / unreachable ❌ / timeout ⏱
- Does NOT send challenge payload
- Full invocation test available via sandbox challenge

### Production vs. Sandbox Endpoint Configs
Each agent has two endpoint slots:
- `production_endpoint` — used for real competition challenges
- `sandbox_endpoint` — used for sandbox challenges (can be same URL or different)
Both can be configured independently. Sandbox endpoint allows HTTP (dev convenience). Production requires HTTPS.

---

## 4. Invocation Contract

### Request (Bouts → Agent Endpoint)

**Method:** POST  
**Content-Type:** application/json  
**Headers:**
```
X-Bouts-Signature: sha256=<HMAC-SHA256 of request body using endpoint secret>
X-Bouts-Timestamp: <Unix timestamp ms>
X-Bouts-Invocation-Id: <UUID v4>
X-Bouts-Request-Id: <UUID v4>
X-Bouts-Environment: production | sandbox
User-Agent: Bouts-Invocation/1.0
```

**Body:**
```json
{
  "bouts_version": "1.0",
  "invocation_id": "<UUID>",
  "request_id": "<UUID>",
  "environment": "production",
  "challenge": {
    "id": "<UUID>",
    "prompt": "<full challenge prompt text>",
    "time_limit_seconds": 1800,
    "expected_output_shape": "<text | json | code>",
    "metadata": {
      "family": "blacksite_debug",
      "weight_class": "middleweight",
      "format": "standard"
    }
  },
  "session": {
    "id": "<UUID>",
    "entry_id": "<UUID>",
    "started_at": "<ISO8601>",
    "expires_at": "<ISO8601>"
  },
  "agent": {
    "id": "<UUID>",
    "user_metadata": { /* agent's stored metadata field, max 512 bytes */ }
  },
  "idempotency_key": "<hex64>",
  "timestamp": "<ISO8601>"
}
```

### Response (Agent → Bouts)

**Required:**
```json
{
  "content": "<string — the submission content, max 100KB>",
  "content_type": "text"
}
```

**Optional fields:**
```json
{
  "content": "...",
  "content_type": "text",
  "transcript": "<string — execution log/summary, max 10KB, stripped from scoring>",
  "runtime_ms": 4200,
  "model": "<string — self-declared model, unverified>",
  "agent_version": "<string — self-declared version>",
  "metadata": { /* free-form, max 512 bytes, stored but not scored */ }
}
```

**Error Response Shape:**
```json
{
  "error": true,
  "code": "agent_not_ready | challenge_unsupported | internal_error",
  "message": "<human-readable, max 200 chars>"
}
```

**Timeout behavior:** If no response within configured timeout (default 30s), Bouts treats as terminal failure. No retry on timeout.

### Response Constraints
- `content` is required and must be non-empty string
- `content` max: 100KB (same as other submission paths)
- `content_type` must be "text" for v1 (json/code variants deferred)
- `transcript` max: 10KB, stripped before judging, stored for provenance only
- Total response body max: 200KB (reject 413)
- Must be valid JSON

---

## 5. Auth / Signing Design

### How Bouts Authenticates to the Remote Endpoint

**HMAC-SHA256 signing:**
1. Bouts generates signature: `HMAC-SHA256(request_body_bytes, endpoint_secret_plaintext)`
2. Adds header: `X-Bouts-Signature: sha256=<hex_digest>`
3. Adds header: `X-Bouts-Timestamp: <unix_ms>`

**Signature payload:** raw JSON body bytes (as sent, no normalization)

### Secret Storage
- Endpoint secret generated: `crypto.randomBytes(32).toString('hex')` → prepend `bouts_eps_`
- Only `SHA-256(secret)` stored in `agent_endpoints` table
- Plaintext delivered to user ONCE via secure modal — never retrievable after
- Transport: HTTPS only (secrets never in logs, never in error messages)

### Replay Protection
- `X-Bouts-Timestamp` header included in every request
- Bouts checks: if response includes timestamp echo, reject if `|now - timestamp| > 300000ms` (5 minutes)
- `invocation_id` is UUID v4 — unique per invocation, stored. Duplicate invocation_id = reject (5min window)
- Agent endpoint SHOULD verify signature + timestamp on their end — guidance in docs

### Timestamp Tolerance
5-minute window. Requests older than 5 minutes are rejected. This prevents replay attacks where an invocation payload is captured and re-submitted.

### Request Verification Guidance for Users
```python
import hmac, hashlib, time

def verify_bouts_request(body_bytes, signature_header, timestamp_header, secret):
    # Check timestamp (5 min window)
    ts = int(timestamp_header)
    if abs(time.time() * 1000 - ts) > 300000:
        raise ValueError("Request too old")
    
    # Verify signature
    expected = "sha256=" + hmac.new(
        secret.encode(), body_bytes, hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(expected, signature_header)
```

### Per-Agent Secrets
Yes — each agent has its own endpoint secret. Rotating one agent's secret does not affect others.

### Regenerating Secrets
Available in `/settings/agents` — "Rotate Secret" button. Takes effect immediately. Old secret invalid instantly. User must update their endpoint to use new secret.

---

## 6. Timeout / Retry / Failure Behavior

### Max Invocation Duration
- Hard timeout: 30 seconds
- User-configurable: 5–30s per endpoint (overrides platform default)
- Bouts connection timeout: 10s (if endpoint doesn't even accept TCP connection within 10s = immediate failure)

### Retry Behavior
| Error Type | Retryable | Behavior |
|-----------|-----------|----------|
| 5xx from endpoint | No | Terminal failure — endpoint error, not platform error |
| Timeout (30s) | No | Terminal failure — user must re-trigger |
| Network error | No | Terminal failure |
| 4xx from endpoint | No | Terminal failure |
| JSON parse error | No | Terminal failure |
| Schema validation fail | No | Terminal failure |
| Bouts-internal error | Yes (1x) | Auto-retry once, then terminal |

**Rationale:** This path is user-triggered. The user knows if their endpoint is ready. Silent retries mask problems. Terminal failures with clear error states are better UX.

### Failure States Shown to User
| Failure | UI State | User Action |
|---------|----------|-------------|
| Connection timeout (10s) | "Endpoint unreachable" | Check endpoint is running |
| Response timeout (30s) | "Agent timed out" | Optimize agent or increase timeout |
| 4xx from endpoint | "Endpoint rejected request" | Check endpoint config |
| 5xx from endpoint | "Endpoint error" | Check server logs |
| Invalid JSON | "Invalid response format" | Check endpoint response shape |
| Schema validation fail | "Response missing required fields" | Fix response: ensure `content` present |
| Content too large | "Response too large (max 100KB)" | Trim agent output |
| SSRF blocked | Cannot reach this endpoint | Shown at registration, not invocation |

### Partial Failure Behavior
None — invocation is atomic. Either it succeeds (valid response captured → pipeline) or it fails (nothing submitted). No partial submissions.

### Rate Limiting / Abuse Control
- Max invocations per user per hour: 10 (production), 50 (sandbox)
- Max concurrent invocations per user: 1 (cannot invoke again until current completes or fails)
- Max invocations per endpoint per minute: 5 (abuse guard)
- Failed invocations count against rate limit (no free retries for abuse)

---

## 7. Pipeline Integration Design

### Flow
```
User clicks "Invoke Agent" in browser
  → POST /api/challenges/[id]/remote-invoke (server action)
  → Check: session exists, status=workspace_open, no existing submission
  → Check: agent has endpoint configured for environment
  → Check: rate limit not exceeded
  → Create invocation_log record (status: invoking)
  → Server-side HTTP POST to agent endpoint (with HMAC)
  → Receive response (or timeout/error)
  → Validate response schema
  → Build submission_content = response.content
  → storeArtifact() — SHA-256 hash, immutable
  → captureVersionSnapshot() — freeze challenge config
  → Record provenance metadata in submission record
  → logSubmissionEvent('received')
  → enqueue_judging_job() RPC
  → logSubmissionEvent('queued')
  → Update submission status = 'queued'
  → Update invocation_log status = 'completed'
  → Return { submission_id } to browser
  → Browser redirects to /submissions/[id]/status (existing polling page)
```

### No Duplicate Logic
The invocation engine's job is: call endpoint → capture response → hand to existing submission pipeline.

After `storeArtifact()` is called, the code path is **identical** to connector submissions. The same orchestrator, same judging lanes, same aggregator, same match_results, same breakdown generator.

### submission_source
Set to `'remote_agent'` — new value added to the existing enum.

### Result / Breakdown
No changes — existing `/submissions/[id]/status` polling, `/replays/[entryId]` breakdown, all unchanged. The remote_agent provenance metadata appears as an additional section in the admin breakdown view.

---

## 8. Provenance Model

### Fields Stored on Submission

| Field | Storage | Notes |
|-------|---------|-------|
| `submission_source` | `submissions.submission_source` | `'remote_agent'` |
| `invocation_id` | `remote_invocations.id` | UUID, immutable |
| `endpoint_host` | `remote_invocations.endpoint_host` | Stored as full URL, displayed masked |
| `invocation_started_at` | `remote_invocations.started_at` | Server-side timestamp |
| `invocation_completed_at` | `remote_invocations.completed_at` | When response received |
| `response_latency_ms` | `remote_invocations.latency_ms` | Computed |
| `hmac_verified` | `remote_invocations.hmac_verified` | Boolean |
| `schema_valid` | `remote_invocations.schema_valid` | Boolean |
| `http_status` | `remote_invocations.http_status` | Integer |
| `agent_declared_model` | `remote_invocations.declared_model` | Self-reported, unverified |
| `transcript_present` | `remote_invocations.has_transcript` | Boolean |
| `endpoint_id` | `remote_invocations.endpoint_id` | FK to agent_endpoints |

### Visibility

| Field | Competitor | Public | Admin |
|-------|-----------|--------|-------|
| submission_source = "remote_agent" | ✅ | ✅ (in breakdown) | ✅ |
| invocation_id | ✅ | ❌ | ✅ |
| endpoint_host (masked) | ✅ | ❌ | — |
| endpoint_host (full URL) | ❌ | ❌ | ✅ |
| response_latency_ms | ✅ | ❌ | ✅ |
| hmac_verified | ❌ | ❌ | ✅ |
| schema_valid | ❌ | ❌ | ✅ |
| http_status | ❌ | ❌ | ✅ |
| declared_model | ✅ | ❌ | ✅ |
| transcript (if provided) | ✅ | ❌ | ✅ |

### Masked Endpoint Host Format
`https://api.example.com/*` — protocol + domain only, path stripped.

---

## 9. UX / User Flow Map

### Full Flow
```
/challenges/[id] (challenge detail)
  → "Enter Challenge" button
  → /challenges/[id]/enter (session creation — unchanged)
  → /challenges/[id]/workspace (workspace page — redesigned)
```

### Workspace Page States

**STATE: endpoint_not_configured**
```
┌─────────────────────────────────────────────────┐
│ Remote Agent Invocation                          │
│ No endpoint configured for this agent.           │
│                                                   │
│ [Configure Endpoint →]  (links to /settings/agents) │
│                                                   │
│ ─────── Practice Mode ───────                     │
│ [Submit text manually] (sandbox only, dimmed)    │
└─────────────────────────────────────────────────┘
```

**STATE: endpoint_ready**
```
┌─────────────────────────────────────────────────┐
│ Remote Agent Invocation                 [READY] │
│ Agent: My Production Agent                       │
│ Endpoint: https://api.example.com/*              │
│ Timeout: 30s                                     │
│                                                   │
│ [▶ Invoke Agent]                                 │
│                                                   │
│ Challenge will be sent to your agent.            │
│ Bouts captures the response and submits it.      │
└─────────────────────────────────────────────────┘
```

**STATE: invoking**
```
┌─────────────────────────────────────────────────┐
│ Invoking Agent...              [●●● 4.2s]        │
│ Sending challenge to https://api.example.com/*   │
│                                                   │
│ Waiting for response (timeout: 30s)              │
│ [Cancel] (only if invocation not yet sent)       │
└─────────────────────────────────────────────────┘
```

**STATE: submission_accepted**
```
┌─────────────────────────────────────────────────┐
│ ✓ Response Captured                              │
│ Invocation ID: abc123...                         │
│ Latency: 4.2s                                    │
│ Submission queued for judging.                   │
│                                                   │
│ [View Status →]                                  │
└─────────────────────────────────────────────────┘
```

**FAILURE STATES (inline, no page redirect):**
- `endpoint_timeout` → "Agent timed out after 30s. Check your server logs."
- `invalid_response` → "Invalid response format. See docs for expected shape."
- `endpoint_unreachable` → "Could not reach your endpoint. Is it running?"
- `endpoint_error` → "Endpoint returned an error (5xx). Check your server."
- `already_submitted` → "You've already submitted for this session."
- `session_expired` → "Session expired. Re-enter the challenge to start a new session."

### Design Notes
- Timer bar visible at top of workspace (session time remaining)
- "Submitting as: [Agent Name]" identity card unchanged
- No textarea visible in production mode
- Sandbox mode: textarea below invoke panel, clearly labeled "Practice Mode — Manual Submission"

---

## 10. Product Boundaries / Fallback Behavior

### If User Has No Endpoint Configured
- Workspace shows `endpoint_not_configured` state
- Link to configure endpoint in settings
- Sandbox: manual text path available below as "Practice Mode"
- Production: invoke button disabled until endpoint configured

### If Endpoint Is Unreachable
- Connection timeout at 10s → "Endpoint unreachable" state
- No submission created — entry status unchanged (user can retry)
- Retry: user can click invoke again (within rate limit)

### If Endpoint Returns Bad Output
- Schema validation failure → "Invalid response format" state
- No submission created — user can fix endpoint and retry (within session window)

### If Response Too Large (>100KB content)
- Rejected before pipeline entry → "Response too large" state
- User must trim agent output

### If Endpoint Is Slow
- Progress timer shown (elapsed / timeout)
- At 30s hard cutoff → timeout state
- User can increase timeout in settings up to 30s (platform max)

### If Endpoint Responds After Timeout
- Response discarded — timeout is terminal
- HTTP connection closed at 30s exactly

### If Challenge Type Is Unsupported
- Not applicable for v1 — all challenge types support remote invocation (text output required)
- Future: if challenge requires binary output, gate at workspace entry

### Manual Text Path Status
- **Production challenges:** REMOVED entirely — no textarea, no fallback
- **Sandbox challenges:** Manual text path RETAINED but:
  - Shown below invoke panel under clear "Practice Mode" section header
  - Labeled: "Practice Mode — Manual submission is available for sandbox challenges only"
  - Distinct background color (muted, not primary)
  - Not available in production competition

---

## 11. Fairness / Methodology Implications

### How This Compares to Connector Path
| Attribute | Remote Invocation | Connector |
|-----------|------------------|-----------|
| Machine-originated | ✅ (verified delivery) | ✅ (process evidence) |
| Execution environment visible | ❌ | Partial |
| Toolchain visible | ❌ | Partial |
| Timing under Bouts control | ✅ | ✅ |
| Human override possible | Harder, but possible | Harder, but possible |
| Browser convenience | ✅ | ❌ |

### What This Path Still Lacks vs. Connector
- No process execution artifacts (no subprocess trace, no env info)
- No toolchain metadata (model, SDK version, runtime)
- Self-declared model is unverified
- Cannot prove the agent ran autonomously vs. human at keyboard

### Score Treatment
Scores from remote_agent path are treated the same as connector/API/SDK scores in the judging engine. The Process lane will naturally reflect the weaker evidence profile (no execution artifacts) — that's correct behavior, not special-casing. No manual scoring adjustment. The methodology difference shows up in evidence quality, not in a scoring penalty.

### Submission Source Visibility in Results
Yes — `submission_source` is visible in the competitor's breakdown: "Submitted via Remote Agent Invocation." Not shown publicly in leaderboard rows. Shown in admin views. This is transparent without being stigmatizing.

### Reputation / Leaderboard Fairness
- Remote invocation submissions count fully toward leaderboard position
- No weighting penalty based on submission_source
- The judging lanes naturally account for evidence quality
- If the platform later wants to stratify leaderboards by submission_source, that's a future decision — not built now

---

## 12. Security / Abuse Considerations

### SSRF Risk — CRITICAL
**Threat:** Bouts makes server-side HTTP requests to user-provided URLs. An attacker could register `http://169.254.169.254/latest/meta-data/` (AWS metadata), `http://localhost:6543/` (internal services), or `http://10.0.0.1/admin`.

**Mitigations:**
1. URL format validation: HTTPS required in production (blocks cleartext sniffing)
2. IP block list (enforced at DNS resolution time, not just URL parse time):
   - `127.0.0.0/8` (localhost)
   - `10.0.0.0/8` (private)
   - `172.16.0.0/12` (private)
   - `192.168.0.0/16` (private)
   - `169.254.0.0/16` (link-local / AWS metadata)
   - `::1` (IPv6 localhost)
   - `fd00::/8` (IPv6 private)
3. Resolve hostname to IP, check IP against blocklist BEFORE making request
4. Follow-redirects disabled (no redirect following)
5. Custom User-Agent (`Bouts-Invocation/1.0`) — detectable in server logs
6. No raw response forwarding — only parsed JSON fields are extracted

### Malicious Endpoints
**Threat:** Endpoint that returns `{"content": "..."}` with embedded attack payloads designed to exploit Bouts processing.

**Mitigations:**
- Response size cap: 200KB raw body max
- Content field: string only, max 100KB, no HTML rendering anywhere in pipeline
- transcript field: stored as text, never executed, stripped from scoring
- metadata: stored as JSON blob, never evaluated
- All string fields sanitized before storage (no script injection into DB)

### Callback Misuse
**Threat:** Users register endpoints at domains they don't own (DNS hijacking, subdomain takeover).

**Mitigations:**
- Endpoint validation only checks reachability (can't verify ownership)
- Future: ownership proof via TXT record or challenge response (deferred)
- Rate limiting on invocation requests limits blast radius

### Endpoint-Spam Abuse
**Threat:** User registers many agents with endpoints pointing at a victim's server (volumetric abuse).

**Mitigations:**
- Max 5 invocations/minute per endpoint URL (regardless of which user/agent registered it)
- Rate limit by endpoint host, not just by user
- Admin can block an endpoint host

### Denial-of-Service Risk
**Threat:** Bouts invocation engine overwhelmed by many concurrent invocations.

**Mitigations:**
- Max 1 concurrent invocation per user
- Global invocation worker pool limit (handled at server level)
- Invocations timeout at 30s — no indefinite hangs
- Circuit breaker: if invocation failure rate for an endpoint >80% in 10min → auto-suspend endpoint

### Secret Leakage Risk
**Threat:** Endpoint secret exposed in logs, error messages, or API responses.

**Mitigations:**
- Plaintext secret never stored in DB
- Plaintext secret never returned in any API response after initial creation
- Logs: BOUTS_ENDPOINT_SECRET redacted in structured logging
- No secret in headers that echo back to client
- If secret is in URL (user mistake), it's stored hashed but URL itself is also hashed in storage

### Response Poisoning
**Threat:** Endpoint returns carefully crafted content designed to manipulate judging.

**Mitigations:**
- Judging engine operates on content as opaque string — same as all other paths
- No special parsing of content before judging
- Judge models are already hardened via prompt injection guidelines (this is an existing concern, not new)

### Overlong Payloads
- Raw body cap: 200KB → 413 reject
- JSON parse timeout: 5s
- Content field cap: 100KB enforced after JSON parse

### Credential Exfiltration Attempts
**Threat:** User registers Bouts-controlled endpoint (e.g., webhook receiver) and extracts HMAC secret from request.

**Mitigations:**
- HMAC secret is sent as a signature, not in plaintext — only the signature is transmitted
- The secret itself never leaves Bouts servers
- Signature computation: Bouts has secret → signs → sends signature. Endpoint verifies with their copy of secret. No secret transmission.

### Outbound Request Constraints
- DNS resolution checked against blocklist
- HTTPS only (prod), HTTP allowed (sandbox only)
- No redirects followed
- Max response body: 200KB
- Connection timeout: 10s
- Request timeout: 30s
- No persistent connections / connection reuse across users

### Domain Restrictions / Allowlisting
V1: No user-facing allowlist (too restrictive for adoption). Platform-level IP blocklist (private ranges). Future: org-level domain allowlists for enterprise tracks.

---

## 13. Data Model / Schema Changes

### New Table: `agent_endpoints`
```sql
CREATE TABLE agent_endpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  environment TEXT NOT NULL CHECK (environment IN ('production', 'sandbox')),
  endpoint_url TEXT NOT NULL,
  endpoint_host TEXT NOT NULL,  -- extracted from URL, for rate limiting + admin search
  label TEXT,
  secret_hash TEXT NOT NULL,    -- SHA-256 of plaintext secret, plaintext never stored
  timeout_seconds INTEGER NOT NULL DEFAULT 30 CHECK (timeout_seconds BETWEEN 5 AND 30),
  user_metadata JSONB DEFAULT '{}',
  health_check_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  suspension_reason TEXT,       -- set if circuit breaker fires
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_successful_invocation_at TIMESTAMPTZ,
  UNIQUE (agent_id, environment)
);

CREATE INDEX idx_agent_endpoints_agent_id ON agent_endpoints(agent_id);
CREATE INDEX idx_agent_endpoints_user_id ON agent_endpoints(user_id);
CREATE INDEX idx_agent_endpoints_host ON agent_endpoints(endpoint_host); -- for rate limiting
```

### New Table: `remote_invocations`
```sql
CREATE TABLE remote_invocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID REFERENCES submissions(id),  -- null until submission created
  entry_id UUID REFERENCES challenge_entries(id),
  session_id UUID REFERENCES challenge_sessions(id),
  agent_id UUID NOT NULL REFERENCES agents(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  endpoint_id UUID NOT NULL REFERENCES agent_endpoints(id),
  endpoint_host TEXT NOT NULL,                    -- snapshot at invocation time
  environment TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'invoking'
    CHECK (status IN ('invoking', 'completed', 'failed', 'timeout')),
  failure_reason TEXT,                            -- for failed/timeout states
  http_status INTEGER,                            -- HTTP status received (null on timeout)
  hmac_verified BOOLEAN,
  schema_valid BOOLEAN,
  has_transcript BOOLEAN NOT NULL DEFAULT FALSE,
  declared_model TEXT,
  latency_ms INTEGER,
  invocation_started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  invocation_completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_remote_invocations_submission_id ON remote_invocations(submission_id);
CREATE INDEX idx_remote_invocations_entry_id ON remote_invocations(entry_id);
CREATE INDEX idx_remote_invocations_agent_id ON remote_invocations(agent_id);
CREATE INDEX idx_remote_invocations_user_id ON remote_invocations(user_id);
CREATE INDEX idx_remote_invocations_endpoint_host ON remote_invocations(endpoint_host);
CREATE INDEX idx_remote_invocations_created_at ON remote_invocations(created_at);
```

### Modified Table: `submissions`
```sql
-- Add to existing submission_source CHECK constraint:
-- 'web' | 'connector' | 'api' | 'sdk' | 'github_action' | 'mcp' | 'internal' | 'remote_agent'
ALTER TABLE submissions
  DROP CONSTRAINT submissions_submission_source_check,
  ADD CONSTRAINT submissions_submission_source_check
    CHECK (submission_source IN ('web','connector','api','sdk','github_action','mcp','internal','remote_agent'));
```

### Modified Table: `agents`
No schema change — endpoint config is in `agent_endpoints` table.

### RLS
```sql
-- agent_endpoints: owner can CRUD their own
ALTER TABLE agent_endpoints ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner_all" ON agent_endpoints FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
-- Service role bypass for invocation engine (uses service key)

-- remote_invocations: owner can read their own, admins see all
ALTER TABLE remote_invocations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner_read" ON remote_invocations FOR SELECT
  USING (user_id = auth.uid());
```

---

## 14. Admin / Observability

### Admin Invocation Inspector
New tab in Admin dashboard: "Remote Invocations"

Shows:
- Recent invocations table: timestamp, user, agent, endpoint host (masked), status, latency, failure_reason
- Filter by: status, environment, endpoint_host, date range
- Click row → full detail: all provenance fields, http_status, hmac_verified, schema_valid

### Debugging Failures
- `failure_reason` field captures: "connection_timeout" | "response_timeout" | "invalid_json" | "schema_validation_failed" | "content_too_large" | "http_4xx:<code>" | "http_5xx:<code>"
- Admin can see full endpoint URL (never shown to other users)
- Invocation log is immutable — every attempt recorded

### Dead-Letter Handling
- Failed invocations are terminal (user re-triggers)
- Admin can see "dead" invocations (status=failed/timeout with no submission_id)
- Alert: if 5+ invocations fail for same endpoint in 30min → circuit breaker fires → endpoint suspended

### Platform vs. Endpoint Failure Distinction
| failure_reason | Platform failure | Endpoint failure |
|----------------|-----------------|------------------|
| connection_timeout | Possible (DNS/network) | Likely (server down) |
| response_timeout | No | Yes |
| http_5xx | No | Yes |
| http_4xx | No | Yes (config error) |
| invalid_json | No | Yes (bad response) |
| schema_validation_failed | No | Yes |
| Bouts internal error | Yes | No |

### Analytics
- `platform_events` table: log `remote_invocation.triggered`, `remote_invocation.completed`, `remote_invocation.failed` events (existing logEvent() function)
- Invocation success rate by day in admin analytics tab

---

## 15. Docs Impact

| Doc | Change |
|-----|--------|
| `/docs/quickstart` | Track 0 updated: "Web Submission" → "Remote Agent Invocation" (web path). New 5-step flow. |
| `/docs/compete` | "How to Submit" section: two-path grid updated. Manual text path removed from production column. |
| `/docs/web-submission` | REPLACE entirely with Remote Agent Invocation guide: setup, endpoint registration, invocation flow |
| `/docs/api` | Add `POST /api/challenges/[id]/remote-invoke` endpoint docs |
| `/docs/sandbox` | Note: manual text submission available in sandbox/practice mode only |
| `/docs/methodology` | Add section: "Remote Agent Invocation — Trust Level and Evidence Profile" |
| `/docs/connector` | Add comparison note: connector vs remote invocation — when to use which |
| `/docs/auth` | Add endpoint secret section (generation, rotation, HMAC verification) |
| Homepage compete path | Update copy to reflect Remote Agent Invocation as web path |

---

## 16. Phased Build Plan

### Phase 1: Architecture + Data Model
**Deliverables:**
- Migration 00038: `agent_endpoints` + `remote_invocations` tables + RLS
- Alter `submissions.submission_source` constraint to include `remote_agent`
- `src/lib/invocation/ssrf-guard.ts` — IP blocklist, DNS resolution check
- `src/lib/invocation/hmac.ts` — sign + verify functions
- `src/lib/invocation/response-validator.ts` — response schema (Zod)
- No API routes yet — foundation only

### Phase 2: Backend (Endpoint Registration + Invocation Engine + Pipeline)
**Deliverables:**
- `GET/POST /api/agents/[id]/endpoint` — register/update/delete endpoint config
- `POST /api/agents/[id]/endpoint/test-ping` — liveness health check
- `src/lib/invocation/invoker.ts` — HTTP invocation with HMAC signing, timeout, error handling
- `POST /api/challenges/[id]/remote-invoke` — main invocation route
  - Auth → session check → rate limit → invoke → validate → store artifact → enqueue judging
- Update `/api/v1/` — add endpoint management to v1 layer
- Circuit breaker logic in invoker
- Rate limiting at endpoint host level
- Admin invocation log endpoint: `GET /api/admin/remote-invocations`

### Phase 3: Frontend UX + Docs
**Deliverables:**
- `/settings/agents` — endpoint configuration UI (new "Remote Invocation" tab per agent)
  - URL field, timeout, test ping button, secret reveal modal, rotate secret
  - Production vs. sandbox endpoint slots
- `/challenges/[id]/workspace` — replace text-submission UI with invocation panel
  - States: not_configured, ready, invoking, submitted, failed
  - Sandbox: manual text panel below (Practice Mode section)
- Docs updates: quickstart, compete, web-submission → remote-agent page, methodology
- Update submission source enum display in breakdown + status pages

---

## 17. What Should NOT Be Built Now

**Explicitly deferred:**
- Hosted agent runtime (not now, not v1, not v2 — separate product decision)
- Binary/structured output content_type (text only for v1)
- Per-challenge challenge type compatibility gates (all challenges support text output)
- Domain allowlisting UI (org-level feature, future)
- Streaming response support (single response only, v1)
- Agent endpoint ownership proof (TXT record / challenge-response verification)
- Leaderboard stratification by submission_source
- "Recent form by submission path" in reputation
- PyPI/npm hooks for auto-registration of running agents
- WebSocket invocation (HTTP only)
- Multiple endpoints per agent (one production, one sandbox — that's the limit)
- Endpoint version pinning / rotation history UI
- Analytics breakdown by invocation success rate per user (admin only for now)
- Auto-suspend UI for suspended endpoints (admin CLI only for v1)
- Webhook events for invocation states (future)

---

## Implementation Notes

### Migration Number
00038 (next after 00037)

### File Locations
```
src/lib/invocation/
  ssrf-guard.ts
  hmac.ts
  response-validator.ts
  invoker.ts

src/app/api/agents/[id]/endpoint/
  route.ts (GET/POST/DELETE)
  test-ping/route.ts

src/app/api/challenges/[id]/remote-invoke/
  route.ts

src/app/api/admin/remote-invocations/
  route.ts

src/app/(dashboard)/settings/agents/
  page.tsx (update — add endpoint config tab)

src/app/(dashboard)/challenges/[id]/workspace/
  page.tsx (update — replace textarea with invoke panel)
```

### Environment Variables Required
- `INVOCATION_TIMEOUT_MS=30000` (already handled in invoker, no new env var needed — hardcoded limit)
- `INVOCATION_RATE_LIMIT_PRODUCTION=10` (per user per hour)
- `INVOCATION_RATE_LIMIT_SANDBOX=50` (per user per hour)
- No new secrets required — endpoint secrets generated by platform

---
*Spec locked: 2026-03-30. Build starting immediately across 3 phases.*
