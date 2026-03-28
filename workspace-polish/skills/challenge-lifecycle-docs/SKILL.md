# Challenge Lifecycle & Admin Flow Docs — Polish Reference

## Challenge Lifecycle (14 States)
```
draft
  ├── draft_failed_validation  (auto-rejected at intake)
  └── draft_review
        ├── needs_revision  (Forge review: rejected)
        └── approved_for_calibration
              └── calibrating
                    ├── flagged  (calibration issues found)
                    └── passed
                          ├── passed_reserve  (good but not needed now)
                          └── queued
                                └── active
                                      ├── quarantined  (quality enforcement pulled it)
                                      ├── retired  (intentionally removed)
                                      └── archived
```

## Admin/Operator Flow (What Polish Should Evaluate)
The operator experience has 4 key workflows. Each should feel like a serious, professional tool.

### Workflow 1: Forge Review Queue
**Route**: `GET/POST /api/admin/forge-review`
**UI**: /admin/challenges (pipeline section)
**What operator does**: Review Gauntlet-submitted challenge bundles for technical quality
- See all challenges in `draft_review` state
- Open a challenge's full package (prompt, tests, difficulty profile, scoring rubric)
- Submit a verdict: approve → `approved_for_calibration` | request changes → `needs_revision` | reject → `draft_failed_validation`

**What good UI looks like**: Clean queue view, clear action buttons, structured review package layout, confirmation on verdict submission.

**What bad UI looks like**: Flat table with no context, no review package layout, unclear what "approve" actually does.

### Workflow 2: Inventory Decisions
**Route**: `GET/POST /api/admin/inventory`
**UI**: /admin/challenges (inventory section)
**What operator does**: Decide what to do with calibration-passed challenges
- Options: publish_now / hold_reserve / queue_for_later / mutate_before_release / quarantine / reject

**What good UI looks like**: Shows advisory context (pool size, family cap, recommended action), confirmation on decision, clear state transition shown.

**What bad UI looks like**: Just a list of challenges with a dropdown, no advisory context, no confirmation.

### Workflow 3: Quality Monitoring
**Route**: `GET /api/admin/challenge-quality`
**UI**: /admin (quality section)
**What operator does**: Monitor CDI scores, flag counts, quarantine status
- CDI = Challenge Difficulty Index (spread of scores across calibration runs)
- Auto-flag: challenges with poor score spread
- Auto-quarantine: challenges with critical quality failures

**What good UI looks like**: Dashboard showing total active, flagged, quarantined; trend over time; ability to act on flagged challenges.

**What bad UI looks like**: Raw JSON dump, no visualization, no action path.

### Workflow 4: Pipeline Status Overview
**What operator needs**: Single view of all challenges by pipeline_status
- How many in draft / review / calibrating / active / quarantined?
- Which ones need action?

## Polish Evaluation Criteria for Admin Flows

### P0
- Admin surfaces are completely inaccessible (blocked, 500, etc.)
- Destructive actions (quarantine, reject) have no confirmation
- Critical workflow has no success/error feedback

### P1
- Admin surface looks like a prototype (default table, no hierarchy, no empty states)
- Operator cannot determine what action to take next
- Review queue shows no context — just challenge IDs
- No confirmation on significant state transitions

### P2
- Admin surface is functional but not ergonomic (too many clicks for common actions)
- Queue is hard to scan (poor use of visual hierarchy)
- Status chips use inconsistent vocabulary

### P3
- Minor visual inconsistencies in admin tables
- Small spacing issues
- Button label wording could be more precise

## Challenge Detail Page (Public)
What a serious competitor needs to see on a challenge detail page:
- Challenge name and narrative description
- Family: Blacksite Debug / Fog of War / False Summit / etc.
- Format: Sprint / Standard / Marathon
- Weight class: Lightweight / Middleweight / Heavyweight / Frontier
- Time limit
- Difficulty profile (8 dimensions) — if public-facing
- Prize pool (when available)
- Entry fee (when applicable)
- Registration/entry CTA
- Status (open / accepting entries / in progress / completed)

**What the page must NOT show**:
- Hidden test cases (ever)
- Internal pipeline_status values (these are operator-only)
- Calibration data or CDI scores (operator-only)
- Scoring formula weights beyond what's published on /judging
