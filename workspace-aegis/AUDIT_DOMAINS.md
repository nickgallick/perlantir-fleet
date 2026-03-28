# AUDIT_DOMAINS.md — Aegis Security Audit Domain Guide

## Domain 1 — Auth / Session Integrity
Test: login flow, session creation, session expiry, password reset, logout
Key checks: JWT not manipulable, sessions expire, logout invalidates server-side, no session fixation

## Domain 2 — Role-Based Access Control
Test: every protected route and API as anonymous + competitor + admin
Key checks: backend enforces role (not just frontend), RLS active in Supabase, no role escalation paths

## Domain 3 — API / Internal Endpoint Protection
Test: all API endpoints without auth, with competitor auth, with admin auth
Key checks: admin APIs return 401/403 to non-admin, internal routes not accessible, response data scoped to role

## Domain 4 — Runtime / Submission Abuse
Test: abuse case library categories AC-SUB-001 through AC-SUB-005
Key checks: no duplicate submissions, no late submissions accepted, malformed payloads rejected

## Domain 5 — Judging / Result Integrity
Test: hidden test extraction attempts, score modification attempts, judge config leakage
Key checks: hidden tests never in competitor API response, activation_snapshot immutable, no score mutation path

## Domain 6 — Data Visibility by Role
Test: permission matrix for all data fields, API response inspection per role
Key checks: competitor can't see other competitor's raw breakdown, hidden tests not in any public response

## Domain 7 — Admin Safety
Test: destructive actions without confirmation, actions without reason, audit trail presence
Key checks: quarantine/reject require confirmation + reason, audit trail written

## Domain 8 — Connector / Integration Trust
Test: intake API with no key, wrong key, valid key, and key on wrong endpoint
Key checks: key only valid for intake, errors don't expose internals, malformed payloads handled

## Domain 9 — Secrets / Error Hygiene
Test: trigger 500s, inspect responses for DB errors, env vars, stack traces
Key checks: no PostgresError in response, no SUPABASE keys visible, no file paths in errors

## Domain 10 — Abuse Case Library
Run all pre-defined cases from ABUSE_CASE_LIBRARY.md
Document pass/fail for each with evidence
