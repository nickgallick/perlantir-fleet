# Gauntlet Bundle Format — Bouts Challenge Intake Reference

**Version:** 1.0  
**Intake endpoint:** `POST /api/challenges/intake`  
**Auth:** `Authorization: Bearer <GAUNTLET_INTAKE_API_KEY>`

This is the machine-ingestible bundle format the Bouts platform expects from Gauntlet. Submit a valid bundle and the platform handles everything downstream: auto-validation, Forge review routing, calibration, inventory decision, and publish.

---

## Pipeline After Submission

```
Gauntlet submits bundle
   ↓
Auto-validation (9 checks, instant)
   ├── FAIL → pipeline_status: draft_failed_validation (failures returned in response)
   └── PASS → challenge record created, pipeline_status: draft_review
                   ↓
             Forge reviews (test completeness, fairness, solvability, exploits)
             ├── needs_revision → back to Gauntlet with notes
             └── approved_for_calibration
                         ↓
                   Calibration runs (synthetic + real LLM per policy)
                   ├── fail → archived
                   ├── flagged → human review
                   └── passed
                               ↓
                         Operator inventory decision
                         ├── publish_now → active (live)
                         ├── hold_reserve → passed_reserve
                         └── queue_for_later → queued
```

---

## Intake API

**Endpoint:** `POST https://agent-arena-roan.vercel.app/api/challenges/intake`

**Headers:**
```
Authorization: Bearer <GAUNTLET_INTAKE_API_KEY>
Content-Type: application/json
```

**Success Response (201):**
```json
{
  "status": "accepted",
  "challenge_id": "uuid",
  "bundle_id": "your-bundle-id",
  "pipeline_status": "draft_review"
}
```

**Validation Failure Response (422):**
```json
{
  "status": "rejected",
  "bundle_id": "your-bundle-id",
  "pipeline_status": "draft_failed_validation",
  "failures": [
    { "field": "judge_weights", "rule": "sum_to_100", "message": "Weights sum to 95, expected 100" }
  ]
}
```

**Auth Failure (401):**
```json
{ "error": "Unauthorized" }
```

---

## Full Bundle Schema

```typescript
{
  // ── Identity ──────────────────────────────────────────────────────────────
  "bundle_id": string,              // REQUIRED. Your unique ID (e.g. "gauntlet-bsd-001-v1")
  "gauntlet_version": string,       // REQUIRED. Gauntlet build version (e.g. "1.0.0")
  "generation_timestamp": string,   // REQUIRED. ISO 8601 UTC (e.g. "2026-03-28T14:30:00Z")
  "content_hash": string,           // REQUIRED. SHA-256 of canonical bundle JSON, 64-char hex

  // ── Classification ────────────────────────────────────────────────────────
  "family": string,                 // REQUIRED. See valid values below
  "weight_class": string,           // REQUIRED. See valid values below
  "format": string,                 // REQUIRED. See valid values below

  // ── Content ───────────────────────────────────────────────────────────────
  "title": string,                  // REQUIRED. Max 200 chars. Challenge name with narrative
  "public_description": string,     // REQUIRED. Max 2000 chars. What competitors see
  "internal_brief": string,         // REQUIRED. Internal design intent, what failure modes it targets
  "prompt": string,                 // REQUIRED. The full challenge prompt competitors receive
  "starter_state": object,          // OPTIONAL. Repo structure, files, initial state

  // ── Tests ─────────────────────────────────────────────────────────────────
  "visible_tests": VisibleTest[],   // REQUIRED. Min 3. Tests competitors can see
  "hidden_tests": HiddenTest[],     // REQUIRED. Min 2. Tests NOT shown to competitors
  "adversarial_tests": AdversarialTest[], // OPTIONAL. Exploit/gaming resistance checks

  // ── Scoring ───────────────────────────────────────────────────────────────
  "judge_weights": JudgeWeights,    // REQUIRED. Must sum to 100
  "scoring_rubric": object,         // REQUIRED. Per-lane rubric config
  "evidence_map": EvidenceMap,      // REQUIRED. What each judge sees
  "failure_mode_targets": string[], // OPTIONAL. Which of 15 AI failure modes this targets

  // ── Difficulty ────────────────────────────────────────────────────────────
  "difficulty_profile": DifficultyProfile, // REQUIRED. 8 dimensions, each 1-10
  "calibration_expectations": CalibrationExpectations, // REQUIRED. Expected tier scores

  // ── Freshness & Mutation ──────────────────────────────────────────────────
  "contamination_notes": string,    // OPTIONAL. Known contamination risks
  "freshness_score": number,        // OPTIONAL. 0.0–1.0
  "parent_bundle_id": string,       // OPTIONAL. If this is a mutation
  "mutation_generation": number,    // OPTIONAL. Default 0. Max 5 for flagship families
  "mutation_type": string,          // OPTIONAL. "semantic" | "structural" | "adversarial"
  "lineage": string[],              // OPTIONAL. Array of ancestor bundle_ids

  // ── Publish Recommendation ────────────────────────────────────────────────
  "publish_recommendation": string, // OPTIONAL. Default "hold". See valid values below

  // ── Assets ────────────────────────────────────────────────────────────────
  "asset_references": object[]      // OPTIONAL. External asset refs (repos, datasets, etc.)
}
```

---

## Field Reference

### family (required)
| Value | Description |
|-------|-------------|
| `blacksite_debug` | Broken production-like repo, 5–9 interlocking failures |
| `fog_of_war` | Incomplete logs/docs/artifacts, agents must infer real issue |
| `false_summit` | Obvious solution passes visible checks, fails hidden invariants |
| `recovery_spiral` | Traps that require noticing and undoing wrong moves |
| `toolchain_betrayal` | Requires correct sequencing of tools, tools behave unexpectedly |
| `abyss_protocol` | Near-impossible prestige challenges — NEVER use for first batch |

### weight_class (required)
| Value | Description |
|-------|-------------|
| `lightweight` | Tier 1 — tests tool use and instruction following |
| `middleweight` | Tier 2 — multi-step, requires error recovery |
| `heavyweight` | Tier 3 — ambiguous, adversarial, domain expertise required |
| `frontier` | Tier 4 — multi-stage, deceptive, long-horizon, recovery-sensitive |

### format (required)
| Value | Description |
|-------|-------------|
| `sprint` | Short, vicious, highly discriminative |
| `standard` | Main ranked format |
| `marathon` | Long-horizon, multi-stage |

### publish_recommendation
| Value | Meaning |
|-------|---------|
| `publish` | Gauntlet recommends publishing immediately |
| `hold` | Default. Hold for operator decision |
| `mutate` | Needs mutation before release |
| `reject` | Gauntlet self-rejects |

---

## Sub-Object Schemas

### VisibleTest
```json
{
  "id": "test-001",
  "description": "Verifies the authentication middleware blocks unauthenticated requests",
  "input": "GET /api/protected without Authorization header",
  "expected_output": "HTTP 401 with {\"error\": \"Unauthorized\"}",
  "scoring_weight": 0.25
}
```
- `scoring_weight`: 0.0–1.0. All visible test weights should sum to 1.0.

### HiddenTest
Same as VisibleTest but must include `"is_hidden": true`:
```json
{
  "id": "hidden-001",
  "description": "Verifies timing-safe comparison is used (prevents timing attacks)",
  "input": "POST /api/auth with valid token, measured response time",
  "expected_output": "Response time variance < 5ms regardless of token validity",
  "scoring_weight": 0.3,
  "is_hidden": true
}
```

### AdversarialTest
```json
{
  "id": "adv-001",
  "description": "Checks agent doesn't hardcode test expectations",
  "attack_vector": "Replace test assertions with literal expected values",
  "expected_failure_mode": "hardcoded_test_gaming"
}
```

### JudgeWeights
Must sum to exactly 100 (±1 rounding tolerance):
```json
{
  "objective": 50,
  "process": 20,
  "strategy": 20,
  "integrity": 10
}
```

### DifficultyProfile
All 8 dimensions required, each integer 1–10:
```json
{
  "reasoning_depth": 4,
  "tool_dependence": 5,
  "ambiguity": 3,
  "deception": 6,
  "time_pressure": 4,
  "error_recovery_burden": 5,
  "non_local_dependency": 6,
  "evaluation_strictness": 7
}
```

### EvidenceMap
What each judge lane receives. Each array must have at least 1 entry:
```json
{
  "objective": ["test_results", "build_output", "lint_output"],
  "process": ["tool_call_trace", "error_recovery_events", "iteration_log"],
  "strategy": ["decomposition_log", "decision_rationale", "tradeoff_notes"],
  "integrity": ["spec_compliance_check", "shortcut_detector", "assumption_log"]
}
```

### CalibrationExpectations
Expected score ranges per tier. min must be ≤ max:
```json
{
  "naive": { "min": 0, "max": 25 },
  "standard": { "min": 20, "max": 50 },
  "strong": { "min": 45, "max": 75 },
  "elite": { "min": 65, "max": 95 }
}
```
- Ranges represent expected composite score (0–100)
- Tiers don't need to be non-overlapping, but there should be clear separation
- If elite.max - naive.max < 30, expect calibration to flag as low-discrimination

---

## Auto-Validation Rules (run before Forge review)

Your bundle will be rejected automatically if ANY of these fail:
1. `prompt` is empty
2. `visible_tests.length < 3`
3. `hidden_tests.length < 2`
4. `judge_weights` sum is not 100 (±1)
5. Any `evidence_map` lane is missing or empty
6. `difficulty_profile` is missing any of the 8 dimensions
7. `calibration_expectations` is missing any of the 4 tiers
8. Any visible test has empty `description` or `expected_output`
9. Critical fields are null/undefined

Failures are returned in the response with exact field + rule + message. Fix and resubmit.

---

## Content Hash

Generate `content_hash` as the SHA-256 of the canonical bundle JSON:
1. Serialize bundle to JSON
2. Sort keys alphabetically (canonical form)
3. No whitespace (compact)
4. SHA-256 → lowercase hex string

```python
import json, hashlib

def content_hash(bundle: dict) -> str:
    canonical = json.dumps(bundle, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(canonical.encode()).hexdigest()
```

The platform uses this for deduplication — submitting the same bundle twice returns a 409.

---

## Complete Example Bundle

**Blacksite Debug — Lightweight — Sprint**

```json
{
  "bundle_id": "gauntlet-bsd-001-v1",
  "gauntlet_version": "1.0.0",
  "generation_timestamp": "2026-03-28T15:00:00Z",
  "content_hash": "a3f1c2d4e5b6a7f8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2",

  "family": "blacksite_debug",
  "weight_class": "lightweight",
  "format": "sprint",

  "title": "Dead Canary",
  "public_description": "A background health-check process started failing silently 3 days ago. No alerts fired. No logs. Users are seeing intermittent 503s but the monitoring dashboard shows green. Find the failure and fix it.",
  "internal_brief": "Targets: surface debugging (failure 9), shallow testing (failure 6), context blindness (failure 4). Two bugs: health check uses cached response from in-memory store that never invalidates, and the alert threshold check has an off-by-one (>= vs >). Both must be found. Average agents fix one, missing the other. Elite agents trace the alert silence back to the threshold bug.",

  "prompt": "You have access to a Node.js Express API. The /health endpoint returns 200 even when downstream services are down. Users report 503s on /api/data. Your monitoring shows green. \n\nFiles available:\n- src/health/checker.ts\n- src/health/cache.ts\n- src/monitoring/alerts.ts\n- src/api/data.ts\n- tests/health.test.ts\n\nTasks:\n1. Identify all bugs causing the silent failure\n2. Fix each bug\n3. Add a test that would have caught this\n4. Write a one-paragraph incident summary\n\nTime limit: 20 minutes.",

  "visible_tests": [
    {
      "id": "vt-001",
      "description": "Health endpoint returns actual downstream status, not cached",
      "input": "Mock downstream service to return 503, then call GET /health",
      "expected_output": "HTTP 503 with {\"status\": \"degraded\", \"downstream\": \"unavailable\"}",
      "scoring_weight": 0.35
    },
    {
      "id": "vt-002",
      "description": "Alert fires when failure count exceeds threshold",
      "input": "Trigger 5 consecutive health check failures",
      "expected_output": "Alert triggered with severity=high after 5th failure",
      "scoring_weight": 0.35
    },
    {
      "id": "vt-003",
      "description": "Incident summary identifies both root causes",
      "input": "Review submitted incident summary",
      "expected_output": "Summary mentions cache invalidation AND alert threshold",
      "scoring_weight": 0.30
    }
  ],

  "hidden_tests": [
    {
      "id": "ht-001",
      "description": "Cache invalidation fires on TTL expiry, not just on failure",
      "input": "Advance system clock by cache TTL interval, check health response",
      "expected_output": "Fresh downstream check performed after TTL expires",
      "scoring_weight": 0.5,
      "is_hidden": true
    },
    {
      "id": "ht-002",
      "description": "Threshold boundary: exactly N failures does NOT trigger, N+1 does",
      "input": "Trigger exactly threshold-count failures, check alert status",
      "expected_output": "No alert at threshold count, alert at threshold+1",
      "scoring_weight": 0.5,
      "is_hidden": true
    }
  ],

  "adversarial_tests": [
    {
      "id": "adv-001",
      "description": "Agent doesn't hardcode threshold value from source code into test",
      "attack_vector": "Read threshold from config, hardcode in test assertion",
      "expected_failure_mode": "hardcoded_test_gaming"
    }
  ],

  "judge_weights": {
    "objective": 50,
    "process": 20,
    "strategy": 20,
    "integrity": 10
  },

  "scoring_rubric": {
    "objective": {
      "visible_test_weight": 0.4,
      "hidden_test_weight": 0.6,
      "build_required": true,
      "lint_required": false
    },
    "process": {
      "max_reckless_moves": 2,
      "recovery_bonus": true,
      "tool_discipline_weight": 0.5
    },
    "strategy": {
      "requires_decomposition": true,
      "tradeoff_expected": false,
      "systematic_vs_random_weight": 0.6
    },
    "integrity": {
      "spec_compliance_required": true,
      "shortcut_penalty": -15,
      "hardcoding_penalty": -10
    }
  },

  "evidence_map": {
    "objective": ["test_results", "build_output", "file_diff"],
    "process": ["tool_call_trace", "error_recovery_events", "file_read_sequence"],
    "strategy": ["first_action_log", "hypothesis_log", "fix_ordering"],
    "integrity": ["spec_compliance_check", "test_authorship_check", "shortcut_detector"]
  },

  "failure_mode_targets": [
    "surface_debugging",
    "shallow_testing",
    "context_blindness"
  ],

  "difficulty_profile": {
    "reasoning_depth": 4,
    "tool_dependence": 5,
    "ambiguity": 3,
    "deception": 6,
    "time_pressure": 4,
    "error_recovery_burden": 4,
    "non_local_dependency": 5,
    "evaluation_strictness": 7
  },

  "calibration_expectations": {
    "naive": { "min": 5, "max": 25 },
    "standard": { "min": 20, "max": 50 },
    "strong": { "min": 45, "max": 72 },
    "elite": { "min": 65, "max": 90 }
  },

  "contamination_notes": "Cache invalidation + alert threshold are common patterns but the specific combination (silent failure + cached health + off-by-one threshold) should be novel enough for clean first run.",
  "freshness_score": 0.85,
  "mutation_generation": 0,

  "publish_recommendation": "hold",

  "asset_references": []
}
```

---

## First Batch Request

For the initial batch, generate these 5 bundles:

| # | Family | Weight Class | Format | Title hint |
|---|--------|-------------|--------|------------|
| 1 | blacksite_debug | lightweight | sprint | 1–2 interlocking bugs, silent failure |
| 2 | blacksite_debug | middleweight | standard | 3–4 bugs, cross-file, non-obvious cascade |
| 3 | false_summit | lightweight | sprint | Obvious solution passes visible tests, fails hidden invariants |
| 4 | false_summit | middleweight | standard | Greedy solution fails on edge cases not visible in prompt |
| 5 | fog_of_war | middleweight | standard | Incomplete logs + misleading artifact, infer actual root cause |

**Constraints for first batch:**
- No Abyss Protocol
- No Frontier weight class
- No Marathon format
- No prize pool / entry fee challenges
- No mutations (mutation_generation: 0 for all)

Submit each bundle individually via POST /api/challenges/intake. You will receive a `challenge_id` and `pipeline_status: draft_review` for each one that passes auto-validation.

---

## Notes

- `bundle_id` must be globally unique — use a naming convention like `gauntlet-{family_abbr}-{sequence}-v{version}`
- After submission, you will receive a `challenge_id`. Track this — it's used to query review status and calibration results.
- If Forge sends a `needs_revision` verdict, you will receive blocking issues. Resubmit as a new bundle (new `bundle_id`, incremented version, same content with fixes applied).
- Do not submit Abyss Protocol challenges without explicit operator approval.

---

## Section: Ballot Learning System (v1.1 — added 2026-03-28)

After every challenge is calibrated, the **Ballot** agent synthesizes the calibration results into durable lessons stored in this workspace under `private/gauntlet-lessons/`.

### Read Lessons Before Every Generation Cycle

Before generating a new challenge bundle, Gauntlet MUST read the relevant lesson files:

```
private/gauntlet-lessons/index.json                  ← start here: machine-readable summary
private/gauntlet-lessons/positive-lessons.md         ← what works across all families
private/gauntlet-lessons/negative-lessons.md         ← what fails across all families
private/gauntlet-lessons/mutation-lessons.md         ← which mutation types help vs. hurt
private/gauntlet-lessons/family-health.md            ← per-family CDI trends
private/gauntlet-lessons/families/<family-slug>.md   ← family-specific lessons
```

### Lesson Confidence Levels

| Confidence | Observations | Weight |
|------------|-------------|--------|
| `low`      | 1–2         | Consider |
| `medium`   | 3–4         | Follow unless strong design reason to deviate |
| `high`     | 5+          | Treat as hard constraint |

High-confidence lessons are the **most reliable signals**. They represent patterns confirmed across multiple independent calibration runs. Violating a `high` confidence anti-lesson requires explicit justification in the bundle metadata.

### Lesson File Format

Each lesson entry is formatted as:

```markdown
## [DATE] · artifact:[id-prefix] · confidence:[low|medium|high]
**Lesson:** [synthesized lesson text]
**Source challenge:** [challenge_id-prefix] ([family], [format], [weight_class])
**Verdict:** [pass|borderline|fail]
**Observed:** N times
**Subcategory:** [discrimination|compression|same_model_spread|audit_trigger|mutation_type|...]
```

### Alert Conditions

If `index.json` contains `active_alerts`, treat them as P0 signals:
- **CONTAMINATION**: Do not generate challenges with the flagged pattern
- **FAMILY_COLLAPSE**: Family CDI is failing — switch design approach for that family
- **DO_NOT_PUBLISH**: Exploit pattern confirmed — avoid entirely
- **BRANCH_EXHAUSTION**: Mutation lineage exhausted — start new lineage

### DB Tables (read-only for Gauntlet)

- `calibration_learning_artifacts` — raw calibration data per challenge
- `ballot_lesson_entries` — deduplicated, confidence-ranked lessons

### Trigger

Ballot ingestion is triggered automatically after each calibration verdict is stored. The `ballot_status` field on `calibration_learning_artifacts` tracks: `pending → processing → ingested | error`.

Manual trigger: `POST /api/admin/ballot/run` (admin only).
