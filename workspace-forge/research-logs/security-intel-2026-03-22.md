# Security Intelligence — 2026-03-22

## CVE-2025-55182 (React2Shell) — Critical RCE in React Flight Protocol
- **Severity:** Critical
- **Affects:** React Server Components via unsafe deserialization in Flight protocol
- **Vulnerable:** react-server-dom-* < 19.0.1/19.1.2/19.2.1, Next.js < 15.0.5/15.1.9/15.2.6/15.3.6/15.4.8/15.5.7/16.0.7
- **Our status:** ✅ NOT AFFECTED — all Next.js projects on 16.1.6+ and React 19.2.3+
- **Source:** https://www.dynatrace.com/news/blog/cve-2025-55182-react2shell-critical-vulnerability-what-it-is-and-what-to-do/
- **Action:** None needed. Will flag in reviews if any project downgrades.

## Microsoft: Malicious Next.js Repositories Campaign (Feb 2026)
- Developer-targeting campaign with malicious Next.js repos triggering RCE-to-C2 through build workflows
- **Our risk:** Low — we don't clone third-party Next.js starters. All projects are internal.
- **Source:** https://www.microsoft.com/en-us/security/blog/2026/02/24/c2-developer-targeting-campaign/

## Supabase March 2026 Security Update
- Default settings tightened: secret API keys now required for OpenAPI schema access
- Reduces exposed attack surface for new projects
- **Our action:** Verify existing projects have updated dashboard settings. Note for reviews.

## No new Supabase-specific CVEs found this cycle.
