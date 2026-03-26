---
name: feature-flag-systems
description: Feature flags — env var flags, database-backed runtime flags, percentage rollout, flag lifecycle, and cleanup discipline.
---

# Feature Flag Systems

## Review Checklist

- [ ] New risky features behind flags
- [ ] Flag checks on BOTH server and client
- [ ] Default is OFF (fail-safe)
- [ ] Old flags at 100% for >30 days → clean up (tech debt)

---

## Simple: Environment Variable Flags

```ts
// lib/features.ts
export const FEATURES = {
  ARENA_TOURNAMENTS: process.env.FEATURE_ARENA_TOURNAMENTS === 'true',
  ARENA_COINS: process.env.FEATURE_ARENA_COINS === 'true',
  SPECTATOR_CHAT: process.env.FEATURE_SPECTATOR_CHAT === 'true',
  GLICKO2_RATING: process.env.FEATURE_GLICKO2_RATING === 'true',
} as const

// Usage
if (FEATURES.ARENA_TOURNAMENTS) {
  // Show tournament UI
}
```
Good for MVP. No runtime control — requires redeploy to change.

## Database-Backed: Runtime Control

```sql
CREATE TABLE feature_flags (
  id text PRIMARY KEY,
  enabled boolean DEFAULT false,
  rollout_percentage int DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
  allowed_user_ids uuid[] DEFAULT '{}',
  allowed_tiers text[] DEFAULT '{}',
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

INSERT INTO feature_flags (id, enabled, rollout_percentage, description)
VALUES ('arena_tournaments', true, 25, 'Tournament bracket system');
```

```ts
// Deterministic percentage rollout (same user always gets same result)
function isEnabledForUser(flag: FeatureFlag, userId: string): boolean {
  if (!flag.enabled) return false
  
  // Explicit allowlist
  if (flag.allowed_user_ids.includes(userId)) return true
  
  // Percentage rollout: hash(userId + flagId) produces consistent result
  const hash = hashCode(`${userId}:${flag.id}`)
  return (hash % 100) < flag.rollout_percentage
}

// Cache for 60 seconds (don't hit DB on every check)
const flagCache = new Map<string, { flag: FeatureFlag; expiresAt: number }>()
```

## Flag Lifecycle

```
1. CREATE flag (default OFF)
2. DEVELOP behind flag
3. GRADUAL ROLLOUT:
   5% → monitor 24h → 25% → monitor 48h → 50% → monitor 1 week → 100%
4. MONITOR at 100% for 2 weeks
5. REMOVE flag AND all conditional code ← critical step

Flags at 100% for >30 days = tech debt. Monthly cleanup review.
```

## Anti-Patterns

```ts
// ❌ Nested flags (creates combinatorial explosion)
if (FEATURES.TOURNAMENTS && FEATURES.SPECTATOR_CHAT && FEATURES.GLICKO2) { ... }

// ❌ Flag checked in wrong place (server flag checked only on client)
// Client can be manipulated — check on server too

// ❌ Flag without cleanup plan
// Every flag needs: owner, creation date, expected removal date
```

## Sources
- LaunchDarkly documentation (feature flag best practices)
- Martin Fowler's "Feature Toggles" article
- cal.com feature flag implementation

## Changelog
- 2026-03-21: Initial skill — feature flag systems
