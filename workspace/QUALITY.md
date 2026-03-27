# QUALITY.md — Build Quality Standards

These standards apply to every project Maks builds. They are not optional. Default to this bar unless Nick explicitly says otherwise.

## Core Principle

First deploy should feel polished, trustworthy, and production-minded — not like a rough MVP.

Quality means:
- secure by default
- clean UX
- strong error handling
- consistent architecture
- performance-aware implementation
- enterprise-grade presentation

---

## 1. Security Standards

### Environment & Secrets
- All secrets live in `.env.local` or environment variables
- Never hardcode API keys, tokens, secrets, or service-role credentials
- Never expose secrets in client bundles, logs, or chat replies
- Validate required environment variables on startup

### Input Validation
- Use Zod validation for all API inputs and form submissions
- Sanitize user-controlled input before processing or storage
- Reject malformed input with clear 400-level errors

### Auth & Access Control
- Supabase Row Level Security on every relevant table
- Role-based access control where needed
- No admin-only operations from client-side trust alone
- Protect auth routes and callback flows carefully

### API Protection
- Rate limiting on write endpoints
  - auth: 5/minute
  - forms: 10/minute
  - search: 30/minute
- Consistent error format for API routes
- Use parameterized queries or safe ORM/database client methods only

### Headers & Browser Security
- Content-Security-Policy where appropriate
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Referrer-Policy: strict-origin-when-cross-origin
- Permissions-Policy for sensitive browser capabilities

---

## 2. Performance Standards

### Rendering & Data
- Prefer server-side rendering and server components when appropriate
- Use streaming / suspense where it improves perceived performance
- Avoid unnecessary client-side fetching
- Paginate large lists
- Use optimistic UI where it improves flow and is safe

### Frontend Performance
- Use dynamic imports for heavy components
- Debounce search inputs at ~300ms
- Memoize expensive computations when justified
- Keep bundle size under control
- Preload critical assets/routes when it materially improves UX

### UX Performance
- Skeleton states for async pages
- Loading indicators on every async action
- Empty states instead of blank screens
- Retry path for failed requests

---

## 3. SEO Standards

Apply to public pages unless the product is intentionally private/internal.

- Unique title and meta description per page
- Open Graph and Twitter Card tags
- Semantic HTML with proper heading hierarchy
- Sitemap and robots.txt where relevant
- Canonical URLs
- Alt text on all meaningful images
- Clean URL structure
- JSON-LD structured data where it makes sense

---

## 4. Accessibility Standards (WCAG 2.1 AA)

- Full keyboard navigation on interactive elements
- Visible focus states
- Labels for buttons, inputs, and icons
- Proper aria roles / landmarks where needed
- Focus trapping in modals/drawers
- Escape closes modal flows
- Color contrast meets AA standards
- Skip-to-content link on public-facing products
- Screen-reader-friendly form errors and status messages

---

## 5. Design Standards

### Baseline
- Mobile-first responsive layout
- Enterprise-grade visual finish
- Consistent spacing and typography
- Trust-building UI, not template-looking UI

### Required UX States
- Loading states
- Empty states
- Error states
- Success confirmation states
- Inline form validation
- Clear CTA hierarchy

### Interaction Standards
- Toasts or equivalent confirmations for important actions
- Smooth transitions where they help clarity
- No gratuitous animation
- Framer Motion only where it improves perceived polish and understanding

---

## 6. Code Quality Standards

- TypeScript strict mode
- Clear file naming and project structure
- No `any` unless absolutely unavoidable and justified
- Proper async error handling with `try/catch`
- No stray `console.log` in production code
- Consistent API response patterns
- Environment validation on startup
- Keep components and route handlers focused and readable

---

## 7. Error Handling Standards

- Custom 404 page or route-specific not-found handling
- Custom 500/error boundary behavior where appropriate
- Network failure handling with retry guidance
- User-friendly form submission errors
- API timeout handling when relevant
- Never expose raw internal errors to end users
- Log with context on the server side

---

## 8. Supabase Standards

- RLS enabled and tested
- Policies reflect actual user roles and ownership rules
- Service-role usage server-side only
- Tables and columns named cleanly
- Schema supports product workflows, not just implementation convenience
- Migrations are explicit and reviewable

---

## 9. Deployment Gate

Before deploy:
- TypeScript passes
- Lint passes or known issues are minor and intentional
- Forge review is completed
- No secret leakage in client code
- Env vars validated
- Basic QA path tested
- Live URL shared after successful deployment

---

## 10. What “Done” Means

A task is not done when the code compiles.
A task is done when:
- the feature works
- the UX is coherent
- the failure modes are handled
- the security model is sound
- the deploy is clean
- the output feels like Perlantir quality
