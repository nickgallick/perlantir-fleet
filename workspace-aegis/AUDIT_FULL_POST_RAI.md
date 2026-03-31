# Aegis — Full Platform Security Audit (Post-RAI Rollout)
**Date:** 2026-03-31
**Scope:** Full platform security, abuse resistance, and trust integrity after RAI rollout
**Auditor:** Aegis
**Commit audited:** 812b72d (RAI full remediation pass R-Fix-1 through R-Fix-6)
**Verdict:** PLATFORM TRUST MODEL HOLDS — No P0/P1 blockers found

---

## Coverage Summary

| Area | Result |
|------|--------|
| RAI-specific trust/security (12 items) | All pass |
| Auth and API boundary checks | All pass |
| Admin API gating | All pass |
| Internal/cron endpoint gating | All pass |
| Legacy submission path isolation | Pass |
| Data exposure / information hygiene | Pass |
| Platform integrity (duplication, ownership, race) | Pass |
| Key/secret exposure | Pass — one P3 observation |

---

## Section 1 — RAI-Specific Trust/Security

All items verified in prior AUDIT_RAI_REMEDIATION_VERIFICATION.md and re-confirmed in this audit:

- ✅ Explicit opt-in per challenge (default false, NOT NULL)
- ✅ DB: 185/187 challenges rai=False; 2 explicitly enabled production challenges
- ✅ SSRF at registration: validateEndpointUrl() called before DB write
- ✅ SSRF at invocation: validateEndpointUrl() + isPrivateIp() called before fetch
- ✅ Redirect fail-closed: redirect:'error' on outbound fetch
- ✅ Missing secret: halts before network call with clear error
- ✅ Non-HTTPS: blocked at registration and invocation
- ✅ Zero retries: maxRetries: 0 hardcoded in invoke route
- ✅ Provenance visibility: spectator=source_only, competitor=host+timing+hash, admin=full
- ✅ Trust language in docs matches implementation
- ✅ Signature verification docs match sign-request.ts exactly

---

## Section 2 — Auth and API Boundary Checks

All live-tested. Results:

| Endpoint | Unauthed result | Expected | Pass? |
|----------|----------------|----------|-------|
| /api/me | 401 | 401 | ✅ |
| /api/admin/challenges | 401 | 401 | ✅ |
| /api/admin/forge-review | 401 | 401 | ✅ |
| /api/admin/inventory | 401 | 401 | ✅ |
| /api/admin/calibration POST | 401 | 401 | ✅ |
| /api/admin/analytics | 401 | 401 | ✅ |
| /api/admin/analytics/funnel | 401 | 401 | ✅ |
| /api/admin/analytics/retention | 401 | 401 | ✅ |
| /api/admin/analytics/access-modes | 401 | 401 | ✅ |
| /api/admin/developer-metrics | 401 | 401 | ✅ |
| /api/admin/health-dashboard | 401 | 401 | ✅ |
| /api/admin/judging-queue | 401 | 401 | ✅ |
| /api/admin/intake-queue | 401 | 401 | ✅ |
| /api/admin/jobs | 401 | 401 | ✅ |
| /api/admin/ballot | 401 | 401 | ✅ |
| /api/internal/run-migration | 401 | 401 | ✅ |
| /api/internal/judge | 401 | 401 | ✅ |
| /api/internal/apply-migration | 401 | 401 | ✅ |
| /api/cron/challenge-quality | 401 | 401 | ✅ |
| /api/cron/gauntlet | 401 | 401 | ✅ |
| /api/cron/process-judging-jobs | 401 | 401 | ✅ |
| /api/challenges/intake (no key) | 401 | 401 | ✅ |
| /api/challenges/intake (wrong key) | 401 | 401 | ✅ |
| /api/challenges/[id]/invoke | 401 | 401 | ✅ |
| /api/challenges/[id]/web-submit | 401 | 401 | ✅ |
| /api/challenges/[id]/enter | 401 | 401 | ✅ |
| /api/challenges/[id]/workspace | 401 | 401 | ✅ |
| /api/connector/submit | 401 | 401 | ✅ |
| /api/connector/heartbeat | 401 | 401 | ✅ |
| /api/notifications | 401 | 401 | ✅ |
| /api/violations | 401 | 401 | ✅ |
| /api/prizes/claim | 401 | 401 | ✅ |
| /api/v1/auth/tokens | 401 | 401 | ✅ |
| /api/v1/webhooks | 401 | 401 | ✅ |
| /api/v1/orgs | 401 | 401 | ✅ |
| /api/v1/agents/[id]/endpoint | 401 | 401 | ✅ |
| /api/v1/agents/[id]/endpoint/ping | 401 | 401 | ✅ |
| /api/v1/agents/[id]/endpoint/validate | 401 | 401 | ✅ |
| /api/v1/agents/[id]/endpoint/rotate-secret | 401 | 401 | ✅ |
| /api/v1/results/[id] | 401 | 401 | ✅ |
| /qa-login | 404 | 404 | ✅ |
| /api/auth/qa-login | 404 | 404 | ✅ |

Public endpoints (200): /api/health, /api/challenges, /api/leaderboard, /api/agents, /api/status — all correct.

### Cron Auth Model
All three cron endpoints use `isCronAuthorized()` — fail-closed: requires either Vercel's `x-vercel-cron: 1` header OR `Authorization: Bearer CRON_SECRET`. Without either, returns 401. Confirmed correct.

### Internal Endpoint Auth Model  
Internal endpoints use CRON_SECRET or INTERNAL_WEBHOOK_SECRET. /api/internal/migrate-038 uses service role key as auth. All verified 401 on unauthed requests.

### GAUNTLET_INTAKE_API_KEY scoping
Key is server-side only (`process.env.GAUNTLET_INTAKE_API_KEY`). Not exposed via NEXT_PUBLIC_ prefix. Not in next.config.ts. Only referenced in `/api/challenges/intake/route.ts`. Using it on admin or user endpoints returns 401.

### Org/Private Challenge Visibility
`/api/challenges` filters to `org_id IS NULL` for unauthenticated users. Authenticated users see their own org challenges. No cross-org leakage confirmed by query review.

### Sandbox Isolation
Sandbox challenges (3 active) do not appear in `/api/challenges` public list (confirmed: 0 sandbox in 2 returned active). Sandbox challenges are accessible directly by ID but not surfaced in discovery. Sandbox web-submission supported (rai=false) — cannot be invoked via RAI.

---

## Section 3 — Legacy Path Trust Risks

### Old web text submission
`/api/challenges/[id]/web-submit` exists but:
- Requires `web_submission_supported = true` (default false)
- Only 5 challenges have this enabled: 3 sandbox (rai=false) + 2 production RAI challenges
- All 5 are deliberately enabled
- Route itself is auth-gated (401 unauthed)
- Tags submission_source='web' — visible in breakdown, not hidden
- **NOT a hidden trust loophole.**

### Deprecated v1 submissions endpoint
`POST /api/v1/submissions` returns HTTP 410 DEPRECATED with redirect to new session-based flow. No submission accepted.

### No unverifiable second-class path found.
All submission paths (connector, web, RAI, SDK, API) tag `submission_source` and require auth. No path produces a submission without an ownership trace.

---

## Section 4 — Data Exposure / Information Hygiene

### Public challenge list (`/api/challenges`)
Keys exposed: id, title, description, category, format, weight_class_id, status, time_limit_minutes, max_coins, entry_fee_cents, prize_pool, platform_fee_percent, starts_at, ends_at, entry_count, is_featured, is_daily, web_submission_supported, created_at, difficulty_profile, challenge_type

Admin-only fields NOT present: pipeline_status, cdi_score, hidden_tests, judge_config, calibration, quarantine_reason, forge_review, bundle, activation_snapshot. ✅

### Challenge detail (`/api/challenges/[id]`)
Same clean field set. `remote_invocation_supported` and `web_submission_supported` are visible — this is intentional (users need to know if they can use these paths). No admin-only fields present.

### Agent public list (`/api/agents`, `/api/v1/agents`)
Fields: id, name, model_name, bio, avatar_url, created_at, capability_tags, domain_tags, is_online, availability_status, contact_opt_in, verified_at
No endpoint URLs, no secrets, no API keys. ✅

### Breakdown endpoint
`/api/submissions/[id]/breakdown` uses `getUser()` (optional auth). Unauthenticated = spectator audience = source badge only. No private data exposed to anonymous users. ✅

### Error response hygiene
- Bad UUID → `{"error":"Invalid challenge ID"}` — clean
- SQL injection attempt → 400 — clean
- Malformed JSON → appropriate error — clean
- No stack traces, no internal paths, no Postgres relation names observed. ✅

### /api/status
Returns: status, updated_at, metrics, services, activity_series — public operational metrics only. No keys, no internal data. ✅

---

## Section 5 — Platform Integrity Risks

### Duplicate submission race protection
DB-level UNIQUE INDEX on `submissions(entry_id)` (migration 00036). Any concurrent duplicate INSERT races at DB constraint level — one wins, one gets unique violation. Application layer also checks entry terminal status before insert. Two-layer protection. ✅

### Submission ownership enforcement
All submission paths verify agent ownership via authenticated user's `user_id` → agent lookup → entry ownership. Cross-user submission not possible. ✅

### Challenge/entry ownership enforcement
`challenge_entries` queries always filter by `agent_id` (which requires authenticated user → their agent). No cross-entry access. ✅

### Replay/result audience gating
`/api/replays/[entryId]` returns 403 for unfinalized results. Breakdown endpoint uses audience scoping (spectator/competitor/admin). ✅

### Connector submit terminal status check
Connector submit route explicitly checks `TERMINAL_STATUSES` and returns 409 before accepting a second submission on a terminal entry. ✅

### RAI race condition
The idempotency check in invoke route + DB UNIQUE INDEX on entry_id provides two-layer protection. Concurrent invocations: first to write wins; second gets unique constraint violation mapped to platform error (entry_consumed: false). ✅

### Cron fail-open patterns
`isCronAuthorized()` is fail-closed: if CRON_SECRET not set AND no Vercel header → always 401. No fail-open condition. ✅

### New RAI attack surface
- SSRF: blocked at registration and invocation (two layers)
- Redirect chains: blocked (redirect:'error')
- Rate limit: 3 invocations per 5 minutes per user (abuse throttle)
- Nonce replay: nonce claimed per attempt, unique DB constraint
- Secret exposure: plaintext secret in `agent_rai_secrets` (service-role RLS, JWT-blocked), hash only on `agents` table
- Endpoint URL in error responses: only hostname exposed to competitor, full URL admin-only ✅

---

## Findings

### P3 — AEG-P3-001: GAUNTLET_INTAKE_API_KEY in workspace TOOLS.md and MEMORY.md

**Severity:** P3 (operational hygiene)
**Category:** Secret management / documentation hygiene
**Affected:** Workspace documentation files, not the production app
**Route:** N/A — not an application vulnerability

The `GAUNTLET_INTAKE_API_KEY` (`a86c6d887c15c5bf259d2f9bcfadddf9`) is documented in `/data/.openclaw/workspace-aegis/TOOLS.md` and referenced in workspace memory. It is also the same value in `.env.production.local`. This key is not exposed in the production app (no NEXT_PUBLIC_ exposure, not in next.config.ts, not in any public response). However it is in plaintext in agent workspace files which are committed to the fleet git repo.

**Risk:** Anyone with access to the fleet repo or workspace files has this key and can submit challenges to the intake pipeline. This would not create fraudulent competition results (intake submissions go through full calibration and admin review before activation) but represents unnecessary key exposure.

**Recommendation:** Rotate the GAUNTLET_INTAKE_API_KEY periodically. Remove from workspace documentation files once operational memory no longer needs it.

**Reproduction:**
```bash
grep "GAUNTLET_INTAKE_API_KEY" /data/.openclaw/workspace-aegis/TOOLS.md
# → GAUNTLET_INTAKE_API_KEY: a86c6d887c15c5bf259d2f9bcfadddf9
```

---

**No P0, P1, or P2 findings.**

---

## Final Verdict

**Platform trust model holds. No remaining trust or security blockers found.**

All auth boundaries verified correct. All admin routes gated. All cron/internal endpoints fail-closed. RAI path fully secured. Legacy paths isolated. No data leakage in public responses. Duplicate/race protections in place. No visible keys or secrets in any public-facing endpoint or response.

The platform is trust-safe for launch after the RAI rollout.
