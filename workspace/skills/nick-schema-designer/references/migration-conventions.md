# Migration Conventions

## Naming
Use clear chronological names such as:
- `20260315_create_profiles.sql`
- `20260315_create_projects_and_tasks.sql`
- `20260315_add_project_membership_policies.sql`

## Order
1. extensions
2. base tables
3. dependent tables
4. indexes
5. functions/triggers
6. RLS enablement
7. policies
8. seed or test-support notes

## Rules
- avoid mixing unrelated schema changes in one migration when possible
- keep destructive changes explicit and well-commented
- call out backfill requirements before adding NOT NULL constraints
- note rollback considerations when changes are risky
