---
name: database-schema-design
description: Schema design from product specs — entity extraction, normalization, naming conventions, index strategy, RLS patterns, migration generation, and seed data.
---

# Database Schema Design

## The Design Process

1. **List entities** (nouns from spec): users, agents, challenges, entries, scores, votes, wallets
2. **List relationships** (verbs): user registers agent, agent enters challenge, judge scores entry
3. **Determine cardinality**: user 1:N agents, challenge 1:N entries, entry 1:N judge_scores
4. **Normalize to 3NF**, then selectively denormalize for performance
5. **Add temporal columns**: `created_at`, `updated_at` on every table
6. **Add soft delete** where needed: `deleted_at` on users, teams (not events)
7. **Define indexes** based on expected query patterns
8. **Write RLS** for every table
9. **Create functions** for complex operations (ELO, wallet, transitions)

## Naming Conventions (Enforce Consistently)

| Element | Convention | Example |
|---------|-----------|---------|
| Tables | plural snake_case | `challenges`, `agent_ratings` |
| Columns | singular snake_case | `user_id`, `elo_rating` |
| Primary keys | `id` (uuid) | `id uuid PRIMARY KEY DEFAULT gen_random_uuid()` |
| Foreign keys | `{table_singular}_id` | `user_id`, `challenge_id` |
| Booleans | `is_` or `has_` prefix | `is_active`, `has_submitted` |
| Timestamps | `_at` suffix | `created_at`, `completed_at` |
| Status columns | `status` with CHECK | `CHECK (status IN ('pending','active','done'))` |
| JSON columns | `_json` suffix | `scores_json`, `metadata_json` |

## JSONB vs Separate Table

| Use JSONB | Use Separate Table |
|-----------|-------------------|
| Flexible metadata varying per record | Data you filter/sort/aggregate on |
| Config blobs, score breakdowns | Data with its own relationships |
| Audit snapshots | Data that grows unboundedly |
| **Test:** if you'd write `WHERE json->>'key' = ?` in a hot query, make it a column | |

## Index Strategy

```sql
-- Every foreign key (Postgres does NOT auto-index FKs)
CREATE INDEX idx_entries_challenge ON entries (challenge_id);
CREATE INDEX idx_entries_agent ON entries (agent_id);

-- Multi-column for common query patterns
CREATE INDEX idx_entries_challenge_status ON entries (challenge_id, status);

-- Partial index (only index relevant subset)
CREATE INDEX idx_entries_pending ON entries (challenge_id, created_at)
  WHERE status = 'pending';

-- GIN for JSONB and tsvector
CREATE INDEX idx_challenges_search ON challenges USING GIN (search_vector);

-- CONCURRENTLY for production (no table lock)
CREATE INDEX CONCURRENTLY idx_votes_entry ON votes (entry_id);
```

## Standard RLS Patterns

```sql
-- 1. User-owned data
CREATE POLICY "own_data" ON entries FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- 2. Team data
CREATE POLICY "team_data" ON challenges FOR SELECT TO authenticated
  USING (team_id IN (
    SELECT team_id FROM team_members WHERE user_id = (select auth.uid())
  ));

-- 3. Public read, owner write
CREATE POLICY "public_read" ON agents FOR SELECT USING (true);
CREATE POLICY "owner_write" ON agents FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);

-- 4. Service role only (webhooks, cron)
-- No authenticated policy = only service_role can access

-- 5. Insert with ownership check
CREATE POLICY "create_own" ON entries FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- ALWAYS use (select auth.uid()) not bare auth.uid() — 99%+ performance improvement
```

## Standard Temporal Columns

```sql
-- Add to EVERY table
created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz NOT NULL DEFAULT now()

-- Auto-update trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END; $$;

-- Apply to each table
CREATE TRIGGER set_updated_at BEFORE UPDATE ON challenges
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

## Schema Evolution Rules

- Prefer nullable columns over NOT NULL when field might not always apply
- Use CHECK constraints over Postgres ENUM (easier to extend)
- Plan for soft delete from start: `deleted_at timestamptz` (null = active)
- UUID primary keys everywhere (never auto-increment for public-facing IDs)
- `text` over `varchar(n)` — length validation belongs in Zod, not the DB

## Output Template

Given a product spec, produce:
1. Complete `CREATE TABLE` statements with all constraints
2. All indexes with rationale
3. All RLS policies
4. Database functions for complex operations
5. `updated_at` triggers
6. Seed data for development
7. The migration file(s)

## Sources
- PostgreSQL documentation (constraints, indexes, RLS)
- Supabase schema design best practices
- cal.com database schema (production reference)
- advanced-postgres skill (CTEs, window functions, partitioning)

## Changelog
- 2026-03-21: Initial skill — database schema design
