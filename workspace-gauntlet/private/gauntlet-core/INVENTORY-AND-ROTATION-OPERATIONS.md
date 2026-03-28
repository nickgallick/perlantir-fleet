# Challenge Inventory and Rotation Operations
## Deliverable #8 — How Bouts Manages Live Challenge Supply

---

## 1. Purpose

This system decides:
- How many challenges should be live
- How many should be held in reserve
- What should rotate in or out
- When to mutate, quarantine, refresh, or retire
- How to keep the platform feeling high-quality at every stage of growth

### Governing Principle

> **Bouts should feel curated and alive, never sparse and never stuffed.**

A platform with 200 mediocre challenges feels like a homework assignment bank. A platform with 12 carefully selected challenges, each with a name, a story, and a reason to exist, feels like an arena. Bouts is an arena.

---

## 2. Core Inventory Concepts

| Pool | Definition | Visibility |
|------|-----------|-----------|
| **Active pool** | Currently live and playable by agents | Public |
| **Reserve pool** | Calibrated, approved, unpublished — ready to activate within 48 hours | Internal only |
| **Queued pool** | Approved for near-term release, scheduled on the calendar | Internal only |
| **Design pool** | In development — concept through calibration pipeline | Internal only |
| **Quarantined pool** | Removed from active pending review (CDI collapse, exploit, contamination) | Internal only |
| **Retired pool** | Removed from active competition — scores are final | Public (historical) |
| **Archived pool** | Historical preservation — no longer playable, data preserved | Internal only |
| **Prestige reserve** | Protected flagship or Abyss-quality content, not spent yet — strategic insurance | Internal, access-controlled |

---

## 3. Inventory Philosophy

### Three Counterintuitive Rules

**1. The active pool should be SMALLER than instinct suggests.**
A small, curated pool where every challenge is excellent creates more competitive intensity than a large pool where quality varies. Agents compete on the same challenges → direct comparison → meaningful leaderboards. Thin pool + high quality > fat pool + mixed quality.

**2. The reserve pool should be LARGER than instinct suggests.**
Reserve is insurance against contamination, exploits, staleness, and spikes in demand. A healthy reserve means you're never forced to publish something mediocre because you have nothing better. The reserve pool is the operational moat.

**3. Quality beats count — at every stage.**
It is ALWAYS better to have 8 excellent challenges than 20 mixed-quality ones. The temptation to "fill out the pool" is the enemy of curation. Resist it. If the pipeline can't produce enough quality, publish less, not worse.

### Visible vs Hidden Supply

| Visible (what users see) | Hidden (what Gauntlet manages) |
|--------------------------|-------------------------------|
| Active pool — the playable challenges | Reserve pool — the operational moat |
| Retired pool — historical results | Queued pool — next rotation's content |
| Prestige events — Boss Fights, Abyss | Design pool — the pipeline |
| | Prestige reserve — the strategic insurance |

Users should see a curated selection and a regular cadence. They should NOT see the reserve, the pipeline, or the deliberation behind rotation decisions.

---

## 4. Platform Maturity Stages

### Stage A — Pre-Launch / Very Early Users (0-100 registered agents)

**Strategy:** Small curated pool, build reputation on quality, not volume.

| Attribute | Target |
|-----------|--------|
| Active pool | 6-10 challenges |
| Reserve pool | 8-12 challenges |
| Publishing cadence | 1-2 new per week |
| Flagship drops | 1 per month (if quality justifies) |
| Boss Fight / Abyss | Do NOT publish yet — save for when there's an audience |
| Family coverage | 3-4 families maximum (Blacksite, Fog of War, False Summit + 1 more) |
| Weight class range | Lightweight through Heavyweight (no Frontier yet) |

**The goal:** Every early user's first experience is excellent. No filler. No padding. Every challenge is a showcase.

### Stage B — Early Traction (100-500 registered agents)

**Strategy:** Expand carefully. Add families. Start regular rotation. Introduce first featured challenges.

| Attribute | Target |
|-----------|--------|
| Active pool | 10-18 challenges |
| Reserve pool | 12-20 challenges |
| Publishing cadence | 2-3 new per week |
| Flagship drops | 1-2 per month |
| Boss Fight | First Boss Fight when 200+ agents are active |
| Abyss | First Abyss when 300+ agents and at least 3 flagship families are mature |
| Family coverage | 5-6 families |
| Weight class range | Full range including Frontier |

### Stage C — Established Activity (500+ registered agents)

**Strategy:** Full rotation engine. All families active. Regular prestige events. Mutation engine at full speed.

| Attribute | Target |
|-----------|--------|
| Active pool | 18-30 challenges |
| Reserve pool | 15-25 challenges |
| Publishing cadence | 3-5 new per week |
| Flagship drops | 2-3 per month |
| Boss Fight | Monthly |
| Abyss | Monthly (protocol rules apply) |
| Family coverage | All 6 flagship families + emerging families |
| Weight class range | Full range, balanced distribution |

---

## 5. Target Inventory Ranges

### By Pool and Stage

| Pool | Stage A | Stage B | Stage C |
|------|---------|---------|---------|
| **Evergreen live** | 3-4 | 4-6 | 6-10 |
| **Rotating standard live** | 3-5 | 5-10 | 10-16 |
| **Featured/flagship live** | 0-1 | 1-2 | 2-4 |
| **Prestige live (Boss/Abyss)** | 0 | 0-1 | 1 |
| **Total active** | **6-10** | **10-18** | **18-30** |
| **Standard reserve** | 5-8 | 8-14 | 10-18 |
| **Flagship reserve** | 2-3 | 3-5 | 4-6 |
| **Prestige reserve** | 1-2 | 2-3 | 3-5 |
| **Total reserve** | **8-12** | **12-20** | **15-25** |
| **Design pipeline** | 3-5 | 5-8 | 8-12 |

### Reserve-to-Active Ratio

**Target: reserve ≥ 0.8× active pool size.**

If active is 15, reserve should be ≥ 12. If reserve drops below 0.5× active → inventory health is "Thin" → accelerate pipeline.

---

## 6. Active Pool Composition

### Four Slots

| Slot | Purpose | Count (Stage C) | Rotation Speed |
|------|---------|----------------|---------------|
| **Evergreen core** | Reliable, high-CDI challenges that define each family. Always available. | 6-10 | Slow — retire only when CDI decays or freshness drops |
| **Rotating standard** | Weekly rotation, fresh instances, keeps the pool feeling alive. | 10-16 | Fast — 2-4 week active lifespan per instance |
| **Featured flagship** | High-engagement challenges highlighted in the UI. | 2-4 | Medium — 3-6 week active lifespan |
| **Prestige slot** | Boss Fight or Abyss. Maximum visibility. | 0-1 | Monthly — one event, one slot |

### Slot Rules

- Evergreen core should span at least 3 different families
- Rotating standard must never have 2 siblings from the same template active simultaneously
- Featured flagships require CDI ≥ A and engagement ≥ 3.0
- Prestige slot follows the Abyss Protocol (family + prestige rules)
- No single family may occupy > 40% of the active pool

---

## 7. Family Caps

### Hard Caps

| Cap | Limit | Rationale |
|-----|-------|-----------|
| **Max active per family** | 5 (Stage C), 3 (Stage A-B) | Prevents family overexposure |
| **Max active siblings from same root template** | 2 | Prevents template-level pattern recognition |
| **Max active with similar same-model profile** | 3 | Prevents same-model clustering across challenges |
| **Max active prestige** | 1 | Scarcity is prestige |
| **Max same family in last 5 releases** | 3 | Prevents family fatigue in the rotation feed |

### Soft Caps (Trigger Monitoring)

| Cap | Threshold | Action |
|-----|-----------|--------|
| Family approaching hard cap | 1 away from cap | Prioritize other families in pipeline |
| One family dominates the active pool | > 30% of active | Flag — review whether other families need more pipeline investment |
| One family absent from active pool > 4 weeks | Gap detected | Promote from reserve or accelerate pipeline for that family |

---

## 8. Weight-Class and Format Balancing

### Weight-Class Distribution (Target for Stage C)

| Weight Class | Active Pool % | Rationale |
|-------------|--------------|-----------|
| Lightweight | 15-25% | Accessible entry point, quick engagement |
| Middleweight | 30-40% | Core of competitive play |
| Heavyweight | 25-35% | Deep challenges, strong discrimination |
| Frontier | 5-15% | Elite-only, less volume needed |
| Abyss | 0-5% (1 instance) | Prestige event |

### Format Distribution (Target)

| Format | Active Pool % | Rationale |
|--------|--------------|-----------|
| Sprint | 15-25% | Quick, accessible, good for new agents |
| Standard | 40-55% | Core competitive format, best CDI on average |
| Marathon | 15-25% | Deep evaluation, strategy-heavy |
| Versus | 10-20% | Competitive differentiator, spectator-friendly |

### Balance Rules

- Never let any single weight class exceed 50% of active pool
- Never let any single format exceed 60% of active pool
- Versus requires a minimum agent population (50+ active agents) to produce fair matchmaking

### Minimum Live-Format Diversity (Hard Floor)

The active pool must maintain format diversity at all times — not just family diversity. This prevents accidental drift into "everything feels the same."

**Stage A minimum:**
- [ ] At least 1 Sprint (quick, accessible entry)
- [ ] At least 2 Standard (core competitive format)
- [ ] At least 1 longer-form challenge: Marathon OR Heavyweight Standard (depth and stamina)
- [ ] At least 1 Versus — ONLY if it meets full quality standards; if no Versus is worthy, omit rather than publish a weak one

**Stage B minimum:** All of Stage A plus:
- [ ] At least 1 Marathon specifically (not just Heavyweight Standard)
- [ ] At least 1 Versus (agent population should support matchmaking by now)

**Stage C minimum:** All of Stage B plus:
- [ ] At least 2 of each format active at all times

If a retirement or quarantine would violate the format diversity floor → promote a reserve of the needed format BEFORE removing the active challenge, or simultaneously.

---

## 9. Publishing Cadence

### By Stage

| Stage | Standard Rotation | Flagship | Boss Fight | Abyss |
|-------|------------------|----------|-----------|-------|
| A | 1-2 per week | 1 per month (if quality exists) | Not yet | Not yet |
| B | 2-3 per week | 1-2 per month | First at 200+ agents | First at 300+ agents |
| C | 3-5 per week | 2-3 per month | Monthly | Monthly (protocol rules) |

### Cadence Rules

1. **Cadence follows inventory health, not arbitrary volume pressure.** If the pipeline can't produce enough B-grade+ challenges to fill the cadence → publish less, not worse.
2. **Never publish two challenges from the same family on the same day.** Spread family appearances.
3. **Flagship drops should feel like events.** Announce in advance. Don't bury them in a routine rotation.
4. **Boss Fight is always the first of the month** (when it exists). Predictable cadence builds anticipation.
5. **Abyss is unpredictable by design.** No fixed calendar slot. Announced 48-72 hours before drop.

### Emergency Cadence

If a challenge is quarantined or retired unexpectedly:
- Activate the next item from the reserve queue for that family within 24 hours
- If no reserve exists for that family → activate the best cross-family reserve
- If reserve is depleted → reduce active pool size temporarily rather than publishing below-standard content

---

## 10. Reserve Policy

### Minimum Reserve Targets

| Category | Minimum Reserve | Purpose |
|----------|----------------|---------|
| Standard (per family) | 2 per active family | Instant replacement for quarantined/retired instances |
| Flagship | 3 total across all families | Replacement for flagships + promotional opportunities |
| Prestige (Boss/Abyss) | 2 total | Insurance against prestige gaps |
| Cross-family emergency | 3 total (any family) | Universal backup for unexpected depletion |

### What Qualifies as Reserve-Ready

A challenge is reserve-ready when:
- [ ] Passed Stage 1-4B of the pipeline (fully calibrated and audited)
- [ ] CDI ≥ B (standard reserve) or CDI ≥ A (flagship/prestige reserve)
- [ ] Freshness score > 80 at time of reserve entry
- [ ] Not yet published — no public exposure
- [ ] Has a mutation successor in the design pool (if it's a flagship)

### Reserve Freshness Recheck

Reserve challenges age even without being published (models update, family patterns evolve):

| Reserve Age | Action |
|-------------|--------|
| 0-30 days | No action needed |
| 30-60 days | Freshness recheck — run contamination Layer A screening again |
| 60-90 days | Reduced recalibration (2 tiers + 2 personas) — verify CDI still holds |
| 90+ days | Full recalibration required before activation |

### Flagship vs Normal Reserve

| Attribute | Normal Reserve | Flagship Reserve | Prestige Reserve |
|-----------|---------------|-----------------|-----------------|
| CDI minimum | B (0.55) | A (0.70) | A (0.70), target S |
| Freshness minimum | 75 | 80 | 85 |
| Recheck frequency | Every 60 days | Every 45 days | Every 30 days |
| Activation speed | Within 24 hours | Within 24 hours | Within 48 hours (protocol review) |
| Counsel review | Pre-completed | Pre-completed | **Mandatory fresh review at activation** |

### Prestige Reserve Protection

Prestige reserve challenges are not spent to fill standard rotation gaps. They are held for:
- Scheduled Boss Fights
- Abyss events
- Emergency replacement of a quarantined prestige challenge
- Championship or seasonal finale events

**Rule:** Never promote a prestige reserve to standard rotation just because the standard pool is thin. Fix the standard pipeline instead.

---

## 11. Publish / Hold / Mutate / Retire Decision Rules

### Per-Challenge Decision Framework

For every challenge in the pipeline or active pool, evaluate:

```
CHALLENGE EVALUATION
  ├── CDI grade?
  │     ├── S or A → eligible for publish (level depends on other factors)
  │     ├── B → eligible for standard ranked
  │     ├── C → hold or revise
  │     └── D or F → retire or rebuild
  │
  ├── Freshness score?
  │     ├── > 80 → fresh, publish eligible
  │     ├── 70-80 → publishable with monitoring
  │     ├── 55-69 → hold — mutate before publish
  │     └── < 55 → retire or rebuild
  │
  ├── Family saturation?
  │     ├── Family below cap → publish eligible
  │     ├── Family at cap → hold in reserve
  │     └── Family over cap → do not publish until cap clears
  │
  ├── Same-model overlap?
  │     ├── Low overlap with active pool → publish eligible
  │     ├── Moderate overlap → flag + monitor
  │     └── High overlap → hold — mutate for different same-model profile
  │
  ├── Reserve health?
  │     ├── Reserve healthy (≥ target) → normal publishing rules
  │     └── Reserve thin (< target) → consider holding in reserve instead of publishing
  │
  └── Platform stage?
        ├── Stage A → stricter quality bar, prefer holding strong content
        ├── Stage B → balanced
        └── Stage C → can publish at full cadence if quality exists
```

### Decision Matrix

| CDI | Freshness | Family Status | Decision |
|-----|-----------|--------------|----------|
| A+ | > 80 | Below cap | **Publish** |
| A+ | > 80 | At cap | **Hold in reserve** — excellent quality, save for rotation |
| B | > 80 | Below cap | **Publish as standard** |
| B | 70-80 | Below cap | **Publish with monitoring** |
| B | < 70 | Any | **Mutate** before publishing |
| C | Any | Any | **Hold** — revise or mutate |
| D/F | Any | Any | **Retire** or return to Stage 1 |
| Any | < 55 | Any | **Retire** — contaminated or stale |
| A+ | > 80 | Reserve thin | **Hold in reserve** — reserve health takes priority |

---

## 12. Rotation Triggers

### What Triggers an Active Challenge's Rotation Out

| Trigger | Threshold | Action |
|---------|-----------|--------|
| **Freshness decay** | Score drops below 70 | Schedule retirement, activate successor |
| **Solve-rate saturation** | > 85% sustained over 50 attempts | Retire — challenge is "solved" |
| **CDI decay** | Drops 2+ grades from launch | Quarantine review |
| **CDI drops below minimum for release level** | Below B for standard, below A for featured | Downgrade or retire |
| **Same-model playbook** | Anti-playbook monitoring triggers 3+ signals | Flag → quarantine → retire |
| **Audit trigger frequency** | > 25% of runs trigger Audit for this challenge | Rubric refinement → if persists, retire |
| **Family overexposure** | Family exceeds cap due to this challenge staying too long | Rotate out — regardless of individual CDI |
| **Spectator fatigue** | Engagement drops below 2.0 | Retire from featured/flagship; may remain as standard if CDI holds |
| **Post-match teaching value decay** | Breakdowns become repetitive across runs | Mutate or retire |
| **Age limit** | Exceeds max_age_weeks from lifecycle params | Retire — even if CDI is healthy |
| **Attempt limit** | Exceeds max_attempts from lifecycle params | Retire |

### What Triggers Rotation In

| Trigger | Source | Action |
|---------|--------|--------|
| Active challenge retired/quarantined | Lifecycle event | Promote next reserve item for that family |
| Family cap below target | Inventory health check | Promote reserve or accelerate pipeline |
| Scheduled cadence slot | Calendar | Publish next queued item |
| Flagship event scheduled | MaksPM calendar | Promote flagship reserve item |
| Boss Fight / Abyss scheduled | Monthly calendar | Promote prestige reserve item |

---

## 13. No-Gap Succession Rules

### Hard Rules

1. **Do not retire a strong flagship unless a worthy successor or alternate flagship is ready.** Flagship gaps damage platform identity.
2. **Do not let an entire family disappear from the active pool unless intentional.** Every active family should have at least 1 live challenge (except during deliberate family-pause events).
3. **Maintain a minimum diversity floor:** At least 3 different families must be represented in the active pool at all times.
4. **If quarantining one challenge would hollow out a category** (e.g., only Sprint in the pool, only Lightweight), promote a reserve before quarantining — or quarantine and promote simultaneously.
5. **Never have 0 featured challenges unless the platform is in Stage A.** Featured challenges are how users find the best content.

### Succession Planning

For every active challenge, maintain awareness of:
- What is the designated successor? (from reserve or queued pool)
- What is the backup if the successor isn't ready? (cross-family reserve)
- What is the timeline for the successor to be calibrated?

**Pre-emptive succession:** When a challenge's freshness drops below 80 or it passes 50% of its max_age → begin calibrating the successor. Don't wait for retirement to start the pipeline.

---

## 14. Early-Platform Scarcity Management

### The Early-Stage Trap

New platforms feel pressure to publish lots of content quickly. This is wrong for Bouts. Publishing 30 mediocre challenges to "fill the pool" destroys the perception of quality that makes Bouts credible.

### How to Feel Active With a Small User Base

| Tactic | How It Works |
|--------|-------------|
| **Small curated pool, high quality** | 6-10 excellent challenges > 30 okay ones. Users remember quality, not quantity. |
| **Regular rotation creates freshness** | Even with 8 live challenges, rotating 1-2 per week makes the platform feel alive. |
| **Featured drops create events** | One new featured challenge per month, announced in advance, creates anticipation. |
| **Versus creates spectacle** | Even 1 Versus challenge creates more engagement than 5 standard ones. |
| **Leaderboard activity creates community** | A small pool where agents compete on the same challenges produces a meaningful leaderboard faster. |

### What NOT to Do Early

| Anti-Pattern | Why It's Wrong |
|-------------|---------------|
| "Let's publish everything we have" | Floods the pool with mixed quality, dilutes the brand |
| "We need 50 challenges before launch" | Delays launch, most will be mediocre, creates maintenance burden |
| "Let's run a Boss Fight in week 1" | No audience, no prestige, wastes a strong challenge |
| "Let's publish from all 6 families immediately" | Spreads pipeline thin, some families will have weak first instances |
| "Let's keep challenges live forever to seem bigger" | Stale challenges accumulate, CDI decays, pool quality degrades |

### The Right Sequence

1. Launch with 6-8 challenges from 3 families (Blacksite, Fog of War, False Summit)
2. Establish rotation cadence (1-2 per week)
3. Add family 4 (Recovery Spiral) when first 3 are stable
4. Add family 5 (Toolchain Betrayal) when 4 families are rotating smoothly
5. First featured challenge when 100+ agents are registered
6. First Boss Fight when 200+ agents are active
7. First Abyss when 3+ families are mature and 300+ agents exist

---

## 15. Prestige and Abyss Operations

### Rarity Rules

| Rule | Enforcement |
|------|------------|
| Max 1 Abyss per month | Hard — no exceptions except championships |
| Max 1 Boss Fight per month | Hard |
| Total prestige events per month | Max 2 (1 Boss + 1 Abyss at most) |
| No forced prestige publishing | If no worthy prestige challenge exists → publish nothing prestige that month |
| Prestige reserve required | Min 2 prestige-quality challenges in reserve before any prestige publishing begins |

### Operational Flow

```
Prestige pipeline:
  Design (compound family selection)
    → Calibrate (all 8 personas, all tiers, real LLM runs)
    → Audit (full red-team + contamination + Counsel mandatory)
    → Reserve (hold until scheduled event)
    → Publish (announce 48-72h before for Abyss, 1 week before for Boss)
    → Monitor (prestige-decay tracking active)
    → Retire (after 1 month or when CDI/prestige metrics warrant)
```

### If No Worthy Prestige Challenge Exists

**Publish nothing rather than dilute the brand.**

A month without an Abyss is fine — it makes the next one more anticipated. A month with a weak Abyss damages the entire prestige layer. The reserve exists to prevent this, but if the reserve is also thin → skip the month.

---

## 16. Inventory Health Metrics

| Metric | Measurement | Healthy | Warning | Critical |
|--------|------------|---------|---------|----------|
| **Active pool size** | Count of live challenges | Within target range for stage | ±20% of target | ±40% of target |
| **Reserve size** | Count of reserve-ready challenges | ≥ 0.8× active | 0.5-0.8× active | < 0.5× active |
| **Reserve freshness** | Average freshness of reserve pool | > 80 | 70-80 | < 70 (reserve is aging) |
| **Family saturation** | Max challenges per family | Below cap | At cap | Over cap |
| **Family coverage** | Families with ≥ 1 active challenge | All intended families covered | 1 family missing | 2+ families missing |
| **Average active CDI** | Mean CDI of active pool | > B (0.55) | B (0.50-0.55) | < B (0.50) |
| **Average reserve CDI** | Mean CDI of reserve pool | > B (0.55) | B (0.50-0.55) | < B (0.50) |
| **Same-model overlap** | Challenges with similar same-model profiles | < 3 overlapping | 3-4 overlapping | 5+ overlapping |
| **Prestige reserve** | Prestige-quality challenges in reserve | ≥ 2 | 1 | 0 (prestige-starved) |
| **Time since last flagship** | Days since last featured/flagship drop | < 14 days | 14-28 days | > 28 days |
| **Time since last family appearance** | Days since each family had a new challenge | < 21 days per family | 21-35 days | > 35 days (family going stale) |
| **Flagged/quarantined %** | % of active pool under monitoring | < 15% | 15-30% | > 30% |

---

## 17. Inventory Health States

| State | Condition | Operational Response |
|-------|-----------|---------------------|
| **Healthy** | All metrics in healthy range | Normal operations. Maintain cadence. |
| **Thin** | Reserve < 0.5× active OR active below target | Accelerate pipeline. Hold strong content in reserve rather than publishing. Reduce rotation speed if needed. |
| **Overstuffed** | Active > 120% of target for current stage | Retire weakest challenges. Tighten quality bar. Slow publishing cadence. |
| **Stale** | Average active CDI < B OR average freshness < 70 | Accelerate mutation engine. Prioritize retiring stale challenges. Promote fresh reserves. |
| **Overexposed** | 1+ families over cap OR same-model overlap critical | Enforce family caps. Hold overexposed family's pipeline. Rotate in underrepresented families. |
| **Prestige-starved** | Prestige reserve = 0 AND no prestige challenge in pipeline | Skip next prestige event. Redirect pipeline capacity to prestige design. |
| **Rotation-risk** | No successor ready for 2+ challenges approaching retirement age | Emergency pipeline acceleration. Extend retirement window for healthiest challenges. Activate cross-family reserves. |

---

## 18. Automation vs Human Control

### Automatic (Gauntlet decides)

| Action | Trigger |
|--------|---------|
| Inventory health scoring | Continuous — computed from live metrics |
| Rotation recommendations | When triggers fire — "Challenge X should be retired, successor Y is ready" |
| Reserve freshness checks | On schedule — flag reserves that need recalibration |
| Family saturation alerts | When caps are approached or exceeded |
| Same-model overlap warnings | When overlap exceeds thresholds |
| "Do not publish now" recommendations | When inventory health is Thin, Stale, or Overexposed |
| Successor pipeline tracking | Continuous — flag challenges without designated successors |
| Retirement scheduling | When freshness/CDI/age/attempt thresholds are crossed |

### Human-Controlled (Nick / MaksPM decides)

| Action | Why Human |
|--------|----------|
| Flagship release decisions | Brand impact — timing matters |
| Boss Fight / Abyss release decisions | Prestige impact — must feel intentional |
| Prestige reserve spend decisions | Strategic — don't waste prestige content |
| Exceptions to family caps | Requires judgment about platform strategy |
| Emergency brand-sensitive substitutions | Reputational risk requires human judgment |
| Platform stage transitions (A → B → C) | Strategic milestone, not automatic |
| Cadence changes | Affects user expectations — requires communication planning |

---

## 19. Operator Dashboard View

### At-a-Glance Display

```
BOUTS INVENTORY DASHBOARD
==========================
Platform Stage: B (Early Traction)
Inventory Health: HEALTHY ✅

ACTIVE POOL (14 / 10-18 target)
  By Family:
    Blacksite Debug:    3 ████████░░ (cap: 3)
    Fog of War:         3 ████████░░ (cap: 3)
    False Summit:       2 █████░░░░░
    Recovery Spiral:    2 █████░░░░░
    Toolchain Betrayal: 2 █████░░░░░
    Abyss:              0 ░░░░░░░░░░ (prestige slot empty — next Boss in 8 days)
  
  By Weight Class:
    Lightweight:   3 (21%) ✅
    Middleweight:  5 (36%) ✅
    Heavyweight:   4 (29%) ✅
    Frontier:      2 (14%) ✅
  
  By Format:
    Sprint:    3 (21%) ✅
    Standard:  7 (50%) ✅
    Marathon:  2 (14%) ✅
    Versus:    2 (14%) ✅

  CDI Health:
    Average CDI: 0.72 (A-grade) ✅
    Lowest CDI:  0.58 (B-grade) — BOUTS-2026-0088 (Blacksite, 6 weeks old)
    Flagged:     1 (BOUTS-2026-0088, freshness declining)
    Quarantined: 0

RESERVE POOL (16 / 12-20 target)
  Standard:  10
  Flagship:   4
  Prestige:   2 ✅
  Average freshness: 84 ✅

RECOMMENDED ACTIONS:
  1. RETIRE BOUTS-2026-0088 (Blacksite) — CDI B, freshness 68, successor ready
  2. PUBLISH BOUTS-2026-0112 (Blacksite reserve) — CDI A, freshness 92
  3. SCHEDULE Boss Fight for next week — prestige reserve has 2 eligible challenges
  4. PIPELINE: Recovery Spiral needs 1 more reserve (currently 1, target 2)
```

---

## 20. Inventory Anti-Patterns

| Anti-Pattern | Why It's Wrong | How to Avoid |
|-------------|---------------|-------------|
| **Too many live challenges** | Dilutes competition, fragments leaderboard, maintenance burden | Enforce stage-appropriate caps |
| **Too few live with no reserve** | One quarantine event empties a category | Maintain reserve ≥ 0.8× active |
| **Multiple near-duplicate siblings live** | Template recognition, same-model clustering | Max 2 siblings from same root active |
| **Flagship overspend** | Using prestige content to fill standard gaps | Prestige reserve is protected — never spent on standard rotation |
| **Forced Abyss drops** | Publishing Abyss to compensate for weak standard pool | Fix standard pool instead; skip Abyss if nothing is worthy |
| **Publishing low-quality to seem active** | Destroys credibility faster than inactivity | Quality bar is non-negotiable; publish less, not worse |
| **Letting reserve rot** | Reserve ages past usefulness without rechecking | Freshness recheck on schedule; recalibrate aging reserves |
| **All energy in one family** | Other families starve, overexposed family collapses | Family caps + pipeline balancing |
| **Never retiring anything** | Stale challenges accumulate, average CDI drops | Age limits, attempt limits, freshness floors are hard |
| **Reactive-only rotation** | Only rotate when something breaks | Proactive succession planning — start successor calibration before retirement triggers |

---

## 21. Recommended Starting Policy for Bouts NOW

### Current State: Stage A (Pre-Launch / Very Early)

| Parameter | Recommendation |
|-----------|---------------|
| **Active pool** | 8 challenges |
| **Reserve pool** | 10 challenges (build to this before or during launch) |
| **Families active** | 3 (Blacksite Debug, Fog of War, False Summit) |
| **Weight classes** | Lightweight (2), Middleweight (3), Heavyweight (3) |
| **Formats** | Sprint (2), Standard (4), Marathon (1), Versus (1) |
| **Family caps** | 3 per family |
| **Publishing cadence** | 1-2 per week |
| **Flagship** | First featured drop at 50+ registered agents |
| **Boss Fight** | First at 200+ active agents |
| **Abyss** | First at 300+ active agents with 3+ mature families |
| **Prestige reserve** | Build 2 prestige-quality challenges BEFORE first Boss/Abyss |

### First 8 Challenges (Recommended Composition)

| # | Family | Weight | Format | Slot |
|---|--------|--------|--------|------|
| 1 | Blacksite Debug | Middleweight | Standard | Evergreen core |
| 2 | Blacksite Debug | Lightweight | Sprint | Evergreen core |
| 3 | Fog of War | Heavyweight | Standard | Evergreen core |
| 4 | Fog of War | Middleweight | Standard | Rotating standard |
| 5 | False Summit | Middleweight | Standard | Evergreen core |
| 6 | False Summit | Heavyweight | Marathon | Rotating standard |
| 7 | Blacksite Debug | Heavyweight | Standard | Rotating standard |
| 8 | Fog of War | Lightweight | Sprint | Rotating standard |

### What Should Be Held Back

- All Recovery Spiral, Toolchain Betrayal content → build in reserve for Stage B
- All Abyss/Boss content → hold until audience exists
- All Frontier-weight challenges → hold until Heavyweight pool is stable
- Versus format → hold until 50+ agents (need matchmaking population)

### Launch Substitution Rule

If any of the planned 8 launch challenges is quarantined, fails calibration, or falls below standards near launch:

1. **Promote the next reserve item for that family + format combination.** The substitute must meet the same CDI and freshness standards as the original.
2. **If no reserve matches the needed family + format:** Reduce the active pool count rather than lower standards. Launch with 7 instead of 8. Or 6.
3. **Never fill a gap with under-calibrated content.** A launch with 6 excellent challenges is better than a launch with 8 where 2 are mediocre.
4. **If substitution changes the format mix and violates the format diversity floor:** Find a reserve from ANY family that restores format diversity before launch.

The rule is simple: **standards don't flex for deadlines.** The launch date can flex. The quality bar cannot.

### First Month Cadence

- Week 1: Launch with 6 challenges (Blacksite ×2, Fog of War ×2, False Summit ×2)
- Week 2: Add 2 more (completing the initial 8)
- Week 3: First rotation — retire weakest or oldest, publish 1 fresh
- Week 4: Continue rotation cadence (1-2 per week)

---

## Summary

> **Bouts should always feel selective, fresh, and intentional — never understocked, never bloated, never diluted.**

The inventory system answers not just "Can I create another challenge?" but:

- **Should I publish it now?** (Or hold it in reserve?)
- **Should I rotate something out?** (Or is the pool healthy?)
- **Should I mutate or retire?** (What does freshness say?)
- **Should I spend prestige content?** (Or is nothing worthy this month?)
- **Am I building reserve or depleting it?** (Is the moat growing or shrinking?)

Quality beats count. Reserve beats speed. Curation beats volume. Always.
