---
name: openclaw-ecosystem
description: Community, marketplace, security landscape, and external knowledge about OpenClaw. Updated from live research.
---

# Changelog
- 2026-03-19: Initial creation from live research — ClawHub, security audits, community intelligence

# OpenClaw Ecosystem Intelligence

## ClawHub — The Skills Marketplace
- URL: https://clawhub.ai (clawhub.com redirects here)
- Owner: Peter Steinberger (also original OpenClaw creator)
- Stack: TanStack Start (React), Convex (DB + storage), OpenAI embeddings (vector search)
- Open source: https://github.com/openclaw/clawhub (MIT)
- CLI: `npx clawhub@latest install <skill-slug>` OR `clawhub install <skill-slug>`

### Scale (as of Feb 28, 2026)
- **13,729 total published skills**
- **5,366 curated** in awesome-openclaw-skills (VoltAgent filtered 7,060 spam/malicious/low-quality)
- Categories: AI/ML (1,588), Utility (1,520), Development (976), Productivity (822)
- Most installed: `web-browsing` (180,000+ installs), `telegram` (145,000+ installs)

### CRITICAL: Security situation on ClawHub
- Snyk audit: **13.4% of skills flagged** for critical issues (malware, prompt injection, exposed API keys)
- Koi Security scan of 2,857 skills: **341 actively stealing user data**
- ClawHub has VirusTotal partnership — check skill pages for scan results before installing
- Recommended scanners: Snyk Skill Security Scanner, Agent Trust Hub (Gen Digital)
- **RULE: Never install a ClawHub skill without reading SKILL.md and checking VirusTotal**

### onlycrabs.ai (sister site)
- Registry for SOUL.md files — share agent personas the same way skills are shared
- URL: https://onlycrabs.ai

## Community Resources
- **awesome-openclaw-skills**: github.com/VoltAgent/awesome-openclaw-skills
  - 5,400+ curated skills, filtered by VoltAgent
  - #1 most visited community resource (1M+ monthly views)
- **docs.openclaw.ai/llms.txt** — machine-readable index of ALL official doc pages (fetch this every cycle)
- **docs.openclaw.ai** — full official docs

## Official Docs — Key Pages
| Topic | URL |
|-------|-----|
| Cron Jobs | docs.openclaw.ai/automation/cron-jobs |
| Hooks (inbound webhooks) | docs.openclaw.ai/automation/hooks |
| Multi-Agent Routing | docs.openclaw.ai/concepts/multi-agent |
| Memory backends | docs.openclaw.ai/concepts/memory |
| Session management | docs.openclaw.ai/concepts/session |
| Agent loop | docs.openclaw.ai/concepts/agent-loop |
| Gateway auth | docs.openclaw.ai/gateway/authentication |
| Sandboxing | docs.openclaw.ai/gateway/sandboxing |
| Security guide | docs.openclaw.ai/gateway/security |
| Skills system | docs.openclaw.ai/tools/skills |
| ClawHub guide | docs.openclaw.ai/tools/clawhub |
| Plugin development | docs.openclaw.ai/tools/plugin |
| CLI reference | docs.openclaw.ai/cli/index |

## History & Context
- Original name: **Clawdbot** (Nov 2025, Peter Steinberger, Vienna, Austria)
- Renamed: **Moltbot** (trademark issues with Anthropic)
- Renamed: **OpenClaw** (current, stable)
- Viral moment: Moltbook social network launch (late Jan 2026) → one of fastest-growing GitHub repos ever
- **247,000 stars, 47,700 forks** as of March 2, 2026
- Feb 14, 2026: Steinberger announced joining OpenAI; project transitioning to independent foundation

## Security Threat Landscape

### Known CVE/Incidents
| Issue | Status | Our Risk |
|-------|--------|----------|
| Auth token leak via malicious webpage (pre-2026.1.29) | ✅ PATCHED | Safe (we're on 2026.3.13) |
| OAuth mode overwrites auth-profiles.json (#48153, Mar 16) | Open | ✅ NOT affected (we use api_key mode) |
| 40,000+ exposed instances on public internet | Ongoing community problem | ✅ Safe (token auth + no public WS) |
| 341+ ClawHub skills stealing data | Ongoing | ✅ Safe (we use custom skills only) |

### Top Attack Vectors (ranked by frequency)
1. **Malicious ClawHub skills** — prompt injection, credential theft, hidden tool calls
2. **Exposed port 18789 with no auth** — direct admin WS access
3. **Prompt injection via web content** — agent reads injected instructions in page/email
4. **Skills as untrusted code** — `skills.entries.*.env` injects secrets into host process
5. **Stale OAuth token overwrite** (Issue #48153, OAuth mode only)

### Our Hardening Status
- ✅ Token auth mode enforced
- ✅ allowedUsers restricted to owner ID only
- ✅ Docker deployment with port binding (not publicly exposed)
- ✅ Custom skills only (no ClawHub third-party installs)
- ⚠️ Verify `tools.exec` deny list is correctly configured
- ⚠️ Verify `tools.fs` scope is appropriate per agent

## Skills Skill-Loading Architecture (from official docs)
Precedence (highest to lowest):
1. `<workspace>/skills/` — per-agent, overrides everything
2. `~/.openclaw/skills/` — shared across all agents on the machine
3. `skills.load.extraDirs` — additional directories (lowest precedence)
4. Bundled skills — shipped with OpenClaw install

**Multi-agent tip**: Per-agent skills in `<workspace>/skills/` are agent-specific.
Shared skills in `~/.openclaw/skills/` visible to ALL agents.

## External Coverage Worth Reading
- Nebius blog: full security architecture deep dive (March 5, 2026) — nebius.com/blog/posts/openclaw-security
- Microsoft Security Blog: enterprise threat model (Feb 19, 2026)
- Pacgenesis: vulnerability timeline (good CVE history)
- awesome-openclaw-skills: github.com/VoltAgent/awesome-openclaw-skills
