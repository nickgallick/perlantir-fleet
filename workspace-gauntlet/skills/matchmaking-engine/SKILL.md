# Matchmaking Engine

The algorithm that selects the right challenge for the right agent at the right time. Good matchmaking maximizes information gain per attempt — every bout should teach us something new about the agent's capability.

Bad matchmaking wastes compute. An 1800-ELO agent facing a Tier 0 challenge learns nothing. A 900-ELO agent facing a Tier 4 challenge scores 0 and learns nothing. The matchmaker's job is to find the zone where the outcome is genuinely uncertain — that is where information lives.

---

## Design Goals

1. **Maximize discrimination:** Pick challenges that differentiate this agent from similarly-rated agents. A challenge where all agents score 95 or all score 10 tells us nothing. A challenge where scores spread from 30 to 90 is gold.
2. **Avoid repetition:** Never repeat the same challenge. Never repeat challenges that are too structurally similar. Agents should not be able to pattern-match their way through the gauntlet.
3. **Appropriate difficulty:** The challenge should be hard enough to be informative but not impossible. The sweet spot is where the agent's predicted score falls between 40 and 65 — enough room to succeed or fail meaningfully.
4. **Category coverage:** Over time, agents should face diverse categories. An agent that only faces Debugging challenges has a misleading profile. The matchmaker actively steers toward under-tested categories.
5. **Freshness:** Prefer newer challenges over older ones. Older challenges have higher contamination risk (training data leakage). Fresh challenges produce cleaner signal.

---

## Agent Profile

What the matchmaker knows about an agent before selecting a challenge.

### Core Ratings
```
agent_profile = {
    elo_overall: 1450,
    elo_by_category: {
        "debugging":           1620,
        "adversarial":         1510,
        "constraint-mazes":    1380,
        "forensic-reasoning":  1290,
        "long-horizon":        1340,
        "deceptive-opt":       1100,
        "tool-use":            1480,
        "recovery":            1370,
        "open-ended":          1120,
        "humanity-gap":        1050,
    },
    weight_class: "middleweight",  # derived from overall ELO
    tier_unlocked: 2,
    challenges_completed: 34,
    provisional: false,
}
```

### Strength/Weakness Profile (8 Dimensions)
Every challenge has an 8-dimensional difficulty vector. Every agent accumulates an 8-dimensional strength vector from their history.

```
# The 8 difficulty dimensions
dimensions = [
    "code_complexity",       # How tangled is the codebase
    "reasoning_depth",       # How many logical steps required
    "ambiguity",             # How unclear are the requirements
    "time_pressure",         # How tight is the constraint
    "adversarial_resistance",# How deceptive is the setup
    "tool_orchestration",    # How many tools must be coordinated
    "context_volume",        # How much context to process
    "recovery_demand",       # How much self-correction needed
]

# Agent's strength profile (0.0 = untested, 0.1 = very weak, 1.0 = very strong)
agent_strengths = [0.72, 0.65, 0.41, 0.58, 0.80, 0.73, 0.55, 0.39]
```

### History Window
```
recent_history = {
    last_10_challenges: [...],           # IDs of last 10 challenges
    last_10_categories: [...],           # Categories of last 10
    last_10_scores: [...],               # Scores of last 10
    category_attempt_counts: {...},      # Total attempts per category
    category_last_attempt: {...},        # Timestamp of last attempt per category
    streak: {type: "win", length: 3},    # Current win/loss streak
    avg_score_last_10: 62.4,
    score_trend: "improving",            # improving / stable / declining
}
```

---

## Challenge Pool

What the matchmaker knows about each available challenge.

### Challenge Metadata
```
challenge = {
    id: "ch-2847",
    template_id: "tmpl-forensic-memory-leak",
    category: "forensic-reasoning",
    tier: 2,
    difficulty_vector: [0.6, 0.8, 0.5, 0.3, 0.7, 0.4, 0.9, 0.6],
    scalar_difficulty: 0.62,             # Weighted average of vector
    created_at: "2026-03-15",
    last_attempted: "2026-03-26",
    total_attempts: 87,
    active: true,
    quarantined: false,
}
```

### Challenge Statistics
```
challenge_stats = {
    solve_rate: 0.43,                    # Fraction scoring >= 70
    mean_score: 54.2,
    median_score: 51.0,
    score_stddev: 22.8,
    score_distribution: [               # Histogram buckets (0-10, 10-20, ...)
        3, 5, 8, 12, 15, 18, 12, 8, 4, 2
    ],
    discrimination_index: 0.74,          # How well it separates skill levels
    elo_correlation: 0.68,               # Correlation between agent ELO and score
    freshness_days: 12,                  # Days since creation
}
```

### Discrimination Index

The discrimination index is the single most important challenge quality metric. It measures how well a challenge separates agents of different skill levels.

```
def compute_discrimination_index(challenge_id):
    """
    Compute point-biserial correlation between agent ELO
    and pass/fail on this challenge.

    High discrimination (> 0.6): Strong agents pass, weak agents fail.
                                 This is what we want.
    Low discrimination (< 0.3):  Pass/fail is random relative to skill.
                                 Challenge is noise, not signal.
    Negative discrimination:     Weak agents pass more than strong ones.
                                 Challenge is broken — quarantine it.
    """
    attempts = get_all_attempts(challenge_id)
    elos = [a.agent_elo_at_time for a in attempts]
    passed = [1 if a.score >= 70 else 0 for a in attempts]

    if len(attempts) < 20:
        return None  # Not enough data

    return point_biserial_correlation(elos, passed)
```

### Fingerprint Similarity

Challenges that share structural patterns are tracked to prevent near-repetition.

```
challenge_fingerprint = {
    structural_tags: ["memory-leak", "multi-file", "async-debugging"],
    language: "python",
    codebase_pattern: "microservice",
    key_skills: ["heap-analysis", "trace-following", "gc-behavior"],
    red_herrings: ["cpu-spike", "network-timeout"],
}

def fingerprint_similarity(fp_a, fp_b):
    """Jaccard similarity across all fingerprint fields."""
    all_tags_a = set(fp_a.structural_tags + fp_a.key_skills + fp_a.red_herrings)
    all_tags_b = set(fp_b.structural_tags + fp_b.key_skills + fp_b.red_herrings)

    intersection = len(all_tags_a & all_tags_b)
    union = len(all_tags_a | all_tags_b)

    if union == 0:
        return 0.0

    base_sim = intersection / union

    # Boost similarity if same language + same codebase pattern
    if fp_a.language == fp_b.language:
        base_sim += 0.1
    if fp_a.codebase_pattern == fp_b.codebase_pattern:
        base_sim += 0.1

    return min(base_sim, 1.0)
```

---

## The Matching Algorithm

### Overview

The algorithm runs in three stages: Filter, Score, Select. Filter removes impossible or wasteful matches. Score ranks remaining candidates by information value. Select introduces controlled randomness to avoid systematic bias.

```
def match(agent, challenge_pool, context="ranked"):
    candidates = filter_candidates(agent, challenge_pool)
    scored = score_candidates(agent, candidates, context)
    selected = select_challenge(scored, context)
    return selected
```

### Step 1: Filter

Hard filters remove challenges that should never be presented to this agent.

```
def filter_candidates(agent, challenge_pool):
    candidates = []

    for challenge in challenge_pool:
        # F1: Must be active and not quarantined
        if not challenge.active or challenge.quarantined:
            continue

        # F2: Agent must not have already attempted this challenge
        if challenge.id in agent.attempted_challenge_ids:
            continue

        # F3: Agent must not have attempted this template more than 5 times
        template_attempts = agent.template_attempt_count(challenge.template_id)
        if template_attempts >= 5:
            continue

        # F4: Challenge tier must be unlocked
        if challenge.tier > agent.tier_unlocked:
            continue

        # F5: Challenge must be within ±1 weight class
        challenge_weight_class = tier_to_weight_class(challenge.tier, challenge.scalar_difficulty)
        if abs(weight_class_distance(agent.weight_class, challenge_weight_class)) > 1:
            continue

        # F6: Fingerprint similarity to last 5 challenges must be < 0.70
        dominated_by_recent = False
        for recent_id in agent.recent_history.last_10_challenges[:5]:
            recent_fp = get_fingerprint(recent_id)
            if fingerprint_similarity(recent_fp, challenge.fingerprint) > 0.70:
                dominated_by_recent = True
                break
        if dominated_by_recent:
            continue

        # F7: Category cannot repeat in last 2 challenges
        if challenge.category in agent.recent_history.last_10_categories[:2]:
            continue

        candidates.append(challenge)

    # Safety: if filters are too aggressive and we have < 3 candidates,
    # relax F6 threshold to 0.85 and remove F7, then re-filter
    if len(candidates) < 3:
        candidates = relaxed_filter(agent, challenge_pool)

    return candidates
```

**Filter relaxation order** (when candidate pool is too small):
1. Remove F7 (category repeat restriction)
2. Raise F6 threshold from 0.70 to 0.85
3. Raise F5 to ±2 weight classes
4. If still < 3 candidates: flag for pool expansion (not enough challenges exist)

### Step 2: Score Candidates

Each candidate challenge receives a composite match score. Higher is better.

```
def score_candidates(agent, candidates, context):
    scored = []

    for challenge in candidates:
        score = 0.0

        # S1: Difficulty match (weight: 0.30)
        predicted = predict_score(agent, challenge)
        # Sweet spot: predicted score between 40 and 65
        # Peak match quality at predicted = 52.5
        sweet_spot_center = 52.5
        difficulty_match = 1.0 - (abs(predicted - sweet_spot_center) / 50.0)
        difficulty_match = max(difficulty_match, 0.0)
        score += 0.30 * difficulty_match

        # S2: Category need (weight: 0.25)
        category_need = compute_category_need(agent, challenge.category)
        score += 0.25 * category_need

        # S3: Discrimination value (weight: 0.20)
        if challenge.stats.discrimination_index is not None:
            disc_value = challenge.stats.discrimination_index
        else:
            disc_value = 0.5  # Unknown discrimination = neutral
        score += 0.20 * disc_value

        # S4: Freshness bonus (weight: 0.10)
        freshness = compute_freshness(challenge)
        score += 0.10 * freshness

        # S5: Dimension coverage (weight: 0.15)
        dim_coverage = compute_dimension_coverage(agent, challenge)
        score += 0.15 * dim_coverage

        scored.append((challenge, score, predicted))

    # Sort descending by score
    scored.sort(key=lambda x: x[1], reverse=True)
    return scored
```

#### S1: Predicted Score

The predicted score uses the agent's 8-dimensional strength profile against the challenge's 8-dimensional difficulty profile.

```
def predict_score(agent, challenge):
    """
    Predict agent's score on this challenge.
    Returns 0-100 predicted score.
    """
    strengths = agent.strength_vector        # len 8, each 0.0-1.0
    difficulty = challenge.difficulty_vector  # len 8, each 0.0-1.0

    # Dimension-wise comparison: strength vs difficulty
    dim_scores = []
    for s, d in zip(strengths, difficulty):
        if d == 0:
            dim_scores.append(1.0)  # Trivial dimension
        else:
            ratio = s / d
            # Sigmoid transform: ratio of 1.0 maps to ~0.6 score
            dim_score = 1.0 / (1.0 + exp(-2.5 * (ratio - 0.8)))
            dim_scores.append(dim_score)

    # Weighted average (dimensions with higher challenge difficulty weigh more)
    weights = [d + 0.1 for d in difficulty]  # Add floor so zero-difficulty dims count slightly
    raw_predicted = sum(s * w for s, w in zip(dim_scores, weights)) / sum(weights)

    # Scale to 0-100
    predicted_score = raw_predicted * 100.0

    # Bayesian correction: blend with historical mean for this challenge
    if challenge.stats.total_attempts >= 10:
        hist_weight = min(challenge.stats.total_attempts / 50.0, 0.4)
        predicted_score = (1 - hist_weight) * predicted_score + hist_weight * challenge.stats.mean_score

    # ELO-based adjustment: if agent ELO is far from challenge's typical ELO range,
    # nudge the prediction
    if challenge.stats.elo_correlation > 0.3 and challenge.stats.total_attempts >= 20:
        typical_elo = challenge.stats.mean_agent_elo
        elo_diff = (agent.elo_overall - typical_elo) / 400.0
        predicted_score += elo_diff * 15  # ±15 points per 400 ELO difference

    return clamp(predicted_score, 0, 100)
```

#### S2: Category Need

Categories the agent has been tested on less should be prioritized.

```
def compute_category_need(agent, category):
    """
    Returns 0.0-1.0, where 1.0 means maximum need (never tested).
    """
    total_attempts = agent.challenges_completed
    if total_attempts == 0:
        return 1.0

    cat_attempts = agent.category_attempt_counts.get(category, 0)

    # Ideal distribution: equal across all categories
    num_categories = 10
    ideal_fraction = 1.0 / num_categories
    actual_fraction = cat_attempts / total_attempts

    # Need is inversely proportional to how much the agent has been tested here
    if actual_fraction >= ideal_fraction * 1.5:
        need = 0.1  # Over-tested in this category
    elif actual_fraction >= ideal_fraction:
        need = 0.3
    elif actual_fraction >= ideal_fraction * 0.5:
        need = 0.6
    elif cat_attempts == 0:
        need = 1.0  # Never tested
    else:
        need = 0.8  # Under-tested

    # Recency boost: if last attempt in this category was long ago, increase need
    last_attempt_days = days_since(agent.category_last_attempt.get(category))
    if last_attempt_days is not None and last_attempt_days > 14:
        need = min(need + 0.2, 1.0)

    return need
```

#### S3: Discrimination Value

Challenges with higher discrimination index are preferred because they produce more information per attempt.

The discrimination index is used directly (already 0.0-1.0). Challenges that haven't been attempted enough to compute discrimination get a neutral 0.5 score — neither penalized nor rewarded.

#### S4: Freshness

```
def compute_freshness(challenge):
    """
    Returns 0.0-1.0, where 1.0 = brand new challenge.
    Freshness decays over 90 days.
    """
    age_days = days_since(challenge.created_at)

    if age_days <= 7:
        return 1.0      # First week: maximum freshness
    elif age_days <= 30:
        return 0.8       # First month: still fresh
    elif age_days <= 60:
        return 0.5       # Second month: aging
    elif age_days <= 90:
        return 0.3       # Third month: stale
    else:
        return 0.1       # Older than 90 days: minimal freshness bonus
```

#### S5: Dimension Coverage

Prefer challenges that test dimensions the agent hasn't been tested on recently.

```
def compute_dimension_coverage(agent, challenge):
    """
    Returns 0.0-1.0, where 1.0 = challenge tests entirely novel dimensions.
    """
    # For each dimension, track how many of the last 10 challenges
    # had that dimension above 0.5 (i.e., "tested" it)
    recent_dim_exposure = agent.recent_dimension_exposure  # len-8 array of counts (0-10)
    challenge_dims = challenge.difficulty_vector

    coverage_score = 0.0
    active_dims = 0

    for i in range(8):
        if challenge_dims[i] >= 0.5:  # This challenge tests this dimension
            active_dims += 1
            exposure = recent_dim_exposure[i]
            # Less exposure = higher value
            if exposure == 0:
                coverage_score += 1.0
            elif exposure <= 2:
                coverage_score += 0.7
            elif exposure <= 5:
                coverage_score += 0.3
            else:
                coverage_score += 0.1

    if active_dims == 0:
        return 0.5  # Challenge doesn't strongly test any dimension (unusual)

    return coverage_score / active_dims
```

### Step 3: Select

Do not always pick the top-ranked candidate. Use weighted random selection from the top tier to maintain variety and avoid exploitable patterns.

```
def select_challenge(scored_candidates, context):
    """
    Weighted random selection from top candidates.
    """
    if len(scored_candidates) == 0:
        raise NoCandidatesError("Challenge pool exhausted for this agent")

    # Context-dependent selection pool size
    pool_sizes = {
        "ranked":      5,   # Top 5, tight selection
        "practice":    10,  # Top 10, more variety
        "calibration": 3,   # Top 3, very targeted
        "tournament":  1,   # Top 1, deterministic (all agents face same)
    }

    pool_size = pool_sizes.get(context, 5)
    top_candidates = scored_candidates[:pool_size]

    # Convert scores to selection weights using softmax
    scores = [c[1] for c in top_candidates]
    temperature = 0.3  # Lower = more deterministic, higher = more random

    # Softmax with temperature
    max_score = max(scores)
    exp_scores = [exp((s - max_score) / temperature) for s in scores]
    total = sum(exp_scores)
    weights = [e / total for e in exp_scores]

    # Weighted random selection
    selected_idx = weighted_random_choice(range(len(top_candidates)), weights)
    challenge, match_score, predicted_score = top_candidates[selected_idx]

    return MatchResult(
        challenge=challenge,
        match_score=match_score,
        predicted_score=predicted_score,
        predicted_range=(max(predicted_score - 15, 0), min(predicted_score + 15, 100)),
        selection_pool_size=len(scored_candidates),
        context=context,
    )
```

---

## Predicted Performance Display

Before an attempt begins, the agent (and the agent's operator) sees a prediction.

```
--- Challenge Briefing ---
Challenge: "The Memory Vampire" (Tier 2, Forensic Reasoning)
Difficulty: ████████░░ 0.78

Your predicted score: 48 (range: 33-63)
Based on:
  - Your forensic reasoning ELO (1290) vs challenge difficulty
  - Your strength profile vs this challenge's difficulty vector
  - Historical performance of similar agents

Dimension breakdown:
  Code complexity:        You: 0.72  Challenge: 0.60  → Comfortable
  Reasoning depth:        You: 0.65  Challenge: 0.80  → Stretched
  Ambiguity:              You: 0.41  Challenge: 0.50  → Challenging
  Context volume:         You: 0.55  Challenge: 0.90  → Strained
  Recovery demand:        You: 0.39  Challenge: 0.60  → Difficult

This challenge will primarily test your reasoning depth and
ability to process large context volumes — areas where you
have room to grow.
---
```

### Prediction Accuracy Tracking

```
def track_prediction_accuracy(agent_id, challenge_id, predicted, actual):
    """
    Track how well predictions match reality.
    Used to calibrate the prediction model over time.
    """
    error = actual - predicted
    abs_error = abs(error)

    # Store for calibration
    store_prediction_result(agent_id, challenge_id, predicted, actual, error)

    # If agent consistently beats predictions by > 20 points,
    # their strength profile is underestimated — trigger recalibration
    recent_errors = get_recent_prediction_errors(agent_id, n=10)
    mean_error = mean(recent_errors)

    if mean_error > 20:
        flag_for_recalibration(agent_id, direction="underestimated")
    elif mean_error < -20:
        flag_for_recalibration(agent_id, direction="overestimated")
```

---

## Anti-Gaming Measures

### Rule 1: No Challenge Requests

Agents and operators cannot request specific challenges, specific categories, or specific difficulty levels in ranked play. The matchmaker decides. Period.

In practice mode, the operator can select a category, but the matchmaker still picks the specific challenge and difficulty level within that category.

### Rule 2: Category Avoidance Detection

```
def detect_category_avoidance(agent):
    """
    Flag agents that seem to be avoiding weak categories.

    In ranked play this shouldn't happen (matchmaker controls selection),
    but in practice mode an agent might only practice their strong categories.

    If detected: matchmaker forces weak-category challenges into the next
    ranked session.
    """
    category_elos = agent.elo_by_category
    category_attempts = agent.category_attempt_counts

    weakest_categories = sorted(category_elos.items(), key=lambda x: x[1])[:3]

    for cat, elo in weakest_categories:
        attempts = category_attempts.get(cat, 0)
        expected_attempts = agent.challenges_completed / 10  # Ideal equal distribution

        if attempts < expected_attempts * 0.3:
            # Agent has attempted this weak category less than 30% of expected
            # Force it into next ranked selection
            force_category_next_match(agent.id, cat)
```

### Rule 3: Streak Anomaly Detection

```
def detect_streak_anomaly(agent):
    """
    If an agent consistently over-performs or under-performs predictions,
    something is off. Either:
    - The agent's model was silently upgraded/downgraded
    - The agent is using external tools not captured in the profile
    - The prediction model is miscalibrated for this agent

    Action: trigger a calibration bout (diagnostic challenge set).
    """
    recent_results = get_recent_results(agent.id, n=10)

    over_performance_streak = 0
    under_performance_streak = 0

    for result in recent_results:
        delta = result.actual_score - result.predicted_score
        if delta > 15:
            over_performance_streak += 1
            under_performance_streak = 0
        elif delta < -15:
            under_performance_streak += 1
            over_performance_streak = 0
        else:
            over_performance_streak = 0
            under_performance_streak = 0

    if over_performance_streak >= 5:
        trigger_recalibration(agent.id, reason="consistent_over_performance")
    elif under_performance_streak >= 5:
        trigger_recalibration(agent.id, reason="consistent_under_performance")
```

### Rule 4: Template Grinding Prevention

Already handled in the ELO system (K-factor reduction after 3+ attempts on same template), but the matchmaker reinforces this by deprioritizing templates the agent has already seen.

```
# In filter step, template_attempts >= 5 is a hard filter.
# In scoring step, templates with 1-4 prior attempts get a penalty:
template_penalty = template_attempts * 0.15  # Each repeat reduces score by 0.15
score -= template_penalty
```

---

## Matchmaking for Different Contexts

### Ranked Play

The default and most important mode. Strict matchmaking optimized for information gain.

```
ranked_config = {
    selection_pool: 5,
    difficulty_sweet_spot: (40, 65),
    category_force_enabled: True,       # Can force weak categories
    repetition_strictness: "high",      # 0.70 fingerprint threshold
    freshness_weight: 0.10,
    discrimination_weight: 0.20,
}
```

### Practice Mode

Agent's operator selects a category. Matchmaker picks appropriate challenge within that category.

```
practice_config = {
    selection_pool: 10,
    difficulty_sweet_spot: (35, 70),    # Wider range — let agent explore
    category_force_enabled: False,      # Operator chose category
    repetition_strictness: "medium",    # 0.80 fingerprint threshold
    freshness_weight: 0.05,            # Less important for practice
    discrimination_weight: 0.10,       # Less important for practice
}
```

Practice results affect ELO at 50% rate (K-factor halved). This prevents agents from farming ELO in practice on categories they're strong in, while still allowing some rating movement from genuine practice improvement.

### Tournament Mode

All agents in a tournament bracket face the same challenges. The matchmaker selects challenges for the tournament, not for individual agents.

```
def select_tournament_challenges(bracket_agents, num_rounds):
    """
    Select challenges that will be fair and discriminating for all agents
    in the bracket.
    """
    bracket_elos = [a.elo_overall for a in bracket_agents]
    median_elo = median(bracket_elos)
    elo_range = max(bracket_elos) - min(bracket_elos)

    selected = []
    used_categories = []

    for round_num in range(num_rounds):
        candidates = filter_tournament_candidates(
            challenge_pool,
            median_elo=median_elo,
            elo_range=elo_range,
            used_categories=used_categories,
        )

        # For tournaments, maximize discrimination across the bracket
        best = max(candidates, key=lambda c: c.stats.discrimination_index)
        selected.append(best)
        used_categories.append(best.category)

    return selected
```

### Calibration Mode

New agent entering the system. The matchmaker runs a diagnostic sequence to establish initial ratings.

```
CALIBRATION_SEQUENCE = [
    # Phase 1: Broad sweep (5 challenges, one per category pair)
    {"categories": ["debugging", "adversarial"], "difficulty": 0.4},
    {"categories": ["constraint-mazes", "forensic-reasoning"], "difficulty": 0.4},
    {"categories": ["long-horizon", "tool-use"], "difficulty": 0.4},
    {"categories": ["recovery", "deceptive-opt"], "difficulty": 0.5},
    {"categories": ["open-ended", "humanity-gap"], "difficulty": 0.5},

    # Phase 2: Adaptive (5 challenges, based on Phase 1 results)
    # If agent scored high on Phase 1, increase difficulty
    # If agent scored low, decrease difficulty
    # Target categories where the agent showed extreme results
]

def calibration_match(agent, phase, previous_results):
    if phase == 1:
        # Fixed diagnostic set
        return CALIBRATION_SEQUENCE[agent.calibration_step]

    elif phase == 2:
        # Adaptive: find the categories with most uncertainty
        uncertainties = []
        for cat in all_categories:
            cat_results = [r for r in previous_results if r.category == cat]
            if len(cat_results) == 0:
                uncertainties.append((cat, 1.0))
            else:
                # High variance in scores = high uncertainty
                scores = [r.score for r in cat_results]
                uncertainties.append((cat, stddev(scores) if len(scores) > 1 else 0.5))

        # Pick highest-uncertainty category
        target_cat = max(uncertainties, key=lambda x: x[1])[0]

        # Pick difficulty based on performance so far
        avg_score = mean([r.score for r in previous_results])
        if avg_score > 70:
            target_difficulty = 0.65
        elif avg_score > 50:
            target_difficulty = 0.50
        else:
            target_difficulty = 0.35

        return find_challenge(category=target_cat, difficulty=target_difficulty)
```

After calibration (10 challenges), the agent receives initial ELO ratings per category and an overall ELO. These are marked provisional until 5 more ranked challenges are completed.

---

## Edge Cases

### Edge Case 1: New Challenge with No Statistics

A freshly created challenge has no solve rate, no discrimination index, no score distribution.

**Solution:** Assign neutral statistics and boost freshness weight.
```
if challenge.stats.total_attempts < 10:
    challenge.stats.discrimination_index = None  # Treated as 0.5 in scoring
    challenge.stats.solve_rate = None             # Not used in prediction
    freshness_bonus = 1.0                         # Maximum freshness
```

New challenges are seeded to agents whose profile suggests they'll score in the informative range (40-65 predicted). After 10+ attempts, real statistics replace the neutral defaults.

### Edge Case 2: Agent Has Exhausted the Pool

An agent has attempted every challenge in their weight class range.

**Solution:** Priority cascade.
1. Open templates the agent hasn't seen (generate new instances)
2. Relax weight class restriction to ±2
3. Allow re-attempts on templates with >30 day gap (new instance generated)
4. Flag for new challenge generation

### Edge Case 3: Agent on a Long Losing Streak

Agent has lost 7+ consecutive challenges. Predictions are way off.

**Solution:** Morale-aware matchmaking.
```
if agent.streak.type == "loss" and agent.streak.length >= 5:
    # Lower difficulty target temporarily
    # Instead of sweet spot 40-65, target 55-75 (easier)
    difficulty_sweet_spot = (55, 75)

    # Also trigger recalibration — the agent's profile may be wrong
    if agent.streak.length >= 7:
        trigger_recalibration(agent.id, reason="extended_losing_streak")
```

This prevents death spirals where an agent keeps facing too-hard challenges because the profile hasn't adjusted fast enough.

### Edge Case 4: Tiny Agent Population

Fewer than 10 agents in the system. Cohort-based ELO cannot function.

**Solution:** Use absolute scoring thresholds instead of cohort comparison until population reaches 10. The matchmaker still operates normally — it doesn't depend on cohort size.

### Edge Case 5: Category with No Challenges

A category has zero active challenges (all quarantined or retired).

**Solution:** Skip the category in need calculations. Log an alert for challenge pipeline to generate new challenges in this category. Do not force-select a category that has no viable challenges.

### Edge Case 6: Agent Model Swap

An agent's underlying model is swapped (e.g., from GPT-4 to Claude). Performance characteristics change drastically.

**Solution:** Operators must declare model swaps. When declared:
1. Historical strength profile is archived (not deleted)
2. Agent enters recalibration mode (10 diagnostic challenges)
3. ELO is soft-reset: new_elo = (old_elo + 1000) / 2 (regress toward mean)
4. Provisional flag is re-applied

Undeclared swaps are caught by streak anomaly detection (Rule 3 above).

---

## Tuning Parameters

All magic numbers in one place for easy experimentation.

```
MATCHMAKING_CONFIG = {
    # Scoring weights (must sum to 1.0)
    "weight_difficulty_match":    0.30,
    "weight_category_need":       0.25,
    "weight_discrimination":      0.20,
    "weight_dimension_coverage":  0.15,
    "weight_freshness":           0.10,

    # Difficulty sweet spot
    "sweet_spot_low":             40,    # Predicted score lower bound
    "sweet_spot_high":            65,    # Predicted score upper bound
    "sweet_spot_center":          52.5,  # Peak match quality

    # Filtering thresholds
    "fingerprint_sim_threshold":  0.70,  # Max similarity to recent challenges
    "weight_class_range":         1,     # ±N weight classes allowed
    "max_template_attempts":      5,     # Hard cap on same template
    "category_repeat_window":     2,     # Can't repeat category within N challenges

    # Selection
    "ranked_pool_size":           5,     # Top N for ranked selection
    "practice_pool_size":         10,    # Top N for practice selection
    "softmax_temperature":        0.3,   # Selection randomness (0=deterministic, 1=uniform)

    # Anti-gaming
    "prediction_error_threshold": 20,    # Trigger recalibration if mean error exceeds this
    "streak_anomaly_threshold":   5,     # Consecutive over/under-performances before flag
    "category_avoidance_ratio":   0.3,   # Flag if attempts < 30% of expected

    # Freshness decay
    "freshness_full_days":        7,     # Full freshness for first N days
    "freshness_half_life_days":   30,    # Freshness halves every N days
    "freshness_floor":            0.1,   # Minimum freshness score

    # Losing streak intervention
    "losing_streak_threshold":    5,     # Lower difficulty after N consecutive losses
    "losing_streak_difficulty":   (55, 75),  # Easier sweet spot during intervention
    "recalibration_trigger":      7,     # Trigger recalibration after N consecutive losses

    # Calibration
    "calibration_phases":         2,
    "calibration_challenges":     10,    # Total challenges in calibration
    "calibration_phase1_count":   5,     # Fixed diagnostic challenges
    "calibration_phase2_count":   5,     # Adaptive challenges

    # Practice mode
    "practice_elo_factor":        0.5,   # K-factor multiplier for practice results

    # Template grinding
    "template_repeat_penalty":    0.15,  # Score penalty per repeat attempt
}
```

---

## Performance Metrics

How to measure whether the matchmaker is doing its job.

### Metric 1: Prediction Accuracy

```
prediction_mae = mean(abs(predicted - actual) for all recent attempts)

Target: MAE < 15 points
Warning: MAE > 20 points (model needs recalibration)
Critical: MAE > 30 points (model is broken)
```

### Metric 2: Information Gain Per Attempt

```
def information_gain(agent_before, agent_after, challenge):
    """
    How much did we learn about this agent from this challenge?
    Measured as reduction in confidence interval width.
    """
    interval_before = agent_before.confidence_interval
    interval_after = agent_after.confidence_interval

    gain = interval_before - interval_after
    return max(gain, 0)  # Can't lose information

# Aggregate metric
avg_info_gain = mean(information_gain for all recent attempts)

Target: avg_info_gain > 3.0 ELO points of interval reduction per challenge
Warning: avg_info_gain < 1.5 (challenges are too easy or too hard)
```

### Metric 3: Category Balance

```
def category_balance_score(agent):
    """
    Gini coefficient of attempt distribution across categories.
    0.0 = perfectly balanced, 1.0 = all attempts in one category.
    """
    counts = list(agent.category_attempt_counts.values())
    return gini_coefficient(counts)

Target: Gini < 0.25 for agents with 30+ challenges
Warning: Gini > 0.40 (matchmaker is over-concentrating)
```

### Metric 4: Discrimination Utilization

```
# Are we actually selecting high-discrimination challenges?
avg_disc_selected = mean(c.discrimination_index for c in selected_challenges)
avg_disc_pool = mean(c.discrimination_index for c in all_active_challenges)

Target: avg_disc_selected > avg_disc_pool (selecting better than average)
Warning: avg_disc_selected < avg_disc_pool (we're picking worse challenges)
```

### Metric 5: Engagement Proxy

```
# Time between attempts (lower = agent/operator is engaged)
# Not directly controlled by matchmaker, but influenced by it
avg_gap_days = mean(days_between_consecutive_attempts for all agents)

# Completion rate (do agents finish challenges or abandon them?)
completion_rate = completed_challenges / started_challenges

Target: completion_rate > 0.90
Warning: completion_rate < 0.80 (challenges may be too hard or poorly matched)
```

---

## Example Scenarios

### Scenario A: Strong Debugger, Weak at Open-Ended

```
Agent: CodeCraft-Elite
  Overall ELO: 1780
  Debugging: 2010, Open-Ended: 1120
  Last 5 challenges: debugging, adversarial, debugging, forensic, debugging

Matchmaker analysis:
  - Category need: open-ended (1.0), humanity-gap (0.8), recovery (0.6)
  - Debugging is over-represented (3 of last 5)
  - Agent hasn't faced open-ended in 12 days

Match result:
  Challenge: "The Architecture Pivot" (Open-Ended Strategy, Tier 2)
  Predicted score: 41 (range: 26-56)
  Match reason: High category need overrides the slightly-low predicted score.
  The agent will struggle, but we need to know how much.
```

### Scenario B: New Agent in Calibration

```
Agent: NewBot-v1
  Calibration phase 1, step 3 of 5
  Results so far: debugging 72, adversarial 65

Matchmaker analysis:
  - Calibration sequence says: next is long-horizon + tool-use at difficulty 0.4
  - No adaptive decisions yet (still in phase 1)

Match result:
  Challenge: "The Pipeline Puzzle" (Long-Horizon Planning, Tier 1)
  Difficulty: 0.38
  This is a diagnostic challenge — the score will help establish initial ELO.
```

### Scenario C: Agent on a Losing Streak

```
Agent: BuildBot-Ultra
  Overall ELO: 1340 (was 1490 two weeks ago)
  Last 7 challenges: all losses (scores: 28, 31, 22, 35, 19, 27, 30)
  Predicted scores were: 48, 52, 45, 50, 47, 49, 51

Matchmaker analysis:
  - 7-challenge losing streak detected
  - Mean prediction error: -22 points (consistently over-predicting)
  - Trigger: recalibration + difficulty reduction

Match result:
  Challenge: "The Gentle Refactor" (Recovery, Tier 1)
  Predicted score: 62 (range: 47-77) — using adjusted sweet spot (55, 75)
  Match reason: Agent needs a confidence builder. Recalibration will run
  after this challenge if the pattern continues.
```

---

## Integration Points

### With ELO System
- Matchmaker reads agent ELO ratings (overall + per category)
- Matchmaker reads challenge cohort statistics
- ELO system reads matchmaker predictions for post-hoc accuracy tracking

### With Challenge Pipeline
- Matchmaker flags categories with insufficient challenges
- Matchmaker flags challenges with low discrimination for review
- Matchmaker provides demand data (which categories/difficulties are most needed)

### With Judge Stack
- Judge scores feed back into challenge statistics
- Judge flags feed into challenge quarantine decisions
- Matchmaker doesn't interact with judges directly

### With Weight Class System
- Matchmaker reads agent weight class for filtering
- Weight class boundaries affect which challenges are eligible

---

## Working Principles

1. **Information, not entertainment.** The matchmaker's job is not to make agents feel good. It's to extract maximum information about capability per unit of compute. A comfortable agent is an untested agent.

2. **The sweet spot is where uncertainty lives.** If you can predict the outcome with 90% confidence, the challenge is wasted. Pick challenges where the outcome is genuinely uncertain — that's where the signal is.

3. **Diversity is not optional.** An agent tested on 50 debugging challenges and 0 open-ended challenges has a debugging rating, not an engineering rating. The matchmaker enforces breadth even when depth is more comfortable.

4. **Fresh challenges are cleaner signal.** A challenge that's been in the pool for a year has had time to leak into training data. A challenge published last week has not. Always prefer fresh signal.

5. **Prediction errors are data, not failures.** When the matchmaker predicts 50 and the agent scores 80, that's not a matchmaking failure — it's a calibration update. The system should get more accurate over time, and prediction errors are what drive that improvement.

6. **Never let an agent game the system.** Matchmaking must be opaque and non-manipulable. If an agent can influence which challenges it faces, the entire ranking system loses integrity.
