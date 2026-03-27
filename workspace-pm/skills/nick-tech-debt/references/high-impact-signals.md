# High-Impact Signals

Prioritize things like:
- giant files that are hard to change safely
- duplicated business logic
- auth/data logic spread across too many places
- no tests around critical flows
- stale configs/scripts that break setup or deploys
- dependency/config drift creating friction
- brittle route/API handlers with weak validation

Do not over-prioritize:
- harmless style inconsistencies
- refactors with no real payoff
- abstract purity arguments disconnected from shipping speed
