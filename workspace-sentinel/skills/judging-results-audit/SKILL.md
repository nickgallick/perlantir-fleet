# Judging & Results Audit — Sentinel Standard

## The 4-Lane Judging System
Bouts uses a 4-lane scoring system. Every challenge result must show all 4 lanes:

| Lane | Weight | What it measures |
|------|--------|-----------------|
| Objective Judge | 50% | Hidden tests, exact outputs, lint/build/runtime |
| Process Judge | 20% | Tool use quality, error recovery, reckless moves |
| Strategy Judge | 20% | Decomposition, prioritization, tradeoff handling |
| Integrity Judge | 10% | Cheating, shortcutting, spec violations, unsafe behavior |

## What to Audit

### Results Pages
- Do completed challenges show a results/breakdown page?
- Are all 4 lanes visible with individual scores?
- Are the percentage weights displayed correctly?
- Is the total score computed correctly (weighted sum)?
- Is the winning agent clearly identified?

### Replay Detail
- Does /replays/[id] show a detailed breakdown?
- Are all 4 judge lanes shown separately?
- Is there a timeline/trace of agent actions?
- Can a spectator understand what the agent did and why it scored how it did?

### Post-Match Breakdown
- Is there a "what separated the scores" section?
- Are specific failure modes identified?
- Is the breakdown honest (shows where the agent failed, not just where it passed)?

### Leaderboard
- Does /leaderboard show ELO ratings?
- Are sub-rating columns present? (Process / Strategy / Integrity)
- Are Win/Loss records shown?
- Is the radar chart present on agent profiles (/agents/[id])?

### Score Integrity
- Are scores stored immutably after judging?
- Is the activation_snapshot frozen (prompt hash, judge weights, thresholds)?
- Can scores be retroactively changed? (should not be possible without admin action + audit trail)

## Critical Trust Checks

### Transparency
- Is there a public /judging page explaining the system?
- Does it accurately describe 4 lanes (not the old 3-judge system)?
- Are the exact scoring formulas NOT published (per contest rules)?
- Are "bounded band" percentages described accurately?

### Consistency
- Do all references to judging say "4-lane" not "3-judge" or "three judges"?
- Is "Claude+GPT-4o+Gemini" language removed? (old system)
- Does the FAQ match the current system?

### Edge Cases
- What happens when a challenge has 0 submissions?
- What happens when a submission times out?
- What happens when the Objective Judge finds 0 passing tests?
- What happens when scores are tied?

## Stale Copy Checklist (P1 if any remain)
- [ ] No "3-Judge Panel" anywhere
- [ ] No "Three independent judges..."
- [ ] No "Claude+GPT-4o+Gemini"
- [ ] No "old scoring system" language
- [ ] All judging references say "4-lane" or "four-lane"
- [ ] Contest Rules Section 6 references 4 lanes (not 3)
- [ ] How It Works references 4-lane system correctly

## Spectate Mode
- Does /challenges/[id]/spectate load?
- Is there real-time or near-real-time data?
- Is the experience useful for a spectator (not just a blank page)?
- Are agent actions visible during judging?

## Test Patterns
```javascript
// Check leaderboard for sub-rating columns
await page.goto(BASE + '/leaderboard');
const content = await page.content();
// Sub-ratings column header is in the table
const hasSubRatings = content.includes('Sub-ratings') || content.includes('sub-rating');
if (!hasSubRatings) errors.push('Leaderboard: Sub-ratings column not found');

// Check agent profile for radar chart
const agentsResp = await page.request.get(BASE + '/api/agents?limit=1');
const agentsData = await agentsResp.json();
if (agentsData.agents?.length > 0) {
  const agentId = agentsData.agents[0].id;
  await page.goto(BASE + `/agents/${agentId}`);
  const agentContent = await page.content();
  if (!agentContent.includes('<svg') && !agentContent.includes('radar')) {
    errors.push('Agent profile: No radar chart found');
  }
}
```
