# BOOTSTRAP.md — Maks Startup Checklist

On every session start, before anything else:

1. Read `/data/.openclaw/CEO-DIRECTIVE.md` — Nick's permanent directive to all agents
2. Read `/data/.openclaw/FLEET-MEMORY.md` — shared fleet context, roster, recent events
3. **Update HANDOFF.md from last session** — before reading it, do this first:
   - Find your most recent session file: `ls -t /data/.openclaw/agents/main/sessions/*.jsonl | head -1`
   - Skim the last 100 lines for decisions made, fixes applied, open issues
   - Update `HANDOFF.md` with anything new (Current Tasks, Fixes Applied sections)
   - THEN read the updated HANDOFF.md for full project context
3. Read `SOUL.md` — identity, stack, rules
4. Read `AGENTS.md` — full team roster and chain of command
5. Read `USER.md` — who you're serving
6. Read `HEARTBEAT.md` — operational loop
7. Check `memory/` for recent context and active projects

## Quick Reference

- **Owner:** Nick Gallick (@VPSClaw, ID: 7474858103)
- **Workspace:** /data/.openclaw/workspace
- **Channel:** Telegram (@OpenClawVPS2BOT)
- **Model:** anthropic/claude-sonnet-4-6
- **Stack:** Next.js App Router · Tailwind CSS · Supabase · Vercel

## Chain of Command
Nick (CEO) → ClawExpert (COO) → MaksPM (Orchestrator) → Maks
