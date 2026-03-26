# Forge Research — Forge Skill

## Overview

Forge continuously improves its knowledge through structured research. This skill defines how Forge finds, evaluates, and incorporates new information.

## Direct Sources

### Official Documentation (Highest Trust)

| Source | What to Look For |
|--------|-----------------|
| Next.js docs (nextjs.org/docs) | API changes, new features, migration guides |
| React docs (react.dev) | New hooks, patterns, deprecations |
| Supabase docs (supabase.com/docs) | Auth changes, RLS updates, new features |
| Expo docs (docs.expo.dev) | SDK updates, new modules, breaking changes |
| TypeScript docs (typescriptlang.org) | New type features, compiler options |
| PostgreSQL docs (postgresql.org/docs) | Query optimization, new features |
| MDN Web Docs | Web APIs, HTML/CSS/JS standards |
| OWASP (owasp.org) | Security best practices, vulnerability patterns |
| WCAG (w3.org/WAI/WCAG21) | Accessibility standards |

### Release Channels

| Source | What to Track |
|--------|--------------|
| GitHub Releases | Next.js, Supabase, Expo, React, TypeScript |
| Changelogs | Breaking changes, deprecations, new features |
| RFCs | Upcoming features that may affect patterns |
| Security Advisories | npm advisories, CVE databases |

### Community (Verify Before Trusting)

| Source | Trust Level | Use For |
|--------|-------------|---------|
| GitHub issues/discussions | Medium | Bug reports, workarounds |
| Stack Overflow | Medium | Common patterns, solutions |
| Blog posts from framework teams | High | Official guidance, best practices |
| Random blog posts | Low | Ideas to verify against docs |
| Twitter/X from core team | Medium | Early announcements, context |

## Search Queries

When researching a topic, use structured search queries:

### For Framework Updates

```
"[framework] [version] changelog"
"[framework] [version] breaking changes"
"[framework] [version] migration guide"
"[framework] [feature] documentation"
```

### For Best Practices

```
"[framework] [pattern] best practices [year]"
"[framework] [anti-pattern] why avoid"
"[technology] security best practices [year]"
"[technology] performance optimization"
```

### For Specific Issues

```
"[framework] [error message]"
"[framework] [feature] not working [version]"
"[framework] [feature] vs [alternative]"
```

## Evaluation Criteria

When evaluating information from any source:

### Accept If

- Comes from official documentation
- Consistent with framework source code (check `repos/`)
- Multiple reliable sources agree
- Includes working code examples that match current API
- Published by a framework team member or recognized contributor

### Verify Further If

- From a single community source
- Contradicts current skill file content
- Seems outdated (check date)
- No code examples provided
- The approach seems overly complex

### Reject If

- Contradicts official documentation
- Uses deprecated APIs
- No date or clearly outdated
- From an unreliable or unknown source
- Introduces security vulnerabilities
- Recommends disabling safety features

## Self-Improvement Process

### When Researching

1. Define the question clearly
2. Start with official docs
3. Check framework source code in `repos/` if needed
4. Verify with web search if docs are insufficient
5. Cross-reference multiple sources
6. Test understanding against known patterns

### After Researching

1. Update the relevant `skills/*/SKILL.md` file
2. Log the research in `research-logs/` with:
   - Date
   - Topic
   - Sources consulted
   - Key findings
   - Changes made to skill files
3. Note any open questions for future research

### Research Log Format

```markdown
# Research: [Topic]
Date: YYYY-MM-DD

## Question
[What was being investigated]

## Sources Consulted
- [Source 1] — [What it said]
- [Source 2] — [What it said]

## Findings
[Key takeaways]

## Changes Made
- Updated `skills/[skill]/SKILL.md`: [What changed]

## Open Questions
- [Any remaining unknowns]
```

## Source Recommendation

When recommending a fix or pattern in a review, include the source:

```
P2: Use `useOptimistic` instead of manual optimistic state.
This is the recommended pattern as of React 19.
Source: react.dev/reference/react/useOptimistic
```

This builds trust with developers and makes it easy to verify the recommendation.
