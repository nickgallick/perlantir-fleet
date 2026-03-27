# Fairness and Bias Detection

Ensuring challenges don't inadvertently favor specific models or approaches. If a challenge is biased, the leaderboard is biased, and Bouts loses credibility. Fairness isn't just ethical — it's existential. An AI evaluation platform that favors one model family is a marketing tool, not a benchmark.

---

## Model Bias Detection

### The Process

After 100+ attempts per challenge template, analyze score distributions by model family.

```python
def detect_model_bias(scores_by_model_family, threshold=10):
    """Flag challenges where one model family has a significant advantage."""

    family_means = {
        family: np.mean(scores)
        for family, scores in scores_by_model_family.items()
    }

    overall_mean = np.mean([s for scores in scores_by_model_family.values() for s in scores])

    flagged = []
    for family, mean in family_means.items():
        deviation = mean - overall_mean
        if abs(deviation) > threshold:
            flagged.append({
                'family': family,
                'mean': mean,
                'overall_mean': overall_mean,
                'deviation': deviation,
                'direction': 'advantage' if deviation > 0 else 'disadvantage'
            })

    return flagged
```

### Common causes of model bias

**1. API Pattern Memorization**

Some models have been trained on specific API documentation (Stripe, AWS, etc.) and can recall exact method signatures. Challenges that test memorization of a specific API advantage models trained on that API's docs.

**Detection:** If scores on "Stripe integration" challenges correlate with model training data cutoff dates, API memorization is likely.

**Fix:** Use fictional APIs with realistic patterns. Or use real APIs but test integration LOGIC, not memorization of method names.

**2. Documentation Memorization**

If a challenge includes a codebase that appears in public GitHub repos, models trained on that code have an unfair advantage.

**Detection:** Check if challenge repos or similar patterns exist in public code datasets.

**Fix:** Generate unique codebases for each challenge instance. Use unusual (but valid) patterns that don't appear in training data.

**3. Code Generation Style Matching**

Test suites that check for specific function names, specific variable naming conventions, or specific code organization inadvertently favor models that default to those patterns.

**Detection:** Analyze whether test suite expectations match the default output style of specific model families.

**Fix:** Test BEHAVIOR, not implementation style. Use interface-based testing (call the endpoint, check the response) instead of checking internal code structure.

**4. Prompt Sensitivity**

Some model families are more sensitive to prompt formatting. A challenge briefing written in a style that one model family handles better creates bias.

**Detection:** Score variance across model families on the same challenge with the same content but reformatted prompts.

**Fix:** Test challenge briefings with multiple prompt styles. Choose the format with lowest cross-model variance.

---

## Approach Bias Detection

### The Problem

Challenges can inadvertently reward one valid approach over equally valid alternatives.

### Common approach biases

**1. Function name expectations**

```python
# Bad: test expects specific function name
def test_solution():
    assert calculate_total(items) == 150.00

# Good: test checks behavior
def test_solution():
    response = client.post('/api/cart/total', json={'items': items})
    assert response.json()['total'] == 150.00
```

When tests expect specific function names, agents that guess the "expected" name score higher than agents with different but equally valid naming conventions.

**2. Code style scoring bias**

```yaml
# Bad: style-dependent scoring
code_quality:
  - "Uses functional programming patterns" → +5
  - "Uses pure functions" → +5

# Good: style-agnostic scoring
code_quality:
  - "No side effects in core logic" → +5  # Achievable in any paradigm
  - "Functions have single responsibility" → +5  # Paradigm-independent
```

**3. Framework bias**

A challenge in a Next.js codebase that tests whether the agent uses the App Router instead of Pages Router biases toward agents trained more recently (App Router is newer).

**Fix:** Either accept both approaches with equal scoring, or specify explicitly: "This project uses the App Router. Follow existing patterns."

**4. Output format bias**

```python
# Bad: expects exact string format
assert output == "Total: $150.00"

# Good: allows equivalent formats
assert parse_amount(output) == 150.00
```

### The equivalence test

For every scored element, ask: "Are there two valid approaches that would produce different scores?" If yes, either:
- Accept both approaches explicitly in the rubric
- Specify the required approach in the briefing (removing ambiguity)
- Test behavior instead of implementation

---

## Cultural and Knowledge Bias

### Geography bias

**Problem:** Challenges assume US-specific knowledge.

| Biased | Unbiased |
|--------|----------|
| Validate US Social Security Numbers | Validate government ID numbers (format provided) |
| Calculate US sales tax (varies by state) | Calculate tax (rate provided as input) |
| Parse US date format (MM/DD/YYYY) | Parse dates (format specified in config) |
| US phone number validation | Phone validation with E.164 specification |

**Fix:** Use internationally generic business domains. When locale-specific logic is needed, provide the specification explicitly rather than assuming knowledge.

### Language bias

**Problem:** String handling challenges that assume ASCII.

```python
# Biased: only works for ASCII
def capitalize(s):
    return s[0].upper() + s[1:]

# Unbiased: works for all Unicode
def capitalize(s):
    return s[0].upper() + s[1:] if s else s
    # But even this fails for some Unicode edge cases
```

**Fix:** Include Unicode test cases in EVERY string-handling challenge. Test with: accented characters (é, ü), CJK characters, emoji, RTL text, zero-width characters.

### Domain knowledge bias

**Problem:** Challenges assume knowledge of specific business domains.

**Fix:** Provide enough domain context that any competent engineer can solve it. Don't assume knowledge of healthcare (HIPAA), finance (SOX), or legal (GDPR) unless those requirements are explicitly stated in the briefing.

---

## Difficulty Consistency Across Variable Combinations

### The Problem

Template challenges use variable combinations to create unique instances:

```yaml
template: "Build a {framework} API with {database} for {domain}"
variables:
  framework: [Express, Fastify, Hono, Koa]
  database: [PostgreSQL, MongoDB, SQLite, MySQL]
  domain: [e-commerce, blog, task management, inventory]
```

Not all combinations are equally difficult:
- Express + PostgreSQL + e-commerce → very well-documented, many examples → easier
- Hono + SQLite + inventory → less common combination → harder

### Detection

```python
def detect_variable_bias(scores_by_combination, threshold=20):
    """Flag variable combinations with significantly different difficulty."""

    combo_means = {
        combo: np.mean(scores)
        for combo, scores in scores_by_combination.items()
    }

    overall_mean = np.mean(list(combo_means.values()))

    flagged = []
    for combo, mean in combo_means.items():
        if abs(mean - overall_mean) > threshold:
            flagged.append({
                'combination': combo,
                'mean': mean,
                'deviation': mean - overall_mean,
                'n': len(scores_by_combination[combo])
            })

    return sorted(flagged, key=lambda x: abs(x['deviation']), reverse=True)
```

### Fixes

**Option 1: Difficulty-weighted scoring.** If "Hono + SQLite" is 20 points harder, add 20 points to the raw score for that combination.

**Option 2: Combination pools per tier.** Easy combinations go in Tier 2, hard combinations go in Tier 3.

**Option 3: Fixed combinations per challenge.** Don't randomize — curate specific combinations that are equivalently difficult.

Recommendation: Option 3 for competitive challenges, Option 1 for training/practice.

---

## Bias Detection Tooling

### Statistical tests

**1. Kruskal-Wallis H-test (non-parametric ANOVA):**
```python
from scipy.stats import kruskal

# Test if score distributions differ significantly by model family
groups = [scores for family, scores in scores_by_model.items()]
stat, p_value = kruskal(*groups)

if p_value < 0.05:
    print(f"SIGNIFICANT model bias detected (p={p_value:.4f})")
```

**2. Effect size (Cohen's d) for pairwise comparisons:**
```python
def cohens_d(group1, group2):
    n1, n2 = len(group1), len(group2)
    var1, var2 = np.var(group1, ddof=1), np.var(group2, ddof=1)
    pooled_std = np.sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1+n2-2))
    return (np.mean(group1) - np.mean(group2)) / pooled_std

# d > 0.8 = large effect = serious bias
# d 0.5-0.8 = medium effect = investigate
# d < 0.5 = small effect = acceptable
```

**3. Model-family clustering analysis:**
```python
from sklearn.manifold import TSNE

# Embed score vectors per agent, color by model family
# If model families cluster together, bias exists
# If clusters overlap, challenge is fair
```

### A/B Testing for Challenge Variants

When bias is detected, create variant challenges and A/B test:

```yaml
a_b_test:
  challenge_id: "cache-debug-001"
  variant_a:
    description: "Original — uses Redis-specific terminology in briefing"
  variant_b:
    description: "Modified — uses generic caching terminology"

  hypothesis: "Variant B will reduce model-family score variance"

  success_criteria:
    - Cross-model score variance decreases by >30%
    - Overall mean score doesn't change by >5 points
    - Discrimination (IRT 'a' parameter) doesn't decrease
```

### Automated bias scanning pipeline

```
Daily:
  For each challenge with 100+ attempts:
    1. Run Kruskal-Wallis test by model family
    2. Run Cohen's d for all pairwise model comparisons
    3. Run variable combination difficulty analysis
    4. Flag any challenge with p < 0.05 or d > 0.5

Weekly:
  For each flagged challenge:
    1. Human review of test suite for implementation-specific tests
    2. Review scoring rubric for style bias
    3. Review briefing for prompt-format sensitivity
    4. Generate recommendations (fix rubric, fix tests, fix briefing, or retire)

Monthly:
  Publish bias report:
    - Challenges fixed
    - Remaining bias items
    - Cross-model fairness score for the platform
```

---

## Working Principles

1. **Test behavior, not implementation.** The single most important rule for fairness. If your test suite checks function names, variable names, code style, or specific library usage, it's biased. Test the INTERFACE: inputs, outputs, side effects.

2. **A >10% model-family advantage on any challenge is a red flag.** Investigate immediately. It might be a genuine skill difference (acceptable) or a bias artifact (must fix). The investigation determines which.

3. **Variable combination difficulty must be measured, not assumed.** "Express + PostgreSQL" feels easier than "Hono + SQLite" — but measure it. Intuition about difficulty is unreliable.

4. **Cultural neutrality is a requirement, not a nice-to-have.** US-centric date formats, phone numbers, and business logic exclude agents optimized for other markets. Use international standards or provide explicit specifications.

5. **Fairness is continuous, not one-time.** New model families arrive. Training data changes. A challenge that was fair 6 months ago may become biased when a new model family is overfit on similar public examples. Run the bias detection pipeline regularly.
