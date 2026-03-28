# Challenge Pipeline Audit — Sentinel Standard

## What the Pipeline Is
Challenges go through a 14-state lifecycle from Gauntlet creation to live competition.

**States**: draft → draft_failed_validation | draft_review → needs_revision | approved_for_calibration → calibrating → passed | flagged → passed_reserve | queued | active → quarantined | retired | archived

## Pipeline APIs to Test

### Intake (Gauntlet → Platform)
- `POST /api/challenges/intake`
- Auth: `Bearer a86c6d887c15c5bf259d2f9bcfadddf9`
- Required fields: family, weight_class, format, name, description, prompt, starter_code, hidden_tests, difficulty_profile, scoring_rubric, calibration_expectations, evidence_map

### Forge Review (Admin)
- `GET /api/admin/forge-review` — list pending review queue
- `POST /api/admin/forge-review` — submit verdict (approve/reject/needs_revision)

### Inventory (Operator Decision)
- `GET /api/admin/inventory` — list with advisories
- `POST /api/admin/inventory` — submit decision (publish_now/hold_reserve/queue_for_later/mutate_before_release/quarantine/reject)

### Quality Enforcement
- `GET /api/cron/challenge-quality` — runs CDI check
- `GET /api/admin/challenge-quality` — quality status

### Calibration
- `POST /api/admin/calibration` — run_synthetic / run_full / run_forced_real / mutate

## What to Audit

### Availability Check
- Do all pipeline API routes return responses (not 500)?
- Is challenge_bundles table accessible? (⚠️ Migration 00024 may be partially applied)
- Are forge-review and inventory routes protected (return 401 unauthed)?

### Data Integrity
- Do challenges in the DB have valid pipeline_status values?
- Are activation snapshots created when challenges go active?
- Is the CDI score present on calibrated challenges?

### UI Access
- Can an admin operator access the pipeline management UI?
- Are challenge states visible in /admin/challenges?
- Is there a way to manually trigger pipeline transitions from the UI?

### Error Handling
- What happens when you POST to /api/challenges/intake with invalid data?
- What happens when migration 00024 is not applied (challenge_bundles missing)?
- What does the error look like to an operator?

## Known Issues (as of 2026-03-29)
- ⚠️ Migration 00024 partially applied — challenge_bundles table may not exist
  - All intake/forge-review/inventory routes will 500 until fixed
  - Forge needs to re-call migration runner with correct Bearer header
  - This is a P0 for the pipeline — nothing can flow through until resolved

## Calibration System
- Synthetic runner: fast automated calibration
- Real LLM runner: actual model evaluation (more expensive)
- Policy: daily=synthetic only, standard=synthetic+optional real, featured/prize=both required
- Calibration results stored in challenge_calibration_results table
- CDI (Challenge Difficulty Index) computed from calibration runs

## Quality Enforcement
- Runs every 15 minutes via cron
- Checks CDI, judge divergence, score spread
- Auto-flags challenges below quality threshold
- Auto-quarantines on critical failures
- Results via /api/admin/challenge-quality

## Activation Gate Requirements
A challenge can only go active if:
- has_objective_tests = true
- prompt present
- description present  
- format present
- time_limit present
- calibration_status = passed

## Test Checklist
- [ ] POST /api/challenges/intake with valid bundle → expect 200 or appropriate error
- [ ] GET /api/admin/forge-review → expect queue (may be empty)
- [ ] GET /api/admin/inventory → expect list with advisories
- [ ] GET /api/cron/challenge-quality → expect JSON result
- [ ] Verify challenge_bundles table exists (migration 00024)
- [ ] Check active challenges have activation_snapshot
- [ ] Verify /api/challenges returns real challenges with correct fields
