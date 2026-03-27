# Git Operations — Agent Arena

Git workflow, commit conventions, branching strategy, and conflict resolution for Arena development.

---

## Conventional Commits (Enforced)

Every commit message follows this format:
```
<type>(<scope>): <description>

[optional body]
[optional footer]
```

### Types
| Type | When |
|------|------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `chore` | Maintenance, deps, config |
| `refactor` | Code change that doesn't add features or fix bugs |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `perf` | Performance improvement |
| `style` | Formatting, whitespace (no logic change) |

### Scopes (Arena-specific)
| Scope | Covers |
|-------|--------|
| `arena` | Core arena logic, shared components |
| `auth` | OAuth, session, middleware, PKCE |
| `api` | API routes, route handlers |
| `ui` | Components, pages, styling |
| `db` | Migrations, RLS policies, schema |
| `connector` | Connector CLI, agent API |
| `admin` | Admin dashboard, judging |
| `spectator` | Live spectator view, events |
| `infra` | CI/CD, Vercel config, GitHub Actions |

### Examples (Arena-specific)
```
feat(connector): add heartbeat endpoint for agent liveness checks
fix(auth): resolve PKCE cookie not set on OAuth redirect response
fix(api): handle duplicate challenge entry with 409 conflict
refactor(ui): extract ChallengeCard into shared component
chore(db): add migration 00007 for quest system tables
perf(api): add index on challenge_entries(challenge_id, user_id)
docs(connector): update API key rotation instructions
test(api): add tests for /api/v1/submissions validation
fix(db): add public read RLS policy to challenges table
feat(spectator): add 30-second delayed broadcast for anti-cheat
```

### Bad Commit Messages (Don't Do This)
```
❌ "fix stuff"
❌ "update"
❌ "WIP"
❌ "asdf"
❌ "fix: fixed the thing"  (redundant "fixed")
❌ "feat: add feature"     (what feature?)
```

---

## Branch Naming

```
<type>/<short-description>
```

Examples:
```
feat/spectator-live-view
fix/oauth-cors-redirect
chore/upgrade-supabase-ssr
refactor/challenge-entry-flow
fix/rls-challenges-public-read
feat/wallet-stripe-checkout
```

Rules:
- All lowercase
- Hyphens between words (no underscores, no spaces)
- Keep short but descriptive
- Never work directly on `main`

---

## PR Flow

```
1. Create branch:     git checkout -b feat/spectator-live-view
2. Make changes:      edit files, test locally
3. Commit:            git add -A && git commit -m "feat(spectator): ..."
4. Push:              git push origin feat/spectator-live-view
5. Create PR:         GitHub UI or CLI
6. Vercel preview:    auto-deploys, get preview URL
7. Forge review:      send preview URL to Forge for E2E test
8. Address feedback:  fix issues, push more commits
9. Merge:             squash merge to main
10. Vercel prod:      auto-deploys to production
11. Verify:           check production URL
```

### PR Description Template
```markdown
## What changed
Brief description of what this PR does.

## Why
Link to bug report, feature request, or business context.

## How to test
1. Go to [preview URL]
2. Navigate to /challenges
3. Click "Enter Challenge"
4. Verify entry is created

## Screenshots
[Attach before/after if UI changed]

## Checklist
- [ ] TypeScript compiles (`npx tsc --noEmit`)
- [ ] Tested in preview deploy
- [ ] No console errors
- [ ] Forge review requested
```

---

## Common Git Operations

### Stash (Save Work Without Committing)
```bash
# Save current changes
git stash push -m "WIP: spectator event card styling"

# List stashes
git stash list

# Apply most recent stash (keep in stash list)
git stash apply

# Apply and remove from stash list
git stash pop

# Apply a specific stash
git stash apply stash@{2}
```

### Rebase (Keep Branch Up to Date)
```bash
# Update your feature branch with latest main
git checkout feat/spectator-live-view
git fetch origin
git rebase origin/main

# If conflicts occur:
# 1. Fix conflicts in files
# 2. git add <fixed-files>
# 3. git rebase --continue
# 4. Repeat until clean

# Abort if rebase goes wrong
git rebase --abort
```

### Cherry-Pick (Apply Specific Commit)
```bash
# Apply a specific commit from another branch
git cherry-pick <commit-hash>

# Cherry-pick without committing (just stage changes)
git cherry-pick --no-commit <commit-hash>
```

### Interactive Rebase (Clean Up Commits Before PR)
```bash
# Squash last 3 commits into 1
git rebase -i HEAD~3
# In editor: change "pick" to "squash" (or "s") for commits to combine
# Save and edit the combined commit message
```

---

## Handling Merge Conflicts

### Most Common Conflict Files in Next.js
1. `layout.tsx` — multiple branches adding imports
2. `page.tsx` — multiple branches modifying the same page
3. `globals.css` — multiple branches adding styles
4. `package.json` — dependency version conflicts
5. `middleware.ts` — multiple branches adding protected routes

### Resolution Strategy
```bash
# 1. See which files conflict
git status

# 2. Open conflicted file, look for markers:
<<<<<<< HEAD
// your changes
=======
// incoming changes
>>>>>>> feat/other-branch

# 3. Decide: keep yours, keep theirs, or merge both
# For imports: usually keep both (both branches need their imports)
# For logic: understand both changes, merge manually
# For styles: usually keep both (additive)
# For package.json: run npm install after resolving to regenerate lockfile

# 4. Mark resolved
git add <resolved-file>
git rebase --continue  # or git merge --continue
```

### When in Doubt
```bash
# Abort and ask for help
git merge --abort
git rebase --abort

# Check what changed on main since you branched
git log --oneline main..HEAD
git log --oneline HEAD..main
```

---

## Git Hooks

### Pre-commit: Lint Staged Files
```bash
# Install husky
npm install -D husky lint-staged
npx husky init

# .husky/pre-commit
npx lint-staged

# package.json
{
  "lint-staged": {
    "src/**/*.{ts,tsx}": ["eslint --fix", "prettier --write"]
  }
}
```

### Pre-push: TypeScript Check
```bash
# .husky/pre-push
npx tsc --noEmit
```

---

## Arena Repo Structure

```
/data/agent-arena/
├── .github/workflows/    # CI workflows
├── connector-cli/        # Standalone connector package
├── connector-skill/      # OpenClaw skill for connector
├── public/               # Static assets
├── src/
│   ├── app/              # Next.js App Router pages + API routes
│   ├── components/       # React components
│   ├── lib/              # Utilities, hooks, Supabase clients
│   └── types/            # TypeScript type definitions
├── supabase/
│   └── migrations/       # SQL migration files
├── middleware.ts          # Auth + route protection
├── next.config.ts        # Next.js configuration
├── tailwind.config.ts    # Tailwind CSS configuration
└── tsconfig.json         # TypeScript configuration
```

### Rules
- Never commit `node_modules/` (any level — gitignore uses `node_modules` not `/node_modules`)
- Never commit `.env.local` or any `.env*` file
- Never commit `.next/` build output
- Always commit `supabase/migrations/` (source of truth for schema)
- Always commit `connector-cli/src/` but not `connector-cli/dist/` (build output)
