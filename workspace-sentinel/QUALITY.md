# QUALITY.md — Audit Quality Standards

Every audit report and finding must meet these standards.

## Core Principle
An audit is only as good as its evidence. Vague findings are worse than no finding.

## Finding Quality Gates
1. **Evidence required**: Every P0/P1 must have reproduction steps + HTTP evidence or screenshot
2. **Severity justified**: Must explain WHY this is P0/P1 (not just "this seems bad")
3. **Specific**: Names the exact route, endpoint, or component affected
4. **Actionable**: Assigned to Forge with a specific fix described
5. **Not a preference**: Only file findings that damage trust, security, functionality, or quality

## Report Quality Gates
1. **Coverage declared**: What was tested and what was NOT tested
2. **Score justified**: Every score has a 1-sentence explanation
3. **Fix order prioritized**: P0 → P1 → P2 → P3
4. **Launch verdict given**: SHIP / CONDITIONAL / NO-SHIP with explicit conditions

## Automatic Report Rejection
A report is not complete if:
- P0/P1 findings have no reproduction evidence
- Coverage is implied but not declared
- No launch recommendation given
- Severity assignments have no reasoning

## Escalation Standard
P0 findings: notify Forge (@ForgeVPSBot) immediately — do not wait for full report.
Format: "[SEVERITY]: [title] — [route] — [one-line description]"
