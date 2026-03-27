# TOOLS.md — ClawExpert Operations Reference

## System

- **VPS IP**: 72.61.127.59 (Hostinger)
- **Gateway port**: 18789
- **Gateway token**: R0ddvlV8VIER6QRhJ8KujsOdZfJG7HxM
- **Hooks token**: hooks_R0ddvlV8VIER6QRhJ8KujsOdZfJG7HxM
- **OpenClaw version**: 2026.3.24
- **Binary**: /data/.npm-global/bin/openclaw

## Config

- **Main config**: /data/.openclaw/openclaw.json
- **Backup before editing**: `cp /data/.openclaw/openclaw.json /data/.openclaw/openclaw.json.bak-$(date +%Y%m%d-%H%M%S)`
- **Reload config**: `kill -USR1 $(pgrep -f openclaw-gateway)`
- **Validate JSON**: `cat /data/.openclaw/openclaw.json | python3 -m json.tool > /dev/null && echo "VALID"`

## Gateway Health Checks

```bash
# Is gateway running?
pgrep -f openclaw-gateway

# Check version
/data/.npm-global/bin/openclaw --version

# Check disk
df -h /data

# Check workspace sizes
du -sh /data/.openclaw/workspace* 2>/dev/null

# Check memory usage
free -h

# Check processes
ps aux | grep -E "openclaw|node" | grep -v grep
```

## Logs

```bash
# Recent logs (inside container)
tail -100 /data/.openclaw/logs/config-audit.jsonl
```

## Git / GitHub

- **Fleet repo**: https://github.com/nickgallick/perlantir-fleet (private)
- **GitHub token**: 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
- **Commit changes**: `cd /data/.openclaw && git add -A && git commit -m "message" && git push origin main`
- **Quick status**: `cd /data/.openclaw && git status --short`

## Crons (Active)

| Name | ID | Schedule |
|------|-----|----------|
| fleet-git-commit | e1e68d15 | 2 AM KL daily |
| handoff-refresh | 3924a862 | Every 48h |

## Agent Workspaces

| Agent | Path |
|-------|------|
| Maks | /data/.openclaw/workspace |
| MaksPM | /data/.openclaw/workspace-pm |
| Scout | /data/.openclaw/workspace-scout |
| ClawExpert | /data/.openclaw/workspace-clawexpert |
| Forge | /data/.openclaw/workspace-forge |
| Pixel | /data/.openclaw/workspace-pixel |
| Launch | /data/.openclaw/workspace-launch |
| Chain | /data/.openclaw/workspace-chain |
| Counsel | /data/.openclaw/workspace-counsel |

## Known Harmless Log Warnings

- nostr module missing
- apply_patch entries
- autoSelectFamily warnings

## Update OpenClaw

```bash
/data/.npm-global/bin/openclaw update --dry-run  # preview
/data/.npm-global/bin/openclaw update            # apply
```

## Rollback

```bash
npm install -g openclaw@VERSION
cp /data/.openclaw/openclaw.json.bak-TIMESTAMP /data/.openclaw/openclaw.json
kill -USR1 $(pgrep -f openclaw-gateway)
```
