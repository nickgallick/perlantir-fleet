# Database Review — Forge Skill

## Overview

We use PostgreSQL via Supabase. Database design decisions are hard to change later, so they deserve careful review. Bad schema design, missing indexes, and unsafe migrations can cause outages.

## Schema Design

### Normalization

- Tables should be normalized to at least 3NF unless there's a documented performance reason for denormalization
- Avoid storing computed values that can be derived from other columns
- Use junction tables for many-to-many relationships
- Use JSONB columns sparingly — only when the schema is truly dynamic

### Naming Conventions

- Tables: `snake_case`, plural (`users`, `blog_posts`)
- Columns: `snake_case`, singular (`user_id`, `created_at`)
- Primary keys: `id` (UUID preferred)
- Foreign keys: `{referenced_table_singular}_id` (e.g., `user_id`, `post_id`)
- Timestamps: `created_at`, `updated_at` (with default values)
- Booleans: `is_` or `has_` prefix (`is_active`, `has_verified`)

### Required Columns

Every table should have:
- `id` — UUID, primary key, default `gen_random_uuid()`
- `created_at` — timestamptz, default `now()`
- `updated_at` — timestamptz, updated via trigger or application code

### Data Types

| Use | Type | Not This |
|-----|------|----------|
| IDs | `uuid` | `serial`, `integer` |
| Timestamps | `timestamptz` | `timestamp` (no timezone) |
| Money | `numeric(12,2)` or `bigint` (cents) | `float`, `real` |
| Status/enum | PostgreSQL `enum` or text with check constraint | Unconstrained `text` |
| JSON data | `jsonb` | `json` (not indexable) |
| Email | `citext` or `text` with check | `varchar` |

## Index Strategy

### When to Add Indexes

- Foreign key columns (PostgreSQL does NOT auto-index these)
- Columns used in WHERE clauses frequently
- Columns used in ORDER BY
- Columns used in JOIN conditions
- Unique constraints (these create indexes automatically)

### When NOT to Add Indexes

- Small tables (< 1000 rows) — sequential scan is faster
- Columns with very low cardinality (e.g., boolean with 50/50 distribution)
- Write-heavy tables where read performance isn't critical
- Columns rarely used in queries

### Index Types

```sql
-- B-tree (default, most common)
CREATE INDEX idx_posts_user_id ON posts (user_id);

-- Composite index (order matters — leftmost column first in queries)
CREATE INDEX idx_posts_user_date ON posts (user_id, created_at DESC);

-- Partial index (index only matching rows)
CREATE INDEX idx_posts_published ON posts (created_at)
  WHERE is_published = true;

-- GIN index for JSONB
CREATE INDEX idx_users_metadata ON users USING GIN (metadata);

-- GiST index for full-text search
CREATE INDEX idx_posts_search ON posts USING GiST (to_tsvector('english', title || ' ' || body));
```

### Index Review Checklist

- [ ] Foreign keys have indexes
- [ ] Query patterns match index column order
- [ ] No duplicate or redundant indexes
- [ ] Partial indexes used where appropriate
- [ ] Index impact on write performance considered

## N+1 Query Detection

### The Problem

```typescript
// BAD — N+1: 1 query for posts + N queries for authors
const posts = await supabase.from('posts').select('*');
for (const post of posts.data) {
  const author = await supabase.from('users').select('*').eq('id', post.author_id).single();
}

// GOOD — join in a single query
const posts = await supabase
  .from('posts')
  .select('*, author:users(name, avatar_url)');
```

### Signs of N+1 in Code Review

- Loops that contain database queries
- `Promise.all` wrapping multiple identical queries with different IDs
- `useEffect` that fetches related data after initial data loads
- Multiple sequential `.from()` calls that could be a join

### Fix Patterns

- Use Supabase's embedded selects (joins): `.select('*, relation(columns)')`
- Use `IN` queries: `.in('id', arrayOfIds)`
- Use database views for complex joins
- Use RPC functions for complex aggregations

## Migration Safety

### Safe Migration Checklist

- [ ] Migration is backwards-compatible (old code works with new schema)
- [ ] No `DROP COLUMN` without verifying the column is unused in all code
- [ ] No `ALTER COLUMN` that changes type in a way that loses data
- [ ] No `NOT NULL` constraint added to existing column without default value
- [ ] Large table migrations use batched operations or `CONCURRENTLY`
- [ ] Indexes created with `CONCURRENTLY` to avoid table locks
- [ ] Migration tested against production-like data volume
- [ ] Rollback plan exists

### Dangerous Migration Patterns

| Pattern | Risk | Safer Alternative |
|---------|------|-------------------|
| `DROP TABLE` | Data loss | Rename to `_deprecated_`, drop later |
| `DROP COLUMN` | Data loss if column still used | Add `_deprecated` suffix, drop after deploy |
| `ALTER COLUMN SET NOT NULL` on existing data | Fails if NULLs exist | Add default, backfill, then add constraint |
| `CREATE INDEX` on large table | Table lock | `CREATE INDEX CONCURRENTLY` |
| Renaming columns | Breaks existing queries | Add new column, migrate data, drop old |
| Changing column type | Data loss or lock | Add new column, migrate, swap |

## Query Patterns

### Pagination

```typescript
// GOOD — cursor-based pagination
const { data } = await supabase
  .from('posts')
  .select('*')
  .order('created_at', { ascending: false })
  .lt('created_at', cursor)
  .limit(20);

// ACCEPTABLE — offset pagination (for small datasets or admin tools)
const { data, count } = await supabase
  .from('posts')
  .select('*', { count: 'exact' })
  .range(offset, offset + limit - 1);
```

### Soft Deletes

```typescript
// If using soft deletes
const { data } = await supabase
  .from('posts')
  .select('*')
  .is('deleted_at', null); // Don't forget to filter!
```

### Aggregations

```sql
-- Use database functions for aggregations, not client-side
CREATE OR REPLACE FUNCTION get_user_stats(uid uuid)
RETURNS TABLE (
  post_count bigint,
  comment_count bigint,
  total_likes bigint
) AS $$
  SELECT
    (SELECT count(*) FROM posts WHERE author_id = uid),
    (SELECT count(*) FROM comments WHERE user_id = uid),
    (SELECT coalesce(sum(likes), 0) FROM posts WHERE author_id = uid);
$$ LANGUAGE sql SECURITY DEFINER;
```

## Review Severity

| Issue | Severity |
|-------|----------|
| Migration drops data without backup plan | P0 — BLOCKED |
| N+1 query on user-facing page | P1 — High |
| Missing index on foreign key | P1 — High |
| Unsafe migration (locks table, no rollback) | P1 — High |
| Using `timestamp` instead of `timestamptz` | P2 — Medium |
| Missing `updated_at` column | P3 — Low |
| Using offset pagination on large table | P2 — Medium |
| Denormalization without justification | P2 — Medium |
