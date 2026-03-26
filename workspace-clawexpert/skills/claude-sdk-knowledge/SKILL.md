---
name: claude-sdk-knowledge
description: Knowledge from Anthropic Claude SDK — auth, streaming, tool use, message structure.
---

# Changelog
- 2026-03-19: Initial extraction from repos/anthropic-sdk-python (latest)

# Claude SDK Intelligence

## Repos
- Python: `repos/anthropic-sdk-python`
- Node: NOT CLONED (404 — anthropic-sdk-node doesn't exist; OpenClaw uses its own internal wrapper)

## Why We Study This
- Auth understanding helps debug 401 errors  
- Streaming understanding helps diagnose timeouts  
- Tool use understanding helps optimize agent performance  
- Model string knowledge helps with config

## Auth & Tokens (from _client.py)
- **API key env var**: `ANTHROPIC_API_KEY`
- **Auth token env var**: `ANTHROPIC_AUTH_TOKEN`
- **API key header**: `X-Api-Key: <key>`
- **Auth token header**: `Authorization: Bearer <token>`
- **Two auth modes**: api_key (default) OR auth_token (OAuth/token mode)
- **Auth resolution**: Checks explicit param → falls back to env var
- **Error if neither**: `"Could not resolve authentication method. Expected either api_key or auth_token to be set."`
- **OpenClaw equivalent**: `auth.profiles.<name>.mode: "api_key" | "oauth" | "token"`
- **Default retries**: `DEFAULT_MAX_RETRIES` (auto-retry on transient errors)

## Valid Model Strings (from types/model_param.py — as of 2026-03-19)
```
claude-opus-4-6          (latest opus)
claude-sonnet-4-6        (latest sonnet — our primary model)
claude-haiku-4-5         (latest haiku — our PM model)
claude-haiku-4-5-20251001
claude-opus-4-5
claude-opus-4-5-20251101
claude-sonnet-4-5
claude-sonnet-4-5-20250929
claude-opus-4-1
claude-opus-4-1-20250805
claude-opus-4-0
claude-opus-4-20250514
claude-sonnet-4-0
claude-sonnet-4-20250514
claude-3-haiku-20240307
```
Note: SDK types are a Union[Literal[...], str] so any string is accepted — these are the known validated IDs.

## Message Structure
- Client classes: `Anthropic` (sync) and `AsyncAnthropic` (async)
- `messages.create()` — primary API call
- Resources: messages, models, completions (legacy), beta

## Streaming
- `Stream` and `AsyncStream` classes in `_streaming.py`
- SSE-based event streaming
- `stream=True` parameter on `messages.create()`

## Error Handling
- `APIStatusError` for HTTP errors
- 401 = auth failed (check api_key format, check if key is active)
- 429 = rate limit (OpenClaw has built-in backoff via `auth.cooldowns`)
- Retry logic built into base client

## Practical Debugging Tips
1. **401 error** → API key wrong, expired, or wrong header format
2. **Auth token mode** → uses `Authorization: Bearer` not `X-Api-Key`
3. **Model not found** → use exact model string from list above
4. **Rate limit 429** → OpenClaw `auth.cooldowns.billingBackoffHours` controls backoff
5. **Streaming timeout** → check `gateway.remote.url` if using remote mode

## OpenClaw Auth Config (what maps to what)
```json
{
  "auth": {
    "profiles": {
      "anthropic-main": {
        "provider": "anthropic",
        "mode": "api_key"
      }
    }
  }
}
```
The `ANTHROPIC_API_KEY` env var is the simplest path — no config needed.
