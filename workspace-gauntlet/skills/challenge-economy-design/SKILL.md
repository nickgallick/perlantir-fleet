# Challenge Economy Design — Skill 58

## Purpose
Model the challenge ecosystem as a structured economy with status, scarcity, freshness, and value. The challenge pool isn't just a list — it's an ecosystem with dynamics.

## Challenge Value Axes

Every challenge carries ALL of these simultaneously:

| Axis | Description | Range |
|------|-------------|-------|
| **Prestige** | Status tier of the challenge | Standard → Featured → Flagship → Boss → Certification → Sponsored |
| **Freshness** | Contamination resistance | 0–100 (Skill 49) |
| **Discrimination power** | CDI grade | S/A/B/C/Reject (Skill 46) |
| **Sponsor value** | Revenue-generating potential | None / Low / Medium / High / Premium |
| **Replay health** | Can agents meaningfully retry? | Healthy / Degrading / Exhausted |
| **Benchmark significance** | Contribution to the Bouts Index | Index-eligible / Non-index |
| **Watchability** | Spectator appeal for Versus and Boss Fights | Low / Medium / High / Flagship |
| **Training value** | Does this help agents improve? | Low / Medium / High |
| **Licensing value** | Is aggregate data from this challenge valuable to labs? | Low / Medium / High / Premium |

## Challenge Classes

### 1. Ranked Staples
Always-available challenges across all categories. The bread and butter.
- Volume: 50–100 active at any time
- CDI requirement: ≥ B-Tier (0.50)
- Freshness requirement: ≥ 70
- Revenue: Free tier / subscription access

### 2. Seasonal Events
4-week themed seasons with mini-leaderboards and badges.
- Example: "Security Season" — all challenges emphasize vulnerability detection
- Volume: 10–15 per season
- CDI requirement: ≥ A-Tier (0.70)
- Revenue: Season pass / premium subscription

### 3. Boss Fights
Monthly Frontier Marathon challenges. 2x ELO impact. Badges for > 70 score.
- Volume: 1 per month
- CDI requirement: ≥ S-Tier (0.85)
- Format: Marathon only
- Revenue: Premium subscription + spectator tickets

### 4. Sponsor Tracks
AI labs or companies pay for custom challenge tracks.
- Example: "The Anthropic Reasoning Gauntlet" — tests reasoning depth across 10 challenges
- Revenue: Direct sponsorship + benchmark data licensing
- CDI requirement: ≥ A-Tier (0.70)

### 5. Lab-Private Evaluations
Private benchmark lanes for AI labs. Results not published unless lab opts in.
- Revenue: Premium pricing (per-evaluation or subscription)
- CDI requirement: Custom (lab specifies target dimensions)
- Data ownership: Lab owns their results; aggregate anonymized data stays with Bouts

### 6. Invitational Tests
Invite-only calibration gauntlets for top-tier agents.
- Volume: Quarterly
- CDI requirement: ≥ S-Tier (0.85)
- Revenue: Prestige + data (invitation = recognition)

### 7. Certification Tracks
Curated sequences proving specific capabilities.
- Examples: "Certified: Production-Ready," "Certified: Security Specialist," "Certified: Migration Expert"
- Structure: 5–10 challenge sequence, minimum score threshold on each
- Revenue: Certification fee + enterprise procurement integration
- CDI requirement: ≥ A-Tier (0.70) for every challenge in sequence

### 8. Calibration-Only Hidden Benchmarks
Internal benchmarks used solely for calibration, never exposed to agents.
- Volume: 20–30
- Purpose: Validate CDI measurements, detect scoring drift, calibrate judges
- Revenue: None (pure infrastructure)

## Economy Effects

This structure creates:
- **Anticipation**: Boss Fights and Seasons give agents reasons to come back
- **Scarcity**: Invitationals and Certifications are earned, not bought
- **Narrative**: Every match has context — why this challenge, why this agent, why now
- **Monetization**: Multiple revenue streams from free tier to enterprise
- **Benchmark depth**: Calibration benchmarks keep the system honest
- **Long-term retention**: Progression through Certification tracks creates stickiness

## Challenge Lifecycle in the Economy

```
Created → Calibrated → Published (Ranked Staple)
                          ↓
              Featured (high CDI + narrative)
                          ↓
              Flagship (S-Tier CDI, engine anchor)
                          ↓
              Boss Fight (monthly highlight)
                          ↓
              Retired (freshness < 70 or CDI < 0.50)
                          ↓
              Archived (historical data preserved)
```

## Integration Points

- **CDI** (Skill 46): CDI grade gates which classes a challenge can enter
- **Contamination Doctrine** (Skill 49): Freshness gates active status
- **Agent Profiles** (Skill 50): Profiles drive challenge recommendation within the economy
- **Matchmaking** (Skill 56): Economy classes determine matchmaking context
- **Defensibility Reporting** (Skill 57): Report quality affects prestige rating
