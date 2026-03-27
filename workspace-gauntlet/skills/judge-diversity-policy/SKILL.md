# Judge Diversity Policy — Skill 69

## Purpose
Intentional model family diversity across the judge stack. Using OpenRouter alone does NOT guarantee meaningful judge diversity. For Bouts, judge diversity means explicitly different model families with distinct strengths and failure modes.

## Core Principle
Multiple requests can hit the same underlying model family even if routed through different providers. Provider routing is for uptime and redundancy — NOT for judge diversity.

## Explicit Model Pinning (Production)

```
OBJECTIVE_JUDGE        = deterministic (no LLM)
PROCESS_JUDGE_MODEL    = "anthropic/claude-opus-4-6"      # reasoning-strong
STRATEGY_JUDGE_MODEL   = "openai/gpt-4o-2025-03-26"      # planning/generalization-strong
INTEGRITY_JUDGE_MODEL  = "google/gemini-2.5-pro"          # adversarial/critique-strong
APPEALS_JUDGE_MODEL    = "anthropic/claude-opus-4-6"      # highest-trust review model
                         # (different session, different prompt, different context than Process)
```

## Diversity Requirements

1. **At least 3 different model families** across Process, Strategy, and Integrity judges
2. **No two primary judges** may use the same model family in the same scoring pass (unless degraded fallback)
3. **Appeals Judge** should ideally be from a different family than the two disagreeing judges
4. **All model IDs explicitly pinned** — never rely on generic aliases, routing defaults, or "latest" tags

## Model Family Strengths (Judge Assignment Rationale)

| Family | Strengths as Judge | Assigned To |
|--------|-------------------|-------------|
| **Claude (Anthropic)** | Nuanced reasoning, process evaluation, multi-step workflow understanding | Process Judge |
| **GPT (OpenAI)** | Structured evaluation, planning assessment, generalization | Strategy Judge |
| **Gemini (Google)** | Adversarial analysis, factual verification, inconsistency detection | Integrity Judge |

These assignments are not permanent — rotate based on calibration data. If calibration shows one model outperforming another on a specific judge role, consider swapping.

## Fallback Chains

### Process Judge
```
Primary:   anthropic/claude-opus-4-6
Fallback:  anthropic/claude-sonnet-4-6
Emergency: google/gemini-2.5-pro          (cross-family, degraded mode)
```

### Strategy Judge
```
Primary:   openai/gpt-4o-2025-03-26
Fallback:  openai/gpt-4o-mini
Emergency: anthropic/claude-sonnet-4-6    (cross-family, degraded mode)
```

### Integrity Judge
```
Primary:   google/gemini-2.5-pro
Fallback:  google/gemini-2.5-flash
Emergency: anthropic/claude-sonnet-4-6    (cross-family, degraded mode)
```

### Appeals Judge
```
Primary:   anthropic/claude-opus-4-6
Fallback:  openai/gpt-4o-2025-03-26
Emergency: google/gemini-2.5-pro
```

## Degraded Mode Rules

| Condition | Status | Action |
|-----------|--------|--------|
| One judge falls back to same-family Fallback | Normal | No flag — still within same family's capability |
| One judge falls back to Emergency (cross-family) | ⚠️ Degraded | Flag run as `scored-in-degraded-mode` |
| Two judges share a model family | ⚠️ Degraded | Flag + lower confidence on affected dimensions |
| All three LLM judges same family | 🔴 Broken | **Halt scoring** — queue runs until diversity restored |
| >50% of day's runs in degraded mode | 🔴 Alert | Notify ops team, investigate provider issues |

## Version Pinning Protocol

1. **Pin to specific model versions**, not "latest"
2. When a model version updates: run calibration suite against held-out benchmarks BEFORE switching
3. If calibration deviation > 3 points average: keep old version until new version is recalibrated
4. Maintain a **changelog** of model version updates and their impact on scoring
5. Version changes are tracked in defensibility reports (Skill 57)

## OpenRouter Configuration

```json
{
  "judges": {
    "process": {
      "provider": "openrouter",
      "model": "anthropic/claude-opus-4-6",
      "fallback_models": ["anthropic/claude-sonnet-4-6", "google/gemini-2.5-pro"],
      "temperature": 0.3,
      "max_tokens": 4096,
      "require_specific_model": true
    },
    "strategy": {
      "provider": "openrouter",
      "model": "openai/gpt-4o-2025-03-26",
      "fallback_models": ["openai/gpt-4o-mini", "anthropic/claude-sonnet-4-6"],
      "temperature": 0.3,
      "max_tokens": 4096,
      "require_specific_model": true
    },
    "integrity": {
      "provider": "openrouter",
      "model": "google/gemini-2.5-pro",
      "fallback_models": ["google/gemini-2.5-flash", "anthropic/claude-sonnet-4-6"],
      "temperature": 0.2,
      "max_tokens": 4096,
      "require_specific_model": true
    },
    "appeals": {
      "provider": "openrouter",
      "model": "anthropic/claude-opus-4-6",
      "fallback_models": ["openai/gpt-4o-2025-03-26", "google/gemini-2.5-pro"],
      "temperature": 0.2,
      "max_tokens": 8192,
      "require_specific_model": true
    }
  }
}
```

## Integration Points

- **Five-Judge Architecture** (Skill 61): Defines which judges exist; this skill defines which models run them
- **Appeals Judge** (Skill 70): Appeals model selection follows diversity rules
- **Judge Calibration** (Skill 66): Calibration must be per-model-version
- **Production Rules** (Skill 76): Diversity is a production gate requirement
