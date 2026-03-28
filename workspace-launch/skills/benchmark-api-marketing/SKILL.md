---
name: benchmark-api-marketing
description: Market the Bouts Benchmark API to AI labs with the right value proposition, API documentation strategy, landing page copy structure, and quick-start framing. Use when writing API documentation, the /benchmark landing page, or any outreach targeted at AI labs that need programmatic access to contamination-resistant evaluation.
---

# Benchmark API Marketing

## The core value proposition
"Evaluate your models against challenges they've never seen before, scored across dimensions no other benchmark measures."

## API documentation as marketing
The docs themselves are a sales tool. They must be:
- Beautiful — not auto-generated Swagger UI
- Example-rich — real request/response pairs with actual score breakdowns
- Methodology-transparent — link to judging policy for every scoring dimension
- Quick-start focused — "Run your first benchmark in 5 minutes"

## Landing page copy structure

### Headline
"The Benchmark API That Tells You Where Your Model Actually Fails"

### Subheadline
"Five independent judge dimensions. Contamination-resistant challenges. Failure archetype detection. The data your internal evals can't produce."

### What you get section
```
POST /api/benchmark/run
Submit model configuration
→ Run against contamination-resistant challenge suite
→ Receive:
  - Composite score + per-judge breakdown
  - Failure archetype detection
  - Peer comparison (percentile vs all models)
  - Process and Recovery scoring (not just output correctness)
```

### Why this data is different
- Challenges generated fresh — model hasn't seen them in training
- 5 independent judges from 3+ model families — no single-model bias
- Failure archetype detection — WHERE it fails, not just that it failed
- Process and Recovery scoring — engineering quality, not just output

### Pricing
[Tier table from data-licensing-content]

### Quick start
```python
from bouts import BenchmarkClient

client = BenchmarkClient(api_key="your_key")

result = client.run(
    model_config={"provider": "anthropic", "model": "claude-3-5-sonnet"},
    challenge_family="blacksite_debug",
    weight_class="heavyweight"
)

print(result.composite_score)  # 74.2
print(result.failure_archetypes)  # ["premature_convergence"]
print(result.judge_breakdown)  # {objective: 81, process: 72, ...}
```

## Objection: "We can do this ourselves"
"You can. And your results will be contaminated by your training data. Our challenge grammar is private. That's the difference."

