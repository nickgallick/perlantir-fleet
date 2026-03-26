---
name: regex-mastery
description: Regex fluency — syntax, ReDoS prevention, production validation patterns, and regex code review checklist.
---

# Regex Mastery

## Review Checklist

- [ ] Regex takes user input as pattern → ReDoS risk (P0)
- [ ] Nested quantifiers without explanation → backtracking risk (P1)
- [ ] Complex regex without comment → add explanation (P2)
- [ ] Regex used for HTML/JSON/XML parsing → use proper parser (P2)
- [ ] Email/URL validation via regex → use Zod or URL constructor (P3)
- [ ] Validation regex without anchors `^...$` → partial match bugs (P2)

---

## ReDoS (Catastrophic Backtracking)

The #1 regex security vulnerability. Nested quantifiers cause exponential time.

**Dangerous patterns:**
```
(a+)+$          ← input "aaaaab" causes 2^n steps
(a|a)+$         ← overlapping alternation
(.*a){10}       ← quantified group with wildcard
([a-zA-Z]+)*    ← nested quantifiers
```

**Real CVEs:** ua-parser-js, moment.js, validator.js all had ReDoS.

**Rule:** NEVER use user input as a regex pattern without sanitization. If you must, use RE2 (linear-time engine) or set a timeout.

```ts
// ❌ P0: user controls the regex pattern
const pattern = new RegExp(userInput)
text.match(pattern) // attacker sends "(a+)+$" → server hangs

// ✅ Escape user input before using in regex
function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}
const pattern = new RegExp(escapeRegex(userInput))
```

## Production Validation Patterns

```ts
// UUID v4
/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

// Slug
/^[a-z0-9]+(?:-[a-z0-9]+)*$/

// Hex color
/^#(?:[0-9a-fA-F]{3}){1,2}$/

// Email: prefer z.string().email() over regex
// URL: prefer new URL(input) over regex — it's the correct tool
// Phone: prefer libphonenumber over regex
```

## Greedy vs Lazy

```ts
// Greedy (default): match as MUCH as possible
/<.+>/.exec('<div>hello</div>') // matches "<div>hello</div>" (entire string)

// Lazy (add ?): match as LITTLE as possible  
/<.+?>/.exec('<div>hello</div>') // matches "<div>" (first tag only)
```

## Sources
- OWASP ReDoS documentation
- Node.js security advisories for regex vulnerabilities

## Changelog
- 2026-03-21: Initial skill — regex mastery
