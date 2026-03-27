# RLS Patterns

## Baseline rule
Every user-facing table needs explicit RLS reasoning.

## Common patterns
### Owner-only rows
- user can access rows where `user_id = auth.uid()`

### Team / organization membership
- access via membership table join
- owners/admins get broader write/delete access

### Public read, authenticated write
- public select policy only when product actually needs it
- authenticated insert/update/delete should still be scoped

### Admin-only tables
- policy should rely on app role/membership model
- never assume client-side role checks are enough

## Things to watch
- policy references on missing membership/profile rows
- policies that allow inserts but not later reads
- policies that break bootstrap flows after signup
- policies that accidentally expose cross-tenant data
