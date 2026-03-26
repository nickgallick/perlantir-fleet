---
name: clawhub-ecosystem
description: Complete ClawHub skill ecosystem catalog — community skills, what we have, what we're missing, recommended installs. Use when researching available community skills, planning installs for any agent workspace, auditing coverage gaps, or managing the skill ecosystem across all 7 agents.
---

# ClawHub Ecosystem

## Changelog
- 2026-03-20: Created from live ClawHub catalog research, awesome-openclaw-skills, and community blog sources

---

## Quick Install Commands

```bash
# Install globally (available to all agents)
clawhub install steipete/github           # GitHub PR/issues/CI management
clawhub install TheSethRose/agent-browser # Browser automation + screenshots
clawhub install framix-team/openclaw-tavily # AI-optimized research search
clawhub install openclaw/gog              # Full Google Workspace CLI
clawhub install capability-evolver        # AI self-evolution engine
clawhub install self-improving-agent      # Autonomous learning (132 stars)
clawhub install ivangdavila/skill-finder  # Meta: find + install skills from chat

# Install to a specific workspace
clawhub install <slug> --path /data/.openclaw/workspace-forge/skills/
clawhub install <slug> --path /data/.openclaw/workspace-clawexpert/skills/
```

---

## 1. ClawHub Overview

**ClawHub** is the public skill registry for OpenClaw — the equivalent of npm for AI agent skills.

- **URL**: https://clawhub.ai (also clawhub.com)
- **Owner**: Peter Steinberger (original OpenClaw/Clawdbot creator)
- **Stack**: TanStack Start (React + Vite/Nitro), Convex (DB + file storage + HTTP), OpenAI embeddings (text-embedding-3-small), Vercel deployment
- **Open source**: https://github.com/openclaw/clawhub (MIT license)
- **Scale (Feb 2026)**: 13,729 total published skills; ~5,366 curated after filtering spam/malware
- **Companion**: onlycrabs.ai — same system for SOUL.md files (agent identities)

### How Skills Work

A skill is a versioned directory containing:
```
skill-name/
├── SKILL.md          ← required (YAML frontmatter + instructions)
├── scripts/          ← executable code (Python/Bash)
├── references/       ← documentation loaded on demand
└── assets/           ← templates, icons, boilerplate
```

**SKILL.md frontmatter** (only `name` and `description` are required):
```yaml
---
name: my-skill
description: What it does and when to trigger it. This is the primary activation mechanism.
metadata:
  openclaw:
    requires:
      env: [MY_API_KEY]
      bins: [curl]
---
```

**Loading model** (progressive disclosure):
1. `description` (frontmatter only) — always in context, ~100 words
2. Full SKILL.md body — loaded when skill triggers
3. `references/` files — loaded on demand by the agent

**Install precedence**: Workspace > Local (~/.openclaw/skills/) > Bundled (node_modules/openclaw/skills/)

### CLI Reference

```bash
# Install
npm i -g clawhub                          # Install CLI
clawhub login                             # Auth with GitHub
clawhub install <slug>                    # Install to ./skills/ (current dir)
clawhub install <slug> --path <dir>       # Install to specific workspace
clawhub install <slug> --version 1.2.3   # Pin version
clawhub install <slug> --force            # Force reinstall

# Discover
clawhub search "web scraping"             # Vector search (natural language works)
clawhub explore                           # Browse trending
clawhub inspect <slug>                    # Preview before installing
clawhub list                              # List installed skills

# Manage
clawhub update <slug>                     # Update one skill
clawhub update --all                      # Update all installed skills
clawhub uninstall <slug>                  # Remove local install
clawhub sync                              # Sync with registry (tracks install telemetry)

# Publish
clawhub publish <path>                    # Publish a skill folder
clawhub skill rename <old> <new>          # Rename (keeps redirect)
clawhub skill merge <source> <target>     # Merge duplicates

# Disable telemetry
export CLAWHUB_DISABLE_TELEMETRY=1
```

**After installing or updating skills, restart OpenClaw to pick up the changes.**

---

## 2. Skills We Already Have

### Globally Installed (node_modules/openclaw/skills/) — Available to ALL agents

| Skill | Description |
|---|---|
| 1password | 1Password CLI integration |
| apple-notes | Apple Notes read/write |
| apple-reminders | Apple Reminders management |
| bear-notes | Bear note-taking app |
| blogwatcher | Monitor blogs/RSS for updates |
| blucli | Bluetooth CLI control |
| bluebubbles | BlueBubbles iMessage bridge |
| camsnap | Camera snapshot capture |
| canvas | Canvas drawing/diagramming |
| clawhub | ClawHub skill manager (meta) |
| coding-agent | Delegate to Codex/Claude Code sub-agents |
| discord | Discord message/reaction control |
| eightctl | Eight Sleep pod control |
| gemini | Google Gemini API integration |
| gh-issues | GitHub Issues specific workflow |
| gifgrep | GIF search and send |
| github | GitHub repos/PRs/CI via gh CLI |
| gog | Google Workspace (Gmail/Calendar/Drive/Sheets) |
| goplaces | Google Places API |
| healthcheck | Host security hardening |
| himalaya | Email via IMAP/SMTP CLI |
| imsg | iMessage send/receive |
| mcporter | MCP server bridge manager |
| model-usage | Token/cost usage tracking |
| nano-banana-pro | (Nano-series tool) |
| nano-pdf | PDF operations |
| node-connect | OpenClaw node pairing diagnostics |
| notion | Notion workspace integration |
| obsidian | Obsidian vault operations |
| openai-image-gen | DALL-E image generation |
| openai-whisper | Local Whisper transcription |
| openai-whisper-api | OpenAI Whisper API |
| openhue | Philips Hue lighting control |
| oracle | (Oracle DB or general query) |
| ordercli | Order management CLI |
| peekaboo | macOS UI capture/automation |
| sag | Self-improving agent (bundled version) |
| session-logs | Session log management |
| sherpa-onnx-tts | Local TTS with Sherpa ONNX |
| skill-creator | Create/improve agent skills |
| slack | Slack message/channel control |
| songsee | Music/lyrics lookup |
| sonoscli | Sonos audio system control |
| spotify-player | Spotify playback control |
| summarize | Intelligent text summarization |
| things-mac | Things 3 task manager |
| tmux | tmux session management |
| trello | Trello board/card management |
| video-frames | Video frame extraction |
| voice-call | Voice call initiation |
| wacli | Versatile CLI multi-tool |
| weather | Weather via wttr.in/Open-Meteo |
| xurl | URL fetching utility |

**Total globally installed: 54 bundled skills**

### ~/.openclaw/skills/ — Custom Nick Skills (Available Globally)

33 custom skills including: api-test-suite-builder, nick-admin-experience, nick-ai-feature-designer, nick-analytics-setup, nick-api-test-builder, nick-app-critic, nick-brand-system, nick-bug-triage, nick-ci-cd, nick-codebase-onboarding, nick-conversion-copy, nick-dependency-guard, nick-design-director, nick-fullstack, nick-git-ops, nick-launch-operator, nick-market-researcher, nick-offer-engine, nick-onboarding-optimizer, nick-pricing-strategist, nick-product-strategist, nick-project-orchestrator, nick-refactor-planner, nick-retention-engine, nick-sales-assets, nick-schema-designer, nick-secrets-guard, nick-supabase-reference, nick-tech-debt, nick-visual-design-review, playwright-skill-safe, self-improving-agent, skill-security-auditor-v2, vercel-qa

### Per-Workspace Skills

| Workspace | Agent | Skill Count | Key Skills |
|---|---|---|---|
| workspace | Maks | 33 | app-builder, nick-fullstack, nick-v0-design, stitch-design, v0-design |
| workspace-clawexpert | ClawExpert | 30 | openclaw-* (full suite), nemoclaw-*, claude-sdk-knowledge, repo-watch |
| workspace-pm | MaksPM | 13 | orchestration-pipeline, quality-gates, handoff-protocols, agent-roster |
| workspace-forge | Forge | 18 | react-nextjs, supabase-patterns, expo-react-native, typescript-mastery, security-review |
| workspace-pixel | Pixel | 21 | v0-mastery, brand-systems, design-system, mobile-ux, image-generation |
| workspace-launch | Launch | 10 | nick-conversion-copy, nick-offer-engine, nick-sales-assets, nick-retention-engine |
| workspace-scout | Scout | 13 | competitive-intelligence, demand-validation-scoring, market-sizing, revenue-validation |

---

## 3. Community Skills Catalog

Skills discovered from ClawHub (clawhub.ai), awesome-openclaw-skills, and community blogs.
Registry total: **13,729 skills** (Feb 2026). Curated safe list: **5,366 skills**.

### Top Skills by Download Count (ClawHub, Feb 2026)

| Rank | Skill | Downloads | Stars | Install Command | Relevance |
|---|---|---|---|---|---|
| 1 | capability-evolver | 35,581 | 33 | `clawhub install capability-evolver` | HIGH |
| 2 | wacli | 16,415 | 37 | `clawhub install wacli` | MEDIUM |
| 3 | byterover | 16,004 | 36 | `clawhub install byterover` | MEDIUM |
| 4 | self-improving-agent | 15,962 | 132 | `clawhub install self-improving-agent` | HIGH |
| 5 | atxp | 14,453 | — | `clawhub install atxp` | LOW |
| 6 | gog | 14,313 | 48 | `clawhub install openclaw/gog` | HIGH |
| 7 | agent-browser | 11,836 | 43 | `clawhub install TheSethRose/agent-browser` | HIGH |
| 8 | summarize | 10,956 | — | `clawhub install summarize` | MEDIUM |
| 9 | github | 10,611 | — | `clawhub install steipete/github` | HIGH |
| 10 | sonoscli | 10,304 | — | `clawhub install sonoscli` | LOW (already have) |
| 11 | web-browsing | 180,000+ | — | `clawhub install web-browsing` | MEDIUM |
| 12 | telegram | 145,000+ | — | `clawhub install telegram` | LOW (native in OpenClaw) |

### Developer/Build Skills

| Skill | Description | Relevance | Agent | Install |
|---|---|---|---|---|
| github | Full GitHub via gh CLI — PRs, issues, CI, branches, reviews | HIGH | Forge, Maks | `clawhub install steipete/github` |
| agent-browser | Browser automation — navigate, fill forms, extract, screenshot | HIGH | Forge, Maks | `clawhub install TheSethRose/agent-browser` |
| nextjs-expert | Next.js 14/15 App Router expert guidance | HIGH | Forge | `clawhub install nextjs-expert` |
| senior-fullstack | Fullstack scaffolding for Next.js/FastAPI/MERN/Django | HIGH | Forge, Maks | `clawhub install senior-fullstack` |
| react-email-skills | Responsive HTML emails with React Email | HIGH | Forge | `clawhub install react-email-skills` |
| playwright | Playwright browser automation (different from playwright-skill-safe) | HIGH | Forge | `clawhub install ivangdavila/playwright` |
| computer-use | Full desktop computer use for headless Linux | MEDIUM | ClawExpert | `clawhub install computer-use` |
| linux-service-triage | Diagnose Linux service issues via logs/systemd/PM2 | HIGH | ClawExpert | `clawhub install linux-service-triage` |
| wacli | Versatile CLI multi-tool (Swiss army knife) | MEDIUM | All | `clawhub install wacli` |
| byterover | Multi-purpose task handler | MEDIUM | Maks | `clawhub install byterover` |
| claw-shell | tmux session manager with opinionated defaults | MEDIUM | ClawExpert | `clawhub install claw-shell` |
| nodetool | Visual AI workflow builder (ComfyUI meets n8n) | LOW | — | `clawhub install nodetool` |
| pinak-frontend-guru | Expert UI/UX + React performance auditor | HIGH | Pixel, Forge | `clawhub install pinak-frontend-guru` |

### Research & Search Skills

| Skill | Description | Relevance | Agent | Install |
|---|---|---|---|---|
| openclaw-tavily | Tavily AI search — structured results, source citations, crawl/extract | HIGH | Scout, Maks | `clawhub install framix-team/openclaw-tavily` |
| felo-search | AI-synthesized answers with citations, multilingual | HIGH | Scout | `clawhub install felo-search` |
| brave-search | Brave Search API integration | HIGH | All | `clawhub install steipete/brave-search` |
| technews | TechMeme stories + article summaries + social reactions | HIGH | Scout | `clawhub install technews` |
| find-skills | Discover + install skills from ClawHub and Skills.sh | MEDIUM | All | `clawhub install JimLiuxinghai/find-skills` |
| skill-finder | Advanced dual-source skill finder (ClawHub + Skills.sh) | HIGH | ClawExpert | `clawhub install ivangdavila/skill-finder` |
| airadar | Track fast-growing AI-native tools and GitHub repos | HIGH | Scout | `clawhub install airadar` |
| miniflux-news | Fetch and triage RSS feeds from Miniflux | LOW | — | `clawhub install miniflux-news` |

### Productivity & Workspace Skills

| Skill | Description | Relevance | Agent | Install |
|---|---|---|---|---|
| gog | Full Google Workspace — Gmail, Calendar, Drive, Docs, Sheets, Contacts | HIGH | Maks, MaksPM | `clawhub install openclaw/gog` |
| capability-evolver | AI self-evolution engine — agent improves itself over time | HIGH | All | `clawhub install capability-evolver` |
| self-improving-agent | Autonomous learning framework (132 stars, highest on ClawHub) | HIGH | All | `clawhub install self-improving-agent` |
| mission-control | Morning briefing — tasks, calendar, notifications aggregated | MEDIUM | MaksPM | `clawhub install mission-control` |
| slack | Slack message/channel control | MEDIUM | MaksPM | already installed globally |
| discord | Discord message/reaction control | MEDIUM | MaksPM | already installed globally |
| summarize | Intelligent text summarization (10K+ downloads) | MEDIUM | Scout | already installed globally |
| smtp-send | Send emails via SMTP (plain text + HTML) | MEDIUM | Launch | `clawhub install smtp-send` |
| agentmail | Email management (read/write/search) | MEDIUM | MaksPM | `clawhub install adboio/agentmail` |

### Design & Frontend Skills

| Skill | Description | Relevance | Agent | Install |
|---|---|---|---|---|
| frontend-design | Production-grade frontend interfaces with high design quality | HIGH | Pixel, Forge | `clawhub install frontend-design` |
| deliberate-frontend-redesign | Deliberate redesign skill (high downloads) | HIGH | Pixel | `clawhub install deliberate-frontend-redesign` |
| human-optimized-frontend | Human-centered frontend design skill | HIGH | Pixel | `clawhub install human-optimized-frontend` |
| artifacts-builder | Multi-component HTML artifact builder (modern frontend) | MEDIUM | Pixel | `clawhub install artifacts-builder` |
| remotion-video-toolkit | Programmatic video creation with Remotion + React | MEDIUM | Launch | `clawhub install remotion-video-toolkit` |
| downloads | (High-download design skill from tree210 collection) | MEDIUM | Pixel | `clawhub install downloads` |

### DevOps & Infrastructure Skills

| Skill | Description | Relevance | Agent | Install |
|---|---|---|---|---|
| docker-essentials | Docker operations fundamentals | HIGH | ClawExpert | `clawhub install docker-essentials` |
| linux-service-triage | Linux service diagnostics (logs, systemd, PM2, permissions) | HIGH | ClawExpert | `clawhub install linux-service-triage` |
| clawflows | Multi-step workflow orchestration | HIGH | MaksPM | `clawhub install clawflows` |
| n8n-workflow | n8n automation integration | MEDIUM | MaksPM | `clawhub install n8n-workflow` |

### Agent-to-Agent & Orchestration Skills

| Skill | Description | Relevance | Agent | Install |
|---|---|---|---|---|
| agent-team-orchestration | Multi-agent teams — roles, task lifecycles, handoffs, review | HIGH | MaksPM | `clawhub install arminnaimi/agent-team-orchestration` |
| agent-commons | Reasoning chains — consult, commit, extend, challenge | HIGH | MaksPM | `clawhub install zanblayde/agent-commons` |
| agentdo | Post/pick up tasks from AgentDo task queue | MEDIUM | MaksPM | `clawhub install wrannaman/agentdo` |
| agentgate | API gateway for personal data with human-in-the-loop approval | HIGH | ClawExpert | `clawhub install monteslu/agentgate` |
| alex-session-wrap-up | End-of-session: commit unpushed work, extract learnings | HIGH | Maks, Forge | `clawhub install xbillwatsonx/alex-session-wrap-up` |

### Storage & Data Skills

| Skill | Description | Relevance | Agent | Install |
|---|---|---|---|---|
| fast-io | Cloud storage for agents — 50GB free, 19 tools, workspaces | MEDIUM | Maks | `clawhub install dbalve/fast-io` |
| s3 | AWS S3 file management | MEDIUM | Forge | `clawhub install ivangdavila/s3` |
| sql-toolkit | SQL query toolkit | HIGH | Forge | `clawhub install gitgoodordietrying/sql-toolkit` |
| filesystem | Enhanced filesystem management | LOW | — | `clawhub install gtrusler/clawdbot-filesystem` |

### Skill Meta-Skills

| Skill | Description | Relevance | Agent | Install |
|---|---|---|---|---|
| skill-creator | Create/improve ClawHub skills (chindden version) | HIGH | ClawExpert | `clawhub install chindden/skill-creator` |
| skill-finder | Dual-source skill discovery (ivangdavila version) | HIGH | ClawExpert | `clawhub install ivangdavila/skill-finder` |
| find-skills | Skills CLI discovery (JimLiuxinghai version) | MEDIUM | ClawExpert | `clawhub install JimLiuxinghai/find-skills` |

---

## 4. Recommended Installs

Priority installs not already present in any workspace, ranked by impact.

### Tier 1 — Install Immediately

#### 1. `steipete/github` → Forge + Maks
```bash
clawhub install steipete/github --path /data/.openclaw/workspace-forge/skills/
clawhub install steipete/github --path /data/.openclaw/workspace/skills/
```
**Why**: Full GitHub workflows via gh CLI. Essential for Forge's code review/PR/CI monitoring. We have `gh-issues` globally but this is the full-featured version. 10K+ downloads, developer essential.

#### 2. `TheSethRose/agent-browser` → Forge + ClawExpert
```bash
clawhub install TheSethRose/agent-browser --path /data/.openclaw/workspace-forge/skills/
clawhub install TheSethRose/agent-browser --path /data/.openclaw/workspace-clawexpert/skills/
```
**Why**: Browser automation beyond what playwright-skill-safe covers — navigates, fills forms, extracts data, screenshots. 11,836 downloads, 43 stars. Augments Playwright for non-test browser tasks.

#### 3. `linux-service-triage` → ClawExpert
```bash
clawhub install linux-service-triage --path /data/.openclaw/workspace-clawexpert/skills/
```
**Why**: Direct match for ClawExpert's role — diagnoses Linux service issues using logs, systemd, PM2, file permissions. Fills a gap in current ClawExpert skills: we have health-checks and log-analysis but nothing that bridges into systemd diagnostics.

### Tier 2 — High Value, Non-Urgent

#### 4. `framix-team/openclaw-tavily` → Scout
```bash
clawhub install framix-team/openclaw-tavily --path /data/.openclaw/workspace-scout/skills/
```
**Why**: AI-optimized search (tavily_search, tavily_extract, tavily_crawl, tavily_research) built for agents. Cleaner results than raw web search. Scout's current research depends on Brave search — Tavily gives structured alternative. Requires TAVILY_API_KEY.

#### 5. `arminnaimi/agent-team-orchestration` → MaksPM
```bash
clawhub install arminnaimi/agent-team-orchestration --path /data/.openclaw/workspace-pm/skills/
```
**Why**: Multi-agent orchestration with defined roles, task lifecycles, handoffs, review workflows. Directly supports MaksPM's job. Community-built for exactly this use case.

#### 6. `capability-evolver` → Globally
```bash
clawhub install capability-evolver
```
**Why**: #1 most downloaded skill on ClawHub (35K+). Enables agents to analyze interaction patterns and auto-optimize. Long-running agent power tool. Audit carefully before install (read SKILL.md first).

#### 7. `nextjs-expert` → Forge
```bash
clawhub install nextjs-expert --path /data/.openclaw/workspace-forge/skills/
```
**Why**: Next.js 14/15 App Router expert guidance — exactly our stack. Forge already has react-nextjs but this is the community-maintained specialist skill with 179 downloads.

#### 8. `ivangdavila/skill-finder` → ClawExpert
```bash
clawhub install ivangdavila/skill-finder --path /data/.openclaw/workspace-clawexpert/skills/
```
**Why**: ClawExpert's meta-role includes managing the skill ecosystem. Skill-finder provides dual-source search (ClawHub + Skills.sh), preference memory, and structured evaluation before recommending installs to Nick.

---

## 5. Skill Gaps

Areas where no strong community skill exists — potential publishing opportunities for Nick's team.

### Missing Skills We Could Build + Publish

| Gap | Description | Who Needs It | Opportunity |
|---|---|---|---|
| **supabase-mcp** | Supabase-aware agent skill with RLS debugging, schema migration help, and realtime subscription patterns | Forge, Maks | ClawHub has no strong Supabase-specific skill. Our nick-supabase-reference could be published |
| **vercel-deploy-agent** | Vercel deployment, preview URL management, env var sync, and build failure triage via Vercel CLI + API | Forge, Launch | No Vercel-specific skill on ClawHub |
| **expo-react-native** | Expo + React Native patterns, EAS build, OTA updates, native module management | Forge | No Expo skill in ClawHub registry |
| **perlantir-ops** | Multi-agent OpenClaw deployment patterns — the "platform operations" skill | ClawExpert | Untapped niche, aligns with Nick's platform project |
| **openclaw-platform-deploy** | One-click multi-agent setup documentation and operator runbook | ClawExpert | Genuine gap in the community — no managed multi-agent deploy skill |
| **claude-api-agent** | Claude API patterns for agents — tool use, streaming, prompt caching, cost control | Maks, Forge | claude-sdk-knowledge exists locally but not published |
| **gtm-launch-ops** | Product launch operations — HN/Reddit/PH post templates, TikTok hooks, waitlist setup | Launch | No launch-ops skill on ClawHub |
| **next-supabase-saas** | Full Next.js + Supabase SaaS scaffold patterns — auth, billing, tenant isolation | Forge | High demand in our stack, nothing comparable on ClawHub |

### Coverage Gaps in Existing Agents

| Agent | Missing | Why It Matters |
|---|---|---|
| Scout | Tavily search (structured AI results) | Brave search works but Tavily is purpose-built for agents |
| Forge | GitHub full-featured (vs gh-issues only) | PR workflows need full github skill |
| MaksPM | Agent orchestration patterns | Community orchestration skill would improve PM workflows |
| Launch | Vercel deploy status | Launch needs to verify deploys are live before distribution |
| ClawExpert | Linux service triage | Closes gap in systemd/PM2 diagnostics |

---

## 6. How to Install Skills

### Prerequisites

```bash
# Install ClawHub CLI globally
npm i -g clawhub

# Verify
clawhub --version

# Authenticate (GitHub account required, min 1 week old)
clawhub login

# Check logged in
clawhub whoami
```

### Search Before Installing

```bash
# Vector search — natural language works
clawhub search "browser automation"
clawhub search "supabase database"
clawhub search "react performance"

# Inspect before installing (read SKILL.md, check security flags)
clawhub inspect TheSethRose/agent-browser

# Browse trending
clawhub explore
```

### Install Patterns

```bash
# Install to current directory (./skills/)
clawhub install <slug>

# Install to a specific agent workspace
clawhub install <slug> --path /data/.openclaw/workspace-forge/skills/
clawhub install <slug> --path /data/.openclaw/workspace-clawexpert/skills/
clawhub install <slug> --path /data/.openclaw/workspace-pm/skills/
clawhub install <slug> --path /data/.openclaw/workspace-scout/skills/
clawhub install <slug> --path /data/.openclaw/workspace-launch/skills/

# Install globally (available to all agents via ~/.openclaw/skills/)
clawhub install <slug> --path ~/.openclaw/skills/

# Install specific version
clawhub install <slug> --version 2.1.0

# Force reinstall
clawhub install <slug> --force
```

### Update Skills

```bash
# Update one skill
clawhub update TheSethRose/agent-browser

# Update everything
clawhub update --all

# Check for updates without applying
clawhub list
```

### Remove Skills

```bash
clawhub uninstall <slug>
```

### Security: Inspect Before You Install

```bash
# Read the SKILL.md and check what env vars/bins it requires
clawhub inspect <slug>

# Check VirusTotal report on clawhub.ai/<author>/<skill> before installing
# Use skill-security-auditor-v2 (already installed) to audit SKILL.md contents
```

**Security facts (Feb 2026)**:
- Snyk audit flagged 13.4% of ClawHub skills for critical issues
- Koi Security found 341 of 2,857 skills actively exfiltrating data
- ClawHavoc cleanup removed 2,419 suspicious skills
- Always: `clawhub inspect <slug>` before install + read SKILL.md manually for unfamiliar authors

### Publish a Skill to ClawHub

```bash
# Initialize a new skill
scripts/init_skill.py my-skill-name --path ./skills/

# Edit SKILL.md and add resources
# Test locally

# Package (validates + creates .skill zip)
scripts/package_skill.py ./skills/my-skill-name

# Publish
clawhub publish ./skills/my-skill-name
```

**Requirements to publish**: GitHub account ≥ 1 week old. Skills use soft-delete (owner/mod can restore). Hard delete is admin-only.

---

## Registry Health Stats (Feb 2026)

| Metric | Value |
|---|---|
| Total published skills | 13,729 |
| Curated safe list (awesome-openclaw-skills) | 5,366 |
| Filtered out (spam/malware/low-quality) | 7,060 |
| Skills flagged by Snyk | ~1,840 (13.4%) |
| Skills flagged by Koi Security | 341 |
| Removed in ClawHavoc cleanup | 2,419 |
| Monthly views on awesome-openclaw-skills | 1M+ |

**Rule**: Always inspect before install. Use `clawhub inspect` + VirusTotal link on clawhub.ai skill page.

---

## Related Resources

- ClawHub: https://clawhub.ai
- ClawHub GitHub: https://github.com/openclaw/clawhub
- awesome-openclaw-skills: https://github.com/VoltAgent/awesome-openclaw-skills
- ClawHub Skills catalog: https://clawskills.sh (5,490+ categorized)
- OpenClaw skills docs: https://docs.openclaw.ai/tools/skills
- Skills.sh ecosystem: https://skills.sh (alternate registry, use `npx skills find`)
- onlycrabs.ai: SOUL.md registry (agent identities)
