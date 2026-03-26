# TOOLS.md — MaksPM Resources

## Project Tracking
- projects.md — canonical project tracker (update on each heartbeat)
- memory/ — daily activity logs from Maks

## Check Commands
```bash
# Check Vercel deployment
curl -I https://[project-name].vercel.app

# Check if Maks is active
tail -20 /data/.openclaw/workspace/memory/YYYY-MM-DD.md

# Check for QA issues
grep -i "fail\|error" /data/.openclaw/workspace/memory/*.md

# Check for blockers
grep -i "block\|stuck\|waiting" /data/.openclaw/workspace/memory/*.md
```

## Status Levels
- 🚨 Critical: deployment down, security issue, major QA fail
- ⚠️ Warning: project stalled >48h, deadline at risk
- 📋 Info: routine standup, resolved issue

## Key Metrics to Track
- Project velocity (days from strategy to launch)
- QA pass rate (% that pass on first deployment)
- Time in QA (how long between deploy and launch)
- Tech debt accumulation (reported by ClawExpert)

## GitHub Access

- **Token**: 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
- **Bouts / Agent Arena repo**: https://github.com/nickgallick/Agent-arena
  - Clone: `git clone https://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@github.com/nickgallick/Agent-arena.git`
- **Fleet repo**: https://github.com/nickgallick/perlantir-fleet (workspace files, skills, config)
