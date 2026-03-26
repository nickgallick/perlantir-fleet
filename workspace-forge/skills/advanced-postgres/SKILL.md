---
name: advanced-postgres
description: Advanced PostgreSQL patterns for Supabase — CTEs, window functions, JSONB, FTS, EXPLAIN ANALYZE, index strategy, migration safety, partitioning, advisory locks.
---

# Advanced PostgreSQL

## Quick Reference — Review Checks

1. [ ] **EXPLAIN ANALYZE** run on any query touching >10K rows
2. [ ] **Indexes** exist for every column in WHERE/ORDER BY/JOIN
3. [ ] **Migrations** are reversible and use CONCURRENTLY for index creation
4. [ ] **NOT NULL additions** have DEFAULT on large tables
5. [ ] **Transactions** wrap multi-step mutations
6. [ ] **`(select auth.uid())`** pattern used in all RLS policies (not bare `auth.uid()`)

---

## Advanced Query Patterns

### Window Functions (for leaderboards)
```sql
-- ELO leaderboard with rank, position change, streak
SELECT 
  a.agent_name,
  ar.elo_rating,
  ar.weight_class,
  ROW_NUMBER() OVER (PARTITION BY ar.weight_class ORDER BY ar.elo_rating DESC) as rank,
  ar.elo_rating - LAG(ar.elo_rating) OVER (
    PARTITION BY ar.agent_id ORDER BY ar.updated_at
  ) as elo_change,
  -- Streak: consecutive wins
  COUNT(*) FILTER (WHERE e.placement = 1) OVER (
    PARTITION BY ar.agent_id 
    ORDER BY e.submitted_at 
    ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
  ) as wins_last_10
FROM agent_ratings ar
JOIN agents a ON a.id = ar.agent_id
LEFT JOIN entries e ON e.agent_id = ar.agent_id
WHERE ar.season_id = current_season_id();
```

### Recursive CTEs (tournament brackets)
```sql
-- Generate bracket matchups from a flat entries table
WITH RECURSIVE bracket AS (
  -- Base: first round (all entries)
  SELECT id, agent_id, 1 as round, ROW_NUMBER() OVER (ORDER BY seed) as position
  FROM tournament_entries WHERE tournament_id = $1
  
  UNION ALL
  
  -- Each round: winners advance
  SELECT m.winner_id, m.winner_agent_id, b.round + 1, 
    CEIL(b.position::numeric / 2) as position
  FROM bracket b
  JOIN matches m ON m.round = b.round AND m.position = CEIL(b.position::numeric / 2)
  WHERE b.round < (SELECT total_rounds FROM tournaments WHERE id = $1)
)
SELECT * FROM bracket ORDER BY round, position;
```

### LATERAL Joins
```sql
-- Top 3 challenges per weight class (correlated subquery as join)
SELECT wc.name, c.*
FROM (VALUES ('Frontier'), ('Contender'), ('Scrapper')) AS wc(name)
CROSS JOIN LATERAL (
  SELECT id, title, entries_count
  FROM challenges
  WHERE weight_class = wc.name AND status = 'completed'
  ORDER BY entries_count DESC
  LIMIT 3
) c;
```

### JSONB Operations
```sql
-- Store and query judge scores (JSONB)
-- When to use JSONB vs separate table:
-- JSONB: schema varies, queried infrequently, no joins needed
-- Separate table: consistent schema, queried/filtered often, needs indexes

-- GIN index for JSONB containment queries
CREATE INDEX idx_scores_json ON entries USING GIN (ai_scores_json);

-- Query: find entries where judge_alpha scored > 8
SELECT * FROM entries 
WHERE ai_scores_json @> '{"judge_alpha": {"technical_quality": 9}}';
```

### Full-Text Search
```sql
-- When to use Postgres FTS vs external (Algolia/Typesense):
-- Postgres FTS: <100K docs, simple queries, no extra infra
-- External: >100K docs, typo tolerance, faceting, complex ranking

-- Add FTS column + index
ALTER TABLE challenges ADD COLUMN fts tsvector 
  GENERATED ALWAYS AS (
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))
  ) STORED;

CREATE INDEX idx_challenges_fts ON challenges USING GIN (fts);

-- Search
SELECT title, ts_rank(fts, query) as rank
FROM challenges, to_tsquery('english', 'coding & speed') query
WHERE fts @@ query
ORDER BY rank DESC;
```

---

## EXPLAIN ANALYZE Reading Guide

```
Seq Scan       → Full table scan. Fine for <1K rows. Bad for larger tables → add index
Index Scan     → Using an index. Good.
Bitmap Heap    → Using index for many rows. OK for 1-20% of table.
Index Only Scan → Best case. All data from index, no table access.
Nested Loop    → Join method. Fine for small tables. Bad for large × large.
Hash Join      → Good for equality joins on larger tables.
Sort           → In-memory sort (fine) vs disk sort (add index or increase work_mem)

Key numbers:
- actual time: first row .. last row (in ms)
- rows: expected vs actual (big mismatch = stale statistics → ANALYZE)
- loops: how many times this node executed (N+1 query indicator)
```

## Index Strategy

| Type | Use For | Example |
|------|---------|---------|
| B-tree (default) | Equality, range, sorting | `user_id`, `created_at`, `elo_rating` |
| GIN | JSONB, arrays, FTS | `ai_scores_json`, `tags`, `fts` |
| GiST | Geometry, ranges | IP ranges, date ranges |
| BRIN | Large sequential data | Time-series (transcript events by timestamp) |
| Partial | Subset of rows | `WHERE status = 'active'` — only index active rows |
| Composite | Multi-column queries | `(weight_class, elo_rating DESC)` for leaderboard |

```sql
-- Partial index: only index submitted entries (not drafts)
CREATE INDEX idx_entries_submitted ON entries (agent_id, final_score)
WHERE status = 'submitted';

-- Composite index: column ORDER MATTERS (leftmost = most selective)
CREATE INDEX idx_ratings_leaderboard ON agent_ratings (weight_class, elo_rating DESC);

-- Create indexes CONCURRENTLY (doesn't lock table)
CREATE INDEX CONCURRENTLY idx_votes_entry ON votes (entry_id);
```

---

## Migration Safety

### ❌ Dangerous Migrations
```sql
-- Locks entire table until backfill complete on large tables
ALTER TABLE entries ADD COLUMN calculated_mps numeric NOT NULL;

-- Drops column that might still be referenced
ALTER TABLE agents DROP COLUMN legacy_field;

-- Creates index with full table lock
CREATE INDEX idx_large_table ON large_table (column);
```

### ✅ Safe Migrations
```sql
-- Step 1: Add nullable column (instant, no lock)
ALTER TABLE entries ADD COLUMN calculated_mps numeric;

-- Step 2: Backfill in batches (no lock)
UPDATE entries SET calculated_mps = 0 WHERE calculated_mps IS NULL AND id < 1000;
UPDATE entries SET calculated_mps = 0 WHERE calculated_mps IS NULL AND id BETWEEN 1000 AND 2000;
-- ... repeat in batches

-- Step 3: Add default and NOT NULL (after backfill complete)
ALTER TABLE entries ALTER COLUMN calculated_mps SET DEFAULT 0;
ALTER TABLE entries ALTER COLUMN calculated_mps SET NOT NULL;

-- Index creation: always CONCURRENTLY
CREATE INDEX CONCURRENTLY idx_entries_mps ON entries (calculated_mps);
```

### Blue-Green Column Migration
1. Add new column (nullable)
2. Deploy code that writes to BOTH old and new columns
3. Backfill new column from old column
4. Deploy code that reads from new column
5. Drop old column (after confirming no reads)

---

## Advanced Supabase Patterns

### Advisory Locks (prevent race conditions)
```sql
-- Lightweight lock for ELO updates — no table locks needed
CREATE OR REPLACE FUNCTION update_agent_elo(p_agent_id uuid, p_new_elo int)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  -- Acquire advisory lock keyed to this agent
  PERFORM pg_advisory_xact_lock(hashtext(p_agent_id::text));
  
  UPDATE agent_ratings SET elo_rating = p_new_elo WHERE agent_id = p_agent_id;
END; $$;
```

### Generated Columns
```sql
-- Auto-computed column — always in sync
ALTER TABLE agents ADD COLUMN display_weight_class text GENERATED ALWAYS AS (
  CASE 
    WHEN model_power_score >= 85 THEN 'Frontier'
    WHEN model_power_score >= 60 THEN 'Contender'
    WHEN model_power_score >= 30 THEN 'Scrapper'
    ELSE 'Underdog'
  END
) STORED;
```

### Table Partitioning (for scale)
```sql
-- Partition transcript events by month
CREATE TABLE transcript_events (
  id bigint GENERATED ALWAYS AS IDENTITY,
  entry_id uuid NOT NULL,
  event_data jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at);

CREATE TABLE transcript_events_2026_03 PARTITION OF transcript_events
  FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE transcript_events_2026_04 PARTITION OF transcript_events
  FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
```

## Sources
- PostgreSQL documentation (CTEs, window functions, indexes, partitioning)
- Supabase RLS performance benchmarks
- postgres.js library patterns
- system-design-primer database section

## Changelog
- 2026-03-21: Initial skill — advanced PostgreSQL for Arena
