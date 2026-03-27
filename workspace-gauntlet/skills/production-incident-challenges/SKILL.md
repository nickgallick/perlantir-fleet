# Production Incident Challenges

The Monday Morning Disaster Recovery archetype and related production incident patterns. These are Gauntlet's signature challenges — they simulate the most stressful, high-stakes scenarios in software engineering and measure whether an agent can think clearly under chaos. The core insight: the difference between a great engineer and a mediocre one is not what they do when everything is calm, but what they do when everything is on fire.

---

## The Monday Morning Pattern

### The Setup

The agent "arrives" to a disaster in progress. Multiple signals, most of them noise.

```
INBOX:
  [ALERT] PagerDuty: payments-service CPU at 98% for 15 minutes
  [ALERT] PagerDuty: database connection pool exhausted
  [ALERT] Sentry: 2,847 unhandled exceptions in last hour
  [SLACK] #engineering: "Is anyone looking at this?"
  [SLACK] CTO: "I'm getting texts from the board. What's happening with payments?"
  [EMAIL] Customer (Acme Corp): "We've been unable to process orders since 6am.
           This is costing us $50K/hour. What's your ETA?"
  [SLACK] #on-call: "I restarted the payments pod at 5:45am, seemed to help
           for 10 minutes then it came back"
  [DASHBOARD] Grafana: payments latency 15x normal, error rate 34%
  [CI/CD] Last deploy: Friday 11:47pm — "Fix: update payment provider SDK to v3.2"
```

### The Correct Approach (90-100 Score)

1. **Read EVERYTHING first.** Don't touch anything for the first 5 minutes. Read all alerts, messages, dashboards, and recent deploys.

2. **Form a hypothesis.** "The Friday night SDK update likely introduced a breaking change. The pod restart temporarily masked it because the connection pool refreshed."

3. **Communicate to stakeholders.** Message the CTO: "I'm investigating the payments outage. Initial assessment: likely related to Friday's SDK update. I'll have a status update in 15 minutes."

4. **Communicate to the customer.** Message Acme Corp: "We're aware of the payment processing issue and are actively investigating. I'll provide an update within 30 minutes."

5. **Investigate systematically.** Check the Friday deploy diff. Compare SDK v3.1 → v3.2 changelog. Look for breaking changes.

6. **Fix the root cause.** Roll back the SDK update OR fix the breaking change.

7. **Verify the fix.** Confirm payments are processing. Check error rates returning to normal.

8. **Post-incident communication.** Update CTO and customer with resolution.

### The Wrong Approach (20-30 Score)

1. Sees "CPU at 98%." Starts investigating CPU.
2. Adds more pods to handle load. CPU drops temporarily.
3. Database connections exhaust again because more pods = more connections.
4. Starts investigating database. Increases connection pool.
5. 45 minutes in, still hasn't read the customer email or messaged the CTO.
6. Never looks at the Friday deploy.
7. Eventually the symptoms come back because the root cause (SDK breaking change) was never addressed.

---

## Inbox Generation

### Generating Realistic Inbox Items

Each inbox item follows a template:

**PagerDuty Alerts:**
```
[ALERT] PagerDuty: {service_name} {metric} at {value} for {duration}
Threshold: {threshold}
Runbook: {url}
Previous incidents: {count} in last 30 days
```

**Slack Messages:**
```
[SLACK] #{channel} @{user} ({role}): "{message}"
Timestamp: {time}
Thread replies: {count}
```

**Sentry Errors:**
```
[SENTRY] {exception_type}: {message}
File: {file_path}:{line_number}
Occurrences: {count} in last {duration}
First seen: {timestamp}
Stack trace: {abbreviated_trace}
```

**Customer Emails:**
```
[EMAIL] From: {name} ({company}) — {account_tier}
Subject: {subject}
Received: {timestamp}
Priority: {priority}

{body}
```

**Dashboard Metrics:**
```
[DASHBOARD] {dashboard_name}
{metric_1}: {value} (normal: {baseline})
{metric_2}: {value} (normal: {baseline})
Trend: {direction} since {timestamp}
```

**CI/CD History:**
```
[DEPLOY] {timestamp} — {author}: "{commit_message}"
Changed files: {file_list}
Pipeline: {status}
Rollback available: {yes/no}
```

### Noise-to-Signal Ratio

A realistic incident inbox has a high noise-to-signal ratio:

| Item Type | Signal | Noise | Purpose |
|-----------|--------|-------|---------|
| Root cause alert | 1 | 0 | The actual problem |
| Symptom alerts | 0 | 3-5 | Cascading effects of root cause |
| Stakeholder messages | 1 | 2-3 | One contains a useful clue, rest are pressure |
| Red herrings | 0 | 1-2 | Unrelated alerts that coincide temporally |
| Historical context | 1 | 0 | The deploy/change that caused it |

### Red Herring Design

Red herrings must be plausible but distinguishable:
- An unrelated cron job that failed at the same time (coincidence)
- A monitoring alert for a different service that's actually fine (flaky alert)
- A team member's message about an unrelated issue in the same channel

Red herrings MUST be identifiable as noise if the agent reads carefully. They're not designed to trick — they're designed to test whether the agent reads carefully.

---

## Scoring Dimensions

### Triage Quality (30%)

```
triage_score = (
  read_all_inputs * 10 +           # Did agent read everything before acting?
  identified_root_cause * 10 +      # Found the actual problem, not symptoms?
  correct_first_action * 5 +        # Was the first remediation action correct?
  avoided_red_herrings * 5          # Didn't waste time on noise?
)
```

### Communication Quality (25%)

```
communication_score = (
  cto_message_sent * 5 +            # Did they communicate to leadership?
  cto_message_quality * 5 +         # Calm, informative, accurate?
  customer_message_sent * 5 +       # Did they acknowledge the customer?
  customer_message_quality * 5 +    # Professional, empathetic, with ETA?
  status_updates * 5                # Ongoing updates during resolution?
)
```

**CTO message rubric:**
- Bad: "Looking into it" (vague, no information)
- Okay: "Payments are down, investigating" (acknowledges, no hypothesis)
- Good: "Payments outage since 6am, likely related to Friday's SDK update. Investigating now. ETA: 30 minutes for initial assessment."
- Excellent: Adds impact assessment, preliminary plan, and next update time.

**Customer message rubric:**
- Bad: No message sent (ignores customer)
- Okay: "We're aware of the issue" (generic)
- Good: "We've identified a processing issue affecting orders since 6am. Our team is actively working on it. I'll provide an update within 30 minutes."
- Excellent: Includes specific acknowledgment of their impact, realistic timeline, and follow-up commitment.

### Fix Quality (30%)

```
fix_score = (
  correct_root_cause_fix * 15 +     # Fixed the actual problem?
  no_side_effects * 5 +             # Fix didn't break other things?
  verified_fix * 5 +                # Confirmed the fix worked?
  clean_implementation * 5          # Fix is production-quality, not a hack?
)
```

### Process Quality (15%)

```
process_score = (
  investigation_order * 5 +         # Read before write?
  hypothesis_formed * 5 +           # Had a theory before making changes?
  rollback_ready * 5                # Could undo if fix didn't work?
)
```

---

## Other Incident Patterns

### Silent Failure

Metrics look fine, but users complain. The system isn't crashing — it's producing wrong results silently.

```
SCENARIO: Users report receiving other users' data in their API responses.
Metrics show: normal latency, normal error rate, normal CPU.
Root cause: caching layer is returning stale/wrong responses due to a
cache key collision introduced in a recent deploy.

Why this is hard: All automated monitoring says "everything is fine."
The agent must trust user reports over dashboards and investigate a
system that appears healthy.
```

### Cascading Failure

Fixing one thing breaks another. Tests whether the agent can think about system-wide effects.

```
SCENARIO: Service A depends on Service B depends on Service C.
Service C is slow. Service B's connection pool to C fills up.
Service A's requests to B start timing out.

Trap: Fixing Service A (increase timeout) or Service B (increase pool)
are symptom fixes. The root cause is in Service C.

Advanced trap: Fixing Service C reveals that Service B has been silently
dropping requests and needs its own fix too.
```

### Phantom Alert

The alert is wrong. The system is fine. Tests whether the agent verifies before fixing.

```
SCENARIO: PagerDuty fires "disk usage at 95%."
Reality: A monitoring agent calculated disk usage wrong after a
partition resize. Actual usage is 45%.

What happens:
- 20/100 agent: Starts deleting old logs to free disk space.
  May accidentally delete important logs.
- 95/100 agent: Verifies the alert with `df -h`.
  Sees actual usage is 45%. Investigates the monitoring discrepancy.
  Files a bug against the monitoring system.
```

### The Slow Bleed

Not a sudden outage — performance degrades 1% per day. By the time someone notices, it's been 3 weeks.

```
SCENARIO: API response times have increased from 100ms to 350ms over 21 days.
No single deploy caused it. It's a combination of:
- Table growth without index optimization
- Memory leak (small, ~1MB/hour)
- Log volume increasing (stdout is unbuffered)

Why this is hard: No single root cause. No single fix. The agent must
investigate multiple contributing factors and prioritize by impact.
```

---

## Incident Generation Template

```yaml
incident:
  name: "The Midnight Meltdown"
  tier: 3
  category: forensic-reasoning

  root_cause: |
    Friday deploy updated payment SDK from v3.1 to v3.2.
    v3.2 changed the webhook signature format from HMAC-SHA256 to HMAC-SHA512.
    All incoming webhooks are rejected as invalid, payments marked as failed.

  symptoms:
    - "Payment success rate dropped from 99.2% to 65.8%"
    - "Webhook endpoint returning 401 for 34% of requests"
    - "Customer complaints about orders stuck in 'processing'"

  inbox_items:
    - type: pagerduty
      message: "payments-webhook error rate >30% for 10 minutes"
      is_signal: true
    - type: pagerduty
      message: "payments-service CPU at 78%"
      is_signal: false  # symptom, not cause
    - type: slack
      from: "CTO"
      message: "Board meeting in 2 hours. Need payments working."
      is_signal: false  # pressure, not information
    - type: slack
      from: "on-call engineer"
      message: "I restarted the pods but it came back"
      is_signal: true  # tells you restart doesn't fix it → not a transient issue
    - type: deploy_log
      message: "Fri 11:47pm: update payment SDK to v3.2"
      is_signal: true  # the root cause

  expected_resolution:
    quick_fix: "Roll back SDK to v3.1"
    proper_fix: "Update webhook validation to accept both SHA256 and SHA512"

  scoring_anchors:
    low: "Increased pod count and connection pool. Never found root cause."
    mid: "Found the SDK update was suspicious. Rolled back. Didn't investigate why."
    high: "Read all inputs. Identified SDK update as cause. Verified webhook signature mismatch. Rolled back immediately. Communicated to CTO and customer. Filed ticket to update webhook validation properly."
```

---

## Working Principles

1. **Read everything before acting.** This is the single highest-signal behavior in incident response. Agents that start fixing things before reading all inputs almost always fix the wrong thing. Score investigation-before-action heavily.

2. **Communication IS part of the fix.** A silent agent that fixes the bug in 5 minutes but never tells the CTO or the customer scores lower than one that takes 10 minutes but communicates throughout. In production incidents, silence is failure.

3. **Root cause, not symptoms.** Every incident challenge has a root cause and 3-5 symptoms. Scoring must distinguish between fixing the root cause (high score) and fixing symptoms (low score). Symptom fixes that happen to pass basic tests should fail hidden tests.

4. **Red herrings must be fair.** Noise in the inbox is realistic, but every red herring must be identifiable as noise if the agent reads carefully. An unfair red herring is one that can only be eliminated with information the agent doesn't have.

5. **The 90/100 agent reads everything, forms a hypothesis, communicates, THEN acts. The 30/100 agent acts first and investigates never.** This is the behavioral signature we're testing for. Design every incident challenge around this distinction.
