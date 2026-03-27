# Auth Test Patterns

For auth-sensitive routes, test:
- no auth
- invalid auth
- valid auth, wrong role
- valid auth, correct role

If the route is supposed to be public, make that explicit too.

For Supabase-backed projects, think about:
- missing profile/bootstrap row
- membership/role assumptions
- policy-driven behavior vs route-level checks
