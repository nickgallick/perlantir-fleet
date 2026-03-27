# Schema Workflow

## 1. Understand the product
- What is the app for?
- Who uses it?
- What actions do they take?
- What permissions differ by role?

## 2. Map the entities
- Core tables
- Junction tables
- Audit/support tables
- Profile/bootstrap tables

## 3. Map the relationships
- ownership
- membership
- parent/child
- many-to-many

## 4. Add operational needs
- indexes
- uniqueness constraints
- soft delete only if justified
- audit fields
- cascade/restrict choices

## 5. Write RLS intentionally
- who can read?
- who can insert?
- who can update?
- who can delete?
- does tenant/role isolation work?

## 6. Finish delivery artifacts
- migration SQL
- TS types
- seed data
- rollout notes
- test checklist
