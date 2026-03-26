---
name: nemoclaw-deep
description: Deep NemoClaw analysis — NVIDIA's enterprise multi-tenant OpenClaw fork. Architecture, isolation model, sandbox policies, enterprise deployment patterns, and applicable patterns for Perlantir.
---

# NemoClaw Deep Analysis

## Changelog
- 2026-03-20: Created from full nemoclaw repo analysis (all source files, policies, docs, scripts)

---

## 1. NemoClaw Overview

### What It Is

NemoClaw is NVIDIA's open-source plugin that sandboxes OpenClaw inside NVIDIA OpenShell — a secure container runtime from the NVIDIA Agent Toolkit. It is NOT a fork of OpenClaw. It is an OpenClaw plugin + orchestration layer that wraps OpenClaw in a hardened execution environment with:

- Kernel-level process isolation (Landlock + seccomp + network namespaces)
- Declarative network egress policy (YAML-defined allowlists, deny-by-default)
- Filesystem access control (read-only system paths, read-write only /sandbox and /tmp)
- Inference routing (all model API calls intercepted and redirected through the OpenShell gateway)
- Versioned blueprint system for reproducible, auditable deployments

### Maturity: **Alpha**

From the README badge and self-documentation:
> "Alpha software. NemoClaw is early-stage. Expect rough edges. Interfaces, APIs, and behavior may change without notice."

Blueprint version: `0.1.0`. Not production-ready. Shared for community feedback and early experimentation.

### NVIDIA's Goals

1. Make running autonomous OpenClaw agents safe by default
2. Route all inference to NVIDIA cloud (Nemotron models via build.nvidia.com) — aligns with NVIDIA's AI services business
3. Give enterprises a portable, auditable agent deployment pattern
4. Provide operator visibility into agent network behavior with real-time approval/deny flows
5. Enable GPU-accelerated local inference (NIM containers, vLLM) as an alternative to cloud

### How It Differs From OpenClaw

| Dimension | OpenClaw | NemoClaw |
|---|---|---|
| Execution environment | Runs on bare host or in Docker | Runs inside OpenShell sandbox |
| Network control | No restrictions | Deny-by-default with YAML allowlist |
| Filesystem control | Full host access | Confined to /sandbox + /tmp |
| Inference routing | Direct API calls to any provider | All calls intercepted by OpenShell gateway |
| Process isolation | None beyond Docker | Landlock LSM + seccomp |
| Deployment model | Direct or Docker Compose | Blueprint-driven via openshell CLI |
| Credential handling | openclaw.json / env vars | ~/.nemoclaw/credentials.json (mode 600) |
| Multi-sandbox | Not native | Registry-aware multi-sandbox (sandboxes.json) |

---

## 2. Multi-Tenant Architecture

NemoClaw supports **multiple named sandboxes** on a single host through a local registry at `~/.nemoclaw/sandboxes.json`. This is the foundation for any multi-tenant pattern.

### Registry Model

Each sandbox is a named OpenShell container with isolated:
- Network namespace (own egress policy, separate from other sandboxes)
- Filesystem (each sandbox has its own /sandbox root)
- Inference route (each sandbox can point to different provider/model)
- Policy preset set (tracked per-sandbox)

Registry entry structure:
```json
{
  "name": "my-assistant",
  "createdAt": "2026-03-20T...",
  "model": "nvidia/nemotron-3-super-120b-a12b",
  "nimContainer": null,
  "provider": "nvidia-nim",
  "gpuEnabled": false,
  "policies": ["telegram", "npm"]
}
```

The `defaultSandbox` key tracks which sandbox is the default when no name is specified.

### Multi-Sandbox CLI Pattern

```bash
nemoclaw my-assistant status     # Query specific sandbox
nemoclaw my-assistant connect    # Shell into specific sandbox
nemoclaw my-assistant logs -f    # Follow specific sandbox logs
```

Each sandbox is independently created, managed, and destroyed. The onboard wizard supports recreating or keeping existing sandboxes.

### Tenant Isolation Mechanism

Since NemoClaw uses OpenShell (which runs k3s internally), each sandbox is a separate container pod with:
- Its own network namespace (complete network isolation between sandboxes)
- Independent filesystem mount (no shared state between sandboxes)
- Per-sandbox policy (different tenants can have different allowlists)
- Per-sandbox inference route (different tenants can use different models)

**Current limitation**: Multi-tenancy is per-host, not distributed. No cross-host orchestration exists yet. This is a single-machine multi-process pattern, not Kubernetes multi-cluster.

---

## 3. Sandbox Isolation Model

### The Core Policy File: `openclaw-sandbox.yaml`

Location: `nemoclaw-blueprint/policies/openclaw-sandbox.yaml`

Design principle: **deny by default, allow only what's needed for core functionality.**

#### Filesystem Policy (Creation-Locked — Cannot Change at Runtime)

```yaml
filesystem_policy:
  include_workdir: true
  read_only:
    - /usr
    - /lib
    - /proc
    - /dev/urandom
    - /app
    - /etc
    - /var/log
  read_write:
    - /sandbox
    - /tmp
    - /dev/null
```

Key points:
- System directories (/usr, /lib, /app, /etc) are **read-only** — agent cannot modify them
- Only /sandbox and /tmp are writable — all agent work happens here
- /var/log is read-only — agent can read logs but not write them
- /proc is read-only — agent can introspect process state but not modify
- Filesystem policy is **static** — locked at sandbox creation time, cannot be hot-reloaded

#### Process Policy (Creation-Locked)

```yaml
process:
  run_as_user: sandbox
  run_as_group: sandbox
```

The agent process runs as a dedicated `sandbox` user, not root. Combined with Landlock + seccomp, this prevents privilege escalation. The `sandbox` user has no sudo access.

#### Landlock LSM Enforcement

```yaml
landlock:
  compatibility: best_effort
```

Landlock is Linux's newest filesystem access control mechanism (kernel 5.13+). `best_effort` mode means it applies where available but doesn't fail if the kernel doesn't support it. This is a defense-in-depth layer on top of Docker's own filesystem restrictions.

#### Network Policies (Hot-Reloadable)

Network policies CAN be updated at runtime via `openshell policy set <file>` without sandbox restart. This is the key operational difference from filesystem policy.

Default allowed endpoints by policy group:

| Policy Group | Allowed Hosts | Allowed Binaries | Methods |
|---|---|---|---|
| `claude_code` | api.anthropic.com, statsig.anthropic.com, sentry.io | /usr/local/bin/claude | All |
| `nvidia` | integrate.api.nvidia.com, inference-api.nvidia.com | /usr/local/bin/claude, /usr/local/bin/openclaw | All |
| `github` | github.com, api.github.com | /usr/bin/gh, /usr/bin/git | All |
| `clawhub` | clawhub.com | /usr/local/bin/openclaw | GET, POST |
| `openclaw_api` | openclaw.ai | /usr/local/bin/openclaw | GET, POST |
| `openclaw_docs` | docs.openclaw.ai | /usr/local/bin/openclaw | GET only |
| `npm_registry` | registry.npmjs.org | /usr/local/bin/openclaw, npm | All |
| `telegram` | api.telegram.org | Any binary | GET, POST /bot*/** |

**Binary-level enforcement** is a standout feature: the policy specifies WHICH binary can reach WHICH endpoint. The `github` policy restricts GitHub API access to only `gh` and `git` binaries — a curl command from within the agent cannot reach GitHub. This is far more granular than typical firewall rules.

#### TLS Termination

All policies include `tls: terminate` — OpenShell terminates TLS at the gateway and re-establishes it. This enables deep packet inspection and policy enforcement on HTTPS traffic.

### Policy Preset System

NemoClaw ships 8 ready-to-use policy presets that can be applied on top of the baseline:

| Preset | Endpoints Covered |
|---|---|
| `telegram` | api.telegram.org (bot API only) |
| `slack` | slack.com, api.slack.com, hooks.slack.com |
| `discord` | discord.com, gateway.discord.gg, cdn.discordapp.com |
| `npm` | registry.npmjs.org, registry.yarnpkg.com |
| `pypi` | pypi.org, files.pythonhosted.org |
| `docker` | registry-1.docker.io, auth.docker.io, nvcr.io, authn.nvidia.com |
| `huggingface` | huggingface.co, cdn-lfs.huggingface.co, api-inference.huggingface.co |
| `jira` | *.atlassian.net, auth.atlassian.com, api.atlassian.com |
| `outlook` | graph.microsoft.com, login.microsoftonline.com, outlook.office365.com |

Auto-detection: during onboarding, NemoClaw scans for `TELEGRAM_BOT_TOKEN`, `SLACK_BOT_TOKEN`, `DISCORD_BOT_TOKEN` env vars and suggests the relevant preset automatically.

Preset application mechanism:
1. Load current policy from `openshell policy get --full <sandbox>`
2. Parse metadata header (Version, Hash) and extract the actual YAML
3. Merge preset's `network_policies` section into existing policy YAML
4. Write to temp file and apply with `openshell policy set --policy <tmpfile> --wait <sandbox>`
5. Record applied presets in the sandbox registry

---

## 4. Enterprise Deployment Patterns

### Blueprint Lifecycle (Core Deployment Abstraction)

The blueprint is NemoClaw's answer to "how do I make deployment reproducible and auditable?"

```
resolve → verify digest → plan → apply → status
```

1. **Resolve**: Plugin downloads versioned blueprint artifact from OCI registry, checks version compatibility against `min_openshell_version` and `min_openclaw_version` constraints
2. **Verify**: SHA-256 digest computed over entire blueprint directory (all files, in sorted order), compared against expected digest — **supply chain integrity check**
3. **Plan**: Blueprint runner validates profile, checks prerequisites (openshell CLI present), resolves sandbox/inference config, outputs JSON plan
4. **Apply**: Creates sandbox via `openshell sandbox create`, configures inference provider, sets inference route, saves run state to `~/.nemoclaw/state/runs/<run-id>/`
5. **Status**: Reads most recent run state from disk, queries openshell for live sandbox status

Run state is saved to `~/.nemoclaw/state/runs/nc-{timestamp}-{uuid}/plan.json` — every deployment is auditable by run ID.

### 7-Step Onboarding Wizard

The `nemoclaw onboard` command runs a 7-step wizard:

1. **Preflight**: Docker running? OpenShell CLI installed? Ports 8080 (OpenShell gateway) and 18789 (NemoClaw dashboard) available? GPU detected?
2. **Gateway**: Start OpenShell gateway (`openshell gateway start --name nemoclaw`), verify health, patch CoreDNS if needed (Colima/k3s-in-Docker DNS issue)
3. **Sandbox**: Name validation (RFC 1123 — lowercase, hyphens only), build Dockerfile context, create sandbox with `openshell sandbox create --from <Dockerfile> --name <name> --policy <base-policy>`, forward port 18789
4. **NIM**: Select inference provider (cloud API / local Ollama / local vLLM / NIM container), prompt for API key if cloud
5. **Inference**: Configure OpenShell provider (`openshell provider create`), set inference route (`openshell inference set`)
6. **OpenClaw**: Write openclaw.json inside sandbox with inference provider config, set primary model
7. **Policy Presets**: Auto-suggest presets based on detected tokens, apply selected presets

Non-interactive mode: all steps can be driven by environment variables (`NEMOCLAW_NON_INTERACTIVE=1`, `NEMOCLAW_PROVIDER`, `NEMOCLAW_MODEL`, `NEMOCLAW_SANDBOX_NAME`, `NEMOCLAW_POLICY_MODE`, `NEMOCLAW_POLICY_PRESETS`) — suitable for CI/CD pipelines.

### Container Image

From the `Dockerfile`:
- Base: `node:22-slim`
- OpenClaw pinned version: `openclaw@2026.3.11` (one version behind our production 2026.3.13)
- Python 3 + PyYAML for blueprint runner
- `sandbox` user/group created (UID/GID not pinned — relying on user name)
- NemoClaw plugin installed at `/opt/nemoclaw/`
- Blueprint installed at `/sandbox/.nemoclaw/blueprints/0.1.0/`
- Entrypoint: `/usr/local/bin/nemoclaw-start` (bash script, not JSON exec form — note: this means signals go through bash, not directly to the process)

openclaw.json written at build time via Python inline script:
```python
config = {
    'agents': {'defaults': {'model': {'primary': 'nvidia/nemotron-3-super-120b-a12b'}}},
    'models': {'mode': 'merge', 'providers': {'nvidia': {
        'baseUrl': 'https://inference.local/v1',  # OpenShell gateway proxy
        'apiKey': 'openshell-managed',             # Credential injected by OpenShell
        'api': 'openai-completions',
        ...
    }}}
}
```

Key design: `inference.local` is the magic hostname — OpenShell's gateway intercepts all traffic to this hostname and routes to the configured provider. The actual API key never appears in the container; OpenShell injects it via the provider credential configuration.

### Port Architecture

| Port | Service | Direction |
|---|---|---|
| 8080 | OpenShell gateway | Host-side (k3s) |
| 18789 | NemoClaw dashboard / OpenClaw gateway | Forwarded into sandbox |
| 11434 | Ollama (if local) | Host-side, sandbox reaches via host-gateway |
| 8000 | vLLM or NIM container | Host-side or separate container |

Port forwarding: `openshell forward start --background 18789 <sandbox-name>` — maps host port 18789 into the named sandbox. Only one sandbox can own a given host port at a time.

### Remote GPU Deployment via Brev

`nemoclaw deploy <instance-name>` provisions a Brev GPU VM with:
- Docker + NVIDIA Container Toolkit
- OpenShell CLI
- NemoClaw setup (gateway + providers + sandbox)
- Optional Telegram bridge and cloudflared tunnel

GPU selection via `NEMOCLAW_GPU` env var, default: `a2-highgpu-1g:nvidia-tesla-a100:1`.

---

## 5. Security Model

### Authentication & Credential Management

Credentials stored at `~/.nemoclaw/credentials.json` (directory mode 0700, file mode 0600):
- `NVIDIA_API_KEY` — NVIDIA cloud inference
- `GITHUB_TOKEN` — for private repo deployments
- `TELEGRAM_BOT_TOKEN`, `SLACK_BOT_TOKEN`, `DISCORD_BOT_TOKEN` — auto-detected for preset suggestions

Credential lookup order:
1. Environment variable (highest priority)
2. `~/.nemoclaw/credentials.json` (stored credentials)
3. `gh auth token` (for GitHub tokens)

Key validation: NVIDIA API keys must start with `nvapi-` — validated at input time.

### What NemoClaw Adds Beyond Base OpenClaw Security

| Security Layer | Base OpenClaw | NemoClaw |
|---|---|---|
| Network egress control | None | Deny-by-default YAML allowlist |
| Binary-level network restriction | None | Per-binary endpoint allowlists |
| Filesystem access control | Docker container scope | Landlock + seccomp + read-only mounts |
| Process user | Root (Docker default) | Dedicated `sandbox` user |
| Inference credential exposure | API key in openclaw.json | Key stored in OpenShell, never in container config |
| TLS inspection | None | OpenShell gateway terminates TLS |
| Real-time operator approval | None | TUI approval flow for unknown egress |
| Supply chain integrity | npm package signing | SHA-256 digest verification on blueprint artifacts |
| Network namespace isolation | Docker bridge network | Separate network namespace per sandbox |

### The `inference.local` Pattern

This is clever: the container's openclaw.json points to `https://inference.local/v1` as the model endpoint. This hostname only resolves inside the OpenShell network namespace, to the OpenShell gateway. The gateway:
1. Authenticates the request (only the `sandbox` user can reach it)
2. Verifies the model matches the configured route
3. Re-issues the request to the actual provider (NVIDIA cloud / Ollama / vLLM) with the real credential
4. Returns the response

The agent never knows where the actual model is. The real API key never touches the sandbox filesystem.

### Auto-Pair Security

The `nemoclaw-start.sh` entrypoint launches an auto-pair watcher that automatically approves device pairing requests for the browser UI within a 600-second window. This is a convenience feature for the control UI but represents a security trade-off: any client that can reach port 18789 during the startup window will be auto-approved.

### Operator Approval Flow

When the agent tries to reach a host not in the policy:
1. OpenShell intercepts and blocks the connection
2. Logs the blocked attempt with host, port, requesting binary, HTTP method
3. TUI (`openshell term`) displays the blocked request for operator review
4. Operator approves or denies
5. Approved endpoints are added to the **running** policy (session-only, not persisted)

To persist an approval: manually edit `openclaw-sandbox.yaml` and re-run `nemoclaw onboard`, or apply via `openshell policy set`.

---

## 6. NemoTron Model Integration

### Available Models

| Model ID | Label | Context Window | Max Output | Use |
|---|---|---|---|---|
| `nvidia/nemotron-3-super-120b-a12b` | Nemotron 3 Super 120B | 131,072 tokens | 8,192 | Production default |
| `nvidia/llama-3.1-nemotron-ultra-253b-v1` | Nemotron Ultra 253B | 131,072 tokens | 4,096 | Highest capability |
| `nvidia/llama-3.3-nemotron-super-49b-v1.5` | Nemotron Super 49B v1.5 | 131,072 tokens | 4,096 | Balanced |
| `nvidia/nemotron-3-nano-30b-a3b` | Nemotron 3 Nano 30B | 131,072 tokens | 4,096 | Local/lightweight |

Plus other NVIDIA-hosted models via build.nvidia.com:
- `moonshotai/kimi-k2.5` — Kimi K2.5
- `z-ai/glm5` — GLM-5
- `minimaxai/minimax-m2.5` — MiniMax M2.5
- `qwen/qwen3.5-397b-a17b` — Qwen3.5 397B A17B
- `openai/gpt-oss-120b` — GPT-OSS 120B

### Inference Routing Configuration

All models are accessed through OpenShell's inference proxy at `https://inference.local/v1`. From the agent's perspective, all models look identical — it's making OpenAI-compatible completions API calls to the same local URL. The provider type is `openai-completions`.

In openclaw.json (written inside the sandbox at build time):
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "nvidia/nemotron-3-super-120b-a12b"
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "nvidia": {
        "baseUrl": "https://inference.local/v1",
        "apiKey": "openshell-managed",
        "api": "openai-completions",
        "models": [
          {
            "id": "nemotron-3-super-120b-a12b",
            "contextWindow": 131072,
            "maxTokens": 4096,
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}
          }
        ]
      }
    }
  }
}
```

Cost is set to 0 — OpenClaw's cost tracking doesn't apply here since billing goes through the NVIDIA API key.

### Runtime Model Switching

```bash
openshell inference set --provider nvidia-nim --model nvidia/llama-3.1-nemotron-ultra-253b-v1
```

No sandbox restart needed. Change takes effect immediately for new requests.

### Local NIM Container Option (Experimental)

For GPU-equipped hosts, NemoClaw can pull and run a NIM (NVIDIA Inference Microserver) Docker container locally:

```bash
# NIM container management
docker run -d --gpus all -p 8000:8000 --name nemoclaw-nim-<sandbox> --shm-size 16g <nim-image>
```

NIM health check: polls `http://localhost:8000/v1/models` with 5-second intervals, 300-second timeout. Falls back to cloud API if NIM fails to start.

GPU VRAM requirements determine eligible NIM models (e.g., Nemotron Nano 30B requires less VRAM than Nemotron Super 120B).

### Network Policy for NVIDIA Inference

The `nvidia` policy group covers both inference endpoints:
```yaml
nvidia:
  endpoints:
    - host: integrate.api.nvidia.com    # Primary NVIDIA API
      port: 443
    - host: inference-api.nvidia.com    # Secondary endpoint
      port: 443
  binaries:
    - { path: /usr/local/bin/claude }   # Claude Code binary
    - { path: /usr/local/bin/openclaw } # OpenClaw binary
```

---

## 7. Applicable Patterns for Our Setup Right Now

Our current setup: Single VPS, Docker container (`openclaw-okny-openclaw-1`), 4 agents (Maks, MaksPM, Scout, ClawExpert), OpenClaw 2026.3.13, token auth mode, Telegram bots.

### Pattern 1: Adopt the Network Policy Model in Documentation

**What NemoClaw does**: Maintains an explicit YAML file listing every allowed outbound endpoint.
**What we can do now**: Document our agents' allowed egress in a reference file. When we build the deployment platform, this becomes executable policy.
**Benefit**: Clarity on what our agents can reach; easier security audit.

Action: Create `~/Projects/perlantir-infra/agent-network-policy.md` listing every outbound connection our agents make (Anthropic API, Telegram, Brave Search, Supabase, Vercel, etc.)

### Pattern 2: Adopt the Credential File Convention

**What NemoClaw does**: Credentials stored at `~/.nemoclaw/credentials.json` (directory 0700, file 0600). No credentials in config files that go to disk in human-readable form.
**What we can do now**: Audit our `openclaw.json` — does it contain API keys directly? If so, move to SecretRef pattern. Verify file permissions: `ls -la /data/.openclaw/openclaw.json` should be 0600.

### Pattern 3: Adopt the Read-Only Filesystem Convention

**What NemoClaw does**: System directories are read-only, only /sandbox and /tmp are writable.
**What we can do now**: Our agents already run in Docker — we can add `--read-only` to the container with explicit `/tmp` and workspace volume mounts. This prevents an agent from accidentally (or maliciously) modifying container internals.

Concrete: Check if our Docker container runs with read-only root filesystem:
```bash
docker inspect openclaw-okny-openclaw-1 | jq '.[0].HostConfig.ReadonlyRootfs'
```

### Pattern 4: Run as Non-Root User

**What NemoClaw does**: Agents run as `sandbox:sandbox` user, not root.
**What we can do now**: Check what user our OpenClaw container runs as:
```bash
docker exec openclaw-okny-openclaw-1 whoami
```
If it's root, adding `USER openclaw` to a custom image would improve security posture.

### Pattern 5: Policy Preset System for Agent Configuration

**What NemoClaw does**: Composable YAML preset files for different integration needs (telegram.yaml, slack.yaml, etc.) that merge into the base policy.
**What we can do now**: Adopt this pattern for our openclaw.json configuration management. Create preset-style config fragments that can be merged for different agent roles. Especially useful if we spin up more specialized agents.

### Pattern 6: Blueprint-Style Deployment with Run IDs

**What NemoClaw does**: Every deployment generates a timestamped run ID (`nc-{timestamp}-{uuid}`), state saved to disk, rollback supported.
**What we can do now**: Our current deployment has no audit trail. When we make changes, we should:
1. Record what changed, when, and by whom
2. Keep a backup of the previous config before changes
3. Use our runbook system for this (already have runbook/ directory)

### Pattern 7: Sandbox Name Validation (RFC 1123)

**What NemoClaw does**: Validates sandbox names as RFC 1123 subdomains (lowercase, hyphens, alphanumeric start/end).
**Relevance**: When we build the deployment platform, use the same validation for customer workspace/agent names. This ensures names are safe for Kubernetes, DNS, and container naming.

### Pattern 8: Non-Interactive Mode for CI/CD

**What NemoClaw does**: `NEMOCLAW_NON_INTERACTIVE=1` + env vars fully drives all onboarding steps without prompts.
**What we can do now**: When we script agent deployments (e.g., for Perlantir's platform), use this pattern — every config value maps to an env var, making deployments scriptable and idempotent.

---

## 8. Platform Product Relevance

If we build an "OpenClaw deployment platform" (SaaS for multi-tenant agent deployments), NemoClaw is the direct blueprint. Here's exactly what we'd need:

### Core Architecture to Replicate

**The Registry Pattern** (`~/.nemoclaw/sandboxes.json` → our database)
NemoClaw's local registry is the prototype for our multi-tenant data model:
```sql
CREATE TABLE sandboxes (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  model TEXT,
  provider TEXT,
  gpu_enabled BOOLEAN DEFAULT FALSE,
  policies TEXT[],
  status TEXT,
  run_id TEXT
);
```

**The Blueprint Pattern** (versioned, digest-verified deployment artifacts)
Our platform needs a blueprint system where each customer gets a specific, reproducible agent configuration. The `verify.ts` digest computation pattern (SHA-256 over sorted file list) is directly reusable.

**The Policy Preset System** (composable allowlists per use case)
Our platform's killer feature: customers pick their integration preset (telegram, slack, github, jira, etc.) and the platform applies the right network policy. NemoClaw already has 8 of these. We extend with Supabase, Vercel, Stripe, etc.

### What We Need Beyond NemoClaw

**Multi-Host Orchestration**
NemoClaw is single-host. Our platform needs:
- Kubernetes or Nomad for multi-host sandbox scheduling
- A control plane API (REST/gRPC) for sandbox lifecycle management
- Per-tenant namespace isolation in Kubernetes
- Resource quotas (CPU/memory/GPU limits per tenant)

**Centralized Policy Management**
NemoClaw's policy files live on the host. Our platform needs:
- Policy stored in database, pushed to runtime
- Policy version history and rollback
- Tenant-configurable policies within platform-defined bounds
- Audit log of all policy changes

**Billing Integration**
NemoClaw doesn't track usage. Our platform needs:
- Token counting per tenant (OpenClaw usage API or proxy-level counting)
- Cost allocation per sandbox
- Usage metering for billing (Stripe or similar)
- Model cost pass-through or markup

**Web-Based Operator TUI**
NemoClaw's `openshell term` is a local terminal UI. Our platform needs:
- Web-based equivalent: live feed of agent network activity
- Click-to-approve interface for blocked egress requests
- Per-tenant access control for the approval UI

**Identity & Access Management**
NemoClaw has no IAM. Our platform needs:
- Tenant authentication (Supabase Auth)
- Role-based access (owner, admin, viewer roles per sandbox)
- API keys for programmatic access
- Audit logging of all administrative actions

**The `inference.local` Pattern — Our Core Infrastructure**
This is the key insight to implement on our platform:
1. Every customer sandbox has a unique gateway URL internal to our network
2. All model calls go through our gateway
3. Our gateway holds the actual provider credentials
4. Customers never see the credentials; they configure which model/provider to use
5. We can implement rate limiting, cost controls, and model switching at the gateway layer
6. We can even switch providers transparently (Anthropic → NVIDIA → Ollama) without customer config changes

**Sandbox Image Registry**
NemoClaw uses `ghcr.io/nvidia/openshell-community/sandboxes/openclaw`. Our platform needs:
- Our own container registry (GitHub Container Registry or AWS ECR)
- Versioned sandbox images for different OpenClaw versions
- Automated build pipeline (GitHub Actions) for new OpenClaw releases
- Image signing for supply chain integrity

### Platform Feature Priority (If Building Today)

1. **Sandbox lifecycle API** — create, start, stop, delete via REST
2. **Policy preset picker** — UI to select which integrations to enable
3. **`inference.local` gateway** — credential isolation + provider flexibility
4. **Web TUI** — real-time egress approval UI
5. **Registry/database** — multi-tenant sandbox state management
6. **Usage metering** — token counting per tenant for billing
7. **Kubernetes deployment** — for scale beyond single-host

### Competitive Moat

NemoClaw is alpha, single-host, NVIDIA-focused. Our platform would be:
- Provider-agnostic (Anthropic, NVIDIA, Ollama, any OpenAI-compat API)
- Multi-host (Kubernetes-native)
- SaaS (web UI, no CLI required for customers)
- Billing-integrated (usage-based or seat-based pricing)
- Enterprise-ready (SSO, audit logs, role-based access, SLAs)

NemoClaw validates the **market need** (enterprises want sandboxed agent deployments) and gives us a **technical blueprint** (the policy model, blueprint lifecycle, registry pattern, inference proxy). We build the production SaaS layer on top.

---

## Appendix A: Key File Locations

| File | Purpose |
|---|---|
| `nemoclaw-blueprint/policies/openclaw-sandbox.yaml` | Baseline network + filesystem policy (deny-by-default) |
| `nemoclaw-blueprint/policies/presets/*.yaml` | Composable policy presets per integration |
| `nemoclaw-blueprint/blueprint.yaml` | Blueprint manifest (version, profiles, compatibility constraints) |
| `nemoclaw-blueprint/orchestrator/runner.py` | Python blueprint runner (plan/apply/status/rollback) |
| `nemoclaw/src/blueprint/verify.ts` | SHA-256 digest verification of blueprint artifacts |
| `nemoclaw/src/blueprint/resolve.ts` | Blueprint version resolution + cache management |
| `bin/lib/onboard.js` | 7-step interactive onboarding wizard |
| `bin/lib/policies.js` | Policy preset loading, merging, and application |
| `bin/lib/registry.js` | Multi-sandbox local registry (~/.nemoclaw/sandboxes.json) |
| `bin/lib/credentials.js` | Credential storage + NVIDIA API key management |
| `bin/lib/nim.js` | NIM container management (pull, start, health-check) |
| `bin/lib/inference-config.js` | Provider selection config + model routing |
| `Dockerfile` | Sandbox container image definition |
| `scripts/nemoclaw-start.sh` | Sandbox entrypoint (configures gateway, auto-pair) |
| `~/.nemoclaw/credentials.json` | Stored credentials (mode 0600) |
| `~/.nemoclaw/sandboxes.json` | Multi-sandbox registry |
| `~/.nemoclaw/state/runs/<id>/plan.json` | Per-run deployment state |

## Appendix B: Key Commands Reference

```bash
# Host-side (nemoclaw CLI)
nemoclaw onboard                        # Full interactive setup
nemoclaw onboard --non-interactive      # CI/CD mode (use env vars)
nemoclaw <name> connect                 # Shell into sandbox
nemoclaw <name> status                  # Sandbox health
nemoclaw <name> logs --follow           # Live log stream

# Plugin commands (inside openclaw CLI)
openclaw nemoclaw status                # Blueprint + sandbox + inference status
openclaw nemoclaw status --json         # Machine-readable output
openclaw nemoclaw logs -f               # Stream blueprint execution logs
openclaw nemoclaw launch --force        # Bootstrap OpenClaw inside sandbox

# OpenShell commands (host)
openshell sandbox list                  # List all sandboxes
openshell sandbox status <name> --json  # Sandbox status JSON
openshell term                          # Open TUI (network monitoring + approval)
openshell policy set <file>             # Hot-reload network policy
openshell policy get --full <name>      # Get current policy YAML
openshell inference set --provider <p> --model <m>   # Switch model
openshell inference get --json          # Current inference config
openshell forward start --background 18789 <name>    # Port forward to sandbox
openshell forward stop 18789            # Release port forward
openshell gateway start --name nemoclaw # Start OpenShell gateway
openshell gateway destroy -g nemoclaw  # Destroy gateway
```

## Appendix C: Non-Interactive Environment Variables

| Variable | Values | Purpose |
|---|---|---|
| `NEMOCLAW_NON_INTERACTIVE` | `1` | Enable non-interactive mode |
| `NEMOCLAW_SANDBOX_NAME` | String | Sandbox name |
| `NEMOCLAW_RECREATE_SANDBOX` | `1` | Recreate existing sandbox without prompting |
| `NEMOCLAW_PROVIDER` | `cloud`, `ollama`, `vllm`, `nim` | Inference provider |
| `NEMOCLAW_MODEL` | Model ID string | Specific model to use |
| `NEMOCLAW_POLICY_MODE` | `suggested`, `custom`, `skip` | Policy preset application mode |
| `NEMOCLAW_POLICY_PRESETS` | Comma-separated preset names | Presets to apply (for custom mode) |
| `NEMOCLAW_EXPERIMENTAL` | `1` | Enable experimental features (NIM local, vLLM) |
| `NVIDIA_API_KEY` | `nvapi-...` | NVIDIA cloud inference credential |
| `NEMOCLAW_GPU` | GPU spec string | GPU type for Brev remote deployment |
