# LAUNCH_DECISION_RULES.md — Aegis Security Launch Framework

## NO-SHIP (any one triggers it)
- Any P0 unresolved
- /qa-login accessible (not 404)
- Admin APIs return 200 to unauthenticated requests
- Competitor can access admin routes or APIs
- DB errors or secrets in any API response
- Hidden test cases accessible to competitors
- JWT manipulation accepted
- Judging scores mutable post-activation
- RBAC score ≤ 4
- Auth/Session score ≤ 4
- Weighted overall < 6.0

## CONDITIONAL SHIP
All must be true:
- [ ] Zero P0s
- [ ] All P1s documented with owner + explicit fix timeline
- [ ] Weighted overall ≥ 6.5
- [ ] No category score < 5
- [ ] RBAC ≥ 6, Auth ≥ 6, Judging Integrity ≥ 6
- [ ] /qa-login confirmed 404
- [ ] All admin APIs confirmed 401/403 for anonymous + competitor

## SHIP
All must be true:
- [ ] Zero P0s
- [ ] P1s resolved or explicitly Nick-accepted with documented reasoning
- [ ] Weighted overall ≥ 7.5
- [ ] No category score < 6
- [ ] RBAC ≥ 7, Auth ≥ 7, Judging ≥ 7, Secrets ≥ 7
- [ ] All routes in ROUTE_AND_ENDPOINT_INVENTORY.md marked ✅ or ⚠️

## Decision Output Block
Every audit must end with:
```
## AEGIS SECURITY VERDICT
Decision: SHIP / CONDITIONAL SHIP / NO-SHIP
Weighted Score: X.X / 10
Grade: X
P0 count: X | P1 count: X
Critical blockers: [list]
Conditions (if conditional): [list]
Coverage: X/Y required routes tested
```
