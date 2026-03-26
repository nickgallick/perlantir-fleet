---
name: secure-architecture-patterns
description: Architecture patterns that make entire categories of vulnerabilities impossible by design. Use when designing system architecture, reviewing architecture specs, deciding on data flow patterns, choosing auth/authz models, or evaluating if a design is secure by construction vs requiring runtime enforcement. Covers zero-trust architecture, defense in depth, blast radius containment, secure-by-default patterns, the principle of least privilege applied to system design, and specific Next.js + Supabase + Vercel architectural decisions that determine the security ceiling of everything built on top.
---

# Secure Architecture Patterns

## The Core Principle

A great architecture makes entire classes of bugs **impossible**, not just **detectable**. If the architecture requires every developer to remember 20 security checks on every endpoint, the architecture is wrong — because someone WILL forget.

**The question**: Can Maks write insecure code if the architecture is designed correctly?
- Bad architecture: Yes, easily, on every endpoint
- Good architecture: Only in very specific, auditable places

## Pattern 1: Secure-by-Default Data Access

### The Anti-Pattern (Insecure by Default)
```
                    ┌──────────┐
   Client ──────→  │ API Route │ ──────→ Database
                    └──────────┘
   Security depends on: every route remembering auth + RLS
   What happens when forgotten: full data exposure
```

### The Pattern (Secure by Default)
```
                    ┌──────────┐     ┌───────────┐
   Client ──────→  │ Middleware│────→│ API Route  │
                    │ (auth +  │     │ (business  │ ──→ Database (RLS enforced)
                    │  rate    │     │  logic     │
                    │  limit)  │     │  only)     │
                    └──────────┘     └───────────┘
   Security enforced at: middleware (auth) + database (RLS)
   API route's job: business logic only — auth already verified
   What happens when developer forgets: still secure (RLS blocks)
```

### Implementation
```typescript
// 1. Middleware handles auth for all /api/** routes
// middleware.ts
export async function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/api')) {
    const supabase = createClient(request)
    const { data: { user } } = await supabase.auth.getUser()
    
    if (!user && !isPublicRoute(request.nextUrl.pathname)) {
      return new Response('Unauthorized', { status: 401 })
    }
    
    // Inject verified user ID into request headers
    const response = NextResponse.next()
    if (user) response.headers.set('x-user-id', user.id)
    return response
  }
}

// 2. API routes trust the middleware — no auth code needed
export async function POST(request: Request) {
  const userId = request.headers.get('x-user-id')!  // Already verified
  // Business logic only — auth was handled upstream
}

// 3. Database enforces RLS as the FINAL gate
// Even if middleware AND route are both wrong, RLS blocks unauthorized access
```

## Pattern 2: Zero-Trust Boundaries

### The Principle
Never trust data or identity based on where it came from. Always verify at the point of use.

### Applied to Our Stack

```
┌─────────────────────────────────────────────────┐
│ BOUNDARY 1: Client → Server                      │
│ Trust: NONE                                       │
│ Verify: Auth token (getUser), input (Zod)        │
│                                                   │
│ BOUNDARY 2: Server → Database                     │
│ Trust: Server identity only                       │
│ Verify: RLS policies on every table               │
│                                                   │
│ BOUNDARY 3: Server → External API                 │
│ Trust: TLS certificate                            │
│ Verify: Response schema (Zod), rate limit         │
│                                                   │
│ BOUNDARY 4: External → Server (webhooks)          │
│ Trust: NONE                                       │
│ Verify: Signature (Stripe-Signature), schema      │
│                                                   │
│ BOUNDARY 5: Server → Server (internal)            │
│ Trust: Network boundary (but verify anyway)       │
│ Verify: Service-to-service auth tokens            │
└─────────────────────────────────────────────────┘
```

**Key**: Even if boundary N-1 is compromised, boundary N still holds.

## Pattern 3: Blast Radius Containment

### The Principle
When (not if) a component is compromised, limit what the attacker can access.

### Strategies

**Credential Scoping**:
```
❌ One database user with all permissions
✅ API uses read-only user; migrations use admin user; background jobs use job-scoped user

❌ One API key for all Stripe operations
✅ Separate restricted keys per operation type

❌ GITHUB_TOKEN with write-all
✅ Fine-grained tokens with minimum permissions per workflow
```

**Data Partitioning**:
```
❌ All data in one schema, rely on RLS for everything
✅ Sensitive data in separate schema with additional access controls
   - auth.users → Supabase manages, we can't accidentally expose
   - public.profiles → RLS enforced, only non-sensitive data
   - private.payment_data → separate schema, service_role only access via RPC
```

**Network Isolation**:
```
❌ All services on same network, trust everything internal
✅ Database only accessible from application server
   Edge Functions can't reach admin APIs
   Webhook endpoints on separate subdomain
```

**Secret Isolation**:
```
❌ All secrets in one .env file shared across all environments
✅ Production secrets in environment-specific secret store
   CI secrets scoped to specific workflows
   Each third-party integration has its own secret
   Secrets rotated on independent schedules
```

## Pattern 4: Input/Output Architecture

### The Principle
All external input enters through ONE validated path. All output exits through ONE encoded path.

```
INPUT FLOW:
  Raw Input → Middleware (auth) → Route (Zod schema) → Service (business logic) → Database (parameterized)
                                        ↑
                              Schema validates here
                              NOTHING downstream sees raw input

OUTPUT FLOW:
  Database → Service → Serializer (shape control) → Response
                              ↑
                    Only allowed fields pass here
                    Internal IDs, sensitive data stripped
```

### Implementation: Validated Input, Controlled Output
```typescript
// Input: Zod schema at the boundary
const CreatePostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(10000),
  categoryId: z.string().uuid(),
})

// Output: Explicit shape — never return raw DB rows
const PostResponseSchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  content: z.string(),
  author: z.object({
    id: z.string().uuid(),
    displayName: z.string(),
    // No email, no internal IDs, no sensitive fields
  }),
  createdAt: z.string().datetime(),
})

function serializePost(dbRow: any): z.infer<typeof PostResponseSchema> {
  return PostResponseSchema.parse({
    id: dbRow.id,
    title: dbRow.title,
    content: dbRow.content,
    author: { id: dbRow.author_id, displayName: dbRow.author_name },
    createdAt: dbRow.created_at,
  })
}
```

## Pattern 5: Secure State Machines

### The Principle
Every stateful workflow (orders, subscriptions, challenges, approvals) should be modeled as a state machine with explicit, validated transitions.

```typescript
// Define valid transitions
const TRANSITIONS: Record<string, string[]> = {
  'draft':     ['submitted'],
  'submitted': ['reviewing'],
  'reviewing': ['approved', 'rejected'],
  'approved':  ['published'],
  'rejected':  ['draft'],           // Can go back to draft
  'published': [],                   // Terminal state
}

async function transitionState(entityId: string, newState: string, userId: string) {
  const entity = await getEntity(entityId)
  
  // 1. Verify transition is valid
  const allowedNext = TRANSITIONS[entity.status]
  if (!allowedNext?.includes(newState)) {
    throw new Error(`Invalid transition: ${entity.status} → ${newState}`)
  }
  
  // 2. Verify user has permission for this transition
  await verifyTransitionPermission(userId, entity, newState)
  
  // 3. Execute transition atomically
  await supabase.from('entities')
    .update({ status: newState, updated_by: userId, updated_at: new Date() })
    .eq('id', entityId)
    .eq('status', entity.status)  // Optimistic lock — prevents race condition
  
  // 4. Audit log
  await logTransition(entityId, entity.status, newState, userId)
}
```

## Pattern 6: Secrets Architecture

```
┌───────────────────────────────────────────────────┐
│                 SECRET HIERARCHY                    │
│                                                     │
│  Tier 1: Infrastructure (rotate yearly)             │
│  ├── SUPABASE_SERVICE_ROLE_KEY                     │
│  ├── STRIPE_SECRET_KEY                             │
│  └── ANTHROPIC_API_KEY                             │
│                                                     │
│  Tier 2: Application (rotate monthly)               │
│  ├── STRIPE_WEBHOOK_SECRET                         │
│  ├── JWT_SECRET (Supabase manages)                 │
│  └── ENCRYPTION_KEY                                │
│                                                     │
│  Tier 3: Session (rotate per session)               │
│  ├── User JWT (auto-expires)                       │
│  ├── Refresh token (auto-rotates)                  │
│  └── CSRF token (per form)                         │
│                                                     │
│  RULES:                                             │
│  - Tier 1: Server-side only, never in env prefixed  │
│    NEXT_PUBLIC_                                      │
│  - Tier 2: Scoped to specific endpoints/functions   │
│  - Tier 3: Short-lived, auto-managed                │
│  - ALL: Encrypted at rest, never logged, never in   │
│    error messages, never in URLs                    │
└───────────────────────────────────────────────────┘
```

## Pattern 7: Audit Trail Architecture

### The Principle
Every security-sensitive action must have an immutable audit record that answers: WHO did WHAT to WHICH resource WHEN, and FROM WHERE.

```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,           -- 'create', 'update', 'delete', 'login', 'export'
  resource_type TEXT NOT NULL,    -- 'document', 'user', 'payment'
  resource_id UUID,
  org_id UUID,                    -- For multi-tenant filtering
  ip_address INET,
  user_agent TEXT,
  old_values JSONB,               -- Previous state (for updates)
  new_values JSONB,               -- New state (for creates/updates)
  metadata JSONB                  -- Additional context
);

-- RLS: Users can read their own org's audit logs
-- But NOBODY can UPDATE or DELETE audit logs
CREATE POLICY "audit_read" ON audit_log FOR SELECT TO authenticated
USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = (select auth.uid())));

-- No UPDATE or DELETE policies = immutable
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
```

## Architecture Review Checklist

When reviewing any architecture spec:

### Data Access
- [ ] Auth enforced at middleware level (not per-route)
- [ ] RLS as the final gate on every table
- [ ] Input validation at the boundary (Zod schemas)
- [ ] Output serialization controls what's returned
- [ ] No raw database rows returned to clients

### Trust Boundaries
- [ ] Every boundary identified and documented
- [ ] Each boundary has independent verification
- [ ] Failure at one boundary doesn't cascade

### Blast Radius
- [ ] Credentials scoped to minimum required
- [ ] Sensitive data in separate storage/schema
- [ ] Secrets isolated per service/environment
- [ ] Network access restricted per component

### State Management
- [ ] Stateful workflows modeled as state machines
- [ ] Transitions validated against allowed set
- [ ] Transition permissions checked
- [ ] Atomic transitions (optimistic locking)

### Audit
- [ ] Security-sensitive actions logged
- [ ] Audit logs are immutable (no UPDATE/DELETE)
- [ ] Logs include who, what, when, where
- [ ] Logs scoped per tenant for multi-tenant

## References

For threat modeling before architecture, see `threat-modeling-methodology` skill.
For secure coding implementation, see `secure-coding-standards` skill.
