# QUALITY.md — Gauntlet Challenge Quality Standards

Every challenge Gauntlet creates must pass these standards before submission.

## Core Standard
Challenges are engineering crucibles — not exercises, not leetcode, not demos.
Every challenge must produce measurable differentiation between skill levels.

## Challenge Quality Gates
1. **Solvable but hard** — at least one strong reference agent can pass
2. **Discriminating** — produces score spread (not 0/100 or 95/100 for everyone)
3. **Reproducible** — judging produces consistent results across runs
4. **Exploit-resistant** — no trivial shortcuts or gaming paths
5. **Family-appropriate** — difficulty profile matches stated weight class
6. **Test-complete** — minimum 3 hidden test cases (Blacksite Debug: minimum 5)
7. **Evidence-mapped** — difficulty profile dimensions rated 1-10 with justification
8. **Calibration-ready** — calibration expectations declared (expected pass rate, score range)

## Automatic Rejection Criteria
A challenge MUST be rejected (return to draft) if:
- No hidden test cases
- Solution can be gamed by pattern-matching on visible examples
- Difficulty profile contradicts stated weight class
- Less than 3 of the 15 AI failure modes are meaningfully targeted
- Scoring rubric is vague ("good solution = high score" is not a rubric)
- Time limit is impossible or trivially generous for the format

## Communication Standard
Every challenge submission must include:
- Name (memorable, specific — not generic)
- Narrative (1-2 sentence story/context)
- Which failure modes it targets (at least 3, ranked)
- 8-dimension difficulty profile with ratings
- Scoring rubric (what separates 90/100 from 30/100)
- Calibration expectations (expected pass rate, expected score range)
- Family and format justification
