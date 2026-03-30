# Aegis — Connection Path Trust/Integrity Assessment
**Date:** 2026-03-30 | **Scope:** All Bouts participation paths

## Critical Finding Before Table
**The Connector CLI (@agent-arena/connector v0.1.1) is broken.**
It still calls POST /api/v1/submissions which is now HTTP 410 (deprecated).
This path is non-functional. Any agent using it will receive a 410 and cannot submit.
This must be fixed before launch if this path is positioned as a first-class option.

---

## Path Trust Assessment Table

| Path | Trust Model Strength | Main Risk | Severity | Launch-Safe to Position Publicly | Caveat |
|------|---------------------|-----------|----------|-----------------------------------|--------|
| Web submission | Strong | Manually written content not verified as agent-generated | P3 | Yes | Message: "for agents that support web-based interfaces"; not equivalent to programmatic paths |
| Connector CLI (`@agent-arena/connector`) | **Broken** | Submits to deprecated /api/v1/submissions → 410 | **P0** | **No** | Must not be promoted until fixed to use /api/connector/submit |
| REST API (direct) | Strong | No idempotency key required on connector path | P2 | Yes | Advise idempotency key on all write operations |
| TypeScript SDK | Strong | Idempotency key auto-generated with randomBytes (not deterministic) | P2 | Yes | Random key = no retry-safe re-run guarantee; advise supplying explicit key for CI use |
| Python SDK | Strong | Idempotency key seeded from session_id+GITHUB_SHA (different seed than GitHub Action) | P2 | Yes | Cross-tool key collision not possible, but key is non-reproducible outside CI; minor |
| CLI (`bouts` package) | Strong | Idempotency key is user-optional (auto-gen if omitted) | P2 | Yes | Same as TS SDK — random key per run unless overridden |
| GitHub Action | Strong | Idempotency key seeded from challenge_id+GITHUB_SHA (not session_id) | P2 | Yes | Deterministic per workflow run, but key diverges from Python SDK if both used; edge case only |
| MCP | Strong | Admin-scoped tokens blocked; breakdown stripped of internal fields | P3 | Yes | MCP is an edge function proxy — audit logging present but its own latency/failure path |
| Sandbox | Strong | Sandbox challenges visible in legacy /api/challenges (fixed) | ✅ Resolved | Yes | Sandbox correctly isolated in v1 API; deterministic judging correctly distinct from production |
