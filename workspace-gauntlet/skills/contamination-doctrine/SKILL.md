# Contamination Doctrine — Skill 49

## Purpose
Treat contamination as a first-order benchmark risk. The moment the arena rewards memorization, the entire prestige layer collapses.

## The Gauntlet Contamination Doctrine

> No challenge in the Bouts active pool shall be solvable by memorization. Every challenge must require genuine reasoning.

## Hard Rules

1. No direct cloning of public benchmark tasks
2. No direct import of public repo tasks as ranked challenge cores
3. No active challenge with easily discoverable answer-path in public sources
4. No "famous bug recreation" without deep mutation
5. No benchmark instance reused once sufficiently exposed

## Ranked Challenge Standard

All ranked instances must be:
- ✅ Generated fresh
- ✅ Lineage-tracked
- ✅ Contamination-screened
- ✅ Answer-path screened
- ✅ Mutation-derived from private internal generators

## Contamination Risk Sources

| Source | Risk Level | Example |
|--------|-----------|---------|
| Public benchmark overlap | 🔴 Critical | SWE-bench, HumanEval, LeetCode tasks |
| Public repo overlap | 🔴 Critical | GitHub issues, Stack Overflow patterns |
| Leaked challenge pools | 🟠 High | Previous Bouts instances shared publicly |
| Repetitive instance templates | 🟡 Medium | Too many similar instances from same engine |
| Search-engine-answerable patterns | 🟠 High | Bug patterns with known fixes |
| Community memorization | 🟡 Medium | High replay volume on same template |

## Eight Contamination Defense Layers

| Layer | Defense | Implementation |
|-------|---------|----------------|
| 1 | **Template mutation** | Skill 52 — 7 mutation types per instance |
| 2 | **Lineage tracking** | `challenge_lineage` entity — full mutation chain |
| 3 | **Public similarity scan** | Google/GitHub search for key phrases from briefing + codebase |
| 4 | **Replay volume thresholds** | Auto-retire after N attempts on same instance |
| 5 | **Auto-retirement on age** | Maximum active lifespan per challenge tier |
| 6 | **Freshness scoring** | Continuous 0–100 score, quarantine below 70 |
| 7 | **Hidden invariant rotation** | Change what adversarial tests check per instance |
| 8 | **Private asset synthesis** | All codebases generated, never borrowed whole |

## Contamination Screening Process

### Pre-Publication Screening (mandatory)

1. **Google search**: Key phrases from briefing → exact matches = contaminated
2. **GitHub search**: Code patterns from codebase → similar repos = contaminated
3. **Frontier model probe**: Submit briefing to frontier model: "Have you seen this before?" → specific confident answer = contaminated
4. **Naive agent test**: Run naive agent (no iteration) → scores > 60% on Tier 3 = suspicious (it "knew" the answer)

### Ongoing Monitoring

5. **Score trend analysis**: Newer models scoring systematically higher on same template = contamination signal
6. **Community monitoring**: Challenge discussion in public forums = exposure risk
7. **Cross-instance correlation**: Agents scoring identically across mutations = memorization signal

## Challenge Freshness Score (0–100)

| Factor | Weight | Measurement |
|--------|--------|-------------|
| Similarity to prior instances | 25% | Asset fingerprint comparison |
| Number of attempts | 25% | Total submissions on this instance |
| Public exposure risk | 20% | Search engine + forum presence |
| Hidden invariant reuse | 15% | How many other instances share the same hidden checks |
| Solution path predictability | 15% | How few distinct successful approaches exist |

### Freshness Thresholds

| Score | Status | Action |
|-------|--------|--------|
| 80–100 | 🟢 Fresh | Active, no action |
| 70–79 | 🟡 Aging | Monitor closely, schedule mutation |
| 50–69 | 🟠 Stale | Quarantine from ranked pool, apply mutation or retire |
| < 50 | 🔴 Contaminated | Retire immediately from all pools |

## Core Principle

> A challenge should age out before it becomes culturally solved.

## Integration Points

- **CDI** (Skill 46): Contamination directly degrades Repeat Stability and Tier Separation
- **Mutation Layer** (Skill 52): Primary defense mechanism for freshness
- **Canonical Engines** (Skill 51): Engines are stable; instances are disposable
- **Defensibility Reporting** (Skill 57): Contamination status is a key defensibility metric
