---
name: nick-api-test-builder
description: API backend test generation for Nick's stack, especially Next.js App Router APIs with Supabase-aware auth assumptions. Use when testing backend routes, generating API test suites, validating authenticated vs unauthenticated access, checking malformed inputs, or building route-by-route backend coverage for projects that use /app/api or /pages/api.
---

# Nick API Test Builder

Use this as the primary API/backend testing skill for Nick's workflow.

## Purpose
Generate practical backend test suites that cover:
- route discovery
- HTTP method coverage
- authenticated vs unauthenticated access
- malformed/missing inputs
- happy path and error path behavior
- role/permission assumptions where relevant

## Hard rules
- Test authenticated and unauthenticated access where auth is relevant
- Test all supported HTTP methods for each route
- Test malformed and missing inputs
- Prefer Next.js App Router route discovery first
- Keep output practical and runnable

## Default workflow
1. Discover API routes
2. Identify supported methods per route
3. Identify auth/role requirements from route code
4. Generate tests for:
   - happy path
   - unauthenticated access
   - malformed inputs
   - missing inputs
   - unsupported methods where relevant
5. Organize tests by route or route group

## Default output
- route map
- backend test files
- auth assumptions to verify
- gaps that still need manual clarification

## Best-fit stack
- Next.js App Router
- Next.js Pages API routes
- Node test runner / Vitest or similar
- Supabase-aware auth patterns

## References
- Read `references/route-discovery.md` for route mapping
- Read `references/auth-test-patterns.md` for auth coverage
- Read `references/input-edge-cases.md` for malformed/missing input patterns
- Read `references/test-file-shape.md` for practical output structure

## Bundled scripts
- `scripts/generate_route_test_plan.sh` — create per-route test planning stub
- `scripts/generate_auth_matrix.sh` — create auth test matrix
- `scripts/generate_endpoint_checklist.sh` — create endpoint coverage checklist
