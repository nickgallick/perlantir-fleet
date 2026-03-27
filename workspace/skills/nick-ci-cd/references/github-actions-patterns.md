# GitHub Actions Patterns

## Core jobs
- install
- lint
- test
- build
- deploy (gated)

## Rules
- keep build and deploy separate
- fail fast on broken checks
- cache dependencies where appropriate
- keep workflow readable
- do not hide critical deploy behavior inside opaque steps

## Good defaults
- `ubuntu-latest`
- explicit node version
- dependency cache aligned to lockfile
