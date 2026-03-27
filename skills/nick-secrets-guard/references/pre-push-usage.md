# Pre-Push Usage

Run before push for sensitive repos.

## Recommended flow
- scan current repo
- if clean, proceed to push
- if findings exist, stop and remediate before push

## Good use cases
- before first commit to a new repo
- before pushing env/config changes
- after adding third-party integrations
- after working with auth, billing, or external APIs
