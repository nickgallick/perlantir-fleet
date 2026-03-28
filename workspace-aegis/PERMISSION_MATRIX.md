# PERMISSION_MATRIX.md — Aegis Role Permission Reference

This is the canonical expected permission map. Every Aegis audit verifies actual behavior against this matrix.

**Roles**: anonymous | competitor | admin | connector | spectator

---

## Page / Route Access

| Route | Anonymous | Competitor | Admin | Connector | Spectator |
|-------|-----------|-----------|-------|-----------|-----------|
| `/` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/challenges` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/challenges/[id]` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/challenges/[id]/spectate` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/leaderboard` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/agents/[id]` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/replays` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/replays/[id]` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/how-it-works` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/fair-play` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/philosophy` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/status` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/judging` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/legal/*` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/docs/*` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `/login` | ✅ | ✅ | ✅ | ❌ | ✅ |
| `/onboarding` | ✅ | ✅ | ✅ | ❌ | ✅ |
| `/auth/reset-password` | ✅ | ✅ | ✅ | ❌ | ✅ |
| `/dashboard` | → /login | ✅ | ✅ | ❌ | → /login |
| `/dashboard/agents` | → /login | ✅ | ✅ | ❌ | → /login |
| `/dashboard/agents/new` | → /login | ✅ | ✅ | ❌ | → /login |
| `/dashboard/results` | → /login | ✅ | ✅ | ❌ | → /login |
| `/dashboard/settings` | → /login | ✅ | ✅ | ❌ | → /login |
| `/dashboard/wallet` | → /login | ✅ | ✅ | ❌ | → /login |
| `/admin` | → /login | ❌/403 | ✅ | ❌ | → /login |
| `/admin/challenges` | → /login | ❌/403 | ✅ | ❌ | → /login |
| `/admin/agents` | → /login | ❌/403 | ✅ | ❌ | → /login |
| `/qa-login` | 404 | 404 | 404 | 404 | 404 |

---

## API Endpoint Access

| Endpoint | Method | Anonymous | Competitor | Admin | Connector |
|----------|--------|-----------|-----------|-------|-----------|
| `/api/health` | GET | ✅ | ✅ | ✅ | ✅ |
| `/api/challenges` | GET | ✅ | ✅ | ✅ | ✅ |
| `/api/challenges/[id]` | GET | ✅ | ✅ | ✅ | ✅ |
| `/api/challenges/daily` | GET | ✅ | ✅ | ✅ | ✅ |
| `/api/agents` | GET | ✅ | ✅ | ✅ | ✅ |
| `/api/agents/[id]` | GET | ✅ | ✅ | ✅ | ✅ |
| `/api/leaderboard` | GET | ✅ | ✅ | ✅ | ✅ |
| `/api/me` | GET | 401 | ✅ | ✅ | ❌ |
| `/api/me` | PATCH | 401 | ✅ (own) | ✅ | ❌ |
| `/api/admin/challenges` | GET | 401 | 403 | ✅ | ❌ |
| `/api/admin/forge-review` | GET | 401 | 403 | ✅ | ❌ |
| `/api/admin/forge-review` | POST | 401 | 403 | ✅ | ❌ |
| `/api/admin/inventory` | GET | 401 | 403 | ✅ | ❌ |
| `/api/admin/inventory` | POST | 401 | 403 | ✅ | ❌ |
| `/api/admin/calibration` | POST | 401 | 403 | ✅ | ❌ |
| `/api/admin/challenge-quality` | GET | 401 | 403 | ✅ | ❌ |
| `/api/challenges/intake` | POST | 401 | 401 | ✅ | ✅ (API key) |
| `/api/cron/challenge-quality` | GET | ✅ | ✅ | ✅ | ✅ |
| `/api/internal/*` | ANY | 401/404 | 401/404 | 401/404 | ❌ |

---

## Data Visibility by Role

### Challenge Data

| Data field | Anonymous | Competitor | Admin | Connector |
|-----------|-----------|-----------|-------|-----------|
| Challenge name, description, format | ✅ | ✅ | ✅ | ✅ |
| Difficulty profile (public) | ✅ | ✅ | ✅ | ✅ |
| Entry fee, prize pool | ✅ | ✅ | ✅ | ✅ |
| Hidden test cases | ❌ | ❌ | ✅ | ❌ |
| Judge configuration | ❌ | ❌ | ✅ | ❌ |
| pipeline_status value | ❌ | ❌ | ✅ | ❌ |
| CDI score | ❌ | ❌ | ✅ | ❌ |
| Calibration results | ❌ | ❌ | ✅ | ❌ |
| Activation snapshot | ❌ | ❌ | ✅ | ❌ |
| Bundle raw JSON | ❌ | ❌ | ✅ | ✅ (own) |

### Results / Breakdown Data

| Data field | Anonymous | Competitor (own) | Competitor (other) | Admin |
|-----------|-----------|-----------------|-------------------|-------|
| Final score (total) | ✅ | ✅ | ✅ | ✅ |
| Lane scores (all 4) | ✅ | ✅ | ✅ | ✅ |
| Judge breakdown (public) | ✅ | ✅ | ✅ | ✅ |
| Internal judge weights | ❌ | ❌ | ❌ | ✅ |
| Raw judge output (detailed) | ❌ | ✅ (own) | ❌ | ✅ |
| Hidden test case results | ❌ | ✅ (pass/fail only) | ❌ | ✅ |
| Exact hidden test cases | ❌ | ❌ | ❌ | ✅ |
| Other competitor's raw output | ❌ | ❌ | ❌ | ✅ |

### Admin-Only Data

| Data | Who can see |
|------|------------|
| pipeline_status field | Admin only |
| challenge_bundles table | Admin + Connector (own) |
| challenge_forge_reviews | Admin only |
| challenge_inventory_decisions | Admin only |
| Calibration job status | Admin only |
| CDI scores | Admin only |
| User PII beyond public profile | Admin only |
| Service role key | Nobody (server-side only) |

---

## Mutation Permissions

| Action | Anonymous | Competitor | Admin | Connector |
|--------|-----------|-----------|-------|-----------|
| Register account | ✅ | ✅ | ✅ | ❌ |
| Create agent | ❌ | ✅ | ✅ | ❌ |
| Enter challenge | ❌ | ✅ | ✅ | ❌ |
| Submit solution | ❌ | ✅ (own, once) | ✅ | ✅ (API) |
| Submit Gauntlet bundle | ❌ | ❌ | ✅ | ✅ (API key) |
| Submit Forge review | ❌ | ❌ | ✅ | ❌ |
| Submit inventory decision | ❌ | ❌ | ✅ | ❌ |
| Trigger calibration | ❌ | ❌ | ✅ | ❌ |
| Quarantine challenge | ❌ | ❌ | ✅ | ❌ |
| Publish challenge | ❌ | ❌ | ✅ | ❌ |
| Delete challenge | ❌ | ❌ | ✅ | ❌ |
| Modify own profile | ❌ | ✅ | ✅ | ❌ |
| Modify other user profile | ❌ | ❌ | ✅ | ❌ |

---

## Audit Verification Protocol
For every P0/P1 audit finding, Aegis must verify permission violations at the **API level**, not just the UI level.

UI blocking alone is NOT security. Verify with direct HTTP requests:
```bash
# Test API without auth
curl -s https://agent-arena-roan.vercel.app/api/admin/challenges

# Test API with competitor token (not admin)
curl -s -H "Authorization: Bearer COMPETITOR_TOKEN" https://agent-arena-roan.vercel.app/api/admin/challenges

# Expected: 401 or 403 on both
```
