# STRIDE Reference Guide

## S — Spoofing

**Definition**: Attacker pretends to be someone/something they're not.

### Examples in Our Stack
- Forging a JWT to claim another user's identity
- Bypassing `getUser()` check by tampering with session cookie
- Replay attack: reusing a captured auth token
- Requesting as another org in multi-tenant system
- Spoofing webhook source (missing Stripe-Signature check)
- DNS spoofing: redirect users to attacker's server

### Mitigation Patterns
- `getUser()` not `getSession()` for server-side auth
- Verify tokens against the auth server, not just decode them
- Webhook signature verification
- Strict CORS origin checking
- Certificate pinning (mobile)
- Short token expiration + refresh rotation

### Review Questions
- How does the system verify the identity of the caller?
- Can a token be forged, stolen, or replayed?
- Are webhook sources verified?

---

## T — Tampering

**Definition**: Attacker modifies data in transit or at rest without authorization.

### Examples in Our Stack
- SQL injection modifying or deleting database records
- Modifying request body to bypass business logic (price, quantity)
- Tampering with cached data to poison cache
- Modifying JWT claims (if using getSession)
- Intercepting and modifying API responses (MITM)
- Modifying files in Supabase Storage
- Race condition that allows unauthorized state modification

### Mitigation Patterns
- Parameterized queries (Supabase client handles this)
- Input validation with Zod on all mutation endpoints
- HTTPS for all communication (no MITM)
- RLS with USING + WITH CHECK on UPDATE operations
- Optimistic locking for concurrent modifications
- Webhook signature verification
- Database triggers for immutable fields

### Review Questions
- Can an attacker modify the data that flows between components?
- Are all mutations authorized and validated?
- Is the data at rest protected from unauthorized modification?

---

## R — Repudiation

**Definition**: Actor denies performing an action, and there's no proof they did it.

### Examples in Our Stack
- Admin deletes records — no audit trail
- User makes payment — no immutable record
- Support agent accesses customer data — not logged
- Developer deploys malicious code — no signed commits

### Mitigation Patterns
- Immutable audit log (no UPDATE/DELETE on audit_log table)
- Log: who, what, which resource, when, from where
- Git signed commits for code changes
- Signed deployments (EAS Build code signing)
- Non-repudiation requires: audit log + user identification + action

### Review Questions
- Can a user deny performing a security-sensitive action?
- Is there an immutable record of all important operations?
- Are admin actions logged differently from regular user actions?

---

## I — Information Disclosure

**Definition**: Data is exposed to entities not authorized to see it.

### Examples in Our Stack
- Missing RLS on Supabase table (entire table readable by anon)
- Stack trace leaked in API error response
- Verbose error includes table name, column names
- Cross-tenant data leak in multi-tenant query
- JWT payload visible in browser (contains sensitive claims)
- Source maps in production (reveals code structure)
- API response includes fields that shouldn't be exposed
- Logs contain PII or secrets

### Mitigation Patterns
- RLS on every table
- Generic error responses to clients, detailed logs server-side
- Output serialization (explicit field allowlist in responses)
- Remove source maps from production builds
- Log sanitization (no PII, no secrets)
- 404 instead of 403 for cross-tenant resources (don't reveal existence)

### Review Questions
- What data is returned in each API response? Should all of it be there?
- What do error responses reveal?
- Can an authenticated user access data belonging to other users?
- Are there any information leaks in HTTP headers?

---

## D — Denial of Service

**Definition**: Attacker makes the system unavailable to legitimate users.

### Examples in Our Stack
- ReDoS: crafted input triggers catastrophic regex backtracking
- No rate limiting on expensive endpoints (AI inference, email)
- Unbounded database query returns millions of rows
- Zip/XML bomb: compressed file expands to exhaust memory
- WebSocket connection flood
- Cost attack: trigger expensive AI inference at scale
- Race condition leads to resource exhaustion
- Malicious GraphQL query with extreme depth/complexity

### Mitigation Patterns
- Rate limiting (per user, per IP, global)
- Input size limits on all endpoints
- Database query timeouts and pagination
- Request body size limits
- Max connections per IP (WebSocket)
- Safe regex validation
- Cost controls on AI inference

### Review Questions
- What happens if an attacker sends 1000 requests per second?
- What is the most expensive operation exposed? Is it rate limited?
- Are there any unbounded database queries?
- Can input size be weaponized?

---

## E — Elevation of Privilege

**Definition**: Attacker gains more permissions than they're supposed to have.

### Examples in Our Stack
- Regular user accesses admin endpoint
- Free tier user accesses premium features (missing server-side plan check)
- User modifies their own `role` column (missing RLS WITH CHECK)
- User submits admin-controlled field during account creation
- JWT claim manipulation (alg:none, RS256→HS256 confusion)
- IDOR: user accesses another user's resource
- Malicious skill/plugin gains elevated permissions
- Privilege escalation via RPC function with SECURITY DEFINER

### Mitigation Patterns
- Role verification on every privileged endpoint
- Server-side feature gating (not just frontend)
- RLS prevents users from modifying sensitive columns
- Server actions derive user ID from auth, not client input
- JWT algorithm enforcement
- Minimum privilege for all service accounts
- SECURITY INVOKER preferred over SECURITY DEFINER

### Review Questions
- Can a regular user trigger admin functionality?
- Are premium features gated server-side?
- Can users escalate their own privileges via any API?
- Does the RLS prevent privilege escalation through data modification?
