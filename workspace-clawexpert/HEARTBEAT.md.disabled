# ClawExpert Heartbeat — Operational Loop

This is your recurring operational loop. Execute all 7 phases in order during each heartbeat cycle. Each phase builds on the previous one. Skip nothing.

---

## Phase 1: Health Checks

Run these checks first. Any failure here takes priority over everything else.

### 1.1 Container Status
```bash
docker ps --filter name=openclaw --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
- Verify container `openclaw-okny-openclaw-1` is running
- Check uptime — unexpected restart means something crashed
- If down: escalate immediately as Critical

### 1.2 Disk Usage
```bash
df -h /data
du -sh /data/.openclaw/workspace* 2>/dev/null
du -sh /data/.openclaw/*.log 2>/dev/null
```
- Warning at 80% disk usage
- Critical at 90% disk usage
- Check if log files are growing unbounded
- Check workspace sizes for bloat

### 1.3 Memory Usage
```bash
free -h
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" openclaw-okny-openclaw-1
```
- Warning if container memory > 70% of limit
- Critical if > 90%
- Check for memory leaks (steadily increasing over time)

### 1.4 Config File Integrity
```bash
cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null 2>&1 && echo "JSON: valid" || echo "JSON: INVALID"
```
- Verify openclaw.json is valid JSON
- Compare against known-good backup if available
- Check for unauthorized changes (diff against last known state)

### 1.5 API Connectivity
```bash
docker exec openclaw-okny-openclaw-1 curl -s -o /dev/null -w "%{http_code}" https://api.anthropic.com/v1/messages -H "x-api-key: test" -H "anthropic-version: 2023-06-01" 2>/dev/null
```
- 401 = API reachable (auth failed as expected with test key)
- Connection error = network issue or API down
- Check Telegram bot connectivity by reviewing recent logs

### 1.6 Process Health
```bash
docker exec openclaw-okny-openclaw-1 ps aux 2>/dev/null | head -20
docker logs --tail 5 openclaw-okny-openclaw-1 2>&1
```
- Verify main process is running
- Check for zombie processes
- Look for OOM kills or segfaults in recent logs

---

## Phase 2: Log Analysis

After health checks pass, analyze logs for issues, patterns, and intelligence.

### 2.1 Error Scan
```bash
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -i -E "error|exception|fatal|crash|panic|ENOENT|EACCES|ETIMEDOUT" | tail -30
```
- Categorize errors: known-harmless vs. actionable
- Known harmless: nostr module missing, apply_patch entries, autoSelectFamily
- Any NEW error type → investigate and add to runbook

### 2.2 Warning Scan
```bash
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -i "warn" | grep -v -E "nostr|apply_patch|autoSelectFamily" | tail -20
```
- Filter out known harmless warnings
- Identify new warning patterns
- Check if warning frequency is increasing

### 2.3 Activity Summary
```bash
docker logs --since 1h openclaw-okny-openclaw-1 2>&1 | grep -i -E "message|request|response|telegram|channel" | tail -20
```
- Summarize agent activity levels
- Note any agents that appear stuck or unresponsive
- Track message throughput for anomaly detection

---

## Phase 3: Config Audit

Verify configuration is correct and hasn't drifted from desired state.

### 3.1 Schema Compliance
Read `/data/.openclaw/openclaw.json` and verify:
- No unknown top-level keys (Zod schema will crash the gateway)
- No `mcpServers` key (must use mcporter bridge only)
- All required keys present: `name`, `description`, `url`, `model`, `channels`, `auth`
- Model references are valid

### 3.2 Channel Health
For each configured channel:
- Verify bot token format looks correct (not truncated or corrupted)
- Check that channel IDs are present
- Verify allowedUsers includes owner (7474858103)

### 3.3 Agent Config
For each agent:
- Verify model assignment matches intended setup
- Check that workspace paths exist
- Verify system prompts reference correct SOUL/skill files

---

## Phase 4: Research

Check external sources for updates, security issues, and new capabilities.

### 4.1 OpenClaw Releases
Check https://github.com/openclaw/openclaw/releases for:
- New versions since our current 2026.3.13
- Breaking changes in CHANGELOG
- Security advisories
- Deprecation notices

### 4.2 OpenClaw Open PRs + Issues (EVERY CYCLE)
Check github.com/openclaw/openclaw for:

**PRs** — what's about to land:
- New config keys, breaking changes, deprecations
- Security-related PRs
- PRs touching config/schema (immediate relevance to us)
Alert if: schema changes, auth changes, Docker/gateway changes, anything marked breaking.

**Issues** — what's breaking in the wild:
- Search recent open issues (last 7 days) for: error, crash, regression, broken, failed
- Cross-reference against our version (currently 2026.3.13) — is it us?
- Look for workarounds the community has found before official fixes land
Alert if: any confirmed bug affecting our version or our auth/config/Docker setup.

### 4.3 Hostinger Infrastructure Status (EVERY CYCLE)
Check https://status.hostinger.com for:
- Active incidents affecting VPS hosting
- Scheduled maintenance windows
- Network/connectivity events
If incident found → cross-reference with container health from Phase 1 → escalate if correlated.

### 4.4 Docker Image Digest (EVERY CYCLE)
Check if `ghcr.io/hostinger/hvps-openclaw:latest` has a new digest:
```bash
docker pull ghcr.io/hostinger/hvps-openclaw:latest --dry-run 2>/dev/null || \
docker manifest inspect ghcr.io/hostinger/hvps-openclaw:latest 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('config',{}).get('digest','unknown'))"
```
Store last known digest in `memory/docker-digest.md`. Alert if changed — new image available.

### 4.5 Anthropic Model Announcements (EVERY CYCLE)
Check https://www.anthropic.com/news for:
- New Claude model releases → update claude-sdk-knowledge skill with new model strings
- Pricing changes → affects our cost projections
- Deprecation notices → affects our agent model configs
- API changes → affects auth or tool use patterns
Alert if: any new claude-* model, pricing change, or deprecation notice found.

### 4.6 Community Intelligence (EVERY OTHER CYCLE — rotate A/B)
**Cycle A — GitHub Discussions:**
Check https://github.com/openclaw/openclaw/discussions for:
- Maintainer authoritative answers to config/behavior questions
- Community-discovered workarounds for known issues
- Patterns in what people are struggling with (informs runbook)

**Cycle B — ClawHub New Skills:**
Check https://clawhub.ai/skills?sort=newest for:
- New skills published since last check
- Updates to skills we use or have referenced
- Skills relevant to our stack (coding, monitoring, productivity)
Note: ClawHub renders via JS — use web_search for "site:clawhub.ai new skills" if direct fetch returns "Loading skills..."
Note new skills in research log. Recommend to owner if high-value.

**Every cycle — Official docs index:**
Fetch https://docs.openclaw.ai/llms.txt for new doc pages (lightweight, text/plain, fast).
If new pages appear covering features we don't have documented in skills, queue them for reading.

Track which cycle we're on in `memory/research-cycle.md` (A or B).

---

## Phase 4.7: COO Agent Audit

As COO, audit agent operations every cycle. Reference: `coo-reference.md`

### 4.7.1 Agent Activity Check
```bash
# Check all agent sessions for recent activity
```
Use sessions_list to check each agent's last activity. Flag:
- Agents idle when they should be active (Launch after QA pass)
- Agents stuck in long-running sessions (compaction risk)
- Agents that haven't responded to directives

### 4.7.2 Process Compliance
Check recent agent outputs for process violations:
- Pixel: Did she generate in Stitch? Or spec-only?
- Maks: Did he get Forge's architecture spec before building?
- Forge: Did he include complete fix code on BLOCKED reviews?
- MaksPM: Did he use sessions_spawn (not sessions_send) for work?
- Scout: Did research briefs include all 6 required sections?
- Launch: Is it active when it should be?

### 4.7.3 Pipeline Health
- Are any projects stalled at a quality gate?
- Are handoffs happening with full context?
- Any cross-agent communication failures?

### 4.7.4 Intervene
If violations found:
1. Send directive to the agent via sessions_send with specific correction
2. Update their SOUL.md if it's a systemic issue (with Nick approval for major changes)
3. Log the issue in coo-reference.md under Known Issues & Patterns
4. Escalate to Nick only if agent is unresponsive or decision requires product judgment

---

## Phase 5: Evaluate and Decide

After gathering all data from Phases 1-4, make decisions:

1. **Triage findings** by severity:
   - **Critical**: System down, data loss risk, security breach → Act immediately
   - **Warning**: Performance degradation, approaching limits → Plan fix within 24h
   - **Info**: Optimization opportunity, new feature available → Queue for review

2. **Prioritize actions**:
   - Fix any Critical issues first
   - Address Warnings before doing research-based improvements
   - Only suggest Info-level changes when no higher-priority items exist

3. **Risk assessment** for each recommended action:
   - What could go wrong?
   - Is it reversible?
   - Does it require downtime?
   - Should we backup first?

4. **Decision framework**:
   - If health check failed → Fix it (Phase 1 priority)
   - If new error pattern found → Document in runbook (Phase 6)
   - If update available → Assess risk vs benefit, recommend timing
   - If security issue found → Escalate immediately regardless of severity
   - If optimization found → Document and queue for owner review

---

## Phase 6: Self-Improvement

Update your own knowledge base based on what you learned this cycle.

### 6.1 Runbook Updates
- Add any new error patterns discovered to `runbook/`
- Update existing entries with new solutions or context
- Add cross-references between related issues
- Format: `runbook/runbook-NNN-descriptive-name.md`

### 6.2 Skill Updates
- Update skill files with new commands, patterns, or gotchas discovered
- Add dated changelog entries to the top of updated skill files
- Remove outdated information that no longer applies

### 6.3 Memory Updates
- Save important findings to memory files
- Update existing memories with new context
- Remove memories that are no longer relevant
- Keep memory index (MEMORY.md) current

### 6.4 Pattern Recognition
- Track recurring issues — if something breaks 3+ times, it needs a systemic fix
- Identify correlations between events (e.g., high memory after many messages)
- Build predictive models for common failure modes
- Document seasonal patterns (e.g., higher load at certain times)

---

## Phase 7: Share

Communicate findings to the owner using the appropriate format.

1. **Critical findings** → Use Health Alert format (from SOUL.md), deliver immediately
2. **Research findings** → Use Intelligence Briefing format (from SOUL.md)
3. **Status update** → Brief summary of all-clear or items requiring attention
4. **Self-improvement** → Mention what you learned and updated (1-2 sentences max)

### Status Report Template
```
📊 **ClawExpert Status Report**
**Time**: [timestamp]
**System Health**: [✅ All Clear / ⚠️ Warning / 🚨 Critical]

**Health Checks**: [summary]
**Logs**: [summary]
**Config**: [summary]
**Research**: [summary]
**Actions Taken**: [list]
**Recommendations**: [list]
```

---

## Standing Rule: New Source Discovery
During any research cycle, if I discover a new source (blog, repo, forum, API changelog, status page, community resource, anything) that would improve my knowledge base if monitored regularly:
- **Flag it to the owner** with: source URL, what it covers, why it matters, how often it should be checked
- **Do NOT add it to HEARTBEAT.md unilaterally**
- Wait for explicit owner approval before adding to the heartbeat cycle
- Document flagged-but-unapproved sources in the research log only

## Cycle Frequency
- Health checks (Phase 1): Every heartbeat
- Log analysis (Phase 2): Every heartbeat
- Config audit (Phase 3): Every heartbeat
- Research (Phase 4): Every heartbeat
- Source code intelligence (Phase 4.5): Every heartbeat
- Evaluate (Phase 5): Every heartbeat (after Phases 1-4.5)
- Self-improvement (Phase 6): When new findings exist
- Share (Phase 7): Only if actionable items found — do NOT send "nothing to report"

---

---

## PHASE 4.5: SOURCE CODE INTELLIGENCE (every cycle)

### 4.5.1 Pull all repos
```bash
cd /data/.openclaw/workspace-clawexpert
for repo in repos/openclaw repos/nemoclaw repos/anthropic-sdk-python; do
  if [ -d "$repo/.git" ]; then
    cd /data/.openclaw/workspace-clawexpert/$repo
    git fetch origin --depth 1 2>/dev/null
    CHANGES=$(git log HEAD..origin/HEAD --oneline 2>/dev/null | wc -l)
    [ "$CHANGES" -gt "0" ] && echo "UPDATE: $repo has $CHANGES new commits" && git pull 2>/dev/null
    cd /data/.openclaw/workspace-clawexpert
  fi
done
```

### 4.5.2 Check for schema changes (CRITICAL)
If `repos/openclaw/src/config/zod-schema.ts` changed:
- Re-read the file
- Compare to `skills/openclaw-schema-map/SKILL.md`
- If different → update schema-map skill + send CRITICAL alert

### 4.5.3 Check package versions
```bash
cat repos/openclaw/package.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['version'])"
```
Compare to our running version. If ahead → note in recommendations.

### 4.5.4 Scan for new patterns
- New CLI commands, config options, plugin hooks
- NemoClaw status changes (alpha → beta)
- SDK new model IDs
- CHANGELOG.md new entries

### 4.5.5 Update knowledge
Update skills/openclaw-source-code/SKILL.md, skills/openclaw-schema-map/SKILL.md, skills/repo-watch/SKILL.md with new findings.

---

## ADDITIONAL REQUIRED PROCEDURES

### Cross-Agent Error Learning (Phase 2 supplement)
Check logs for errors from ALL agents (Maks, MaksPM, Scout, ClawExpert):
```bash
docker logs openclaw-okny-openclaw-1 --since 6h 2>&1 | grep -i "error"
```
- If any agent hit an error, log what happened and the resolution (if visible)
- Add new error patterns to the runbook skill file
- This is how you learn from the entire team's mistakes

### Targeted Web Searches (Phase 4 supplement)
Run these searches (rotate through them — do 3-4 per cycle, cover all within 24 hours):
- "openclaw release notes 2026"
- "openclaw changelog breaking changes"
- "openclaw github issues Hostinger Docker"
- "openclaw mcporter new features"
- "openclaw new skills community"
- "openclaw config best practices 2026"
- "openclaw security advisory CVE"
- "openclaw Telegram multi-agent setup"
- "openclaw performance optimization Docker"
- "openclaw stitch-mcp integration"

### Competitive Intelligence (Phase 4 supplement)
Track what similar tools are doing:
- "Claude Code new features 2026"
- "Cursor AI agent mode"
- "AI coding agent MCP integration"

### Research Logging (Phase 6 supplement)
Save a timestamped entry to research-logs/:
- File: research-YYYY-MM-DD-HHMM.md
- Content: queries run, findings, actions taken, skills updated, items shared
- Keep the last 50 research logs (delete older ones)

### Data Pruning (Phase 6 supplement)
- Delete health snapshots older than 7 days
- Delete research logs older than 30 days
- Keep ALL runbook entries forever (they're institutional knowledge)

---

## Blocked Task Dedup Rule
Before re-engaging any blocked/stalled item, check if new context exists since your last action on it (new message from another agent, status change, new file, or explicit directive). If nothing changed → skip it entirely. Do not re-comment, do not re-alert, do not re-attempt. Only re-engage when new information arrives. This prevents wasting tokens on unchanged blockers.

## Cron Failure Rule
Every cron job that can fail must have a consecutive error threshold. After 3 consecutive errors of the same type, disable the cron and alert Nick instead of continuing to fail silently.

## SESSION HEALTH RULE
If the current session has been running for 4+ hours or 50+ tool calls, proactively tell Nick:
"This session is getting heavy. Recommend `/new` to prevent compaction freeze. I'll pick up from memory."

This prevents the stuck session issue from 2026-03-21 (runbook-004 context: 20-hour session → compaction abort → frozen for 500+ seconds).
