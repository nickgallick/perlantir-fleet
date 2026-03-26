# Risk Register — Project Risk Tracking Framework

## Purpose
Identify, assess, and mitigate risks at project intake and throughout the pipeline. Every project gets a risk register. Risks are reviewed at each phase transition and COO gate.

## Risk Categories

### 1. Technical Risks
- New/unfamiliar technology in the stack
- Complex integrations (third-party APIs, OAuth, payments)
- Performance requirements (real-time, high concurrency)
- Mobile-specific challenges (Expo, native modules)
- Database complexity (complex RLS, migrations, real-time subscriptions)

### 2. Scope Risks
- Unclear or evolving requirements
- Feature creep during build phase
- Nick adds "one more thing" mid-build
- Underestimated complexity revealed during architecture
- Design specs that imply features not in architecture

### 3. Dependency Risks
- External API availability/reliability
- Third-party service rate limits or pricing changes
- Apple/Google store review timelines
- DNS propagation, domain setup
- Supabase plan limits (storage, edge functions, realtime connections)

### 4. Timeline Risks
- Agent capacity (multiple projects competing)
- Model rate limits or degraded performance
- COO gate failures requiring rework
- QA failures requiring fix iterations (max 3)
- Nick unavailable for decisions when needed

## Risk Assessment Matrix

| | **Low Impact** | **Medium Impact** | **High Impact** |
|---|---|---|---|
| **High Likelihood** | 🟡 Monitor | 🟠 Mitigate | 🔴 Block/Redesign |
| **Medium Likelihood** | 🟢 Accept | 🟡 Monitor | 🟠 Mitigate |
| **Low Likelihood** | 🟢 Accept | 🟢 Accept | 🟡 Monitor |

## Risk Register Template

Create as `active-projects/[project]-risks.md` at intake:

```markdown
# Risk Register — [Project Name]
**Created**: [date]
**Last Reviewed**: [date]
**Overall Risk Level**: 🟢 Low / 🟡 Medium / 🟠 High / 🔴 Critical

## Active Risks

| ID | Category | Description | Likelihood | Impact | Rating | Mitigation | Owner | Status |
|----|----------|-------------|-----------|--------|--------|------------|-------|--------|
| R1 | Technical | | H/M/L | H/M/L | 🟢🟡🟠🔴 | | | Open/Mitigated/Closed |
| R2 | Scope | | H/M/L | H/M/L | 🟢🟡🟠🔴 | | | Open/Mitigated/Closed |
| R3 | Dependency | | H/M/L | H/M/L | 🟢🟡🟠🔴 | | | Open/Mitigated/Closed |
| R4 | Timeline | | H/M/L | H/M/L | 🟢🟡🟠🔴 | | | Open/Mitigated/Closed |

## Risk History
| Date | Risk ID | Event | Action Taken |
|------|---------|-------|-------------|
| | | | |

## Pre-Mortem Notes
[What could go wrong with this project? Written at intake.]
```

## When to Assess Risks

### At Intake (Mandatory)
Run through all 4 categories. Identify at least:
- 1-2 technical risks
- 1 scope risk
- 1 dependency risk
- 1 timeline risk
Even "low risk" projects have risks. If you can't identify any, you haven't thought hard enough.

### At Each Phase Transition
- Any new risks revealed by the completed phase?
- Any existing risks that changed likelihood/impact?
- Any risks that can be closed?

### At COO Gates
- COO may identify risks during review
- Add any COO-flagged risks immediately

### At QA
- Failed QA items may reveal unmitigated risks
- Update risk register with actual outcomes vs. predictions

## Common Risks by Project Type

### Web App (Next.js + Supabase + Vercel)
- RLS policy complexity → data leaks
- Vercel cold start on serverless → slow first load
- Supabase free tier limits → scaling issues
- OAuth provider configuration → auth failures

### Mobile App (Expo + React Native)
- Expo build failures → EAS config issues
- App store review rejection → compliance gaps
- Deep linking configuration → broken navigation
- Push notification setup → platform-specific gotchas

### AI-Integrated App
- API cost overruns → unbounded token usage
- Model latency → poor UX for real-time features
- Prompt injection → security risk
- Rate limits → degraded functionality under load

## Risk Escalation Rules
- 🟢 Accept: Log and move on
- 🟡 Monitor: Review at each phase transition
- 🟠 Mitigate: Must have active mitigation plan before proceeding
- 🔴 Block/Redesign: Stop pipeline, escalate to Nick with options. Do not proceed until resolved.

## Post-Project Risk Review
At project completion, review the risk register:
1. Which risks materialized? Were mitigations effective?
2. Which risks were overestimated? Underestimated?
3. Any new risk patterns to add to "Common Risks" above?
4. Update this skill with lessons learned.
