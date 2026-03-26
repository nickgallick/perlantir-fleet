---
name: code-review-protocol
description: Forge's standard operating procedure for receiving and executing code reviews.
---

# Code Review Protocol

## How Reviews Arrive

MaksPM spawns you via sessions_spawn with a review request. Your output auto-announces back to MaksPM when done.

## Expected Review Request Format

```
FORGE REVIEW REQUEST
Project: [name]
Repo: [path]
Changed files: [list or "full project"]
Type: [new-build | feature | bugfix | refactor]
Stack: [Next.js | Expo | API-only | full-stack]
Supabase tables affected: [list or "none"]
Auth changes: [yes/no]
Notes: [focus areas]
```

If the request doesn't follow this format, still review — extract what you can.

## Review Process

1. **Read ALL code first** — understand the full picture before flagging anything
2. **Check developer-patterns** — front-load checks for Maks's known blind spots
3. **Run 8-point checklist:**
   - Security (auth, RLS, secrets, injection, CORS)
   - Type Safety (any, assertions, missing types, Zod coverage)
   - Architecture (component structure, server/client boundary, data flow)
   - Data Integrity (validation, null handling, race conditions, error states)
   - Performance (N+1, re-renders, bundle size, missing indexes)
   - Error Handling (unhandled promises, try/catch, user-facing errors, loading/empty states)
   - Accessibility & SEO (alt text, headings, ARIA, meta, contrast)
   - Code Quality (naming, duplication, dead code, complexity)
4. **Cross-reference framework source repos** for pattern validation
5. **Run threat model** — think like an attacker
6. **Write verdict** using standard format
7. **Generate auto-fix** for every WARNING or BLOCKED issue
8. **Save to review-history/** — `review-YYYY-MM-DD-[project].md`
9. **Update developer-patterns** — add new issues, check for recurring patterns

## Verdict Format

```
## Forge Review — [Project] — [Date]

**Verdict**: ✅ APPROVED / ⚠️ APPROVED WITH WARNINGS / ❌ BLOCKED

### Security: PASS / [n issues]
### Types: PASS / [n issues]
### Architecture: PASS / [n issues]
### Data: PASS / [n issues]
### Performance: PASS / [n issues]
### Error Handling: PASS / [n issues]
### A11y/SEO: PASS / [n issues]
### Code Quality: PASS / [n issues]

### Issues
[#. SEVERITY | file:line | issue | fix]

### Threat Model
[Attack vectors considered and their status]

### What's Done Well
[Positive reinforcement — list strengths]

### Auto-Fix
[Complete corrected code for every WARNING/BLOCKED issue]
```

## Severity Levels
- **P0** (🚨 BLOCKED): Security vuln, auth bypass, data exposure, crash risk, COPPA violation
- **P1** (🚨 BLOCKED): Broken core flow, data loss risk, missing RLS on user tables
- **P2** (⚠️ WARNING): Type gaps, missing validation, performance issue, accessibility gap
- **P3** (ℹ️ INFO): Naming, style, minor optimization — never blocks

## Review Scope by Type
- **new-build**: Full 8-point review, every file
- **feature**: Changed files + security surface area
- **bugfix**: Verify fix is correct, check for regressions
- **refactor**: Architecture + type safety + no behavior change

## After Every Review
1. Save review to `review-history/review-YYYY-MM-DD-[project].md`
2. Update `developer-patterns` with new issues found
3. If same issue appears 3+ times → flag it as a blind spot pattern

## Changelog
- 2026-03-21: Restored full version with structured handoff, threat model, auto-fix requirement
- 2026-03-20: Initial protocol
