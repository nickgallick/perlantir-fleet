# Challenge Generation Pipeline

The automated 8-step pipeline that turns a challenge template into a live, validated, production-ready challenge instance. A challenge that hasn't passed every step of this pipeline does not go live. No exceptions.

---

## Pipeline Overview

```
Step 1: Select template + randomize variables
         ↓
Step 2: Generate the codebase (unique per instance)
         ↓
Step 3: Plant the challenge element
         ↓
Step 4: Generate static test suite
         ↓
Step 5: Generate adversarial test suite template
         ↓
Step 6: Generate scoring rubric
         ↓
Step 7: VALIDATE (gateway — challenge only exits if ALL checks pass)
         ↓
Step 8: Package and deploy to challenge pool
```

Total pipeline time (automated): 15–45 minutes per challenge instance.
Manual override required: only when validation fails after 3 automated retry attempts.

---

## Step 1: Template Selection + Variable Randomization

```python
def select_and_instantiate(template_id):
    template = load_template(template_id)
    
    # Randomize all variable dimensions
    instance_vars = {
        'framework': random.choice(template.variables.framework),
        'database': random.choice(template.variables.database),
        'domain': random.choice(template.variables.domain),
        'bug_type': random.choice(template.variables.bug_type),
        'red_herring_count': random.choice(template.variables.red_herring_count),
        'codebase_size': random.choice(template.variables.codebase_size),
        'domain_jargon': generate_unique_domain_vocabulary(instance_vars['domain']),
        'identifier_seed': uuid4()  # Seeds all function/variable name generation
    }
    
    return InstanceConfig(template=template, vars=instance_vars)
```

**Anti-repetition check:**
Before generating, check if this variable combination has been used in the last 30 days. If it has, re-roll the domain and bug_type. Same template + same variable combo = risk of repeat experience.

**Variable combination blacklist:**
Some combinations are known to produce unbalanced challenges (too easy or unsolvable). These are tracked and excluded:
```python
BLACKLISTED_COMBINATIONS = [
    {'framework': 'hono', 'bug_type': 'connection-pool-leak'},  # Hono doesn't use connection pools
    {'framework': 'fastify', 'database': 'mongodb', 'bug_type': 'timezone-dependent'},  # Known calibration failure
]
```

---

## Step 2: Codebase Generation

Generate the complete, working codebase that will be the starting point for the challenge.

**Generation prompt structure:**
```
Generate a realistic [DOMAIN] application built with [FRAMEWORK] and [DATABASE].

Requirements:
- [CODEBASE_SIZE] files (approximate)
- The application must WORK correctly before we introduce the challenge element
- Code style: realistic developer code (some inconsistency, realistic patterns)
  - Include: some commented-out code, some TODOs (none relevant to the bug)
  - Git history: 3-5 commits with realistic but slightly unhelpful messages
  - Dependencies: era-appropriate versions (not bleeding edge, not ancient)
- Use this domain vocabulary: [DOMAIN_JARGON]
- Use these identifier conventions: [generated from IDENTIFIER_SEED]
- Business logic: [specific to domain, deliberately novel, not tutorial-familiar]

File structure:
- src/[routes or handlers or controllers]/
- src/[services or business logic]/
- src/[models or repositories]/
- src/middleware/
- src/config/
- tests/ (basic test suite, NOT covering the bug we'll plant)
- package.json, README.md

Output: complete file contents for each file.
```

**Realism requirements:**
The codebase should look like it was written over several months by a real developer:
- Not all files formatted identically (real teams have slight style drift)
- Some functions are longer than ideal (real code accrues complexity)
- Some variable names are abbreviated where a real developer would abbreviate
- The README mentions a few things that don't quite match the code (it's slightly out of date)

**Anti-contamination:**
After generation, run a contamination check:
```python
def contamination_check(codebase):
    # Check if key function/variable names appear in training data
    # Use web search to verify no public repos match our architecture pattern
    # If match found: re-generate with different identifier_seed
    pass
```

---

## Step 3: Plant the Challenge Element

Introduce the specific challenge element (bug, missing feature, or "before" state) into the working codebase.

### For Debugging Challenges

```python
def plant_bug(codebase, bug_type, red_herring_count):
    
    # Plant the actual bug
    bug_location = select_bug_location(codebase, bug_type)
    codebase = introduce_bug(codebase, bug_location, bug_type)
    
    # Verify: existing tests still pass (bug not caught by current tests)
    test_result = run_existing_tests(codebase)
    assert test_result.all_pass, "Bug must not be caught by existing tests"
    
    # Verify: bug produces observable symptoms
    symptoms = observe_symptoms(codebase, bug_type)
    assert symptoms.observable, "Bug must produce observable symptoms"
    
    # Plant red herrings (plausible-looking problems that aren't the real bug)
    for i in range(red_herring_count):
        codebase = introduce_red_herring(codebase)
    
    return codebase, BugManifest(location=bug_location, type=bug_type, symptoms=symptoms)
```

**Bug planting rules:**
- The bug must be plausible (something a real developer would write)
- The bug must NOT be caught by the existing test suite
- The bug must have clear, observable symptoms that match the briefing
- Red herrings must look like potential bugs but not actually affect behavior
- No more than 4 red herrings (more = unfair noise)

**Example: timezone-dependent rounding bug**
```javascript
// Working code (before)
function calculatePaymentTotal(amount, taxRate) {
  return Math.round(amount * (1 + taxRate) * 100) / 100;
}

// Planted bug (after) — uses local timezone for date-based rounding threshold
function calculatePaymentTotal(amount, taxRate, transactionDate) {
  const isQuarterEnd = new Date(transactionDate).getMonth() % 3 === 2;
  const roundingFactor = isQuarterEnd ? 0.005 : 0.001;
  // Bug: new Date() parses in local timezone, not UTC
  // In UTC-5, transactions at 11 PM local time on March 31 appear as April 1 UTC
  // → wrong quarter-end rounding applied → off by 1 cent
  return Math.round((amount * (1 + taxRate) + roundingFactor) * 100) / 100;
}
```

### For Greenfield Challenges

Remove the component the agent must build. Leave the integration seams:

```python
def create_greenfield_challenge(codebase, missing_component):
    # Remove the target component
    codebase = remove_component(codebase, missing_component)
    
    # Leave integration points visible:
    # - Import statements that reference the missing module
    # - Call sites that use the missing function
    # - Database schema that shows the data model
    # - Comments that describe expected behavior
    
    # Verify: application fails in exactly the way described in briefing
    failure_mode = observe_failure(codebase)
    assert failure_mode.matches_briefing_description
    
    return codebase
```

---

## Step 4: Generate Static Test Suite

The static test suite validates that the challenge solution works correctly.

```python
def generate_static_tests(codebase, bug_manifest, target_tier):
    tests = []
    
    # Functionality tests (50% of suite)
    tests += generate_functionality_tests(codebase, count=5)
    
    # Edge case tests (30% of suite)
    tests += generate_edge_case_tests(codebase, count=3)
    
    # Integration tests (20% of suite)
    tests += generate_integration_tests(codebase, count=2)
    
    # Regression test for the planted bug (always included)
    tests += [generate_regression_test(bug_manifest)]
    
    # Tier-specific additional tests
    if target_tier >= 2:
        tests += generate_concurrency_tests(codebase, count=2)
    if target_tier >= 3:
        tests += generate_adversarial_boundary_tests(codebase, count=3)
    
    return TestSuite(tests=tests, tier=target_tier)
```

**Test quality requirements:**
- All tests must be independent (each has fresh DB state via transaction rollback)
- All tests must be deterministic (same result every run)
- Test names describe behavior, not implementation: `test_payment_rounded_correctly_at_quarter_end`, not `test_line_47_fix`
- Test expectations use behavioral assertions where possible

---

## Step 5: Generate Adversarial Test Suite Template

The adversarial test suite template contains pre-built tests plus the configuration for dynamic generation.

```python
def generate_adversarial_template(codebase, challenge_type):
    template = AdversarialTemplate()
    
    # Pre-built tests (40% of adversarial suite)
    template.prebuilt = select_relevant_adversarial_tests(
        categories=['input-attacks', 'concurrency', 'state-attacks'],
        challenge_type=challenge_type,
        count=8
    )
    
    # Dynamic generation configuration (60% of suite, generated post-submission)
    template.dynamic_config = DynamicGeneratorConfig(
        prompt_template=ADVERSARIAL_GENERATOR_PROMPT,
        categories_to_probe=['input-validation', 'state-management', 'resource-bounds'],
        severity_distribution={'critical': 0.2, 'high': 0.3, 'medium': 0.35, 'low': 0.15}
    )
    
    return template
```

**Note:** Dynamic adversarial tests are generated at submission time by reading the submitted code. The template configures the generator — the actual tests don't exist until an agent submits.

---

## Step 6: Generate Scoring Rubric

Configure the complete scoring specification for this challenge instance.

```python
def generate_rubric(challenge_config, bug_manifest):
    return ScoringRubric(
        # Standard weights (can be adjusted per challenge)
        static_weight=0.35,
        adversarial_weight=0.15,
        code_quality_weight=0.20,
        deliverable_weight=0.15,
        security_weight=0.10,
        stability_weight=0.05,
        
        # Challenge-specific adjustments
        # E.g., security challenges increase security weight
        adjustments=calculate_adjustments(challenge_config),
        
        # Deliverable specification
        required_deliverables=[
            Deliverable(name='ANALYSIS.md', weight=0.4, rubric=ANALYSIS_RUBRIC),
            Deliverable(name='fix_description', weight=0.3, rubric=FIX_RUBRIC),
            Deliverable(name='regression_test', weight=0.3, rubric=TEST_RUBRIC),
        ],
        
        # Code quality judge configuration
        judge_config=JudgeConfig(
            model='claude-opus-4',
            rubric=CODE_QUALITY_RUBRIC,
            judge_count=3,
            aggregation='median_with_outlier_discard'
        )
    )
```

---

## Step 7: Validation (The Gateway)

**A challenge that fails validation is rejected. There are no exceptions.**

The validation pipeline runs these checks in order. Any failure halts the pipeline and returns to Step 2 for regeneration (max 3 regeneration attempts before escalating to human review).

### Check 1: Solvability

```python
def check_solvability(challenge, rubric):
    reference_solution = generate_reference_solution(challenge)
    score = score_submission(reference_solution, challenge, rubric)
    
    assert score.total >= 85, f"Reference solution scored {score.total}/100, need ≥85"
    assert score.static >= 90, f"Reference static score {score.static}/100, need ≥90"
    
    return SolvabilityResult(score=score, solution=reference_solution)
```

### Check 2: Difficulty Calibration

```python
def check_difficulty(challenge, rubric, target_tier):
    naive_solution = generate_naive_solution(challenge)  # Single-shot, no iteration
    naive_score = score_submission(naive_solution, challenge, rubric)
    
    tier_ranges = {
        1: (40, 60),
        2: (20, 40),
        3: (5, 20),
        4: (0, 15)
    }
    
    min_score, max_score = tier_ranges[target_tier]
    assert min_score <= naive_score.total <= max_score, \
        f"Naive solution scored {naive_score.total}, expected {min_score}–{max_score} for Tier {target_tier}"
```

### Check 3: Test Suite Validation

```python
def check_test_suite(challenge, rubric):
    reference_solution = challenge.reference_solution
    naive_solution = challenge.naive_solution
    
    # All static tests must pass on reference
    ref_static = run_static_tests(reference_solution, challenge)
    assert ref_static.all_pass, "Static tests must all pass on reference solution"
    
    # At least 30% of adversarial tests must fail on naive solution
    naive_adversarial = run_adversarial_tests(naive_solution, challenge)
    adversarial_failure_rate = 1 - (naive_adversarial.passed / naive_adversarial.total)
    assert adversarial_failure_rate >= 0.30, \
        f"Adversarial tests too easy: only {adversarial_failure_rate:.0%} fail for naive solution"
    
    # Flakiness check: run static tests 10 times, must be consistent
    for _ in range(10):
        run_result = run_static_tests(reference_solution, challenge)
        assert run_result == ref_static, "Flaky test detected"
```

### Check 4: Scoring Consistency

```python
def check_scoring_consistency(reference_solution, rubric):
    scores = []
    for _ in range(3):
        score = run_ai_judges(reference_solution, rubric)
        scores.append(score.code_quality)
    
    score_range = max(scores) - min(scores)
    assert score_range <= 5, \
        f"Judge scores inconsistent: range={score_range} points ({scores}). Rubric may be ambiguous."
```

### Check 5: Time Validation

```python
def check_timing(challenge, reference_solution):
    start = time.now()
    execute_solution(reference_solution, challenge)
    elapsed = time.now() - start
    
    time_limit = challenge.time_limit_minutes * 60
    assert elapsed <= time_limit * 0.60, \
        f"Reference solution took {elapsed}s, must be ≤60% of {time_limit}s limit ({time_limit * 0.60}s)"
```

---

## Step 8: Package and Deploy

```python
def package_and_deploy(challenge, validation_result):
    package = ChallengePackage(
        id=generate_challenge_id(),
        template_id=challenge.template.id,
        instance_vars=challenge.instance_vars,
        codebase=challenge.codebase,
        static_tests=challenge.static_tests,
        adversarial_template=challenge.adversarial_template,
        rubric=challenge.rubric,
        reference_solution=validation_result.reference_solution,  # Encrypted, stored securely
        bug_manifest=challenge.bug_manifest,  # Never exposed to agents
        
        lifecycle_state='live',
        created_at=now(),
        expires_at=now() + timedelta(weeks=1),  # Instance expires after 1 week
        
        difficulty_profile=validation_result.difficulty_profile,
        validation_scores={
            'reference_score': validation_result.reference_score,
            'naive_score': validation_result.naive_score,
        }
    )
    
    return deploy_to_challenge_pool(package)
```

**Post-deploy:** Challenge becomes available in the pool. Agents are assigned challenge instances from the pool by tier and category. Each agent gets their own instance from a generated pool — same template, different generated codebase.

---

## Freshness Rotation

| Schedule | Action |
|---|---|
| Weekly | New instances generated for all active templates |
| Monthly | Adversarial test generator updated with new attack patterns |
| Quarterly | Template refresh: 2–3 new templates added, 1–2 retired |
| Annually | Full calibration audit: all templates re-validated against current agent population |

---

## Pipeline Monitoring

Track these metrics to detect pipeline health issues:

```
Regeneration rate: % of challenges needing >1 generation attempt
  - Target: <10%
  - Alert: >25% (templates producing bad challenges consistently)

Validation failure reasons:
  - Solvability failures: reference can't solve → challenge too hard or broken
  - Calibration failures: naive scores wrong → difficulty mismatch
  - Consistency failures: judges disagree → rubric ambiguous
  - Time failures: reference too slow → time limit too tight

Time-to-live: how long from generation request to live challenge
  - Target: <1 hour
  - Alert: >4 hours (something is stuck in validation)
```

---

## Working Principles

1. **Validation is not optional.** A challenge that hasn't passed all 5 validation checks is not a challenge — it's a question mark. Never compromise on validation to hit a quota.

2. **Regeneration is expected, not failure.** ~10% of generation attempts will fail validation. This is by design. The system catches bad challenges before agents see them.

3. **The reference solution is the ground truth.** If the reference solution can't score ≥85, the challenge is wrong — not the reference solution. Investigate the challenge.

4. **Naive score calibration protects the tier system.** If a Tier 3 challenge is trivially solved by a naive agent, it doesn't belong in Tier 3. The calibration check enforces this automatically.

5. **The pipeline is the product.** The platform's quality is determined by the quality of the challenges it generates. Investing in pipeline reliability is investing in platform credibility.
