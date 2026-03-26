---
name: nemoclaw-patterns
description: Patterns from NVIDIA NemoClaw — security, sandboxing, enterprise agent patterns.
---

# Changelog
- 2026-03-19: Initial analysis from repos/nemoclaw (v0.1.0, alpha, Apache 2.0, GTC 2026-03-16)

# NemoClaw Intelligence

## What Is It
NVIDIA's enterprise security layer ON TOP of OpenClaw. NOT a fork — it's an **OpenClaw plugin**.
- Apache 2.0 license
- Announced GTC 2026 (March 16, 2026)
- **Alpha software** — interfaces may change
- Repo: `/data/.openclaw/workspace-clawexpert/repos/nemoclaw`

## How NemoClaw Extends OpenClaw
- **Mechanism**: OpenClaw **plugin** (`openclaw.plugin.json` with id: `nemoclaw`)
- **NOT a fork** — runs as a plugin inside existing OpenClaw installation
- Installs via: `curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash`
- Provides CLI commands: `nemoclaw <name> connect/status/logs/migrate`
- Plugin config keys (in `plugins.entries.nemoclaw.config`):
  - `blueprintVersion` — pinned blueprint OCI version (default: "latest")
  - `blueprintRegistry` — OCI registry (default: "ghcr.io/nvidia/nemoclaw-blueprint")
  - `sandboxName` — sandbox name in OpenShell (default: "openclaw")
  - `inferenceProvider` — nvidia/vllm/openai-compatible (default: "nvidia")

## OpenShell Runtime
- **What**: k3s-based sandbox with Landlock + seccomp + network namespace isolation
- **How**: Runs OpenClaw INSIDE a container with strict security policies
- **Hardware**: Min 4 vCPU / 8GB RAM / 20GB disk; sandbox image ~2.4GB compressed
- **Model**: Routes to NVIDIA NIM cloud by default (nvidia/nemotron models)
- **Workspace modes**: `mirror` (sync from host) or `remote` (live in sandbox)

## Security Policies (openclaw-sandbox.yaml)
```yaml
# Filesystem
read_only: /usr, /lib, /proc, /dev/urandom, /app, /etc, /var/log
read_write: /sandbox, /tmp, /dev/null
landlock: best_effort (kernel-level filesystem sandboxing)

# Process
run_as_user: sandbox (non-root)
run_as_group: sandbox

# Network — Network namespace isolation + explicit allowlist
# claude_code policy allows: api.anthropic.com:443, statsig.anthropic.com:443, sentry.io:443
# All other outbound blocked by default
# Dynamic policies can be added via: openshell policy set
```

## Applicable Patterns for Our Setup

### Pattern 1: Network Namespace Egress Control
NemoClaw enforces egress via explicit endpoint allowlists. We can adapt by reviewing our Docker network config to limit unnecessary outbound access.

### Pattern 2: Non-Root Process Execution
NemoClaw runs OpenClaw as `sandbox` user, not root. Our container should verify it's not running as root unnecessarily.

### Pattern 3: Read-Only Filesystem Mounting
Key system paths (`/usr`, `/lib`, `/etc`) are mounted read-only. Good Docker security practice we can review for our container.

### Pattern 4: Plugin-Based Extension (NOT config keys)
NemoClaw proves the correct way to extend OpenClaw is via plugins with `openclaw.plugin.json`, NOT by adding unknown keys to `openclaw.json`.

### Pattern 5: Dynamic Policy Updates
Post-creation policies can be updated without restart via `openshell policy set` — analogous to our `openclaw config set` pattern.

## Migration Path (if we ever want NemoClaw)
- **Requirements**: OpenShell installed (k3s), 8GB+ RAM, Linux (Ubuntu 22.04+)
- **Process**: Run installer script → guided onboard wizard
- **Breaking changes**: OpenClaw runs INSIDE sandbox — filesystem paths change
- **Benefits**: Landlock + seccomp + network namespace isolation for autonomous agents
- **Risks**: Alpha software, NVIDIA NIM API dependency for inference, significant resource overhead
- **Recommendation**: Watch but don't adopt until production-ready (currently alpha)

## Key Files
- `nemoclaw/openclaw.plugin.json` — plugin manifest
- `nemoclaw/src/index.ts` — plugin entry point (OpenClaw plugin SDK)
- `nemoclaw-blueprint/policies/openclaw-sandbox.yaml` — security policy
- `nemoclaw-blueprint/orchestrator/runner.py` — sandbox orchestration
