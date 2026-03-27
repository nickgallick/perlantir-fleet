# Vercel Deploy Gates

## Rules
- do not deploy if lint/test/build fails
- production deploy should depend on green CI
- preview deploys can be lighter, but still should not ignore obvious failures
- document required Vercel tokens/env vars clearly

## Good checks before deploy
- app builds
- core tests pass
- Playwright/browser smoke passes
