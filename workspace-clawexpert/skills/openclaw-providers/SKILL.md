---
name: openclaw-providers
description: Expert reference for all OpenClaw model providers — Anthropic, OpenAI, Google, Ollama, OpenRouter, GitHub Copilot, and more. Covers model string format (provider/model-id), auth modes (API key / token / OAuth / setup-token), model aliases, prompt caching, cost tracking, and fast mode. Includes our live setup (Anthropic token mode, sonnet-4-6 / opus-4-6 / haiku-4-5).
---

# OpenClaw Providers — Expert Reference

## Changelog
- 2026-03-20: Created from source docs (providers/*, reference/prompt-caching, reference/api-usage-costs)

---

## 1. Provider Overview

OpenClaw supports a wide range of LLM providers. All model references use the format `provider/model-id`.

### Supported Providers (documented in detail below)
- **Anthropic** — Claude family (API key or setup-token)
- **OpenAI** — GPT models (API key or Codex OAuth)
- **Google (Gemini)** — Gemini models (API key or OAuth)
- **Ollama** — Local and cloud models (native API)
- **OpenRouter** — Unified multi-provider gateway
- **GitHub Copilot** — Device-flow OAuth

### Additional Providers (brief entries in index)
Amazon Bedrock, Cloudflare AI Gateway, GLM, Hugging Face, Kilocode, LiteLLM, MiniMax, Mistral, Model Studio, Moonshot AI (Kimi), NVIDIA, OpenCode, Perplexity, Qianfan, Qwen, SGLang, Together AI, Vercel AI Gateway, Venice, vLLM, Volcengine (Doubao), xAI, Xiaomi, Z.AI

### Transcription Providers
- Deepgram (audio transcription)

### Community Tools
- Claude Max API Proxy (community-built, policy risk — see §9)

---

## 2. Model String Format

All model refs use `provider/model-id`:

```
anthropic/claude-opus-4-6
anthropic/claude-sonnet-4-6
anthropic/claude-haiku-4-5
openai/gpt-5.4
openai-codex/gpt-5.4
google/gemini-3.1-pro-preview
ollama/glm-4.7-flash
openrouter/anthropic/claude-sonnet-4-5
github-copilot/gpt-4o
```

Set the default model in config:

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-6",
        fallbacks: ["anthropic/claude-sonnet-4-6"],
      },
    },
  },
}
```

Model aliases (display names for `/model` command):

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-sonnet-4-6": { alias: "Sonnet" },
        "anthropic/claude-opus-4-6": { alias: "Opus" },
        "anthropic/claude-haiku-4-5": { alias: "Haiku" },
      },
    },
  },
}
```

---

## 3. Anthropic (Claude)

Our primary provider. Auth: Anthropic API key OR setup-token (subscription).

### Option A: API Key

Best for production, usage-based billing.

```bash
# Interactive
openclaw onboard
# Non-interactive
openclaw onboard --anthropic-api-key "$ANTHROPIC_API_KEY"
```

Config:
```json5
{
  env: { ANTHROPIC_API_KEY: "sk-ant-..." },
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
```

### Option B: Setup-Token (Subscription / Claude Max)

Best for Claude subscription users. Requires Claude Code CLI (`claude` command).

```bash
# Generate setup-token (on gateway host or any machine)
claude setup-token

# Apply on gateway host
openclaw models auth setup-token --provider anthropic

# If generated on a different machine, paste manually
openclaw models auth paste-token --provider anthropic
```

Config (same as API key — no extra config needed):
```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
```

**⚠️ Auth warning:** Anthropic has blocked some subscription usage outside Claude Code in the past. Verify current terms. API key is the safe production path.

### Claude Models

| Model string | Description |
|---|---|
| `anthropic/claude-opus-4-6` | Most capable, highest cost |
| `anthropic/claude-sonnet-4-6` | Balanced capability/cost — our primary |
| `anthropic/claude-haiku-4-5` | Fast, cheapest — our PM/Haiku agent |

### Thinking Defaults (Claude 4.6)

Claude 4.6 models default to `adaptive` thinking in OpenClaw when no explicit level is set.

Override per-message: `/think:<level>`

Override in config:
```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-6": {
          params: { thinking: "extended" },
        },
      },
    },
  },
}
```

### Fast Mode (API Key Only)

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-sonnet-4-5": {
          params: { fastMode: true },
        },
      },
    },
  },
}
```

- `/fast on` → `service_tier: "auto"`
- `/fast off` → `service_tier: "standard_only"`
- **API key only** — does NOT work with setup-token/OAuth
- Only applies to direct `api.anthropic.com` requests

### Prompt Caching (API Key Only)

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-6": {
          params: { cacheRetention: "long" },
        },
      },
    },
  },
}
```

| Value | Duration | Notes |
|---|---|---|
| `none` | No caching | Disabled |
| `short` | 5 minutes | **Default for API key auth** |
| `long` | 1 hour | Requires beta flag (auto-included) |

Legacy values still supported: `"5m"` → `short`, `"1h"` → `long`

**API key default:** OpenClaw automatically applies `cacheRetention: "short"` for all Anthropic models when using API key auth.

Per-agent cache override:
```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-6": {
          params: { cacheRetention: "long" },
        },
      },
    },
    list: [
      { id: "research", default: true },
      { id: "alerts", params: { cacheRetention: "none" } },
    ],
  },
}
```

Config merge order:
1. `agents.defaults.models["provider/model"].params`
2. `agents.list[].params` (overrides by key for that agent)

### 1M Context Window (Beta)

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-6": {
          params: { context1m: true },
        },
      },
    },
  },
}
```

- Maps to `anthropic-beta: context-1m-2025-08-07`
- Requires billing-eligible API key or Anthropic Extra Usage on subscription
- **NOT supported with OAuth/subscription tokens** — OpenClaw automatically skips this header for OAuth auth

### Bedrock Claude Notes

- Claude models on Bedrock (`amazon-bedrock/*anthropic.claude*`) support `cacheRetention` pass-through
- Non-Anthropic Bedrock models are forced to `cacheRetention: "none"` at runtime

### Anthropic Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| 401 / token invalid | Setup-token expired | Re-run `claude setup-token`, re-paste |
| "No API key found" | New agent, no auth | Re-run onboarding for that agent |
| "No credentials found for profile" | Missing profile | Run `openclaw models status` |
| "No available auth profile (all in cooldown)" | Rate limits | Check `openclaw models status --json` → `auth.unusableProfiles` |
| "This credential is only authorized for Claude Code" | Subscription blocked | Use API key instead |
| "Extra usage required for long context" | context1m on non-eligible account | Disable `params.context1m: true` |

---

## 4. OpenAI

### Option A: API Key

```bash
openclaw onboard --auth-choice openai-api-key
# or
openclaw onboard --openai-api-key "$OPENAI_API_KEY"
```

```json5
{
  env: { OPENAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "openai/gpt-5.4" } } },
}
```

Current models: `openai/gpt-5.4`, `openai/gpt-5.4-pro`

Note: `openai/gpt-5.3-codex-spark` is Codex-only; direct API path rejects it.

### Option B: Codex Subscription (OAuth)

```bash
openclaw onboard --auth-choice openai-codex
# or
openclaw models auth login --provider openai-codex
```

```json5
{
  agents: { defaults: { model: { primary: "openai-codex/gpt-5.4" } } },
}
```

Codex Spark (if entitled): `openai-codex/gpt-5.3-codex-spark`

### Transport Mode

Default: `"auto"` (WebSocket-first, SSE fallback)

```json5
{
  agents: {
    defaults: {
      models: {
        "openai-codex/gpt-5.4": {
          params: { transport: "auto" },  // "sse" | "websocket" | "auto"
        },
      },
    },
  },
}
```

### WebSocket Warm-up

OpenClaw enables WebSocket warm-up by default for `openai/*` to reduce first-turn latency.

```json5
// Disable warm-up
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: { openaiWsWarmup: false },
        },
      },
    },
  },
}
```

### OpenAI Priority Processing

```json5
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: { serviceTier: "priority" },  // auto | default | flex | priority
        },
      },
    },
  },
}
```

### OpenAI Fast Mode

```json5
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: { fastMode: true },
        },
        "openai-codex/gpt-5.4": {
          params: { fastMode: true },
        },
      },
    },
  },
}
```

When enabled:
- `reasoning.effort = "low"` (if not already set)
- `text.verbosity = "low"` (if not already set)
- `service_tier = "priority"` for direct `openai/*` Responses calls

### OpenAI Server-Side Compaction

For direct OpenAI Responses models, OpenClaw auto-enables server-side compaction:
- Forces `store: true`
- Injects `context_management` with `compact_threshold: 70%` of model contextWindow (or 80000)

```json5
// Disable compaction
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: { responsesServerCompaction: false },
        },
      },
    },
  },
}

// Custom threshold
{
  agents: {
    defaults: {
      models: {
        "openai/gpt-5.4": {
          params: {
            responsesServerCompaction: true,
            responsesCompactThreshold: 120000,
          },
        },
      },
    },
  },
}
```

---

## 5. Google (Gemini)

Provider: `google`
Auth: `GEMINI_API_KEY` or `GOOGLE_API_KEY`

```bash
openclaw onboard --auth-choice google-api-key
# Non-interactive
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice google-api-key \
  --gemini-api-key "$GEMINI_API_KEY"
```

```json5
{
  agents: {
    defaults: {
      model: { primary: "google/gemini-3.1-pro-preview" },
    },
  },
}
```

### OAuth (Gemini CLI)

Alternative provider `google-gemini-cli` uses PKCE OAuth.
**Use at your own risk** — unofficial integration, some account restrictions reported.

Env vars:
- `OPENCLAW_GEMINI_OAUTH_CLIENT_ID`
- `OPENCLAW_GEMINI_OAUTH_CLIENT_SECRET`

### Gemini Capabilities

| Capability | Supported |
|---|---|
| Chat completions | Yes |
| Image generation | Yes |
| Image understanding | Yes |
| Audio transcription | Yes |
| Video understanding | Yes |
| Web search (Grounding) | Yes |
| Thinking/reasoning | Yes (Gemini 3.1+) |

---

## 6. Ollama (Local / Cloud)

Native Ollama API (`/api/chat`). Supports local and cloud models.

**⚠️ Critical:** Do NOT use `/v1` URL. Use native Ollama URL: `http://host:11434` (no `/v1`). Using `/v1` breaks tool calling.

### Quick Setup

```bash
# Install Ollama: https://ollama.com/download

# Pull a local model
ollama pull glm-4.7-flash

# Sign in for cloud models (optional)
ollama signin

# Onboard
openclaw onboard
# Select: Ollama → Local or Cloud + Local
```

### Non-interactive

```bash
openclaw onboard --non-interactive \
  --auth-choice ollama \
  --custom-base-url "http://ollama-host:11434" \
  --custom-model-id "qwen3.5:27b" \
  --accept-risk
```

### Implicit Auto-Discovery

Set `OLLAMA_API_KEY` (any value) **without** defining `models.providers.ollama` to enable auto-discovery:

```bash
export OLLAMA_API_KEY="ollama-local"
```

OpenClaw will:
- Query `/api/tags` for models
- Use `/api/show` lookups for `contextWindow`
- Auto-detect reasoning models (names containing `r1`, `reasoning`, `think`)
- Set all costs to `$0`

### Explicit Config (Remote Host or Manual)

```json5
{
  models: {
    providers: {
      ollama: {
        baseUrl: "http://ollama-host:11434",  // No /v1
        apiKey: "ollama-local",
        api: "ollama",  // Use native API for reliable tool calling
        models: [
          {
            id: "gpt-oss:20b",
            name: "GPT-OSS 20B",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 8192,
            maxTokens: 81920,
          },
        ],
      },
    },
  },
}
```

### Model Selection

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "ollama/glm-4.7-flash",
        fallbacks: ["ollama/llama3.3", "ollama/qwen2.5-coder:32b"],
      },
    },
  },
}
```

### Cloud Models (via ollama.com)

Requires `ollama signin` or Cloud + Local mode. No local pull needed.

Suggested cloud models:
- `ollama/kimi-k2.5:cloud`
- `ollama/minimax-m2.5:cloud`
- `ollama/glm-5:cloud`

### Legacy OpenAI-Compatible Mode (Not Recommended)

Only if you need OpenAI format for a proxy AND don't rely on tool calling:

```json5
{
  models: {
    providers: {
      ollama: {
        baseUrl: "http://ollama-host:11434/v1",
        api: "openai-completions",
        injectNumCtxForOpenAICompat: true,  // prevent 4096 context fallback
        apiKey: "ollama-local",
        models: [...],
      },
    },
  },
}
```

---

## 7. OpenRouter

Unified API for many models behind a single key.

```bash
openclaw onboard --auth-choice apiKey --token-provider openrouter --token "$OPENROUTER_API_KEY"
```

```json5
{
  env: { OPENROUTER_API_KEY: "sk-or-..." },
  agents: {
    defaults: {
      model: { primary: "openrouter/anthropic/claude-sonnet-4-5" },
    },
  },
}
```

Model format: `openrouter/<provider>/<model>`

Examples:
- `openrouter/anthropic/claude-sonnet-4-5`
- `openrouter/openai/gpt-4o`
- `openrouter/google/gemini-pro`

### Cache on OpenRouter Anthropic Models

For `openrouter/anthropic/*` models, OpenClaw injects Anthropic `cache_control` on system/developer prompt blocks automatically to improve cache reuse.

---

## 8. GitHub Copilot

Two modes:
1. **`github-copilot`** — Built-in device-flow OAuth (recommended)
2. **`copilot-proxy`** — VS Code extension bridge

### Built-in Flow

```bash
openclaw models auth login-github-copilot
# Visit URL, enter one-time code, keep terminal open
```

```json5
{
  agents: { defaults: { model: { primary: "github-copilot/gpt-4o" } } },
}
```

### Optional Flags

```bash
openclaw models auth login-github-copilot --profile-id github-copilot:work
openclaw models auth login-github-copilot --yes
```

**Note:** Requires interactive TTY. Model availability depends on your Copilot plan.

---

## 9. Claude Max API Proxy (Community Tool)

Exposes Claude Max/Pro subscription as an OpenAI-compatible endpoint.

**⚠️ Policy warning:** Anthropic has blocked some subscription usage outside Claude Code in the past. Use at your own risk.

```bash
npm install -g claude-max-api-proxy
claude-max-api  # runs at http://localhost:3456
```

Use with OpenClaw:
```json5
{
  env: {
    OPENAI_API_KEY: "not-needed",
    OPENAI_BASE_URL: "http://localhost:3456/v1",
  },
  agents: {
    defaults: {
      model: { primary: "openai/claude-opus-4" },
    },
  },
}
```

Available model IDs: `claude-opus-4`, `claude-sonnet-4`, `claude-haiku-4`

Cost comparison:
| Approach | Cost | Best For |
|---|---|---|
| Anthropic API | ~$15/M input, $75/M output (Opus) | Production, high volume |
| Claude Max subscription | $200/month flat | Personal use, development |

---

## 10. Prompt Caching (Deep Reference)

Prompt caching reuses unchanged prompt prefixes across turns. Reduces cost and latency for long-running sessions.

First matching request: writes `cacheWrite` tokens
Later matching requests: reads `cacheRead` tokens (cheaper)

### Primary Config Knob: `cacheRetention`

```yaml
agents:
  defaults:
    models:
      "anthropic/claude-opus-4-6":
        params:
          cacheRetention: "short"  # none | short | long
```

### Context Pruning with Cache TTL

Prune old tool-result context after cache TTL windows:

```yaml
agents:
  defaults:
    contextPruning:
      mode: "cache-ttl"
      ttl: "1h"
```

### Heartbeat Cache Keep-Warm

Heartbeat can keep cache windows warm and prevent repeated cache writes after idle gaps:

```yaml
agents:
  defaults:
    heartbeat:
      every: "55m"  # just under the 1h cache TTL
```

### Mixed Traffic Pattern (Recommended)

```yaml
agents:
  defaults:
    model:
      primary: "anthropic/claude-opus-4-6"
    models:
      "anthropic/claude-opus-4-6":
        params:
          cacheRetention: "long"
  list:
    - id: "research"
      default: true
      heartbeat:
        every: "55m"
    - id: "alerts"
      params:
        cacheRetention: "none"  # bursty/low-reuse traffic
```

### Cache Diagnostics

```yaml
diagnostics:
  cacheTrace:
    enabled: true
    filePath: "~/.openclaw/logs/cache-trace.jsonl"
    includeMessages: false
    includePrompt: false
    includeSystem: false
```

Env toggles (one-off debugging):
```bash
OPENCLAW_CACHE_TRACE=1
OPENCLAW_CACHE_TRACE_FILE=/path/to/cache-trace.jsonl
OPENCLAW_CACHE_TRACE_MESSAGES=0|1
OPENCLAW_CACHE_TRACE_PROMPT=0|1
OPENCLAW_CACHE_TRACE_SYSTEM=0|1
```

Events in JSONL: `session:loaded`, `prompt:before`, `stream:context`, `session:after`

Per-turn cache impact visible in `/usage full` and session usage summaries (`cacheRead`, `cacheWrite`).

### Cache Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| High `cacheWrite` on most turns | Volatile system-prompt inputs | Check for dynamic system prompt content |
| No effect from `cacheRetention` | Model key mismatch | Confirm key matches `agents.defaults.models["provider/model"]` |
| Bedrock Nova/Mistral with cache | Expected | Non-Anthropic Bedrock forced to `none` at runtime |

---

## 11. API Usage and Cost Tracking

### Where Costs Appear

- `/status` — current session model, context, last response tokens, **estimated cost** (API key only)
- `/usage full` — appends usage footer with **estimated cost** (API key only; OAuth hides dollar cost)
- `/usage tokens` — tokens only
- `openclaw status --usage` — provider usage windows (quota snapshots)
- `openclaw channels list` — provider usage windows

### Credential Discovery Order

OpenClaw discovers credentials from (in order):
1. Auth profiles (per-agent `auth-profiles.json`)
2. Environment variables (`OPENAI_API_KEY`, `BRAVE_API_KEY`, etc.)
3. Config (`models.providers.*.apiKey`)
4. Skills (`skills.entries.<name>.apiKey`)

### API Key Rotation (Rate Limit Handling)

Priority order for key rotation on `429` rate limits:
1. `OPENCLAW_LIVE_<PROVIDER>_KEY` (single override)
2. `<PROVIDER>_API_KEYS`
3. `<PROVIDER>_API_KEY`
4. `<PROVIDER>_API_KEY_*`

Non-rate-limit errors are NOT retried with alternate keys.

### Features That Can Spend Keys

| Feature | Keys Used |
|---|---|
| Core model responses | Primary model provider |
| Audio transcription | OpenAI / Groq / Deepgram |
| Image understanding | OpenAI / Anthropic / Google |
| Video understanding | Google |
| Memory embeddings | OpenAI/Gemini/Voyage/Mistral/Ollama (if configured) |
| Web search | Brave / Gemini / Grok / Kimi / Perplexity |
| Web fetch (Firecrawl) | `FIRECRAWL_API_KEY` (optional) |
| Compaction summarization | Current model |
| Model scan/probe | `OPENROUTER_API_KEY` (if probing) |
| Talk/TTS | ElevenLabs (`ELEVENLABS_API_KEY`) |
| Skills (third-party) | Skill-specific `apiKey` |

### Web Search Keys

- Brave: `BRAVE_API_KEY` — $5/mo free credit (1,000 requests); set dashboard limit
- Gemini: `GEMINI_API_KEY`
- Grok: `XAI_API_KEY`
- Kimi: `KIMI_API_KEY` or `MOONSHOT_API_KEY`
- Perplexity: `PERPLEXITY_API_KEY` or `OPENROUTER_API_KEY`

---

## 12. Auth Management CLI

```bash
# Check auth status
openclaw models status
openclaw models status --json
openclaw models status --check  # exit 1 if expired, exit 2 if expiring

# Per-session model pin with specific credential profile
/model anthropic/claude-sonnet-4-6@anthropic:default

# Per-agent auth profile order
openclaw models auth order get --provider anthropic
openclaw models auth order set --provider anthropic anthropic:default
openclaw models auth order clear --provider anthropic --agent myagent

# Paste token manually
openclaw models auth paste-token --provider anthropic
openclaw models auth paste-token --provider openrouter

# Setup-token flow
openclaw models auth setup-token --provider anthropic
```

---

## 13. Our Setup

### Active Provider: Anthropic (Setup-Token / Token Mode)

| Agent | Model | Auth |
|---|---|---|
| Maks (main/coding) | `anthropic/claude-sonnet-4-6` | Setup-token |
| MaksPM (pm) | `anthropic/claude-haiku-4-5` | Setup-token |
| Scout (research) | `anthropic/claude-opus-4-6` | Setup-token |
| ClawExpert (ops) | `anthropic/claude-sonnet-4-6` | Setup-token |

### Config Pattern

```json5
{
  agents: {
    defaults: {
      model: { primary: "anthropic/claude-sonnet-4-6" },
      models: {
        "anthropic/claude-sonnet-4-6": { alias: "Sonnet" },
        "anthropic/claude-opus-4-6": { alias: "Opus" },
        "anthropic/claude-haiku-4-5": { alias: "Haiku" },
      },
    },
  },
}
```

### Important: Setup-Token Limitations

Because we use **setup-token (OAuth/subscription) auth**, the following features are DISABLED:
- Prompt caching (`cacheRetention` has no effect)
- Fast mode (`/fast on` has no effect)
- 1M context window (`params.context1m: true` is silently skipped)
- Cost display (`/status` and `/usage full` do NOT show dollar costs)

Default heartbeat interval is `1h` (not `30m`) because we use OAuth auth.

### Auth Troubleshooting (Our Setup)

```bash
# Check status
openclaw models status

# Re-auth if expired
claude setup-token
openclaw models auth paste-token --provider anthropic

# Verify
openclaw models status
openclaw doctor
```

If auth fails with "credential only authorized for Claude Code" — we need to switch to API key auth.

### Brave Search

We use Brave Search API for web_search:
- Key: `BRAVE_API_KEY`
- Free: $5/month credit (1,000 requests)
- Set usage limit in Brave dashboard to avoid unexpected charges
