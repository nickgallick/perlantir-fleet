---
name: migration-and-schema-evolution
description: Safe database migration patterns — adding/removing/renaming columns, index creation, foreign keys, and Supabase-specific migration workflow.
---

# Migration & Schema Evolution

## Migration Review Checklist

1. [ ] **Reverse migration exists?** Every up migration has a down.
2. [ ] **Will this lock tables?** For how long? (NOT NULL addition, index creation)
3. [ ] **Safe under traffic?** Can this run while the app is serving requests?
4. [ ] **Failure recovery?** What happens if migration fails halfway?
5. [ ] **Backfill needed?** Is it a separate step from the schema change?
6. [ ] **Deploy ordering?** Must code deploy before, after, or doesn't matter?

---

## Safe Migration Patterns

### Adding a Column
```sql
-- ✅ SAFE: nullable column, instant operation
ALTER TABLE entries ADD COLUMN calculated_mps numeric;

-- ❌ DANGEROUS: NOT NULL on existing table locks it during backfill
ALTER TABLE entries ADD COLUMN calculated_mps numeric NOT NULL;

-- ✅ SAFE: add with DEFAULT (Postgres 11+ makes this instant)
ALTER TABLE entries ADD COLUMN calculated_mps numeric NOT NULL DEFAULT 0;
-- On large tables: still prefer nullable → backfill → set NOT NULL
```

### Removing a Column (3-step, 2 deploys)
```
Deploy 1: Remove all code that reads/writes the column
Deploy 2: DROP COLUMN migration
Never combine — if migration runs before code deploys, app crashes
```

### Renaming a Column (4-step, 3 deploys)
```
DON'T use ALTER COLUMN RENAME — breaks running code instantly.

Step 1: Add new column (migration)
Step 2: Deploy code that writes to BOTH columns (dual-write)
Step 3: Backfill new column from old (migration)
Step 4: Deploy code using only new column
Step 5: Drop old column (migration)
```

### Changing Column Type
```sql
-- ❌ DANGEROUS: locks table while rewriting every row
ALTER TABLE entries ALTER COLUMN score TYPE numeric;

-- ✅ SAFE: new column approach
ALTER TABLE entries ADD COLUMN score_v2 numeric;
-- Backfill: UPDATE entries SET score_v2 = score::numeric WHERE score_v2 IS NULL;
-- Update code to use score_v2
-- Drop old column
```

### Adding Index
```sql
-- ❌ LOCKS TABLE during creation
CREATE INDEX idx_entries_agent ON entries (agent_id);

-- ✅ Non-blocking (takes longer but no lock)
CREATE INDEX CONCURRENTLY idx_entries_agent ON entries (agent_id);
```

### Adding Foreign Key
```sql
-- ❌ VALIDATES all existing data (slow on large tables, holds lock)
ALTER TABLE entries ADD CONSTRAINT fk_agent FOREIGN KEY (agent_id) REFERENCES agents(id);

-- ✅ Add without scanning existing data, validate separately
ALTER TABLE entries ADD CONSTRAINT fk_agent 
  FOREIGN KEY (agent_id) REFERENCES agents(id) NOT VALID;
-- Later (can run while serving traffic):
ALTER TABLE entries VALIDATE CONSTRAINT fk_agent;
```

---

## Supabase Migration Workflow

```bash
# 1. Create migration
supabase migration new add_weight_class_verification

# 2. Write SQL
# supabase/migrations/20260321_add_weight_class_verification.sql

# 3. Test locally
supabase db reset  # drops, recreates, applies all migrations + seed

# 4. Generate types
supabase gen types typescript --local > packages/db/types.ts

# 5. Test RLS with real tokens
# In SQL editor:
SET role authenticated;
SET request.jwt.claims TO '{"sub":"test-user-id","role":"authenticated"}';
SELECT * FROM new_table;

# 6. Deploy
supabase db push --linked  # applies to production
```

### Migration Naming Convention
```
20260321120000_create_challenges_table.sql
20260321120100_add_weight_class_to_agents.sql
20260321120200_create_elo_calculation_function.sql
```
Timestamp prefix ensures ordering. Descriptive suffix explains what it does.

---

## Rollback Strategy

Every migration file should have a comment with the reverse:
```sql
-- UP
ALTER TABLE agents ADD COLUMN weight_class text;
CREATE INDEX CONCURRENTLY idx_agents_weight_class ON agents (weight_class);

-- ROLLBACK (keep as comment, run manually if needed)
-- DROP INDEX CONCURRENTLY idx_agents_weight_class;
-- ALTER TABLE agents DROP COLUMN weight_class;
```

For data backfills, the rollback is: "restore from backup" or "reverse the data transformation." Document which.

## Sources
- PostgreSQL ALTER TABLE documentation
- Supabase CLI migration documentation
- "Zero Downtime Postgres Migrations" (strong_migrations patterns)
- cal.com migration patterns

## Changelog
- 2026-03-21: Initial skill — migration and schema evolution
