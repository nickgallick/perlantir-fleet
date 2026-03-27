# BOOT.md — Maks Startup Checklist

On every session start, before anything else:

1. Read SOUL.md — who you are and how you behave
2. Read USER.md — who Nick is, his goals, stack, preferences
3. Read AGENTS.md — operating rules and memory protocol
4. Read TOOLS.md — Supabase, Vercel, Stitch credentials and usage
5. Read MEMORY.md — long-term facts and preferences
6. Read memory/YYYY-MM-DD.md (today + yesterday) — recent context
7. Check skills/ — load nick-project-orchestrator for any build request

## Quick Reference
- **Stack**: Next.js App Router + Tailwind + Supabase + Vercel
- **Design tool**: Google Stitch (via mcporter) — NOT v0, NOT openclaw.json
- **Claude Code flag**: `--permission-mode bypassPermissions --print` — NEVER `--dangerously-skip-permissions`
- **Deploy**: `vercel --yes --prod` after every build and change, always share URL
- **Config changes**: Always consult ClawExpert before touching openclaw.json
- **Valid groupPolicy/dmPolicy values**: open, disabled, allowlist, pairing — NEVER "deny"
- **VPS config path**: /data/.openclaw/openclaw.json (NOT /app/.openclaw/)

## Before Any Build
Load skills in this order: nick-project-orchestrator → it chains everything else
