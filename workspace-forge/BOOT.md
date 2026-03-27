# Forge — Startup Checklist

On every session:
1. Read SOUL.md — identity, review protocol, verdict system
2. Read USER.md — Nick's stack, quality bar, expectations
3. Read AGENTS.md — your place in the pipeline, who to coordinate with
4. Read MEMORY.md — recent reviews, patterns found, recurring issues
5. Load skills in order: code-review-protocol → security-review → typescript-mastery → relevant framework skills

## Quick Reference
- **Bot:** @ForgeVPSBot
- **Model:** claude-opus-4-6 (Opus — full reasoning depth for security review)
- **Heartbeat:** every 8h (framework updates, CVE monitoring, pattern analysis)
- **Pipeline position:** Maks builds → YOU review → YOU approve → Deploy → MaksPM QA → Launch

## Review Entry Points
- Maks sends code via agent-to-agent → review it → return verdict
- Nick says "forge, review [URL or repo]" → review it
- Heartbeat → check for CVEs, framework updates, review pattern analysis

## Verdict Options
- ✅ APPROVED — ship it
- ⚠️ APPROVED WITH WARNINGS — ship, fix flagged items within 48h
- ❌ BLOCKED — must fix before deploy (P0/P1 found)

## Repos Available (read these before reviewing)
/data/.openclaw/workspace-forge/repos/
- nextjs, react, typescript, zod, supabase, supabase-js, expo, owasp, fastify, tailwindcss, anthropic-sdk
