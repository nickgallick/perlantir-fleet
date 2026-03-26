---
name: competitive-platform-integrity
description: Anti-cheat, ELO manipulation prevention, Sybil defense, virtual currency compliance, and community moderation for competitive AI platforms. The integrity bible for Agent Arena. Cover ELO system design, anti-sandbagging, multi-account detection, submission integrity, judge integrity, economy abuse prevention, spectator privacy, replay integrity. Includes Supabase/Postgres patterns (RLS, functions, triggers).
---

# Competitive Platform Integrity

## Quick Reference — Code Review Checklist

1. [ ] ELO calculated server-side only via Postgres function — never trust client
2. [ ] Submissions table: no UPDATE/DELETE RLS policies (append-only)
3. [ ] Coin balance changes only via `transact_coins()` with SELECT FOR UPDATE
4. [ ] Weight class enforced at entry time AND post-challenge verification
5. [ ] Multi-judge consensus with outlier detection on every judged challenge
6. [ ] Replay events have hash chain — tamper detection on every read
7. [ ] Agent API keys bcrypt-hashed, never stored raw, never logged
8. [ ] Rate limits on all economy endpoints (purchases, transfers)
9. [ ] Spectator feed delayed 30s server-side (not client-side)
10. [ ] Multi-account signals logged: IP, API key correlation, behavioral fingerprints

For detailed patterns, read the relevant reference file:
- **ELO system design** → [references/elo-system.md](references/elo-system.md)
- **Anti-cheat detection** → [references/anti-cheat.md](references/anti-cheat.md)
- **Economy & currency** → [references/economy.md](references/economy.md)
- **Judge integrity** → [references/judge-integrity.md](references/judge-integrity.md)
- **Supabase enforcement patterns** → [references/supabase-patterns.md](references/supabase-patterns.md)

---

## Architecture Principles

### Defense in Depth
Every competitive integrity rule is enforced at **multiple layers**:
1. **Database constraints** — CHECK, UNIQUE, FK, NOT NULL
2. **RLS policies** — Row-level access control
3. **Postgres functions** — SECURITY DEFINER business logic
4. **API validation** — Zod schemas + auth checks
5. **Statistical detection** — Post-hoc anomaly analysis

No single layer is trusted alone. If RLS is bypassed, the function still enforces. If the function is bypassed (service role), the constraint still holds.

### Server Authority
The server is the single source of truth for:
- ELO ratings (calculated, never accepted from clients)
- Submission timestamps (server-generated, not client-reported)
- Coin balances (modified only via locked Postgres function)
- Challenge status transitions (state machine enforced server-side)
- Weight class assignment (derived from model MPS, not user-declared)

### Transparency as Deterrent
Public replay transcripts are the most powerful anti-cheat mechanism. When agents know their work is visible, manipulation becomes harder to hide and easier to report.

---

## When to Read Reference Files

| Situation | Read |
|---|---|
| Designing or reviewing ELO calculation, K-factors, floors, decay | `references/elo-system.md` |
| Reviewing anti-sandbagging, multi-account, smurfing detection | `references/anti-cheat.md` |
| Reviewing coin transactions, streak freezes, purchase flows | `references/economy.md` |
| Reviewing AI judge scoring, consensus, outlier detection | `references/judge-integrity.md` |
| Writing or reviewing Supabase RLS, functions, triggers for competitive rules | `references/supabase-patterns.md` |
