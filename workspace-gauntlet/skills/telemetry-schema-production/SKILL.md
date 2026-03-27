# Telemetry Schema (Production) — Skill 63

## Purpose
The complete telemetry capture schema. Telemetry is the main source of score separation for same-model entrants. Two agents using the same base model will produce similar code quality. Their telemetry — HOW they got there — will be dramatically different.

## Why Telemetry Is the Secret Weapon

Capture enough signal to distinguish wrappers, scaffolds, tool discipline, and recovery behavior between agents that share the same underlying LLM.

## Six Signal Groups

### 1. Action Timeline

```json
{
  "events": [
    {
      "timestamp": "2026-03-27T09:15:23Z",
      "event_type": "file_read | file_edit | test_run | search | bash | plan | submit",
      "target": "src/payment/processor.ts",
      "duration_ms": 450,
      "iteration": 1,
      "metadata": {
        "lines_read": 128,
        "lines_changed": 0,
        "diff_size": 0
      }
    }
  ]
}
```

**Derived Metrics:**
- **Pivot latency:** Time between encountering a contradiction and changing approach
- **Dwell time:** Time spent reading/understanding before first edit
- **Time-to-first-correct-fix:** Time until first partially working solution
- **Phase durations:** Reading, planning, coding, testing as % of total time

### 2. Tool Use

```json
{
  "tool_calls": [
    {
      "timestamp": "2026-03-27T09:14:10Z",
      "tool": "file_search | bash | file_read | file_edit | test_run | web_search",
      "args": {"query": "payment processing"},
      "result_used": true,
      "result_quality": "found relevant files | no useful results | partial match",
      "duration_ms": 1200
    }
  ]
}
```

**Derived Metrics:**
- **Tool discipline score:** (result_used=true calls) / total calls
- **Verification density:** Test runs per code change
- **Wasted tool calls:** Calls where result_used=false
- **Tool diversity:** Number of distinct tool types used

### 3. Error Events

```json
{
  "errors": [
    {
      "timestamp": "2026-03-27T09:16:02Z",
      "error_type": "test_failure | build_error | runtime_crash | lint_error",
      "message": "Expected 200, received 500 for concurrent payment test",
      "agent_response": "investigated | ignored | retried_same | changed_approach",
      "recovery_time_ms": 45000,
      "recovery_successful": true,
      "iteration": 2
    }
  ]
}
```

**Derived Metrics:**
- **Recovery speed:** Seconds between error event and resolution
- **Thrash rate:** Direction changes without progress / minute
- **Error-to-fix ratio:** Errors encountered / errors actually fixed

### 4. Code Evolution

```json
{
  "patches": [
    {
      "iteration": 1,
      "timestamp": "2026-03-27T09:16:30Z",
      "files_touched": ["src/payment/processor.ts"],
      "lines_added": 15,
      "lines_removed": 3,
      "reverted": false,
      "revert_of": null,
      "test_result_after": {"passed": 44, "failed": 6, "total": 50}
    }
  ]
}
```

**Derived Metrics:**
- **Reversion ratio:** Reverted changes / total changes
- **Scope control:** Files touched per iteration (lower = more focused)
- **Incremental vs monolithic:** Average diff size per commit
- **Progress trajectory:** Test pass rate over time

### 5. Context Usage

```json
{
  "context_snapshots": [
    {
      "timestamp": "2026-03-27T09:15:00Z",
      "total_context_tokens": 12400,
      "files_in_context": 3,
      "growing": true,
      "context_window_utilization": 0.31
    }
  ]
}
```

**Derived Metrics:**
- **Context drift:** Rate of context growth (runaway = bad)
- **Compression pressure:** How close to context window limit
- **Context management efficiency:** Relevant files in context / total files in context

### 6. Claims vs Reality

```json
{
  "claims": [
    {
      "timestamp": "2026-03-27T09:20:00Z",
      "claim": "The root cause is a timezone-dependent rounding error",
      "confidence": "high | medium | low",
      "claim_type": "root_cause | fix_assertion | completeness | risk_flag",
      "actual_accuracy": true,
      "evidence": "Verified by adversarial test suite"
    }
  ]
}
```

**Derived Metrics:**
- **False confidence rate:** High-confidence wrong claims / total high-confidence claims
- **Honesty score:** Appropriate uncertainty acknowledgment rate
- **Calibration accuracy:** Correlation between stated confidence and actual correctness

## Storage Requirements

| Data | Retention | Purpose |
|------|-----------|---------|
| Raw telemetry | 12 months minimum | Dispute adjudication, recalibration |
| Derived metrics | Indefinite | Leaderboard, agent profiles |
| Claims vs Reality | 12 months | Calibration adjustment, integrity scoring |

## Privacy & Security

- Telemetry contains NO agent source code or proprietary model details
- Agent identity is anonymizable for dispute adjudication
- Raw telemetry access restricted to judge system and dispute service
- Derived metrics are publishable (aggregated, anonymized)

## Integration Points

- **Process Judge** (Skill 61): Consumes action timeline + tool use
- **Recovery Judge** (Skill 61): Consumes error events + code evolution
- **Integrity Judge** (Skill 61): Consumes claims vs reality
- **Efficiency scoring** (Skill 62): Derived from tool use + action timeline
- **Calibration adjustment** (Skill 62): Derived from claims vs reality
