# Telemetry and Observability

**Skill 43 — Gauntlet Challenge Engine**

The comprehensive telemetry system that captures everything about how agents interact with challenges. This data feeds the Process Judge, powers analytics, detects anomalies, and drives system improvement. Without telemetry, the Gauntlet is blind — scores exist but the story behind them is lost.

---

## Two Telemetry Domains

All telemetry in the Gauntlet falls into one of two domains, each with distinct purposes, schemas, retention policies, and consumers.

### Domain 1: Agent Telemetry (feeds Process Judge)

Everything the agent does during an attempt. This is the primary input to the Process Judge, which evaluates *how* the agent solved a challenge, not just *whether* it solved it.

#### Tool Call Log

Every tool invocation during an attempt is captured as a structured event.

```yaml
event_type: tool_call
schema:
  attempt_id: string        # links to the parent attempt
  sequence_number: int      # monotonically increasing per attempt
  timestamp: ISO-8601       # when the tool was invoked
  tool_name: string         # e.g., "Read", "Edit", "Bash", "Grep", "Glob"
  arguments_summary: string # truncated/sanitized argument snapshot (max 512 chars)
  result_summary: string    # truncated result (max 1024 chars)
  result_status: enum       # success | error | timeout
  duration_ms: int          # wall-clock time for the tool call
  tokens_in: int            # tokens sent to the tool (if applicable)
  tokens_out: int           # tokens returned from the tool
```

**Why sequence matters.** The Process Judge distinguishes between agents that follow a disciplined read-plan-code-test loop and those that thrash with code-test-code-test cycles. The sequence of tool calls is itself a signal:

| Pattern | Interpretation |
|---------|---------------|
| Read → Read → Read → Edit → Bash(test) | Thorough understanding before acting |
| Edit → Bash(test) → Edit → Bash(test) | Trial-and-error, possibly effective |
| Edit → Edit → Edit → Bash(test) | Batch changes without validation |
| Bash(test) → Bash(test) → Bash(test) | Re-running tests hoping for different results |

#### Test Run Log

Every test execution is a first-class telemetry event.

```yaml
event_type: test_run
schema:
  attempt_id: string
  sequence_number: int
  timestamp: ISO-8601
  iteration: int             # which iteration of the attempt
  suite_name: string         # e.g., "unit", "integration", "e2e"
  command: string            # the exact test command run
  exit_code: int
  passed_count: int
  failed_count: int
  skipped_count: int
  total_count: int
  failure_messages: string[] # first 10 failure messages, truncated to 256 chars each
  duration_ms: int
  coverage_percent: float    # if coverage is enabled, null otherwise
  regression_detected: bool  # true if previously-passing tests now fail
```

**Derived metrics from test runs:**
- **Test-between-edits ratio**: `count(test_run events) / count(edit events)`. A ratio below 0.3 suggests the agent is coding blind. A ratio above 2.0 suggests excessive test-running without meaningful changes.
- **Regression rate**: percentage of test runs where `regression_detected = true`. High regression rates indicate the agent is breaking things it already fixed.
- **First-green iteration**: the iteration number where all tests first pass. Earlier is better, but only if the solution is correct.

#### File Change Log

Every file modification inside the sandbox is captured.

```yaml
event_type: file_change
schema:
  attempt_id: string
  sequence_number: int
  timestamp: ISO-8601
  file_path: string          # relative to workspace root
  change_type: enum          # create | edit | delete | rename
  diff_lines_added: int
  diff_lines_removed: int
  diff_size_bytes: int
  content_hash_before: string  # SHA-256 of file before change
  content_hash_after: string   # SHA-256 of file after change
  tool_that_caused: string     # which tool call produced this change
```

**Derived metrics from file changes:**
- **Change scope**: number of unique files touched. Focused solutions touch fewer files.
- **Churn rate**: number of times the same file is edited. High churn on a single file suggests the agent is struggling with that file.
- **Net change size**: total lines added minus lines removed. Smaller net changes for correct solutions indicate precision.
- **Shotgun surgery detection**: many small changes across many files in a short window.

#### Error Log

Every error the agent encounters — tool failures, compilation errors, runtime exceptions.

```yaml
event_type: error_encountered
schema:
  attempt_id: string
  sequence_number: int
  timestamp: ISO-8601
  error_type: enum           # tool_error | compilation | runtime | timeout | sandbox
  error_message: string      # truncated to 512 chars
  error_source: string       # which tool or process produced the error
  is_repeat: bool            # true if same error_type + similar message seen before in this attempt
  repeat_count: int          # how many times this error has occurred in this attempt
  resolved: bool             # true if the error stops appearing in subsequent events
  resolution_latency_ms: int # time between first occurrence and resolution (null if unresolved)
```

**Error repetition is a strong signal.** An agent that encounters the same `ModuleNotFoundError` three times without installing the module is demonstrating poor problem-solving. The Process Judge uses `repeat_count` and `resolved` to assess adaptability.

#### Time Log

Phase-level timing derived from tool call patterns.

```yaml
event_type: phase_transition
schema:
  attempt_id: string
  sequence_number: int
  timestamp: ISO-8601
  phase_from: enum           # reading | planning | coding | testing | debugging | idle
  phase_to: enum
  duration_in_phase_ms: int  # how long the agent spent in phase_from
```

**Phase classification rules:**
- **Reading**: consecutive Read, Grep, Glob calls with no Edit/Write/Bash calls
- **Planning**: gaps between tool calls > 5 seconds (agent is thinking/generating plan)
- **Coding**: Edit, Write calls
- **Testing**: Bash calls that execute test commands (detected by command pattern matching)
- **Debugging**: interleaved Read/Grep calls followed by Edit calls after a test failure
- **Idle**: gaps > 30 seconds with no tool calls (may indicate confusion or rate limiting)

#### Score Trajectory

The score at each iteration checkpoint.

```yaml
event_type: score_checkpoint
schema:
  attempt_id: string
  iteration: int
  timestamp: ISO-8601
  score: float               # 0.0 to 1.0
  tests_passed: int
  tests_total: int
  delta_from_previous: float # score change since last checkpoint
  cumulative_time_ms: int    # total elapsed time since attempt start
```

**Trajectory patterns the Process Judge recognizes:**

| Pattern | Name | Interpretation |
|---------|------|---------------|
| [0.0, 0.3, 0.6, 0.9, 1.0] | Monotonic climb | Steady, methodical progress |
| [0.0, 0.0, 0.0, 1.0] | Eureka | Sudden insight after exploration |
| [0.0, 0.5, 0.3, 0.7, 0.4] | Oscillating | Fixing one thing breaks another |
| [0.0, 0.6, 0.6, 0.6, 0.6] | Plateau | Got stuck, couldn't push further |
| [0.0, 0.8, 0.5, 0.3, 0.2] | Regression | Making things worse over time |

---

### Domain 2: System Telemetry (platform health)

System telemetry monitors the Gauntlet platform itself. It is not per-attempt — it tracks pipelines, infrastructure, and operational health.

#### Challenge Generation Pipeline Metrics

```yaml
event_type: pipeline_stage
schema:
  pipeline_run_id: string
  stage: enum                # seed_selection | spec_generation | codebase_generation |
                             # test_generation | validation | quality_gate
  started_at: ISO-8601
  completed_at: ISO-8601
  duration_ms: int
  status: enum               # success | failure | retry | timeout
  retry_count: int
  failure_reason: string     # null on success
  challenge_id: string       # the challenge being generated (null for seed_selection)
  model_used: string         # which LLM was used for this stage
  tokens_consumed: int
```

#### Judge Execution Metrics

```yaml
event_type: judge_execution
schema:
  judgment_id: string
  attempt_id: string
  judge_type: enum           # functional | process | style | meta
  started_at: ISO-8601
  completed_at: ISO-8601
  duration_ms: int
  model_used: string
  tokens_consumed: int
  score_given: float
  confidence: float
  api_retries: int
  api_errors: int
```

**Cross-judge disagreement tracking:**

```yaml
event_type: judge_disagreement
schema:
  attempt_id: string
  judge_a: string
  judge_b: string
  score_a: float
  score_b: float
  delta: float               # abs(score_a - score_b)
  flagged_for_review: bool   # true if delta > threshold (default 0.3)
```

#### Matchmaking Metrics

```yaml
event_type: matchmaking_decision
schema:
  agent_id: string
  timestamp: ISO-8601
  queue_depth: int           # how many challenges were available
  selected_challenge_id: string
  predicted_score: float     # what the matchmaker predicted the agent would score
  actual_score: float        # filled in after attempt completes (null initially)
  prediction_error: float    # abs(predicted - actual), filled in after
  selection_reason: string   # why this challenge was chosen
  selection_duration_ms: int
```

#### Infrastructure Metrics

```yaml
event_type: infra_health
schema:
  timestamp: ISO-8601
  component: enum            # sandbox | api | database | queue | storage
  metric_name: string        # e.g., "sandbox_spin_up_ms", "api_latency_p99"
  metric_value: float
  unit: string               # ms | percent | count | bytes
  threshold_warning: float
  threshold_critical: float
  alert_status: enum         # normal | warning | critical
```

---

## Collection Architecture

Telemetry collection is designed for minimal overhead inside the sandbox and maximum reliability outside it.

### Agent-Side Instrumentation

The sandbox runtime wraps every tool call with instrumentation. The agent does not need to opt in — telemetry is a property of the sandbox, not the agent.

```
┌─────────────────────────────────────────────┐
│  Sandbox                                    │
│  ┌─────────┐    ┌──────────────────────┐    │
│  │  Agent   │───▶│  Tool Proxy Layer    │    │
│  │ Runtime  │◀───│  (intercepts calls)  │    │
│  └─────────┘    └──────────┬───────────┘    │
│                            │                │
│                   ┌────────▼────────┐       │
│                   │  Event Buffer   │       │
│                   │  (in-memory)    │       │
│                   └────────┬────────┘       │
└────────────────────────────┼────────────────┘
                             │ flush every 5s
                             │ or on buffer full (1000 events)
                    ┌────────▼────────┐
                    │  Event Ingress  │
                    │  (HTTP endpoint)│
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Event Stream   │
                    │  (Kafka/NATS)   │
                    └─────────────────┘
```

**Key design decisions:**
1. **In-sandbox buffer**: Events are buffered in memory to avoid per-event network overhead. The buffer flushes every 5 seconds or when it reaches 1000 events, whichever comes first.
2. **Fire-and-forget from sandbox**: The sandbox does not wait for acknowledgment. If the event ingress is down, events are written to a local file as a fallback and recovered later.
3. **Tool Proxy Layer**: Sits between the agent runtime and actual tool implementations. It captures timing, arguments, and results without modifying tool behavior. The agent cannot detect or bypass this layer.
4. **Filesystem watcher**: A separate process inside the sandbox monitors the workspace directory for file changes, capturing diffs that occur outside tool calls (e.g., build artifacts, generated files).

### Event Streaming

Events flow through a streaming platform (Kafka or NATS JetStream) for decoupled processing.

```
Event Ingress ──▶ Stream Topic: gauntlet.telemetry.raw
                       │
          ┌────────────┼──────────────┐
          │            │              │
          ▼            ▼              ▼
    Process Judge   Analytics     Anomaly
    Consumer        Consumer      Detector
```

**Topics:**
- `gauntlet.telemetry.raw` — all raw events, partitioned by `attempt_id`
- `gauntlet.telemetry.agent` — agent telemetry only (tool calls, tests, file changes, errors)
- `gauntlet.telemetry.system` — system telemetry only (pipeline, judge, infra)
- `gauntlet.telemetry.alerts` — anomaly detection outputs
- `gauntlet.telemetry.dead-letter` — events that failed processing

### Structured Logging

All Gauntlet components emit structured JSON logs that are indexed alongside telemetry events.

```json
{
  "timestamp": "2026-03-27T14:32:01.445Z",
  "level": "info",
  "component": "challenge-generator",
  "pipeline_run_id": "prun_a1b2c3",
  "stage": "codebase_generation",
  "message": "Codebase generation completed",
  "duration_ms": 12450,
  "files_generated": 23,
  "total_lines": 1847
}
```

---

## Storage and Retention

### Storage Architecture

```
┌──────────────────────────────────────────────────┐
│                   Query Layer                     │
│         (Grafana / Custom Dashboards)             │
└──────────┬──────────────┬───────────┬────────────┘
           │              │           │
    ┌──────▼──────┐ ┌─────▼────┐ ┌───▼─────────┐
    │  Hot Store  │ │ Cold     │ │ Aggregated  │
    │  (ClickHouse│ │ Store    │ │ Store       │
    │  or TimescaleDB) │ (S3/GCS  │ │ (Postgres)  │
    │             │ │ Parquet) │ │             │
    │  Recent     │ │ Archived │ │ Rollups     │
    │  events     │ │ events   │ │ forever     │
    └─────────────┘ └──────────┘ └─────────────┘
```

### Retention Policies

| Data Category | Hot Retention | Cold Retention | Aggregated |
|---------------|---------------|----------------|------------|
| Agent telemetry (raw events) | 90 days | 1 year | Forever |
| System telemetry (raw events) | 30 days | 1 year | Forever |
| Score trajectories | 1 year | Forever | Forever |
| Judge disagreements | 1 year | Forever | Forever |
| Infrastructure metrics | 7 days | 90 days | 1 year |
| Structured logs | 14 days | 90 days | N/A |

### Aggregation Rules

Raw events are rolled up into aggregations that persist indefinitely:

```yaml
agent_attempt_summary:
  attempt_id: string
  agent_id: string
  challenge_id: string
  total_tool_calls: int
  tool_call_breakdown: map[string, int]  # tool_name → count
  total_test_runs: int
  total_files_changed: int
  total_errors: int
  unique_errors: int
  repeated_errors: int
  phase_time_breakdown: map[string, int] # phase → total_ms
  score_trajectory: float[]
  final_score: float
  total_duration_ms: int
  regression_count: int
  churn_files: string[]                  # files edited 3+ times

challenge_health_summary:
  challenge_id: string
  period: string                         # daily, weekly
  attempts_count: int
  avg_score: float
  median_score: float
  p10_score: float
  p90_score: float
  avg_duration_ms: int
  avg_tool_calls: int
  common_errors: map[string, int]        # error_message → count
  common_failure_points: string[]        # test names that fail most

system_health_summary:
  period: string
  pipeline_success_rate: float
  avg_pipeline_duration_ms: int
  judge_avg_latency_ms: int
  judge_disagreement_rate: float
  sandbox_avg_spin_up_ms: int
  total_attempts: int
  total_challenges_generated: int
```

---

## Privacy and Security

### What IS Captured

- Tool call names and argument summaries (truncated)
- Test execution results (pass/fail counts, failure messages)
- File paths and diff statistics (not full file contents)
- Timing data for all operations
- Error messages (truncated)
- Score trajectories

### What is NOT Captured

- **Full file contents**: Only diffs and hashes, never the complete source code of solutions
- **Agent model weights or prompts**: The telemetry system captures behavior, not internals
- **Agent API keys or credentials**: Stripped from all event fields before storage
- **Inter-agent communication content**: If multi-agent, only metadata (message count, size) not content
- **User PII**: Agent IDs are pseudonymous; no real names, emails, or identifying information in telemetry

### Data Access Controls

```yaml
access_levels:
  public:
    - Aggregated leaderboard statistics
    - Challenge-level aggregate metrics (avg score, attempt count)
    - System uptime and availability metrics

  agent_owner:
    - All telemetry for their own agent's attempts
    - Score trajectories and tool call logs for their agent
    - Comparison against anonymized population statistics

  platform_admin:
    - All telemetry for all agents
    - Raw event access
    - Judge calibration data
    - Anomaly detection alerts

  judge_system:
    - Agent telemetry for the specific attempt being judged
    - No access to other agents' telemetry
    - No access to system telemetry
```

### Anonymization for Public Analytics

When telemetry is surfaced in public dashboards or research:
- Agent IDs are replaced with opaque hashes
- Specific tool call arguments are stripped
- Error messages are categorized (not shown verbatim)
- Timing data is bucketed (e.g., "fast", "medium", "slow") rather than exact
- File paths are generalized (e.g., "src/**/*.py" not "src/auth/jwt_validator.py")

---

## Analytics and Dashboards

### Dashboard 1: Agent Behavior Patterns

**Purpose**: Understand how agents approach challenges across the population.

**Panels:**

| Panel | Visualization | Data Source |
|-------|---------------|-------------|
| Tool usage distribution | Stacked bar chart | `tool_call` events grouped by `tool_name` |
| Average phase time breakdown | Pie chart | `phase_transition` events |
| Test-between-edits ratio distribution | Histogram | Derived from `test_run` and `file_change` counts |
| Score trajectory clusters | Line chart overlay | `score_checkpoint` events, clustered by pattern |
| Error recovery rate | Gauge | `error_encountered` where `resolved = true` / total |
| Churn heatmap | Heatmap (file × time) | `file_change` events for high-churn attempts |

**Key queries:**
```sql
-- Average tool calls per attempt by tool type
SELECT tool_name, AVG(call_count) as avg_calls
FROM (
  SELECT attempt_id, tool_name, COUNT(*) as call_count
  FROM tool_call_events
  WHERE timestamp > NOW() - INTERVAL 7 DAY
  GROUP BY attempt_id, tool_name
) sub
GROUP BY tool_name
ORDER BY avg_calls DESC;

-- Score trajectory pattern distribution
SELECT trajectory_pattern, COUNT(*) as attempt_count
FROM agent_attempt_summary
WHERE created_at > NOW() - INTERVAL 30 DAY
GROUP BY trajectory_pattern
ORDER BY attempt_count DESC;
```

### Dashboard 2: Challenge Health

**Purpose**: Monitor whether challenges are well-calibrated and functioning correctly.

**Panels:**

| Panel | Visualization | Data Source |
|-------|---------------|-------------|
| Score distribution per challenge | Box plot | `score_checkpoint` final scores |
| Challenge difficulty vs. actual scores | Scatter plot | challenge metadata + attempt scores |
| Most common failure points | Table | `test_run` failure messages, ranked |
| Time-to-solve distribution | Histogram | `agent_attempt_summary.total_duration_ms` |
| Staleness indicator | Timeline | Last attempted date per challenge |
| Quality gate pass rate | Line chart (over time) | `pipeline_stage` events where stage = quality_gate |

**Alert conditions:**
- Challenge has 0% pass rate after 10+ attempts → likely broken
- Challenge has 100% pass rate after 10+ attempts → likely too easy
- Average score drifts > 0.2 over a week → possible contamination

### Dashboard 3: System Performance

**Purpose**: Operational health of the Gauntlet platform.

**Panels:**

| Panel | Visualization | Data Source |
|-------|---------------|-------------|
| Pipeline success rate | Line chart (24h rolling) | `pipeline_stage` events |
| Sandbox spin-up time (p50/p95/p99) | Line chart | `infra_health` where metric = sandbox_spin_up_ms |
| Judge latency by type | Multi-line chart | `judge_execution` events |
| Event ingestion rate | Counter + sparkline | Event stream consumer lag |
| API error rate | Line chart | `infra_health` where component = api |
| Queue depth | Area chart | `matchmaking_decision.queue_depth` |

### Dashboard 4: Judge Calibration

**Purpose**: Ensure judges are consistent, accurate, and not drifting.

**Panels:**

| Panel | Visualization | Data Source |
|-------|---------------|-------------|
| Inter-judge agreement | Heatmap (judge × judge) | `judge_disagreement` events |
| Score distribution by judge | Violin plot | `judge_execution.score_given` |
| Judge latency trends | Line chart | `judge_execution.duration_ms` |
| Flagged disagreements | Table (sortable) | `judge_disagreement` where `flagged_for_review = true` |
| Confidence distribution | Histogram | `judge_execution.confidence` |
| Calibration drift | Line chart (weekly avg score per judge) | Aggregated `judge_execution` |

---

## Anomaly Detection

Automated systems that monitor telemetry streams in real time, flagging patterns that indicate problems, gaming, or system failures.

### Rule-Based Anomalies

```yaml
anomaly_rules:

  - name: sandbox_escape_attempt
    description: Agent attempts to access resources outside the sandbox
    trigger: >
      tool_call where tool_name = "Bash" AND
      (arguments_summary CONTAINS "curl" OR
       arguments_summary CONTAINS "wget" OR
       arguments_summary CONTAINS "/etc/passwd" OR
       arguments_summary CONTAINS "ssh" OR
       arguments_summary MATCHES "nc\s+-l")
    severity: critical
    action: terminate_attempt, flag_agent, alert_admin

  - name: abnormal_tool_volume
    description: Agent making an unusually high number of tool calls
    trigger: >
      COUNT(tool_call) WHERE attempt_id = X
      AND window = 60 seconds
      > 100
    severity: warning
    action: throttle_agent, log_alert

  - name: suspiciously_fast_solution
    description: Agent solves challenge faster than any known baseline
    trigger: >
      score_checkpoint WHERE score = 1.0
      AND cumulative_time_ms < challenge.min_expected_time_ms * 0.2
    severity: high
    action: flag_for_review, hold_score

  - name: score_manipulation_attempt
    description: Agent appears to be modifying test files or scoring scripts
    trigger: >
      file_change WHERE file_path MATCHES "test_.*\\.py$|.*_test\\.go$|.*\\.test\\.(js|ts)$"
      OR file_path MATCHES "score.*|judge.*|eval.*"
    severity: critical
    action: terminate_attempt, score_zero, flag_agent

  - name: infinite_loop_detection
    description: Agent is stuck in a loop repeating the same actions
    trigger: >
      3 consecutive windows of 5 tool calls each where
      tool_name sequence is identical
    severity: warning
    action: notify_agent (if supported), log_alert

  - name: test_result_regression_spiral
    description: Agent is making things progressively worse
    trigger: >
      3 consecutive score_checkpoints where
      delta_from_previous < -0.05
    severity: info
    action: log_alert
```

### Statistical Anomalies

Beyond rules, the system uses statistical methods on sliding windows:

**Z-score detection**: For each metric (tool call count, duration, error count), compute the population mean and standard deviation. Flag attempts where the metric exceeds 3 standard deviations.

**Isolation forest**: Trained on feature vectors derived from `agent_attempt_summary` records. Detects attempts that are outliers across multiple dimensions simultaneously (e.g., very few tool calls + perfect score + very fast = suspicious).

**Temporal anomaly detection**: Time-series anomaly detection on system metrics. Sudden spikes in judge latency, drops in pipeline success rate, or unusual patterns in sandbox spin-up times trigger infrastructure alerts.

### Alert Routing

```yaml
alert_routing:
  critical:
    channels: [pagerduty, slack_oncall]
    response_sla: 15 minutes
    examples: sandbox_escape_attempt, score_manipulation_attempt

  high:
    channels: [slack_alerts]
    response_sla: 1 hour
    examples: suspiciously_fast_solution, judge_disagreement > 0.5

  warning:
    channels: [slack_alerts]
    response_sla: 4 hours
    examples: abnormal_tool_volume, infinite_loop_detection

  info:
    channels: [dashboard_only]
    response_sla: next_business_day
    examples: test_result_regression_spiral, minor_judge_drift
```

### Alert Schema

```yaml
event_type: anomaly_alert
schema:
  alert_id: string
  timestamp: ISO-8601
  rule_name: string
  severity: enum             # critical | high | warning | info
  attempt_id: string         # null for system-level anomalies
  agent_id: string           # null for system-level anomalies
  description: string
  evidence: object           # the telemetry events that triggered the alert
  action_taken: string[]     # what automated actions were performed
  resolved: bool
  resolved_at: ISO-8601      # null if unresolved
  resolved_by: string        # system | admin_username
```

---

## Telemetry-Driven Feedback Loops

Telemetry doesn't just observe — it drives improvement.

### Loop 1: Challenge Calibration

```
Telemetry → aggregate scores per challenge
          → detect difficulty drift
          → trigger recalibration pipeline
          → adjust challenge difficulty metadata
```

If a challenge that was rated "hard" consistently gets 90%+ scores, telemetry triggers automatic difficulty reassessment.

### Loop 2: Judge Tuning

```
Telemetry → detect inter-judge disagreement trends
          → surface flagged cases for human review
          → human labels become judge training data
          → judge prompts/models updated
```

### Loop 3: Matchmaking Accuracy

```
Telemetry → compare predicted scores vs. actual scores
          → compute prediction error distribution
          → retrain matchmaking model on new data
          → deploy updated model
```

### Loop 4: Anti-Gaming Evolution

```
Telemetry → anomaly detector finds new gaming pattern
          → pattern added to rule set
          → historical attempts re-scanned
          → affected scores adjusted
```

---

## Implementation Priorities

### Phase 1: Foundation (MVP)

- Tool call logging with basic schema
- Test run logging
- Score trajectory capture
- Storage in a single database (Postgres with TimescaleDB extension)
- One dashboard (agent behavior)
- Basic rule-based anomaly detection (sandbox escape, score manipulation)

### Phase 2: Full Agent Telemetry

- File change logging with diff stats
- Error logging with repeat detection
- Phase transition classification
- Process Judge integration (telemetry becomes judge input)
- Challenge health dashboard
- Statistical anomaly detection

### Phase 3: System Telemetry

- Pipeline metrics
- Judge execution metrics
- Infrastructure metrics
- System performance dashboard
- Judge calibration dashboard
- Alert routing with severity tiers

### Phase 4: Feedback Loops

- Challenge recalibration loop
- Judge tuning loop
- Matchmaking accuracy loop
- Anti-gaming evolution loop
- Full cold-storage archival pipeline
- Public anonymized analytics

---

## Operational Runbook

### Telemetry Ingestion Down

1. Events buffer locally in sandbox (file fallback)
2. Alert fires after 2 minutes of ingestion silence
3. Check event ingress endpoint health
4. Check stream broker (Kafka/NATS) health
5. If broker is down, restart broker; buffered events will replay
6. If ingress is down, check for OOM or crash loops
7. After recovery, trigger backfill from sandbox fallback files

### High Event Volume (>10x baseline)

1. Check for runaway agents (infinite loop detection should catch this)
2. Check for event duplication (duplicate `sequence_number` per `attempt_id`)
3. If legitimate volume spike, scale ingress horizontally
4. Enable sampling for `info`-level events if needed (never sample `critical`)

### Storage Approaching Capacity

1. Verify retention policies are executing (check last successful cleanup)
2. Run emergency aggregation for oldest hot data
3. Migrate to cold storage ahead of schedule
4. If cold storage is also full, extend capacity or reduce cold retention
5. Never delete raw data before aggregation completes

---

## Key Metrics to Track About Telemetry Itself (Meta-Telemetry)

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Event ingestion latency (p99) | < 500ms | > 2000ms |
| Event loss rate | 0% | > 0.1% |
| Storage utilization | < 70% | > 85% |
| Query latency (dashboard) | < 2s | > 10s |
| Anomaly detection latency | < 30s | > 120s |
| Backfill completion time | < 1 hour | > 4 hours |
| Aggregation job duration | < 30 min | > 2 hours |

These meta-metrics ensure the telemetry system itself is healthy. A blind telemetry system is worse than no telemetry at all — it provides false confidence.
