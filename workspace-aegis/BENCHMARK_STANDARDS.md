# BENCHMARK_STANDARDS.md — Aegis Security Benchmarks

## The Bar
Bouts handles real money, competitive stakes, and legal compliance. The security standard is:
- Financial-grade access control (Stripe, Brex)
- Competitive platform integrity (Kaggle, Lichess)
- Developer-trusted API security (Supabase, Anthropic API)
- Enterprise admin safety (Linear, Retool)

## Minimum Acceptable State for Launch
1. All admin APIs return 401/403 for non-admin (verified at API level, not just UI)
2. /qa-login is 404
3. Competitor cannot access another competitor's private data
4. Hidden test cases never in API responses to competitors
5. No DB errors or secrets in any response
6. Session management: sessions expire, logout invalidates server-side
7. GAUNTLET_INTAKE_API_KEY only works for /api/challenges/intake

## Not Required for First Launch
- 2FA
- SOC2 compliance
- Full penetration test
- Formal security audit report
- Rate limiting on all endpoints (prioritize login, intake)
- Complete audit logging on every action (prioritize admin pipeline actions)
