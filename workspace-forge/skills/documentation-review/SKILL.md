---
name: documentation-review
description: What needs docs, what doesn't, documentation quality assessment, inline doc patterns, and ADR (Architecture Decision Record) format.
---

# Documentation Review

## What NEEDS Documentation (flag if missing)

| What | Why | Format |
|------|-----|--------|
| README.md per package | New devs need to know what it does, how to run, how to deploy | Markdown with setup steps |
| API endpoints | Consumers need method, path, schema, errors, auth | OpenAPI or markdown table |
| Database schema | Future devs need purpose of each table, relationships, constraints | SQL comments + ERD |
| Environment variables | Every env var: description, required/optional, example | `.env.example` file |
| Architecture decisions | WHY a particular approach was chosen | ADR (see below) |
| Complex algorithms | Any function that takes >30s to understand | Inline JSDoc + comments |

## What Does NOT Need Documentation (flag if over-documented)

- `getUserById(id: string)` — the name IS the documentation
- `<Button>` — doesn't need "renders a button"
- Trivial getters/setters
- Code that changes frequently (docs go stale faster than code)

## Documentation Quality Checks

1. **Accurate?** Outdated docs are worse than no docs.
2. **Findable?** Can a new dev discover it?
3. **Explains WHY?** "We use cursor pagination because offset breaks on real-time data" > "Pagination is cursor-based"
4. **Has examples?** For APIs: show a curl request and response.
5. **Setup guide tested?** Can someone actually follow it from zero?

## Architecture Decision Records (ADR)

```markdown
# ADR-001: Cursor-Based Pagination

## Status: Accepted

## Context
Arena leaderboards update in real-time. Offset pagination (page 1, page 2) breaks when
new entries are inserted — users see duplicate or missing items.

## Decision
Use cursor-based pagination with `created_at` timestamps as cursors.

## Consequences
- ✅ Stable pagination during real-time updates
- ✅ Consistent performance regardless of page depth
- ❌ Can't jump to "page 5" directly (sequential access only)
- ❌ Slightly more complex client implementation
```

## Inline Documentation Patterns

```ts
// ✅ GOOD: explains WHY (non-obvious business logic)
// We use advisory locks here instead of SELECT FOR UPDATE because
// ELO updates can span multiple tables and advisory locks are
// released at transaction end regardless of which tables are touched.
PERFORM pg_advisory_xact_lock(hashtext(p_agent_id::text));

// ❌ BAD: explains WHAT (the code already says this)
// Update the user's name
user.name = newName;

// ✅ TODO with context and reference
// TODO(arena-42): Replace with proper rate limiting middleware
// Current implementation uses in-memory counter, won't work across Vercel instances

// ✅ HACK with explanation
// HACK: Supabase Realtime doesn't guarantee event ordering.
// We buffer events and sort by sequence number before processing.
// Real fix: implement server-side event sequencing in the orchestrator.

// ✅ IMPORTANT for critical business logic
// IMPORTANT: This balance check and deduction MUST be atomic.
// If separated, concurrent requests can overdraw the balance.
// See ADR-003 for why we use a Postgres function instead of application-level locking.
```

## Sources
- ADR format from Michael Nygard
- js-testing-best-practices documentation patterns
- cal.com docs structure

## Changelog
- 2026-03-21: Initial skill — documentation review
