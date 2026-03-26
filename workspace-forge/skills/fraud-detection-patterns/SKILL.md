---
name: fraud-detection-patterns
description: Fraud detection for Arena anti-cheat and OUTBOUND abuse prevention — behavioral analytics, statistical anomaly detection, velocity checks, fingerprinting, abuse pattern catalog.
---

# Fraud Detection Patterns

## Review Checklist

- [ ] Rate limiting on account creation and authentication
- [ ] Velocity checks on financial transactions (coins, entries)
- [ ] Statistical anomaly detection on competition results
- [ ] Account correlation data collected (IP, user agent, creation time)
- [ ] Abuse reports have automated escalation thresholds
- [ ] Fraud detection is async (doesn't block user experience)

---

## Behavioral Analytics

### Session Fingerprinting
```ts
// Collect behavioral signals (privacy-respecting, no PII)
interface SessionFingerprint {
  userAgent: string
  screenResolution: string
  timezone: string
  language: string
  colorDepth: number
  platform: string
  // Combined hash = device fingerprint (not unique, but discriminating)
}

// Store with each login for correlation analysis
async function recordLogin(userId: string, fingerprint: SessionFingerprint) {
  await supabase.from('login_events').insert({
    user_id: userId,
    fingerprint_hash: hashFingerprint(fingerprint),
    ip_address: getClientIP(), // hashed, not raw
    created_at: new Date().toISOString(),
  })
}
```

### Behavioral Baselines
Build a normal behavior profile per agent/user, then flag deviations:

| Signal | Normal | Anomalous |
|--------|--------|-----------|
| Challenge entry rate | 1-5/week | 50/week |
| Win rate | 40-60% | 95%+ sustained |
| Response time pattern | Consistent with model class | Sudden speed change |
| Voting pattern | Varied across entries | Always votes for same agent |
| Login timing | Consistent timezone | Logins from 5 timezones in 1 hour |

## Statistical Anomaly Detection

### Z-Score for Performance Outliers
```ts
function detectPerformanceAnomaly(
  agentId: string,
  recentScores: number[],
  historicalMean: number,
  historicalStdDev: number
): AnomalyResult {
  const recentMean = recentScores.reduce((a, b) => a + b) / recentScores.length
  const zScore = (recentMean - historicalMean) / Math.max(historicalStdDev, 1)
  
  return {
    agentId,
    zScore,
    anomalous: Math.abs(zScore) > 3, // 3 sigma = 0.13% chance of being normal
    direction: zScore > 0 ? 'overperforming' : 'underperforming',
    confidence: Math.abs(zScore) > 4 ? 'HIGH' : Math.abs(zScore) > 3 ? 'MEDIUM' : 'LOW',
  }
}
```

### Benford's Law for Financial Fraud
```ts
// Arena Coins: legitimate transactions follow Benford's distribution
// Fraudulent transactions (coin duplication, fake purchases) don't
function checkBenford(amounts: number[]): boolean {
  const expectedFirst = [0, 30.1, 17.6, 12.5, 9.7, 7.9, 6.7, 5.8, 5.1, 4.6] // %
  const actualFirst = new Array(10).fill(0)
  
  for (const amount of amounts) {
    const firstDigit = parseInt(String(Math.abs(amount))[0])
    actualFirst[firstDigit]++
  }
  
  // Chi-squared test against expected distribution
  // Significant deviation → flag for review
  return chiSquaredTest(actualFirst, expectedFirst, amounts.length) > 0.05
}
```

## Velocity Checks

```ts
// Rate-based fraud prevention
const VELOCITY_LIMITS = {
  account_creation_per_ip: { limit: 3, window: '24 hours' },
  login_attempts_per_account: { limit: 10, window: '15 minutes' },
  coin_purchases_per_day: { limit: 5, window: '24 hours' },
  challenge_entries_per_hour: { limit: 10, window: '1 hour' },
  votes_per_minute: { limit: 5, window: '1 minute' },
  password_resets_per_day: { limit: 3, window: '24 hours' },
} as const

async function checkVelocity(
  key: string, // e.g., "account_creation:192.168.1.1"
  rule: keyof typeof VELOCITY_LIMITS
): Promise<{ allowed: boolean; remaining: number }> {
  const config = VELOCITY_LIMITS[rule]
  return checkRateLimit(key, config.limit, parseWindow(config.window))
}
```

## Multi-Account Detection

```sql
-- Find accounts that share characteristics
SELECT a.id as account_a, b.id as account_b,
  CASE 
    WHEN a.creation_ip = b.creation_ip THEN 'same_ip'
    WHEN a.fingerprint_hash = b.fingerprint_hash THEN 'same_device'
    WHEN similarity(a.agent_config, b.agent_config) > 0.8 THEN 'similar_config'
  END as correlation_type
FROM users a
JOIN users b ON a.id < b.id -- avoid self-join and duplicates
WHERE a.creation_ip = b.creation_ip
   OR a.fingerprint_hash = b.fingerprint_hash;
```

## Abuse Pattern Catalog

| Pattern | Signal | Detection | Response |
|---------|--------|-----------|----------|
| **Vote ring** | Group of accounts always vote together | Graph analysis of vote correlation | Shadow ban votes |
| **Coin farming** | Create accounts → win easy challenges → transfer coins | New account + high win rate + transfers | Freeze transfers for new accounts |
| **Rating manipulation** | Two accounts alternately win/lose against each other | Pair frequency analysis | ELO reset + warning |
| **Submission plagiarism** | Copy another entry with minor changes | Embedding similarity >0.9 between entries | Disqualify + warning |
| **Judge manipulation** | Injection patterns in submissions | Pre-judge injection scanner | Flag for manual review |
| **Referral abuse** | Create fake accounts for referral rewards | Same IP/device for referrer and referee | Void referral credits |

## Implementation Architecture

```
User action → Normal processing (synchronous)
     ↓ (async, non-blocking)
Fraud signal queue → Fraud analysis worker
     ↓
Decision: ALLOW / FLAG / BLOCK
     ↓
If FLAG: log to fraud_events table, notify moderator
If BLOCK: suspend action, notify user
```

**Key principle:** Fraud detection runs ASYNC. Never block the user experience to check for fraud (except velocity limits, which are fast). Analyze patterns after the fact and take action retroactively.

## Sources
- Chess.com Fair Play system (behavioral analytics at scale)
- Stripe Radar (payment fraud detection patterns)
- Kaggle competition integrity enforcement
- Benford's Law for financial fraud detection

## Changelog
- 2026-03-21: Initial skill — fraud detection patterns
