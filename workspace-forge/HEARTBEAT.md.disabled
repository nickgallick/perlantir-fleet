# HEARTBEAT.md — Forge Operational Loop

This is the recurring self-improvement cycle Forge runs to stay current and sharpen its review capabilities. Each phase feeds into the next.

---

## Phase 1: Framework Update Monitoring

Stay current with the frameworks and tools in our stack.

### 1.1 Check for Updates
- Check release notes and changelogs for:
  - Next.js (App Router changes, new APIs, deprecations)
  - React (new hooks, concurrent features, compiler updates)
  - Supabase (auth changes, new features, RLS updates, client library changes)
  - Expo / React Native (SDK updates, new modules, breaking changes)
  - TypeScript (new type features, strictness options)
  - Zod (new validators, breaking changes)
  - Tailwind CSS (new utilities, configuration changes)
- Use `skills/forge-research/SKILL.md` for research methodology
- Use `skills/framework-source-code/SKILL.md` for source validation

### 1.2 Assess Impact
- For each update, determine:
  - Does this affect our current code patterns?
  - Does this introduce new best practices we should adopt?
  - Does this deprecate patterns we currently use?
  - Does this fix bugs we've been working around?

### 1.3 Update Skills
- Update relevant `skills/*/SKILL.md` files with new knowledge
- Add migration notes if patterns need to change
- Log the update in `research-logs/`

---

## Phase 2: Coding Best Practices Research

Research and internalize evolving best practices beyond framework updates.

- Security advisories (OWASP, CVE databases, npm advisories)
- Performance research (Core Web Vitals changes, new optimization techniques)
- Accessibility standards updates (WCAG updates, new ARIA patterns)
- TypeScript community patterns (type-level programming, utility types)
- Testing strategies (new testing patterns, tools, approaches)
- Database optimization techniques (PostgreSQL-specific)
- API design evolution (REST best practices, error handling standards)

Sources: See `skills/forge-research/SKILL.md` for approved research sources and methodology.

---

## Phase 3: Review Pattern Analysis

Learn from past reviews to improve future reviews.

### 3.1 Analyze Review History
- Review past reviews in `review-history/`
- Identify:
  - **Recurring issues** — What problems keep appearing? These need better prevention.
  - **False positives** — Where did I flag something that wasn't actually a problem? Calibrate.
  - **Missed issues** — Were there bugs or problems I should have caught? Learn the pattern.
  - **Common fixes** — What suggestions do developers consistently accept? Reinforce these.

### 3.2 Extract Patterns
- Group recurring issues by category (security, performance, types, etc.)
- Update relevant skill files with new patterns to watch for
- Create runbook entries for complex or nuanced review scenarios

---

## Phase 4: Self-Improvement

Synthesize learnings and evolve.

### 4.1 Update Skills
- Revise `skills/*/SKILL.md` files based on Phase 1-3 findings
- Add new examples of good and bad patterns
- Remove outdated guidance
- Sharpen severity calibration

### 4.2 Update Review Protocol
- If new checklist items are needed, propose updates to `SOUL.md`
- If severity levels need recalibration, update `skills/code-review-protocol/SKILL.md`

### 4.3 Log Changes
- Record what changed and why in `research-logs/`
- Create runbook entries for significant process changes

### 4.4 Validate
- Re-review a past PR with updated knowledge
- Confirm the updated skills would have caught previously missed issues
- Confirm the updated skills would not have introduced new false positives

---

## Phase 5: Share

Communicate improvements to the team.

- When skill files are updated with significant new patterns, note them in review comments so developers learn too
- When new anti-patterns are identified, document them clearly with examples and fixes
- When framework updates affect the project, proactively flag them in reviews
- Keep `runbook/` updated so operational knowledge is preserved

---

## Cycle Frequency

- **Phase 1** (Framework Updates): Before each review session, or when a developer mentions a framework update
- **Phase 2** (Best Practices): Weekly research cycle
- **Phase 3** (Review Analysis): After every 5-10 reviews
- **Phase 4** (Self-Improvement): After Phase 1-3 produce actionable findings
- **Phase 5** (Share): Continuously, as part of reviews and documentation

---

## PHASE 6: WEEKLY SECURITY SCAN (Sundays only)

Load `weekly-security-scan` skill and execute:

1. Discover all active projects in ~/Projects/
2. Run secret scan (exposed credentials, .env files committed)
3. Run dependency vulnerability scan (npm audit high/critical)
4. Run RLS coverage check (tables without row-level security)
5. Run auth boundary check (API routes without auth)

Report format: see weekly-security-scan skill.

Critical findings → message Nick immediately.
Warnings → include in Sunday heartbeat report.
Clean scan → log to runbook/security-scan-YYYY-MM-DD.md, no message.

---

## PHASE 7: SELF-REVIEW (after every 5 code reviews)

Load `self-review` skill and execute:

1. Read last 10 review-history/ entries
2. Check: did QA catch anything Forge missed? → add to skills
3. Check: any issue appearing 3+ times? → send Maks proactive tip
4. Check: any skills updated since last self-review that need verification?
5. Self-review any skill changes made this cycle before finalizing

---

## PHASE 8: DEVELOPER PATTERN ANALYSIS (every cycle)

### 8.1 Review the review log
Read /data/.openclaw/workspace-forge/developer-profiles/review-log.md
- Count reviews since last analysis
- If 5+ new reviews since last analysis → run full pattern recalculation

### 8.2 Update pattern profiles
For each developer with new reviews:
- Recalculate top recurring issue categories
- Update blind spot summary
- Adjust review calibration priorities
- Check if any previously recurring issues have improved (3+ clean reviews)

### 8.3 Research new attack patterns
Search (rotate):
- "new web application vulnerability 2026"
- "OWASP emerging threats"
- "Next.js security vulnerability"
- "Supabase RLS bypass"
- "React XSS attack vector new"
- "financial application security patterns"

If new attack patterns found → add to threat-modeling/common-attacks.md

---

## PHASE 9: SECURITY INTELLIGENCE (every cycle)

### 9.1 CVE and Advisory Monitoring
Search (rotate each cycle):
- "CVE React Next.js 2026"
- "Supabase security advisory"
- "npm vulnerability critical 2026"
- "OWASP new guidance"
- "Node.js security update"
- "Vercel security update"
- "Next.js security patch"

### 9.2 Assess and Act
For each finding:
- Does it affect our stack versions?
- Is there a patch available?
- Do any current projects use the affected component?

### 9.3 Alert Protocol
- **Critical CVE affecting our stack** → message Nick immediately
- **High severity, patch available** → log to runbook + mention in next review
- **Low/medium or unaffected** → log to research-logs/ for reference
- Update `skills/owasp-stack-specific/SKILL.md`, `skills/react-nextjs-security/SKILL.md`, or `skills/supabase-attack-vectors/SKILL.md` with new findings

## Blocked Task Dedup Rule
Before re-engaging any blocked/stalled item, check if new context exists since your last action on it (new message from another agent, status change, new file, or explicit directive). If nothing changed → skip it entirely. Do not re-comment, do not re-alert, do not re-attempt. Only re-engage when new information arrives. This prevents wasting tokens on unchanged blockers.
