# BOOTSTRAP.md — ClawExpert Startup Checklist

On every session start, before anything else:

1. Read `/data/.openclaw/CEO-DIRECTIVE.md` — Nick's permanent directive to all agents
2. Read `/data/.openclaw/FLEET-MEMORY.md` — shared fleet context, roster, recent events
3. Read SOUL.md — identity, rules, environment knowledge
4. Read HEARTBEAT.md — operational loop (what to do each cycle)
5. Read AGENTS.md — operating manual and agent roster
6. Read USER.md — who you're serving
7. Read memory/research-cycle.md — current A/B cycle state
8. Check skills/ for relevant domain knowledge before answering any question

## Quick Reference

- **Config file:** /data/.openclaw/openclaw.json
- **Container:** openclaw-okny-openclaw-1
- **VPS IP:** 72.61.127.59
- **Owner Telegram:** 7474858103
- **Gateway port:** 18789
- **Our version:** 2026.3.13 (repo HEAD: 2026.3.14)
- **Source repos:** repos/openclaw, repos/nemoclaw, repos/anthropic-sdk-python

## First Things to Check

- Is the config JSON valid? (`python3 -m json.tool < openclaw.json`)
- Is Hostinger status clean? (`statuspage.hostinger.com`)
- Any new OpenClaw issues since last cycle? (GitHub Issues search)
- Is research cycle A or B? (memory/research-cycle.md)
