# Challenge Generation Pipeline v2

The 5-stage pipeline from concept to live challenge. Each stage has defined inputs, process, quality gates, and outputs. No challenge reaches production without passing ALL gates. This is a complete replacement for the v1 8-step pipeline — fewer stages, stricter gates, better discrimination.

---

## Pipeline Overview

```
Stage 1: Challenge Architect
         → structured challenge spec (YAML)
         ↓
Stage 2: Scenario Builder
         → complete challenge package (all assets)
         ↓
Stage 3: Difficulty Calibrator
         → validated difficulty profile (4-agent benchmark)
         ↓
Stage 4: Integrity Auditor
         → security + fairness clearance
         ↓
Stage 5: Arena Publisher
         → live challenge with monitoring
```

Total pipeline time (automated): 20-60 minutes per challenge instance.
Hard timeout: 90 minutes. If any stage exceeds its timeout, the pipeline aborts with a diagnostic report.
Maximum retry budget: 3 full pipeline attempts before escalation to human review.

---

## Stage 1: Challenge Architect

**Purpose:** Transform a high-level request into a precise, structured challenge specification that controls everything downstream.

### Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `category` | enum | yes | One of: debugging, greenfield, refactoring, system-design, incident-response, optimization |
| `target_weight_class` | int (0-4) | yes | Desired tier/difficulty level |
| `target_solve_rate` | float (0.0-1.0) | yes | Expected fraction of agents at target tier who should pass |
| `discriminator_traits` | list[str] | yes | Which of the 8 difficulty dimensions to emphasize |

The 8 difficulty dimensions available for `discriminator_traits`:
1. `code-navigation` — finding relevant code in a large codebase
2. `root-cause-analysis` — tracing symptoms to underlying cause
3. `edge-case-reasoning` — handling boundary conditions and corner cases
4. `system-thinking` — understanding cross-component interactions
5. `time-pressure` — working under tight deadlines
6. `ambiguity-tolerance` — operating with incomplete or misleading information
7. `tool-mastery` — effective use of debugging/profiling/testing tools
8. `communication` — explaining findings and decisions clearly

### Process

#### Step 1.1: Template Selection or Concept Creation

```python
def architect_challenge(category, weight_class, solve_rate, discriminators):
    # Search existing templates first
    candidates = query_template_library(
        category=category,
        weight_class=weight_class,
        discriminators=discriminators
    )

    if candidates and random.random() < 0.7:
        # 70% of the time: use existing template with fresh variables
        template = select_weighted(candidates, weight_by='last_used_recency')
    else:
        # 30% of the time: generate a new concept from scratch
        template = generate_novel_concept(
            category=category,
            discriminators=discriminators,
            avoid_patterns=get_recent_patterns(days=60)
        )

    return template
```

#### Step 1.2: Variable Randomization

```python
def randomize_variables(template, weight_class):
    variables = {
        'framework': random.choice(template.framework_options),
        'domain': random.choice(template.domain_options),
        'bug_type': random.choice(template.bug_type_options),
        'codebase_size': select_size_for_weight_class(weight_class),
        'red_herring_count': select_herring_count(weight_class),
        'identifier_seed': uuid4(),
        'domain_vocabulary': generate_domain_jargon(variables['domain']),
        'complexity_modifiers': select_complexity_mods(weight_class),
    }

    # Weight-class-specific adjustments
    if weight_class >= 3:
        variables['cross_component_depth'] = random.randint(3, 6)
        variables['misleading_clue_count'] = random.randint(2, 4)
    if weight_class <= 1:
        variables['hint_level'] = random.choice(['moderate', 'generous'])
        variables['red_herring_count'] = min(variables['red_herring_count'], 1)

    return variables
```

#### Step 1.3: Generate Structured Challenge Spec

The spec is the contract for everything downstream. Every field is mandatory.

```yaml
# Example structured challenge spec
challenge_spec:
  title: "The Phantom Transaction"
  hook: "Payments are silently rounding to zero for Australian users after midnight UTC."
  category: debugging
  format: codebase_with_bug
  weight_class: 3

  difficulty_profile:
    code_navigation: 0.7
    root_cause_analysis: 0.9
    edge_case_reasoning: 0.8
    system_thinking: 0.6
    time_pressure: 0.4
    ambiguity_tolerance: 0.7
    tool_mastery: 0.5
    communication: 0.6

  deliverables:
    - name: "ANALYSIS.md"
      description: "Root cause analysis with evidence chain"
      weight: 0.35
    - name: "fix"
      description: "Code fix applied to the codebase"
      weight: 0.40
    - name: "regression_test"
      description: "Test that catches this specific bug"
      weight: 0.25

  expected_failure_modes:
    - "Agent fixes the symptom (rounding) without identifying the timezone root cause"
    - "Agent identifies timezone issue but misses the currency-specific decimal handling"
    - "Agent writes regression test that only covers one timezone offset"

  variables:
    framework: "fastify"
    domain: "payment-processing"
    bug_type: "timezone-locale-interaction"
    codebase_size: "medium-35-files"
    red_herring_count: 3
    identifier_seed: "a1b2c3d4-..."

  anti_repetition_fingerprint: "debug:payment:timezone:fastify:medium:3rh"
```

### Quality Gate 1: Spec Completeness

All checks must pass. Any failure rejects the spec and retries from Step 1.1.

```python
def gate_1_spec_validation(spec):
    errors = []

    # Completeness: every field present and non-empty
    required_fields = [
        'title', 'hook', 'category', 'format', 'weight_class',
        'difficulty_profile', 'deliverables', 'expected_failure_modes',
        'variables', 'anti_repetition_fingerprint'
    ]
    for field in required_fields:
        if not getattr(spec, field, None):
            errors.append(f"Missing required field: {field}")

    # Difficulty profile: all 8 dimensions present, values in [0.0, 1.0]
    if spec.difficulty_profile:
        for dim in DIFFICULTY_DIMENSIONS:
            val = spec.difficulty_profile.get(dim)
            if val is None:
                errors.append(f"Missing difficulty dimension: {dim}")
            elif not (0.0 <= val <= 1.0):
                errors.append(f"Dimension {dim} out of range: {val}")

    # Weight class ranges: difficulty profile must match target
    if spec.weight_class is not None and spec.difficulty_profile:
        avg_difficulty = mean(spec.difficulty_profile.values())
        expected_range = WEIGHT_CLASS_RANGES[spec.weight_class]
        if not (expected_range[0] <= avg_difficulty <= expected_range[1]):
            errors.append(
                f"Avg difficulty {avg_difficulty:.2f} outside "
                f"weight class {spec.weight_class} range {expected_range}"
            )

    # Anti-repetition: fingerprint must not match recent instances
    recent_fingerprints = get_fingerprints(days=30)
    for fp in recent_fingerprints:
        similarity = fingerprint_similarity(spec.anti_repetition_fingerprint, fp)
        if similarity > 0.70:
            errors.append(
                f"Fingerprint too similar to recent instance "
                f"({similarity:.0%} match, threshold 70%)"
            )

    # Deliverables: at least 2 deliverables, weights sum to 1.0
    if spec.deliverables:
        total_weight = sum(d.weight for d in spec.deliverables)
        if abs(total_weight - 1.0) > 0.01:
            errors.append(f"Deliverable weights sum to {total_weight}, must be 1.0")
        if len(spec.deliverables) < 2:
            errors.append("Must have at least 2 deliverables")

    if errors:
        raise SpecValidationError(errors=errors, retry=True)

    return spec
```

### Failure Handling

| Failure | Action | Max Retries |
|---------|--------|-------------|
| Missing fields | Regenerate spec with explicit field requirements | 3 |
| Difficulty out of range | Adjust discriminator weights and regenerate | 3 |
| Fingerprint collision | Re-roll domain + bug_type + framework | 5 |
| Template exhaustion | Force novel concept generation | 1 |

**Stage 1 timeout:** 5 minutes. If spec generation exceeds this, abort and log the template/variable combo for investigation.

### Output

Structured challenge spec as YAML, conforming to the schema above. Passed to Stage 2.

---

## Stage 2: Scenario Builder

**Purpose:** Transform the abstract spec into a complete, runnable challenge package with all assets, tests, and judge configurations.

### Inputs

- Structured challenge spec (YAML) from Stage 1

### Process

#### Step 2.1: Codebase Generation

Generate the complete, working codebase that will serve as the challenge environment. The codebase must work correctly BEFORE the challenge element is introduced.

```python
def generate_codebase(spec):
    codebase = generate_from_spec(
        framework=spec.variables.framework,
        domain=spec.variables.domain,
        size=spec.variables.codebase_size,
        identifier_seed=spec.variables.identifier_seed,
        domain_vocabulary=spec.variables.domain_vocabulary,
    )

    # Realism pass: inject the artifacts of real development
    codebase = add_realism_artifacts(codebase, {
        'style_drift': True,           # Slight formatting inconsistencies
        'stale_comments': 2,            # Comments that don't match current code
        'dead_code': 1,                 # One unused function
        'incomplete_readme': True,      # README slightly out of date
        'git_history': generate_realistic_commits(count=5),
        'todo_comments': 3,             # None related to the actual challenge
        'dependency_versions': 'realistic',  # Not bleeding edge, not ancient
    })

    # Contamination check: verify no public repos match our code patterns
    contamination = check_contamination(codebase)
    if contamination.detected:
        codebase = regenerate_with_new_seed(spec)

    # Smoke test: the application must start and pass basic health checks
    health = run_health_check(codebase)
    assert health.passes, f"Generated codebase fails health check: {health.errors}"

    return codebase
```

#### Step 2.2: Plant Challenge Element

```python
def plant_challenge_element(codebase, spec):
    if spec.category == 'debugging':
        return plant_bug(codebase, spec)
    elif spec.category == 'greenfield':
        return remove_component(codebase, spec)
    elif spec.category == 'refactoring':
        return degrade_architecture(codebase, spec)
    elif spec.category == 'optimization':
        return introduce_performance_bottleneck(codebase, spec)
    elif spec.category == 'incident-response':
        return generate_incident_scenario(codebase, spec)
    elif spec.category == 'system-design':
        return create_design_challenge(codebase, spec)
```

Bug planting rules (for debugging challenges):
- The bug must be plausible — something a real developer would write
- The bug must NOT be caught by the existing test suite
- The bug must produce observable symptoms matching the briefing hook
- Red herrings must look like potential bugs but not affect behavior
- Maximum red herrings: `spec.variables.red_herring_count` (capped at 4)

#### Step 2.3: Generate Supporting Assets

```python
def generate_assets(codebase, spec, challenge_element):
    assets = {}

    # Starter code / repo structure
    assets['starter'] = package_starter_repo(codebase)

    # Fixtures and test data
    assets['fixtures'] = generate_test_fixtures(
        codebase=codebase,
        domain=spec.variables.domain,
        include_edge_cases=(spec.weight_class >= 2),
    )

    # Synthetic logs and traces (for debugging/incident challenges)
    if spec.category in ('debugging', 'incident-response'):
        assets['logs'] = generate_synthetic_logs(
            codebase=codebase,
            challenge_element=challenge_element,
            noise_level=LOG_NOISE_BY_WEIGHT[spec.weight_class],
            include_misleading_entries=(spec.weight_class >= 2),
        )
        assets['traces'] = generate_traces(
            codebase=codebase,
            challenge_element=challenge_element,
        )

    # Documentation (with deliberate gaps for high-tier challenges)
    assets['docs'] = generate_documentation(
        codebase=codebase,
        completeness=DOC_COMPLETENESS_BY_WEIGHT[spec.weight_class],
        # Weight class 3+: docs contain at least one misleading statement
        misleading_sections=(spec.weight_class >= 3),
    )

    return assets
```

#### Step 2.4: Generate Test Suites

```python
def generate_test_suites(codebase, spec, challenge_element):
    # Hidden static test suite: validates correctness
    static_tests = generate_static_tests(
        codebase=codebase,
        challenge_element=challenge_element,
        tier=spec.weight_class,
        count_by_type={
            'functionality': 5,
            'edge_case': 3 + spec.weight_class,
            'integration': 2,
            'regression': 1,  # Always: test for the specific planted issue
            'concurrency': 2 if spec.weight_class >= 2 else 0,
            'adversarial_boundary': 3 if spec.weight_class >= 3 else 0,
        }
    )

    # Adversarial test template: generates tests at submission time
    adversarial_template = generate_adversarial_template(
        codebase=codebase,
        challenge_type=spec.category,
        severity_distribution={
            'critical': 0.20,
            'high': 0.30,
            'medium': 0.35,
            'low': 0.15,
        },
        prebuilt_ratio=0.40,
        dynamic_ratio=0.60,
    )

    return static_tests, adversarial_template
```

#### Step 2.5: Configure Judges

```python
def configure_judges(spec):
    judge_configs = {
        'correctness_judge': JudgeConfig(
            type='automated',
            runs_static_tests=True,
            runs_adversarial_tests=True,
            weight=0.50,
        ),
        'code_quality_judge': JudgeConfig(
            type='llm',
            model='claude-opus-4',
            rubric=load_rubric('code-quality', spec.category),
            judge_count=3,
            aggregation='median_with_outlier_discard',
            weight=0.20,
        ),
        'deliverable_judge': JudgeConfig(
            type='llm',
            model='claude-opus-4',
            rubric=load_rubric('deliverable', spec.category),
            judge_count=3,
            aggregation='median_with_outlier_discard',
            weight=0.15,
            deliverable_specs=spec.deliverables,
        ),
        'security_judge': JudgeConfig(
            type='hybrid',
            static_analysis=['semgrep', 'bandit'],
            llm_model='claude-opus-4',
            rubric=load_rubric('security', spec.category),
            weight=0.15,
        ),
    }
    return judge_configs
```

### Quality Gate 2: Package Completeness

```python
def gate_2_package_validation(package):
    errors = []

    # All required files exist
    required = ['starter/', 'fixtures/', 'static_tests/', 'adversarial_template/',
                'judge_config.yaml', 'challenge_manifest.yaml']
    for path in required:
        if not package.contains(path):
            errors.append(f"Missing required asset: {path}")

    # Static tests execute without errors on the UNMODIFIED codebase
    # (tests should FAIL because the bug is present, but they must not ERROR)
    test_result = execute_tests(package.static_tests, package.starter)
    for test in test_result.results:
        if test.status == 'error':
            errors.append(f"Test execution error (not failure): {test.name}: {test.error}")

    # Hidden tests isolated from agent-accessible filesystem
    if paths_overlap(package.agent_visible_paths, package.hidden_test_paths):
        errors.append("CRITICAL: Hidden tests accessible to agent filesystem")

    # Judge configurations parseable and complete
    for judge_name, config in package.judge_configs.items():
        validation = validate_judge_config(config)
        if not validation.valid:
            errors.append(f"Judge config '{judge_name}' invalid: {validation.errors}")

    # Adversarial template generates at least 5 test cases on reference solution
    sample_tests = package.adversarial_template.generate_sample(
        solution=package.reference_placeholder,
        count=5
    )
    if len(sample_tests) < 5:
        errors.append(f"Adversarial template only produced {len(sample_tests)} tests, need 5+")

    if errors:
        raise PackageValidationError(errors=errors, retry=True)

    return package
```

### Failure Handling

| Failure | Action | Max Retries |
|---------|--------|-------------|
| Codebase health check fails | Regenerate codebase with different seed | 3 |
| Contamination detected | Regenerate with new identifier seed | 3 |
| Test execution errors | Fix test generation prompt, regenerate tests | 2 |
| Hidden test isolation breach | Restructure package paths, rebuild | 1 |
| Judge config invalid | Regenerate judge configs from spec | 2 |

**Stage 2 timeout:** 30 minutes. This is the most time-intensive stage. If generation exceeds the timeout, abort and flag the spec for complexity review.

### Output

Complete challenge package containing: starter repo, fixtures, logs/traces, documentation, hidden static tests, adversarial test template, judge configurations, and challenge manifest. Passed to Stage 3.

---

## Stage 3: Difficulty Calibrator

**Purpose:** Validate that the challenge actually discriminates between skill levels by running it against 4 benchmark agents with known capabilities.

### Inputs

- Complete challenge package from Stage 2

### Process

#### Step 3.1: Run 4 Benchmark Agents

Each agent runs in a sandboxed environment identical to what a real contestant would see. Agents have the same time limits, tool access, and filesystem visibility.

```python
BENCHMARK_AGENTS = {
    'naive': {
        'description': 'Single-shot, basic prompting, no iteration',
        'strategy': 'Read briefing, attempt immediate fix, submit',
        'tools': ['file_read', 'file_write', 'terminal'],
        'iterations': 1,
        'error_recovery': False,
    },
    'standard': {
        'description': 'Iterative, good prompting, basic tools',
        'strategy': 'Read briefing, explore codebase, form hypothesis, implement, test, iterate',
        'tools': ['file_read', 'file_write', 'terminal', 'search', 'test_runner'],
        'iterations': 5,
        'error_recovery': True,
    },
    'elite': {
        'description': 'Full capability, advanced prompting, sophisticated tool use',
        'strategy': 'Deep exploration, multi-hypothesis, systematic elimination, thorough testing',
        'tools': ['file_read', 'file_write', 'terminal', 'search', 'test_runner',
                  'debugger', 'profiler', 'git_log'],
        'iterations': 15,
        'error_recovery': True,
    },
    'reference': {
        'description': 'Uses intended solution approach (establishes ceiling)',
        'strategy': 'Follows the golden path with hints from the challenge manifest',
        'tools': 'all',
        'iterations': 10,
        'error_recovery': True,
        'has_hints': True,  # Gets access to challenge_manifest hints (not full answer)
    },
}

def run_calibration(package):
    results = {}
    for agent_name, agent_config in BENCHMARK_AGENTS.items():
        env = create_sandbox(package, agent_config)
        submission = run_agent(agent_config, env, timeout=package.time_limit)
        score = score_submission(submission, package)
        results[agent_name] = CalibrationResult(
            agent=agent_name,
            score=score,
            time_taken=submission.elapsed,
            tools_used=submission.tool_log,
            iterations=submission.iteration_count,
        )
    return results
```

#### Step 3.2: Validate Score Distribution

ALL checks must pass. Any single failure rejects the challenge.

```python
def validate_calibration(results, spec):
    errors = []
    scores = {name: r.score.total for name, r in results.items()}

    # Check 1: Reference agent scores >85 (challenge IS solvable)
    if scores['reference'] <= 85:
        errors.append(
            f"CRITICAL: Reference agent scored {scores['reference']}/100 "
            f"(need >85). Challenge may be unsolvable or rubric may be broken."
        )

    # Check 2: Elite agent scores 55-80 (appropriately hard for top tier)
    if not (55 <= scores['elite'] <= 80):
        errors.append(
            f"Elite agent scored {scores['elite']}/100 "
            f"(need 55-80). "
            f"{'Too easy for elite.' if scores['elite'] > 80 else 'Too hard for elite.'}"
        )

    # Check 3: Standard agent scores 25-55 (meaningful middle range)
    if not (25 <= scores['standard'] <= 55):
        errors.append(
            f"Standard agent scored {scores['standard']}/100 "
            f"(need 25-55). "
            f"{'Too easy for standard.' if scores['standard'] > 55 else 'Too hard for standard.'}"
        )

    # Check 4: Naive agent scores 5-25 (one-shot insufficient)
    if not (5 <= scores['naive'] <= 25):
        errors.append(
            f"Naive agent scored {scores['naive']}/100 "
            f"(need 5-25). "
            f"{'Too easy — naive should not score this high.' if scores['naive'] > 25 else 'Too hard — naive should get partial credit.'}"
        )

    # Check 5: Score spread (stddev) >15 (challenge discriminates)
    all_scores = [scores['naive'], scores['standard'], scores['elite'], scores['reference']]
    spread = stdev(all_scores)
    if spread <= 15:
        errors.append(
            f"Score spread (stddev) is {spread:.1f} (need >15). "
            f"Scores: naive={scores['naive']}, standard={scores['standard']}, "
            f"elite={scores['elite']}, reference={scores['reference']}. "
            f"Challenge does not discriminate between skill levels."
        )

    # Check 6: Monotonic ordering (reference > elite > standard > naive)
    if not (scores['reference'] > scores['elite'] > scores['standard'] > scores['naive']):
        errors.append(
            f"Score ordering violated. Expected reference > elite > standard > naive. "
            f"Got: {scores['reference']} > {scores['elite']} > "
            f"{scores['standard']} > {scores['naive']}"
        )

    if errors:
        # Determine retry target: spec issue (Stage 1) or package issue (Stage 2)
        if scores['reference'] <= 85:
            raise CalibrationError(errors=errors, retry_stage=2,
                                   reason="Challenge unsolvable — rebuild package")
        elif spread <= 15:
            raise CalibrationError(errors=errors, retry_stage=1,
                                   reason="Poor discrimination — redesign spec")
        else:
            raise CalibrationError(errors=errors, retry_stage=2,
                                   reason="Score range issue — adjust difficulty")

    return CalibrationReport(
        scores=scores,
        spread=spread,
        classification=spec.weight_class,
        confidence=calculate_confidence(scores, spec.weight_class),
    )
```

#### Step 3.3: Flakiness Check

Run elite and standard agents 2 additional times each. Score variance across runs must be <10 points.

```python
def flakiness_check(package, initial_results):
    for agent_name in ['elite', 'standard']:
        all_scores = [initial_results[agent_name].score.total]
        for _ in range(2):
            env = create_sandbox(package, BENCHMARK_AGENTS[agent_name])
            submission = run_agent(BENCHMARK_AGENTS[agent_name], env)
            score = score_submission(submission, package)
            all_scores.append(score.total)

        variance = max(all_scores) - min(all_scores)
        if variance > 10:
            raise FlakinessError(
                f"{agent_name} agent scores vary by {variance} points "
                f"across 3 runs: {all_scores}. Challenge or judge is flaky."
            )
```

### Quality Gate 3: Calibration Pass

All of the following must be true:
1. Reference > 85
2. Elite in [55, 80]
3. Standard in [25, 55]
4. Naive in [5, 25]
5. Stddev > 15
6. Monotonic ordering: reference > elite > standard > naive
7. Flakiness variance < 10 for elite and standard

### Failure Handling

| Failure | Root Cause | Retry Target | Action |
|---------|-----------|--------------|--------|
| Reference <= 85 | Challenge unsolvable or rubric broken | Stage 2 | Rebuild package, verify tests pass on known-good solution |
| Elite > 80 | Too easy | Stage 1 | Increase discriminator weights, add complexity |
| Elite < 55 | Too hard | Stage 2 | Reduce red herrings, improve documentation completeness |
| Standard out of range | Difficulty miscalibrated | Stage 2 | Adjust codebase size or red herring count |
| Naive > 25 | Trivially solvable | Stage 1 | Redesign — challenge lacks depth |
| Naive < 5 | No partial credit possible | Stage 2 | Add clearer entry points for partial solutions |
| Stddev <= 15 | Doesn't discriminate | Stage 1 | Redesign with different discriminator traits |
| Flaky scores | Non-deterministic judge or test | Stage 2 | Fix flaky tests, tighten judge rubric |

**Stage 3 timeout:** 45 minutes (most time is benchmark agent runs). If benchmark agents stall, kill after individual agent timeout + 60 seconds grace.

### Output

Calibration report with all 4 agent scores, spread, confidence level, and classification confirmation. Passed to Stage 4.

---

## Stage 4: Integrity Auditor

**Purpose:** Catch leaked answers, trivial shortcuts, ambiguous instructions, impossible edge cases, unintended exploits, bias, and repetition before the challenge goes live.

### Inputs

- Complete challenge package from Stage 2
- Calibration report from Stage 3

### Process

#### Check 4.1: Answer Leakage

Search all agent-visible files for content that reveals the solution.

```python
def check_answer_leakage(package):
    findings = []
    solution_keywords = extract_solution_keywords(package.challenge_manifest)
    agent_visible = package.get_agent_visible_files()

    for filepath, content in agent_visible.items():
        # Direct answer in comments
        for keyword in solution_keywords:
            if keyword.lower() in content.lower():
                findings.append(Finding(
                    severity='critical',
                    check='answer_leakage',
                    detail=f"Solution keyword '{keyword}' found in {filepath}",
                ))

        # Git history leaking the fix
        git_log = package.get_git_history(filepath)
        for commit in git_log:
            if any(kw.lower() in commit.message.lower() for kw in solution_keywords):
                findings.append(Finding(
                    severity='critical',
                    check='answer_leakage',
                    detail=f"Solution keyword in git commit message: {commit.sha[:8]}",
                ))

        # Stack traces or error messages that directly point to the bug location
        if contains_revealing_stack_trace(content, package.challenge_manifest):
            findings.append(Finding(
                severity='high',
                check='answer_leakage',
                detail=f"Stack trace in {filepath} reveals bug location",
            ))

    return findings
```

#### Check 4.2: Trivial Shortcuts

Verify that no simple shortcut bypasses the intended challenge.

```python
def check_trivial_shortcuts(package):
    findings = []

    # Can the agent just delete the buggy code and still pass tests?
    deletion_score = try_deletion_attack(package)
    if deletion_score > 30:
        findings.append(Finding(
            severity='critical',
            check='trivial_shortcut',
            detail=f"Deleting buggy code scores {deletion_score}/100 — tests too weak",
        ))

    # Can a simple regex replace fix the issue?
    regex_score = try_regex_attacks(package, COMMON_FIX_PATTERNS)
    if regex_score > 50:
        findings.append(Finding(
            severity='critical',
            check='trivial_shortcut',
            detail=f"Simple regex fix scores {regex_score}/100 — challenge too shallow",
        ))

    # Can the agent just copy a function from the test expectations?
    copy_score = try_test_copying_attack(package)
    if copy_score > 40:
        findings.append(Finding(
            severity='high',
            check='trivial_shortcut',
            detail=f"Copying test expectations scores {copy_score}/100",
        ))

    return findings
```

#### Check 4.3: Instruction Ambiguity

```python
def check_ambiguity(package):
    findings = []

    # LLM-based ambiguity scan: ask 3 independent judges to interpret the briefing
    interpretations = []
    for i in range(3):
        interpretation = interpret_briefing(
            package.briefing,
            model='claude-opus-4',
            prompt="What exactly is the agent being asked to do? List specific deliverables."
        )
        interpretations.append(interpretation)

    # If interpretations diverge, the briefing is ambiguous
    agreement = calculate_interpretation_agreement(interpretations)
    if agreement < 0.85:
        findings.append(Finding(
            severity='high',
            check='ambiguity',
            detail=f"Briefing interpretation agreement only {agreement:.0%} — instructions unclear",
            interpretations=interpretations,
        ))

    return findings
```

#### Check 4.4: Impossible Cases

```python
def check_impossible_cases(package):
    findings = []

    # Verify all deliverables are actually achievable given the starter code
    for deliverable in package.spec.deliverables:
        achievable = verify_deliverable_achievable(package, deliverable)
        if not achievable.possible:
            findings.append(Finding(
                severity='critical',
                check='impossible_case',
                detail=f"Deliverable '{deliverable.name}' appears impossible: {achievable.reason}",
            ))

    # Check for circular dependencies that block progress
    dep_graph = analyze_dependency_graph(package.starter)
    if dep_graph.has_unsolvable_cycles:
        findings.append(Finding(
            severity='critical',
            check='impossible_case',
            detail=f"Codebase has unsolvable circular dependency: {dep_graph.cycle_description}",
        ))

    return findings
```

#### Check 4.5: Unintended Exploits

```python
def check_exploits(package):
    findings = []

    # Sandbox escape vectors
    sandbox_check = scan_for_sandbox_escapes(package)
    if sandbox_check.risks:
        findings.extend([Finding(severity='critical', check='exploit', detail=r)
                         for r in sandbox_check.risks])

    # Can the agent access the scoring system or judge configs?
    if can_access_judge_configs(package):
        findings.append(Finding(
            severity='critical',
            check='exploit',
            detail="Agent can read judge configuration files",
        ))

    # Can the agent modify the test suite?
    if can_modify_tests(package):
        findings.append(Finding(
            severity='critical',
            check='exploit',
            detail="Agent can modify hidden test files",
        ))

    return findings
```

#### Check 4.6: Bias Detection

```python
def check_bias(package):
    findings = []

    # Framework bias: does the challenge assume specific framework knowledge
    # beyond what's documented in the starter code?
    assumed_knowledge = detect_assumed_knowledge(package)
    if assumed_knowledge.undocumented:
        findings.append(Finding(
            severity='medium',
            check='bias',
            detail=f"Challenge assumes undocumented framework knowledge: {assumed_knowledge.items}",
        ))

    # Cultural/locale bias: does the challenge depend on culture-specific assumptions?
    locale_dependencies = detect_locale_assumptions(package)
    if locale_dependencies:
        findings.append(Finding(
            severity='medium',
            check='bias',
            detail=f"Challenge has locale-specific assumptions: {locale_dependencies}",
        ))

    return findings
```

#### Check 4.7: Repetition Detection

```python
def check_repetition(package):
    findings = []

    # Compare against all challenges from last 90 days (broader window than Stage 1)
    recent_packages = get_recent_packages(days=90)
    for recent in recent_packages:
        structural_similarity = compare_structure(package, recent)
        if structural_similarity > 0.60:
            findings.append(Finding(
                severity='high',
                check='repetition',
                detail=(
                    f"Structurally {structural_similarity:.0%} similar to "
                    f"challenge {recent.id} from {recent.created_at}"
                ),
            ))

    return findings
```

### Quality Gate 4: Integrity Pass

```python
def gate_4_integrity_verdict(all_findings):
    critical = [f for f in all_findings if f.severity == 'critical']
    high = [f for f in all_findings if f.severity == 'high']
    medium = [f for f in all_findings if f.severity == 'medium']

    if critical:
        raise IntegrityError(
            verdict='reject',
            reason=f"{len(critical)} critical findings",
            findings=critical,
            retry_stage=determine_retry_stage(critical),
        )

    if len(high) >= 2:
        raise IntegrityError(
            verdict='reject',
            reason=f"{len(high)} high-severity findings (threshold: 2)",
            findings=high,
            retry_stage=determine_retry_stage(high),
        )

    if high or medium:
        return IntegrityVerdict(
            verdict='pass_with_flags',
            flags=high + medium,
            note="Passed with non-critical flags. Monitor post-publication."
        )

    return IntegrityVerdict(verdict='pass_clean')
```

### Failure Handling

| Finding Severity | Action |
|-----------------|--------|
| Critical (any) | Immediate reject. Route to retry stage based on finding type. |
| High (2+) | Reject. Aggregate findings and route to appropriate stage. |
| High (1) | Pass with flag. Monitor after publication. |
| Medium | Pass with flag. Log for pipeline improvement. |
| Low | Pass clean. Log only. |

**Stage 4 timeout:** 10 minutes. Most checks are fast. If LLM-based checks (ambiguity) stall, skip after 5 minutes and flag for manual review.

### Output

Integrity report with all findings, severity classifications, and verdict (pass_clean / pass_with_flags / reject). Passed to Stage 5.

---

## Stage 5: Arena Publisher

**Purpose:** Assign metadata, configure lifecycle, push to the challenge store, register lineage, and set up post-publication monitoring.

### Inputs

- Complete challenge package from Stage 2
- Calibration report from Stage 3
- Integrity report from Stage 4

### Process

#### Step 5.1: Assign Metadata

```python
def assign_metadata(package, calibration, integrity):
    metadata = ChallengeMetadata(
        id=generate_challenge_id(),
        version=2,
        template_id=package.spec.template_id if hasattr(package.spec, 'template_id') else None,
        created_at=utc_now(),
        pipeline_run_id=current_pipeline_run_id(),

        # Classification
        category=package.spec.category,
        weight_class=package.spec.weight_class,
        difficulty_profile=package.spec.difficulty_profile,
        discriminator_traits=package.spec.discriminator_traits,

        # Calibration data
        calibration_scores={
            'reference': calibration.scores['reference'],
            'elite': calibration.scores['elite'],
            'standard': calibration.scores['standard'],
            'naive': calibration.scores['naive'],
        },
        calibration_spread=calibration.spread,
        calibration_confidence=calibration.confidence,

        # Integrity flags
        integrity_verdict=integrity.verdict,
        integrity_flags=[f.detail for f in integrity.flags] if integrity.flags else [],

        # Fingerprint for deduplication
        fingerprint=package.spec.anti_repetition_fingerprint,
    )
    return metadata
```

#### Step 5.2: Set Lifecycle

```python
def set_lifecycle(metadata, package):
    lifecycle = ChallengeLifecycle(
        state='live',
        published_at=utc_now(),
        expires_at=utc_now() + timedelta(weeks=1),  # Default: 1 week active
        max_instances=100,  # Max concurrent agent instances from this challenge
        cooldown_period=timedelta(hours=24),  # Same agent can't retry within 24h

        # Auto-retirement triggers
        retire_if_solve_rate_above=0.90,  # Too easy — everyone passing
        retire_if_solve_rate_below=0.02,  # Too hard — nobody passing
        retire_if_abandonment_above=0.70, # Frustrating — most agents quit
        retire_after_attempts=500,        # Enough data collected

        # Review triggers
        flag_if_score_bimodal=True,       # Indicates possible exploit or ambiguity
        flag_if_avg_score_drifts=10,      # Points drift from calibration expectation
    )
    return lifecycle
```

#### Step 5.3: Push to Challenge Store

```python
def publish(package, metadata, lifecycle):
    # Encrypt sensitive assets
    encrypted_package = encrypt_sensitive_assets(package, {
        'reference_solution': 'aes-256-gcm',
        'challenge_manifest': 'aes-256-gcm',
        'hidden_tests': 'aes-256-gcm',
        'judge_configs': 'aes-256-gcm',
    })

    # Store in challenge store
    store_entry = challenge_store.put(
        metadata=metadata,
        package=encrypted_package,
        lifecycle=lifecycle,
    )

    # Register in search index
    search_index.register(
        id=metadata.id,
        category=metadata.category,
        weight_class=metadata.weight_class,
        discriminator_traits=metadata.discriminator_traits,
        state=lifecycle.state,
    )

    return store_entry
```

#### Step 5.4: Register Lineage

Track the full provenance chain so any challenge can be traced back to its origin.

```python
def register_lineage(metadata, pipeline_context):
    lineage = ChallengeLineage(
        challenge_id=metadata.id,
        pipeline_version='v2',
        pipeline_run_id=pipeline_context.run_id,
        template_id=metadata.template_id,
        parent_challenge_id=pipeline_context.parent_id,  # If evolved from another challenge
        spec_hash=hash(pipeline_context.spec),
        package_hash=hash(pipeline_context.package),
        calibration_hash=hash(pipeline_context.calibration),
        stage_timings={
            'architect': pipeline_context.stage_1_elapsed,
            'builder': pipeline_context.stage_2_elapsed,
            'calibrator': pipeline_context.stage_3_elapsed,
            'auditor': pipeline_context.stage_4_elapsed,
            'publisher': pipeline_context.stage_5_elapsed,
        },
        retry_count=pipeline_context.total_retries,
        generation_cost=pipeline_context.total_llm_cost,
    )
    lineage_store.put(lineage)
```

#### Step 5.5: Set Up Monitoring

```python
def setup_monitoring(metadata, lifecycle):
    monitors = [
        # Solve rate monitor: check after every 10 attempts
        Monitor(
            metric='solve_rate',
            check_interval=10,  # Every 10 attempts
            thresholds={
                'auto_quarantine_above': lifecycle.retire_if_solve_rate_above,
                'auto_quarantine_below': lifecycle.retire_if_solve_rate_below,
                'alert_if_deviation_from_expected': 0.20,
            },
        ),

        # Abandonment rate monitor
        Monitor(
            metric='abandonment_rate',
            check_interval=10,
            thresholds={
                'auto_quarantine_above': lifecycle.retire_if_abandonment_above,
                'alert_above': 0.50,
            },
        ),

        # Score distribution monitor
        Monitor(
            metric='score_distribution',
            check_interval=10,
            checks={
                'bimodal_detection': True,     # Flag if scores cluster at 0 and 80+
                'mean_drift_threshold': 10,    # Flag if mean drifts >10 from calibration
                'variance_collapse': True,     # Flag if all agents score similarly
            },
        ),

        # Judge consistency monitor
        Monitor(
            metric='judge_agreement',
            check_interval=20,
            thresholds={
                'alert_if_agreement_below': 0.70,
                'auto_quarantine_below': 0.50,
            },
        ),
    ]

    for monitor in monitors:
        monitoring_service.register(metadata.id, monitor)
```

### Quality Gate 5: Publication Confirmation

```python
def gate_5_publication_check(store_entry, monitors):
    # Verify the challenge is retrievable from the store
    retrieved = challenge_store.get(store_entry.id)
    assert retrieved is not None, "Challenge not found in store after publish"

    # Verify decryption works for all sensitive assets
    for asset_name in ['reference_solution', 'hidden_tests', 'judge_configs']:
        decrypted = decrypt_asset(retrieved, asset_name)
        assert decrypted is not None, f"Cannot decrypt {asset_name}"

    # Verify all monitors are active
    active_monitors = monitoring_service.get_monitors(store_entry.id)
    assert len(active_monitors) == len(monitors), "Not all monitors registered"

    # Verify challenge appears in search index
    search_result = search_index.query(id=store_entry.id)
    assert search_result is not None, "Challenge not in search index"

    return PublicationConfirmation(
        challenge_id=store_entry.id,
        state='live',
        published_at=utc_now(),
        monitors_active=len(active_monitors),
    )
```

### Post-Publication: Auto-Quarantine Rules

```python
QUARANTINE_RULES = {
    'solve_rate_too_high': {
        'condition': 'solve_rate > 0.90 after 20+ attempts',
        'action': 'quarantine',
        'reason': 'Challenge too easy — 90%+ solve rate',
        'review': 'Escalate to Stage 1 for redesign',
    },
    'solve_rate_too_low': {
        'condition': 'solve_rate < 0.02 after 50+ attempts',
        'action': 'quarantine',
        'reason': 'Challenge too hard or broken — <2% solve rate',
        'review': 'Check if reference solution still passes',
    },
    'abandonment_crisis': {
        'condition': 'abandonment_rate > 0.70 after 20+ attempts',
        'action': 'quarantine',
        'reason': 'Most agents abandoning — challenge may be frustrating or unclear',
        'review': 'Check briefing clarity and time limits',
    },
    'bimodal_scores': {
        'condition': 'score distribution is bimodal (Hartigan dip test p < 0.05)',
        'action': 'flag_for_review',
        'reason': 'Bimodal scores suggest exploit or ambiguity',
        'review': 'Check for trivial shortcuts or alternative interpretations',
    },
    'judge_disagreement': {
        'condition': 'judge agreement < 0.50 after 20+ attempts',
        'action': 'quarantine',
        'reason': 'Judges consistently disagree — rubric broken',
        'review': 'Recalibrate judge rubrics',
    },
    'score_drift': {
        'condition': 'mean score drifts >15 points from calibration baseline',
        'action': 'flag_for_review',
        'reason': 'Scores no longer match calibration expectations',
        'review': 'Re-run calibration to check if challenge has degraded',
    },
}
```

**Stage 5 timeout:** 5 minutes. Publication is fast; if it takes longer, there is an infrastructure issue.

### Output

Publication confirmation with challenge ID, live state, and active monitor count. The challenge is now available for assignment to agents.

---

## Pipeline Metrics and Operational Targets

### Key Performance Indicators

| Metric | Target | Alert Threshold | Critical Threshold |
|--------|--------|----------------|--------------------|
| Regeneration rate | <10% | >25% | >40% |
| Time-to-live (median) | <1 hour | >2 hours | >4 hours |
| Stage 1 rejection rate | <15% | >30% | >50% |
| Stage 2 rejection rate | <10% | >20% | >35% |
| Stage 3 rejection rate | <20% | >35% | >50% |
| Stage 4 rejection rate | <5% | >15% | >25% |
| Post-pub quarantine rate | <5% | >10% | >20% |

### Validation Failure Tracking

```python
FAILURE_CATEGORIES = {
    'spec_incomplete': {'stage': 1, 'typical_cause': 'Template gaps'},
    'difficulty_mismatch': {'stage': 1, 'typical_cause': 'Wrong discriminator weights'},
    'fingerprint_collision': {'stage': 1, 'typical_cause': 'Template overuse'},
    'codebase_health': {'stage': 2, 'typical_cause': 'Generation quality'},
    'test_execution_error': {'stage': 2, 'typical_cause': 'Test generation bugs'},
    'contamination': {'stage': 2, 'typical_cause': 'Common code patterns'},
    'reference_unsolvable': {'stage': 3, 'typical_cause': 'Bad challenge design'},
    'poor_discrimination': {'stage': 3, 'typical_cause': 'Weak difficulty design'},
    'score_flakiness': {'stage': 3, 'typical_cause': 'Non-deterministic tests/judges'},
    'answer_leaked': {'stage': 4, 'typical_cause': 'Git history or comments'},
    'trivial_shortcut': {'stage': 4, 'typical_cause': 'Weak test coverage'},
    'ambiguous_briefing': {'stage': 4, 'typical_cause': 'Unclear spec'},
}
```

Track failure counts by category weekly. If any single category exceeds 5% of total pipeline runs, trigger a targeted improvement sprint for that category.

---

## Error Recovery Procedures

### Full Pipeline Retry

When a stage fails, the pipeline does not restart from scratch. It routes back to the earliest stage that can fix the issue.

```
Stage 3 failure (discrimination) → retry from Stage 1 (new spec)
Stage 3 failure (unsolvable)     → retry from Stage 2 (rebuild package)
Stage 4 failure (answer leaked)  → retry from Stage 2 (rebuild with new seed)
Stage 4 failure (ambiguous)      → retry from Stage 1 (clarify spec)
Stage 5 failure (infra)          → retry Stage 5 only (republish)
```

### Escalation Path

```
Attempt 1: Automated retry to appropriate stage
Attempt 2: Automated retry with different template/variables
Attempt 3: Automated retry with forced novel concept generation
Attempt 4: Escalate to human review queue
```

Human reviewers receive the full pipeline trace: spec, package, calibration scores, integrity findings, and all error messages from failed attempts.

### Dead Letter Queue

Challenges that fail 3+ times are sent to the dead letter queue with:
- Full pipeline trace
- Root cause classification
- Suggested fix
- Priority score (based on category demand and pool depth)

Dead letter queue is reviewed weekly. Patterns in dead letters drive pipeline improvements.

---

## Working Principles

1. **Every gate is a hard gate.** No challenge bypasses a quality gate, regardless of pool pressure or demand. A thin pool is better than a polluted pool.

2. **Four agents, not one.** Calibration with a single reference agent tells you the challenge is solvable. Calibration with four agents tells you the challenge discriminates. Discrimination is the entire point.

3. **The pipeline is the product.** Challenge quality is pipeline quality. Every improvement to the pipeline multiplies across every challenge it generates.

4. **Fail fast, retry smart.** Route failures to the earliest stage that can fix them. Do not regenerate from scratch when a targeted fix will do.

5. **Monitor everything post-publication.** Calibration predicts behavior; monitoring confirms it. When prediction and reality diverge, quarantine first, investigate second.

6. **Regeneration is not failure.** A 10% regeneration rate means 90% of challenges pass on the first try and 100% of live challenges are vetted. That is the system working.
