---
name: repo-watch
description: Protocol for monitoring repo changes and extracting new knowledge.
---

# Changelog
- 2026-03-19: Setup with 3 repos (anthropic-sdk-node 404'd)

# Repository Watch Protocol

## Repos (3 active, 1 unavailable)
1. `repos/openclaw` — github.com/openclaw/openclaw ✅
2. `repos/nemoclaw` — github.com/NVIDIA/NemoClaw ✅
3. `repos/anthropic-sdk-python` — github.com/anthropics/anthropic-sdk-python ✅
4. `repos/anthropic-sdk-node` — github.com/anthropics/anthropic-sdk-node ❌ (404 - doesn't exist)

## Update Script
```bash
cd /data/.openclaw/workspace-clawexpert
for repo in repos/openclaw repos/nemoclaw repos/anthropic-sdk-python; do
  if [ -d "$repo/.git" ]; then
    echo "=== Updating $repo ==="
    cd /data/.openclaw/workspace-clawexpert/$repo
    git fetch origin --depth 1 2>/dev/null
    CHANGES=$(git log HEAD..origin/main --oneline 2>/dev/null || git log HEAD..origin/HEAD --oneline 2>/dev/null | wc -l)
    echo "$CHANGES new commits"
    [ "$CHANGES" -gt "0" ] && git pull 2>/dev/null
    cd /data/.openclaw/workspace-clawexpert
  fi
done
```

## Priority Files (re-read immediately if changed)
- `src/config/zod-schema.ts` — root config schema, most critical
- `src/config/zod-schema.*.ts` — sub-schemas
- `src/acp/translator.ts` — MCP capabilities
- `CHANGELOG.md` — release notes
- `package.json` — version bump indicator
- `Dockerfile*`, `docker-compose.yml` — container changes
- `nemoclaw/openclaw.plugin.json` — NemoClaw plugin manifest
- `src/anthropic/types/model_param.py` — new model IDs

## Alert Triggers (send immediately to owner)
- Config schema root keys changed → update openclaw-schema-map + CRITICAL alert
- MCP handling changed → update openclaw-source-code skill
- New root-level schema keys added/removed → config compat risk
- Security advisory in SECURITY.md
- Major version bump (e.g., 2026.x.x)
- New model IDs available
- NemoClaw goes beta/stable

## Size Management
Current sizes:
```bash
du -sh repos/openclaw repos/nemoclaw repos/anthropic-sdk-python
```
If repos exceed 500MB total: re-clone with `--depth 1`

## Version Tracking
| Repo | Cloned Version | Our Running Version | Delta |
|------|---------------|---------------------|-------|
| openclaw | 2026.3.14 | 2026.3.13 | +1 patch |
| nemoclaw | 0.1.0-alpha | N/A (not installed) | — |
| anthropic-sdk-python | latest | N/A | — |

## What Changed in openclaw 2026.3.14 vs 2026.3.13 (Unreleased)
Key new features in HEAD (not yet in our 2026.3.13):
- `/btw` side-questions command
- OpenShell sandbox backend (pluggable sandbox system)
- Firecrawl integration (bundled plugin)
- Bundle plugins: Codex, Claude, Cursor
- Android dark theme
- Feishu ACP bindings
- Claude marketplace registry
- `/plugins` chat commands
- NemoClaw plugin support
- `gpt-5.4-mini` / `gpt-5.4-nano` in OpenAI catalog
- Gateway health monitor improvements (stale event threshold, restart limits)
- `browser.profiles.<name>.userDataDir` support
