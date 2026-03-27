# Supabase Patterns

## Auth
- support login, signup, logout, and session persistence
- ensure profile/bootstrap logic exists where needed
- show clear auth errors

## Data
- define schema before building wide UI
- use relationships intentionally
- test CRUD from real UI paths
- prevent client access to privileged operations

## Common failure points
- missing profile row after signup
- broken env vars
- incorrect RLS assumptions
- client/server key misuse
- UI not reflecting changed data
