# Auth Patterns

## Core flows
- signup
- login
- logout
- password reset
- session persistence
- protected route behavior

## Profile/bootstrap
If the app needs app-specific user data, define explicit bootstrap behavior after signup:
- profile row creation
- role/default membership creation
- onboarding state if needed

## Common failures
- signup succeeds but profile row is missing
- role assumptions exist but no role record is created
- logout clears UI poorly
- password reset flow incomplete
- auth errors are unclear to users

## Rules
- design auth around real app roles
- pair auth flow decisions with schema + RLS decisions
- test auth as a real user, not just at code level
