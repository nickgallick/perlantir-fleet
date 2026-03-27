# Architecture Defaults

## Core principles
- Build around user flows, not random pages
- Model auth and data early
- Keep server/client boundaries intentional
- Prefer simple, composable patterns
- Avoid premature abstraction but do not ship chaos

## Next.js defaults
- Server Components first
- Client Components for stateful UI only
- Route groups for organization when useful
- Use metadata properly for SEO-sensitive pages
- Keep fetch/data logic close to the route or server utility that owns it

## Supabase defaults
- Design tables and relationships before UI sprawl
- Use RLS intentionally
- Separate public client access from service-role operations
- Make signup bootstrap/profile creation explicit

## Quality defaults
- Empty states
- Error states
- Success states
- Loading states
- Mobile usability
- Accessibility basics
