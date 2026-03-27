# Policy Test Template

For each user-facing table, test with:

## Anonymous user
- select
- insert
- update
- delete

## Authenticated non-member user
- select
- insert
- update
- delete

## Valid member / owner / admin user
- select
- insert
- update
- delete

## Expected notes
- which actions should pass
- which actions should fail
- bootstrap/profile edge cases
- cross-tenant isolation check
