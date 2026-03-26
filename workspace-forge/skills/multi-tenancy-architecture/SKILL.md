---
name: multi-tenancy-architecture
description: Multi-tenancy patterns — shared schema with RLS, schema-per-tenant, tenant context propagation, team/role management, billing per tenant, and isolation testing.
---

# Multi-Tenancy Architecture

## Review Checklist

1. [ ] Every table has tenant column (`team_id` or `user_id`) + RLS
2. [ ] Tenant context from auth token, NEVER from client request body
3. [ ] Queries include tenant filter even with RLS (defense in depth)
4. [ ] Cross-tenant access tested and verified impossible
5. [ ] Usage limits enforced at application level
6. [ ] Tenant deletion cascades properly

---

## Tenancy Models

| Model | Isolation | Cost | Complexity | Use When |
|-------|-----------|------|-----------|----------|
| **Shared schema** | RLS-based | $ | Low | B2C (Arena, MathMind) |
| **Schema per tenant** | Schema-based | $$ | Medium | B2B with isolation needs (OUTBOUND managed) |
| **Database per tenant** | Complete | $$$ | High | Enterprise/regulated ($1K+/mo customers) |

## Shared Schema Implementation (Arena, MathMind)

```sql
-- Every table has tenant column
CREATE TABLE challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id uuid NOT NULL REFERENCES teams(id),
  title text NOT NULL,
  weight_class text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- RLS enforces tenant isolation
CREATE POLICY "team_challenges" ON challenges
FOR ALL TO authenticated
USING (
  team_id IN (
    SELECT team_id FROM team_members
    WHERE user_id = (select auth.uid())
  )
)
WITH CHECK (
  team_id IN (
    SELECT team_id FROM team_members
    WHERE user_id = (select auth.uid())
  )
);

-- Performance: index on tenant column
CREATE INDEX idx_challenges_team ON challenges (team_id);
```

## Tenant Context Propagation

```ts
// ❌ NEVER trust client-sent tenant ID
const teamId = req.body.teamId // attacker can send any team ID

// ✅ Derive from auth token
const { data: { claims } } = await supabase.auth.getClaims()
const userId = claims?.sub

// Get user's team(s) from database
const { data: memberships } = await supabase
  .from('team_members')
  .select('team_id, role')
  .eq('user_id', userId)

// For single-team apps: use the first (or only) team
// For multi-team apps: team from URL path or subdomain
```

### Propagation Patterns

| Pattern | How | Use When |
|---------|-----|----------|
| **JWT claim** | `auth.jwt()->'app_metadata'->>'team_id'` | Single-team per user |
| **URL subdomain** | `acme.outbound.com` → parse subdomain | B2B SaaS |
| **URL path** | `/team/acme/challenges` → extract from route | Multi-team per user |
| **Middleware** | Extract tenant, set in request context | Any pattern |

## Team & Role Management

```sql
CREATE TABLE teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  plan_tier text DEFAULT 'free',
  stripe_customer_id text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE team_members (
  team_id uuid REFERENCES teams(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  joined_at timestamptz DEFAULT now(),
  PRIMARY KEY (team_id, user_id)
);

-- Role-based RLS
CREATE POLICY "team_write" ON challenges
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = challenges.team_id
    AND user_id = (select auth.uid())
    AND role IN ('owner', 'admin', 'member')
    -- viewers can't create
  )
);
```

| Role | Read | Create | Edit Own | Edit All | Manage Members | Billing |
|------|:----:|:------:|:--------:|:--------:|:--------------:|:-------:|
| viewer | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| member | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| admin | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| owner | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Tenant Isolation Testing

```ts
// AUTOMATED — run in CI
describe('Tenant Isolation', () => {
  let teamA: Team, teamB: Team, userA: User, userB: User
  
  beforeAll(async () => {
    teamA = await createTestTeam('Team A')
    teamB = await createTestTeam('Team B')
    userA = await createTestUser(teamA, 'member')
    userB = await createTestUser(teamB, 'member')
  })
  
  it('User A cannot read Team B challenges', async () => {
    const challengeB = await createChallenge(teamB)
    const clientA = createClientAs(userA)
    
    const { data } = await clientA
      .from('challenges').select('*').eq('id', challengeB.id)
    
    expect(data).toHaveLength(0) // RLS blocks
  })
  
  it('User A cannot create challenge in Team B', async () => {
    const clientA = createClientAs(userA)
    
    const { error } = await clientA
      .from('challenges')
      .insert({ team_id: teamB.id, title: 'Hacked' })
    
    expect(error).toBeTruthy() // RLS blocks
  })
  
  it('Direct ID access returns nothing for wrong tenant', async () => {
    const challengeB = await createChallenge(teamB)
    const clientA = createClientAs(userA)
    
    const { data } = await clientA
      .from('challenges').select('*').eq('id', challengeB.id).single()
    
    expect(data).toBeNull() // Can't access by guessing ID
  })
})
```

## Billing Per Tenant

```sql
-- Usage tracking
CREATE TABLE usage_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id uuid NOT NULL REFERENCES teams(id),
  metric text NOT NULL, -- 'challenges_created', 'ai_judge_calls', 'storage_bytes'
  value bigint NOT NULL DEFAULT 1,
  period_start date NOT NULL DEFAULT date_trunc('month', now()),
  created_at timestamptz DEFAULT now()
);

-- Usage limit check
CREATE OR REPLACE FUNCTION check_usage_limit(
  p_team_id uuid, p_metric text, p_limit bigint
) RETURNS boolean LANGUAGE sql AS $$
  SELECT COALESCE(SUM(value), 0) < p_limit
  FROM usage_records
  WHERE team_id = p_team_id
    AND metric = p_metric
    AND period_start = date_trunc('month', now());
$$;
```

## Sources
- cal.com multi-tenancy patterns
- Supabase RLS documentation
- hoppscotch team management architecture
- OWASP access control for multi-tenant apps

## Changelog
- 2026-03-21: Initial skill — multi-tenancy architecture
