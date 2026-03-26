---
name: multi-tenant-isolation
description: Security patterns for multi-tenant SaaS applications built on Supabase + Next.js. Use when reviewing applications where multiple organizations/teams share the same database, reviewing RLS policies with org/team scoping, checking for cross-tenant data leakage, auditing shared resource isolation, or building any B2B SaaS product (UberKiwi, white-label platforms). Covers tenant isolation via RLS, tenant context propagation, cross-tenant IDOR, shared resource abuse, tenant-scoped API keys, data export isolation, and the specific patterns where Supabase's architecture creates multi-tenant risks.
---

# Multi-Tenant Isolation

## Why Multi-Tenancy Is a Special Security Problem

In single-tenant apps, a bug affects one user. In multi-tenant apps, a bug can **leak one customer's data to another customer**. That's not just a security incident — it's a business-ending event for B2B SaaS.

**The difference**:
- Single-tenant: User A accesses User B's profile → bad but contained
- Multi-tenant: Company A's admin sees Company B's customer data, financial records, API keys → lawsuit, contract termination, regulatory fine

## Supabase Multi-Tenant Architecture

### Pattern 1: Shared Database, RLS Isolation (Most Common)
All tenants in the same tables, isolated by RLS policies:
```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id),
  title TEXT,
  content TEXT,
  created_by UUID REFERENCES auth.users(id)
);

-- RLS: Users can only see documents from their organization
CREATE POLICY "tenant_isolation" ON documents
FOR ALL TO authenticated
USING (
  org_id IN (
    SELECT org_id FROM org_members 
    WHERE user_id = (select auth.uid())
  )
);
```

**Risk**: One RLS policy mistake = cross-tenant data leak.

### Pattern 2: Schema-Per-Tenant
Each tenant gets their own Postgres schema. Strongest isolation but harder to manage.

**Risk**: Schema routing errors. If the application connects to wrong schema, data leaks.

### Pattern 3: Database-Per-Tenant
Each tenant gets their own Supabase project. Maximum isolation.

**Risk**: Misconfigured connection pooling, shared service accounts.

## Cross-Tenant Attack Vectors

### Vector 1: Missing org_id Filter
```typescript
// VULNERABLE — no tenant scoping
export async function GET(request: Request) {
  const documentId = request.nextUrl.searchParams.get('id')
  const { data } = await supabase
    .from('documents')
    .select('*')
    .eq('id', documentId)  // Any document from any org!
    .single()
  return Response.json(data)
}

// SAFE — tenant-scoped (if RLS handles it)
// But VERIFY RLS is correct — don't rely on it blindly
export async function GET(request: Request) {
  const user = await getUser()
  const userOrg = await getUserOrg(user.id)
  
  const { data } = await supabase
    .from('documents')
    .select('*')
    .eq('id', documentId)
    .eq('org_id', userOrg.id)  // Belt AND suspenders
    .single()
  return Response.json(data)
}
```

**Rule**: Even with RLS, add explicit tenant filtering in application code. Defense in depth.

### Vector 2: Tenant Context Confusion
```typescript
// VULNERABLE — tenant ID from URL parameter
export async function GET(request: Request) {
  const orgId = request.nextUrl.searchParams.get('org_id')
  // Attacker changes org_id to another tenant's ID
  const { data } = await supabase
    .from('documents')
    .select('*')
    .eq('org_id', orgId)  // Cross-tenant access!
}

// SAFE — tenant ID from auth context
export async function GET(request: Request) {
  const user = await getUser()
  const orgId = await getUserOrgId(user.id)  // Derived from auth, not user input
  const { data } = await supabase
    .from('documents')
    .select('*')
    .eq('org_id', orgId)
}
```

**Rule**: NEVER derive tenant context from user-supplied parameters. Always derive from the authenticated user's membership.

### Vector 3: RLS Policy Logic Errors
```sql
-- VULNERABLE — allows any authenticated user to see all orgs' data
CREATE POLICY "bad_tenant_policy" ON documents
FOR SELECT TO authenticated
USING (true);  -- Oops — no org check

-- VULNERABLE — trusts JWT claims for org (can be tampered)
CREATE POLICY "jwt_trust_policy" ON documents
FOR SELECT TO authenticated
USING (org_id = (current_setting('request.jwt.claims')::json->>'org_id')::uuid);
-- If user can modify JWT claims via getSession(), they can access any org

-- SAFE — verifies membership via lookup table
CREATE POLICY "membership_policy" ON documents
FOR SELECT TO authenticated
USING (
  org_id IN (
    SELECT om.org_id FROM org_members om 
    WHERE om.user_id = (select auth.uid())
    AND om.status = 'active'
  )
);
```

### Vector 4: Shared Resource Leakage
Resources that are shared across tenants can leak data:

```typescript
// VULNERABLE — search across all tenants
export async function GET(request: Request) {
  const query = request.nextUrl.searchParams.get('q')
  const { data } = await supabase
    .from('documents')
    .textSearch('content', query)  // Searches ALL documents if RLS is wrong
}

// Cache key collision
const cacheKey = `search:${query}`  // Same key regardless of tenant
cache.set(cacheKey, results)
// Tenant B gets Tenant A's cached results!

// SAFE — tenant-scoped cache keys
const cacheKey = `search:${orgId}:${query}`
```

### Vector 5: File Storage Cross-Tenant Access
```sql
-- VULNERABLE — storage bucket without tenant isolation
-- User uploads to: /documents/file.pdf
-- Any authenticated user can download: /documents/file.pdf

-- SAFE — tenant-scoped storage paths
-- Upload to: /{org_id}/documents/file.pdf
-- RLS policy: bucket_id = org_id check
CREATE POLICY "tenant_storage" ON storage.objects
FOR SELECT TO authenticated
USING (
  (storage.foldername(name))[1] IN (
    SELECT org_id::text FROM org_members 
    WHERE user_id = (select auth.uid())
  )
);
```

### Vector 6: Aggregation Data Leakage
```typescript
// VULNERABLE — analytics includes all tenants
export async function GET(request: Request) {
  const { data } = await supabase
    .from('usage_stats')
    .select('*')
    .gte('date', startDate)
  // Returns stats for ALL orgs if RLS is wrong
  
  // Even with RLS, aggregate functions can leak:
  const { count } = await supabase
    .from('documents')
    .select('*', { count: 'exact' })
  // Count of ALL documents across all tenants? Or just this tenant's?
}
```

### Vector 7: Background Job Cross-Tenant Execution
```typescript
// VULNERABLE — background job doesn't scope to tenant
async function processExport(exportId: string) {
  // Using service_role (bypasses RLS!) — must scope manually
  const { data: export } = await adminSupabase
    .from('exports')
    .select('*')
    .eq('id', exportId)
    .single()
  
  // If export.org_id is wrong or missing, exports wrong tenant's data
  const { data: documents } = await adminSupabase
    .from('documents')
    .select('*')
    .eq('org_id', export.org_id)  // Must verify this matches the requesting user's org
}
```

**Rule**: Any code using `service_role` (which bypasses RLS) MUST manually implement tenant scoping. This is the #1 source of multi-tenant bugs.

## Tenant Isolation Checklist

### Database Layer
- [ ] Every table with tenant data has `org_id` column
- [ ] RLS enabled and policies scope to org_id via membership lookup
- [ ] RLS policies use `(select auth.uid())` not JWT claims for org_id
- [ ] All CRUD operations (SELECT, INSERT, UPDATE, DELETE) have tenant policies
- [ ] Full-text search is tenant-scoped
- [ ] Aggregate queries (COUNT, SUM) are tenant-scoped
- [ ] No `USING (true)` on tables with multi-tenant data

### Application Layer
- [ ] Tenant context derived from auth, never from URL/query params
- [ ] Explicit `org_id` filter in queries even with RLS (defense in depth)
- [ ] Cache keys include tenant ID to prevent cross-tenant cache hits
- [ ] Search results scoped to tenant
- [ ] Data exports scoped to tenant
- [ ] Background jobs validate tenant context before processing
- [ ] Service role operations manually implement tenant scoping

### Storage Layer
- [ ] File storage paths include org_id: `/{org_id}/...`
- [ ] Storage bucket RLS policies check org membership
- [ ] File download URLs are tenant-scoped and time-limited (signed URLs)
- [ ] Shared uploads (avatars, logos) can't overwrite other tenants' files

### API Layer
- [ ] API keys scoped to specific tenant
- [ ] Rate limits per-tenant (one tenant can't DoS others)
- [ ] Error messages don't reveal other tenants' data or existence
- [ ] Admin endpoints verify org admin role, not just authenticated status

### Infrastructure Layer
- [ ] Database connection pooling doesn't leak tenant context between requests
- [ ] Logs include tenant_id for audit trail
- [ ] Log search can filter to specific tenant
- [ ] No shared secrets between tenants (each org has own webhook secrets, API keys)

## Testing Multi-Tenant Isolation

### Manual Test Script
```bash
# Get tokens for two different orgs
ORG_A_TOKEN="..."
ORG_B_TOKEN="..."

# For each API endpoint, test cross-tenant access:

# 1. List resources — does Org A see only their data?
curl -H "Authorization: Bearer $ORG_A_TOKEN" /api/documents

# 2. Read specific resource — can Org A read Org B's document?
curl -H "Authorization: Bearer $ORG_A_TOKEN" /api/documents/{ORG_B_DOC_ID}
# Expected: 404 (not 403 — don't reveal existence)

# 3. Update — can Org A modify Org B's document?
curl -X PATCH -H "Authorization: Bearer $ORG_A_TOKEN" \
  /api/documents/{ORG_B_DOC_ID} -d '{"title":"hacked"}'
# Expected: 404

# 4. Delete — can Org A delete Org B's document?
curl -X DELETE -H "Authorization: Bearer $ORG_A_TOKEN" \
  /api/documents/{ORG_B_DOC_ID}
# Expected: 404

# 5. Search — does search leak cross-tenant results?
curl -H "Authorization: Bearer $ORG_A_TOKEN" /api/search?q=confidential
# Expected: Only Org A's results

# 6. Aggregation — does count/sum include other tenants?
curl -H "Authorization: Bearer $ORG_A_TOKEN" /api/stats
# Expected: Only Org A's stats
```

### Automated Test Pattern
```typescript
describe('Multi-tenant isolation', () => {
  let orgAToken: string
  let orgBToken: string
  let orgBDocId: string
  
  beforeAll(async () => {
    // Setup: create two orgs, two users, one document in Org B
  })
  
  test('Org A cannot read Org B documents', async () => {
    const res = await fetch(`/api/documents/${orgBDocId}`, {
      headers: { Authorization: `Bearer ${orgAToken}` }
    })
    expect(res.status).toBe(404)
  })
  
  test('Org A search does not return Org B results', async () => {
    const res = await fetch('/api/search?q=secret', {
      headers: { Authorization: `Bearer ${orgAToken}` }
    })
    const data = await res.json()
    expect(data.results.every(r => r.org_id === orgAId)).toBe(true)
  })
  
  // Test for every CRUD operation on every multi-tenant endpoint
})
```

## References

For RLS policy specifics, see `rls-bypass-testing` skill.
For IDOR patterns, see `business-logic-exploitation` skill.
For caching security, see general architecture patterns.
