# Advanced Checks

## Supabase-aware checks
- Signup creates expected profile row/onboarding state
- Auth errors are understandable
- Missing session/profile bootstrap is surfaced
- Obvious permission leakage is flagged as critical
- Realtime listeners update UI when feature claims realtime support

## Vercel-aware checks
- Preview/prod mismatch symptoms
- API routes return expected status
- next/image loads properly
- favicon/logo/metadata basics
- custom 404/500 behavior
- cold-start delays if noticeable

## Accessibility upgrades
- keyboard tab flow basics
- visible focus state
- modal escape/close behavior
- empty buttons/links without accessible names

## Regression memory
After major QA runs, store repeated patterns in project memory:
- recurring auth breakages
- repeated env-var issues
- same UX issues across builds
- routes that commonly regress
