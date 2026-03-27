# 004 — Pipeline Flow Issues: MathMind First Run Post-Mortem

**Date:** 2026-03-21
**Severity:** Warning
**Project:** MathMind (first real pipeline test)

## Issues Found (3)

### Issue 1: MaksPM used sessions_send instead of sessions_spawn
**What happened:** MaksPM sent Pixel the design brief via `sessions_send` instead of `sessions_spawn`. Pixel received it and worked, but when Pixel finished (or timed out), there was no auto-announce back to MaksPM. MaksPM went idle. Nick waited 2+ hours with no update.

**Root cause:** MaksPM's session started before the handoff-protocols skill was updated to sessions_spawn. The session context still had the old sessions_send pattern in memory.

**Fix needed:** MaksPM needs a `/new` session reset so it loads the updated skills on next project. OR add the instruction directly to MaksPM's SOUL.md so it's always in the system prompt (not just in a skill that might not be read mid-session).

**Status:** Partially fixed — nudged MaksPM with explicit instruction. Permanent fix below.

---

### Issue 2: Pixel timed out on large design scope (13 screens)
**What happened:** Pixel was generating 13 screens with 4 age tier variants. Completed dashboards (4 tiers), onboarding, and grade select. Session was aborted during Practice Session generation (V0 timed out on Chat C).

**Root cause:** Even with `timeoutSeconds: 600`, a 13-screen design job exceeds what a single agent turn can complete. V0 generation per screen takes 2-5 min. 13 screens × 3-5 min = 40-65 min minimum. A single agent turn can't sustain that.

**Fix needed:** MaksPM should break large design scopes into batches:
- Batch 1: screens 1-4 (spawn Pixel, yield, receive)
- Batch 2: screens 5-8 (spawn Pixel again with batch 1 context)
- Batch 3: screens 9-13
Each batch completes in one agent turn. MaksPM chains them.

**Status:** Not yet implemented — needs orchestration-pipeline skill update.

---

### Issue 3: No progress updates during long Pixel sessions
**What happened:** Pixel worked for 2+ hours with no status update to Nick. MaksPM had yielded and was waiting. Nick had no visibility into what was happening.

**Root cause:** sessions_spawn is all-or-nothing — you get the result when it completes, or nothing. No intermediate updates during a long-running spawn.

**Fix options:**
A) Break into batches (fixes both timeout + visibility)
B) Have Pixel send Nick a direct status update every N screens via sessions_send (Pixel → Nick directly)
C) Add a monitoring cron that checks Pixel's activity every 10 min and reports to Nick

**Recommended:** Option A (batching) — solves timeout AND visibility. Option B as supplement for extra-long batches.

---

## Permanent Fixes Required

### Fix 1: Add sessions_spawn to MaksPM's SOUL.md system prompt
Don't rely on skill files being read mid-session. Put the core instruction in SOUL.md where it's always loaded.

Add to SOUL.md Core Rules:
```
ALWAYS use sessions_spawn(mode="run") for agent handoffs, NEVER sessions_send for work assignments.
After every sessions_spawn, call sessions_yield() to receive the auto-announce.
Use sessions_send ONLY for quick nudges or status checks.
```

### Fix 2: Add batch splitting to orchestration-pipeline
For design phase: if >6 screens, split into batches of 4-5 screens per spawn.
For build phase: if >8 files expected, split into module-based batches.

Add to orchestration-pipeline Phase 3 (Design):
```
If screens > 6:
  Split into batches of 4-5 screens
  Spawn Pixel for batch 1 → yield → receive
  Send Nick: "Design batch 1 complete (N/total screens)"
  Spawn Pixel for batch 2 with batch 1 context → yield → receive
  Repeat until all screens designed
```

### Fix 3: Add direct progress updates for long phases
Add to Pixel's SOUL.md:
```
For design requests with 6+ screens: after completing each batch of 3-4 screens,
send Nick a brief progress update via sessions_send before continuing.
Format: "🎨 Pixel Progress — [N/total] screens designed. Working on: [next screens]"
```

## Prevention Checklist (for future projects)
- [ ] Is MaksPM using sessions_spawn? (check session transcript)
- [ ] Is the design scope > 6 screens? If yes, batch it
- [ ] Is the build scope > 8 files? If yes, batch it  
- [ ] Has MaksPM loaded the latest skills? (check session start time vs skill update time)
