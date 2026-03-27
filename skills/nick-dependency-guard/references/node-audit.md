# Node Audit

## Common checks
- `npm audit`
- outdated packages
- lockfile presence
- major version upgrade risk

## Rules
- treat critical vulnerabilities as blockers
- prefer `npm ci`/lockfile-consistent installs
- check whether build/test still pass after upgrade
