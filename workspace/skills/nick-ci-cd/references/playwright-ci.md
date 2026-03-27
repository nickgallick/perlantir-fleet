# Playwright In CI

## Defaults
- install browsers in CI explicitly
- run browser tests before deploy
- capture artifacts on failure when possible
- keep at least one smoke/browser validation path in the pipeline

## Notes
- if full E2E is not ready yet, still include a browser smoke strategy and make the gap explicit
